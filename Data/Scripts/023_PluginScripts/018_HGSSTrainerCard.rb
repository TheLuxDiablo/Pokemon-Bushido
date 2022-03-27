class PokemonTrainerCard_Scene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
    if @sprites["bg"]
      @sprites["bg"].ox -= 2
      @sprites["bg"].oy -= 2
    end
  end

  def pbStartScene
    @front=true
    @flip=false
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    if $game_variables[99]=="Hattori"
      addBackgroundPlane(@sprites,"bg","Trainer Card/bg_H",@viewport)
    else
      addBackgroundPlane(@sprites,"bg","Trainer Card/bg",@viewport)
    end
    @sprites["card"] = IconSprite.new(128*2,96*2,@viewport)
    if $game_variables[99]=="Hattori"
      @sprites["card"].setBitmap("Graphics/Pictures/Trainer Card/card_H")
    else
      @sprites["card"].setBitmap("Graphics/Pictures/Trainer Card/card_0")
    end
    @sprites["card"].zoom_x=2 ; @sprites["card"].zoom_y=2
    @sprites["card"].ox=@sprites["card"].bitmap.width/2
    @sprites["card"].oy=@sprites["card"].bitmap.height/2
    @sprites["bg"].zoom_x=2 ; @sprites["bg"].zoom_y=2
    @sprites["bg"].ox+=6
    @sprites["bg"].oy-=26
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["overlay"].x=128*2
    @sprites["overlay"].y=96*2
    @sprites["overlay"].ox=@sprites["overlay"].bitmap.width/2
    @sprites["overlay"].oy=@sprites["overlay"].bitmap.height/2
    @sprites["trainer"] = IconSprite.new(336,112,@viewport)
    @sprites["trainer"].setBitmap(pbPlayerSpriteFile($Trainer.trainertype))
    @sprites["trainer"].x -= (@sprites["trainer"].bitmap.width-128)/2+36-4
    @sprites["trainer"].y -= (@sprites["trainer"].bitmap.height-128)+80+4
    @sprites["trainer"].x += 120
    @sprites["trainer"].y += 80
    @tx=@sprites["trainer"].x
    @ty=@sprites["trainer"].y
    @sprites["trainer"].ox=@sprites["trainer"].bitmap.width/2
    pbDrawTrainerCardFront
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbDrawTrainerCardFront
    flip1 if @flip==true
    @front=true
    @sprites["trainer"].visible=true
    if $game_variables[99]=="Hattori"
      @sprites["card"].setBitmap("Graphics/Pictures/Trainer Card/card_H")
    else
      @sprites["card"].setBitmap("Graphics/Pictures/Trainer Card/card_0")
    end
    @overlay  = @sprites["overlay"].bitmap
    @overlay.clear
    baseColor   = Color.new(72,72,72)
    shadowColor = Color.new(160,160,160)
    baseGold = Color.new(255,198,74)
    shadowGold = Color.new(123,107,74)
    totalsec = Graphics.frame_count / Graphics.frame_rate
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    time = _ISPRINTF("{1:02d}:{2:02d}",hour,min)
    $PokemonGlobal.startTime = pbGetTimeNow if !$PokemonGlobal.startTime
    starttime = _INTL("{1} {2}, {3}",
       pbGetAbbrevMonthName($PokemonGlobal.startTime.mon),
       $PokemonGlobal.startTime.day,
       $PokemonGlobal.startTime.year)
    # loop through all pokemon and see if they've been purified, check if has NATIONAL ribbon?
    $game_variables[94] = pbGetTotalPurified
    game_modes = []
    if Randomizer.on? && $PokemonGlobal.randomizerRules
      if $PokemonGlobal.randomizerRules.include?(:MOVESETS)
        game_modes.push(_INTL("Extreme Randomizer"))
      elsif $PokemonGlobal.randomizerRules.include?(:TRAINERS)
        game_modes.push(_INTL("Super Randomizer"))
      else
        game_modes.push(_INTL("Randomizer"))
      end
    end
    if (Nuzlocke.on? || $PokemonGlobal.qNuzlocke) && $PokemonGlobal.nuzlockeRules
      if $PokemonGlobal.nuzlockeRules.include?(:NOSTORE)
        game_modes.push(_INTL("Hardcore Nuzlocke"))
      else
        game_modes.push(_INTL("Nuzlocke"))
      end
    end
    game_modes.push(_INTL("Normal")) if game_modes.length == 0
    game_modes = game_modes.to_s
    game_modes.gsub!("\"","")
    game_modes.gsub!("[","")
    game_modes.gsub!("]","")
    imagepos = []
    if $game_variables[99]=="Hattori"
       textPositions = [
          [_INTL("NAME"),332-60,64-16,0,baseColor,shadowColor],
          [$Trainer.name,302+89*2,64-16,1,baseColor,shadowColor],
          [_INTL("Kenshi Card"),32,12,0,baseColor,shadowColor],
          [_INTL("Time."),32,64-16,0,baseColor,shadowColor],
          [time,468-122*2,64-16,1,baseColor,shadowColor],
          [_INTL("MONEY"),32,112-16,0,baseColor,shadowColor],
          [_INTL("${1}",$Trainer.money.to_s_formatted),302+2,112-16,1,baseColor,shadowColor],
          [_INTL("Chapter: Hattori's Story"),32,112+32,0,baseColor,shadowColor],
          #[sprintf("%d",$game_variables[99]),302+2,112+32,1,baseColor,shadowColor],
          [_INTL("Pokémon Corrupted"),32,112+64,0,baseColor,shadowColor],
          [sprintf("%d",$game_variables[199]),302+2,112+64,1,baseColor,shadowColor],
          [_INTL("Tales of Aisho"),32,256+32,1,baseColor,shadowColor]
          #[_INTL("ADVENTURE STARTED"),32,256+32,0,baseColor,shadowColor],
          #[starttime,302+89*2,256+32,1,baseColor,shadowColor]
       ]
    elsif $game_switches[67]
      textPositions = [
         [_INTL("NAME"),332-60,64-16,0,baseColor,shadowColor],
         [$Trainer.name,302+89*2,64-16,1,baseColor,shadowColor],
         [_INTL("Kenshi Card"),32,12,0,baseColor,shadowColor],
         [_INTL("Time."),32,64-16,0,baseColor,shadowColor],
         [time,468-122*2,64-16,1,baseColor,shadowColor],
         [_INTL("MONEY"),32,112-16,0,baseColor,shadowColor],
         [_INTL("${1}",$Trainer.money.to_s_formatted),302+2,112-16,1,baseColor,shadowColor],
         [_INTL("Chapter"),32,112+32,0,baseColor,shadowColor],
         [sprintf("%d",$game_variables[99]),302+2,112+32,1,baseColor,shadowColor],
         [_INTL("Katana Level"),32,112+64,0,baseColor,shadowColor],
         [sprintf("%d",$game_variables[100]),302+2,112+64,1,baseColor,shadowColor],
         [_INTL("Shadows Purified"),32,112+98,0,baseColor,shadowColor],
         [sprintf("%d",$game_variables[94]),302+2,112+98,1,baseColor,shadowColor],
         [_INTL("{1} mode", game_modes),32,208+48,0,baseColor,shadowColor],
         [_INTL("ADVENTURE STARTED"),32,256+32,0,baseColor,shadowColor],
         [starttime,302+89*2,256+32,1,baseColor,shadowColor]
      ]
    elsif $game_variables[100] !=0
      textPositions = [
         [_INTL("NAME"),332-60,64-16,0,baseColor,shadowColor],
         [$Trainer.name,302+89*2,64-16,1,baseColor,shadowColor],
         [_INTL("Kenshi Card"),32,12,0,baseColor,shadowColor],
         [_INTL("Time."),32,64-16,0,baseColor,shadowColor],
         [time,468-122*2,64-16,1,baseColor,shadowColor],
         [_INTL("MONEY"),32,112-16,0,baseColor,shadowColor],
         [_INTL("${1}",$Trainer.money.to_s_formatted),302+2,112-16,1,baseColor,shadowColor],
         [_INTL("Chapter"),32,112+32,0,baseColor,shadowColor],
         [sprintf("%d",$game_variables[99]),302+2,112+32,1,baseColor,shadowColor],
         [_INTL("Katana Level"),32,112+64,0,baseColor,shadowColor],
         [sprintf("%d",$game_variables[100]),302+2,112+64,1,baseColor,shadowColor],
         [_INTL("---"),32,112+98,0,baseColor,shadowColor],
         [sprintf("-"),302+2,112+98,1,baseColor,shadowColor],
         [_INTL("{1} mode", game_modes),32,208+48,0,baseColor,shadowColor],
         [_INTL("ADVENTURE STARTED"),32,256+32,0,baseColor,shadowColor],
         [starttime,302+89*2,256+32,1,baseColor,shadowColor]
      ]
    else
      textPositions = [
         [_INTL("NAME"),332-60,64-16,0,baseColor,shadowColor],
         [$Trainer.name,302+89*2,64-16,1,baseColor,shadowColor],
         [_INTL("Kenshi Card"),32,12,0,baseColor,shadowColor],
         [_INTL("Time."),32,64-16,0,baseColor,shadowColor],
         [time,468-122*2,64-16,1,baseColor,shadowColor],
         [_INTL("MONEY"),32,112-16,0,baseColor,shadowColor],
         [_INTL("${1}",$Trainer.money.to_s_formatted),302+2,112-16,1,baseColor,shadowColor],
         [_INTL("Chapter"),32,112+32,0,baseColor,shadowColor],
         [sprintf("%d",$game_variables[99]),302+2,112+32,1,baseColor,shadowColor],
         [_INTL("---"),32,112+64,0,baseColor,shadowColor],
         [sprintf("-"),302+2,112+64,1,baseColor,shadowColor],
         [_INTL("---"),32,112+98,0,baseColor,shadowColor],
         [sprintf("-"),302+2,112+98,1,baseColor,shadowColor],
         [_INTL("{1} mode", game_modes),32,208+48,0,baseColor,shadowColor],
         [_INTL("ADVENTURE STARTED"),32,256+32,0,baseColor,shadowColor],
         [starttime,302+89*2,256+32,1,baseColor,shadowColor]
      ]
    end
    # Draw trainer achievements
    x = 462
    if $game_variables[99] != "Hattori"
      for i in 0...8
        if $PokemonGlobal.gameModesWon[i]
          imagepos.push(["Graphics/Pictures/Trainer Card/icon_badges",x,10,i*32,0,32,32])
          x -= 36
        end
      end
    end
    pbDrawImagePositions(@overlay,imagepos)
    pbDrawTextPositions(@overlay,textPositions)
  end

  def pbTrainerCard
    loop do
      Graphics.update
      Input.update
      pbUpdate
      break if Input.trigger?(Input::B) || Input.trigger?(Input::C)
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end



class PokemonTrainerCardScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbTrainerCard
    @scene.pbEndScene
  end
end
