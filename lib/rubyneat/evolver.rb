require 'rubyneat'
require 'distribution'
module NEAT
  #= Evolver -- Basis of all evolvers.
  # All evolvers shall derive from this basic evolver (or this one can be
  # used as is). Here, we'll have many different evolutionary operators
  # that will perform operations on the various critters in the population.
  #
  
  class Evolver < Operator
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

      # Do it!
      if @controller.parms.mate_only_prob.nil? or rand > @controller.parms.mate_only_prob
        log.debug "[[[ Neuron Giggling!"
        mutate_perturb_gene_weights!
        mutate_change_gene_weights!
        mutate_add_neurons!
        mutate_change_neurons!
        mutate_add_genes!
        mutate_reenable_genes!
        log.debug "]]] End Neuron Giggling!\n"
      else
        log.debug "*** Mating only!"
      end
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

    # Sort species within the basis of fitness
    def prepare_fitness!
      @npop.species.each do |k, sp|
        sp.sort!{|c1, c2| c2.fitness <=> c1.fitness }
      end
    end

    #TODO: write novelty code
    def prepare_novelty!
    end

    # Perturb existing gene weights by adding a guassian to them.
    def mutate_perturb_gene_weights!
      @gperturb = Distribution::Normal::rng(0, @controller.parms.mutate_perturb_gene_weights_sd) if @gperturb.nil?
      @npop.critters.each do |critter|
        critter.genotype.genes.each { |innov, gene|
          if rand < @controller.parms.mutate_perturb_gene_weights_prob
            gene.weight += per = @gperturb.()
            log.debug { "Peturbed gene #{gene}.#{innov} by #{per}" }
          end
        }
      end
    end

    # TODO Finish mutate_change_gene_weights!
    def mutate_change_gene_weights!
      log.error "mutate_change_gene_weights! NIY"
    end

    # TODO Finish mutate_add_genes!
    def mutate_add_genes!
      log.error "mutate_add_genes! NIY"
    end

    # TODO Finish mutate_reenable_genes!
    def mutate_reenable_genes!
      log.error "mutate_reenable_genes! NIY"
    end


    # TODO Finish mutate_add_neurons!
    def mutate_add_neurons!
      log.error "mutate_add_neurons! NIY"
    end

    # TODO Finish mutate_change_neurons!
    def mutate_change_neurons!
      log.error "mutate_change_neurons! NIY"
    end

    # Here we select candidates for mating. We must look at species and fitness
    # to make the selection for mating.
    def mate!
      popsize = @controller.parms.population_size
      surv = @controller.parms.survival_threshold
      mlist = [] # list of chosen mating pairs of critters [crit1, crit2]

      # species list already sorted in descending order of fitness
      @npop.species.each do |k, sp|
        spsel = sp[0, sp.size * surv]
        spsel = sp if spsel.empty?
        sp.size.times do
          mlist << [spsel[rand spsel.size], spsel[rand spsel.size]]
        end
      end
      @npop.critters = mlist.map do |crit1, crit2|
        sex crit1, crit2
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
      end
    end
  end
end
