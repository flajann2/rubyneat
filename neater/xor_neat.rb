#!/usr/bin/env neat
require 'rubyneat/dsl'
require 'xor_lib'

include NEAT::DSL

#= TEST FOR RubyNEAT

# The number of inputs to the xor function
XOR_INPUTS = 3
XOR_STATES = 2 ** XOR_INPUTS
MAX_FIT    = XOR_STATES
ALMOST_FIT = XOR_STATES - 0.5

# This defines the controller
define "XOR System" do
  # Define the IO neurons
  inputs {
    cinv = Hash[(1..XOR_INPUTS).map{|i| [("i%s" % i).to_sym, InputNeuron]}]
    cinv[:bias] = BiasNeuron
    cinv
  }
  outputs out: TanhNeuron

  # Hidden neuron specification is optional. 
  # The name given here is largely meaningless, but may be useful as some sort
  # of unique flag.
  hidden tan: TanhNeuron

  ### Settings
  ## General
  hash_on_fitness false
  start_population_size 30
  population_size 30
  max_generations 10000
  max_population_history 10

  ## Evolver probabilities and SDs
  # Perturbations
  mutate_perturb_gene_weights_prob 0.10
  mutate_perturb_gene_weights_sd 0.25

  # Complete Change of weight
  mutate_change_gene_weights_prob 0.10
  mutate_change_gene_weights_sd 1.00

  # Adding new neurons and genes
  mutate_add_neuron_prob 0.05
  mutate_add_gene_prob 0.20

  # Switching genes on and off
  mutate_gene_disable_prob 0.01
  mutate_gene_reenable_prob 0.01

  interspecies_mate_rate 0.03
  mate_only_prob 0.10 #0.7

  # Mating
  survival_threshold 0.20 # top % allowed to mate in a species.
  survival_mininum_per_species  4 # for small populations, we need SOMETHING to go on.

  # Fitness costs
  fitness_cost_per_neuron 0#.00001
  fitness_cost_per_gene   0#.00001

  # Speciation
  compatibility_threshold 2.5
  disjoint_coefficient 0.6
  excess_coefficient 0.6
  weight_coefficient 0.2
  max_species 20
  dropoff_age 15
  smallest_species 5

  # Sequencing
  start_sequence_at 0
  end_sequence_at 2 ** XOR_INPUTS - 1
end

evolve do
  # This query shall return a vector result that will serve
  # as the inputs to the critter. 
  query { |seq|
    # We'll use the seq to create the xor sequences via
    # the least signficant bits.
    condition_boolean_vector (0 ... XOR_INPUTS).map{|i| (seq & (1 << i)) != 0}
  }

  # Compare the fitness of two critters. We may choose a different ordering
  # here.
  compare {|f1, f2| f2 <=> f1 }

  # Here we integrate the cost with the fitness.
  cost { |fitvec, cost|
    fit = XOR_STATES - fitvec.reduce {|a,r| a+r} - cost
    $log.debug ">>>>>>> fitvec #{fitvec} => #{fit}, cost #{cost}"
    fit
  }

  fitness { |vin, vout, seq|
    unless vout == :error
      bin = uncondition_boolean_vector vin
      bout = uncondition_boolean_vector vout
      bactual = [xor(*vin)]
      vactual = condition_boolean_vector bactual
      fit = (bout == bactual) ? 0.00 : 1.00
      #simple_fitness_error(vout, vactual.map{|f| f * 0.50 })
      bfit = (bout == bactual) ? 'T' : 'F'
      $log.debug "(%s) Fitness bin=%s, bout=%s, bactual=%s, vout=%s, fit=%6.3f, seq=%s" % [bfit,
                                                                                           bin,
                                                                                           bout,
                                                                                           bactual,
                                                                                           vout,
                                                                                           fit,
                                                                                           seq]
      fit
    else
      $log.debug "Error on #{vin} [#{seq}]"
      1.0
    end
  }

  stop_on_fitness {|fitness, c|
    puts "*** Generation Run #{c.generation_num}, best is #{fitness[:best]} ***\n\n"
    fitness[:best] >= ALMOST_FIT
  }
end

report do |rept|
  $log.info "REPORT #{rept.to_yaml}"
end

# The block here is called upon the completion of each generation
run_engine do |c|
  $log.info "******** Run of generation %s completed, history count %d ********" %
        [c.generation_num, c.population_history.size]
end
