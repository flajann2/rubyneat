=begin rdoc
=Inverted Pendulum Experiment

Here we provide a graphic visualization of the inverted pendulum
problem, so you can actually SEE the problem being solved by
RubyNEAT.

==Notes
===Physical Quantities
All physical quantities are in SI units.

===Vectors
* We use 3 dimensional vectors here, even though it's a 2D simulation, for the
  simple reason that cross products require at least 3 components to a vector.
* x and z are taken to be on the horizontal plane, and y is taken to be the vertical.
* The sign of the *graphical* y will be reversed of the physical y.
=end

require 'gosu'
require 'matrix'

module InvertedPendulum
  include Math
  GC = 6.67384e-11 # m3 kg-1 s-2
  ADTG = -9.81 # m/s**2, acceleration due to gravity on earth
  TORAD = PI / 180.0 # converts degrees to radians, deg * TORAD
  PI2 = 2.0 * PI

  # The following are array indicies of the vector.
  X = 0 # Horizontal, cart travels in this coordinate.
  Y = 1 # Vertical, gravitation acts in this coordinate
  Z = 2 # Horizontal, purely there so the cross products work

  GV = Vector[0, ADTG, 0]
  ZERO_VECTOR = Vector[0,0,0]

  # ID INPUTS
  MOUSE_LB = 256
  MOUSE_RB = 257
  MOUSE_MB = 258
  MOUSE_ROLL_BACK = 260
  MOUSE_ROLL_FOREWARD = 259
  MOUSE_SIDE_BACK = 268
  MOUSE_SIDE_FOREWARD = 264

  # We do this for speedier simulations, otherwise Vector is immutable.
  class ::Vector
    def []=(i, v)
      @elements[i] = v
    end

    # Given that self vector is a basis vector,
    # compute the component vector for v.
    def basis(v)
      self * self.inner_product(v)
    end
  end

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

    def button_down(id)
      pp id
      @cart.button_down(id) unless @cart.nil?
    end

    def button_up(id)
      pp id
      @cart.button_up(id) unless @cart.nil?
    end
  end

  class Cart
    attr_accessor :pix_meters # pixels per meter

    #@param ipwin -- the windowed canvalss this will be shown.
    #@param scale -- visual scale on the canvas.
    #@param ang   -- initial angle in degrees, 0 being the
    #                positive side of the x axis.
    #@param xpos  -- initial x position of the center of cart, in pixels.
    #@param cartmass -- in kg. included are the mass of the wheels.
    #                   We will not deal with the angular momentum
    #                   of the wheels, because that's beyond the scope
    #                   of what this is supposed to accomplish.
    #@param polemass -- in kg. The mass of the pole is assumed to all
    #                   reside at a point at
    #                   the knobby end.
    #@param bang     -- per mouse event, how much bang (acceleration in m/s) to
    #                   deliver to the cart
    def initialize(ipwin, scale: 0.50,
          ang: 90.1,
          xpos: 500.0,
          cartmass: 200.0,
          polemass: 100.10,
          bang: 0.40)
      @t = 0
      @bang = bang
      @thrust = 0 # accumulated bang
      @scale = scale
      @cart_length = 5.0 # meters
      @pix_meters = 640.0 * scale / @cart_length
      @ipwin = ipwin
      @cart = {
          image: Gosu::Image.new(ipwin, 'public/cart.png', true),
          pos: Vector[xpos / @pix_meters, 650 / @pix_meters, 0],
          vel: Vector[0.0, 0, 0], #speed in meters per second
          acc: Vector[0.0, 0, 0], #acceleration in meters per second squared
          scale: 0.2 * scale,
          length: nil, # in meters, calculated from the scaled pixel length.
          height: nil, # in meters, calculated from the scaled pixel height
          basis: {
              horiz: Vector[1.0, 0.0, 0.0], # The cart is resticted to movement on the x axis
              vert: Vector[0.0, 1.0, 0.0]}, # so these basis vectors will never change.
          force: {},
          mass: cartmass
      }
      @cart[:length] = @cart[:image].width * @cart[:scale] / @pix_meters
      @cart[:height] = @cart[:image].height * @cart[:scale] / @pix_meters

      # Pole is relative to cart, and in the image is laying horizontal.
      @pole = {
          image: Gosu::Image.new(ipwin, 'public/pole.png', true),
          z: 0,
          xoff: 0.0,
          yoff: 0.5,
          ang: ang, # angle is in degrees
          dang: 0.0, # degrees per second
          ddang: nil, # angular acceleration, degree / second ** 2
          cdang: 0.0, # degrees per second, contribution from cart
          cddang: nil, # angular acceleration, degree / second ** 2, contribution from cart
          scale: 0.2 * scale,
          force: {}, # shall hold the 2 force vectors :shaft and :radial
          basis: {}, # basis (unit) vectors
          cacc: Vector[0,0,0], # acceleration from cart
          length: nil, # in meters, calculated from the scaled pixel length.
          mass: polemass
      }
      @pole[:length] = @pole[:image].width * @pole[:scale] / @pix_meters

      # Wheels is relative to cart
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

    # External input
    # Return a thrust (acc) vector (really just x)
    # based on thrust
    def external_update
      Vector[@thrust, 0, 0]
    end

    def button_down(id)
      case id
        when MOUSE_ROLL_FOREWARD
          @thrust += @bang
        when MOUSE_ROLL_BACK
          @thrust -= @bang
      end
      pp @thrust
    end

    def button_up(id)

    end

    def update
      ## Physics updates
      @dt = @ipwin.update_interval / 1000.0
      @t += @dt

      ## Pole (Pendulum) forces, accelerations, etc.
      # basis vectors
      ang = @pole[:ang] * TORAD
      @pole[:time] = @t
      @pole[:basis][:shaft] = iShaft   = Vector[cos(ang), sin(ang),  0]
      @pole[:basis][:radial] = iRadial = Vector[sin(ang), -cos(ang), 0]
      @pole[:r] = r = iShaft * @pole[:length]
      @pole[:force][:shaft] = iShaft.basis(GV * @pole[:mass])
      @pole[:force][:radial] = radial = iRadial.basis(GV * @pole[:mass])
      # the magnitude of the radial vector goes to the torque on
      @pole[:force][:torque] = torque = r.cross_product(radial)
      @pole[:alpha] = alpha = torque / (@pole[:mass] * (@pole[:length] ** 2.0))
      @pole[:ddang] = -alpha[Z] / TORAD # the pseudo vector component Z is the signed magnitude
      @pole[:dang] += @pole[:ddang] * @dt # angular velocity
      @pole[:vel] = @pole[:basis][:radial] * (@pole[:dang] * TORAD * PI2 * @pole[:length]) #linear velocity at the pole mass
      @pole[:ang] += @pole[:dang] * @dt

      ## Cart forces from pole [:force][:shaft] and centifugal
      @cart[:time] = @t

      @pole[:force][:centrifugal] = centrifugal = (@pole[:basis][:shaft] * @pole[:vel].magnitude ** 2) * @pole[:mass]
      @cart[:force][:shaft] = shaft = @pole[:force][:shaft] # + centrifugal #FIXME cemtrifugal calculations wonky!
      @cart[:force][:horiz] = horiz = @cart[:basis][:horiz].basis shaft
      @cart[:force][:vert] = @cart[:basis][:vert].basis shaft # not that we use the vert

      # Now the horz force induces an acceleration on the cart.
      # Any additions to the acceleration vector must be done after
      # this point.
      @cart[:acc] = horiz / (@cart[:mass] + @pole[:mass] * cos(ang).abs)

      @cart[:acc] += external_update

      ## Cart acceleration also affects angular torque
      # FIXME: Note that recalculations are being done here, which
      # FIXME: are not DRY. Redo this properly later.
      @pole[:cacc] = cacc = @cart[:acc] * -1.0
      @pole[:force][:cradial] = radial = iRadial.basis(cacc * @pole[:mass])
      # the magnitude of the radial vector goes to the torque on
      @pole[:force][:ctorque] = torque = r.cross_product(radial)
      @pole[:calpha] = alpha = torque / (@pole[:mass] * (@pole[:length] ** 2.0))
      @pole[:cddang] = -alpha[Z] / TORAD # the pseudo vector component Z is the signed magnitude
      @pole[:cdang] += @pole[:cddang] * @dt
      @pole[:ang] += @pole[:cdang] * @dt

      ## Actual cart physics
      @cart[:vel][X] += @cart[:acc][X] * @dt
      @cart[:pos][X] += @cart[:vel][X] * @dt
      @cart[:x] = @cart[:pos][X] * @pix_meters
      @cart[:y] = @cart[:pos][Y] * @pix_meters

      #puts '=' * 80
      #pp({pole: @pole, cart: @cart})

      # wheels physics -- angular velocity of each wheel based
      # on the linear velocity of the cart.
      @wheels.each do |w|
        w[:dang] = 360.0 * @cart[:vel][X] / w[:circumference]
        w[:ang] += w[:dang] * @dt
      end

      # model update
      self.update_cart
    end

    # update the positions of all the compnents of the cart
    # in terms of the relative positional relationships
    def update_cart
      # center of cart is taken as (x, y), actual is (_x, _y)
      pw = @cart[:image].width * @cart[:scale]
      ph = @cart[:image].height * @cart[:scale]
      @cart[:_x] = @cart[:x] - pw / 2.0
      @cart[:_y] = @cart[:y] - ph / 2.0

      # Wheels in their respective places
      @wheels.each do |wl|
        #ww = wl[:image].width * wl[:scale]
        #wh = wl[:image].height * wl[:scale]
        wl[:_x] = @cart[:x] + wl[:xoff] * pw / 2.0
        wl[:_y] = @cart[:y] + wl[:yoff] * ph / 2.0
      end

      # Pendulum
      polew = @pole[:image].width * @pole[:scale]
      poleh = @pole[:image].height * @pole[:scale]
      @pole[:_x] = @cart[:x]
      @pole[:_y] = @cart[:y]
    end

    def draw
      @pole[:image].draw_rot( @pole[:_x],
                              @pole[:_y],
                              @pole[:z],
                              -@pole[:ang], # negative because y is inverted on the canvas
                              @pole[:xoff], @pole[:yoff],
                              @pole[:scale],
                              @pole[:scale])

      @cart[:image].draw(@cart[:_x],
                             @cart[:_y],
                             0,
                             @cart[:scale],
                             @cart[:scale])

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
