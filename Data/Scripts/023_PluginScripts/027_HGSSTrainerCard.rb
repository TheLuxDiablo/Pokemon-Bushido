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
      @sprites["card"].setBitmap("Graphics/Pictures/Trainer Card/card_#{$Trainer.stars}")
    end
    @sprites["card"].zoom_x=2 ; @sprites["card"].zoom_y=2

    @sprites["card"].ox=@sprites["card"].bitmap.width/2
    @sprites["card"].oy=@sprites["card"].bitmap.height/2

    @sprites["bg"].zoom_x=2 ; @sprites["bg"].zoom_y=2
    @sprites["bg"].ox+=6
    @sprites["bg"].oy-=26
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)

    @sprites["overlay2"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay2"].bitmap)

    @sprites["overlay"].x=128*2
    @sprites["overlay"].y=96*2
    @sprites["overlay"].ox=@sprites["overlay"].bitmap.width/2
    @sprites["overlay"].oy=@sprites["overlay"].bitmap.height/2

    @sprites["help_overlay"] = IconSprite.new(0,Graphics.height-48,@viewport)
    @sprites["help_overlay"].setBitmap("Graphics/Pictures/Trainer Card/overlay_0")
    @sprites["help_overlay"].zoom_x=2 ; @sprites["help_overlay"].zoom_y=2
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


  def flip1
    # "Flip"
    15.times do
      @sprites["overlay"].zoom_y=1.03
      @sprites["card"].zoom_y=2.06
      @sprites["overlay"].zoom_x-=0.1
      @sprites["trainer"].zoom_x-=0.2
      @sprites["trainer"].x-=12
      @sprites["card"].zoom_x-=0.15
      pbUpdate
      wait(1)
    end
      pbUpdate
  end

  def flip2
    # UNDO "Flip"
    15.times do
      @sprites["overlay"].zoom_x+=0.1
      @sprites["trainer"].zoom_x+=0.2
      @sprites["trainer"].x+=12
      @sprites["card"].zoom_x+=0.15
      @sprites["overlay"].zoom_y=1
      @sprites["card"].zoom_y=2
      pbUpdate
      wait(1)
    end
      pbUpdate
  end

  def pbDrawTrainerCardFront
    flip1 if @flip==true
    @front=true
    @sprites["trainer"].visible=true
    if $game_variables[99]=="Hattori"
      @sprites["card"].setBitmap("Graphics/Pictures/Trainer Card/card_H")
    else
      @sprites["card"].setBitmap("Graphics/Pictures/Trainer Card/card_#{$Trainer.stars}")
    end
    @overlay  = @sprites["overlay"].bitmap
    @overlay2 = @sprites["overlay2"].bitmap
    @overlay.clear
    @overlay2.clear
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
     if $game_variables[94]==0
       # loop through all pokemon and see if they've been purified, check if has NATIONAL ribbon?
       $game_variables[94]=pbGetTotalPurified
     end
     if $game_variables[99]=="Hattori"
       textPositions = [
          [_INTL("NAME"),332-60,64-16,0,baseColor,shadowColor],
          [$Trainer.name,302+89*2,64-16,1,baseColor,shadowColor],
          [_INTL("Kenshi Card"),32,12,0,baseColor,shadowColor],
          [_INTL("ID No."),32,64-16,0,baseColor,shadowColor],
          [sprintf("%05d",$Trainer.publicID($Trainer.id)),468-122*2,64-16,1,baseColor,shadowColor],
          [_INTL("MONEY"),32,112-16,0,baseColor,shadowColor],
          [_INTL("${1}",$Trainer.money.to_s_formatted),302+2,112-16,1,baseColor,shadowColor],
          [_INTL("Chapter: Hattori's Story"),32,112+32,0,baseColor,shadowColor],
          #[sprintf("%d",$game_variables[99]),302+2,112+32,1,baseColor,shadowColor],
          [_INTL("Pokémon Corrupted"),32,112+64,0,baseColor,shadowColor],
          [sprintf("%d",$game_variables[199]),302+2,112+64,1,baseColor,shadowColor],
          [_INTL("TIME"),32,256+32,0,baseColor,shadowColor],
          [time,302+89*2,256+32,1,baseColor,shadowColor]
          #[_INTL("ADVENTURE STARTED"),32,256+32,0,baseColor,shadowColor],
          #[starttime,302+89*2,256+32,1,baseColor,shadowColor]
       ]
    elsif $game_switches[67]
      textPositions = [
         [_INTL("NAME"),332-60,64-16,0,baseColor,shadowColor],
         [$Trainer.name,302+89*2,64-16,1,baseColor,shadowColor],
         [_INTL("Kenshi Card"),32,12,0,baseColor,shadowColor],
         [_INTL("ID No."),32,64-16,0,baseColor,shadowColor],
         [sprintf("%05d",$Trainer.publicID($Trainer.id)),468-122*2,64-16,1,baseColor,shadowColor],
         [_INTL("MONEY"),32,112-16,0,baseColor,shadowColor],
         [_INTL("${1}",$Trainer.money.to_s_formatted),302+2,112-16,1,baseColor,shadowColor],
         [_INTL("Chapter"),32,112+32,0,baseColor,shadowColor],
         [sprintf("%d",$game_variables[99]),302+2,112+32,1,baseColor,shadowColor],
         [_INTL("Katana Level"),32,112+64,0,baseColor,shadowColor],
         [sprintf("%d",$game_variables[100]),302+2,112+64,1,baseColor,shadowColor],
         [_INTL("Shadows Purified"),32,112+98,0,baseColor,shadowColor],
         [sprintf("%d",$game_variables[94]),302+2,112+98,1,baseColor,shadowColor],
         [_INTL("TIME"),32,208+48,0,baseColor,shadowColor],
         [time,302+88*2,208+48,1,baseColor,shadowColor],
         [_INTL("ADVENTURE STARTED"),32,256+32,0,baseColor,shadowColor],
         [starttime,302+89*2,256+32,1,baseColor,shadowColor]
      ]
    elsif $game_variables[100] !=0
      textPositions = [
         [_INTL("NAME"),332-60,64-16,0,baseColor,shadowColor],
         [$Trainer.name,302+89*2,64-16,1,baseColor,shadowColor],
         [_INTL("Kenshi Card"),32,12,0,baseColor,shadowColor],
         [_INTL("ID No."),32,64-16,0,baseColor,shadowColor],
         [sprintf("%05d",$Trainer.publicID($Trainer.id)),468-122*2,64-16,1,baseColor,shadowColor],
         [_INTL("MONEY"),32,112-16,0,baseColor,shadowColor],
         [_INTL("${1}",$Trainer.money.to_s_formatted),302+2,112-16,1,baseColor,shadowColor],
         [_INTL("Chapter"),32,112+32,0,baseColor,shadowColor],
         [sprintf("%d",$game_variables[99]),302+2,112+32,1,baseColor,shadowColor],
         [_INTL("Katana Level"),32,112+64,0,baseColor,shadowColor],
         [sprintf("%d",$game_variables[100]),302+2,112+64,1,baseColor,shadowColor],
         [_INTL("---"),32,112+98,0,baseColor,shadowColor],
         [sprintf("-"),302+2,112+98,1,baseColor,shadowColor],
         [_INTL("TIME"),32,208+48,0,baseColor,shadowColor],
         [time,302+88*2,208+48,1,baseColor,shadowColor],
         [_INTL("ADVENTURE STARTED"),32,256+32,0,baseColor,shadowColor],
         [starttime,302+89*2,256+32,1,baseColor,shadowColor]
      ]
    else
      textPositions = [
         [_INTL("NAME"),332-60,64-16,0,baseColor,shadowColor],
         [$Trainer.name,302+89*2,64-16,1,baseColor,shadowColor],
         [_INTL("Kenshi Card"),32,12,0,baseColor,shadowColor],
         [_INTL("ID No."),32,64-16,0,baseColor,shadowColor],
         [sprintf("%05d",$Trainer.publicID($Trainer.id)),468-122*2,64-16,1,baseColor,shadowColor],
         [_INTL("MONEY"),32,112-16,0,baseColor,shadowColor],
         [_INTL("${1}",$Trainer.money.to_s_formatted),302+2,112-16,1,baseColor,shadowColor],
         [_INTL("Chapter"),32,112+32,0,baseColor,shadowColor],
         [sprintf("%d",$game_variables[99]),302+2,112+32,1,baseColor,shadowColor],
         [_INTL("---"),32,112+64,0,baseColor,shadowColor],
         [sprintf("-"),302+2,112+64,1,baseColor,shadowColor],
         [_INTL("---"),32,112+98,0,baseColor,shadowColor],
         [sprintf("-"),302+2,112+98,1,baseColor,shadowColor],
         [_INTL("TIME"),32,208+48,0,baseColor,shadowColor],
         [time,302+88*2,208+48,1,baseColor,shadowColor],
         [_INTL("ADVENTURE STARTED"),32,256+32,0,baseColor,shadowColor],
         [starttime,302+89*2,256+32,1,baseColor,shadowColor]
      ]
    end
    @sprites["overlay"].z+=10
    pbDrawTextPositions(@overlay,textPositions)
    if @flip==true
      textPositions = [[_INTL("Press F5 to flip the card."),16,64+280,0,Color.new(216,216,216),Color.new(80,80,80)]]
    else
      textPositions = [[_INTL(""),16,64+280,0,Color.new(216,216,216),Color.new(80,80,80)]]
    end
    @sprites["overlay2"].z+=20
    pbDrawTextPositions(@overlay2,textPositions)
    flip2 if @flip==true
  end

  def pbDrawTrainerCardBack
    pbUpdate
    @flip=true
    flip1
    @front=false
    @sprites["trainer"].visible=false
    @sprites["card"].setBitmap("Graphics/Pictures/Trainer Card/card_#{$Trainer.stars}b")
    @overlay  = @sprites["overlay"].bitmap
    @overlay2 = @sprites["overlay2"].bitmap
    @overlay.clear
    @overlay2.clear
    baseColor   = Color.new(72,72,72)
    shadowColor = Color.new(160,160,160)
    baseGold = Color.new(255,198,74)
    shadowGold = Color.new(123,107,74)
    if $Trainer.stars==5
      baseColor   = baseGold
      shadowColor = shadowGold
    end
    hof=[]
    if $Trainer.halloffame!=[]
      hof.push(_INTL("{1} {2}, {3}",
      pbGetAbbrevMonthName($Trainer.halloffame[0].mon),
      $Trainer.halloffame[0].day,
      $Trainer.halloffame[0].year))
      hour = $Trainer.halloffame[1] / 60 / 60
      min = $Trainer.halloffame[1] / 60 % 60
      time=_ISPRINTF("{1:02d}:{2:02d}",hour,min)
      hof.push(time)
    else
      hof.push("--- --, ----")
      hof.push("--:--")
    end
    textPositions = [
      [_INTL("HALL OF FAME DEBUT"),32,64-48,0,baseColor,shadowColor],
      [hof[0],302+89*2,64-48,1,baseColor,shadowColor],
      [hof[1],302+89*2,64-16,1,baseColor,shadowColor],
      # These are meant to be Link Battle modes, use as you wish, see below
      #[_INTL(" "),32+111*2,112-16,0,baseColor,shadowColor],
      #[_INTL(" "),32+176*2,112-16,0,baseColor,shadowColor],

      [_INTL("W"),32+111*2,112-16+32,0,baseColor,shadowColor],
      [_INTL("L"),32+176*2,112-16+32,0,baseColor,shadowColor],

      [_INTL("W"),32+111*2,112-16+64,0,baseColor,shadowColor],
      [_INTL("L"),32+176*2,112-16+64,0,baseColor,shadowColor],

      # Customize "$game_variables[100]" to use whatever variable you'd like
      # Some examples: eggs hatched, berries collected,
      # total steps (maybe converted to km/miles? Be creative, dunno!)
      # Pokémon defeated, shiny Pokémon encountered, etc.
      # While I do not include how to create those variables, feel free to HMU
      # if you need some support in the process, or reply to the Relic Castle
      # thread.

      [_INTL($Trainer.fullname2),32,112-16,0,baseColor,shadowColor],
      #[_INTL(" ",$game_variables[100]),302+2+50-2,112-16,1,baseColor,shadowColor],
      #[_INTL(" ",$game_variables[100]),302+2+50+63*2,112-16,1,baseColor,shadowColor],

      [_INTL("STRING 2"),32,112+32-16,0,baseColor,shadowColor],
      [_INTL("{1}",$game_variables[100]),302+2+50-2,112+32-16,1,baseColor,shadowColor],
      [_INTL("{1}",$game_variables[100]),302+2+50+63*2,112+32-16,1,baseColor,shadowColor],

      [_INTL("STRING 3"),32,112+32-16+32,0,baseColor,shadowColor],
      [_INTL("{1}",$game_variables[100]),302+2+50-2,112+32-16+32,1,baseColor,shadowColor],
      [_INTL("{1}",$game_variables[100]),302+2+50+63*2,112+32-16+32,1,baseColor,shadowColor],
    ]
    @sprites["overlay"].z+=20
    pbDrawTextPositions(@overlay,textPositions)
    textPositions = [
      [_INTL("Press F5 to flip the card."),16,64+280,0,Color.new(216,216,216),Color.new(80,80,80)]
    ]
    @sprites["overlay2"].z+=20
    pbDrawTextPositions(@overlay2,textPositions)
    # Draw Badges on overlay (doesn't support animations, might support .gif)
    imagepos=[]
    # Draw Region 0 badges
    x = 64-28
    for i in 0...8
      if $Trainer.badges[i+0*8]
        imagepos.push(["Graphics/Pictures/Trainer Card/badges0",x,104*2,i*48,0*48,48,48])
      end
      x += 48+8
    end
    # Draw Region 1 badges
    x = 64-28
    for i in 0...8
      if $Trainer.badges[i+1*8]
        imagepos.push(["Graphics/Pictures/Trainer Card/badges1",x,104*2+52,i*48,0*48,48,48])
      end
      x += 48+8
    end
    #print(@sprites["overlay"].ox,@sprites["overlay"].oy,x)
    pbDrawImagePositions(@overlay,imagepos)
    flip2
  end

  def pbTrainerCard
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::F5)
        if @front==true
          pbDrawTrainerCardBack
          wait(3)
        else
          pbDrawTrainerCardFront if @front==false
          wait(3)
        end
      end
      if Input.trigger?(Input::B)
        break
      end
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
