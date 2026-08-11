#===============================================================================
# FancyCamera - Camera Script
# Pokemon Essentials v18.1 Port
# Original plugin by ENLS
#===============================================================================

class Game_Temp
  attr_accessor :camera_x
  attr_accessor :camera_y
  attr_accessor :camera_shake
  attr_accessor :camera_speed
  attr_accessor :camera_offset
  attr_accessor :camera_target_event

  def camera_x
    @camera_x ||= 0
    return @camera_x
  end

  def camera_y
    @camera_y ||= 0
    return @camera_y
  end

  def camera_shake
    @camera_shake ||= 0
    return @camera_shake
  end

  def camera_speed
    @camera_speed ||= FancyCamera::DEFAULT_SPEED
    return @camera_speed
  end

  def camera_offset
    @camera_offset ||= [0, 0]
    return @camera_offset
  end

  def camera_target_event
    return @camera_target_event
  end
end

module FancyCameraV18
  def self.x_subpixels
    return Game_Map::X_SUBPIXELS
  end

  def self.y_subpixels
    return Game_Map::Y_SUBPIXELS
  end

  def self.real_res_x
    return Game_Map::REAL_RES_X
  end

  def self.real_res_y
    return Game_Map::REAL_RES_Y
  end

  def self.screen_center_x
    if defined?(Game_Player::SCREEN_CENTER_X)
      return Game_Player::SCREEN_CENTER_X
    end
    return ((Graphics.width - Game_Map::TILE_WIDTH) / 2) * x_subpixels
  end

  def self.screen_center_y
    if defined?(Game_Player::SCREEN_CENTER_Y)
      return Game_Player::SCREEN_CENTER_Y
    end
    return ((Graphics.height - Game_Map::TILE_HEIGHT) / 2) * y_subpixels
  end

  def self.target_for_tile(x, y)
    return [
      (x.to_f * real_res_x) - screen_center_x,
      (y.to_f * real_res_y) - screen_center_y
    ]
  end

  def self.target_for_character(character)
    return nil if !character
    return [
      character.real_x.to_f - screen_center_x,
      character.real_y.to_f - screen_center_y
    ]
  end

  def self.current_target
    return nil if !$game_temp || !$game_player

    target = target_for_character($game_player)

    event_id = $game_temp.camera_target_event
    if event_id && event_id != 0 && $game_map && $game_map.events
      event = $game_map.events[event_id]
      target = target_for_character(event) if event
    elsif $game_temp.camera_x != 0 || $game_temp.camera_y != 0
      target = target_for_tile($game_temp.camera_x, $game_temp.camera_y)
    end

    offset = $game_temp.camera_offset
    if offset && offset != [0, 0]
      target[0] += offset[0].to_f * real_res_x
      target[1] += offset[1].to_f * real_res_y
    end

    shake = $game_temp.camera_shake.to_f
    if shake > 0
      power = shake * 25.0
      target[0] += (rand * power * 2.0) - power
      target[1] += (rand * power * 2.0) - power
    end

    return target
  end

  def self.ease_in_out(a, b, amount)
    amount = amount.to_f
    amount = 1.0 if amount > 1.0
    amount = 0.0 if amount < 0.0
    smooth = amount * amount * (3.0 - (2.0 * amount))
    return a + ((b - a) * smooth)
  end

  def self.apply
    return if !$game_map || !$game_player || !$game_temp
    return if $game_map.scrolling? rescue false

    target = current_target
    return if !target

    dx = target[0] - $game_map.display_x
    dy = target[1] - $game_map.display_y
    distance = Math.sqrt((dx * dx) + (dy * dy))

    # ENLS's modern plugin scales speed against newer frame/update behavior.
    # This factor is tuned to preserve the same general feel in v18.
    speed = $game_temp.camera_speed.to_f * 0.16
    speed = 0.01 if speed <= 0

    if distance < 1.0
      $game_map.display_x = target[0]
      $game_map.display_y = target[1]
    else
      $game_map.display_x = ease_in_out($game_map.display_x, target[0], speed)
      $game_map.display_y = ease_in_out($game_map.display_y, target[1], speed)
    end
  end
end

# Scrolls the camera to x/y relative to the player's current tile.
def pbCameraScroll(relative_x, relative_y, speed=nil)
  pbCameraSpeed(speed) if speed
  $game_temp.camera_target_event = nil
  $game_temp.camera_x = $game_player.x + relative_x
  $game_temp.camera_y = $game_player.y + relative_y
end

# Scrolls the camera in an RMXP direction by a number of tiles.
def pbCameraScrollDirection(direction, distance, speed=nil)
  x = ($game_temp.camera_x == 0) ? $game_player.x : $game_temp.camera_x
  y = ($game_temp.camera_y == 0) ? $game_player.y : $game_temp.camera_y

  case direction
  when 1; x -= distance; y += distance
  when 2;                y += distance
  when 3; x += distance; y += distance
  when 4; x -= distance
  when 6; x += distance
  when 7; x -= distance; y -= distance
  when 8;                y -= distance
  when 9; x += distance; y -= distance
  end

  pbCameraScrollTo(x, y, speed)
end

# Scrolls the camera to a map tile.
def pbCameraScrollTo(x, y, speed=nil)
  if x == $game_player.x && y == $game_player.y
    pbCameraReset(speed)
    return
  end

  pbCameraSpeed(speed) if speed
  $game_temp.camera_target_event = nil
  $game_temp.camera_x = x
  $game_temp.camera_y = y
end

# Returns camera control to the player.
def pbCameraReset(speed=nil)
  pbCameraSpeed(speed || FancyCamera::DEFAULT_SPEED)
  $game_temp.camera_target_event = nil
  $game_temp.camera_x = 0
  $game_temp.camera_y = 0
  $game_temp.camera_offset = [0, 0]
end

# Focuses the camera on a map event.
def pbCameraToEvent(event_id=nil, speed=nil)
  pbCameraSpeed(speed) if speed

  # If called from an event Script command without an ID, try the current
  # interpreter's event ID when available.
  if !event_id
    begin
      event_id = pbMapInterpreter.get_self.id
    rescue
      return
    end
  end

  return if !$game_map || !$game_map.events[event_id]

  $game_temp.camera_x = 0
  $game_temp.camera_y = 0
  $game_temp.camera_target_event = event_id
end

def pbCameraShake(power=2)
  $game_temp.camera_shake = power
end

def pbCameraShakeOff
  $game_temp.camera_shake = 0
end

def pbCameraSpeed(speed)
  speed = FancyCamera::DEFAULT_SPEED if !speed || speed == 0
  $game_temp.camera_speed = speed.to_f
end

def pbCameraOffset(x, y)
  $game_temp.camera_offset = [x, y]
end
