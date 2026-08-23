#===============================================================================
# Trainer Sensor
# Pokémon Bushido / Pokémon Essentials v18.1
#===============================================================================
#
# Event naming:
#
#   Trainer(5)
#
# Add "no_s" to disable the warning for an individual trainer:
#
#   Trainer(5) no_s
#
# Settings:
#
#   TRAINER_SENSOR_ENABLED       = true
#   TRAINER_SENSOR_BUSHIDO_STYLE = true
#
# Bushido style adds:
#   - Deep red/black cinematic framing
#   - Crimson inner-edge glow
#   - Screen-edge danger vignette
#   - Increasing red pulse near trainer FOV
#   - Animated ink/katana slash when one tile from danger
#
#===============================================================================


module TrainerSensor

  #=============================================================================
  # Visual Settings
  #=============================================================================

  SENSOR_Z = 99998

  NORMAL_BAR_COLOR = Color.new(0, 0, 0)

  BUSHIDO_BAR_COLOR       = Color.new(16, 0, 0)
  BUSHIDO_BAR_INNER       = Color.new(40, 0, 0)
  BUSHIDO_CRIMSON         = Color.new(150, 12, 12)
  BUSHIDO_CRIMSON_BRIGHT  = Color.new(220, 32, 25)
  BUSHIDO_CRIMSON_DARK    = Color.new(75, 0, 0)

  # Width of the framing.
  BAR_SIZE = 52

  # Maximum opacity of the main cinematic bars.
  MAX_BAR_OPACITY = 225

  # Maximum strength of the red screen-edge warning.
  MAX_VIGNETTE_OPACITY = 135

  #=============================================================================
  # Runtime Data
  #=============================================================================

  @top       = nil
  @bottom    = nil
  @left      = nil
  @right     = nil

  @vignette  = nil
  @slash     = nil

  @triggered = false
  @created   = false

  @event     = nil
  @direction = 2

  @distance  = 1
  @range     = 0

  @target_opacity = 0
  @duration       = 0

  @slash_timer    = 0
  @slash_visible  = false


  #=============================================================================
  # Settings
  #=============================================================================

  def self.enabled?
    return true if !defined?(TRAINER_SENSOR_ENABLED)
    return TRAINER_SENSOR_ENABLED
  end


  def self.bushido_style?
    return false if !defined?(TRAINER_SENSOR_BUSHIDO_STYLE)
    return TRAINER_SENSOR_BUSHIDO_STYLE
  end


  #=============================================================================
  # Public Access
  #=============================================================================

  def self.triggered?
    return @triggered
  end


  def self.event
    return @event
  end


  #=============================================================================
  # Create Graphics
  #=============================================================================

  def self.create
    return if @created

    create_bars

    if bushido_style?
      create_vignette
      create_slash
    end

    @created = true
  end


  #=============================================================================
  # Main Cinematic Bars
  #=============================================================================

  def self.create_bars
    color = bushido_style? ? BUSHIDO_BAR_COLOR : NORMAL_BAR_COLOR

    #---------------------------------------------------------------------------
    # Top
    #---------------------------------------------------------------------------

    @top = Sprite.new
    @top.z = SENSOR_Z

    @top.bitmap = Bitmap.new(
      Graphics.width,
      BAR_SIZE
    )

    @top.bitmap.fill_rect(
      0,
      0,
      Graphics.width,
      BAR_SIZE,
      color
    )

    if bushido_style?
      draw_horizontal_bar_detail(
        @top.bitmap,
        false
      )
    end

    @top.x  = 0
    @top.y  = 0
    @top.oy = BAR_SIZE

    #---------------------------------------------------------------------------
    # Bottom
    #---------------------------------------------------------------------------

    @bottom = Sprite.new
    @bottom.z = SENSOR_Z

    @bottom.bitmap = Bitmap.new(
      Graphics.width,
      BAR_SIZE
    )

    @bottom.bitmap.fill_rect(
      0,
      0,
      Graphics.width,
      BAR_SIZE,
      color
    )

    if bushido_style?
      draw_horizontal_bar_detail(
        @bottom.bitmap,
        true
      )
    end

    @bottom.x = 0
    @bottom.y = Graphics.height

    #---------------------------------------------------------------------------
    # Left
    #---------------------------------------------------------------------------

    @left = Sprite.new
    @left.z = SENSOR_Z

    @left.bitmap = Bitmap.new(
      BAR_SIZE,
      Graphics.height
    )

    @left.bitmap.fill_rect(
      0,
      0,
      BAR_SIZE,
      Graphics.height,
      color
    )

    if bushido_style?
      draw_vertical_bar_detail(
        @left.bitmap,
        false
      )
    end

    @left.x  = 0
    @left.y  = 0
    @left.ox = BAR_SIZE

    #---------------------------------------------------------------------------
    # Right
    #---------------------------------------------------------------------------

    @right = Sprite.new
    @right.z = SENSOR_Z

    @right.bitmap = Bitmap.new(
      BAR_SIZE,
      Graphics.height
    )

    @right.bitmap.fill_rect(
      0,
      0,
      BAR_SIZE,
      Graphics.height,
      color
    )

    if bushido_style?
      draw_vertical_bar_detail(
        @right.bitmap,
        true
      )
    end

    @right.x = Graphics.width
    @right.y = 0

    @top.opacity    = 0
    @bottom.opacity = 0
    @left.opacity   = 0
    @right.opacity  = 0
  end


  #=============================================================================
  # Bushido Bar Detail
  #=============================================================================

  def self.draw_horizontal_bar_detail(bitmap, top_edge)
    h = bitmap.height

    if top_edge
      bitmap.fill_rect(
        0, 0,
        bitmap.width, 8,
        BUSHIDO_BAR_INNER
      )

      bitmap.fill_rect(
        0, 0,
        bitmap.width, 2,
        BUSHIDO_CRIMSON
      )

      bitmap.fill_rect(
        0, 2,
        bitmap.width, 1,
        BUSHIDO_CRIMSON_DARK
      )
    else
      bitmap.fill_rect(
        0, h - 8,
        bitmap.width, 8,
        BUSHIDO_BAR_INNER
      )

      bitmap.fill_rect(
        0, h - 2,
        bitmap.width, 2,
        BUSHIDO_CRIMSON
      )

      bitmap.fill_rect(
        0, h - 3,
        bitmap.width, 1,
        BUSHIDO_CRIMSON_DARK
      )
    end
  end


  def self.draw_vertical_bar_detail(bitmap, left_edge)
    w = bitmap.width

    if left_edge
      bitmap.fill_rect(
        0, 0,
        8, bitmap.height,
        BUSHIDO_BAR_INNER
      )

      bitmap.fill_rect(
        0, 0,
        2, bitmap.height,
        BUSHIDO_CRIMSON
      )

      bitmap.fill_rect(
        2, 0,
        1, bitmap.height,
        BUSHIDO_CRIMSON_DARK
      )
    else
      bitmap.fill_rect(
        w - 8, 0,
        8, bitmap.height,
        BUSHIDO_BAR_INNER
      )

      bitmap.fill_rect(
        w - 2, 0,
        2, bitmap.height,
        BUSHIDO_CRIMSON
      )

      bitmap.fill_rect(
        w - 3, 0,
        1, bitmap.height,
        BUSHIDO_CRIMSON_DARK
      )
    end
  end


  #=============================================================================
  # Red Edge Vignette
  #=============================================================================

  def self.create_vignette
    @vignette = Sprite.new
    @vignette.z = SENSOR_Z - 1

    bitmap = Bitmap.new(
      Graphics.width,
      Graphics.height
    )

    thickness = 32
    steps     = 8
    size      = thickness / steps

    steps.times do |i|
      strength = (steps - i).to_f / steps
      alpha    = (80 * strength).to_i

      color = Color.new(
        150,
        0,
        0,
        alpha
      )

      offset = i * size

      # Top
      bitmap.fill_rect(
        0,
        offset,
        Graphics.width,
        size,
        color
      )

      # Bottom
      bitmap.fill_rect(
        0,
        Graphics.height - offset - size,
        Graphics.width,
        size,
        color
      )

      # Left
      bitmap.fill_rect(
        offset,
        0,
        size,
        Graphics.height,
        color
      )

      # Right
      bitmap.fill_rect(
        Graphics.width - offset - size,
        0,
        size,
        Graphics.height,
        color
      )
    end

    @vignette.bitmap  = bitmap
    @vignette.opacity = 0
  end


  #=============================================================================
  # Katana / Ink Slash
  #=============================================================================

  def self.create_slash
    @slash = Sprite.new
    @slash.z = SENSOR_Z + 1

    width  = 150
    height = 50

    bitmap = Bitmap.new(
      width,
      height
    )

    #---------------------------------------------------------------------------
    # Main uneven brush stroke.
    #
    # Drawing it manually gives it a rough ink/slash character rather than
    # looking like a clean UI rectangle.
    #---------------------------------------------------------------------------

    95.times do |i|
      x = 20 + i
      y = 36 - (i / 4)

      thickness = 2

      thickness = 4 if i > 18 && i < 70
      thickness = 3 if i > 70 && i < 85

      bitmap.fill_rect(
        x,
        y,
        1,
        thickness,
        BUSHIDO_CRIMSON_BRIGHT
      )
    end

    # Secondary dark brush trail
    78.times do |i|
      x = 28 + i
      y = 42 - (i / 4)

      bitmap.fill_rect(
        x,
        y,
        1,
        2,
        BUSHIDO_CRIMSON_DARK
      )
    end

    # Tiny broken ink pieces
    bitmap.fill_rect(
      13, 38,
      7, 2,
      BUSHIDO_CRIMSON
    )

    bitmap.fill_rect(
      119, 9,
      10, 2,
      BUSHIDO_CRIMSON
    )

    bitmap.fill_rect(
      132, 5,
      5, 1,
      BUSHIDO_CRIMSON_DARK
    )

    @slash.bitmap = bitmap

    @slash.ox = width / 2
    @slash.oy = height / 2

    @slash.x = Graphics.width / 2
    @slash.y = Graphics.height / 2

    @slash.opacity = 0
    @slash.visible = false
  end


  #=============================================================================
  # Show Sensor
  #=============================================================================

  def self.show(event, distance)
    return if !enabled?
    return if !event

    self.create if !@created

    old_event     = @event
    old_direction = @direction
    was_triggered = @triggered

    @triggered = true
    @event     = event
    @direction = event.direction
    @distance  = [distance.to_i, 1].max

    #---------------------------------------------------------------------------
    # Distance to the trainer's actual FOV line.
    #
    # Trainer faces vertically -> horizontal distance matters.
    # Trainer faces horizontally -> vertical distance matters.
    #---------------------------------------------------------------------------

    case @direction
    when 2, 8
      @range = (
        $game_player.x -
        event.x
      ).abs

    when 4, 6
      @range = (
        $game_player.y -
        event.y
      ).abs

    else
      @range = @distance
    end

    ratio =
      (@distance - @range + 1) /
      @distance.to_f

    ratio = 0.0 if ratio < 0.0
    ratio = 1.0 if ratio > 1.0

    @target_opacity =
      (MAX_BAR_OPACITY * ratio).to_i

    #---------------------------------------------------------------------------
    # First appearance / different trainer / trainer turned.
    #---------------------------------------------------------------------------

    if !was_triggered ||
       old_event != event ||
       old_direction != @direction

      @duration = [
        Graphics.frame_rate / 5,
        1
      ].max
    end
  end


  #=============================================================================
  # Hide
  #=============================================================================

  def self.hide
    return if !@created

    if @triggered
      @triggered = false

      @duration = [
        Graphics.frame_rate / 5,
        1
      ].max
    end

    @event          = nil
    @direction      = 0
    @distance       = 1
    @range          = 0
    @target_opacity = 0

    @slash_visible = false

    if @slash
      @slash.visible = false
      @slash.opacity = 0
    end
  end


  #=============================================================================
  # Frame Update
  #=============================================================================

  def self.update
    return if !@created

    @top.update
    @bottom.update
    @left.update
    @right.update

    @vignette.update if @vignette
    @slash.update    if @slash

    if @duration > 0
      if @triggered
        update_bar_positions
      else
        hide_bar_positions
      end

      @duration -= 1
      @duration = 0 if @duration < 0
    end

    if @triggered
      update_live_opacity

      if bushido_style?
        update_vignette
        update_slash
      end
    else
      update_hide_opacity
    end
  end


  #=============================================================================
  # Position Cinematic Bars
  #=============================================================================

  def self.update_bar_positions
    d = @duration
    return if d <= 0

    #---------------------------------------------------------------------------
    # Trainer faces LEFT/RIGHT.
    # Top and bottom framing closes in.
    #---------------------------------------------------------------------------

    if [4, 6].include?(@direction)

      @top.y =
        (
          @top.y * (d - 1) +
          BAR_SIZE
        ) / d

      @bottom.y =
        (
          @bottom.y * (d - 1) +
          Graphics.height -
          BAR_SIZE
        ) / d

      @left.x =
        (
          @left.x * (d - 1) +
          0
        ) / d

      @right.x =
        (
          @right.x * (d - 1) +
          Graphics.width
        ) / d

    #---------------------------------------------------------------------------
    # Trainer faces UP/DOWN.
    # Left and right framing closes in.
    #---------------------------------------------------------------------------

    elsif [2, 8].include?(@direction)

      @left.x =
        (
          @left.x * (d - 1) +
          BAR_SIZE
        ) / d

      @right.x =
        (
          @right.x * (d - 1) +
          Graphics.width -
          BAR_SIZE
        ) / d

      @top.y =
        (
          @top.y * (d - 1) +
          0
        ) / d

      @bottom.y =
        (
          @bottom.y * (d - 1) +
          Graphics.height
        ) / d
    end
  end


  #=============================================================================
  # Move Bars Back Offscreen
  #=============================================================================

  def self.hide_bar_positions
    d = @duration
    return if d <= 0

    @top.y =
      (
        @top.y * (d - 1) +
        0
      ) / d

    @bottom.y =
      (
        @bottom.y * (d - 1) +
        Graphics.height
      ) / d

    @left.x =
      (
        @left.x * (d - 1) +
        0
      ) / d

    @right.x =
      (
        @right.x * (d - 1) +
        Graphics.width
      ) / d
  end


  #=============================================================================
  # Main Opacity
  #=============================================================================

  def self.update_live_opacity
    target = @target_opacity

    #---------------------------------------------------------------------------
    # Bushido "danger heartbeat".
    #
    # Only becomes noticeable when you're extremely close to stepping into FOV.
    #---------------------------------------------------------------------------

    if bushido_style? && @range <= 2

      speed =
        @range <= 1 ? 4.0 : 7.0

      amount =
        @range <= 1 ? 28 : 12

      pulse =
        (
          Math.sin(
            Graphics.frame_count / speed
          ) + 1.0
        ) / 2.0

      target += (
        pulse * amount
      ).to_i
    end

    target = 245 if target > 245

    current = @top.opacity

    difference =
      target - current

    if difference.abs <= 2
      current = target
    else
      step = difference / 4
      step = 1  if step == 0 && difference > 0
      step = -1 if step == 0 && difference < 0

      current += step
    end

    set_bar_opacity(current)
  end


  def self.set_bar_opacity(value)
    value = value.to_i
    value = 0   if value < 0
    value = 255 if value > 255

    @top.opacity    = value
    @bottom.opacity = value
    @left.opacity   = value
    @right.opacity  = value
  end


  #=============================================================================
  # Red Vignette
  #=============================================================================

  def self.update_vignette
    return if !@vignette

    ratio =
      (@distance - @range + 1) /
      @distance.to_f

    ratio = 0.0 if ratio < 0.0
    ratio = 1.0 if ratio > 1.0

    target =
      (MAX_VIGNETTE_OPACITY * ratio).to_i

    # Stronger living pulse at the edge of FOV.
    if @range <= 1
      pulse =
        (
          Math.sin(
            Graphics.frame_count / 4.0
          ) + 1.0
        ) / 2.0

      target += (
        pulse * 40
      ).to_i
    end

    target = 190 if target > 190

    current = @vignette.opacity
    difference = target - current

    if difference.abs <= 2
      current = target
    else
      step = difference / 5
      step = 1  if step == 0 && difference > 0
      step = -1 if step == 0 && difference < 0

      current += step
    end

    @vignette.opacity = current
  end


  #=============================================================================
  # Katana Slash Warning
  #=============================================================================

  def self.update_slash
    return if !@slash

    #---------------------------------------------------------------------------
    # Only appears when ONE tile away from entering the FOV.
    #---------------------------------------------------------------------------

    if @range != 1
      @slash.visible = false
      @slash.opacity = 0
      @slash_timer   = 0
      return
    end

    #---------------------------------------------------------------------------
    # Spawn a quick repeating slash.
    #
    # It isn't permanently sitting on-screen. It flashes in like an instinctive
    # danger cue, disappears, then can happen again after a short pause.
    #---------------------------------------------------------------------------

    @slash_timer += 1

    cycle = Graphics.frame_rate

    frame =
      @slash_timer % cycle

    if frame < 12

      @slash.visible = true

      # Fast flash in/out
      if frame < 4
        @slash.opacity =
          frame * 60
      else
        @slash.opacity =
          240 -
          ((frame - 4) * 30)
      end

      @slash.opacity = 0 if @slash.opacity < 0
      @slash.opacity = 240 if @slash.opacity > 240

      # Slight movement gives it a cutting motion.
      movement = frame * 2

      #-----------------------------------------------------------------------
      # Position the slash toward the side of the screen representing danger.
      #-----------------------------------------------------------------------

      case @direction

      when 2, 8
        if $game_player.x < @event.x
          @slash.x =
            Graphics.width - 76 + movement
        else
          @slash.x =
            76 - movement
        end

        @slash.y =
          Graphics.height / 2

      when 4, 6
        @slash.x =
          Graphics.width / 2

        if $game_player.y < @event.y
          @slash.y =
            Graphics.height - 58 + movement
        else
          @slash.y =
            58 - movement
        end
      end

    else
      @slash.visible = false
      @slash.opacity = 0
    end
  end


  #=============================================================================
  # Fade Everything Out
  #=============================================================================

  def self.update_hide_opacity
    current = @top.opacity

    if current > 0
      current -= 22
      current = 0 if current < 0

      set_bar_opacity(current)
    end

    if @vignette && @vignette.opacity > 0
      value =
        @vignette.opacity - 20

      value = 0 if value < 0

      @vignette.opacity = value
    end

    if @slash
      @slash.opacity = 0
      @slash.visible = false
    end
  end


  #=============================================================================
  # Warning Range
  #=============================================================================

  def self.inRange?(event, distance)
    return false if !enabled?
    return false if !event
    return false if !$game_player
    return false if !distance
    return false if distance <= 0

    #---------------------------------------------------------------------------
    # Must be generally in front of the trainer.
    #---------------------------------------------------------------------------

    case event.direction

    when 2
      return false if $game_player.y <= event.y

    when 4
      return false if $game_player.x >= event.x

    when 6
      return false if $game_player.x <= event.x

    when 8
      return false if $game_player.y >= event.y

    else
      return false
    end

    #---------------------------------------------------------------------------
    # If the trainer can ALREADY see us, the warning is over.
    # Essentials' normal trainer encounter takes over here.
    #---------------------------------------------------------------------------

    if pbEventCanReachPlayer?(
      event,
      $game_player,
      distance
    )
      return false
    end

    #---------------------------------------------------------------------------
    # Keep warning local to the trainer instead of extending infinitely alongside
    # their sight line.
    #---------------------------------------------------------------------------

    dx =
      event.x -
      $game_player.x

    dy =
      event.y -
      $game_player.y

    radius =
      Math.sqrt(
        (dx * dx) +
        (dy * dy)
      )

    return radius.floor <= distance
  end

end


#===============================================================================
# Update Sensor With Player
#===============================================================================

class Game_Player

  unless method_defined?(:trainer_sensor_original_update)
    alias trainer_sensor_original_update update
  end

  def update(*args)
    trainer_sensor_original_update(*args)
    TrainerSensor.update
  end

end


#===============================================================================
# Trainer Event Data
#===============================================================================

class Game_Event

  attr_reader :view_distance

  unless method_defined?(:trainer_sensor_original_refresh)
    alias trainer_sensor_original_refresh refresh
  end

  def refresh(*args)
    trainer_sensor_original_refresh(*args)
    refresh_trainer_sensor
  end


  def refresh_trainer_sensor
    @trainer_sensor_enabled = false
    @view_distance = 1

    event_name =
      self.name.to_s

    if event_name =~ /trainer\s*\(\s*(\d+)\s*\)/i
      @trainer_sensor_enabled = true
      @view_distance = $1.to_i
    end

    if event_name =~ /no_s/i
      @trainer_sensor_enabled = false
    end
  end


  def is_trainer?
    if @trainer_sensor_enabled.nil?
      refresh_trainer_sensor
    end

    return @trainer_sensor_enabled
  end

end


#===============================================================================
# Map Sensor Scanner
#===============================================================================

Events.onMapUpdate += proc { |sender, e|

  begin

    #---------------------------------------------------------------------------
    # Master Settings switch
    #---------------------------------------------------------------------------

    if !TrainerSensor.enabled?
      TrainerSensor.hide
      next
    end

    next if !$game_map
    next if !$game_player

    final_event = nil

    #---------------------------------------------------------------------------
    # Don't show warning while an event is running.
    #---------------------------------------------------------------------------

    if $game_system &&
       $game_system.map_interpreter &&
       $game_system.map_interpreter.running?

      TrainerSensor.hide
      next
    end

    #---------------------------------------------------------------------------
    # Find all applicable trainers.
    #---------------------------------------------------------------------------

    $game_map.events.each_value do |event|

      next if !event
      next if !event.is_trainer?

      distance =
        event.view_distance

      next if !TrainerSensor.inRange?(
        event,
        distance
      )

      #-------------------------------------------------------------------------
      # Multiple overlapping trainer warning zones:
      # use the closest trainer.
      #-------------------------------------------------------------------------

      if final_event

        old_x =
          final_event.x -
          $game_player.x

        old_y =
          final_event.y -
          $game_player.y

        new_x =
          event.x -
          $game_player.x

        new_y =
          event.y -
          $game_player.y

        old_distance =
          Math.sqrt(
            (old_x * old_x) +
            (old_y * old_y)
          )

        new_distance =
          Math.sqrt(
            (new_x * new_x) +
            (new_y * new_y)
          )

        next if new_distance >= old_distance
      end

      final_event = event
    end

    #---------------------------------------------------------------------------
    # Display
    #---------------------------------------------------------------------------

    if final_event

      TrainerSensor.show(
        final_event,
        final_event.view_distance
      )

    else

      TrainerSensor.hide

    end

  rescue Exception => ex

    p "[TrainerSensor] #{ex.class}: #{ex.message}"

  end

}