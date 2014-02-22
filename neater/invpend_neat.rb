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
