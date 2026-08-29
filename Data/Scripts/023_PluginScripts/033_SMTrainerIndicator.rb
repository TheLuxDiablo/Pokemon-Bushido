# Trainer sensor visuals and detection.
module TrainerSensor

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

  def self.enabled?
    return true if !defined?(TRAINER_SENSOR_ENABLED)
    return TRAINER_SENSOR_ENABLED
  end

  def self.bushido_style?
    return false if !defined?(TRAINER_SENSOR_BUSHIDO_STYLE)
    return TRAINER_SENSOR_BUSHIDO_STYLE
  end

  def self.triggered?
    return @triggered
  end

  def self.event
    return @event
  end

  def self.create
    return if @created

    create_bars

    if bushido_style?
      create_vignette
      create_battle_slash
    end

    @created = true
  end

  def self.create_bars
    color = bushido_style? ? BUSHIDO_BAR_COLOR : NORMAL_BAR_COLOR

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

  def self.create_battle_slash
    @battle_slash = Sprite.new
    @battle_slash.z = SENSOR_Z + 10

    @battle_slash.bitmap = Bitmap.new(
      Graphics.width,
      Graphics.height
    )

    @battle_slash.opacity = 0
    @battle_slash.visible = false

    redraw_battle_slash(0.0)
  end

  def self.redraw_battle_slash(progress)
    return if !@battle_slash
    return if !@battle_slash.bitmap

    bitmap = @battle_slash.bitmap
    bitmap.clear

    progress = progress.to_f
    progress = 0.0 if progress < 0.0
    progress = 1.0 if progress > 1.0
    return if progress <= 0.0

    width  = Graphics.width.to_f
    height = Graphics.height.to_f

    p0 = [-width * 0.035, -height * 0.045]
    p1 = [ width * 0.34,  height * 0.08]
    p2 = [ width * 1.04,  height * 0.48]
    p3 = [ width * 0.96,  height * 1.07]

    samples = 42
    visible_samples = [(samples * progress).ceil, 2].max

    red_outer_left  = []
    red_outer_right = []
    red_inner_left  = []
    red_inner_right = []
    blade_left      = []
    blade_right     = []

    0.upto(visible_samples) do |i|
      t = i.to_f / samples.to_f
      t = progress if t > progress

      point = cubic_bezier_point(
        p0, p1, p2, p3, t
      )

      tangent = cubic_bezier_tangent(
        p0, p1, p2, p3, t
      )

      length = Math.sqrt(
        tangent[0] * tangent[0] +
        tangent[1] * tangent[1]
      )

      length = 1.0 if length <= 0.0

      nx = -tangent[1] / length
      ny =  tangent[0] / length

      if t < 0.14
        half_width = width * 0.0015 +
          width * 0.0145 * (t / 0.14)
      elsif t < 0.72
        local = (t - 0.14) / 0.58
        half_width = width * (0.016 + 0.018 * local)
      else
        local = (t - 0.72) / 0.28
        half_width = width * (0.034 - 0.027 * local)
      end

      if progress < 0.999
        tip_distance = progress - t
        tip_zone = 0.075

        if tip_distance < tip_zone
          tip_scale = tip_distance / tip_zone
          tip_scale = 0.10 if tip_scale < 0.10
          half_width *= tip_scale
        end
      end

      outer = half_width * 1.04
      inner = half_width * 0.82

      blade_left << [
        point[0] + nx * outer,
        point[1] + ny * outer
      ]

      blade_right << [
        point[0] - nx * inner,
        point[1] - ny * inner
      ]

      red_outer_extra = 3.0
      red_inner_extra = 1.0

      red_outer_left << [
        point[0] + nx * (outer + red_outer_extra),
        point[1] + ny * (outer + red_outer_extra)
      ]

      red_outer_right << [
        point[0] - nx * (inner + red_outer_extra),
        point[1] - ny * (inner + red_outer_extra)
      ]

      red_inner_left << [
        point[0] + nx * (outer + red_inner_extra),
        point[1] + ny * (outer + red_inner_extra)
      ]

      red_inner_right << [
        point[0] - nx * (inner + red_inner_extra),
        point[1] - ny * (inner + red_inner_extra)
      ]

      break if t >= progress
    end

    red_outer = red_outer_left + red_outer_right.reverse
    red_inner = red_inner_left + red_inner_right.reverse
    blade     = blade_left + blade_right.reverse

    draw_filled_polygon(
      bitmap,
      red_outer,
      Color.new(75, 0, 0, 115)
    )

    draw_filled_polygon(
      bitmap,
      red_inner,
      Color.new(235, 35, 28, 175)
    )

    draw_filled_polygon(
      bitmap,
      blade,
      Color.new(255, 255, 255, 255)
    )

    accent1 = [
      [width * 0.525, height * 0.365],
      [width * 0.590, height * 0.425],
      [width * 0.545, height * 0.392]
    ]

    accent2 = [
      [width * 0.585, height * 0.275],
      [width * 0.675, height * 0.395],
      [width * 0.615, height * 0.315]
    ]

    if progress >= 0.50
      draw_polygon_outline(
        bitmap,
        accent1,
        Color.new(235, 35, 28, 190)
      )

      draw_filled_polygon(
        bitmap,
        accent1,
        Color.new(255, 255, 255, 255)
      )
    end

    if progress >= 0.63
      draw_polygon_outline(
        bitmap,
        accent2,
        Color.new(235, 35, 28, 190)
      )

      draw_filled_polygon(
        bitmap,
        accent2,
        Color.new(255, 255, 255, 255)
      )
    end
  end

  def self.cubic_bezier_point(p0, p1, p2, p3, t)
    u = 1.0 - t

    x =
      (u * u * u * p0[0]) +
      (3.0 * u * u * t * p1[0]) +
      (3.0 * u * t * t * p2[0]) +
      (t * t * t * p3[0])

    y =
      (u * u * u * p0[1]) +
      (3.0 * u * u * t * p1[1]) +
      (3.0 * u * t * t * p2[1]) +
      (t * t * t * p3[1])

    return [x, y]
  end

  def self.cubic_bezier_tangent(p0, p1, p2, p3, t)
    u = 1.0 - t

    x =
      (3.0 * u * u * (p1[0] - p0[0])) +
      (6.0 * u * t * (p2[0] - p1[0])) +
      (3.0 * t * t * (p3[0] - p2[0]))

    y =
      (3.0 * u * u * (p1[1] - p0[1])) +
      (6.0 * u * t * (p2[1] - p1[1])) +
      (3.0 * t * t * (p3[1] - p2[1]))

    return [x, y]
  end

  def self.draw_filled_polygon(bitmap, points, color)
    return if !points || points.length < 3

    min_y = points[0][1].to_i
    max_y = min_y

    points.each do |point|
      y = point[1].to_i
      min_y = y if y < min_y
      max_y = y if y > max_y
    end

    min_y = 0 if min_y < 0
    max_y = bitmap.height - 1 if max_y >= bitmap.height

    min_y.upto(max_y) do |y|
      intersections = []

      0.upto(points.length - 1) do |i|
        a = points[i]
        b = points[(i + 1) % points.length]

        ay = a[1]
        by = b[1]

        next if ay == by

        low_y  = ay < by ? ay : by
        high_y = ay > by ? ay : by

        next if y < low_y
        next if y >= high_y

        x =
          a[0] +
          (y - ay) *
          (b[0] - a[0]) /
          (by - ay).to_f

        intersections << x
      end

      intersections.sort!

      index = 0

      while index + 1 < intersections.length
        x1 = intersections[index].ceil
        x2 = intersections[index + 1].floor

        x1 = 0 if x1 < 0
        x2 = bitmap.width - 1 if x2 >= bitmap.width

        if x2 >= x1
          bitmap.fill_rect(
            x1,
            y,
            x2 - x1 + 1,
            1,
            color
          )
        end

        index += 2
      end
    end
  end

  def self.draw_polygon_outline(bitmap, points, color)
    return if !points || points.length < 2

    0.upto(points.length - 1) do |i|
      a = points[i]
      b = points[(i + 1) % points.length]

      draw_slash_line(
        bitmap,
        a[0].to_i,
        a[1].to_i,
        b[0].to_i,
        b[1].to_i,
        color
      )
    end
  end

  def self.draw_slash_line(bitmap, x1, y1, x2, y2, color)
    dx = (x2 - x1).abs
    dy = (y2 - y1).abs

    sx = x1 < x2 ? 1 : -1
    sy = y1 < y2 ? 1 : -1

    err = dx - dy

    loop do
      if x1 >= 0 && x1 < bitmap.width &&
         y1 >= 0 && y1 < bitmap.height
        bitmap.set_pixel(x1, y1, color)
      end

      break if x1 == x2 && y1 == y2

      e2 = err * 2

      if e2 > -dy
        err -= dy
        x1 += sx
      end

      if e2 < dx
        err += dx
        y1 += sy
      end
    end
  end

  def self.trigger_battle_slash(event)
    return if !bushido_style?
    return if !@battle_slash
    return if @battle_slash_playing

    if @last_seen_event == event
      return
    end

    @last_seen_event = event

    @battle_slash_timer   = 0
    @battle_slash_playing = true

    @battle_slash.visible = true
    @battle_slash.opacity = 0
    redraw_battle_slash(0.0)
  end

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

  def self.clear_seen_lock
    @last_seen_event = nil
  end

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

  def self.update_battle_slash
    return if !@battle_slash_playing
    return if !@battle_slash

    @battle_slash_timer += 1
    frame = @battle_slash_timer

    if frame == 1
      @battle_slash.visible = true
      @battle_slash.opacity = 255
      redraw_battle_slash(0.08)

    elsif frame == 2
      redraw_battle_slash(0.34)
      @battle_slash.opacity = 255

    elsif frame == 3
      redraw_battle_slash(0.78)
      @battle_slash.opacity = 255

    elsif frame == 4
      redraw_battle_slash(1.0)
      @battle_slash.opacity = 255

    elsif frame <= 14
      @battle_slash.opacity = 255

    elsif frame <= 25
      fade_frame = frame - 14
      @battle_slash.opacity = 255 - ((255 * fade_frame) / 11)
      @battle_slash.opacity = 0 if @battle_slash.opacity < 0

    else
      @battle_slash.visible = false
      @battle_slash.opacity = 0

      redraw_battle_slash(0.0)

      @battle_slash_timer   = 0
      @battle_slash_playing = false
    end
  end

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

# Updates the trainer sensor with the player.
class Game_Player

  unless method_defined?(:trainer_sensor_original_update)
    alias trainer_sensor_original_update update
  end

  def update(*args)
    trainer_sensor_original_update(*args)
    TrainerSensor.update
  end

end

# Reads trainer sensor data from map events.
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

# Scans trainer sight and warning ranges.
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

    $game_map.events.each_value do |event|

      next if !event
      next if !event.is_trainer?

      distance =
        event.view_distance

      if pbEventCanReachPlayer?(
        event,
        $game_player,
        distance
      )

        seeing_event = event
        next
      end

      next if !TrainerSensor.inRange?(
        event,
        distance
      )

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

    if seeing_event

      TrainerSensor.hide

      TrainerSensor.create

      TrainerSensor.trigger_battle_slash(
        seeing_event
      )

    else

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
