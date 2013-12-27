require 'oread'

class FooBase
  include Oread
end

class Foo < FooBase
  attr_accessor :a, :b, :c, :changeme
end

class Bar < FooBase
  attr_accessor :a, :b, :c, :changeme
end

class FooBar < FooBase
  attr_accessor :a, :b, :c, :changeme
end

describe Oread do
  before(:each) do
    @foo = Foo.new
    @bar = Bar.new
    @foobar = FooBar.new

    @foo.b = @bar
    @bar.b = @foo
    @foo.c = @bar.c = @foobar.c = @foobar
    @foo.changeme = @bar.changeme = @foobar.changeme = "initial"
  end

  pending "Add some tests here"
end
