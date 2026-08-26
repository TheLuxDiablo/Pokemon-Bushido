#===============================================================================
# Pokémon Bushido - Save Screen
# Matches the Bushido load-screen presentation and removes the old fade between
# the save command and SaveSlot_Selection_Scene.
#===============================================================================

def pbSave(safesave = false)
  $Trainer.metaID = $PokemonGlobal.playerID
  $Trainer.set_last_save_time
  $Trainer.chapter = $game_variables[99]
  $Trainer.nat_dex_show = Randomizer.on? && Randomizer.rules.include?(:TRAINERS)
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
  oldscene = $scene
  $scene = nil
  pbMessage(_INTL("The script is taking too long. The game will restart."))
  return if !$Trainer
  if safeExists?(RTP.getSaveFileName("Game_0.rxdata"))
    File.open(RTP.getSaveFileName("Game_0.rxdata"), "rb") { |r|
      File.open(RTP.getSaveFileName("Game_0.rxdata.bak"), "wb") { |w|
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
  $scene = oldscene
end


#===============================================================================
# Lightweight backdrop shown underneath the save-slot selector.
#
# The save-slot selector remains responsible for the actual list of slots.
# This scene just makes the transition out of the pause menu feel like part of
# the same UI family as PScreen_Load instead of flashing/fading to black.
#===============================================================================
class BushidoSaveBackdrop < SpriteWrapper
  RED      = Color.new(154, 48, 47)
  RED_DARK = Color.new(102, 33, 34)
  INK      = Color.new(68, 48, 37)
  INK_SOFT = Color.new(111, 84, 64)

  def initialize(viewport)
    super(viewport)
    self.bitmap = BitmapWrapper.new(Graphics.width, Graphics.height)
    pbSetSystemFont(self.bitmap)
    refresh
  end

  def refresh
    self.bitmap.clear

    # Same drop-in background used by PScreen_Load.
    bg = pbBitmap("Graphics/Pictures/LoadScreen/load_bg")
    self.bitmap.blt(0, 0, bg, Rect.new(0, 0, bg.width, bg.height))

    # Reuse the approved right-side paper panel.
    panel = pbBitmap("Graphics/Pictures/LoadScreen/load_right_panel")
    self.bitmap.blt(220, 0, panel, Rect.new(0, 0, panel.width, panel.height))

    draw_current_save_info
  end

  def draw_current_save_info
    return if !$Trainer

    totalsec = Graphics.frame_count / Graphics.frame_rate
    hour = totalsec / 3600
    min = (totalsec / 60) % 60

    mapname = $game_map ? $game_map.name : _INTL("Unknown")
    chapter = $game_variables[99] rescue 0
    journal = $Trainer.pokedexOwned(2) rescue ($Trainer.pokedexOwned rescue 0)

    shadow = Color.new(229, 204, 169)

    pbDrawTextPositions(self.bitmap, [
      [_INTL("Save Game"), 238, 18, 0, RED, shadow],
      [$Trainer.name, 294, 62, 0, INK, shadow],
      [mapname, 294, 91, 0, INK_SOFT, shadow],
      [_INTL("Chapter: {1}", chapter), 238, 136, 0, RED_DARK, shadow],
      [_INTL("Journal: {1}", journal), 366, 136, 0, INK, shadow],
      [_INTL("Playtime: {1}:{2}", sprintf("%02d", hour), sprintf("%02d", min)),
        238, 174, 0, INK, shadow]
    ])
  end
end


class PokemonSave_Scene
  def pbStartScreen
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99998
    @sprites = {}

    @sprites["backdrop"] = BushidoSaveBackdrop.new(@viewport)

    # Current player sprite, matching the load-screen placement.
    begin
      meta = pbGetMetadata(0, MetadataPlayerA + $Trainer.metaID)
      if meta
        filename = pbGetPlayerCharset(meta, 1, $Trainer, true)
        @sprites["player"] = TrainerWalkingCharSprite.new(filename, @viewport)
        sprite = @sprites["player"]
        charwidth = sprite.bitmap.width
        charheight = sprite.bitmap.height
        sprite.src_rect = Rect.new(0, 0, charwidth / 4, charheight / 4)
        sprite.x = 232
        sprite.y = 56
        sprite.z = @viewport.z + 10
      end
    rescue
    end

    # Party icons, same 2x3 layout as load.
    begin
      $Trainer.party.each_with_index do |pkmn, i|
        break if i >= 6
        key = "party#{i}"
        @sprites[key] = PokemonIconSprite.new(pkmn, @viewport)
        @sprites[key].setOffset(PictureOrigin::Center)

        col = i % 3
        row = i / 3

        @sprites[key].x = 270 + (col * 78)
        @sprites[key].y = 266 + (row * 46)
        @sprites[key].z = @viewport.z + 10
      end
    rescue
    end

    # No fade-in. Draw it immediately.
    Graphics.update
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  # Tiny lateral handoff instead of a fade.
  def pbSlideOut
    return if !@viewport

    8.times do |i|
      @viewport.ox = ((i + 1) * 6)
      pbUpdate
      Graphics.update
    end
  end

  def pbSlideBack
    return if !@viewport

    @viewport.ox = 48
    8.times do |i|
      @viewport.ox = 48 - ((i + 1) * 6)
      pbUpdate
      Graphics.update
    end
    @viewport.ox = 0
  end

  def pbEndScreen
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose if @viewport
    @viewport = nil
  end
end

class PokemonSaveScreen
  def initialize(scene)
    @scene = scene
  end

  def pbSaveScreen
    ret = false

    # Open the shared Bushido save-slot carousel.
    slot_scene = SaveSlot_Selection_Scene.new(true, true)
    slot = slot_scene.get_save_slot

    # Back out without saving.
    if slot <= 0
      slot_scene.dispose
      Graphics.update
      return false
    end

    $PokemonSystem.save_slot = slot
    success = pbSave

    if success
      # pbSave has now written Game_X.rxdata to disk.
      #
      # Rebuild the carousel's Save_Slot objects from disk immediately so
      # location, party, chapter, playtime, player sprite, etc. all represent
      # the save that was just written.
      #
      # Carousel indexes are zero-based while save slots are one-based.
      slot_scene.refresh_save_slots(slot - 1)

      # Bring the refreshed carousel back onscreen. get_save_slot hides it
      # when the selection flow ends.
      slot_scene.fade_sprites(true)

      # Give the carousel one frame to rebuild its card sprites.
      slot_scene.update
      Graphics.update

      pbSEPlay("GUI save game") rescue nil

      # Keep the refreshed card visible while the confirmation is shown.
      pbMessage(_INTL("{1} saved the game!", $Trainer.name))

      ret = true
    else
      pbPlayBuzzerSE rescue nil
      ret = false
    end

    slot_scene.dispose
    Graphics.update

    return ret
  end
end

def pbSaveScreen
  scene = PokemonSave_Scene.new
  screen = PokemonSaveScreen.new(scene)
  return screen.pbSaveScreen
end
