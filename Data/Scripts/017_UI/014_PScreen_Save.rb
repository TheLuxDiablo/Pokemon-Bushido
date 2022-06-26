def pbSave(safesave = false)
  $Trainer.metaID = $PokemonGlobal.playerID
  $Trainer.set_last_save_time
  $Trainer.chapter = $game_variables[99]
  begin
    File.open(RTP.getSaveFileName("Game_#{$PokemonSystem.save_slot}.rxdata"),"wb") { |f|
      Marshal.dump($Trainer, f)
      Marshal.dump($game_map.map_id, f)
      if $data_system.respond_to?("magic_number")
        $game_system.magic_number = $data_system.magic_number
      else
        $game_system.magic_number = $data_system.version_id
      end
      Marshal.dump(Graphics.frame_count, f)
      Marshal.dump($game_switches, f)
      Marshal.dump($game_variables, f)
      Marshal.dump($game_self_switches, f)
      Marshal.dump($game_screen, f)
      Marshal.dump($MapFactory, f)
      Marshal.dump($game_player, f)
      $PokemonGlobal.safesave = safesave
      Marshal.dump($PokemonGlobal, f)
      Marshal.dump($PokemonMap, f)
      Marshal.dump($PokemonBag, f)
      Marshal.dump($PokemonStorage, f)
      Marshal.dump(ESSENTIALS_VERSION, f)
    }
    File.open(RTP.getSaveFileName("Settings.rxdata"), "wb") { |f|
      Marshal.dump($PokemonSystem, f)
      $game_system.save_count += 1
      Marshal.dump($game_system, f)
    }
    Graphics.frame_reset
  rescue
    return false
  end
  return true
end

def pbEmergencySave
  oldscene=$scene
  $scene=nil
  pbMessage(_INTL("The script is taking too long. The game will restart."))
  return if !$Trainer
  if safeExists?(RTP.getSaveFileName("Game_0.rxdata"))
    File.open(RTP.getSaveFileName("Game_0.rxdata"),  'rb') { |r|
      File.open(RTP.getSaveFileName("Game_0.rxdata.bak"), 'wb') { |w|
        while s = r.read(4096)
          w.write s
        end
      }
    }
  end
  if pbSave
    pbMessage(_INTL("\\se[]The game was saved.\\me[GUI save game] The previous save file has been backed up.\\wtnp[30]"))
  else
    pbMessage(_INTL("\\se[]Save failed.\\wtnp[30]"))
  end
  $scene=oldscene
end



class PokemonSave_Scene
  def pbStartScreen
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @sprites={}
    totalsec = Graphics.frame_count / Graphics.frame_rate
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    mapname=$game_map.name
    textColor = ["0070F8,78B8E8","E82010,F8A8B8","0070F8,78B8E8"][$Trainer.gender]
    locationColor = "209808,90F090"   # green
    loctext = _INTL("<ac><c3={1}>{2}</c3></ac>",locationColor,mapname)
    loctext+=_INTL("Player<r><c3={1}>{2}</c3><br>",textColor,$Trainer.name)
    if hour>0
      loctext+=_INTL("Time<r><c3={1}>{2}h {3}m</c3><br>",textColor,hour,min)
    else
      loctext+=_INTL("Time<r><c3={1}>{2}m</c3><br>",textColor,min)
    end
    if $Trainer.pokedex
      loctext+=_INTL("Journal<r><c3={1}>{2}/{3}</c3><br>",textColor,$Trainer.pokedexOwned,$Trainer.pokedexSeen)
    end
    loctext+=_INTL("Chapter<r><c3={1}>{2}</c3><br>",textColor,$game_variables[99])
    #if $game_variables[100]>0 && $game_variables[99]!="Hattori"
      #loctext+=_INTL("Katana Level<r><c3={1}>{2}</c3>",textColor,$game_variables[100])
    #end
    if $game_variables[99]=="Hattori" && $game_variables[199]!=0
      loctext+=_INTL("Corrupted<r><c3={1}>{2}</c3>",textColor,$game_variables[199])
    end
    @sprites["locwindow"]=Window_AdvancedTextPokemon.new(loctext)
    @sprites["locwindow"].viewport=@viewport
    @sprites["locwindow"].x=0
    @sprites["locwindow"].y=0
    @sprites["locwindow"].width=228 if @sprites["locwindow"].width<228
    @sprites["locwindow"].visible=true
  end

  def pbEndScreen
    pbDisposeSpriteHash(@sprites)
    @viewport&.dispose
  end
end



class PokemonSaveScreen
  def initialize(scene)
    @scene=scene
  end

  def pbSaveScreen
    ret=false
    # @scene.pbStartScreen
    slot = $PokemonSystem.save_slot
    pbFadeOutIn(99999) {
      scene = SaveSlot_Selection_Scene.new(true, true)
      slot  = scene.get_save_slot
      next scene.dispose if slot <= 0
      $PokemonSystem.save_slot = slot
      pbSave
      scene.dispose
      ret = true
    }
    # @scene.pbEndScreen
    return ret
  end
end



def pbSaveScreen
  scene = PokemonSave_Scene.new
  screen = PokemonSaveScreen.new(scene)
  ret = screen.pbSaveScreen
  return ret
end
