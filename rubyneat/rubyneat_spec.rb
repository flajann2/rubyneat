require 'rubyneat/rubyneat'
require 'rubyneat/dsl'

module DSLSetup
  include DSL

  # The number of inputs to the xor function
  XOR_INPUTS=2

  # Basic xor function we shall evolve a net for. Only goes true
  # on one and only one true input, false otherwise.
  def xor(*inp)
    p = 0
    inp.each {|i| p += 1 if i}
    return p == 1
  end

  # This defines the controller
  define "XOR System" do
    # Define the IO neurons
    inputs {
      cinv = Hash[(1..XOR_INPUTS).map{|i| [("i%s" % i).to_sym, InputNeuron]}]
      cinv[:bias] = BiasNeuron
      cinv
    }
    outputs out: SigmoidNeuron
    
    # Hidden neuron specification is optional. 
    # The name given here is largely meaningless, but may be useful as some sort
    # of unique flag.
    hidden sig: SigmoidNeuron
    
    # Settings
    hash_on_fitness = false
    start_population_size 10
    population_size 100
    max_generations 50

    start_sequence_at 0
    end_sequence_at 10
  end
  
  evolve do
    query { |seq|
      puts "Query called with seq %s" % seq
    }
    
    fitness { |vin, vout, seq|
      puts "Fitness called with vin=%s, vout=%s, seq=%s" % [vin, vout, seq]
      return 0.0
    }
  end

  report do
  end

  # The block here is called upon the completion of each generation
  run_engine do |c|
    puts "Run of generation %s completed, history count %d" % [c.generation_num, 
                                                               c.population_history.size]
  end
end


class GraphTest
  include NEAT::Graph
  def initialize(i)
    @i = i
  end
  
  def to_s
    "node[%s]" % @i
  end
end


def pgraph(a, mess)
  puts "\n\n" + mess
  a.each{|g|
    puts "  %s ->" % g
    g.inputs.each{|h|
      puts "    %s" % h
    }
  }
end

def create_nodes(n)
  nodes = (1..n).map{ |i| GraphTest.new i }
  n.times {|i|
    nodes[i].clear_graph
    i.times {|j| nodes[i] << nodes[j] }}
  nodes
end

describe NEAT do
  describe "::random_name_generator" do
    it "returns a random string" do
      s = NEAT::random_name_generator
      s.size.should > 0
    end
  end

  describe "::Graph::DependencyResolver" do

    nodes_ff = create_nodes 5
    pgraph nodes_ff, "Feed Forward"

    it "resolves depedencies" do
      depres = NEAT::Graph::DependencyResolver.new([nodes_ff.last])
      dr, cl = depres.resolve

      puts "\n**** dr=%s\n**** cl=%s" % [dr, cl]

      dr.size.should == 5
      cl.nil?.should == true
    end

    # we add a circular dependency between the first and last.
    nodes_c = create_nodes 5
    nodes_c.first << nodes_c.last
    pgraph nodes_c, "Circluar Dependency"

    it "detects circular dependencies" do
      depres = NEAT::Graph::DependencyResolver.new([nodes_c.last])
      dr, cl = depres.resolve

      puts "\nxxxx dr=%s\nxxxx cl=%s" % [dr, cl]

      dr.size.should == 5
      cl.nil?.should_not == true
    end
  end
end
