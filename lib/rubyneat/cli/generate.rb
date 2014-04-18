module RubyNEAT
  module Cli
    module Generator
      module GenHelpers
        def source_root
          File.dirname(__FILE__) + "/templates/generate"
        end
      end

      class NewProject < Thor::Group
        include Thor::Actions
        extend GenHelpers
        desc "Generate a new NEAT Project."

        argument :name, type: :string, desc: 'Name of the NEAT project'


        def create_project_directory
          empty_directory name.snake
        end

        def create_project_directories
          inside name.snake do
            %w{neater lib config tmp log}.
            each {|dir| empty_directory dir}
          end
        end

        def create_project_root_files
          %w{Gemfile README.md}.
            map{ |pfile| ["#{pfile}.tt", "#{pfile}"] }.
            each{ |source, destination| template source, destination }
        end
      end

      class Neater < Thor::Group
        include Thor::Actions
        extend GenHelpers
        desc "Generate a Neater"

        argument :name, type: :string, desc: 'Name of the Neater'
        argument :inputs, type: :numeric, desc: 'Number of Input neurons'
        argument :outputs, type: :numeric, desc: 'Number of Output neurons'
        argument :itype, type: :string, desc: 'Input neuron type', default: 'input'
        argument :btype, type: :string, desc: 'Bias neuron type', default: 'bias'
        argument :htypes, type: :array, desc: 'Hidden neuron types', default: ['tanh']
        argument :otype, type: :string, desc: 'Output neuron type', default: 'tanh'
        argument :description, type: :string, desc: 'Description', default: false

        def create_neater_file
          @description ||= "#{name.camel_case} Neater"
          template 'neater.tt', "neater/#{name.snake}_neat.rb"
        end

        def create_gem_file

        end
      end
    end

    class Generate < Thor
      register Generator::Neater, 'neater', 'neater', 'Generates a neater'
      register Generator::NewProject, 'new', 'new', 'Generates a new NEAT project'
    end
  end
end

class String
  def camel_case
    return self if self !~ /_| / && self =~ /[A-Z]+.*/
    split(/_| /).map{|e| e.capitalize}.join
  end

  def camel_case_lower
    self.split(/_| /).inject([]){ |buffer,e| buffer.push(buffer.empty? ? e : e.capitalize) }.join
  end

  def snake
    self.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        tr(' ', '_').
        downcase
  end
end
