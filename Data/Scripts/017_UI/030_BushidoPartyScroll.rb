#===============================================================================
# Phoenix-style Party UI v11.6 native Pokemon fonts
# Pokemon Bushido / Pokemon Essentials v18.1
#
# Visual target:
#   A close recreation of the Phoenix Rising party interface shown in the
#   provided references: large left focal Pokemon, lower-left HP/info panel,
#   permanent right-side command stack, and six-member dock along the bottom.
#
# INSTALL:
#   Put AFTER the original Essentials party UI script.
#   Disable older Bushido party UI override scripts.
#
# TEST:
#   pbPhoenixPartyTest
#===============================================================================

module PhoenixPartyUI
  BG          = Color.new(91, 75, 96)
  BG_DARK     = Color.new(69, 57, 75)
  PANEL       = Color.new(132, 118, 135)
  PANEL_DARK  = Color.new(108, 94, 112)
  PANEL_LIGHT = Color.new(151, 137, 153)
  WHITE       = Color.new(245, 244, 247)
  SHADOW      = Color.new(50, 42, 55, 65)
  RED         = Color.new(229, 30, 68)
  RED_DARK    = Color.new(154, 18, 44)
  MALE        = Color.new(78, 125, 209)
  FEMALE      = Color.new(211, 69, 157)
  HP_GREEN    = Color.new(54, 201, 92)
  HP_YELLOW   = Color.new(226, 184, 58)
  HP_RED      = Color.new(222, 69, 62)
  HP_BG       = Color.new(64, 62, 67)

  DOCK_Y       = 302
  SLOT_W       = 75
  SLOT_GAP     = 6
  SLOT_START_X = 17

  def self.slot_x(index)
    SLOT_START_X + index * (SLOT_W + SLOT_GAP)
  end

  def self.hp_color(pokemon)
    return HP_BG if pokemon.hp <= 0
    r = pokemon.totalhp > 0 ? pokemon.hp.to_f / pokemon.totalhp : 0.0
    return HP_RED if r <= 0.25
    return HP_YELLOW if r <= 0.50
    HP_GREEN
  end

    def self.set_primary_font(bitmap)
      BushidoFonts.apply(bitmap, :label)
    end

    def self.set_ui_font(bitmap)
      BushidoFonts.apply(bitmap, :label)
    end
    
  # Compatibility helpers for inherited scene code.
  def self.set_font(bitmap, size=nil)
    if size
      set_ui_font(bitmap)
    else
      set_primary_font(bitmap)
    end
  end

  def self.set_dialogue_font(bitmap, size=nil)
    set_font(bitmap, size)
  end

  def self.draw_text(bitmap,text,x,y,w,h,align=0,base=WHITE,shadow=SHADOW)
    pbDrawShadowText(bitmap, x, y, w, h, text.to_s, base, shadow, align)
  end

  def self.draw_scaled_text(bitmap,text,x,y,w,h,scale=0.5,align=0,
                            base=WHITE,shadow=SHADOW)
    # Legacy compatibility only. Never scale rendered text.
    # Any "scaled" call now uses the engine's dedicated small Pokemon font.
    set_ui_font(bitmap)
    pbDrawShadowText(bitmap, x, y, w, h, text.to_s, base, shadow, align)
  end

  def self.status_name(pokemon)
    return _INTL("FAINTED") if pokemon.hp <= 0
    return nil if pokemon.status <= 0
    begin
      PBStatuses.getName(pokemon.status)
    rescue
      _INTL("STATUS")
    end
  end

  def self.visible_bounds(bitmap)
    return nil if !bitmap || bitmap.disposed?
    min_x=bitmap.width; min_y=bitmap.height; max_x=-1; max_y=-1
    for y in 0...bitmap.height
      for x in 0...bitmap.width
        c=bitmap.get_pixel(x,y)
        next if c.alpha <= 8
        min_x=x if x<min_x
        min_y=y if y<min_y
        max_x=x if x>max_x
        max_y=y if y>max_y
      end
    end
    return nil if max_x<min_x || max_y<min_y
    [min_x,min_y,max_x,max_y]
  end
end

#===============================================================================
# Background
#===============================================================================
class PhoenixPartyBackground < SpriteWrapper
  def initialize(viewport=nil)
    super(viewport)
    self.bitmap=Bitmap.new(Graphics.width,Graphics.height)
    draw_background
  end

  def rounded_rect(b,x,y,w,h,border,fill)
    b.fill_rect(x+4,y,w-8,h,border)
    b.fill_rect(x,y+4,w,h-8,border)
    b.fill_rect(x+2,y+2,w-4,h-4,border)
    b.fill_rect(x+7,y+3,w-14,h-6,fill)
    b.fill_rect(x+3,y+7,w-6,h-14,fill)
  end

  def draw_background
    b=self.bitmap
    b.clear
    b.fill_rect(0,0,Graphics.width,Graphics.height,PhoenixPartyUI::BG_DARK)

    rounded_rect(b,22,14,468,274,PhoenixPartyUI::WHITE,PhoenixPartyUI::BG)

    # Large lavender spotlight.
    cx=145; cy=117; r=104
    (-r).step(r,4) do |dy|
      dx=Math.sqrt([r*r-dy*dy,0].max).to_i
      b.fill_rect(cx-dx,cy+dy,dx*2,4,PhoenixPartyUI::PANEL_LIGHT)
    end

    # Bottom party shelf.
    b.fill_rect(0,294,Graphics.width,4,PhoenixPartyUI::WHITE)
    b.fill_rect(0,298,Graphics.width,4,PhoenixPartyUI::BG_DARK)
    b.fill_rect(0,302,Graphics.width,82,PhoenixPartyUI::PANEL_DARK)
  end
end

#===============================================================================
# Bottom party slot
#===============================================================================
class PhoenixPartySlot < SpriteWrapper
  attr_reader :pokemon
  attr_reader :selected
  attr_reader :preselected
  attr_reader :switching
  attr_reader :text

  def initialize(pokemon, index, viewport=nil)
    super(viewport)
    @pokemon = pokemon
    @index = index
    @selected = false
    @preselected = false
    @switching = false
    @text = nil

    self.bitmap = Bitmap.new(PhoenixPartyUI::SLOT_W, 74)
    self.x = PhoenixPartyUI.slot_x(index)
    self.y = PhoenixPartyUI::DOCK_Y + 4
    self.z = 5

    @icon = PokemonIconSprite.new(@pokemon, viewport)
    @icon.setOffset(PictureOrigin::Center)
    @icon.z = self.z + 2

    @item = HeldItemIconSprite.new(0, 0, @pokemon, viewport)
    @item.z = self.z + 3

    refresh
  end

  def dispose
    @icon.dispose if @icon && !@icon.disposed?
    @item.dispose if @item && !@item.disposed?
    self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
    super
  end

  def pokemon=(value)
    @pokemon = value
    @icon.pokemon = value if @icon && !@icon.disposed?
    @item.pokemon = value if @item && !@item.disposed?
    refresh
  end

  def selected=(value)
    return if @selected == value
    @selected = value
    refresh
  end

  def preselected=(value)
    return if @preselected == value
    @preselected = value
    refresh
  end

  def switching=(value)
    @switching = value
    refresh
  end

  def text=(value)
    @text = value
    refresh
  end

  def hp
    return @pokemon.hp
  end

  def refresh
    return if disposed?
    b=self.bitmap
    b.clear

    if @selected || @preselected
      accent=@preselected ? Color.new(198,139,67) : PhoenixPartyUI::WHITE
      fill=@preselected ? Color.new(190,130,62) : PhoenixPartyUI::PANEL
      b.fill_rect(5,0,PhoenixPartyUI::SLOT_W-10,58,accent)
      b.fill_rect(8,3,PhoenixPartyUI::SLOT_W-16,55,fill)
    end

    bw=46
    bx=(PhoenixPartyUI::SLOT_W-bw)/2
    by=62
    b.fill_rect(bx,by,bw,6,PhoenixPartyUI::HP_BG)
    if @pokemon && @pokemon.totalhp>0 && @pokemon.hp>0
      fill=((bw-2)*@pokemon.hp.to_f/@pokemon.totalhp).round
      fill=1 if fill<1
      b.fill_rect(bx+1,by+1,fill,4,PhoenixPartyUI.hp_color(@pokemon))
    end
    update_icon_position
  end

  def update_icon_position
    return if !@icon || @icon.disposed?
    @icon.x=self.x+PhoenixPartyUI::SLOT_W/2
    @icon.y=self.y+43
    if @item
      @item.x=self.x+58
      @item.y=self.y+49
    end
  end

  def x=(value)
    super
    update_icon_position if @icon
  end

  def y=(value)
    super
    update_icon_position if @icon
  end

  def color=(value)
    super
    @icon.color = value if @icon && !@icon.disposed?
    @item.color = value if @item && !@item.disposed?
  end

  def update
    super
    @icon.update if @icon && !@icon.disposed?
    @item.update if @item && !@item.disposed?
  end
end

class PhoenixPartyBlankSlot < SpriteWrapper
  attr_accessor :text
  attr_accessor :selected
  attr_accessor :preselected
  attr_accessor :switching

  def initialize(_pokemon, index, viewport=nil)
    super(viewport)
    @text = nil
    @selected = false
    @preselected = false
    @switching = false
    self.bitmap = Bitmap.new(PhoenixPartyUI::SLOT_W, 74)
    self.x = PhoenixPartyUI.slot_x(index)
    self.y = PhoenixPartyUI::DOCK_Y + 4
  end

  def refresh; end
  def dispose
    self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
    super
  end
end

class PhoenixPartyInvisibleAction < SpriteWrapper
  attr_accessor :text
  attr_accessor :selected
  def initialize(viewport=nil)
    super(viewport)
    @text = nil
    @selected = false
    self.bitmap = Bitmap.new(1, 1)
    self.x = -16
    self.y = -16
  end
  def preselected; false; end
  def preselected=(v); end
  def switching; false; end
  def switching=(v); end
  def refresh; end
  def dispose
    self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
    super
  end
end


#===============================================================================
# Phoenix-style Info Panel Component
#===============================================================================
class PhoenixPartyInfoPanel < SpriteWrapper
  PANEL_W = 216
  PANEL_H = 73

  def initialize(viewport=nil)
    super(viewport)
    self.bitmap = Bitmap.new(PANEL_W, PANEL_H)
    self.x = 43
    self.y = 202
    self.z = 9
    @pokemon = nil
  end

  def pokemon=(pkmn)
    @pokemon = pkmn
    refresh
  end

  def draw_panel_frame(b)
    b.fill_rect(4,0,PANEL_W-8,PANEL_H,PhoenixPartyUI::WHITE)
    b.fill_rect(0,4,PANEL_W,PANEL_H-8,PhoenixPartyUI::WHITE)
    b.fill_rect(3,3,PANEL_W-6,PANEL_H-6,PhoenixPartyUI::PANEL)
  end

  def refresh
    b = self.bitmap
    b.clear
    draw_panel_frame(b)
    return if !@pokemon

    pkmn = @pokemon

    # -----------------------------------------------------------------------
    # TOP ROW
    # -----------------------------------------------------------------------
    PhoenixPartyUI.set_primary_font(b)
    name_h = b.text_size(pkmn.name).height
    PhoenixPartyUI.draw_text(
      b, pkmn.name,
      10, 2, 112, name_h,
      0,
      PhoenixPartyUI::WHITE, PhoenixPartyUI::SHADOW
    )

    if !pkmn.egg?
      # Gender and level use Essentials' own dedicated small Pokemon font.
      PhoenixPartyUI.set_ui_font(b)
      meta_h = b.text_size("Ag").height

      if pkmn.male?
        PhoenixPartyUI.draw_text(
          b, _INTL("♂"),
          123, 4, 18, meta_h,
          1,
          PhoenixPartyUI::MALE, PhoenixPartyUI::SHADOW
        )
      elsif pkmn.female?
        PhoenixPartyUI.draw_text(
          b, _INTL("♀"),
          123, 4, 18, meta_h,
          1,
          PhoenixPartyUI::FEMALE, PhoenixPartyUI::SHADOW
        )
      end

      PhoenixPartyUI.draw_text(
        b, _INTL("Lv. {1}", pkmn.level),
        143, 4, 62, meta_h,
        1,
        PhoenixPartyUI::WHITE, PhoenixPartyUI::SHADOW
      )

      # ---------------------------------------------------------------------
      # HP STRIP
      # ---------------------------------------------------------------------
      strip_y = 31
      strip_h = 15
      strip_dark = Color.new(74, 69, 78)

      # Dark status strip has no stroke.
      b.fill_rect(3, strip_y, PANEL_W-6, strip_h, strip_dark)

      # Compact custom HP mark with visible spacing between H and P.
      hp_x = 8
      hp_y = strip_y + 4
      c = PhoenixPartyUI::WHITE

      # H
      b.fill_rect(hp_x,     hp_y,     2, 8, c)
      b.fill_rect(hp_x+6,   hp_y,     2, 8, c)
      b.fill_rect(hp_x,     hp_y+3,   8, 2, c)

      # P
      p_x = hp_x + 12
      b.fill_rect(p_x,      hp_y,     2, 8, c)
      b.fill_rect(p_x,      hp_y,     7, 2, c)
      b.fill_rect(p_x+5,    hp_y+1,   2, 3, c)
      b.fill_rect(p_x,      hp_y+3,   7, 2, c)

      # Actual HP meter gets the 1px casing.
      bx = 31
      by = strip_y + 2
      bw = PANEL_W - bx - 8
      bh = strip_h - 4

      casing = Color.new(46, 43, 49)
      track  = Color.new(36, 35, 39)
      b.fill_rect(bx, by, bw, bh, casing)
      b.fill_rect(bx+1, by+1, bw-2, bh-2, track)

      if pkmn.totalhp > 0 && pkmn.hp > 0
        fill = ((bw-2) * pkmn.hp.to_f / pkmn.totalhp).round
        fill = 1 if fill < 1

        hp_color = PhoenixPartyUI.hp_color(pkmn)

        base =
          if hp_color == PhoenixPartyUI::HP_GREEN
            Color.new(42, 186, 78)
          elsif hp_color == PhoenixPartyUI::HP_YELLOW
            Color.new(204, 158, 43)
          else
            Color.new(193, 57, 55)
          end

        hi =
          if hp_color == PhoenixPartyUI::HP_GREEN
            Color.new(68, 233, 105)
          elsif hp_color == PhoenixPartyUI::HP_YELLOW
            Color.new(240, 196, 67)
          else
            Color.new(235, 80, 76)
          end

        low =
          if hp_color == PhoenixPartyUI::HP_GREEN
            Color.new(29, 126, 57)
          elsif hp_color == PhoenixPartyUI::HP_YELLOW
            Color.new(142, 106, 28)
          else
            Color.new(128, 38, 39)
          end

        fx = bx + 1
        fy = by + 1
        fh = bh - 2
        b.fill_rect(fx, fy, fill, fh, base)
        b.fill_rect(fx, fy, fill, 1, hi)
        b.fill_rect(fx, fy+fh-1, fill, 1, low)
      end

      # HP fraction also uses the engine's small Pokemon font directly.
      PhoenixPartyUI.set_ui_font(b)
      hp_fraction = sprintf("%d/%d", pkmn.hp, pkmn.totalhp)
      fraction_h = b.text_size(hp_fraction).height
      PhoenixPartyUI.draw_text(
        b, hp_fraction,
        3, 47, PANEL_W-6, fraction_h,
        1,
        PhoenixPartyUI::WHITE, PhoenixPartyUI::SHADOW
      )
    end
  end

  def dispose
    self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
    super
  end
end

#===============================================================================
# Phoenix-style Action Button Component
#===============================================================================
class PhoenixPartyActionButton < SpriteWrapper
  BUTTON_W = 194
  BUTTON_H = 37

  attr_reader :label

  def initialize(label,index,viewport=nil)
    super(viewport)
    self.bitmap = Bitmap.new(BUTTON_W, BUTTON_H)
    self.z = 9
    @label = label.to_s
    @index = index
    @selected = false
    self.x = 276
    self.y = 35 + index * 46
    refresh
  end

  def label=(value)
    @label = value.to_s
    refresh
  end

  def selected=(value)
    return if @selected == value
    @selected = value
    refresh
  end

  def selected
    @selected
  end

  def refresh
    b = self.bitmap
    b.clear

    border = @selected ? PhoenixPartyUI::RED : PhoenixPartyUI::WHITE

    # soft shadow
    b.fill_rect(3,4,BUTTON_W,BUTTON_H,Color.new(35,29,40,75))

    # rounded-ish outer border
    b.fill_rect(5,0,BUTTON_W-10,BUTTON_H,border)
    b.fill_rect(0,5,BUTTON_W,BUTTON_H-10,border)
    b.fill_rect(3,3,BUTTON_W-6,BUTTON_H-6,PhoenixPartyUI::PANEL)

    # right-side shade
    b.fill_rect(BUTTON_W-31,5,27,BUTTON_H-10,PhoenixPartyUI::PANEL_DARK)

    # Essentials' dedicated small Pokemon font, no scaling.
    PhoenixPartyUI.set_ui_font(b)
    th = b.text_size(@label).height
    ty = ((BUTTON_H - th) / 2)
    PhoenixPartyUI.draw_text(
      b, @label,
      12, ty,
      BUTTON_W-49, th,
      0
    )

    if @selected
      mx=BUTTON_W-21
      my=BUTTON_H/2
      b.fill_rect(mx,my-5,5,10,PhoenixPartyUI::WHITE)
      b.fill_rect(mx+5,my-3,3,6,PhoenixPartyUI::WHITE)
      b.fill_rect(mx+8,my-1,2,2,PhoenixPartyUI::WHITE)
    end
  end

  def dispose
    self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
    super
  end
end

#===============================================================================
# Scene
#===============================================================================
class PokemonParty_Scene
  def pbStartScene(party, starthelptext, annotations=nil, multiselect=false)
    @sprites = {}
    @party = party
    @multiselect = multiselect
    @helptext = starthelptext

    @command_mode = false
    @command_commands = nil
    @command_index = 0
    @command_page = 0
    @message_text = nil

    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999

    @sprites["background"] = PhoenixPartyBackground.new(@viewport)
    @sprites["background"].z = 0

    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["overlay"].z = 8
    PhoenixPartyUI.set_font(@sprites["overlay"].bitmap)

    # Isolated UI components.
    @sprites["infoPanel"] = PhoenixPartyInfoPanel.new(@viewport)
    @action_buttons = []

    for i in 0...6
      if @party[i]
        @sprites["pokemon#{i}"] = PhoenixPartySlot.new(@party[i], i, @viewport)
      else
        @sprites["pokemon#{i}"] = PhoenixPartyBlankSlot.new(@party[i], i, @viewport)
      end
      @sprites["pokemon#{i}"].text = annotations[i] if annotations
    end

    # Hidden compatibility targets for stock party logic.
    @sprites["pokemon6"] = PhoenixPartyInvisibleAction.new(@viewport)
    @sprites["pokemon7"] = PhoenixPartyInvisibleAction.new(@viewport) if @multiselect

    # Large active Pokemon uses the FRONT BATTLE SPRITE, not the party icon.
    @sprites["activePokemon"] = PokemonSprite.new(@viewport)
    @sprites["activePokemon"].z = 6
    setActivePokemonBitmap(@party[0])

    @activecmd = 0
    @sprites["pokemon0"].selected = true if @sprites["pokemon0"]

    refreshBushidoUI

    # One normal fade. No extra opening flash/animation.
    pbFadeInAndShow(@sprites) { update }
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { update }

    if @action_buttons
      @action_buttons.each do |button|
        button.dispose if button && !button.disposed?
      end
    end

    pbDisposeSpriteHash(@sprites)
    @viewport.dispose if @viewport && !@viewport.disposed?
  end

  def selectedPokemon
    return nil if @activecmd.nil?
    return nil if @activecmd < 0 || @activecmd >= @party.length
    return @party[@activecmd]
  end

  def setActivePokemonBitmap(pkmn)
    spr=@sprites["activePokemon"]
    return if !spr || !pkmn
    begin
      spr.setPokemonBitmap(pkmn,false)
    rescue
      begin
        spr.bitmap=pbLoadPokemonBitmap(pkmn,false)
      rescue
        spr.bitmap=nil
      end
    end
    return if !spr.bitmap
    spr.zoom_x=1.0
    spr.zoom_y=1.0
    bounds=PhoenixPartyUI.visible_bounds(spr.bitmap)
    if bounds
      l,t,r,b=bounds
      spr.ox=(l+r)/2.0
      spr.oy=(t+b)/2.0
    else
      spr.ox=spr.bitmap.width/2
      spr.oy=spr.bitmap.height/2
    end
    spr.x=145
    spr.y=116
  end

  def refreshActivePokemon
    spr = @sprites["activePokemon"]
    pkmn = selectedPokemon
    return if !spr
    if pkmn
      spr.visible = true
      setActivePokemonBitmap(pkmn)
    else
      spr.visible = false
    end
  end

  def refreshBushidoUI
    return if !@sprites["overlay"]

    refreshActivePokemon

    # Info panel is now its own component.
    @sprites["infoPanel"].pokemon = selectedPokemon if @sprites["infoPanel"]

    # Overlay only handles transient messages + paging arrows now.
    b = @sprites["overlay"].bitmap
    b.clear

    refreshActionButtons

    if @message_text
      drawMessage(b, @message_text)
    else
      drawPagingArrows(b)
    end
  end

  def drawPokemonInfo(b)
    pkmn=selectedPokemon
    return if !pkmn

    x=43
    y=202
    w=216
    h=73

    # White rounded-ish Phoenix panel.
    b.fill_rect(x+4,y,w-8,h,PhoenixPartyUI::WHITE)
    b.fill_rect(x,y+4,w,h-8,PhoenixPartyUI::WHITE)
    b.fill_rect(x+3,y+3,w-6,h-6,PhoenixPartyUI::PANEL)

    # -----------------------------------------------------------------------
    # TOP ROW
    # Bigger name on left, gender + level grouped tightly on the right.
    # -----------------------------------------------------------------------
    PhoenixPartyUI.draw_scaled_text(
      b, pkmn.name,
      x+10, y+2, 116, 29,
      0.70, 0,
      PhoenixPartyUI::WHITE, PhoenixPartyUI::SHADOW
    )

    if !pkmn.egg?
      if pkmn.male?
        PhoenixPartyUI.draw_scaled_text(
          b, _INTL("♂"),
          x+126, y+4, 18, 25,
          0.50, 1,
          PhoenixPartyUI::MALE, PhoenixPartyUI::SHADOW
        )
      elsif pkmn.female?
        PhoenixPartyUI.draw_scaled_text(
          b, _INTL("♀"),
          x+126, y+4, 18, 25,
          0.50, 1,
          PhoenixPartyUI::FEMALE, PhoenixPartyUI::SHADOW
        )
      end

      PhoenixPartyUI.draw_scaled_text(
        b, _INTL("Lv. {1}",pkmn.level),
        x+145, y+4, 60, 25,
        0.50, 1,
        PhoenixPartyUI::WHITE, PhoenixPartyUI::SHADOW
      )

      # ---------------------------------------------------------------------
      # HP row sits lower and uses the full width well.
      # ---------------------------------------------------------------------
      PhoenixPartyUI.draw_scaled_text(
        b, _INTL("HP"),
        x+10, y+33, 26, 18,
        0.50, 0,
        PhoenixPartyUI::WHITE, PhoenixPartyUI::SHADOW
      )

      bx=x+38
      by=y+38
      bw=164
      b.fill_rect(bx,by,bw,9,PhoenixPartyUI::HP_BG)

      if pkmn.totalhp>0 && pkmn.hp>0
        fill=((bw-2)*pkmn.hp.to_f/pkmn.totalhp).round
        fill=1 if fill<1
        b.fill_rect(
          bx+1,by+1,fill,7,
          PhoenixPartyUI.hp_color(pkmn)
        )
      end

      # Center fraction exactly under the bar.
      PhoenixPartyUI.draw_scaled_text(
        b, sprintf("%d/%d",pkmn.hp,pkmn.totalhp),
        bx, y+49, bw, 19,
        0.50, 1,
        PhoenixPartyUI::WHITE, PhoenixPartyUI::SHADOW
      )
    end
  end

  # Build the SAME command preview the real PokemonPartyScreen builds after C.
  # This means hovering alone shows the correct actions for that Pokemon.
  def previewCommands
    pkmn=selectedPokemon
    return [] if !pkmn

    commands=[]
    commands.push(_INTL("Summary"))
    commands.push(_INTL("Debug")) if $DEBUG

    # Match the original Bushido/Essentials field-move entries.
    if !pkmn.egg?
      for i in 0...pkmn.moves.length
        move=pkmn.moves[i]
        if isConst?(move.id,PBMoves,:MILKDRINK) ||
           isConst?(move.id,PBMoves,:SOFTBOILED)
          commands.push([PBMoves.getName(move.id),1])
        end
      end
    end

    commands.push(_INTL("Switch")) if @party.length>1

    if !pkmn.egg?
      if pkmn.mail
        commands.push(_INTL("Mail"))
      else
        commands.push(_INTL("Item"))
      end
    end

    commands.push(_INTL("Cancel"))
    return commands
  end

  def currentPreviewCommands
    return @command_mode ? (@command_commands || []) : previewCommands
  end

  def refreshActionButtons
    commands = currentPreviewCommands
    page_size = 5

    max_page = commands.length > 0 ? (commands.length - 1) / page_size : 0
    @command_page = 0 if !@command_page
    @command_page = max_page if @command_page > max_page

    page_start = @command_page * page_size
    visible = commands[page_start, page_size] || []

    # Ensure five persistent button sprites max.
    for i in 0...5
      if !@action_buttons[i]
        @action_buttons[i] = PhoenixPartyActionButton.new("", i, @viewport)
      end

      button = @action_buttons[i]

      if i < visible.length
        raw = visible[i]
        cmd = raw.is_a?(Array) ? raw[0] : raw
        label = (cmd.to_s.downcase == "move") ? _INTL("Swap") : cmd.to_s

        button.visible = true
        button.label = label

        absolute_index = page_start + i
        button.selected = (@command_mode && absolute_index == @command_index)
      else
        button.visible = false
        button.selected = false
      end
    end
  end

  def drawPagingArrows(b)
    commands = currentPreviewCommands
    return if commands.length <= 5

    max_page = (commands.length - 1) / 5
    x = 373

    if @command_page < max_page
      ay = 268
      b.fill_rect(x-5,ay,10,2,PhoenixPartyUI::WHITE)
      b.fill_rect(x-3,ay+2,6,2,PhoenixPartyUI::WHITE)
      b.fill_rect(x-1,ay+4,2,2,PhoenixPartyUI::WHITE)
    end

    if @command_page > 0
      ay = 22
      b.fill_rect(x-1,ay,2,2,PhoenixPartyUI::WHITE)
      b.fill_rect(x-3,ay+2,6,2,PhoenixPartyUI::WHITE)
      b.fill_rect(x-5,ay+4,10,2,PhoenixPartyUI::WHITE)
    end
  end

  def drawActionArea(b)
    # Intentionally empty. Action buttons are isolated Sprite components now.
    refreshActionButtons
  end

  def drawMessage(b, text)
    # Context message replaces the action list temporarily, but has no OK box.
    b.fill_rect(320, 78, 150, 116, PhoenixPartyUI::PANEL_DARK)
    b.fill_rect(323, 81, 144, 110, PhoenixPartyUI::PANEL_LIGHT)
    PhoenixPartyUI.set_primary_font(b)

    # Simple word wrap that is safe on old Ruby.
    words = text.to_s.split(/\s+/)
    lines = []
    line = ""
    words.each do |word|
      test = line.length == 0 ? word : line + " " + word
      if b.text_size(test).width > 124 && line.length > 0
        lines.push(line)
        line = word
      else
        line = test
      end
    end
    lines.push(line) if line.length > 0

    y = 91
    lines[0, 5].each do |ln|
      pbDrawShadowText(
        b, 332, y - 4, 126, 28, ln,
        PhoenixPartyUI::INK, Color.new(0,0,0,0)
      )
      y += 20
    end
  end

  def pbSetHelpText(helptext)
    @helptext = helptext
    refreshBushidoUI
  end

  def pbShowCommands(helptext, commands, index=0)
    return -1 if !commands || commands.length == 0

    @command_mode = true
    @command_commands = commands
    @command_index = index
    @command_index = 0 if @command_index < 0 || @command_index >= commands.length
    @command_page = @command_index / 5
    refreshBushidoUI

    ret = -1
    loop do
      Graphics.update
      Input.update
      self.update

      old=@command_index

      if Input.repeat?(Input::UP)
        @command_index-=1
        @command_index=commands.length-1 if @command_index<0
      elsif Input.repeat?(Input::DOWN)
        @command_index+=1
        @command_index=0 if @command_index>=commands.length
      end

      if old!=@command_index
        # Automatically move to the page containing the newly-selected option.
        @command_page=@command_index/5
        pbPlayCursorSE
        refreshBushidoUI
      end

      if Input.trigger?(Input::B)
        pbPlayCancelSE
        ret = -1
        break
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE
        ret = @command_index
        break
      end
    end

    @command_mode = false
    @command_commands = nil
    @command_page = 0
    refreshBushidoUI
    return ret
  end

  def pbDisplay(text)
    @message_text = text
    refreshBushidoUI

    # Party notifications are toast-like now. Held-item messages such as
    # "...was given the ... to hold" never trap the player waiting for input.
    # C/B can still dismiss immediately.
    frames = Graphics.frame_rate
    frames = 60 if !frames || frames <= 0
    frames.times do
      Graphics.update
      Input.update
      self.update
      break if Input.trigger?(Input::C) || Input.trigger?(Input::B)
    end

    @message_text = nil
    refreshBushidoUI
    return 0
  end

  def pbDisplayConfirm(text)
    return pbShowCommands(text, [_INTL("Yes"), _INTL("No")], 0) == 0
  end

  def pbSelect(item)
    @activecmd = item
    @command_page = 0 if !@command_mode

    for i in 0...6
      s = @sprites["pokemon#{i}"]
      s.selected = (i == @activecmd) if s
    end

    # Critical Phoenix behavior: arrow-key hover immediately refreshes BOTH
    # the large Pokemon and the right-side options. No C press required.
    refreshBushidoUI
  end

  def pbPreSelect(item)
    @activecmd = item
  end

  # Horizontal dock navigation.
  def pbChoosePokemon(switching=false, initialsel=-1, canswitch=0)
    for i in 0...6
      @sprites["pokemon#{i}"].preselected = (switching && i == @activecmd)
      @sprites["pokemon#{i}"].switching = switching
    end

    @activecmd = initialsel if initialsel >= 0 && initialsel < @party.length
    @activecmd = 0 if @activecmd.nil? || @activecmd < 0
    @activecmd = @party.length - 1 if @activecmd >= @party.length
    pbSelect(@activecmd)
    pbRefresh

    loop do
      Graphics.update
      Input.update
      self.update

      oldsel = @activecmd

      if Input.repeat?(Input::LEFT)
        @activecmd -= 1
        @activecmd = @party.length - 1 if @activecmd < 0
      elsif Input.repeat?(Input::RIGHT)
        @activecmd += 1
        @activecmd = 0 if @activecmd >= @party.length
      elsif Input.repeat?(Input::UP)
        # Up/down also step horizontally, useful on controller muscle memory.
        @activecmd -= 1
        @activecmd = @party.length - 1 if @activecmd < 0
      elsif Input.repeat?(Input::DOWN)
        @activecmd += 1
        @activecmd = 0 if @activecmd >= @party.length
      end

      if @activecmd != oldsel
        pbPlayCursorSE
        pbSelect(@activecmd)
      end

      if Input.trigger?(Input::A) && canswitch == 1
        pbPlayDecisionSE
        return [1, @activecmd]
      elsif Input.trigger?(Input::A) && canswitch == 2
        return -1
      elsif Input.trigger?(Input::B)
        pbPlayCloseMenuSE if !switching
        return -1
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE
        return @activecmd
      end
    end
  end

  def pbSwitchBegin(oldid, newid)
    pbSEPlay("GUI party switch")
    oldsprite = @sprites["pokemon#{oldid}"]
    newsprite = @sprites["pokemon#{newid}"]
    5.times do |i|
      oldsprite.opacity = 255 - ((i + 1) * 34)
      newsprite.opacity = 255 - ((i + 1) * 34)
      Graphics.update
      self.update
    end
  end

  def pbSwitchEnd(oldid, newid)
    oldsprite = @sprites["pokemon#{oldid}"]
    newsprite = @sprites["pokemon#{newid}"]

    oldsprite.pokemon = @party[oldid]
    newsprite.pokemon = @party[newid]

    oldsprite.x = PhoenixPartyUI.slot_x(oldid)
    newsprite.x = PhoenixPartyUI.slot_x(newid)
    oldsprite.opacity = 255
    newsprite.opacity = 255

    for i in 0...6
      @sprites["pokemon#{i}"].preselected = false
      @sprites["pokemon#{i}"].switching = false
    end

    pbRefresh
  end

  def pbClearSwitching
    for i in 0...6
      @sprites["pokemon#{i}"].preselected = false
      @sprites["pokemon#{i}"].switching = false
    end
  end

  def pbHasAnnotations?
    return @sprites["pokemon0"].text != nil
  end

  def pbAnnotate(annot)
    for i in 0...6
      @sprites["pokemon#{i}"].text = annot ? annot[i] : nil
    end
  end

  def pbHardRefresh
    oldtext = []
    lastselected = 0

    for i in 0...6
      oldtext.push(@sprites["pokemon#{i}"].text)
      lastselected = i if @sprites["pokemon#{i}"].selected
      @sprites["pokemon#{i}"].dispose
    end

    lastselected = @party.length - 1 if lastselected >= @party.length
    lastselected = 0 if lastselected < 0

    for i in 0...6
      if @party[i]
        @sprites["pokemon#{i}"] = PhoenixPartySlot.new(@party[i], i, @viewport)
      else
        @sprites["pokemon#{i}"] = PhoenixPartyBlankSlot.new(@party[i], i, @viewport)
      end
      @sprites["pokemon#{i}"].text = oldtext[i]
    end

    pbSelect(lastselected)
  end

  def pbRefresh
    for i in 0...6
      sprite = @sprites["pokemon#{i}"]
      next if !sprite
      if sprite.is_a?(PhoenixPartySlot)
        sprite.pokemon = @party[i] if @party[i]
      else
        sprite.refresh
      end
    end
    refreshBushidoUI
  end

  def pbRefreshSingle(i)
    return if i.nil? || i < 0 || i >= 6
    sprite = @sprites["pokemon#{i}"]
    return if !sprite

    if sprite.is_a?(PhoenixPartySlot)
      sprite.pokemon = @party[i] if @party[i]
    else
      sprite.refresh
    end

    refreshBushidoUI
  end

  def update
    pbUpdateSpriteHash(@sprites)
    if @action_buttons
      @action_buttons.each do |button|
        button.update if button && !button.disposed?
      end
    end
  end
end

#===============================================================================
# Quick test
#===============================================================================
def pbPhoenixPartyTest
  if !$Trainer || !$Trainer.party || $Trainer.party.length == 0
    pbMessage(_INTL("Put a Pokemon in your party first."))
    return
  end

  scene = PokemonParty_Scene.new
  screen = PokemonPartyScreen.new(scene, $Trainer.party)
  screen.pbStartScene(_INTL("Choose a Pokemon."), 0)
  screen.pbChoosePokemon
  screen.pbEndScene
end
