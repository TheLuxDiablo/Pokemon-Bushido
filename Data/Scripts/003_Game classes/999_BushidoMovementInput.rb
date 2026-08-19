#===============================================================================
# Bushido Movement Input
#===============================================================================

module BushidoMovementInput
  BUFFER_FRAMES = [(Graphics.frame_rate / 6), 1].max

  DIRECTIONS = [2, 4, 6, 8]

  def self.direction_pressed?(dir)
    case dir
    when 2; return Input.press?(Input::DOWN)
    when 4; return Input.press?(Input::LEFT)
    when 6; return Input.press?(Input::RIGHT)
    when 8; return Input.press?(Input::UP)
    end
    return false
  end

  def self.direction_triggered?(dir)
    case dir
    when 2; return Input.trigger?(Input::DOWN)
    when 4; return Input.trigger?(Input::LEFT)
    when 6; return Input.trigger?(Input::RIGHT)
    when 8; return Input.trigger?(Input::UP)
    end
    return false
  end
end


class Game_Player
  alias bushido_input_initialize initialize
  def initialize(*args)
    bushido_input_initialize(*args)

    @bushido_buffered_dir   = 0
    @bushido_buffer_frame   = 0
    @bushido_direction_age  = {}
  end

  alias bushido_input_update update
  def update
    bushido_update_direction_input
    bushido_input_update
  end

  def bushido_update_direction_input
    bushido_init_input_state

    return if pbMapInterpreterRunning?
    return if $game_temp.message_window_showing
    return if $PokemonTemp.miniupdate
    return if $game_temp.in_menu

    BushidoMovementInput::DIRECTIONS.each do |dir|
      if BushidoMovementInput.direction_triggered?(dir)
        @bushido_direction_age[dir] = Graphics.frame_count

        if moving?
          @bushido_buffered_dir = dir
          @bushido_buffer_frame = Graphics.frame_count
        end
      end
    end

    if @bushido_buffered_dir != 0
      age = Graphics.frame_count - @bushido_buffer_frame

      if age > BushidoMovementInput::BUFFER_FRAMES
        @bushido_buffered_dir = 0
      end
    end
  end

  def bushido_held_directions
    bushido_init_input_state
    dirs = []

    BushidoMovementInput::DIRECTIONS.each do |dir|
      dirs.push(dir) if BushidoMovementInput.direction_pressed?(dir)
    end

    dirs.sort! do |a, b|
      age_a = @bushido_direction_age[a] || -1
      age_b = @bushido_direction_age[b] || -1
      age_b <=> age_a
    end

    return dirs
  end

  def bushido_try_move(dir)
    return false if dir == 0

    if passable?(@x, @y, dir)
      bushido_move_direction(dir)
      return true
    end

    return false
  end

  def bushido_move_direction(dir)
    case dir
    when 2; move_down
    when 4; move_left
    when 6; move_right
    when 8; move_up
    end
  end

  def bushido_turn_direction(dir)
    case dir
    when 2; turn_down
    when 4; turn_left
    when 6; turn_right
    when 8; turn_up
    end
  end

  def update_command_new
    unless pbMapInterpreterRunning? ||
           $game_temp.message_window_showing ||
           $PokemonTemp.miniupdate ||
           $game_temp.in_menu

      # A direction pressed during the previous step gets first priority.
      if @bushido_buffered_dir != 0
        buffered = @bushido_buffered_dir
        @bushido_buffered_dir = 0

        if bushido_try_move(buffered)
          @lastdir      = buffered
          @lastdirframe = Graphics.frame_count
          return
        end
      end

      held = bushido_held_directions
      dir  = held[0] || 0

      # Preserve Essentials' tap-to-turn behavior.
      if !@moved_last_frame && dir != 0 && dir != @lastdir
        bushido_turn_direction(dir)
      elsif dir != 0
        # Try the player's most recently pressed direction first.
        moved = bushido_try_move(dir)

        # If it's blocked, try another direction they're still holding.
        if !moved
          held[1..-1].to_a.each do |fallback|
            if bushido_try_move(fallback)
              dir = fallback
              moved = true
              break
            end
          end

          # Nothing else worked. Use the normal movement call so Essentials
          # can still handle bumps and touch events correctly.
          bushido_move_direction(dir) if !moved
        end
      end
    end

    if dir != @lastdir
      @lastdirframe = Graphics.frame_count
    end

    @lastdir = dir
  end

  def bushido_init_input_state
    @bushido_buffered_dir  = 0   if @bushido_buffered_dir.nil?
    @bushido_buffer_frame  = 0   if @bushido_buffer_frame.nil?
    @bushido_direction_age = {}  if @bushido_direction_age.nil?
    end
end