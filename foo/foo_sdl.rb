# from http://moriq.tdiary.net/20051006.html 
# Apollo with Ruby/SDL
require 'phi'
require 'sdl'

# Create form
form = Phi::Form.new
$terminated = false
form.on_close{ $terminated = true }
form.caption = "Ruby/SDL on Phi::Form"
# Create a panel on new form
panel = Phi::Panel.new(form)
panel.align = Phi::AL_LEFT

# Put SDL window on panel with WINDOWID hack
SDL.putenv("SDL_VIDEODRIVER=windib")
SDL.putenv("SDL_WINDOWID=#{panel.handle}")
form.show

# initialize SDL
SDL.init(SDL::INIT_VIDEO)
screen = SDL.setVideoMode(640, 480, 16, SDL::SWSURFACE)

# main loop
unless $terminated
  while event = SDL::Event2.poll
    case event
    when SDL::Event2::KeyDown, SDL::Event2::Quit
      exit
    end
  end

  sleep 0.05
end
