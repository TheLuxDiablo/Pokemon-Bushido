module BushidoPostFX
  TOGGLE_KEY = Input::F6

  EZO_VILLAGE_MAP_ID = 79
  NAGISA_BAY_MAP_ID  = 81
  SAKURA_PASS_MAP_ID = 82
  SHIZEN_TRAIL_MAP_ID = 90

  PROFILE_TRANSITION_FRAMES = 48
  TOGGLE_TRANSITION_FRAMES  = 24

  DEFAULT_TONE = Tone.new(5, 1, -5, 4)

  DEFAULT_VIGNETTE_OPACITY = 72
  DEFAULT_VIGNETTE_COLOR   = Color.new(0, 2, 10)

  DEFAULT_CENTER_LIFT_OPACITY = 18
  DEFAULT_DEPTH_OPACITY       = 32

  INK_STYLE_ENABLED = true

  DEFAULT_WARM_WASH_OPACITY  = 24
  DEFAULT_COOL_WASH_OPACITY  = 18
  DEFAULT_PRINT_GRAIN_OPACITY = 22

  WASH_DRIFT_SPEED = 0.0025

  EZO_CLOUD_OPACITY    = 62
  EZO_HAZE_OPACITY     = 24
  EZO_DAYLIGHT_OPACITY = 11

  NAGISA_TONE = Tone.new(-2, 1, 7, 0)

  NAGISA_HAZE_OPACITY    = 22
  NAGISA_SHIMMER_OPACITY = 34
  NAGISA_COOL_OPACITY    = 6

  NAGISA_PARTICLE_COUNT   = 26
  NAGISA_PARTICLE_OPACITY = 205

  SAKURA_PETAL_COUNT        = 198
  SAKURA_SPAWN_INTERVAL_MIN = 1
  SAKURA_SPAWN_INTERVAL_MAX = 1
  SAKURA_PETAL_OPACITY      = 235
  SAKURA_GUST_INTERVAL_MIN  = 0
  SAKURA_GUST_INTERVAL_MAX  = 120
  SAKURA_GUST_PETALS        = 14

  SHIZEN_LEAF_COUNT          = 12
  SHIZEN_LEAF_OPACITY        = 255
  SHIZEN_LEAF_SPAWN_MIN      = 52
  SHIZEN_LEAF_SPAWN_MAX      = 100
  SHIZEN_GUST_INTERVAL_MIN   = 240
  SHIZEN_GUST_INTERVAL_MAX   = 420
  SHIZEN_GUST_LEAVES         = 3

  SHIZEN_TRANSITION_FRAMES   = 48

  class << self
    attr_reader :enabled
    attr_reader :profile
  end

  @viewport = nil
  @particle_viewport = nil
  @created = false

  @vignette_sprite = nil
  @center_lift_sprite = nil
  @depth_sprite = nil

  @warm_wash_sprite = nil
  @cool_wash_sprite = nil
  @print_grain_sprite = nil

  @ezo_cloud_sprite = nil
  @ezo_haze_sprite = nil
  @ezo_daylight_sprite = nil

  @nagisa_haze_sprite = nil
  @nagisa_shimmer_sprite = nil
  @nagisa_cool_sprite = nil
  @nagisa_particles = []

  @sakura_particles = []
  @shizen_leaves = []

  @vignette_bitmap = nil
  @center_lift_bitmap = nil
  @depth_bitmap = nil

  @warm_wash_bitmap = nil
  @cool_wash_bitmap = nil
  @print_grain_bitmap = nil

  @ezo_cloud_bitmap = nil
  @ezo_haze_bitmap = nil
  @ezo_daylight_bitmap = nil

  @nagisa_haze_bitmap = nil
  @nagisa_shimmer_bitmap = nil
  @nagisa_cool_bitmap = nil
  @nagisa_particle_bitmap = nil
  @sakura_petal_bitmaps = []
  @shizen_leaf_bitmaps = []

  @enabled = true
  @profile = :DEFAULT
  @last_map_id = nil
  @frame = 0

  @sakura_spawning = false
  @sakura_spawn_timer = 0
  @sakura_gust_timer = 120

  @shizen_leaf_spawn_timer = 0
  @shizen_gust_timer = 210

  @master_strength = 1.0
  @master_start = 1.0
  @master_target = 1.0
  @master_duration = 0
  @master_elapsed = 0

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

  @shizen_strength = 0.0
  @shizen_start = 0.0
  @shizen_target = 0.0
  @shizen_duration = 0
  @shizen_elapsed = 0

  @grade_tone = DEFAULT_TONE.clone
  @grade_start_tone = DEFAULT_TONE.clone
  @grade_target_tone = DEFAULT_TONE.clone
  @grade_duration = 0
  @grade_elapsed = 0

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

    @warm_wash_sprite = Sprite.new(@viewport)
    @warm_wash_sprite.bitmap = @warm_wash_bitmap
    @warm_wash_sprite.z = 11
    @warm_wash_sprite.blend_type = 1

    @cool_wash_sprite = Sprite.new(@viewport)
    @cool_wash_sprite.bitmap = @cool_wash_bitmap
    @cool_wash_sprite.z = 12
    @cool_wash_sprite.blend_type = 0

    @print_grain_sprite = Sprite.new(@viewport)
    @print_grain_sprite.bitmap = @print_grain_bitmap
    @print_grain_sprite.z = 13
    @print_grain_sprite.blend_type = 0

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
    @ezo_cloud_sprite.zoom_x = 2.0
    @ezo_cloud_sprite.zoom_y = 2.0

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

    @sakura_particles.each do |data|
      dispose_sprite(data[:sprite]) if data
    end
    @sakura_particles.clear

    NAGISA_PARTICLE_COUNT.times do
      sprite = Sprite.new(@particle_viewport)
      sprite.bitmap = @nagisa_particle_bitmap
      sprite.blend_type = 1

      data = {
        :sprite => sprite,
        :map_id => 0,
        :tile_x => 0,
        :tile_y => 0,
        :local_x => 0.0,
        :local_y => 0.0,
        :offset_x => 0.0,
        :offset_y => 0.0,
        :drift_x => 0.0,
        :drift_y => 0.0,
        :life => 0,
        :max_life => 1,
        :opacity => 0,
        :scale => 1.0,
        :active => false,
        :retry => 0
      }

      reset_nagisa_particle(data, true)
      @nagisa_particles.push(data)
    end

    create_sakura_particles
    create_shizen_particles
  end

  def self.create_sakura_particles
    @sakura_particles.each do |data|
      dispose_sprite(data[:sprite]) if data
    end
    @sakura_particles.clear

    SAKURA_PETAL_COUNT.times do
      sprite = Sprite.new(@particle_viewport)
      sprite.visible = false

      data = {
        :sprite => sprite,
        :active => false,
        :map_id => SAKURA_PASS_MAP_ID,
        :world_x => 0.0,
        :world_y => 0.0,
        :vx => 0.0,
        :vy => 0.0,
        :phase => 0.0,
        :phase_speed => 0.0,
        :life => 0,
        :max_life => 1,
        :opacity => SAKURA_PETAL_OPACITY,
        :bitmap_index => 0,
        :scale => 1.0,
        :depth => 1
      }

      @sakura_particles.push(data)
    end

    @sakura_spawn_timer = 0
  @sakura_gust_timer = 120
  end

  def self.reset_sakura_particle(data, from_top = true)
    sprite = data[:sprite]
    return if !$game_map

    display_x = ($game_map.display_x / Game_Map::X_SUBPIXELS).round
    display_y = ($game_map.display_y / Game_Map::Y_SUBPIXELS).round

    data[:map_id] = $game_map.map_id

    data[:world_x] =
      display_x +
      rand(Graphics.width + 120) -
      60

    if from_top
      data[:world_y] =
        display_y -
        16 -
        rand(52)
    else
      data[:world_y] =
        display_y +
        rand(Graphics.height)
    end

    data[:depth] = rand(3)

    case data[:depth]
    when 0
      data[:vx] = 0.20 + rand(26) / 100.0
      data[:vy] = 0.48 + rand(34) / 100.0
      data[:scale] = 0.78 + rand(22) / 100.0
      data[:opacity] = 125 + rand(55)
    when 1
      data[:vx] = 0.28 + rand(34) / 100.0
      data[:vy] = 0.62 + rand(40) / 100.0
      data[:scale] = 1.00 + rand(34) / 100.0
      data[:opacity] = 165 + rand(55)
    else
      data[:vx] = 0.36 + rand(42) / 100.0
      data[:vy] = 0.78 + rand(46) / 100.0
      data[:scale] = 1.28 + rand(38) / 100.0
      data[:opacity] = 195 + rand(SAKURA_PETAL_OPACITY - 194)
    end

    data[:phase] = rand(628) / 100.0
    data[:phase_speed] = 0.030 + rand(50) / 1000.0

    data[:max_life] = 520 + rand(220)
    data[:life] = 0
    data[:bitmap_index] = rand(@sakura_petal_bitmaps.length)

    sprite.bitmap = @sakura_petal_bitmaps[data[:bitmap_index]]
    sprite.zoom_x = data[:scale]
    sprite.zoom_y = data[:scale]
    sprite.opacity = 0
    sprite.visible = true

    data[:active] = true
  end

  def self.update_sakura_particles
    on_sakura =
      ($game_map && $game_map.map_id == SAKURA_PASS_MAP_ID)

    @sakura_spawning =
      on_sakura &&
      @enabled

    if @sakura_spawning
      @sakura_spawn_timer -= 1
      @sakura_gust_timer -= 1

      if @sakura_spawn_timer <= 0
        inactive =
          @sakura_particles.find { |p| !p[:active] }

        reset_sakura_particle(inactive, true) if inactive

        range =
          SAKURA_SPAWN_INTERVAL_MAX -
          SAKURA_SPAWN_INTERVAL_MIN +
          1

        @sakura_spawn_timer =
          SAKURA_SPAWN_INTERVAL_MIN +
          rand([range, 1].max)
      end

      if @sakura_gust_timer <= 0
        spawned = 0

        @sakura_particles.each do |particle|
          next if particle[:active]

          reset_sakura_particle(particle, true)

          particle[:world_y] -= rand(70)
          particle[:vx] += 0.10 + rand(14) / 100.0

          spawned += 1
          break if spawned >= SAKURA_GUST_PETALS
        end

        gust_range =
          SAKURA_GUST_INTERVAL_MAX -
          SAKURA_GUST_INTERVAL_MIN +
          1

        @sakura_gust_timer =
          SAKURA_GUST_INTERVAL_MIN +
          rand([gust_range, 1].max)
      end
    end

    @sakura_particles.each do |data|
      next if !data[:active]

      sprite = data[:sprite]
      next if !sprite || sprite.disposed?

      data[:life] += 1
      data[:phase] += data[:phase_speed]

      sway_strength =
        (data[:depth] == 2) ? 0.62 :
        (data[:depth] == 1) ? 0.48 :
                              0.34

      sway = Math.sin(data[:phase]) * sway_strength
      flutter = Math.sin(data[:phase] * 2.7) * 0.16

      data[:world_x] += data[:vx] + sway * 0.12
      data[:world_y] += data[:vy] + flutter

      if $game_map && data[:map_id] == $game_map.map_id
        display_x =
          ($game_map.display_x / Game_Map::X_SUBPIXELS).round

        display_y =
          ($game_map.display_y / Game_Map::Y_SUBPIXELS).round

        screen_x =
          data[:world_x] -
          display_x

        screen_y =
          data[:world_y] -
          display_y
      elsif $MapFactory
        pos = $MapFactory.getRelativePos(
          $game_map.map_id,
          0,
          0,
          data[:map_id],
          0,
          0
        )

        display_x =
          ($game_map.display_x / Game_Map::X_SUBPIXELS).round

        display_y =
          ($game_map.display_y / Game_Map::Y_SUBPIXELS).round

        screen_x =
          (pos[0] * Game_Map::TILE_WIDTH) +
          data[:world_x] -
          display_x

        screen_y =
          (pos[1] * Game_Map::TILE_HEIGHT) +
          data[:world_y] -
          display_y
      else
        sprite.visible = false
        next
      end

      sprite.x = screen_x.to_i
      sprite.y = screen_y.to_i

      flip = Math.sin(data[:phase] * 1.8)

      sprite.zoom_x =
        data[:scale] *
        (0.68 + flip.abs * 0.32)

      sprite.zoom_y =
        data[:scale]

      progress =
        data[:life].to_f /
        data[:max_life]

      fade = 1.0

      if progress < 0.08
        fade = progress / 0.08
      end

      fade =
        [[fade, 0.0].max, 1.0].min

      sprite.opacity =
        clamp_opacity(
          data[:opacity] *
          fade *
          @master_strength
        )

      on_screen =
        screen_x >= -96 &&
        screen_y >= -96 &&
        screen_x <= Graphics.width + 96 &&
        screen_y <= Graphics.height + 96

      sprite.visible =
        sprite.opacity > 0 &&
        on_screen

      if data[:life] >= data[:max_life] ||
         screen_y > Graphics.height + 260 ||
         screen_x > Graphics.width + 300 ||
         screen_x < -300
        data[:active] = false
        sprite.visible = false
      end
    end
  end

  def self.create_shizen_particles
    @shizen_leaves.each do |data|
      dispose_sprite(data[:sprite]) if data
    end
    @shizen_leaves.clear

    SHIZEN_LEAF_COUNT.times do
      sprite = Sprite.new(@particle_viewport)
      sprite.visible = false

      @shizen_leaves.push({
        :sprite => sprite,
        :active => false,
        :x => 0.0,
        :y => 0.0,
        :vx => 0.0,
        :vy => 0.0,
        :phase => 0.0,
        :phase_speed => 0.0,
        :spin => 0.0,
        :spin_speed => 0.0,
        :life => 0,
        :max_life => 1,
        :opacity => SHIZEN_LEAF_OPACITY,
        :bitmap_index => 0,
        :scale => 1.0
      })
    end

    @shizen_leaf_spawn_timer = 18
    @shizen_gust_timer = 210
  end

  def self.reset_shizen_leaf(data, gust = false)
    return if !data

    sprite = data[:sprite]
    return if !sprite || sprite.disposed?

    data[:bitmap_index] = rand(@shizen_leaf_bitmaps.length)
    sprite.bitmap = @shizen_leaf_bitmaps[data[:bitmap_index]]

    sprite.ox = sprite.bitmap.width / 2
    sprite.oy = sprite.bitmap.height / 2

    data[:x] = -28 - rand(80)
    data[:y] = 16 + rand([Graphics.height - 32, 1].max)

    if gust
      data[:vx] = 2.15 + rand(96) / 100.0
      data[:vy] = -0.18 + rand(43) / 100.0
    else
      data[:vx] = 1.35 + rand(91) / 100.0
      data[:vy] = -0.12 + rand(35) / 100.0
    end

    data[:phase] = rand(628) / 100.0
    data[:phase_speed] = 0.045 + rand(36) / 1000.0

    data[:spin] = rand(360).to_f
    spin_dir = rand(2) == 0 ? -1.0 : 1.0
    data[:spin_speed] = spin_dir * (1.25 + rand(176) / 100.0)

    data[:max_life] = 250 + rand(130)
    data[:life] = 0
    data[:opacity] = 245 + rand(11)
    data[:scale] = 1.35 + rand(51) / 100.0

    sprite.zoom_x = data[:scale]
    sprite.zoom_y = data[:scale]
    sprite.angle = data[:spin]
    sprite.opacity = 0
    sprite.visible = true
    data[:active] = true
  end

  def self.update_shizen_particles
    on_shizen = ($game_map && $game_map.map_id == SHIZEN_TRAIL_MAP_ID)

    if on_shizen && @enabled
      @shizen_leaf_spawn_timer -= 1
      @shizen_gust_timer -= 1

      if @shizen_leaf_spawn_timer <= 0
        inactive = @shizen_leaves.find { |p| !p[:active] }
        reset_shizen_leaf(inactive, false) if inactive

        range = SHIZEN_LEAF_SPAWN_MAX - SHIZEN_LEAF_SPAWN_MIN + 1
        @shizen_leaf_spawn_timer = SHIZEN_LEAF_SPAWN_MIN + rand([range, 1].max)
      end

      if @shizen_gust_timer <= 0
        spawned = 0

        @shizen_leaves.each do |leaf|
          next if leaf[:active]
          reset_shizen_leaf(leaf, true)
          leaf[:x] -= rand(90)
          leaf[:y] += rand(64) - 32
          spawned += 1
          break if spawned >= SHIZEN_GUST_LEAVES
        end

        range = SHIZEN_GUST_INTERVAL_MAX - SHIZEN_GUST_INTERVAL_MIN + 1
        @shizen_gust_timer = SHIZEN_GUST_INTERVAL_MIN + rand([range, 1].max)
      end
    end

    strength = @shizen_strength * @master_strength

    @shizen_leaves.each do |data|
      sprite = data[:sprite]
      next if !sprite || sprite.disposed?

      if !data[:active]
        sprite.visible = false
        next
      end

      data[:life] += 1
      data[:phase] += data[:phase_speed]
      data[:spin] += data[:spin_speed]

      sway = Math.sin(data[:phase]) * 0.42
      flutter = Math.sin(data[:phase] * 2.4) * 0.16

      data[:x] += data[:vx] + Math.cos(data[:phase] * 0.75) * 0.08
      data[:y] += data[:vy] + sway + flutter

      sprite.x = data[:x].to_i
      sprite.y = data[:y].to_i
      sprite.angle = data[:spin]

      flip = Math.sin(data[:phase] * 2.0)
      edge = flip.abs
      sprite.zoom_x = data[:scale] * (0.34 + edge * 0.66)
      sprite.zoom_y = data[:scale] * (0.94 + Math.cos(data[:phase]) * 0.06)

      progress = data[:life].to_f / data[:max_life]
      life_fade = 1.0
      life_fade = progress / 0.08 if progress < 0.08
      life_fade = (1.0 - progress) / 0.12 if progress > 0.88
      life_fade = [[life_fade, 0.0].max, 1.0].min

      sprite.opacity = clamp_opacity(data[:opacity] * life_fade * strength)
      sprite.visible = sprite.opacity > 0

      if data[:life] >= data[:max_life] ||
         data[:x] > Graphics.width + 64 ||
         data[:y] < -64 ||
         data[:y] > Graphics.height + 64
        data[:active] = false
        sprite.visible = false
      end
    end
  end

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
    when SAKURA_PASS_MAP_ID
      @profile = :SAKURA_PASS
    when SHIZEN_TRAIL_MAP_ID
      @profile = :SHIZEN_TRAIL
    else
      @profile = :DEFAULT
    end

    duration = force ? 0 : PROFILE_TRANSITION_FRAMES

    transition_ezo(@profile == :EZO_VILLAGE ? 1.0 : 0.0, duration)
    transition_nagisa(@profile == :NAGISA_BAY ? 1.0 : 0.0, duration)
    transition_shizen(@profile == :SHIZEN_TRAIL ? 1.0 : 0.0,
                      force ? 0 : SHIZEN_TRANSITION_FRAMES)

    target_tone = DEFAULT_TONE.clone

    if @profile == :NAGISA_BAY
      target_tone = Tone.new(
        DEFAULT_TONE.red   + NAGISA_TONE.red,
        DEFAULT_TONE.green + NAGISA_TONE.green,
        DEFAULT_TONE.blue  + NAGISA_TONE.blue,
        DEFAULT_TONE.gray + NAGISA_TONE.gray
      )
    end

    transition_grade(target_tone, duration)

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

  def self.transition_shizen(target, duration)
    @shizen_start = @shizen_strength
    @shizen_target = target.to_f
    @shizen_duration = [duration.to_i, 0].max
    @shizen_elapsed = 0
    @shizen_strength = @shizen_target if @shizen_duration == 0
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

    if @shizen_duration > 0
      @shizen_elapsed += 1
      t = eased_progress(@shizen_elapsed, @shizen_duration)
      @shizen_strength =
        @shizen_start + (@shizen_target - @shizen_start) * t

      if @shizen_elapsed >= @shizen_duration
        @shizen_strength = @shizen_target
        @shizen_duration = 0
        @shizen_elapsed = 0
      end
    end
  end

  def self.update_toggle
    toggle if Input.trigger?(TOGGLE_KEY)
  end

  def self.toggle
    @enabled = !@enabled
    transition_master(@enabled ? 1.0 : 0.0, TOGGLE_TRANSITION_FRAMES)

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

  def self.update
    ensure_created

    @frame += 1

    detect_map
    update_toggle
    update_master
    update_profile_transitions
    update_grade
    update_ink_style

    update_ezo_motion
    update_nagisa_motion
    update_nagisa_particles
    update_sakura_particles
    update_shizen_particles

    apply_all

    @viewport.update if @viewport && !@viewport.disposed?
    @particle_viewport.update if @particle_viewport && !@particle_viewport.disposed?
  end

  def self.update_ink_style
    return if !INK_STYLE_ENABLED

    if @warm_wash_sprite && !@warm_wash_sprite.disposed?
      @warm_wash_sprite.x =
        -80 + (Math.sin(@frame * WASH_DRIFT_SPEED) * 18).to_i
      @warm_wash_sprite.y =
        -60 + (Math.cos(@frame * WASH_DRIFT_SPEED * 0.73) * 10).to_i
    end

    if @cool_wash_sprite && !@cool_wash_sprite.disposed?
      @cool_wash_sprite.x =
        -90 + (Math.cos(@frame * WASH_DRIFT_SPEED * 0.61) * 15).to_i
      @cool_wash_sprite.y =
        -70 + (Math.sin(@frame * WASH_DRIFT_SPEED * 0.82) * 8).to_i
    end

    if @print_grain_sprite && !@print_grain_sprite.disposed?
      @print_grain_sprite.x = 0
      @print_grain_sprite.y = 0
    end
  end

  def self.update_ezo_motion
    return if !@ezo_cloud_sprite || @ezo_cloud_sprite.disposed?

    @ezo_cloud_sprite.x = -120 + ((@frame / 2) % 240)
    @ezo_cloud_sprite.y = (Math.sin(@frame / 150.0) * 6).to_i
  end

  def self.update_nagisa_motion
    return if !@nagisa_shimmer_sprite || @nagisa_shimmer_sprite.disposed?

    @nagisa_shimmer_sprite.x = -24 + ((@frame / 3) % 48)
    @nagisa_shimmer_sprite.y = (Math.sin(@frame / 100.0) * 3).to_i
  end

  def self.water_tile?(map_id, x, y)
    return false if !$MapFactory

    map = nil

    for candidate in $MapFactory.maps
      next if !candidate
      if candidate.map_id == map_id
        map = candidate
        break
      end
    end

    return false if !map
    return false if x < 0 || y < 0
    return false if x >= map.width || y >= map.height

    tag = map.terrain_tag(x, y)

    if defined?(PBTerrain) && PBTerrain.respond_to?(:isWater?)
      return PBTerrain.isWater?(tag)
    end

    return false
  end

  def self.connected_map_offset(map)
    return [0, 0] if !$game_map || !map
    return [0, 0] if map.map_id == $game_map.map_id

    return $MapFactory.getRelativePos(
      $game_map.map_id,
      0,
      0,
      map.map_id,
      0,
      0
    )
  end

  def self.map_tile_screen_position(map_id, tile_x, tile_y, local_x = 0, local_y = 0)
    return nil if !$game_map || !$MapFactory

    map = nil

    for candidate in $MapFactory.maps
      next if !candidate
      if candidate.map_id == map_id
        map = candidate
        break
      end
    end

    return nil if !map

    offset = connected_map_offset(map)

    display_x = ($game_map.display_x / Game_Map::X_SUBPIXELS).round
    display_y = ($game_map.display_y / Game_Map::Y_SUBPIXELS).round

    world_x =
      (offset[0] + tile_x) * Game_Map::TILE_WIDTH +
      local_x

    world_y =
      (offset[1] + tile_y) * Game_Map::TILE_HEIGHT +
      local_y

    return [
      world_x - display_x,
      world_y - display_y
    ]
  end

  def self.find_visible_water_tile
    return nil if !$game_map || !$MapFactory

    tile_w = Game_Map::TILE_WIDTH
    tile_h = Game_Map::TILE_HEIGHT

    display_x = ($game_map.display_x / Game_Map::X_SUBPIXELS).round
    display_y = ($game_map.display_y / Game_Map::Y_SUBPIXELS).round

    maps = $MapFactory.maps.compact
    return nil if maps.empty?

    start_index = rand(maps.length)

    maps.length.times do |map_index|
      map = maps[(start_index + map_index) % maps.length]
      next if !map

      next if map.map_id != EZO_VILLAGE_MAP_ID &&
              map.map_id != NAGISA_BAY_MAP_ID

      offset = connected_map_offset(map)

      screen_left_tile   = (display_x / tile_w) - offset[0] - 1
      screen_top_tile    = (display_y / tile_h) - offset[1] - 1
      screen_right_tile  = ((display_x + Graphics.width) / tile_w) - offset[0] + 1
      screen_bottom_tile = ((display_y + Graphics.height) / tile_h) - offset[1] + 1

      left   = [[screen_left_tile, 0].max, map.width - 1].min
      top    = [[screen_top_tile, 0].max, map.height - 1].min
      right  = [[screen_right_tile, 0].max, map.width - 1].min
      bottom = [[screen_bottom_tile, 0].max, map.height - 1].min

      next if right < left || bottom < top

      36.times do
        tx = left + rand([right - left + 1, 1].max)
        ty = top  + rand([bottom - top + 1, 1].max)

        if water_tile?(map.map_id, tx, ty)
          return [map.map_id, tx, ty]
        end
      end

      for ty in top..bottom
        for tx in left..right
          if water_tile?(map.map_id, tx, ty)
            return [map.map_id, tx, ty]
          end
        end
      end
    end

    return nil
  end

  def self.reset_nagisa_particle(data, initial = false)
    sprite = data[:sprite]
    tile = find_visible_water_tile

    if !tile
      data[:active] = false
      data[:life] = 0
      data[:retry] = 8 + rand(14)
      sprite.visible = false
      return
    end

    map_id, tx, ty = tile

    data[:map_id] = map_id
    data[:tile_x] = tx
    data[:tile_y] = ty

    data[:local_x] = rand(Game_Map::TILE_WIDTH)
    data[:local_y] = rand(Game_Map::TILE_HEIGHT)

    data[:drift_x] = -0.10 + rand(21) / 100.0
    data[:drift_y] = -(0.22 + rand(26) / 100.0)

    data[:offset_x] = 0.0
    data[:offset_y] = 0.0

    data[:max_life] = 68 + rand(58)
    data[:life] = initial ? rand(data[:max_life]) : 0
    data[:opacity] = 135 + rand(NAGISA_PARTICLE_OPACITY - 134)

    data[:scale] = 0.92 + rand(19) / 100.0
    sprite.zoom_x = data[:scale]
    sprite.zoom_y = data[:scale]

    data[:active] = true
    data[:retry] = 0

    sprite.opacity = 0
    sprite.visible = false
  end

  def self.update_nagisa_particles
    bubble_map =
      @profile == :EZO_VILLAGE ||
      @profile == :NAGISA_BAY

    strength = bubble_map ? @master_strength : 0.0

    @nagisa_particles.each do |data|
      sprite = data[:sprite]
      next if !sprite || sprite.disposed?

      if strength <= 0.001
        sprite.visible = false
        next
      end

      if !data[:active]
        data[:retry] -= 1
        reset_nagisa_particle(data) if data[:retry] <= 0
        next
      end

      if !water_tile?(data[:map_id], data[:tile_x], data[:tile_y])
        reset_nagisa_particle(data)
        next
      end

      data[:life] += 1

      if data[:life] >= data[:max_life]
        reset_nagisa_particle(data)
        next
      end

      data[:offset_x] += data[:drift_x]
      data[:offset_y] += data[:drift_y]

      position = map_tile_screen_position(
        data[:map_id],
        data[:tile_x],
        data[:tile_y],
        data[:local_x] + data[:offset_x],
        data[:local_y] + data[:offset_y]
      )

      if !position
        reset_nagisa_particle(data)
        next
      end

      screen_x = position[0]
      screen_y = position[1]

      sprite.x = screen_x.to_i
      sprite.y = screen_y.to_i

      progress = data[:life].to_f / data[:max_life]

      fade = 1.0
      fade = progress / 0.16 if progress < 0.16
      fade = (1.0 - progress) / 0.28 if progress > 0.72
      fade = [[fade, 0.0].max, 1.0].min

      breathe =
        0.92 +
        Math.sin((@frame + data[:life] * 2) / 11.0) * 0.08

      sprite.opacity =
        clamp_opacity(
          data[:opacity] *
          fade *
          breathe *
          strength
        )

      on_screen =
        screen_x >= -12 &&
        screen_y >= -12 &&
        screen_x <= Graphics.width + 12 &&
        screen_y <= Graphics.height + 12

      sprite.visible =
        sprite.opacity > 0 &&
        on_screen

      if screen_x < -64 ||
         screen_y < -64 ||
         screen_x > Graphics.width + 64 ||
         screen_y > Graphics.height + 64
        reset_nagisa_particle(data)
      end
    end
  end

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

    if @warm_wash_sprite && !@warm_wash_sprite.disposed?
      opacity = INK_STYLE_ENABLED ? DEFAULT_WARM_WASH_OPACITY * master : 0
      @warm_wash_sprite.opacity = clamp_opacity(opacity)
      @warm_wash_sprite.visible = @warm_wash_sprite.opacity > 0
    end

    if @cool_wash_sprite && !@cool_wash_sprite.disposed?
      opacity = INK_STYLE_ENABLED ? DEFAULT_COOL_WASH_OPACITY * master : 0
      @cool_wash_sprite.opacity = clamp_opacity(opacity)
      @cool_wash_sprite.visible = @cool_wash_sprite.opacity > 0
    end

    if @print_grain_sprite && !@print_grain_sprite.disposed?
      opacity = INK_STYLE_ENABLED ? DEFAULT_PRINT_GRAIN_OPACITY * master : 0
      @print_grain_sprite.opacity = clamp_opacity(opacity)
      @print_grain_sprite.visible = @print_grain_sprite.opacity > 0
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
      clamp_gray(source.gray + @grade_tone.gray * master)
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

  def self.cache_ready?
    bitmaps = [
      @vignette_bitmap,
      @center_lift_bitmap,
      @depth_bitmap,
      @warm_wash_bitmap,
      @cool_wash_bitmap,
      @print_grain_bitmap,
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

    return false if !@sakura_petal_bitmaps || @sakura_petal_bitmaps.empty?
    @sakura_petal_bitmaps.each do |bitmap|
      return false if !bitmap || bitmap.disposed?
    end

    return false if !@shizen_leaf_bitmaps || @shizen_leaf_bitmaps.empty?
    @shizen_leaf_bitmaps.each do |bitmap|
      return false if !bitmap || bitmap.disposed?
    end

    return true
  end

  def self.build_cache
    @vignette_bitmap = build_vignette_bitmap
    @center_lift_bitmap = build_center_lift_bitmap
    @depth_bitmap = build_depth_bitmap

    @warm_wash_bitmap = build_warm_wash_bitmap
    @cool_wash_bitmap = build_cool_wash_bitmap
    @print_grain_bitmap = build_print_grain_bitmap

    build_ezo_cache
    build_nagisa_cache
    build_sakura_cache
    build_shizen_cache
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

        bitmap.set_pixel(
          x, y,
          Color.new(255, 247, 236, alpha)
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

  def self.build_warm_wash_bitmap
    width  = Graphics.width + 160
    height = Graphics.height + 120
    bitmap = Bitmap.new(width, height)

    14.times do
      draw_pigment_blob(
        bitmap,
        rand(width),
        rand(height),
        55 + rand(125),
        30 + rand(85),
        212, 154, 94,
        18 + rand(25)
      )
    end

    5.times do
      draw_pigment_blob(
        bitmap,
        rand(width),
        rand(height),
        130 + rand(150),
        70 + rand(110),
        185, 128, 78,
        14 + rand(10)
      )
    end

    return bitmap
  end

  def self.build_cool_wash_bitmap
    width  = Graphics.width + 180
    height = Graphics.height + 140
    bitmap = Bitmap.new(width, height)

    16.times do
      draw_pigment_blob(
        bitmap,
        rand(width),
        rand(height),
        45 + rand(110),
        25 + rand(75),
        20, 30, 42,
        12 + rand(22)
      )
    end

    return bitmap
  end

  def self.build_print_grain_bitmap
    bitmap = Bitmap.new(Graphics.width, Graphics.height)
    step = 2
    y = 0

    while y < bitmap.height
      x = 0

      while x < bitmap.width
        if rand(100) < 7
          color = if rand(2) == 0
                    Color.new(218, 181, 133, 10 + rand(12))
                  else
                    Color.new(32, 42, 51, 8 + rand(10))
                  end

          bitmap.fill_rect(x, y, step, step, color)
        end

        x += step
      end

      y += step
    end

    return bitmap
  end

  def self.draw_pigment_blob(bitmap, cx, cy, rx, ry, red, green, blue, alpha)
    return if !bitmap || bitmap.disposed?
    return if rx <= 0 || ry <= 0

    layers = 7

    for layer in 1..layers
      scale = layer.to_f / layers
      layer_rx = [1, (rx * scale).to_i].max
      layer_ry = [1, (ry * scale).to_i].max

      layer_strength = 1.0 - (layer - 1).to_f / layers
      layer_alpha = (alpha * layer_strength * 0.72).to_i
      next if layer_alpha <= 0

      color = Color.new(red, green, blue, layer_alpha)
      top = [cy - layer_ry, 0].max
      bottom = [cy + layer_ry, bitmap.height - 1].min

      for y in top..bottom
        ny = (y - cy).to_f / layer_ry
        span_sq = 1.0 - ny * ny
        next if span_sq <= 0.0

        span = (Math.sqrt(span_sq) * layer_rx).to_i

        wobble =
          (Math.sin(y * 0.083 + cx * 0.017) * 5.0 +
           Math.sin(y * 0.031 - cy * 0.013) * 3.0).to_i

        left = [cx - span + wobble, 0].max
        right = [cx + span + wobble, bitmap.width - 1].min
        next if right < left

        bitmap.fill_rect(left, y, right - left + 1, 1, color)
      end
    end
  end

  def self.build_ezo_cache
    width = (Graphics.width + 180) / 2
    height = (Graphics.height + 80) / 2

    @ezo_cloud_bitmap = Bitmap.new(width, height)

    clouds = [
      [30,  26, 42, 16, 0.72],
      [62,  20, 34, 14, 0.58],
      [92,  30, 48, 18, 0.66],

      [150, 18, 52, 17, 0.68],
      [190, 28, 42, 15, 0.54],
      [222, 20, 50, 18, 0.64],

      [282, 32, 48, 16, 0.62],
      [324, 20, 56, 19, 0.70],
      [366, 30, 44, 16, 0.56]
    ]

    for y in 0...height
      for x in 0...width
        strength = 0.0

        clouds.each do |c|
          cx, cy, rx, ry, power = c

          dx = (x - cx).to_f / rx
          dy = (y - cy).to_f / ry
          d2 = dx * dx + dy * dy

          next if d2 >= 1.0

          local = (1.0 - d2)
          local = local * local * power
          strength = local if local > strength
        end

        next if strength <= 0.0

        alpha = (strength * 112).to_i
        @ezo_cloud_bitmap.set_pixel(
          x, y,
          Color.new(7, 13, 22, alpha)
        )
      end
    end

    @ezo_haze_bitmap =
      Bitmap.new(Graphics.width, Graphics.height)

    half = [Graphics.height / 2, 1].max

    for y in 0...half
      t = 1.0 - y.to_f / half
      alpha = (t * t * 46).to_i

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
      Color.new(238, 246, 255, 255)
    )
  end

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
      Color.new(226, 238, 244, 255)
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
      Bitmap.new(9, 9)

    outer = Color.new(120, 205, 255, 70)
    rim   = Color.new(185, 232, 255, 150)
    hot   = Color.new(245, 252, 255, 225)
    shine = Color.new(255, 255, 255, 255)

    @nagisa_particle_bitmap.set_pixel(3, 0, outer)
    @nagisa_particle_bitmap.set_pixel(4, 0, outer)
    @nagisa_particle_bitmap.set_pixel(5, 0, outer)
    @nagisa_particle_bitmap.set_pixel(1, 2, outer)
    @nagisa_particle_bitmap.set_pixel(7, 2, outer)
    @nagisa_particle_bitmap.set_pixel(0, 3, outer)
    @nagisa_particle_bitmap.set_pixel(8, 3, outer)
    @nagisa_particle_bitmap.set_pixel(0, 4, outer)
    @nagisa_particle_bitmap.set_pixel(8, 4, outer)
    @nagisa_particle_bitmap.set_pixel(0, 5, outer)
    @nagisa_particle_bitmap.set_pixel(8, 5, outer)
    @nagisa_particle_bitmap.set_pixel(1, 6, outer)
    @nagisa_particle_bitmap.set_pixel(7, 6, outer)
    @nagisa_particle_bitmap.set_pixel(3, 8, outer)
    @nagisa_particle_bitmap.set_pixel(4, 8, outer)
    @nagisa_particle_bitmap.set_pixel(5, 8, outer)

    @nagisa_particle_bitmap.set_pixel(2, 1, rim)
    @nagisa_particle_bitmap.set_pixel(3, 1, hot)
    @nagisa_particle_bitmap.set_pixel(4, 1, hot)
    @nagisa_particle_bitmap.set_pixel(5, 1, rim)
    @nagisa_particle_bitmap.set_pixel(6, 1, rim)

    @nagisa_particle_bitmap.set_pixel(1, 2, hot)
    @nagisa_particle_bitmap.set_pixel(7, 2, rim)

    @nagisa_particle_bitmap.set_pixel(1, 3, hot)
    @nagisa_particle_bitmap.set_pixel(7, 3, rim)

    @nagisa_particle_bitmap.set_pixel(1, 4, rim)
    @nagisa_particle_bitmap.set_pixel(7, 4, rim)

    @nagisa_particle_bitmap.set_pixel(1, 5, rim)
    @nagisa_particle_bitmap.set_pixel(7, 5, rim)

    @nagisa_particle_bitmap.set_pixel(1, 6, rim)
    @nagisa_particle_bitmap.set_pixel(7, 6, rim)

    @nagisa_particle_bitmap.set_pixel(2, 7, rim)
    @nagisa_particle_bitmap.set_pixel(3, 7, rim)
    @nagisa_particle_bitmap.set_pixel(4, 7, rim)
    @nagisa_particle_bitmap.set_pixel(5, 7, rim)
    @nagisa_particle_bitmap.set_pixel(6, 7, rim)

    @nagisa_particle_bitmap.set_pixel(2, 2, shine)
    @nagisa_particle_bitmap.set_pixel(3, 2, hot)
  end

  def self.build_sakura_cache
    @sakura_petal_bitmaps = []

    palettes = [
      [Color.new(255, 151, 198, 255), Color.new(255, 215, 231, 230)],
      [Color.new(244, 127, 184, 255), Color.new(255, 201, 223, 230)],
      [Color.new(255, 176, 210, 255), Color.new(255, 226, 238, 230)]
    ]

    3.times do |i|
      bitmap = Bitmap.new(8, 8)

      main  = palettes[i][0]
      light = palettes[i][1]
      soft  = Color.new(main.red, main.green, main.blue, 165)

      case i
      when 0
        bitmap.set_pixel(3, 1, light)
        bitmap.set_pixel(4, 1, light)
        bitmap.fill_rect(2, 2, 4, 3, main)
        bitmap.set_pixel(3, 5, main)
        bitmap.set_pixel(4, 5, soft)

      when 1
        bitmap.set_pixel(2, 1, light)
        bitmap.fill_rect(2, 2, 4, 2, main)
        bitmap.fill_rect(3, 4, 3, 2, main)
        bitmap.set_pixel(5, 6, soft)

      when 2
        bitmap.set_pixel(3, 1, light)
        bitmap.set_pixel(4, 1, light)
        bitmap.fill_rect(1, 2, 6, 3, main)
        bitmap.fill_rect(2, 5, 4, 1, main)
        bitmap.set_pixel(3, 6, soft)
      end

      @sakura_petal_bitmaps.push(bitmap)
    end
  end

  def self.build_shizen_cache
    @shizen_leaf_bitmaps = []

    leaf_palettes = [
      [Color.new(83, 132, 48, 255),  Color.new(145, 183, 79, 255), Color.new(47, 78, 35, 255)],
      [Color.new(117, 147, 55, 255), Color.new(176, 192, 88, 255), Color.new(62, 88, 40, 255)],
      [Color.new(151, 112, 43, 255), Color.new(205, 160, 70, 255), Color.new(91, 67, 31, 255)]
    ]

    3.times do |i|
      bitmap = Bitmap.new(13, 11)
      main = leaf_palettes[i][0]
      light = leaf_palettes[i][1]
      dark = leaf_palettes[i][2]

      case i
      when 0
        bitmap.set_pixel(6, 0, light)
        bitmap.fill_rect(4, 1, 5, 1, light)
        bitmap.fill_rect(3, 2, 7, 2, light)
        bitmap.fill_rect(2, 4, 9, 3, main)
        bitmap.fill_rect(3, 7, 7, 1, main)
        bitmap.fill_rect(4, 8, 5, 1, dark)
        bitmap.set_pixel(6, 9, dark)
        bitmap.set_pixel(7, 10, dark)
      when 1
        bitmap.set_pixel(3, 1, light)
        bitmap.fill_rect(3, 2, 6, 2, light)
        bitmap.fill_rect(2, 4, 9, 3, main)
        bitmap.fill_rect(4, 7, 7, 2, main)
        bitmap.fill_rect(6, 9, 4, 1, dark)
        bitmap.set_pixel(9, 10, dark)
      else
        bitmap.set_pixel(8, 0, light)
        bitmap.fill_rect(5, 1, 5, 1, light)
        bitmap.fill_rect(4, 2, 7, 2, light)
        bitmap.fill_rect(2, 4, 9, 3, main)
        bitmap.fill_rect(1, 7, 8, 1, main)
        bitmap.fill_rect(3, 8, 5, 1, dark)
        bitmap.set_pixel(3, 9, dark)
        bitmap.set_pixel(2, 10, dark)
      end

      4.upto(8) do |y|
        bitmap.set_pixel(6, y, dark) if bitmap.get_pixel(6, y).alpha > 0
      end

      @shizen_leaf_bitmaps.push(bitmap)
    end
  end

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

Events.onSpritesetCreate += proc { |_sender, _spriteset, _viewport|
  BushidoPostFX.ensure_created
}

Events.onMapUpdate += proc { |_sender, _e|
  BushidoPostFX.update
}
