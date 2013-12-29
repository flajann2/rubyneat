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
  attr_accessor :a, :b, :c, :changeme, :dontcopy, :arr, :hsh
  exclude :dontcopy
end

describe DeepDive do
  before(:each) do
    @foo = Foo.new
    @bar = Bar.new
    @foobar = FooBar.new
    @foobar.arr = [@foo, @bar, @foobar]
    @foobar.hsh = {foo: @foo, bar: @bar, foobar: @foobar}

    @foo.a = 'foo just around'
    @bar.a = 'bar hanging around'
    @foo.b = @bar
    @bar.b = @foo
    @foo.c = @bar.c = @foobar.c = @foobar
    @foo.changeme = @bar.changeme = @foobar.changeme = "initial"
  end


  context 'clone' do
    it 'simple' do
      cfoo = @foo.dclone
      cfoo.should_not == nil
      cfoo.should_not == @foo
      @foo.b.changeme = 'changed'
      @foobar.changeme = 'also changed'
      cfoo.c.changeme.should == @foobar.changeme
      cfoo.b.changeme.should_not == @foo.b.changeme
    end

    it 'exclusion' do
      @foobar.dontcopy = @bar
      cfoobar = @foobar.dclone
      cfoobar.dontcopy.should == @foobar.dontcopy

      @foo.a = @bar
      cfoo = @foo.dclone
      cfoo.a.should_not == @foo.a
    end
  end

  context 'dup' do
    it 'simple' do
      cfoo = @foo.ddup
      cfoo.should_not == nil
    end
    it 'deep'
  end

  context 'enumerables' do
    it 'makes copies of the arrayed objects' do
      cfb = @foobar.dclone
      cfb.arr.size.should > 0
      (0 ... cfb.arr.size).each do |i|
        cfb.arr[i].should_not be_nil
        cfb.arr[i].should_not == @foobar.arr[i]
      end
    end

    it 'makes copies of the hashed objects' do
      cfb = @foobar.dclone
      cfb.hsh.size.should > 0
      cfb.hsh.each do |k, o|
        cfb.hsh[k].should_not == @foobar.hsh[k]
      end
    end
  end
end
