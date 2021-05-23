# Overhauls the classic Trainer Card from Pokémon Essentials
class PokeBattle_Trainer
  # These need to be initialized
  # A swinging number, increases and decreases with progress
  attr_accessor(:score)
  # Changes the Trainer Card, similar to achievements
  attr_accessor(:stars)
  # Battle Points, if you wish to use them
  attr_accessor(:bp)
  # Date and time
  attr_accessor(:halloffame)
  # Fake Trainer Class
  attr_accessor(:tclass)

  def score
    @score=0 if !@score
    return @score
  end

  def stars
    @stars=0 if !@stars
    return @stars
  end

  def bp
    @bp=0 if !@bp
    return @bp
  end

  def halloffame
    @halloffame=[] if !@halloffame
    return @halloffame
  end

  def tclass
    @tclass="PKMN Trainer" if !@tclass
    return @tclass
  end

  def publicID(id=nil)   # Portion of the ID which is visible on the Trainer Card
    return id ? id&0xFFFF : @id&0xFFFF
  end

  def fullname2
    return _INTL("{1} {2}",$Trainer.tclass,$Trainer.name)
  end

  def initialize(name,trainertype)
    @name=name
    @language=pbGetLanguage()
    @trainertype=trainertype
    @id=rand(256)
    @id|=rand(256)<<8
    @id|=rand(256)<<16
    @id|=rand(256)<<24
    @metaID=0
    @outfit=0
    @pokegear=false
    @pokedex=false
    clearPokedex
    @shadowcaught=[]
    for i in 1..PBSpecies.maxValue
      @shadowcaught[i]=false
    end
    @badges=[]
    for i in 0...8
      @badges[i]=false
    end
    @money=INITIAL_MONEY
    @party=[]
    @score=0
    @stars=0
    @bp=0
    @halloffame=[]
    @tclass="PKMN Trainer"
  end

  def getForeignID(number=nil)   # Random ID other than this Trainer's ID
    fid=0
    fid=number if number!=nil
    loop do
      fid=rand(256)
      fid|=rand(256)<<8
      fid|=rand(256)<<16
      fid|=rand(256)<<24
      break if fid!=@id
    end
    return fid
  end

  def setForeignID(other,number=nil)
    @id=other.getForeignID(number)
  end
end

class HallOfFame_Scene # Minimal change to store HoF time into a variable

  def writeTrainerData
    totalsec = Graphics.frame_count / Graphics.frame_rate
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    # Store time of first Hall of Fame in $Trainer.halloffame if not array is empty
    if $Trainer.halloffame=[]
      $Trainer.halloffame.push(pbGetTimeNow)
      $Trainer.halloffame.push(totalsec)
    end
    pubid=sprintf("%05d",$Trainer.publicID($Trainer.id))
    lefttext= _INTL("Name<r>{1}<br>",$Trainer.name)
    lefttext+=_INTL("IDNo.<r>{1}<br>",pubid)
    lefttext+=_ISPRINTF("Time<r>{1:02d}:{2:02d}<br>",hour,min)
    lefttext+=_INTL("Pokédex<r>{1}/{2}<br>",
        $Trainer.pokedexOwned,$Trainer.pokedexSeen)
    @sprites["messagebox"]=Window_AdvancedTextPokemon.new(lefttext)
    @sprites["messagebox"].viewport=@viewport
    @sprites["messagebox"].width=192 if @sprites["messagebox"].width<192
    @sprites["msgwindow"]=Kernel.pbCreateMessageWindow(@viewport)
    Kernel.pbMessageDisplay(@sprites["msgwindow"],
        _INTL("League champion!\nCongratulations!\\^"))
  end

end

class PokemonTrainerCard_Scene

  # Waits x frames
  def wait(frames)
    frames.times do
    Graphics.update
    end
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
    if @sprites["bg"]
      @sprites["bg"].ox-=2
      @sprites["bg"].oy-=2
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
    if $Trainer.stars==5
      baseColor   = baseGold
      shadowColor = shadowGold
    end
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
    $game_variables[94]=pbGetTotalPurified
    gameModes = []
    gameModes.push("#{($PokemonGlobal.randomizerRules && $PokemonGlobal.randomizerRules.include?(:SPECIES_MOVESETS))? "Extreme " : ""}Randomizer") if Randomizer.on?
    gameModes.push("#{($PokemonGlobal.nuzlockeRules && $PokemonGlobal.nuzlockeRules.include?(:NOSTORE))? "Extreme " : ""}Nuzlocke") if Nuzlocke.on?
    gameModes.push("Normal") if gameModes.length == 0
    gameModes = gameModes.to_s
    gameModes.gsub!("\"","")
    gameModes.gsub!("[","")
    gameModes.gsub!("]","")
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
          [_INTL("GAME MODE"),32,256+32,0,baseColor,shadowColor],
          [_INTL("Tales of Aisho"),302+89*2,256+32,1,baseColor,shadowColor]
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
         [_INTL("GAME MODE"),32,208+48,0,baseColor,shadowColor],
         [gameModes,302+88*2,208+48,1,baseColor,shadowColor],
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
         [_INTL("GAME MODE"),32,208+48,0,baseColor,shadowColor],
         [gameModes,302+88*2,208+48,1,baseColor,shadowColor],
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
         [_INTL("GAME MODE"),32,208+48,0,baseColor,shadowColor],
         [gameModes,302+88*2,208+48,1,baseColor,shadowColor],
         [_INTL("ADVENTURE STARTED"),32,256+32,0,baseColor,shadowColor],
         [starttime,302+89*2,256+32,1,baseColor,shadowColor]
      ]
    end
    # Draw trainer achievements
    x = 462
    for i in 0...8
      if $PokemonGlobal.gameModesWon[i]
        imagepos.push(["Graphics/Pictures/Trainer Card/icon_badges",x,10,i*32,0,32,32])
        x -= 36
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
