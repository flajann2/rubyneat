module NEAT
  module Cli
    class Daemon < Thor
      desc 'background', 'Run RubyNEAT Daemon in the background'
      def background
        puts "Daemon Lives in the Background"
        daemon
      end
    
      desc 'foreground', 'Run RubyNEAT Daemon in the foreground, with STDOUT/STDERR. Interrupt with ^C.'
      def foreground
        daemon
      end
      
      no_tasks do
        def daemon
          puts "Cthulhu woke up"
        end
      end
    end
  end
end
