require 'thor'
require 'semver'

NEATER = File.join [Dir.pwd, "neater"]
NEATGLOB = NEATER + '/*_neat.rb'

require 'rubyneat/cli/main'
require 'rubyneat'

RubyNEAT::Cli::Main.start
