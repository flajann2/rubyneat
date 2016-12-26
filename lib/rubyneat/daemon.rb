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
  end
end
