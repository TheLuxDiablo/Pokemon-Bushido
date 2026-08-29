#===============================================================================
# ** Modified Scene_Map class for Pokémon.
#-------------------------------------------------------------------------------
#
#===============================================================================
class Scene_Map
  attr_reader :spritesetGlobal

  def spriteset
    return nil if !@spritesets

    for i in @spritesets.values
      next if !i
      return i if i.map == $game_map
    end

    for i in @spritesets.values
      return i if i
    end

    return nil
  end

  #-----------------------------------------------------------------------------
  # Create spritesets for all maps currently owned by MapFactory.
  #-----------------------------------------------------------------------------
  def createSpritesets
    @spritesetGlobal = Spriteset_Global.new
    @spritesets = {}

    maps_to_create = $MapFactory.maps.clone

    $MapFactory.lockMapAdds

    begin
      for map in maps_to_create
        next if !map


        @spritesets[map.map_id] = Spriteset_Map.new(map)
      end
    ensure
      $MapFactory.unlockMapAdds
    end

    $MapFactory.setSceneStarted(self)

    updateSpritesets
  end

  #-----------------------------------------------------------------------------
  # Create one spriteset.
  #-----------------------------------------------------------------------------
  def createSingleSpriteset(map_id)
    old_spriteset = spriteset
    temp = old_spriteset ? old_spriteset.getAnimations : nil

    map = nil

    for current_map in $MapFactory.maps
      next if !current_map

      if current_map.map_id == map_id
        map = current_map
        break
      end
    end

    return if !map

    if @spritesets[map_id]
      @spritesets[map_id].dispose
      @spritesets.delete(map_id)
    end

    $MapFactory.lockMapAdds

    begin
      @spritesets[map_id] = Spriteset_Map.new(map)
    ensure
      $MapFactory.unlockMapAdds
    end

    new_spriteset = spriteset

    if new_spriteset && temp
      new_spriteset.restoreAnimations(temp)
    end

    $MapFactory.setSceneStarted(self)

    updateSpritesets
  end

  #-----------------------------------------------------------------------------
  # Dispose all map spritesets.
  #-----------------------------------------------------------------------------
  def disposeSpritesets
    if @spritesets
      for id in @spritesets.keys.clone
        next if !@spritesets[id]

        @spritesets[id].dispose
        @spritesets[id] = nil
      end

      @spritesets.clear
    end

    @spritesets = {}

    if @spritesetGlobal
      @spritesetGlobal.dispose
      @spritesetGlobal = nil
    end
  end

  #-----------------------------------------------------------------------------
  # Fade map audio if necessary.
  #-----------------------------------------------------------------------------
  def autofade(mapid)
    playingBGM = $game_system.playing_bgm
    playingBGS = $game_system.playing_bgs

    return if !playingBGM && !playingBGS

    map = load_data(sprintf("Data/Map%03d.rxdata", mapid))

    if playingBGM && map.autoplay_bgm
      if (PBDayNight.isNight? rescue false)
        if playingBGM.name != map.bgm.name &&
           playingBGM.name != map.bgm.name + "_n"
          pbBGMFade(0.8)
        end
      else
        pbBGMFade(0.8) if playingBGM.name != map.bgm.name
      end
    end

    if playingBGS && map.autoplay_bgs
      pbBGMFade(0.8) if playingBGS.name != map.bgs.name
    end

    Graphics.frame_reset
  end

  #-----------------------------------------------------------------------------
  # Transfer player.
  #-----------------------------------------------------------------------------
  def transfer_player(cancelVehicles = true)
    $game_temp.player_transferring = false

    pbCancelVehicles($game_temp.player_new_map_id) if cancelVehicles
    autofade($game_temp.player_new_map_id)
    pbBridgeOff

    if $DEBUG
    end

    #-------------------------------------------------------------------------
    # Build destination map collection.
    #-------------------------------------------------------------------------
    if $game_map.map_id != $game_temp.player_new_map_id
      $MapFactory.setup($game_temp.player_new_map_id)
    end

    if $DEBUG
      maps = []

      for map in $MapFactory.maps
        maps.push(map.map_id) if map
      end

    end

    #-------------------------------------------------------------------------
    # Nothing during transfer initialization is allowed to silently expand
    # MapFactory beyond the maps setup() already chose.
    #-------------------------------------------------------------------------
    $MapFactory.lockMapAdds

    begin
      #-----------------------------------------------------------------------
      # Position player.
      #-----------------------------------------------------------------------
      $game_player.moveto(
        $game_temp.player_new_x,
        $game_temp.player_new_y
      )

      case $game_temp.player_new_direction
      when 2
        $game_player.turn_down
      when 4
        $game_player.turn_left
      when 6
        $game_player.turn_right
      when 8
        $game_player.turn_up
      end

      $game_player.straighten

      #-----------------------------------------------------------------------
      # Initial destination map update.
      #-----------------------------------------------------------------------
      $game_map.update

      #-----------------------------------------------------------------------
      # Dispose previous renderers.
      #-----------------------------------------------------------------------
      if $DEBUG
        sprites = []

        if @spritesets
          for id in @spritesets.keys
            sprites.push(id)
          end
        end

      end

      disposeSpritesets

      if $DEBUG
      end

      GC.start

      #-----------------------------------------------------------------------
      # Rebuild the destination renderers.
      #-----------------------------------------------------------------------
      createSpritesets

    ensure
      $MapFactory.unlockMapAdds
    end

    if $DEBUG
      maps = []

      for map in $MapFactory.maps
        maps.push(map.map_id) if map
      end

      sprites = []

      for id in @spritesets.keys
        sprites.push(id)
      end

    end

    if $game_temp.transition_processing
      $game_temp.transition_processing = false
      Graphics.transition(20)
    end

    $game_map.autoplay

    Graphics.frame_reset
    Input.update
  end

  def call_name
    $game_temp.name_calling = false
    $game_player.straighten
    $game_map.update
  end

  def call_menu
    $game_temp.menu_calling = false
    $game_temp.in_menu = true

    $game_player.straighten
    $game_map.update

    sscene = PokemonPauseMenu_Scene.new
    sscreen = PokemonPauseMenu.new(sscene)
    sscreen.pbStartPokemonMenu

    $game_temp.in_menu = false
  end

  def call_debug
    $game_temp.debug_calling = false

    pbPlayDecisionSE
    $game_player.straighten

    pbFadeOutIn do
      pbDebugMenu
    end
  end

  def miniupdate
    $PokemonTemp.miniupdate = true

    loop do
      updateMaps

      $game_player.update
      $game_system.update
      $game_screen.update

      break unless $game_temp.player_transferring

      transfer_player

      break if $game_temp.transition_processing
    end

    updateSpritesets

    $PokemonTemp.miniupdate = false
  end

  def updateMaps
    for map in $MapFactory.maps
      next if !map
      map.update
    end

    $MapFactory.updateMaps(self)
  end

  #-----------------------------------------------------------------------------
  # Update spritesets.
  #-----------------------------------------------------------------------------
  def updateSpritesets
    @spritesets = {} if !@spritesets

    keys = @spritesets.keys.clone

    #-------------------------------------------------------------------------
    # Remove spritesets whose maps MapFactory has dropped.
    #-------------------------------------------------------------------------
    for i in keys
      if !$MapFactory.hasMap?(i)

        @spritesets[i].dispose if @spritesets[i]
        @spritesets[i] = nil
        @spritesets.delete(i)
      else
        @spritesets[i].update
      end
    end

    @spritesetGlobal.update if @spritesetGlobal

    #-------------------------------------------------------------------------
    # Snapshot the current active maps before constructing anything.
    #-------------------------------------------------------------------------
    maps_to_create = $MapFactory.maps.clone

    $MapFactory.lockMapAdds

    begin
      for map in maps_to_create
        next if !map

        if !@spritesets[map.map_id]

          @spritesets[map.map_id] = Spriteset_Map.new(map)
        end
      end
    ensure
      $MapFactory.unlockMapAdds
    end

    Events.onMapUpdate.trigger(self)
  end

  #-----------------------------------------------------------------------------
  # Main update.
  #-----------------------------------------------------------------------------
  def update
    loop do
      updateMaps

      pbMapInterpreter.update
      $game_player.update
      $game_system.update
      $game_screen.update

      break unless $game_temp.player_transferring

      transfer_player

      break if $game_temp.transition_processing
    end

    updateSpritesets

    if $game_temp.to_title
      $scene = pbCallTitle
      return
    end

    if $game_temp.transition_processing
      $game_temp.transition_processing = false

      if $game_temp.transition_name == ""
        Graphics.transition(20)
      else
        Graphics.transition(
          40,
          "Graphics/Transitions/" + $game_temp.transition_name
        )
      end
    end

    return if $game_temp.message_window_showing

    if !pbMapInterpreterRunning?
      if Input.trigger?(Input::C)
        $PokemonTemp.hiddenMoveEventCalling = true

      elsif Input.trigger?(Input::A)
        unless $game_system.menu_disabled
          $game_temp.menu_calling = true
          $game_temp.menu_beep = true
        end

      elsif Input.trigger?(Input::X) || Input.pressex?(0x46)
        unless $game_player.moving?
          $PokemonTemp.keyItemCalling = true
        end

      elsif Input.triggerex?(0x78)
        $game_temp.debug_calling = true if $DEBUG
      end
    end

    unless $game_player.moving?
      if $game_temp.name_calling
        call_name

      elsif $game_temp.menu_calling
        call_menu

      elsif $game_temp.debug_calling
        call_debug

      elsif $PokemonTemp.keyItemCalling
        $PokemonTemp.keyItemCalling = false

        $game_player.straighten

        pbUseKeyItem

      elsif $PokemonTemp.hiddenMoveEventCalling
        $PokemonTemp.hiddenMoveEventCalling = false

        $game_player.straighten

        Events.onAction.trigger(self)
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Main scene loop.
  #-----------------------------------------------------------------------------
  def main
    createSpritesets

    Graphics.transition(20)

    loop do
      Graphics.update
      Input.update
      update

      break if $scene != self
    end

    Graphics.freeze

    disposeSpritesets

    if $game_temp.to_title
      Graphics.transition(20)
      Graphics.freeze
    end
  end
end