class PokemonStatsPage
  def initialize(battle, idx_battler)
    @battle   = battle
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @idx_battler = idx_battler
    @sprites = {}
    @type_bmp = AnimatedBitmap.new("Graphics/Pictures/types")
    @sprites["background"] = IconSprite.new(0, 0, @viewport)
    if pbResolveBitmap("Graphics/Pictures/Battle/Stats Screen/stat_#{@idx_battler}")
      @sprites["background"].setBitmap("Graphics/Pictures/Battle/Stats Screen/stat_#{@idx_battler}")
    else
      @sprites["background"].setBitmap("Graphics/Pictures/Battle/Stats Screen/stat_0")
    end
    @sprites["overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    @sprites["icon"] = PokemonIconSprite.new(@battle.battlers[idx_battler].pokemon, @viewport)
    @sprites["icon"].x = 2
    @sprites["icon"].y = 4
    pbSetSystemFont(@sprites["overlay"].bitmap)
    xVals = [122, 374, 122, 374, 122, 374, 122]
    yVals = [126, 126, 162, 162, 198, 198, 234]
    index = 0
    PBStats.eachBattleStat do |s|
      6.times do |i|
        ["_up", "_down"].each do |j|
          @sprites["#{s}#{i}#{j}"] = AnimatedSprite.new("Graphics/Pictures/Battle/Stats Screen/stat#{j}", 9, 14, 28, 3, @viewport)
          @sprites["#{s}#{i}#{j}"].x = xVals[index] + (19 * i)
          @sprites["#{s}#{i}#{j}"].y = yVals[index]
          @sprites["#{s}#{i}#{j}"].visible = false
          @sprites["#{s}#{i}#{j}"].play
        end
      end
      index += 1
    end
    @whiteBase   = Color.new(248, 248, 248)
    @whiteShadow = Color.new(101, 57, 11)
    @blackBase   = Color.new(64, 64, 64)
    @blackShadow = Color.new(176, 176, 176)
    drawPage
    pbFadeInAndShow(@sprites)
    pbScene
    pbFadeOutAndHide(@sprites)
    dispose
  end

  def drawPage
    @sprites["overlay"].bitmap.clear
    battler = @battle.battlers[@idx_battler]
    if pbResolveBitmap("Graphics/Pictures/Battle/Stats Screen/stat_#{@idx_battler}")
      @sprites["background"].setBitmap("Graphics/Pictures/Battle/Stats Screen/stat_#{@idx_battler}")
    else
      @sprites["background"].setBitmap("Graphics/Pictures/Battle/Stats Screen/stat_0")
    end
    @sprites["icon"].pokemon = battler.displayPokemon
    imagepos = []
    textpos = [
      [battler.displayPokemon.level.to_s, 180, 85, 0, @whiteBase, @whiteShadow],
      ["#{battler.displayPokemon.hp} / #{battler.displayPokemon.totalhp}", 354, 92, 1, @whiteBase, @whiteShadow],
      ["Weather", 49, 294, 2, @whiteBase, @whiteShadow],
      ["Terrain", 147, 294, 2, @whiteBase, @whiteShadow],
      ["Active Battle Effects", 392, 264, 2, @whiteBase, @whiteShadow]
    ]
    pbSetSmallFont(@sprites["overlay"].bitmap)
    pbDrawTextPositions(@sprites["overlay"].bitmap, textpos)
    effects_str = ""
    effects_side = {
      :AuroraVeil  => "Aurora Veil",
      :LightScreen => "Light Screen",
      :LuckyChant  => "Lucky Chant",
      :Mist        => "Mist",
      :Rainbow     => "Rainbow",
      :Reflect     => "Reflect",
      :Safeguard   => "Safeguard",
      :SeaOfFire   => "Sea Of Fire",
      :Spikes      => "Spikes",
      :StealthRock => "Stealth Rocks",
      :StickyWeb   => "Sticky Web",
      :Swamp       => "Swamp",
      :Tailwind    => "Tailwind",
      :ToxicSpikes => "Toxic Spikes"
    }
    effects_field = {
      :WonderRoom      => "Wonder Room",
      :TrickRoom       => "Trick Room",
      :MagicRoom       => "Magic Room",
      :MudSportField   => "Mud Sport",
      :WaterSportField => "Water Sport",
      :IonDeluge       => "Ion Deluge",
      :Gravity         => "Gravity",
      :FairyLock       => "Fairy Lock",
      :NeutralizingGas => "Neutralizing Gas"
    }
    side_effects = battler.pbOwnSide.effects
    effects_side.each do |effect, name|
      e = getConst(PBEffects, effect)
      next if [nil, 0, -1, false].include?(side_effects[e])
      new_str = (nil_or_empty?(effects_str) ? "" : ", ") + name
      effects_str += new_str
    end
    field_effects = @battle.field.effects
    effects_field.each do |effect, name|
      e = getConst(PBEffects, effect)
      next if [nil, 0, -1, false].include?(field_effects[e])
      new_str = (nil_or_empty?(effects_str) ? "" : ", ") + name
      effects_str += new_str
    end
    effects_str = "None" if nil_or_empty?(effects_str)
    drawFormattedTextEx(@sprites["overlay"].bitmap, 288, 292, 212,
                        effects_str, @blackBase, @blackShadow, 28)
    textpos = [
      [battler.name, 16, 80, 0, @whiteBase, @whiteShadow]
    ]
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbDrawTextPositions(@sprites["overlay"].bitmap, textpos)
    textpos = [
      [_INTL("Attack"), 20, 124, 0, @whiteBase, @whiteShadow],
      [_INTL("Defense"), 270, 124, 0, @whiteBase, @whiteShadow],
      [_INTL("Sp.Atk"), 20, 160, 0, @whiteBase, @whiteShadow],
      [_INTL("Sp.Def"), 270, 160, 0, @whiteBase, @whiteShadow],
      [_INTL("Speed"), 20, 196, 0, @whiteBase, @whiteShadow],
      [_INTL("Accuracy"), 270, 196, 0, @whiteBase, @whiteShadow],
      [_INTL("Evasion."), 20, 232, 0, @whiteBase, @whiteShadow]
    ]
    pbSetNarrowFont(@sprites["overlay"].bitmap)
    pbDrawTextPositions(@sprites["overlay"].bitmap, textpos)
    imagepos.push(["Graphics/Pictures/Battle/Stats Screen/stat_box_2", 0, 16, 0, 0, 36, 36])
    @battle.battlers.each_with_index do |b, i|
      next if !b || b.fainted?
      if i == @idx_battler
        @sprites["icon"].x = 36 + (i * 66)
      else
        imagepos.push(["Graphics/Pictures/Battle/Stats Screen/stat_box", 36 + (i * 66), 2, 0, 0, 64, 64])
      end
    end
    imagepos.push(["Graphics/Pictures/Battle/Stats Screen/stat_box_2", 36 + (66 * @battle.battlers.length), 16, 36, 0, 36, 36])
    # Draw status icon
    if battler.status > 0
      s = battler.status
      s = 6 if s == PBStatuses::POISON && battler.statusCount > 0 # Badly poisoned
      imagepos.push(["Graphics/Pictures/Battle/icon_statuses", 238, 97,
                     0, (s - 1) * 16, -1, 16])
    end
    imagepos.push(["Graphics/Pictures/Battle/Stats Screen/icon_weather", 8, 322,
                   0, @battle.field.weather * 50, 86, 50])
    imagepos.push(["Graphics/Pictures/Battle/Stats Screen/icon_terrain", 106, 322,
                   0, @battle.field.terrain * 50, 86, 50])
    # Draw HP bar
    hpzone = 0
    hpzone = 1 if battler.displayPokemon.hp <= (battler.displayPokemon.totalhp / 2).floor
    hpzone = 2 if battler.displayPokemon.hp <= (battler.displayPokemon.totalhp / 4).floor
    imagepos.push(["Graphics/Pictures/Battle/Stats Screen/overlay_hp", 256, 84, 0, hpzone * 4,
                   battler.displayPokemon.hp * 96 / battler.displayPokemon.totalhp, 6])
    pbDrawImagePositions(@sprites["overlay"].bitmap, imagepos)
    type1rect = Rect.new(0, battler.displayPokemon.type1 * 28, 72, 28)
    type2rect = Rect.new(0, battler.displayPokemon.type2 * 28, 72, 28)
    if battler.displayPokemon.type1 == battler.displayPokemon.type2
      @sprites["overlay"].bitmap.blt(436, 82, @type_bmp.bitmap, type1rect)
    else
      @sprites["overlay"].bitmap.blt(366, 82, @type_bmp.bitmap, type1rect)
      @sprites["overlay"].bitmap.blt(436, 82, @type_bmp.bitmap, type2rect)
    end
    PBStats.eachBattleStat do |s|
      6.times do |i|
        ["_up", "_down"].each do |j|
          @sprites["#{s}#{i}#{j}"].visible = false
        end
      end
      stage = battler.stages[s].abs
      stage.times do |i|
        if battler.stages[s] > 0
          @sprites["#{s}#{i}_up"].visible = true
        elsif battler.stages[s] < 0
          @sprites["#{s}#{i}_down"].visible = true
        end
      end
    end
  end

  def pbScene
    loop do
      Graphics.update
      Input.update
      pbUpdateSpriteHash(@sprites)
      if Input.trigger?(Input::LEFT)
        loop do
          @idx_battler -= 1
          @idx_battler = @battle.battlers.length - 1 if @idx_battler < 0
          break if @battle.battlers[@idx_battler]
        end
        pbSEPlay("GUI summary change page")
        drawPage
      elsif Input.trigger?(Input::RIGHT)
        loop do
          @idx_battler += 1
          @idx_battler =  0 if @idx_battler >= @battle.battlers.length
          break if @battle.battlers[@idx_battler]
        end
        pbSEPlay("GUI summary change page")
        drawPage
      end
      if Input.trigger?(Input::B) || Input.trigger?(Input::C) || Input.pressex?(0x1B)
        pbSEPlay("GUI menu close")
        break
      end
    end
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @type_bmp.dispose
  end
end

class PokeBattle_Scene
  def pbStatsPage(idx_battler)
    @sprites["commandWindow"].pressAButton { (Graphics.frame_rate / 4).times { pbUpdate } }
    pbFadeOutIn(99999) { scene = PokemonStatsPage.new(@battle, idx_battler) }
  end
end
