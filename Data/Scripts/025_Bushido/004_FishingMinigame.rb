#===============================================================================
# Fishing Minigame
#===============================================================================

class FishingMinigame
  PROGRESS_MAX  = 5

  TARGET_WIDTH  = 96
  PERFECT_WIDTH = 24

  START_SPEED   = 4.0
  SPEED_GAIN    = 0.45

  TIME_LIMIT    = 10.0

  FEEDBACK_TIME = 14

  INTRO_FRAMES  = 14
  OUTRO_FRAMES  = 12
  HOOKED_FRAMES = 22

  def initialize(msgWindow=nil)
    @msgWindow = msgWindow

    @progress = 0
    @last_progress = 0

    @marker_x = 0.0
    @marker_dir = 1
    @marker_speed = START_SPEED

    @target_x = 0

    @feedback = nil
    @feedback_timer = 0

    @input_lock = 8

    @finished = false
    @success = false

    @time_left = TIME_LIMIT

    @old_message_visible = nil

    @intro_amount = 0.0
    @outro_amount = 0.0

    @pulse = 0
    @pip_pulse = 0

    setup_graphics
    reset_round
  end

  #-----------------------------------------------------------------------------
  # Main
  #-----------------------------------------------------------------------------
  def main
    if @msgWindow
      @old_message_visible = @msgWindow.visible
      @msgWindow.visible = false
    end

    play_intro

    loop do
      Graphics.update
      Input.update
      pbUpdateSceneMap

      update
      draw

      break if @finished
    end

    if @success
      play_hooked
    end

    play_outro

    return @success
  ensure
    dispose

    if @msgWindow && @old_message_visible != nil
      @msgWindow.visible = @old_message_visible
    end
  end

  #-----------------------------------------------------------------------------
  # Graphics setup
  #-----------------------------------------------------------------------------
  def setup_graphics
    @viewport = Viewport.new(
      0,
      0,
      Graphics.width,
      Graphics.height
    )
    @viewport.z = 99999

    @sprite = Sprite.new(@viewport)
    @sprite.bitmap = Bitmap.new(
      Graphics.width,
      Graphics.height
    )

    pbSetSystemFont(@sprite.bitmap)

    @width  = Graphics.width
    @height = Graphics.height

    @panel_height = 138
    @panel_base_y = @height - @panel_height

    @track_width  = snap2(@width - 80)
    @track_height = 16
    @track_x      = snap2((@width - @track_width) / 2)

    @timer_x = 32
    @timer_width = snap2(@width - 64)
  end

  def dispose
    if @sprite
      if @sprite.bitmap &&
         !@sprite.bitmap.disposed?
        @sprite.bitmap.dispose
      end

      @sprite.dispose
    end

    if @viewport &&
       !@viewport.disposed?
      @viewport.dispose
    end
  end

  #-----------------------------------------------------------------------------
  # 2px positioning
  #-----------------------------------------------------------------------------
  def snap2(value)
    return (value.to_i / 2) * 2
  end

  #-----------------------------------------------------------------------------
  # Animated panel position
  #-----------------------------------------------------------------------------
  def current_panel_y
    offset = 0

    if @intro_amount < 1.0
      offset =
        @panel_height *
        (1.0 - ease_out(@intro_amount))
    elsif @outro_amount > 0.0
      offset =
        @panel_height *
        ease_in(@outro_amount)
    end

    return snap2(@panel_base_y + offset)
  end

  def ease_out(t)
    return 1.0 - ((1.0 - t) * (1.0 - t))
  end

  def ease_in(t)
    return t * t
  end

  #-----------------------------------------------------------------------------
  # Intro animation
  #-----------------------------------------------------------------------------
  def play_intro
    INTRO_FRAMES.times do |i|
      Graphics.update
      Input.update
      pbUpdateSceneMap

      @intro_amount =
        (i + 1).to_f / INTRO_FRAMES.to_f

      draw
    end

    @intro_amount = 1.0

    5.times do
      Graphics.update
      Input.update
      pbUpdateSceneMap
      draw
    end
  end

  #-----------------------------------------------------------------------------
  # Outro animation
  #-----------------------------------------------------------------------------
  def play_outro
    OUTRO_FRAMES.times do |i|
      Graphics.update
      Input.update
      pbUpdateSceneMap

      @outro_amount =
        (i + 1).to_f / OUTRO_FRAMES.to_f

      draw
    end
  end

  #-----------------------------------------------------------------------------
  # Hooked animation
  #-----------------------------------------------------------------------------
  def play_hooked
    HOOKED_FRAMES.times do |i|
      Graphics.update
      Input.update
      pbUpdateSceneMap

      @pulse = HOOKED_FRAMES - i

      draw

      panel_y = current_panel_y

      pop = 0

      if i < 6
        pop = 6 - i
      end

      draw_center_text(
        @sprite.bitmap,
        "HOOKED!",
        0,
        snap2(panel_y - 42 - pop),
        @width,
        Color.new(110, 220, 135)
      )
    end
  end

  #-----------------------------------------------------------------------------
  # Update
  #-----------------------------------------------------------------------------
  def update
    return if @finished

    if @feedback_timer > 0
      @feedback_timer -= 1

      @pulse -= 1 if @pulse > 0
      @pip_pulse -= 1 if @pip_pulse > 0

      if @feedback_timer <= 0
        @feedback = nil

        if @progress >= PROGRESS_MAX
          @success = true
          @finished = true
          return
        end

        reset_round
      end

      return
    end

    update_timer

    return if @finished

    update_marker

    @pip_pulse -= 1 if @pip_pulse > 0

    if @input_lock > 0
      @input_lock -= 1
      return
    end

    if Input.trigger?(Input::C)
      check_input
    end
  end

  #-----------------------------------------------------------------------------
  # Timer
  #-----------------------------------------------------------------------------
  def update_timer
    @time_left -=
      1.0 / Graphics.frame_rate.to_f

    if @time_left <= 0
      @time_left = 0
      @success = false
      @finished = true
    end
  end

  #-----------------------------------------------------------------------------
  # Marker movement
  #-----------------------------------------------------------------------------
  def update_marker
    @marker_x +=
      @marker_speed *
      @marker_dir

    left_edge  = @track_x
    right_edge = @track_x + @track_width

    if @marker_x >= right_edge
      @marker_x = right_edge
      @marker_dir = -1

    elsif @marker_x <= left_edge
      @marker_x = left_edge
      @marker_dir = 1
    end
  end

  #-----------------------------------------------------------------------------
  # Input check
  #-----------------------------------------------------------------------------
  def check_input
    marker = snap2(@marker_x)

    target_left =
      @target_x

    target_right =
      @target_x +
      TARGET_WIDTH

    perfect_left =
      @target_x +
      ((TARGET_WIDTH - PERFECT_WIDTH) / 2)

    perfect_right =
      perfect_left +
      PERFECT_WIDTH

    if marker >= perfect_left &&
       marker <= perfect_right
      perfect_hit

    elsif marker >= target_left &&
          marker <= target_right
      good_hit

    else
      miss
    end
  end

  #-----------------------------------------------------------------------------
  # Hit results
  #-----------------------------------------------------------------------------
  def good_hit
    @last_progress = @progress

    @progress += 1

    if @progress > PROGRESS_MAX
      @progress = PROGRESS_MAX
    end

    @marker_speed += SPEED_GAIN

    @feedback = :good
    @feedback_timer = FEEDBACK_TIME

    @pulse = 8
    @pip_pulse = 8

    play_hit_sound
  end

  def perfect_hit
    @last_progress = @progress

    @progress += 2

    if @progress > PROGRESS_MAX
      @progress = PROGRESS_MAX
    end

    @marker_speed += SPEED_GAIN

    @feedback = :perfect
    @feedback_timer = FEEDBACK_TIME + 4

    @pulse = 12
    @pip_pulse = 10

    play_perfect_sound
  end

  def miss
    @feedback = :miss
    @feedback_timer = FEEDBACK_TIME

    @pulse = 6

    play_miss_sound
  end

  #-----------------------------------------------------------------------------
  # Prepare next pull
  #-----------------------------------------------------------------------------
  def reset_round
    min_target =
      snap2(@track_x + 12)

    max_target =
      snap2(
        @track_x +
        @track_width -
        TARGET_WIDTH -
        12
      )

    if max_target <= min_target
      @target_x = min_target
    else
      range =
        max_target -
        min_target

      @target_x =
        snap2(
          min_target +
          rand(range)
        )
    end

    if rand(2) == 0
      @marker_x = @track_x
      @marker_dir = 1
    else
      @marker_x =
        @track_x +
        @track_width

      @marker_dir = -1
    end

    @input_lock = 5
  end

  #-----------------------------------------------------------------------------
  # Main draw
  #-----------------------------------------------------------------------------
  def draw
    bmp = @sprite.bitmap
    bmp.clear

    panel_y = current_panel_y

    draw_dimming(bmp)

    if panel_y < @height
      draw_panel(bmp, panel_y)
      draw_instruction(bmp, panel_y)
      draw_focus_meter(bmp, panel_y)
      draw_pips(bmp, panel_y)
      draw_timer(bmp, panel_y)
      draw_feedback(bmp, panel_y)
    end
  end

  #-----------------------------------------------------------------------------
  # Overworld dimming
  #-----------------------------------------------------------------------------
  def draw_dimming(bmp)
    alpha = 90

    if @intro_amount < 1.0
      alpha =
        (90 * @intro_amount).to_i
    end

    if @outro_amount > 0.0
      alpha =
        (90 * (1.0 - @outro_amount)).to_i
    end

    return if alpha <= 0

    bmp.fill_rect(
      0,
      0,
      @width,
      @height,
      Color.new(0, 0, 0, alpha)
    )
  end

  #-----------------------------------------------------------------------------
  # Panel
  #-----------------------------------------------------------------------------
  def draw_panel(bmp, panel_y)
    panel =
      Color.new(
        20,
        22,
        30,
        255
      )

    border =
      Color.new(
        220,
        220,
        230
      )

    inner =
      Color.new(
        65,
        68,
        78
      )

    bmp.fill_rect(
      0,
      panel_y,
      @width,
      @panel_height,
      panel
    )

    bmp.fill_rect(
      0,
      panel_y,
      @width,
      2,
      border
    )

    bmp.fill_rect(
      0,
      panel_y + 4,
      @width,
      2,
      inner
    )
  end

  #-----------------------------------------------------------------------------
  # Instruction
  #-----------------------------------------------------------------------------
  def draw_instruction(bmp, panel_y)
    return if @feedback

    draw_center_text(
      bmp,
      "Press C inside the focus zone!",
      0,
      panel_y + 14,
      @width,
      Color.new(220, 222, 230)
    )
  end

  #-----------------------------------------------------------------------------
  # Focus meter
  #-----------------------------------------------------------------------------
  def draw_focus_meter(bmp, panel_y)
    track_y =
      snap2(panel_y + 48)

    track_bg =
      Color.new(
        46,
        48,
        58
      )

    track_border =
      Color.new(
        200,
        202,
        212
      )

    target_color =
      Color.new(
        84,
        160,
        104
      )

    perfect_color =
      Color.new(
        218,
        178,
        70
      )

    marker_color =
      Color.new(
        245,
        245,
        245
      )

    # Border
    bmp.fill_rect(
      @track_x - 2,
      track_y - 2,
      @track_width + 4,
      @track_height + 4,
      track_border
    )

    # Track
    bmp.fill_rect(
      @track_x,
      track_y,
      @track_width,
      @track_height,
      track_bg
    )

    # Target zone
    bmp.fill_rect(
      @target_x,
      track_y,
      TARGET_WIDTH,
      @track_height,
      target_color
    )

    # Perfect zone
    perfect_x =
      snap2(
        @target_x +
        ((TARGET_WIDTH - PERFECT_WIDTH) / 2)
      )

    bmp.fill_rect(
      perfect_x,
      track_y,
      PERFECT_WIDTH,
      @track_height,
      perfect_color
    )

    # Small ticks beneath the bar
    tick_y =
      snap2(
        track_y +
        @track_height +
        6
      )

    11.times do |i|
      tick_x =
        snap2(
          @track_x +
          ((@track_width * i) / 10)
        )

      tick_height =
        (i == 5) ? 8 : 4

      bmp.fill_rect(
        tick_x,
        tick_y,
        2,
        tick_height,
        Color.new(
          170,
          172,
          182
        )
      )
    end

    # Actual diamond marker
    draw_diamond(
      bmp,
      snap2(@marker_x),
      snap2(
        track_y +
        (@track_height / 2)
      ),
      16,
      marker_color
    )
  end

  #-----------------------------------------------------------------------------
  # Progress pips
  #-----------------------------------------------------------------------------
  def draw_pips(bmp, panel_y)
    filled =
      Color.new(
        92,
        190,
        112
      )

    empty =
      Color.new(
        50,
        52,
        60
      )

    outline =
      Color.new(
        182,
        184,
        194
      )

    pip_size = 12
    spacing = 28

    total_width =
      ((PROGRESS_MAX - 1) * spacing) +
      pip_size

    start_x =
      snap2(
        (@width / 2) -
        (total_width / 2)
      )

    pip_y =
      snap2(
        panel_y + 96
      )

    PROGRESS_MAX.times do |i|
      cx =
        snap2(
          start_x +
          (i * spacing) +
          (pip_size / 2)
        )

      cy =
        snap2(
          pip_y +
          (pip_size / 2)
        )

      radius = 6

      if @pip_pulse > 0 &&
         i >= @last_progress &&
         i < @progress
        radius = 8
      end

      draw_circle_2px(
        bmp,
        cx,
        cy,
        radius,
        outline
      )

      inner_radius =
        radius - 2

      color =
        i < @progress ?
        filled :
        empty

      draw_circle_2px(
        bmp,
        cx,
        cy,
        inner_radius,
        color
      )
    end
  end

  #-----------------------------------------------------------------------------
  # Timer
  #-----------------------------------------------------------------------------
  def draw_timer(bmp, panel_y)
    ratio =
      @time_left /
      TIME_LIMIT

    ratio = 0 if ratio < 0
    ratio = 1 if ratio > 1

    remaining_width =
      snap2(
        @timer_width *
        ratio
      )

    timer_y =
      snap2(
        panel_y +
        @panel_height -
        8
      )

    background =
      Color.new(
        55,
        58,
        68
      )

    foreground =
      Color.new(
        205,
        208,
        218
      )

    if ratio <= 0.30
      foreground =
        Color.new(
          220,
          100,
          90
        )
    elsif ratio <= 0.55
      foreground =
        Color.new(
          220,
          180,
          90
        )
    end

    bmp.fill_rect(
      @timer_x,
      timer_y,
      @timer_width,
      2,
      background
    )

    if remaining_width > 0
      bmp.fill_rect(
        @timer_x,
        timer_y,
        remaining_width,
        2,
        foreground
      )
    end
  end

  #-----------------------------------------------------------------------------
  # Hit feedback
  #-----------------------------------------------------------------------------
  def draw_feedback(bmp, panel_y)
    return if !@feedback

    case @feedback
    when :good
      text = "HIT!"
      color =
        Color.new(
          110,
          220,
          135
        )

    when :perfect
      text = "PERFECT!"
      color =
        Color.new(
          255,
          215,
          90
        )

    when :miss
      text = "MISS!"
      color =
        Color.new(
          235,
          90,
          90
        )

    else
      return
    end

    pop = 0

    if @feedback_timer > FEEDBACK_TIME - 5
      pop =
        (@feedback_timer -
        (FEEDBACK_TIME - 5))
    end

    draw_center_text(
      bmp,
      text,
      0,
      snap2(panel_y + 14 - pop),
      @width,
      color
    )
  end

  #-----------------------------------------------------------------------------
  # Sounds
  #-----------------------------------------------------------------------------
  def play_hit_sound
    begin
      pbSEPlay(
        "GUI sel decision"
      )
    rescue
    end
  end

  def play_perfect_sound
    begin
      pbSEPlay(
        "GUI sel decision"
      )
    rescue
    end
  end

  def play_miss_sound
    begin
      pbSEPlay(
        "GUI sel buzzer"
      )
    rescue
    end
  end

  #-----------------------------------------------------------------------------
  # Text
  #-----------------------------------------------------------------------------
  def draw_center_text(
    bmp,
    text,
    x,
    y,
    width,
    color
  )
    shadow =
      Color.new(
        0,
        0,
        0,
        180
      )

    bmp.font.color =
      shadow

    bmp.draw_text(
      snap2(x + 2),
      snap2(y + 2),
      snap2(width),
      24,
      text,
      1
    )

    bmp.font.color =
      color

    bmp.draw_text(
      snap2(x),
      snap2(y),
      snap2(width),
      24,
      text,
      1
    )
  end

  #-----------------------------------------------------------------------------
  # Diamond marker
  #-----------------------------------------------------------------------------
  def draw_diamond(
    bmp,
    cx,
    cy,
    size,
    color
  )
    cx = snap2(cx)
    cy = snap2(cy)
    size = snap2(size)

    half = size / 2

    i = 0

    while i < half
      # Upper-left
      bmp.fill_rect(
        snap2(cx - i - 2),
        snap2(cy - half + i),
        2,
        2,
        color
      )

      # Upper-right
      bmp.fill_rect(
        snap2(cx + i),
        snap2(cy - half + i),
        2,
        2,
        color
      )

      # Lower-left
      bmp.fill_rect(
        snap2(cx - i - 2),
        snap2(cy + half - i - 2),
        2,
        2,
        color
      )

      # Lower-right
      bmp.fill_rect(
        snap2(cx + i),
        snap2(cy + half - i - 2),
        2,
        2,
        color
      )

      i += 2
    end
  end

  #-----------------------------------------------------------------------------
  # 2px circles
  #-----------------------------------------------------------------------------
  def draw_circle_2px(
    bmp,
    cx,
    cy,
    radius,
    color
  )
    cx = snap2(cx)
    cy = snap2(cy)
    radius = snap2(radius)

    case radius
    when 8
      bmp.fill_rect(
        cx - 4,
        cy - 8,
        8,
        2,
        color
      )

      bmp.fill_rect(
        cx - 6,
        cy - 6,
        12,
        2,
        color
      )

      bmp.fill_rect(
        cx - 8,
        cy - 4,
        16,
        8,
        color
      )

      bmp.fill_rect(
        cx - 6,
        cy + 4,
        12,
        2,
        color
      )

      bmp.fill_rect(
        cx - 4,
        cy + 6,
        8,
        2,
        color
      )

    when 6
      bmp.fill_rect(
        cx - 4,
        cy - 6,
        8,
        2,
        color
      )

      bmp.fill_rect(
        cx - 6,
        cy - 4,
        12,
        8,
        color
      )

      bmp.fill_rect(
        cx - 4,
        cy + 4,
        8,
        2,
        color
      )

    when 4
      bmp.fill_rect(
        cx - 2,
        cy - 4,
        4,
        2,
        color
      )

      bmp.fill_rect(
        cx - 4,
        cy - 2,
        8,
        4,
        color
      )

      bmp.fill_rect(
        cx - 2,
        cy + 2,
        4,
        2,
        color
      )

    when 2
      bmp.fill_rect(
        cx - 2,
        cy - 2,
        4,
        4,
        color
      )
    end
  end
end


#===============================================================================
# Launch
#===============================================================================
def pbFishingMinigame(msgWindow=nil)
  game =
    FishingMinigame.new(
      msgWindow
    )

  return game.main
end


#===============================================================================
# Replace the original bite reaction check
#===============================================================================
def pbWaitForInput(
  msgWindow,
  message,
  frames
)
  pbMessageDisplay(
    msgWindow,
    message,
    false
  )

  (Graphics.frame_rate / 5).times do
    Graphics.update
    Input.update
    pbUpdateSceneMap
  end

  return pbFishingMinigame(
    msgWindow
  )
end