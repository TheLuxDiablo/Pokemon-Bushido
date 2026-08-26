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
# Behavior:
#   - Near trainer FOV: dark red/black warning frame
#   - Closer to FOV: stronger red vignette + pulse
#   - Enter actual FOV: full-screen slash flash
#   - Normal trainer event then takes over
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
  BUSHIDO_CRIMSON_BRIGHT  = Color.new(235, 35, 28)
  BUSHIDO_CRIMSON_DARK    = Color.new(75, 0, 0)

  BAR_SIZE = 52

  MAX_BAR_OPACITY      = 225
  MAX_VIGNETTE_OPACITY = 135

  #=============================================================================
  # Runtime Data
  #=============================================================================

  @top       = nil
  @bottom    = nil
  @left      = nil
  @right     = nil

  @vignette  = nil
  @battle_slash = nil

  @triggered = false
  @created   = false

  @event     = nil
  @direction = 2

  @distance  = 1
  @range     = 0

  @target_opacity = 0
  @duration       = 0

  @battle_slash_timer   = 0
  @battle_slash_playing = false
  @last_seen_event      = nil


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
      create_battle_slash
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

      bitmap.fill_rect(
        0,
        offset,
        Graphics.width,
        size,
        color
      )

      bitmap.fill_rect(
        0,
        Graphics.height - offset - size,
        Graphics.width,
        size,
        color
      )

      bitmap.fill_rect(
        offset,
        0,
        size,
        Graphics.height,
        color
      )

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
  # Full-Screen Battle Slash
  #=============================================================================

  def self.create_battle_slash
    @battle_slash = Sprite.new
    @battle_slash.z = SENSOR_Z + 10

    bitmap = Bitmap.new(
      Graphics.width,
      Graphics.height
    )

    #---------------------------------------------------------------------------
    # Large diagonal white-red slash.
    #
    # Drawn as several staggered streaks to feel more like a katana impact than
    # a clean UI line.
    #---------------------------------------------------------------------------

    width  = Graphics.width
    height = Graphics.height

    0.upto(width - 1) do |x|
      y = height - 70 - ((x * 0.55).to_i)

      # Dark red outer trail
      if y >= 0 && y < height
        bitmap.fill_rect(
          x,
          y,
          1,
          12,
          BUSHIDO_CRIMSON_DARK
        )
      end

      # Bright crimson body
      if y + 2 >= 0 && y + 2 < height
        bitmap.fill_rect(
          x,
          y + 2,
          1,
          7,
          BUSHIDO_CRIMSON_BRIGHT
        )
      end

      # White-hot blade center
      if y + 4 >= 0 && y + 4 < height
        bitmap.fill_rect(
          x,
          y + 4,
          1,
          2,
          Color.new(255, 235, 225)
        )
      end
    end

    # Secondary parallel slash
    0.upto(width - 1) do |x|
      y = height - 20 - ((x * 0.55).to_i)

      next if y < 0 || y >= height

      bitmap.fill_rect(
        x,
        y,
        1,
        3,
        BUSHIDO_CRIMSON
      )
    end

    @battle_slash.bitmap  = bitmap
    @battle_slash.opacity = 0
    @battle_slash.visible = false
  end


  #=============================================================================
  # Trigger Full-Screen Slash
  #=============================================================================

  def self.trigger_battle_slash(event)
    return if !bushido_style?
    return if !@battle_slash
    return if @battle_slash_playing

    # Don't retrigger every frame while the trainer still sees the player.
    if @last_seen_event == event
      return
    end

    @last_seen_event = event

    @battle_slash_timer   = 0
    @battle_slash_playing = true

    @battle_slash.visible = true
    @battle_slash.opacity = 0
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
  # Hide Sensor
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
  end


  #=============================================================================
  # Reset Battle Detection Lock
  #=============================================================================

  def self.clear_seen_lock
    @last_seen_event = nil
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

    @vignette.update    if @vignette
    @battle_slash.update if @battle_slash

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
      end
    else
      update_hide_opacity
    end

    update_battle_slash if @battle_slash_playing
  end


  #=============================================================================
  # Position Bars
  #=============================================================================

  def self.update_bar_positions
    d = @duration
    return if d <= 0

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
          @left.x * (d - 1)
        ) / d

      @right.x =
        (
          @right.x * (d - 1) +
          Graphics.width
        ) / d

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
          @top.y * (d - 1)
        ) / d

      @bottom.y =
        (
          @bottom.y * (d - 1) +
          Graphics.height
        ) / d
    end
  end


  #=============================================================================
  # Hide Bars
  #=============================================================================

  def self.hide_bar_positions
    d = @duration
    return if d <= 0

    @top.y =
      (
        @top.y * (d - 1)
      ) / d

    @bottom.y =
      (
        @bottom.y * (d - 1) +
        Graphics.height
      ) / d

    @left.x =
      (
        @left.x * (d - 1)
      ) / d

    @right.x =
      (
        @right.x * (d - 1) +
        Graphics.width
      ) / d
  end


  #=============================================================================
  # Live Opacity / Pulse
  #=============================================================================

  def self.update_live_opacity
    target = @target_opacity

    if bushido_style? && @range <= 2
      speed  = @range <= 1 ? 4.0 : 7.0
      amount = @range <= 1 ? 28 : 12

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

    current =
      @top.opacity

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
  # Vignette
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

    current =
      @vignette.opacity

    difference =
      target - current

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
  # Full-Screen Battle Slash Animation
  #=============================================================================

  def self.update_battle_slash
    return if !@battle_slash_playing
    return if !@battle_slash

    @battle_slash_timer += 1

    frame = @battle_slash_timer

    #---------------------------------------------------------------------------
    # 0-3:
    # extremely fast flash-in
    #---------------------------------------------------------------------------

    if frame <= 3

      @battle_slash.visible = true

      @battle_slash.opacity =
        frame * 85

    #---------------------------------------------------------------------------
    # 4-7:
    # hold the slash at full strength very briefly
    #---------------------------------------------------------------------------

    elsif frame <= 7

      @battle_slash.opacity = 255

    #---------------------------------------------------------------------------
    # 8-16:
    # rapidly disappear
    #---------------------------------------------------------------------------

    elsif frame <= 16

      remaining =
        16 - frame

      @battle_slash.opacity =
        (remaining * 28)

      @battle_slash.opacity = 0 if @battle_slash.opacity < 0

    #---------------------------------------------------------------------------
    # Finished
    #---------------------------------------------------------------------------

    else

      @battle_slash.visible = false
      @battle_slash.opacity = 0

      @battle_slash_timer   = 0
      @battle_slash_playing = false
    end
  end


  #=============================================================================
  # Fade Sensor Out
  #=============================================================================

  def self.update_hide_opacity
    current =
      @top.opacity

    if current > 0

      current -= 22
      current = 0 if current < 0

      set_bar_opacity(current)
    end

    if @vignette &&
       @vignette.opacity > 0

      value =
        @vignette.opacity - 20

      value = 0 if value < 0

      @vignette.opacity = value
    end
  end


  #=============================================================================
  # Pre-FOV Warning Check
  #=============================================================================

  def self.inRange?(event, distance)
    return false if !enabled?
    return false if !event
    return false if !$game_player
    return false if !distance
    return false if distance <= 0

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

    # If already seen, this is NOT warning range anymore.
    if pbEventCanReachPlayer?(
      event,
      $game_player,
      distance
    )
      return false
    end

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


  def trainer_sensor_completed?
    return false if !$game_self_switches
    key = [$game_map.map_id, self.id, "A"]
    return $game_self_switches[key] == true
  end

  def is_trainer?
    if @trainer_sensor_enabled.nil?
      refresh_trainer_sensor
    end

    return false if !@page

    return false if trainer_sensor_completed?
    return @trainer_sensor_enabled
  end

end


#===============================================================================
# Map Scanner
#===============================================================================

Events.onMapUpdate += proc { |sender, e|

  begin

    if !TrainerSensor.enabled?
      TrainerSensor.hide
      next
    end

    next if !$game_map
    next if !$game_player

    final_event = nil
    seeing_event = nil

    #---------------------------------------------------------------------------
    # Scan every Trainer(X)
    #---------------------------------------------------------------------------

    $game_map.events.each_value do |event|

      next if !event
      next if !event.is_trainer?

      distance =
        event.view_distance

      #-------------------------------------------------------------------------
      # FIRST:
      # Is the player actually inside this trainer's FOV?
      #
      # If yes, trigger the battle slash.
      #-------------------------------------------------------------------------

      if pbEventCanReachPlayer?(
        event,
        $game_player,
        distance
      )

        seeing_event = event
        next
      end

      #-------------------------------------------------------------------------
      # SECOND:
      # Otherwise check whether we're in the pre-FOV warning zone.
      #-------------------------------------------------------------------------

      next if !TrainerSensor.inRange?(
        event,
        distance
      )

      #-------------------------------------------------------------------------
      # Multiple warning zones:
      # choose closest.
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
    # Actual trainer detection
    #---------------------------------------------------------------------------

    if seeing_event

      TrainerSensor.hide

      TrainerSensor.create

      TrainerSensor.trigger_battle_slash(
        seeing_event
      )

    else

      # Reset so another future trainer can trigger its own slash.
      TrainerSensor.clear_seen_lock

      if final_event

        TrainerSensor.show(
          final_event,
          final_event.view_distance
        )

      else

        TrainerSensor.hide

      end
    end

  rescue Exception => ex

    p "[TrainerSensor] #{ex.class}: #{ex.message}"

  end

}