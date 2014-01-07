require 'rubyneat/rubyneat'

module NEAT
  #= Evaluator evaluates phenotype of critter for fitness, novelty, etc.
  # We can have a chain of these evaluators whose outputs are summed, etc.
  class Evaluator < Operator

    # This is call prior to any sequence evaluation. Here,
    # we clean up persistent tracking information, etc.
    def ready_for_evaluation
      @crit_hist = {}
    end

    # Evaluate one step of a sequence of evaluations.
    # For time series and realtime ongoing evaluations,
    # @controller.seq_num governs where in the sequence
    # everything is. 
    #
    # Returns [vin, vout], where vin in the input vector,
    # and vout in the output vector from the critter.
    def evaluate!(critter)
      vin = @controller.query_func.(@controller.seq_num)
      vout = critter.phenotype.stimulate *vin
      log.debug "critter #{critter.name}: vin=#{vin}. vout=#{vout}"
      @crit_hist[critter] = {} unless @crit_hist.member? critter
      @crit_hist[critter][@controller.seq_num] = [vin, vout] 
    end

    # Analyze the evaluation and compute a fitness for the given critter.
    def analyze_for_fitness!(critter)
      fitvec = @crit_hist[critter].map{|seq, vio| @controller.fitness_func.(vio[0], vio[1], seq) }
      # Average the fitness vector to get a scalar fitness.
      critter.fitness = fitvec.reduce {|a,r| a+r} / fitvec.size.to_f - critter.genotype.fitness_cost
      log.debug "Fitness Vector: #{fitvec}, fitness of #{critter.fitness} assigned to #{critter}"
    end
  end
end
