require 'rubyneat/rubyneat'

=begin rdoc
= RubyNEAT DSL
DSL is a doman-specific language for RubyNEAT to allow you to configure the NEAT engine
for various evolutionary projects.
=end
module NEAT
  module DSL
    include NEAT
    include NEAT::BasicNeuronTypes

    # RNDSL -- Define defines the parameters to the controller.
    def define(name = NEAT.random_name_generator, &block)
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
     NEAT::controller.neural_#{iometh} = if neui.kind_of? Hash
                                           neui
                                         else
                                           Hash[neui.map{|n| [NEAT::random_name_generator, n]}]
                                         end
   end]
      end
      block.(NEAT::controller)
    end

    # DSL -- Run evolution
    def evolve(&block)
      # Query function is called with the sequence (time evalution) number,
      # and returns an array or hash of parameters that will be given
      # to the input nodes. In the case of hash, the keys in the hash
      # shall correspond to the names given to the input neurons.
      def query(&block)
        NEAT::controller.query_func = block
      end

      # fitness function calls the block with 2 vectors or two hashes, input and output
      # vectors of the critter being evaluated for fitness, as well as a sequence
      # number that can be used to index what the actual output should be.
      # |vin, vout, seq|
      def fitness(&block)
        NEAT::controller.fitness_func = block
      end

      # Helper function to
      # Condition boolean vectors to be +1 if true, -1 if false
      def condition_boolean_vector(vec)
        vec.map{|b| b ? 1 : -1}
      end

      # Helper function to
      # Uncondition boolean vectors to be +1 if true, -1 if false
      def uncondition_boolean_vector(vec)
        vec.map{|o| o > 0.0 ? true : false}
      end

      block.(NEAT::controller)
    end

    # Report on evaluations
    def report(&block)
      NEAT::controller.report_hook = block
    end

    # Run the engine. The block is called on each generation.
    def run_engine(&block)
      NEAT::controller.end_run_func = block
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

# FIXME: This needs to better specified for cases in which there may be multiple
# Controllers.
require 'rubyneat/default_neat'

BEGIN {
  puts "RN::DSL evaluation of %s" % $0
}

END {
  puts "RN::DSL Completed."
  c = NEAT::controller
  puts "parameters = %s" % c.parms
  print "query = " 
  p  c.query_func
  print "fitness = " 
  p c.fitness_func
}
