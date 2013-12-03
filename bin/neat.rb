#!/usr/bin/env ruby
=begin rdoc
=RubyNEAT Launcher

=end
require 'pp'

# Be sure lib is added to the library path
%w{ lib neater }.each do |dir|
  $:.unshift File.join([Dir.pwd, dir])
end
pp Dir.pwd

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
        "#{proj}_neat.rb"
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
