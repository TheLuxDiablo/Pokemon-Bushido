#===============================================================================
# Bushido Event Exporter UI
# Pokemon Bushido / Essentials v18.1
#
# Requires:
#   997_BushidoEventExporter.rb
#===============================================================================

module BushidoEventExporterUI
  BG          = Color.new(48, 38, 35)
  BG_DARK     = Color.new(31, 25, 23)
  PANEL       = Color.new(76, 60, 53)
  PANEL_DARK  = Color.new(45, 35, 31)
  PANEL_LIGHT = Color.new(112, 94, 82)

  WHITE       = Color.new(244, 232, 207)
  WHITE_DIM   = Color.new(190, 177, 157)

  GOLD        = Color.new(188, 144, 76)
  GOLD_DARK   = Color.new(122, 88, 47)

  RED         = Color.new(176, 49, 48)

  SHADOW      = Color.new(24, 18, 16, 96)

  HEADER_H = 44
  FOOTER_H = 76

  MARGIN = 14
  GAP    = 10

  MAP_W = 220
  ROW_H = 28


  def self.set_font(bitmap)
    begin
      BushidoFonts.apply(bitmap, :label)
    rescue
      pbSetSystemFont(bitmap)
    end
  end


  def self.draw_text(bitmap, text, x, y, width, height,
                     align=0, base=WHITE, shadow=SHADOW)
    pbDrawShadowText(
      bitmap,
      x,
      y,
      width,
      height,
      text.to_s,
      base,
      shadow,
      align
    )
  end


  def self.fill(bitmap, x, y, width, height, color)
    return if width <= 0 || height <= 0
    bitmap.fill_rect(x, y, width, height, color)
  end


  def self.draw_border(bitmap, x, y, width, height, color)
    fill(bitmap, x, y, width, 2, color)
    fill(bitmap, x, y + height - 2, width, 2, color)
    fill(bitmap, x, y, 2, height, color)
    fill(bitmap, x + width - 2, y, 2, height, color)
  end


  def self.truncate(bitmap, text, max_width)
    text = text.to_s

    return text if bitmap.text_size(text).width <= max_width

    suffix = "..."

    while text.length > 0
      test = text + suffix

      if bitmap.text_size(test).width <= max_width
        return test
      end

      text = text[0, text.length - 1]
    end

    return suffix
  end


  def self.open
    scene = BushidoEventExporterScene.new
    scene.start
  end
end


class BushidoEventExporterScene
  def start
    unless defined?(BushidoEventExporter)
      pbMessage("Bushido Event Exporter backend was not found.")
      return
    end

    @sprites = {}

    @viewport = Viewport.new(
      0,
      0,
      Graphics.width,
      Graphics.height
    )

    @viewport.z = 99999

    @sprites["background"] = BitmapSprite.new(
      Graphics.width,
      Graphics.height,
      @viewport
    )

    @sprites["overlay"] = BitmapSprite.new(
      Graphics.width,
      Graphics.height,
      @viewport
    )

    @sprites["background"].z = 0
    @sprites["overlay"].z    = 1

    BushidoEventExporterUI.set_font(
      @sprites["overlay"].bitmap
    )

    @focus = :maps

    @map_ids   = []
    @map_index = 0
    @map_top   = 0

    @event_ids   = []
    @event_index = 0
    @event_top   = 0

    @status_text = "Select a map and event to export."
    @status_timer = 0

    load_maps
    load_events

    draw_background
    refresh

    pbFadeInAndShow(@sprites) { update }

    main_loop

    pbFadeOutAndHide(@sprites) { update }

    pbDisposeSpriteHash(@sprites)

    if @viewport && !@viewport.disposed?
      @viewport.dispose
    end
  end


  #=============================================================================
  # Data
  #=============================================================================

  def load_maps
    infos = BushidoEventExporter.load_map_infos

    old_id = selected_map_id

    @map_ids = []

    infos.keys.sort.each do |map_id|
      next if !infos[map_id]

      filename = sprintf(
        "Data/Map%03d.rxdata",
        map_id
      )

      next unless FileTest.exist?(filename)

      @map_ids << map_id
    end

    if old_id && @map_ids.include?(old_id)
      @map_index = @map_ids.index(old_id)
    end

    @map_index = 0 if @map_index.nil?
    @map_index = 0 if @map_index < 0

    if !@map_ids.empty? && @map_index >= @map_ids.length
      @map_index = @map_ids.length - 1
    end

    @map_top = 0 if @map_top.nil?

    ensure_map_visible
  end


  def load_events
    old_event_id = selected_event_id

    @event_ids = []
    @event_index = 0
    @event_top = 0

    map_id = selected_map_id

    return if map_id.nil?

    begin
      map = BushidoEventExporter.load_map(map_id)

      if map.events
        @event_ids = map.events.keys.sort
      end

      if old_event_id && @event_ids.include?(old_event_id)
        @event_index = @event_ids.index(old_event_id)
      end
    rescue => e
      set_status(
        "Could not load map: #{e.message}",
        180
      )
    end

    ensure_event_visible
  end


  def reload_data
    old_map_id   = selected_map_id
    old_event_id = selected_event_id

    load_maps

    if old_map_id && @map_ids.include?(old_map_id)
      @map_index = @map_ids.index(old_map_id)
    end

    load_events

    if old_event_id && @event_ids.include?(old_event_id)
      @event_index = @event_ids.index(old_event_id)
    end

    ensure_map_visible
    ensure_event_visible

    set_status(
      "Reloaded map data from disk.",
      120
    )

    pbPlayDecisionSE
    refresh
  end


  #=============================================================================
  # Selection
  #=============================================================================

  def selected_map_id
    return nil if !@map_ids
    return nil if @map_ids.empty?

    return @map_ids[@map_index]
  end


  def selected_event_id
    return nil if !@event_ids
    return nil if @event_ids.empty?

    return @event_ids[@event_index]
  end


  def selected_map
    id = selected_map_id

    return nil if id.nil?

    begin
      return BushidoEventExporter.load_map(id)
    rescue
      return nil
    end
  end


  def selected_event
    map = selected_map
    id  = selected_event_id

    return nil if !map
    return nil if id.nil?
    return nil if !map.events

    return map.events[id]
  end


  def selected_map_name
    id = selected_map_id

    return "No Map" if id.nil?

    return BushidoEventExporter.get_map_name(id)
  end


  #=============================================================================
  # Layout
  #=============================================================================

  def list_y
    return BushidoEventExporterUI::HEADER_H + 36
  end


  def list_bottom
    return Graphics.height -
           BushidoEventExporterUI::FOOTER_H -
           8
  end


  def visible_rows
    height = list_bottom - list_y

    rows = height / BushidoEventExporterUI::ROW_H
    rows = 1 if rows < 1

    return rows
  end


  def ensure_map_visible
    return if @map_ids.empty?

    rows = visible_rows

    if @map_index < @map_top
      @map_top = @map_index
    elsif @map_index >= @map_top + rows
      @map_top = @map_index - rows + 1
    end

    max_top = [@map_ids.length - rows, 0].max

    @map_top = max_top if @map_top > max_top
    @map_top = 0 if @map_top < 0
  end


  def ensure_event_visible
    return if @event_ids.empty?

    rows = visible_rows

    if @event_index < @event_top
      @event_top = @event_index
    elsif @event_index >= @event_top + rows
      @event_top = @event_index - rows + 1
    end

    max_top = [@event_ids.length - rows, 0].max

    @event_top = max_top if @event_top > max_top
    @event_top = 0 if @event_top < 0
  end


  #=============================================================================
  # Input
  #=============================================================================

  def main_loop
    loop do
      Graphics.update
      Input.update
      update

      if Input.trigger?(Input::B)
        pbPlayCancelSE
        break
      end

      if Input.trigger?(Input::LEFT)
        if @focus != :maps
          @focus = :maps
          pbPlayCursorSE
          refresh
        end

      elsif Input.trigger?(Input::RIGHT)
        if @focus != :events
          @focus = :events
          pbPlayCursorSE
          refresh
        end
      end

      if Input.repeat?(Input::UP)
        move_selection(-1)
      elsif Input.repeat?(Input::DOWN)
        move_selection(1)
      end

      if Input.trigger?(Input::C)
        export_selected_event
      end

      if key_trigger?(:M)
        export_selected_map
      end

      if key_trigger?(:R)
        reload_data
      end
    end
  end


  def move_selection(amount)
    if @focus == :maps
      return if @map_ids.empty?

      old = @map_index

      @map_index += amount

      if @map_index < 0
        @map_index = @map_ids.length - 1
      elsif @map_index >= @map_ids.length
        @map_index = 0
      end

      if old != @map_index
        pbPlayCursorSE
        ensure_map_visible
        load_events
        refresh
      end

    else
      return if @event_ids.empty?

      old = @event_index

      @event_index += amount

      if @event_index < 0
        @event_index = @event_ids.length - 1
      elsif @event_index >= @event_ids.length
        @event_index = 0
      end

      if old != @event_index
        pbPlayCursorSE
        ensure_event_visible
        refresh
      end
    end
  end


  def key_trigger?(symbol)
    begin
      constant = Input.const_get(symbol)
      return Input.trigger?(constant)
    rescue
    end

    return false
  end


  #=============================================================================
  # Export
  #=============================================================================

  def export_selected_event
    map_id   = selected_map_id
    event_id = selected_event_id

    if map_id.nil?
      pbPlayBuzzerSE
      set_status("No map selected.", 120)
      refresh
      return
    end

    if event_id.nil?
      pbPlayBuzzerSE
      set_status("This map has no events.", 120)
      refresh
      return
    end

    begin
      filename = BushidoEventExporter.export_event(
        map_id,
        event_id
      )

      pbPlayDecisionSE

      set_status(
        "Exported #{File.basename(filename)}",
        240
      )
    rescue => e
      pbPlayBuzzerSE

      set_status(
        "Export failed: #{e.message}",
        240
      )
    end

    refresh
  end


  def export_selected_map
    map_id = selected_map_id

    if map_id.nil?
      pbPlayBuzzerSE
      set_status("No map selected.", 120)
      refresh
      return
    end

    begin
      filename = BushidoEventExporter.export_map(
        map_id
      )

      pbPlayDecisionSE

      set_status(
        "Exported #{File.basename(filename)}",
        240
      )
    rescue => e
      pbPlayBuzzerSE

      set_status(
        "Map export failed: #{e.message}",
        240
      )
    end

    refresh
  end


  #=============================================================================
  # Status
  #=============================================================================

  def set_status(text, frames=120)
    @status_text  = text.to_s
    @status_timer = frames
  end


  #=============================================================================
  # Drawing
  #=============================================================================

  def draw_background
    b = @sprites["background"].bitmap

    b.clear

    BushidoEventExporterUI.fill(
      b,
      0,
      0,
      Graphics.width,
      Graphics.height,
      BushidoEventExporterUI::BG
    )

    BushidoEventExporterUI.fill(
      b,
      0,
      0,
      Graphics.width,
      BushidoEventExporterUI::HEADER_H,
      BushidoEventExporterUI::BG_DARK
    )

    BushidoEventExporterUI.fill(
      b,
      0,
      BushidoEventExporterUI::HEADER_H - 2,
      Graphics.width,
      2,
      BushidoEventExporterUI::GOLD
    )

    footer_y = Graphics.height -
               BushidoEventExporterUI::FOOTER_H

    BushidoEventExporterUI.fill(
      b,
      0,
      footer_y,
      Graphics.width,
      BushidoEventExporterUI::FOOTER_H,
      BushidoEventExporterUI::BG_DARK
    )

    BushidoEventExporterUI.fill(
      b,
      0,
      footer_y,
      Graphics.width,
      2,
      BushidoEventExporterUI::GOLD_DARK
    )
  end


  def refresh
    b = @sprites["overlay"].bitmap

    b.clear

    BushidoEventExporterUI.set_font(b)

    draw_header(b)
    draw_columns(b)
    draw_footer(b)
  end


  def draw_header(b)
    BushidoEventExporterUI.draw_text(
      b,
      "BUSHIDO EVENT EXPORTER",
      16,
      8,
      Graphics.width - 32,
      28,
      0,
      BushidoEventExporterUI::WHITE
    )

    id = selected_map_id

    if id
      BushidoEventExporterUI.draw_text(
        b,
        sprintf("MAP %03d", id),
        Graphics.width - 130,
        8,
        112,
        28,
        2,
        BushidoEventExporterUI::GOLD
      )
    end
  end


  def draw_columns(b)
    margin = BushidoEventExporterUI::MARGIN
    gap    = BushidoEventExporterUI::GAP

    map_x = margin
    map_w = BushidoEventExporterUI::MAP_W

    event_x = map_x + map_w + gap
    event_w = Graphics.width - event_x - margin

    panel_y = BushidoEventExporterUI::HEADER_H + 8
    panel_h = list_bottom - panel_y + 4

    draw_panel(
      b,
      map_x,
      panel_y,
      map_w,
      panel_h,
      "MAPS",
      @focus == :maps
    )

    draw_panel(
      b,
      event_x,
      panel_y,
      event_w,
      panel_h,
      "EVENTS",
      @focus == :events
    )

    draw_maps(
      b,
      map_x + 6,
      list_y,
      map_w - 12
    )

    draw_events(
      b,
      event_x + 6,
      list_y,
      event_w - 12
    )
  end


  def draw_panel(b, x, y, width, height, title, active)
    BushidoEventExporterUI.fill(
      b,
      x,
      y,
      width,
      height,
      BushidoEventExporterUI::PANEL_DARK
    )

    border =
      active ?
      BushidoEventExporterUI::GOLD :
      BushidoEventExporterUI::PANEL_LIGHT

    BushidoEventExporterUI.draw_border(
      b,
      x,
      y,
      width,
      height,
      border
    )

    BushidoEventExporterUI.draw_text(
      b,
      title,
      x + 8,
      y + 4,
      width - 16,
      24,
      0,
      border
    )
  end


  def draw_maps(b, x, y, width)
    if @map_ids.empty?
      BushidoEventExporterUI.draw_text(
        b,
        "No maps found.",
        x + 6,
        y,
        width - 12,
        BushidoEventExporterUI::ROW_H,
        0,
        BushidoEventExporterUI::WHITE_DIM
      )

      return
    end

    rows = visible_rows

    rows.times do |row|
      index = @map_top + row

      break if index >= @map_ids.length

      map_id   = @map_ids[index]
      map_name = BushidoEventExporter.get_map_name(map_id)

      row_y = y + row * BushidoEventExporterUI::ROW_H

      selected = index == @map_index

      if selected
        color =
          @focus == :maps ?
          BushidoEventExporterUI::GOLD_DARK :
          BushidoEventExporterUI::PANEL

        BushidoEventExporterUI.fill(
          b,
          x,
          row_y,
          width,
          BushidoEventExporterUI::ROW_H - 2,
          color
        )
      end

      id_text = sprintf("%03d", map_id)

      BushidoEventExporterUI.draw_text(
        b,
        id_text,
        x + 6,
        row_y + 2,
        38,
        22,
        0,
        selected ?
          BushidoEventExporterUI::WHITE :
          BushidoEventExporterUI::GOLD
      )

      available_width = width - 52

      display_name = BushidoEventExporterUI.truncate(
        b,
        map_name,
        available_width
      )

      BushidoEventExporterUI.draw_text(
        b,
        display_name,
        x + 48,
        row_y + 2,
        available_width,
        22,
        0,
        selected ?
          BushidoEventExporterUI::WHITE :
          BushidoEventExporterUI::WHITE_DIM
      )
    end

    draw_scroll_marker(
      b,
      x,
      y,
      width,
      @map_top,
      @map_ids.length
    )
  end


  def draw_events(b, x, y, width)
    if @event_ids.empty?
      BushidoEventExporterUI.draw_text(
        b,
        "No events on this map.",
        x + 6,
        y,
        width - 12,
        BushidoEventExporterUI::ROW_H,
        0,
        BushidoEventExporterUI::WHITE_DIM
      )

      return
    end

    map = selected_map

    return if !map

    rows = visible_rows

    rows.times do |row|
      index = @event_top + row

      break if index >= @event_ids.length

      event_id = @event_ids[index]
      event    = map.events[event_id]

      next if !event

      row_y = y + row * BushidoEventExporterUI::ROW_H

      selected = index == @event_index

      if selected
        color =
          @focus == :events ?
          BushidoEventExporterUI::GOLD_DARK :
          BushidoEventExporterUI::PANEL

        BushidoEventExporterUI.fill(
          b,
          x,
          row_y,
          width,
          BushidoEventExporterUI::ROW_H - 2,
          color
        )
      end

      BushidoEventExporterUI.draw_text(
        b,
        sprintf("%03d", event.id),
        x + 6,
        row_y + 2,
        38,
        22,
        0,
        selected ?
          BushidoEventExporterUI::WHITE :
          BushidoEventExporterUI::GOLD
      )

      coord_text = sprintf(
        "(%d,%d)",
        event.x,
        event.y
      )

      coord_width = 74

      BushidoEventExporterUI.draw_text(
        b,
        coord_text,
        x + width - coord_width - 6,
        row_y + 2,
        coord_width,
        22,
        2,
        BushidoEventExporterUI::WHITE_DIM
      )

      name_width = width - 52 - coord_width

      display_name = BushidoEventExporterUI.truncate(
        b,
        event.name.to_s,
        name_width
      )

      BushidoEventExporterUI.draw_text(
        b,
        display_name,
        x + 48,
        row_y + 2,
        name_width,
        22,
        0,
        selected ?
          BushidoEventExporterUI::WHITE :
          BushidoEventExporterUI::WHITE_DIM
      )
    end

    draw_scroll_marker(
      b,
      x,
      y,
      width,
      @event_top,
      @event_ids.length
    )
  end


  def draw_scroll_marker(b, x, y, width, top, total)
    rows = visible_rows

    return if total <= rows
    return if total <= 0

    track_x = x + width - 3
    track_h = rows * BushidoEventExporterUI::ROW_H

    BushidoEventExporterUI.fill(
      b,
      track_x,
      y,
      2,
      track_h,
      BushidoEventExporterUI::PANEL
    )

    thumb_h = (
      track_h * rows.to_f / total
    ).round

    thumb_h = 8 if thumb_h < 8

    max_top = total - rows

    ratio =
      max_top > 0 ?
      top.to_f / max_top :
      0.0

    travel = track_h - thumb_h

    thumb_y = y + (travel * ratio).round

    BushidoEventExporterUI.fill(
      b,
      track_x,
      thumb_y,
      2,
      thumb_h,
      BushidoEventExporterUI::GOLD
    )
  end


  def draw_footer(b)
    footer_y = Graphics.height -
               BushidoEventExporterUI::FOOTER_H

    event  = selected_event
    map_id = selected_map_id

    if map_id
      breadcrumb = sprintf(
        "%03d %s",
        map_id,
        selected_map_name
      )

      if event
        breadcrumb += sprintf(
          " / %03d %s",
          event.id,
          event.name
        )
      end

      BushidoEventExporterUI.draw_text(
        b,
        breadcrumb,
        16,
        footer_y + 7,
        Graphics.width - 32,
        24,
        0,
        BushidoEventExporterUI::WHITE
      )
    end

    if @status_timer && @status_timer > 0
      details = @status_text
      details_color = BushidoEventExporterUI::GOLD

    elsif event
      details = sprintf(
        "Event %03d | X:%d Y:%d | %d page%s",
        event.id,
        event.x,
        event.y,
        event.pages ? event.pages.length : 0,
        event.pages && event.pages.length == 1 ? "" : "s"
      )

      details_color = BushidoEventExporterUI::WHITE_DIM

    else
      details = "No event selected."
      details_color = BushidoEventExporterUI::WHITE_DIM
    end

    BushidoEventExporterUI.draw_text(
      b,
      details,
      16,
      footer_y + 29,
      Graphics.width - 32,
      20,
      0,
      details_color
    )

    controls =
      "ENTER Export Event    M Export Map    R Refresh    ESC Close"

    BushidoEventExporterUI.draw_text(
      b,
      controls,
      16,
      footer_y + 51,
      Graphics.width - 32,
      20,
      0,
      BushidoEventExporterUI::GOLD
    )
  end


  def update
    pbUpdateSpriteHash(@sprites)

    if @status_timer && @status_timer > 0
      @status_timer -= 1

      if @status_timer == 0
        @status_text = "Select a map and event to export."
        refresh
      end
    end
  end
end