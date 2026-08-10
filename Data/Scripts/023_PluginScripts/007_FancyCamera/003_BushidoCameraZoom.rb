#===============================================================================
# Bushido FancyCamera Zoom Extension
# Pokemon Essentials v18.1 / Pokemon Bushido
# Requires the v18 FancyCamera port to be loaded first.
#
# FancyCamera handles camera position/focus/reset.
# This script ONLY adds live overworld zoom.
#
# No screenshots.
# No dialogue hooks.
# No UI scaling.
#===============================================================================

module BushidoCameraZoom
  VERSION     = "1.2.0"
  ALLOWED_ZOOMS = [1.0, 2.0, 4.0]
  DEFAULT_ZOOM = 1.0

  @zoom         = DEFAULT_ZOOM
  @zoom_start   = DEFAULT_ZOOM
  @zoom_target  = DEFAULT_ZOOM
  @zoom_frames  = 0
  @zoom_elapsed = 0
  @zoom_easing  = :ease_in_out
  @last_frame   = -1

  def self.clamp(v, lo, hi)
    v = lo if v < lo
    v = hi if v > hi
    return v
  end

  def self.pixel_zoom(value)
    value = value.to_f
    best = ALLOWED_ZOOMS[0]
    best_dist = (value - best).abs
    ALLOWED_ZOOMS.each do |z|
      dist = (value - z).abs
      if dist < best_dist
        best = z
        best_dist = dist
      end
    end
    return best
  end

  def self.ease(t, kind)
    t = clamp(t.to_f, 0.0, 1.0)
    case kind
    when :linear
      return t
    when :ease_in
      return t * t
    when :ease_out
      return 1.0 - ((1.0 - t) * (1.0 - t))
    when :smooth
      return t * t * (3.0 - 2.0 * t)
    else
      return (t < 0.5) ? (2.0 * t * t) :
                         (1.0 - (((-2.0 * t + 2.0) ** 2) / 2.0))
    end
  end

  def self.value
    return @zoom || DEFAULT_ZOOM
  end

  def self.active?
    return (value - 1.0).abs > 0.0001
  end

  def self.set(value, frames=20, easing=:ease_in_out, wait=false)
    # The requested resting zoom always resolves to an exact pixel tier.
    # During the transition, fractional values are allowed so the camera
    # can visibly push in/out. Once complete, it locks exactly to the tier.
    value = pixel_zoom(value)

    @zoom_start   = self.value
    @zoom_target  = value
    @zoom_frames  = [frames.to_i, 0].max
    @zoom_elapsed = 0
    @zoom_easing  = easing

    if @zoom_frames <= 0
      @zoom = @zoom_target
    end

    pbWait(frames.to_i) if wait && frames.to_i > 0
  end

  def self.reset(frames=20, easing=:ease_in_out, wait=false)
    self.set(1.0, frames, easing, wait)
  end

  def self.update
    frame = Graphics.frame_count
    return if @last_frame == frame
    @last_frame = frame

    return if !@zoom_frames || @zoom_frames <= 0

    @zoom_elapsed += 1

    # Fractional zoom is permitted only while actively transitioning.
    t = @zoom_elapsed.to_f / @zoom_frames.to_f
    e = ease(t, @zoom_easing)
    @zoom = @zoom_start + ((@zoom_target - @zoom_start) * e)

    if @zoom_elapsed >= @zoom_frames
      # Hard-lock to the exact tier once motion stops.
      @zoom = @zoom_target
      @zoom_frames = 0
    end
  end

  def self.transform_sprite(sprite)
    return if !sprite || sprite.disposed?
    return if !active?

    state = sprite.instance_variable_get(:@__bushido_zoom_original)
    if !state
      state = [sprite.x, sprite.y, sprite.zoom_x, sprite.zoom_y]
      sprite.instance_variable_set(:@__bushido_zoom_original, state)
    end

    z  = value
    cx = Graphics.width / 2.0
    cy = Graphics.height / 2.0

    new_x = cx + ((state[0].to_f - cx) * z)
    new_y = cy + ((state[1].to_f - cy) * z)

    # While moving between tiers, preserve smooth subpixel motion.
    # At rest, lock back onto whole pixels.
    if @zoom_frames && @zoom_frames > 0
      sprite.x = new_x
      sprite.y = new_y
    else
      sprite.x = new_x.round
      sprite.y = new_y.round
    end
    sprite.zoom_x = state[2].to_f * z
    sprite.zoom_y = state[3].to_f * z
  end

  def self.restore_sprite(sprite)
    return if !sprite || sprite.disposed?

    state = sprite.instance_variable_get(:@__bushido_zoom_original)
    return if !state

    sprite.x      = state[0]
    sprite.y      = state[1]
    sprite.zoom_x = state[2]
    sprite.zoom_y = state[3]

    sprite.instance_variable_set(:@__bushido_zoom_original, nil)
  end

  def self.character_children(sprite)
    ret = [sprite]

    reflection = sprite.instance_variable_get(:@reflection) rescue nil
    if reflection
      child = reflection.instance_variable_get(:@sprite) rescue nil
      ret << child if child
    end

    shadow = sprite.instance_variable_get(:@shadowoverworldbitmap) rescue nil
    if shadow
      child = shadow.instance_variable_get(:@sprite) rescue nil
      ret << child if child
    end

    surf = sprite.instance_variable_get(:@surfbase) rescue nil
    if surf
      surf.instance_variables.each do |ivar|
        obj = surf.instance_variable_get(ivar) rescue nil
        ret << obj if obj.is_a?(Sprite)
      end
    end

    return ret.compact.uniq
  end
end


#===============================================================================
# CustomTilemap
# Scales Bushido's actual tile sprites live.
#===============================================================================
class CustomTilemap
  alias bushido_zoom_update update unless method_defined?(:bushido_zoom_update)

  def update
    bushido_zoom_restore_tiles
    bushido_zoom_update
    bushido_zoom_apply_tiles
  end

  def bushido_zoom_tile_sprites
    ret = []
    ret << @layer0 if @layer0 && !@layer0.disposed?
    ret << @flash if @flash && !@flash.disposed?

    if @tiles
      @tiles.each do |obj|
        ret << obj if obj.is_a?(Sprite) && !obj.disposed?
      end
    end

    if @autosprites
      @autosprites.each do |obj|
        ret << obj if obj.is_a?(Sprite) && !obj.disposed?
      end
    end

    return ret.uniq
  end

  def bushido_zoom_restore_tiles
    bushido_zoom_tile_sprites.each do |sprite|
      BushidoCameraZoom.restore_sprite(sprite)
    end
  end

  def bushido_zoom_apply_tiles
    return if !BushidoCameraZoom.active?
    bushido_zoom_tile_sprites.each do |sprite|
      BushidoCameraZoom.transform_sprite(sprite)
    end
  end
end


#===============================================================================
# Sprite_Character
# Covers map events, player, follower, shadows and reflections.
#===============================================================================
class Sprite_Character
  alias bushido_zoom_character_update update unless method_defined?(:bushido_zoom_character_update)

  def update
    BushidoCameraZoom.character_children(self).each do |sprite|
      BushidoCameraZoom.restore_sprite(sprite)
    end

    bushido_zoom_character_update

    if BushidoCameraZoom.active?
      BushidoCameraZoom.character_children(self).each do |sprite|
        BushidoCameraZoom.transform_sprite(sprite)
      end
    end
  end
end


#===============================================================================
# Spriteset_Map
# Drives the zoom animation once per frame.
#===============================================================================
class Spriteset_Map
  alias bushido_zoom_spriteset_update update unless method_defined?(:bushido_zoom_spriteset_update)

  def update
    BushidoCameraZoom.update
    bushido_zoom_spriteset_update
  end
end


#===============================================================================
# Public helpers
#===============================================================================
def pbCameraZoom(value, frames=20, easing=:ease_in_out, wait=false)
  BushidoCameraZoom.set(value, frames, easing, wait)
end

def pbCameraZoomReset(frames=20, easing=:ease_in_out, wait=false)
  BushidoCameraZoom.reset(frames, easing, wait)
end


class Interpreter
  def camZoom(value, frames=20, easing=:ease_in_out, wait=false)
    pbCameraZoom(value, frames, easing, wait)
  end

  def camZoomReset(frames=20, easing=:ease_in_out, wait=false)
    pbCameraZoomReset(frames, easing, wait)
  end
end
