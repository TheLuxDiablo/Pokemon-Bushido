class PokemonLoadPanel < SpriteWrapper
  attr_reader :selected
  attr_reader :title

  TEXTCOLOR             = Color.new(80,80,88)
  TEXTSHADOWCOLOR       = Color.new(160,160,168)
  MALETEXTCOLOR         = Color.new(56,160,248)
  MALETEXTSHADOWCOLOR   = Color.new(56,104,168)
  FEMALETEXTCOLOR       = Color.new(240,72,88)
  FEMALETEXTSHADOWCOLOR = Color.new(160,64,64)

  def initialize(index,title,isContinue,trainer,framecount,mapid,viewport=nil)
    super(viewport)
    @index = index
    @title = title
    @isContinue = isContinue
    @trainer = trainer
    @totalsec = (framecount || 0) / Graphics.frame_rate
    @mapid = mapid
    @selected = (index==0)
    @bgbitmap = AnimatedBitmap.new("Graphics/Pictures/loadPanels")
    @refreshBitmap = true
    @refreshing = false
    refresh
  end

  def title=(value)
    @title = value
    @refreshBitmap = true
    @refreshing = false
    pbRefresh
  end

  def isContinue=(value)
    @isContinue = value
    @refreshBitmap = true
    @refreshing = false
    pbRefresh
  end

  def setData(trainer,framecount,mapid)
    @trainer = trainer
    @totalsec = (framecount || 0) / Graphics.frame_rate
    @mapid = mapid
    @refreshBitmap = true
    @refreshing = false
    pbRefresh
  end

  def dispose
    @bgbitmap.dispose
    self.bitmap.dispose
    super
  end

  def selected=(value)
    return if @selected==value
    @selected = value
    @refreshBitmap = true
    refresh
  end

  def pbRefresh
    @refreshBitmap = true
    refresh
  end

  def refresh
    return if @refreshing
    return if disposed?
    @refreshing = true
    if !self.bitmap || self.bitmap.disposed?
      self.bitmap = BitmapWrapper.new(@bgbitmap.width,111*2)
      pbSetSystemFont(self.bitmap)
    end
    if @refreshBitmap
      @refreshBitmap = false
      self.bitmap.clear if self.bitmap
      if @isContinue
        self.bitmap.blt(0,0,@bgbitmap.bitmap,Rect.new(0,(@selected) ? 111*2 : 0,@bgbitmap.width,111*2))
      else
        self.bitmap.blt(0,0,@bgbitmap.bitmap,Rect.new(0,111*2*2+((@selected) ? 23*2 : 0),@bgbitmap.width,23*2))
      end
      textpos = []
      if @isContinue
        textpos.push([@title,16*2,5*2,0,TEXTCOLOR,TEXTSHADOWCOLOR])
        textpos.push([_INTL("Chapter:"),16*2,56*2,0,TEXTCOLOR,TEXTSHADOWCOLOR])
        textpos.push([@trainer.chapter.to_s,103*2,56*2,1,TEXTCOLOR,TEXTSHADOWCOLOR])
        textpos.push([_INTL("Journal:"),16*2,72*2,0,TEXTCOLOR,TEXTSHADOWCOLOR])
        textpos.push([@trainer.pokedexSeen.to_s,103*2,72*2,1,TEXTCOLOR,TEXTSHADOWCOLOR])
        textpos.push([_INTL("Time:"),16*2,88*2,0,TEXTCOLOR,TEXTSHADOWCOLOR])
        hour = @totalsec / 60 / 60
        min  = @totalsec / 60 % 60
        if hour>0
          textpos.push([_INTL("{1}h {2}m",hour,min),103*2,88*2,1,TEXTCOLOR,TEXTSHADOWCOLOR])
        else
          textpos.push([_INTL("{1}m",min),103*2,88*2,1,TEXTCOLOR,TEXTSHADOWCOLOR])
        end
        if @trainer.male?
          textpos.push([@trainer.name,56*2,32*2,0,MALETEXTCOLOR,MALETEXTSHADOWCOLOR])
        elsif @trainer.female?
          textpos.push([@trainer.name,56*2,32*2,0,FEMALETEXTCOLOR,FEMALETEXTSHADOWCOLOR])
        else
          textpos.push([@trainer.name,56*2,32*2,0,TEXTCOLOR,TEXTSHADOWCOLOR])
        end
        mapname = pbGetMapNameFromId(@mapid)
        mapname.gsub!(/\\PN/,@trainer.name)
        textpos.push([mapname,193*2,5*2,1,TEXTCOLOR,TEXTSHADOWCOLOR])
      else
        textpos.push([@title,16*2,4*2,0,TEXTCOLOR,TEXTSHADOWCOLOR])
      end
      pbDrawTextPositions(self.bitmap,textpos)
    end
    @refreshing = false
  end
end



class PokemonLoad_Scene
  def pbStartScene(commands,showContinue,trainer,framecount,mapid)
    @commands = commands
    @sprites = {}
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99998
    addBackgroundOrColoredPlane(@sprites,"background","loadbg",Color.new(248,248,248),@viewport)
    y = 16*2
    for i in 0...commands.length
      @sprites["panel#{i}"] = PokemonLoadPanel.new(i,commands[i],
         (showContinue) ? (i==0) : false,trainer,framecount,mapid,@viewport)
      @sprites["panel#{i}"].x = 24*2
      @sprites["panel#{i}"].y = y
      @sprites["panel#{i}"].pbRefresh
      y += (showContinue && i==0) ? 112*2 : 24*2
    end
    @sprites["cmdwindow"] = Window_CommandPokemon.new([])
    @sprites["cmdwindow"].viewport = @viewport
    @sprites["cmdwindow"].visible  = false
    @sprites["loadPanel"] = PokemonLoadPanel.new(999,"Nil",false,trainer,framecount,mapid,@viewport)
    @sprites["loadPanel"].x = 48
    @sprites["loadPanel"].y = 32
    @sprites["loadPanel"].visible = false
    @sprites["messagebox"] = Window_AdvancedTextPokemon.new("C: Select                                                A: Delete")
    @sprites["messagebox"].y = Graphics.height - @sprites["messagebox"].height
    @sprites["messagebox"].x = (Graphics.width - @sprites["messagebox"].width)/2
    @sprites["messagebox"].viewport       = @viewport
    @sprites["messagebox"].visible        = false
    @sprites["messagebox"].letterbyletter = false
    @sprites["messagebox"].setSkin(MessageConfig.pbGetSystemFrame())
  end

  def pbStartScene2
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartDeleteScene
    @sprites = {}
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99998
    addBackgroundOrColoredPlane(@sprites,"background","loadbg",Color.new(248,248,248),@viewport)
  end

  def pbShowSlots(array,delete= false)
    oldTitles = []
    for i in 0...@commands.length
      @sprites["panel#{i}"].visible = false
      oldTitles.push(@sprites["panel#{i}"].title)
    end
    for i in 0...array.length
      @sprites["panel#{i}"].visible = true
      @sprites["panel#{i}"].title = array[i]
      @sprites["panel#{i}"].selected = false
    end
    @sprites["panel0"].selected = true
    ret = -1
    index = 0
    if delete
      @sprites["messagebox"].visible = true
    end
    loop do
      Graphics.update
      Input.update
      pbUpdateSpriteHash(@sprites)
      if Input.trigger?(Input::C)
        ret = index
        break
      elsif Input.trigger?(Input::B)
        ret = -1
        break
      elsif Input.trigger?(Input::A) && delete
        ret = -2 - index
        pbPlayDecisionSE
        break
      elsif Input.trigger?(Input::UP)
        pbPlayCursorSE
        index -= 1
        index = (array.length - 1) if index < 0
        for i in 0...array.length
          @sprites["panel#{i}"].selected = false
        end
        @sprites["panel#{index}"].selected = true
        Graphics.update
      elsif Input.trigger?(Input::DOWN)
        pbPlayCursorSE
        index += 1
        index = 0 if index >= (array.length)
        for i in 0...array.length
          @sprites["panel#{i}"].selected = false
        end
        @sprites["panel#{index}"].selected = true
        Graphics.update
      end
    end
    for i in 0...@commands.length
      @sprites["panel#{i}"].title = oldTitles[i] if delete
    end
    if ret < 0
      for i in 0...@commands.length
        @sprites["panel#{i}"].title = oldTitles[i]
        @sprites["panel#{i}"].visible = true
        @sprites["panel#{i}"].selected = false
      end
      @sprites["panel#{delete ? 0 : 1}"].selected = true
      @sprites["cmdwindow"].index = delete ? 0 : 1
    end
    @sprites["messagebox"].visible = false
    return ret
  end

  def pbShowLoadScreen(data,message)
    for i in 0...@commands.length
      @sprites["panel#{i}"].visible = false
    end
    @sprites["loadPanel"].visible = true
    @sprites["loadPanel"].setData(data[0],data[1],data[2])
    @sprites["loadPanel"].title = (message == "Would you like to load this file?") ? "Slot #{$PokemonTemp.saveSlot + 1}" : "Continue..."
    @sprites["loadPanel"].isContinue = true
    pbSetParty(data[0])
    array = ["Yes","No"]
    array.push("Delete") if message != "Would you like to load this file?"
    ret = pbMessage(message,array) {pbUpdate}
    if ret != 0
      @sprites["loadPanel"].visible = false
      pbHideParty(data[0])
      for i in 0...@commands.length
        @sprites["panel#{i}"].visible = true
        @sprites["panel#{i}"].selected = false
      end
      @sprites["panel0"].selected = true
      @sprites["cmdwindow"].index = 0
      return ret
    end
    return 0
  end

  def pbUpdate
    oldi = @sprites["cmdwindow"].index rescue 0
    pbUpdateSpriteHash(@sprites)
    newi = @sprites["cmdwindow"].index rescue 0
    if oldi!=newi
      @sprites["panel#{oldi}"].selected = false
      @sprites["panel#{oldi}"].pbRefresh
      @sprites["panel#{newi}"].selected = true
      @sprites["panel#{newi}"].pbRefresh
      while @sprites["panel#{newi}"].y>Graphics.height-40*2
        for i in 0...@commands.length
          @sprites["panel#{i}"].y -= 24*2
        end
        for i in 0...6
          break if !@sprites["party#{i}"]
          @sprites["party#{i}"].y -= 24*2
        end
        @sprites["player"].y -= 24*2 if @sprites["player"]
      end
      while @sprites["panel#{newi}"].y<16*2
        for i in 0...@commands.length
          @sprites["panel#{i}"].y += 24*2
        end
        for i in 0...6
          break if !@sprites["party#{i}"]
          @sprites["party#{i}"].y += 24*2
        end
        @sprites["player"].y += 24*2 if @sprites["player"]
      end
    end
  end

  def pbSetParty(trainer)
    return if !trainer || !trainer.party
    meta = pbGetMetadata(0,MetadataPlayerA+trainer.metaID)
    if meta
      filename = pbGetPlayerCharset(meta,1,trainer,true)
      @sprites["player"] = TrainerWalkingCharSprite.new(filename,@viewport)
      charwidth  = @sprites["player"].bitmap.width
      charheight = @sprites["player"].bitmap.height
      @sprites["player"].x        = 56*2-charwidth/8
      @sprites["player"].y        = 56*2-charheight/8
      @sprites["player"].src_rect = Rect.new(0,0,charwidth/4,charheight/4)
    end
    for i in 0...trainer.party.length
      @sprites["party#{i}"] = PokemonIconSprite.new(trainer.party[i],@viewport)
      @sprites["party#{i}"].setOffset(PictureOrigin::Center)
      @sprites["party#{i}"].x = (167+33*(i%2))*2
      @sprites["party#{i}"].y = (56+25*(i/2))*2
      @sprites["party#{i}"].z = 99999
    end
  end

  def pbHideParty(trainer)
    @sprites["player"].visible = false
    @sprites["player"] = nil
    for i in 0...trainer.party.length
      @sprites["party#{i}"].visible = false
      @sprites["party#{i}"] = nil
    end
    Graphics.update
  end

  def pbChoose(commands)
    @sprites["cmdwindow"].commands = commands
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::C)
        return @sprites["cmdwindow"].index
      end
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end



class PokemonLoadScreen
  def initialize(scene)
    @scene = scene
  end

  def pbTryLoadFile(savefile)
    trainer       = nil
    framecount    = nil
    game_system   = nil
    pokemonSystem = nil
    mapid         = nil
    File.open(savefile) { |f|
      trainer       = Marshal.load(f)
      framecount    = Marshal.load(f)
      game_system   = Marshal.load(f)
      pokemonSystem = Marshal.load(f)
      mapid         = Marshal.load(f)
    }
    raise "Corrupted file" if !trainer.is_a?(PokeBattle_Trainer)
    raise "Corrupted file" if !framecount.is_a?(Numeric)
    raise "Corrupted file" if !game_system.is_a?(Game_System)
    raise "Corrupted file" if !pokemonSystem.is_a?(PokemonSystem)
    raise "Corrupted file" if !mapid.is_a?(Numeric)
    return [trainer,framecount,game_system,pokemonSystem,mapid]
  end

  def pbStartDeleteScreen(slot)
    savefile = RTP.getSaveFileName("Game_#{slot}.rxdata")
    if safeExists?(savefile)
      if pbConfirmMessageSerious(_INTL("Delete all saved data from Slot #{slot + 1}?"))
        pbMessage(_INTL("Once data has been deleted, there is no way to recover it.\1"))
        if pbConfirmMessageSerious(_INTL("Delete the saved data anyway?"))
          pbMessage(_INTL("Deleting all data. Don't turn off the power.\\wtnp[0]"))
          begin; File.delete(savefile); rescue; end
          begin; File.delete(savefile+".bak"); rescue; end
          pbMessage(_INTL("The save file was deleted."))
          return true
        end
      end
    end
    return false
  end

  def pbStartLoadScreen
    $PokemonTemp   = PokemonTemp.new if !$PokemonTemp
    $game_temp     = Game_Temp.new
    $game_system   = Game_System.new
    $PokemonSystem = PokemonSystem.new if !$PokemonSystem
    data_system = load_data("Data/System.rxdata")
    mapfile = sprintf("Data/Map%03d.rxdata",data_system.start_map_id)
    if data_system.start_map_id==0 || !pbRgssExists?(mapfile)
      pbMessage(_INTL("No starting position was set in the map editor.\1"))
      pbMessage(_INTL("The game cannot continue."))
      @scene.pbEndScene
      $scene = nil
      return
    end
    if System.platform[/Windows/]
      oldfilename = File.join(RTP.getLegacySaveFolder, "Game.rxdata")
      if safeExists?(oldfilename) && !safeExists?(RTP.getSaveFileName("Game_0.rxdata"))
        pbMessage("The game has detected that you have a save file from an older version of the game.")
        if pbConfirmMessage("Would you like to carry the old save file over?")
          pbMessage("Retrieving old save data...\\wt[16] ...\\wt[16] ...\\wtnp[32]")
          File.rename(oldfilename,RTP.getSaveFileName("Game_0.rxdata"))
          pbMessage("Transferring old save data...\\wt[16] ...\\wt[16] ...\\wtnp[16]")
          pbMessage("1, 2, and...\\wt[16] ...\\wt[16] ... Ta-da!\\se[Battle ball drop]\1\\wtnp[]")
          pbMessage("\\se[]Your save file was transferred!\\se[Pkmn move learnt]")
          pbMessage("Enjoy the new update!<ar>~Team Bushido</ar>")
        end
      end
    end
    commands = []
    cmdNewGame     = -1
    cmdContinue    = -1
    cmdOption      = -1
    cmdLanguage    = -1
    cmdDebug       = -1
    cmdQuit        = -1
    commands[cmdContinue = commands.length]    = _INTL("Load Game") if pbHasSave?(3)
    commands[cmdNewGame = commands.length]     = _INTL("New Game")
    commands[cmdOption = commands.length]        = _INTL("Options")
    commands[cmdLanguage = commands.length]      = _INTL("Language") if LANGUAGES.length>=2
    commands[cmdDebug = commands.length]         = _INTL("Debug") if $DEBUG
    commands[cmdQuit = commands.length]          = _INTL("Quit Game")
    @scene.pbStartScene(commands,false,nil,0,0)
    @scene.pbStartScene2
    loop do
      command = @scene.pbChoose(commands)
      slotArray = ["Slot 1","Slot 2","Slot 3"]
      if cmdContinue>=0 && command==cmdContinue
        displayArray = []
        displayArray2 = []
        for i in 0...slotArray.length
          if pbHasSave?(i,true)
            trainerName = pbGetSave(i,true)[0].name
            displayArray.push(slotArray[i])
            displayArray2.push(slotArray[i] + " . . . . . . Kenshi: #{trainerName}")
          end
        end
        if displayArray.length == 1
          value = 0
          message = "Would you like to continue on your adventure?"
        else
          pbPlayDecisionSE
          value = @scene.pbShowSlots(displayArray2,true)
          message = "Would you like to load this file?"
        end
        if value < -1
          pbPlayDecisionSE
          pbStartDeleteScreen(slotArray.index(displayArray[-((value) + 2)]))
          commands = []
          cmdNewGame     = -1
          cmdContinue    = -1
          cmdOption      = -1
          cmdLanguage    = -1
          cmdDebug       = -1
          cmdQuit        = -1
          commands[cmdContinue = commands.length]    = _INTL("Load Game") if pbHasSave?(3)
          commands[cmdNewGame = commands.length]     = _INTL("New Game")
          commands[cmdOption = commands.length]      = _INTL("Options")
          commands[cmdLanguage = commands.length]    = _INTL("Language") if LANGUAGES.length>=2
          commands[cmdDebug = commands.length]       = _INTL("Debug") if $DEBUG
          commands[cmdQuit = commands.length]        = _INTL("Quit Game")
          @scene.pbEndScene
          @scene.pbStartScene(commands,false,nil,0,0)
          @scene.pbStartScene2
          next
        elsif value < 0
          pbPlayCloseMenuSE
          next
        end
        ret = slotArray.index(displayArray[value])
        $PokemonTemp.saveSlot = ret
        data = pbGetSave($PokemonTemp.saveSlot,true)
        next if !data.is_a?(Array)
        final = @scene.pbShowLoadScreen(data,message)
        if final == 2
          pbPlayDecisionSE
          pbStartDeleteScreen($PokemonTemp.saveSlot)
          commands = []
          cmdNewGame     = -1
          cmdContinue    = -1
          cmdOption      = -1
          cmdLanguage    = -1
          cmdDebug       = -1
          cmdQuit        = -1
          commands[cmdContinue = commands.length]    = _INTL("Load Game") if pbHasSave?(3)
          commands[cmdNewGame = commands.length]     = _INTL("New Game")
          commands[cmdOption = commands.length]        = _INTL("Options")
          commands[cmdLanguage = commands.length]      = _INTL("Language") if LANGUAGES.length>=2
          commands[cmdDebug = commands.length]         = _INTL("Debug") if $DEBUG
          commands[cmdQuit = commands.length]          = _INTL("Quit Game")
          @scene.pbEndScene
          @scene.pbStartScene(commands,false,nil,0,0)
          @scene.pbStartScene2
          next
        elsif final != 0
          pbPlayCloseMenuSE
          next
        end
        pbGetSave($PokemonTemp.saveSlot)
        return
      elsif cmdNewGame>=0 && command==cmdNewGame
        pbPlayDecisionSE
        displayArray = slotArray
        for i in 0...displayArray.length
          if pbHasSave?(i,true)
            trainerName = pbGetSave(i,true)[0].name
            displayArray[i] += " . . . . . . Kenshi: #{trainerName}"
          else
            displayArray[i] += " . . . . . . EMPTY"
          end
        end
        value = @scene.pbShowSlots(displayArray)
        if value < 0
          pbPlayCloseMenuSE
          next
        end
        $PokemonTemp.saveSlot = value
        pbPlayDecisionSE
        @scene.pbEndScene
        if $game_map && $game_map.events
          for event in $game_map.events.values
            event.clear_starting
          end
        end
        $game_temp.common_event_id = 0 if $game_temp
        $scene               = Scene_Map.new
        Graphics.frame_count = 0
        $game_system         = Game_System.new
        $game_switches       = Game_Switches.new
        $game_variables      = Game_Variables.new
        $game_self_switches  = Game_SelfSwitches.new
        $game_screen         = Game_Screen.new
        $game_player         = Game_Player.new
        $PokemonMap          = PokemonMapMetadata.new
        $PokemonGlobal       = PokemonGlobalMetadata.new
        $PokemonStorage      = PokemonStorage.new
        $PokemonEncounters   = PokemonEncounters.new
        $PokemonTemp.begunNewGame = true
        $data_system         = load_data("Data/System.rxdata")
        $MapFactory          = PokemonMapFactory.new($data_system.start_map_id)   # calls setMapChanged
        $game_player.moveto($data_system.start_x, $data_system.start_y)
        $game_player.refresh
        $game_map.autoplay
        $game_map.update
        pbUpdateVehicle
        return
      elsif cmdOption>=0 && command==cmdOption
        pbPlayDecisionSE
        pbFadeOutIn {
          scene = PokemonOption_Scene.new
          screen = PokemonOptionScreen.new(scene)
          screen.pbStartScreen(true)
        }
      elsif cmdLanguage>=0 && command==cmdLanguage
        pbPlayDecisionSE
        @scene.pbEndScene
        $PokemonSystem.language = pbChooseLanguage
        pbLoadMessages("Data/"+LANGUAGES[$PokemonSystem.language][1])
        savedata = []
        if safeExists?(savefile)
          File.open(savefile,"rb") { |f|
            16.times { savedata.push(Marshal.load(f)) }
          }
          savedata[3]=$PokemonSystem
          begin
            File.open(RTP.getSaveFileName("Game_0.rxdata"),"wb") { |f|
              16.times { |i| Marshal.dump(savedata[i],f) }
            }
          rescue
          end
        end
        $scene = pbCallTitle
        return
      elsif cmdDebug>=0 && command==cmdDebug
        pbPlayDecisionSE
        pbFadeOutIn { pbDebugMenu(false) }
      elsif cmdQuit>=0 && command==cmdQuit
        pbPlayCloseMenuSE
        @scene.pbEndScene
        $scene = nil
        return
      end
    end
  end

  def pbGetSave(slot,data = false)
    savefile = RTP.getSaveFileName("Game_#{slot}.rxdata")
    if safeExists?(savefile)
      trainer      = nil
      framecount   = 0
      mapid        = 0
      haveBackup   = false
      showContinue = false
      begin
        trainer, framecount, $game_system, $PokemonSystem, mapid = pbTryLoadFile(savefile)
        showContinue = true
      rescue
        if safeExists?(savefile+".bak")
          begin
            trainer, framecount, $game_system, $PokemonSystem, mapid = pbTryLoadFile(savefile+".bak")
            haveBackup   = true
            showContinue = true
          rescue
          end
        end
        if haveBackup
          pbMessage(_INTL("The save file is corrupt. The previous save file will be loaded."))
        else
          pbMessage(_INTL("The save file is corrupt, or is incompatible with this game."))
          if !pbConfirmMessageSerious(_INTL("Do you want to delete the save file and start anew?"))
            $scene = nil
            return false
          end
          begin; File.delete(savefile); rescue; end
          begin; File.delete(savefile+".bak"); rescue; end
          $game_system   = Game_System.new
          $PokemonSystem = PokemonSystem.new if !$PokemonSystem
          pbMessage(_INTL("The save file was deleted."))
        end
      end
      if showContinue
        if !haveBackup && safeExists?(savefile+".bak")
          File.delete(savefile+".bak")
        end
      end
    end
    return [trainer,framecount,mapid] if data
    @scene.pbEndScene
    metadata = nil
    File.open(savefile) { |f|
      Marshal.load(f)   # Trainer already loaded
      $Trainer             = trainer
      Graphics.frame_count = Marshal.load(f)
      $game_system         = Marshal.load(f)
      Marshal.load(f)   # PokemonSystem already loaded
      Marshal.load(f)   # Current map id no longer needed
      $game_switches       = Marshal.load(f)
      $game_variables      = Marshal.load(f)
      $game_self_switches  = Marshal.load(f)
      $game_screen         = Marshal.load(f)
      $MapFactory          = Marshal.load(f)
      $game_map            = $MapFactory.map
      $game_player         = Marshal.load(f)
      $PokemonGlobal       = Marshal.load(f)
      metadata             = Marshal.load(f)
      $PokemonBag          = Marshal.load(f)
      $PokemonStorage      = Marshal.load(f)
      $SaveVersion         = Marshal.load(f) unless f.eof?
      magicNumberMatches = false
      if $data_system.respond_to?("magic_number")
        magicNumberMatches = ($game_system.magic_number==$data_system.magic_number)
      else
        magicNumberMatches = ($game_system.magic_number==$data_system.version_id)
      end
      if !magicNumberMatches || $PokemonGlobal.safesave
        if pbMapInterpreterRunning?
          pbMapInterpreter.setup(nil,0)
        end
        begin
          $MapFactory.setup($game_map.map_id)   # calls setMapChanged
        rescue Errno::ENOENT
          if $DEBUG
            pbMessage(_INTL("Map {1} was not found.",$game_map.map_id))
            map = pbWarpToMap
            if map
              $MapFactory.setup(map[0])
              $game_player.moveto(map[1],map[2])
            else
              $game_map = nil
              $scene = nil
              return
            end
          else
            $game_map = nil
            $scene = nil
            pbMessage(_INTL("The map was not found. The game cannot continue."))
          end
        end
        $game_player.center($game_player.x, $game_player.y)
      else
        $MapFactory.setMapChanged($game_map.map_id)
      end
    }
    if !$game_map.events   # Map wasn't set up
      $game_map = nil
      $scene = nil
      pbMessage(_INTL("The map is corrupt. The game cannot continue."))
      return
    end
    $PokemonMap = metadata
    $PokemonEncounters = PokemonEncounters.new
    $PokemonEncounters.setup($game_map.map_id)
    pbAutoplayOnSave
    $game_map.update
    $PokemonMap.updateMap
    $scene = Scene_Map.new
    return true
  end

  def pbHasSave?(number,limit = false)
    ret = false
    if limit
      savefile = RTP.getSaveFileName("Game_#{number}.rxdata")
      if safeExists?(savefile)
        begin
          ret = pbTryLoadFile(savefile)
        rescue
          if safeExists?(savefile+".bak")
            begin
              ret = pbTryLoadFile(savefile+".bak")
            rescue
            end
          end
        end
      end
    else
      for i in 0...number
        savefile = RTP.getSaveFileName("Game_#{i}.rxdata")
        if safeExists?(savefile)
          begin
            ret = pbTryLoadFile(savefile)
          rescue
            if safeExists?(savefile+".bak")
              begin
                ret = pbTryLoadFile(savefile+".bak")
              rescue
              end
            end
          end
        end
      end
    end
    return true if ret
  end
end

class PokemonTemp
  attr_accessor :saveSlot

  def saveSlot
    @saveSlot = 0 if !@saveSlot
    return @saveSlot
  end
end
