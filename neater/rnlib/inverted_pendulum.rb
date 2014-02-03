=begin rdoc
=Inverted Pendulum Experiment

Here we provide a graphic visualization of the inverted pendulum
problem, so you can actually SEE the problem being solved by
RubyNEAT.
=end

require 'gosu'
require 'matrix'

module InvertedPendulum
  include Math

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
    attr_accessor :pix_meters # pixels per meter

    def initialize(ipwin, scale: 1.0)
      @scale = scale
      @cart_length = 5.0 # meters
      @pix_meters = 640.0 * scale / @cart_length
      @ipwin = ipwin
      @platform = {
          image: Gosu::Image.new(ipwin, 'public/platform.png', true),
          x: 500,
          y: 650,
          dx: 0.50, #speed in meters per second
          dy: 0, #speed in meters per second, this will always be zero
          scale: 0.2 * scale,
          length: nil, # in meters, calculated from the scaled pixel length.
          height: nil, # in meters, calculated from the scaled pixel height
          mass: 100 # in kg. included are the mass of the wheels.
                    # We will not deal with the angular momentum of the wheels,
                    # because that's beyond the scope of what this is supposed to
                    # accomplish.
      }
      @platform[:length] = @platform[:image].width * @platform[:scale] / @pix_meters
      @platform[:height] = @platform[:image].height * @platform[:scale] / @pix_meters

      # Pole is relative to platform, and in the image is laying horizontal.
      @pole = {
          image: Gosu::Image.new(ipwin, 'public/pole.png', true),
          z: 0,
          xoff: 1.0,
          yoff: 0.5,
          ang: 90.01, # angle is in degrees
          dang: 10.0, # degrees per second
          scale: 0.2 * scale,
          length: nil, # in meters, calculated from the scaled pixel length.
          mass: 100 # in kg. The mass of the pole is assumed to all reside at a point at
                    # the knobby end.
      }
      @pole[:length] = @pole[:image].width * @pole[:scale] / @pix_meters

      # Wheels is relative to platform
      @wheels = [
          {
            image: Gosu::Image.new(ipwin, 'public/wheel.png', true),
            ang: 0,
            dang: 100, #FIXME: delete this for this will be overwritten anyway
            xoff: -0.7, # percentage from center
            yoff: 0.4, # percentage from center
            scale: 0.2 * scale
          },
          {
            image: Gosu::Image.new(ipwin, 'public/wheel.png', true),
            ang: 0,
            dang: 12.33, #FIXME: delete this for this will be overwritten anyway
            xoff: 0.7,
            yoff: 0.4,
            scale: 0.2 * scale
          }
      ].map { |w|
        # radius of wheel in meters, need this for rotational velocity calculation
        w[:radius] = w[:image].width * w[:scale] / @pix_meters / 2.0
        w[:circumference] = w[:radius] * 2.0 * PI
        w
      }
    end

    def update
      ## Physics updates
      @dt = @ipwin.update_interval / 1000.0

      # platform physics
      @platform[:x] += @platform[:dx] * @dt * @pix_meters

      # wheels physics -- angular velocity of each wheel based
      # on the linear velocity of the platform.
      @wheels.each do |w|
        w[:dang] = 360.0 * @platform[:dx] / w[:circumference]
        w[:ang] += w[:dang] * @dt
      end

      @pole[:ang] += @pole[:dang] * @dt

      # model update
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
        #ww = wl[:image].width * wl[:scale]
        #wh = wl[:image].height * wl[:scale]
        wl[:_x] = @platform[:x] + wl[:xoff] * pw / 2.0
        wl[:_y] = @platform[:y] + wl[:yoff] * ph / 2.0
      end

      # Pendulum
      polew = @pole[:image].width * @pole[:scale]
      poleh = @pole[:image].height * @pole[:scale]
      @pole[:_x] = @platform[:x]
      @pole[:_y] = @platform[:y]
    end

    def draw
      @pole[:image].draw_rot( @pole[:_x],
                              @pole[:_y],
                              @pole[:z],
                              @pole[:ang],
                              @pole[:xoff], @pole[:yoff],
                              @pole[:scale],
                              @pole[:scale])

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
