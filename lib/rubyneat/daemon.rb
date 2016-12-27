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
      
    }
    class Command
      attr_accessor :cmd
      attr_accessor :payload # specifics for the command
      attr_accessor :response # response to the command
    end
  end
end
