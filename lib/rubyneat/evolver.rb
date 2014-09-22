require 'rubyneat'
require 'distribution'

module NEAT
  #= Evolver -- Basis of all evolvers.
  # All evolvers shall derive from this basic evolver (or this one can be
  # used as is). Here, we'll have many different evolutionary operators
  # that will perform operations on the various critters in the population.
  #
  
  class Evolver < Operator
    attr_reader :npop

    def initialize(c)
      super
      @critter_op = CritterOp.new self
    end

    # Generate the initial genes for a given genotype.
    # We key genes off their innovation numbers.
    def gen_initial_genes!(genotype)
      genotype.genes = {}
      genotype.neural_inputs.each do |s1, input|
        genotype.neural_outputs.each do |s2, output|
          g = Critter::Genotype::Gene[genotype, input, output, NEAT::controller.gaussian]
          genotype.genes[g.innovation] = g
        end
      end
    end

    # Here we mutate the population.
    def mutate!(population)
      @npop = population

      if @controller.parms.mate_only_prob.nil? or rand > @controller.parms.mate_only_prob
        log.debug "[[[ Neuron and Gene Giggling!"
        mutate_perturb_gene_weights!
        mutate_change_gene_weights!
        mutate_add_neurons!
        mutate_change_neurons!
        mutate_add_genes!
        mutate_disable_genes!
        mutate_reenable_genes!
        log.debug "]]] End Neuron and Gene Giggling!\n"
      else
        log.debug "*** Mating only!"
      end
    end

    # Here we clone the population and then evolve it
    # on the basis of fitness and novelty, etc.
    #
    # Returns  the newly-evolved population.
    def evolve(population)
      @npop = population.dclone
      
      # Population sorting and evaluation for breeding, mutations, etc.
      prepare_speciation!
      prepare_fitness!
      prepare_novelty!

      mate!

      return @npop
    end
    
    # Here we specify evolutionary operators.
    protected
    
    def prepare_speciation!
      @npop.speciate!
      log.debug "SPECIES:"
      NEAT::dpp @npop.species
    end

    # Sort species within the basis of fitness.
    # Think of the fitness as an error / cost function.
    # The better fit, the closer to zero the fitness parameter will be.
    #
    # If a compare block is specified in the DSL, then that function is called
    # with the *fitness values* from critters c1 and c2. The default valuation
    # is c1.fitness <=> c2.fitness. You may elect to evaluate them differently.
    def prepare_fitness!
      @npop.species.each do |k, sp|
        sp.sort!{|c1, c2|
          unless @controller.compare_func.nil?
            @controller.compare_func_hook(c1.fitness, c2.fitness)
          else
            c1.fitness <=> c2.fitness
          end
        }
      end
    end

    #TODO: write novelty code
    def prepare_novelty!
    end

    # Perturb existing gene weights by adding a guassian to them.
    def mutate_perturb_gene_weights!
      @gperturb = Distribution::Normal::rng(0, @controller.parms.mutate_perturb_gene_weights_sd) if @gperturb.nil?
      @npop.critters.each do |critter|
        critter.genotypes.each{ |name, genotype|
            genotype.genes.each { |innov, gene|
            if rand < @controller.parms.mutate_perturb_gene_weights_prob
              gene.weight += per = @gperturb.()
              log.debug { "Peturbed gene #{gene}.#{innov} by #{per}" }
            end
          }
        }
      end
    end

    # Totally change weights to something completely different
    def mutate_change_gene_weights!
      @gchange = Distribution::Normal::rng(0, @controller.parms.mutate_change_gene_weights_sd) if @gchange.nil?
      @npop.critters.each do |critter|
        critter.genotypes.each{ |name, genotype|
            genotype.genes.each { |innov, gene|
            if rand < @controller.parms.mutate_change_gene_weights_prob
              gene.weight = chg = @gchange.()
              log.debug { "Change gene #{gene}.#{innov} by #{chg}" }
            end
          }
        }
      end
    end

    def mutate_add_genes!
      @npop.critters.each do |critter|
        if rand < @controller.parms.mutate_add_gene_prob
          log.debug "mutate_add_genes! for #{critter}"
          @critter_op.add_gene! critter
        end
      end
    end

    def mutate_disable_genes!
      @npop.critters.each do |critter|
        if rand < @controller.parms.mutate_gene_disable_prob
          log.debug "mutate_disable_genes! for #{critter}"
          @critter_op.disable_gene! critter
        end
      end
    end

    def mutate_reenable_genes!
      @npop.critters.each do |critter|
        if rand < @controller.parms.mutate_gene_reenable_prob
          log.debug "mutate_reenable_genes! for #{critter}"
          @critter_op.reenable_gene! critter
        end
      end
    end

    def mutate_add_neurons!
      @npop.critters.each do |critter|
        if rand < @controller.parms.mutate_add_neuron_prob
          log.debug "mutate_add_neurons! for #{critter}"
          @critter_op.add_neuron! critter
        end
      end
    end

    # TODO Finish mutate_change_neurons!
    def mutate_change_neurons!
      log.error "mutate_change_neurons! NIY"
    end

    # Here we select candidates for mating. We must look at species and fitness
    # to make the selection for mating.
    def mate!
      parm = @controller.parms
      popsize = parm.population_size
      surv = parm.survival_threshold
      survmin = parm.survival_mininum_per_species
      mlist = [] # list of chosen mating pairs of critters [crit1, crit2], or [:carryover, crit]

      # species list already sorted in descending order of fitness.
      # We will generate the approximate number of  pairs that correspond
      # to the survivial_threshold percentage of the population,
      # then backfill with the most fit out of the top original population.
      @npop.species.each do |k, sp|
        crem = [(sp.size * surv).ceil, survmin].max
        log.warn "Minumum per species hit -- #{survmin}" unless crem > survmin
        spsel = sp[0, crem]
        spsel = sp if spsel.empty?
        crem.times do
          mlist << [spsel[rand spsel.size], spsel[rand spsel.size]]
        end
      end

      # And now for the backfilling
      unless mlist.size >= @npop.critters.size
        mlist += @npop.critters[0, @npop.critters.size - mlist.size].map{|crit| [:carryover, crit]}
      end

      @npop.critters = mlist.map do |crit1, crit2|
        (crit1 == :carryover) ? crit2 : sex(crit1, crit2)
      end
    end
    
    protected
    # Mate the given critters and return a baby.
    # This is rather involved, and relies heavily on the Innovation Numbers.
    #
    # Some definitions:
    #
    ## Matching Gene
    ### 2 genes with matching innovation numbers.
    #
    ## Disjoint Gene
    ### A gene in one has an innovation number in the range of innovation numbers
    ### of the other.
    #
    ## Excess Gene
    ### Gene in one critter that has an innovation number outside of the range
    ### of innovation numbers of the other.
    #
    ## Neurons
    ### Distinct Neurons from both crit1 and crit2 must be present in
    ### the baby.
    #
    # Excess and Disjoint genes are always included from the more fit parent.
    # Matching genes are randomly chosen. For now, we make it 50/50.
    def sex(crit1, crit2)
      Critter.new(@npop, true) do |baby|
        fitcrit = if crit1.fitness > crit2.fitness
                    crit1
                  elsif crit2.fitness > crit1.fitness
                    crit2
                  else
                    (rand(2) == 1) ? crit1 : crit2
                  end
        a = crit1.genotype.genes.keys.to_set
        b = crit2.genotype.genes.keys.to_set
        disjoint = (a - b) + (b - a)
        joint = (a + b) - disjoint
        baby.genotype.neucleate { |gtype|
          joint.map { |innov|
            g1 = crit1.genotype.genes[innov]
            g2 = crit2.genotype.genes[innov]
            Critter::Genotype::Gene[gtype,
                                    g1.in_neuron, g1.out_neuron,
                                    (rand(2) == 1) ? g1.weight : g2.weight,
                                    innov]
          } + disjoint.map { |innov|
            fitcrit.genotype.genes[innov].clone unless fitcrit.genotype.genes[innov].nil?
          }.reject{|i| i.nil? }
        }
        baby.genotype.innervate! crit1.genotype.neurons, crit2.genotype.neurons
        baby.genotype.prune!
        baby.genotype.wire!
      end
    end

    # A set of Critter Genotype operators.
    class CritterOp < NeatOb
      def initialize(evol)
        super evol.controller
        @evolver = evol
        @npop = evol.npop
      end

      #= Add a neuron to given critter
      # Here, we add a neuron by randomly picking a
      # gene, and split it into two genes with an intervening
      # neuron. The old gene is not replaced, but disabled. 2 new genes are
      # created along with the new neuron.
      def add_neuron!(crit)
        crit.genotypes.each{ |name, genotype|
          gene = genotype.genes.values.sample
          neu = genotype.composition.neural_hidden.values.sample.new(controller)
          g1 = Critter::Genotype::Gene[genotype, gene.in_neuron, neu.name, gene.weight]
          g2 = Critter::Genotype::Gene[genotype, neu.name, gene.out_neuron, gene.weight]
          gene.enabled = false
          genotype.add_neurons neu
          genotype.add_genes g1, g2
          log.debug "add_neuron!(#{name}): neu #{neu}, g1 #{g1}, g2 #{g2}"
        }
      end

      #= Add a gene to the genome
      # Unlike adding a new neuron, adding a new gene
      # could result in a circular dependency. If so,
      # and if recurrency is switched off, we must detect
      # this condition and switch off the offending neurons.
      #
      # Obviously, this might result in a loss of functionality, but
      # oh well.
      #
      # An easy and obvious check is to make sure we don't
      # accept any inputs from output neurons, and we don't
      # do any outputs to input neurons.
      #
      # Constructs for handling recurrency are present in Expressor.
      def add_gene!(crit)
        crit.genotypes.each{ |name, genotype|
          n1 = genotype.neurons.values.sample # input
          n2 = genotype.neurons.values.sample # output

          # Sanity checks!
          unless n1 == n2 or n1.output? or n2.input?
            gene = Critter::Genotype::Gene[genotype, n1.name, n2.name, NEAT::controller.gaussian]
            genotype.add_genes gene
            log.debug "add_gene!(#{name}) Added gene #{gene}(#{n1.name} -> #{n2.name}) to #{crit}"
          end
        }
      end

      # Pick an enabled gene at random and disable it.
      def disable_gene!(crit)
        crit.genotypes.each{ |name, genotype|
          gene = genotype.genes.values.reject{ |gene| gene.disabled? }.sample
          gene.enabled = false unless gene.nil?
        }
      end

      # Pick a disabled gene at random and reenable it.
      def reenable_gene!(crit)
        crit.genotypes.each{ |name, genotype|
          gene = genotype.genes.values.reject{|gene| gene.enabled? }.sample
          gene.enabled = true unless gene.nil?
        }
      end
    end
  end
end
