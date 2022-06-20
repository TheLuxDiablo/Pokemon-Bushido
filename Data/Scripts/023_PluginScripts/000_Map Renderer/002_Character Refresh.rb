# Just ensures that @real_x and @real_y are floats, to avoid rounding errors.

class Game_Character
  def screen_x
    ret = ((@real_x.to_f - self.map.display_x) / Game_Map::X_SUBPIXELS).round
    ret += Game_Map::TILE_WIDTH / 2
    return ret
  end

  def screen_y_ground
    ret = ((@real_y.to_f - self.map.display_y) / Game_Map::Y_SUBPIXELS).round
    ret += Game_Map::TILE_HEIGHT
    return ret
  end
end


class Game_Player
  def can_run?
    return false if $game_temp.in_menu || $game_temp.in_battle ||
                    @move_route_forcing || $game_temp.message_window_showing ||
                    pbMapInterpreterRunning?
    return false if !$PokemonGlobal.runningShoes && !$PokemonGlobal.diving &&
                    !$PokemonGlobal.surfing && !$PokemonGlobal.bicycle
    return false if jumping?
    terrain = pbGetTerrainTag
    return false if PBTerrain.onlyWalk?(terrain)
    run_key = ($PokemonSystem.controlScheme==1 ? Input::B : Input::A)
    return ($PokemonSystem.runstyle == 1) ^ Input.press?(run_key)
  end

  def pbCanRun?
    return can_run?
  end

  def character_name
    return @character_name
  end

  def set_movement_type(type)
    return if @move_route_forcing
    meta = pbGetMetadata(0, MetadataPlayerA + $PokemonGlobal.playerID)
    new_charset = nil
    if $PokemonGlobal.playerID < 0
      new_charset = nil
    else
      case type
      when :fishing
        new_charset = pbGetPlayerCharset(meta, 6)
      when :surf_fishing
        new_charset = pbGetPlayerCharset(meta, 7)
      when :diving, :diving_fast, :diving_jumping, :diving_stopped
        self.move_speed = 3
        new_charset = pbGetPlayerCharset(meta, 5)
      when :surfing, :surfing_fast, :surfing_jumping, :surfing_stopped
        self.move_speed = (type == :surfing_jumping) ? 3 : 4
        new_charset = pbGetPlayerCharset(meta, 3)
      when :cycling, :cycling_fast, :cycling_jumping, :cycling_stopped
        self.move_speed = (type == :cycling_jumping) ? 3 : 5
        new_charset = pbGetPlayerCharset(meta, 2)
      when :running
        self.move_speed = 4
        new_charset = pbGetPlayerCharset(meta, 4)
      when :ice_sliding
        self.move_speed = 4
        new_charset = pbGetPlayerCharset(meta, 1)
      else   # :walking, :jumping, :walking_stopped
        self.move_speed = 3
        new_charset = pbGetPlayerCharset(meta, 1)
      end
    end
    @character_name = new_charset if new_charset
  end

  # Called when the player's character or outfit changes. Assumes the player
  # isn't moving.
  def refresh_charset
    meta = pbGetMetadata(0, MetadataPlayerA + $PokemonGlobal.playerID)
    new_charset = nil
    if $PokemonGlobal.playerID < 0
      new_charset = nil
    else
      if $PokemonGlobal&.diving
        new_charset = pbGetPlayerCharset(meta, 5)
      elsif $PokemonGlobal&.surfing
        new_charset = pbGetPlayerCharset(meta, 3)
      elsif $PokemonGlobal&.bicycle
        new_charset = pbGetPlayerCharset(meta, 2)
      else
        new_charset = pbGetPlayerCharset(meta, 1)
      end
    end
    @character_name = new_charset if new_charset
  end

  def update_move
    if !@moved_last_frame || @stopped_last_frame   # Started a new step
      if PBTerrain.isIce?(pbGetTerrainTag)
        set_movement_type(:ice_sliding)
      elsif !@move_route_forcing
        faster = can_run?
        if $PokemonGlobal&.diving
          set_movement_type((faster) ? :diving_fast : :diving)
        elsif $PokemonGlobal&.surfing
          set_movement_type((faster) ? :surfing_fast : :surfing)
        elsif $PokemonGlobal&.bicycle
          set_movement_type((faster) ? :cycling_fast : :cycling)
        else
          set_movement_type((faster) ? :running : :walking)
        end
      end
      if jumping?
        if $PokemonGlobal&.diving
          set_movement_type(:diving_jumping)
        elsif $PokemonGlobal&.surfing
          set_movement_type(:surfing_jumping)
        elsif $PokemonGlobal&.bicycle
          set_movement_type(:cycling_jumping)
        else
          set_movement_type(:jumping)   # Walking speed/charset while jumping
        end
      end
    end
    super
  end

  def update_command
    return super
  end

  def update_stop
    if @stopped_last_frame
      if $PokemonGlobal&.diving
        set_movement_type(:diving_stopped)
      elsif $PokemonGlobal&.surfing
        set_movement_type(:surfing_stopped)
      elsif $PokemonGlobal&.bicycle
        set_movement_type(:cycling_stopped)
      else
        set_movement_type(:walking_stopped)
      end
    end
    super
  end

  def update_pattern
    if $PokemonGlobal&.surfing || $PokemonGlobal&.diving
      p = ((Graphics.frame_count % 60) * @@bobFrameSpeed).floor
      @pattern = p if !@lock_pattern
      @pattern_surf = p
      @bob_height = (p >= 2) ? 2 : 0
    else
      @bob_height = 0
      super
    end
  end
end

def pbUpdateVehicle
  if $PokemonGlobal&.diving
    $game_player.set_movement_type(:diving)
  elsif $PokemonGlobal&.surfing
    $game_player.set_movement_type(:surfing)
  elsif $PokemonGlobal&.bicycle
    $game_player.set_movement_type(:cycling)
  else
    $game_player.set_movement_type(:walking)
  end
end

def pbFishingBegin
  $PokemonGlobal.fishing = true
  if !pbCommonEvent(FISHING_BEGIN_COMMON_EVENT)
    $game_player.set_movement_type(($PokemonGlobal.surfing) ? :surf_fishing : :fishing)
    $game_player.lock_pattern = true
    4.times do |pattern|
      $game_player.pattern = 3 - pattern
      (Graphics.frame_rate / 20).times do
        Graphics.update
        Input.update
        pbUpdateSceneMap
      end
    end
    $game_player.lock_pattern = false
  end
end

def pbFishingEnd
  if !pbCommonEvent(FISHING_END_COMMON_EVENT)
    $game_player.lock_pattern = true
    4.times do |pattern|
      $game_player.pattern = pattern
      (Graphics.frame_rate / 20).times do
        Graphics.update
        Input.update
        pbUpdateSceneMap
      end
    end
  end
  yield if block_given?
  $game_player.set_movement_type(($PokemonGlobal.surfing) ? :surfing : :walking)
  $game_player.lock_pattern = false
  $game_player.straighten
  $PokemonGlobal.fishing = false
end

def pbFishing(hasEncounter,rodType=1)
  speedup = ($Trainer.first_pokemon && [:STICKYHOLD, :SUCTIONCUPS].include?($Trainer.first_pokemon.ability_id))
  biteChance = 20+(25*rodType)   # 45, 70, 95
  biteChance *= 1.5 if speedup   # 67.5, 100, 100
  hookChance = 100
  pbFishingBegin
  msgWindow = pbCreateMessageWindow
  ret = false
  loop do
    time = 5+rand(6)
    time = [time,5+rand(6)].min if speedup
    message = ""
    time.times { message += ".   " }
    if pbWaitMessage(msgWindow,time)
      pbFishingEnd {
        pbMessageDisplay(msgWindow,_INTL("Not even a nibble..."))
      }
      break
    end
    if hasEncounter && rand(100)<biteChance
      $scene.spriteset.addUserAnimation(EXCLAMATION_ANIMATION_ID,$game_player.x,$game_player.y,true,3)
      frames = Graphics.frame_rate - rand(Graphics.frame_rate/2)   # 0.5-1 second
      if !pbWaitForInput(msgWindow,message+_INTL("\r\nOh! A bite!"),frames)
        pbFishingEnd {
          pbMessageDisplay(msgWindow,_INTL("The Pokémon got away..."))
        }
        break
      end
      if FISHING_AUTO_HOOK || rand(100) < hookChance
        pbFishingEnd {
          pbMessageDisplay(msgWindow,_INTL("Landed a Pokémon!")) if !FISHING_AUTO_HOOK
        }
        ret = true
        break
      end
    else
      pbFishingEnd {
        pbMessageDisplay(msgWindow,_INTL("Not even a nibble..."))
      }
      break
    end
  end
  pbDisposeMessageWindow(msgWindow)
  return ret
end

# A Pokémon is biting, reflex test to reel it in
def pbWaitForInput(msgWindow,message,frames)
  pbMessageDisplay(msgWindow,message,false)
  numFrame = 0
  twitchFrame = 0
  twitchFrameTime = Graphics.frame_rate * 2 / 10   # 0.2 seconds, 8 frames
  loop do
    Graphics.update
    Input.update
    pbUpdateSceneMap
    # Twitch cycle: 1,0,1,0,0,0,0,0
    twitchFrame = (twitchFrame+1)%(twitchFrameTime*8)
    case twitchFrame%twitchFrameTime
    when 0, 2
      $game_player.pattern = 1
    else
      $game_player.pattern = 0
    end
    if Input.trigger?(Input::C) || Input.trigger?(Input::B)
      $game_player.pattern = 0
      return true
    end
    break if !FISHING_AUTO_HOOK && numFrame > frames
    numFrame += 1
  end
  return false
end


class PokeBattle_Trainer
  def metaID=(value)
    return if @metaID == value
    @metaID = value
    $game_player.refresh_charset if $game_player
  end

  alias old_outfit outfit= unless method_defined?(:old_outfit)
  def outfit=(value)
    old_val = @outfit
    old_outfit(value)
    $game_player.refresh_charset if $game_player && old_val != @outfit
  end
end
