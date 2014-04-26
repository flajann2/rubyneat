require 'irb'
require 'irb/completion'

module RubyNEAT
  module Cli
    class Console < Thor

      desc 'console', "Starts a repl console and requires the gem"
      def console
        # TODO: maybe dynamically set it in Rakefile and then retrieve from ENV?
        # require "#{$calling_gem_name}"
        ARGV.clear
        IRB.start
      end

    end
  end
end
