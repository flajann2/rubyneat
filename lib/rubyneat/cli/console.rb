require 'irb'
require 'irb/completion'

module RubyNEAT
  module Cli
    class Console < Thor

      class << self
        def default_command
          # TODO: maybe dynamically set it in Rakefile and then retrieve from ENV?
          # require "#{$calling_gem_name}"
          ARGV.clear
          IRB.start
        end
        alias_method :default_task, :default_command
      end
    end
  end
end
