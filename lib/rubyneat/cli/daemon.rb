module NEAT
  module Cli
    class Daemon < Thor
      class << self
        def default_command
        end
        alias_method :default_task, :default_command
      end
    end
  end
end
