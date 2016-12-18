module NEAT
  module Cli
    class Daemon < Thor
      class_option :address, type: :string, banner: '<ip-addr>', default: ENV['RUBYNEAT_AMQP_URL'] || 'localhost', aliases: '-a'
      
      desc 'start', 'Start the RubyNEAT Daemon'
      def start
        Eudaimonia.start
      end
      
      desc 'stop', 'Stop the RubyNEAT Daemon'
      def stop
        Eudaimonia.stop
      end

      desc 'status', 'Status of the RubyNEAT Daemon'
      def status
        Eudaimonia.status
      end
      
      desc 'foreground', 'Run RubyNEAT Daemon in the foreground, with STDOUT/STDERR. Interrupt with ^C.'
      def foreground
        Eudaimonia.new.run
      end      
    end
  end
end
