$MKXP = !!defined?(System)

def mkxp?
  return $MKXP
end

def pbSetWindowText(string)
  if mkxp?
    System.set_window_title(string || System.game_title)
  else
    Win32API.SetWindowText(string || "RGSS Player")
  end
end

class Bitmap
  if mkxp?
    alias mkxp_draw_text draw_text
    def draw_text(x, y, width, height, text, align = 0)
      height = text_size(text).height
      mkxp_draw_text(x, y, width, height, text, align)
    end
  end
end

if !mkxp?
  module System
    def self.platform; "Windows"; end
  end
end

if mkxp?
  alias old_load_data load_data
  def load_data(filename)
    return old_load_data(filename) if filename["Data/PkmnAnimations.rxdata"]
    File.open(filename, 'rb'){|f| return Marshal.load(f.read)}
  end
end
