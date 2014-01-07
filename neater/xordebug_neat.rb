#!/usr/bin/env neat
require 'rubyneat/dsl'
require 'xor_lib'

include NEAT::DSL

#= DEBUGGING FOR RubyNEAT

# The number of inputs to the xor function
XOR_INPUTS = 2

$log.level = Logger::DEBUG

# This defines the controller
define "XOR System" do
  # Define the IO neurons
  inputs {
    cinv = Hash[(1..XOR_INPUTS).map{|i| [("i%s" % i).to_sym, InputNeuron]}]
    cinv[:bias] = BiasNeuron
    cinv
  }
  outputs out: SigmoidNeuron

  # Hidden neuron specification is optional. 
  # The name given here is largely meaningless, but may be useful as some sort
  # of unique flag.
  hidden sig: SigmoidNeuron

  ### Settings
  ## General
  hash_on_fitness = false
  start_population_size 10
  population_size 10
  max_generations 100
  max_population_history 10

  ## Evolver probabilities and SDs
  # Perturbations
  mutate_perturb_gene_weights_prob 0.05
  mutate_perturb_gene_weights_sd 0.30

  # Complete Change of weight
  mutate_change_gene_weights_prob 0.01
  mutate_change_gene_weights_sd 2.0

  # Adding new neurons and genes
  mutate_add_neuron_prob 0.1
  mutate_add_gene_prob 0.1

  interspecies_mate_rate 0.03
  mate_only_prob 0.10 #0.7

  # Mating
  survival_threshold 0.2 # top 20% allowed to mate in a species.

  # Fitness costs
  fitness_cost_per_neuron 0.0016
  fitness_cost_per_gene   0.0001

  # Speciation
  compatibility_threshold 4.0
  disjoint_coefficient 0.6
  excess_coefficient 0.6
  weight_coefficient 0.2
  max_species 50
  dropoff_age 15

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

  fitness { |vin, vout, seq|
    bin = uncondition_boolean_vector vin
    bout = uncondition_boolean_vector vout
    bactual = [xor(*vin)]
    vactual = condition_boolean_vector bactual
    fit = 2.00 - simple_fitness_error(vout, vactual)
    bfit = (bout == bactual) ? 'T' : 'F'
    $log.debug "(%s) Fitness bin=%s, bout=%s, bactual=%s, vout=%s, fit=%5.2f, seq=%s" % [bfit,
                                                                                      bin,
                                                                                      bout,
                                                                                      bactual,
                                                                                      vout,
                                                                                      fit,
                                                                                      seq]
    fit
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
