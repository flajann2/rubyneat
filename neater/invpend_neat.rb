#!/usr/bin/env neat
require 'rubyneat/dsl'
require 'inverted_pendulum'

include NEAT::DSL
include InvertedPendulum::DSL

=begin rdoc
=Inverted Pendulum
=end


invpend do |ipwin|
  puts "Inverted Pendulum"
  show
end
