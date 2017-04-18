=begin rdoc
=RubyNEAT Reporting
Here we factor out all reporting-related functionality across the entire
RubyNEAT system to this one place, because reporting is not directly related
to RubyNEAT functionality. As such, it will make it much easier for forkers
to slim down RubyNEAT for some specific application where reporting may not
be so needed.

As far as plugins go, we could insist that all plugins do their own reporting.
However, we wish to insulate such activities from the internal structures of
the Population, Critters, etc. simply they are subject to change. This affords
us the one place to look to update the API in response to deep structural changes.
=end

module NEAT
  #= Population Reporting
  # The tangenial reporting needs for the Population module
  # are extracted here simply because they do not directly relate
  # to the operations of the Population.
  class Population
    # report on many fitness metrics
    def report_fitness
      {
          overall: critters.map{|critter| critter.fitness}.reduce{|m, f| m + f} / critters.size,
          best: best_critter.fitness,
          worst: worst_critter.fitness,
          best_cost: best_critter.genotype.fitness_cost,
          worst_cost: worst_critter.genotype.fitness_cost,
      }
    end

    # report on the best and worst species
    # TODO: finish report_fitness_species
    def report_fitness_species
      {
          best: nil,
          worst: nil,
      }
    end

    # Find the best fit critter
    def report_best_fit
      best_critter.phenotype.code
    end

    # cost of the best critter
    def report_best_cost
      best_critter.genotype.fitness_cost
    end
    
    # Find the worst fit critter
    def report_worst_fit
      worst_critter.phenotype.code
    end

    # cost of the worst critter
    def report_worst_cost
      worst_critter.genotype.fitness_cost
    end

    # Create a hash of critter names and fitness values
    def report_critters
      critters.inject({}){|memo, critter| memo[critter.name] = critter.fitness; memo }
    end

    #== Generate a report on the state of this population.
    #
    def report
      [
          self,
          {
              generation:         generation,
              fitness:            report_fitness,
              fitness_species:    report_fitness_species,
              best_critter:       report_best_fit,
              worst_critter:      report_worst_fit,
              best_critter_cost:  report_best_cost,
              worst_critter_cost: report_worst_cost,
              worst_critter:      report_worst_fit,
              all_critters:       report_critters,
          }
      ]
    end

    #TODO: we should probably provide a means to invalidate this cache.
    #TODO: but in most reasonable use cases this would not be called until
    #TODO: after all the critters have been created.
    def critter_hash
      @critter_hash ||= critters.inject({}){|memo, crit| memo[crit.name]=crit; memo}
    end

    # Retrive list of critters given from parameters given, names of critters.
    # Return the results in an array. Names given must exist. Can be either
    # strings or symbols or something that can be reduced to symbols, at least.
    def find_critters(*names)
      names.map{|name| critter_hash[name.to_sym]}
    end
  end

  #= Critter Reporting
  # The reporting functionality for critters are represented here,
  # since this is only tangenial to the actual functionality of
  # the critters themselves.
  class Critter
    def report_neuron_types
      {
          input:  population.input_neurons.map {|n| n.name},
          output: population.output_neurons.map{|n| n.name},
          hidden: population.hidden_neurons.map{|n| n.name}
      }
    end

    def report_genotype
      genotype.genes.map{|innov, gene| {in: gene.in_neuron, out: gene.out_neuron, innov: innov}}
    end

    def report_phenotype
      phenotype.code
    end

    def report
      {
          genotype: report_genotype,
          phenotype: report_phenotype,
          neuron_types: report_neuron_types
      }
    end
  end
end
