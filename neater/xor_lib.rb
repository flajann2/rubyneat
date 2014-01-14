=begin rdoc
 Basic xor function we shall evolve a net for. Only goes true
 on one and only one true input, false otherwise.
== Note Well
 This function can either take 0 or -1 to signify "false".
=end

def xor(*inp)
  inp.map{|n| (n > 0) ? 1 : 0}.reduce {|p, i| p + ((i > 0) ? 1 : 0) } == 1
end
