require_relative 'rubyneat'

module NEAT
  #= Evaluator evaluates phenotype of critter for fitness, novelty, etc.
  # We can have a chain of these evaluators whose outputs are summed, etc.
  class Evaluator < Operator

    # This is call prior to any sequence evaluation. Here,
    # we clean up persistent tracking information, etc.
    def ready_for_evaluation(pop)
      @crit_hist = {}
      pop.initialize_for_recurrence!
    end

    # Evaluate one step of a sequence of evaluations.
    # For time series and realtime ongoing evaluations,
    # @controller.seq_num governs where in the sequence
    # everything is. 
    #
    # Returns [vin, vout], where vin is the input vector,
    # and vout in the output vector from the critter.
    # FIXME: this should not really have to deal with an error.
    # FIXME: the error should be handled upstream from here.
    def evaluate!(critter)
      vin = @controller.query_func.(@controller.seq_num)
      @crit_hist[critter] = {} unless @crit_hist.member? critter
      begin
        vout = critter.phenotype.stimulate *vin, &@controller.recurrence_func
        log.debug "Critter #{critter.name}: vin=#{vin}. vout=#{vout}"
        @crit_hist[critter][@controller.seq_num] = [vin, vout]
      rescue Exception => e
        log.error "Exception #{e} on code:\n#{critter.phenotype.code}"
        @crit_hist[critter][@controller.seq_num] = [vin, :error]
      end
    end

    # Analyze the evaluation and compute a fitness for the given critter.
    # Note that if cost_func is set, we call that to integrate the cost to
    # the fitness average fitness calculated for the fitness vector.
    def analyze_for_fitness!(critter)
      fitvec = @crit_hist[critter].map{|seq, vio| @controller.fitness_func.(vio[0], vio[1], seq) }
      # Average the fitness vector to get a scalar fitness.
      critter.fitness = unless @controller.cost_func_none?
                          @controller.cost_func_hook(fitvec, critter.genotype.fitness_cost)
                        else
                          fitvec.reduce {|a,r| a+r} / fitvec.size.to_f + critter.genotype.fitness_cost
                        end
      log.debug "Fitness Vector: #{fitvec}, fitness of #{critter.fitness} assigned to #{critter}"
    end
  end
end
