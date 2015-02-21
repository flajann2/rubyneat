require_relative 'rubyneat'

module NEAT
  #= Basis of all expressors. 
  # Expressor object turn genotypes into phenotypes.
  class Expressor < Operator
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
    ## 1) Via yielding, thus treating the stimulus (activation)
    ## function as a enumerable.
    ### In this approach, one would call the Critter's phenotype with a block of
    ### code that would accept the output of the net. It would return 'true' to
    ### continue the iteration, or 'false' to end the iteration.
    ## 2) Via multiple calls to the Pheontype instance:
    ### Since the value of the prior activation is preserved in the instance variables
    ### of the phenotype, subsequent activations will iterate the network.
    #== Cavets to recurrent activation
    # For (2) above, the input neurons would be overwritten on each subsequent call.
    # Since we do not allow recurrent connections to input neurons anyway, this should
    # not be an issue, though we may allow for this at a future date.
    def express_genes!(critter)
      p = critter.phenotype

      critter.genotypes.each{ |name, g|
        init_code = "\n  def #{g.init_funct}\n"

        # 'stimulate' function call (really should be 'activate', but we'll reserve this for something else)
        p.code += "  def #{g.activation_funct}("
        p.code += g.funct_parameters.join(', ')
        p.code += ")\n"

        # Assign all the parameters to instance variables.
        p.code += g.neural_inputs.map{|sym, neu| "    #{g.uvar sym} = #{sym}\n"}.join("")
        p.code += "    loop {\n"

        # Resolve the order in which we shall call the neurons
        # TODO handle the dependency list if it comes back!
        @resolved, @dependencies = NEAT::Graph::DependencyResolver[g.neural_outputs.map{|s, neu| neu}].resolve

        # And now call them in that order!
        @resolved.each do |neu|
          unless neu.input?
            init_code += "    #{g.uvar neu.name} = 0\n"
            if g.neural_gene_map.member? neu.name
              p.code += "      #{g.uvar neu.name} = #{neu.name}("
              p.code += g.neural_gene_map[neu.name].map{ |gene|
                "%s * %s" % [gene.weight, g.uvar(gene.in_neuron)]
              }.join(", ") + ")\n"
            else
              g.dangling_neurons = true
              log.debug "Dangling neuron in critter #{critter} -- #{neu}"
            end
          end
        end
        init_code += "  end\n\n"

        # And now return the result as a vector of outputs.
        outvec = g.uvar :_outvec
        p.code += "      #{outvec} = [" + g.funct_outputs.map{ |sym| "#{g.uvar sym}"}.join(',') + "]\n"
        p.code += "      break unless block_given?\n"
        p.code += "      break unless yield #{outvec}\n"
        p.code += "    }\n"
        p.code += "    #{outvec}\n"
        p.code += "  end\n\n"
        p.code += init_code
      }
      p.code += xpress_wrapper critter
      log.debug p.code
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

      # Initialize neurons for the critter function
      code =  %[  def #{critter.init_funct} \n]
      code += gtypes.map{|k, g| g.init_funct }.map{|f| "    #{f}"}.join("\n")
      code += %[\n  end\n\n]

      # Main Critter Activation Function.
      # TODO: This function currently does not handle recurrent
      # TODO: TWEANNs.
      annlist = conn.keys - [:input, :output] # order-preserving set op
      code += %[  def #{critter.activation_funct}(#{critter.funct_params.join(', ')})\n]

      # make input parameters into instance variables
      code += conn[:input].keys.map{ |v| %[    #{c.uvar v, :input} = #{v}\n]}.join

      # call the other ANNs
      code += annlist.map{ |ann|
        g = gtypes[ann] # genotype for the ANN
        %[    #{(g.funct_outputs.map{|o| g.uvar(o) } + [:ignore]).join(', ')} = #{ann}(#{g.funct_parameters.map{|p| plist[ann][p]}.join(', ') })\n]
      }.join

      # Output (return) the results.
      outvec = conn[:output].map{ |o| plist[:output][o] }
      code += %{    [#{outvec.join(', ')}]\n}

      # code endtet hier!
      code += %[  end\n\n]
      code
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
