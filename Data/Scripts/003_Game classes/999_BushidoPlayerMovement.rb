#===============================================================================
# Bushido Player Movement
#===============================================================================

module BushidoPlayerMovement
  BUFFER_FRAMES = [(Graphics.frame_rate / 6), 1].max
  DIRECTIONS    = [2, 4, 6, 8]

  # Visual movement feel, measured in screen pixels.
  START_LEAD = 1.0
  TURN_CARRY = 1.0

  # Lower values settle more quickly.
  VISUAL_DECAY = 0.52

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

  def self.direction_vector(dir)
    case dir
    when 2; return [0, 1]
    when 4; return [-1, 0]
    when 6; return [1, 0]
    when 8; return [0, -1]
    end
    return [0, 0]
  end
end


class Game_Player
  #-----------------------------------------------------------------------------
  # Setup
  #-----------------------------------------------------------------------------

  alias bushido_movement_initialize initialize
  def initialize(*args)
    bushido_movement_initialize(*args)
    bushido_init_movement_state
  end

  def bushido_init_movement_state
    @bushido_buffered_dir  = 0     if @bushido_buffered_dir.nil?
    @bushido_buffer_frame  = 0     if @bushido_buffer_frame.nil?
    @bushido_direction_age = {}    if @bushido_direction_age.nil?

    @bushido_visual_x      = 0.0   if @bushido_visual_x.nil?
    @bushido_visual_y      = 0.0   if @bushido_visual_y.nil?
    @bushido_motion_chain  = false if @bushido_motion_chain.nil?
    @bushido_motion_dir    = 0     if @bushido_motion_dir.nil?
  end

  #-----------------------------------------------------------------------------
  # Main update
  #-----------------------------------------------------------------------------

  alias bushido_movement_update update
  def update
    bushido_init_movement_state
    bushido_update_direction_input

    old_direction = @direction

    bushido_movement_update

    bushido_update_visual_motion(old_direction)
  end

  #-----------------------------------------------------------------------------
  # Input buffering
  #-----------------------------------------------------------------------------

  def bushido_update_direction_input
    return if pbMapInterpreterRunning?
    return if $game_temp.message_window_showing
    return if $PokemonTemp.miniupdate
    return if $game_temp.in_menu

    BushidoPlayerMovement::DIRECTIONS.each do |dir|
      next if !BushidoPlayerMovement.direction_triggered?(dir)

      @bushido_direction_age[dir] = Graphics.frame_count

      if moving?
        @bushido_buffered_dir = dir
        @bushido_buffer_frame = Graphics.frame_count
      end
    end

    if @bushido_buffered_dir != 0
      age = Graphics.frame_count - @bushido_buffer_frame

      if age > BushidoPlayerMovement::BUFFER_FRAMES
        @bushido_buffered_dir = 0
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Direction priority
  #-----------------------------------------------------------------------------

  def bushido_held_directions
    bushido_init_movement_state

    dirs = []

    BushidoPlayerMovement::DIRECTIONS.each do |dir|
      dirs.push(dir) if BushidoPlayerMovement.direction_pressed?(dir)
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

  #-----------------------------------------------------------------------------
  # Movement commands
  #-----------------------------------------------------------------------------

  def update_command_new
    dir = 0

    unless pbMapInterpreterRunning? ||
           $game_temp.message_window_showing ||
           $PokemonTemp.miniupdate ||
           $game_temp.in_menu

      # Buffered input has first priority.
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

      # Keep Essentials' tap-to-face behavior.
      if !@moved_last_frame && dir != 0 && dir != @lastdir
        bushido_turn_direction(dir)

      elsif dir != 0
        moved = bushido_try_move(dir)

        # If the preferred direction is blocked, try another held direction.
        if !moved
          i = 1
          while i < held.length
            if bushido_try_move(held[i])
              dir = held[i]
              moved = true
              break
            end
            i += 1
          end

          # Keep normal bump/touch-event behavior if every direction is blocked.
          bushido_move_direction(dir) if !moved
        end
      end
    end

    if dir != @lastdir
      @lastdirframe = Graphics.frame_count
    end

    @lastdir = dir
  end

  #-----------------------------------------------------------------------------
  # Visual movement feel
  #
  # These offsets never modify @x, @y, @real_x or @real_y.
  #-----------------------------------------------------------------------------

  def bushido_update_visual_motion(old_direction)
    bushido_decay_visual_offset

    # Don't apply movement juice to jumps or forced routes.
    if jumping? || @move_route_forcing
      bushido_reset_visual_motion
      return
    end

    held = (Input.dir4 != 0)

    # Beginning a fresh movement chain.
    if moving? && !@bushido_motion_chain
      @bushido_motion_chain = true
      @bushido_motion_dir   = @direction

      x, y = BushidoPlayerMovement.direction_vector(@direction)

      @bushido_visual_x += x * BushidoPlayerMovement::START_LEAD
      @bushido_visual_y += y * BushidoPlayerMovement::START_LEAD
    end

    # Carry a tiny amount of the previous direction through a turn.
    if moving? &&
       @bushido_motion_chain &&
       old_direction != @direction

      x, y = BushidoPlayerMovement.direction_vector(old_direction)

      @bushido_visual_x += x * BushidoPlayerMovement::TURN_CARRY
      @bushido_visual_y += y * BushidoPlayerMovement::TURN_CARRY

      @bushido_motion_dir = @direction
    end

    # Once movement has physically completed and input has been released,
    # visually finish the final couple of pixels rather than stopping dead.
    if @bushido_motion_chain && !moving? && !held
      @bushido_motion_chain = false
      @bushido_motion_dir   = 0
    end
  end

  def bushido_decay_visual_offset
    decay = BushidoPlayerMovement::VISUAL_DECAY

    @bushido_visual_x *= decay
    @bushido_visual_y *= decay

    @bushido_visual_x = 0.0 if @bushido_visual_x.abs < 0.10
    @bushido_visual_y = 0.0 if @bushido_visual_y.abs < 0.10
  end

  def bushido_reset_visual_motion
    @bushido_visual_x     = 0.0
    @bushido_visual_y     = 0.0
    @bushido_motion_chain = false
    @bushido_motion_dir   = 0
  end

  #-----------------------------------------------------------------------------
  # Player-only rendering offset
  #-----------------------------------------------------------------------------

  alias bushido_movement_screen_x screen_x
  def screen_x
    bushido_init_movement_state
    return bushido_movement_screen_x + @bushido_visual_x.round
  end

  alias bushido_movement_screen_y screen_y
  def screen_y
    bushido_init_movement_state
    return bushido_movement_screen_y + @bushido_visual_y.round
  end
end