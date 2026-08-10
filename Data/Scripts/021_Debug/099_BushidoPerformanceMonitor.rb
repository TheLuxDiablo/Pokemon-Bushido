#===============================================================================
# Bushido Performance Monitor
#-------------------------------------------------------------------------------
# Debug-only performance inspection tool for Pokémon Bushido.
#
# Current features:
# - Toggle with F10.
# - Current, rolling average, and recent-low FPS.
# - Current map ID, name, and player coordinates.
# - Loaded connected-map inspection.
# - Lightweight event-category counts.
#
# This tool only reads existing game state. It does not modify map or event
# behavior. Remove this file to remove the monitor completely.
#===============================================================================


#===============================================================================
# BushidoPerformanceSampler
#-------------------------------------------------------------------------------
# Collects lightweight performance and map information.
#
# FPS updates every 0.25 seconds.
# Map/event inspection also updates every 0.25 seconds rather than every frame.
#===============================================================================

class BushidoPerformanceSampler
  FPS_SAMPLE_INTERVAL  = 0.25
  DATA_SAMPLE_INTERVAL = 0.25
  AVERAGE_WINDOW       = 1.0
  LOW_WINDOW           = 5.0

  def initialize
    @cached_map_id   = nil
    @cached_map_name = ""

    @fps_elapsed = 0.0
    @fps_frames  = 0
    @fps_time    = 0.0

    @current_fps = nil
    @average_fps = nil
    @lowest_fps  = nil

    @fps_samples = []

    @data_elapsed = DATA_SAMPLE_INTERVAL
    @map_stats    = []
    @event_stats  = empty_event_stats
  end

  #-----------------------------------------------------------------------------
  # Public sampling
  #-----------------------------------------------------------------------------

  def sample
    delta = safe_delta

    update_fps(delta)
    update_inspection_data(delta)

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

    return {
      :current_fps => format_fps(@current_fps),
      :average_fps => format_fps(@average_fps),
      :lowest_fps  => format_fps(@lowest_fps),

      :map_id      => map_id,
      :map_name    => map_name,
      :player_x    => player_x,
      :player_y    => player_y,

      :loaded_maps => @map_stats,
      :event_stats => @event_stats
    }
  end

  #-----------------------------------------------------------------------------
  # Frame timing
  #-----------------------------------------------------------------------------

  def safe_delta
    delta = Graphics.delta_s
    return 0.0 if !delta
    return 0.0 if delta <= 0
    return delta
  rescue
    return 0.0
  end

  def update_fps(delta)
    return if delta <= 0

    @fps_elapsed += delta
    @fps_time    += delta
    @fps_frames  += 1

    return if @fps_elapsed < FPS_SAMPLE_INTERVAL

    fps = @fps_frames.to_f / @fps_elapsed

    @current_fps = fps
    @fps_samples.push([@fps_time, fps])

    @fps_elapsed = 0.0
    @fps_frames  = 0

    remove_old_fps_samples
    calculate_fps_windows
  end

  def remove_old_fps_samples
    cutoff = @fps_time - LOW_WINDOW

    while @fps_samples.length > 0 &&
          @fps_samples[0][0] < cutoff
      @fps_samples.shift
    end
  end

  def calculate_fps_windows
    return if @fps_samples.length == 0

    average_cutoff = @fps_time - AVERAGE_WINDOW
    average_total  = 0.0
    average_count  = 0
    lowest         = nil

    for sample in @fps_samples
      sample_time = sample[0]
      sample_fps  = sample[1]

      if sample_time >= average_cutoff
        average_total += sample_fps
        average_count += 1
      end

      lowest = sample_fps if !lowest || sample_fps < lowest
    end

    if average_count > 0
      @average_fps = average_total / average_count
    else
      @average_fps = @current_fps
    end

    @lowest_fps = lowest
  end

  def format_fps(value)
    return "--" if !value
    return sprintf("%.1f", value)
  end

  #-----------------------------------------------------------------------------
  # Loaded-map and event inspection
  #-----------------------------------------------------------------------------

  def update_inspection_data(delta)
    @data_elapsed += delta
    return if @data_elapsed < DATA_SAMPLE_INTERVAL

    @data_elapsed = 0.0

    collect_loaded_maps
    collect_event_stats
  end

  def collect_loaded_maps
    results = []

    if $MapFactory && $MapFactory.maps
      for map in $MapFactory.maps
        next if !map

        map_id    = map.map_id
        map_name  = pbGetBasicMapNameFromId(map_id)
        width     = 0
        height    = 0
        event_count = 0

        if map.data
          width  = map.data.xsize
          height = map.data.ysize
        end

        event_count = map.events.length if map.events

        results.push({
          :map_id      => map_id,
          :map_name    => map_name,
          :width       => width,
          :height      => height,
          :event_count => event_count
        })
      end
    end

    results.sort! { |a, b| a[:map_id] <=> b[:map_id] }
    @map_stats = results
  rescue
    @map_stats = []
  end

  def empty_event_stats
    return {
      :total        => 0,
      :active       => 0,
      :parallel     => 0,
      :autorun      => 0,
      :moving       => 0,
      :interpreters => 0
    }
  end

  def collect_event_stats
    stats = empty_event_stats

    if $MapFactory && $MapFactory.maps
      for map in $MapFactory.maps
        next if !map || !map.events

        for event in map.events.values
          next if !event

          stats[:total] += 1

          # should_update? without an argument returns the event's cached
          # update decision from its most recent Game_Event#update call.
          stats[:active] += 1 if event.should_update?

          stats[:parallel] += 1 if event.trigger == 4
          stats[:autorun]  += 1 if event.trigger == 3
          stats[:moving]   += 1 if event.moving?

          interpreter = event.instance_variable_get(:@interpreter)

          if interpreter && interpreter.running?
            stats[:interpreters] += 1
          end
        end
      end
    end

    @event_stats = stats
  rescue
    @event_stats = empty_event_stats
  end
end


#===============================================================================
# BushidoPerformanceOverlay
#-------------------------------------------------------------------------------
# Draws the visible developer HUD.
#===============================================================================

class BushidoPerformanceOverlay
  WIDTH  = 404
  HEIGHT = 372

  PANEL_PADDING  = 10
  HEADER_HEIGHT  = 32
  SECTION_HEIGHT = 22
  LINE_HEIGHT    = 21
  MAP_LINE_HEIGHT = 18
  DIVIDER_MARGIN = 3

  MAX_VISIBLE_MAPS = 6

  def initialize
    @sprite = Sprite.new
    @sprite.z = 99999
    @sprite.x = 6
    @sprite.y = 4
    @sprite.bitmap = Bitmap.new(WIDTH, HEIGHT)
    @sprite.visible = false

    @last_data = nil
    @cursor_y  = 0

    create_colors
  end

  #-----------------------------------------------------------------------------
  # Colors
  #-----------------------------------------------------------------------------

  def create_colors
    @background_color = Color.new(0, 0, 0, 210)
    @header_color     = Color.new(36, 42, 52, 245)
    @divider_color    = Color.new(110, 120, 135, 180)

    @title_color   = Color.new(255, 255, 255)
    @section_color = Color.new(150, 180, 220)
    @label_color   = Color.new(175, 190, 210)
    @value_color   = Color.new(255, 255, 255)
    @muted_color   = Color.new(150, 160, 175)

    @good_color    = Color.new(130, 235, 145)
    @warning_color = Color.new(245, 210, 105)
    @bad_color     = Color.new(245, 125, 115)
  end

  #-----------------------------------------------------------------------------
  # Public update
  #-----------------------------------------------------------------------------

  def update(data)
    return if data == @last_data

    @last_data = clone_display_data(data)
    redraw(data)
  end

  def clone_display_data(data)
    copy = data.clone

    copy[:loaded_maps] = []
    for map_data in data[:loaded_maps]
      copy[:loaded_maps].push(map_data.clone)
    end

    copy[:event_stats] = data[:event_stats].clone
    return copy
  end

  #-----------------------------------------------------------------------------
  # Full redraw
  #-----------------------------------------------------------------------------

  def redraw(data)
    bitmap = @sprite.bitmap
    bitmap.clear

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
    draw_performance(data)
    draw_divider
    draw_player(data)
    draw_divider
    draw_loaded_maps(data)
    draw_divider
    draw_events(data)
  end

  #-----------------------------------------------------------------------------
  # Major sections
  #-----------------------------------------------------------------------------

  def draw_performance(data)
    draw_section("PERFORMANCE")

    current_value = data[:current_fps]
    current_color = fps_color(current_value)

    draw_line("Current FPS", current_value, current_color)
    draw_line("Average FPS", data[:average_fps])
    draw_line("Lowest (5 sec)", data[:lowest_fps])
  end

  def draw_player(data)
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

  def draw_loaded_maps(data)
    maps = data[:loaded_maps]

    draw_section("LOADED MAPS")
    draw_line("Count", maps.length.to_s)

    visible_count = [maps.length, MAX_VISIBLE_MAPS].min

    for i in 0...visible_count
      draw_map_line(maps[i])
    end

    if maps.length > MAX_VISIBLE_MAPS
      hidden_count = maps.length - MAX_VISIBLE_MAPS
      draw_small_text(
        sprintf("+%d additional loaded map(s)", hidden_count),
        @muted_color
      )
    end
  end

  def draw_events(data)
    stats = data[:event_stats]

    draw_section("EVENTS")

    left_text = sprintf(
      "Total %d    Active %d",
      stats[:total],
      stats[:active]
    )

    right_text = sprintf(
      "Parallel %d    Autorun %d",
      stats[:parallel],
      stats[:autorun]
    )

    movement_text = sprintf(
      "Moving %d    Interpreters %d",
      stats[:moving],
      stats[:interpreters]
    )

    draw_small_text(left_text, @value_color)
    draw_small_text(right_text, @value_color)
    draw_small_text(movement_text, @value_color)
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

    bitmap.font.size  = 17
    bitmap.font.bold  = true
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

    bitmap.font.size  = 14
    bitmap.font.bold  = true
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
  # Standard label/value row
  #-----------------------------------------------------------------------------

  def draw_line(label, value, value_color = nil)
    bitmap = @sprite.bitmap

    label_width = 134
    value_x     = PANEL_PADDING + label_width

    bitmap.font.size  = 15
    bitmap.font.bold  = false
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
  # Loaded-map row
  #-----------------------------------------------------------------------------

  def draw_map_line(map_data)
    bitmap = @sprite.bitmap

    map_text = sprintf(
      "%03d  %s",
      map_data[:map_id],
      map_data[:map_name]
    )

    detail_text = sprintf(
      "%dx%d   %d ev",
      map_data[:width],
      map_data[:height],
      map_data[:event_count]
    )

    bitmap.font.size  = 13
    bitmap.font.bold  = false
    bitmap.font.color = @value_color

    bitmap.draw_text(
      PANEL_PADDING + 8,
      @cursor_y + 2,
      236,
      MAP_LINE_HEIGHT,
      map_text
    )

    bitmap.font.color = @muted_color

    bitmap.draw_text(
      250,
      @cursor_y + 2,
      WIDTH - 260,
      MAP_LINE_HEIGHT,
      detail_text,
      2
    )

    @cursor_y += MAP_LINE_HEIGHT
  end

  #-----------------------------------------------------------------------------
  # Compact text row
  #-----------------------------------------------------------------------------

  def draw_small_text(text, color)
    bitmap = @sprite.bitmap

    bitmap.font.size  = 13
    bitmap.font.bold  = false
    bitmap.font.color = color

    bitmap.draw_text(
      PANEL_PADDING + 8,
      @cursor_y + 2,
      WIDTH - (PANEL_PADDING * 2) - 8,
      MAP_LINE_HEIGHT,
      text
    )

    @cursor_y += MAP_LINE_HEIGHT
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
  # FPS coloring
  #-----------------------------------------------------------------------------

  def fps_color(fps_text)
    fps = fps_text.to_f

    return @value_color if fps <= 0
    return @good_color if fps >= 55
    return @warning_color if fps >= 40
    return @bad_color
  end

  #-----------------------------------------------------------------------------
  # Visibility and cleanup
  #-----------------------------------------------------------------------------

  def visible=(value)
    @sprite.visible = value
  end

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
# Controls input, monitor state, sampling, and drawing.
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
# Scene_Map triggers this once during each overworld update.
#===============================================================================

Events.onMapUpdate += proc { |_sender|
  BushidoPerformanceMonitor.update
}