module NEAT
  module Cli
    class Daemon < Thor
      class_option :address, type: :string, banner: '<ip-addr>', default: 'localhost', aliases: '-a'
      
      desc 'background', 'Run RubyNEAT Daemon in the background'
      def background
        puts "Daemon Lives in the Background"
        Eudaimonia.daemonize
      end
      
      desc 'foreground', 'Run RubyNEAT Daemon in the foreground, with STDOUT/STDERR. Interrupt with ^C.'
      def foreground
        Eudaimonia.new.run
      end      
    end
  end
end
