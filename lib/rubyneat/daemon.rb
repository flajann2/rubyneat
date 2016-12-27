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
      status: "Fetch and return the complete state of the RubyNEAT Daemon",
      run:    "Run a Neater",
      list:   "List the requested type",
      version: "Get the verison of NEAT running",
    }
    class Command
      attr_accessor :cmd
      attr_accessor :call_id
      attr_accessor :payload # specifics for the command
      attr_accessor :response # response to the command
      
      def initialize command = nil
        if COMMANDS.member? command
          @cmd = command
        else
          raise "Command #{command} is not defined."
        end unless command.nil?
        @call_id = SecureRandom.uuid
      end
    end
  end
end
