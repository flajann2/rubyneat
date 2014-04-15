require 'rubyneat/cli/generate'

module RubyNEAT
  module Cli

    class List < Thor
      desc 'neaters', 'List all Neaters.'
      def neaters
        Dir.glob(NEATGLOB).sort.each do |ne|
          puts 'neat runeater ' + File.basename(ne).gsub(%r{_neat\.rb}, '')
        end
      end

      desc 'neurons', 'List all Neurons.'
      def neurons
        puts NEAT::Neuron.neuron_types.map{|n| n.name }.sort.join "\n"
      end
    end

    class Main < Thor
      class_option :verbose, type: :string, banner: '[1|2|3]', aliases: '-v'

      desc 'list <type>', 'List the requested type.'
      subcommand 'list', List

      desc 'generate <generator>', 'Generators'
      subcommand 'generate', Generate

      desc 'version', 'Display RubyNEAT version'
      def version
        puts SemVer.find.format "%M.%m.%p%s"
      end

      desc 'console', 'Run RubyNEAT interactively'
      def console
        #TODO: Finish the console
        puts "Not Implemented Yet."
      end

      desc 'runeater <neater> [<neater> <neater> ...] [OPTS]', 'Run a Neater'
      option :log, type: :string, banner: 'info|warn|debug|error'
      def runeater(*neaters)
        NEAT::controller.verbosity = options[:verbose].to_i if options[:verbose]
        eval %{$log.level = Logger::#{options[:log].upcase}} if options[:log]

        neaters.map do |neater|
          "#{neater}_neat.rb"
        end.each do |file|
          load file
        end
      end
    end
  end
end
