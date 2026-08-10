#===============================================================================
# FancyCamera - Method Overrides
# Pokemon Essentials v18.1 Port
# Original plugin by ENLS
#
# This v18 port intentionally avoids newer Essentials systems such as:
#   GameData::PlayerMetadata
#   $player
#   $game_temp.followers
#   modern Scene_Map transfer_player
#===============================================================================

class Game_Player < Game_Character
  # v18's normal player update performs vanilla scrolling. FancyCamera runs
  # immediately afterward and supplies the final display_x/display_y for the
  # frame. This keeps the patch small and compatible with Bushido's movement.
  alias fancycamera_v18_update update unless method_defined?(:fancycamera_v18_update)

  def update
    fancycamera_v18_update
    FancyCameraV18.apply
  end
end

if FancyCamera::OVERRIDE_SCROLL_MAP
  class Interpreter
    alias fancycamera_v18_command_203 command_203 unless method_defined?(:fancycamera_v18_command_203)

    # RPG Maker XP "Scroll Map"
    def command_203
      return fancycamera_v18_command_203 if $game_temp.in_battle

      direction = @parameters[0]
      distance  = @parameters[1]
      speed_id  = @parameters[2]

      speed = FancyCamera::DEFAULT_SPEED
      case speed_id
      when 1; speed *= 0.50
      when 2; speed *= 0.75
      when 3; speed *= 0.85
      when 4; speed *= 1.00
      when 5; speed *= 1.50
      when 6; speed *= 2.00
      end

      pbCameraScrollDirection(direction, distance, speed)
      return true
    end
  end
end
