require 'thor'
require 'semver'

NEATER = File.join [Dir.pwd, "neater"]
NEATGLOB = NEATER + '/*_neat.rb'

require_relative 'cli/generate'
require_relative 'cli/console'
require_relative 'cli/main'
require 'rubyneat'
