require 'set'
require 'pp'
require 'awesome_print'
require 'process/daemon'
require 'oj'
require 'bunny'
require 'securerandom'

require 'semver'
require 'distribution'
require 'yaml'
require 'logger'
require 'awesome_print'
require 'deep_dive'
require 'queue_ding'
require 'matrix'
require 'parser/current'
require 'unparser'

def rubyneat_version
  SemVer.find.format "RubyNEAT v%M.%m.%p%s"
end

require_relative 'rubyneat/rubyneat'
require_relative 'rubyneat/graph'
require_relative 'rubyneat/dsl'
require_relative 'rubyneat/reporting'
require_relative 'rubyneat/daemon'
require_relative 'rubyneat/eudaimonia'
