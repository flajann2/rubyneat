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
    # This implenetation assumes an acyclic graph (feed forward)
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
    
    # What this really does is create the function that calls
    # all the functions. 
    #
    # This makes use of the Graph plugin for Neurons.
    def express_genes!(critter)
      g = critter.genotype
      p = critter.phenotype

      # 'stimulate' function call
      p.code += "  def #{NEAT::STIMULUS}("
      p.code += g.neural_inputs.reject{ |sym| g.neural_inputs[sym].bias? }.map{|sym, neu| sym}.join(", ")
      p.code += ")\n"

      # Assign all the parameters to instance variables.
      # FIXME: Later eliminate this step!!! We can either fix the code
      # to use local variables or add the logic to check for parameter inputs.
      p.code += g.neural_inputs.map{|sym, neu| "    @#{sym} = #{sym}\n"}.join("")
      
      # Resolve the order in which we shall call the neurons
      @resolved = NEAT::Graph::DependencyResolver[g.neural_outputs.map{|s, neu| neu}].resolve!

      # And now call them in that order!
      @resolved.each do |neu|
        unless neu.input?
          p.code += "    @#{neu.name} = #{neu.name}("
          p.code += g.neural_gene_map[neu.name].map{ |gene|
            "%s * @%s" % [gene.weight, gene.in_neuron]
          }.join(", ") + ")\n"
        end
      end

      # And now return the result as a vector of outputs.
      p.code += "    return [" + g.neural_outputs.map{|sym, neu| "@#{sym}"}.join(',') + "]\n  end\n"
      log.debug p.code
      p.express!
    end

    def express_expression!(critter)
      critter.phenotype.express!      
    end
  end
end
