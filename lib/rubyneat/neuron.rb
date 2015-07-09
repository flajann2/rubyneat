# -*- coding: utf-8 -*-
require 'rubyneat'
require_relative 'graph'

=begin rdoc
= Neuron Types

We create all the neuron types for this system here.

=end
module NEAT
  module SExpressions
    def s(type, *children)
      Parser::AST::Node.new(type, children)
    end
  end

  #= Neuron -- Basis of all Neat Neuron types.
  # Normally contains primatives which aids in its
  # own expression, but the details of this remains to be worked out.
  class Neuron < NeatOb
    include Math
    include Graph
    include SExpressions

    # Genotype to which we belong
    attr_reader :genotype
    attr_accessor :trait

    # Hyper coordinates (Vector)
    attr_neat :hccoord, default: nil

    # (assigned by wire!) Heirarchy number in the Genome / Critter
    # We need this to assure we add genes in the proper order.
    # This will be recalculated every time a new neuron is added.
    attr_accessor :heirarchy_number

    # This is true if this is an output neuron.
    attr_accessor :output

    # List of neuron types defined.
    @@neuron_types = []

    # Type names must always be unique for Neurons.
    # TODO: Enforce uniqueness in neural type names
    def self.type_name
      @type_name ||= self.to_s.split('::').last.split('Neuron').first.downcase
    end

    def type_name
      self.class.type_name
    end

    # Class is is of Input type?
    def self.input? ; false ; end
    def input? ; self.class.input? ; end

    def self.bias? ; false ; end
    def bias? ; self.class.bias? ; end
    def hyper? ; not hccoord.nil? ; end

    # Instantiation is of output type?
    def output? ; !!@output ; end

    def self.inherited(clazz)
      @@neuron_types << clazz
    end

    # List of distinct neuron types (classes)
    def self.neuron_types; @@neuron_types ; end

    # Function may be implemented by subclasses for phenotype
    # generation. Basically, an instance is passed to this function
    # and it will add a function to sum all inputs
    # and a apply an operator to the sum.
    def express(instance)
      instance.instance_eval Unparser.unparse express_ast
    end

    # Function must be implemented by subclasses for phenotype
    # generation.
    #
    # This will generate Abstract Syntax Tree code so that the 
    # TWEANN may be treated as a fully independent program apart
    # from the RubyNEAT infrastructure.
    #
    # The AST code generated here must be compatable with the
    # unparser gem. Other lanaguages that will want to unparse
    # this same code may have to tweak this representation a bit
    # as need be, but that aspect is beyond our scope here.
    def express_ast
      raise NeatException.new "express_ast() or express() must be implemented by #{self.class}."
    end
  end


=begin rdoc
= Basic Neuron Types

Basically, the neurons (nodes) will have an instantiation to represent their places in the
neural net, and way to spin up the phenotypic representation.

The basic types to RubyNEAT are represented here.
=end
  module BasicNeuronTypes
    #= Special class of Neuron that takes input from the "real world"
    # Name of this neuron equates to the parameter name of the input.
    #
    # All inputs are handled with this neuron. This type of
    # neuron only has one input -- from the outside world.
    class InputNeuron < NEAT::Neuron
      def self.input? ; true ; end

      # Takes a single input and passes it as is.
      def express_ast
        s(:def, @name,
          s(:args,
            s(:arg, :input)),
            s(:lvar, :input))
      end
    end

    #= Special class of neuron that provides a bias signal.
    # FIXME: The bias value is not behaving as expected because
    # FIXME: the instance is not the neuron, but the phenotype.
    class BiasNeuron < InputNeuron
      def self.bias? ; true ; end
      attr_accessor :neu_bias

      def initialize(c=nil, n=nil)
        super
        @neu_bias = 1.00
      end

      # Just provides a bias signal
      # FIXME: we had to hard-code the value here for now. Not a biggie,
      # FIXME: but really should be @neu_bias

      def express_ast
        s(:def, @name,
          s(:args),
          s(:float, @neu_bias))
      end
    end

    # The most commonly-used neuron for the hidden and output layers.
    # We use the Logistic Function for the Sigmoid.
    class SigmoidNeuron < Neuron
      # create a function on the instance with our name
      # that sums all inputs and produce a sigmoid output (using tanh)
      def express(instance)
        instance.define_singleton_method(@name) {|*inputs|
          1.0 / (1.0 + exp(-4.9 * inputs.reduce {|p, q| p + q}))
        }
      end
    end

    # An alternative Sigmoid Function, but ranges -1 to +1
    class TanhNeuron < Neuron
      # create a function on the instance with our name
      # that sums all inputs and produce a sigmoid output (using tanh)
      def express(instance)
        instance.define_singleton_method(@name) {|*inputs|
          tanh(2.4 * inputs.reduce {|p, q| p + q})
        }
      end
    end

    # Sin function (CPPN) -- adjusted to have its +1 and -1 near TanhNeuron
    class SineNeuron < Neuron
      # create a function on the instance with our name
      # that sums all inputs and produce a sigmoid output (using tanh)
      def express(instance)
        instance.define_singleton_method(@name) {|*inputs|
          sin(1.6 * inputs.reduce {|p, q| p + q})
        }
      end
    end

    # Cosine function (CPPN) -- adjusted to have its +1 and -1 near TanhNeuron
    class CosineNeuron < Neuron
      # create a function on the instance with our name
      # that sums all inputs and produce a sigmoid output (using tanh)
      def express(instance)
        instance.define_singleton_method(@name) {|*inputs|
          cos(1.6 * inputs.reduce {|p, q| p + q})
        }
      end
    end

    # Linear function (CPPN) -- simply add up all the inputs.
    class LinearNeuron < Neuron
      # create a function on the instance with our name
      # that sums all inputs only.
      def express(instance)
        instance.define_singleton_method(@name) {|*inputs|
          inputs.reduce {|p, q| p + q}
        }
      end
    end

    # Multiplier function (CPPN) -- simply multiply all the inputs.
    class MulNeuron < Neuron
      # create a function on the instance with our name
      # that multiplies all inputs only.
      def express(instance)
        instance.define_singleton_method(@name) {|*inputs|
          inputs.reduce {|p, q| p * q}
        }
      end
    end

    # Heaviside (CPPN)
    class HeavisideNeuron < Neuron
      # Peform the Heaviside function on the summation
      # of the inputs.
      def express(instance)
        instance.define_singleton_method(@name) {|*inputs|
          (inputs.reduce {|p, q| p + q} >= 0.0) ? 1.0 : 0.0
        }
      end
    end

    # Sign (CPPN)
    class SignNeuron < Neuron
      # Perform the Sign function on the summation
      # of the inputs. Note that rarely will the
      # inputs be exactly zero except in some specific
      # circumstances.
      def express(instance)
        instance.define_singleton_method(@name) {|*inputs|
          (inputs.reduce {|p, q| p + q} >= 0) <=> 0.0
        }
      end
    end

    # Gaussian function (CPPN) -- SD 1 of inputs
    class GaussianNeuron < Neuron
      # create a function on the instance with our name
      # that sums all inputs and produce a gaussian of
      # standard deviation of 1.
      def express(instance)
        instance.define_singleton_method(@name) { |*inputs|
          a = 1.0 #height
          b = 0.0 #center
          c = 1.0 #SD
          d = 0.0 #lowest y point
          x = inputs.reduce {|p, q| p + q}
          a * exp(-(x - b)**2.0 / 2*c**2.0) + d
        }
      end
    end
  end
end
