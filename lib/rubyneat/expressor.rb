require_relative 'rubyneat'

module NEAT
  #= Basis of all expressors. 
  # Expressor object turn genotypes into phenotypes.
  class Expressor < Operator
    include SExpressions

    def initialize(c)
      super      
    end

    # Take the genotype(s) of the critter and
    # create a phenotype from the genotype.
    # 
    # In the phenotype, it creates a function called stimulate(),
    # which is called with the input parameters and returns a response
    # in the form of a response hash (which corresponds directly to the
    # output neurons).
    #
    # This implementation handles both acyclic (feed forward) and cyclic
    # (recurrent) graphs.
    def express!(critter)
      critter.ready_for_expression!
      express_neurons! critter
      express_genes! critter
      express_expression! critter
    end

    protected
    # Express Neurons as methods
    def express_neurons!(critter)
      critter.genotypes.each { |gname, genotype|
        genotype.neurons.each do |name, neuron|
          neuron.express(critter.phenotype) unless neuron.input? and not neuron.bias?
        end
      }
    end
    
    #= Expression of the Genotype as a Phenotype.
    # What this really does is create the function that calls
    # all the functions. 
    #
    # This makes use of the Graph plugin for Neurons.
    #= Recurrency and Expression of Genes
    # A simple approach has been taken here to allow for recurrency in
    # our Critters. Basically, a looping construct has been put around the
    # activation of the neurons so that recurrency can be done in 2 ways:
    #
    ## 1) Via yielding, thus treating the stimulus (activation)
    ## function as a enumerable.
    ### In this approach, one would call the Critter's phenotype with a block of
    ### code that would accept the output of the net. It would return 'true' to
    ### continue the iteration, or 'false' to end the iteration.
    ###
    ## 2) Via multiple calls to the Pheontype instance:
    ### Since the value of the prior activation is preserved in the instance variables
    ### of the phenotype, subsequent activations will iterate the network.
    ###
    #== Cavets to recurrent activation
    # For (2) above, the input neurons would be overwritten on each subsequent call.
    # Since we do not allow recurrent connections to input neurons anyway, this should
    # not be an issue, though we may allow for this at a future date.
    def express_genes!(critter)
      p = critter.phenotype
      sx = [] # Where all of our child s-expressions go

      critter.genotypes.each{ |name, g|
        isx = [] # Initial expressions will go here

        # Resolve the order in which we shall call the neurons
        # TODO handle the dependency list if it comes back!
        @resolved, @dependencies = NEAT::Graph::DependencyResolver[g.neural_outputs.map{|s, neu| neu}].resolve
        sx << s(:def, g.activation_funct,
                s(:args, *g.funct_parameters.map{ |pm| s(:arg, pm)  }),
                s(:begin,
                  # Assign all the parameters to instance variables.
                  *g.neural_inputs.map{|sym, neu| s(:ivasgn, g.uvar(sym), s(:lvar, sym))},
                  
                  # looping construct for generator
                  s(:block,
                    s(:send, nil, :loop), s(:args),
                    s(:begin,                      
                      # And now call them in that order!
                      *@resolved.map { |neu|
                        unless neu.input?
                          isx << s(:ivasgn, g.uvar(neu.name), s(:float, 0.0))
                          
                          if g.neural_gene_map.member? neu.name
                            s(:ivasgn, g.uvar(neu.name),
                              s(:send, nil, neu.name, 
                                *g.neural_gene_map[neu.name].map{ |gene|
                                  s(:send,
                                    s(:float, gene.weight),
                                    :*,
                                    s(:lvar, g.uvar(gene.in_neuron)))
                                }))
                          else
                            g.dangling_neurons = true
                            log.debug "Dangling neuron in critter #{critter} -- #{neu}"
                            nil
                          end
                        end
                      }.compact,

                      s(:ivasgn, g.uvar(:_outvec), 
                        s(:array, *g.funct_outputs.map{ |sym| s(:lvar, g.uvar(sym)) })),
                      s(:if, s(:send, nil, :block_given?), nil, s(:break)),
                      s(:if, s(:yield, s(:ivar, g.uvar(:_outvec))), nil,s(:break)))),
                  s(:lvar, g.uvar(:_outvec))
                  ))
        # init code
        sx << s(:def, g.init_funct, s(:args), *isx)
      }
      sx += xpress_wrapper(critter)
      p.code = s(:begin, *sx)
      log.debug p.code.inspect if cparms.verbose_logging
      log.debug Unparser.unparse p.code if cparms.verbose_logging == :all
      p.express!
    end

    # Express the wrapper code
    # TODO: We generate these calls within the activation function
    # TODO: in the order specified in the connections directive. We
    # TODO: do the necessary "magic" to automatically order the calls
    # TODO: like we do in the code generation of the TWEANNs themselves.
    def xpress_wrapper(critter)
      c = critter
      corpus = critter.population.corpus
      conn = corpus.nexion.conn
      gtypes = critter.genotypes
      plist = generate_ann_plist c, gtypes, conn
      annlist = conn.keys - [:input, :output] # order-preserving set op

      # Here we generate a couple of functions.
      [
       # Initialize neurons for the critter function
       s(:def, critter.init_funct, 
                s(:args),
                s(:begin, *gtypes.map{ |k, g| g.init_funct }.map{|f| s(:send, nil, f)})),

       # Main Critter Activation Function.
       # TODO: This function currently does not handle recurrent TWEANNs.
       s(:def, critter.activation_funct,
         s(:args, *critter.funct_params.map{|arg| s(:arg, arg)}),
         s(:begin, 
           
           # make input parameters into instance variables
           *conn[:input].keys.map{ |v|
             s(:ivasgn, c.uvar(v, :input), s(:lvar, v))},
           
           # call the other ANNs
           *annlist.map{ |ann| xp_ann_caller(gtypes, ann, plist)},
           
           # Output (return) the results.
           s(:array, *conn[:output].map{ |o| s(:ivar, plist[:output][o]) }))),
       ]
    end

    def xp_ann_caller(gtypes, ann, plist)
      # call the other ANNs
      g = gtypes[ann] # genotype for the ANN
      s(:masgn,
        s(:mlhs,
          *(g.funct_outputs.map{ |o| s(:ivasgn, g.uvar(o)) } + [s(:ivasgn, :ignore)])), 
        s(:send, nil, g.activation_funct, 
          *g.funct_parameters.map{ |p| s(:ivar, plist[ann][p]) }))
    end

    # Taking the conn directives, generate a parameter
    # list (really a map) of all the ANNs.
    # TODO: We should do a check here to ensure that all parameters
    # TODO: are fully specified and are only assigned once.
    def generate_ann_plist(crit, gtypes, conn)
      (conn.keys - [:output]).reduce({}){ |memo_ann, ann|
        aplist = conn[ann].reduce({}){ |memo, (pfrom, apto)|
          # @ann_pfrom
          vfrom = unless ann == :input
                    gtypes[ann].uvar pfrom
                  else
                    crit.uvar pfrom, :input
                  end
          apto.each{ |to_ann, to_parm|
            (memo[to_ann] ||= {})[to_parm] = vfrom
          }
          memo
        }
        aplist.each{ |to_ann, plist|
          unless memo_ann.member? to_ann
            memo_ann[to_ann] = plist
          else
            memo_ann[to_ann].merge! plist
          end
        }
        memo_ann
      }
    end

    def express_expression!(critter)
      critter.phenotype.express!      
    end
  end
end
