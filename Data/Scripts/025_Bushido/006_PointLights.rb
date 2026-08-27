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
# FIRE - DEBUG BASELINE
#
# Event names:
#
#   Fire(0,0)
#   Fire(4,-12)
#   Bonfire Fire(0,-8)
#
# Fire currently renders as a solid red square only.
#
# This is intentional so we can prove the safe baseline before
# reintroducing glow, additive blending, flicker, and particles.
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
# IMPORTANT
#
# This script:
#
#   - uses event names only
#   - has no pbPointLight
#   - has no pbFire
#   - requires no Parallel Process
#   - does not modify Game_Event
#   - does not modify Spriteset_Map
#   - discovers effects only after Scene_Map's normal update
#
#===============================================================================


module BushidoPointLights
  #=============================================================================
  # Shared
  #=============================================================================

  PIXEL_SIZE = 2

  BASE_Y_OFFSET = -16

  BLEND_TYPE = 1

  EFFECT_Z = 99999

  SCAN_INTERVAL = 15
  INITIAL_DELAY = 1


  #=============================================================================
  # Point Light Appearance
  #=============================================================================

  INNER_RADIUS = 24
  OUTER_RADIUS = 48

  INNER_COLOR = Color.new(
    255,
    225,
    150
  )

  OUTER_COLOR = Color.new(
    255,
    205,
    110
  )

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
  # Fire Debug Appearance
  #=============================================================================

  FIRE_DEBUG_SIZE = 16

  FIRE_DEBUG_COLOR = Color.new(
    255,
    0,
    0,
    255
  )


  #=============================================================================
  # Night Detection
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
  # Sprite Helpers
  #=============================================================================

  def self.character_from_sprite(sprite)
    return nil if !sprite

    begin
      return sprite.instance_variable_get(
        :@character
      )
    rescue
      return nil
    end
  end


  def self.event_name_from_sprite(sprite)
    character =
      character_from_sprite(
        sprite
      )

    return "" if !character

    begin
      event_data =
        character.instance_variable_get(
          :@event
        )

      return event_data.name.to_s if event_data
    rescue
    end

    return ""
  end


  #=============================================================================
  # Tag Detection
  #=============================================================================

  def self.light_sprite?(sprite)
    name =
      event_name_from_sprite(
        sprite
      )

    if name =~ /Light\s*\(\s*-?\d+\s*,\s*-?\d+\s*\)/i
      return true
    end

    return false
  end


  def self.fire_sprite?(sprite)
    name =
      event_name_from_sprite(
        sprite
      )

    if name =~ /Fire\s*\(\s*-?\d+\s*,\s*-?\d+\s*\)/i
      return true
    end

    return false
  end


  #=============================================================================
  # Offset Parsing
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
  # Scene Spriteset Discovery
  #=============================================================================

  def self.scene_spritesets(scene)
    results = []
    seen = {}

    return results if !scene

    begin
      variables =
        scene.instance_variables
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

    key =
      value.object_id

    return if seen[key]

    seen[key] =
      true

    if defined?(Spriteset_Map) &&
       value.is_a?(Spriteset_Map)

      results.push(
        value
      )

      return
    end

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


  def self.character_sprites_from_spriteset(
    spriteset
  )
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
# Point Light
#===============================================================================

class BushidoPointLight
  def initialize(character_sprite)
    @character_sprite =
      character_sprite

    viewport =
      nil

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
    dispose_sprite(
      @inner
    )

    dispose_sprite(
      @outer
    )

    @inner =
      nil

    @outer =
      nil

    @character_sprite =
      nil
  end
end


#===============================================================================
# Fire Effect - Minimal Debug Version
#
# Fire currently creates ONE red square.
#
# No:
#   - glow
#   - blending
#   - particles
#   - flicker
#   - opacity animation
#
#===============================================================================

class BushidoFireEffect
  def initialize(character_sprite)
    @character_sprite =
      character_sprite

    viewport =
      nil

    begin
      viewport =
        @character_sprite.viewport
    rescue
      viewport =
        nil
    end

    @sprite =
      Sprite.new(
        viewport
      )

    @sprite.bitmap =
      Bitmap.new(
        BushidoPointLights::FIRE_DEBUG_SIZE,
        BushidoPointLights::FIRE_DEBUG_SIZE
      )

    @sprite.bitmap.fill_rect(
      0,
      0,
      BushidoPointLights::FIRE_DEBUG_SIZE,
      BushidoPointLights::FIRE_DEBUG_SIZE,
      BushidoPointLights::FIRE_DEBUG_COLOR
    )

    @sprite.ox =
      BushidoPointLights::FIRE_DEBUG_SIZE /
      2

    @sprite.oy =
      BushidoPointLights::FIRE_DEBUG_SIZE /
      2

    @sprite.z =
      BushidoPointLights::EFFECT_Z

    @sprite.visible =
      true
  end


  #=============================================================================
  # Update
  #=============================================================================

  def update
    return if disposed?
    return if source_disposed?

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

    # Fire marker events may intentionally have no event graphic.
    # Their FX should still render.
    @sprite.visible =
      true
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

    @sprite =
      nil

    @character_sprite =
      nil
  end
end


#===============================================================================
# Scene-Level Environmental FX Manager
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

    if @initial_delay > 0
      @initial_delay -=
        1

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
  # Update Existing Effects
  #=============================================================================

  def update_effects
    remove =
      []

    @lights.each do |key, effect|
      begin
        if effect.source_disposed?
          remove.push(
            key
          )
        else
          effect.update
        end
      rescue
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


    remove =
      []

    @fires.each do |key, effect|
      begin
        if effect.source_disposed?
          remove.push(
            key
          )
        else
          effect.update
        end
      rescue
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
# Spriteset_Map is intentionally untouched.
#===============================================================================

class Scene_Map
  unless method_defined?(:bushido_envfx_base_update)
    alias bushido_envfx_base_update update
  end


  def update(*args)
    bushido_envfx_base_update(
      *args
    )

    if !@bushido_environment_fx_manager
      @bushido_environment_fx_manager =
        BushidoEnvironmentFXManager.new(
          self
        )
    end

    @bushido_environment_fx_manager.update
  end


  #=============================================================================
  # Cleanup Before Map Spritesets Are Destroyed
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