module NEAT
  module Cli
    class Daemon < Thor
      desc 'background', 'Run RubyNEAT Daemon in the background'
      def background
        puts "Daemon Lives in the Background"
      end
    
      desc 'foreground', 'Run RubyNEAT Daemon in the foreground, with STDOUT/STDERR. Interrupt with ^C.'
      def foreground
        puts "Cthulhu woke up"
      end
    end
  end
end
