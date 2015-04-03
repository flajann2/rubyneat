require 'rubyneat'

module NEAT
  # General graph representation
  # (mainly used for Neurons, but could be used
  # for other structures.)
  #
  # This is a mixin for Neuron and whatever else you'd like.
  # the contained class is for evaluation, and may be instantiated separately.
  module Graph
    class GraphException < Exception
    end

    # clear and initialize the graph.
    def clear_graph
      @g_inputs = []
    end

    def << (input)
      @g_inputs << input
      self
    end

    # Add a single input
    def add (input)
      @g_inputs << input
    end

    # Get list of inputs
    def inputs
      raise GraphException.new "Graph Failure -- input is nil" if @g_inputs.nil?
      @g_inputs
    end

    # Create an instantiation of this and pass it a list of nodes to resolve.
    class DependencyResolver < NeatOb

      # Given a list of output nodes, we shall work backwards
      # from them to resolve their dependencies.
      def initialize(outputs, &block)
        @outputs = outputs
        super
        block.(self) unless block.nil?
      end

      # Create a DependencyResolver from either
      # an array of outputs or a parameter list of outputs.
      def self.[](*outs)
        outs = outs.first if outs.first.kind_of? Array
        DependencyResolver.new outs
      end


      # Resolve dependencies, and return [dependency_list, circular_ref_node_list]
      # Note that circular_ref_node_list shall be nil if there are no dependencies!
      def resolve
        @resolved = []
        @unresolved = []
        @circular = []
        @outputs.each do |onode|
          rdep onode
        end
        [@resolved, @circular.empty? ? nil : @circular]
      end

      # Throw an exception if dependencies are found.
      # We only return the dependency list since we throw an exception on circular
      # dependencies.
      def resolve!
        dl, cl = resolve
        raise GraphException("Circular Dependency Detected: %s" % cl) unless cl.nil?
        dl
      end

      private
      # recursive resolution of nodes
      def rdep(node)
        @unresolved << node
        node.inputs.each { |inode|
          if not @resolved.member? inode
            unless @unresolved.member? inode
              rdep inode
            else
              # we found a circular reference.
              @circular << inode
              #log.warn "Dependency found: %s" % inode
            end
          end
        }
        @resolved << node
        @unresolved.delete node
      end
    end
  end
end
