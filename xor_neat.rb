#!/usr/bin/env neat
require 'rubyneat/dsl'
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
include DSL

# The number of inputs to the xor function
XOR_INPUTS = 2

# Basic xor function we shall evolve a net for. Only goes true
# on one and only one true input, false otherwise.
def xor(*inp)
  p = 0
  inp.each {|i| p += 1 if i > 0}
  return p == 1
end

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
  start_population_size 10
  population_size 100
  max_generations 5

  # Evolver probabilities and SDs
  mutate_perturb_gene_weights_prob 0.2
  mutate_perturb_gene_weights_sd 0.3
  mutate_change_gene_weights_prob 0.002
  mutate_change_gene_weights_sd 1.00
  
  interspecies_mate_rate 0.03
  mate_only_prob 0.7

  # Mating
  survival_threshold 0.2 # top 20% allowed to mate in a species.

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
    inp = condition_boolean_vector (0 ... XOR_INPUTS).map{|i| (seq & (1 << i)) != 0}
    $log.info "Query called with seq %s, inputs=%s" % [seq, inp]
    inp
  }

  fitness { |vin, vout, seq|
    #bin = uncondition_boolean_vector vin
    bout, = uncondition_boolean_vector vout
    actual = xor(*vin)
    #puts "Fitness called with bin=%s, bout=%s, actual=%s, seq=%s" % [bin, bout, actual, seq]
    (bout == actual) ? 1.0 : 0.0
  }
end

report do
end

# The block here is called upon the completion of each generation
run_engine do |c|
  $log.info "Run of generation %s completed, history count %d" % [c.generation_num, 
                                                             c.population_history.size]
end
