<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#orgheadline42">1. RubyNEAT &#x2013; Ruby implementation of Neural Evolution of Augmenting Topologies (NEAT)</a>
<ul>
<li><a href="#orgheadline1">1.1. What is NEAT?</a></li>
<li><a href="#orgheadline2">1.2. What is RubyNEAT?</a></li>
<li><a href="#orgheadline9">1.3. Architecture</a>
<ul>
<li><a href="#orgheadline3">1.3.1. Controller</a></li>
<li><a href="#orgheadline4">1.3.2. Evolver</a></li>
<li><a href="#orgheadline5">1.3.3. Expressor</a></li>
<li><a href="#orgheadline6">1.3.4. Evaluator</a></li>
<li><a href="#orgheadline7">1.3.5. Population</a></li>
<li><a href="#orgheadline8">1.3.6. Critter</a></li>
</ul>
</li>
<li><a href="#orgheadline11">1.4. Installation</a>
<ul>
<li><a href="#orgheadline10">1.4.1. Requirements</a></li>
</ul>
</li>
<li><a href="#orgheadline15">1.5. Examples</a>
<ul>
<li><a href="#orgheadline14">1.5.1. Note Well</a></li>
</ul>
</li>
<li><a href="#orgheadline41">1.6. RubyNEAT DSL</a>
<ul>
<li><a href="#orgheadline34">1.6.1. The XOR Neater Example</a></li>
<li><a href="#orgheadline40">1.6.2. Releases</a></li>
</ul>
</li>
</ul>
</li>
</ul>
</div>
</div>

&#x2014;
layout: default
title: RubyNEAT
&#x2014;

# RubyNEAT &#x2013; Ruby implementation of Neural Evolution of Augmenting Topologies (NEAT)<a id="orgheadline42"></a>

## What is NEAT?<a id="orgheadline1"></a>

NEAT is an acronym for Neural Evolution of Augmenting Topologies.
In short, neural nets that are evolved from a minimal topology,
allowing selection to decide on what topologies are most adequate
for resolving the problem at hand.

## What is RubyNEAT?<a id="orgheadline2"></a>

RubyNEAT is the world's first (and currently only) implementation
of the NEAT algorithm in the Ruby programming language. RubyNEAT
leverages some of the benefits of Ruby, such as metaprogramming,
to implement activation of the Neural Net.

Basically, the Neural Nets in RubyNEAT manifests themselves in the
Phenotypes as functional programs &#x2013; of a sort. You may think of it
as an application of Genetic Programming techniques to resolving the
NEAT algorithm. As such, once fit Critters (neural nets) are found,
they may be extracted as pure Ruby code, not needing the
RubyNEAT engine for activation.

## Architecture<a id="orgheadline9"></a>

RubyNEAT comprises many interacting modules. While it is
not strictly necessary to understand RubyNEAT at this level
of detail, it would be beneficial for a number of reasons,
especially in understanding how to tweak the parameters
to improve performance for your application. 

RubyNEAT comprises the following modules: 
Controller, Expressor, Evaluator, Evolver, Population, and Critter.

### Controller<a id="orgheadline3"></a>

The Controller mediates all aspects of RubyNEAT
evolution, the various modules involved and their
interactions, and also holds the settings the other
modules will refer to. 

The Controller is singular. There can only be one
Controller in the RubyNEAT system. All other objects
associated with the Controller shall have embedded
in them a reference to their controller.

### Evolver<a id="orgheadline4"></a>

The Evolver module houses the evolving algorithms
for RubyNEAT. It evolves the entire Population of Critters.

### Expressor<a id="orgheadline5"></a>

The Expressor module is responsible for interpreting
the Genotype of the Critters and creating their
Phenotypes. The default Expressor generates Ruby code
and attaches that code to the Phenotype instances of the Critter. 

It is entirely possible to swap in a different Expressor and
generate code for a different target language, or create some 
other construct. There is no limit to what you could
have an Expressor do.

### Evaluator<a id="orgheadline6"></a>

The Evaluator is a kind of bridge between the inner "biology" of the RubyNEAT "ecosystem" and the outside world. It has ties to the RubyNEAT DSL where you encode your own fitness functions and data links to some external problem space. It is, in a sense, the "gateway".

### Population<a id="orgheadline7"></a>

The Population is what your intuition tells you. It is a environment that houses a collection of Critters. 

### Critter<a id="orgheadline8"></a>

The Critter is the embodiment of both the genetics for the neural net and also the expression of the same. It contains, in other words, the Genotype and the Phenotype.

Critters are mated through the Evolver, and have their genes expressed through the Expressor. 

## Installation<a id="orgheadline11"></a>

You may install RubyNEAT by cloning the repo at GitHub:
[RubyNEAT Github](https://github.com/flajann2/rubyneat)

Or you may get it via a gem

    gem install rubyneat --pre

### Requirements<a id="orgheadline10"></a>

You will need at least Ruby 2.0.0, though we strongly recommend 2.1.1
or better. We will NOT be supporting 1.9.x,
as that is being phased out anyway.

## Examples<a id="orgheadline15"></a>

Clone:

    git clone git@github.com:flajann2/rubyneat_examples.git

and cd into the '''rubyneat<sub>examples</sub>''' directory. 

Type: 

    neat list neaters

to get a list of neaters. To run one like, say, the XOR test:

    neat run xor

### Note Well<a id="orgheadline14"></a>

The pole-balancing invpend neater is still under
development. It will display a window with the cart and pole,
but will not balance yet. Just a matter of me 
finishing up that code. All the others work.

1.  RubyNEAT

    -   GitHUB
        [RubyNEAT GitHub](https://github.com/flajann2/rubyneat)
    
    -   Ruby GEM
        
            gem install rubyneat --pre

2.  RubyNEAT Examples

    -   Github
        [Example Neaters on GitHub](https://github.com/flajann2/rubyneat_examples)

## RubyNEAT DSL<a id="orgheadline41"></a>

I will take the '''XOR''' neater and document it.
This is not the perfect way to go,
but I will get more extensive later.

### The XOR Neater Example<a id="orgheadline34"></a>

    require 'xor'
    include NEAT::DSL

-   The first lines here includes the special XOR library, which is basically:

    def xor(*inp)
      inp.map{|n| (n > 0) ? 1 : 0}.reduce {|p, i| p + ((i > 0) ? 1 : 0) } == 1
    end

-Basic settings for the '''XOR''', which can handle more than 2 inputs.

    XOR_INPUTS = 2
    XOR_STATES = 2 ** XOR_INPUTS
    MAX_FIT    = XOR_STATES
    ALMOST_FIT = XOR_STATES - 0.5

-   The actual definition of the Neater. Here you specify the parameters RubyNEAT
    will use to run the evolution, as well as the CPPN neuron types, the fitness function,
    etc.

    define "XOR System" do

-   Inputs defined as name: Neuron, name: Neuron &#x2026; hash. In this segment, we
    create a block to generate the hash since we can have a variable number of
    inputs to the XOR. The input names must be unique. Note that a bias neuron
    is also supplied, and it is always called :bias.

    inputs {
      cinv = Hash[(1..XOR_INPUTS).map{|i| [("i%s" % i).to_sym, InputNeuron]}]
      cinv[:bias] = BiasNeuron
      cinv
    }

-   Outputs are defined in a similar fashion to the inputs. The names of all the 
    output neurons must be unique. Here in this example we only have one output, and
    we use the hyperbolic tan Neuron as the output. There is also a sigmoid Neuron
    that could be used as well, but the input levels would have to be conditioned
    to vary from 0 to 1 instead of from -1 to one.

    outputs out: TanhNeuron

-   Hidden neuron specification is optional. 
    The names given here are largely meaningless, but but follow the same rules
    for uniqueness. The neurons specified will be selected randomly as the topologies
    are augmented.

    hidden tan: TanhNeuron

1.  Settings

    For RubyNEAT. Extensive documentation will be provided on a later date
    as to the meanings, which closely follow the parameters for Ken Stanley's NEAT
    implementation.
    
    1.  General
    
            hash_on_fitness false
            start_population_size 30
            population_size 30
            max_generations 10000
            max_population_history 10
    
    2.  Evolver probabilities and SDs
    
        Perturbations
        
            mutate_perturb_gene_weights_prob 0.10
            mutate_perturb_gene_weights_sd 0.25
    
    3.  Complete Change of weight
    
            mutate_change_gene_weights_prob 0.10
            mutate_change_gene_weights_sd 1.00
    
    4.  Adding new neurons and genes
    
            mutate_add_neuron_prob 0.05
            mutate_add_gene_prob 0.20
    
    5.  Switching genes on and off
    
            mutate_gene_disable_prob 0.01
            mutate_gene_reenable_prob 0.01
            
            interspecies_mate_rate 0.03
            mate_only_prob 0.10 *0.7
    
    6.  Mating
    
            survival_threshold 0.20 # top % allowed to mate in a species.
            survival_mininum_per_species  4 # for small populations, we need SOMETHING to go on.
    
    7.  Fitness costs
    
            fitness_cost_per_neuron 0.00001
            fitness_cost_per_gene   0.00001
    
    8.  Speciation
    
            compatibility_threshold 2.5
            disjoint_coefficient 0.6
            excess_coefficient 0.6
            weight_coefficient 0.2
            max_species 20
            dropoff_age 15
            smallest_species 5
    
    9.  Sequencing
    
        The evaluation function is called repeatedly, and each iteration is given a
        monotonically increasing integer which represents the sequence number. The results
        of each run is returned, and those results are evaluated elsewhere in the Neater.
        
            start_sequence_at 0
            end_sequence_at 2 ** XOR_INPUTS - 1

2.  The Evolution Block

        evolve do
    
    1.  The Query Block
    
        This query shall return a vector result that will serve
        as the inputs to the critter. 
        
            query { |seq|
              * We'll use the seq to create the xor sequences via
              * the least signficant bits.
              condition_boolean_vector (0 ... XOR_INPUTS).map{|i| (seq & (1 << i)) != 0}
            }
    
    2.  The Compare Block
    
        Compare the fitness of two critters. We may choose a different ordering here.
        
            compare {|f1, f2| f2 <=> f1 }
    
    3.  The Cost of Fitness Block
    
        Here we integrate the cost with the fitness.
        
            cost { |fitvec, cost|
              fit = XOR_STATES - fitvec.reduce {|a,r| a+r} - cost
              $log.debug ">>>>>>> fitvec *{fitvec} => *{fit}, cost *{cost}"
              fit
            }
    
    4.  The Fitness Block
    
        The fitness block is called for each activation and is given the input vector,
        the output vector, and the sequence number given to the query. The results are
        evaluated and a fitness scalar is returned.
        
        \#+BEGIN<sub>SRC</sub> ruby
          fitness { |vin, vout, seq|
            unless vout **\*** :error
              bin = uncondition<sub>boolean</sub><sub>vector</sub> vin
              bout = uncondition<sub>boolean</sub><sub>vector</sub> vout
              bactual = [xor(\*vin)]
              vactual = condition<sub>boolean</sub><sub>vector</sub> bactual
              fit = (bout **\*** bactual) ? 0.00 : 1.00
              **simple<sub>fitness</sub><sub>error</sub>(vout, vactual.map{|f| f \* 0.50 })
              bfit = (bout \*\*** bactual) ? 'T' : 'F'
              fit
            else
              $log.debug "Error on \*{vin} [\*{seq}]"
              1.0
            end
          }
        \\#+ END<sub>SRC</sub>
    
    5.  The Termination Condition
    
        When the desired fitness level is reached, you may want to end the
        Neater run. If so, provide a block to do just that.
        
              stop_on_fitness { |fitness, c|
                puts "*** Generation Run *{c.generation_num}, best is *{fitness[:best]} ***\n\n"
                fitness[:best] >= ALMOST_FIT
              }
            end

3.  Report Generating Block

    This particular report block just adds something to the log. You could easily
    replace that with a visual update if you like, etc.
    
        report do |rept|
          $log.info "REPORT *{rept.to_yaml}"
        end

4.  Engine Run Block

    The block here is called upon the completion of each generation. The
    'c' parameter is the RubyNEAT Controller, the same as given to the stop<sub>on</sub><sub>fitness</sub>
    block.
    
        run_engine do |c|
          $log.info "******** Run of generation %s completed, history count %d ********" %
                [c.generation_num, c.population_history.size]
        end

### Releases<a id="orgheadline40"></a>

1.  v0.4.0.alpha.4

    -   First crude cut of a dashboard rubyneat<sub>dashboard</sub>

2.  0.3.5.alpha.6

    -   Command line workflow is a bit cleaner
    -   Removed neater examples completely and place them in   
        <https://github.com/flajann2/rubyneat_examples>
    -   Cleaned up the internal docs a bit
    -   Uniquely Generated Named Objects (UGNOs) cleaned up to be respectable

3.  2015-06-08

    -   Working on the Iterated ES HyperNEAT still,
        after being side-tracked by having to make a living.
        Also creating a maze environment for the critters to
        operate as bots in order to test the new ES HyperNEAT extension.
    -   rnDSL, as a result of TWEANN Compositions, is undergoing
        radical changes. All example Neaters will be 
        eventually update to reflect the new syntax.

4.  2014-09-25

    Hot on the efforts on adding two major features to RubyNEAT:
    
    -   TWEANN Compositions &#x2013; you will be able to define composites of TWEANNs on
        a per critter basis. This should mirror how, say, biological brains composite
        themselves into regions of speciality. You may specify different selections
        of neurons for each TWEANN. This is totally experiential, so we'll
        see if this results in better convergence for some problems.
    
    -   iterated ES HyperNEAT &#x2013; one of the compsitions
        above can be specified as a Hyper TWEANN, and just
        represent one of the many compositions you may have.
    
    -   The syntax of the Neater DSL will change quite a bit to
        reflect the new features, and all of the examples will
        be rewritten to show this.
    
    Do not confuse the ANN compositions here with CPPNs,
    which are completely different. By default, all TWEANNs 
    in HyperNEAT are potential CPPNs anyway, as
    you can specify more than one neuron type.

5.  2014-08-03

    Just released a very crude alpha cut of a 
    dashboard for RubyNEAT. You will have to
    install it manually, along with rubyneat.
    The gem is rubyneat<sub>dashboard</sub>.
    
    -   I am currently working on a Dashboard for RubyNEAT.
        It will be a gemmable plugin that will allow you to
        use the browser as the dashboard. It will have realtime
        updates and the like, allowing you to monitor the progress 
        of your Neaters, and to view and possibly set parameters,
        and to see what your Critters look like.
