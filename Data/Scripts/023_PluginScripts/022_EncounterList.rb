#===============================================================================
# Pokémon Bushido - Habitat Scroll
# Essentials v18.x
#===============================================================================
PluginManager.register({
  :name    => "Bushido Habitat Scroll",
  :version => "4.0",
  :credits => ["theluxdiablo", "raZ", "Nuri Yuri", "Vendily",
               "Savordez", "Marin", "PurpleZaffre", "ThatWelshOne_"]
})

#===============================================================================
# Configuration
#===============================================================================
module BushidoHabitat
  ASSET_ROOT = "Graphics/Pictures/HabitatScroll"
  BACKGROUND = "#{ASSET_ROOT}/bg"

  def self.asset(name)
    return "#{ASSET_ROOT}/#{name}"
  end

  COLUMNS        = 2
  ROWS           = 4
  ITEMS_PER_PAGE = COLUMNS * ROWS

  ENCOUNTER_NAMES = [
    "Grass",
    "Cave",
    "Surfing",
    "Rock Smash",
    "Old Rod",
    "Good Rod",
    "Super Rod",
    "Headbutt",
    "Headbutt (High)",
    "Grass - Morning",
    "Grass - Day",
    "Grass - Night",
    "Bug Contest",
    "Shaking Grass",
    "Rippling Water",
    "Dust Clouds",
    "Birds"
  ]

  ENCOUNTER_SHORT_NAMES = [
    "Grass",
    "Cave",
    "Surf",
    "Rock Smash",
    "Old Rod",
    "Good Rod",
    "Super Rod",
    "Headbutt",
    "High Headbutt",
    "Morning Grass",
    "Day Grass",
    "Night Grass",
    "Bug Contest",
    "Shaking Grass",
    "Rippling Water",
    "Dust Cloud",
    "Birds"
  ]

  BG            = Color.new(91, 63, 39)
  PANEL         = Color.new(227, 206, 165)
  PANEL_DARK    = Color.new(212, 184, 136)
  PARCHMENT     = Color.new(244, 226, 190)
  PARCHMENT_DIM = Color.new(188, 151, 102)
  INK           = Color.new(56, 39, 27)
  WHITE         = Color.new(255, 247, 226)
  MUTED         = Color.new(122, 91, 61)
  RED           = Color.new(116, 89, 61)
  RED_LIGHT     = Color.new(166, 132, 84)
  GOLD          = Color.new(156, 116, 62)
  BLACK         = Color.new(0, 0, 0)
  SHADOW        = Color.new(83, 55, 33, 80)

  UNKNOWN_SHOW_PRIMARY_TYPE = true



  #--------------------------------------------------------------------------
  #--------------------------------------------------------------------------
  def self.primary_type(species, form=0)
    @type_cache ||= {}
    key = [species, form]
    return @type_cache[key] if @type_cache.has_key?(key)

    type = nil

    begin
      if defined?(PokeBattle_Pokemon)
        pkmn = PokeBattle_Pokemon.new(species, 5, $Trainer)
        pkmn.form = form if pkmn.respond_to?(:form=)
        type = pkmn.type1 if pkmn.respond_to?(:type1)
      end
    rescue
    end

    begin
      if type.nil? && defined?(GameData::Species)
        data = GameData::Species.get_species_form(species, form)
        type = data.types[0]
      end
    rescue
    end

    @type_cache[key] = type
    return type
  end

  def self.type_name(type)
    return _INTL("???") if type.nil?

    begin
      if type.is_a?(Symbol)
        return type.to_s.capitalize
      end
      return PBTypes.getName(type)
    rescue
      return type.to_s.capitalize
    end
  end

  def self.type_symbol(type)
    return :UNKNOWN if type.nil?
    return type if type.is_a?(Symbol)

    begin
      name = PBTypes.getName(type)
      return name.upcase.gsub(" ", "_").to_sym
    rescue
      return :UNKNOWN
    end
  end


  #--------------------------------------------------------------------------
  #--------------------------------------------------------------------------
  def self.visited_maps
    return [] if !$PokemonGlobal
    $PokemonGlobal.habitatVisitedMaps = [] if !$PokemonGlobal.habitatVisitedMaps
    return $PokemonGlobal.habitatVisitedMaps
  end

  def self.register_map(map_id)
    return if !$PokemonGlobal
    return if !map_id || map_id <= 0
    maps = self.visited_maps
    maps.push(map_id) if !maps.include?(map_id)
  end

  #--------------------------------------------------------------------------
  #--------------------------------------------------------------------------
  def self.map_name(map_id)
    begin
      infos = load_data("Data/MapInfos.rxdata")
      return infos[map_id].name if infos && infos[map_id]
    rescue
    end
    return _INTL("Unknown Area")
  end

  def self.resolve_bitmap(path)
    begin
      return pbResolveBitmap(path)
    rescue
      return nil
    end
  end

  def self.seen?(species)
    return false if !$Trainer
    begin
      return !!$Trainer.seen[species]
    rescue
      return false
    end
  end

  def self.owned?(species)
    return false if !$Trainer
    begin
      return !!$Trainer.owned[species]
    rescue
      return false
    end
  end

  def self.species_name(species)
    begin
      return PBSpecies.getName(species)
    rescue
      return _INTL("Pokémon")
    end
  end

  def self.encounter_name(index, short=false)
    names = short ? ENCOUNTER_SHORT_NAMES : ENCOUNTER_NAMES
    return names[index] if index && index >= 0 && index < names.length
    begin
      return [EncounterTypes::Names].flatten[index]
    rescue
      return _INTL("Encounter")
    end
  end
end

#===============================================================================
# Persistent visited-map tracking
#===============================================================================
class PokemonGlobalMetadata
  attr_accessor :habitatVisitedMaps
end

class Game_Map
  alias bushido_habitat_setup setup unless method_defined?(:bushido_habitat_setup)
  def setup(map_id)
    bushido_habitat_setup(map_id)
    BushidoHabitat.register_map(map_id)
  end
end

#===============================================================================
# Habitat UI
#===============================================================================
class EncounterListUI
  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}

    @encdata       = pbLoadEncountersData
    @current_mapid = $game_map.map_id
    BushidoHabitat.register_map(@current_mapid)

    @maps          = []
    @map_index     = 0
    @entries       = []
    @selected      = 0
    @page          = 0
    @map_states    = {}
    @type_cache    = {}

    build_map_list
  end

  #-----------------------------------------------------------------------------
  # Data
  #-----------------------------------------------------------------------------
  def map_has_encounters?(map_id)
    return false if !@encdata
    return false if !@encdata.is_a?(Hash)
    return false if !@encdata[map_id]
    enc = @encdata[map_id][1]
    return false if !enc
    enc.each do |type|
      return true if type && type.length > 0
    end
    return false
  end

  def build_map_list
    visited = BushidoHabitat.visited_maps.clone
    visited.push(@current_mapid) if !visited.include?(@current_mapid)

    @maps = visited.select { |id| map_has_encounters?(id) }

    @maps.push(@current_mapid) if !@maps.include?(@current_mapid)

    @maps = [@current_mapid] if @maps.length == 0

    idx = @maps.index(@current_mapid)
    @map_index = idx ? idx : 0
  end

  def current_map_id
    return @maps[@map_index]
  end

  def current_map_name
    return BushidoHabitat.map_name(current_map_id)
  end

  def species_for_encounter_type(map_id, type_index)
    return [] if !@encdata || !@encdata.is_a?(Hash)
    return [] if !@encdata[map_id]

    enc = @encdata[map_id][1]
    return [] if !enc || !enc[type_index]

    temp_enc_array = enc[type_index].clone
    temp_enc_array.compact!
    temp_enc_array.map! { |slot| slot[0] }
    temp_enc_array.flatten!
    temp_enc_array.compact!
    temp_enc_array.uniq!

    temp_enc_array.each_with_index do |s, i|
      if (isConst?(s, PBSpecies, :DEERLING) ||
          isConst?(s, PBSpecies, :SAWSBUCK))
        temp_enc_array[i] = pbGetFSpeciesFromForm(s, pbGetSeason)
      end
    end

    sortable = []
    temp_enc_array.each do |s|
      fSpecies = pbGetSpeciesFromFSpecies(s)
      sortable.push(fSpecies[0] + fSpecies[1] * 0.001)
    end

    sorted = []
    sortable.sort.each do |sort_value|
      original_index = sortable.index(sort_value)
      sorted.push(temp_enc_array[original_index])
    end
    return sorted
  end

  def build_entries(map_id)
    results = []
    return results if !map_has_encounters?(map_id)

    enc = @encdata[map_id][1]
    lookup = {}

    for type_index in 0...enc.length
      next if !enc[type_index]

      species_list = species_for_encounter_type(map_id, type_index)

      species_list.each do |f_species|
        next if !f_species

        sf = pbGetSpeciesFromFSpecies(f_species)
        species = sf[0]
        form    = sf[1]
        key     = "#{species}:#{form}"

        if !lookup[key]
          lookup[key] = {
            :fspecies => f_species,
            :species  => species,
            :form     => form,
            :methods  => []
          }
          results.push(lookup[key])
        end

        lookup[key][:methods].push(type_index) if
          !lookup[key][:methods].include?(type_index)
      end
    end

    results.sort! do |a, b|
      av = a[:species] + a[:form] * 0.001
      bv = b[:species] + b[:form] * 0.001
      av <=> bv
    end
    return results
  end

  def load_current_map
    dispose_icons

    map_id = current_map_id
    @entries = build_entries(map_id)

    state = @map_states[map_id]
    if state && @entries.length > 0
      @selected = [state[0], @entries.length - 1].min
      @page = @selected / BushidoHabitat::ITEMS_PER_PAGE
    else
      @selected = 0
      @page = 0
    end

    refresh
  end

  #-----------------------------------------------------------------------------
  #-----------------------------------------------------------------------------
  def pbStartMenu
    create_background
    create_overlay
    create_arrows
    load_current_map

    pbFadeInAndShow(@sprites) { pbUpdate }
    pbMain
  end

  def create_background
    @sprites["background"] = Sprite.new(@viewport)
    @sprites["background"].bitmap = Bitmap.new(BushidoHabitat::BACKGROUND)
  end

  def create_overlay
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
  end

  def create_arrows
  end

  def blit_habitat_asset(bmp, name, x, y)
    source = Bitmap.new(BushidoHabitat.asset(name))
    bmp.blt(x, y, source, Rect.new(0, 0, source.width, source.height))
    source.dispose
  end

  #-----------------------------------------------------------------------------
  # Drawing
  #-----------------------------------------------------------------------------
  def refresh
    dispose_icons
    bmp = @sprites["overlay"].bitmap
    bmp.clear
    pbSetSystemFont(bmp)

    draw_header(bmp)

    if @entries.length == 0
      draw_empty_state(bmp)
      draw_controls(bmp)
      return
    end

    clamp_selection
    draw_grid(bmp)
    draw_detail_panel(bmp)
    draw_controls(bmp)
  end

  def draw_header(bmp)
    map_name = current_map_name

    seen_count  = 0
    owned_count = 0
    @entries.each do |entry|
      seen_count  += 1 if BushidoHabitat.seen?(entry[:species])
      owned_count += 1 if BushidoHabitat.owned?(entry[:species])
    end

    text = []

    text.push([
      map_name,
      26, 18, 0,
      BushidoHabitat::INK,
      BushidoHabitat::SHADOW
    ])

    if @entries.length > 0
      text.push([
        _INTL("{1} habitats", @entries.length),
        26, 47, 0,
        BushidoHabitat::MUTED,
        BushidoHabitat::SHADOW
      ])

      text.push([
        _INTL("Seen {1}/{2}", seen_count, @entries.length),
        340, 47, 1,
        BushidoHabitat::INK,
        BushidoHabitat::SHADOW
      ])

      text.push([
        _INTL("Caught {1}/{2}", owned_count, @entries.length),
        Graphics.width - 26, 47, 1,
        BushidoHabitat::INK,
        BushidoHabitat::SHADOW
      ])
    end

    if @maps.length > 1
      text.push([
        "‹",
        16, 23, 2,
        @map_index > 0 ? BushidoHabitat::GOLD : BushidoHabitat::PARCHMENT_DIM,
        BushidoHabitat::SHADOW
      ])
      text.push([
        "›",
        Graphics.width - 16, 23, 2,
        @map_index < @maps.length - 1 ? BushidoHabitat::GOLD : BushidoHabitat::PARCHMENT_DIM,
        BushidoHabitat::SHADOW
      ])
    end

    pbDrawTextPositions(bmp, text)
  end

  def draw_empty_state(bmp)
    pbDrawTextPositions(bmp, [
      [
        _INTL("No wild encounters in this area."),
        Graphics.width / 2, 164, 2,
        BushidoHabitat::INK,
        BushidoHabitat::SHADOW
      ],
      [
        _INTL("Nothing appears on the Habitat Scroll here."),
        Graphics.width / 2, 197, 2,
        BushidoHabitat::MUTED,
        BushidoHabitat::SHADOW
      ]
    ])
  end

  def draw_grid(bmp)
    first = @page * BushidoHabitat::ITEMS_PER_PAGE
    last  = [first + BushidoHabitat::ITEMS_PER_PAGE, @entries.length].min

    columns = 2
    cell_w  = 222
    cell_h  = 42
    gap_x   = 14
    gap_y   = 8
    start_x = 27
    start_y = 94

    icon_segment_w = 82
    divider_x      = icon_segment_w
    text_padding   = 9

    selected_rect = nil

    for absolute_index in first...last
      local = absolute_index - first
      col = local % columns
      row = local / columns

      x = start_x + col * (cell_w + gap_x)
      y = start_y + row * (cell_h + gap_y)

      selected = (absolute_index == @selected)
      entry = @entries[absolute_index]

      blit_habitat_asset(
        bmp,
        selected ? "habitat_card_selected" : "habitat_card",
        x,
        y
      )

      divider_screen_x = x + divider_x

      if selected
        selected_rect = [x, y, cell_w, cell_h, col, row]
      end

      seen  = BushidoHabitat.seen?(entry[:species])
      owned = BushidoHabitat.owned?(entry[:species])

      icon_lane_x = x + 10
      icon_lane_w = icon_segment_w - 14
      icon_lane_y = y - 10
      icon_lane_h = cell_h + 20

      if seen
        create_species_icon(
          entry,
          absolute_index,
          icon_lane_x,
          icon_lane_y,
          icon_lane_w,
          icon_lane_h
        )
      else
        draw_unknown_type_badge(
          bmp,
          entry,
          x + 8,
          y + 8,
          icon_segment_w - 16,
          cell_h - 16
        )
      end

      if seen
        name = BushidoHabitat.species_name(entry[:species])
        name_color = owned ? BushidoHabitat::INK : BushidoHabitat::MUTED
        text_x = divider_screen_x + text_padding

        pbDrawTextPositions(bmp, [[
          name,
          text_x, y + 7, 0,
          name_color,
          BushidoHabitat::SHADOW
        ]])
      end

      if owned
        blit_habitat_asset(bmp, "pip_caught", x + cell_w - 12, y + 7)
      elsif seen
        blit_habitat_asset(bmp, "pip_seen", x + cell_w - 12, y + 7)
      end
    end

    draw_selection_arrows(bmp, selected_rect) if selected_rect

    pages = (@entries.length.to_f / BushidoHabitat::ITEMS_PER_PAGE).ceil
    draw_page_dots(bmp, pages) if pages > 1
  end

  def draw_unknown_type_badge(bmp, entry, x, y, w, h)
    type = BushidoHabitat.primary_type(entry[:species], entry[:form])

    # Use the exact same type badge sheet as the rest of Essentials/Bushido.
    # Graphics/Pictures/types.png is a vertical sheet of 64x28 badges.
    if BushidoHabitat::UNKNOWN_SHOW_PRIMARY_TYPE && !type.nil?
      begin
        type_id = type

        # primary_type normally returns the numeric Essentials v18 type ID.
        # Keep a Symbol fallback in case this helper is ever used by a fork
        # that returns symbols instead.
        if type_id.is_a?(Symbol)
          begin
            type_id = getID(PBTypes, type_id)
          rescue
            type_id = nil
          end
        end

        if !type_id.nil?
          type_sheet = pbBitmap("Graphics/Pictures/types")
          badge_w = 64
          badge_h = 28
          source = Rect.new(0, type_id * badge_h, badge_w, badge_h)

          # Center the real 64x28 badge in the unknown Pokémon icon lane.
          bx = x + ((w - badge_w) / 2)
          by = y + ((h - badge_h) / 2)

          bmp.blt(bx, by, type_sheet, source)
          return
        end
      rescue
      end
    end

    # Safe fallback only. No custom badge art is drawn here.
    pbSetSmallFont(bmp)
    pbDrawTextPositions(bmp, [[
      _INTL("???"),
      x + (w / 2),
      y + ((h - 28) / 2),
      2,
      BushidoHabitat::MUTED,
      BushidoHabitat::SHADOW
    ]])
    pbSetSystemFont(bmp)
  end

  def draw_selection_arrows(bmp, rect)
    return if !rect
    x, y, w, h, col, row = rect

    page_first = @page * BushidoHabitat::ITEMS_PER_PAGE
    local_index = @selected - page_first
    page_count = [BushidoHabitat::ITEMS_PER_PAGE,
                  @entries.length - page_first].min

    has_left  = (local_index % 2) == 1
    has_right = (local_index % 2) == 0 && local_index + 1 < page_count
    has_up    = local_index - 2 >= 0
    has_down  = local_index + 2 < page_count

    blit_habitat_asset(bmp, "arrow_left",  x - 13, y + h / 2 - 7) if has_left
    blit_habitat_asset(bmp, "arrow_right", x + w + 1, y + h / 2 - 7) if has_right
    blit_habitat_asset(bmp, "arrow_up",    x + w / 2 - 7, y - 12) if has_up
    blit_habitat_asset(bmp, "arrow_down",  x + w / 2 - 7, y + h) if has_down
  end

  def draw_page_dots(bmp, pages)
    return if pages <= 1

    rail_x = Graphics.width - 27
    rail_y = 132
    pip_w  = 5
    pip_h  = 12
    gap    = 5

    total_h = pages * pip_h + (pages - 1) * gap
    y = rail_y + (84 - total_h) / 2

    if @page > 0
      blit_habitat_asset(bmp, "arrow_up", rail_x - 7, y - 13)
    end

    for i in 0...pages
      color = (i == @page) ? BushidoHabitat::INK : BushidoHabitat::PARCHMENT_DIM
      w = (i == @page) ? 9 : pip_w
      x = rail_x - w / 2
      bmp.fill_rect(x, y, w, pip_h, color)
      y += pip_h + gap
    end

    if @page < pages - 1
      blit_habitat_asset(bmp, "arrow_down", rail_x - 7, y + 2)
    end
  end

  def create_species_icon(entry, index, lane_x, lane_y, lane_w=68, lane_h=62)
    species = entry[:species]
    form    = entry[:form]
    owned   = BushidoHabitat.owned?(species)

    sprite = PokemonSpeciesIconSprite.new(species, @viewport)
    sprite.pbSetParams(species, 0, form, false)

    rect   = sprite.src_rect
    bitmap = sprite.bitmap
    bounds = visible_pixel_bounds_in_rect(bitmap, rect)

    if bounds
      left, top, right, bottom = bounds
      visible_w = right - left + 1
      visible_h = bottom - top + 1

      target_cx = lane_x + lane_w / 2
      target_cy = lane_y + lane_h / 2

      local_center_x = left + visible_w / 2
      local_center_y = top  + visible_h / 2

      sx = target_cx - local_center_x
      sy = target_cy - local_center_y

      margin_x = 6
      margin_y = 6

      min_left   = lane_x + margin_x
      max_right  = lane_x + lane_w - margin_x - 1
      min_top    = lane_y + margin_y
      max_bottom = lane_y + lane_h - margin_y - 1

      visible_left   = sx + left
      visible_right  = sx + right
      visible_top    = sy + top
      visible_bottom = sy + bottom

      sx += min_left - visible_left if visible_left < min_left
      sx -= visible_right - max_right if visible_right > max_right
      sy += min_top - visible_top if visible_top < min_top
      sy -= visible_bottom - max_bottom if visible_bottom > max_bottom

      sprite.x = sx
      sprite.y = sy
    else
      sprite.x = lane_x + (lane_w - rect.width) / 2
      sprite.y = lane_y + (lane_h - rect.height) / 2
    end

    if !owned
      sprite.color = Color.new(70, 70, 70, 150)
    end

    @sprites["habitat_icon_#{index}"] = sprite
  end

  def visible_pixel_bounds_in_rect(bitmap, rect)
    return nil if !bitmap || bitmap.disposed?
    return nil if !rect

    min_x = rect.width
    min_y = rect.height
    max_x = -1
    max_y = -1

    for local_y in 0...rect.height
      py = rect.y + local_y
      next if py < 0 || py >= bitmap.height

      for local_x in 0...rect.width
        px = rect.x + local_x
        next if px < 0 || px >= bitmap.width

        pixel = bitmap.get_pixel(px, py)
        next if pixel.alpha <= 8

        min_x = local_x if local_x < min_x
        min_y = local_y if local_y < min_y
        max_x = local_x if local_x > max_x
        max_y = local_y if local_y > max_y
      end
    end

    return nil if max_x < 0
    return [min_x, min_y, max_x, max_y]
  end

  def draw_detail_panel(bmp)
    entry = @entries[@selected]
    return if !entry

    seen  = BushidoHabitat.seen?(entry[:species])
    owned = BushidoHabitat.owned?(entry[:species])

    if seen
      name = BushidoHabitat.species_name(entry[:species])
    else
      name = _INTL("Unknown Pokémon")
    end

    status = owned ? _INTL("CAUGHT") : (seen ? _INTL("SEEN") : _INTL("UNDISCOVERED"))
    status_color = owned ? BushidoHabitat::GOLD :
                   (seen ? BushidoHabitat::INK : BushidoHabitat::MUTED)

    methods = []
    entry[:methods].each do |method_index|
      methods.push(BushidoHabitat.encounter_name(method_index, true))
    end
    method_text = methods.join(" / ")

    if !seen && BushidoHabitat::UNKNOWN_SHOW_PRIMARY_TYPE
      type = BushidoHabitat.primary_type(entry[:species], entry[:form])
      type_name = BushidoHabitat.type_name(type)
      method_text = _INTL("{1}-type  •  {2}", type_name, method_text)
    end

    pbSetSystemFont(bmp)

    pbDrawTextPositions(bmp, [
      [
        name,
        26, 302, 0,
        BushidoHabitat::INK,
        BushidoHabitat::SHADOW
      ],
      [
        status,
        Graphics.width - 26, 302, 1,
        status_color,
        BushidoHabitat::SHADOW
      ],
      [
        method_text,
        26, 331, 0,
        BushidoHabitat::MUTED,
        BushidoHabitat::SHADOW
      ]
    ])
  end

  def draw_controls(bmp)
  end

  #-----------------------------------------------------------------------------
  #-----------------------------------------------------------------------------
  def clamp_selection
    @selected = 0 if @selected < 0
    @selected = @entries.length - 1 if @selected >= @entries.length
    @selected = 0 if @entries.length == 0

    if @entries.length > 0
      @page = @selected / BushidoHabitat::ITEMS_PER_PAGE
    else
      @page = 0
    end
  end

  def move_selection(delta)
    return if @entries.length == 0

    old = @selected
    new_index = @selected + delta

    if new_index < 0
      new_index = 0
    elsif new_index >= @entries.length
      new_index = @entries.length - 1
    end

    @selected = new_index

    if old != @selected
      @map_states[current_map_id] = [@selected, @page]
      pbPlayCursorSE
      refresh
    end
  end

  def move_horizontal(delta)
    return if @entries.length == 0

    columns = 2
    old = @selected
    row_start = (@selected / columns) * columns
    row_end = [row_start + columns - 1, @entries.length - 1].min

    @selected += delta
    @selected = row_start if @selected < row_start
    @selected = row_end if @selected > row_end

    if old != @selected
      @map_states[current_map_id] = [@selected, @page]
      pbPlayCursorSE
      refresh
    end
  end

  def change_map(delta)
    return if @maps.length <= 1

    new_index = @map_index + delta
    return if new_index < 0 || new_index >= @maps.length

    @map_states[current_map_id] = [@selected, @page]
    @map_index = new_index
    pbPlayCursorSE
    load_current_map
  end

  def pbMain
    loop do
      Graphics.update
      Input.update
      pbUpdate

      if Input.trigger?(Input::B) || Input.trigger?(Input::C)
        pbPlayCloseMenuSE
        break
      end

      if defined?(Input::L) && Input.trigger?(Input::L)
        change_map(-1)
        next
      elsif defined?(Input::R) && Input.trigger?(Input::R)
        change_map(1)
        next
      end

      next if @entries.length == 0

      if Input.trigger?(Input::UP)
        move_selection(-2)
      elsif Input.trigger?(Input::DOWN)
        move_selection(2)
      elsif Input.trigger?(Input::LEFT)
        move_horizontal(-1)
      elsif Input.trigger?(Input::RIGHT)
        move_horizontal(1)
      end
    end

    dispose
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  #-----------------------------------------------------------------------------
  # Cleanup
  #-----------------------------------------------------------------------------
  def dispose_icons
    @sprites.keys.each do |key|
      next if key.to_s.index("habitat_icon_") != 0
      sprite = @sprites[key]
      if sprite && !sprite.disposed?
        sprite.dispose
      end
      @sprites.delete(key)
    end
  end

  def dispose
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
# Public entry point
#===============================================================================
def pbEncounterListUI
  EncounterListUI.new.pbStartMenu
end
