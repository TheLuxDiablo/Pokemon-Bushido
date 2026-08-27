#===============================================================================
# Bushido Environmental Lights
# Pokemon Essentials v18.1 / RGSS1
#
# 006_PointLights.rb
#
# Event-name setup only. No event calls or Parallel Processes are required.
#
# Normal light:
#   Light(0,0)
#   Lantern Light(8,-16)
#
# Fire:
#   Fire(0,0)
#   Bonfire Fire(-4,-12)
#
# Offsets are PIXELS:
#   X: negative = left, positive = right
#   Y: negative = up,   positive = down
#
# Safety/scaling design:
# - Spriteset_Map is never modified.
# - No recursive methods exist in this script.
# - Scene_Map container discovery is iterative and hard-bounded.
# - Connected-map duplicates are deduplicated by logical event identity.
# - Effects never write state into Game_Event or Game_Map.
# - Generated glow/particle bitmaps are cached and shared by every effect.
# - Off-screen effects keep no rendered sprites, allowing many tagged events.
#===============================================================================

module BushidoPointLights
  #=============================================================================
  # Shared
  #=============================================================================

  PIXEL_SIZE       = 2
  BASE_Y_OFFSET    = -16
  BLEND_TYPE       = 1
  EFFECT_Z         = 99999
  PARTICLE_Z       = 100000

  SCAN_INTERVAL    = 10
  INITIAL_DELAY    = 2

  # No recursive traversal. The Scene_Map scan uses an iterative queue and
  # never inspects deeper than this many Array/Hash layers.
  SPRITESET_SCAN_DEPTH      = 4
  SPRITESET_SCAN_NODE_LIMIT = 4096

  # FX outside this margin are not rendered. The logical effect remains in the
  # manager and wakes back up as soon as its source approaches the screen.
  ACTIVE_MARGIN = 128

  #=============================================================================
  # Point Light
  #=============================================================================

  INNER_RADIUS = 24
  OUTER_RADIUS = 48

  INNER_COLOR = Color.new(255, 225, 150)
  OUTER_COLOR = Color.new(255, 205, 110)

  INNER_OPACITY = 140
  OUTER_OPACITY = 80

  INNER_PULSE_SCALE = 0.045
  OUTER_PULSE_SCALE = 0.075

  INNER_PULSE_SPEED = 0.035
  OUTER_PULSE_SPEED = 0.065

  OUTER_PULSE_OFFSET = 1.7

  INNER_OPACITY_PULSE = 12
  OUTER_OPACITY_PULSE = 16

  #=============================================================================
  # Fire
  #=============================================================================

  FIRE_INNER_RADIUS = 24
  FIRE_OUTER_RADIUS = 46

  FIRE_INNER_COLOR = Color.new(255, 118, 45)
  FIRE_OUTER_COLOR = Color.new(235, 48, 30)

  FIRE_INNER_OPACITY = 105
  FIRE_OUTER_OPACITY = 55

  # Fire remains visible during daytime, but its cast light is softer.
  FIRE_DAY_STRENGTH   = 0.68
  FIRE_NIGHT_STRENGTH = 1.0

  FIRE_INNER_SCALE_MIN = 0.96
  FIRE_INNER_SCALE_MAX = 1.04

  FIRE_OUTER_SCALE_MIN = 0.97
  FIRE_OUTER_SCALE_MAX = 1.06

  FIRE_INNER_FLICKER = 12
  FIRE_OUTER_FLICKER = 8

  FIRE_PARTICLE_COUNT   = 5
  FIRE_PARTICLE_OPACITY = 180

  FIRE_PARTICLE_SPREAD_X = 10
  FIRE_PARTICLE_SPREAD_Y = 4

  FIRE_PARTICLE_RISE_MIN = 16
  FIRE_PARTICLE_RISE_MAX = 28

  FIRE_PARTICLE_SPEED_MIN = 0.30
  FIRE_PARTICLE_SPEED_MAX = 0.60

  FIRE_PARTICLE_DRIFT = 0.16

  FIRE_PARTICLE_SIZE_SMALL = 2
  FIRE_PARTICLE_SIZE_LARGE = 4

  #=============================================================================
  # Runtime Bitmap Cache
  #=============================================================================

  @bitmap_cache = {}

  def self.cached_bitmap(key)
    bitmap = @bitmap_cache[key]

    begin
      return bitmap if bitmap && !bitmap.disposed?
    rescue
    end

    bitmap = yield
    @bitmap_cache[key] = bitmap
    return bitmap
  end

  def self.light_inner_bitmap
    return cached_bitmap(:light_inner) {
      make_glow(INNER_RADIUS, INNER_COLOR)
    }
  end

  def self.light_outer_bitmap
    return cached_bitmap(:light_outer) {
      make_glow(OUTER_RADIUS, OUTER_COLOR)
    }
  end

  def self.fire_inner_bitmap
    return cached_bitmap(:fire_inner) {
      make_glow(FIRE_INNER_RADIUS, FIRE_INNER_COLOR)
    }
  end

  def self.fire_outer_bitmap
    return cached_bitmap(:fire_outer) {
      make_glow(FIRE_OUTER_RADIUS, FIRE_OUTER_COLOR)
    }
  end

  def self.fire_particle_bitmap(size, palette)
    key = [:fire_particle, size, palette]

    return cached_bitmap(key) {
      color = nil

      case palette
      when 0
        color = Color.new(255, 205, 95, 255)
      when 1
        color = Color.new(255, 105, 40, 255)
      else
        color = Color.new(235, 48, 30, 255)
      end

      bitmap = Bitmap.new(size, size)
      bitmap.fill_rect(0, 0, size, size, color)
      bitmap
    }
  end

  #=============================================================================
  # Time
  #=============================================================================

  def self.night?
    begin
      time = pbGetTimeNow

      if defined?(PBDayNight)
        begin
          return PBDayNight.isNight?(time)
        rescue
        end

        begin
          return PBDayNight.isNight?
        rescue
        end
      end

      hour = time.hour
      return (hour >= 20 || hour < 6)
    rescue
      return false
    end
  end

  #=============================================================================
  # Sprite / Event Helpers
  #=============================================================================

  def self.character_from_sprite(sprite)
    return nil if !sprite

    begin
      return sprite.instance_variable_get(:@character)
    rescue
      return nil
    end
  end

  def self.event_name_from_sprite(sprite)
    character = character_from_sprite(sprite)
    return "" if !character

    begin
      event_data = character.instance_variable_get(:@event)
      return event_data.name.to_s if event_data
    rescue
    end

    return ""
  end

  def self.light_sprite?(sprite)
    name = event_name_from_sprite(sprite)
    return !!(name =~ /Light\s*\(\s*-?\d+\s*,\s*-?\d+\s*\)/i)
  end

  def self.fire_sprite?(sprite)
    name = event_name_from_sprite(sprite)
    return !!(name =~ /Fire\s*\(\s*-?\d+\s*,\s*-?\d+\s*\)/i)
  end

  #=============================================================================
  # Pixel Offsets
  #=============================================================================

  def self.light_offset(sprite)
    return parse_offset(event_name_from_sprite(sprite), "Light")
  end

  def self.fire_offset(sprite)
    return parse_offset(event_name_from_sprite(sprite), "Fire")
  end

  def self.parse_offset(name, tag)
    regex = /#{tag}\s*\(\s*(-?\d+)\s*,\s*(-?\d+)\s*\)/i

    if name =~ regex
      return [$1.to_i, $2.to_i]
    end

    return [0, 0]
  end

  #=============================================================================
  # Logical Event Identity
  #=============================================================================

  def self.event_id_from_character(character)
    return nil if !character

    begin
      value = character.id
      return value if !value.nil?
    rescue
    end

    begin
      value = character.instance_variable_get(:@id)
      return value if !value.nil?
    rescue
    end

    return nil
  end

  def self.map_id_from_character(character)
    return nil if !character

    begin
      value = character.map_id
      return value if !value.nil?
    rescue
    end

    begin
      value = character.instance_variable_get(:@map_id)
      return value if !value.nil?
    rescue
    end

    begin
      map = character.instance_variable_get(:@map)

      if map
        begin
          value = map.map_id
          return value if !value.nil?
        rescue
        end

        begin
          value = map.instance_variable_get(:@map_id)
          return value if !value.nil?
        rescue
        end
      end
    rescue
    end

    return nil
  end

  def self.map_from_spriteset(spriteset)
    return nil if !spriteset

    begin
      map = spriteset.instance_variable_get(:@map)
      return map if map
    rescue
    end

    return nil
  end

  def self.map_id_from_spriteset(spriteset)
    map = map_from_spriteset(spriteset)

    if map
      begin
        value = map.map_id
        return value if !value.nil?
      rescue
      end

      begin
        value = map.instance_variable_get(:@map_id)
        return value if !value.nil?
      rescue
      end
    end

    begin
      value = spriteset.instance_variable_get(:@map_id)
      return value if !value.nil?
    rescue
    end

    return nil
  end

  def self.logical_event_key(sprite, spriteset)
    character = character_from_sprite(sprite)
    return nil if !character

    event_id = event_id_from_character(character)
    map_id = map_id_from_character(character)
    map_id = map_id_from_spriteset(spriteset) if map_id.nil?

    if !map_id.nil? && !event_id.nil?
      return [map_id.to_i, event_id.to_i]
    end

    # If map IDs aren't exposed, use the map object's runtime identity.
    map = map_from_spriteset(spriteset)

    if map && !event_id.nil?
      return [:map_object, map.object_id, event_id.to_i]
    end

    # Final fallback. Separate Sprite_Characters that share the exact same
    # Game_Event object still deduplicate here.
    return [:character, character.object_id]
  end

  #=============================================================================
  # Duplicate Source Selection
  #=============================================================================

  def self.sprite_score(sprite)
    return -100000 if !sprite

    begin
      return -100000 if sprite.disposed?
    rescue
      return -100000
    end

    score = 0

    begin
      score += 20 if sprite.visible
    rescue
    end

    begin
      viewport = sprite.viewport

      if viewport
        begin
          score += 8 if viewport.visible
        rescue
          score += 2
        end
      end
    rescue
    end

    begin
      if source_near_screen?(sprite)
        score += 40
      end
    rescue
    end

    return score
  end

  def self.source_near_screen?(sprite)
    return false if !sprite

    begin
      x = sprite.x
      y = sprite.y

      return false if x < -ACTIVE_MARGIN
      return false if y < -ACTIVE_MARGIN
      return false if x > Graphics.width + ACTIVE_MARGIN
      return false if y > Graphics.height + ACTIVE_MARGIN

      return true
    rescue
      return false
    end
  end

  #=============================================================================
  # Pixelated Radial Glow
  #=============================================================================

  def self.make_glow(radius, color)
    size = (radius * 2) + PIXEL_SIZE
    bitmap = Bitmap.new(size, size)

    center = size / 2.0
    max_distance = radius.to_f

    y = 0

    while y < size
      x = 0

      while x < size
        sample_x = x + (PIXEL_SIZE / 2.0)
        sample_y = y + (PIXEL_SIZE / 2.0)

        dx = sample_x - center
        dy = sample_y - center

        distance = Math.sqrt((dx * dx) + (dy * dy))

        if distance <= max_distance
          strength = 1.0 - (distance / max_distance)
          strength = Math.sqrt(strength)
          alpha = (255 * strength).to_i

          bitmap.fill_rect(
            x,
            y,
            PIXEL_SIZE,
            PIXEL_SIZE,
            Color.new(color.red, color.green, color.blue, alpha)
          )
        end

        x += PIXEL_SIZE
      end

      y += PIXEL_SIZE
    end

    return bitmap
  end

  def self.random_float(minimum, maximum)
    amount = rand(1000) / 1000.0
    return minimum + (amount * (maximum - minimum))
  end

  #=============================================================================
  # Scene_Map Spriteset Discovery
  #
  # This is intentionally iterative. There are NO recursive calls here.
  #=============================================================================

  def self.scene_spritesets(scene)
    results = []
    seen = {}
    queue = []

    return results if !scene

    begin
      scene.instance_variables.each do |variable|
        value = scene.instance_variable_get(variable)
        queue.push([value, 0]) if value
      end
    rescue
      return results
    end

    index = 0
    processed = 0

    while index < queue.length
      pair = queue[index]
      index += 1

      value = pair[0]
      depth = pair[1]

      next if !value
      next if depth > SPRITESET_SCAN_DEPTH

      processed += 1
      break if processed > SPRITESET_SCAN_NODE_LIMIT

      object_key = value.object_id
      next if seen[object_key]
      seen[object_key] = true

      if defined?(Spriteset_Map) && value.is_a?(Spriteset_Map)
        results.push(value)
        next
      end

      if value.is_a?(Array)
        value.each do |entry|
          queue.push([entry, depth + 1]) if entry
        end
      elsif value.is_a?(Hash)
        value.each_value do |entry|
          queue.push([entry, depth + 1]) if entry
        end
      end
    end

    return results
  end

  def self.character_sprites_from_spriteset(spriteset)
    return [] if !spriteset

    begin
      sprites = spriteset.instance_variable_get(:@character_sprites)
      return sprites if sprites
    rescue
    end

    return []
  end
end


#===============================================================================
# Point Light
#===============================================================================

class BushidoPointLight
  attr_reader :source_sprite

  def initialize(character_sprite)
    @source_sprite = character_sprite
    @viewport = nil
    @outer = nil
    @inner = nil
    @pulse_time = rand(1000)
  end

  def source_viewport
    begin
      return @source_sprite.viewport
    rescue
      return nil
    end
  end

  def rebind_source(character_sprite)
    return if !character_sprite
    return if @source_sprite.equal?(character_sprite)

    old_viewport = source_viewport
    @source_sprite = character_sprite
    new_viewport = source_viewport

    dispose_graphics if !old_viewport.equal?(new_viewport)
  end

  def ensure_graphics
    return if @inner && @outer

    @viewport = source_viewport

    @outer = Sprite.new(@viewport)
    @inner = Sprite.new(@viewport)

    @outer.bitmap = BushidoPointLights.light_outer_bitmap
    @inner.bitmap = BushidoPointLights.light_inner_bitmap

    setup_sprite(@outer)
    setup_sprite(@inner)

    @inner.opacity = BushidoPointLights::INNER_OPACITY
    @outer.opacity = BushidoPointLights::OUTER_OPACITY
  end

  def setup_sprite(sprite)
    sprite.ox = sprite.bitmap.width / 2
    sprite.oy = sprite.bitmap.height / 2
    sprite.blend_type = BushidoPointLights::BLEND_TYPE
    sprite.z = BushidoPointLights::EFFECT_Z
  end

  def update
    return if source_disposed?

    if !BushidoPointLights.source_near_screen?(@source_sprite)
      hide_graphics
      return
    end

    ensure_graphics
    update_position
    update_visibility
    update_pulse
  end

  def hide_graphics
    begin
      @inner.visible = false if @inner && !@inner.disposed?
    rescue
    end

    begin
      @outer.visible = false if @outer && !@outer.disposed?
    rescue
    end
  end

  def update_position
    offset = BushidoPointLights.light_offset(@source_sprite)

    x = @source_sprite.x + offset[0]
    y = @source_sprite.y + BushidoPointLights::BASE_Y_OFFSET + offset[1]

    @inner.x = x
    @inner.y = y
    @outer.x = x
    @outer.y = y
  end

  def update_visibility
    visible = BushidoPointLights.night?
    @inner.visible = visible
    @outer.visible = visible
  end

  def update_pulse
    return if !@inner.visible

    @pulse_time += 1.0

    inner_wave =
      Math.sin(
        @pulse_time * BushidoPointLights::INNER_PULSE_SPEED
      )

    outer_wave =
      Math.sin(
        (@pulse_time * BushidoPointLights::OUTER_PULSE_SPEED) +
        BushidoPointLights::OUTER_PULSE_OFFSET
      )

    inner_scale =
      1.0 + (inner_wave * BushidoPointLights::INNER_PULSE_SCALE)

    outer_scale =
      1.0 + (outer_wave * BushidoPointLights::OUTER_PULSE_SCALE)

    @inner.zoom_x = inner_scale
    @inner.zoom_y = inner_scale
    @outer.zoom_x = outer_scale
    @outer.zoom_y = outer_scale

    inner_opacity =
      BushidoPointLights::INNER_OPACITY +
      (inner_wave * BushidoPointLights::INNER_OPACITY_PULSE).to_i

    outer_opacity =
      BushidoPointLights::OUTER_OPACITY +
      (outer_wave * BushidoPointLights::OUTER_OPACITY_PULSE).to_i

    inner_opacity = 0 if inner_opacity < 0
    inner_opacity = 255 if inner_opacity > 255

    outer_opacity = 0 if outer_opacity < 0
    outer_opacity = 255 if outer_opacity > 255

    @inner.opacity = inner_opacity
    @outer.opacity = outer_opacity
  end

  def source_disposed?
    return true if !@source_sprite

    begin
      return @source_sprite.disposed?
    rescue
      return true
    end
  end

  def dispose_sprite(sprite)
    return if !sprite

    # The bitmap is shared by every effect and is owned by the module cache.
    begin
      sprite.dispose if !sprite.disposed?
    rescue
    end
  end

  def dispose_graphics
    dispose_sprite(@inner)
    dispose_sprite(@outer)

    @inner = nil
    @outer = nil
    @viewport = nil
  end

  def dispose
    dispose_graphics
    @source_sprite = nil
  end
end


#===============================================================================
# Fire Particle
#===============================================================================

class BushidoFireParticle
  def initialize(viewport)
    @sprite = Sprite.new(viewport)
    @sprite.z = BushidoPointLights::PARTICLE_Z
    @sprite.blend_type = BushidoPointLights::BLEND_TYPE

    @active = false
    @relative_x = 0.0
    @relative_y = 0.0
    @distance = 0.0
    @rise_distance = 1.0
    @speed = 0.0
    @drift = 0.0
  end

  def reset(center_x, center_y, initial = false)
    if rand(100) < 75
      size = BushidoPointLights::FIRE_PARTICLE_SIZE_SMALL
    else
      size = BushidoPointLights::FIRE_PARTICLE_SIZE_LARGE
    end

    roll = rand(100)
    palette = 2
    palette = 0 if roll < 18
    palette = 1 if roll >= 18 && roll < 65

    @sprite.bitmap =
      BushidoPointLights.fire_particle_bitmap(size, palette)

    @sprite.ox = @sprite.bitmap.width / 2
    @sprite.oy = @sprite.bitmap.height / 2

    spread_x = BushidoPointLights::FIRE_PARTICLE_SPREAD_X
    spread_y = BushidoPointLights::FIRE_PARTICLE_SPREAD_Y

    @relative_x =
      (rand((spread_x * 2) + 1) - spread_x).to_f

    @relative_y =
      (rand((spread_y * 2) + 1) - spread_y).to_f

    @rise_distance =
      (
        rand(
          BushidoPointLights::FIRE_PARTICLE_RISE_MAX -
          BushidoPointLights::FIRE_PARTICLE_RISE_MIN +
          1
        ) +
        BushidoPointLights::FIRE_PARTICLE_RISE_MIN
      ).to_f

    @speed =
      BushidoPointLights.random_float(
        BushidoPointLights::FIRE_PARTICLE_SPEED_MIN,
        BushidoPointLights::FIRE_PARTICLE_SPEED_MAX
      )

    @drift =
      BushidoPointLights.random_float(
        -BushidoPointLights::FIRE_PARTICLE_DRIFT,
        BushidoPointLights::FIRE_PARTICLE_DRIFT
      )

    @distance = 0.0

    if initial
      progress = rand(1000) / 1000.0
      @distance = @rise_distance * progress
      @relative_y -= @distance

      if @speed > 0
        frames = @distance / @speed
        @relative_x += @drift * frames
      end
    end

    @active = true
    update_visuals(center_x, center_y)
  end

  def update(center_x, center_y)
    if !@active
      reset(center_x, center_y)
      return
    end

    @distance += @speed
    @relative_y -= @speed
    @relative_x += @drift

    if @distance >= @rise_distance
      reset(center_x, center_y)
      return
    end

    update_visuals(center_x, center_y)
  end

  def update_visuals(center_x, center_y)
    progress = @distance / @rise_distance
    progress = 0.0 if progress < 0.0
    progress = 1.0 if progress > 1.0

    opacity = 0.0

    if progress < 0.18
      opacity =
        (progress / 0.18) * BushidoPointLights::FIRE_PARTICLE_OPACITY
    else
      opacity =
        (
          1.0 - ((progress - 0.18) / 0.82)
        ) * BushidoPointLights::FIRE_PARTICLE_OPACITY
    end

    opacity = 0 if opacity < 0
    opacity = 255 if opacity > 255

    scale = 1.0 - (progress * 0.45)

    @sprite.x = (center_x + @relative_x).to_i
    @sprite.y = (center_y + @relative_y).to_i
    @sprite.opacity = opacity.to_i
    @sprite.zoom_x = scale
    @sprite.zoom_y = scale
  end

  def visible=(value)
    return if !@sprite
    @sprite.visible = value
  end

  def dispose
    return if !@sprite

    # Particle bitmaps are shared and are not disposed here.
    begin
      @sprite.dispose if !@sprite.disposed?
    rescue
    end

    @sprite = nil
  end
end


#===============================================================================
# Fire Effect
#===============================================================================

class BushidoFireEffect
  attr_reader :source_sprite

  def initialize(character_sprite)
    @source_sprite = character_sprite
    @viewport = nil
    @inner = nil
    @outer = nil
    @particles = []

    @center_x = 0
    @center_y = 0

    @flicker_inner = rand(2001) / 1000.0 - 1.0
    @flicker_outer = rand(2001) / 1000.0 - 1.0

    @target_inner = @flicker_inner
    @target_outer = @flicker_outer

    @next_flicker = 2 + rand(5)
  end

  def source_viewport
    begin
      return @source_sprite.viewport
    rescue
      return nil
    end
  end

  def rebind_source(character_sprite)
    return if !character_sprite
    return if @source_sprite.equal?(character_sprite)

    old_viewport = source_viewport
    @source_sprite = character_sprite
    new_viewport = source_viewport

    dispose_graphics if !old_viewport.equal?(new_viewport)
  end

  def ensure_graphics
    return if @inner && @outer

    @viewport = source_viewport

    @outer = Sprite.new(@viewport)
    @inner = Sprite.new(@viewport)

    @outer.bitmap = BushidoPointLights.fire_outer_bitmap
    @inner.bitmap = BushidoPointLights.fire_inner_bitmap

    setup_sprite(@outer)
    setup_sprite(@inner)

    update_position

    @particles = []

    BushidoPointLights::FIRE_PARTICLE_COUNT.times do
      particle = BushidoFireParticle.new(@viewport)
      particle.reset(@center_x, @center_y, true)
      @particles.push(particle)
    end
  end

  def setup_sprite(sprite)
    sprite.ox = sprite.bitmap.width / 2
    sprite.oy = sprite.bitmap.height / 2
    sprite.blend_type = BushidoPointLights::BLEND_TYPE
    sprite.z = BushidoPointLights::EFFECT_Z
  end

  def update
    return if source_disposed?

    if !BushidoPointLights.source_near_screen?(@source_sprite)
      hide_graphics
      return
    end

    ensure_graphics
    update_position
    update_visibility
    update_flicker
    update_particles
  end

  def hide_graphics
    begin
      @inner.visible = false if @inner && !@inner.disposed?
    rescue
    end

    begin
      @outer.visible = false if @outer && !@outer.disposed?
    rescue
    end

    @particles.each do |particle|
      begin
        particle.visible = false
      rescue
      end
    end
  end

  def update_position
    offset = BushidoPointLights.fire_offset(@source_sprite)

    @center_x = @source_sprite.x + offset[0]
    @center_y =
      @source_sprite.y +
      BushidoPointLights::BASE_Y_OFFSET +
      offset[1]

    if @inner
      @inner.x = @center_x
      @inner.y = @center_y
    end

    if @outer
      @outer.x = @center_x
      @outer.y = @center_y
    end
  end

  def fire_strength
    if BushidoPointLights.night?
      return BushidoPointLights::FIRE_NIGHT_STRENGTH
    end

    return BushidoPointLights::FIRE_DAY_STRENGTH
  end

  def update_visibility
    # Fire emits visible colored light during the day too.
    @inner.visible = true
    @outer.visible = true
  end

  def update_flicker
    @next_flicker -= 1

    if @next_flicker <= 0
      @target_inner = rand(2001) / 1000.0 - 1.0
      @target_outer = rand(2001) / 1000.0 - 1.0
      @next_flicker = 2 + rand(5)
    end

    @flicker_inner +=
      (@target_inner - @flicker_inner) * 0.28

    @flicker_outer +=
      (@target_outer - @flicker_outer) * 0.20

    inner_t = (@flicker_inner + 1.0) / 2.0
    outer_t = (@flicker_outer + 1.0) / 2.0

    inner_scale =
      BushidoPointLights::FIRE_INNER_SCALE_MIN +
      (
        BushidoPointLights::FIRE_INNER_SCALE_MAX -
        BushidoPointLights::FIRE_INNER_SCALE_MIN
      ) * inner_t

    outer_scale =
      BushidoPointLights::FIRE_OUTER_SCALE_MIN +
      (
        BushidoPointLights::FIRE_OUTER_SCALE_MAX -
        BushidoPointLights::FIRE_OUTER_SCALE_MIN
      ) * outer_t

    @inner.zoom_x = inner_scale
    @inner.zoom_y = inner_scale
    @outer.zoom_x = outer_scale
    @outer.zoom_y = outer_scale

    strength = fire_strength

    inner_opacity =
      (
        BushidoPointLights::FIRE_INNER_OPACITY +
        (@flicker_inner * BushidoPointLights::FIRE_INNER_FLICKER)
      ) * strength

    outer_opacity =
      (
        BushidoPointLights::FIRE_OUTER_OPACITY +
        (@flicker_outer * BushidoPointLights::FIRE_OUTER_FLICKER)
      ) * strength

    inner_opacity = 0 if inner_opacity < 0
    inner_opacity = 255 if inner_opacity > 255

    outer_opacity = 0 if outer_opacity < 0
    outer_opacity = 255 if outer_opacity > 255

    @inner.opacity = inner_opacity.to_i
    @outer.opacity = outer_opacity.to_i
  end

  def update_particles
    @particles.each do |particle|
      particle.visible = true
      particle.update(@center_x, @center_y)
    end
  end

  def source_disposed?
    return true if !@source_sprite

    begin
      return @source_sprite.disposed?
    rescue
      return true
    end
  end

  def dispose_sprite(sprite)
    return if !sprite

    # Radial bitmaps are shared and remain in the module cache.
    begin
      sprite.dispose if !sprite.disposed?
    rescue
    end
  end

  def dispose_graphics
    dispose_sprite(@inner)
    dispose_sprite(@outer)

    @particles.each do |particle|
      begin
        particle.dispose
      rescue
      end
    end

    @particles.clear
    @inner = nil
    @outer = nil
    @viewport = nil
  end

  def dispose
    dispose_graphics
    @source_sprite = nil
  end
end


#===============================================================================
# Scene-Level Environmental FX Manager
#
# One manager exists per Scene_Map. It does NOT retain a back-reference to the
# scene and never stores Game_Map/Game_Event objects directly.
#===============================================================================

class BushidoEnvironmentFXManager
  def initialize
    @lights = {}
    @fires = {}

    @scan_counter = 0
    @initial_delay = BushidoPointLights::INITIAL_DELAY
    @has_scanned = false
  end

  def update(scene)
    return if !scene

    if @initial_delay > 0
      @initial_delay -= 1
      return
    end

    if !@has_scanned
      @has_scanned = true
      @scan_counter = 0
      sync_effects(scene)
    else
      @scan_counter += 1

      if @scan_counter >= BushidoPointLights::SCAN_INTERVAL
        @scan_counter = 0
        sync_effects(scene)
      end
    end

    update_effects
  end

  #=============================================================================
  # Candidate Collection / Deduplication
  #=============================================================================

  def collect_candidates(scene)
    light_candidates = {}
    fire_candidates = {}

    spritesets = BushidoPointLights.scene_spritesets(scene)

    spritesets.each do |spriteset|
      sprites =
        BushidoPointLights.character_sprites_from_spriteset(
          spriteset
        )

      sprites.each do |character_sprite|
        next if !character_sprite

        begin
          next if character_sprite.disposed?
        rescue
          next
        end

        is_light = BushidoPointLights.light_sprite?(character_sprite)
        is_fire = BushidoPointLights.fire_sprite?(character_sprite)

        next if !is_light && !is_fire

        key =
          BushidoPointLights.logical_event_key(
            character_sprite,
            spriteset
          )

        next if !key

        if is_light
          existing = light_candidates[key]

          if !existing ||
             BushidoPointLights.sprite_score(character_sprite) >
             BushidoPointLights.sprite_score(existing)

            light_candidates[key] = character_sprite
          end
        end

        if is_fire
          existing = fire_candidates[key]

          if !existing ||
             BushidoPointLights.sprite_score(character_sprite) >
             BushidoPointLights.sprite_score(existing)

            fire_candidates[key] = character_sprite
          end
        end
      end
    end

    return [light_candidates, fire_candidates]
  end

  #=============================================================================
  # Synchronization
  #=============================================================================

  def sync_effects(scene)
    candidates = collect_candidates(scene)
    sync_light_effects(candidates[0])
    sync_fire_effects(candidates[1])
  end

  def sync_light_effects(candidates)
    candidates.each do |key, character_sprite|
      effect = @lights[key]

      if effect
        effect.rebind_source(character_sprite)
      else
        @lights[key] = BushidoPointLight.new(character_sprite)
      end
    end

    remove = []

    @lights.each_key do |key|
      remove.push(key) if !candidates.has_key?(key)
    end

    remove.each do |key|
      begin
        @lights[key].dispose if @lights[key]
      rescue
      end

      @lights.delete(key)
    end
  end

  def sync_fire_effects(candidates)
    candidates.each do |key, character_sprite|
      effect = @fires[key]

      if effect
        effect.rebind_source(character_sprite)
      else
        @fires[key] = BushidoFireEffect.new(character_sprite)
      end
    end

    remove = []

    @fires.each_key do |key|
      remove.push(key) if !candidates.has_key?(key)
    end

    remove.each do |key|
      begin
        @fires[key].dispose if @fires[key]
      rescue
      end

      @fires.delete(key)
    end
  end

  #=============================================================================
  # Per-Frame Update
  #=============================================================================

  def update_effects
    update_light_effects
    update_fire_effects
  end

  def update_light_effects
    remove = []

    @lights.each do |key, effect|
      begin
        if effect.source_disposed?
          remove.push(key)
        else
          effect.update
        end
      rescue
        remove.push(key)
      end
    end

    remove.each do |key|
      begin
        @lights[key].dispose if @lights[key]
      rescue
      end

      @lights.delete(key)
    end
  end

  def update_fire_effects
    remove = []

    @fires.each do |key, effect|
      begin
        if effect.source_disposed?
          remove.push(key)
        else
          effect.update
        end
      rescue
        remove.push(key)
      end
    end

    remove.each do |key|
      begin
        @fires[key].dispose if @fires[key]
      rescue
      end

      @fires.delete(key)
    end
  end

  #=============================================================================
  # Cleanup
  #=============================================================================

  def dispose
    @lights.each_value do |effect|
      begin
        effect.dispose
      rescue
      end
    end

    @fires.each_value do |effect|
      begin
        effect.dispose
      rescue
      end
    end

    @lights.clear
    @fires.clear
  end
end


#===============================================================================
# Scene_Map Integration
#
# Spriteset_Map is intentionally untouched. The guarded aliases are created
# once, so this file cannot alias its own wrapper if evaluated a second time.
#===============================================================================

class Scene_Map
  unless method_defined?(:bushido_envlights_original_update_v6)
    alias bushido_envlights_original_update_v6 update
  end

  def update(*args)
    # Connected-map and normal Scene_Map behavior always completes first.
    bushido_envlights_original_update_v6(*args)

    if !@bushido_environment_fx_manager_v6
      @bushido_environment_fx_manager_v6 =
        BushidoEnvironmentFXManager.new
    end

    @bushido_environment_fx_manager_v6.update(self)
  end

  if method_defined?(:disposeSpritesets)
    unless method_defined?(:bushido_envlights_original_dispose_spritesets_v6)
      alias bushido_envlights_original_dispose_spritesets_v6 disposeSpritesets
    end

    def disposeSpritesets(*args)
      if @bushido_environment_fx_manager_v6
        begin
          @bushido_environment_fx_manager_v6.dispose
        rescue
        end

        @bushido_environment_fx_manager_v6 = nil
      end

      bushido_envlights_original_dispose_spritesets_v6(*args)
    end
  end
end
