
#===============================================================================
# Bushido Summary UI v2.1 clean move bitmap
#
# This keeps the stock summary layout/coordinates intact. The goal is for the
# summary to feel like the "deeper information" layer of the party screen,
# rather than a completely separate menu.
#===============================================================================
module BushidoSummaryUI
  BG          = Color.new(31, 25, 23)
  FRAME       = Color.new(244, 232, 207)
  PANEL       = Color.new(112, 94, 82)
  PANEL_DARK  = Color.new(76, 60, 53)
  PANEL_LIGHT = Color.new(150, 128, 106)
  GOLD        = Color.new(188, 144, 76)

  TEXT        = Color.new(244, 232, 207)
  TEXT_SHADOW = Color.new(24, 18, 16, 72)
  MUTED       = Color.new(190, 172, 148)

  MALE        = Color.new(82, 132, 204)
  FEMALE      = Color.new(204, 74, 105)
  NATURE_UP   = Color.new(224, 92, 70)
  NATURE_DOWN = Color.new(80, 142, 220)
  EXP_BLUE    = Color.new(64, 144, 224)
  SHADOW      = Color.new(144, 78, 188)

  UI_ASSET_ROOT = "Graphics/Pictures/Summary/Bushido"

  def self.floor2(value)
    (value.to_i / 2) * 2
  end

  def self.fill2(bitmap, x, y, w, h, color)
    x = floor2(x)
    y = floor2(y)
    w = floor2(w)
    h = floor2(h)
    return if w <= 0 || h <= 0
    bitmap.fill_rect(x, y, w, h, color)
  end

  def self.type_color(type_id)
    name = ""
    begin
      name = PBTypes.getName(type_id).to_s.upcase
    rescue
      name = type_id.to_s.upcase
    end

    colors = {
      "NORMAL"   => Color.new(168,168,120),
      "FIRE"     => Color.new(224,104,48),
      "WATER"    => Color.new(88,136,216),
      "ELECTRIC" => Color.new(232,192,48),
      "GRASS"    => Color.new(104,176,72),
      "ICE"      => Color.new(120,192,200),
      "FIGHTING" => Color.new(176,56,48),
      "POISON"   => Color.new(152,72,152),
      "GROUND"   => Color.new(200,168,88),
      "FLYING"   => Color.new(144,128,216),
      "PSYCHIC"  => Color.new(224,80,120),
      "BUG"      => Color.new(152,168,40),
      "ROCK"     => Color.new(168,144,56),
      "GHOST"    => Color.new(104,80,144),
      "DRAGON"   => Color.new(104,64,216),
      "DARK"     => Color.new(96,76,68),
      "STEEL"    => Color.new(152,152,176),
      "FAIRY"    => Color.new(220,132,156),
      "SHADOW"   => Color.new(144,78,188)
    }
    return colors[name] || GOLD
  end

  def self.asset(name)
    return "#{UI_ASSET_ROOT}/#{name}"
  end

  def self.skills_layout
    rows = []
    row_y = 112
    5.times do
      rows.push(Rect.new(238, row_y, 238, 28))
      row_y += 30
    end

    return {
      :hp       => Rect.new(238, 68, 238, 40),
      :stats    => rows,
      :ability  => Rect.new(224, 266, 264, 30),
      :desc     => Rect.new(224, 300, 264, 58)
    }
  end

  def self.ev_layout
    rows = []
    row_y = 90
    6.times do
      rows.push(Rect.new(238, row_y, 238, 28))
      row_y += 28
    end

    return {
      :header   => Rect.new(238, 62, 238, 28),
      :stats    => rows,
      :ability  => Rect.new(224, 262, 264, 30),
      :desc     => Rect.new(224, 296, 264, 62),
      :label_x  => 238,
      :label_w  => 112,
      :ev_x     => 350,
      :ev_w     => 72,
      :iv_x     => 422,
      :iv_w     => 54
    }
  end


  def self.move_mode_layout
    return {
      :hint        => Rect.new(332, 16, 154, 30),

      # Four compact move rows on the right.
      :list        => Rect.new(222, 62, 266, 192),
      :row_height  => 48,
      :row_gap     => 0,

      # Selected move metadata fills the left side under the header.
      :detail      => Rect.new(20, 58, 176, 142),
      :type        => Rect.new(28, 64, 160, 30),
      :category    => Rect.new(28, 96, 160, 30),
      :power       => Rect.new(28, 128, 160, 30),
      :accuracy    => Rect.new(28, 160, 160, 30),

      # Long prose gets a full-width tray beneath BOTH columns.
      :description => Rect.new(28, 258, 456, 112)
    }
  end

end

class BushidoMoveCursor < SpriteWrapper
  attr_accessor :index
  attr_reader :preselected

  def initialize(viewport=nil)
    super(viewport)
    @index = 0
    @preselected = false
    self.z = 20
    refresh
  end

  def index=(value)
    @index = value
  end

  def preselected=(value)
    @preselected = value
    refresh
  end

  def refresh
    path = @preselected ?
           BushidoSummaryUI.asset("move_cursor_preselected") :
           BushidoSummaryUI.asset("move_cursor")

    self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
    self.bitmap = Bitmap.new(path)
  end

  def dispose
    self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
    super
  end
end

class MoveSelectionSprite < SpriteWrapper
  attr_reader :preselected
  attr_reader :index

  def initialize(viewport=nil,fifthmove=false)
    super(viewport)
    @movesel = AnimatedBitmap.new("Graphics/Pictures/Summary/cursor_move")
    @frame = 0
    @index = 0
    @fifthmove = fifthmove
    @preselected = false
    @updating = false
    refresh
  end

  def dispose
    @movesel.dispose
    super
  end

  def index=(value)
    @index = value
    refresh
  end

  def preselected=(value)
    @preselected = value
    refresh
  end

  def refresh
    w = @movesel.width
    h = @movesel.height/2
    self.x = 240
    self.y = 92+(self.index*64)
    self.y -= 76 if @fifthmove
    self.y += 20 if @fifthmove && self.index==4
    self.bitmap = @movesel.bitmap
    if self.preselected
      self.src_rect.set(0,h,w,h)
    else
      self.src_rect.set(0,0,w,h)
    end
  end

  def update
    @updating = true
    super
    @movesel.update
    @updating = false
    refresh
  end
end



class RibbonSelectionSprite < MoveSelectionSprite
  def initialize(viewport=nil)
    super(viewport)
    @movesel = AnimatedBitmap.new("Graphics/Pictures/Summary/cursor_move")
    @frame = 0
    @index = 0
    @preselected = false
    @updating = false
    @spriteVisible = true
    refresh
  end

  def visible=(value)
    super
    @spriteVisible = value if !@updating
  end

  def refresh
    w = @movesel.width
    h = @movesel.height/2
    self.x = 228+(self.index%4)*68
    self.y = 76+((self.index/4).floor*68)
    self.bitmap = @movesel.bitmap
    if self.preselected
      self.src_rect.set(0,h,w,h)
    else
      self.src_rect.set(0,0,w,h)
    end
  end

  def update
    @updating = true
    super
    self.visible = @spriteVisible && @index>=0 && @index<12
    @movesel.update
    @updating = false
    refresh
  end
end



class PokemonSummary_Scene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbStartScene(party,partyindex,inbattle=false)
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @party      = party
    @partyindex = partyindex
    @pokemon    = @party[@partyindex]
    @inbattle   = inbattle
    @page = 1
    @typebitmap    = AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
    @sprites = {}
    @sprites["background"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["background"].z = 0
    @sprites["pokemon"] = PokemonSprite.new(@viewport)
    @sprites["pokemon"].setOffset(PictureOrigin::Center)
    @sprites["pokemon"].x = 104
    @sprites["pokemon"].y = 206
    @sprites["pokemon"].setPokemonBitmap(@pokemon)
    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon,@viewport)
    @sprites["pokeicon"].setOffset(PictureOrigin::Center)
    @sprites["pokeicon"].x       = 46
    @sprites["pokeicon"].y       = 92
    @sprites["pokeicon"].visible = false
    @sprites["itemicon"] = ItemIconSprite.new(30,306,@pokemon.item,@viewport)
    @sprites["itemicon"].blankzero = true
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["movepresel"] = BushidoMoveCursor.new(@viewport)
    @sprites["movepresel"].visible     = false
    @sprites["movepresel"].preselected = true
    @sprites["movesel"] = BushidoMoveCursor.new(@viewport)
    @sprites["movesel"].visible = false
    @sprites["ribbonpresel"] = RibbonSelectionSprite.new(@viewport)
    @sprites["ribbonpresel"].visible     = false
    @sprites["ribbonpresel"].preselected = true
    @sprites["ribbonsel"] = RibbonSelectionSprite.new(@viewport)
    @sprites["ribbonsel"].visible = false
    @sprites["uparrow"] = AnimatedSprite.new("Graphics/Pictures/uparrow",8,28,40,2,@viewport)
    @sprites["uparrow"].x = 350
    @sprites["uparrow"].y = 56
    @sprites["uparrow"].play
    @sprites["uparrow"].visible = false
    @sprites["downarrow"] = AnimatedSprite.new("Graphics/Pictures/downarrow",8,28,40,2,@viewport)
    @sprites["downarrow"].x = 350
    @sprites["downarrow"].y = 260
    @sprites["downarrow"].play
    @sprites["downarrow"].visible = false
    @sprites["markingbg"] = IconSprite.new(260,88,@viewport)
    @sprites["markingbg"].setBitmap("Graphics/Pictures/Summary/overlay_marking")
    @sprites["markingbg"].visible = false
    @sprites["markingoverlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["markingoverlay"].visible = false
    pbSetSystemFont(@sprites["markingoverlay"].bitmap)
    @sprites["markingsel"] = IconSprite.new(0,0,@viewport)
    @sprites["markingsel"].setBitmap("Graphics/Pictures/Summary/cursor_move")
    @sprites["markingsel"].src_rect.height = @sprites["markingsel"].bitmap.height/2
    @sprites["markingsel"].visible = false
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new("")
    @sprites["messagebox"].viewport       = @viewport
    @sprites["messagebox"].visible        = false
    @sprites["messagebox"].letterbyletter = true
    pbBottomLeftLines(@sprites["messagebox"],2)
    drawPage(@page)

    @sprites["pokemon"].x -= 10 if @sprites["pokemon"]
    @sprites["overlay"].x += 8 if @sprites["overlay"]

    pbFadeInAndShow(@sprites) { pbUpdate }

    # Settle into place after the fade.
    5.times do |i|
      @sprites["pokemon"].x += 2 if @sprites["pokemon"]
      @sprites["overlay"].x -= 2 if @sprites["overlay"] && i < 4
      Graphics.update
      pbUpdate
    end
    @sprites["pokemon"].x = 104 if @sprites["pokemon"]
    @sprites["overlay"].x = 0 if @sprites["overlay"]
  end

  def pbStartForgetScene(party,partyindex,moveToLearn)
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @party      = party
    @partyindex = partyindex
    @pokemon    = @party[@partyindex]
    @page       = 4

    # The move-learning screen can contain a fifth entry. Keep that state
    # separate from normal Summary move reordering.
    @move_to_learn     = moveToLearn
    @move_scroll_offset = 0

    @typebitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/types"))
    @sprites = {}

    @sprites["background"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["background"].z = 0

    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)

    @sprites["pokeicon"] = PokemonIconSprite.new(@pokemon,@viewport)
    @sprites["pokeicon"].setOffset(PictureOrigin::Center)
    @sprites["pokeicon"].x = 46
    @sprites["pokeicon"].y = 92

    # IMPORTANT: use the Bushido cursor here. The old Essentials
    # MoveSelectionSprite assumes the stock 64px move rows and is much too
    # large for this custom layout.
    @sprites["movesel"] = BushidoMoveCursor.new(@viewport)
    @sprites["movesel"].visible = true
    @sprites["movesel"].index = 0

    positionMoveCursors(0)
    drawSelectedMove(moveToLearn,@pokemon.moves[0].id)

    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @typebitmap.dispose
    @markingbitmap.dispose if @markingbitmap
    @viewport.dispose
    @move_to_learn = nil
    @move_scroll_offset = 0
  end

  def pbDisplay(text)
    @sprites["messagebox"].text = text
    @sprites["messagebox"].visible = true
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["messagebox"].busy?
        if Input.trigger?(Input::C)
          pbPlayDecisionSE() if @sprites["messagebox"].pausing?
          @sprites["messagebox"].resume
        end
      elsif Input.trigger?(Input::C) || Input.trigger?(Input::B)
        break
      end
    end
    @sprites["messagebox"].visible = false
  end

  def pbConfirm(text)
    ret = -1
    @sprites["messagebox"].text    = text
    @sprites["messagebox"].visible = true
    using(cmdwindow = Window_CommandPokemon.new([_INTL("Yes"),_INTL("No")])) {
      cmdwindow.z       = @viewport.z+1
      cmdwindow.visible = false
      pbBottomRight(cmdwindow)
      cmdwindow.y -= @sprites["messagebox"].height
      loop do
        Graphics.update
        Input.update
        cmdwindow.visible = true if !@sprites["messagebox"].busy?
        cmdwindow.update
        pbUpdate
        if !@sprites["messagebox"].busy?
          if Input.trigger?(Input::B)
            ret = false
            break
          elsif Input.trigger?(Input::C) && @sprites["messagebox"].resume
            ret = (cmdwindow.index==0)
            break
          end
        end
      end
    }
    @sprites["messagebox"].visible = false
    return ret
  end

  def pbShowCommands(commands,index=0)
    ret = -1
    using(cmdwindow = Window_CommandPokemon.new(commands)) {
       cmdwindow.z = @viewport.z+1
       cmdwindow.index = index
       pbBottomRight(cmdwindow)
       loop do
         Graphics.update
         Input.update
         cmdwindow.update
         pbUpdate
         if Input.trigger?(Input::B)
           pbPlayCancelSE
           ret = -1
           break
         elsif Input.trigger?(Input::C)
           pbPlayDecisionSE
           ret = cmdwindow.index
           break
         end
       end
    }
    return ret
  end

  def drawMarkings(bitmap,x,y)
    return false
    markings = @pokemon.markings
    markrect = Rect.new(0,0,16,16)
    for i in 0...6
      markrect.x = i*16
      markrect.y = (markings&(1<<i)!=0) ? 16 : 0
      bitmap.blt(x+i*16,y,@markingbitmap.bitmap,markrect)
    end
  end

  def drawSummaryActionHint(text)
    return if !text || text == ""

    b = @sprites["overlay"].bitmap
    pbSetSystemFont(b)

    label = text.to_s
    text_size = b.text_size(label)

    pad_x = 10
    pad_y = 6

    box_w = text_size.width + (pad_x * 2)
    box_h = text_size.height + (pad_y * 2)

    # Stay on the same 2px grid as the rest of the custom UI.
    box_w = BushidoSummaryUI.floor2(box_w + 1)
    box_h = BushidoSummaryUI.floor2(box_h + 1)

    # Right-align inside the top header, with enough breathing room from frame.
    box_x = BushidoSummaryUI.floor2(486 - box_w)
    box_y = 8

    BushidoSummaryUI.fill2(
      b, box_x, box_y, box_w, box_h,
      BushidoSummaryUI::FRAME
    )
    BushidoSummaryUI.fill2(
      b, box_x+2, box_y+2, box_w-4, box_h-4,
      BushidoSummaryUI::BG
    )

    # Use the measured text height directly. No compression or fixed-height
    # text rectangle, which is what made the previous tooltip look squashed.
    text_y = box_y + pad_y

    pbDrawShadowText(
      b,
      box_x + pad_x,
      text_y,
      text_size.width,
      text_size.height,
      label,
      BushidoSummaryUI::TEXT,
      BushidoSummaryUI::TEXT_SHADOW,
      0
    )
  end

  def drawSummaryBoxText(bitmap, rect, text, align, base, shadow)
    return if !rect || text.nil?

    pbSetSystemFont(bitmap)
    text = text.to_s
    text_h = bitmap.text_size("Ag").height

    # The engine font sits visually high inside a mathematical box. The +2 is
    # intentional and shared everywhere instead of being hand-tuned per row.
    text_y = rect.y + ((rect.height - text_h) / 2) + 2

    pbDrawShadowText(
      bitmap,
      rect.x,
      text_y,
      rect.width,
      text_h,
      text,
      base,
      shadow,
      align
    )
  end

  def drawMoveDescription(bitmap, x, y, width, text, base, shadow)
    pbSetSmallFont(bitmap)

    drawTextEx(
      bitmap,
      x,
      y,
      width,
      4,
      text,
      base,
      shadow
    )
  end

  def insetSummaryRect(rect, left, right)
    return Rect.new(
      rect.x + left,
      rect.y,
      rect.width - left - right,
      rect.height
    )
  end

  def drawSummaryRule(bitmap, rect, color)
    # A separator belongs to the box above it, so its position is always the
    # exact bottom of that box rather than a separately maintained Y value.
    y = BushidoSummaryUI.floor2(rect.y + rect.height)
    BushidoSummaryUI.fill2(bitmap, rect.x, y, rect.width, 2, color)
  end

  def drawBushidoBackground(page, mode=:normal)
    b = @sprites["background"].bitmap
    b.clear

    filename =
      if mode == :move_detail
        "background_move_detail"
      elsif mode == :moves
        "background_moves"
      else
        "background_page_#{page}"
      end

    source = Bitmap.new(BushidoSummaryUI.asset(filename))
    b.blt(0, 0, source, Rect.new(0, 0, source.width, source.height))
    source.dispose

    # Shadow Pokémon keep a dynamic semantic accent. This is data/state-driven,
    # not part of the authored background artwork.
    begin
      if @pokemon && @pokemon.shadowPokemon? && mode == :normal
        BushidoSummaryUI.fill2(
          b, 218, 56, 274, 2,
          BushidoSummaryUI::SHADOW
        )
      end
    rescue
    end
  end

  def summaryPixelsDifferent?(a, b)
    return true if a.red   != b.red
    return true if a.green != b.green
    return true if a.blue  != b.blue
    return true if a.alpha != b.alpha
    return false
  end

  def buildSummaryDiff(old_bitmap, new_bitmap)
    width  = old_bitmap.width
    height = old_bitmap.height

    old_diff = Bitmap.new(width, height)
    new_diff = Bitmap.new(width, height)
    static   = Bitmap.new(width, height)
    static.blt(0, 0, new_bitmap, Rect.new(0, 0, width, height))

    # Work in 2x2 cells. That matches the density of the custom UI and is much
    # cheaper than comparing every pixel individually.
    y = 0
    while y < height
      x = 0
      while x < width
        changed = false

        2.times do |dy|
          break if changed
          next if y + dy >= height

          2.times do |dx|
            next if x + dx >= width

            old_c = old_bitmap.get_pixel(x + dx, y + dy)
            new_c = new_bitmap.get_pixel(x + dx, y + dy)

            if summaryPixelsDifferent?(old_c, new_c)
              changed = true
              break
            end
          end
        end

        if changed
          w = [2, width - x].min
          h = [2, height - y].min
          rect = Rect.new(x, y, w, h)

          old_diff.blt(x, y, old_bitmap, rect)
          new_diff.blt(x, y, new_bitmap, rect)
          static.clear_rect(x, y, w, h)
        end

        x += 2
      end
      y += 2
    end

    return [static, old_diff, new_diff]
  end

  def runSummaryDiffTransition(old_bitmap, new_bitmap, direction=0)
    overlay = @sprites["overlay"]
    return if !overlay

    static, old_diff, new_diff = buildSummaryDiff(old_bitmap, new_bitmap)

    # Unchanged pixels stay on the normal overlay and never fade.
    overlay.bitmap.clear
    overlay.bitmap.blt(
      0, 0, static,
      Rect.new(0, 0, static.width, static.height)
    )

    old_sprite = Sprite.new(@viewport)
    new_sprite = Sprite.new(@viewport)

    old_sprite.bitmap = old_diff
    new_sprite.bitmap = new_diff

    old_sprite.z = overlay.z + 1
    new_sprite.z = overlay.z + 1

    shift = direction * 8
    old_sprite.x = 0
    new_sprite.x = -shift
    new_sprite.opacity = 0

    5.times do |i|
      t = (i + 1).to_f / 5.0

      old_sprite.opacity = (255 * (1.0 - t)).round
      new_sprite.opacity = (255 * t).round

      if shift != 0
        old_sprite.x = (shift * t).round
        new_sprite.x = (-shift + shift * t).round
      end

      Graphics.update
      pbUpdate
    end

    # Put the final complete image back on the real overlay.
    overlay.bitmap.clear
    overlay.bitmap.blt(
      0, 0, new_bitmap,
      Rect.new(0, 0, new_bitmap.width, new_bitmap.height)
    )

    old_sprite.dispose
    new_sprite.dispose
    old_diff.dispose
    new_diff.dispose
    static.dispose
  end

  def animateSummaryPage(direction)
    overlay = @sprites["overlay"]
    return yield if !overlay

    old_bitmap = Bitmap.new(overlay.bitmap.width, overlay.bitmap.height)
    old_bitmap.blt(
      0, 0, overlay.bitmap,
      Rect.new(0, 0, overlay.bitmap.width, overlay.bitmap.height)
    )

    yield if block_given?

    new_bitmap = Bitmap.new(overlay.bitmap.width, overlay.bitmap.height)
    new_bitmap.blt(
      0, 0, overlay.bitmap,
      Rect.new(0, 0, overlay.bitmap.width, overlay.bitmap.height)
    )

    runSummaryDiffTransition(
      old_bitmap,
      new_bitmap,
      direction < 0 ? -1 : 1
    )

    old_bitmap.dispose
    new_bitmap.dispose
  end

  def animateSummaryPokemonSwap
    spr = @sprites["pokemon"]
    overlay = @sprites["overlay"]
    return yield if !spr || !overlay

    old_overlay = Bitmap.new(overlay.bitmap.width, overlay.bitmap.height)
    old_overlay.blt(
      0, 0, overlay.bitmap,
      Rect.new(0, 0, overlay.bitmap.width, overlay.bitmap.height)
    )

    start_x = spr.x

    4.times do |i|
      spr.opacity = 255 - ((i + 1) * 52)
      spr.x = start_x - ((i + 1) * 3)
      Graphics.update
      pbUpdate
    end

    yield if block_given?

    new_overlay = Bitmap.new(overlay.bitmap.width, overlay.bitmap.height)
    new_overlay.blt(
      0, 0, overlay.bitmap,
      Rect.new(0, 0, overlay.bitmap.width, overlay.bitmap.height)
    )

    # Only text/pixels that changed animate. Static labels don't blink.
    runSummaryDiffTransition(old_overlay, new_overlay, 0)

    spr.x = start_x + 12
    spr.opacity = 48

    5.times do |i|
      t = (i + 1).to_f / 5.0
      spr.opacity = (48 + 207 * t).round
      spr.x = (start_x + 12 - 12 * t).round
      Graphics.update
      pbUpdate
    end

    spr.x = start_x
    spr.opacity = 255

    old_overlay.dispose
    new_overlay.dispose
  end

  def drawPage(page)
    if @pokemon.egg?
      drawPageOneEgg; return
    end
    @sprites["itemicon"].item = @pokemon.item
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base = BushidoSummaryUI::TEXT
    shadow = BushidoSummaryUI::TEXT_SHADOW
    drawBushidoBackground(page)

    begin
      accent = BushidoSummaryUI.type_color(@pokemon.type1)
      BushidoSummaryUI.fill2(@sprites["background"].bitmap, 218, 56, 274, 2, accent)
      if @pokemon.type2 && @pokemon.type2 != @pokemon.type1
        BushidoSummaryUI.fill2(@sprites["background"].bitmap, 355, 56, 137, 2,
                               BushidoSummaryUI.type_color(@pokemon.type2))
      end
    rescue
    end

    imagepos=[]
    # Show the Poké Ball containing the Pokémon
    ballimage = sprintf("Graphics/Pictures/Summary/icon_ball_%02d",@pokemon.ballused)
    imagepos.push([ballimage,14,60])
    # Show status/fainted/Pokérus infected icon
    status = -1
    status = 6 if @pokemon.pokerusStage==1
    status = @pokemon.status-1 if @pokemon.status>0
    status = 5 if @pokemon.hp==0
    if status>=0
      imagepos.push(["Graphics/Pictures/statuses",124,100,0,16*status,44,16])
    end
    # Show Pokérus cured icon
    if @pokemon.pokerusStage==2
      imagepos.push([sprintf("Graphics/Pictures/Summary/icon_pokerus"),176,100])
    end
    # Show shininess star
    if @pokemon.shiny?
      imagepos.push([sprintf("Graphics/Pictures/shiny"),2,134])
    end
    # Draw all images
    pbDrawImagePositions(overlay,imagepos)
    # Write various bits of text
    pagename = [_INTL("INFO"),
                _INTL("TRAINER MEMO"),
                _INTL("SKILLS"),
                _INTL("MOVES"),
                _INTL("EV's & IV's")][page-1]
    textpos = [
       [pagename,26,16,0,base,shadow],
       [@pokemon.name,46,62,0,base,shadow],
       ["Lv. #{@pokemon.level}",46,92,0,BushidoSummaryUI::TEXT,BushidoSummaryUI::TEXT_SHADOW],
       [_INTL("Item"),66,304,0,base,shadow]
    ]
    # Write the held item's name
    if @pokemon.hasItem?
      textpos.push([PBItems.getName(@pokemon.item),16,336,0,BushidoSummaryUI::TEXT,BushidoSummaryUI::TEXT_SHADOW])
    else
      textpos.push([_INTL("None"),16,336,0,BushidoSummaryUI::MUTED,BushidoSummaryUI::TEXT_SHADOW])
    end
    # Write the gender symbol
    if @pokemon.male?
      textpos.push([_INTL("♂"),178,62,0,BushidoSummaryUI::MALE,Color.new(136,168,208)])
    elsif @pokemon.female?
      textpos.push([_INTL("♀"),178,62,0,BushidoSummaryUI::FEMALE,Color.new(224,152,144)])
    end
    # Draw all text
    pbDrawTextPositions(overlay,textpos)
    # Draw the Pokémon's markings
    drawMarkings(overlay,84,292)
    # Draw page-specific information
    case page
    when 1; drawPageOne
    when 2; drawPageTwo
    when 3; drawPageThree
    when 4; drawPageFour
    when 5; drawPageFive
    end

    if page == 4
      drawSummaryActionHint(_INTL("ENTER: Reorder"))
    elsif !@inbattle
      drawSummaryActionHint(_INTL("ENTER: Give Item"))
    end
  end

  def drawPageOne
    overlay = @sprites["overlay"].bitmap
    base = BushidoSummaryUI::TEXT
    shadow = BushidoSummaryUI::TEXT_SHADOW
    dexNumBase   = (@pokemon.shiny?) ? BushidoSummaryUI::FEMALE : BushidoSummaryUI::TEXT
    dexNumShadow = (@pokemon.shiny?) ? Color.new(224,152,144) : BushidoSummaryUI::TEXT_SHADOW
    # If a Shadow Pokémon, draw the heart gauge area and bar
    if @pokemon.shadowPokemon?
      shadowfract = @pokemon.heartgauge*1.0/PokeBattle_Pokemon::HEARTGAUGESIZE
      imagepos = [
         ["Graphics/Pictures/Summary/overlay_shadow",224,240],
         ["Graphics/Pictures/Summary/overlay_shadowbar",242,280,0,0,(shadowfract*248).floor,-1]
      ]
      pbDrawImagePositions(overlay,imagepos)
    end
    # Write various bits of text
    textpos = [
       [_INTL("Dex No."),224,80,0,base,shadow],
       [_INTL("Species"),224,112,0,base,shadow],
       [PBSpecies.getName(@pokemon.species),421,112,2,BushidoSummaryUI::TEXT,BushidoSummaryUI::TEXT_SHADOW],
       [_INTL("Type"),224,144,0,base,shadow],
       [_INTL("OT"),224,176,0,base,shadow],
       [_INTL("ID No."),224,208,0,base,shadow],
    ]
    # Write the Regional/National Dex number
    dexnum = @pokemon.species
    dexnumshift = false
    if $PokemonGlobal.pokedexUnlocked[$PokemonGlobal.pokedexUnlocked.length-1]
      dexnumshift = true if DEXES_WITH_OFFSETS.include?(-1)
    else
      dexnum = 0
      for i in 0...$PokemonGlobal.pokedexUnlocked.length-1
        next if !$PokemonGlobal.pokedexUnlocked[i]
        num = pbGetRegionalNumber(i,@pokemon.species)
        next if num<=0
        dexnum = num
        dexnumshift = true if DEXES_WITH_OFFSETS.include?(i)
        break
      end
    end
    if dexnum<=0
      textpos.push(["???",421,80,2,dexNumBase,dexNumShadow])
    else
      dexnum -= 1 if dexnumshift
      textpos.push([sprintf("%03d",dexnum),435,80,2,dexNumBase,dexNumShadow])
    end
    # Write Original Trainer's name and ID number
    if @pokemon.ot==""
      textpos.push([_INTL("RENTAL"),421,176,2,BushidoSummaryUI::TEXT,BushidoSummaryUI::TEXT_SHADOW])
      textpos.push(["?????",421,208,2,BushidoSummaryUI::TEXT,BushidoSummaryUI::TEXT_SHADOW])
    else
      # OT is informational, not a gender callout. Keep it in the Bushido
      # palette so it doesn't compete with semantic stat/type colors.
      ownerbase = BushidoSummaryUI::GOLD
      ownershadow = BushidoSummaryUI::TEXT_SHADOW
      textpos.push([@pokemon.ot,421,176,2,ownerbase,ownershadow])
      textpos.push([sprintf("%05d",@pokemon.publicID),421,208,2,BushidoSummaryUI::TEXT,BushidoSummaryUI::TEXT_SHADOW])
    end
    # Write Exp text OR heart gauge message (if a Shadow Pokémon)
    if @pokemon.shadowPokemon?
      #thundaga add new messaging for shadow lugia here
      if @pokemon.isSpecies?(:LUGIA)
        textpos.push([_INTL("Heart Gauge"),224,240,0,base,shadow])
        heartmessage = [_INTL("The door to its heart will never open..."),
                        _INTL("The door to its heart will never open..."),
                        _INTL("The door to its heart will never open..."),
                        _INTL("The door to its heart will never open..."),
                        _INTL("The door to its heart will never open..."),
                        _INTL("The door to its heart will never open...")][@pokemon.heartStage]
      else
        textpos.push([_INTL("Heart Gauge"),238,240,0,base,shadow])
        heartmessage = [_INTL("The door to its heart is open! Undo the final lock!"),
                        _INTL("The door to its heart is almost fully open."),
                        _INTL("The door to its heart is nearly open."),
                        _INTL("The door to its heart is opening wider."),
                        _INTL("The door to its heart is opening up."),
                        _INTL("The door to its heart is tightly shut.")][@pokemon.heartStage]
      end
      memo = sprintf("<c3=F4E8CF,181210>%s\n",heartmessage)
      drawFormattedTextEx(overlay,234,304,264,memo)
    else
      endexp = PBExperience.pbGetStartExperience(@pokemon.level+1,@pokemon.growthrate)
      textpos.push([_INTL("Exp. Points"),238,240,0,base,shadow])
      textpos.push([@pokemon.exp.to_s_formatted,474,272,1,BushidoSummaryUI::TEXT,BushidoSummaryUI::TEXT_SHADOW])
      textpos.push([_INTL("To Next Lv."),224,304,0,base,shadow])
      textpos.push([(endexp-@pokemon.exp).to_s_formatted,474,336,1,BushidoSummaryUI::TEXT,BushidoSummaryUI::TEXT_SHADOW])
    end
    # Draw all text
    pbDrawTextPositions(overlay,textpos)
    # Draw Pokémon type(s)
    type1rect = Rect.new(0,@pokemon.type1*28,64,28)
    type2rect = Rect.new(0,@pokemon.type2*28,64,28)
    if @pokemon.shadowPokemon?  # Thundaga, making Shadow pokemon use shadow as their type
      type1rect = Rect.new(0,getID(PBTypes,:SHADOW)*28,64,28)
      overlay.blt(388,146,@typebitmap.bitmap,type1rect)
    elsif @pokemon.type1==@pokemon.type2
      overlay.blt(388,146,@typebitmap.bitmap,type1rect)
    else
      overlay.blt(356,146,@typebitmap.bitmap,type1rect)
      overlay.blt(422,146,@typebitmap.bitmap,type2rect)
    end
    # Draw Exp bar
    if @pokemon.level<PBExperience.maxLevel
      w = @pokemon.expFraction*128
      w = ((w/2).round)*2
      pbDrawImagePositions(overlay,[
         ["Graphics/Pictures/Summary/overlay_exp",348,372,0,0,w,6]
      ])
    end
  end

  def drawPageOneEgg
    @sprites["itemicon"].item = @pokemon.item
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    base = BushidoSummaryUI::TEXT
    shadow = BushidoSummaryUI::TEXT_SHADOW
    drawBushidoBackground(2)
    imagepos = []
    # Show the Poké Ball containing the Pokémon
    ballimage = sprintf("Graphics/Pictures/Summary/icon_ball_%02d",@pokemon.ballused)
    imagepos.push([ballimage,14,60])
    # Draw all images
    pbDrawImagePositions(overlay,imagepos)
    # Write various bits of text
    textpos = [
       [_INTL("TRAINER MEMO"),26,16,0,base,shadow],
       [@pokemon.name,46,62,0,base,shadow],
       [_INTL("Item"),66,304,0,base,shadow]
    ]
    # Write the held item's name
    if @pokemon.hasItem?
      textpos.push([PBItems.getName(@pokemon.item),16,336,0,BushidoSummaryUI::TEXT,BushidoSummaryUI::TEXT_SHADOW])
    else
      textpos.push([_INTL("None"),16,336,0,BushidoSummaryUI::MUTED,BushidoSummaryUI::TEXT_SHADOW])
    end
    # Draw all text
    pbDrawTextPositions(overlay,textpos)
    memo = ""
    # Write date received
    if @pokemon.timeReceived
      date  = @pokemon.timeReceived.day
      month = pbGetMonthName(@pokemon.timeReceived.mon)
      year  = @pokemon.timeReceived.year
      memo += _INTL("<c3=F4E8CF,181210>{1} {2}, {3}\n",date,month,year)
    end
    # Write map name egg was received on
    mapname = pbGetMapNameFromId(@pokemon.obtainMap)
    if (@pokemon.obtainText rescue false) && @pokemon.obtainText!=""
      mapname = @pokemon.obtainText
    end
    if mapname && mapname!=""
      memo += _INTL("<c3=F4E8CF,181210>A mysterious Pokémon Egg received from <c3=BC904C,181210>{1}<c3=F4E8CF,181210>.\n",mapname)
    else
      memo += _INTL("<c3=F4E8CF,181210>A mysterious Pokémon Egg.\n",mapname)
    end
    memo += "\n" # Empty line
    # Write Egg Watch blurb
    memo += _INTL("<c3=F4E8CF,181210>\"The Egg Watch\"\n")
    eggstate = _INTL("It looks like this Egg will take a long time to hatch.")
    eggstate = _INTL("What will hatch from this? It doesn't seem close to hatching.") if @pokemon.eggsteps<10200
    eggstate = _INTL("It appears to move occasionally. It may be close to hatching.") if @pokemon.eggsteps<2550
    eggstate = _INTL("Sounds can be heard coming from inside! It will hatch soon!") if @pokemon.eggsteps<1275
    memo += sprintf("<c3=F4E8CF,181210>%s\n",eggstate)
    # Draw all text
    drawFormattedTextEx(overlay,232,78,268,memo)
    # Draw the Pokémon's markings
    drawMarkings(overlay,84,292)
  end

  def drawPageTwo
    overlay = @sprites["overlay"].bitmap
    memo = ""
    # Write nature
    showNature = !@pokemon.shadowPokemon? || @pokemon.heartStage>3
    if showNature
      natureName = PBNatures.getName(@pokemon.nature)
      memo += _INTL("<c3=E05C46,181210>{1}<c3=F4E8CF,181210> nature.\n",natureName)
    end
    # Write date received
    if @pokemon.timeReceived
      date  = @pokemon.timeReceived.day
      month = pbGetMonthName(@pokemon.timeReceived.mon)
      year  = @pokemon.timeReceived.year
      memo += _INTL("<c3=F4E8CF,181210>{1} {2}, {3}\n",date,month,year)
    end
    # Write map name Pokémon was received on
    mapname = pbGetMapNameFromId(@pokemon.obtainMap)
    if (@pokemon.obtainText rescue false) && @pokemon.obtainText!=""
      mapname = @pokemon.obtainText
    end
    mapname = _INTL("Faraway place") if !mapname || mapname==""
    memo += sprintf("<c3=BC904C,181210>%s\n",mapname)
    # Write how Pokémon was obtained
    mettext = [_INTL("Met at Lv. {1}.",@pokemon.obtainLevel),
               _INTL("Egg received."),
               _INTL("Traded at Lv. {1}.",@pokemon.obtainLevel),
               "",
               _INTL("Had a fateful encounter at Lv. {1}.",@pokemon.obtainLevel)
              ][@pokemon.obtainMode]
    memo += sprintf("<c3=F4E8CF,181210>%s\n",mettext) if mettext && mettext!=""
    # If Pokémon was hatched, write when and where it hatched
    if @pokemon.obtainMode==1
      if @pokemon.timeEggHatched
        date  = @pokemon.timeEggHatched.day
        month = pbGetMonthName(@pokemon.timeEggHatched.mon)
        year  = @pokemon.timeEggHatched.year
        memo += _INTL("<c3=F4E8CF,181210>{1} {2}, {3}\n",date,month,year)
      end
      mapname = pbGetMapNameFromId(@pokemon.hatchedMap)
      mapname = _INTL("Faraway place") if !mapname || mapname==""
      memo += sprintf("<c3=BC904C,181210>%s\n",mapname)
      memo += _INTL("<c3=F4E8CF,181210>Egg hatched.\n")
    else
      memo += "\n"   # Empty line
    end
    # Write characteristic
    if showNature
      bestiv     = 0
      tiebreaker = @pokemon.personalID%6
      for i in 0...6
        if @pokemon.iv[i]==@pokemon.iv[bestiv]
          bestiv = i if i>=tiebreaker && bestiv<tiebreaker
        elsif @pokemon.iv[i]>@pokemon.iv[bestiv]
          bestiv = i
        end
      end
      characteristic = [_INTL("Loves to eat."),
                        _INTL("Often dozes off."),
                        _INTL("Often scatters things."),
                        _INTL("Scatters things often."),
                        _INTL("Likes to relax."),
                        _INTL("Proud of its power."),
                        _INTL("Likes to thrash about."),
                        _INTL("A little quick tempered."),
                        _INTL("Likes to fight."),
                        _INTL("Quick tempered."),
                        _INTL("Sturdy body."),
                        _INTL("Capable of taking hits."),
                        _INTL("Highly persistent."),
                        _INTL("Good endurance."),
                        _INTL("Good perseverance."),
                        _INTL("Likes to run."),
                        _INTL("Alert to sounds."),
                        _INTL("Impetuous and silly."),
                        _INTL("Somewhat of a clown."),
                        _INTL("Quick to flee."),
                        _INTL("Highly curious."),
                        _INTL("Mischievous."),
                        _INTL("Thoroughly cunning."),
                        _INTL("Often lost in thought."),
                        _INTL("Very finicky."),
                        _INTL("Strong willed."),
                        _INTL("Somewhat vain."),
                        _INTL("Strongly defiant."),
                        _INTL("Hates to lose."),
                        _INTL("Somewhat stubborn.")
                       ][bestiv*5+@pokemon.iv[bestiv]%5]
      memo += sprintf("<c3=F4E8CF,181210>%s\n",characteristic)
    end
    # Write all text
    drawFormattedTextEx(overlay,232,78,268,memo)
  end

  def drawPageThree
    overlay = @sprites["overlay"].bitmap
    base = BushidoSummaryUI::TEXT
    shadow = BushidoSummaryUI::TEXT_SHADOW
    layout = BushidoSummaryUI.skills_layout

    statbases = []
    statshadows = []
    PBStats.eachStat do |s|
      statbases[s] = base
      statshadows[s] = shadow
    end

    if !@pokemon.shadowPokemon? || @pokemon.heartStage > 3
      natup = PBNatures.getStatRaised(@pokemon.calcNature)
      natdn = PBNatures.getStatLowered(@pokemon.calcNature)

      if natup != natdn
        statbases[natup] = BushidoSummaryUI::NATURE_UP
        statbases[natdn] = BushidoSummaryUI::NATURE_DOWN
      end
    end

    # HP owns one box. Label, value and bar are all children of that box.
    hp_box = layout[:hp]
    hp_label = Rect.new(hp_box.x + 8, hp_box.y, 70, hp_box.height)
    hp_value = Rect.new(hp_box.x + 116, hp_box.y, 112, hp_box.height - 10)

    drawSummaryBoxText(
      overlay, hp_label, _INTL("HP"), 1,
      statbases[PBStats::HP], statshadows[PBStats::HP]
    )
    drawSummaryBoxText(
      overlay, hp_value,
      sprintf("%d/%d", @pokemon.hp, @pokemon.totalhp),
      1, base, shadow
    )

    if @pokemon.hp > 0
      bar_x = hp_box.x + 116
      bar_y = hp_box.y + hp_box.height - 8
      bar_w = 112
      bar_h = 6

      BushidoSummaryUI.fill2(
        overlay, bar_x, bar_y, bar_w, bar_h,
        Color.new(48, 42, 38)
      )

      fill = (@pokemon.hp * bar_w.to_f / @pokemon.totalhp).round
      fill = 2 if fill < 2
      fill = BushidoSummaryUI.floor2(fill)

      hp_color = Color.new(24,192,32)
      hp_color = Color.new(248,192,0) if @pokemon.hp <= (@pokemon.totalhp / 2).floor
      hp_color = Color.new(248,72,72) if @pokemon.hp <= (@pokemon.totalhp / 4).floor

      BushidoSummaryUI.fill2(
        overlay, bar_x, bar_y, fill, bar_h, hp_color
      )
    end

    stat_data = [
      [_INTL("Attack"),  @pokemon.attack,  PBStats::ATTACK],
      [_INTL("Defense"), @pokemon.defense, PBStats::DEFENSE],
      [_INTL("Sp. Atk"), @pokemon.spatk,   PBStats::SPATK],
      [_INTL("Sp. Def"), @pokemon.spdef,   PBStats::SPDEF],
      [_INTL("Speed"),   @pokemon.speed,   PBStats::SPEED]
    ]

    layout[:stats].each_with_index do |row, i|
      label, value, stat = stat_data[i]

      label_box = Rect.new(row.x + 8, row.y, 142, row.height)
      value_box = Rect.new(row.x + 158, row.y, 70, row.height)

      drawSummaryBoxText(
        overlay, label_box, label, 0,
        statbases[stat], statshadows[stat]
      )
      drawSummaryBoxText(
        overlay, value_box, value.to_s, 1,
        base, shadow
      )
    end

    # Ability is isolated from the stat table, so Speed can never bleed into it.
    ability = layout[:ability]
    ability_label = Rect.new(ability.x, ability.y, 112, ability.height)
    ability_value = Rect.new(ability.x + 112, ability.y, 152, ability.height)

    drawSummaryBoxText(
      overlay, ability_label, _INTL("Ability"), 0,
      base, shadow
    )

    ability_color = @pokemon.hasHiddenAbility? ?
                    Color.new(176,112,232) : base

    drawSummaryBoxText(
      overlay, ability_value,
      PBAbilities.getName(@pokemon.ability),
      1, ability_color, shadow
    )

    abilitydesc = pbGetMessage(MessageTypes::AbilityDescs, @pokemon.ability)
    desc = layout[:desc]

    drawTextEx(
      overlay,
      desc.x,
      desc.y + 4,
      desc.width,
      2,
      abilitydesc,
      base,
      shadow
    )
  end

  def drawPageFour
    overlay = @sprites["overlay"].bitmap
    moveBase   = BushidoSummaryUI::TEXT
    moveShadow = BushidoSummaryUI::TEXT_SHADOW
    ppBase   = [moveBase,                # More than 1/2 of total PP
                Color.new(248,192,0),    # 1/2 of total PP or less
                Color.new(248,136,32),   # 1/4 of total PP or less
                Color.new(248,72,72)]    # Zero PP
    ppShadow = [moveShadow,             # More than 1/2 of total PP
                Color.new(144,104,0),   # 1/2 of total PP or less
                Color.new(144,72,24),   # 1/4 of total PP or less
                Color.new(136,48,48)]   # Zero PP
    @sprites["pokemon"].visible  = true
    @sprites["pokeicon"].visible = false
    @sprites["itemicon"].visible = true
    textpos  = []
    imagepos = []
    # Write move names, types and PP amounts for each known move
    yPos = 98
    for i in 0...@pokemon.moves.length
      move=@pokemon.moves[i]
      if move.id>0
        imagepos.push(["Graphics/Pictures/types",248,yPos+2,0,move.type*28,64,28])
        textpos.push([PBMoves.getName(move.id),316,yPos,0,moveBase,moveShadow])
        if move.totalpp>0
          textpos.push([_INTL("PP"),350,yPos+32,0,moveBase,moveShadow])
          ppfraction = 0
          if move.pp==0;                 ppfraction = 3
          elsif move.pp*4<=move.totalpp; ppfraction = 2
          elsif move.pp*2<=move.totalpp; ppfraction = 1
          end
          textpos.push([sprintf("%d/%d",move.pp,move.totalpp),470,yPos+32,1,ppBase[ppfraction],ppShadow[ppfraction]])
        end
      else
        textpos.push(["-",316,yPos,0,moveBase,moveShadow])
        textpos.push(["--",442,yPos+32,1,moveBase,moveShadow])
      end
      yPos += 64
    end
    # Draw all text and images
    pbDrawTextPositions(overlay,textpos)
    pbDrawImagePositions(overlay,imagepos)
  end

  def drawSelectedMove(moveToLearn, moveid)
    drawMoveSelection(moveToLearn)

    overlay = @sprites["overlay"].bitmap
    layout = BushidoSummaryUI.move_mode_layout
    base = BushidoSummaryUI::TEXT
    shadow = BushidoSummaryUI::TEXT_SHADOW

    # Move inspection owns the left column. Hide the Pokemon/icon/item instead
    # of leaving their old layout space empty.
    @sprites["pokemon"].visible = false if @sprites["pokemon"]
    @sprites["pokeicon"].visible = false if @sprites["pokeicon"]
    @sprites["itemicon"].visible = false if @sprites["itemicon"]

    return if !moveid || moveid <= 0

    data = pbGetMoveData(moveid)
    power = data[MOVE_BASE_DAMAGE]
    category = data[MOVE_CATEGORY]
    accuracy = data[MOVE_ACCURACY]
    type = data[MOVE_TYPE]

    # TYPE
    type_box = layout[:type]
    drawSummaryBoxText(
      overlay,
      Rect.new(type_box.x+4, type_box.y, 76, type_box.height),
      _INTL("TYPE"),
      0,
      BushidoSummaryUI::GOLD,
      shadow
    )

    begin
      type_rect = Rect.new(0, type * 28, 64, 28)
      overlay.blt(
        type_box.x + 94,
        type_box.y,
        @typebitmap.bitmap,
        type_rect
      )
    rescue
      drawSummaryBoxText(
        overlay,
        Rect.new(type_box.x+88, type_box.y, 68, type_box.height),
        PBTypes.getName(type),
        1,
        BushidoSummaryUI.type_color(type),
        shadow
      )
    end

    # CATEGORY
    category_box = layout[:category]
    drawSummaryBoxText(
      overlay,
      Rect.new(category_box.x+4, category_box.y, 88, category_box.height),
      _INTL("CATEGORY"),
      0,
      BushidoSummaryUI::GOLD,
      shadow
    )

    begin
      cat_rect = Rect.new(0, category * 28, 64, 28)
      cat_bitmap = pbBitmap("Graphics/Pictures/category")
      overlay.blt(
        category_box.x + 94,
        category_box.y,
        cat_bitmap,
        cat_rect
      )
    rescue
    end

    # POWER
    power_text =
      if power == 0
        "---"
      elsif power == 1
        "???"
      else
        power.to_s
      end

    drawSummaryBoxText(
      overlay,
      Rect.new(layout[:power].x+4, layout[:power].y, 88, layout[:power].height),
      _INTL("POWER"),
      0,
      BushidoSummaryUI::GOLD,
      shadow
    )
    drawSummaryBoxText(
      overlay,
      Rect.new(layout[:power].x+96, layout[:power].y, 60, layout[:power].height),
      power_text,
      1,
      base,
      shadow
    )

    # ACCURACY
    acc_text = accuracy == 0 ? "---" : sprintf("%d%%", accuracy)

    drawSummaryBoxText(
      overlay,
      Rect.new(layout[:accuracy].x+4, layout[:accuracy].y, 88, layout[:accuracy].height),
      _INTL("ACCURACY"),
      0,
      BushidoSummaryUI::GOLD,
      shadow
    )
    drawSummaryBoxText(
      overlay,
      Rect.new(layout[:accuracy].x+96, layout[:accuracy].y, 60, layout[:accuracy].height),
      acc_text,
      1,
      base,
      shadow
    )

    # DESCRIPTION
    desc = layout[:description]
    move_desc = pbGetMessage(MessageTypes::MoveDescriptions, moveid)

    drawMoveDescription(
      overlay,
      desc.x + 6,
      desc.y + 8,
      desc.width - 12,
      move_desc,
      base,
      shadow
    )

    drawSummaryActionHint(
      @move_switching ?
      _INTL("ENTER: Place") :
      _INTL("ENTER: Select")
    )
  end

  def drawMoveSelection(moveToLearn)
    overlay = @sprites["overlay"].bitmap
    overlay.clear

    layout = BushidoSummaryUI.move_mode_layout
    drawBushidoBackground(4, :move_detail)

    base = BushidoSummaryUI::TEXT
    shadow = BushidoSummaryUI::TEXT_SHADOW

    drawSummaryBoxText(
      overlay,
      Rect.new(26, 14, 164, 34),
      _INTL("MOVES"),
      0,
      base,
      shadow
    )

    list = layout[:list]
    row_h = layout[:row_height]

    entries = []
    @pokemon.moves.each do |move|
      entries.push(move) if move && move.id > 0
    end

    learning_move = moveToLearn && moveToLearn > 0
    entries.push(PBMove.new(moveToLearn)) if learning_move

    # Four rows fit the authored Bushido move-detail background. When learning
    # a fifth move, scroll the list instead of squeezing five rows together.
    offset = learning_move ? (@move_scroll_offset || 0) : 0
    visible_entries = entries[offset,4] || []

    visible_entries.each_with_index do |move,i|
      row = Rect.new(
        list.x,
        list.y + (i * row_h),
        list.width,
        row_h
      )

      begin
        type_rect = Rect.new(0, move.type * 28, 64, 28)
        overlay.blt(
          row.x + 12,
          row.y + 10,
          @typebitmap.bitmap,
          type_rect
        )
      rescue
      end

      drawSummaryBoxText(
        overlay,
        Rect.new(row.x + 82, row.y, 112, row.height),
        PBMoves.getName(move.id),
        0,
        base,
        shadow
      )

      pp_text = sprintf("%d/%d",move.pp,move.totalpp)

      drawSummaryBoxText(
        overlay,
        Rect.new(row.x + 194, row.y, 60, row.height),
        pp_text,
        1,
        base,
        shadow
      )
    end
  end

  def drawPageFive
    overlay = @sprites["overlay"].bitmap
    base = BushidoSummaryUI::TEXT
    shadow = BushidoSummaryUI::TEXT_SHADOW
    layout = BushidoSummaryUI.ev_layout

    statbases = []
    statshadows = []
    PBStats.eachStat do |s|
      statbases[s] = base
      statshadows[s] = shadow
    end

    if !@pokemon.shadowPokemon? || @pokemon.heartStage > 3
      natup = PBNatures.getStatRaised(@pokemon.calcNature)
      natdn = PBNatures.getStatLowered(@pokemon.calcNature)

      if natup != natdn
        statbases[natup] = BushidoSummaryUI::NATURE_UP
        statbases[natdn] = BushidoSummaryUI::NATURE_DOWN
      end
    end

    # Column headers live entirely inside the header box.
    header = layout[:header]
    ev_header = Rect.new(layout[:ev_x], header.y, layout[:ev_w], header.height)
    iv_header = Rect.new(layout[:iv_x], header.y, layout[:iv_w], header.height)

    drawSummaryBoxText(overlay, ev_header, _INTL("EV"), 1, base, shadow)
    drawSummaryBoxText(overlay, iv_header, _INTL("IV"), 1, base, shadow)

    stat_data = [
      [_INTL("HP"),      @pokemon.ev[0], @pokemon.iv[0], PBStats::HP],
      [_INTL("Attack"),  @pokemon.ev[1], @pokemon.iv[1], PBStats::ATTACK],
      [_INTL("Defense"), @pokemon.ev[2], @pokemon.iv[2], PBStats::DEFENSE],
      [_INTL("Sp. Atk"), @pokemon.ev[4], @pokemon.iv[4], PBStats::SPATK],
      [_INTL("Sp. Def"), @pokemon.ev[5], @pokemon.iv[5], PBStats::SPDEF],
      [_INTL("Speed"),   @pokemon.ev[3], @pokemon.iv[3], PBStats::SPEED]
    ]

    layout[:stats].each_with_index do |row, i|
      label, ev, iv, stat = stat_data[i]

      label_box = Rect.new(
        layout[:label_x], row.y,
        layout[:label_w], row.height
      )
      ev_box = Rect.new(
        layout[:ev_x], row.y,
        layout[:ev_w], row.height
      )
      iv_box = Rect.new(
        layout[:iv_x], row.y,
        layout[:iv_w], row.height
      )

      drawSummaryBoxText(
        overlay, label_box, label, 1,
        statbases[stat], statshadows[stat]
      )
      drawSummaryBoxText(
        overlay, ev_box, ev.to_s, 1,
        base, shadow
      )
      drawSummaryBoxText(
        overlay, iv_box, iv.to_s, 1,
        base, shadow
      )
    end

    # Ability is a separate box below the table, never part of the Speed row.
    ability = layout[:ability]
    ability_label = Rect.new(ability.x, ability.y, 112, ability.height)
    ability_value = Rect.new(ability.x + 112, ability.y, 152, ability.height)

    drawSummaryBoxText(
      overlay, ability_label, _INTL("Ability"), 0,
      base, shadow
    )

    ability_color = @pokemon.abilityIndex < 2 ?
                    base : Color.new(176,112,232)

    drawSummaryBoxText(
      overlay, ability_value,
      PBAbilities.getName(@pokemon.ability),
      1, ability_color, shadow
    )

    abilitydesc = pbGetMessage(MessageTypes::AbilityDescs, @pokemon.ability)
    desc = layout[:desc]

    drawTextEx(
      overlay,
      desc.x,
      desc.y + 4,
      desc.width,
      2,
      abilitydesc,
      base,
      shadow
    )
  end

  def drawSelectedRibbon(ribbonid)
    # Draw all of page five
    drawPage(5)
    # Set various values
    overlay = @sprites["overlay"].bitmap
    base   = BushidoSummaryUI::TEXT
    shadow = BushidoSummaryUI::TEXT_SHADOW
    nameBase   = Color.new(248,248,248)
    nameShadow = Color.new(104,104,104)
    # Get data for selected ribbon
    name = ribbonid ? PBRibbons.getName(ribbonid) : ""
    desc = ribbonid ? PBRibbons.getDescription(ribbonid) : ""
    # Draw the description box
    imagepos = [
       ["Graphics/Pictures/Summary/overlay_ribbon",8,280]
    ]
    pbDrawImagePositions(overlay,imagepos)
    # Draw name of selected ribbon
    textpos = [
       [name,18,286,0,nameBase,nameShadow]
    ]
    pbDrawTextPositions(overlay,textpos)
    # Draw selected ribbon's description
    drawTextEx(overlay,18,318,480,2,desc,base,shadow)
  end

  def pbGoToPrevious
    newindex = @partyindex
    while newindex>0
      newindex -= 1
      if @party[newindex] && (@page==1 || !@party[newindex].egg?)
        @partyindex = newindex
        break
      end
    end
  end

  def pbGoToNext
    newindex = @partyindex
    while newindex<@party.length-1
      newindex += 1
      if @party[newindex] && (@page==1 || !@party[newindex].egg?)
        @partyindex = newindex
        break
      end
    end
  end

  def pbChangePokemon
    animateSummaryPokemonSwap do
      @pokemon = @party[@partyindex]
      @sprites["pokemon"].setPokemonBitmap(@pokemon)
      @sprites["itemicon"].item = @pokemon.item
      drawPage(@page)
    end

    pbSEStop
    pbPlayCry(@pokemon)
  end

  def positionMoveCursors(selmove, oldselmove=nil)
    layout = BushidoSummaryUI.move_mode_layout
    list = layout[:list]
    row_h = layout[:row_height]

    # The learning screen shows four rows at once and scrolls when the fifth
    # "new move" entry is selected. Normal move reordering has no scroll.
    offset =
      if @move_to_learn && @move_to_learn > 0
        @move_scroll_offset || 0
      else
        0
      end

    if @sprites["movesel"]
      display_index = selmove - offset
      display_index = 0 if display_index < 0
      display_index = 3 if display_index > 3

      @sprites["movesel"].x = list.x
      @sprites["movesel"].y = list.y + (display_index * row_h)
      @sprites["movesel"].index = selmove
    end

    if @sprites["movepresel"] && !oldselmove.nil?
      @sprites["movepresel"].x = list.x
      @sprites["movepresel"].y = list.y + (oldselmove * row_h)
      @sprites["movepresel"].index = oldselmove
    end
  end

  def pbMoveSelection
    @sprites["movesel"].visible = true
    @sprites["movesel"].index   = 0
    selmove    = 0
    oldselmove = 0
    switching = false
    @move_switching = false
    drawSelectedMove(0,@pokemon.moves[selmove].id)
    positionMoveCursors(selmove, oldselmove)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["movepresel"].index==@sprites["movesel"].index
        @sprites["movepresel"].z = @sprites["movesel"].z+1
      else
        @sprites["movepresel"].z = @sprites["movesel"].z
      end
      if Input.trigger?(Input::B)
        (switching) ? pbPlayCancelSE : pbPlayCloseMenuSE
        break if !switching
        @sprites["movepresel"].visible = false
        switching = false
        @move_switching = false
        positionMoveCursors(selmove, oldselmove)
        drawSelectedMove(0,@pokemon.moves[selmove].id)
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE
        if selmove==4
          break if !switching
          @sprites["movepresel"].visible = false
          switching = false
        else
          if !@pokemon.shadowPokemon?
            if !switching
              @sprites["movepresel"].index   = selmove
              @sprites["movepresel"].visible = true
              oldselmove = selmove
              switching = true
              @move_switching = true
              positionMoveCursors(selmove, oldselmove)
              drawSelectedMove(0,@pokemon.moves[selmove].id)
            else
              tmpmove                    = @pokemon.moves[oldselmove]
              @pokemon.moves[oldselmove] = @pokemon.moves[selmove]
              @pokemon.moves[selmove]    = tmpmove
              @sprites["movepresel"].visible = false
              switching = false
              @move_switching = false
              positionMoveCursors(selmove, oldselmove)
              drawSelectedMove(0,@pokemon.moves[selmove].id)
            end
          end
        end
      elsif Input.trigger?(Input::UP)
        selmove -= 1
        if selmove<4 && selmove>=@pokemon.numMoves
          selmove = @pokemon.numMoves-1
        end
        selmove = 0 if selmove>=4
        selmove = @pokemon.numMoves-1 if selmove<0
        @sprites["movesel"].index = selmove
        positionMoveCursors(selmove, oldselmove)
        newmove = @pokemon.moves[selmove].id
        pbPlayCursorSE
        drawSelectedMove(0,newmove)
      elsif Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove<4 && selmove>=@pokemon.numMoves
        selmove = 0 if selmove>=4
        selmove = 4 if selmove<0
        @sprites["movesel"].index = selmove
        positionMoveCursors(selmove, oldselmove)
        newmove = @pokemon.moves[selmove].id
        pbPlayCursorSE
        drawSelectedMove(0,newmove)
      end
    end
    @sprites["movesel"].visible=false
    @sprites["movepresel"].visible=false
    @move_switching = false
  end

  def pbRibbonSelection
    @sprites["ribbonsel"].visible = true
    @sprites["ribbonsel"].index   = 0
    selribbon    = @ribbonOffset*4
    oldselribbon = selribbon
    switching = false
    numRibbons = @pokemon.ribbons.length
    numRows    = [((numRibbons+3)/4).floor,3].max
    drawSelectedRibbon(@pokemon.ribbons[selribbon])
    loop do
      @sprites["uparrow"].visible   = (@ribbonOffset>0)
      @sprites["downarrow"].visible = (@ribbonOffset<numRows-3)
      Graphics.update
      Input.update
      pbUpdate
      if @sprites["ribbonpresel"].index==@sprites["ribbonsel"].index
        @sprites["ribbonpresel"].z = @sprites["ribbonsel"].z+1
      else
        @sprites["ribbonpresel"].z = @sprites["ribbonsel"].z
      end
      hasMovedCursor = false
      if Input.trigger?(Input::B)
        (switching) ? pbPlayCancelSE : pbPlayCloseMenuSE
        break if !switching
        @sprites["ribbonpresel"].visible = false
        switching = false
      elsif Input.trigger?(Input::C)
        if !switching
          if @pokemon.ribbons[selribbon]
            pbPlayDecisionSE
            @sprites["ribbonpresel"].index = selribbon-@ribbonOffset*4
            oldselribbon = selribbon
            @sprites["ribbonpresel"].visible = true
            switching = true
          end
        else
          pbPlayDecisionSE
          tmpribbon                      = @pokemon.ribbons[oldselribbon]
          @pokemon.ribbons[oldselribbon] = @pokemon.ribbons[selribbon]
          @pokemon.ribbons[selribbon]    = tmpribbon
          if @pokemon.ribbons[oldselribbon] || @pokemon.ribbons[selribbon]
            @pokemon.ribbons.compact!
            if selribbon>=numRibbons
              selribbon = numRibbons-1
              hasMovedCursor = true
            end
          end
          @sprites["ribbonpresel"].visible = false
          switching = false
          drawSelectedRibbon(@pokemon.ribbons[selribbon])
        end
      elsif Input.trigger?(Input::UP)
        selribbon -= 4
        selribbon += numRows*4 if selribbon<0
        hasMovedCursor = true
        pbPlayCursorSE
      elsif Input.trigger?(Input::DOWN)
        selribbon += 4
        selribbon -= numRows*4 if selribbon>=numRows*4
        hasMovedCursor = true
        pbPlayCursorSE
      elsif Input.trigger?(Input::LEFT)
        selribbon -= 1
        selribbon += 4 if selribbon%4==3
        hasMovedCursor = true
        pbPlayCursorSE
      elsif Input.trigger?(Input::RIGHT)
        selribbon += 1
        selribbon -= 4 if selribbon%4==0
        hasMovedCursor = true
        pbPlayCursorSE
      end
      if hasMovedCursor
        @ribbonOffset = (selribbon/4).floor if selribbon<@ribbonOffset*4
        @ribbonOffset = (selribbon/4).floor-2 if selribbon>=(@ribbonOffset+3)*4
        @ribbonOffset = 0 if @ribbonOffset<0
        @ribbonOffset = numRows-3 if @ribbonOffset>numRows-3
        @sprites["ribbonsel"].index    = selribbon-@ribbonOffset*4
        @sprites["ribbonpresel"].index = oldselribbon-@ribbonOffset*4
        drawSelectedRibbon(@pokemon.ribbons[selribbon])
      end
    end
    @sprites["ribbonsel"].visible = false
  end

  def pbMarking(pokemon)
    @sprites["markingbg"].visible      = true
    @sprites["markingoverlay"].visible = true
    @sprites["markingsel"].visible     = true
    base = BushidoSummaryUI::TEXT
    shadow = BushidoSummaryUI::TEXT_SHADOW
    ret = pokemon.markings
    markings = pokemon.markings
    index = 0
    redraw = true
    markrect = Rect.new(0,0,16,16)
    loop do
      # Redraw the markings and text
      if redraw
        @sprites["markingoverlay"].bitmap.clear
        for i in 0...6
          markrect.x = i*16
          markrect.y = (markings&(1<<i)!=0) ? 16 : 0
          @sprites["markingoverlay"].bitmap.blt(300+58*(i%3),154+50*(i/3),@markingbitmap.bitmap,markrect)
        end
        textpos = [
           [_INTL("Mark {1}",pokemon.name),366,96,2,base,shadow],
           [_INTL("OK"),366,248,2,base,shadow],
           [_INTL("Cancel"),366,298,2,base,shadow]
        ]
        pbDrawTextPositions(@sprites["markingoverlay"].bitmap,textpos)
        redraw = false
      end
      # Reposition the cursor
      @sprites["markingsel"].x = 284+58*(index%3)
      @sprites["markingsel"].y = 144+50*(index/3)
      if index==6   # OK
        @sprites["markingsel"].x = 284
        @sprites["markingsel"].y = 244
        @sprites["markingsel"].src_rect.y = @sprites["markingsel"].bitmap.height/2
      elsif index==7   # Cancel
        @sprites["markingsel"].x = 284
        @sprites["markingsel"].y = 294
        @sprites["markingsel"].src_rect.y = @sprites["markingsel"].bitmap.height/2
      else
        @sprites["markingsel"].src_rect.y = 0
      end
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE
        if index==6   # OK
          ret = markings
          break
        elsif index==7   # Cancel
          break
        else
          mask = (1<<index)
          if (markings&mask)==0
            markings |= mask
          else
            markings &= ~mask
          end
          redraw = true
        end
      elsif Input.trigger?(Input::UP)
        if index==7;    index = 6
        elsif index==6; index = 4
        elsif index<3;  index = 7
        else;           index -= 3
        end
        pbPlayCursorSE
      elsif Input.trigger?(Input::DOWN)
        if index==7;    index = 1
        elsif index==6; index = 7
        elsif index>=3; index = 6
        else;           index += 3
        end
        pbPlayCursorSE
      elsif Input.trigger?(Input::LEFT)
        if index<6
          index -= 1
          index += 3 if index%3==2
          pbPlayCursorSE
        end
      elsif Input.trigger?(Input::RIGHT)
        if index<6
          index += 1
          index -= 3 if index%3==0
          pbPlayCursorSE
        end
      end
    end
    @sprites["markingbg"].visible      = false
    @sprites["markingoverlay"].visible = false
    @sprites["markingsel"].visible     = false
    if pokemon.markings!=ret
      pokemon.markings = ret
      return true
    end
    return false
  end

  def pbOptions
    dorefresh = false
    commands   = []
    cmdGiveItem = -1
    cmdTakeItem = -1
    cmdPokedex  = -1
    cmdMark     = -1
    if !@pokemon.egg?
      commands[cmdGiveItem = commands.length] = _INTL("Give item")
      commands[cmdTakeItem = commands.length] = _INTL("Take item") if @pokemon.hasItem?
      commands[cmdPokedex = commands.length]  = _INTL("View Pokédex") if $Trainer.pokedex
    end
    commands[commands.length]                 = _INTL("Cancel")
    command = pbShowCommands(commands)
    if cmdGiveItem>=0 && command==cmdGiveItem
      item = 0
      pbFadeOutIn {
        scene = PokemonBag_Scene.new
        screen = PokemonBagScreen.new(scene,$PokemonBag)
        item = screen.pbChooseItemScreen(Proc.new { |itm| pbCanHoldItem?(itm) })
      }
      if item>0
        dorefresh = pbGiveItemToPokemon(item,@pokemon,self,@partyindex)
      end
    elsif cmdTakeItem>=0 && command==cmdTakeItem
      dorefresh = pbTakeItemFromPokemon(@pokemon,self)
    elsif cmdPokedex>=0 && command==cmdPokedex
      pbUpdateLastSeenForm(@pokemon)
      pbFadeOutIn {
        scene = PokemonPokedexInfo_Scene.new
        screen = PokemonPokedexInfoScreen.new(scene)
        screen.pbStartSceneSingle(@pokemon.species)
      }
      dorefresh = true
    elsif cmdMark>=0 && command==cmdMark
      dorefresh = pbMarking(@pokemon)
    end
    return dorefresh
  end

  def pbChooseMoveToForget(moveToLearn)
    selmove = 0
    maxmove = (moveToLearn>0) ? 4 : 3

    @move_to_learn = moveToLearn
    @move_scroll_offset = 0

    positionMoveCursors(selmove)

    loop do
      Graphics.update
      Input.update
      pbUpdate

      if Input.trigger?(Input::B)
        selmove = 4
        pbPlayCloseMenuSE if moveToLearn>0
        break

      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE
        break

      elsif Input.trigger?(Input::UP)
        selmove -= 1
        selmove = maxmove if selmove<0

        if selmove<4 && selmove>=@pokemon.numMoves
          selmove = @pokemon.numMoves-1
        end

        # Keep four visible rows. The fifth entry appears by scrolling the
        # window down one row; scrolling back to the first entry restores it.
        if moveToLearn>0
          @move_scroll_offset = 1 if selmove==4
          @move_scroll_offset = 0 if selmove==0
        end

        @sprites["movesel"].index = selmove
        positionMoveCursors(selmove)

        newmove = (selmove==4) ? moveToLearn : @pokemon.moves[selmove].id

        pbPlayCursorSE
        drawSelectedMove(moveToLearn,newmove)

      elsif Input.trigger?(Input::DOWN)
        selmove += 1
        selmove = 0 if selmove>maxmove

        if selmove<4 && selmove>=@pokemon.numMoves
          selmove = (moveToLearn>0) ? maxmove : 0
        end

        if moveToLearn>0
          @move_scroll_offset = 1 if selmove==4
          @move_scroll_offset = 0 if selmove==0
        end

        @sprites["movesel"].index = selmove
        positionMoveCursors(selmove)

        newmove = (selmove==4) ? moveToLearn : @pokemon.moves[selmove].id

        pbPlayCursorSE
        drawSelectedMove(moveToLearn,newmove)
      end
    end

    return (selmove==4) ? -1 : selmove
  end

  def pbScene
    pbPlayCry(@pokemon)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      dorefresh = false
      if Input.trigger?(Input::A)
        pbSEStop
        pbPlayCry(@pokemon)
      elsif Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::C)
        if @page==4
          pbPlayDecisionSE
          pbMoveSelection
          dorefresh = true
        elsif !@inbattle
          pbPlayDecisionSE
          dorefresh = pbOptions
        end
      elsif Input.trigger?(Input::UP) && @partyindex>0
        oldindex = @partyindex
        pbGoToPrevious
        if @partyindex!=oldindex
          pbChangePokemon
          @ribbonOffset = 0
          dorefresh = false
        end
      elsif Input.trigger?(Input::DOWN) && @partyindex<@party.length-1
        oldindex = @partyindex
        pbGoToNext
        if @partyindex!=oldindex
          pbChangePokemon
          @ribbonOffset = 0
          dorefresh = false
        end
      elsif Input.trigger?(Input::LEFT) && !@pokemon.egg?
        oldpage = @page
        @page -= 1
        @page = 1 if @page<1
        @page = 5 if @page>5
        if @page!=oldpage
          pbSEPlay("GUI summary change page")
          @ribbonOffset = 0
          animateSummaryPage(-1) { drawPage(@page) }
          dorefresh = false
        end
      elsif Input.trigger?(Input::RIGHT) && !@pokemon.egg?
        oldpage = @page
        @page += 1
        @page = 1 if @page<1
        @page = 5 if @page>5
        if @page!=oldpage
          pbSEPlay("GUI summary change page")
          @ribbonOffset = 0
          animateSummaryPage(1) { drawPage(@page) }
          dorefresh = false
        end
      end
      if dorefresh
        drawPage(@page)
      end
    end
    return @partyindex
  end
end



class PokemonSummaryScreen
  def initialize(scene,inbattle=false)
    @scene = scene
    @inbattle = inbattle
  end

  def pbStartScreen(party,partyindex)
    @scene.pbStartScene(party,partyindex,@inbattle)
    ret = @scene.pbScene
    @scene.pbEndScene
    return ret
  end

  def pbStartForgetScreen(party,partyindex,moveToLearn)
    ret = -1
    @scene.pbStartForgetScene(party,partyindex,moveToLearn)
    loop do
      ret = @scene.pbChooseMoveToForget(moveToLearn)
      if ret>=0 && moveToLearn!=0 && pbIsHiddenMove?(party[partyindex].moves[ret].id) && !$DEBUG
        pbMessage(_INTL("HM moves can't be forgotten now.")) { @scene.pbUpdate }
      else
        break
      end
    end
    @scene.pbEndScene
    return ret
  end

  def pbStartChooseMoveScreen(party,partyindex,message)
    ret = -1
    @scene.pbStartForgetScene(party,partyindex,0)
    pbMessage(message) { @scene.pbUpdate }
    loop do
      ret = @scene.pbChooseMoveToForget(0)
      if ret<0
        pbMessage(_INTL("You must choose a move!")) { @scene.pbUpdate }
      else
        break
      end
    end
    @scene.pbEndScene
    return ret
  end
end
