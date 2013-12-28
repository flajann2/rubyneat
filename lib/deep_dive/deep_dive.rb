=begin rdoc
=DeepDive Deep Contolled Cloning

When you have a system of objects that have many references to each other, it becomes an
issue to be able to clone properly that object graph. There may be control objects you may
not want to clone, but maintain references to. And some references you may not wish to clone at all.

Enter DeepDive. Allows you a means by which you can do controlled deep cloning or
copying of your complex interconnected objects.

=Usage
Simply include DeepDive in your base class. All classes derived will be set
for deep cloning or deep duping.

=end

module DeepDive
  def odup
    _odup dupit: true
  end

  def oclone
    _odup dupit: false
  end

  # not meant to be called externally. Use either odup or oclone.
  def _odup(dupit: true, oc: {})
    unless oc.member? self
      copy = oc[self] = if dupit
                          dup
                        else
                          clone
                        end
      copy.instance_variables.map do |var|
        [var, instance_variable_get(var)]
      end.reject do |var, ob|
        not ob.respond_to? :_odup
      end.reject do |var, ob|
        self.class.excluded? var
      end.each do |var, value|
        copy.instance_variable_set(var, value._odup(oc: oc, dupit: dupit))
      end
    end
    oc[self]
  end

  module CMeth
    @@exclusion = []
    # exclusion list of instance variables to dup/clone
    def exclude(*list)
      @@exclusion << list.map { |s| "@#{s}".to_sym }
      @@exclusion.flatten!
    end

    # Internal function not meant to be called by the application.
    def excluded?(sym)
      @@exclusion.member? sym
    end
  end

  def self.included(base)
    base.extend(CMeth)
  end

  def self.inherited(sub)
    sub.include(DeepDive)
  end
end
