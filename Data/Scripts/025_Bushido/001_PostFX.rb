#===============================================================================
# Bushido PostFX
# Persistent overworld post-processing + map-native atmosphere
#
# Essentials v18.1 / RGSS1
#
# Important:
# - PostFX viewport persists across map transfers.
# - Map profiles crossfade instead of snapping.
# - Effects are cached and lightweight.
# - F6 toggles all Bushido PostFX.
#===============================================================================

module BushidoPostFX
  TOGGLE_KEY = Input::F6

  EZO_VILLAGE_MAP_ID = 79
  NAGISA_BAY_MAP_ID  = 81

  PROFILE_TRANSITION_FRAMES = 48
  TOGGLE_TRANSITION_FRAMES  = 24

  #-----------------------------------------------------------------------------
  # Default Bushido look
  #-----------------------------------------------------------------------------

  DEFAULT_TONE = Tone.new(-4, 0, 9, 0)

  DEFAULT_VIGNETTE_OPACITY = 72
  DEFAULT_VIGNETTE_COLOR   = Color.new(0, 2, 10)

  DEFAULT_CENTER_LIFT_OPACITY = 15
  DEFAULT_DEPTH_OPACITY       = 28

  #-----------------------------------------------------------------------------
  # Ezo Village
  #-----------------------------------------------------------------------------

  # Strong enough to visibly read during evaluation.
  EZO_CLOUD_OPACITY    = 74
  EZO_HAZE_OPACITY     = 24
  EZO_DAYLIGHT_OPACITY = 13

  #-----------------------------------------------------------------------------
  # Nagisa Bay
  #-----------------------------------------------------------------------------

  # Coastal clarity without turning the whole map blue.
  NAGISA_TONE = Tone.new(-4, 1, 13, 0)

  NAGISA_HAZE_OPACITY    = 22
  NAGISA_SHIMMER_OPACITY = 34
  NAGISA_COOL_OPACITY    = 10

  NAGISA_PARTICLE_COUNT   = 16
  NAGISA_PARTICLE_OPACITY = 170

  class << self
    attr_reader :enabled
    attr_reader :profile
  end

  #-----------------------------------------------------------------------------
  # Persistent render objects
  #-----------------------------------------------------------------------------

  @viewport = nil
  @particle_viewport = nil
  @created = false

  @vignette_sprite = nil
  @center_lift_sprite = nil
  @depth_sprite = nil

  @ezo_cloud_sprite = nil
  @ezo_haze_sprite = nil
  @ezo_daylight_sprite = nil

  @nagisa_haze_sprite = nil
  @nagisa_shimmer_sprite = nil
  @nagisa_cool_sprite = nil
  @nagisa_particles = []

  #-----------------------------------------------------------------------------
  # Cached bitmaps
  #-----------------------------------------------------------------------------

  @vignette_bitmap = nil
  @center_lift_bitmap = nil
  @depth_bitmap = nil

  @ezo_cloud_bitmap = nil
  @ezo_haze_bitmap = nil
  @ezo_daylight_bitmap = nil

  @nagisa_haze_bitmap = nil
  @nagisa_shimmer_bitmap = nil
  @nagisa_cool_bitmap = nil
  @nagisa_particle_bitmap = nil

  #-----------------------------------------------------------------------------
  # Global state
  #-----------------------------------------------------------------------------

  @enabled = true
  @profile = :DEFAULT
  @last_map_id = nil
  @frame = 0

  # Master on/off blend
  @master_strength = 1.0
  @master_start = 1.0
  @master_target = 1.0
  @master_duration = 0
  @master_elapsed = 0

  # Independent map blends.
  # These are what allow real crossfades.
  @ezo_strength = 0.0
  @ezo_start = 0.0
  @ezo_target = 0.0
  @ezo_duration = 0
  @ezo_elapsed = 0

  @nagisa_strength = 0.0
  @nagisa_start = 0.0
  @nagisa_target = 0.0
  @nagisa_duration = 0
  @nagisa_elapsed = 0

  # Grade transition
  @grade_tone = DEFAULT_TONE.clone
  @grade_start_tone = DEFAULT_TONE.clone
  @grade_target_tone = DEFAULT_TONE.clone
  @grade_duration = 0
  @grade_elapsed = 0

  #-----------------------------------------------------------------------------
  # Setup
  #-----------------------------------------------------------------------------

  def self.ensure_created
    return if @created &&
              @viewport &&
              !@viewport.disposed?

    build_cache unless cache_ready?
    create_viewports
    create_sprites
    create_particles

    @created = true
    detect_map(true)
    apply_all

    echoln("[BushidoPostFX] Persistent renderer created")
  end

  def self.create_viewports
    if @viewport && !@viewport.disposed?
      @viewport.dispose
    end

    if @particle_viewport && !@particle_viewport.disposed?
      @particle_viewport.dispose
    end

    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 450

    @particle_viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @particle_viewport.z = 451
  end

  def self.create_sprites
    @center_lift_sprite = Sprite.new(@viewport)
    @center_lift_sprite.bitmap = @center_lift_bitmap
    @center_lift_sprite.z = 5
    @center_lift_sprite.blend_type = 1

    @depth_sprite = Sprite.new(@viewport)
    @depth_sprite.bitmap = @depth_bitmap
    @depth_sprite.z = 10

    @ezo_haze_sprite = Sprite.new(@viewport)
    @ezo_haze_sprite.bitmap = @ezo_haze_bitmap
    @ezo_haze_sprite.z = 15
    @ezo_haze_sprite.blend_type = 1

    @ezo_daylight_sprite = Sprite.new(@viewport)
    @ezo_daylight_sprite.bitmap = @ezo_daylight_bitmap
    @ezo_daylight_sprite.z = 16
    @ezo_daylight_sprite.blend_type = 1

    @ezo_cloud_sprite = Sprite.new(@viewport)
    @ezo_cloud_sprite.bitmap = @ezo_cloud_bitmap
    @ezo_cloud_sprite.z = 17

    @nagisa_haze_sprite = Sprite.new(@viewport)
    @nagisa_haze_sprite.bitmap = @nagisa_haze_bitmap
    @nagisa_haze_sprite.z = 18
    @nagisa_haze_sprite.blend_type = 1

    @nagisa_cool_sprite = Sprite.new(@viewport)
    @nagisa_cool_sprite.bitmap = @nagisa_cool_bitmap
    @nagisa_cool_sprite.z = 19

    @nagisa_shimmer_sprite = Sprite.new(@viewport)
    @nagisa_shimmer_sprite.bitmap = @nagisa_shimmer_bitmap
    @nagisa_shimmer_sprite.z = 20
    @nagisa_shimmer_sprite.blend_type = 1

    @vignette_sprite = Sprite.new(@viewport)
    @vignette_sprite.bitmap = @vignette_bitmap
    @vignette_sprite.z = 40
    @vignette_sprite.color = DEFAULT_VIGNETTE_COLOR.clone
  end

  def self.create_particles
    @nagisa_particles.each do |data|
      dispose_sprite(data[:sprite]) if data
    end
    @nagisa_particles.clear

    NAGISA_PARTICLE_COUNT.times do
      sprite = Sprite.new(@particle_viewport)
      sprite.bitmap = @nagisa_particle_bitmap
      sprite.blend_type = 1

      data = {
        :sprite => sprite,
        :x => 0.0,
        :y => 0.0,
        :vx => 0.0,
        :vy => 0.0,
        :life => 0,
        :max_life => 1,
        :opacity => 0
      }

      reset_nagisa_particle(data, true)
      @nagisa_particles.push(data)
    end
  end

  #-----------------------------------------------------------------------------
  # Map detection / transitions
  #-----------------------------------------------------------------------------

  def self.detect_map(force = false)
    return if !$game_map

    map_id = $game_map.map_id
    return if !force && map_id == @last_map_id

    @last_map_id = map_id

    case map_id
    when EZO_VILLAGE_MAP_ID
      @profile = :EZO_VILLAGE
    when NAGISA_BAY_MAP_ID
      @profile = :NAGISA_BAY
    else
      @profile = :DEFAULT
    end

    duration = force ? 0 : PROFILE_TRANSITION_FRAMES

    # Independent targets = true crossfade.
    transition_ezo(@profile == :EZO_VILLAGE ? 1.0 : 0.0, duration)
    transition_nagisa(@profile == :NAGISA_BAY ? 1.0 : 0.0, duration)

    target_tone = DEFAULT_TONE.clone

    if @profile == :NAGISA_BAY
      target_tone = Tone.new(
        DEFAULT_TONE.red   + NAGISA_TONE.red,
        DEFAULT_TONE.green + NAGISA_TONE.green,
        DEFAULT_TONE.blue  + NAGISA_TONE.blue,
        0
      )
    end

    transition_grade(target_tone, duration)

    echoln("[BushidoPostFX] Map #{map_id} -> #{@profile}")
  end

  def self.transition_ezo(target, duration)
    @ezo_start = @ezo_strength
    @ezo_target = target.to_f
    @ezo_duration = [duration.to_i, 0].max
    @ezo_elapsed = 0
    @ezo_strength = @ezo_target if @ezo_duration == 0
  end

  def self.transition_nagisa(target, duration)
    @nagisa_start = @nagisa_strength
    @nagisa_target = target.to_f
    @nagisa_duration = [duration.to_i, 0].max
    @nagisa_elapsed = 0
    @nagisa_strength = @nagisa_target if @nagisa_duration == 0
  end

  def self.update_profile_transitions
    if @ezo_duration > 0
      @ezo_elapsed += 1
      t = eased_progress(@ezo_elapsed, @ezo_duration)
      @ezo_strength = @ezo_start + (@ezo_target - @ezo_start) * t

      if @ezo_elapsed >= @ezo_duration
        @ezo_strength = @ezo_target
        @ezo_duration = 0
        @ezo_elapsed = 0
      end
    end

    if @nagisa_duration > 0
      @nagisa_elapsed += 1
      t = eased_progress(@nagisa_elapsed, @nagisa_duration)
      @nagisa_strength =
        @nagisa_start + (@nagisa_target - @nagisa_start) * t

      if @nagisa_elapsed >= @nagisa_duration
        @nagisa_strength = @nagisa_target
        @nagisa_duration = 0
        @nagisa_elapsed = 0
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Toggle
  #-----------------------------------------------------------------------------

  def self.update_toggle
    toggle if Input.trigger?(TOGGLE_KEY)
  end

  def self.toggle
    @enabled = !@enabled
    transition_master(@enabled ? 1.0 : 0.0, TOGGLE_TRANSITION_FRAMES)

    echoln("[BushidoPostFX] #{@enabled ? 'ENABLED' : 'DISABLED'}")
  end

  def self.transition_master(target, duration)
    @master_start = @master_strength
    @master_target = target.to_f
    @master_duration = [duration.to_i, 0].max
    @master_elapsed = 0
    @master_strength = @master_target if @master_duration == 0
  end

  def self.update_master
    return if @master_duration <= 0

    @master_elapsed += 1
    t = eased_progress(@master_elapsed, @master_duration)

    @master_strength =
      @master_start +
      (@master_target - @master_start) * t

    if @master_elapsed >= @master_duration
      @master_strength = @master_target
      @master_duration = 0
      @master_elapsed = 0
    end
  end

  #-----------------------------------------------------------------------------
  # Grade
  #-----------------------------------------------------------------------------

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
      0
    )

    if @grade_elapsed >= @grade_duration
      @grade_tone = @grade_target_tone.clone
      @grade_duration = 0
      @grade_elapsed = 0
    end
  end

  #-----------------------------------------------------------------------------
  # Main update
  #-----------------------------------------------------------------------------

  def self.update
    ensure_created

    @frame += 1

    detect_map
    update_toggle
    update_master
    update_profile_transitions
    update_grade

    update_ezo_motion
    update_nagisa_motion
    update_nagisa_particles

    apply_all

    @viewport.update if @viewport && !@viewport.disposed?
    @particle_viewport.update if @particle_viewport && !@particle_viewport.disposed?
  end

  #-----------------------------------------------------------------------------
  # Ezo
  #-----------------------------------------------------------------------------

  def self.update_ezo_motion
    return if !@ezo_cloud_sprite || @ezo_cloud_sprite.disposed?

    # Faster than previous pass so movement is readable.
    @ezo_cloud_sprite.x = -80 + ((@frame / 2) % 160)
    @ezo_cloud_sprite.y = (Math.sin(@frame / 150.0) * 5).to_i
  end

  #-----------------------------------------------------------------------------
  # Nagisa
  #-----------------------------------------------------------------------------

  def self.update_nagisa_motion
    return if !@nagisa_shimmer_sprite || @nagisa_shimmer_sprite.disposed?

    @nagisa_shimmer_sprite.x = -24 + ((@frame / 3) % 48)
    @nagisa_shimmer_sprite.y = (Math.sin(@frame / 100.0) * 3).to_i
  end

  def self.reset_nagisa_particle(data, initial = false)
    sprite = data[:sprite]

    data[:x] = rand(Graphics.width + 40) - 20
    data[:y] = initial ? rand(Graphics.height + 20) : Graphics.height + rand(28)

    data[:vx] = 0.25 + rand(30) / 100.0
    data[:vy] = -(0.45 + rand(45) / 100.0)

    data[:max_life] = 80 + rand(100)
    data[:life] = initial ? rand(data[:max_life]) : 0
    data[:opacity] = 90 + rand(NAGISA_PARTICLE_OPACITY - 89)

    sprite.x = data[:x].to_i
    sprite.y = data[:y].to_i
    sprite.opacity = 0
    sprite.visible = false
  end

  def self.update_nagisa_particles
    strength = @nagisa_strength * @master_strength

    @nagisa_particles.each do |data|
      sprite = data[:sprite]
      next if !sprite || sprite.disposed?

      if strength <= 0.001
        sprite.visible = false
        next
      end

      data[:life] += 1

      if data[:life] >= data[:max_life]
        reset_nagisa_particle(data)
      end

      data[:x] += data[:vx]
      data[:y] += data[:vy]
      data[:x] += Math.sin((@frame + data[:life]) / 20.0) * 0.12

      sprite.x = data[:x].to_i
      sprite.y = data[:y].to_i

      progress = data[:life].to_f / data[:max_life]

      fade = 1.0
      fade = progress / 0.15 if progress < 0.15
      fade = (1.0 - progress) / 0.22 if progress > 0.78
      fade = [[fade, 0.0].max, 1.0].min

      sprite.opacity =
        clamp_opacity(data[:opacity] * fade * strength)

      sprite.visible = sprite.opacity > 0

      if data[:y] < -12 || data[:x] > Graphics.width + 20
        reset_nagisa_particle(data)
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Apply
  #-----------------------------------------------------------------------------

  def self.apply_all
    apply_world_grade

    master = @master_strength

    if @center_lift_sprite && !@center_lift_sprite.disposed?
      @center_lift_sprite.opacity =
        clamp_opacity(DEFAULT_CENTER_LIFT_OPACITY * master)
    end

    if @depth_sprite && !@depth_sprite.disposed?
      @depth_sprite.opacity =
        clamp_opacity(DEFAULT_DEPTH_OPACITY * master)
    end

    if @vignette_sprite && !@vignette_sprite.disposed?
      @vignette_sprite.opacity =
        clamp_opacity(DEFAULT_VIGNETTE_OPACITY * master)
    end

    apply_ezo(master)
    apply_nagisa(master)
  end

  def self.apply_world_grade
    return if !$game_screen

    viewport = Spriteset_Map.viewport
    return if !viewport || viewport.disposed?

    source = $game_screen.tone
    master = @master_strength

    viewport.tone = Tone.new(
      clamp_tone(source.red   + @grade_tone.red   * master),
      clamp_tone(source.green + @grade_tone.green * master),
      clamp_tone(source.blue  + @grade_tone.blue  * master),
      clamp_gray(source.gray)
    )
  end

  def self.apply_ezo(master)
    strength = @ezo_strength * master

    if @ezo_haze_sprite && !@ezo_haze_sprite.disposed?
      @ezo_haze_sprite.opacity =
        clamp_opacity(EZO_HAZE_OPACITY * strength)
      @ezo_haze_sprite.visible = @ezo_haze_sprite.opacity > 0
    end

    if @ezo_daylight_sprite && !@ezo_daylight_sprite.disposed?
      breathe = 1.0 + Math.sin(@frame / 120.0) * 0.25

      @ezo_daylight_sprite.opacity =
        clamp_opacity(EZO_DAYLIGHT_OPACITY * strength * breathe)

      @ezo_daylight_sprite.visible =
        @ezo_daylight_sprite.opacity > 0
    end

    if @ezo_cloud_sprite && !@ezo_cloud_sprite.disposed?
      breathe = 0.88 + Math.sin(@frame / 170.0) * 0.12

      @ezo_cloud_sprite.opacity =
        clamp_opacity(EZO_CLOUD_OPACITY * strength * breathe)

      @ezo_cloud_sprite.visible =
        @ezo_cloud_sprite.opacity > 0
    end
  end

  def self.apply_nagisa(master)
    strength = @nagisa_strength * master

    if @nagisa_haze_sprite && !@nagisa_haze_sprite.disposed?
      @nagisa_haze_sprite.opacity =
        clamp_opacity(NAGISA_HAZE_OPACITY * strength)
      @nagisa_haze_sprite.visible = @nagisa_haze_sprite.opacity > 0
    end

    if @nagisa_cool_sprite && !@nagisa_cool_sprite.disposed?
      @nagisa_cool_sprite.opacity =
        clamp_opacity(NAGISA_COOL_OPACITY * strength)
      @nagisa_cool_sprite.visible = @nagisa_cool_sprite.opacity > 0
    end

    if @nagisa_shimmer_sprite && !@nagisa_shimmer_sprite.disposed?
      breathe = 0.80 + Math.sin(@frame / 85.0) * 0.20

      @nagisa_shimmer_sprite.opacity =
        clamp_opacity(NAGISA_SHIMMER_OPACITY * strength * breathe)

      @nagisa_shimmer_sprite.visible =
        @nagisa_shimmer_sprite.opacity > 0
    end
  end

  #-----------------------------------------------------------------------------
  # Cache
  #-----------------------------------------------------------------------------

  def self.cache_ready?
    bitmaps = [
      @vignette_bitmap,
      @center_lift_bitmap,
      @depth_bitmap,
      @ezo_cloud_bitmap,
      @ezo_haze_bitmap,
      @ezo_daylight_bitmap,
      @nagisa_haze_bitmap,
      @nagisa_shimmer_bitmap,
      @nagisa_cool_bitmap,
      @nagisa_particle_bitmap
    ]

    bitmaps.each do |bitmap|
      return false if !bitmap || bitmap.disposed?
    end

    return true
  end

  def self.build_cache
    @vignette_bitmap = build_vignette_bitmap
    @center_lift_bitmap = build_center_lift_bitmap
    @depth_bitmap = build_depth_bitmap

    build_ezo_cache
    build_nagisa_cache
  end

  #-----------------------------------------------------------------------------
  # Default graphics
  #-----------------------------------------------------------------------------

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

        bitmap.set_pixel(
          x, y,
          Color.new(255, 255, 255, alpha)
        )
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

        bitmap.set_pixel(
          x, y,
          Color.new(255, 255, 255, alpha)
        )
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
        center =
          (x - width / 2.0).abs / (width / 2.0)

        edge =
          [center - 0.45, 0.0].max / 0.55

        edge = [edge, 1.0].min

        strength =
          lower * 0.48 +
          edge * 0.30

        strength = [strength, 1.0].min

        alpha = (strength * 72).to_i
        next if alpha <= 0

        bitmap.set_pixel(
          x, y,
          Color.new(0, 0, 0, alpha)
        )
      end
    end

    return bitmap
  end

  #-----------------------------------------------------------------------------
  # Ezo graphics
  #-----------------------------------------------------------------------------

  def self.build_ezo_cache
    width = Graphics.width + 160
    height = Graphics.height + 30

    @ezo_cloud_bitmap = Bitmap.new(width, height)

    outer = Color.new(4, 9, 18, 30)
    middle = Color.new(4, 9, 18, 48)
    inner = Color.new(4, 9, 18, 68)

    clouds = [
      [-10, 30, 150, 52],
      [104, 8, 190, 66],
      [260, 42, 154, 48],
      [380, 12, 194, 64],
      [538, 36, 158, 52]
    ]

    clouds.each do |c|
      x, y, w, h = c

      @ezo_cloud_bitmap.fill_rect(
        x, y + 10, w, h - 20, outer
      )

      @ezo_cloud_bitmap.fill_rect(
        x + 14, y + 5, w - 28, h - 10, middle
      )

      @ezo_cloud_bitmap.fill_rect(
        x + 30, y + 12, w - 60, h - 24, inner
      )
    end

    @ezo_haze_bitmap =
      Bitmap.new(Graphics.width, Graphics.height)

    half = [Graphics.height / 2, 1].max

    for y in 0...half
      t = 1.0 - y.to_f / half
      alpha = (t * t * 54).to_i

      @ezo_haze_bitmap.fill_rect(
        0, y,
        Graphics.width, 1,
        Color.new(220, 235, 250, alpha)
      )
    end

    @ezo_daylight_bitmap =
      Bitmap.new(Graphics.width, Graphics.height)

    @ezo_daylight_bitmap.fill_rect(
      0, 0,
      Graphics.width,
      Graphics.height,
      Color.new(232, 242, 255, 255)
    )
  end

  #-----------------------------------------------------------------------------
  # Nagisa graphics
  #-----------------------------------------------------------------------------

  def self.build_nagisa_cache
    width = Graphics.width
    height = Graphics.height

    @nagisa_haze_bitmap =
      Bitmap.new(width, height)

    horizon = height * 0.58

    for y in 0...horizon.to_i
      t = 1.0 - y.to_f / horizon
      alpha = (t * t * 52).to_i

      @nagisa_haze_bitmap.fill_rect(
        0, y,
        width, 1,
        Color.new(205, 232, 250, alpha)
      )
    end

    @nagisa_cool_bitmap =
      Bitmap.new(width, height)

    @nagisa_cool_bitmap.fill_rect(
      0, 0,
      width, height,
      Color.new(200, 226, 255, 255)
    )

    @nagisa_shimmer_bitmap =
      Bitmap.new(width + 48, height)

    bright = Color.new(230, 249, 255, 74)
    soft = Color.new(215, 242, 255, 38)

    y = 14
    row = 0

    while y < height - 4
      offset = (row % 2) * 26
      x = -20 + offset

      while x < width + 48
        length =
          20 + ((x + y + row * 11).abs % 34)

        @nagisa_shimmer_bitmap.fill_rect(
          x, y,
          length, 1,
          bright
        )

        @nagisa_shimmer_bitmap.fill_rect(
          x + 8, y + 2,
          [length - 16, 4].max, 1,
          soft
        )

        x += 62 + ((x + row * 17).abs % 36)
      end

      y += 21 + (row % 3) * 5
      row += 1
    end

    @nagisa_particle_bitmap =
      Bitmap.new(5, 5)

    @nagisa_particle_bitmap.set_pixel(
      2, 0,
      Color.new(225, 245, 255, 70)
    )

    @nagisa_particle_bitmap.set_pixel(
      1, 1,
      Color.new(235, 250, 255, 105)
    )

    @nagisa_particle_bitmap.set_pixel(
      2, 1,
      Color.new(255, 255, 255, 185)
    )

    @nagisa_particle_bitmap.set_pixel(
      3, 1,
      Color.new(235, 250, 255, 105)
    )

    @nagisa_particle_bitmap.set_pixel(
      0, 2,
      Color.new(225, 245, 255, 60)
    )

    @nagisa_particle_bitmap.set_pixel(
      1, 2,
      Color.new(245, 252, 255, 150)
    )

    @nagisa_particle_bitmap.set_pixel(
      2, 2,
      Color.new(255, 255, 255, 255)
    )

    @nagisa_particle_bitmap.set_pixel(
      3, 2,
      Color.new(245, 252, 255, 150)
    )

    @nagisa_particle_bitmap.set_pixel(
      4, 2,
      Color.new(225, 245, 255, 60)
    )

    @nagisa_particle_bitmap.set_pixel(
      1, 3,
      Color.new(235, 250, 255, 105)
    )

    @nagisa_particle_bitmap.set_pixel(
      2, 3,
      Color.new(255, 255, 255, 185)
    )

    @nagisa_particle_bitmap.set_pixel(
      3, 3,
      Color.new(235, 250, 255, 105)
    )

    @nagisa_particle_bitmap.set_pixel(
      2, 4,
      Color.new(225, 245, 255, 70)
    )
  end

  #-----------------------------------------------------------------------------
  # Helpers
  #-----------------------------------------------------------------------------

  def self.dispose_sprite(sprite)
    return if !sprite
    sprite.dispose unless sprite.disposed?
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

# The renderer is persistent. Spriteset creation just ensures it exists.
Events.onSpritesetCreate += proc { |_sender, _spriteset, _viewport|
  BushidoPostFX.ensure_created
}

Events.onMapUpdate += proc { |_sender, _e|
  BushidoPostFX.update
}
