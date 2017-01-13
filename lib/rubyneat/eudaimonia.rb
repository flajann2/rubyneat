module NEAT
  class Eudaimonia < Process::Daemon
    attr_accessor :amqp
    
    class << self
      attr_accessor :url
      attr_accessor :queue
      attr_accessor :daemonized
      def daemonized?
        @daemonized
      end
    end
    
    def startup
      # Let everyone know we are running as a daemon
      self.class.daemonized = true
      
      # Setup the AMQP channel
      @amqp ||= {}
      @amqp[:conn] = Bunny.new (@amqp[:url] = self.class.url)
      @amqp[:conn].start
      @amqp[:channel]  = @amqp[:conn].create_channel
      @amqp[:queue]    = @amqp[:channel].queue(@amqp[:queue_name] = self.class.queue)
      @amqp[:exchange] = @amqp[:channel].default_exchange
    end

    def run
      @amqp[:queue].subscribe(block: true) do |info, prop, payload|
        pl = Oj.load payload

        begin
          puts "Executing: #{Daemon::COMMANDS[pl.cmd].first}"
          pl.response = [:success, Daemon::COMMANDS[pl.cmd].last.(pl.payload)]
        rescue => e
          pl.response = [:fail, ["RubyNEAT Exception: #{$!}", e.backtrace]]
        end
        ap pl
        @amqp[:exchange].publish(Oj.dump(pl),
                                 routing_key: prop.reply_to,
                                 correlation_id: prop.correlation_id)
      end     
    ensure
      puts "Eudaimonia noooo."
    end

    def shutdown
      # Stop everything that was setup in startup.
      # Called as part of main daemon thread/process,
      # not in trap context (e.g. SIGINT).
      # Asynchronous code can call self.request_shutdown
      # from a trap context to interrupt the main process,
      # provided you aren't doing work in #run.
      self.class.daemonized = false
      puts "Fertig"
    end
    
  end
end

#MyDaemon.daemonize

