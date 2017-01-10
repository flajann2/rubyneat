# coding: utf-8
=begin rdoc
= RúbyNEAT Daemon Module
The purpose of this module is to provide
a command interface. It is entirely built
on Ruby objects that are safe to serialize
with Oj as JSON.

RubyNEAT Panel and any other remote system
that needs to communicat with RubyNEAT across
AMQP shall use this.

== Usage
require 'rubyneat/daemon'
include NEAT::Daemon

=end

module NEAT
  module Daemon
    COMMANDS = {
      status:  ["Fetch and return the complete state of the RubyNEAT Daemon",
                ->(pl) {
                  { neaters: Dir.glob(NEATGLOB).sort.map { |ne|
                      File.basename(ne).gsub(%r{_neat\.rb}, '')
                    },
                    neurons: NEAT::Neuron.neuron_types.map{|n| n.name }.sort,
                  }
                }],
      details: ["Fetch the details of a particular neater",
                ->(neater) {
                  begin
                    load "#{neater}_neat.rb"
                    
                  rescue => e
                    [:error, e]
                  end
                }],
      run:     ["Run a Neater",
                ->(neater) {
                  begin
                    load "#{neater}_neat.rb"
                  rescue => e
                    [:error, e]
                  end
                }],
      kill:     ["Kill a running Neater",
                ->(neater) {
                  begin
                    :niy
                  rescue => e
                    [:error, e]
                  end
                }],
      pause:     ["Pause a running Neater",
                ->(neater) {
                  begin
                    :niy
                  rescue => e
                    [:error, e]
                  end
                }],
      resume:    ["Resume a paused Neater",
                ->(neater) {
                  begin
                    :niy
                  rescue => e
                    [:error, e]
                  end
                }],
      step:     ["Step a running Neater one generation",
                ->(neater) {
                  begin
                    :niy
                  rescue => e
                    [:error, e]
                  end
                }],
      list:    ["List the requested type", ->() { :niy }],
      version: ["Get the verison of NEAT running", ->() { rubyneat_version }],
    }
    class Command
      attr_accessor :cmd
      attr_accessor :call_id
      attr_accessor :payload # specifics for the command
      attr_accessor :response # response to the command
      
      def initialize command = nil, payload = nil
        if COMMANDS.member? command
          @cmd = command
          @payload = payload
        else
          raise "Command #{command} is not defined."
        end unless command.nil?
        @call_id = SecureRandom.uuid
      end
    end
  end
end
