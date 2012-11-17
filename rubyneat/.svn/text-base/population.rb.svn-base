require 'rubyneat/rubyneat'

module NEAT
  #= Population of NEAT Critters.
  # The Population 
  # In ourselves we have the pool of neurons the critters all use.
  # the pool of neurons are indirects, of course, as during phenotype
  # expression, all the phenotypes shall be created individually.
  #
  class Population < NeatOb
    # Ordered list or hash of input neuron classes (all critters generated here shall have this)
    attr_accessor :input_neurons

    # List of possible neuron classes for hidden neurons.
    attr_accessor :hidden_neurons

    # Ordered list or hash of output neuron classes (all critters generated here shall have this)
    attr_accessor :output_neurons

    attr_accessor :traits

    # list of critter in this population
    attr_accessor :critters

    # Overall population fitness and novelty
    attr_reader :fitness, :novelty

    # Hash list of species lists
    attr_reader :species

    # Create initial (ramdom) population of critters
    def initialize(c)
      super
      @input_neurons = c.neural_inputs.clone
      @output_neurons = c.neural_outputs.clone
      @hidden_neurons = unless c.neural_hidden.nil?
                          c.neural_hidden
                        else
                          c.neuron_catalog.keep_if {|n| not n.input?}
                        end
      @critters = (0 ... c.parms.start_population_size || c.parms.population_size).map do
        Critter.new(self)
      end
    end
    
    # Express the entire population.
    def express!
       @critters.each { |critter| critter.express! }
    end

    # Called for each sequence.
    def evaluate!
       @critters.each { |critter| critter.evaluate! }
    end
    
    # Alalyze evaluation results.
    def analyze!
       @critters.each { |critter| @controller.evaluator.analyze_for_fitness! critter }
    end

    # Call this after evaluation.
    # Returns a newly-evolved population.
    def evolve
      @controller.evolver.evolve self
    end
   
    # Group crtters into species
    # Note that the @species objects
    # have useful singleton methods:
    #* @species.member? -- checks all of the lists for membership, not just the hash
    #* @species[crit].fitness -- fitness of the entire species
    def speciate!
      # We blow away existing species and create our own member? function
      @species = {} # lists keyed by representative critter
      def @species.member?(crit)
        super.member?(crit) or self.map{|k, li| li.member? crit}.reduce{|t1, t2| t1 or t2 }
      end

      def @species.evaluate!
        self.each do |k, sp|
          sp.fitness = sp.map{|crit| crit.fitness}.reduce{|a,b| a+b} / sp.size
        end
      end
      
      # Some convience parms
      threshold = @controller.parms.compatibility_threshold

      # And so now we iterate...
      @critters.each do |crit|
        wearein = false
        @species.each do |ck, list|
          delta = crit.compare(ck)
          puts "delta for #{crit} and #{ck} is #{delta}"
          if delta < threshold
            list << crit
            wearein = true
            break
          end
        end
        # New species?
        unless wearein
          @species[crit] = species = [crit]
          def species.fitness=(fit)
            @fitness = fit
          end
          def species.fitness
            @fitness
          end
        end
      end

      # And now we evaluate all species for fitness...
      @species.evaluate!
    end

  end
end
