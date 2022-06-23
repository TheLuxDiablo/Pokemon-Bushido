#-------------------------------------------------------------------------------
class Window_Moves < Window_CommandPokemon
  VISIBLE_ITEMS = 9

  def initialize(viewport, commands, width = 132)
    super(commands, width)
    self.rowHeight   = 24
    self.windowskin  = nil
    @selarrow&.dispose
    @selarrow        = AnimatedBitmap.new("Graphics/Pictures/Pokedex/arrow_c")
    self.height      = (self.rowHeight * VISIBLE_ITEMS) + 32
    self.viewport    = viewport
    self.baseColor   = Color.new(0, 0, 0)
    self.shadowColor = Color.new(198, 175, 104)
    self.startX      = 0
    self.startY      = 0
    self.endX        = 0
    self.endY        = 0
  end

  def active=(value)
    super
    self.refresh
  end

  def drawCursor(index, rect)
    if self.index == index && self.active
      pbCopyBitmap(self.contents, @selarrow.bitmap, rect.x, rect.y + 4)
    end
    return Rect.new(rect.x + 12, rect.y, rect.width - 12, rect.height)
  end

  def drawItem(index, _count, rect)
    pbSetSmallFont(self.contents)
    rect = drawCursor(index, rect)
    move = @commands[index]
    x_offset = 0
    name = ""
    if move.is_a?(Array)
      text = (move[0] == 0 ? _INTL("Evo.") : move[0])
      name = _INTL("{1} - {2}", text, PBMoves.getName(move[1]))
    else
      name = PBMoves.getName(move)
    end
    pbDrawShadowText(self.contents, rect.x + x_offset, rect.y + 4, rect.width - x_offset, rect.height, name, self.baseColor, self.shadowColor)
  end

  def initUpDownArrow
    @uparrow           = Sprite.new(self.viewport)
    @uparrow.bitmap    = RPG::Cache.load_bitmap("Graphics/Pictures/Pokedex/arrow")
    @downarrow         = Sprite.new(self.viewport)
    @downarrow.bitmap  = RPG::Cache.load_bitmap("Graphics/Pictures/Pokedex/arrow_2")
    @uparrow.z         = 99998
    @downarrow.z       = 99998
    @uparrow.visible   = false
    @downarrow.visible = false
  end

  def update
    super
    @uparrow.x         = self.x + self.width - 46
    @downarrow.x       = self.x + self.width - 46
    @uparrow.y         = self.y + 2
    @downarrow.y       = self.y + self.height - 42
    @uparrow.visible   = self.visible && (self.top_item != 0 && @item_max > self.page_item_max)
    @downarrow.visible = self.visible && (self.top_item + self.page_item_max < @item_max && @item_max > self.page_item_max)
  end
end

#-------------------------------------------------------------------------------
class Window_Evolutions < Window_CommandPokemon
  VISIBLE_ITEMS = 4

  attr_accessor :species

  def initialize(viewport, commands, width = 488)
    super(commands, width)
    self.rowHeight   = 62
    self.windowskin  = nil
    self.height      = (self.rowHeight * VISIBLE_ITEMS) + (60)
    self.viewport    = viewport
    self.baseColor   = Color.new(0, 0, 0)
    self.shadowColor = Color.new(198, 175, 104)
    self.startX      = 0
    self.startY      = 0
    self.endX        = 0
    self.endY        = 0
    @arrow_bmp       = pbBitmap("Graphics/Pictures/Pokedex/arrow_evo")
    @pokemon         = pbGenPkmn(getID(PBSpecies, :BULBASAUR), 1)
  end

  def active=(value)
    super
    self.refresh
  end

  def drawCursor(index, rect)
    if self.index == index && self.active
      color = self.shadowColor.clone
      color.alpha = 160
      self.contents.fill_rect(rect.x, rect.y, self.width, self.rowHeight, color)
    end
    return Rect.new(rect.x + 12, rect.y, rect.width - 12, rect.height)
  end

  def drawItem(index, _count, rect)
    pbSetSmallFont(self.contents)
    offset, species, text = @commands[index]
    prev_cmd = false
    prev_cmd = index != 0 && @commands[index - 1][0] == offset
    new_sp, new_form = pbGetSpeciesFromFSpecies(species)
    @pokemon.species    = new_sp
    @pokemon.forcedForm = new_form
    @pokemon.makeMale
    @pokemon.makeNotShiny
    bmp = pbBitmap(pbPokemonIconFile(@pokemon))
    icon = Bitmap.new(bmp.height, bmp.height)
    icon.blt(0, 0, bmp, Rect.new(0, 0, bmp.height, bmp.height))
    y_offset = 0
    x_offset = self.rowHeight * offset
    bmp.dispose
    if species == self.species
      color = self.active && self.index == index ? Color.new(150, 127, 56) : Color.new(198, 175, 104)
      icon  = create_outline(icon, color)
      y_offset -= 2
      x_offset -= 2
    end
    self.contents.blt(rect.x + x_offset, rect.y + y_offset, icon, Rect.new(0, 0, icon.width, icon.height))
    if offset != 0
      x_pos = rect.x + x_offset - 36 - (species == self.species ? 0 : 2)
      if prev_cmd
        self.contents.blt(x_pos, rect.y - 28, @arrow_bmp, Rect.new(0, 0, @arrow_bmp.width, @arrow_bmp.height))
      else
        self.contents.blt(x_pos, rect.y + 4, @arrow_bmp, Rect.new(0, 32, @arrow_bmp.width, 40))
      end
    end
    x_offset += (icon.width - (species == self.species ? 2 : 0))
    icon.dispose
    pbDrawShadowText(self.contents, rect.x + x_offset + 4, rect.y + 26, rect.width - x_offset- 4, rect.height, text, self.baseColor, self.shadowColor)
  end

  def refresh
    @item_max = itemCount
    dwidth  = self.width-self.borderX
    dheight = self.height-self.borderY
    self.contents = pbDoEnsureBitmap(self.contents, dwidth, dheight)
    self.contents.clear
    drawCursor(self.index, itemRect(self.index))
    return if @commands.length <= 1
    @item_max.times do |i|
      next if i < self.top_item || i > self.top_item + self.page_item_max
      rect = itemRect(i).clone
      rect.width -= 12
      rect.x     += 12
      drawItem(i, @item_max,  rect)
    end
  end

  def dispose
    super
    @arrow_bmp.dispose
  end


  def initUpDownArrow
    @uparrow           = Sprite.new(self.viewport)
    @uparrow.bitmap    = RPG::Cache.load_bitmap("Graphics/Pictures/Pokedex/arrow")
    @downarrow         = Sprite.new(self.viewport)
    @downarrow.bitmap  = RPG::Cache.load_bitmap("Graphics/Pictures/Pokedex/arrow_2")
    @uparrow.z         = 99998
    @downarrow.z       = 99998
    @uparrow.visible   = false
    @downarrow.visible = false
  end

  def update
    super
    @uparrow.x         = self.x + self.width - 46
    @downarrow.x       = self.x + self.width - 46
    @uparrow.y         = self.y + 2
    @downarrow.y       = self.y + self.height - 70
    @uparrow.visible   = self.visible && (self.top_item != 0 && @item_max > self.page_item_max)
    @downarrow.visible = self.visible && (self.top_item + self.page_item_max < @item_max && @item_max > self.page_item_max)
  end
end
#-------------------------------------------------------------------------------

class Sprite
  def framewidth
    return self.bitmap&.width || 0
  end

  def frameheight
    return self.bitmap&.height || 0
  end
end


class PokemonPokedexInfo_Scene

  def drawPage(page)
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    # Make certain sprites visible
    @sprites["infosprite"].visible    = @page == 1
    @sprites["areamap"].visible       = @page == 2 if @sprites["areamap"]
    @sprites["areahighlight"].visible = @page == 2 if @sprites["areahighlight"]
    @sprites["areaoverlay"].visible   = @page == 2 if @sprites["areaoverlay"]
    @sprites["formfront"].visible     = @page == 3 if @sprites["formfront"]
    @sprites["formback"].visible      = @page == 3 if @sprites["formback"]
    if @sprites["formicon"]
      @sprites["formicon"].visible    = [1, 3].include?(@page)
      @sprites["formicon"].x          = 242 if @page == 1
      @sprites["formicon"].y          = 158 if @page == 1
      @sprites["formicon"].x          = 82  if @page == 3
      @sprites["formicon"].y          = 328 if @page == 3
    end
    if !@viewport2
      @viewport2   = Viewport.new(12, 120, 488, 248)
      @viewport2.z = 100000
      @move_list   = 0
      @sprites["lvup_moves"]     = Window_Moves.new(@viewport2, [], 162)
      @sprites["lvup_moves"].x   = 4
      @sprites["tutor_moves"]    = Window_Moves.new(@viewport2, [])
      @sprites["tutor_moves"].x  = 350
      @sprites["egg_moves"]      = Window_Moves.new(@viewport2, [])
      @sprites["egg_moves"].x    = 192
      @sprites["evolutions"]     = Window_Evolutions.new(@viewport2, [])
      @sprites["ctrl_overlay"]   = BitmapSprite.new(512, 28, @viewport)
      @sprites["ctrl_overlay"].y = 88
      ["lvup_moves", "egg_moves", "tutor_moves"].each_with_index do |_key, i|
        @sprites["brwn_#{i}"]        = Sprite.new(@viewport2)
        @sprites["brwn_#{i}"].bitmap = Bitmap.new([172, 142, 142][i], 220)
        @sprites["brwn_#{i}"].bitmap.fill_rect(0, 0, @sprites["brwn_#{i}"].bitmap.width, @sprites["brwn_#{i}"].bitmap.height, Color.new(119, 96, 25, 160))
        @sprites["brwn_#{i}"].x      = [0, 188, 346][i]
        @sprites["brwn_#{i}"].y      = 28
      end
      pbSetSmallFont(@sprites["ctrl_overlay"].bitmap)
    end
    @sprites["evolutions"].visible = false
    if @page == 5
      f_species    = pbGetFSpeciesFromForm(@species, @form)
      lvup_moves   = pbGetSpeciesMoveset(@species, @form)
      egg_moves    = pbGetSpeciesEggMoves(Nuzlocke.getFirstEvo(f_species), 0)
      tutor_moves  = []
      all_tm_moves = pbLoadSpeciesTMData
      all_tm_moves.each_with_index do |pkmn, move|
        next if !pkmn || pkmn.empty?
        next if !pkmn.any? { |p| f_species == getID(PBSpecies, p) }
        tutor_moves.push(move)
      end
      tutor_moves.sort! { |a, b| PBMoves.getName(a) <=> PBMoves.getName(b) }
      @sprites["lvup_moves"].commands  = lvup_moves
      @sprites["egg_moves"].commands   = egg_moves
      @sprites["tutor_moves"].commands = tutor_moves
    elsif @page == 6
      f_species  = pbGetFSpeciesFromForm(@species, @form)
      first_evo  = Nuzlocke.getFirstEvo(f_species)
      evolutions = get_evolution_array(first_evo)
      @sprites["evolutions"].commands = evolutions
      @sprites["evolutions"].index    = evolutions.index { |_, s, _| s == f_species } || 0
      @sprites["evolutions"].visible  = evolutions.length > 1
      @sprites["evolutions"].species  = f_species
    end
    pbDeactivateWindows(@sprites)
    @sprites["ctrl_overlay"].bitmap.clear
    @sprites["ctrl_overlay"].visible = [5, 6].include?(@page)
    ["lvup_moves", "egg_moves", "tutor_moves"].each_with_index do |key, i|
      @sprites[key].index   = 0
      @sprites[key].visible = @page == 5
      @sprites[key].y       = 32
      @sprites["brwn_#{i}"].visible = i != @move_list && @page == 5
    end
    @started = false
    # Draw page-specific information
    case page
    when 1 then drawPageInfo
    when 2 then drawPageArea
    when 3 then drawPageForms
    when 4 then drawPageBaseData
    when 5 then drawPageBaseMoves
    when 6 then drawPageBaseEvos
    end
  end

  def get_evolution_array(new_species, old_species = nil, offset = 0, method = nil, parameter = nil)
    ret = []
    new_species = pbGetFSpeciesFromForm(new_species, @form)
    ret.push(get_evolution(new_species, old_species, offset, method, parameter))
    old_species = new_species
    pbGetEvolvedFormData(old_species, true).each do |method, parameter, new_sp|
      next if method == PBEvolution::Beauty
      arr = get_evolution_array(new_sp, old_species, offset + 1, method, parameter)
      next if arr.empty?
      ret.concat(arr)
    end
    return ret
  end

  def get_evolution(new_species, old_species, offset, method = nil, parameter = nil)
    icon    = new_species
    species = old_species
    arr     = [offset, icon]
    str     = ""
    if method && offset != 0
      case method
      when PBEvolution::Level, PBEvolution::Ninjask
        str = _INTL("Level up to Lv. {1}", parameter)
      when PBEvolution::LevelMale
        str = _INTL("Level up a male {2} to Lv. {1}", parameter, PBSpecies.getName(species))
      when PBEvolution::LevelFemale
        str = _INTL("Level up a female {2} to Lv. {1}", parameter, PBSpecies.getName(species))
      when PBEvolution::LevelDay
        str = _INTL("Level up to Lv. {1} during daytime", parameter)
      when PBEvolution::LevelNight
        str = _INTL("Level up to Lv. {1} at night", parameter)
      when PBEvolution::LevelMorning
        str = _INTL("Level up to Lv. {1} in the morning", parameter)
      when PBEvolution::LevelAfternoon
        str = _INTL("Level up to Lv. {1} in the afternoon", parameter)
      when PBEvolution::LevelEvening
        str = _INTL("Level up to Lv. {1} in the evening", parameter)
      when PBEvolution::LevelNoWeather
        str = _INTL("Level up to Lv. {1} during clear weather", parameter)
      when PBEvolution::LevelSun
        str = _INTL("Level up to Lv. {1} during Sunny weather", parameter)
      when PBEvolution::LevelRain
        str = _INTL("Level up to Lv. {1} during Rainy weather", parameter)
      when PBEvolution::LevelSnow
        str = _INTL("Level up to Lv. {1} during snowy weather", parameter)
      when PBEvolution::LevelSandstorm
        str = _INTL("Level up to Lv. {1} during Sandstorm weather", parameter)

      when PBEvolution::LevelCycling
        str = _INTL("Level up to Lv. {1} while Cycling", parameter)
      when PBEvolution::LevelSurfing
        str = _INTL("Level up to Lv. {1} while Water Walking", parameter)
      when PBEvolution::LevelDiving
        str = _INTL("Level up to Lv. {1} while underwater", parameter)
      when PBEvolution::LevelDarkness
        str = _INTL("Level up to Lv. {1} while in a dark cave", parameter)
      when PBEvolution::LevelDarkInParty
        str = _INTL("Level up to Lv. {1} with a Dark-type Pokémon in party", parameter)
      when PBEvolution::DefenseGreater
        str = _INTL("Level up to Lv. {1} with ATK > DEF", parameter)
      when PBEvolution::AtkDefEqual
        str = _INTL("Level up to Lv. {1} with ATK = DEF", parameter)
      when PBEvolution::AttackGreater
        str = _INTL("Level up to Lv. {1} with ATK < DEF", parameter)
      when PBEvolution::Silcoon, PBEvolution::Cascoon
        str = _INTL("Level up to Lv. {1} with random chance", parameter)
      when PBEvolution::Shedinja
        str = _INTL("Level up to Lv. {1} with space in party", parameter)
      when PBEvolution::Happiness, PBEvolution::MaxHappiness
        str = _INTL("Level up with high friendship")
      when PBEvolution::HappinessMale
        str = _INTL("Level up a male {1} with high friendship", PBSpecies.getName(species))
      when PBEvolution::HappinessFemale
        str = _INTL("Level up a female {1} with high friendship", PBSpecies.getName(species))
      when PBEvolution::HappinessDay
        str = _INTL("Level up with high friendship in the day")
      when PBEvolution::HappinessNight
        str = _INTL("Level up with high friendship at night")
      when PBEvolution::HappinessMove
        str = _INTL("Level up with high friendship and the move {1}", PBMoves.getName(parameter))
      when PBEvolution::HappinessMoveType
        str = _INTL("Level up with high friendship and a {1}-type move", PBTypes.getName(parameter))
      when PBEvolution::HappinessHoldItem, PBEvolution::HoldItemHappiness
        item_name = PBItems.getName(parameter)
        if item_name.starts_with_vowel?
          str = _INTL("Level up with high friendship while holding an {1}", item_name)
        else
          str = _INTL("Level up with high friendship while holding a {1}", item_name)
        end
      when PBEvolution::HoldItem
        item_name = PBItems.getName(parameter)
        if item_name.starts_with_vowel?
          str = _INTL("Level up holding an {1}", item_name)
        else
          str = _INTL("Level up holding a {1}", item_name)
        end
      when PBEvolution::HoldItemMale
        item_name = PBItems.getName(parameter)
        if item_name.starts_with_vowel?
          str = _INTL("Level up a male {2} holding an {1}", item_name, PBSpecies.getName(species))
        else
          str = _INTL("Level up a male {2} holding a {1}", item_name, PBSpecies.getName(species))
        end
      when PBEvolution::HoldItemFemale
        item_name = PBItems.getName(parameter)
        if item_name.starts_with_vowel?
          str = _INTL("Level up a female {2} holding an {1}", item_name, PBSpecies.getName(species))
        else
          str = _INTL("Level up a female {2} holding a {1}", item_name, PBSpecies.getName(species))
        end
      when PBEvolution::DayHoldItem
        item_name = PBItems.getName(parameter)
        if item_name.starts_with_vowel?
          str = _INTL("Level up holding an {1} in the day", item_name)
        else
          str = _INTL("Level up holding a {1} in the day", item_name)
        end
      when PBEvolution::NightHoldItem
        item_name = PBItems.getName(parameter)
        if item_name.starts_with_vowel?
          str = _INTL("Level up holding an {1} in the night", item_name)
        else
          str = _INTL("Level up holding a {1} in the night", item_name)
        end
      when PBEvolution::HasMove
        str = _INTL("Level up with the move {1}", PBMoves.getName(parameter))
      when PBEvolution::HasMoveType
        str = _INTL("Level up with a {1}-type move", PBTypes.getName(parameter))
      when PBEvolution::HasInParty
        str = _INTL("Level up with {1} in party", PBSpecies.getName(species))
      when PBEvolution::Location
        str = _INTL("Level up in {1}", pbGetMapNameFromId(parameter))
      when PBEvolution::Region
        metadata = pbGetMetadata($game_map.map_id, MetadataMapPosition)
        region = metadata && metadata[0]
        if region
          r_name = pbGetMessage(MessageTypes::RegionNames, mapindex)
          str = _INTL("Level up in the {1}", r_name)
        end
      when PBEvolution::Item
        item_name = PBItems.getName(parameter)
        if item_name.starts_with_vowel?
          str = _INTL("Use an {1}", item_name)
        else
          str = _INTL("Use a {1}", item_name)
        end
      when PBEvolution::ItemMale
        item_name = PBItems.getName(parameter)
        if item_name.starts_with_vowel?
          str = _INTL("Use an {1} on a male {2}", item_name, PBSpecies.getName(species))
        else
          str = _INTL("Use a {1} on a male {2}", item_name, PBSpecies.getName(species))
        end
      when PBEvolution::ItemFemale
        item_name = PBItems.getName(parameter)
        if item_name.starts_with_vowel?
          str = _INTL("Use an {1} on a female {2}", item_name, PBSpecies.getName(species))
        else
          str = _INTL("Use a {1} on a female {2}", item_name, PBSpecies.getName(species))
        end
      when PBEvolution::ItemDay
        item_name = PBItems.getName(parameter)
        if item_name.starts_with_vowel?
          str = _INTL("Use an {1} during the day", item_name)
        else
          str = _INTL("Use a {1} during the day", item_name)
        end
      when PBEvolution::ItemNight
        item_name = PBItems.getName(parameter)
        if item_name.starts_with_vowel?
          str = _INTL("Use an {1} at night", item_name)
        else
          str = _INTL("Use a {1} at night", item_name)
        end
      when PBEvolution::ItemHappiness
        item_name = PBItems.getName(parameter)
        if item_name.starts_with_vowel?
          str = _INTL("Use an {1} with high friendship", item_name)
        else
          str = _INTL("Use a {1} with high friendship", item_name)
        end
      when PBEvolution::Trade
        str = _INTL("Trade")
      when PBEvolution::TradeItem
        str = _INTL("Trade while holding {1}", PBItems.getName(parameter))
      when PBEvolution::TradeSpecies
        str = _INTL("Trade with a {1} in party", PBSpecies.getName(species))
      else
        str = _INTL("Unknown Evolution Method")
      end
    end
    arr.push(str)
    return arr
  end

  def drawDataPageTop
    base_color = Color.new(0, 0, 0)
    sel_shdw   = Color.new(198, 175, 104)
    desel_shdw = Color.new(146, 123, 62)
    textpos = []
    [_INTL("Stats"), _INTL("Moves"), _INTL("Evos.")].each_with_index do |text, i|
      x_pos = 88 + (167 * i)
      shdw_color = @page - 4 == i ? sel_shdw : desel_shdw
      textpos.push([text, x_pos, 50, 2, base_color, shdw_color])
    end
    pbDrawTextPositions(@sprites["overlay"].bitmap, textpos)
    @sprites["background"].setBitmap("Graphics/Pictures/Pokedex/bg_data_#{@page - 3}")
  end

  def drawPageBaseData
    drawDataPageTop
    overlay    = @sprites["overlay"].bitmap
    pbSetSmallFont(overlay)
    base_color = Color.new(0, 0, 0)
    shdw_color = Color.new(198, 175, 104)
    left_col   = 166
    right_col  = 326
    textpos    = []
    imagepos   = []
    # Base Stats
    base_stats = pbGetSpeciesData(@species, @form, SpeciesBaseStats)
    bst_total  = 0
    base_stats.each_with_index do |stat, i|
      bst_total += stat
      stat_name = PBStats.getNameBrief(i)
      y_pos     = 104 + (28 * i)
      textpos.push([stat_name, 50, y_pos, 2, base_color, shdw_color])
      textpos.push([stat.to_s, 118, y_pos, 2, base_color, shdw_color])
    end
    textpos.push([_INTL("Total"), 50, 276, 2, base_color, shdw_color])
    textpos.push([bst_total.to_s, 118, 276, 2, base_color, shdw_color])
    # Gender Rate
    gender_ratio = pbGetSpeciesData(@species, @form, SpeciesGenderRate)
    gender_str   = _INTL("Genderless")
    if gender_ratio != PBGenderRates::Genderless
      male_ratio = ((1 - PBGenderRates.genderByte(gender_ratio ) / 256.0) * 100).to_i
      fml_ratio  = 100 - male_ratio
      gcd = male_ratio.gcd(fml_ratio)
      male_ratio /= gcd
      fml_ratio /= gcd
      gender_str = _INTL("{1} ♂/♀ {2}", male_ratio, fml_ratio)
    end
    textpos.push([gender_str, 246, 104, 2, base_color, shdw_color])
    # Catch Rate
    catch_rate = pbGetSpeciesData(@species, @form, SpeciesRareness)
    catch_str = _INTL("V. Hard")
    if catch_rate >= 250
      catch_str = _INTL("Instant")
    elsif catch_rate >= 200
      catch_str = _INTL("V. Easy")
    elsif catch_rate >= 150
      catch_str = _INTL("Easy")
    elsif catch_rate >= 100
      catch_str = _INTL("Normal")
    elsif catch_rate >= 50
      catch_str = _INTL("Hard")
    end
    textpos.push([_INTL("Catch% :"), left_col, 132, 0, base_color, shdw_color])
    textpos.push([catch_str, right_col, 132, 1, base_color, shdw_color])
    # Growth Rate
    growth_rate = pbGetSpeciesData(@species, @form, SpeciesGrowthRate)
    growth_str = [
      _INTL("Med. Fast"),
      _INTL("Erratic"),
      _INTL("Fluctuating"),
      _INTL("Med. Slow"),
      _INTL("Fast"),
      _INTL("Slow")
    ][growth_rate]
    textpos.push([_INTL("Growth :"), left_col, 160, 0, base_color, shdw_color])
    textpos.push([growth_str, right_col, 160, 1, base_color, shdw_color])
    # Exp Yield
    exp_yield = pbGetSpeciesData(@species, @form, SpeciesBaseExp)
    textpos.push([_INTL("Exp Yield :"), left_col, 188, 0, base_color, shdw_color])
    textpos.push([exp_yield.to_s, right_col, 188, 1, base_color, shdw_color])
    # Base Friendship
    base_friendship = pbGetSpeciesData(@species, @form, SpeciesHappiness)
    textpos.push([_INTL("Happiness :"), left_col, 216, 0, base_color, shdw_color])
    x_pos = 0
    if base_friendship >= 140
      x_pos = 4
    elsif base_friendship >= 100
      x_pos = 3
    elsif base_friendship >= 50
      x_pos = 2
    elsif  base_friendship >= 35
      x_pos = 1
    end
    x_pos *= 16
    imagepos.push(["Graphics/Pictures/Pokedex/icon_happiness", right_col - 16, 222, x_pos, 0, 16, 16])
    # Egg Steps
    steps_to_hatch = pbGetSpeciesData(@species, @form, SpeciesStepsToHatch)
    textpos.push([_INTL("Egg Steps :"), left_col, 244, 0, base_color, shdw_color])
    textpos.push([steps_to_hatch.to_s, right_col, 244, 1, base_color, shdw_color])
    # EV Yield
    ev_yield = pbGetSpeciesData(@species, @form, SpeciesEffortPoints)
    ev_str   = ""
    ev_yield.each_with_index do |a, i|
      next if a <= 0
      stat_name = [
        _INTL("HP"),
        _INTL("ATK"),
        _INTL("DEF"),
        _INTL("SPATK"),
        _INTL("SPDEF"),
        _INTL("SPD")
      ]
      ev_str += (stat_name[i] + " ")
    end
    textpos.push([_INTL("EVs : {1}", ev_str), left_col, 272, 0, base_color, shdw_color])
    # Egg Groups
    egg_groups = pbGetSpeciesData(@species, @form, SpeciesCompatibility).clone
    egg_groups = [egg_groups] if !egg_groups.is_a?(Array)
    egg_groups.compact!
    egg_groups.map! { |e| PBEggGroups.getName(e) }
    egg_groups = egg_groups.compact.join(", ")
    textpos.push([_INTL("Egg Groups:"), 18, 316, 0, base_color, shdw_color])
    textpos.push([egg_groups, 18, 344, 0, base_color, shdw_color])
    left_col = 354
    # Abilities
    textpos.push([_INTL("Abilities:"), 354, 104, 0, base_color, shdw_color])
    abilities = pbGetSpeciesData(@species, @form, SpeciesAbilities)
    abilities = [abilities] if !abilities.is_a?(Array)
    abilities.compact!
    abilities.each_with_index do |a, i|
      textpos.push([PBAbilities.getName(a), left_col, 104 + (28 * (i + 1)), 0, base_color, shdw_color])
    end
    # Egg Groups
    textpos.push([_INTL("Hidden Ability:"), left_col, 210, 0, base_color, shdw_color])
    abilities = pbGetSpeciesData(@species, @form, SpeciesHiddenAbility)
    abilities = [abilities] if !abilities.is_a?(Array)
    abilities.compact!
    abilities.each_with_index do |a, i|
      textpos.push([PBAbilities.getName(a), left_col, 208 + (28 * (i + 1)), 0, base_color, shdw_color])
    end
    # Wild Items
    textpos.push([_INTL("Wild Held Items:"), left_col, 284, 0, base_color, shdw_color])
    items = [
      pbGetSpeciesData(@species, @form, SpeciesWildItemCommon),
      pbGetSpeciesData(@species, @form, SpeciesWildItemUncommon),
      pbGetSpeciesData(@species, @form, SpeciesWildItemRare)
    ]
    if items.all? { |i| i == 0 || i.nil? }
      textpos.push([_INTL("None"), 424, 322, 2, base_color, shdw_color])
    elsif items.all? { |i| i == items[0] }
      bmp = pbBitmap(pbItemIconFile(items[0]))
      overlay.blt(424 - bmp.width / 2, 312, bmp, Rect.new(50 - bmp.width, 56 - bmp.height, 50, 50))
      bmp.dispose
      textpos.push([_INTL("(100%)"), 424, 344, 2, base_color, shdw_color])
    else
      x = 348
      items.each_with_index do |item, i|
        next if item.nil? || item  == 0
        bmp = pbBitmap(pbItemIconFile(item))
        overlay.blt(x, 316, bmp, Rect.new(50 - bmp.width, (56 - bmp.height) / 2, 50, 50))
        bmp.dispose
        item_text = [_INTL("50%"), _INTL("5%"), _INTL("1%")][i]
        textpos.push([item_text, x + 25, 344, 2, base_color, shdw_color])
        x += 51
      end
    end
    pbDrawTextPositions(overlay, textpos)
    pbDrawImagePositions(overlay, imagepos)
    pbSetSystemFont(overlay)
  end

  def drawPageBaseMoves
    drawDataPageTop
    overlay    = @sprites["overlay"].bitmap
    pbSetSmallFont(overlay)
    textpos    = []
    base_color = Color.new(0, 0, 0)
    shdw_color = Color.new(198, 175, 104)
    textpos.push([_INTL("Level-up Moves"), 98, 120, 2, base_color, shdw_color])
    textpos.push([_INTL("Egg Moves"), 271, 120, 2, base_color, shdw_color])
    textpos.push([_INTL("Tutor Moves"), 429, 120, 2, base_color, shdw_color])
    pbDrawTextPositions(overlay, textpos)
    textpos = []
    textpos.push([_INTL("C: Scroll Move List"), 480, 3, 1, Color.white, Color.new(122, 99, 28)])
    pbDrawTextPositions(@sprites["ctrl_overlay"].bitmap, textpos)
    pbSetSystemFont(overlay)
  end

  def drawPageBaseEvos
    drawDataPageTop
    pbSetSystemFont(@sprites["overlay"].bitmap)
    base_color = Color.new(0, 0, 0)
    shdw_color = Color.new(198, 175, 104)
    textpos = []
    if @sprites["evolutions"].commands.length <= 1
      textpos.push([_INTL("{1} has no evolutions.", PBSpecies.getName(@species)), 256, 226, 2, base_color, shdw_color])
      pbDrawTextPositions(@sprites["overlay"].bitmap, textpos)
    elsif @sprites["evolutions"].commands.length > 4
      textpos.push([_INTL("C: Scroll Evolutions"), 32, 3, 0, Color.white, Color.new(122, 99, 28)])
      pbDrawTextPositions(@sprites["ctrl_overlay"].bitmap, textpos)
    end
  end

  def view_moves
    pbPlayDecisionSE
    need_refresh = true
    textpos      = []
    textpos.push([_INTL("LEFT/RIGHT: Change Move List"), 32, 2, 0, Color.white, Color.new(122, 99, 28)])
    textpos.push([_INTL("B: Exit Move List"), 480, 3, 1, Color.white, Color.new(122, 99, 28)])
    @sprites["ctrl_overlay"].bitmap.clear
    pbDrawTextPositions(@sprites["ctrl_overlay"].bitmap, textpos)
    loop do
      if need_refresh
        pbDeactivateWindows(@sprites)
        spr_key = ""
        ["lvup_moves", "egg_moves", "tutor_moves"].each_with_index do |key, i|
          @sprites["brwn_#{i}"].visible = true
          next if @move_list != i
          spr_key = key
          @sprites["brwn_#{i}"].visible = false
        end
        @sprites[spr_key].active = true
        need_refresh = false
      end
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::B) || Input.trigger?(Input::C)
        pbPlayDecisionSE
        break
      elsif Input.trigger?(Input::LEFT)
        old_val     = @move_list
        @move_list -= 1
        @move_list = 0 if @move_list < 0
        if old_val != @move_list
          pbPlayCursorSE
          need_refresh = true
        end
      elsif Input.trigger?(Input::RIGHT)
        @move_list += 1
        @move_list = 2 if @move_list > 2
        need_refresh = true
        if old_val != @move_list
          pbPlayCursorSE
          need_refresh = true
        end
      end
    end
    textpos = []
    textpos.push([_INTL("C: Scroll Move List"), 480, 3, 1, Color.white, Color.new(122, 99, 28)])
    @sprites["ctrl_overlay"].bitmap.clear
    pbDrawTextPositions(@sprites["ctrl_overlay"].bitmap, textpos)
    pbDeactivateWindows(@sprites)
  end

  def view_evolutions
    pbPlayDecisionSE
    need_refresh = true
    textpos = []
    textpos.push([_INTL("B: Exit Evolutions"), 32, 3, 0, Color.white, Color.new(122, 99, 28)])
    @sprites["ctrl_overlay"].bitmap.clear
    pbDrawTextPositions(@sprites["ctrl_overlay"].bitmap, textpos)
    @sprites["evolutions"].active = true
    loop do
      Graphics.update
      Input.update
      pbUpdate
      next if !Input.trigger?(Input::B) && !Input.trigger?(Input::C)
      pbPlayDecisionSE
      break
    end
    textpos = []
    textpos.push([_INTL("C: Scroll Evolutions"), 32, 3, 0, Color.white, Color.new(122, 99, 28)])
    @sprites["ctrl_overlay"].bitmap.clear
    pbDrawTextPositions(@sprites["ctrl_overlay"].bitmap, textpos)
    pbDeactivateWindows(@sprites)
  end

  def pbScene
    pbPlayCrySpecies(@species, @form)
    loop do
      Graphics.update
      Input.update
      pbUpdate
      dorefresh = false
      if Input.trigger?(Input::A)
        pbSEStop
        pbPlayCrySpecies(@species, @form) if @page == 1
      elsif Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        break
      elsif Input.trigger?(Input::C)
        if @page == 3 && @available.length > 1
          pbPlayDecisionSE
          pbChooseForm
          dorefresh = true
        elsif @page == 5
          view_moves
        elsif @page == 6
          view_evolutions if @sprites["evolutions"].commands.length > 4
        end
      elsif Input.trigger?(Input::UP)
        oldindex = @index
        pbGoToPrevious
        if @index != oldindex
          pbUpdateDummyPokemon
          @available = pbGetAvailableForms
          pbSEStop
          (@page == 1) ? pbPlayCrySpecies(@species, @form) : pbPlayCursorSE
          dorefresh = true
        end
      elsif Input.trigger?(Input::DOWN)
        oldindex = @index
        pbGoToNext
        if @index != oldindex
          pbUpdateDummyPokemon
          @available = pbGetAvailableForms
          pbSEStop
          (@page == 1) ? pbPlayCrySpecies(@species,@form) : pbPlayCursorSE
          dorefresh = true
        end
      elsif Input.trigger?(Input::LEFT)
        oldpage = @page
        @page -= 1
        @page = 1 if @page < 1
        @page = 6 if @page > 6
        if @page != oldpage
          pbPlayCursorSE
          dorefresh = true
        end
      elsif Input.trigger?(Input::RIGHT)
        oldpage = @page
        @page += 1
        @page = 1 if @page < 1
        @page = 6 if @page > 6
        if @page != oldpage
          pbPlayCursorSE
          dorefresh = true
        end
      end
      drawPage(@page) if dorefresh
    end
    return @index
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @typebitmap.dispose
    @viewport.dispose
    @viewport2&.dispose
  end

end
