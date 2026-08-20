#===============================================================================
# Bushido PostFX
# Improved default overworld treatment
#
# Goals:
# - stronger visual clarity
# - more perceived contrast and vibrance
# - cooler/neutral presentation
# - stronger depth perception
# - lightweight enough for RMXP
#===============================================================================

module BushidoPostFX
  TOGGLE_KEY = Input::F6

  TOGGLE_TRANSITION_FRAMES = 20

  DEFAULT_TONE = Tone.new(-4, 0, 9, 0)

  DEFAULT_VIGNETTE_OPACITY = 68
  DEFAULT_VIGNETTE_COLOR   = Color.new(0, 2, 10)

  DEFAULT_CENTER_LIFT_OPACITY = 14
  DEFAULT_DEPTH_OPACITY       = 26

  class << self
    attr_reader :enabled
  end

  @viewport = nil
  @vignette_sprite = nil
  @center_lift_sprite = nil
  @depth_sprite = nil

  @enabled = true

  @grade_tone = DEFAULT_TONE.clone
  @grade_start_tone = DEFAULT_TONE.clone
  @grade_target_tone = DEFAULT_TONE.clone
  @grade_duration = 0
  @grade_elapsed = 0

  @vignette_opacity = DEFAULT_VIGNETTE_OPACITY.to_f
  @vignette_start_opacity = DEFAULT_VIGNETTE_OPACITY.to_f
  @vignette_target_opacity = DEFAULT_VIGNETTE_OPACITY.to_f
  @vignette_duration = 0
  @vignette_elapsed = 0

  @center_lift_opacity = DEFAULT_CENTER_LIFT_OPACITY.to_f
  @center_lift_start_opacity = DEFAULT_CENTER_LIFT_OPACITY.to_f
  @center_lift_target_opacity = DEFAULT_CENTER_LIFT_OPACITY.to_f
  @center_lift_duration = 0
  @center_lift_elapsed = 0

  @depth_opacity = DEFAULT_DEPTH_OPACITY.to_f
  @depth_start_opacity = DEFAULT_DEPTH_OPACITY.to_f
  @depth_target_opacity = DEFAULT_DEPTH_OPACITY.to_f
  @depth_duration = 0
  @depth_elapsed = 0

  @vignette_bitmap = nil
  @center_lift_bitmap = nil
  @depth_bitmap = nil

  def self.create
    dispose_sprites
    build_cache unless cache_ready?

    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 450

    @center_lift_sprite = Sprite.new(@viewport)
    @center_lift_sprite.bitmap = @center_lift_bitmap
    @center_lift_sprite.z = 5
    @center_lift_sprite.blend_type = 1

    @depth_sprite = Sprite.new(@viewport)
    @depth_sprite.bitmap = @depth_bitmap
    @depth_sprite.z = 10

    @vignette_sprite = Sprite.new(@viewport)
    @vignette_sprite.bitmap = @vignette_bitmap
    @vignette_sprite.z = 20
    @vignette_sprite.color = DEFAULT_VIGNETTE_COLOR.clone

    apply_all

    echoln("[BushidoPostFX] ENABLED | F6 toggles PostFX")
  end

  def self.dispose_sprites
    dispose_sprite_only(@vignette_sprite)
    dispose_sprite_only(@center_lift_sprite)
    dispose_sprite_only(@depth_sprite)

    @vignette_sprite = nil
    @center_lift_sprite = nil
    @depth_sprite = nil

    if @viewport
      @viewport.dispose unless @viewport.disposed?
      @viewport = nil
    end
  end

  def self.dispose_sprite_only(sprite)
    return if !sprite
    sprite.dispose unless sprite.disposed?
  end

  def self.update
    update_toggle
    update_grade
    update_vignette
    update_center_lift
    update_depth
    apply_all

    @viewport.update if @viewport && !@viewport.disposed?
  end

  def self.update_toggle
    toggle if Input.trigger?(TOGGLE_KEY)
  end

  def self.toggle
    @enabled = !@enabled

    if @enabled
      transition_grade(DEFAULT_TONE, TOGGLE_TRANSITION_FRAMES)
      transition_vignette(DEFAULT_VIGNETTE_OPACITY, TOGGLE_TRANSITION_FRAMES)
      transition_center_lift(DEFAULT_CENTER_LIFT_OPACITY, TOGGLE_TRANSITION_FRAMES)
      transition_depth(DEFAULT_DEPTH_OPACITY, TOGGLE_TRANSITION_FRAMES)
      echoln("[BushidoPostFX] ENABLED")
    else
      transition_grade(Tone.new(0, 0, 0, 0), TOGGLE_TRANSITION_FRAMES)
      transition_vignette(0, TOGGLE_TRANSITION_FRAMES)
      transition_center_lift(0, TOGGLE_TRANSITION_FRAMES)
      transition_depth(0, TOGGLE_TRANSITION_FRAMES)
      echoln("[BushidoPostFX] DISABLED")
    end
  end

  def self.transition_grade(target, duration)
    @grade_start_tone = @grade_tone.clone
    @grade_target_tone = target.clone
    @grade_duration = [duration.to_i, 0].max
    @grade_elapsed = 0
    @grade_tone = @grade_target_tone.clone if @grade_duration == 0
  end

  def self.update_grade
    return if @grade_duration <= 0

    @grade_elapsed += 1
    t = eased_progress(@grade_elapsed, @grade_duration)

    @grade_tone = Tone.new(
      lerp(@grade_start_tone.red,   @grade_target_tone.red,   t),
      lerp(@grade_start_tone.green, @grade_target_tone.green, t),
      lerp(@grade_start_tone.blue,  @grade_target_tone.blue,  t),
      lerp(@grade_start_tone.gray,  @grade_target_tone.gray,  t)
    )

    if @grade_elapsed >= @grade_duration
      @grade_tone = @grade_target_tone.clone
      @grade_duration = 0
      @grade_elapsed = 0
    end
  end

  def self.apply_world_grade
    return if !$game_screen

    viewport = Spriteset_Map.viewport
    return if !viewport || viewport.disposed?

    source = $game_screen.tone

    viewport.tone = Tone.new(
      clamp_tone(source.red   + @grade_tone.red),
      clamp_tone(source.green + @grade_tone.green),
      clamp_tone(source.blue  + @grade_tone.blue),
      clamp_gray(source.gray  + @grade_tone.gray)
    )
  end

  def self.transition_vignette(opacity, duration)
    @vignette_start_opacity = @vignette_opacity
    @vignette_target_opacity = clamp_opacity(opacity).to_f
    @vignette_duration = [duration.to_i, 0].max
    @vignette_elapsed = 0
    @vignette_opacity = @vignette_target_opacity if @vignette_duration == 0
  end

  def self.update_vignette
    return if @vignette_duration <= 0

    @vignette_elapsed += 1
    t = eased_progress(@vignette_elapsed, @vignette_duration)

    @vignette_opacity =
      @vignette_start_opacity +
      (@vignette_target_opacity - @vignette_start_opacity) * t

    if @vignette_elapsed >= @vignette_duration
      @vignette_opacity = @vignette_target_opacity
      @vignette_duration = 0
      @vignette_elapsed = 0
    end
  end

  def self.transition_center_lift(opacity, duration)
    @center_lift_start_opacity = @center_lift_opacity
    @center_lift_target_opacity = clamp_opacity(opacity).to_f
    @center_lift_duration = [duration.to_i, 0].max
    @center_lift_elapsed = 0
    @center_lift_opacity = @center_lift_target_opacity if @center_lift_duration == 0
  end

  def self.update_center_lift
    return if @center_lift_duration <= 0

    @center_lift_elapsed += 1
    t = eased_progress(@center_lift_elapsed, @center_lift_duration)

    @center_lift_opacity =
      @center_lift_start_opacity +
      (@center_lift_target_opacity - @center_lift_start_opacity) * t

    if @center_lift_elapsed >= @center_lift_duration
      @center_lift_opacity = @center_lift_target_opacity
      @center_lift_duration = 0
      @center_lift_elapsed = 0
    end
  end

  def self.transition_depth(opacity, duration)
    @depth_start_opacity = @depth_opacity
    @depth_target_opacity = clamp_opacity(opacity).to_f
    @depth_duration = [duration.to_i, 0].max
    @depth_elapsed = 0
    @depth_opacity = @depth_target_opacity if @depth_duration == 0
  end

  def self.update_depth
    return if @depth_duration <= 0

    @depth_elapsed += 1
    t = eased_progress(@depth_elapsed, @depth_duration)

    @depth_opacity =
      @depth_start_opacity +
      (@depth_target_opacity - @depth_start_opacity) * t

    if @depth_elapsed >= @depth_duration
      @depth_opacity = @depth_target_opacity
      @depth_duration = 0
      @depth_elapsed = 0
    end
  end

  def self.apply_all
    apply_world_grade

    if @center_lift_sprite && !@center_lift_sprite.disposed?
      @center_lift_sprite.opacity = clamp_opacity(@center_lift_opacity)
      @center_lift_sprite.visible = (@center_lift_sprite.opacity > 0)
    end

    if @depth_sprite && !@depth_sprite.disposed?
      @depth_sprite.opacity = clamp_opacity(@depth_opacity)
      @depth_sprite.visible = (@depth_sprite.opacity > 0)
    end

    if @vignette_sprite && !@vignette_sprite.disposed?
      @vignette_sprite.opacity = clamp_opacity(@vignette_opacity)
      @vignette_sprite.visible = (@vignette_sprite.opacity > 0)
    end
  end

  def self.cache_ready?
    return false if !@vignette_bitmap || @vignette_bitmap.disposed?
    return false if !@center_lift_bitmap || @center_lift_bitmap.disposed?
    return false if !@depth_bitmap || @depth_bitmap.disposed?
    return true
  end

  def self.build_cache
    @vignette_bitmap = build_vignette_bitmap
    @center_lift_bitmap = build_center_lift_bitmap
    @depth_bitmap = build_depth_bitmap
  end

  def self.build_vignette_bitmap
    bitmap = Bitmap.new(Graphics.width, Graphics.height)

    width = Graphics.width
    height = Graphics.height

    edge_x = [width / 4, 1].max
    edge_y = [height / 4, 1].max

    for y in 0...height
      dy = [y, height - 1 - y].min
      y_strength = 1.0 - [dy.to_f / edge_y, 1.0].min

      for x in 0...width
        dx = [x, width - 1 - x].min
        x_strength = 1.0 - [dx.to_f / edge_x, 1.0].min

        strength = [x_strength, y_strength].max
        next if strength <= 0.0

        alpha = (strength * strength * 220).to_i
        bitmap.set_pixel(x, y, Color.new(255, 255, 255, alpha))
      end
    end

    return bitmap
  end

  def self.build_center_lift_bitmap
    bitmap = Bitmap.new(Graphics.width, Graphics.height)

    width = Graphics.width
    height = Graphics.height

    cx = width / 2.0
    cy = height * 0.46
    rx = width * 0.55
    ry = height * 0.52

    for y in 0...height
      ny = (y - cy) / ry

      for x in 0...width
        nx = (x - cx) / rx
        dist = Math.sqrt(nx * nx + ny * ny)

        strength = 1.0 - [dist, 1.0].min
        next if strength <= 0.0

        strength *= strength
        alpha = (strength * 40).to_i

        bitmap.set_pixel(x, y, Color.new(255, 255, 255, alpha))
      end
    end

    return bitmap
  end

  def self.build_depth_bitmap
    bitmap = Bitmap.new(Graphics.width, Graphics.height)

    width = Graphics.width
    height = Graphics.height

    for y in 0...height
      vertical = y.to_f / height
      lower = [vertical - 0.42, 0.0].max / 0.58
      lower = [lower, 1.0].min

      for x in 0...width
        center = (x - width / 2.0).abs / (width / 2.0)
        edge = [center - 0.45, 0.0].max / 0.55
        edge = [edge, 1.0].min

        strength = lower * 0.48 + edge * 0.30
        strength = [strength, 1.0].min

        alpha = (strength * 72).to_i
        next if alpha <= 0

        bitmap.set_pixel(x, y, Color.new(0, 0, 0, alpha))
      end
    end

    return bitmap
  end

  def self.eased_progress(elapsed, duration)
    return 1.0 if duration <= 0

    t = elapsed.to_f / duration.to_f
    t = 1.0 if t > 1.0

    return t * t * (3.0 - 2.0 * t)
  end

  def self.clamp_tone(value)
    return [[value.to_i, -255].max, 255].min
  end

  def self.clamp_gray(value)
    return [[value.to_i, 0].max, 255].min
  end

  def self.clamp_opacity(value)
    return [[value.to_i, 0].max, 255].min
  end

  def self.lerp(a, b, t)
    return (a + (b - a) * t).to_i
  end
end

Events.onSpritesetCreate += proc { |_sender, _spriteset, _viewport|
  BushidoPostFX.create
}

Events.onMapUpdate += proc { |_sender, _e|
  BushidoPostFX.update
}
