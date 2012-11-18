require 'distribution'
require 'yaml'
require 'pp'
require 'logger'
require 'stringio'

=begin rdoc
= RubyNEAT -- a Ruby Implementation of the NeuroEvolution by Augmented Topologies.

The RubyNEAT system incorporates the basis of the NEAT alorithm. Flexibility
is the key here, allowing RubyNEAT to be leverage in a varitety of applications.

=== Requirements
We make no effort to support Ruby versions less than 1.9.2. I know this will
be a problem to some, but you are strongly urgerd to upgrade.

=end

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG

=begin rdoc
= NEAT -- Module for RubyNEAT.

== Synopsis
We have a Population of Critters, and each Critter
represents a network of Neurons and a connection list specifying
how those Neurons are connected.

Each Neuron has an inplicit genotype and phenotype component. Neurons,
from the Ruby persoective, contain their own code to produce their own
phenotypes. 

There are input Neurons and output Neurons. The input Neurons are special, as
they do not contain any input from other nodes, but serve as interfaces
from the "real world". Thier range of inputs are open, and it shall be up to
the input Neuron's phenotype generators to condition those inputs, if need be,
to someething more suiable for the neural network.

== Issues
=== Multicore / Cloud Computing
Some thought needs to be given to how to make this anenable to multiple
processes so that we can leverage the power of multicore systems as well
as multiple computers in the Cloud, etc.

Our initial inclination  is to put all of that functionality in the Conroller.
=end
module NEAT
  @rng_count = 0
  @rng_names = %w{aaa bee cex dee flo kis lee mor cie lou gir sex quo sam lac hin pee  
                  cur set sew flat nac zac pae por lie lox pox nez fez wib poo sho
                  nuz tux que bsh shi her him can muk fuk kit kat uno dos ant mic
                  aa be nz oo py tt my of ze mu pi zz qu fl tr as sd fg gh hj bc
                  lion tame monk busy honk tape slap zonk funk tear flip shop soap
                  quay mony stir moot shoo slim fate trat beep kook love hate 
                  mire hair lips funk open shut case lace joop lute doze fuzz
                  mean nice soil vote kick apes snak huge sine pine gray nook fool
                  woot hail smel tell jell suut gage phat}
  def self.random_name_generator
    @rng_count += 1
    s = ""
    3.times do
      s += "#{@rng_names[rand @rng_names.size]}_" 
    end
    s += @rng_count.to_s
  end

  # Name of the stimulus method in NEAT::Critter::Phenotype to use
  # for the singleton method expression of the critter.
  STIMULUS = :stimulate

  # Mixin for new innovation numbers.
  def self.new_innovation; @controller.new_innovation; end

  # Mixin for the gaussian object.
  def self.gaussian ; @controller.gaussian; end

  # PrettyPrint to log.debug
  def self.dpp ob
    sio = StringIO.new
    PP::pp ob, sio
    sio.lines.each do |line|
      $log.debug line
    end
  end

  # Basis of all NEAT objects
  class NeatOb
    # Designation of this particular object instance
    attr_reader :name

    # Who's your daddy?
    attr_reader :controller

    def log ; $log ; end

    # Initializer for all NEAT objects. Requires that
    # the controller object is specified for all classes
    # with the exception of the Controller itself or the
    # Controller's NeatSettings.
    def initialize(controller = nil, name = nil)
      @name = unless name.nil?
                name
              else
                NEAT::random_name_generator
              end
      unless controller.nil?
        @controller = controller
      else
        raise NeatException.new "Controller Needed!" unless self.is_a?(Controller) or                                                             self.is_a?(Controller::NeatSettings)
        @controller = self unless self.is_a? Controller::NeatSettings
      end
    end

    def to_s
      "%s<%s>" % [self.class, self.name]
    end
  end

  class NeatException < Exception
  end

  # General graph representation
  # (mainly used for Neurons, but could be used
  # for other structures.)
  #
  # This is a mixin for Neuron and whatever else you'd like.
  # the contained class is for evaluation, and may be instaintiated seperately.
  module Graph
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
      @g_inputs
    end

    # Create an instantiation of this and pass it a list of nodes to resolve.
    class DependencyResolver < NeatOb

      # Given a list of output nodes, we shall work backwards
      # from them to resolve their dependencies.
      def initialize(outputs)
        @outputs = outputs
        super
      end
      
      # Create a DepedencyResolver from either
      # an array of outputs or a parmeter list of outputs.
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
        raise NeatException("Circular Dependency Detected: %s" % cl) unless cl.nil?
        dl
      end

      private
      # resursive resolution of nodes
      def rdep(node)
        @unresolved << node
        node.inputs.each { |inode|
          if not @resolved.member? inode
            unless @unresolved.member? inode
              rdep inode
            else
              # we found a circular reference.
              @circular << inode
              log.warn "Dependency found: %s" % inode
            end
          end
        }
        @resolved << node
        @unresolved.delete node
      end
    end
  end

  #= Base class of operators in RubyNEAT,
  # Such as Evolver, etc.
  class Operator < NeatOb
  end

  #= Traits
  # A Trait is a group of parameters that can be expressed     
  # as a group more than one time.  Traits save a genetic      
  # algorithm from having to search vast parameter landscapes  
  # on every node.  Instead, each node can simply point to a trait 
  # and those traits can evolve on their own. (Taken from the C version of NEAT)
  #
  # Since we wish to allow for different classes of Neurons, this trait idea is
  # super, since all we need to do is have a different trait species for the
  # different node types.
  class Trait < NeatOb
  end

  require 'rubyneat/critter'
  require 'rubyneat/neuron'
  require 'rubyneat/population'
  require 'rubyneat/evolver'
  require 'rubyneat/expressor'
  require 'rubyneat/evaluator'

  #= Controller for all operations of RubyNEAT
  # This object contails all the specifications and details for
  # evolving and evaluation of the RubyNEAT system.  It is 
  # a type of "World", if you will, for the entntire enterprise.
  #
  # Your application shall only have one Controller. 
  class Controller < NeatOb
    # global innovation number
    attr_reader :glob_innov_num

    # current sequence number being evaluated
    attr_reader :seq_num

    # Current generation count
    attr_reader :generation_num

    # catalog of neurons classes to use { weight => nclass, ... }
    attr_accessor :neuron_catalog

    # Class map of named input and output neurons (each critter will have 
    # instantiations of these) name: InputNeuralClass (usually InputNeuron)
    attr_accessor :neural_inputs, :neural_outputs, :neural_hidden

    # Parameters for evolution (NeatParmeters)
    attr_accessor :parms

    # population object and class specification
    attr_reader :population, :population_history, :population_class

    attr_accessor :expressor, :expressor_class 
    attr_accessor :evaluator, :evaluator_class
    attr_accessor :evolver, :evolver_class

    # Query function that Critters shall call.
    attr_accessor :query_func

    # Fitness function that Critters shall be rated on.
    attr_accessor :fitness_func
    
    # End run function to call at the end of each generational run
    # Also report_hook to dump reports for the user, etc.
    attr_accessor :end_run_func, :report_hook

    # Logger object for all of RubyNEAT
    attr_reader :log

    # Various parameters affecting evolution.
    # Based somewhat on the C version of NEAT.
    class NeatSettings < NeatOb
      ## RubyNEAT specific
      
      # Set to true to returned named parameters as hashes to the fitness function
      # (the default is to do ordered arrays)
      attr_accessor :hash_on_fitness

      ## based on the C version of NEAT
      attr_accessor :age_significance
      attr_accessor :babies_stolen

      # Species compatability threshold
      attr_accessor :compatibility_threshold

      # Speciation coffficient
      attr_accessor :disjoint_coefficient, :excess_coefficient, :weight_coefficient
      
      # Max target number of species (will result in the compatability_coeifficient
      # being adjusted automatically
      attr_accessor :max_species

      # Species Peality age for not making progress
      attr_accessor :dropoff_age

      # Ratio of mating are actually interspecies
      attr_accessor :interspecies_mate_rate

      attr_accessor :linktrait_mutation_sig
      attr_accessor :mate_multipoint_avg_prob
      attr_accessor :mate_multipoint_prob
      attr_accessor :mate_only_prob
      attr_accessor :mate_singlepoint_prob

      # Maximum number of generations to run, if given.
      attr_accessor :max_generations

      attr_accessor :mutate_add_gene_prob
      attr_accessor :mutate_add_neuron_prob

      attr_accessor :mutate_gene_reenable_prob

      attr_accessor :mutate_gene_trait_prob

      # For gene weights perturbations and changes (complete overwrites)
      attr_accessor :mutate_perturb_gene_weights_prob, 
      :mutate_perturb_gene_weights_sd, 
      :mutate_change_gene_weights_prob, 
      :mutate_change_gene_weights_sd

      attr_accessor :mutate_neuron_trait_prob
      attr_accessor :mutate_only_prob
      attr_accessor :mutate_random_trait_prob
      attr_accessor :mutate_toggle_enable_prob
      attr_accessor :mutdiff_coefficient
      attr_accessor :newlink_tries
      attr_accessor :neuron_trait_mut_sig

      # If set, will start off at the specified size and 
      # grow to the bigger population size
      attr_accessor :start_population_size, :population_size

      attr_accessor :start_sequence_at, :end_sequence_at

      attr_accessor :print_every
      attr_accessor :recur_only_prob
      attr_accessor :recur_prob

      # factor (0 to 1) of the top percentage of the species that's
      # allowed to mate.
      attr_accessor :survival_threshold

      attr_accessor :trait_mutation_power
      attr_accessor :trait_param_mut_prob
      attr_accessor :weigh_mut_power

      # Enable FS-NEAT
      attr_accessor :feature_selection_switch

      # Enable HyperNEAT. This will result in the critters
      # being interpreted as CPPNs for substrate weights. Additional
      # setup will be necessary.
      attr_accessor :hyper_switch

      # Enable Evolved Substrate HyperNEAT. Meaningless unless
      # hyper_switch is also enabled.
      attr_accessor :evolved_substrate_switch

      # Enable RT-NEAT, for gradual evolution suitable for
      # games and other human-interactive systems.
      attr_accessor :real_time_switch

      # Set up defaults for mandatory entries.
      def initialize
        super
        @start_sequence_at = 0
        @end_sequence_at = 100
        @max_generations = 1000

        # Default operators
        @evaluator = Evaluator.new self
        @expressor = Expressor.new self
        @evolver = Evolver.new self
      end
    end

    #- neural_inputs -- array of input classes
    #- neural_outputs -- array of output classes
    #- parameters -- NeatParameters object, or a path to a YAML file to create this.
    def initialize(neural_inputs = nil, neural_outputs = nil, parameters = NeatSettings.new)
      super(self)

      @glob_innov_num = 0
      @gaussian = Distribution::Normal.rng
      @population_history = []
      @evolver = Evolver.new self
      @expressor = Expressor.new self
      @neuron_catalog = Neuron::neuronTypes.clone
      @neural_inputs = neural_inputs
      @neural_outputs = neural_outputs

      # Default classes for population and operators, etc.
      @population_class = NEAT::Population
      @evaluator_class = NEAT::Evaluator
      @expressor_class = NEAT::Expressor
      @evolver_class = NEAT::Evolver

      # Handle the parameters parameter. :-)
      @parms = unless parameters.kind_of? String
                 parameters
               else # load it from a file
                 open(parameters, 'r') { |fd| YAML::load fd.read }
               end
    end

    def new_innovation ; @glob_innov_num += 1; end
    def gaussian ; @gaussian.() ; end

    # Run this evolution.
    def run
      pre_run_initialize
      (1..@parms.max_generations).each do |gen_number|
        @generation_num = gen_number
        @population_history << unless @population.nil?
                                 @population
                               else
                                 @population = @population_class.new(self)
                               end
        
        @population.express!

        ## Evaluate population
        @evaluator.ready_for_evaluation
        (@parms.start_sequence_at .. @parms.end_sequence_at).each do |snum|
          @seq_num = snum
          @population.evaluate!
        end
        @population.analyze!
        @population.speciate!
        @population.evolve

        ## Report hook for evaluation
        @report_hook.(@population) unless @report_hook.nil?

        ## Evolve population
        @population = @population.evolve

        ## Finish up this run
        @end_run_func.(self) unless @end_run_func.nil?
      end
    end

    private
    # We must set up the objects we need prior to the run, if not set.
    def pre_run_initialize
      @evaluator = @evaluator_class.new(self) if @evaluator.nil?
      @evolver = @evolver_class.new(self) if @evolver.nil?
    end
  end

  @controller = Controller.new
  def self.controller ; @controller ; end
  def self.controller=(controller) ; @controller = controller ; end
  def self.create_controller(*parms); @controller = Controller.new(*parms); end
end

# We put all the internal requires at the end to avoid conflicts.
require 'rubyneat/neuron'
require 'rubyneat/population'

END {
  puts "RubyNEAT has ended"
}
