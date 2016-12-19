module NEAT
  class Eudaimonia < Process::Daemon
    attr_accessor :amqp
    class << self
      attr_accessor :url
    end
    
    def startup
      # Setup the AMQP channel
      @ampq ||= []
      @amqp[:conn] = Bunny.new (@amqp[:url] = self.class.url)
      @amqp[:conn].start
      @amqp[:channel] = @amqp[:conn].create_channel
      @amqp[:queue] = @amqp[:channel].queue(*@amqp[:queue_params])
      @amqp[:reply] = @amqp[:channel].queue(*@amqp[:reply_params])
      @amqp[:exchange] = @amqp[:channel].default_exchange
    end

    def run
      loop do
        puts "It runs"
        ap @ampq
        sleep 1
      end
    ensure
      puts "Eudaimonia noooo."
    end

    def shutdown
      # Stop everything that was setup in startup. Called as part of main daemon thread/process, not in trap context (e.g. SIGINT).
      # Asynchronous code can call self.request_shutdown from a trap context to interrupt the main process, provided you aren't doing work in #run.
      puts "Fertig"
    end
    
  end
end

#MyDaemon.daemonize

