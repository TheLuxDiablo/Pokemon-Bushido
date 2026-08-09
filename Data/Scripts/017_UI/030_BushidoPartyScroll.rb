#===============================================================================
# Bushido Party UI
# quick test: pbBushidoPartyTest
#===============================================================================

module BushidoPartyUI
  # Main Bushido palette.
  BG          = Color.new(48, 38, 35)
  BG_DARK     = Color.new(31, 25, 23)
  PANEL       = Color.new(112, 94, 82)
  PANEL_DARK  = Color.new(76, 60, 53)
  PANEL_LIGHT = Color.new(150, 128, 106)
  WHITE       = Color.new(244, 232, 207)
  SHADOW      = Color.new(24, 18, 16, 72)
  RED         = Color.new(176, 49, 48)
  RED_DARK    = Color.new(111, 30, 30)
  GOLD        = Color.new(188, 144, 76)
  MALE        = Color.new(82, 132, 204)
  FEMALE      = Color.new(204, 74, 105)
  HP_GREEN    = Color.new(54, 185, 82)
  HP_YELLOW   = Color.new(220, 174, 53)
  HP_RED      = Color.new(198, 59, 56)
  HP_BG       = Color.new(45, 39, 36)

  DOCK_Y       = 302
  SLOT_W       = 75
  SLOT_GAP     = 6
  SLOT_START_X = 17

  # Type color is only used for small accents so the whole screen doesn't
  # turn into a different theme every time the selection changes.
  def self.type_accent(pokemon)
    return GOLD if !pokemon

    type_id = nil
    begin
      type_id = pokemon.type1
    rescue
      return GOLD
    end

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
      "FAIRY"    => Color.new(220,132,156)
    }
    return colors[name] || GOLD
  end

  def self.mix(c1, c2, amount)
    amount = 0.0 if amount < 0.0
    amount = 1.0 if amount > 1.0
    Color.new(
      (c1.red   + (c2.red   - c1.red)   * amount).round,
      (c1.green + (c2.green - c1.green) * amount).round,
      (c1.blue  + (c2.blue  - c1.blue)  * amount).round,
      (c1.alpha + (c2.alpha - c1.alpha) * amount).round
    )
  end

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
    
  # A few older party methods still call these names.
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
    # Old calls still hit this method, but we keep the font at a crisp preset.
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
class BushidoPartyBackground < SpriteWrapper
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
    b.fill_rect(0,0,Graphics.width,Graphics.height,BushidoPartyUI::BG_DARK)

    rounded_rect(b,22,14,468,274,BushidoPartyUI::WHITE,BushidoPartyUI::BG)

    # Soft spotlight behind the focused Pokemon.
    cx=145; cy=117; r=104
    (-r).step(r,4) do |dy|
      dx=Math.sqrt([r*r-dy*dy,0].max).to_i
      b.fill_rect(cx-dx,cy+dy,dx*2,4,BushidoPartyUI::PANEL_LIGHT)
    end

    # Bottom party shelf.
    b.fill_rect(0,294,Graphics.width,4,BushidoPartyUI::WHITE)
    b.fill_rect(0,298,Graphics.width,4,BushidoPartyUI::BG_DARK)
    b.fill_rect(0,302,Graphics.width,82,BushidoPartyUI::PANEL_DARK)
  end
end


#===============================================================================
# Bottom party slot
#===============================================================================
class BushidoPartySlot < SpriteWrapper
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

    # Small bit of motion when the selection changes.
    @hover_amount = 0.0
    @hover_target = 0.0
    @base_y = BushidoPartyUI::DOCK_Y + 4

    self.bitmap = Bitmap.new(BushidoPartyUI::SLOT_W, 82)
    self.x = BushidoPartyUI.slot_x(index)
    self.y = @base_y
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
    @hover_target = (@selected || @preselected) ? 1.0 : 0.0

    # Selection box itself snaps immediately so two selected boxes are never
    # visible at once. Motion is reserved for the icon response.
    refresh
  end

  def preselected=(value)
    return if @preselected == value
    @preselected = value
    @hover_target = (@selected || @preselected) ? 1.0 : 0.0
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
    b = self.bitmap
    b.clear

    # Selection and switch-source are deliberately different.
    # Red = where the cursor is now. Gold = Pokemon being moved from.
    if @selected
      inset = 7
      top = 14
      h = 48

      b.fill_rect(inset, top, BushidoPartyUI::SLOT_W-inset*2, h, BushidoPartyUI::RED)
      b.fill_rect(inset+2, top+2, BushidoPartyUI::SLOT_W-(inset+2)*2, h-4, BushidoPartyUI::PANEL)

      # Small downward target notch.
      cx = BushidoPartyUI::SLOT_W / 2
      b.fill_rect(cx-4, 10, 8, 2, BushidoPartyUI::RED)
      b.fill_rect(cx-2, 12, 4, 2, BushidoPartyUI::RED)
    end

    if @preselected
      # Source gets corner brackets rather than another full box.
      gold = BushidoPartyUI::GOLD
      left = 5
      right = BushidoPartyUI::SLOT_W - 6
      top = 12
      bottom = 63

      # 2px chunky corner brackets.
      b.fill_rect(left, top, 12, 2, gold)
      b.fill_rect(left, top, 2, 12, gold)
      b.fill_rect(right-10, top, 12, 2, gold)
      b.fill_rect(right, top, 2, 12, gold)

      b.fill_rect(left, bottom, 12, 2, gold)
      b.fill_rect(left, bottom-10, 2, 12, gold)
      b.fill_rect(right-10, bottom, 12, 2, gold)
      b.fill_rect(right, bottom-10, 2, 12, gold)

      # Tiny upward source marker.
      cx = BushidoPartyUI::SLOT_W / 2
      b.fill_rect(cx-2, 8, 4, 2, gold)
      b.fill_rect(cx-4, 10, 8, 2, gold)
    end

    # Small HP bar under each party icon.
    bw = 50
    bx = (BushidoPartyUI::SLOT_W-bw)/2
    by = 69
    bh = 8

    b.fill_rect(bx, by, bw, bh, BushidoPartyUI::HP_BG)
    b.fill_rect(bx+2, by+2, bw-4, bh-4, Color.new(34,31,29))

    if @pokemon && @pokemon.totalhp>0 && @pokemon.hp>0
      fill=((bw-4)*@pokemon.hp.to_f/@pokemon.totalhp).round
      fill=1 if fill<1
      b.fill_rect(bx+2,by+2,fill,bh-4,BushidoPartyUI.hp_color(@pokemon))
    end

    update_icon_position
  end

  def update_icon_position
    return if !@icon || @icon.disposed?

    # Tiny icon lift so moving through the row doesn't feel totally static.
    lift = (2 * @hover_amount).round
    @icon.x = self.x + BushidoPartyUI::SLOT_W/2
    @icon.y = self.y + 46 - lift

    if @item
      @item.x = self.x + 58
      @item.y = self.y + 52 - lift
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

    # Smooth hover interpolation.
    speed = 0.22
    old = @hover_amount
    @hover_amount += (@hover_target - @hover_amount) * speed

    if (@hover_target - @hover_amount).abs < 0.01
      @hover_amount = @hover_target
    end

    if (old - @hover_amount).abs > 0.001
      self.y = @base_y
      refresh
    end

    @icon.update if @icon && !@icon.disposed?
    @item.update if @item && !@item.disposed?
  end
end

class BushidoPartyBlankSlot < SpriteWrapper
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
    self.bitmap = Bitmap.new(BushidoPartyUI::SLOT_W, 82)
    self.x = BushidoPartyUI.slot_x(index)
    self.y = BushidoPartyUI::DOCK_Y + 4
  end

  def refresh; end
  def dispose
    self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
    super
  end
end

class BushidoPartyInvisibleAction < SpriteWrapper
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
# Bushido-style Info Panel Component
#===============================================================================
class BushidoPartyInfoPanel < SpriteWrapper
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
    b.fill_rect(4,0,PANEL_W-8,PANEL_H,BushidoPartyUI::WHITE)
    b.fill_rect(0,4,PANEL_W,PANEL_H-8,BushidoPartyUI::WHITE)
    b.fill_rect(3,3,PANEL_W-6,PANEL_H-6,BushidoPartyUI::PANEL)
  end

  def refresh
    b = self.bitmap
    b.clear
    draw_panel_frame(b)
    return if !@pokemon

    pkmn = @pokemon
    accent = BushidoPartyUI.type_accent(pkmn)
    b.fill_rect(7, 5, PANEL_W-14, 2, accent)

    # Name, gender and level.
    BushidoPartyUI.set_primary_font(b)
    name_h = b.text_size(pkmn.name).height
    BushidoPartyUI.draw_text(
      b, pkmn.name,
      10, 13, 112, name_h,
      0,
      BushidoPartyUI::WHITE, BushidoPartyUI::SHADOW
    )

    if !pkmn.egg?
      # Gender and level use Essentials' own dedicated small Pokemon font.
      BushidoPartyUI.set_ui_font(b)
      meta_h = b.text_size("Ag").height

      if pkmn.male?
        BushidoPartyUI.draw_text(
          b, _INTL("♂"),
          123, 13, 18, meta_h,
          1,
          BushidoPartyUI::MALE, BushidoPartyUI::SHADOW
        )
      elsif pkmn.female?
        BushidoPartyUI.draw_text(
          b, _INTL("♀"),
          123, 13, 18, meta_h,
          1,
          BushidoPartyUI::FEMALE, BushidoPartyUI::SHADOW
        )
      end

      BushidoPartyUI.draw_text(
        b, _INTL("Lv. {1}", pkmn.level),
        143, 13, 62, meta_h,
        1,
        BushidoPartyUI::WHITE, BushidoPartyUI::SHADOW
      )

      # HP strip.
      strip_y = 31
      strip_h = 15
      strip_dark = Color.new(74, 69, 78)
      b.fill_rect(3, strip_y, PANEL_W-6, strip_h, strip_dark)

      # Compact custom HP mark with visible spacing between H and P.
      hp_x = 8
      hp_y = strip_y + 4
      c = BushidoPartyUI::WHITE

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

        hp_color = BushidoPartyUI.hp_color(pkmn)

        base =
          if hp_color == BushidoPartyUI::HP_GREEN
            Color.new(42, 186, 78)
          elsif hp_color == BushidoPartyUI::HP_YELLOW
            Color.new(204, 158, 43)
          else
            Color.new(193, 57, 55)
          end

        hi =
          if hp_color == BushidoPartyUI::HP_GREEN
            Color.new(68, 233, 105)
          elsif hp_color == BushidoPartyUI::HP_YELLOW
            Color.new(240, 196, 67)
          else
            Color.new(235, 80, 76)
          end

        low =
          if hp_color == BushidoPartyUI::HP_GREEN
            Color.new(29, 126, 57)
          elsif hp_color == BushidoPartyUI::HP_YELLOW
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
      BushidoPartyUI.set_ui_font(b)
      hp_fraction = sprintf("%d/%d", pkmn.hp, pkmn.totalhp)
      fraction_h = b.text_size(hp_fraction).height
      BushidoPartyUI.draw_text(
        b, hp_fraction,
        3, 53, PANEL_W-6, fraction_h,
        1,
        BushidoPartyUI::WHITE, BushidoPartyUI::SHADOW
      )
    end
  end

  def dispose
    self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
    super
  end
end

#===============================================================================
# Bushido-style Action Button Component
#===============================================================================
class BushidoPartyActionButton < SpriteWrapper
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
    @focus_amount = 0.0
    @focus_target = 0.0
    @accent = BushidoPartyUI::GOLD
    @base_x = 276
    self.x = @base_x
    self.y = 35 + index * 46
    refresh
  end

  def label=(value)
    @label = value.to_s
    refresh
  end

  def accent=(value)
    return if !value
    @accent = value
    refresh
  end

  def selected=(value)
    return if @selected == value
    @selected = value
    @focus_target = @selected ? 1.0 : 0.0
  end

  def selected
    @selected
  end

  def refresh
    b = self.bitmap
    b.clear

    border = @selected ? @accent : BushidoPartyUI::WHITE
    b.fill_rect(3,4,BUTTON_W,BUTTON_H,Color.new(35,29,40,75))
    b.fill_rect(5,0,BUTTON_W-10,BUTTON_H,border)
    b.fill_rect(0,5,BUTTON_W,BUTTON_H-10,border)
    b.fill_rect(3,3,BUTTON_W-6,BUTTON_H-6,BushidoPartyUI::PANEL)
    rail = BushidoPartyUI.mix(BushidoPartyUI::PANEL_DARK, @accent,
                              @selected ? 0.55 : 0.24)
    b.fill_rect(BUTTON_W-31,5,27,BUTTON_H-10,rail)
    BushidoPartyUI.set_ui_font(b)
    th = b.text_size(@label).height
    ty = ((BUTTON_H - th) / 2)
    BushidoPartyUI.draw_text(
      b, @label,
      12, ty,
      BUTTON_W-49, th,
      0
    )

    if @selected
      mx=BUTTON_W-21
      my=BUTTON_H/2
      b.fill_rect(mx,my-5,5,10,BushidoPartyUI::WHITE)
      b.fill_rect(mx+5,my-3,3,6,BushidoPartyUI::WHITE)
      b.fill_rect(mx+8,my-1,2,2,BushidoPartyUI::WHITE)
    end
  end


  def update
    super
    old = @focus_amount
    @focus_amount += (@focus_target - @focus_amount) * 0.24
    if (@focus_target - @focus_amount).abs < 0.01
      @focus_amount = @focus_target
    end

    if (old - @focus_amount).abs > 0.001
      # Selected buttons ease a few pixels left, like they're being pulled out.
      self.x = @base_x - (4 * @focus_amount).round
      refresh
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

    @sprites["background"] = BushidoPartyBackground.new(@viewport)
    @sprites["background"].z = 0

    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["overlay"].z = 8
    BushidoPartyUI.set_font(@sprites["overlay"].bitmap)

    # Main UI pieces.
    @sprites["infoPanel"] = BushidoPartyInfoPanel.new(@viewport)
    @action_buttons = []

    for i in 0...6
      if @party[i]
        @sprites["pokemon#{i}"] = BushidoPartySlot.new(@party[i], i, @viewport)
      else
        @sprites["pokemon#{i}"] = BushidoPartyBlankSlot.new(@party[i], i, @viewport)
      end
      @sprites["pokemon#{i}"].text = annotations[i] if annotations
    end

    # Hidden compatibility targets for stock party logic.
    @sprites["pokemon6"] = BushidoPartyInvisibleAction.new(@viewport)
    @sprites["pokemon7"] = BushidoPartyInvisibleAction.new(@viewport) if @multiselect

    # Use the battle sprite for the focused Pokemon.
    @sprites["activePokemon"] = PokemonSprite.new(@viewport)
    @sprites["activePokemon"].z = 6
    setActivePokemonBitmap(@party[0])

    # Show the focused Pokemon's held item next to it.
    @sprites["focusItemBack"] = BitmapSprite.new(42, 42, @viewport)
    @sprites["focusItemBack"].x = 202
    @sprites["focusItemBack"].y = 50
    @sprites["focusItemBack"].z = 5

    ib = @sprites["focusItemBack"].bitmap
    ib.clear
    cx = 21
    cy = 21
    r  = 19
    (-r).step(r, 2) do |dy|
      dx = Math.sqrt([r*r - dy*dy, 0].max).to_i
      ib.fill_rect(cx-dx, cy+dy, dx*2, 2, BushidoPartyUI::WHITE)
    end

    @sprites["focusItem"] = ItemIconSprite.new(0, 0, @party[0].item, @viewport)
    @sprites["focusItem"].x = 223
    @sprites["focusItem"].y = 71
    @sprites["focusItem"].z = 7
    @sprites["focusItem"].zoom_x = 0.5
    @sprites["focusItem"].zoom_y = 0.5

    refreshFocusItem(@party[0])

    @activecmd = 0
    @last_activecmd = 0
    @focus_anim = 1.0
    @sprites["pokemon0"].selected = true if @sprites["pokemon0"]

    refreshBushidoUI

    # Normal menu fade-in.
    pbFadeInAndShow(@sprites) { update }
    playFocusedPokemonCry(selectedPokemon)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { update }

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
    bounds=BushidoPartyUI.visible_bounds(spr.bitmap)
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

  def pokemonHasHeldItem?(pkmn)
    return false if !pkmn
    begin
      return pkmn.item && pkmn.item != 0
    rescue
      return false
    end
  end

  def refreshFocusItem(pkmn)
    item = @sprites["focusItem"]
    back = @sprites["focusItemBack"]
    return if !item || !back

    has_item = pokemonHasHeldItem?(pkmn)
    item.visible = has_item
    back.visible = has_item

    if has_item
      begin
        item.item = pkmn.item
      rescue
        # ItemIconSprite in v18 also accepts the item in its constructor.
        # Recreate it only if this particular fork doesn't expose item=.
        old_x = item.x
        old_y = item.y
        old_z = item.z
        item.dispose if !item.disposed?
        @sprites["focusItem"] = ItemIconSprite.new(0, 0, pkmn.item, @viewport)
        @sprites["focusItem"].x = old_x
        @sprites["focusItem"].y = old_y
        @sprites["focusItem"].z = old_z
        @sprites["focusItem"].zoom_x = 0.5
        @sprites["focusItem"].zoom_y = 0.5
      end
    end
  end

  def playFocusedPokemonCry(pkmn)
    return if !pkmn || pkmn.egg?

    begin
      pbPlayCry(pkmn)
    rescue
      begin
        pbPlayCry(pkmn.species)
      rescue
      end
    end
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
    refreshFocusItem(selectedPokemon)

    # Update the focused Pokemon's info card.
    @sprites["infoPanel"].pokemon = selectedPokemon if @sprites["infoPanel"]

    # The overlay is just for temporary messages and page arrows.
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

    # White rounded-ish Bushido panel.
    b.fill_rect(x+4,y,w-8,h,BushidoPartyUI::WHITE)
    b.fill_rect(x,y+4,w,h-8,BushidoPartyUI::WHITE)
    b.fill_rect(x+3,y+3,w-6,h-6,BushidoPartyUI::PANEL)

    # -----------------------------------------------------------------------
    # TOP ROW
    # Bigger name on left, gender + level grouped tightly on the right.
    # -----------------------------------------------------------------------
    BushidoPartyUI.draw_scaled_text(
      b, pkmn.name,
      x+10, y+2, 116, 29,
      0.70, 0,
      BushidoPartyUI::WHITE, BushidoPartyUI::SHADOW
    )

    if !pkmn.egg?
      if pkmn.male?
        BushidoPartyUI.draw_scaled_text(
          b, _INTL("♂"),
          x+126, y+4, 18, 25,
          0.50, 1,
          BushidoPartyUI::MALE, BushidoPartyUI::SHADOW
        )
      elsif pkmn.female?
        BushidoPartyUI.draw_scaled_text(
          b, _INTL("♀"),
          x+126, y+4, 18, 25,
          0.50, 1,
          BushidoPartyUI::FEMALE, BushidoPartyUI::SHADOW
        )
      end

      BushidoPartyUI.draw_scaled_text(
        b, _INTL("Lv. {1}",pkmn.level),
        x+145, y+4, 60, 25,
        0.50, 1,
        BushidoPartyUI::WHITE, BushidoPartyUI::SHADOW
      )

      # ---------------------------------------------------------------------
      # HP row sits lower and uses the full width well.
      # ---------------------------------------------------------------------
      BushidoPartyUI.draw_scaled_text(
        b, _INTL("HP"),
        x+10, y+33, 26, 18,
        0.50, 0,
        BushidoPartyUI::WHITE, BushidoPartyUI::SHADOW
      )

      bx=x+38
      by=y+38
      bw=164
      b.fill_rect(bx,by,bw,9,BushidoPartyUI::HP_BG)

      if pkmn.totalhp>0 && pkmn.hp>0
        fill=((bw-2)*pkmn.hp.to_f/pkmn.totalhp).round
        fill=1 if fill<1
        b.fill_rect(
          bx+1,by+1,fill,7,
          BushidoPartyUI.hp_color(pkmn)
        )
      end

      # Center fraction exactly under the bar.
      BushidoPartyUI.draw_scaled_text(
        b, sprintf("%d/%d",pkmn.hp,pkmn.totalhp),
        bx, y+49, bw, 19,
        0.50, 1,
        BushidoPartyUI::WHITE, BushidoPartyUI::SHADOW
      )
    end
  end

  # Build the same commands the normal party screen would offer, but show
  # them as soon as the Pokemon is hovered.
  def previewCommands
    pkmn=selectedPokemon
    return [] if !pkmn

    commands=[]
    commands.push(_INTL("Summary"))
    commands.push(_INTL("Debug")) if $DEBUG

    # Field moves that can be used directly from the party screen.
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

      # I keep Rename near Item because both are Pokemon-specific management
      # actions, and putting it before Cancel keeps the menu order predictable.
      commands.push(_INTL("Rename"))
    end

    commands.push(_INTL("Cancel"))
    return commands
  end

  def switchingParty?
    for i in 0...6
      s = @sprites["pokemon#{i}"]
      return true if s && s.respond_to?(:preselected) && s.preselected
    end
    return false
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

    # Reuse five button sprites instead of recreating them every refresh.
    for i in 0...5
      if !@action_buttons[i]
        @action_buttons[i] = BushidoPartyActionButton.new("", i, @viewport)

        # Keep these in the main sprite hash so the stock scene fade handles
        # them exactly like the background, info card and party icons.
        @sprites["actionButton#{i}"] = @action_buttons[i]
      end

      button = @action_buttons[i]

      if i < visible.length
        raw = visible[i]
        cmd = raw.is_a?(Array) ? raw[0] : raw
        label = (cmd.to_s.downcase == "move") ? _INTL("Swap") : cmd.to_s

        button.visible = true
        button.label = label
        button.accent = BushidoPartyUI.type_accent(selectedPokemon)

        absolute_index = page_start + i
        button.selected = (@command_mode && absolute_index == @command_index)
      else
        button.visible = false
        button.selected = false
      end
    end
  end

  def drawPagingArrows(b)
    if switchingParty?
      BushidoPartyUI.set_ui_font(b)
      pbDrawShadowText(
        b, 276, 10, 194, 24,
        _INTL("SWAP WITH"),
        BushidoPartyUI::GOLD, BushidoPartyUI::SHADOW, 1
      )
    end

    commands = currentPreviewCommands
    return if commands.length <= 5

    max_page = (commands.length - 1) / 5
    x = 373

    if @command_page < max_page
      ay = 268
      b.fill_rect(x-5,ay,10,2,BushidoPartyUI::WHITE)
      b.fill_rect(x-3,ay+2,6,2,BushidoPartyUI::WHITE)
      b.fill_rect(x-1,ay+4,2,2,BushidoPartyUI::WHITE)
    end

    if @command_page > 0
      ay = 22
      b.fill_rect(x-1,ay,2,2,BushidoPartyUI::WHITE)
      b.fill_rect(x-3,ay+2,6,2,BushidoPartyUI::WHITE)
      b.fill_rect(x-5,ay+4,10,2,BushidoPartyUI::WHITE)
    end
  end

  def drawActionArea(b)
    # Buttons draw themselves.
    refreshActionButtons
  end

  def drawMessage(b, text)
    # Temporary message in place of the action list.
    b.fill_rect(320, 78, 150, 116, BushidoPartyUI::PANEL_DARK)
    b.fill_rect(323, 81, 144, 110, BushidoPartyUI::PANEL_LIGHT)
    BushidoPartyUI.set_primary_font(b)

    # Basic word wrap that works with this old Ruby version.
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
        BushidoPartyUI::WHITE, BushidoPartyUI::SHADOW
      )
      y += 20
    end
  end

  def pbSetHelpText(helptext)
    @helptext = helptext
    refreshBushidoUI
  end

  def renameSelectedPokemon
    pkmn = selectedPokemon
    return if !pkmn || pkmn.egg?

    old_name = pkmn.name

    # Essentials forks don't all expose the same name-length constant.
    max_length = 12
    begin
      max_length = Pokemon::MAX_NAME_SIZE
    rescue
    end

    new_name = pbEnterPokemonName(
      _INTL("Give {1} a new name.", old_name),
      0,
      max_length,
      old_name,
      pkmn
    )

    return if !new_name || new_name == ""

    pkmn.name = new_name
    pbRefreshSingle(@activecmd)
  end

  def pbShowCommands(helptext, commands, index=0)
    return -1 if !commands || commands.length == 0

    # Stock PokemonPartyScreen builds its own command array. I add Rename here
    # instead of replacing that whole method, which keeps this override much
    # less fragile if the rest of the party logic changes later.
    shown_commands = commands.clone
    rename_index = -1

    pkmn = selectedPokemon
    if pkmn && !pkmn.egg?
      cancel_index = shown_commands.length - 1
      rename_index = cancel_index
      shown_commands.insert(rename_index, _INTL("Rename"))
    end

    # If the stock menu wanted to re-open on a specific command, shift that
    # index only when Rename was inserted before it.
    shown_index = index
    if rename_index >= 0 && shown_index >= rename_index
      shown_index += 1
    end

    @command_mode = true
    @command_commands = shown_commands
    @command_index = shown_index
    @command_index = 0 if @command_index < 0 ||
                          @command_index >= shown_commands.length
    @command_page = @command_index / 5
    refreshBushidoUI

    ret = -1

    loop do
      Graphics.update
      Input.update
      self.update

      old = @command_index

      if Input.repeat?(Input::UP)
        @command_index -= 1
        @command_index = shown_commands.length - 1 if @command_index < 0
      elsif Input.repeat?(Input::DOWN)
        @command_index += 1
        @command_index = 0 if @command_index >= shown_commands.length
      end

      if old != @command_index
        @command_page = @command_index / 5
        pbPlayCursorSE
        refreshBushidoUI
      end

      if Input.trigger?(Input::B)
        pbPlayCancelSE
        ret = -1
        break
      elsif Input.trigger?(Input::C)
        pbPlayDecisionSE

        if rename_index >= 0 && @command_index == rename_index
          # The naming scroll is already a modal, so this drops straight into
          # the same rename UI used everywhere else in Bushido.
          renameSelectedPokemon

          # Coming back from text entry can change the name width, so redraw
          # everything before returning to the command list.
          @command_commands = shown_commands
          refreshBushidoUI
          next
        end

        ret = @command_index

        # Remove the slot we inserted before handing the result back to the
        # stock party screen. It should never know Rename existed.
        if rename_index >= 0 && ret > rename_index
          ret -= 1
        end
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

    # Party notifications disappear on their own, but C/B can dismiss early.
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

  def animateFocusedPokemonChange(old_index, new_index)
    spr = @sprites["activePokemon"]
    info = @sprites["infoPanel"]
    item = @sprites["focusItem"]
    item_back = @sprites["focusItemBack"]

    return if !spr

    # Fade the old Pokemon out.
    4.times do |i|
      spr.opacity = 255 - ((i+1) * 48)
      spr.x = 145 - ((i+1) * 3)
      info.opacity = 255 - ((i+1) * 36) if info
      item.opacity = 255 - ((i+1) * 48) if item
      item_back.opacity = 255 - ((i+1) * 48) if item_back
      Graphics.update
      update
    end

    # Swap to the new Pokemon while everything is mostly hidden.
    @activecmd = new_index
    refreshActivePokemon
    @sprites["infoPanel"].pokemon = selectedPokemon if @sprites["infoPanel"]
    refreshFocusItem(selectedPokemon)
    refreshActionButtons

    spr.x = 157
    spr.opacity = 60
    info.opacity = 90 if info
    item.opacity = 60 if item
    item_back.opacity = 60 if item_back

    # Bring the new Pokemon back in.
    5.times do |i|
      t = (i+1) / 5.0
      spr.opacity = (60 + (195 * t)).round
      spr.x = (157 - (12 * t)).round
      info.opacity = (90 + (165 * t)).round if info
      item.opacity = (60 + (195 * t)).round if item
      item_back.opacity = (60 + (195 * t)).round if item_back
      Graphics.update
      update
    end

    spr.x = 145
    spr.opacity = 255
    info.opacity = 255 if info
    item.opacity = 255 if item
    item_back.opacity = 255 if item_back
  end

  def pbSelect(item)
    old = @activecmd
    @command_page = 0 if !@command_mode

    # Update dock highlight immediately.
    for i in 0...6
      s = @sprites["pokemon#{i}"]
      s.selected = (i == item) if s
    end

    if old != item && old && old >= 0 && old < @party.length
      animateFocusedPokemonChange(old, item)
      playFocusedPokemonCry(selectedPokemon)
    else
      @activecmd = item
      refreshBushidoUI
    end
  end

  def pbPreSelect(item)
    @activecmd = item
  end

  # Party-row navigation.
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
      newsel = oldsel

      if Input.repeat?(Input::LEFT)
        newsel -= 1
        newsel = @party.length - 1 if newsel < 0
      elsif Input.repeat?(Input::RIGHT)
        newsel += 1
        newsel = 0 if newsel >= @party.length
      elsif Input.repeat?(Input::UP)
        # Up/down mirror left/right for controller muscle memory.
        newsel -= 1
        newsel = @party.length - 1 if newsel < 0
      elsif Input.repeat?(Input::DOWN)
        newsel += 1
        newsel = 0 if newsel >= @party.length
      end

      if newsel != oldsel
        pbPlayCursorSE
        pbSelect(newsel)
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

    oldsprite.x = BushidoPartyUI.slot_x(oldid)
    newsprite.x = BushidoPartyUI.slot_x(newid)
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
        @sprites["pokemon#{i}"] = BushidoPartySlot.new(@party[i], i, @viewport)
      else
        @sprites["pokemon#{i}"] = BushidoPartyBlankSlot.new(@party[i], i, @viewport)
      end
      @sprites["pokemon#{i}"].text = oldtext[i]
    end

    pbSelect(lastselected)
  end

  def pbRefresh
    for i in 0...6
      sprite = @sprites["pokemon#{i}"]
      next if !sprite
      if sprite.is_a?(BushidoPartySlot)
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

    if sprite.is_a?(BushidoPartySlot)
      sprite.pokemon = @party[i] if @party[i]
    else
      sprite.refresh
    end

    refreshBushidoUI
  end

  def update
    pbUpdateSpriteHash(@sprites)
  end
end

#===============================================================================
# Quick test
#===============================================================================
def pbBushidoPartyTest
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
