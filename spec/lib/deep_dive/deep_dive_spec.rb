require 'deep_dive'

class FooBase
  include DeepDive
  exclude :c
end

class Foo < FooBase
  attr_accessor :a, :b, :c, :changeme
end

class Bar < FooBase
  attr_accessor :a, :b, :c, :changeme
end

class FooBar < FooBase
  attr_accessor :a, :b, :c, :changeme, :dontcopy
  exclude :dontcopy
end

describe DeepDive do
  before(:each) do
    @foo = Foo.new
    @bar = Bar.new
    @foobar = FooBar.new

    @foo.a = 'foo just around'
    @bar.a = 'bar hanging around'
    @foo.b = @bar
    @bar.b = @foo
    @foo.c = @bar.c = @foobar.c = @foobar
    @foo.changeme = @bar.changeme = @foobar.changeme = "initial"
  end


  context 'clone' do
    it 'simple' do
      cfoo = @foo.oclone
      cfoo.should_not == nil
      cfoo.should_not == @foo
      @foo.b.changeme = 'changed'
      @foobar.changeme = 'also changed'
      cfoo.c.changeme.should == @foobar.changeme
      cfoo.b.changeme.should_not == @foo.b.changeme
    end

    it 'exclusion' do
      @foobar.dontcopy = @bar
      cfoobar = @foobar.oclone
      cfoobar.dontcopy.should == @foobar.dontcopy

      @foo.a = @bar
      cfoo = @foo.oclone
      cfoo.a.should_not == @foo.a
    end
  end

  context 'dup' do
    it 'simple' do
      cfoo = @foo.odup
      cfoo.should_not == nil
    end
    it 'deep'
  end
end

