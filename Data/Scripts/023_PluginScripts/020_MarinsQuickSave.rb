#==============================================================================#
#                                   Quicksave                                  #
#                                    by Marin                                  #
#==============================================================================#
#         Saves the game with a little animation upon pressing F8.             #
#==============================================================================#
#                    Please give credit when using this.                       #
#==============================================================================#

PluginManager.register({
  :name => "Quicksave",
  :version => "1.1",
  :credits => "Marin",
  :link => "https://reliccastle.com/resources/136/"
})

class Scene_Map
  alias quicksave_update update unless method_defined?(:quicksave_update)
  def update
    quicksave_update
    if Input.trigger?(Input::L) && is_save_possible?(recalc: true)
      pbSave
      @mode = 0
      @vp = Viewport.new(0,0,Graphics.width,Graphics.height)
      @vp.z = 99999
      @disk = Sprite.new(@vp)
      @disk.bitmap = RPG::Cache.load_bitmap("Graphics/Pictures/saveDisk")
      @disk.x, @disk.y = 8, 8
      @disk.opacity = 0
      @arrow = Sprite.new(@vp)
      @arrow.bitmap = RPG::Cache.load_bitmap("Graphics/Pictures/saveArrow")
      @arrow.x, @arrow.y = 8, -4
      @arrow.opacity = 0
    end
    if $game_temp.in_menu || $game_temp.in_battle || $game_player.move_route_forcing
      @mode = nil
      if @disk && !@disk.disposed?
        @disk.opacity = 0
        @disk.dispose
      end
      if @arrow && !@arrow.disposed?
        @arrow.opacity = 0
        @arrow.dispose
      end
      @vp.dispose if @vp
      return
    end
    if @mode == 0
      @disk.opacity += (255/(4 * (Graphics.frame_rate/10)))
      @mode = 1 if @disk.opacity >= 255
    end
    if @mode == 1
      @arrow.opacity += (255/(4 * (Graphics.frame_rate/10)))
      @mode = 2 if @arrow.opacity >= 255
    end
    if @mode == 2
      @arrow.y += 1
      @mode = 3 if @arrow.y >= 22
    end
    if @mode == 3
      @arrow.opacity -= (255/(4 * (Graphics.frame_rate/10)))
      @disk.opacity -= (255/(4 * (Graphics.frame_rate/10)))
      if @disk.opacity <= 0
        @arrow.dispose
        @disk.dispose
        @vp.dispose
        @mode = nil
      end
    end
  end
end

def is_save_possible?(key = :base, recalc: false)
  return false if !$game_temp
  return $game_temp.save_possible[key] if !recalc
  ret   = true
  ret_i = true
  ret_m = true
  ret = false if $game_temp.in_menu || $game_temp.in_battle
  ret = false if $game_temp.message_window_showing
  ret = false if !$game_system || $game_system.save_disabled
  ret_m = false if pbMapInterpreterRunning?
  ret_m = false if pbMapInterpreter && pbMapInterpreter.move_route_waiting
  ret_m = false if pbMapInterpreter && pbMapInterpreter.wait_count > 0
  ret_i = false if !$game_map || $game_map.events.values.any? { |e| e.wait_count > 0 }
  ret = false if !$game_temp || $game_temp.executing_script
  ret = false if pbInBugContest?
  ret = false if pbInSafari?
  $game_temp.save_possible[:base]       = ret && ret_i && ret_m
  $game_temp.save_possible[:interp]     = ret_i && ret
  $game_temp.save_possible[:move_route] = ret_m && ret
  return $game_temp.save_possible[key]
end

class Game_Temp
  attr_accessor :save_possible

  def save_possible
    @save_possible = {} if !@save_possible
    return @save_possible
  end
end

class Interpreter
  attr_reader :move_route_waiting
  attr_reader :wait_count

  alias __saving__pbExecuteScript pbExecuteScript unless method_defined?(:__saving__execute_script)
  def pbExecuteScript(*args)
    $game_temp.executing_script = true
    ret = __saving__pbExecuteScript(*args)
    $game_temp.executing_script = false
    return ret
  end
end

class Game_Event
  attr_reader :wait_count
end

class Game_Temp
  attr_accessor :executing_script
end
