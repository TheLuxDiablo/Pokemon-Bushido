#==============================================================================#
#                             Enhanced Staircases                              #
#                                  by Marin                                    #
#------------------------------------------------------------------------------#
# This script provides pixel movement while walking on staircases, while also  #
# slowing down movement to capture the real feeling and motion of a staircase. #
#------------------------------------------------------------------------------#
#                                  Usage                                       #
#                                                                              #
# To make a stair work smoothly, it must have one event at the bottom, and one #
# at the top (not on the staircase; one tile outwards).                        #
# Staircase events utilize comments to configure the properties of the stairs. #
# These comments are not compiled it any different format unlike, say, trainer #
# generation, and as such do not require you to restart RPG Maker XP.          #
#                                                                              #
# The name of a staircase event must be `Slope` (without the backticks ``),    #
# and the event must contain a comment with the following text:                #
# `Slope: AxB` where A and B are integers, specifying how many tiles           #
# away the second event is. If the staircase is wider than 1 tile, this must   #
# match up with event that has the same stair index, as explained below.       #
#                                                                              #
# If your staircase is more than 1 tile wide, you require an additional        #
# `Width: A/B` comment, where A is the index of the event in the staircase     #
# (i.e. if it's the bottom part of the staircase 0, if it's one higher 1, etc) #
# and B is the total width of the staircase. If you understand the explanation,#
# you'll agree that this means that the top event of a 3-wide staircase will   #
# say `Width: 2/3`.                                                            #
#                                                                              #
# It is also possible to specify at which point during movement from the event #
# to the start of the staircase to increment the vertical offset.              #
# By default, this is a value of 16 pixels. This means that you move without   #
# any vertical increase for the first 16 pixels, and after that start climbing #
# the staircase.                                                               #
# To change this offset, write in a comment, `Offset: Apx`, where A is the     #
# number of pixels after which to start climbing the staircase.                #
#------------------------------------------------------------------------------#
#                    Please give credit when using this.                       #
#==============================================================================#
PluginManager.register({
  :name => "Enhanced Staircases",
  :version => "1.7",
  :credits => "Marin",
  :link => "https://reliccastle.com/resources/396/"
})

# If true, overwrites default scrolling behaviour to make stair movement smooth
# and to reduce improper scrolling offsets after walking on stairs wider than 1.
SMOOTH_SCROLLING = false

$DisableScrollCounter = 0

def pbTurnTowardEvent(event,otherEvent)
  sx = 0; sy = 0
  if $MapFactory
    relativePos=$MapFactory.getThisAndOtherEventRelativePos(otherEvent,event)
    sx = relativePos[0]
    sy = relativePos[1]
  else
    sx = event.x - otherEvent.x
    sy = event.y - otherEvent.y
  end
  return if sx == 0 and sy == 0
  if event.on_middle_of_stair? && !otherEvent.on_middle_of_stair?
    sx > 0 ? event.turn_left : event.turn_right
    return
  end
  if sx.abs > sy.abs
    (sx > 0) ? event.turn_left : event.turn_right
  else
    (sy > 0) ? event.turn_up : event.turn_down
  end
end

class Scene_Map
  alias stair_transfer_player transfer_player unless method_defined?(:stair_transfer_player)
  def transfer_player(cancelVehicles = true)
    stair_transfer_player(cancelVehicles)
    $game_player.clear_stair_data
  end
end

class Game_Event
  alias stair_cett check_event_trigger_touch unless method_defined?(:stair_cett)
  def check_event_trigger_touch(x, y)
    return if on_stair?
    return stair_cett(x, y)
  end

  alias stair_ceta check_event_trigger_auto unless method_defined?(:stair_ceta)
  def check_event_trigger_auto
    if $game_map && $game_map.events
      for event in $game_map.events.values
        next if self.is_stair_event? || @id == event.id
        if @real_x / Game_Map::REAL_RES_X == event.x &&
           @real_y / Game_Map::REAL_RES_Y == event.y
          if event.is_stair_event?
            self.slope(*event.get_stair_data)
            return
          end
        end
      end
    end
    return if on_stair? || $game_player.on_stair?
    return stair_ceta
  end

  alias stair_start start unless method_defined?(:stair_start)
  def start
    if is_stair_event?
      $game_player.slope(*self.get_stair_data)
    else
      stair_start
    end
  end

  def is_stair_event?
    return self.name == "Slope"
  end

  def get_stair_data
    return if !is_stair_event?
    return if !@list
    for cmd in @list
      if cmd.code == 108
        if cmd.parameters[0] =~ /Slope: (\d+)x(\d+)/
          xincline, yincline = $1.to_i, $2.to_i
        elsif cmd.parameters[0] =~ /Slope: -(\d+)x(\d+)/
          xincline, yincline = -$1.to_i, $2.to_i
        elsif cmd.parameters[0] =~ /Slope: (\d+)x-(\d+)/
          xincline, yincline = $1.to_i, -$2.to_i
        elsif cmd.parameters[0] =~ /Slope: -(\d+)x-(\d+)/
          xincline, yincline = -$1.to_i, -$2.to_i
        elsif cmd.parameters[0] =~ /Width: (\d+)\/(\d+)/
          ypos, yheight = $1.to_i, $2.to_i
        elsif cmd.parameters[0] =~ /Offset: (\d+)px/
          offset = $1.to_i
        end
      end
      if xincline && yincline && ypos && yheight && offset
        return [xincline, yincline, ypos, yheight, offset]
      end
    end
    return [xincline, yincline, ypos, yheight, 16]
  end
end

class Game_Player
  alias stair_cetc check_event_trigger_touch unless method_defined?(:stair_cetc)
  def check_event_trigger_touch(x, y)
    return if on_stair?
    return stair_cetc(x, y)
  end

  alias stair_ceth check_event_trigger_here unless method_defined?(:stair_ceth)
  def check_event_trigger_here(triggers)
    return if on_stair?
    return stair_ceth(triggers)
  end

  alias stair_cett check_event_trigger_there unless method_defined?(:stair_cett)
  def check_event_trigger_there(triggers)
    return if on_stair?
    return stair_cett(triggers)
  end

  def move_down(turn_enabled = true)
    turn_down if turn_enabled
    if passable?(@x, @y, 2)
      return if pbLedge(0,1)
      return if pbEndSurf(0,1)
      turn_down
      @y += 1
      $PokemonTemp.dependentEvents.pbMoveDependentEvents
      increase_steps
      moving_vertically(1)
    else
      if !check_event_trigger_touch(@x, @y+1)
        if !@bump_se || @bump_se<=0
          pbSEPlay("Player bump"); @bump_se = Graphics.frame_rate / 4
        end
      end
    end
  end

  def move_up(turn_enabled = true)
    turn_up if turn_enabled
    if passable?(@x, @y, 8)
      return if pbLedge(0,-1)
      return if pbEndSurf(0,-1)
      turn_up
      @y -= 1
      $PokemonTemp.dependentEvents.pbMoveDependentEvents
      increase_steps
      moving_vertically(-1)
    else
      if !check_event_trigger_touch(@x, @y-1)
        if !@bump_se || @bump_se<=0
          pbSEPlay("Player bump"); @bump_se = Graphics.frame_rate / 4
        end
      end
    end
  end
end

class Game_Map
  alias stair_passable? passable? unless method_defined?(:stair_passable?)
  def passable?(x, y, d, self_event = nil)
    return stair_passable?(x, y, d, self_event) if self_event.nil?
    return stair_passable?(x, y, d, self_event) if !self_event.on_middle_of_stair?
    if y > self_event.y
      return self_event.stair_y_position > 0
    elsif y < self_event.y
      return self_event.stair_y_position + 1 < self_event.stair_y_height
    end
    return true
  end

  alias stair_scroll_down scroll_down unless method_defined?(:stair_scroll_down)
  def scroll_down(distance)
    return if $DisableScrollCounter == 1
    return stair_scroll_down(distance)
  end

  alias stair_scroll_left scroll_left unless method_defined?(:stair_scroll_left)
  def scroll_left(distance)
    return if $DisableScrollCounter == 1
    return stair_scroll_left(distance)
  end

  alias stair_scroll_right scroll_right unless method_defined?(:stair_scroll_right)
  def scroll_right(distance)
    return if $DisableScrollCounter == 1
    return stair_scroll_right(distance)
  end

  alias stair_scroll_up scroll_up unless method_defined?(:stair_scroll_up)
  def scroll_up(distance)
    return if $DisableScrollCounter == 1
    return stair_scroll_up(distance)
  end
end

class Game_Character
  attr_accessor :stair_start_x
  attr_accessor :stair_start_y
  attr_accessor :stair_end_x
  attr_accessor :stair_end_y
  attr_accessor :stair_y_position
  attr_accessor :stair_y_height
  attr_accessor :stair_begin_offset

  def on_stair?
    return @stair_begin_offset && @stair_start_x && @stair_start_y &&
           @stair_end_x && @stair_end_y && @stair_y_position && @stair_y_height
  end

  def on_middle_of_stair?
    return false if !on_stair?
    if @stair_start_x > @stair_end_x
      return @real_x < (@stair_start_x * Game_Map::TILE_WIDTH - @stair_begin_offset) * Game_Map::X_SUBPIXELS &&
          @real_x > (@stair_end_x * Game_Map::TILE_WIDTH + @stair_begin_offset) * Game_Map::X_SUBPIXELS
    else
      return @real_x > (@stair_start_x * Game_Map::TILE_WIDTH + @stair_begin_offset) * Game_Map::X_SUBPIXELS &&
          @real_x < (@stair_end_x * Game_Map::TILE_WIDTH - @stair_begin_offset) * Game_Map::X_SUBPIXELS
    end
  end

  def slope(x, y, ypos = 0, yheight = 1, begin_offset = 0)
    @stair_start_x = self.is_a?(Game_Player) ? @x : (@real_x / Game_Map::REAL_RES_X).round
    @stair_start_y = self.is_a?(Game_Player) ? @y : (@real_y / Game_Map::REAL_RES_Y).round
    @stair_end_x = @stair_start_x + x
    @stair_end_y = @stair_start_y + y
    @stair_y_position = ypos
    @stair_y_height = yheight
    @stair_begin_offset = begin_offset
    @stair_start_y += ypos
    @stair_end_y += ypos
  end

  def clear_stair_data
    @stair_begin_offset = nil
    @stair_start_x = nil
    @stair_start_y = nil
    @stair_end_x = nil
    @stair_end_y = nil
    @stair_y_position = nil
    @stair_y_height = nil
    @stair_last_increment = nil
  end

  def move_down(turn_enabled = true)
    turn_down if turn_enabled
    if passable?(@x, @y, 2)
      turn_down
      @y += 1
      increase_steps
      moving_vertically(1)
    else
      check_event_trigger_touch(@x, @y+1)
    end
  end

  def move_up(turn_enabled = true)
    turn_up if turn_enabled
    if passable?(@x, @y, 8)
      turn_up
      @y -= 1
      increase_steps
      moving_vertically(-1)
    else
      check_event_trigger_touch(@x, @y-1)
    end
  end

  def moving_vertically(value)
    if on_stair?
      @stair_y_position -= value
      if @stair_y_position >= @stair_y_height || @stair_y_position < 0
        clear_stair_data
      end
    end
  end

  alias stair_update update unless method_defined?(:stair_update)
  def update
    if self == $game_player && SMOOTH_SCROLLING && on_stair?
      # Game_Player#update called; now disable Game_Map#scroll_*
      $DisableScrollCounter = 2
    end
    stair_update
  end

  alias stair_update_pattern update_pattern unless method_defined?(:stair_update_pattern)
  def update_pattern
    if self == $game_player && $DisableScrollCounter == 2
      $DisableScrollCounter = 1
    end
    stair_update_pattern
  end

  alias stair_moving? moving? unless method_defined?(:stair_moving?)
  def moving?
    if self == $game_player && $DisableScrollCounter == 1
      # New Game_Player#update scroll method
      $DisableScrollCounter = 0
      @view_offset_x ||= 0
      @view_offset_y ||= 0
      self.center(
          (@real_x + @view_offset_x) / 4 / Game_Map::TILE_WIDTH,
          (@real_y + @view_offset_y) / 4 / Game_Map::TILE_HEIGHT
      )
    end
    return stair_moving?
  end

  alias stair_screen_y screen_y unless method_defined?(:stair_screen_y)
  def screen_y
    real_y = @real_y
    if on_stair?
      if @real_x / Game_Map::X_SUBPIXELS.to_f <= @stair_start_x * Game_Map::TILE_WIDTH &&
         @stair_end_x < @stair_start_x
        distance = (@stair_start_x - @stair_end_x) * Game_Map::REAL_RES_X -
            2.0 * @stair_begin_offset * Game_Map::X_SUBPIXELS
        rpos = @real_x - @stair_end_x * Game_Map::REAL_RES_X - @stair_begin_offset * Game_Map::X_SUBPIXELS
        fraction = 1 - rpos / distance.to_f
        if fraction >= 0 && fraction <= 1
          diff = fraction * (@stair_end_y - @stair_start_y) * Game_Map::REAL_RES_Y
          real_y += diff
          if self.is_a?(Game_Player)
            if SMOOTH_SCROLLING
              @view_offset_y += diff - (@stair_last_increment || 0)
            else
              $game_map.scroll_down(diff - (@stair_last_increment || 0))
            end
          end
          @stair_last_increment = diff
        end
        if fraction >= 1
          endy = @stair_end_y
          if @stair_end_y < @stair_start_y
            endy -= @stair_y_position
          else
            endy -= @stair_y_position
          end
          @y = endy
          @real_y = endy * Game_Map::REAL_RES_Y
          @view_offset_y = 0 if SMOOTH_SCROLLING && self.is_a?(Game_Player)
          clear_stair_data
          return stair_screen_y
        end
      elsif @real_x / Game_Map::X_SUBPIXELS.to_f >= @stair_start_x * Game_Map::TILE_WIDTH &&
          @stair_end_x > @stair_start_x
        distance = (@stair_end_x - @stair_start_x) * Game_Map::REAL_RES_X -
            2.0 * @stair_begin_offset * Game_Map::X_SUBPIXELS
        rpos = @stair_start_x * Game_Map::REAL_RES_X - @real_x + @stair_begin_offset * Game_Map::X_SUBPIXELS
        fraction = rpos / distance.to_f
        if fraction <= 0 && fraction >= -1
          diff = fraction * (@stair_start_y - @stair_end_y) * Game_Map::REAL_RES_Y
          real_y += diff
          if self.is_a?(Game_Player)
            if SMOOTH_SCROLLING
              @view_offset_y += diff - (@stair_last_increment || 0)
            else
              $game_map.scroll_down(diff - (@stair_last_increment || 0))
            end
          end
          @stair_last_increment = diff
        end
        if fraction <= -1
          endy = @stair_end_y
          if @stair_end_y < @stair_start_y
            endy -= @stair_y_position
          else
            endy -= @stair_y_position
          end
          @y = endy
          @real_y = endy * Game_Map::REAL_RES_Y
          @view_offset_y = 0 if SMOOTH_SCROLLING && self.is_a?(Game_Player)
          clear_stair_data
          return stair_screen_y
        end
      else
        clear_stair_data
      end
    elsif jumping?
      if @jump_distance == 0
        jump_fraction = 0.5   # 0.5 to 0 to 0.5
      else
        jump_fraction = ((@jump_distance_left / @jump_distance) - 0.5).abs   # 0.5 to 0 to 0.5
      end
      n = @jump_peak * (4 * jump_fraction**2 - 1)
      return (real_y - self.map.display_y + 3) / 4 + Game_Map::TILE_HEIGHT + n
    end
    return (real_y - self.map.display_y + 3) / 4 + (Game_Map::TILE_HEIGHT)
  end
end
