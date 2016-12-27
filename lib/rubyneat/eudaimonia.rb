module NEAT
  class Eudaimonia < Process::Daemon
    attr_accessor :amqp
    
    class << self
      attr_accessor :url
      attr_accessor :queue      
    end
    
    def startup
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
        ap info
        ap prop
        ap payload
        @amqp[:exchange].publish('return',
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
      puts "Fertig"
    end
    
  end
end

#MyDaemon.daemonize

