require 'rubyneat/rubyneat'

=begin rdoc
= Critter
=end
module NEAT

  #= Critters for NEAT
  # The Critter class comprises a Genotype and a Phenotype.
  # The Genotype comprises Genes and Neurons.
  class Critter < NeatOb
    attr_reader :population
    attr_accessor :genotype, :phenotype

    # Ratings assigned by Evaluator
    attr_accessor :fitness, :novelty

    # Critter construction. We construct the genotype.
    # The phenotype will be constructed by the Expressor operator.
    def initialize(pop, mating = false)
      super pop.controller
      @population = pop
      @genotype = Genotype.new(self, mating)
    end

    # We deep-copy the genotype here, since we
    # obviously need it to be seperate.
    def initialize_copy(source)
      super
      @genotype = source.genotype.clone
      @genotype.critter = self
    end

    # Get the Critter ready for the Expressor to
    # express the geneotype.
    def ready_for_expression!
      @genotype.wire!
      @phenotype = NEAT::Critter::Phenotype[self]
    end

    # Exoress this critter using the Expressor plugin.
    def express!
      @controller.expressor.express! self
    end

    # A single evaluation step. Evaluate and
    # generate fitness, novelty, etc.
    # Returns the result.
    def evaluate!
      @controller.evaluator.evaluate! self
    end

    #= Genotype part of the Critter
    # List of connections, basically.
    #
    # Also, basic phentypic expression (which may be overriden by
    # the expressor)
    #
    #= Notes
    # Currently, all lists of neurons and genes are Hashes. The
    # neurons are indexed by their own names, and the genes
    # are indexed by their innovation numbers.
    #
    class Genotype < NeatOb
      # Critter to which we belong
      attr_accessor :critter

      # Genes keyed by innovation numbers
      attr_accessor :genes

      # List of neurons hashed by name
      attr_accessor :neurons

      # Instantiations of neural inputs and outputs
      attr_reader :neural_inputs, :neural_outputs

      # Map neurons to the genes that marks them as output
      # { oneu_name => [ gene_1, gene_2,... gene_n], ...}
      # Just take the in_neuron name and the weight to do
      # the call to that neuron function with the appropriate weights
      attr_reader :neural_gene_map

      def initialize(critter, mating = false)
        super critter.controller
        @critter = critter

        # Initialize basic structures
        @neural_inputs = Hash[@critter.population.input_neurons.map { |sym, ineu| 
                                [sym, ineu.new(@controller, sym)]
                              }]

        @neural_outputs = Hash[@critter.population.output_neurons.map { |sym, ineu| 
                                [sym, ineu.new(@controller, sym)]
                              }]
        @neurons = @neural_inputs.clone
        @neurons.merge! @neural_outputs

        @controller.evolver.gen_initial_genes!(self) unless mating
      end
      
      # Deep-copy the neurons and genes.
      # Question: Do we really need to deep-copy the neurons?
      # There is the possibility of modifying the neurons themselves,
      # so for now we do this.
      def initialize_copy(source)
        super
        @neurons = source.neurons.clone
        @genes = source.genes.clone
      end

      # Make the neurons forget their wiring.
      def forget!
        @neurons.each do |name, neu|
          neu.clear_graph
        end
        @neural_gene_map = {}
      end

      # Wire up the neurons based on the genes.
      def wire!
        forget!
        @genes.each do |innov, gene|
          if gene.enabled?
            @neurons[gene.out_neuron] << @neurons[gene.in_neuron]
            @neural_gene_map[gene.out_neuron] = [] if @neural_gene_map[gene.out_neuron].nil?
            @neural_gene_map[gene.out_neuron] << gene unless gene.in_neuron.nil?
          end
        end
      end

      #= Gene Specification
      # The Gene specifices a singlular input and
      # output neuron, which represents a connection
      # between them, along with the weight of that
      # connection, which may be positive, negative, or zero.
      #
      # There is also the enabled flag
      class Gene < NeatOb
        # parent genotype
        attr_accessor :genotype

        # innovation number
        attr_reader :innovation

        # input neuron's name (where our output goes)
        # ouptut neuron's name (neuron to be queried)
        attr_accessor :in_neuron, :out_neuron

        # weight of the connection
        attr_accessor :weight
        # Is this gene enabled?
        attr_accessor :enabled

        def initialize(genotype)
          super genotype.controller
          @genotype = genotype
          @enabled = true
          @innovation = NEAT::new_innovation
        end

        def enabled? ; @enabled ; end

        # Create a new Gene and set it up fully.
        def self.[](genotype, input, output, weight = 0.0)
          g = Gene.new genotype
          g.in_neuron = input.name
          g.out_neuron = output.name
          g.weight = weight
          return g
        end

        def to_s
          super + "[i%s,w%s,%s]" % [@innovation, @weight, self.enabled?]
        end
      end

    end

    #= Phenotype part of the Critter
    # This is created by Evolver. 
    class Phenotype < NeatOb
      include Math

      # Critter to which we belong
      attr_accessor :critter

      # Expressed code as a string (that was instance_eval()ed)
      attr_accessor :code

      def self.[](critter)
        ph = Phenotype.new critter.controller
        ph.critter = critter
        ph.code = "## Phenotype Code %s for critter %s\n" % [ph.name, critter.name]
        return ph
      end
      
      # Take what is in code and express that!
      def express!
        instance_eval @code
        return self
      end

      # This function is re-written by Expressor -- with parameters and all.
      # It returns a "response" in the form of a response hash.
      def stimulate
        nil
      end

      # This gives us a complete
      def to_s
        "## %s\n%s" % [super, @code]
      end
    end

    # Compare ourselves against another critter for
    # compability.
    #
    # The function to be used here is:
    ## distance = c1*E + c2*D + c3*W
    # 
    # Where:
    ## E, D - The number of excess and disjoint genes repesctively.
    ## N - The number of genes in the largest genome.
    ## W - The sum of absolute weight differences.
    #
    # This is a variation of the formulation suggested by the Stanley
    # paper, which normalizes the E and D terms by N.
    def compare(oc)
      c1 = @controller.parms.excess_coefficient
      c2 = @controller.parms.disjoint_coefficient
      c3 = @controller.parms.weight_coefficient
      e = excess(oc)
      d = disjoint(oc)
      w = weight_diff(oc)
      return c1 * e + c2 * d + c3 * w
    end

    private
    # Return a count of excesses.
    def excess(oc)
      (@genotype.genes.size - oc.genotype.genes.size).abs
    end

    # Return the count of disjoint genes
    def disjoint(oc)
      a = @genotype.genes.keys
      b = oc.genotype.genes.keys
      (a - b).size + (b - a).size - excess(oc)
    end

    # 
    def weight_diff(oc)
      ag = @genotype.genes
      bg = oc.genotype.genes
      matches = ag.keys & bg.keys
      unless matches.empty?
        matches.map{|i| (ag[i].weight - bg[i].weight).abs}.reduce{|w, ws| w + ws} / matches.size
      else
        0
      end
    end

  end
end
