$VERBOSE = nil
Font.default_shadow = false if Font.respond_to?(:default_shadow)
Graphics.frame_rate = 60

def mkxp?
  return $MKXP
end

def pbSetWindowText(string)
  System.set_window_title(string || System.game_title)
end

class Bitmap
  alias mkxp_draw_text draw_text unless method_defined?(:mkxp_draw_text)
  def draw_text(x, y, width, height, text, align = 0)
    height = text_size(text).height
    mkxp_draw_text(x, y, width, height, text, align)
  end
end

class Object
  alias full_inspect inspect

  def inspect; to_s; end

  def deep_clone
    return @deep_cloning_obj if @deep_cloning
    @deep_cloning_obj = clone
    @deep_cloning_obj.instance_variables.each do |var|
      val = @deep_cloning_obj.instance_variable_get(var)
      begin
        if val.frozen?
          val = val
        else
          @deep_cloning = true
          val = val.deep_clone
        end
      rescue TypeError
        next
      ensure
        @deep_cloning = false
      end
      @deep_cloning_obj.instance_variable_set(var, val)
    end
    deep_cloning_obj = @deep_cloning_obj
    @deep_cloning_obj = nil
    return deep_cloning_obj
  end
end

#===============================================================================
# Ensure required method definitions
#===============================================================================
module Graphics
  def self.delta_s
    return self.delta.to_f / 1_000_000
  end

  def self.width; return SCREEN_WIDTH.to_i; end

  def self.height; return SCREEN_HEIGHT.to_i; end
end

def pbSetResizeFactor(factor)
  if !$ResizeInitialized
    Graphics.resize_screen(SCREEN_WIDTH, SCREEN_HEIGHT)
    $ResizeInitialized = true
  end
  if factor < 0 || factor == 4
    Graphics.fullscreen = true if !Graphics.fullscreen
  else
    Graphics.fullscreen = false if Graphics.fullscreen
    Graphics.scale = (factor + 1) * 0.5
    Graphics.center
  end
end

ESSENTIALS_VERSION = "Bushido"
ERROR_TEXT = ""
GAME_VERSION = "2.0.0"
