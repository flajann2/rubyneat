module RubyNEAT
  module Cli
    module Generator
      class Neater < Thor::Group
        include Thor::Actions
        argument :name, type: :string, desc: 'Name of the Neater'
        argument :description, type: :string, desc: 'Description', default: false

        desc "Generate a Neater"

        def self.source_root
          File.dirname(__FILE__) + "/templates/generate"
        end

        def create_neater_file
          @description ||= "#{name.camel_case} Neater"
          template 'neater.tt', "neater/#{name.snake}_neat.rb"
        end
      end
    end

    class Generate < Thor
      register Generator::Neater, 'neater', 'neater', 'Generates a neater'
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
