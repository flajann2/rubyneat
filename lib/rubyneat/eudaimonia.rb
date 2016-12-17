module NEAT
  class Eudaimonia < Process::Daemon
    def startup
      puts "Eudaimonia loves you."

    end

    def run
      loop do
        puts "It runs"
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

