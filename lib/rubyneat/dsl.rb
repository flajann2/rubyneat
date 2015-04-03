require_relative 'rubyneat'

=begin rdoc
= RubyNEAT DSL
DSL is a domain-specific language for RubyNEAT to allow you to
configure the NEAT engine for various evolutionary projects.
=end
module NEAT
  module DSL
    include NEAT
    include NEAT::BasicNeuronTypes
    include Math

    class Composition < NeatOb
      # Class map of named input and output neurons (each critter will have
      # instantiations of these) name: InputNeuralClass (usually InputNeuron)
      attr_neat :neural_inputs,  default: nil
      attr_neat :neural_outputs, default: nil
      attr_neat :neural_hidden,  default: nil

      def initialize(name = :main, &block)
        super(nil, name, controllerfrei: true)
        [
            :inputs,
            :outputs,
            :hidden  # we really don't care about mapping hidden neurons, but we'll ignore them later.
        ].each do |iometh|
          instance_eval %Q[
             def #{iometh}(nodes = nil, &block)
               neui = unless nodes.nil?
                        nodes
                      else
                        block.()
                      end
               self.neural_#{iometh} = if neui.kind_of? Hash
                                                     neui
                                                   else
                                                     Hash[neui.map{|n| [NEAT::random_name_generator, n]}]
                                                   end
             end]
        end
        instance_eval &block
      end
    end

    # Genotype composition within our Critter embodied.
    class TweannComposition < Composition

    end

    class HyperComposition < Composition
      attr_neat :hyper, default: nil

      class CPPN < Composition
        attr_neat :tuple_factor, default: 2
        attr_neat :depth_factor, default: 8
        attr_neat :scale_factor, default: 4.0

        # Dimensionality of the CPPN space
        def tuple(t)
          self.tuple_factor = t
        end

        # Maximum depth of the k-tree
        def depth(d)
          self.depth_factor = d
        end

        # Scale the weights by +/- s
        def scale(s)
          self.scale_factor = s
        end
      end

      def hyper(&block)
        self.hyper = CPPN.new(&block)
      end
    end

    class Connections < NeatOb
      attr_neat :conn, default: {}

      def initialize(corpus, &block)
        super(nil, nil, controllerfrei: true)
        corpus.compositions.each do |name, composition|
          create_method(name) do |**cmap|
              conn[name] = cmap
          end
        end
        instance_eval(&block)
      end

      def inputs(**cmap, &block)
        conn[:input] = block_given? ? block.() : cmap
      end

      def outputs(*olist, &block)
        conn[:output] = block_given? ? block.() : olist
      end
    end

    class Corpus < NeatOb
      attr_neat :nexion, default: nil #connections
      attr_neat :compositions, default: {}

      def initialize(&block)
        instance_eval &block
      end

      def tweann(name, hyper: false, &block)
        self.compositions[name] = (hyper ? HyperComposition
                                         : TweannComposition).new(name, &block)
      end

      def connections (&block)
        self.nexion = Connections.new(self, &block)
      end
    end

    # DSL -- Define defines the parameters to the controller.
    def define(name = NEAT.random_name_generator, &block)
      def compose(&block)
        NEAT::controller.corpus = Corpus.new(&block)
      end

      block.(NEAT::controller)
    end

    # DSL -- Run evolution
    def evolve(&block)
      # Query function is called with the sequence (time evolution) number,
      # and returns an array or hash of parameters that will be given
      # to the input nodes. In the case of hash, the keys in the hash
      # shall correspond to the names given to the input neurons.
      def query(&block)
        NEAT::controller.query_func_add  &block
      end

      def recurrence(&block)
        NEAT::controller.recurrence_func_set &block
      end

      # fitness function calls the block with 2 vectors or two hashes, input and output
      # vectors of the critter being evaluated for fitness, as well as a sequence
      # number that can be used to index what the actual output should be.
      # |vin, vout, seq|
      def fitness(&block)
        NEAT::controller.fitness_func_set &block
      end

      # Fitness ordering -- given 2 fitness numbers,
      # use the <=> to compare them (or the equivalent, following
      # the +1, 0, -1 that is in the sense of <=>)
      def compare(&block)
        NEAT::controller.compare_func_set &block
      end

      # Calculation to add the cost to the fitness, resulting in a fitness
      # that incorporates the cost for sorting purposes.
      def cost(&block)
        NEAT::controller.cost_func_set &block
      end

      # Stop the progression once the fitness criteria is reached
      # for the most fit critter. We allow more than one stop
      # function here.
      def stop_on_fitness(&block)
        NEAT::controller.stop_on_fit_func_add &block
      end

      # Helper function to
      # Condition boolean vectors to be +1 if true, -1 if false (0 if sigmoid)
      def condition_boolean_vector(vec, sig = :tanh)
        vec.map{|b| b ? 1 : ((sig == :sigmoid) ? 0 : -1)}
      end

      # Helper function to
      # Uncondition boolean vectors to be +1 if true, -1 if false
      # FIXME we need a better discrimination function
      def uncondition_boolean_vector(vec, sig = :tanh)
        vec.map{|o| o > ((sig == :sigmoid) ? 0.5 : 0) ? true : false}
      end

      # Helper function to do a simple fitness calculation
      # on the basis of the sum of the square of the diffences
      # of the element in the two vectors.
      def simple_fitness_error(v1, v2)
        sqrt v1.zip(v2).map{|a, b| (a - b) ** 2.0}.reduce{|m, c| m + c}
      end

      block.(NEAT::controller)
    end

    # Report on evaluations
    def report(&block)
      NEAT::controller.report_add &block
    end

    # Run the engine. The block is called on each generation.
    def run_engine(&block)
      NEAT::controller.end_run_add &block
      NEAT::controller.run
    end

    # This is used to handle the details of our DSL.
    def method_missing(m, *args, &block)
      # we want to catch parameters settings here.
      if NEAT::controller.parms.respond_to? (assignment = (m.to_s + '=').to_sym)
        raise NeatException.new("Missing value(s) to %s" % m) if args.empty?
        val = (args.size == 1) ? args[0] : args
        $log.debug { "Caught method %s with parameter of %s" % [assignment, val] }
        NEAT::controller.parms.send(assignment, val)
      else
        super
      end
    end
  end
end

# FIXME: This needs to better specified for cases in which
# FIXME: there may be multiple Controllers.
require 'rubyneat/default_neat'
