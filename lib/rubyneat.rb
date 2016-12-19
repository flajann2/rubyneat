require 'set'
require 'pp'
require 'awesome_print'
require 'process/daemon'

set_trace_func proc { |event, file, line, id, binding, classname|
  if /ruby24.rb/ =~ file
    printf "%8s %s:%-2d %10s %8s\n", event, file, line, id, classname
    ap binding.local_variables
        .select{|v| [:str,:idx].member?(v)  }
        .map{|v| [v, binding.local_variable_get(v)]}.to_h
  end
}

require_relative 'rubyneat/rubyneat'
require_relative 'rubyneat/graph'
require_relative 'rubyneat/dsl'
require_relative 'rubyneat/reporting'
require_relative 'rubyneat/eudaimonia'
