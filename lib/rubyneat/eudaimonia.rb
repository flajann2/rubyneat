module NEAT
  class Eudaimonia < Process::Daemon
    def startup
        # Called when the daemon is initialized in it's own process. Should return quickly.
    end

    def run
      puts "Eudaimonia loves you."
    end

    def shutdown
        # Stop everything that was setup in startup. Called as part of main daemon thread/process, not in trap context (e.g. SIGINT).
        # Asynchronous code can call self.request_shutdown from a trap context to interrupt the main process, provided you aren't doing work in #run.
    end
    
  end
end

#MyDaemon.daemonize

