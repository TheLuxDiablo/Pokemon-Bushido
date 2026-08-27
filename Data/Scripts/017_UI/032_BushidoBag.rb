#===============================================================================
# Pokémon Bushido - Bag UI
# Pokémon Essentials v18.1
#
# Full replacement override for PokemonBag_Scene.
#
# Includes:
# - 7x3 full-width item grid
# - Native-size item icons
# - PNG-backed rounded item cards + selection cursor
# - Brown quantity normally, white when selected
# - Quantity floats from bottom-right of card
# - Pocket arrows always visible
# - Pocket position strip with active pocket illuminated
# - Up from first page/top row selects pocket header
# - L/R on header switches pockets
# - L/R on items wraps inside row
# - Up/Down traverses pages
# - PNG-backed left-side page rail
# - Smooth cursor motion
# - Tiny hover bump
# - Confirmation shake
# - Item-content pocket transitions, header remains fixed
# - Native-size Scroll compatibility party icons (opacity states, no bars)
# - Party icons centered on a single 2-frame sprite frame
# - Scroll name = taught move name
# - Scroll party compatibility
# - Scroll one-line auto-scrolling description
# - Normal item multi-line small-font description
# - 21px description line spacing
# - Manual A-button sorting
# - Filtered Bag chooser support
# - Registered Key Item corner indicator
#
# Katana/SP UI intentionally omitted.
#===============================================================================


module BushidoBagUI

  ASSET_PATH        = "Graphics/Pictures/Bag/"
  #=============================================================================
  # Palette
  #=============================================================================

  BACKGROUND        = Color.new(247, 242, 225)

  TEXT              = Color.new(78, 31, 28)
  TEXT_SHADOW       = Color.new(205, 188, 169)

  CARD_FILL         = Color.new(239, 231, 211)
  CARD_BORDER       = Color.new(191, 174, 151)

  SELECT_FILL       = Color.new(222, 199, 179)
  SELECT_BORDER     = Color.new(132, 35, 31)

  HEADER_FILL       = Color.new(239, 231, 211)

  QUANTITY_NORMAL   = Color.new(112, 82, 64)
  QUANTITY_SELECTED = Color.new(255, 255, 255)
  QUANTITY_SHADOW   = Color.new(90, 70, 65)

  EMPTY_TEXT        = Color.new(148, 132, 116)
  DIVIDER           = Color.new(205, 188, 169)

  SCROLL_TRACK      = Color.new(214, 202, 182)
  SCROLL_THUMB      = Color.new(132, 35, 31)

  COMPATIBLE        = Color.new(88, 126, 76)
  INCOMPATIBLE      = Color.new(150, 137, 121)
  ALREADY_KNOWS     = Color.new(195, 145, 47)

  SORT_FILL         = Color.new(228, 211, 184)
  SORT_BORDER       = Color.new(176, 116, 45)

  REGISTERED_FILL   = Color.new(132, 35, 31)
  REGISTERED_TEXT   = Color.new(255, 255, 255)

  #=============================================================================
  # Grid
  #=============================================================================

  COLS              = 7
  ROWS              = 3
  PAGE_SIZE         = COLS * ROWS

  GRID_X            = 22
  GRID_Y            = 58

  CELL_W            = 60
  CELL_H            = 58

  GAP_X             = 8
  GAP_Y             = 8

  GRID_TOTAL_W =
    (COLS * CELL_W) +
    ((COLS - 1) * GAP_X)

  GRID_CENTER_X =
    GRID_X +
    GRID_TOTAL_W / 2

  BORDER_SIZE       = 2
  CARD_RADIUS       = 8

  #=============================================================================
  # Header
  #=============================================================================

  TITLE_Y           = 12

  HEADER_W          = 220
  HEADER_H          = 42

  HEADER_X =
    GRID_CENTER_X -
    HEADER_W / 2

  HEADER_Y          = 8

  #=============================================================================
  # Pocket position indicators
  #=============================================================================

  POCKET_DOT_Y       = 46
  POCKET_DOT_W       = 10
  POCKET_DOT_H       = 10
  POCKET_DOT_GAP     = 8

  #=============================================================================
  # Quantity
  #=============================================================================

  QUANTITY_X_OFFSET = 4
  QUANTITY_Y_OFFSET = -16

  #=============================================================================
  # Registered marker
  #=============================================================================

  REGISTER_W        = 16
  REGISTER_H        = 18
  REGISTER_OFFSET_X = 4
  REGISTER_OFFSET_Y = 4

  #=============================================================================
  # Page rail
  #=============================================================================

  SCROLLBAR_X       = 8
  SCROLLBAR_Y       = GRID_Y + 4
  SCROLLBAR_W       = 4

  SCROLLBAR_H =
    (ROWS * CELL_H) +
    ((ROWS - 1) * GAP_Y) -
    6

  # All custom-drawn UI geometry is kept on a 2px grid.

  SCROLL_THUMB_MIN_H = 18

  #=============================================================================
  # Normal item information
  #=============================================================================

  INFO_X            = 22
  INFO_W            = 468

  ITEM_NAME_Y       = 270

  DIVIDER_Y         = 299

  DESCRIPTION_X     = 22
  DESCRIPTION_Y     = 309
  DESCRIPTION_W     = 468

  DESCRIPTION_LINE_HEIGHT = 21
  DESCRIPTION_MAX_LINES   = 4

  #=============================================================================
  # Scroll/TM information
  #=============================================================================

  SCROLL_NAME_Y     = 254

  # PARTY_ICON_Y is the visual center of a single icon frame.
  PARTY_ICON_Y      = 294

  PARTY_START_X     = 52
  PARTY_SPACING     = 82

  PARTY_MARK_Y      = 326
  PARTY_MARK_W      = 28
  PARTY_MARK_H      = 3

  SCROLL_DIVIDER_Y  = 340

  MARQUEE_X         = 22
  MARQUEE_Y         = 348
  MARQUEE_W         = 468
  MARQUEE_H         = 26

  MARQUEE_START_HOLD = 42
  MARQUEE_END_HOLD   = 30
  MARQUEE_SPEED       = 1
  MARQUEE_INTERVAL    = 2
  MARQUEE_PADDING     = 8

  #=============================================================================
  # Motion
  #=============================================================================

  CURSOR_MOVE_FRAMES = 4
  CURSOR_BORDER_SIZE = 4

  HOVER_BUMP_PIXELS  = 2

  POCKET_TRANSITION_FRAMES = 6
  POCKET_SLIDE_DISTANCE    = 30

  PAGE_TRANSITION_FRAMES   = 4
  PAGE_SLIDE_DISTANCE      = 12

  CONFIRM_SHAKE =
    [-3, 3, -2, 2, -1, 1, 0]
end


#===============================================================================
# Bag scene
#===============================================================================

class PokemonBag_Scene
  #=============================================================================
  # Update
  #=============================================================================

  def pbUpdate
    pbUpdateSpriteHash(@sprites) if @sprites

    # PokemonIconSprite handles its own frame animation in update. Reassert the
    # correct one-frame origin after that update so the 2-frame sheet stays
    # centered instead of being treated as a single wide image.
    if @sprites
      for i in 0...6
        sprite = @sprites["partyicon#{i}"]

        next if !sprite
        next if !sprite.visible

        bushido_setup_party_icon_frame(sprite)
      end
    end

    update_scroll_marquee
  end

  #=============================================================================
  # Filters
  #=============================================================================

  def pbRefreshFilter
    @filterlist = nil

    return if !@choosing
    return if !@filterproc

    @filterlist = []

    for pocket in 1...@bag.pockets.length
      @filterlist[pocket] = []

      for i in 0...@bag.pockets[pocket].length
        entry = @bag.pockets[pocket][i]
        next if !entry

        item = entry[0]

        begin
          if @filterproc.call(item)
            @filterlist[pocket] << i
          end
        rescue
        end
      end
    end
  end

  #=============================================================================
  # Start scene
  #=============================================================================

  def pbStartScene(
    bag,
    choosing = false,
    filterproc = nil,
    resetpocket = true
  )
    @bag        = bag
    @choosing   = choosing
    @filterproc = filterproc

    pbRefreshFilter

    @viewport = Viewport.new(
      0,
      0,
      Graphics.width,
      Graphics.height
    )

    @viewport.z = 99999

    @sprites = {}

    #-------------------------------------------------------------------------
    # Background
    #-------------------------------------------------------------------------

    @sprites["background"] =
      BitmapSprite.new(
        Graphics.width,
        Graphics.height,
        @viewport
      )

    bag_blt_asset(
      @sprites["background"].bitmap,
      0,
      0,
      "background"
    )

    #-------------------------------------------------------------------------
    # Header
    #-------------------------------------------------------------------------

    @sprites["header"] =
      BitmapSprite.new(
        Graphics.width,
        Graphics.height,
        @viewport
      )

    @sprites["header"].z = 5

    pbSetSystemFont(
      @sprites["header"].bitmap
    )

    #-------------------------------------------------------------------------
    # Item/content layer
    #-------------------------------------------------------------------------

    @sprites["content"] =
      BitmapSprite.new(
        Graphics.width,
        Graphics.height,
        @viewport
      )

    @sprites["content"].z = 5

    pbSetSystemFont(
      @sprites["content"].bitmap
    )

    #-------------------------------------------------------------------------
    # Page rail
    #-------------------------------------------------------------------------

    @sprites["scrollbar"] =
      BitmapSprite.new(
        Graphics.width,
        Graphics.height,
        @viewport
      )

    @sprites["scrollbar"].z = 6

    #-------------------------------------------------------------------------
    # Animated cursor
    #-------------------------------------------------------------------------

    @sprites["cursor"] =
      BitmapSprite.new(
        Graphics.width,
        Graphics.height,
        @viewport
      )

    @sprites["cursor"].z = 8

    @cursor_rect = nil

    #-------------------------------------------------------------------------
    # Item icons
    #-------------------------------------------------------------------------

    @item_icon_base_x = []
    @item_icon_base_y = []

    for i in 0...BushidoBagUI::PAGE_SIZE
      sprite =
        ItemIconSprite.new(
          0,
          0,
          nil,
          @viewport
        )

      sprite.visible = false
      sprite.z       = 10
      sprite.zoom_x  = 1.0
      sprite.zoom_y  = 1.0

      @sprites["itemicon#{i}"] = sprite
    end

    #-------------------------------------------------------------------------
    # Quantity / register marker layer
    #-------------------------------------------------------------------------

    @sprites["itemoverlay"] =
      BitmapSprite.new(
        Graphics.width,
        Graphics.height,
        @viewport
      )

    @sprites["itemoverlay"].z = 20

    #-------------------------------------------------------------------------
    # Party compatibility underline layer
    #-------------------------------------------------------------------------

    @sprites["party_marks"] =
      BitmapSprite.new(
        Graphics.width,
        Graphics.height,
        @viewport
      )

    @sprites["party_marks"].z = 22

    #-------------------------------------------------------------------------
    # Party icons
    #-------------------------------------------------------------------------

    for i in 0...6
      pokemon = nil

      if $Trainer &&
         $Trainer.party &&
         i < $Trainer.party.length

        pokemon = $Trainer.party[i]
      end

      sprite =
        PokemonIconSprite.new(
          pokemon,
          @viewport
        )

      sprite.visible = false
      sprite.z       = 21
      sprite.zoom_x  = 1.0
      sprite.zoom_y  = 1.0

      bushido_setup_party_icon_frame(sprite)

      @sprites["partyicon#{i}"] =
        sprite
    end

    #-------------------------------------------------------------------------
    # One-line Scroll description
    #-------------------------------------------------------------------------

    @sprites["marquee"] =
      Sprite.new(
        @viewport
      )

    @sprites["marquee"].x =
      BushidoBagUI::MARQUEE_X

    @sprites["marquee"].y =
      BushidoBagUI::MARQUEE_Y

    @sprites["marquee"].z = 24
    @sprites["marquee"].visible = false

    reset_marquee

    #-------------------------------------------------------------------------
    # Stock compatibility windows
    #-------------------------------------------------------------------------

    @sprites["helpwindow"] =
      Window_UnformattedTextPokemon.new("")

    @sprites["helpwindow"].visible =
      false

    @sprites["helpwindow"].viewport =
      @viewport

    @sprites["msgwindow"] =
      Window_AdvancedTextPokemon.new("")

    @sprites["msgwindow"].visible =
      false

    @sprites["msgwindow"].viewport =
      @viewport

    pbBottomLeftLines(
      @sprites["helpwindow"],
      1
    )

    pbDeactivateWindows(
      @sprites
    )

    #-------------------------------------------------------------------------
    # Initial pocket
    #-------------------------------------------------------------------------

    @pocket =
      resolve_start_pocket(
        resetpocket
      )

    @bag.lastpocket =
      @pocket

    #-------------------------------------------------------------------------
    # Initial selection
    #-------------------------------------------------------------------------

    @index =
      @bag.getChoice(
        @pocket
      )

    @index = 0 if !@index

    clamp_index

    @header_selected = false
    @header_col      = 0

    #-------------------------------------------------------------------------
    # Sorting
    #-------------------------------------------------------------------------

    @sorting          = false
    @sort_backup      = nil
    @sort_start_index = -1

    pbRefresh

    pbFadeInAndShow(
      @sprites
    )
  end

  #=============================================================================
  # Pocket setup
  #=============================================================================

  def resolve_start_pocket(resetpocket)
    pocket =
      @bag.lastpocket

    if !pocket ||
       pocket < 1 ||
       pocket > PokemonBag.numPockets

      pocket = 1
    end

    if @choosing &&
       resetpocket

      pocket = 1
    end

    return pocket if
      pocket_available?(pocket)

    for i in 1..PokemonBag.numPockets
      return i if
        pocket_available?(i)
    end

    return 1
  end

  def pocket_available?(pocket)
    return false if pocket < 1
    return false if pocket > PokemonBag.numPockets

    return true if !@choosing

    if @filterlist
      list =
        @filterlist[pocket]

      return list &&
             list.length > 0
    end

    data =
      @bag.pockets[pocket]

    return data &&
           data.length > 0
  end

  def next_valid_pocket(direction)
    original =
      @pocket

    pocket =
      original

    loop do
      pocket += direction

      pocket =
        PokemonBag.numPockets if
        pocket < 1

      pocket =
        1 if
        pocket > PokemonBag.numPockets

      return original if
        pocket == original

      return pocket if
        pocket_available?(pocket)
    end
  end

  #=============================================================================
  # Items
  #=============================================================================

  def valid_item_id?(item)
    return false if !item
    return false if !item.is_a?(Numeric)
    return false if item <= 0

    begin
      PBItems.getName(item)
      return true
    rescue
      return false
    end
  end

  def machine_item?(item)
    return false if
      !valid_item_id?(item)

    return pbIsMachine?(item)
  end

  def machine_move(item)
    return 0 if
      !machine_item?(item)

    move =
      pbGetMachine(item)

    return move || 0
  end

  def display_item_name(item)
    return "" if
      !valid_item_id?(item)

    move =
      machine_move(item)

    if move > 0
      return PBMoves.getName(move)
    end

    return PBItems.getName(item)
  end

  def display_item_description(item)
    return "" if
      !valid_item_id?(item)

    move =
      machine_move(item)

    if move > 0
      return pbGetMessage(
        MessageTypes::MoveDescriptions,
        move
      )
    end

    return pbGetMessage(
      MessageTypes::ItemDescriptions,
      item
    )
  end

  #=============================================================================
  # Registered items
  #=============================================================================

  def registered_item?(item)
    return false if
      !valid_item_id?(item)

    begin
      return @bag.pbIsRegistered?(item)
    rescue
      return false
    end
  end

  #=============================================================================
  # Display indices
  #=============================================================================

  def display_indices(pocket = @pocket)
    if @filterlist
      return @filterlist[pocket] || []
    end

    ret = []

    data =
      @bag.pockets[pocket]

    return ret if !data

    for i in 0...data.length
      entry =
        data[i]

      next if !entry
      next if !valid_item_id?(entry[0])

      ret << i
    end

    return ret
  end

  def item_count
    return display_indices.length
  end

  def real_index(display_index = @index)
    list =
      display_indices

    return nil if
      display_index < 0

    return nil if
      display_index >= list.length

    return list[display_index]
  end

  def item_entry(display_index)
    ri =
      real_index(display_index)

    return nil if ri.nil?

    return @bag.pockets[@pocket][ri]
  end

  def item_at(display_index)
    entry =
      item_entry(display_index)

    return 0 if !entry

    item =
      entry[0]

    return 0 if
      !valid_item_id?(item)

    return item
  end

  def quantity_at(display_index)
    entry =
      item_entry(display_index)

    return 0 if !entry
    return 0 if entry.length < 2

    return entry[1] || 0
  end

  def current_item
    return item_at(@index)
  end

  #=============================================================================
  # Pages
  #=============================================================================

  def clamp_index
    count =
      item_count

    if count <= 0
      @index = 0
      return
    end

    @index = 0 if
      @index < 0

    if @index >= count
      @index =
        count - 1
    end
  end

  def current_page
    return @index /
           BushidoBagUI::PAGE_SIZE
  end

  def page_start
    return current_page *
           BushidoBagUI::PAGE_SIZE
  end

  def max_page
    count =
      item_count

    return 0 if count <= 0

    return (count - 1) /
           BushidoBagUI::PAGE_SIZE
  end

  def local_index
    return @index -
           page_start
  end

  def local_row
    return local_index /
           BushidoBagUI::COLS
  end

  def local_col
    return local_index %
           BushidoBagUI::COLS
  end

  #=============================================================================
  # Geometry
  #=============================================================================

  def grid_rect(slot)
    col =
      slot %
      BushidoBagUI::COLS

    row =
      slot /
      BushidoBagUI::COLS

    x =
      BushidoBagUI::GRID_X +
      col * (
        BushidoBagUI::CELL_W +
        BushidoBagUI::GAP_X
      )

    y =
      BushidoBagUI::GRID_Y +
      row * (
        BushidoBagUI::CELL_H +
        BushidoBagUI::GAP_Y
      )

    return Rect.new(
      x,
      y,
      BushidoBagUI::CELL_W,
      BushidoBagUI::CELL_H
    )
  end

  def header_rect
    return Rect.new(
      BushidoBagUI::HEADER_X,
      BushidoBagUI::HEADER_Y,
      BushidoBagUI::HEADER_W,
      BushidoBagUI::HEADER_H
    )
  end

  def current_selection_rect
    return header_rect if
      @header_selected

    return header_rect if
      item_count <= 0

    return grid_rect(
      local_index
    )
  end

  #=============================================================================
  # PNG assets
  #=============================================================================

  def bag_asset(name)
    return Bitmap.new(
      BushidoBagUI::ASSET_PATH + name
    )
  end

  def bag_blt_asset(bitmap, x, y, name)
    asset = bag_asset(name)
    bitmap.blt(x, y, asset, asset.rect)
    asset.dispose
  end

  #=============================================================================
  # Party icon frame setup
  #=============================================================================

  def bushido_setup_party_icon_frame(sprite)
    return if !sprite
    return if sprite.disposed?
    return if !sprite.bitmap
    return if sprite.bitmap.disposed?

    sheet_w =
      sprite.bitmap.width

    sheet_h =
      sprite.bitmap.height

    return if
      sheet_w <= 0 ||
      sheet_h <= 0

    # Bushido's party icon graphic contains 2 horizontal animation frames.
    frame_w =
      sheet_w / 2

    frame_w =
      sheet_w if frame_w <= 0

    frame_h =
      sheet_h

    # PokemonIconSprite updates src_rect.x to animate. Preserve whichever frame
    # it is currently on, but force the src_rect to a SINGLE frame.
    frame_x =
      sprite.src_rect.x

    if sheet_w >= frame_w * 2
      frame_x =
        frame_x >= frame_w ?
        frame_w :
        0
    else
      frame_x = 0
    end

    sprite.src_rect.set(
      frame_x,
      0,
      frame_w,
      frame_h
    )

    # x/y now represent the visual center of a single animation frame.
    sprite.ox =
      frame_w / 2

    sprite.oy =
      frame_h / 2

    sprite.zoom_x =
      1.0

    sprite.zoom_y =
      1.0
  end

  #=============================================================================
  # Refresh
  #=============================================================================

  def pbRefresh
    clamp_index

    @bag.lastpocket =
      @pocket

    @bag.setChoice(
      @pocket,
      @index
    )

    reset_marquee

    draw_header
    draw_content
    draw_scrollbar

    refresh_item_icons
    refresh_item_overlay
    refresh_scroll_party

    snap_cursor
  end

  def pbRefreshIndexChanged
    clamp_index

    @bag.setChoice(
      @pocket,
      @index
    )

    reset_marquee

    draw_header
    draw_content
    draw_scrollbar

    refresh_item_icons
    refresh_item_overlay
    refresh_scroll_party

    animate_cursor_to(
      current_selection_rect
    )
  end

  #=============================================================================
  # Header
  #=============================================================================

  def draw_header
    bitmap =
      @sprites["header"].bitmap

    bitmap.clear

    pbSetSystemFont(bitmap)

    rect =
      header_rect

    if @header_selected
      bag_blt_asset(
        bitmap,
        rect.x,
        rect.y,
        "header_selected"
      )
    end

    arrow_color =
      @header_selected ?
      BushidoBagUI::SELECT_BORDER :
      BushidoBagUI::TEXT

    pbDrawTextPositions(
      bitmap,
      [
        [
          "<",
          rect.x + 18,
          BushidoBagUI::TITLE_Y,
          2,
          arrow_color,
          BushidoBagUI::TEXT_SHADOW
        ],
        [
          PokemonBag.pocketNames[@pocket],
          BushidoBagUI::GRID_CENTER_X,
          BushidoBagUI::TITLE_Y,
          2,
          BushidoBagUI::TEXT,
          BushidoBagUI::TEXT_SHADOW
        ],
        [
          ">",
          rect.x + rect.width - 18,
          BushidoBagUI::TITLE_Y,
          2,
          arrow_color,
          BushidoBagUI::TEXT_SHADOW
        ]
      ]
    )

    #-------------------------------------------------------------------------
    # Pocket position strip.
    #-------------------------------------------------------------------------
    pockets =
      PokemonBag.numPockets

    dot_w =
      BushidoBagUI::POCKET_DOT_W

    gap =
      BushidoBagUI::POCKET_DOT_GAP

    total_w =
      pockets * dot_w +
      (pockets - 1) * gap

    dot_x =
      Graphics.width / 2 -
      total_w / 2

    for i in 1..pockets
      asset =
        i == @pocket ?
        "pocket_on" :
        "pocket_off"

      bag_blt_asset(
        bitmap,
        dot_x,
        BushidoBagUI::POCKET_DOT_Y,
        asset
      )

      dot_x +=
        dot_w +
        gap
    end
  end

  #=============================================================================
  # Page scrollbar
  #=============================================================================

  def draw_scrollbar
    bitmap =
      @sprites["scrollbar"].bitmap

    bitmap.clear

    pages =
      max_page + 1

    return if
      pages <= 1

    x = BushidoBagUI::SCROLLBAR_X
    y = BushidoBagUI::SCROLLBAR_Y
    h = BushidoBagUI::SCROLLBAR_H

    bag_blt_asset(
      bitmap,
      x,
      y,
      "page_track"
    )

    thumb_h =
      h / pages

    thumb_h =
      (thumb_h / 2) * 2

    if thumb_h <
       BushidoBagUI::SCROLL_THUMB_MIN_H

      thumb_h =
        BushidoBagUI::SCROLL_THUMB_MIN_H
    end

    travel =
      h -
      thumb_h

    thumb_y =
      y +
      (
        travel *
        current_page /
        (pages - 1)
      )

    thumb_y =
      (thumb_y / 2) * 2

    tile =
      bag_asset(
        "page_thumb_tile"
      )

    yy = 0

    while yy < thumb_h
      bitmap.blt(
        x,
        thumb_y + yy,
        tile,
        tile.rect
      )

      yy += 2
    end

    tile.dispose
  end

  #=============================================================================
  # Content
  #=============================================================================

  def draw_content
    bitmap =
      @sprites["content"].bitmap

    bitmap.clear

    pbSetSystemFont(bitmap)

    draw_item_grid(bitmap)
    draw_item_info(bitmap)
  end

  #=============================================================================
  # Grid
  #=============================================================================

  def draw_item_grid(bitmap)
    count =
      item_count

    if count <= 0
      pbDrawTextPositions(
        bitmap,
        [
          [
            _INTL("No items."),
            Graphics.width / 2,
            150,
            2,
            BushidoBagUI::EMPTY_TEXT,
            BushidoBagUI::TEXT_SHADOW
          ]
        ]
      )

      return
    end

    first =
      page_start

    last = [
      first +
      BushidoBagUI::PAGE_SIZE,
      count
    ].min

    for display_index in first...last
      slot =
        display_index -
        first

      rect =
        grid_rect(slot)

      selected =
        display_index == @index &&
        !@header_selected

      draw_item_card(
        bitmap,
        rect,
        selected
      )
    end
  end

  def draw_item_card(bitmap, rect, selected)
    asset =
      if selected && @sorting
        "item_card_sort"
      elsif selected
        "item_card_selected"
      else
        "item_card"
      end

    bag_blt_asset(
      bitmap,
      rect.x,
      rect.y,
      asset
    )
  end

  #=============================================================================
  # Item icons
  #=============================================================================

  def refresh_item_icons
    first =
      page_start

    count =
      item_count

    for slot in 0...BushidoBagUI::PAGE_SIZE
      sprite =
        @sprites["itemicon#{slot}"]

      display_index =
        first +
        slot

      if display_index >= count
        sprite.visible =
          false

        next
      end

      item =
        item_at(display_index)

      if !valid_item_id?(item)
        sprite.visible =
          false

        next
      end

      rect =
        grid_rect(slot)

      sprite.item =
        item

      sprite.zoom_x =
        1.0

      sprite.zoom_y =
        1.0

      base_x =
        rect.x +
        rect.width / 2

      base_y =
        rect.y +
        rect.height / 2

      @item_icon_base_x[slot] =
        base_x

      @item_icon_base_y[slot] =
        base_y

      sprite.x =
        base_x

      sprite.y =
        base_y

      sprite.opacity =
        255

      sprite.visible =
        true
    end
  end

  #=============================================================================
  # Quantity + registered marker
  #=============================================================================

  def refresh_item_overlay
    bitmap =
      @sprites["itemoverlay"].bitmap

    bitmap.clear

    pbSetSmallFont(bitmap)

    first =
      page_start

    count =
      item_count

    last = [
      first +
      BushidoBagUI::PAGE_SIZE,
      count
    ].min

    for display_index in first...last
      slot =
        display_index -
        first

      rect =
        grid_rect(slot)

      item =
        item_at(display_index)

      quantity =
        quantity_at(display_index)

      quantity = 999 if
        quantity > 999

      selected =
        display_index == @index &&
        !@header_selected

      color =
        selected ?
        BushidoBagUI::QUANTITY_SELECTED :
        BushidoBagUI::QUANTITY_NORMAL

      #-----------------------------------------------------------------------
      # Floating quantity
      #-----------------------------------------------------------------------

      text_x =
        rect.x +
        rect.width +
        BushidoBagUI::QUANTITY_X_OFFSET

      text_y =
        rect.y +
        rect.height +
        BushidoBagUI::QUANTITY_Y_OFFSET

      pbDrawTextPositions(
        bitmap,
        [
          [
            quantity.to_s,
            text_x,
            text_y,
            1,
            color,
            BushidoBagUI::QUANTITY_SHADOW
          ]
        ]
      )

      #-----------------------------------------------------------------------
      # Registered Key Item marker
      #-----------------------------------------------------------------------

      if registered_item?(item)
        draw_registered_marker(
          bitmap,
          rect
        )
      end
    end

    pbSetSystemFont(bitmap)
  end

  def draw_registered_marker(bitmap, rect)
    x =
      rect.x +
      BushidoBagUI::REGISTER_OFFSET_X

    y =
      rect.y +
      BushidoBagUI::REGISTER_OFFSET_Y

    bag_blt_asset(
      bitmap,
      x,
      y,
      "registered_marker"
    )

    pbSetSmallFont(bitmap)

    pbDrawTextPositions(
      bitmap,
      [
        [
          "R",
          x + BushidoBagUI::REGISTER_W / 2,
          y - 4,
          2,
          BushidoBagUI::REGISTERED_TEXT,
          BushidoBagUI::REGISTERED_FILL
        ]
      ]
    )
  end

  #=============================================================================
  # Item information
  #=============================================================================

  def draw_item_info(bitmap)
    return if
      @header_selected

    item =
      current_item

    return if
      !valid_item_id?(item)

    if machine_item?(item)
      draw_scroll_info(
        bitmap,
        item
      )
    else
      draw_normal_item_info(
        bitmap,
        item
      )
    end
  end

  #-----------------------------------------------------------------------------
  # Normal item
  #-----------------------------------------------------------------------------

  def draw_normal_item_info(bitmap, item)
    pbSetSystemFont(bitmap)

    pbDrawTextPositions(
      bitmap,
      [
        [
          display_item_name(item),
          Graphics.width / 2,
          BushidoBagUI::ITEM_NAME_Y,
          2,
          BushidoBagUI::TEXT,
          BushidoBagUI::TEXT_SHADOW
        ]
      ]
    )

    bag_blt_asset(
      bitmap,
      BushidoBagUI::INFO_X,
      BushidoBagUI::DIVIDER_Y,
      "divider"
    )

    pbSetSmallFont(bitmap)

    draw_tight_description(
      bitmap,
      BushidoBagUI::DESCRIPTION_X,
      BushidoBagUI::DESCRIPTION_Y,
      BushidoBagUI::DESCRIPTION_W,
      display_item_description(item)
    )

    pbSetSystemFont(bitmap)
  end

  #-----------------------------------------------------------------------------
  # Scroll
  #-----------------------------------------------------------------------------

  def draw_scroll_info(bitmap, item)
    move =
      machine_move(item)

    return if
      move <= 0

    pbSetSystemFont(bitmap)

    pbDrawTextPositions(
      bitmap,
      [
        [
          PBMoves.getName(move),
          Graphics.width / 2,
          BushidoBagUI::SCROLL_NAME_Y,
          2,
          BushidoBagUI::TEXT,
          BushidoBagUI::TEXT_SHADOW
        ]
      ]
    )

    bag_blt_asset(
      bitmap,
      BushidoBagUI::INFO_X,
      BushidoBagUI::SCROLL_DIVIDER_Y,
      "divider"
    )
  end

  #=============================================================================
  # Description wrapping
  #=============================================================================

  def draw_tight_description(
    bitmap,
    x,
    y,
    width,
    text
  )
    words =
      text.to_s.split(/\s+/)

    lines = []
    line  = ""

    words.each do |word|
      test =
        line == "" ?
        word :
        line + " " + word

      if bitmap.text_size(test).width > width &&
         line != ""

        lines << line
        line = word
      else
        line = test
      end
    end

    lines << line if
      line != ""

    lines =
      lines[
        0,
        BushidoBagUI::DESCRIPTION_MAX_LINES
      ]

    lines.each_with_index do |ln, i|
      pbDrawTextPositions(
        bitmap,
        [
          [
            ln,
            x,
            y +
            i *
            BushidoBagUI::DESCRIPTION_LINE_HEIGHT,
            0,
            BushidoBagUI::TEXT,
            BushidoBagUI::TEXT_SHADOW
          ]
        ]
      )
    end
  end

  #=============================================================================
  # Scroll party preview
  #=============================================================================

  def hide_party_icons
    for i in 0...6
      sprite =
        @sprites["partyicon#{i}"]

      sprite.visible =
        false if sprite
    end

    @sprites["party_marks"].bitmap.clear
  end

  def refresh_scroll_party
    hide_party_icons

    if @header_selected
      hide_marquee
      return
    end

    item =
      current_item

    if !machine_item?(item)
      hide_marquee
      return
    end

    move =
      machine_move(item)

    if move <= 0
      hide_marquee
      return
    end

    party =
      ($Trainer && $Trainer.party) ?
      $Trainer.party :
      []

    for i in 0...6
      sprite =
        @sprites["partyicon#{i}"]

      if i >= party.length ||
         !party[i]

        sprite.visible =
          false

        next
      end

      pokemon =
        party[i]

      begin
        sprite.pokemon =
          pokemon
      rescue
      end

      # pokemon= may replace the bitmap, so frame/origin setup comes after.
      bushido_setup_party_icon_frame(
        sprite
      )

      x =
        BushidoBagUI::PARTY_START_X +
        i *
        BushidoBagUI::PARTY_SPACING

      # x/y are the CENTER of one animation frame.
      sprite.x =
        x

      sprite.y =
        BushidoBagUI::PARTY_ICON_Y

      state =
        pokemon_move_state(
          pokemon,
          move
        )

      case state
      when :knows
        sprite.opacity =
          255

        # Already knows the move: full opacity.

      when :able
        sprite.opacity =
          255

        # Can learn the move: full opacity.

      else
        sprite.opacity =
          85

        # Can't learn the move: dimmed.
      end

      sprite.visible =
        true
    end

    build_scroll_marquee(
      display_item_description(item)
    )
  end

  #=============================================================================
  # Essentials v18 move compatibility
  #=============================================================================

  def pokemon_move_state(pokemon, move)
    return :unable if
      !pokemon

    return :unable if
      pokemon.egg?

    begin
      return :unable if
        pokemon.shadowPokemon?
    rescue
    end

    return :knows if
      pokemon_knows_move?(
        pokemon,
        move
      )

    begin
      return :able if
        pokemon.compatibleWithMove?(move)
    rescue
    end

    return :unable
  end

  def pokemon_knows_move?(pokemon, move)
    return false if
      !pokemon

    begin
      return true if
        pokemon.knowsMove?(move)
    rescue
    end

    begin
      pokemon.moves.each do |pkmn_move|
        next if !pkmn_move

        return true if
          pkmn_move.id == move
      end
    rescue
    end

    return false
  end

  #=============================================================================
  # Marquee
  #=============================================================================

  def reset_marquee
    @marquee_offset =
      0

    @marquee_direction =
      1

    @marquee_hold =
      BushidoBagUI::MARQUEE_START_HOLD

    @marquee_tick =
      0

    @marquee_max_offset =
      0

    @marquee_active =
      false

    hide_marquee
  end

  def hide_marquee
    sprite =
      @sprites["marquee"]

    return if
      !sprite

    sprite.visible =
      false

    @marquee_active =
      false
  end

  def build_scroll_marquee(text)
    sprite =
      @sprites["marquee"]

    return if !sprite

    if sprite.bitmap &&
       !sprite.bitmap.disposed?

      sprite.bitmap.dispose
    end

    measure =
      Bitmap.new(
        16,
        BushidoBagUI::MARQUEE_H
      )

    pbSetSmallFont(
      measure
    )

    text_width =
      measure.text_size(
        text.to_s
      ).width

    measure.dispose

    bitmap_width = [
      BushidoBagUI::MARQUEE_W,
      text_width +
      BushidoBagUI::MARQUEE_PADDING * 2
    ].max

    bitmap =
      Bitmap.new(
        bitmap_width,
        BushidoBagUI::MARQUEE_H
      )

    pbSetSmallFont(
      bitmap
    )

    if text_width <=
       BushidoBagUI::MARQUEE_W

      pbDrawTextPositions(
        bitmap,
        [
          [
            text.to_s,
            BushidoBagUI::MARQUEE_W / 2,
            -2,
            2,
            BushidoBagUI::TEXT,
            BushidoBagUI::TEXT_SHADOW
          ]
        ]
      )
    else
      pbDrawTextPositions(
        bitmap,
        [
          [
            text.to_s,
            BushidoBagUI::MARQUEE_PADDING,
            -2,
            0,
            BushidoBagUI::TEXT,
            BushidoBagUI::TEXT_SHADOW
          ]
        ]
      )
    end

    sprite.bitmap =
      bitmap

    sprite.x =
      BushidoBagUI::MARQUEE_X

    sprite.y =
      BushidoBagUI::MARQUEE_Y

    sprite.src_rect =
      Rect.new(
        0,
        0,
        BushidoBagUI::MARQUEE_W,
        BushidoBagUI::MARQUEE_H
      )

    @marquee_offset =
      0

    @marquee_direction =
      1

    @marquee_tick =
      0

    @marquee_max_offset = [
      bitmap_width -
      BushidoBagUI::MARQUEE_W,
      0
    ].max

    @marquee_hold =
      BushidoBagUI::MARQUEE_START_HOLD

    @marquee_active =
      @marquee_max_offset > 0

    sprite.visible =
      true
  end

  def update_scroll_marquee
    return if
      !@marquee_active

    return if
      @header_selected

    sprite =
      @sprites["marquee"]

    return if !sprite
    return if !sprite.visible
    return if !sprite.bitmap
    return if sprite.bitmap.disposed?

    if @marquee_hold > 0
      @marquee_hold -= 1
      return
    end

    @marquee_tick += 1

    return if
      @marquee_tick <
      BushidoBagUI::MARQUEE_INTERVAL

    @marquee_tick = 0

    @marquee_offset +=
      BushidoBagUI::MARQUEE_SPEED *
      @marquee_direction

    if @marquee_offset >=
       @marquee_max_offset

      @marquee_offset =
        @marquee_max_offset

      @marquee_direction =
        -1

      @marquee_hold =
        BushidoBagUI::MARQUEE_END_HOLD

    elsif @marquee_offset <= 0

      @marquee_offset =
        0

      @marquee_direction =
        1

      @marquee_hold =
        BushidoBagUI::MARQUEE_START_HOLD
    end

    sprite.src_rect.x =
      @marquee_offset
  end

  #=============================================================================
  # Rounded cursor
  #=============================================================================

  def ease_position(t)
    return t *
           t *
           (3.0 - 2.0 * t)
  end

  def bushido_point_in_round_rect?(x, y, w, h, radius)
    return false if
      x < 0 ||
      y < 0 ||
      x >= w ||
      y >= h

    return true if
      x >= radius &&
      x < w - radius

    return true if
      y >= radius &&
      y < h - radius

    cx =
      x < radius ?
      radius :
      w - radius - 2

    cy =
      y < radius ?
      radius :
      h - radius - 2

    dx =
      x - cx

    dy =
      y - cy

    return dx * dx +
           dy * dy <=
           radius * radius
  end

  def draw_cursor_rect(rect)
    bitmap =
      @sprites["cursor"].bitmap

    bitmap.clear

    return if !rect

    is_header =
      rect.width ==
      BushidoBagUI::HEADER_W

    asset =
      if is_header
        @sorting ?
        "header_cursor_sort" :
        "header_cursor"
      else
        @sorting ?
        "item_cursor_sort" :
        "item_cursor"
      end

    bag_blt_asset(
      bitmap,
      (rect.x / 2) * 2,
      (rect.y / 2) * 2,
      asset
    )
  end

  def snap_cursor
    @cursor_rect =
      current_selection_rect

    draw_cursor_rect(
      @cursor_rect
    )
  end

  def animate_cursor_to(target)
    if !@cursor_rect
      @cursor_rect =
        target

      draw_cursor_rect(
        target
      )

      return
    end

    start =
      @cursor_rect

    frames =
      BushidoBagUI::CURSOR_MOVE_FRAMES

    for frame in 1..frames
      t =
        ease_position(
          frame.to_f /
          frames
        )

      rect =
        Rect.new(
          (
            start.x +
            (target.x - start.x) *
            t
          ).round,
          (
            start.y +
            (target.y - start.y) *
            t
          ).round,
          (
            start.width +
            (target.width - start.width) *
            t
          ).round,
          (
            start.height +
            (target.height - start.height) *
            t
          ).round
        )

      draw_cursor_rect(
        rect
      )

      Graphics.update
      pbUpdate
    end

    @cursor_rect =
      target

    draw_cursor_rect(
      target
    )

    if !@header_selected &&
       !@sorting

      play_hover_bump
    end
  end

  #=============================================================================
  # Hover juice
  #=============================================================================

  def selected_visible_slot
    return nil if
      @header_selected

    slot =
      @index -
      page_start

    return nil if
      slot < 0

    return nil if
      slot >= BushidoBagUI::PAGE_SIZE

    return slot
  end

  def play_hover_bump
    slot =
      selected_visible_slot

    return if
      slot.nil?

    sprite =
      @sprites["itemicon#{slot}"]

    return if
      !sprite ||
      !sprite.visible

    base_y =
      @item_icon_base_y[slot]

    return if
      base_y.nil?

    sprite.y =
      base_y -
      BushidoBagUI::HOVER_BUMP_PIXELS

    Graphics.update
    pbUpdate

    sprite.y =
      base_y
  end

  #=============================================================================
  # Confirm juice
  #=============================================================================

  def play_confirm_juice
    slot =
      selected_visible_slot

    return if
      slot.nil?

    sprite =
      @sprites["itemicon#{slot}"]

    return if
      !sprite ||
      !sprite.visible

    base_x =
      @item_icon_base_x[slot]

    return if
      base_x.nil?

    BushidoBagUI::CONFIRM_SHAKE.each do |offset|
      sprite.x =
        base_x +
        offset

      @sprites["cursor"].x =
        offset

      Graphics.update
      pbUpdate
    end

    sprite.x =
      base_x

    @sprites["cursor"].x =
      0
  end

  #=============================================================================
  # Content transition positioning
  #=============================================================================

  def set_content_offset(
    x,
    y,
    opacity
  )
    @sprites["content"].x =
      x

    @sprites["content"].y =
      y

    @sprites["content"].opacity =
      opacity

    @sprites["itemoverlay"].x =
      x

    @sprites["itemoverlay"].y =
      y

    @sprites["itemoverlay"].opacity =
      opacity

    @sprites["party_marks"].x =
      x

    @sprites["party_marks"].y =
      y

    @sprites["party_marks"].opacity =
      opacity

    marquee =
      @sprites["marquee"]

    if marquee
      marquee.x =
        BushidoBagUI::MARQUEE_X +
        x

      marquee.y =
        BushidoBagUI::MARQUEE_Y +
        y

      marquee.opacity =
        opacity
    end

    for slot in 0...BushidoBagUI::PAGE_SIZE
      sprite =
        @sprites["itemicon#{slot}"]

      next if !sprite

      bx =
        @item_icon_base_x[slot]

      by =
        @item_icon_base_y[slot]

      sprite.x =
        bx + x if bx

      sprite.y =
        by + y if by

      sprite.opacity =
        opacity
    end

    for i in 0...6
      sprite =
        @sprites["partyicon#{i}"]

      next if !sprite

      sprite.x =
        BushidoBagUI::PARTY_START_X +
        i *
        BushidoBagUI::PARTY_SPACING +
        x

      sprite.y =
        BushidoBagUI::PARTY_ICON_Y +
        y
    end
  end

  #=============================================================================
  # Pocket transitions
  #=============================================================================

  def animate_pocket_out(direction)
    frames =
      BushidoBagUI::POCKET_TRANSITION_FRAMES

    distance =
      BushidoBagUI::POCKET_SLIDE_DISTANCE

    for frame in 1..frames
      t =
        ease_position(
          frame.to_f /
          frames
        )

      set_content_offset(
        (
          -direction *
          distance *
          t
        ).round,
        0,
        (
          255 *
          (1.0 - t)
        ).round
      )

      Graphics.update
      pbUpdate
    end
  end

  def animate_pocket_in(direction)
    frames =
      BushidoBagUI::POCKET_TRANSITION_FRAMES

    distance =
      BushidoBagUI::POCKET_SLIDE_DISTANCE

    for frame in 1..frames
      t =
        ease_position(
          frame.to_f /
          frames
        )

      set_content_offset(
        (
          direction *
          distance *
          (1.0 - t)
        ).round,
        0,
        (255 * t).round
      )

      Graphics.update
      pbUpdate
    end

    set_content_offset(
      0,
      0,
      255
    )
  end

  #=============================================================================
  # Page transitions
  #=============================================================================

  def animate_page_out(direction)
    frames =
      BushidoBagUI::PAGE_TRANSITION_FRAMES

    distance =
      BushidoBagUI::PAGE_SLIDE_DISTANCE

    for frame in 1..frames
      t =
        ease_position(
          frame.to_f /
          frames
        )

      set_content_offset(
        0,
        (
          -direction *
          distance *
          t
        ).round,
        (
          255 *
          (1.0 - t)
        ).round
      )

      Graphics.update
      pbUpdate
    end
  end

  def animate_page_in(direction)
    frames =
      BushidoBagUI::PAGE_TRANSITION_FRAMES

    distance =
      BushidoBagUI::PAGE_SLIDE_DISTANCE

    for frame in 1..frames
      t =
        ease_position(
          frame.to_f /
          frames
        )

      set_content_offset(
        0,
        (
          direction *
          distance *
          (1.0 - t)
        ).round,
        (255 * t).round
      )

      Graphics.update
      pbUpdate
    end

    set_content_offset(
      0,
      0,
      255
    )
  end

  #=============================================================================
  # Set index
  #=============================================================================

  def set_index(new_index)
    return if
      item_count <= 0

    new_index =
      [
        [new_index, 0].max,
        item_count - 1
      ].min

    return if
      new_index == @index

    old_page =
      current_page

    new_page =
      new_index /
      BushidoBagUI::PAGE_SIZE

    if new_page != old_page
      direction =
        new_page > old_page ?
        1 :
        -1

      animate_page_out(
        direction
      )

      @index =
        new_index

      reset_marquee

      draw_content
      draw_scrollbar
      refresh_item_icons
      refresh_item_overlay
      refresh_scroll_party

      @cursor_rect =
        current_selection_rect

      draw_cursor_rect(
        @cursor_rect
      )

      set_content_offset(
        0,
        direction *
        BushidoBagUI::PAGE_SLIDE_DISTANCE,
        0
      )

      animate_page_in(
        direction
      )

      pbPlayCursorSE

      return
    end

    @index =
      new_index

    pbPlayCursorSE

    pbRefreshIndexChanged
  end

  #=============================================================================
  # Navigation
  #=============================================================================

  def move_left
    if @header_selected
      change_pocket(-1)
      return
    end

    return if
      item_count <= 0

    row =
      local_row

    col =
      local_col

    row_start =
      page_start +
      row *
      BushidoBagUI::COLS

    row_end = [
      row_start +
      BushidoBagUI::COLS -
      1,
      item_count - 1,
      page_start +
      BushidoBagUI::PAGE_SIZE -
      1
    ].min

    if col == 0
      set_index(
        row_end
      )
    else
      set_index(
        @index - 1
      )
    end
  end

  def move_right
    if @header_selected
      change_pocket(1)
      return
    end

    return if
      item_count <= 0

    row =
      local_row

    row_start =
      page_start +
      row *
      BushidoBagUI::COLS

    row_end = [
      row_start +
      BushidoBagUI::COLS -
      1,
      item_count - 1,
      page_start +
      BushidoBagUI::PAGE_SIZE -
      1
    ].min

    if @index >= row_end
      set_index(
        row_start
      )
    else
      set_index(
        @index + 1
      )
    end
  end

  def move_up
    return if
      @header_selected

    return if
      item_count <= 0

    col =
      local_col

    if local_row > 0
      set_index(
        @index -
        BushidoBagUI::COLS
      )

      return
    end

    if current_page > 0
      previous_page_start =
        page_start -
        BushidoBagUI::PAGE_SIZE

      previous_page_end =
        page_start -
        1

      target =
        page_start -
        BushidoBagUI::COLS +
        col

      target =
        previous_page_end if
        target > previous_page_end

      target =
        previous_page_start if
        target < previous_page_start

      set_index(target)

      return
    end

    @header_col =
      col

    @header_selected =
      true

    reset_marquee
    hide_party_icons

    draw_header
    draw_content
    refresh_item_overlay

    pbPlayCursorSE

    animate_cursor_to(
      header_rect
    )
  end

  def move_down
    if @header_selected
      # Empty pockets have nowhere to move. Stay on the header so the player
      # can still switch pockets or back out instead of entering a dead state.
      return if item_count <= 0

      @header_selected =
        false

      target =
        @header_col

      target =
        item_count - 1 if
        target >= item_count

      @index =
        target

      pbPlayCursorSE
      pbRefreshIndexChanged

      return
    end

    return if
      item_count <= 0

    col =
      local_col

    target =
      @index +
      BushidoBagUI::COLS

    page_end = [
      page_start +
      BushidoBagUI::PAGE_SIZE -
      1,
      item_count - 1
    ].min

    if target <= page_end
      set_index(target)
      return
    end

    if current_page < max_page
      next_start =
        page_start +
        BushidoBagUI::PAGE_SIZE

      target =
        next_start +
        col

      target =
        item_count - 1 if
        target >= item_count

      set_index(target)
    end
  end

  #=============================================================================
  # Pocket switching
  #=============================================================================

  def change_pocket(direction)
    new_pocket =
      next_valid_pocket(
        direction
      )

    return if
      new_pocket == @pocket

    animate_pocket_out(
      direction
    )

    @bag.setChoice(
      @pocket,
      @index
    )

    @pocket =
      new_pocket

    @bag.lastpocket =
      @pocket

    @index =
      @bag.getChoice(
        @pocket
      )

    @index = 0 if
      !@index

    clamp_index

    @header_selected =
      true

    reset_marquee

    draw_header
    draw_content
    draw_scrollbar

    refresh_item_icons
    refresh_item_overlay
    refresh_scroll_party

    @cursor_rect =
      header_rect

    draw_cursor_rect(
      @cursor_rect
    )

    set_content_offset(
      direction *
      BushidoBagUI::POCKET_SLIDE_DISTANCE,
      0,
      0
    )

    animate_pocket_in(
      direction
    )

    pbPlayCursorSE
  end

  #=============================================================================
  # Sorting
  #=============================================================================

  def can_sort_current_pocket?
    return false if
      @choosing

    return false if
      @filterlist

    return false if
      item_count <= 1

    return false if
      @header_selected

    begin
      return false if
        BAG_POCKET_AUTO_SORT[@pocket]
    rescue
    end

    return true
  end

  def start_sorting
    return if
      !can_sort_current_pocket?

    @sort_backup =
      @bag.pockets[@pocket].map do |entry|
        entry ?
        entry.dup :
        nil
      end

    @sort_start_index =
      @index

    @sorting =
      true

    pbPlayDecisionSE

    draw_content

    draw_cursor_rect(
      current_selection_rect
    )
  end

  def sorting_swap(new_index)
    return if
      !@sorting

    new_index =
      [
        [new_index, 0].max,
        item_count - 1
      ].min

    return if
      new_index == @index

    pocket =
      @bag.pockets[@pocket]

    moved =
      pocket.delete_at(
        @index
      )

    pocket.insert(
      new_index,
      moved
    )

    @index =
      new_index

    reset_marquee

    draw_content
    draw_scrollbar

    refresh_item_icons
    refresh_item_overlay
    refresh_scroll_party

    animate_cursor_to(
      current_selection_rect
    )
  end

  def sorting_left
    row =
      local_row

    col =
      local_col

    row_start =
      page_start +
      row *
      BushidoBagUI::COLS

    row_end = [
      row_start +
      BushidoBagUI::COLS -
      1,
      item_count - 1,
      page_start +
      BushidoBagUI::PAGE_SIZE -
      1
    ].min

    sorting_swap(
      col == 0 ?
      row_end :
      @index - 1
    )
  end

  def sorting_right
    row =
      local_row

    row_start =
      page_start +
      row *
      BushidoBagUI::COLS

    row_end = [
      row_start +
      BushidoBagUI::COLS -
      1,
      item_count - 1,
      page_start +
      BushidoBagUI::PAGE_SIZE -
      1
    ].min

    sorting_swap(
      @index >= row_end ?
      row_start :
      @index + 1
    )
  end

  def sorting_up
    target =
      @index -
      BushidoBagUI::COLS

    return if
      target < 0

    sorting_swap(target)
  end

  def sorting_down
    target =
      @index +
      BushidoBagUI::COLS

    return if
      target >= item_count

    sorting_swap(target)
  end

  def finish_sorting
    return if
      !@sorting

    @sorting =
      false

    @sort_backup =
      nil

    @sort_start_index =
      -1

    pbPlayDecisionSE

    pbRefresh
  end

  def cancel_sorting
    return if
      !@sorting

    if @sort_backup
      @bag.pockets[@pocket].replace(
        @sort_backup
      )
    end

    if @sort_start_index >= 0
      @index =
        @sort_start_index
    end

    @sorting =
      false

    @sort_backup =
      nil

    @sort_start_index =
      -1

    clamp_index

    pbPlayCancelSE

    pbRefresh
  end

  #=============================================================================
  # Main chooser
  #=============================================================================

  def pbChooseItem
    @sprites["helpwindow"].visible =
      false

    loop do
      Graphics.update
      Input.update
      pbUpdate

      if @sorting
        if Input.trigger?(Input::LEFT)
          sorting_left

        elsif Input.trigger?(Input::RIGHT)
          sorting_right

        elsif Input.trigger?(Input::UP)
          sorting_up

        elsif Input.trigger?(Input::DOWN)
          sorting_down

        elsif Input.trigger?(Input::A) ||
              Input.trigger?(Input::C)

          finish_sorting

        elsif Input.trigger?(Input::B)
          cancel_sorting
        end

        next
      end

      if Input.trigger?(Input::LEFT)
        move_left

      elsif Input.trigger?(Input::RIGHT)
        move_right

      elsif Input.trigger?(Input::UP)
        move_up

      elsif Input.trigger?(Input::DOWN)
        move_down

      elsif Input.trigger?(Input::A)
        start_sorting

      elsif Input.trigger?(Input::B)
        pbPlayCloseMenuSE

        return 0

      elsif Input.trigger?(Input::C)
        next if
          @header_selected

        item =
          current_item

        next if
          !valid_item_id?(item)

        play_confirm_juice

        @bag.setChoice(
          @pocket,
          @index
        )

        pbPlayDecisionSE

        return item
      end
    end
  end

  #=============================================================================
  # Stock PokemonBagScreen support
  #=============================================================================

  def pbDisplay(
    msg,
    brief = false
  )
    pbMessageDisplay(
      @sprites["msgwindow"],
      msg,
      brief
    ) {
      pbUpdate
    }
  end

  def pbConfirm(msg)
    return pbConfirmMessage(
      msg
    )
  end

  def pbChooseNumber(
    helptext,
    maximum,
    initnum = 1
  )
    params =
      ChooseNumberParams.new

    params.setRange(
      1,
      maximum
    )

    params.setDefaultValue(
      initnum
    )

    return pbMessageChooseNumber(
      helptext,
      params
    ) {
      pbUpdate
    }
  end

  #=============================================================================
  # Command popup
  #=============================================================================

  def pbShowCommands(
    helptext,
    commands,
    index = 0
  )
    return -1 if
      !commands ||
      commands.length == 0

    index = 0 if
      index < 0

    if index >= commands.length
      index =
        commands.length - 1
    end

    popup =
      BitmapSprite.new(
        Graphics.width,
        Graphics.height,
        @viewport
      )

    popup.z =
      @viewport.z + 100

    pbSetSystemFont(
      popup.bitmap
    )

    loop do
      draw_command_popup(
        popup.bitmap,
        commands,
        index
      )

      Graphics.update
      Input.update
      pbUpdate

      if Input.trigger?(Input::UP)
        index -= 1

        index =
          commands.length - 1 if
          index < 0

        pbPlayCursorSE

      elsif Input.trigger?(Input::DOWN)
        index += 1

        index =
          0 if
          index >= commands.length

        pbPlayCursorSE

      elsif Input.trigger?(Input::B)
        pbPlayCancelSE

        popup.dispose

        return -1

      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE

        popup.dispose

        return index
      end
    end
  end

  def draw_command_popup(
    bitmap,
    commands,
    index
  )
    bitmap.clear

    bitmap.fill_rect(
      0,
      0,
      Graphics.width,
      Graphics.height,
      Color.new(
        0,
        0,
        0,
        80
      )
    )

    width =
      176

    row_h =
      30

    height =
      commands.length *
      row_h +
      20

    x =
      Graphics.width / 2 -
      width / 2

    y =
      Graphics.height / 2 -
      height / 2

    bitmap.fill_rect(
      x,
      y,
      width,
      height,
      BushidoBagUI::BACKGROUND
    )

    border =
      BushidoBagUI::SELECT_BORDER

    bitmap.fill_rect(
      x,
      y,
      width,
      2,
      border
    )

    bitmap.fill_rect(
      x,
      y + height - 2,
      width,
      2,
      border
    )

    bitmap.fill_rect(
      x,
      y,
      2,
      height,
      border
    )

    bitmap.fill_rect(
      x + width - 2,
      y,
      2,
      height,
      border
    )

    commands.each_with_index do |command, i|
      yy =
        y +
        10 +
        i *
        row_h

      selected =
        i == index

      if selected
        bitmap.fill_rect(
          x + 6,
          yy,
          width - 12,
          row_h - 2,
          BushidoBagUI::SELECT_BORDER
        )
      end

      color =
        selected ?
        Color.new(255, 255, 255) :
        BushidoBagUI::TEXT

      shadow =
        selected ?
        Color.new(90, 20, 20) :
        BushidoBagUI::TEXT_SHADOW

      pbDrawTextPositions(
        bitmap,
        [
          [
            command,
            x + width / 2,
            yy + 2,
            2,
            color,
            shadow
          ]
        ]
      )
    end
  end

  #=============================================================================
  # Fade
  #=============================================================================

  def pbFadeOutScene
    @oldsprites =
      pbFadeOutAndHide(
        @sprites
      )
  end

  def pbFadeInScene
    pbFadeInAndShow(
      @sprites,
      @oldsprites
    )

    @oldsprites =
      nil
  end

  def pbEndScene
    pbFadeOutAndHide(
      @sprites
    ) if !@oldsprites

    @oldsprites =
      nil

    dispose
  end

  #=============================================================================
  # Cleanup
  #=============================================================================

  def dispose
    if @sprites &&
       @sprites["marquee"] &&
       @sprites["marquee"].bitmap &&
       !@sprites["marquee"].bitmap.disposed?

      @sprites["marquee"].bitmap.dispose

      @sprites["marquee"].bitmap =
        nil
    end

    pbDisposeSpriteHash(
      @sprites
    ) if @sprites

    if @viewport &&
       !@viewport.disposed?

      @viewport.dispose
    end
  end
end
