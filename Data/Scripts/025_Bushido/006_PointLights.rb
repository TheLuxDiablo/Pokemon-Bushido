#===============================================================================
# Bushido Environmental Lights
# Pokemon Essentials v18.1
#
# 006_PointLights.rb
#
#===============================================================================
#
# POINT LIGHT
#
# Event names:
#
#   Light(0,0)
#   Light(12,-8)
#   Lantern Light(6,-20)
#
#
# FIRE
#
# Event names:
#
#   Fire(0,0)
#   Fire(4,-12)
#   Bonfire Fire(0,-8)
#
#
# OFFSETS
#
# Values are PIXELS.
#
# X:
#   negative = left
#   positive = right
#
# Y:
#   negative = up
#   positive = down
#
#
# DESIGN
#
# This script does NOT patch Spriteset_Map.
#
# All connected maps/spritesets are allowed to finish their normal update
# before environmental effects are scanned or updated.
#
# The lighting manager exists only on Scene_Map and only references
# already-created Sprite_Character objects.
#
#===============================================================================


module BushidoPointLights
  #=============================================================================
  # Shared
  #=============================================================================

  PIXEL_SIZE = 2

  BASE_Y_OFFSET = -16

  BLEND_TYPE = 1

  EFFECT_Z   = 99999
  PARTICLE_Z = 100000

  # How often we rescan existing character sprites for newly-added/removed FX.
  SCAN_INTERVAL = 15

  # Wait this many completed Scene_Map update frames before first scanning.
  INITIAL_DELAY = 1


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

  FIRE_INNER_RADIUS = 20
  FIRE_OUTER_RADIUS = 40

  FIRE_INNER_COLOR = Color.new(255, 118, 45)
  FIRE_OUTER_COLOR = Color.new(235, 48, 30)

  FIRE_INNER_OPACITY = 75
  FIRE_OUTER_OPACITY = 32

  FIRE_INNER_SCALE_MIN = 0.96
  FIRE_INNER_SCALE_MAX = 1.04

  FIRE_OUTER_SCALE_MIN = 0.97
  FIRE_OUTER_SCALE_MAX = 1.06

  FIRE_INNER_FLICKER = 12
  FIRE_OUTER_FLICKER = 8

  FIRE_PARTICLE_COUNT = 5

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
  # Night
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

      return true if hour >= 20
      return true if hour < 6

      return false
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
      event_data =
        character.instance_variable_get(:@event)

      return event_data.name.to_s if event_data
    rescue
    end

    return ""
  end


  #=============================================================================
  # Tag Detection
  #=============================================================================

  def self.light_sprite?(sprite)
    name = event_name_from_sprite(sprite)

    return true if
      name =~ /Light\s*\(\s*-?\d+\s*,\s*-?\d+\s*\)/i

    return false
  end


  def self.fire_sprite?(sprite)
    return false
  end


  #=============================================================================
  # Offsets
  #=============================================================================

  def self.light_offset(sprite)
    return parse_offset(
      event_name_from_sprite(sprite),
      "Light"
    )
  end


  def self.fire_offset(sprite)
    return parse_offset(
      event_name_from_sprite(sprite),
      "Fire"
    )
  end


  def self.parse_offset(name, tag)
    regex =
      /#{tag}\s*\(\s*(-?\d+)\s*,\s*(-?\d+)\s*\)/i

    if name =~ regex
      return [
        $1.to_i,
        $2.to_i
      ]
    end

    return [0, 0]
  end


  #=============================================================================
  # Pixelated Glow
  #=============================================================================

  def self.make_glow(radius, color)
    size =
      (radius * 2) +
      PIXEL_SIZE

    bitmap =
      Bitmap.new(
        size,
        size
      )

    center =
      size / 2.0

    max_distance =
      radius.to_f

    y = 0

    while y < size
      x = 0

      while x < size
        sample_x =
          x +
          (PIXEL_SIZE / 2.0)

        sample_y =
          y +
          (PIXEL_SIZE / 2.0)

        dx =
          sample_x -
          center

        dy =
          sample_y -
          center

        distance =
          Math.sqrt(
            (dx * dx) +
            (dy * dy)
          )

        if distance <= max_distance
          strength =
            1.0 -
            (
              distance /
              max_distance
            )

          # Keeps the rings readable while preserving the 2px density.
          strength =
            Math.sqrt(
              strength
            )

          alpha =
            (
              strength *
              255
            ).to_i

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


  #=============================================================================
  # Fire Particle Bitmap
  #=============================================================================

  def self.make_fire_particle(size, color)
    bitmap =
      Bitmap.new(
        size,
        size
      )

    bitmap.fill_rect(
      0,
      0,
      size,
      size,
      color
    )

    return bitmap
  end


  def self.random_float(minimum, maximum)
    amount =
      rand(1000) /
      1000.0

    return minimum +
      (
        amount *
        (
          maximum -
          minimum
        )
      )
  end


  #=============================================================================
  # Find Spriteset_Map Objects Inside Scene_Map
  #
  # Essentials/connected-map implementations can store spritesets in arrays,
  # hashes, or individual instance variables.
  #
  # We only inspect container objects owned by Scene_Map. We do NOT recursively
  # walk arbitrary game objects.
  #=============================================================================

  def self.scene_spritesets(scene)
    results = []
    seen    = {}

    return results if !scene

    begin
      variables = scene.instance_variables
    rescue
      return results
    end

    variables.each do |variable|
      begin
        value =
          scene.instance_variable_get(
            variable
          )

        collect_spritesets(
          value,
          results,
          seen,
          0
        )
      rescue
      end
    end

    return results
  end


  def self.collect_spritesets(
    value,
    results,
    seen,
    depth
  )
    return if !value
    return if depth > 4

    object_key =
      value.object_id

    return if seen[object_key]

    seen[object_key] =
      true

    #-------------------------------------------------------------------------
    # Found an actual map spriteset.
    #-------------------------------------------------------------------------

    if defined?(Spriteset_Map) &&
       value.is_a?(Spriteset_Map)

      results.push(value)

      return
    end

    #-------------------------------------------------------------------------
    # Only recurse through basic containers.
    #-------------------------------------------------------------------------

    if value.is_a?(Array)
      value.each do |entry|
        collect_spritesets(
          entry,
          results,
          seen,
          depth + 1
        )
      end

      return
    end


    if value.is_a?(Hash)
      value.each_value do |entry|
        collect_spritesets(
          entry,
          results,
          seen,
          depth + 1
        )
      end

      return
    end
  end


  #=============================================================================
  # Character Sprites From Existing Spriteset
  #=============================================================================

  def self.character_sprites_from_spriteset(spriteset)
    return [] if !spriteset

    begin
      sprites =
        spriteset.instance_variable_get(
          :@character_sprites
        )

      return sprites if sprites
    rescue
    end

    return []
  end
end


#===============================================================================
# Point Light Effect
#===============================================================================

class BushidoPointLight
  def initialize(character_sprite)
    @character_sprite =
      character_sprite

    viewport = nil

    begin
      viewport =
        @character_sprite.viewport
    rescue
    end

    @outer =
      Sprite.new(
        viewport
      )

    @inner =
      Sprite.new(
        viewport
      )

    @outer.bitmap =
      BushidoPointLights.make_glow(
        BushidoPointLights::OUTER_RADIUS,
        BushidoPointLights::OUTER_COLOR
      )

    @inner.bitmap =
      BushidoPointLights.make_glow(
        BushidoPointLights::INNER_RADIUS,
        BushidoPointLights::INNER_COLOR
      )

    setup_sprite(
      @outer
    )

    setup_sprite(
      @inner
    )

    @inner.opacity =
      BushidoPointLights::INNER_OPACITY

    @outer.opacity =
      BushidoPointLights::OUTER_OPACITY

    # Random starting point prevents synchronized lamps and avoids
    # the initial bright snap.
    @pulse_time =
      rand(1000)
  end


  def setup_sprite(sprite)
    sprite.ox =
      sprite.bitmap.width /
      2

    sprite.oy =
      sprite.bitmap.height /
      2

    sprite.blend_type =
      BushidoPointLights::BLEND_TYPE

    sprite.z =
      BushidoPointLights::EFFECT_Z
  end


  #=============================================================================
  # Update
  #=============================================================================

  def update
    return if disposed?
    return if source_disposed?

    update_position
    update_visibility
    update_pulse
  end


  #=============================================================================
  # Position
  #=============================================================================

  def update_position
    offset =
      BushidoPointLights.light_offset(
        @character_sprite
      )

    x =
      @character_sprite.x +
      offset[0]

    y =
      @character_sprite.y +
      BushidoPointLights::BASE_Y_OFFSET +
      offset[1]

    @inner.x = x
    @inner.y = y

    @outer.x = x
    @outer.y = y
  end


  #=============================================================================
  # Visibility
  #=============================================================================

  def update_visibility
    visible =
      BushidoPointLights.night?

    begin
      visible =
        false if !@character_sprite.visible
    rescue
    end

    @inner.visible =
      visible

    @outer.visible =
      visible
  end


  #=============================================================================
  # Pulse
  #=============================================================================

  def update_pulse
    return if !@inner.visible

    @pulse_time +=
      1.0

    inner_wave =
      Math.sin(
        @pulse_time *
        BushidoPointLights::INNER_PULSE_SPEED
      )

    outer_wave =
      Math.sin(
        (
          @pulse_time *
          BushidoPointLights::OUTER_PULSE_SPEED
        ) +
        BushidoPointLights::OUTER_PULSE_OFFSET
      )

    inner_scale =
      1.0 +
      (
        inner_wave *
        BushidoPointLights::INNER_PULSE_SCALE
      )

    outer_scale =
      1.0 +
      (
        outer_wave *
        BushidoPointLights::OUTER_PULSE_SCALE
      )

    @inner.zoom_x =
      inner_scale

    @inner.zoom_y =
      inner_scale

    @outer.zoom_x =
      outer_scale

    @outer.zoom_y =
      outer_scale

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

    @inner.opacity =
      inner_opacity

    @outer.opacity =
      outer_opacity
  end


  #=============================================================================
  # Source
  #=============================================================================

  def source_disposed?
    return true if !@character_sprite

    begin
      return @character_sprite.disposed?
    rescue
      return true
    end
  end


  #=============================================================================
  # Dispose
  #=============================================================================

  def disposed?
    return true if !@inner

    begin
      return @inner.disposed?
    rescue
      return true
    end
  end


  def dispose_sprite(sprite)
    return if !sprite

    begin
      if sprite.bitmap &&
         !sprite.bitmap.disposed?

        sprite.bitmap.dispose
      end
    rescue
    end

    begin
      sprite.dispose if !sprite.disposed?
    rescue
    end
  end


  def dispose
    dispose_sprite(@inner)
    dispose_sprite(@outer)

    @inner =
      nil

    @outer =
      nil

    @character_sprite =
      nil
  end
end


#===============================================================================
# Fire Particle
#===============================================================================

class BushidoFireParticle
  def initialize(viewport)
    @sprite =
      Sprite.new(
        viewport
      )

    @sprite.z =
      BushidoPointLights::PARTICLE_Z

    @sprite.blend_type =
      BushidoPointLights::BLEND_TYPE

    @active =
      false

    @relative_x =
      0.0

    @relative_y =
      0.0

    @distance =
      0.0

    @rise_distance =
      1.0

    @speed =
      0.0

    @drift =
      0.0
  end


  #=============================================================================
  # Reset
  #=============================================================================

  def reset(
    center_x,
    center_y,
    initial = false
  )
    dispose_bitmap

    if rand(100) < 75
      size =
        BushidoPointLights::FIRE_PARTICLE_SIZE_SMALL
    else
      size =
        BushidoPointLights::FIRE_PARTICLE_SIZE_LARGE
    end

    roll =
      rand(100)

    if roll < 18
      color =
        Color.new(
          255,
          205,
          95
        )

    elsif roll < 65
      color =
        Color.new(
          255,
          105,
          40
        )

    else
      color =
        Color.new(
          235,
          48,
          30
        )
    end

    @sprite.bitmap =
      BushidoPointLights.make_fire_particle(
        size,
        color
      )

    @sprite.ox =
      @sprite.bitmap.width /
      2

    @sprite.oy =
      @sprite.bitmap.height /
      2

    spread_x =
      BushidoPointLights::FIRE_PARTICLE_SPREAD_X

    spread_y =
      BushidoPointLights::FIRE_PARTICLE_SPREAD_Y

    @relative_x =
      (
        rand(
          (spread_x * 2) +
          1
        ) -
        spread_x
      ).to_f

    @relative_y =
      (
        rand(
          (spread_y * 2) +
          1
        ) -
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

    @distance =
      0.0

    # Seed particles throughout their life so fire exists immediately.
    if initial
      progress =
        rand(1000) /
        1000.0

      @distance =
        @rise_distance *
        progress

      @relative_y -=
        @distance

      if @speed > 0
        frames =
          @distance /
          @speed

        @relative_x +=
          @drift *
          frames
      end
    end

    @active =
      true

    update_visuals(
      center_x,
      center_y
    )
  end


  #=============================================================================
  # Update
  #=============================================================================

  def update(
    center_x,
    center_y
  )
    if !@active
      reset(
        center_x,
        center_y
      )

      return
    end

    @distance +=
      @speed

    @relative_y -=
      @speed

    @relative_x +=
      @drift

    if @distance >=
       @rise_distance

      reset(
        center_x,
        center_y
      )

      return
    end

    update_visuals(
      center_x,
      center_y
    )
  end


  #=============================================================================
  # Visual
  #=============================================================================

  def update_visuals(
    center_x,
    center_y
  )
    progress =
      @distance /
      @rise_distance

    progress = 0.0 if progress < 0.0
    progress = 1.0 if progress > 1.0

    if progress < 0.18
      opacity =
        (
          progress /
          0.18
        ) *
        180

    else
      opacity =
        (
          1.0 -
          (
            (
              progress -
              0.18
            ) /
            0.82
          )
        ) *
        180
    end

    opacity = 0 if opacity < 0
    opacity = 255 if opacity > 255

    scale =
      1.0 -
      (
        progress *
        0.45
      )

    @sprite.x =
      (
        center_x +
        @relative_x
      ).to_i

    @sprite.y =
      (
        center_y +
        @relative_y
      ).to_i

    @sprite.opacity =
      opacity.to_i

    @sprite.zoom_x =
      scale

    @sprite.zoom_y =
      scale
  end


  def visible=(value)
    return if !@sprite

    @sprite.visible =
      value
  end


  #=============================================================================
  # Dispose
  #=============================================================================

  def dispose_bitmap
    return if !@sprite

    begin
      if @sprite.bitmap &&
         !@sprite.bitmap.disposed?

        @sprite.bitmap.dispose
      end
    rescue
    end
  end


  def dispose
    return if !@sprite

    dispose_bitmap

    begin
      @sprite.dispose if !@sprite.disposed?
    rescue
    end

    @sprite =
      nil
  end
end

#===============================================================================
# Fire Effect - Minimal Debug Version
#===============================================================================

class BushidoFireEffect
  def initialize(character_sprite)
    @character_sprite = character_sprite

    viewport = nil

    begin
      viewport = @character_sprite.viewport
    rescue
      viewport = nil
    end

    @sprite = Sprite.new(viewport)

    @sprite.bitmap = Bitmap.new(
      16,
      16
    )

    @sprite.bitmap.fill_rect(
      0,
      0,
      16,
      16,
      Color.new(
        255,
        0,
        0,
        255
      )
    )

    @sprite.ox = 8
    @sprite.oy = 8

    @sprite.z = 99999
  end


  def update
    return if source_disposed?
    return if !@sprite

    offset =
      BushidoPointLights.fire_offset(
        @character_sprite
      )

    @sprite.x =
      @character_sprite.x +
      offset[0]

    @sprite.y =
      @character_sprite.y +
      BushidoPointLights::BASE_Y_OFFSET +
      offset[1]

    begin
      @sprite.visible =
        @character_sprite.visible
    rescue
      @sprite.visible =
        true
    end
  end


  def source_disposed?
    return true if !@character_sprite

    begin
      return @character_sprite.disposed?
    rescue
      return true
    end
  end


  def disposed?
    return true if !@sprite

    begin
      return @sprite.disposed?
    rescue
      return true
    end
  end


  def dispose
    return if !@sprite

    begin
      if @sprite.bitmap &&
         !@sprite.bitmap.disposed?

        @sprite.bitmap.dispose
      end
    rescue
    end

    begin
      @sprite.dispose if !@sprite.disposed?
    rescue
    end

    @sprite = nil
    @character_sprite = nil
  end
end


#===============================================================================
# Scene-Level Environment Manager
#
# This is deliberately NOT attached to Spriteset_Map.
#
# It runs after Scene_Map's normal update has completed.
#===============================================================================

class BushidoEnvironmentFXManager
  def initialize(scene)
    @scene =
      scene

    @lights =
      {}

    @fires =
      {}

    @scan_counter =
      0

    @initial_delay =
      BushidoPointLights::INITIAL_DELAY
  end


  #=============================================================================
  # Update
  #=============================================================================

  def update
    return if !@scene

    #-------------------------------------------------------------------------
    # Do nothing during our first completed Scene_Map frame.
    #
    # This guarantees connected-map spritesets have had an opportunity to
    # finish their own normal creation/update before we touch them.
    #-------------------------------------------------------------------------

    if @initial_delay > 0
      @initial_delay -= 1

      return
    end

    @scan_counter +=
      1

    if @scan_counter >=
       BushidoPointLights::SCAN_INTERVAL

      @scan_counter =
        0

      sync_effects
    end

    update_effects
  end


  #=============================================================================
  # Synchronize
  #=============================================================================

  def sync_effects
    spritesets =
      BushidoPointLights.scene_spritesets(
        @scene
      )

    valid_lights =
      {}

    valid_fires =
      {}


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

        key =
          character_sprite.object_id


        #-----------------------------------------------------------------------
        # Point Light
        #-----------------------------------------------------------------------

        if BushidoPointLights.light_sprite?(
             character_sprite
           )

          valid_lights[key] =
            true

          if !@lights[key]
            @lights[key] =
              BushidoPointLight.new(
                character_sprite
              )
          end
        end


        #-----------------------------------------------------------------------
        # Fire
        #-----------------------------------------------------------------------

        if BushidoPointLights.fire_sprite?(
             character_sprite
           )

          valid_fires[key] =
            true

          if !@fires[key]
            @fires[key] =
              BushidoFireEffect.new(
                character_sprite
              )
          end
        end
      end
    end


    #-------------------------------------------------------------------------
    # Remove stale lights.
    #-------------------------------------------------------------------------

    remove =
      []

    @lights.each_key do |key|
      if !valid_lights[key]
        remove.push(
          key
        )
      end
    end

    remove.each do |key|
      begin
        @lights[key].dispose if @lights[key]
      rescue
      end

      @lights.delete(
        key
      )
    end


    #-------------------------------------------------------------------------
    # Remove stale fires.
    #-------------------------------------------------------------------------

    remove =
      []

    @fires.each_key do |key|
      if !valid_fires[key]
        remove.push(
          key
        )
      end
    end

    remove.each do |key|
      begin
        @fires[key].dispose if @fires[key]
      rescue
      end

      @fires.delete(
        key
      )
    end
  end


  #=============================================================================
  # Update Effects
  #=============================================================================

  def update_effects
    remove =
      []

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

      @lights.delete(
        key
      )
    end


    remove =
      []

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

      @fires.delete(
        key
      )
    end
  end


  #=============================================================================
  # Dispose
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

    @scene =
      nil
  end
end


#===============================================================================
# Scene_Map Integration
#
# IMPORTANT:
#
# Spriteset_Map is completely untouched.
#
# Environmental FX run only AFTER the normal Scene_Map update has completed.
#===============================================================================

class Scene_Map
  #=============================================================================
  # Update Alias
  #=============================================================================

  unless method_defined?(:bushido_envfx_base_update)
    alias bushido_envfx_base_update update
  end


  def update(*args)
    #-------------------------------------------------------------------------
    # First allow Essentials and connected maps to perform ALL normal work.
    #-------------------------------------------------------------------------

    bushido_envfx_base_update(
      *args
    )

    #-------------------------------------------------------------------------
    # Only after the normal frame has completed do we touch environmental FX.
    #-------------------------------------------------------------------------

    if !@bushido_environment_fx_manager
      @bushido_environment_fx_manager =
        BushidoEnvironmentFXManager.new(
          self
        )
    end

    @bushido_environment_fx_manager.update
  end


  #=============================================================================
  # Connected Spriteset Cleanup
  #
  # Bushido/Essentials has disposeSpritesets alongside createSpritesets.
  # Clean our runtime FX BEFORE their source sprites/viewports are destroyed.
  #=============================================================================

  if method_defined?(:disposeSpritesets)

    unless method_defined?(:bushido_envfx_base_disposeSpritesets)
      alias bushido_envfx_base_disposeSpritesets disposeSpritesets
    end


    def disposeSpritesets(*args)
      if @bushido_environment_fx_manager
        begin
          @bushido_environment_fx_manager.dispose
        rescue
        end

        @bushido_environment_fx_manager =
          nil
      end

      bushido_envfx_base_disposeSpritesets(
        *args
      )
    end
  end
end