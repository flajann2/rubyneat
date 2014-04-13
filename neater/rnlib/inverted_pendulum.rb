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
    attr_reader :pix_width, :pix_height

    def initialize(width: 1280, height: 1024)
      super(@pix_width = width, @pix_height = height, false)
      self.caption = "RubyNEAT Inverted Pendulum Simulation -- use mouse wheel to bang the cart."

      @background = {image: Gosu::Image.new(self, 'public/background.png', true),
                     x: 0,
                     y: 0,
                     scale: 1.0
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
      @cart.button_down(id) unless @cart.nil?
    end

    def button_up(id)
      @cart.button_up(id) unless @cart.nil?
    end
  end

  class Cart
    attr_accessor :pix_meters # pixels per meter
    attr_accessor :ipwin

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
    def initialize(ipwin: nil,
          scale: 0.50,
          ang: 90.1,
          xpos: 500.0,
          ypos: 845.0,
          cartmass: 200.0,
          polemass: 100.10,
          bang: 10.0,       # acceleration on a bang event
          thrust_decay: 2.0, # thrust decay percentage per second
          window_pix_width: 1280,
          update_interval: 16.666666,
          naked: false)
      @t = 0
      @bang = bang
      @thrust = 0 # accumulated bang
      @thrust_decay = thrust_decay
      @scale = scale
      @cart_length = 5.0 # meters
      @pix_meters = 640.0 * scale / @cart_length
      @ipwin = ipwin
      @pix_width = @ipwin.nil? ? window_pix_width : @ipwin.pix_width
      @update_interval = ipwin.nil? ? update_interval : @ipwin.update_interval
      @cart = {
          pos: Vector[xpos / @pix_meters, ypos / @pix_meters, 0],
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

      # Pole is relative to cart, and in the image is laying horizontal.
      @pole = {
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

      # Wheels is relative to cart
      @wheels = [
          {
            ang: 0,
            dang: 100, #FIXME: delete this for this will be overwritten anyway
            xoff: -0.7, # percentage from center
            yoff: 0.4, # percentage from center
            scale: 0.2 * scale
          },
          {
            ang: 0,
            dang: 12.33, #FIXME: delete this for this will be overwritten anyway
            xoff: 0.7,
            yoff: 0.4,
            scale: 0.2 * scale
          }
      ]
    end

    def ipwin=(ipwin)
      @ipwin = ipwin
      @cart[:image] = Gosu::Image.new(ipwin, 'public/cart.png', true)
      @pole[:image] = Gosu::Image.new(ipwin, 'public/pole.png', true)
      @wheels.each {|w|
        w[:image] = Gosu::Image.new(ipwin, 'public/wheel.png', true)
        # radius of wheel in meters, need this for rotational velocity calculation
        w[:radius] = w[:image].width * w[:scale] / @pix_meters / 2.0
        w[:circumference] = w[:radius] * 2.0 * PI
      }

      @cart[:length] = @cart[:image].width * @cart[:scale] / @pix_meters
      @cart[:height] = @cart[:image].height * @cart[:scale] / @pix_meters
      @pole[:length] = @pole[:image].width * @pole[:scale] / @pix_meters
    end

    # Provide a bang for the cart.
    # Return a thrust (acc) vector (really just x)
    # based on thrust
    #@param bb -- bang factor, normally -1, 0, or 1, but could be
    #             other values based on being a multiplier of the actual bang to be
    #             applied.
    def big_bang(bb = 0)
      # FIXME: this is temporary. Eventually this will call a callback in the Neater script.
      v = Vector[@thrust, 0, 0]
      @thrust += @bang * bb
      @thrust -= @thrust * @thrust_decay * @dt
      v
    end

    def button_down(id)
      big_bang  case id
                  when MOUSE_ROLL_FOREWARD
                    1.0
                  when MOUSE_ROLL_BACK
                    -1.0
                  else
                    0
                end
    end

    def button_up(id)
      # no op for now.
    end

    def update
      ## Physics updates
      @dt = @update_interval / 1000.0
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

      @cart[:acc] += big_bang

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
      @pole[:image].draw_rot( @pole[:_x] % @pix_width,
                              @pole[:_y],
                              @pole[:z],
                              -@pole[:ang], # negative because y is inverted on the canvas
                              @pole[:xoff], @pole[:yoff],
                              @pole[:scale],
                              @pole[:scale])

      @cart[:image].draw(@cart[:_x] % @pix_width,
                             @cart[:_y],
                             0,
                             @cart[:scale],
                             @cart[:scale])

      @wheels.each do |wh|
        wh[:image].draw_rot(wh[:_x] % @pix_width,
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

      def cart(&block)
        @cart_params = block.()
        unless @cart_params[:naked]
          @cart = @ipwin.cart = Cart.new({ipwin: @ipwin}.merge @cart_params)
        else
          @cart = Cart.new(@cart_params)
        end
      end

      def show(cart: @cart, &block)
        unless cart.nil?
          @ipwin.cart = cart
          cart.ipwin = @ipwin
        end

        @ipwin.show
      end
      block.(@ipwin)
    end
  end
end
