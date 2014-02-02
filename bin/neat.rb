#!/usr/bin/env ruby
=begin rdoc
=RubyNEAT Launcher

=end
require 'semver'

# Be sure rnlib is added to the library path
%w{ lib neater neater/rnlib }.each do |dir|
  $:.unshift File.join([Dir.pwd, dir])
end

NEATER = File.join [Dir.pwd, "neater"]
NEATGLOB = NEATER + '/*_neat.rb'

require 'slop'
require 'rubyneat'


opts = Slop.parse(strict: true, help: true) do
  banner 'Usage: neat [commands] [options] ...'

  on :version, 'Version information' do
    run do |opts, args|
      puts SemVer.find.format "%M.%m.%p%s"
    end
  end

  command :console do
    banner 'Usage: neat console [options]'
    run do
      # TODO Implement an interactive console
    end
  end

  command :list do
    banner 'Usage: neat list [options]'
    run do |opts, args|
      Dir.glob(NEATGLOB).sort.each do |ne|
        puts File.basename(ne).gsub(%r{_neat\.rb}, '')
      end
    end
  end

  command :run do
    banner "Usage: neat run [options] neater_module ...\nFor a list of neater modules: neat list"
    on :log=, 'Debugging level [info|warn|error|debug]'
    on :v, :verbose=, 'Verbose mode', as: Integer

    run do |opts, args|
      NEAT::controller.verbosity = opts[:v].to_i unless opts[:v].nil?
      eval %{$log.level = Logger::#{opts[:log].upcase}} unless opts[:log].nil?

      args.map do |proj|
        "#{proj}_neat.rb"
      end.each do |file|
        load file
      end
    end
  end

  run do |opts, args|
    puts opts
  end
end
