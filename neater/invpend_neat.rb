#!/usr/bin/env neat
require 'rubyneat/dsl'
require 'inverted_pendulum'

include NEAT::DSL
include InvertedPendulum::DSL

=begin rdoc
=Inverted Pendulum
=end


invpend do |ipwin|
  puts "Inverted Pendulum -- use the mouse wheel to bang the cart yourself."

  c = cart do
    {
      scale: 0.20,
      ang: 80,
      xpos: 600.0,
      cartmass: 200.0, #kg
      polemass: 100.10, #kg, knobby end only
      bang: 10.0,       # acceleration on a bang event
      thrust_decay: 2.0, # thrust decay percentage per second
      window_pix_width: 1280,
      naked: true  # Naked cart, not attached to a window.
    }
  end

  show cart: c
end

define "InvPend System" do
  #-----------------------------------------------------
  #= Neuron Specifications
  inputs(
    in_cart_velocity: InputNeuron,
    in_cart_position: InputNeuron,
    in_pole_velocity: InputNeuron,
    in_pole_angle:    InputNeuron,
    bias: BiasNeuron
  )

  outputs out_bang_left: TanhNeuron, out_bang_right: TanhNeuron

  hidden tan: TanhNeuron

  #-----------------------------------------------------
  #= Settings
  # General
  hash_on_fitness false
  start_population_size 30
  population_size 30
  max_generations 10000
  max_population_history 10

  #-----------------------------------------------------
  #= Evolver probabilities and SDs
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
  end_sequence_at 200
end
