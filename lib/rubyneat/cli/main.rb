require 'rubyneat/cli'

module RubyNEAT
  module Cli

    class List < Thor
      desc 'neaters', 'List all Neaters.'
      def neaters
        Dir.glob(NEATGLOB).sort.each do |ne|
          puts 'neat run ' + File.basename(ne).gsub(%r{_neat\.rb}, '')
        end
      end

      desc 'neurons', 'List all Neurons by their full class names.'
      def neurons
        puts NEAT::Neuron.neuron_types.map{|n| n.name }.sort.join "\n"
      end

      desc 'types', 'List all Neurons by their type names.'
      def types
        puts NEAT::Neuron.neuron_types.map{|n| n.type_name }.sort.join "\n"
        #puts NEAT::Neuron.neuron_type_names.sort.join "\n"
      end

    end

    class NewMain < Thor
      register Generator::NewProject, 'new', 'new', 'Generates a new NEAT Project'
    end

    class Main < Thor
      class_option :verbose, type: :numeric, banner: '[1|2|3]', aliases: '-v'

      desc 'list <type>', 'List the requested type.'
      subcommand 'list', List

      desc 'generate <generator>', 'Generators'
      subcommand 'generate', Generate

      desc 'version', 'Display RubyNEAT version'
      def version
        puts SemVer.find.format "%M.%m.%p%s"
      end

      desc 'console', 'Run RubyNEAT interactively'
      subcommand 'console', Console

      desc 'run <neater> [<neater> <neater> ...] [OPTS]', 'Run a Neater'
      option :log, type: :string, banner: 'info|warn|debug|error'
      def neater(*neaters)
        NEAT::controller.verbosity = options[:verbose].to_i if options[:verbose]
        eval %{$log.level = Logger::#{options[:log].upcase}} if options[:log]

        neaters.map do |neater|
          "#{neater}_neat.rb"
        end.each do |file|
          NEAT::controller.neater = file
          load file
        end
      end
      map run: :neater

    end
  end
end
