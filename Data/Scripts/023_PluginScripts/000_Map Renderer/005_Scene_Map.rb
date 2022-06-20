class Scene_Map
  attr_reader :map_renderer

  def spriteset(map_id = -1)
    return @spritesets[map_id] if map_id > 0 && @spritesets[map_id]
    for i in @spritesets.values
      return i if i.map==$game_map
    end
    return @spritesets.values[0]
  end

  alias __renderer__createSpritesets createSpritesets unless method_defined?(:__renderer__createSpritesets)
  def createSpritesets
    @map_renderer = TilemapRenderer.new(Spriteset_Map.viewport) if !@map_renderer || @map_renderer.disposed?
    __renderer__createSpritesets
    updateSpritesets(true)
  end

  alias __renderer__disposeSpritesets disposeSpritesets unless method_defined?(:__renderer__disposeSpritesets)
  def disposeSpritesets
    __renderer__disposeSpritesets
    @map_renderer.dispose
    @map_renderer = nil
  end

  def miniupdate
    $PokemonTemp.miniupdate = true
    loop do
      $game_player.update
      updateMaps
      $game_system.update
      $game_screen.update
      break unless $game_temp.player_transferring
      transfer_player
      break if $game_temp.transition_processing
    end
    updateSpritesets
    $PokemonTemp.miniupdate = false
  end

  def updateSpritesets(refresh = false)
    @spritesets = {} if !@spritesets
    for map in $MapFactory.maps
      @spritesets[map.map_id] = Spriteset_Map.new(map) if !@spritesets[map.map_id]
    end
    keys = @spritesets.keys.clone
    for i in keys
      if !$MapFactory.hasMap?(i)
        @spritesets[i].dispose if @spritesets[i]
        @spritesets[i] = nil
        @spritesets.delete(i)
      else
        @spritesets[i].update
      end
    end
    @spritesetGlobal.update
    pbDayNightTint(@map_renderer)
    @map_renderer.refresh if refresh
    @map_renderer.update
    Events.onMapUpdate.trigger(self)
  end

  def update
    loop do
      pbMapInterpreter.update
      $game_player.update
      updateMaps
      $game_system.update
      $game_screen.update
      break unless $game_temp.player_transferring
      transfer_player
      break if $game_temp.transition_processing
    end
    updateSpritesets
    if $game_temp.to_title
      $game_temp.to_title = false
      SaveData.mark_values_as_unloaded
      $scene = pbCallTitle
      return
    end
    if $game_temp.transition_processing
      $game_temp.transition_processing = false
      if $game_temp.transition_name == ""
        Graphics.transition
      else
        Graphics.transition(40, "Graphics/Transitions/" + $game_temp.transition_name)
      end
    end
    return if $game_temp.message_window_showing
    if !pbMapInterpreterRunning?
      if Input.trigger?(Input::C)
        $PokemonTemp.hiddenMoveEventCalling = true
      elsif (Input.trigger?(Input::B) && $PokemonSystem.controlScheme == 0) || (Input.trigger?(Input::A) && $PokemonSystem.controlScheme == 1)
        unless $game_system.menu_disabled || $game_player.moving?
          $game_temp.menu_calling = true
          $game_temp.menu_beep = true
        end
      elsif Input.trigger?(Input::X) || Input.triggerex?(0x46) #thundaga, A key and F key for key item calling
        unless $game_player.moving?
          $PokemonTemp.keyItemCalling = true
        end
      elsif Input.press?(Input::F9)
        $game_temp.debug_calling = true if $DEBUG
      end
    end
    unless $game_player.moving?
      if $game_temp.menu_calling
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
end
