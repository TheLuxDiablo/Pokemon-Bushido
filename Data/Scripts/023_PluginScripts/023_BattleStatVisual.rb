class PokemonStatsPage
  def initialize(battle,idxBattler)
    @battle   = battle
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @idxBattler = idxBattler
    @sprites = {}
    @typebitmap = AnimatedBitmap.new("Graphics/Pictures/types")
    @sprites["background"] = IconSprite.new(0,0,@viewport)
    @sprites["background"].setBitmap("Graphics/Pictures/Battle/StatVisual/stat_#{@idxBattler}")
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    @sprites["icon"] = PokemonIconSprite.new(@battle.battlers[idxBattler].pokemon,@viewport)
    @sprites["icon"].x = 2
    @sprites["icon"].y = 4
    pbSetSystemFont(@sprites["overlay"].bitmap)
    xVals = [122,374,122,374,122,374,122]
    yVals = [126,126,162,162,198,198,234]
    index = 0
    PBStats.eachBattleStat{|s|
      for i in 0...6
        for j in ["_up","_down"]
          @sprites["#{s}#{i}#{j}"] = AnimatedSprite.new("Graphics/Pictures/Battle/StatVisual/stat#{j}",9,14,28,3,@viewport)
          @sprites["#{s}#{i}#{j}"].x = xVals[index] + (19*i)
          @sprites["#{s}#{i}#{j}"].y = yVals[index]
          @sprites["#{s}#{i}#{j}"].visible = false
          @sprites["#{s}#{i}#{j}"].play
        end
      end
      index += 1
    }
    @whiteBase   = Color.new(248,248,248)
    @whiteShadow = Color.new(101,57,11)
    @blackBase   = Color.new(64,64,64)
    @blackShadow = Color.new(176,176,176)
    drawPage
    pbFadeInAndShow(@sprites)
    pbScene
    pbFadeOutAndHide(@sprites)
    dispose
  end

  def drawPage
    @sprites["overlay"].bitmap.clear
    battler = @battle.battlers[@idxBattler]
    @sprites["background"].setBitmap("Graphics/Pictures/Battle/StatVisual/stat_#{@idxBattler}")
    @sprites["icon"].pokemon = battler.pokemon
    imagepos = []
    textpos = [
      [_INTL("#{battler.level}"),180,85,0,@whiteBase,@whiteShadow],
      ["#{battler.hp}/#{battler.totalhp}",354,92,1,@whiteBase,@whiteShadow],
      ["Weather",49,294,2,@whiteBase,@whiteShadow],
      ["Terrain",147,294,2,@whiteBase,@whiteShadow],
      ["Active Battle Effects",392,264,2,@whiteBase,@whiteShadow],
    ]
    pbSetSmallFont(@sprites["overlay"].bitmap)
    pbDrawTextPositions(@sprites["overlay"].bitmap,textpos)
    effectString = ""
    effects1 = [
      :AuroraVeil, :LightScreen, :LuckyChant, :Mist, :Rainbow, :Reflect,
      :Safeguard, :SeaOfFire, :Spikes, :StealthRock, :StickyWeb, :Swamp,
      :Tailwind, :ToxicSpikes
    ]
    effect1Names = [
      "Aurora Veil", "Light Screen", "Lucky Chant", "Mist", "Rainbow",
      "Reflect", "Safeguard", "Sea Of Fire", "Spikes", "Stealth Rocks",
      "Sticky Web", "Swamp", "Tailwind", "Toxic Spikes"
    ]
    effects2 = [
      :WonderRoom, :TrickRoom, :MagicRoom, :MudSportField, :WaterSportField,
      :IonDeluge, :Gravity, :FairyLock, :NeutralizingGas
    ]
    effect2Names = [
      "Wonder Room", "Trick Room", "Magic Room", "Mud Sport", "Water Sport",
      "Ion Deluge", "Gravity", "Fairy Lock", "Neutralizing Gas"
    ]
    side = battler.pbOwnSide.effects
    effects1.each_with_index {|e,i|
      effectString += "#{nil_or_empty?(effectString)? "" : ", "}#{effect1Names[i]}" if ![nil,0,-1,false].include?(side[getConst(PBEffects, e)])
    }
    field = @battle.field.effects
    effects2.each_with_index {|e,i|
      effectString += "#{nil_or_empty?(effectString)? "" : ", "}#{effect2Names[i]}" if ![nil,0,-1,false].include?(field[getConst(PBEffects, e)])
    }
    effectString = "None" if nil_or_empty?(effectString)
    drawFormattedTextEx(@sprites["overlay"].bitmap,288,292,212,
      effectString,@blackBase,@blackShadow,28)
    textpos = [
      [battler.name,16,80,0,@whiteBase,@whiteShadow]
    ]
    pbSetSystemFont(@sprites["overlay"].bitmap)
    pbDrawTextPositions(@sprites["overlay"].bitmap,textpos)
    textpos = [
      [_INTL("Attack"),20,124,0,@whiteBase,@whiteShadow],
      [_INTL("Defense"),270,124,0,@whiteBase,@whiteShadow],
      [_INTL("Sp.Atk"),20,160,0,@whiteBase,@whiteShadow],
      [_INTL("Sp.Def"),270,160,0,@whiteBase,@whiteShadow],
      [_INTL("Speed"),20,196,0,@whiteBase,@whiteShadow],
      [_INTL("Accuracy"),270,196,0,@whiteBase,@whiteShadow],
      [_INTL("Evasion."),20,232,0,@whiteBase,@whiteShadow]
    ]
    pbSetNarrowFont(@sprites["overlay"].bitmap)
    pbDrawTextPositions(@sprites["overlay"].bitmap,textpos)
    imagepos.push(["Graphics/Pictures/Battle/StatVisual/stat_box_2",0,16,0,0,36,36])
    for i in 0...@battle.battlers.length
      if @battle.battlers[i]
        if i == @idxBattler
          @sprites["icon"].x = 36 + (i * 66)
        else
          imagepos.push(["Graphics/Pictures/Battle/StatVisual/stat_box",36 + (i * 66),2,0,0,64,64])
        end
      end
    end
    imagepos.push(["Graphics/Pictures/Battle/StatVisual/stat_box_2",36 + (66 * @battle.battlers.length),16,36,0,36,36])
    # Draw status icon
    if battler.status>0
      s = battler.status
      s = 6 if s==PBStatuses::POISON && battler.statusCount>0   # Badly poisoned
      imagepos.push(["Graphics/Pictures/Battle/icon_statuses",238,97,
         0,(s-1)*16,-1,16])
    end
    imagepos.push(["Graphics/Pictures/Battle/StatVisual/icon_weather",8,322,
      0,@battle.field.weather * 50,86,50])
    imagepos.push(["Graphics/Pictures/Battle/StatVisual/icon_terrain",106,322,
      0,@battle.field.terrain * 50,86,50])
    # Draw HP bar
    hpzone = 0
    hpzone = 1 if battler.hp<=(battler.totalhp/2).floor
    hpzone = 2 if battler.hp<=(battler.totalhp/4).floor
    imagepos.push(["Graphics/Pictures/Battle/overlay_hp",256,84,0,hpzone*6,battler.hp*96/battler.totalhp,6])
    pbDrawImagePositions(@sprites["overlay"].bitmap,imagepos)
    type1rect = Rect.new(0,battler.type1*28,72,28)
    type2rect = Rect.new(0,battler.type2*28,72,28)
    if battler.type1==battler.type2
      @sprites["overlay"].bitmap.blt(436,82,@typebitmap.bitmap,type1rect)
    else
      @sprites["overlay"].bitmap.blt(366,82,@typebitmap.bitmap,type1rect)
      @sprites["overlay"].bitmap.blt(436,82,@typebitmap.bitmap,type2rect)
    end
    PBStats.eachBattleStat{|s|
      for i in 0...6
        for j in ["_up","_down"]
          @sprites["#{s}#{i}#{j}"].visible = false
        end
      end
      stage = (battler.stages[s]).abs
      for i in 0...stage
        if battler.stages[s] > 0
          @sprites["#{s}#{i}_up"].visible = true
        else battler.stages[s] < 0
          @sprites["#{s}#{i}_down"].visible = true
        end
      end
    }
  end

  def pbScene
    loop do
      Graphics.update
      Input.update
      if Input.trigger?(Input::LEFT)
        loop do
          @idxBattler -= 1
          @idxBattler = @battle.battlers.length - 1 if @idxBattler < 0
          break if @battle.battlers[@idxBattler]
        end
        pbSEPlay("GUI summary change page")
        drawPage
      elsif Input.trigger?(Input::RIGHT)
        loop do
          @idxBattler += 1
          @idxBattler =  0 if @idxBattler >= @battle.battlers.length
          break if @battle.battlers[@idxBattler]
        end
        pbSEPlay("GUI summary change page")
        drawPage
      end
      if Input.trigger?(Input::B) || Input.trigger?(Input::C)
        pbSEPlay("GUI menu close")
        break
      end
      pbUpdateSpriteHash(@sprites)
    end
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @typebitmap.dispose
  end
end

class PokeBattle_Scene
  def pbStatsPage(idxBattler)
    @sprites["commandWindow"].pressAButton {10.times do; pbUpdate; end}
    pbFadeOutIn(99999) {scene = PokemonStatsPage.new(@battle,idxBattler)}
  end
end
