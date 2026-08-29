
# Enables the Bushido party screen.
BUSHIDO_PARTY_UI_ENABLED = true unless defined?(BUSHIDO_PARTY_UI_ENABLED)

if BUSHIDO_PARTY_UI_ENABLED

# Party UI helpers and styling
module BushidoPartyUI
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
  EXP_BLUE     = Color.new(64, 144, 224)
  HEART_PURPLE = Color.new(144, 78, 188)

  UI_ASSET_ROOT = "Graphics/Pictures/Party/Bushido"

  DOCK_Y       = 302
  SLOT_W       = 75
  SLOT_GAP     = 6
  SLOT_START_X = 17

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
      "FAIRY"    => Color.new(220,132,156)
    }
    return colors[name] || GOLD
  end

  def self.type_accent(pokemon)
    return GOLD if !pokemon
    begin
      return type_color(pokemon.type1)
    rescue
      return GOLD
    end
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

  def self.floor2(value)
    (value.to_i / 2) * 2
  end

  def self.ceil2(value)
    ((value.to_i + 1) / 2) * 2
  end

  def self.fill2(bitmap, x, y, w, h, color)
    x = floor2(x)
    y = floor2(y)
    w = ceil2(w)
    h = ceil2(h)
    return if w <= 0 || h <= 0
    bitmap.fill_rect(x, y, w, h, color)
  end

  def self.circle2(bitmap, cx, cy, radius, color)
    cx = floor2(cx)
    cy = floor2(cy)
    radius = floor2(radius)

    y = -radius
    while y <= radius
      x = -radius
      while x <= radius
        if (x * x + y * y) <= (radius * radius)
          bitmap.fill_rect(cx + x, cy + y, 2, 2, color)
        end
        x += 2
      end
      y += 2
    end
  end

  def self.draw_type_bar(bitmap, x, y, w, h, pokemon)
    return if !pokemon
    c1 = type_color(pokemon.type1)
    dual = pokemon.type2 && pokemon.type2 != pokemon.type1
    if dual
      half = floor2(w / 2)
      fill2(bitmap, x, y, half, h, c1)
      fill2(bitmap, x + half, y, w - half, h, type_color(pokemon.type2))
    else
      fill2(bitmap, x, y, w, h, c1)
    end
  end

  def self.draw_type_icon(bitmap, type_id, x, y)
    begin
      sheet = pbBitmap("Graphics/Pictures/types")
      icon_w = 64
      icon_h = 28
      if sheet.height < (type_id + 1) * icon_h
        count = 18
        icon_h = sheet.height / count if sheet.height >= count
      end
      src = Rect.new(0, type_id * icon_h, icon_w, icon_h)
      bitmap.blt(x, y, sheet, src)
      return true
    rescue
      return false
    end
  end

  def self.shadow_pokemon?(pokemon)
    return false if !pokemon
    begin
      return pokemon.shadowPokemon? if pokemon.respond_to?(:shadowPokemon?)
    rescue
    end
    begin
      return pokemon.shadow? if pokemon.respond_to?(:shadow?)
    rescue
    end
    begin
      return pokemon.isShadow? if pokemon.respond_to?(:isShadow?)
    rescue
    end
    return false
  end

  def self.shadow_heart_value(pokemon)
    return nil if !pokemon
    [:heartgauge, :heartGauge, :heart_gauge].each do |method_name|
      begin
        return pokemon.send(method_name) if pokemon.respond_to?(method_name)
      rescue
      end
    end
    return nil
  end

  def self.shadow_heart_max(pokemon)
    return nil if !pokemon
    [:maxheartgauge, :maxHeartGauge, :heartgaugemax, :heartGaugeMax].each do |method_name|
      begin
        return pokemon.send(method_name) if pokemon.respond_to?(method_name)
      rescue
      end
    end
    return 3840
  end

  def self.asset(name)
    return "#{UI_ASSET_ROOT}/#{name}"
  end

  def self.blit_asset(bitmap, name, x=0, y=0)
    source = Bitmap.new(asset(name))
    bitmap.blt(x, y, source, Rect.new(0, 0, source.width, source.height))
    source.dispose
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

  def self.status_icon_color(pokemon)
    return nil if !pokemon || pokemon.hp <= 0 || pokemon.status <= 0

    name = ""
    begin
      name = PBStatuses.getName(pokemon.status).to_s.upcase
    rescue
      name = ""
    end

    case name
    when "POISON", "BADLY POISONED"
      Color.new(164, 76, 184)
    when "BURN"
      Color.new(224, 92, 54)
    when "PARALYSIS", "PARALYZED"
      Color.new(236, 198, 58)
    when "SLEEP"
      Color.new(100, 112, 190)
    when "FROZEN", "FREEZE"
      Color.new(104, 202, 228)
    else
      Color.new(180, 180, 180)
    end
  end

  def self.status_tint(pokemon)
    return Color.new(0,0,0,0) if !pokemon
    return Color.new(0,0,0,150) if pokemon.hp <= 0

    name = ""
    begin
      name = PBStatuses.getName(pokemon.status).to_s.upcase if pokemon.status > 0
    rescue
      name = ""
    end

    case name
    when "POISON", "BADLY POISONED"
      Color.new(150, 70, 170, 72)
    when "BURN"
      Color.new(220, 80, 48, 68)
    when "PARALYSIS", "PARALYZED"
      Color.new(230, 190, 48, 72)
    when "SLEEP"
      Color.new(90, 100, 170, 64)
    when "FROZEN", "FREEZE"
      Color.new(90, 190, 220, 68)
    else
      Color.new(0,0,0,0)
    end
  end

    def self.set_primary_font(bitmap)
      BushidoFonts.apply(bitmap, :label)
    end

    def self.set_ui_font(bitmap)
      BushidoFonts.apply(bitmap, :label)
    end
    
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

# Draws the party screen background.
class BushidoPartyBackground < SpriteWrapper
  def initialize(viewport=nil)
    super(viewport)
    self.bitmap = Bitmap.new(BushidoPartyUI.asset("background"))
  end

  def dispose
    self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
    super
  end
end

# Draws and updates a Pokemon party slot.
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
    @icon.color = BushidoPartyUI.status_tint(@pokemon)

    @item = ItemIconSprite.new(0, 0, @pokemon.item, viewport)
    @item.zoom_x = 0.25
    @item.zoom_y = 0.25
    @item.z = self.z + 3
    @item.visible = (@pokemon.item && @pokemon.item != 0)

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

    if @icon && !@icon.disposed?
      @icon.pokemon = value
      @icon.color = BushidoPartyUI.status_tint(value)
    end

    if @item && !@item.disposed?
      begin
        @item.item = value.item
      rescue
      end
      @item.visible = (value.item && value.item != 0)
    end
    refresh
  end

  def selected=(value)
    return if @selected == value
    @selected = value
    @hover_target = (@selected || @preselected) ? 1.0 : 0.0

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

  def compatibility_annotation?
    return @text == _INTL("ABLE") || @text == _INTL("NOT ABLE")
  end

  def item_target_compatible?
    return @text == _INTL("ABLE")
  end

  def item_target_incompatible?
    return @text == _INTL("NOT ABLE")
  end

  def hp
    return @pokemon.hp
  end

  def refresh
    return if disposed?
    b = self.bitmap
    b.clear

    BushidoPartyUI.blit_asset(b, "party_slot_selected") if @selected
    BushidoPartyUI.blit_asset(b, "party_slot_preselected") if @preselected

    BushidoPartyUI.blit_asset(b, "party_slot_base")

    if compatibility_annotation?
      BushidoPartyUI.set_ui_font(b)
      label = item_target_incompatible? ? _INTL("NO") : _INTL("OK")
      base = item_target_incompatible? ? BushidoPartyUI::RED : BushidoPartyUI::GOLD
      pbDrawShadowText(
        b, 6, 2, BushidoPartyUI::SLOT_W-12, 20,
        label,
        base, BushidoPartyUI::SHADOW, 1
      )
    end

    bw = 50
    bx = 12

    hp_y = 62
    if @pokemon && @pokemon.totalhp>0 && @pokemon.hp>0
      fill=((bw-4)*@pokemon.hp.to_f/@pokemon.totalhp).round
      fill=2 if fill<2
      fill=BushidoPartyUI.floor2(fill)
      BushidoPartyUI.fill2(
        b, bx+2, hp_y+2, fill, 2,
        BushidoPartyUI.hp_color(@pokemon)
      )
    end

    exp_y = 70
    if @pokemon && !@pokemon.egg?
      meter_fill = 0
      meter_color = BushidoPartyUI::EXP_BLUE

      if BushidoPartyUI.shadow_pokemon?(@pokemon)
        meter_color = BushidoPartyUI::HEART_PURPLE
        value = BushidoPartyUI.shadow_heart_value(@pokemon)
        max_value = BushidoPartyUI.shadow_heart_max(@pokemon)
        if value && max_value && max_value > 0
          meter_fill = ((bw-4) * value.to_f / max_value).round
        end
      else
        begin
          start_exp = PBExperience.pbGetStartExperience(@pokemon.level, @pokemon.growthrate)
          end_exp   = PBExperience.pbGetStartExperience(@pokemon.level + 1, @pokemon.growthrate)
          current   = @pokemon.exp - start_exp
          span      = [end_exp - start_exp, 1].max
          meter_fill = ((bw-4) * current.to_f / span).round
        rescue
          meter_fill = 0
        end
      end

      meter_fill = BushidoPartyUI.floor2(meter_fill)
      meter_fill = 0 if meter_fill < 0
      meter_fill = bw-4 if meter_fill > bw-4
      BushidoPartyUI.fill2(b, bx+2, exp_y+2, meter_fill, 2, meter_color)
    end

    update_icon_position
  end

  def update_icon_position
    return if !@icon || @icon.disposed?

    lift = (2 * @hover_amount).round
    @icon.x = self.x + BushidoPartyUI::SLOT_W/2
    @icon.y = self.y + 40 - lift
    @icon.opacity = item_target_incompatible? ? 96 : 255

    if @item
      @item.x = self.x + 60
      @item.y = self.y + 48 - lift
      @item.opacity = item_target_incompatible? ? 96 : 255
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
    @item.color = value if @item && !@item.disposed?
  end

  def update
    super

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

# Handles empty party slots.
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

# Provides hidden targets used by the stock party logic.
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

# Draws the selected Pokemon's HP and basic info.
class BushidoPartyInfoPanel < SpriteWrapper
  PANEL_W = 216
  PANEL_H = 73

  def initialize(viewport=nil)
    super(viewport)
    self.bitmap = Bitmap.new(PANEL_W, PANEL_H)
    self.x = 43
    self.y = 212
    self.z = 9
    @pokemon = nil
  end

  def pokemon=(pkmn)
    @pokemon = pkmn
    refresh
  end

  def draw_panel_frame(b)
    BushidoPartyUI.blit_asset(b, "info_panel")
  end

  def refresh
    b = self.bitmap
    b.clear
    draw_panel_frame(b)
    return if !@pokemon

    pkmn = @pokemon
    accent = BushidoPartyUI.type_accent(pkmn)
    BushidoPartyUI.draw_type_bar(b, 8, 6, PANEL_W-16, 2, pkmn)

    BushidoPartyUI.set_primary_font(b)
    name_h = b.text_size(pkmn.name).height
    BushidoPartyUI.draw_text(
      b, pkmn.name,
      10, 13, 112, name_h,
      0,
      BushidoPartyUI::WHITE, BushidoPartyUI::SHADOW
    )

    if !pkmn.egg?
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

      bx = 30
      by = 32
      bw = 178
      bh = 14

      if pkmn.totalhp > 0 && pkmn.hp > 0
        fill = ((bw-4) * pkmn.hp.to_f / pkmn.totalhp).round
        fill = 2 if fill < 2
        fill = BushidoPartyUI.floor2(fill)

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

        fx = bx + 2
        fy = by + 2
        fh = bh - 4
        BushidoPartyUI.fill2(b, fx, fy,      fill, fh, base)
        BushidoPartyUI.fill2(b, fx, fy,      fill, 2,  hi)
        BushidoPartyUI.fill2(b, fx, fy+fh-2, fill, 2,  low)
      end
      BushidoPartyUI.set_ui_font(b)
      hp_fraction = sprintf("%d/%d", pkmn.hp, pkmn.totalhp)
      fraction_h = b.text_size(hp_fraction).height
      BushidoPartyUI.draw_text(
        b, hp_fraction,
        3, 49, PANEL_W-6, fraction_h,
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

# Draws the selected Pokemon's details.
class BushidoPartyDetailPanel < SpriteWrapper
  PANEL_W = 194
  PANEL_H = 241

  def initialize(viewport=nil)
    super(viewport)
    self.bitmap = Bitmap.new(PANEL_W, PANEL_H)
    self.x = 276
    self.y = 44
    self.z = 8
    @pokemon = nil
  end

  def pokemon=(pkmn)
    @pokemon = pkmn
    refresh
  end

  def species_name(pkmn)
    begin
      return PBSpecies.getName(pkmn.species)
    rescue
      return pkmn.name
    end
  end

  def layout
    return {
      :header     => Rect.new(8,   8, 178, 34),
      :type       => Rect.new(10,  50, 174, 32),
      :ability    => Rect.new(10,  86, 174, 32),
      :item       => Rect.new(10, 122, 174, 32),
      :meter      => Rect.new(10, 160, 174, 30),
      :traits     => Rect.new(10, 198, 174, 30)
    }
  end

  def draw_box_text(b, rect, text, align=0, base=nil, shadow=nil)
    base ||= BushidoPartyUI::WHITE
    shadow ||= BushidoPartyUI::SHADOW
    BushidoPartyUI.set_ui_font(b)
    th = b.text_size("Ag").height
    ty = rect.y + ((rect.height - th) / 2) + 2
    pbDrawShadowText(b, rect.x, ty, rect.width, th, text.to_s,
                     base, shadow, align)
  end

  def draw_condition_icons(b, pkmn, name_x, name_y)
    BushidoPartyUI.set_primary_font(b)
    text_w = b.text_size(species_name(pkmn)).width
    x = name_x + text_w + 8
    y = name_y + 8

    status_color = BushidoPartyUI.status_icon_color(pkmn)
    if status_color
      BushidoPartyUI.fill2(b, x+2, y,   4, 2, status_color)
      BushidoPartyUI.fill2(b, x,   y+2, 8, 4, status_color)
      BushidoPartyUI.fill2(b, x+2, y+6, 4, 2, status_color)
      x += 12
    end

    if BushidoPartyUI.shadow_pokemon?(pkmn)
      c = BushidoPartyUI::HEART_PURPLE
      BushidoPartyUI.fill2(b, x+2, y,   4, 2, c)
      BushidoPartyUI.fill2(b, x,   y+2, 2, 4, c)
      BushidoPartyUI.fill2(b, x+6, y+2, 2, 4, c)
      BushidoPartyUI.fill2(b, x+2, y+6, 4, 2, c)
    end
  end

  def draw_type_row(b, pkmn, rect)
    draw_box_text(
      b, Rect.new(rect.x, rect.y, 44, rect.height),
      _INTL("TYPE"), 0, BushidoPartyUI::GOLD
    )

    icon_y = rect.y + 2
    first_x = rect.x + 48

    drawn1 = BushidoPartyUI.draw_type_icon(b, pkmn.type1, first_x, icon_y)

    if pkmn.type2 && pkmn.type2 != pkmn.type1
      second_x = first_x + 64
      drawn2 = BushidoPartyUI.draw_type_icon(b, pkmn.type2, second_x, icon_y)

      if !drawn1
        draw_box_text(
          b, Rect.new(first_x, rect.y, 60, rect.height),
          PBTypes.getName(pkmn.type1), 1,
          BushidoPartyUI.type_color(pkmn.type1)
        )
      end

      if !drawn2
        draw_box_text(
          b, Rect.new(second_x, rect.y, 60, rect.height),
          PBTypes.getName(pkmn.type2), 1,
          BushidoPartyUI.type_color(pkmn.type2)
        )
      end
    elsif !drawn1
      draw_box_text(
        b, Rect.new(first_x, rect.y, 116, rect.height),
        PBTypes.getName(pkmn.type1), 0,
        BushidoPartyUI.type_color(pkmn.type1)
      )
    end
  end

  def draw_label_value(b, rect, label, value)
    label_w = 66
    draw_box_text(
      b, Rect.new(rect.x, rect.y, label_w, rect.height),
      label, 0, BushidoPartyUI::GOLD
    )
    draw_box_text(
      b, Rect.new(rect.x + label_w, rect.y, rect.width-label_w, rect.height),
      value, 0, BushidoPartyUI::WHITE
    )
  end

  def item_name(pkmn)
    begin
      return PBItems.getName(pkmn.item) if pkmn.item && pkmn.item != 0
    rescue
    end
    return _INTL("None")
  end

  def ability_name(pkmn)
    begin
      return PBAbilities.getName(pkmn.ability)
    rescue
    end
    return _INTL("None")
  end

  def nature_name(pkmn)
    begin
      return PBNatures.getName(pkmn.nature)
    rescue
    end
    begin
      return pkmn.natureName if pkmn.respond_to?(:natureName)
    rescue
    end
    return _INTL("—")
  end

  def friendship_value(pkmn)
    [:happiness, :friendship].each do |m|
      begin
        return pkmn.send(m).to_i if pkmn.respond_to?(m)
      rescue
      end
    end
    return 0
  end

  def draw_friendship_hearts(b, x, y, pkmn)
    value = friendship_value(pkmn)
    filled = ((value * 5) / 255.0).round
    filled = 0 if filled < 0
    filled = 5 if filled > 5

    5.times do |i|
      c = i < filled ? BushidoPartyUI::GOLD : BushidoPartyUI::PANEL_DARK
      hx = x + i * 12
      BushidoPartyUI.fill2(b, hx,   y,   4, 2, c)
      BushidoPartyUI.fill2(b, hx+6, y,   4, 2, c)
      BushidoPartyUI.fill2(b, hx,   y+2, 10, 4, c)
      BushidoPartyUI.fill2(b, hx+2, y+6, 6, 2, c)
      BushidoPartyUI.fill2(b, hx+4, y+8, 2, 2, c)
    end
  end

  def draw_meter(b, rect, pkmn)
    shadow = BushidoPartyUI.shadow_pokemon?(pkmn)
    label = shadow ? _INTL("HEART") : _INTL("EXP")
    color = shadow ? BushidoPartyUI::HEART_PURPLE : BushidoPartyUI::EXP_BLUE

    draw_box_text(
      b, Rect.new(rect.x, rect.y, 46, rect.height),
      label, 0,
      shadow ? BushidoPartyUI::HEART_PURPLE : BushidoPartyUI::GOLD
    )

    x = rect.x + 50
    y = rect.y + 10
    w = rect.width - 56
    h = 8

    BushidoPartyUI.fill2(b, x, y, w, h, BushidoPartyUI::HP_BG)
    BushidoPartyUI.fill2(b, x+2, y+2, w-4, h-4, Color.new(34,31,29))

    fill = 0

    if shadow
      value = BushidoPartyUI.shadow_heart_value(pkmn)
      max_value = BushidoPartyUI.shadow_heart_max(pkmn)
      if value && max_value && max_value > 0
        fill = ((w-4) * value.to_f / max_value).round
      end
    else
      begin
        start_exp = PBExperience.pbGetStartExperience(pkmn.level, pkmn.growthrate)
        end_exp   = PBExperience.pbGetStartExperience(pkmn.level + 1, pkmn.growthrate)
        current   = pkmn.exp - start_exp
        span      = [end_exp - start_exp, 1].max
        fill      = ((w-4) * current.to_f / span).round
      rescue
        fill = 0
      end
    end

    fill = BushidoPartyUI.floor2(fill)
    fill = 0 if fill < 0
    fill = w-4 if fill > w-4
    BushidoPartyUI.fill2(b, x+2, y+2, fill, h-4, color)
  end

  def draw_traits(b, rect, pkmn)
    draw_box_text(
      b,
      Rect.new(rect.x, rect.y, 104, rect.height),
      nature_name(pkmn),
      0,
      BushidoPartyUI::WHITE
    )

    draw_friendship_hearts(
      b,
      rect.x + 112,
      rect.y + 10,
      pkmn
    )
  end

  def refresh
    b = self.bitmap
    b.clear
    return if !@pokemon

    pkmn = @pokemon
    boxes = layout

    BushidoPartyUI.blit_asset(b, "detail_panel")

    header = boxes[:header]
    BushidoPartyUI.draw_type_bar(
      b, header.x, header.y+header.height-2,
      header.width, 2, pkmn
    )

    BushidoPartyUI.set_primary_font(b)
    th = b.text_size("Ag").height
    ty = header.y + ((header.height-th)/2) + 2
    pbDrawShadowText(
      b, header.x+10, ty, header.width-20, th,
      species_name(pkmn),
      BushidoPartyUI::WHITE, BushidoPartyUI::SHADOW, 0
    )
    draw_condition_icons(b, pkmn, header.x+10, ty)

    return if pkmn.egg?

    draw_type_row(b, pkmn, boxes[:type])
    draw_label_value(b, boxes[:ability], _INTL("ABILITY"), ability_name(pkmn))
    draw_label_value(b, boxes[:item], _INTL("ITEM"), item_name(pkmn))
    draw_meter(b, boxes[:meter], pkmn)
    draw_traits(b, boxes[:traits], pkmn)
  end

  def dispose
    self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
    super
  end
end

# Draws and animates party action buttons.
class BushidoPartyActionButton < SpriteWrapper
  BUTTON_W = 194
  BUTTON_H = 34

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
    self.y = 40 + index * 40
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
    BushidoPartyUI.fill2(b, 4, 4, BUTTON_W-4, BUTTON_H-2, Color.new(35,29,40,75))
    BushidoPartyUI.fill2(b, 6, 0, BUTTON_W-12, BUTTON_H, border)
    BushidoPartyUI.fill2(b, 0, 6, BUTTON_W, BUTTON_H-12, border)
    BushidoPartyUI.fill2(b, 4, 4, BUTTON_W-8, BUTTON_H-8, BushidoPartyUI::PANEL)

    rail = BushidoPartyUI.mix(
      BushidoPartyUI::PANEL_DARK, @accent,
      @selected ? 0.55 : 0.24
    )
    BushidoPartyUI.fill2(b, BUTTON_W-32, 6, 28, BUTTON_H-12, rail)
    BushidoPartyUI.set_ui_font(b)
    th = b.text_size(@label).height
    ty = ((BUTTON_H - th) / 2) + 2
    BushidoPartyUI.draw_text(
      b, @label,
      12, ty,
      BUTTON_W-49, th,
      0
    )

    if @selected
      mx = BUTTON_W - 22
      my = 18
      BushidoPartyUI.fill2(b, mx,   my-6, 4, 12, BushidoPartyUI::WHITE)
      BushidoPartyUI.fill2(b, mx+4, my-4, 4, 8,  BushidoPartyUI::WHITE)
      BushidoPartyUI.fill2(b, mx+8, my-2, 2, 4,  BushidoPartyUI::WHITE)
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
      self.x = @base_x - (4 * @focus_amount).round
      refresh
    end
  end

  def dispose
    self.bitmap.dispose if self.bitmap && !self.bitmap.disposed?
    super
  end
end

# Runs the Bushido party screen.
class PokemonParty_Scene
  def pbStartScene(party, starthelptext, annotations=nil, multiselect=false)
    @sprites = {}
    @party = party
    @multiselect = multiselect
    @helptext = starthelptext
    @item_target_mode = (starthelptext == _INTL("Use on which Pokémon?") && annotations)

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

    @sprites["infoPanel"] = BushidoPartyInfoPanel.new(@viewport)
    @sprites["detailPanel"] = BushidoPartyDetailPanel.new(@viewport)
    @action_buttons = []

    for i in 0...6
      if @party[i]
        @sprites["pokemon#{i}"] = BushidoPartySlot.new(@party[i], i, @viewport)
      else
        @sprites["pokemon#{i}"] = BushidoPartyBlankSlot.new(@party[i], i, @viewport)
      end
      @sprites["pokemon#{i}"].text = annotations[i] if annotations
    end

    @sprites["pokemon6"] = BushidoPartyInvisibleAction.new(@viewport)
    @sprites["pokemon7"] = BushidoPartyInvisibleAction.new(@viewport) if @multiselect

    @sprites["activePokemon"] = PokemonSprite.new(@viewport)
    @sprites["activePokemon"].z = 6
    setActivePokemonBitmap(@party[@activecmd || 0])

    @sprites["focusItemBack"] = BitmapSprite.new(42, 42, @viewport)
    @sprites["focusItemBack"].x = 204
    @sprites["focusItemBack"].y = 50
    @sprites["focusItemBack"].z = 5

    ib = @sprites["focusItemBack"].bitmap
    ib.clear
    BushidoPartyUI.blit_asset(ib, "focus_item_back")

    @sprites["focusItem"] = ItemIconSprite.new(0, 0, @party[@activecmd || 0].item, @viewport)
    @sprites["focusItem"].x = 225
    @sprites["focusItem"].y = 71
    @sprites["focusItem"].z = 7
    @sprites["focusItem"].zoom_x = 0.5
    @sprites["focusItem"].zoom_y = 0.5

    refreshFocusItem(@party[@activecmd || 0])

    @activecmd = 0
    if @item_target_mode
      for i in 0...@party.length
        sprite = @sprites["pokemon#{i}"]
        if sprite && sprite.text == _INTL("ABLE")
          @activecmd = i
          break
        end
      end
    end
    @last_activecmd = @activecmd
    @focus_anim = 1.0
    @sprites["pokemon#{@activecmd}"].selected = true if @sprites["pokemon#{@activecmd}"]

    refreshBushidoUI

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

    @sprites["infoPanel"].pokemon = selectedPokemon if @sprites["infoPanel"]
    @sprites["detailPanel"].pokemon = selectedPokemon if @sprites["detailPanel"]

    if @sprites["detailPanel"]
      @sprites["detailPanel"].visible = !@command_mode && !@message_text
    end

    b = @sprites["overlay"].bitmap
    b.clear

    refreshActionButtons

    if @message_text
      drawMessage(b, @message_text)
    else
      drawBrowseHint(b)
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

    b.fill_rect(x+4,y,w-8,h,BushidoPartyUI::WHITE)
    b.fill_rect(x,y+4,w,h-8,BushidoPartyUI::WHITE)
    b.fill_rect(x+3,y+3,w-6,h-6,BushidoPartyUI::PANEL)

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

      BushidoPartyUI.draw_scaled_text(
        b, sprintf("%d/%d",pkmn.hp,pkmn.totalhp),
        bx, y+49, bw, 19,
        0.50, 1,
        BushidoPartyUI::WHITE, BushidoPartyUI::SHADOW
      )
    end
  end

  def previewCommands
    pkmn=selectedPokemon
    return [] if !pkmn

    commands=[]
    commands.push(_INTL("Summary"))
    commands.push(_INTL("Debug")) if $DEBUG

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
    return [] if !@command_mode
    return @command_commands || []
  end

  def refreshActionButtons
    commands = currentPreviewCommands
    page_size = 5

    max_page = commands.length > 0 ? (commands.length - 1) / page_size : 0
    @command_page = 0 if !@command_page
    @command_page = max_page if @command_page > max_page

    page_start = @command_page * page_size
    visible = commands[page_start, page_size] || []

    for i in 0...5
      if !@action_buttons[i]
        @action_buttons[i] = BushidoPartyActionButton.new("", i, @viewport)

        @sprites["actionButton#{i}"] = @action_buttons[i]
      end

      button = @action_buttons[i]

      if @command_mode && i < visible.length
        raw = visible[i]
        cmd = raw.is_a?(Array) ? raw[0] : raw
        label = (cmd.to_s.downcase == "move") ? _INTL("Swap") : cmd.to_s

        button.visible = true
        button.label = label
        button.accent = BushidoPartyUI.type_accent(selectedPokemon)

        absolute_index = page_start + i
        button.selected = (absolute_index == @command_index)
      else
        button.visible = false
        button.selected = false
      end
    end
  end

  def drawBrowseHint(b)
    return if @command_mode
    return if !selectedPokemon

    box_x = 330
    box_y = 8
    box_w = 140
    box_h = 32

    BushidoPartyUI.blit_asset(b, "browse_hint", box_x, box_y)

    BushidoPartyUI.set_ui_font(b)

    pbDrawShadowText(
      b, box_x, box_y+8, box_w, 24,
      _INTL("ENTER: Actions"),
      BushidoPartyUI::WHITE, BushidoPartyUI::SHADOW, 1
    )
  end

  def drawPagingArrows(b)
    return if !@command_mode

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
      BushidoPartyUI.fill2(b, x-6, ay,   12, 2, BushidoPartyUI::WHITE)
      BushidoPartyUI.fill2(b, x-4, ay+2, 8,  2, BushidoPartyUI::WHITE)
      BushidoPartyUI.fill2(b, x-2, ay+4, 4,  2, BushidoPartyUI::WHITE)
    end

    if @command_page > 0
      ay = 22
      BushidoPartyUI.fill2(b, x-2, ay,   4,  2, BushidoPartyUI::WHITE)
      BushidoPartyUI.fill2(b, x-4, ay+2, 8,  2, BushidoPartyUI::WHITE)
      BushidoPartyUI.fill2(b, x-6, ay+4, 12, 2, BushidoPartyUI::WHITE)
    end
  end

  def drawActionArea(b)
    refreshActionButtons
  end

  def drawMessage(b, text)
    BushidoPartyUI.blit_asset(b, "message_panel", 320, 78)
    BushidoPartyUI.set_primary_font(b)

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

    max_length = 12

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

    shown_commands = commands.clone
    rename_index = -1

    pkmn = selectedPokemon

    base_action_menu = shown_commands.any? do |cmd|
      label = cmd.is_a?(Array) ? cmd[0] : cmd
      label.to_s == _INTL("Summary").to_s
    end

    if pkmn && !pkmn.egg? && base_action_menu
      cancel_index = shown_commands.length - 1
      rename_index = cancel_index
      shown_commands.insert(rename_index, _INTL("Rename"))
    end

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
          renameSelectedPokemon

          @command_commands = shown_commands
          refreshBushidoUI
          next
        end

        ret = @command_index

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
    detail = @sprites["detailPanel"]
    item = @sprites["focusItem"]
    item_back = @sprites["focusItemBack"]

    return if !spr

    4.times do |i|
      spr.opacity = 255 - ((i+1) * 48)
      spr.x = 145 - ((i+1) * 3)
      info.opacity = 255 - ((i+1) * 36) if info
      detail.opacity = 255 - ((i+1) * 36) if detail
      item.opacity = 255 - ((i+1) * 48) if item
      item_back.opacity = 255 - ((i+1) * 48) if item_back
      Graphics.update
      update
    end

    @activecmd = new_index
    refreshActivePokemon
    @sprites["infoPanel"].pokemon = selectedPokemon if @sprites["infoPanel"]
    @sprites["detailPanel"].pokemon = selectedPokemon if @sprites["detailPanel"]
    refreshFocusItem(selectedPokemon)
    refreshActionButtons

    spr.x = 157
    spr.opacity = 60
    info.opacity = 90 if info
    detail.opacity = 90 if detail
    item.opacity = 60 if item
    item_back.opacity = 60 if item_back

    5.times do |i|
      t = (i+1) / 5.0
      spr.opacity = (60 + (195 * t)).round
      spr.x = (157 - (12 * t)).round
      info.opacity = (90 + (165 * t)).round if info
      detail.opacity = (90 + (165 * t)).round if detail
      item.opacity = (60 + (195 * t)).round if item
      item_back.opacity = (60 + (195 * t)).round if item_back
      Graphics.update
      update
    end

    spr.x = 145
    spr.opacity = 255
    info.opacity = 255 if info
    detail.opacity = 255 if detail
    item.opacity = 255 if item
    item_back.opacity = 255 if item_back
  end

  def pbSelect(item)
    old = @activecmd
    @command_page = 0 if !@command_mode

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

  def pbInvalidItemTarget?(index)
    return false if !@item_target_mode
    return false if index < 0 || index >= @party.length
    sprite = @sprites["pokemon#{index}"]
    return false if !sprite
    return sprite.text == _INTL("NOT ABLE")
  end

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
        if pbInvalidItemTarget?(@activecmd)
          if defined?(pbPlayBuzzerSE)
            pbPlayBuzzerSE
          else
            pbPlayCancelSE
          end
          next
        end
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

# Opens the party screen for testing.
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

end # BUSHIDO_PARTY_UI_ENABLED
