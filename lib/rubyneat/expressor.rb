require 'rubyneat/rubyneat'
require 'pp'

module NEAT
  #= Basis of all expressors. 
  # Expressor object turn genotypes into phenotypes.
  class Expressor < Operator
    def initialize(c)
      super      
    end

    # Take the genotype of the critter and
    # create a phenotype from the genotype.
    # 
    # In the phenotype, it creates a function called stimulate(),
    # which is called with the input parameters and returns a response
    # in the form of a response hash (which corresponds directly to the
    # output neurons).
    #
    # This implementation assumes an acyclic graph (feed forward)
    # and cannot handle cycles at all. Later we may fix this or create
    # a type of Expressor that can.
    def express!(critter)
      critter.ready_for_expression!
      express_neurons! critter
      express_genes! critter
      express_expression! critter
    end

    protected
    # Express Neurons as methods
    def express_neurons!(critter)
      critter.genotype.neurons.each do |name, neuron|
        neuron.express(critter.phenotype) unless neuron.input? and not neuron.bias?
      end
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
    ## 1) Via yielding, thus treating the stimulus function as a enumerable.
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
      g = critter.genotype
      p = critter.phenotype

      init_code = "\n  def initialize_neurons\n"

      # 'stimulate' function call (really should be 'activate', but we'll reserve this for something else)
      p.code += "  def #{NEAT::STIMULUS}("
      p.code += g.neural_inputs.reject{ |sym| g.neural_inputs[sym].bias? }.map{|sym, neu| sym}.join(", ")
      p.code += ")\n"

      # Assign all the parameters to instance variables.
      p.code += g.neural_inputs.map{|sym, neu| "    @#{sym} = #{sym}\n"}.join("")
      p.code += "    loop {\n"

      # Resolve the order in which we shall call the neurons
      @resolved = NEAT::Graph::DependencyResolver[g.neural_outputs.map{|s, neu| neu}].resolve!

      # And now call them in that order!
      @resolved.each do |neu|
        unless neu.input?
          init_code += "    @#{neu.name} = 0\n"
          if g.neural_gene_map.member? neu.name
            p.code += "      @#{neu.name} = #{neu.name}("
            p.code += g.neural_gene_map[neu.name].map{ |gene|
              "%s * @%s" % [gene.weight, gene.in_neuron]
            }.join(", ") + ")\n"
          else
            g.dangling_neurons = true
            log.debug "Dangling neuron in critter #{critter} -- #{neu}"
          end
        end
      end
      init_code += "  end\n"

      # And now return the result as a vector of outputs.
      p.code += "     @_outvec = [" + g.neural_outputs.map{|sym, neu| "@#{sym}"}.join(',') + "]\n"
      p.code += "     break unless block_given?\n"
      p.code += "     break unless yield @_outvec\n"
      p.code += "  }\n"
      p.code += "  @_outvec\n"
      p.code += "  end\n"
      p.code += init_code
      log.debug p.code
      p.express!
    end

    def express_expression!(critter)
      critter.phenotype.express!      
    end
  end
end
