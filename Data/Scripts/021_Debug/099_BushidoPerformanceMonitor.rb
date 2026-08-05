#===============================================================================
# Bushido Performance Monitor
#-------------------------------------------------------------------------------
# Debug-only performance inspection tool for Pokémon Bushido.
#
# Current features:
# - Toggle with F10.
# - Display current FPS.
# - Display current map ID and name.
# - Display player coordinates.
# - Uses Bushido's configured in-game font.
# - Modular HUD layout for future performance sections.
#
# Remove this file to remove the monitor completely.
#===============================================================================


#===============================================================================
# BushidoPerformanceSampler
#-------------------------------------------------------------------------------
# Reads lightweight information from the current game state.
#
# FPS is calculated over short 0.25-second windows. This is more readable than
# displaying 1 / frame time directly, which would fluctuate every frame.
#===============================================================================

class BushidoPerformanceSampler
  FPS_SAMPLE_INTERVAL = 0.25

  def initialize
    @cached_map_id   = nil
    @cached_map_name = ""

    @fps_elapsed = 0.0
    @fps_frames  = 0
    @current_fps = nil
  end

  def update_fps
    delta = Graphics.delta_s
    return if delta <= 0

    @fps_elapsed += delta
    @fps_frames += 1

    if @fps_elapsed >= FPS_SAMPLE_INTERVAL
      @current_fps = @fps_frames.to_f / @fps_elapsed
      @fps_elapsed = 0.0
      @fps_frames  = 0
    end
  end

  def sample
    update_fps

    map_id   = 0
    map_name = ""
    player_x = 0
    player_y = 0

    if $game_map
      map_id = $game_map.map_id

      if map_id != @cached_map_id
        @cached_map_id   = map_id
        @cached_map_name = pbGetBasicMapNameFromId(map_id)
      end

      map_name = @cached_map_name
    end

    if $game_player
      player_x = $game_player.x
      player_y = $game_player.y
    end

    fps_text = "--"
    fps_text = sprintf("%.1f", @current_fps) if @current_fps

    return {
      :fps      => fps_text,
      :map_id   => map_id,
      :map_name => map_name,
      :player_x => player_x,
      :player_y => player_y
    }
  end
end


#===============================================================================
# BushidoPerformanceOverlay
#-------------------------------------------------------------------------------
# Owns and draws the visible performance HUD.
#
# The layout is built from reusable methods:
# - draw_header
# - draw_section
# - draw_line
# - draw_divider
#
# Each method advances @cursor_y automatically.
#===============================================================================

class BushidoPerformanceOverlay
  WIDTH  = 320
  HEIGHT = 168

  PANEL_PADDING  = 10
  HEADER_HEIGHT  = 32
  SECTION_HEIGHT = 22
  LINE_HEIGHT    = 22
  DIVIDER_MARGIN = 4

  def initialize
    @sprite = Sprite.new
    @sprite.z = 99999
    @sprite.x = 8
    @sprite.y = 8
    @sprite.bitmap = Bitmap.new(WIDTH, HEIGHT)
    @sprite.visible = false

    @last_data = nil
    @cursor_y = 0

    create_colors
  end

  #-----------------------------------------------------------------------------
  # Color setup
  #-----------------------------------------------------------------------------

  def create_colors
    @background_color = Color.new(0, 0, 0, 210)
    @header_color     = Color.new(36, 42, 52, 245)
    @divider_color    = Color.new(110, 120, 135, 180)

    @title_color      = Color.new(255, 255, 255)
    @section_color    = Color.new(150, 180, 220)
    @label_color      = Color.new(175, 190, 210)
    @value_color      = Color.new(255, 255, 255)
  end

  #-----------------------------------------------------------------------------
  # Public update
  #-----------------------------------------------------------------------------

  def update(data)
    return if data == @last_data

    @last_data = data.clone
    redraw(data)
  end

  #-----------------------------------------------------------------------------
  # Full redraw
  #-----------------------------------------------------------------------------

  def redraw(data)
    bitmap = @sprite.bitmap
    bitmap.clear

    # Use Bushido's configured in-game font and fallback settings.
    pbSetSystemFont(bitmap)

    bitmap.fill_rect(
      0,
      0,
      WIDTH,
      HEIGHT,
      @background_color
    )

    @cursor_y = 0

    draw_header("Bushido Performance Monitor")

    draw_section("PERFORMANCE")
    draw_line("Current FPS", data[:fps])

    draw_divider

    draw_section("PLAYER")

    map_text = sprintf(
      "%03d - %s",
      data[:map_id],
      data[:map_name]
    )

    position_text = sprintf(
      "(%d, %d)",
      data[:player_x],
      data[:player_y]
    )

    draw_line("Map", map_text)
    draw_line("Position", position_text)
  end

  #-----------------------------------------------------------------------------
  # Header
  #-----------------------------------------------------------------------------

  def draw_header(text)
    bitmap = @sprite.bitmap

    bitmap.fill_rect(
      0,
      @cursor_y,
      WIDTH,
      HEADER_HEIGHT,
      @header_color
    )

    bitmap.font.size = 17
    bitmap.font.bold = true
    bitmap.font.color = @title_color

    bitmap.draw_text(
      PANEL_PADDING,
      @cursor_y + 8,
      WIDTH - (PANEL_PADDING * 2),
      HEADER_HEIGHT - 4,
      text
    )

    bitmap.font.bold = false
    @cursor_y += HEADER_HEIGHT
  end

  #-----------------------------------------------------------------------------
  # Section heading
  #-----------------------------------------------------------------------------

  def draw_section(text)
    bitmap = @sprite.bitmap

    bitmap.font.size = 14
    bitmap.font.bold = true
    bitmap.font.color = @section_color

    bitmap.draw_text(
      PANEL_PADDING,
      @cursor_y + 6,
      WIDTH - (PANEL_PADDING * 2),
      SECTION_HEIGHT,
      text
    )

    bitmap.font.bold = false
    @cursor_y += SECTION_HEIGHT
  end

  #-----------------------------------------------------------------------------
  # Label/value line
  #-----------------------------------------------------------------------------

  def draw_line(label, value, value_color = nil)
    bitmap = @sprite.bitmap

    label_width = 108
    value_x = PANEL_PADDING + label_width

    bitmap.font.size = 15
    bitmap.font.bold = false
    bitmap.font.color = @label_color

    bitmap.draw_text(
      PANEL_PADDING,
      @cursor_y + 2,
      label_width,
      LINE_HEIGHT,
      label.to_s
    )

    bitmap.font.color = value_color || @value_color

    bitmap.draw_text(
      value_x,
      @cursor_y + 2,
      WIDTH - value_x - PANEL_PADDING,
      LINE_HEIGHT,
      value.to_s
    )

    @cursor_y += LINE_HEIGHT
  end

  #-----------------------------------------------------------------------------
  # Divider
  #-----------------------------------------------------------------------------

  def draw_divider
    bitmap = @sprite.bitmap

    @cursor_y += DIVIDER_MARGIN

    bitmap.fill_rect(
      PANEL_PADDING,
      @cursor_y,
      WIDTH - (PANEL_PADDING * 2),
      1,
      @divider_color
    )

    @cursor_y += DIVIDER_MARGIN + 1
  end

  #-----------------------------------------------------------------------------
  # Visibility
  #-----------------------------------------------------------------------------

  def visible=(value)
    @sprite.visible = value
  end

  #-----------------------------------------------------------------------------
  # Cleanup
  #-----------------------------------------------------------------------------

  def dispose
    return if !@sprite

    if @sprite.bitmap && !@sprite.bitmap.disposed?
      @sprite.bitmap.dispose
    end

    @sprite.dispose if !@sprite.disposed?

    @sprite = nil
    @last_data = nil
  end
end


#===============================================================================
# BushidoPerformanceMonitor
#-------------------------------------------------------------------------------
# Controls monitor state, input, sampling, and overlay updates.
#===============================================================================

module BushidoPerformanceMonitor
  TOGGLE_KEY = 0x79   # F10

  @enabled = false
  @overlay = nil
  @sampler = nil

  def self.enabled?
    return @enabled == true
  end

  def self.ensure_components
    @sampler = BushidoPerformanceSampler.new if !@sampler
    @overlay = BushidoPerformanceOverlay.new if !@overlay
  end

  def self.toggle
    ensure_components

    @enabled = !@enabled
    @overlay.visible = @enabled

    if @enabled
      @overlay.update(@sampler.sample)
    end

    echoln(
      "Bushido Performance Monitor: " +
      (@enabled ? "ON" : "OFF")
    )
  end

  def self.update
    return if !$DEBUG

    toggle if Input.triggerex?(TOGGLE_KEY)

    return if !@enabled

    ensure_components
    @overlay.update(@sampler.sample)
  end

  def self.dispose
    if @overlay
      @overlay.dispose
      @overlay = nil
    end

    @sampler = nil
    @enabled = false
  end
end


#===============================================================================
# Update Hook
#-------------------------------------------------------------------------------
# Scene_Map triggers this event once during each overworld update.
#===============================================================================

Events.onMapUpdate += proc { |_sender|
  BushidoPerformanceMonitor.update
}