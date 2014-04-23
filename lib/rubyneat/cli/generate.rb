require 'ostruct'

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
        attr_accessor :ruby

        def create_project_directory
          empty_directory name.snake
        end

        def create_project_directories
          inside name.snake do
            %w{neater lib config tmp log bin}.
            each {|dir| empty_directory dir}
          end
        end

        def create_project_root_files
          @ruby = OpenStruct.new version: RUBY_VERSION,
                                 engine: RUBY_ENGINE,
                                 platform: RUBY_PLATFORM
          tcopy %w{Gemfile README.md}.
                  map{ |pfile| [pfile, "#{name.snake}/#{pfile}"] }
        end

        def create_project_bin_files
          tcopy %w{ neat }.
                  map{ |pfile| ["bin/#{pfile}", "#{name.snake}/bin/#{pfile}"] }
        end

        private
        def tcopy(from_to_list)
          from_to_list.each{ |from, to| template from, to }
        end
      end

      class Neater < Thor::Group
        include Thor::Actions
        extend GenHelpers
        desc "Generate a Neater"

        argument :name, type: :string, desc: 'Name of the Neater'
        argument :nparams, type: :hash, desc: 'Neuron Parameters', default: {}

        attr_accessor :description, :inputs, :outputs, :hidden, :bias

        def create_neater_file
          setup_neuron_parameters
          @description ||= "#{name.camel_case} Neater"
          template 'neater', "neater/#{name.snake}_neat.rb"
        end

        private
        # We need to create the Input Neurons (including the bias neuron),
        # the Output Neurons, and the Hidden neurons.
        # attr:name
        # attr:n1:t1,n2:t2,...
        def setup_neuron_parameters
          params = {
                      inputs:      {in1: 'input', in2: 'input'},
                      outputs:     {out: 'tanh'},
                      hidden:      {tanh: nil},
                      bias:        'bias',
                      description: 'Neater scaffold'
                  }.merge(nparams.inject({}) { |memo, (k,v)|
                      memo[k.to_sym] = Hash[v.split(',').map{|q| q.split(':') }].
                        inject({}) {|mmemo, (kk, vv)| mmemo[kk.to_sym] = vv; mmemo}
                      memo
                    })
          puts params
          params.each do |attr, o|
            instance_variable_set("@#{attr}", case attr
                                                when :inputs, :outputs
                                                  o.inject({}){|memo, (ky, vl)|
                                                    memo[ky] = unless vl.nil?
                                                                vl.camel_case
                                                              else
                                                                case attr
                                                                  when :inputs; 'Input'
                                                                  when :outputs; 'Output'
                                                                end
                                                              end + 'Neuron'
                                                    memo
                                                  }
                                                when :bias
                                                  unless o.nil?
                                                    o.camel_case
                                                  else
                                                    'Bias'
                                                  end + 'Neuron'
                                                when :hidden
                                                  o.map{|hk, ignore| hk.to_s.camel_case + 'Neuron' }
                                                when :description; o.keys.first
                                                else o
                                              end)
            puts attr
          end
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
