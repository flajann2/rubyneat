#!/usr/bin/env neat
require 'rubyneat/dsl'
require 'xor_lib'
=begin rdoc
= XOR Test for RubyNEAT

The XOR testis the most fundamental test given to neural networks to
see if they can handle representing the function, which usually entails
a hidden layer. RubyNEAT generates hidden layers, so this would represent
a good "First Test" of what RubyNEAT can do.

Also, we need to work out the details of the RubyNEAT UI, so this also
serves as a playground for that as well.

Here we shall treat signals <0 as a logical false, and >0 as a logical true.
+1/-1 shall represent the input nodes, and we shall have only one output node.

We shall also experiment with signal shaping so that the output node
explicitly coerces the signal to true/false.

== Notes
We shall have a callback for grabbing the data, and another for fitness
evaluation. Both shall be passed a tcnt parameter, which represents "time" 
or some other cardinal in the walk through of the data space. Fitness shall 
return something between +/-1.

There shall be also a novelty measure, as a separate parameter internal to the
Evaluator. Some sort of logic shall reside in the evaluator choose actual "fitness" 
over the fitness result vs. novelty.

=== Naming issues
For input and output neurons, the names of them shall be specified
up front. The names of neurons only need be unique on a per-critter basis. And
it makes all the sense in the world to have the IO neurons specifically named
so that linkages to the "outside world" can be maintained.

For this reason, we incorporate as a requirement names for the IO neurons.

For the bias neuron, that will have a name too, but can simply be called :bias.
=end
include NEAT::DSL

# The number of inputs to the xor function
XOR_INPUTS = 2

$log.level = Logger::INFO

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

  ## Settings
  # General
  hash_on_fitness = false
  start_population_size 200
  population_size 200
  max_generations 1000
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
  mate_only_prob 0.02 #0.7

  # Mating
  survival_threshold 0.2 # top 20% allowed to mate in a species.
  survival_mininum_per_species  6 # for small populations, we need SOMETHING to go on.

  # Fitness costs
  fitness_cost_per_neuron 0.016
  fitness_cost_per_gene   0.001

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
