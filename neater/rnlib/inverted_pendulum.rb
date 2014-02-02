=begin rdoc
=Inverted Pendulum Experiment

Here we provide a graphic visualization of the inverted pendulum
problem, so you can actually SEE the problem being solved by
RubyNEAT.
=end

require 'gosu'

module InvertedPendulum
  class InvPendWindow < Gosu::Window
    attr_accessor :cart

    def initialize
      super(1280, 1024, false)
      self.caption = "RubyNEAT Inverted Pendulum Simulation"

      @background = {image: Gosu::Image.new(self, 'public/background.png', true),
                     x: 0,
                     y: 0,
                     scale: 0.9
                    }
    end

    def update
      @cart.update unless @cart.nil?
    end

    def draw
      @background[:image].draw(@background[:x],
                               @background[:y],
                               0,
                               @background[:scale],
                               @background[:scale])

      @cart.draw unless cart.nil?
    end

    def needs_cursor?; true; end
  end

  class Cart
    def initialize(ipwin)
      @ipwin = ipwin
      @platform = {
          image: Gosu::Image.new(ipwin, 'public/platform.png', true),
          x: 500,
          y: 900,
          dx: 0,
          dy: 0,
          scale: 0.2
      }

      # Pole is relative to platform, and in the image is laying horizontal.
      @pole = {
          image: Gosu::Image.new(ipwin, 'public/pole.png', true),
          xoff: 0.5, # percentage from center
          yoff: 0,   # percentage from center
          ang: 0,
          dang: 0,
          length: 0,
          scale: 0.2
      }

      # Wheels is relative to platform
      @wheels = [
          {
            image: Gosu::Image.new(ipwin, 'public/wheel.png', true),
            ang: 0,
            dang: 100,
            xoff: -0.7, # percentage from center
            yoff: 0.4, # percentage from center
            scale: 0.2
          },
          {
            image: Gosu::Image.new(ipwin, 'public/wheel.png', true),
            ang: 0,
            dang: 12.33,
            xoff: 0.7,
            yoff: 0.4,
            scale: 0.2
          }
      ]
    end

    def update
      @dt = @ipwin.update_interval / 1000.0
      puts @dt
      @wheels.each {|w| w[:ang] += w[:dang] * @dt }
      self.update_cart
    end

    # update the positions of all the compnents of the cart
    # in terms of the relative positional relationships
    def update_cart
      # center of platform is taken as (x, y), actual is (_x, _y)
      pw = @platform[:image].width * @platform[:scale]
      ph = @platform[:image].height * @platform[:scale]
      @platform[:_x] = @platform[:x] - pw / 2.0
      @platform[:_y] = @platform[:y] - ph / 2.0

      # Wheels in their respective places
      @wheels.each do |wl|
        ww = wl[:image].width * wl[:scale]
        wh = wl[:image].height * wl[:scale]
        wl[:_x] = @platform[:x] + wl[:xoff] * pw / 2.0
        wl[:_y] = @platform[:y] + wl[:yoff] * ph / 2.0
      end

      # Pendulum
      polew = @pole[:image].width * @pole[:scale]
      poleh = @pole[:image].height * @pole[:scale]

      @pole
    end

    def draw
      @platform[:image].draw(@platform[:_x],
                             @platform[:_y],
                             0,
                             @platform[:scale],
                             @platform[:scale])

      @wheels.each do |wh|
        wh[:image].draw_rot(wh[:_x],
                            wh[:_y],
                            0,
                            wh[:ang],
                            0.5, 0.5,
                            wh[:scale],
                            wh[:scale])
      end
      @pole[:image].draw(@pole[:_x], @pole[:_y], 0)
    end
  end

  module DSL
    include Math
    def invpend(&block)
      @ipwin = InvPendWindow.new
      @ipwin.cart = Cart.new @ipwin

      def show(&block)
        @ipwin.show
      end
      block.(@ipwin)
    end
  end
end
