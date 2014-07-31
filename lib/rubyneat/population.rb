require_relative 'rubyneat'

module NEAT
  #= Population of NEAT Critters.
  # The Population 
  # In ourselves we have the pool of neurons the critters all use.
  # the pool of neurons are indirects, of course, as during phenotype
  # expression, all the phenotypes shall be created individually.
  #
  class Population < NeatOb
    # Generation number of the Population.
    # Any newly-derivied population is always one greater
    # than the former. Needs to be set, invalid if nil.
    attr_neat :generation, default: nil

    # Ordered list or hash of input neuron classes 
    # (all critters generated here shall have this)
    attr_accessor :input_neurons

    # List of possible neuron classes for hidden neurons.
    attr_accessor :hidden_neurons

    # Ordered list or hash of output neuron classes
    # (all critters generated here shall have this)
    attr_accessor :output_neurons

    attr_accessor :traits

    # list of critter in this population
    attr_accessor :critters

    # Overall population fitness and novelty
    attr_reader :fitness, :novelty

    # Hash list of species lists
    attr_reader :species

    # in a deep dive, exclude the following from replication.
    exclude :input_neurons, :output_neurons

    # Create initial (ramdom) population of critters
    def initialize(c, &block)
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

      block.(self) unless block.nil?
    end

    # Make sure all critters are reset and prepared for
    # recurrent network evaluation.
    def initialize_for_recurrence!
      @critters.each {|crit| crit.initialize_neurons!}
    end

    # Mutate the genes and neurons.
    def mutate!
      @controller.evolver.mutate! self
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
   
    # Group critters into species
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

      def @species.compactify!(parm)
        mutt = self[:mutt] = self.map { |k, splist| [k, splist]}.reject {|k, splist|
          splist.size >= parm.smallest_species
        }.map { |k, splist|
          self.delete k
          splist
        }.flatten

        # FIXME this code is not dry!!!!
        def mutt.fitness=(fit)
          @fitness = fit
        end

        def mutt.fitness
          @fitness
        end

        self.delete :mutt if self[:mutt].empty?
      end

      # Some convience parms
      parm = @controller.parms

      # And so now we iterate...
      @critters.each do |crit|
        wearein = false
        @species.each do |ck, list|
          delta = crit.compare(ck)
          #log.debug { "delta for #{crit} and #{ck} is #{delta}" }
          if delta < parm.compatibility_threshold
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

      # Compactify the species if less than smallest_species
      @species.compactify! parm

      # And now we evaluate all species for fitness...
      @species.evaluate!

      # Dump for debugging reasons
      @species.each do |k, sp|
        log.debug ">> Species #{k} has #{sp.size} members with a #{sp.fitness} fitness"
      end

    end

    # The "best critter" is the critter with the lowest (closet to zero)
    # fitness rating.
    # TODO: DRY up best_critter and worst_critter
    def best_critter
      unless @controller.compare_func.empty?
        @critters.min {|a, b| @controller.compare_func_hook(a.fitness, b.fitness) }
      else
        @critters.min {|a, b| a.fitness <=> b.fitness}
      end
    end

    # The "worst critter" is the critter with the highest (away from zero)
    # fitness rating.
    def worst_critter
      unless @controller.compare_func.empty?
        @critters.max {|a, b| @controller.compare_func_hook(a.fitness, b.fitness) }
      else
        @critters.max {|a, b| a.fitness <=> b.fitness}
      end
    end

    def dump_s
      to_s + "\npopulation:\n" + @critters.map{|crit| crit.dump_s }.join("\n")
    end
  end
end
