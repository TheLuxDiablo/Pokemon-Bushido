module Input
  class << self
    alias __fast_forward__update update unless method_defined?(:__fast_forward__update)
  end

  def self.update
    __fast_forward__update
    if $CanToggle && trigger?(Input::R) #remap your Q button on the F1 screen to change your speedup switch
      $GameSpeed += 1
      $GameSpeed = 0 if $GameSpeed >= SPEEDUP_STAGES.size
      if $game_temp
        $game_temp.ff_sprite.opacity = 0
        $game_temp.ff_sprite.src_rect.x = $game_temp.ff_sprite.src_rect.height * $GameSpeed
        $game_temp.ff_timer = Graphics.frame_rate * 2
      end
    end
    return if !$game_temp
    if $game_temp.ff_timer <= 0
      $game_temp.ff_sprite.opacity = 0
      $game_temp.ff_timer = 0
    end
  end
end

class Game_Temp
  attr_accessor :ff_sprite
  attr_accessor :ff_vp
  attr_accessor :ff_timer

  def ff_sprite
    if !@ff_sprite
      @ff_sprite = Sprite.new(self.ff_vp)
      @ff_sprite.bitmap = RPG::Cache.load_bitmap("Graphics/Pictures/ff_icon") rescue Bitmap.new(32, 32)
      @ff_sprite.x = 8
      @ff_sprite.y = 8
      @ff_sprite.opacity = 0
      @ff_sprite.src_rect.width = @ff_sprite.src_rect.height
    end
    return @ff_sprite
  end

  def ff_vp
    if !@ff_vp
      @ff_vp = Viewport.new(0, 0, Graphics.width / 4, Graphics.height / 4)
      @ff_vp.z = 9999999
    end
    return @ff_vp
  end

  def ff_timer
    @ff_timer = 0 if !@ff_timer
    return @ff_timer
  end

  def update_ff_sprite
    return if self.ff_timer <= 0
    self.ff_timer -= 1
    if self.ff_timer >= ((Graphics.frame_rate / 4) * 7)
      self.ff_sprite.opacity += (255 / (Graphics.frame_rate / 4))
    elsif self.ff_timer <= (Graphics.frame_rate / 4)
      self.ff_sprite.opacity -= (255 / (Graphics.frame_rate / 4))
    else
      self.ff_sprite.opacity = 255
    end
    self.ff_sprite.update
  end
end

SPEEDUP_STAGES = [1, 2, 3]
$GameSpeed = 0
$frame = 0
$CanToggle = $DEBUG

module Graphics
  class << self
    alias __fast_forward__update update unless method_defined?(:__fast_forward__update)
    alias __fast_forward__snap_to_bitmap snap_to_bitmap unless method_defined?(:__fast_forward__snap_to_bitmap)
  end

  def self.snap_to_bitmap
    old_timer = $game_temp&.ff_timer
    old_opac  = $game_temp&.ff_sprite.opacity
    $game_temp&.ff_timer = 0
    $game_temp&.ff_sprite.opacity = 0
    ret = __fast_forward__snap_to_bitmap
    $game_temp&.ff_timer = old_timer
    $game_temp&.ff_sprite.opacity = old_opac
    return ret
  end

  def self.update
    $frame += 1
    return unless $frame % SPEEDUP_STAGES[$GameSpeed] == 0
    __fast_forward__update
    # $frame = 0
    $game_temp&.update_ff_sprite
  end
end

def pbDisallowSpeedup
  $CanToggle = false
  $GameSpeed = 0
end

def pbAllowSpeedup
  $CanToggle = true
end

alias __speedup__pbEnterText pbEnterText unless defined?(__speedup__pbEnterText)
def pbEnterText(*args)
  old_toggle = $CanToggle
  old_speed  = $GameSpeed
  $CanToggle = false
  $GameSpeed = 0
  ret = __speedup__pbEnterText(*args)
  $CanToggle = old_toggle
  $GameSpeed = old_speed
  return ret
end

PluginManager.register({
  :name => "Speedup Switch",
  :credits => ["Golisopod User", "Marin"]
})
