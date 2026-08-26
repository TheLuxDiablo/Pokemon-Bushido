#===============================================================================
# Bushido Point Lights
# Pokemon Essentials v18.1
#
# Save as:
#   006_PointLights.rb
#
# Event calls:
#   pbPointLight
#   pbPointLightOff
#
# Optional event-name offset:
#
#   Light(0,0)
#   Light(12,-8)
#   Lamp Light(-16,4)
#
# Offset values are PIXELS.
#
# X:
#   negative = left
#   positive = right
#
# Y:
#   negative = up
#   positive = down
#
# Example:
#
#   Light(12,-8)
#
# moves the center of the glow:
#   12 pixels right
#   8 pixels up
#
# Point lights are only visible at night.
#===============================================================================


module BushidoPointLights
  #=============================================================================
  # Appearance
  #=============================================================================

  # Radius of each glow layer in pixels.
  INNER_RADIUS = 24
  OUTER_RADIUS = 48

  # Warm lantern colors.
  INNER_COLOR = Color.new(255, 225, 150)
  OUTER_COLOR = Color.new(255, 205, 110)

  # Overall transparency.
  #
  # Inner is stronger.
  # Outer is deliberately very soft.
    INNER_OPACITY = 145
    OUTER_OPACITY = 85

  #=============================================================================
  # Pulse
  #=============================================================================

  # How much each ring changes size.
  INNER_PULSE_SCALE = 0.045
  OUTER_PULSE_SCALE = 0.075

  # Outer ring pulses faster.
  INNER_PULSE_SPEED = 0.035
  OUTER_PULSE_SPEED = 0.065

  # Prevents both rings from peaking at the same time.
  OUTER_PULSE_OFFSET = 1.7

  # Small opacity pulse layered on top of the scale pulse.
  INNER_OPACITY_PULSE = 14
  OUTER_OPACITY_PULSE = 18

  #=============================================================================
  # Rendering
  #=============================================================================

  # RMXP screen_y sits around the bottom/feet of an event.
  # This pulls the default glow center upward toward the middle of its tile.
  BASE_Y_OFFSET = -16

  # Additive blending.
  BLEND_TYPE = 1

  # Draw the radial glow using 2x2 blocks instead of individual pixels.
  # This produces the chunky 2px-density look.
  PIXEL_SIZE = 2

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

      # Fallback if Bushido's day/night helper isn't available.
      hour = time.hour
      return (hour >= 20 || hour < 6)
    rescue
      return false
    end
  end

  #=============================================================================
  # Event Name
  #=============================================================================

  def self.event_name(event)
    return "" if !event

    begin
      data = event.instance_variable_get(:@event)
      return data.name.to_s if data
    rescue
    end

    return ""
  end

  #=============================================================================
  # Event Offset
  #
  # Reads:
  #
  #   Light(12,-8)
  #
  # as:
  #
  #   +12 pixels X
  #   -8 pixels Y
  #
  # The word Light can appear anywhere in the event name.
  #
  # Examples:
  #
  #   Light(0,0)
  #   Street Lamp Light(4,-20)
  #   ShrineLantern Light(-12,6)
  #=============================================================================

  def self.event_offset(event)
    name = event_name(event)

    if name =~ /Light\s*\(\s*(-?\d+)\s*,\s*(-?\d+)\s*\)/i
      return [$1.to_i, $2.to_i]
    end

    return [0, 0]
  end

  #=============================================================================
  # Pixelated Radial Glow
  #
  # The original version rendered a smooth gradient at full screen resolution.
  # This one deliberately samples the glow in 2x2 blocks.
  #
  # That means the edge and falloff retain the pixel structure of Bushido
  # instead of looking like a modern high-resolution blur.
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
        # Sample from the center of this 2x2 block.
        sample_x = x + (PIXEL_SIZE / 2.0)
        sample_y = y + (PIXEL_SIZE / 2.0)

        dx = sample_x - center
        dy = sample_y - center

        distance = Math.sqrt(
          (dx * dx) +
          (dy * dy)
        )

        if distance <= max_distance
          strength = 1.0 - (distance / max_distance)

          # Stronger center, softer outer edge.
          strength *= strength

          alpha = (255 * strength).to_i

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
end


#===============================================================================
# Point Light
#===============================================================================

class BushidoPointLight
  def initialize(event, viewport)
    @event = event

    # Outer sprite is created first so the inner glow draws above it.
    @outer = Sprite.new(viewport)
    @inner = Sprite.new(viewport)

    @outer.bitmap = BushidoPointLights.make_glow(
      BushidoPointLights::OUTER_RADIUS,
      BushidoPointLights::OUTER_COLOR
    )

    @inner.bitmap = BushidoPointLights.make_glow(
      BushidoPointLights::INNER_RADIUS,
      BushidoPointLights::INNER_COLOR
    )

    setup_sprite(@outer)
    setup_sprite(@inner)

    @inner.opacity = 0
    @outer.opacity = 0

    # Random starting point prevents every lamp on the map from
    # breathing in perfect synchronization.
    @pulse_time = rand(1000)

    update
  end

  #=============================================================================
  # Setup
  #=============================================================================

  def setup_sprite(sprite)
    sprite.ox = sprite.bitmap.width / 2
    sprite.oy = sprite.bitmap.height / 2

    sprite.blend_type = BushidoPointLights::BLEND_TYPE

    # High enough to draw with the world, but still under menus/windows.
    sprite.z = 99999
  end

  #=============================================================================
  # Update
  #=============================================================================

  def update
    return if disposed?

    update_position
    update_visibility
    update_pulse
  end

  #=============================================================================
  # Position
  #=============================================================================

  def update_position
    offset = BushidoPointLights.event_offset(@event)

    # Offset values are directly in pixels.
    offset_x = offset[0]
    offset_y = offset[1]

    x = @event.screen_x + offset_x

    y = @event.screen_y +
        BushidoPointLights::BASE_Y_OFFSET +
        offset_y

    @inner.x = x
    @inner.y = y

    @outer.x = x
    @outer.y = y
  end

  #=============================================================================
  # Visibility
  #=============================================================================

  def update_visibility
    visible = BushidoPointLights.night?

    @inner.visible = visible
    @outer.visible = visible
  end

  #=============================================================================
  # Pulse
  #=============================================================================

  def update_pulse
    return if !@inner.visible

    @pulse_time += 1.0

    inner_wave = Math.sin(
      @pulse_time *
      BushidoPointLights::INNER_PULSE_SPEED
    )

    outer_wave = Math.sin(
      (@pulse_time *
       BushidoPointLights::OUTER_PULSE_SPEED) +
      BushidoPointLights::OUTER_PULSE_OFFSET
    )

    #-------------------------------------------------------------------------
    # Scale pulse
    #-------------------------------------------------------------------------

    inner_scale =
      1.0 +
      (inner_wave *
       BushidoPointLights::INNER_PULSE_SCALE)

    outer_scale =
      1.0 +
      (outer_wave *
       BushidoPointLights::OUTER_PULSE_SCALE)

    @inner.zoom_x = inner_scale
    @inner.zoom_y = inner_scale

    @outer.zoom_x = outer_scale
    @outer.zoom_y = outer_scale

    #-------------------------------------------------------------------------
    # Opacity pulse
    #-------------------------------------------------------------------------

    inner_opacity =
      BushidoPointLights::INNER_OPACITY +
      (inner_wave *
       BushidoPointLights::INNER_OPACITY_PULSE).to_i

    outer_opacity =
      BushidoPointLights::OUTER_OPACITY +
      (outer_wave *
       BushidoPointLights::OUTER_OPACITY_PULSE).to_i

    inner_opacity = 0 if inner_opacity < 0
    inner_opacity = 255 if inner_opacity > 255

    outer_opacity = 0 if outer_opacity < 0
    outer_opacity = 255 if outer_opacity > 255

    @inner.opacity = inner_opacity
    @outer.opacity = outer_opacity
  end

  #=============================================================================
  # Dispose
  #=============================================================================

  def dispose
    if @inner
      if @inner.bitmap && !@inner.bitmap.disposed?
        @inner.bitmap.dispose
      end

      if !@inner.disposed?
        @inner.dispose
      end
    end

    if @outer
      if @outer.bitmap && !@outer.bitmap.disposed?
        @outer.bitmap.dispose
      end

      if !@outer.disposed?
        @outer.dispose
      end
    end
  end

  def disposed?
    return true if !@inner
    return @inner.disposed?
  end
end


#===============================================================================
# Point Light Manager
#===============================================================================

class BushidoPointLightManager
  def initialize(viewport)
    @viewport = viewport
    @lights = {}
  end

  #=============================================================================
  # Update
  #=============================================================================

  def update
    sync_lights

    @lights.each_value do |light|
      light.update
    end
  end

  #=============================================================================
  # Synchronize Lights
  #=============================================================================

  def sync_lights
    return if !$game_map
    return if !$game_map.events

    #-------------------------------------------------------------------------
    # Add or remove lights based on each event's enabled flag.
    #-------------------------------------------------------------------------

    $game_map.events.each do |id, event|
      enabled = event.instance_variable_get(
        :@bushido_point_light
      )

      if enabled
        if !@lights[id]
          @lights[id] = BushidoPointLight.new(
            event,
            @viewport
          )
        end
      elsif @lights[id]
        @lights[id].dispose
        @lights.delete(id)
      end
    end

    #-------------------------------------------------------------------------
    # Remove lights whose events no longer exist.
    #-------------------------------------------------------------------------

    remove = []

    @lights.each_key do |id|
      if !$game_map.events[id]
        remove.push(id)
      end
    end

    remove.each do |id|
      if @lights[id]
        @lights[id].dispose
      end

      @lights.delete(id)
    end
  end

  #=============================================================================
  # Dispose
  #=============================================================================

  def dispose
    @lights.each_value do |light|
      light.dispose
    end

    @lights.clear
  end
end


#===============================================================================
# Event Calls
#===============================================================================

def pbPointLight
  event = nil

  # Try the current interpreter first.
  begin
    event = get_character(0)
  rescue
  end

  # Fallback for Bushido/Essentials interpreter setups.
  if !event &&
     defined?($game_system) &&
     $game_system

    interpreter = nil

    begin
      interpreter = $game_system.map_interpreter
    rescue
    end

    if interpreter
      begin
        event = interpreter.get_character(0)
      rescue
      end
    end
  end

  return if !event

  event.instance_variable_set(
    :@bushido_point_light,
    true
  )
end


def pbPointLightOff
  event = nil

  begin
    event = get_character(0)
  rescue
  end

  if !event &&
     defined?($game_system) &&
     $game_system

    interpreter = nil

    begin
      interpreter = $game_system.map_interpreter
    rescue
    end

    if interpreter
      begin
        event = interpreter.get_character(0)
      rescue
      end
    end
  end

  return if !event

  event.instance_variable_set(
    :@bushido_point_light,
    false
  )
end


#===============================================================================
# Spriteset_Map Integration
#===============================================================================

class Spriteset_Map
  alias bushido_pointlights_initialize initialize

  def initialize(*args)
    bushido_pointlights_initialize(*args)

    viewport = nil

    begin
      viewport = @viewport1
    rescue
    end

    @bushido_point_light_manager =
      BushidoPointLightManager.new(viewport)
  end


  alias bushido_pointlights_update update

  def update(*args)
    bushido_pointlights_update(*args)

    if @bushido_point_light_manager
      @bushido_point_light_manager.update
    end
  end


  alias bushido_pointlights_dispose dispose

  def dispose(*args)
    if @bushido_point_light_manager
      @bushido_point_light_manager.dispose
      @bushido_point_light_manager = nil
    end

    bushido_pointlights_dispose(*args)
  end
end