=begin rdoc
=Oread Deep Contolled Cloning

When you have a system of objects that have many references to each other, it becomes an
issue to be able to clone properly that object graph. There may be control objects you may
not want to clone, but maintain references to. And some references you may not wish to clone at all.

Enter Oread. In Greek Mythology, Echo fell in love with Narcissus, who in term fell in love with
his own reflection. Echo was an Oread who would "echo" whatever she heard from Narcissus up to a point.

And so, Oread does exactly that. Allows you a means by which you can do controlled deep cloning or
copying of your complex interconnected objects.

=Usage
Simply include Oread in your base class. All classes derived will be set for deep copying.

=end

module Oread

  def dup
    super.dup
  end

  def clone
    super.clone
  end

  module ClassMethods

  end

  def self.included(base)
    base.extend(ClassMethods)
  end
end
