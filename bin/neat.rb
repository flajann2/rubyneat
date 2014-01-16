#!/usr/bin/env ruby
=begin rdoc
=RubyNEAT Launcher

=end
require 'pp'
require 'semver'

# Be sure lib is added to the library path
%w{ lib neater }.each do |dir|
  $:.unshift File.join([Dir.pwd, dir])
end
pp Dir.pwd

NEATER = File.join [Dir.pwd, "neater"]
NEATGLOB = NEATER + '/*_neat.rb'

require 'slop'
require 'rubyneat'


opts = Slop.parse do
  banner 'Usage: neat [commands] [options] ...'

  on :version, 'Version information' do
    run do |opts, args|
      puts SemVer.find.format "%M.%m.%p%s"
    end
  end

  command :console do
    run do
      # TODO Implement an interactive console
    end
  end

  command :list do
    run do |opts, args|
      Dir.glob(NEATGLOB).sort.each do |ne|
        puts File.basename(ne).gsub(%r{_neat\.rb}, '')
      end
    end
  end

  command :run do
    on :log=, 'Debugging level [info|warn|error|debug]'
    on :v, :verbose=, 'Verbose mode'

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
    # TODO add some stuff here, or remove this block
  end
end

puts opts
