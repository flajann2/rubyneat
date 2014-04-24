# Set up gems listed in the Gemfile.

require 'rubyneat/cli'

ENV['RUBYNEAT_ENV'] ||= 'development'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])

%w{ lib neater }.each do |dir|
  $:.unshift File.join([NEAT_PATH, dir])
end

Bundler.require(:default, ENV['RUBYNEAT_ENV'].to_sym)
