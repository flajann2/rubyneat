module NEAT
  module Cli
    class Daemon < Thor
      class_option :url,
                   type: :string,
                   banner: 'URL like amqp://guest:guest@localhost:5672',
                   default: ENV['RUBYNEAT_AMQP_URL'] || 'amqp://guest:guest@localhost:5672',
                   aliases: '-a'
      
      class_option :routing,
                   type: :string,
                   banner: '<routing_name>',
                   default: ENV['RUBYNEAT_AMQP_ROUTING'] || 'rubyneat_cmd',
                   aliases: '-r'
      
      class_option :queue,
                   type: :string,
                   banner: '<queue_name>',
                   default: ENV['RUBYNEAT_AMQP_QUEUE'] || 'rubyneat_cmd',
                   aliases: '-q'
      
      class_option :reply,
                   type: :string,
                   banner: '<reply_to_name>',
                   default: ENV['RUBYNEAT_AMQP_REPLY_TO'] || 'rubyneat_reply',
                   aliases: '-y'
      
      desc 'start', 'Start the RubyNEAT Daemon'
      def start
        Eudaimonia.url = options[:url]
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
