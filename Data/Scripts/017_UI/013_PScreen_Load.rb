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
        textpos.push([@trainer.pokedexOwned(2).to_s,103*2,72*2,1,TEXTCOLOR,TEXTSHADOWCOLOR])
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
    if !@viewport
      @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      @viewport.z = 99998
    end
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

  def pbResetScene(commands)
    Graphics.freeze
    pbDisposeSpriteHash(@sprites)
    pbStartScene(commands, false, nil, 0, 0)
    Graphics.transition(0)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end



class PokemonLoadScreen


  def initialize(scene)
    @scene      = scene
    @load_scene = SaveSlot_Selection_Scene.new
    @ng_scene   = SaveSlot_Selection_Scene.new(true)
  end

  def create_load_commands(reset = false)
    @commands        = []
    @cmd_new_game    = -1
    @cmd_continue    = -1
    @cmd_options     = -1
    @cmd_language    = -1
    @cmd_debug       = -1
    @cmd_quit        = -1
    @commands[@cmd_continue = @commands.length] = _INTL("Load Game") if !@load_scene.slots.empty?
    @commands[@cmd_new_game = @commands.length] = _INTL("New Game")
    @commands[@cmd_options = @commands.length]  = _INTL("Options")
    @commands[@cmd_language = @commands.length] = _INTL("Language") if LANGUAGES.length >= 2
    @commands[@cmd_debug = @commands.length]    = _INTL("Debug") if $DEBUG
    @commands[@cmd_quit = @commands.length]     = _INTL("Quit Game")
    return if !reset
    @scene.pbResetScene(@commands)
    @load_scene.refresh_save_slots($PokemonSystem.save_slot - 1)
    @ng_scene.refresh_save_slots($PokemonSystem.save_slot - 1)
  end

  def pbEndScene
    @scene.pbEndScene
    @load_scene.dispose
    @ng_scene.dispose
  end

  def pbStartLoadScreen
    $game_temp     = Game_Temp.new
    $PokemonTemp   = PokemonTemp.new if !$PokemonTemp
    $game_system   = Game_System.new if !$game_system
    $PokemonSystem = PokemonSystem.new if !$PokemonSystem
    data_system = load_data("Data/System.rxdata")
    mapfile = sprintf("Data/Map%03d.rxdata",data_system.start_map_id)
    if data_system.start_map_id == 0 || !pbRgssExists?(mapfile)
      pbMessage(_INTL("No starting position was set in the map editor.\1"))
      pbMessage(_INTL("The game cannot continue."))
      pbEndScene
      $scene = nil
      return
    end
    create_load_commands
    @scene.pbStartScene(@commands, false, nil, 0, 0)
    @scene.pbStartScene2
    loop do
      command = @scene.pbChoose(@commands)
      case command
      when @cmd_continue
        pbPlayDecisionSE
        slot = @load_scene.get_save_slot
        if slot <= 0
          create_load_commands(true) if slot == -1
          next
        end
        $PokemonSystem.save_slot = slot
        save_file = RTP.getSaveFileName("Game_#{slot}.rxdata")
        unless safeExists?(save_file)
          pbPlayBuzzerSE
          next
        end
        pbEndScene
        metadata = nil
        File.open(save_file) { |f|
          $Trainer             = Marshal.load(f)
          Marshal.load(f)   # Current map id no longer needed
          Graphics.frame_count = Marshal.load(f)
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
            magicNumberMatches = ($game_system.magic_number == $data_system.magic_number)
          else
            magicNumberMatches = ($game_system.magic_number == $data_system.version_id)
          end
          if !magicNumberMatches || $PokemonGlobal.safesave
            pbMapInterpreter.setup(nil, 0) if pbMapInterpreterRunning?
            begin
              $MapFactory.setup($game_map.map_id)   # calls setMapChanged
            rescue Errno::ENOENT
              end_game = true
              if $DEBUG
                pbMessage(_INTL("Map {1} was not found.", $game_map.map_id))
                map = pbWarpToMap
                if map
                  end_game = false
                  $MapFactory.setup(map[0])
                  $game_player.moveto(map[1],map[2])
                end
              end
              if end_game
                $game_map = nil
                $scene = nil
                pbMessage(_INTL("The map was not found. The game cannot continue."))
                return
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
=begin
        #Thundaga force fog onto map in chapter 6
        if $game_variables[99]==6 && ($game_map.map_id==85 || $game_map.map_id==88)
          $game_map.fog_name = 'clouds3'
          $game_map.fog_hue = 0
          $game_map.fog_opacity = 170
          $game_map.fog_blend_type = 0
          $game_map.fog_zoom = 150
          $game_map.fog_sx = 8
          $game_map.fog_sy = 2
          if($game_map.map_id==88 and $game_player.x>55)
            pbBGMPlay('PKMNMovie15-TruePower')
          elsif $game_map.map_id==88
            pbBGMPlay('Conquest-EventTheme05')
          else
            pbBGMPlay('Conquest-EventTheme03')
          end
          $game_map.update
        end
=end
        return
      when @cmd_new_game
        pbPlayDecisionSE
        slot = @ng_scene.get_save_slot
        if slot <= 0
          create_load_commands(true) if slot == -1
          next
        end
        $PokemonSystem.save_slot = slot
        pbEndScene
        $game_map.events.each_value { |e| e.clear_starting } if $game_map && $game_map.events
        $game_temp.common_event_id = 0 if $game_temp
        $scene               = Scene_Map.new
        Graphics.frame_count = 0
        $game_switches       = Game_Switches.new
        $game_variables      = Game_Variables.new
        $game_self_switches  = Game_SelfSwitches.new
        $game_screen         = Game_Screen.new
        $game_player         = Game_Player.new
        $PokemonMap          = PokemonMapMetadata.new
        $PokemonGlobal       = PokemonGlobalMetadata.new
        $PokemonStorage      = PokemonStorage.new
        $PokemonEncounters   = PokemonEncounters.new
        # $PokemonTemp.begunNewGame = true
        $data_system         = load_data("Data/System.rxdata")
        $MapFactory          = PokemonMapFactory.new($data_system.start_map_id)   # calls setMapChanged
        $game_player.moveto($data_system.start_x, $data_system.start_y)
        $game_player.refresh
        $game_map.autoplay
        $game_map.update
        return
      when @cmd_options
        pbPlayDecisionSE
        pbFadeOutIn {
          scene = PokemonOption_Scene.new
          screen = PokemonOptionScreen.new(scene)
          screen.pbStartScreen(true)
        }
      when @cmd_language
        pbPlayDecisionSE
        @scene.pbEndScene
        $PokemonSystem.language = pbChooseLanguage
        pbLoadMessages("Data/" + LANGUAGES[$PokemonSystem.language][1])
        save_data = []
        settings  = RTP.getSaveFileName("Settings.rxdata")
        if safeExists?(settings)
          File.open(settings) { |f| 2.times { save_data.push(Marshal.load(f)) } }
          save_data[0] = $PokemonSystem
          begin
            File.open(settings) { |f| 2.times { |i| Marshal.dump(save_data[i]) } }
          rescue
          end
        end
        $scene = pbCallTitle
        return
      when @cmd_debug
        pbPlayDecisionSE
        pbFadeOutIn { pbDebugMenu(false) }
      when @cmd_quit
        pbPlayCloseMenuSE
        @scene.pbEndScene
        $scene = nil
        return
      end
    end
  end
end

class PokemonSystem
  attr_accessor :save_slot

  def save_slot
    @save_slot = 0 if !@save_slot
    return @save_slot
  end
end
