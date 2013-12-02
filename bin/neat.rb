#!/usr/bin/env ruby
=begin rdoc
=RubyNEAT Launcher

=end

# Be sure lib is added to the library path
$:.unshift File.join( %w{ lib neater } )

require 'pp'
require 'slop'
require 'rubyneat'


opts = Slop.parse do
  banner 'Usage: neat [commands] [options] ...'

  on :version, 'Version information' do
    puts 'v0.0.0'
  end

  command :console do

  end

  command :list do

  end

  command :run do
    on :v, :verbose, 'Verbose mode'

    run do |opts, args|
      args.map do |proj|
        "#{proj}_neat"
      end.each do |file|
        load file
      end
    end
  end

  run do |opts, args|
    puts args
    puts opts
  end
end
