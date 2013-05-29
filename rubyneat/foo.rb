require 'aquarium'

class ControllerPoint

  include Aquarium::DSL
end

class CuteA
  attr_accessor :cp

  def initialize
    puts "A initialized"
  end
end

class CuteB < CuteA
  attr_accessor :acp
  def initialize 
    puts "B initialized"
    @acp = CuteA.new
  end
end

include Aquarium::Aspects

@cp = ControllerPoint.new
Aspect.new :before, :invocations_of => :initialize, :for_types => /Cute.*$/, 
:restricting_methods_to => :private_methods do |jp, ob, args|
  puts "jp: #{jp.class} ob: #{ob.cp}"
  ob.cp = @cp
end


ca = CuteA.new
cb = CuteB.new

puts ca.cp
puts cb.cp
