
# BushidoPointLights.
module BushidoPointLights

  PIXEL_SIZE = 2
  BASE_Y_OFFSET = -16

  EFFECT_Z   = 99999
  PARTICLE_Z = 100000

  BLEND_TYPE = 1

  SCAN_INTERVAL = 8
  INITIAL_DELAY = 2

  SCREEN_MARGIN = 96

  INNER_RADIUS = 24
  OUTER_RADIUS = 48

  INNER_COLOR = Color.new(255, 225, 150)
  OUTER_COLOR = Color.new(255, 205, 110)

  INNER_OPACITY = 150
  OUTER_OPACITY = 90

  INNER_PULSE_SCALE = 0.050
  OUTER_PULSE_SCALE = 0.085

  INNER_PULSE_SPEED = 0.035
  OUTER_PULSE_SPEED = 0.068

  OUTER_PULSE_OFFSET = 1.65

  INNER_OPACITY_PULSE = 14
  OUTER_OPACITY_PULSE = 20

  FIRE_INNER_RADIUS = 24
  FIRE_OUTER_RADIUS = 46

  FIRE_INNER_COLOR = Color.new(255, 118, 45)
  FIRE_OUTER_COLOR = Color.new(235, 48, 30)

  FIRE_INNER_OPACITY = 150
  FIRE_OUTER_OPACITY = 90

  FIRE_DAY_STRENGTH = 1.00
  FIRE_NIGHT_STRENGTH = 1.00

  FIRE_INNER_SCALE_MIN = 0.95
  FIRE_INNER_SCALE_MAX = 1.05

  FIRE_OUTER_SCALE_MIN = 0.96
  FIRE_OUTER_SCALE_MAX = 1.07

  FIRE_INNER_FLICKER = 14
  FIRE_OUTER_FLICKER = 10

  FIRE_PARTICLE_COUNT = 8
  FIRE_PARTICLE_OPACITY = 220

  FIRE_PARTICLE_SPREAD_X = 10
  FIRE_PARTICLE_SPREAD_Y = 5

  FIRE_PARTICLE_RISE_MIN = 18
  FIRE_PARTICLE_RISE_MAX = 30

  FIRE_PARTICLE_SPEED_MIN = 0.34
  FIRE_PARTICLE_SPEED_MAX = 0.65

  FIRE_PARTICLE_DRIFT = 0.18

  FIRE_PARTICLE_SIZE_SMALL = 2
  FIRE_PARTICLE_SIZE_LARGE = 4

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
      color =
        case palette
        when 0
          Color.new(255, 215, 115, 255)
        when 1
          Color.new(255, 120, 45, 255)
        else
          Color.new(235, 48, 30, 255)
        end

      bitmap = Bitmap.new(size, size)
      bitmap.fill_rect(0, 0, size, size, color)
      bitmap
    }
  end

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
      return hour >= 20 || hour < 6
    rescue
      return false
    end
  end

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

  def self.event_id_from_character(character)
    return nil if !character

    begin
      id = character.id
      return id if !id.nil?
    rescue
    end

    begin
      id = character.instance_variable_get(:@id)
      return id if !id.nil?
    rescue
    end

    return nil
  end

  def self.map_id_from_character(character)
    return nil if !character

    begin
      id = character.map_id
      return id if !id.nil?
    rescue
    end

    begin
      id = character.instance_variable_get(:@map_id)
      return id if !id.nil?
    rescue
    end

    begin
      map = character.instance_variable_get(:@map)

      if map
        begin
          id = map.map_id
          return id if !id.nil?
        rescue
        end

        begin
          id = map.instance_variable_get(:@map_id)
          return id if !id.nil?
        rescue
        end
      end
    rescue
    end

    return nil
  end

  def self.map_id_from_spriteset(spriteset)
    return nil if !spriteset

    begin
      map = spriteset.map
      return map.map_id if map
    rescue
    end

    begin
      map = spriteset.instance_variable_get(:@map)
      return map.map_id if map
    rescue
    end

    return nil
  end

  def self.logical_event_key(sprite, spriteset_map_id = nil)
    character = character_from_sprite(sprite)
    return nil if !character

    event_id = event_id_from_character(character)
    map_id = map_id_from_character(character)
    map_id = spriteset_map_id if map_id.nil?

    if !map_id.nil? && !event_id.nil?
      return [map_id.to_i, event_id.to_i]
    end

    return [:character, character.object_id]
  end

  def self.scene_spritesets(scene)
    results = []
    seen = {}

    return results if !scene

    queue = []

    begin
      scene.instance_variables.each do |ivar|
        value = scene.instance_variable_get(ivar)
        queue.push([value, 0]) if value
      end
    rescue
      return results
    end

    while queue.length > 0
      pair = queue.shift
      value = pair[0]
      depth = pair[1]

      next if !value
      next if depth > 4

      key = value.object_id
      next if seen[key]
      seen[key] = true

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

  def self.source_screen_position(sprite, offset_x, offset_y)
    return nil if !sprite

    character = character_from_sprite(sprite)
    return nil if !character

    if defined?(ScreenPosHelper)
      begin
        x = ScreenPosHelper.pbScreenX(character) + offset_x
        y = ScreenPosHelper.pbScreenY(character) + BASE_Y_OFFSET + offset_y
        return [x, y]
      rescue
      end
    end

    begin
      x = sprite.x + offset_x
      y = sprite.y + BASE_Y_OFFSET + offset_y
      return [x, y]
    rescue
      return nil
    end
  end

  def self.source_position_ready?(sprite)
    return false if !sprite

    character = character_from_sprite(sprite)
    return false if !character

    begin
      return false if sprite.disposed?
    rescue
      return false
    end

    if character.is_a?(Game_Event)
      begin
        map = character.instance_variable_get(:@map)
        return false if !map
        return false if map.map_id.nil?
      rescue
        return false
      end
    end

    return true
  end

  def self.on_screen_position?(x, y, margin = SCREEN_MARGIN)
    return false if x.nil? || y.nil?

    return false if x < -margin
    return false if y < -margin
    return false if x > Graphics.width + margin
    return false if y > Graphics.height + margin

    return true
  end

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
      if sprite.x >= -SCREEN_MARGIN &&
         sprite.y >= -SCREEN_MARGIN &&
         sprite.x <= Graphics.width + SCREEN_MARGIN &&
         sprite.y <= Graphics.height + SCREEN_MARGIN
        score += 40
      end
    rescue
    end

    return score
  end

  def self.make_glow(radius, color)
    size = (radius * 2) + PIXEL_SIZE
    bitmap = Bitmap.new(size, size)

    center = size / 2.0
    max_distance = radius.to_f

    y = 0

    while y < size
      x = 0

      while x < size
        sx = x + (PIXEL_SIZE / 2.0)
        sy = y + (PIXEL_SIZE / 2.0)

        dx = sx - center
        dy = sy - center

        distance = Math.sqrt((dx * dx) + (dy * dy))

        if distance <= max_distance
          strength = 1.0 - (distance / max_distance)

          strength = Math.sqrt(strength)

          alpha = (strength * 255).to_i

          bitmap.fill_rect(
            x,
            y,
            PIXEL_SIZE,
            PIXEL_SIZE,
            Color.new(
              color.red,
              color.green,
              color.blue,
              alpha
            )
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
    return minimum + amount * (maximum - minimum)
  end
end

# BushidoPointLight.
class BushidoPointLight
  attr_reader :source_sprite

  def initialize(character_sprite)
    @source_sprite = character_sprite
    @inner = nil
    @outer = nil
    @screen_x = nil
    @screen_y = nil
    @pulse_time = rand(1000)

    create_sprites
  end

  def source_viewport
    begin
      return @source_sprite.viewport
    rescue
      return nil
    end
  end

  def create_sprites
    viewport = source_viewport

    @outer = Sprite.new(viewport)
    @inner = Sprite.new(viewport)

    @outer.bitmap = BushidoPointLights.light_outer_bitmap
    @inner.bitmap = BushidoPointLights.light_inner_bitmap

    setup_sprite(@outer)
    setup_sprite(@inner)

    @outer.visible = false
    @inner.visible = false

    apply_pulse
  end

  def setup_sprite(sprite)
    sprite.ox = sprite.bitmap.width / 2
    sprite.oy = sprite.bitmap.height / 2
    sprite.blend_type = BushidoPointLights::BLEND_TYPE
    sprite.z = BushidoPointLights::EFFECT_Z
  end

  def rebind_source(character_sprite)
    return if !character_sprite
    @source_sprite = character_sprite
  end

  def update
    return if disposed?
    return if source_disposed?

    update_position
    update_visibility

    @pulse_time += 1.0
    apply_pulse
  end

  def update_position
    return if !BushidoPointLights.source_position_ready?(@source_sprite)

    offset = BushidoPointLights.light_offset(@source_sprite)

    pos =
      BushidoPointLights.source_screen_position(
        @source_sprite,
        offset[0],
        offset[1]
      )

    if pos
      @screen_x = pos[0]
      @screen_y = pos[1]

      @inner.x = @screen_x
      @inner.y = @screen_y

      @outer.x = @screen_x
      @outer.y = @screen_y
    end
  end

  def update_visibility
    visible =
      BushidoPointLights.source_position_ready?(@source_sprite) &&
      BushidoPointLights.night? &&
      BushidoPointLights.on_screen_position?(
        @screen_x,
        @screen_y
      )

    @inner.visible = visible
    @outer.visible = visible
  end

  def apply_pulse
    inner_wave =
      Math.sin(
        @pulse_time *
        BushidoPointLights::INNER_PULSE_SPEED
      )

    outer_wave =
      Math.sin(
        (@pulse_time * BushidoPointLights::OUTER_PULSE_SPEED) +
        BushidoPointLights::OUTER_PULSE_OFFSET
      )

    inner_scale =
      1.0 +
      inner_wave *
      BushidoPointLights::INNER_PULSE_SCALE

    outer_scale =
      1.0 +
      outer_wave *
      BushidoPointLights::OUTER_PULSE_SCALE

    @inner.zoom_x = inner_scale
    @inner.zoom_y = inner_scale

    @outer.zoom_x = outer_scale
    @outer.zoom_y = outer_scale

    inner_opacity =
      BushidoPointLights::INNER_OPACITY +
      (
        inner_wave *
        BushidoPointLights::INNER_OPACITY_PULSE
      ).to_i

    outer_opacity =
      BushidoPointLights::OUTER_OPACITY +
      (
        outer_wave *
        BushidoPointLights::OUTER_OPACITY_PULSE
      ).to_i

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

  def disposed?
    return true if !@inner

    begin
      return @inner.disposed?
    rescue
      return true
    end
  end

  def dispose
    begin
      @inner.dispose if @inner && !@inner.disposed?
    rescue
    end

    begin
      @outer.dispose if @outer && !@outer.disposed?
    rescue
    end

    @inner = nil
    @outer = nil
    @core = nil
    @source_sprite = nil
  end
end

# BushidoFireParticle.
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
    if rand(100) < 78
      size = BushidoPointLights::FIRE_PARTICLE_SIZE_SMALL
    else
      size = BushidoPointLights::FIRE_PARTICLE_SIZE_LARGE
    end

    roll = rand(100)

    palette =
      if roll < 20
        0
      elsif roll < 68
        1
      else
        2
      end

    @sprite.bitmap =
      BushidoPointLights.fire_particle_bitmap(
        size,
        palette
      )

    @sprite.ox = @sprite.bitmap.width / 2
    @sprite.oy = @sprite.bitmap.height / 2

    spread_x = BushidoPointLights::FIRE_PARTICLE_SPREAD_X
    spread_y = BushidoPointLights::FIRE_PARTICLE_SPREAD_Y

    @relative_x =
      (
        rand((spread_x * 2) + 1) -
        spread_x
      ).to_f

    @relative_y =
      (
        rand((spread_y * 2) + 1) -
        spread_y
      ).to_f

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
    return if center_x.nil? || center_y.nil?

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

    if progress < 0.18
      opacity =
        (progress / 0.18) *
        BushidoPointLights::FIRE_PARTICLE_OPACITY
    else
      opacity =
        (
          1.0 -
          ((progress - 0.18) / 0.82)
        ) *
        BushidoPointLights::FIRE_PARTICLE_OPACITY
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

    begin
      @sprite.dispose if !@sprite.disposed?
    rescue
    end

    @sprite = nil
  end
end

# BushidoFireEffect.
class BushidoFireEffect
  attr_reader :source_sprite

  def initialize(character_sprite)
    @source_sprite = character_sprite

    @inner = nil
    @outer = nil
    @core = nil
    @particles = []

    @center_x = nil
    @center_y = nil

    @flicker_inner = rand(2001) / 1000.0 - 1.0
    @flicker_outer = rand(2001) / 1000.0 - 1.0

    @target_inner = @flicker_inner
    @target_outer = @flicker_outer

    @next_flicker = 2 + rand(5)

    create_sprites
  end

  def source_viewport
    begin
      return @source_sprite.viewport
    rescue
      return nil
    end
  end

  def create_sprites
    viewport = source_viewport

    @outer = Sprite.new(viewport)
    @inner = Sprite.new(viewport)
    @core = Sprite.new(viewport)

    @core.bitmap = Bitmap.new(8, 8)
    @core.bitmap.fill_rect(
      0,
      0,
      8,
      8,
      Color.new(255, 135, 40, 235)
    )
    @core.ox = 4
    @core.oy = 4
    @core.blend_type = BushidoPointLights::BLEND_TYPE
    @core.z = BushidoPointLights::PARTICLE_Z

    @outer.bitmap = BushidoPointLights.fire_outer_bitmap
    @inner.bitmap = BushidoPointLights.fire_inner_bitmap

    setup_sprite(@outer)
    setup_sprite(@inner)

    @outer.visible = false
    @inner.visible = false
    @core.visible = false if @core

    update_position

    BushidoPointLights::FIRE_PARTICLE_COUNT.times do
      particle = BushidoFireParticle.new(viewport)

      if !@center_x.nil? && !@center_y.nil?
        particle.reset(@center_x, @center_y, true)
      end

      particle.visible = false
      @particles.push(particle)
    end

    apply_flicker
  end

  def setup_sprite(sprite)
    sprite.ox = sprite.bitmap.width / 2
    sprite.oy = sprite.bitmap.height / 2
    sprite.blend_type = BushidoPointLights::BLEND_TYPE
    sprite.z = BushidoPointLights::EFFECT_Z
  end

  def rebind_source(character_sprite)
    return if !character_sprite
    @source_sprite = character_sprite
  end

  def update
    return if disposed?
    return if source_disposed?

    update_position
    update_visibility
    update_flicker
    update_particles
  end

  def update_position
    return if !BushidoPointLights.source_position_ready?(@source_sprite)

    offset = BushidoPointLights.fire_offset(@source_sprite)

    pos =
      BushidoPointLights.source_screen_position(
        @source_sprite,
        offset[0],
        offset[1]
      )

    return if !pos

    @center_x = pos[0]
    @center_y = pos[1]

    @inner.x = @center_x
    @inner.y = @center_y

    @outer.x = @center_x
    @outer.y = @center_y

    @core.x = @center_x if @core
    @core.y = @center_y if @core
  end

  def fire_strength
    if BushidoPointLights.night?
      return BushidoPointLights::FIRE_NIGHT_STRENGTH
    end

    return BushidoPointLights::FIRE_DAY_STRENGTH
  end

  def update_visibility
    visible =
      BushidoPointLights.source_position_ready?(@source_sprite) &&
      BushidoPointLights.on_screen_position?(
        @center_x,
        @center_y
      )

    @inner.visible = visible
    @outer.visible = visible
    @core.visible = visible if @core

    @particles.each do |particle|
      particle.visible = visible
    end
  end

  def update_flicker
    @next_flicker -= 1

    if @next_flicker <= 0
      @target_inner = rand(2001) / 1000.0 - 1.0
      @target_outer = rand(2001) / 1000.0 - 1.0

      @next_flicker = 2 + rand(5)
    end

    @flicker_inner +=
      (@target_inner - @flicker_inner) *
      0.28

    @flicker_outer +=
      (@target_outer - @flicker_outer) *
      0.20

    apply_flicker
  end

  def apply_flicker
    inner_t = (@flicker_inner + 1.0) / 2.0
    outer_t = (@flicker_outer + 1.0) / 2.0

    inner_scale =
      BushidoPointLights::FIRE_INNER_SCALE_MIN +
      (
        BushidoPointLights::FIRE_INNER_SCALE_MAX -
        BushidoPointLights::FIRE_INNER_SCALE_MIN
      ) *
      inner_t

    outer_scale =
      BushidoPointLights::FIRE_OUTER_SCALE_MIN +
      (
        BushidoPointLights::FIRE_OUTER_SCALE_MAX -
        BushidoPointLights::FIRE_OUTER_SCALE_MIN
      ) *
      outer_t

    @inner.zoom_x = inner_scale
    @inner.zoom_y = inner_scale

    @outer.zoom_x = outer_scale
    @outer.zoom_y = outer_scale

    strength = fire_strength

    inner_opacity =
      (
        BushidoPointLights::FIRE_INNER_OPACITY +
        (
          @flicker_inner *
          BushidoPointLights::FIRE_INNER_FLICKER
        )
      ) *
      strength

    outer_opacity =
      (
        BushidoPointLights::FIRE_OUTER_OPACITY +
        (
          @flicker_outer *
          BushidoPointLights::FIRE_OUTER_FLICKER
        )
      ) *
      strength

    inner_opacity = 0 if inner_opacity < 0
    inner_opacity = 255 if inner_opacity > 255

    outer_opacity = 0 if outer_opacity < 0
    outer_opacity = 255 if outer_opacity > 255

    @inner.opacity = inner_opacity.to_i
    @outer.opacity = outer_opacity.to_i

    if @core
      core_scale = 0.92 + ((@flicker_inner + 1.0) * 0.06)
      @core.zoom_x = core_scale
      @core.zoom_y = core_scale

      core_opacity = 220 + (@flicker_inner * 20).to_i
      core_opacity = 0 if core_opacity < 0
      core_opacity = 255 if core_opacity > 255
      @core.opacity = core_opacity
    end
  end

  def update_particles
    visible =
      BushidoPointLights.on_screen_position?(
        @center_x,
        @center_y
      )

    return if !visible

    @particles.each do |particle|
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

  def disposed?
    return true if !@inner

    begin
      return @inner.disposed?
    rescue
      return true
    end
  end

  def dispose
    begin
      @inner.dispose if @inner && !@inner.disposed?
    rescue
    end

    begin
      @outer.dispose if @outer && !@outer.disposed?
    rescue
    end

    begin
      if @core
        if @core.bitmap && !@core.bitmap.disposed?
          @core.bitmap.dispose
        end
        @core.dispose if !@core.disposed?
      end
    rescue
    end

    @particles.each do |particle|
      begin
        particle.dispose
      rescue
      end
    end

    @particles.clear

    @inner = nil
    @outer = nil
    @source_sprite = nil
  end
end

# BushidoEnvironmentFXManager.
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

  def collect_candidates(scene)
    light_candidates = {}
    fire_candidates = {}

    spritesets = BushidoPointLights.scene_spritesets(scene)

    spritesets.each do |spriteset|
      map_id =
        BushidoPointLights.map_id_from_spriteset(
          spriteset
        )

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

        is_light =
          BushidoPointLights.light_sprite?(
            character_sprite
          )

        is_fire =
          BushidoPointLights.fire_sprite?(
            character_sprite
          )

        next if !is_light && !is_fire

        key =
          BushidoPointLights.logical_event_key(
            character_sprite,
            map_id
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

  def sync_effects(scene)
    candidates = collect_candidates(scene)

    sync_lights(candidates[0])
    sync_fires(candidates[1])
  end

  def sync_lights(candidates)
    candidates.each do |key, sprite|
      effect = @lights[key]

      if effect
        effect.rebind_source(sprite)
      else
        @lights[key] = BushidoPointLight.new(sprite)
      end
    end

    stale = []

    @lights.each_key do |key|
      stale.push(key) if !candidates.has_key?(key)
    end

    stale.each do |key|
      begin
        @lights[key].dispose if @lights[key]
      rescue
      end
      @lights.delete(key)
    end
  end

  def sync_fires(candidates)
    candidates.each do |key, sprite|
      effect = @fires[key]

      if effect
        effect.rebind_source(sprite)
      else
        @fires[key] = BushidoFireEffect.new(sprite)
      end
    end

    stale = []

    @fires.each_key do |key|
      stale.push(key) if !candidates.has_key?(key)
    end

    stale.each do |key|
      begin
        @fires[key].dispose if @fires[key]
      rescue
      end
      @fires.delete(key)
    end
  end

  def update_effects
    stale = []

    @lights.each do |key, effect|
      begin
        if effect.source_disposed?
          stale.push(key)
        else
          effect.update
        end
      rescue
        stale.push(key)
      end
    end

    stale.each do |key|
      begin
        @lights[key].dispose if @lights[key]
      rescue
      end

      @lights.delete(key)
    end

    stale = []

    @fires.each do |key, effect|
      begin
        if effect.source_disposed?
          stale.push(key)
        else
          effect.update
        end
      rescue
        stale.push(key)
      end
    end

    stale.each do |key|
      begin
        @fires[key].dispose if @fires[key]
      rescue
      end

      @fires.delete(key)
    end
  end

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

# Scene_Map.
class Scene_Map
  unless method_defined?(:bushido_pointlights_original_update_final)
    alias bushido_pointlights_original_update_final update
  end

  def update(*args)
    bushido_pointlights_original_update_final(*args)

    if !@bushido_environment_fx_manager
      @bushido_environment_fx_manager =
        BushidoEnvironmentFXManager.new
    end

    @bushido_environment_fx_manager.update(self)
  end

  if method_defined?(:disposeSpritesets)
    unless method_defined?(:bushido_pointlights_original_dispose_spritesets_final)
      alias bushido_pointlights_original_dispose_spritesets_final disposeSpritesets
    end

    def disposeSpritesets(*args)
      if @bushido_environment_fx_manager
        begin
          @bushido_environment_fx_manager.dispose
        rescue
        end

        @bushido_environment_fx_manager = nil
      end

      bushido_pointlights_original_dispose_spritesets_final(*args)
    end
  end
end
