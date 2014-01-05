require 'rubyneat'

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
    def initialize(pop, mating = false, &block)
      super pop.controller
      @population = pop
      @genotype = Genotype.new(self, mating)
      block.(self) unless block.nil?
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

      def initialize(critter, mating = false, &block)
        super critter.controller
        @critter = critter

        # Initialize basic structures
        @genes = nil
        @neural_inputs = Hash[@critter.population.input_neurons.map { |sym, ineu|
                                [sym, ineu.new(@controller, sym)]
                              }]

        @neural_outputs = Hash[@critter.population.output_neurons.map { |sym, ineu|
                                [sym, ineu.new(@controller, sym)]
                              }]
        @neurons = @neural_inputs.clone # this must be a shallow clone!
        @neurons.merge! @neural_outputs

        @controller.evolver.gen_initial_genes!(self) unless mating
        block.(self) unless block.nil?
      end

      # We add genes given here to the genome.
      # An array of genes is returned from the block
      # and we simply add them in.
      # @param [boolean] clean
      # @param [Proc] block
      def neucleate(clean: true, &block)
        genes = Hash[block.(self).map { |g|
          g.genotype = self
          [g.innovation, g] }]
        if clean
          @genes = genes
        else
          @genes.merge! genes
        end
        nuke_redundancies!
      end

      # Remove any redundancies in the genome,
      # any genes refering to the same two neurons.
      # Simply choose one and delete the rest.
      # TODO: implement nuke_redundancies!
      def nuke_redundancies!
        log.error 'nuke_redundancies! NIY'
      end

      # Make the neurons forget their wiring.
      def forget!
        @neurons.each { |name, neu| neu.clear_graph }
        @neural_gene_map = Hash.new {|h, k| h[k] = [] }
      end

      # Wire up the neurons based on the genes.
      def wire!
        forget!
        @genes.each do |innov, gene|
          if gene.enabled?
            raise NeatException.new "Can't find #{gene.out_neuron}" if @neurons[gene.out_neuron].nil?
            @neurons[gene.out_neuron] << @neurons[gene.in_neuron]
            @neural_gene_map[gene.out_neuron] << gene unless gene.in_neuron.nil?
          end
        end unless @genes.nil?
        if @genes.nil?
          $log.error 'Genes Not Present'
        end
      end

      # Add new neurons to the fold
      def add_neurons(*neus)
        neus.each do |neu|
          @neurons[neu.name] = neu
        end
      end

      # Genes added here MUST correspond to pre-existing neurons.
      # Be sure to do add_neurons first!!!!
      def add_genes(*genes)
        genes.each do |gene|
          raise NeatException.new "Neuron #{gene.in_neuron} missing" unless @neurons.member? gene.in_neuron
          raise NeatException.new "Neuron #{gene.out_neuron} missing" unless @neurons.member? gene.out_neuron
          @genes[gene.innovation] = gene
        end
      end

      # We take the neural hashes (presumably from other neurons), and innervate them.
      # We do this in distinctions based on the neuron's names.
      # FIXME We need to randomly select a neuron in the case of clashes.
      # @param [Hash] hneus -- hashes of neurons to innervate
      def innervate!(*hneus)
        hneus.each do |neus|
          @neurons.merge! neus.dclone
        end
      end

      # Go through the list of neurons and drop
      # any neurons not referenced by the genes.
      #
      # Then go through the genes and drop any that
      # are dangling (i.e. no matching neurons)
      #
      # Then make sure that @neural_inputs and @neural_outputs reference the actual
      # instance neurons in @neurons
      def prune!
        # Take care of dangling neurons
        neunames = @genes.values.map{|g| [g.in_neuron, g.out_neuron]}.flatten.to_set
        @neurons = Hash[@neurons.values.reject do |n|
          not neunames.member? n.name
        end.map do |n|
          [n.name, n]
        end]

        # Take care of dangling genes
        @genes = Hash[@genes.values.reject do |gene|
          not (@neurons.member?(gene.in_neuron) and @neurons.member?(gene.out_neuron))
        end.map do |gene|
          [gene.name, gene]
        end]

        # Make sure @neural_inputs and @neural_outputs are consistent
        @neural_inputs = Hash[@neural_inputs.values.map{|n| [n.name, @neurons[n.name]]}]
        @neural_outputs = Hash[@neural_outputs.values.map{|n| [n.name, @neurons[n.name]]}]
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
        attr_accessor :innovation

        # input neuron's name (where our output goes)
        # ouptut neuron's name (neuron to be queried)
        attr_accessor :in_neuron, :out_neuron

        # weight of the connection
        attr_accessor :weight
        # Is this gene enabled?
        attr_accessor :enabled

        def initialize(genotype, &block)
          super genotype.controller
          @genotype = genotype
          @enabled = true
          @innovation = NEAT::new_innovation
          @in_neuron = @out_neuron = nil
          block.(self) unless block.nil?
        end

        def enabled? ; @enabled ; end

        # Create a new Gene and set it up fully.
        ## genotype -- genotype
        ## input -- name of input neuron connection
        ## output -- name of output neuron connection
        ## weight -- weight to give neuron (optional)
        ## innov -- innovation number of gene (optional)
        def self.[](genotype, input, output, weight = 0.0, innov = nil)
          g = Gene.new genotype
          g.in_neuron = (input.kind_of? Symbol) ? input : input.name
          g.out_neuron = (output.kind_of? Symbol) ? output : output.name
          g.weight = weight
          g.innovation = innov unless innov.nil?
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
        self
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
