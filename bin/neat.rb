#!/usr/bin/env ruby
=begin rdoc
=RubyNEAT Launcher

=end

require 'pp'
require 'slop'

# Be sure lib is added to the library path
$:.unshift File.join( %w{ lib } )

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
      pp args
    end
  end

  run do |opts, args|
    puts args
    puts opts
  end
end
