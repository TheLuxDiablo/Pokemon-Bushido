#===============================================================================
# Modular Pause Menu - Main Update
# Update for Luka S.J.'s Modular Pause Menu / Essentials v18.1
#
# 5x2 scroll grid, red ink selection, map/money header and party strip.
#===============================================================================

module MenuHandlers
  @@menuEntry = {} if !defined?(@@menuEntry)
  @@available = {} if !defined?(@@available)
  @@indexes   = {} if !defined?(@@indexes)
  @@index     = 0  if !defined?(@@index)

  def self.addEntry(ref,name,icon,proc,conditional)
    if !@@menuEntry.has_key?(ref)
      @@indexes[ref] = @@index
      @@index += 1
    end
    @@menuEntry[ref] = [name,icon,proc]
    @@available[ref] = conditional
  end

  def self.getName(ref)
    return @@menuEntry[ref][0]
  end

  def self.getIcon(ref)
    return "Graphics/Icons/#{@@menuEntry[ref][1]}"
  end

  def self.getKeys
    entries = Array.new(@@menuEntry.keys.length)
    for key in @@menuEntry.keys
      entries[@@indexes[key]] = key
    end
    return entries.compact
  end

  def self.runAction(ref,scene)
    @@menuEntry[ref][2].call(scene)
  end

  def self.available?(ref)
    return @@available[ref].call
  end

  def self.elements?
    items = 0
    for val in self.getKeys
      items += 1 if self.available?(val)
    end
    return items
  end
end

module BushidoPause
  PANEL_WIDTH        = 480
  PANEL_HEIGHT       = 350
  PANEL_Y_OFFSET     = 0

  COLUMNS            = 5
  ROWS               = 2
  PAGE_SIZE          = COLUMNS * ROWS

  GRID_LEFT          = 48
  GRID_TOP           = 76
  CELL_WIDTH         = 77
  CELL_HEIGHT        = 82
  CELL_GAP_X         = 4
  CELL_GAP_Y         = 2

  PARTY_Y            = 284
  PARTY_SPACING      = 55

  DIM_ALPHA          = 118
  OPEN_FRAMES        = 10
  CLOSE_FRAMES       = 8

  PARCHMENT_LIGHT    = Color.new(244,226,190)
  PARCHMENT          = Color.new(227,206,165)
  PARCHMENT_MID      = Color.new(212,184,136)
  PARCHMENT_DARK     = Color.new(188,151,102)
  PARCHMENT_DEEP     = Color.new(139,101,66)

  INK                = Color.new(56,39,27)
  MUTED              = Color.new(122,91,61)
  GOLD               = Color.new(156,116,62)
  SHADOW             = Color.new(83,55,33,80)

  RED                = Color.new(166,48,44)
  RED_DARK           = Color.new(112,30,28)
  RED_LIGHT          = Color.new(204,82,68)
  RED_FAINT          = Color.new(166,48,44,45)

  def self.ease_out(t)
    return 1.0 - ((1.0 - t) * (1.0 - t))
  end

  def self.ease_in(t)
    return t * t
  end
end

class PokemonPauseMenu_Scene
  attr_accessor :index
  attr_accessor :entries
  attr_accessor :endscene
  attr_accessor :close
  attr_accessor :hidden

  def pbShowInfo(text)
    @sprites["helpwindow"].resizeToFit(text,Graphics.height)
    @sprites["helpwindow"].text = text
    @sprites["helpwindow"].visible = true
    pbBottomLeft(@sprites["helpwindow"])
  end

  def pbShowHelp(text)
    pbShowInfo(text)
  end

  def pbStartScene
    pbSetViableDexes

    @index = $PokemonTemp.menuLastChoice.nil? ? 0 : $PokemonTemp.menuLastChoice
    @endscene = true
    @close = false
    @hidden = false
    @closing = false
    @page = -1
    @hoverTick = 0
    @selectionKick = 0

    buildEntries
    @index = 0 if @index < 0 || @index >= @entries.length

    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites = {}

    createBackground
    createDimmer
    createScroll
    createHoverSprites
    createOverlay
    createPartySprites

    @sprites["infowindow"] = Window_UnformattedTextPokemon.newWithSize(
      "",0,0,32,32,@viewport
    )
    @sprites["infowindow"].visible = false

    @sprites["helpwindow"] = Window_UnformattedTextPokemon.newWithSize(
      "",0,0,32,32,@viewport
    )
    @sprites["helpwindow"].visible = false

    refresh(true)
    setMenuOpacity(0)
  end

  def buildEntries
    @entries = []
    for val in MenuHandlers.getKeys
      @entries.push(val) if MenuHandlers.available?(val)
    end
  end

  def createBackground
    @sprites["background"] = Sprite.new(@viewport)
    @sprites["background"].bitmap = Graphics.snap_to_bitmap
    begin
      @sprites["background"].blur_sprite(3)
    rescue
    end
  end

  def createDimmer
    @sprites["dimmer"] = BitmapSprite.new(
      Graphics.width,
      Graphics.height,
      @viewport
    )
    @sprites["dimmer"].bitmap.fill_rect(
      0,0,Graphics.width,Graphics.height,
      Color.new(0,0,0,BushidoPause::DIM_ALPHA)
    )
  end

  def createScroll
    @panelX = (Graphics.width - BushidoPause::PANEL_WIDTH) / 2
    @panelY = (Graphics.height - BushidoPause::PANEL_HEIGHT) / 2 +
              BushidoPause::PANEL_Y_OFFSET

    @sprites["scroll"] = Sprite.new(@viewport)
    @sprites["scroll"].bitmap = Bitmap.new(
      BushidoPause::PANEL_WIDTH,
      BushidoPause::PANEL_HEIGHT
    )

    @sprites["scroll"].ox = BushidoPause::PANEL_WIDTH / 2
    @sprites["scroll"].oy = BushidoPause::PANEL_HEIGHT / 2
    @sprites["scroll"].x = Graphics.width / 2
    @sprites["scroll"].y = @panelY + BushidoPause::PANEL_HEIGHT / 2

    drawScroll(@sprites["scroll"].bitmap)
  end


  def createHoverSprites
    # The selected cell gets its own sprite so it can breathe/pulse without
    # forcing the entire menu bitmap to redraw every frame.
    @sprites["selection"] = Sprite.new(@viewport)
    @sprites["selection"].bitmap = Bitmap.new(
      BushidoPause::CELL_WIDTH,
      BushidoPause::CELL_HEIGHT
    )
    @sprites["selection"].ox = BushidoPause::CELL_WIDTH / 2
    @sprites["selection"].oy = BushidoPause::CELL_HEIGHT / 2
    @sprites["selection"].z = 2

    sbmp = @sprites["selection"].bitmap
    w = BushidoPause::CELL_WIDTH
    h = BushidoPause::CELL_HEIGHT
    sbmp.fill_rect(0,0,w,h,BushidoPause::RED_FAINT)
    sbmp.fill_rect(0,0,w,2,BushidoPause::RED)
    sbmp.fill_rect(0,0,2,h,BushidoPause::RED)
    sbmp.fill_rect(w-2,0,2,h,BushidoPause::RED)
    sbmp.fill_rect(0,h-2,w,2,BushidoPause::RED)

    # The active icon is separated from the static grid so it can lift,
    # bob and settle when the cursor moves onto it.
    @sprites["hovericon"] = Sprite.new(@viewport)
    @sprites["hovericon"].ox = 24
    @sprites["hovericon"].oy = 24
    @sprites["hovericon"].z = 4
  end

  def createOverlay
    @sprites["overlay"] = BitmapSprite.new(
      Graphics.width,
      Graphics.height,
      @viewport
    )
    @sprites["overlay"].z = 3
    pbSetSystemFont(@sprites["overlay"].bitmap)
  end

  def createPartySprites
    for i in 0...6
      key = "party#{i}"
      if $Trainer.party[i]
        @sprites[key] = PokemonIconSprite.new($Trainer.party[i],@viewport)
        @sprites[key].setOffset(PictureOrigin::Center)
        @sprites[key].z = 4
        @sprites[key].x = partyX(i)
        @sprites[key].y = @panelY + BushidoPause::PARTY_Y
      end
    end
  end

  def refreshPartySprites
    for i in 0...6
      key = "party#{i}"
      if @sprites[key]
        @sprites[key].dispose
        @sprites.delete(key)
      end
    end
    createPartySprites
  end

  def partyX(i)
    count = $Trainer.party.length
    count = 1 if count < 1
    total = (count - 1) * BushidoPause::PARTY_SPACING
    start = Graphics.width / 2 - total / 2
    return start + i * BushidoPause::PARTY_SPACING
  end

  def drawScroll(bmp)
    bmp.clear

    w = BushidoPause::PANEL_WIDTH
    h = BushidoPause::PANEL_HEIGHT

    light = BushidoPause::PARCHMENT_LIGHT
    body  = BushidoPause::PARCHMENT
    mid   = BushidoPause::PARCHMENT_MID
    dark  = BushidoPause::PARCHMENT_DARK
    deep  = BushidoPause::PARCHMENT_DEEP

    paper_left  = 31
    paper_right = w - 32
    top_base    = 22
    bottom_base = h - 24

    top_profile = [
      3,3,3,2,2,2,1,1,1,0,0,0,
      2,2,1,1,0,0,0,1,1,1,3,3,
      2,2,2,1,0,0,1,1,2,2,1,1,
      0,0,0,2,2,2,3,3,1,1,0,0
    ]

    bottom_profile = [
      0,0,1,1,2,2,3,3,2,2,1,1,
      3,3,4,4,2,2,1,1,0,0,2,2,
      3,3,1,1,0,0,2,2,4,4,3,3,
      1,1,2,2,3,3,1,1,0,0,2,2
    ]

    x = paper_left
    while x <= paper_right
      idx = (x - paper_left) % top_profile.length
      top_y = top_base + top_profile[idx]
      bottom_y = bottom_base - bottom_profile[idx]
      column_h = bottom_y - top_y + 1

      if column_h > 0
        bmp.fill_rect(x,top_y,1,column_h,dark)

        inner_top = top_y + 2
        inner_bottom = bottom_y - 2

        if inner_bottom >= inner_top
          bmp.fill_rect(
            x,inner_top,1,inner_bottom-inner_top+1,light
          )
        end

        shade_top = bottom_y - 8
        if shade_top > inner_top
          bmp.fill_rect(
            x,shade_top,1,[6,bottom_y-shade_top].min,body
          )
        end
      end
      x += 1
    end

    # left roll
    bmp.fill_rect(9,13,23,h-26,deep)
    bmp.fill_rect(12,10,17,h-20,dark)
    bmp.fill_rect(15,13,11,h-26,mid)
    bmp.fill_rect(18,15,5,h-30,light)

    bmp.fill_rect(5,8,28,9,deep)
    bmp.fill_rect(8,5,22,9,dark)
    bmp.fill_rect(11,7,16,5,light)
    bmp.fill_rect(7,14,10,5,deep)

    bmp.fill_rect(5,h-17,28,9,deep)
    bmp.fill_rect(8,h-14,22,9,dark)
    bmp.fill_rect(11,h-12,16,5,light)
    bmp.fill_rect(7,h-19,10,5,deep)

    bmp.fill_rect(26,26,6,h-52,deep)
    bmp.fill_rect(29,30,4,h-60,dark)

    # right roll
    rx = w - 32
    bmp.fill_rect(rx,13,23,h-26,deep)
    bmp.fill_rect(rx+3,10,17,h-20,dark)
    bmp.fill_rect(rx+6,13,11,h-26,mid)
    bmp.fill_rect(rx+9,15,5,h-30,light)

    bmp.fill_rect(w-33,8,28,9,deep)
    bmp.fill_rect(w-30,5,22,9,dark)
    bmp.fill_rect(w-27,7,16,5,light)
    bmp.fill_rect(w-17,14,10,5,deep)

    bmp.fill_rect(w-33,h-17,28,9,deep)
    bmp.fill_rect(w-30,h-14,22,9,dark)
    bmp.fill_rect(w-27,h-12,16,5,light)
    bmp.fill_rect(w-17,h-19,10,5,deep)

    bmp.fill_rect(w-33,26,6,h-52,deep)
    bmp.fill_rect(w-33,30,4,h-60,dark)

  end

  def setMenuOpacity(value)
    @sprites["dimmer"].opacity = value if @sprites["dimmer"]
    @sprites["scroll"].opacity = value if @sprites["scroll"]
    @sprites["overlay"].opacity = value if @sprites["overlay"]
    @sprites["selection"].opacity = value if @sprites["selection"]
    @sprites["hovericon"].opacity = value if @sprites["hovericon"]

    for i in 0...6
      spr = @sprites["party#{i}"]
      spr.opacity = value if spr
    end
  end

  def pbShowMenu
    @hidden = false
    frames = BushidoPause::OPEN_FRAMES
    frames = 1 if frames < 1

    @sprites["scroll"].zoom_x = 0.08
    setMenuOpacity(0)

    for i in 0...frames
      Graphics.update
      updatePartyOnly

      t = (i + 1).to_f / frames
      e = BushidoPause.ease_out(t)
      alpha = (255 * e).to_i

      @sprites["scroll"].zoom_x = 0.08 + (0.92 * e)
      setMenuOpacity(alpha)
    end

    @sprites["scroll"].zoom_x = 1.0
    setMenuOpacity(255)
    @sprites["selection"].opacity = 230 if @sprites["selection"]
  end

  def pbHideMenu
    return if @hidden
    @hidden = true

    frames = BushidoPause::CLOSE_FRAMES
    frames = 1 if frames < 1

    for i in 0...frames
      Graphics.update
      updatePartyOnly

      t = (i + 1).to_f / frames
      e = BushidoPause.ease_in(t)
      remain = 1.0 - e
      alpha = (255 * remain).to_i

      @sprites["scroll"].zoom_x = 0.08 + (0.92 * remain)
      setMenuOpacity(alpha)
    end

    @sprites["scroll"].zoom_x = 0.08
    setMenuOpacity(0)
  end

  def refresh(force=false)
    old_count = @entries ? @entries.length : 0
    buildEntries

    if @entries.length == 0
      @index = 0
      return
    end

    @index = @entries.length - 1 if @index >= @entries.length
    @index = 0 if @index < 0

    new_page = @index / BushidoPause::PAGE_SIZE
    page_changed = (new_page != @page)
    @page = new_page

    refreshPartySprites if force || old_count != @entries.length

    bmp = @sprites["overlay"].bitmap
    bmp.clear
    pbSetSystemFont(bmp)

    drawHeader(bmp)
    drawGrid(bmp)
    drawPageIndicator(bmp) if @entries.length > BushidoPause::PAGE_SIZE
    syncHoverSprites
  end

  def drawHeader(bmp)
    map_name = $game_map ? $game_map.name : ""

    time_text = ""
    begin
      time_text = pbGetTimeNow.strftime("%I:%M %p")
    rescue
      time_text = ""
    end

    money = $Trainer ? $Trainer.money : 0
    money_text = money.to_i.to_s
    money_text = money_text.reverse.scan(/.{1,3}/).join(",").reverse
    money_text = _INTL("¥{1}",money_text)

    # One clean header line: location on the left, time centered, money right.
    begin
      pbSetSmallFont(bmp)
    rescue
    end

    y = @panelY + 40
    text = [
      [
        map_name,
        @panelX + 52,
        y,
        0,
        BushidoPause::INK,
        BushidoPause::SHADOW
      ],
      [
        time_text,
        @panelX + BushidoPause::PANEL_WIDTH / 2,
        y,
        2,
        BushidoPause::MUTED,
        BushidoPause::SHADOW
      ],
      [
        money_text,
        @panelX + BushidoPause::PANEL_WIDTH - 52,
        y,
        1,
        BushidoPause::RED_DARK,
        BushidoPause::SHADOW
      ]
    ]

    pbDrawTextPositions(bmp,text)
    pbSetSystemFont(bmp)
  end

  def drawGrid(bmp)
    start_index = @page * BushidoPause::PAGE_SIZE
    finish_index = [start_index + BushidoPause::PAGE_SIZE,@entries.length].min

    for global_index in start_index...finish_index
      local_index = global_index - start_index
      row = local_index / BushidoPause::COLUMNS
      col = local_index % BushidoPause::COLUMNS

      x = @panelX + BushidoPause::GRID_LEFT +
          col * (BushidoPause::CELL_WIDTH + BushidoPause::CELL_GAP_X)
      y = @panelY + BushidoPause::GRID_TOP +
          row * (BushidoPause::CELL_HEIGHT + BushidoPause::CELL_GAP_Y)

      selected = (global_index == @index)
      drawCell(bmp,x,y,@entries[global_index],selected)
    end
  end

  def drawCell(bmp,x,y,key,selected)
    w = BushidoPause::CELL_WIDTH
    h = BushidoPause::CELL_HEIGHT


    begin
      icon = pbBitmap(MenuHandlers.getIcon(key))
      src_w = [48,icon.width].min
      src_h = [48,icon.height].min
      ix = x + (w - src_w) / 2
      iy = y + 2
      opacity = selected ? 0 : 145
      bmp.blt(ix,iy,icon,Rect.new(0,0,src_w,src_h),opacity)
    rescue
    end

    name = MenuHandlers.getName(key).clone
    name = name.gsub("\\pn") { "#{$Trainer.name}" }
    name = name.gsub("\\contest") { pbInSafari? ? "Quit" : "Quit Contest" }

    begin
      pbSetSmallFont(bmp)
    rescue
    end

    base = selected ? BushidoPause::RED_DARK : BushidoPause::INK
    shadow = BushidoPause::SHADOW

    # Keep labels compact. Longer names are split cleanly over two lines.
    if name.length > 9 && name.include?(" ")
      words = name.split(" ")
      split_at = (words.length / 2.0).ceil
      line1 = words[0...split_at].join(" ")
      line2 = words[split_at...words.length].join(" ")
      pbDrawTextPositions(bmp,[
        [line1,x + w/2,y + 49,2,base,shadow],
        [line2,x + w/2,y + 61,2,base,shadow]
      ])
    else
      pbDrawTextPositions(bmp,[[
        name,
        x + w/2,
        y + 56,
        2,
        base,
        shadow
      ]])
    end

    pbSetSystemFont(bmp)
  end

  def drawPageIndicator(bmp)
    pages = (@entries.length + BushidoPause::PAGE_SIZE - 1) /
            BushidoPause::PAGE_SIZE

    begin
      pbSetSmallFont(bmp)
    rescue
    end

    pbDrawTextPositions(bmp,[[
      _INTL("{1}/{2}",@page + 1,pages),
      @panelX + BushidoPause::PANEL_WIDTH - 54,
      @panelY + 277,
      1,
      BushidoPause::MUTED,
      BushidoPause::SHADOW
    ]])

    pbSetSystemFont(bmp)
  end


  def selectedCellPosition
    local_index = @index % BushidoPause::PAGE_SIZE
    row = local_index / BushidoPause::COLUMNS
    col = local_index % BushidoPause::COLUMNS

    x = @panelX + BushidoPause::GRID_LEFT +
        col * (BushidoPause::CELL_WIDTH + BushidoPause::CELL_GAP_X)
    y = @panelY + BushidoPause::GRID_TOP +
        row * (BushidoPause::CELL_HEIGHT + BushidoPause::CELL_GAP_Y)
    return x,y
  end

  def syncHoverSprites
    return if !@entries || @entries.length == 0

    x,y = selectedCellPosition

    @sprites["selection"].x = x + BushidoPause::CELL_WIDTH / 2
    @sprites["selection"].y = y + BushidoPause::CELL_HEIGHT / 2

    key = @entries[@index]
    begin
      @sprites["hovericon"].bitmap = pbBitmap(MenuHandlers.getIcon(key))
    rescue
      @sprites["hovericon"].bitmap = nil
    end

    @sprites["hovericon"].x = x + BushidoPause::CELL_WIDTH / 2
    @sprites["hovericon"].y = y + 26

    @selectionKick = 7
  end

  def updateHover
    return if !@sprites["selection"] || !@sprites["hovericon"]

    @hoverTick += 1

    # Slow breathing on the red selection box.
    breathe = Math.sin(@hoverTick / 8.0)
    frame_scale = 1.0 + 0.012 * breathe
    @sprites["selection"].zoom_x = frame_scale
    @sprites["selection"].zoom_y = frame_scale

    # The active icon floats by a pixel or two while selected.
    bob = Math.sin(@hoverTick / 5.0) * 1.5
    x,y = selectedCellPosition
    base_y = y + 26

    if @selectionKick > 0
      # A quick little pop when landing on a new command.
      kick = @selectionKick.to_f / 7.0
      @sprites["hovericon"].zoom_x = 1.0 + 0.10 * kick
      @sprites["hovericon"].zoom_y = 1.0 + 0.10 * kick
      @sprites["hovericon"].y = base_y - 3 * kick + bob
      @selectionKick -= 1
    else
      @sprites["hovericon"].zoom_x = 1.0
      @sprites["hovericon"].zoom_y = 1.0
      @sprites["hovericon"].y = base_y + bob
    end

    # Gentle ink pulse, kept restrained so it doesn't look like a neon UI.
    pulse = 210 + (25 * ((breathe + 1.0) / 2.0)).to_i
    @sprites["selection"].opacity = pulse
  end

  def updatePartyOnly
    for i in 0...6
      spr = @sprites["party#{i}"]
      spr.update if spr
    end
  end

  def update
    updatePartyOnly
    updateHover
  end

  def pbEndScene
    pbSEPlay("GUI menu close")
    pbHideMenu if !@hidden
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose if @viewport && !@viewport.disposed?
  end

  def pbRefresh
    refresh(true)
  end
end

class PokemonPauseMenu
  def initialize(scene)
    @scene = scene
  end

  def pbShowMenu
    @scene.pbShowMenu
  end

  def pbStartPokemonMenu
    pbSEPlay("GUI menu open")
    @scene.pbStartScene
    @scene.pbShowMenu

    loop do
      Graphics.update
      Input.update
      @scene.update

      old_index = @scene.index

      if Input.repeat?(Input::LEFT)
        moveLeft
      elsif Input.repeat?(Input::RIGHT)
        moveRight
      elsif Input.repeat?(Input::UP)
        moveUp
      elsif Input.repeat?(Input::DOWN)
        moveDown
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE()
        MenuHandlers.runAction(@scene.entries[@scene.index],@scene)
      end

      if old_index != @scene.index
        $PokemonTemp.menuLastChoice = @scene.index
        pbSEPlay("SE_Select1",75)
        @scene.refresh
      end

      break if @scene.close ||
               Input.trigger?(Input::B) ||
               Input.trigger?(Input::A)
    end

    @scene.pbEndScene if @scene.endscene
  end

  def moveLeft
    count = @scene.entries.length
    return if count <= 1

    cols = BushidoPause::COLUMNS
    row = @scene.index / cols
    row_start = row * cols
    row_end = [row_start + cols - 1,count - 1].min

    if @scene.index <= row_start
      @scene.index = row_end
    else
      @scene.index -= 1
    end
  end

  def moveRight
    count = @scene.entries.length
    return if count <= 1

    cols = BushidoPause::COLUMNS
    row = @scene.index / cols
    row_start = row * cols
    row_end = [row_start + cols - 1,count - 1].min

    if @scene.index >= row_end
      @scene.index = row_start
    else
      @scene.index += 1
    end
  end

  def moveUp
    moveVertical(-1)
  end

  def moveDown
    moveVertical(1)
  end

  def moveVertical(direction)
    count = @scene.entries.length
    return if count <= 1

    cols = BushidoPause::COLUMNS
    total_rows = (count + cols - 1) / cols

    row = @scene.index / cols
    col = @scene.index % cols

    target_row = row + direction
    target_row = total_rows - 1 if target_row < 0
    target_row = 0 if target_row >= total_rows

    target_start = target_row * cols
    target_end = [target_start + cols - 1,count - 1].min
    target = target_start + col

    # A short final row shouldn't create a dead direction. Land on the
    # closest valid choice in that row instead.
    target = target_end if target > target_end
    @scene.index = target
  end
end
