#===============================================================================
# Shadow Lugia QTE
# Pokemon Bushido
#===============================================================================
#
# Examples:
#
#   ShadowLugiaQTE.test
#
#   ShadowLugiaQTE.run([
#     :top,
#     :bottom,
#     :left,
#     :right
#   ])
#
#   ShadowLugiaQTE.run_random(4)
#
# Returns:
#   true  = survived the encounter
#   false = lost all hearts / blacked out
#
# External asset:
#   Graphics/Characters/249_shadow.png
#
# QTE UI assets live in Graphics/Pictures/ShadowLugiaQTE.
#===============================================================================

module ShadowLugiaQTE

  #=============================================================================
  # CONFIG
  #=============================================================================

  LUGIA_CHARACTER = "249_shadow"
  UI_PATH = "Graphics/Pictures/ShadowLugiaQTE/"

  def self.ui_bitmap(name)
    return Bitmap.new(UI_PATH + name + ".png")
  end

  #-----------------------------------------------------------------------------
  # Timing
  #-----------------------------------------------------------------------------

  APPROACH_FRAMES       = 34
  SLOWMO_FRAMES         = 68
  EXIT_FRAMES           = 28
  RECOVERY_FRAMES       = 24
  BETWEEN_ATTACK_FRAMES = 12
  FINAL_RELEASE_FRAMES  = 22

  #-----------------------------------------------------------------------------
  # Lugia charset
  #-----------------------------------------------------------------------------

  LUGIA_FRAME_W = 128
  LUGIA_FRAME_H = 128

  LUGIA_ANIM_FRAMES = [0, 1]

  # Normal RMXP charset direction rows:
  #
  #   0 = down
  #   1 = left
  #   2 = right
  #   3 = up
  #
  LUGIA_ROW_DOWN  = 0
  LUGIA_ROW_LEFT  = 1
  LUGIA_ROW_RIGHT = 2
  LUGIA_ROW_UP    = 3

  #-----------------------------------------------------------------------------
  # Camera
  #-----------------------------------------------------------------------------

  CAMERA_ZOOM         = 1.16
  BETWEEN_ATTACK_ZOOM = 1.045

  #-----------------------------------------------------------------------------
  # Dodge meter
  #-----------------------------------------------------------------------------

  METER_WIDTH         = 300
  METER_HEIGHT        = 24
  SUCCESS_ZONE_WIDTH  = 72

  MARKER_WIDTH        = 8
  MARKER_HEIGHT       = 36

  METER_BOTTOM_MARGIN = 54

  #-----------------------------------------------------------------------------
  # Player dodge
  #-----------------------------------------------------------------------------

  PLAYER_DODGE_PIXELS = 64

  #-----------------------------------------------------------------------------
  # Cinematic
  #-----------------------------------------------------------------------------

  LETTERBOX_HEIGHT = 32

  VIGNETTE_DEPTH   = 56
  VIGNETTE_OPACITY = 210

  #-----------------------------------------------------------------------------
  # Hearts
  #-----------------------------------------------------------------------------

  MAX_HEARTS = 3

  # Clean compact heart: 16x16 logical pixels, displayed at 2x.
  # The silhouette itself stays inset from the bitmap edges so neither outline
  # nor scaling can clip it.
  HEART_WIDTH   = 32
  HEART_HEIGHT  = 32
  HEART_SPACING = 6

  # Tiny pre-attack settle so the player always reaches a clean idle frame.
  PLAYER_SETTLE_MAX_FRAMES  = 8
  PLAYER_IDLE_HOLD_FRAMES   = 2

  HEART_RIGHT_MARGIN = 18
  HEART_TOP_MARGIN   = 18

  #-----------------------------------------------------------------------------
  # Death / blackout
  #-----------------------------------------------------------------------------

  DEATH_HOLD_FRAMES     = 24
  BLACKOUT_FRAMES       = 28
  BLACKOUT_HOLD_FRAMES  = 28

  #=============================================================================
  # CACHE
  #=============================================================================

  @lugia_bitmap_cache = nil

  def self.lugia_bitmap
    if !@lugia_bitmap_cache ||
       @lugia_bitmap_cache.disposed?

      @lugia_bitmap_cache =
        Bitmap.new(
          "Graphics/Characters/#{LUGIA_CHARACTER}.png"
        )
    end

    return @lugia_bitmap_cache
  end

  #=============================================================================
  # PUBLIC API
  #=============================================================================

  def self.test
    return run([
      :top,
      :bottom,
      :left,
      :right
    ])
  end

  def self.run(attacks)
    attacks = [attacks] if
      !attacks.is_a?(Array)

    cleaned = []

    attacks.each do |attack|
      direction =
        normalize_direction(
          attack
        )

      cleaned << direction if
        direction
    end

    return false if
      cleaned.empty?

    runner = Runner.new

    begin
      runner.start

      result =
        runner.run_sequence(
          cleaned
        )
    ensure
      runner.dispose
    end

    return result
  end

  def self.run_random(count = 4)
    count = count.to_i
    count = 1 if count < 1

    directions = [
      :top,
      :bottom,
      :left,
      :right
    ]

    sequence = []
    previous = nil

    count.times do
      choices =
        directions.clone

      choices.delete(previous) if
        previous

      direction =
        choices[
          rand(choices.length)
        ]

      sequence << direction
      previous = direction
    end

    return run(sequence)
  end

  def self.normalize_direction(value)
    if value.is_a?(Hash)
      value =
        value[:from] ||
        value["from"]
    end

    value =
      value.to_s.downcase.to_sym rescue nil

    return value if
      [
        :top,
        :bottom,
        :left,
        :right
      ].include?(value)

    return nil
  end

  #=============================================================================
  # RUNNER
  #=============================================================================

  class Runner

    def initialize
      #-------------------------------------------------------------------------
      # Viewports
      #-------------------------------------------------------------------------

      @world_viewport = nil
      @viewport       = nil

      #-------------------------------------------------------------------------
      # Frozen world
      #-------------------------------------------------------------------------

      @world_bitmap = nil
      @world_sprite = nil

      @camera_zoom    = 1.0
      @camera_focus_x = 0
      @camera_focus_y = 0

      # Screen shake is applied to cinematic actors/world only.
      # Screen-space UI/effects remain locked to the physical screen.
      @shake_x = 0
      @shake_y = 0

      #-------------------------------------------------------------------------
      # Lugia
      #-------------------------------------------------------------------------

      @lugia = nil

      @lugia_world_x = 0
      @lugia_world_y = 0
      @lugia_scale   = 1.0

      @lugia_afterimages = []

      #-------------------------------------------------------------------------
      # Player
      #-------------------------------------------------------------------------

      @map_player_sprite   = nil
      @real_player_visible = true

      @cinematic_player = nil

      @player_world_x = 0
      @player_world_y = 0

      @player_offset_x = 0
      @player_offset_y = 0

      @player_zoom_x = 1.0
      @player_zoom_y = 1.0

      # Exact idle frame captured after the player settles.
      @standing_src_x = nil
      @standing_src_y = nil
      @standing_src_w = nil
      @standing_src_h = nil

      @player_afterimages = []

      #-------------------------------------------------------------------------
      # Follower
      #-------------------------------------------------------------------------

      @follower_was_active = false

      #-------------------------------------------------------------------------
      # UI
      #-------------------------------------------------------------------------

      @dark_overlay   = nil
      @vignette       = nil
      @flash_overlay  = nil
      @impact_overlay = nil

      @letterbox_top    = nil
      @letterbox_bottom = nil

      @speed_lines = nil

      @meter  = nil
      @marker = nil
      @prompt = nil

      # Threat vignette state. During slow-mo this steadily closes inward.
      @vignette_progress = 0.0
      @vignette_color    = Color.new(28, 8, 38)

      #-------------------------------------------------------------------------
      # Hearts
      #-------------------------------------------------------------------------

      @hearts       = MAX_HEARTS
      @heart_sprites = []

      #-------------------------------------------------------------------------
      # State
      #-------------------------------------------------------------------------

      @current_direction = :top

      @cinematic_active = false
      @dead              = false
      @disposed          = false
    end

    #===========================================================================
    # START
    #===========================================================================

    def start
      find_player_sprite

      # Finish the triggering step and lock the player into a clean standing
      # frame before any cinematic capture happens. This prevents the QTE from
      # freezing the player halfway through a walk cycle.
      settle_player_before_qte

      hide_follower_immediately

      create_viewports
      create_overlays
      create_letterbox
      create_speed_lines
      create_lugia
      create_hearts
    end

    #===========================================================================
    # PLAYER SETTLE
    #===========================================================================

    def settle_player_before_qte
      # Finish the final pixels of the triggering step, but cap this so there is
      # never a noticeable delay before the encounter begins.
      frames = 0

      begin
        while $game_player.moving? &&
              frames < PLAYER_SETTLE_MAX_FRAMES

          Graphics.update
          Input.update
          update_map_spriteset

          frames += 1
        end
      rescue
      end

      # Face the player up before the attack starts.
      
      begin
        $game_player.direction = 8
      rescue
        begin
          $game_player.instance_variable_set(
            :@direction,
            8
          )
        rescue
        end
      end

      # Reset to the standing frame.
      begin
        $game_player.straighten
      rescue
        begin
          original =
            $game_player.instance_variable_get(
              :@original_pattern
            )

          original = 0 if original.nil?

          $game_player.instance_variable_set(
            :@pattern,
            original
          )
        rescue
        end
      end

      update_map_spriteset

      # Give the idle frame a couple frames to settle.
      PLAYER_IDLE_HOLD_FRAMES.times do
        Graphics.update
        Input.update
        update_map_spriteset
      end

      capture_standing_player_frame
    end

    def capture_standing_player_frame
      return if !@map_player_sprite

      begin
        rect = @map_player_sprite.src_rect

        @standing_src_x = rect.x
        @standing_src_y = rect.y
        @standing_src_w = rect.width
        @standing_src_h = rect.height
      rescue
        @standing_src_x = nil
        @standing_src_y = nil
        @standing_src_w = nil
        @standing_src_h = nil
      end
    end

    #===========================================================================
    # SEQUENCE
    #===========================================================================

    def run_sequence(attacks)
      survived =
        true

      attacks.each_with_index do |direction, index|
        break if @dead

        @current_direction =
          direction

        final_attack =
          index == attacks.length - 1

        #---------------------------------------------------------------------
        # Set up incoming attack.
        #---------------------------------------------------------------------

        if index == 0
          setup_attack(
            direction
          )

          run_approach(
            direction
          )

          begin_cinematic
        else
          prepare_next_attack(
            direction
          )

          run_approach(
            direction
          )
        end

        #---------------------------------------------------------------------
        # QTE
        #---------------------------------------------------------------------

        create_meter

        result =
          timing_sequence(
            direction
          )

        dispose_meter

        #---------------------------------------------------------------------
        # Resolve.
        #---------------------------------------------------------------------

        if result == :success
          resolve_success(
            direction,
            final_attack
          )
        else
          resolve_failure(
            direction
          )

          if @hearts <= 0
            survived = false
            @dead = true

            dramatic_blackout

            break
          end
        end

        #---------------------------------------------------------------------
        # Continue encounter if alive.
        #---------------------------------------------------------------------

        if !final_attack &&
           !@dead

          between_attack_hold
        end
      end

      if @dead
        respawn_after_blackout
        return false
      end

      end_cinematic

      return survived
    end

    #===========================================================================
    # ATTACK SETUP
    #===========================================================================

    def setup_attack(direction)
      px =
        player_screen_x

      py =
        player_screen_y

      case direction
      when :top
        @lugia_world_x = px
        @lugia_world_y = -110

      when :bottom
        @lugia_world_x = px
        @lugia_world_y = Graphics.height + 110

      when :left
        @lugia_world_x = -110
        @lugia_world_y = py - 16

      when :right
        @lugia_world_x = Graphics.width + 110
        @lugia_world_y = py - 16
      end

      @lugia_scale   = 0.58
      @lugia.opacity = 255

      # Apply correct directional frame immediately.
      update_lugia_frame(
        0,
        4
      )

      apply_lugia_transform
    end

    #===========================================================================
    # LUGIA DIRECTION
    #===========================================================================

    def lugia_row_for_attack
      case @current_direction
      when :top
        # Comes from top, travels downward.
        return LUGIA_ROW_DOWN

      when :bottom
        # Comes from bottom, travels upward.
        return LUGIA_ROW_UP

      when :left
        # Comes from left, travels right.
        return LUGIA_ROW_RIGHT

      when :right
        # Comes from right, travels left.
        return LUGIA_ROW_LEFT
      end

      return LUGIA_ROW_DOWN
    end

    #===========================================================================
    # PREPARE NEXT ATTACK
    #===========================================================================

    def prepare_next_attack(direction)
      setup_attack(
        direction
      )

      @vignette_progress = 0.0
      @vignette_color =
        Color.new(
          28,
          8,
          38
        )

      swap_asset(@vignette, "vignette_threat_00")

      flash(
        Color.new(
          120,
          70,
          150
        ),
        54
      )

      4.times do
        fade_flash(14)
        qte_update
      end

      @flash_overlay.opacity = 0
    end

    #===========================================================================
    # APPROACH
    #===========================================================================

    def run_approach(direction)
      px =
        player_screen_x

      py =
        player_screen_y

      start_x =
        @lugia_world_x

      start_y =
        @lugia_world_y

      end_x = px
      end_y = py

      case direction
      when :top
        end_y =
          py - 146

      when :bottom
        end_y =
          py + 116

      when :left
        end_x =
          px - 146

        end_y =
          py - 16

      when :right
        end_x =
          px + 146

        end_y =
          py - 16
      end

      APPROACH_FRAMES.times do |frame|
        t =
          frame.to_f /
          (APPROACH_FRAMES - 1)

        eased =
          t * t

        @lugia_world_x =
          lerp(
            start_x,
            end_x,
            eased
          )

        @lugia_world_y =
          lerp(
            start_y,
            end_y,
            eased
          )

        @lugia_scale =
          lerp(
            0.58,
            1.0,
            eased
          )

        if frame >=
           APPROACH_FRAMES - 8

          if vertical_attack?(
               direction
             )

            @lugia_world_x +=
              frame % 2 == 0 ?
              -2 :
              2
          else
            @lugia_world_y +=
              frame % 2 == 0 ?
              -2 :
              2
          end
        end

        update_lugia_frame(
          frame,
          4
        )

        apply_lugia_transform

        if frame >=
           APPROACH_FRAMES - 4

          shake(
            frame,
            2
          )
        end

        qte_update
      end

      reset_shake
    end

    #===========================================================================
    # BEGIN CINEMATIC
    #===========================================================================

    def begin_cinematic
      return if
        @cinematic_active

      @cinematic_active = true

      @camera_focus_x =
        player_screen_x

      @camera_focus_y =
        player_screen_y

      @player_world_x =
        @camera_focus_x

      @player_world_y =
        @camera_focus_y

      hide_real_player

      old_lugia_opacity =
        @lugia.opacity

      # Hearts must not be baked into world capture.
      old_heart_opacities = []

      @heart_sprites.each do |heart|
        old_heart_opacities <<
          heart.opacity

        heart.opacity = 0
      end

      @lugia.opacity = 0

      force_follower_sprite_hidden

      Graphics.update

      @world_bitmap =
        Graphics.snap_to_bitmap

      @lugia.opacity =
        old_lugia_opacity

      @heart_sprites.each_with_index do |heart, i|
        heart.opacity =
          old_heart_opacities[i]
      end

      @world_sprite =
        Sprite.new(
          @world_viewport
        )

      @world_sprite.bitmap =
        @world_bitmap

      @world_sprite.ox =
        @camera_focus_x

      @world_sprite.oy =
        @camera_focus_y

      @world_sprite.x =
        @camera_focus_x

      @world_sprite.y =
        @camera_focus_y

      @world_sprite.zoom_x = 1.0
      @world_sprite.zoom_y = 1.0

      create_cinematic_player

      @camera_zoom = 1.0

      4.times do |frame|
        t =
          frame.to_f /
          3.0

        eased =
          ease_out_cubic(t)

        @letterbox_top.y =
          snap2(
            lerp(
              -LETTERBOX_HEIGHT,
              0,
              eased
            )
          )

        @letterbox_bottom.y =
          snap2(
            lerp(
              Graphics.height,
              Graphics.height -
              LETTERBOX_HEIGHT,
              eased
            )
          )

        @dark_overlay.opacity =
          lerp(
            0,
            76,
            eased
          ).to_i

        @vignette.opacity =
          lerp(
            0,
            215,
            eased
          ).to_i

        qte_update
      end
    end

    #===========================================================================
    # TIMING
    #===========================================================================

    def timing_sequence(direction)
      left =
        @meter.x

      right =
        @meter.x +
        METER_WIDTH

      target_left =
        left +
        ((METER_WIDTH -
        SUCCESS_ZONE_WIDTH) / 2)

      target_right =
        target_left +
        SUCCESS_ZONE_WIDTH

      start_x =
        @lugia_world_x

      start_y =
        @lugia_world_y

      target_x =
        @player_world_x

      target_y =
        @player_world_y

      case direction
      when :top
        target_y -= 68

      when :bottom
        target_y += 58

      when :left
        target_x -= 68
        target_y -= 16

      when :right
        target_x += 68
        target_y -= 16
      end

      start_zoom =
        @camera_zoom

      SLOWMO_FRAMES.times do |frame|
        t =
          frame.to_f /
          (SLOWMO_FRAMES - 1)

        eased =
          ease_out_cubic(t)

        @camera_zoom =
          lerp(
            start_zoom,
            CAMERA_ZOOM,
            eased
          )

        @marker.x =
          snap2(
            lerp(
              left,
              right,
              t
            )
          )

        @lugia_world_x =
          lerp(
            start_x,
            target_x,
            t
          )

        @lugia_world_y =
          lerp(
            start_y,
            target_y,
            t
          )

        @lugia_scale =
          lerp(
            1.0,
            1.16,
            t
          )

        update_lugia_frame(
          frame,
          12
        )

        update_camera

        animate_prompt(
          frame
        )

        animate_speed_lines_directional(
          frame,
          direction,
          false
        )

        update_threat_vignette(
          t
        )

        if t > 0.82
          shake(
            frame,
            t > 0.94 ? 2 : 1
          )
        else
          reset_shake
        end

        qte_update

        if Input.trigger?(
             Input::C
           )

          x =
            @marker.x

          reset_shake

          if x >= target_left &&
             x <= target_right

            meter_hit_snap

            return :success
          end

          return :fail
        end
      end

      reset_shake

      return :fail
    end

    #===========================================================================
    # SUCCESS
    #===========================================================================

    def resolve_success(direction, final_attack)
      pbSEPlay(
        "GUI sel decision",
        100,
        120
      ) rescue nil

      # Clear the vignette on a successful dodge.
      
      release_vignette_on_dodge

      dodge_axis =
        vertical_attack?(direction) ?
        :horizontal :
        :vertical

      sign =
        choose_dodge_sign(
          dodge_axis
        )

      target =
        PLAYER_DODGE_PIXELS *
        sign

      anticipation =
        -6 *
        sign

      #-----------------------------------------------------------------------
      # Anticipation
      #-----------------------------------------------------------------------

      2.times do |frame|
        t =
          frame.to_f

        if dodge_axis ==
           :horizontal

          @player_offset_x =
            snap2(
              lerp(
                0,
                anticipation,
                t
              )
            )
        else
          @player_offset_y =
            snap2(
              lerp(
                0,
                anticipation,
                t
              )
            )
        end

        update_camera
        qte_update
      end

      #-----------------------------------------------------------------------
      # Impact cut
      #-----------------------------------------------------------------------

      impact_frame(
        Color.new(
          0,
          0,
          0
        ),
        255
      )

      Graphics.update

      impact_frame(
        Color.new(
          255,
          255,
          255
        ),
        255
      )

      Graphics.update

      @impact_overlay.opacity = 0

      #-----------------------------------------------------------------------
      # Dodge snap
      #-----------------------------------------------------------------------

      spawn_player_afterimage

      4.times do |frame|
        t =
          frame.to_f /
          3.0

        value =
          snap2(
            lerp(
              anticipation,
              target +
              (8 * sign),
              ease_out_cubic(t)
            )
          )

        if dodge_axis ==
           :horizontal

          @player_offset_x =
            value
        else
          @player_offset_y =
            value
        end

        if frame == 1 ||
           frame == 2

          spawn_player_afterimage
        end

        update_player_afterimages

        animate_speed_lines_directional(
          frame,
          direction,
          true
        )

        update_camera
        qte_update
      end

      #-----------------------------------------------------------------------
      # Settle
      #-----------------------------------------------------------------------

      4.times do |frame|
        t =
          frame.to_f /
          3.0

        value =
          snap2(
            lerp(
              target +
              (8 * sign),
              target,
              ease_out_cubic(t)
            )
          )

        if dodge_axis ==
           :horizontal

          @player_offset_x =
            value
        else
          @player_offset_y =
            value
        end

        update_player_afterimages

        update_camera
        qte_update
      end

      #-----------------------------------------------------------------------
      # Fly through
      #-----------------------------------------------------------------------

      exit_start_x =
        @lugia_world_x

      exit_start_y =
        @lugia_world_y

      exit_x =
        exit_start_x

      exit_y =
        exit_start_y

      case direction
      when :top
        exit_y =
          Graphics.height + 300

      when :bottom
        exit_y =
          -300

      when :left
        exit_x =
          Graphics.width + 300

      when :right
        exit_x =
          -300
      end

      EXIT_FRAMES.times do |frame|
        t =
          frame.to_f /
          (EXIT_FRAMES - 1)

        move_t =
          ease_in_cubic(t)

        @lugia_world_x =
          lerp(
            exit_start_x,
            exit_x,
            move_t
          )

        @lugia_world_y =
          lerp(
            exit_start_y,
            exit_y,
            move_t
          )

        @lugia_scale =
          lerp(
            1.16,
            1.48,
            t
          )

        update_lugia_frame(
          frame,
          2
        )

        if frame == 2 ||
           frame == 6 ||
           frame == 10

          spawn_lugia_afterimage
        end

        update_lugia_afterimages
        update_player_afterimages

        animate_speed_lines_directional(
          frame,
          direction,
          true
        )

        if frame == 4
          flash(
            Color.new(
              255,
              255,
              255
            ),
            150
          )
        end

        if frame >= 3 &&
           frame <= 12

          shake(
            frame,
            6
          )
        else
          reset_shake
        end

        fade_flash(18)

        update_camera
        qte_update
      end

      reset_shake

      #-----------------------------------------------------------------------
      # Recovery / exhale
      #-----------------------------------------------------------------------

      recovery_start_zoom =
        @camera_zoom

      recovery_start_x =
        @player_offset_x

      recovery_start_y =
        @player_offset_y

      recovery_start_vignette =
        @vignette.opacity

      RECOVERY_FRAMES.times do |frame|
        t =
          frame.to_f /
          (RECOVERY_FRAMES - 1)

        eased =
          ease_out_cubic(t)

        target_zoom =
          final_attack ?
          1.0 :
          BETWEEN_ATTACK_ZOOM

        @camera_zoom =
          lerp(
            recovery_start_zoom,
            target_zoom,
            eased
          )

        @player_offset_x =
          snap2(
            lerp(
              recovery_start_x,
              0,
              eased
            )
          )

        @player_offset_y =
          snap2(
            lerp(
              recovery_start_y,
              0,
              eased
            )
          )

        @vignette.opacity =
          lerp(
            recovery_start_vignette,
            final_attack ? 90 : 125,
            eased
          ).to_i

        if @speed_lines.opacity > 0
          @speed_lines.opacity -= 8

          @speed_lines.opacity = 0 if
            @speed_lines.opacity < 0
        end

        update_lugia_afterimages
        update_player_afterimages

        update_camera
        qte_update
      end

      @player_offset_x = 0
      @player_offset_y = 0

      clear_player_afterimages
      clear_lugia_afterimages

      @lugia.opacity = 0
    end

    #===========================================================================
    # FAILURE
    #===========================================================================

    def resolve_failure(direction)
      start_x =
        @lugia_world_x

      start_y =
        @lugia_world_y

      hit_x =
        @player_world_x

      hit_y =
        @player_world_y

      #-----------------------------------------------------------------------
      # Lugia commits
      #-----------------------------------------------------------------------

      5.times do |frame|
        t =
          frame.to_f /
          4.0

        @lugia_world_x =
          lerp(
            start_x,
            hit_x,
            t * t
          )

        @lugia_world_y =
          lerp(
            start_y,
            hit_y,
            t * t
          )

        @lugia_scale =
          lerp(
            1.16,
            1.32,
            t
          )

        update_lugia_frame(
          frame,
          2
        )

        update_camera
        qte_update
      end

      pbSEPlay(
        "Battle damage normal",
        110,
        80
      ) rescue nil

      # Close the vignette on a hit.
      
      consume_vignette_on_hit

      #-----------------------------------------------------------------------
      # Impact frames
      #-----------------------------------------------------------------------

      impact_frame(
        Color.new(
          0,
          0,
          0
        ),
        255
      )

      Graphics.update

      impact_frame(
        Color.new(
          180,
          0,
          22
        ),
        255
      )

      Graphics.update

      @impact_overlay.opacity = 0

      flash(
        Color.new(
          220,
          0,
          28
        ),
        235
      )


      #-----------------------------------------------------------------------
      # Hit stop
      #-----------------------------------------------------------------------

      4.times do |frame|
        shake(
          frame,
          14
        )

        Graphics.update
        Input.update
      end

      #-----------------------------------------------------------------------
      # LOSE HEART
      #-----------------------------------------------------------------------

      lose_heart

      #-----------------------------------------------------------------------
      # DIRECT HIT
      #
      # A failed dodge must NOT move the player. Lugia actually collides with
      # the player's current position and the player stays planted through the
      # entire hit. Only the world/camera shakes around them.
      #-----------------------------------------------------------------------

      @player_offset_x = 0
      @player_offset_y = 0

      12.times do |frame|
        animate_speed_lines_directional(
          frame,
          direction,
          true
        )

        shake(
          frame,
          [10 - frame, 2].max
        )

        fade_flash(18)

        update_camera
        qte_update
      end

      reset_shake

      #-----------------------------------------------------------------------
      # Lugia continues through
      #-----------------------------------------------------------------------

      exit_start_x =
        @lugia_world_x

      exit_start_y =
        @lugia_world_y

      exit_x =
        exit_start_x

      exit_y =
        exit_start_y

      case direction
      when :top
        exit_y =
          Graphics.height + 300

      when :bottom
        exit_y =
          -300

      when :left
        exit_x =
          Graphics.width + 300

      when :right
        exit_x =
          -300
      end

      24.times do |frame|
        t =
          frame.to_f /
          23.0

        @lugia_world_x =
          lerp(
            exit_start_x,
            exit_x,
            ease_in_cubic(t)
          )

        @lugia_world_y =
          lerp(
            exit_start_y,
            exit_y,
            ease_in_cubic(t)
          )

        @lugia_scale =
          lerp(
            1.32,
            1.58,
            t
          )

        update_lugia_frame(
          frame,
          2
        )

        if frame == 2 ||
           frame == 6

          spawn_lugia_afterimage
        end

        update_lugia_afterimages
        update_player_afterimages

        if frame < 8
          shake(
            frame,
            6
          )
        else
          reset_shake
        end

        update_camera
        qte_update
      end

      reset_shake

      #-----------------------------------------------------------------------
      # If dead, leave the camera zoomed on the impact.
      # The player remains exactly where they were hit and blackout takes over.
      #-----------------------------------------------------------------------

      if @hearts <= 0
        clear_player_afterimages
        clear_lugia_afterimages
        @lugia.opacity = 0

        return
      end

      #-----------------------------------------------------------------------
      # Survived hit. Recover and continue.
      #-----------------------------------------------------------------------

      start_zoom =
        @camera_zoom

      start_x =
        @player_offset_x

      start_y =
        @player_offset_y

      22.times do |frame|
        t =
          frame.to_f /
          21.0

        eased =
          ease_out_cubic(t)

        @camera_zoom =
          lerp(
            start_zoom,
            BETWEEN_ATTACK_ZOOM,
            eased
          )

        @player_offset_x =
          snap2(
            lerp(
              start_x,
              0,
              eased
            )
          )

        @player_offset_y =
          snap2(
            lerp(
              start_y,
              0,
              eased
            )
          )

        @vignette.opacity =
          lerp(
            @vignette.opacity,
            125,
            0.12
          ).to_i

        if @speed_lines.opacity > 0
          @speed_lines.opacity -= 8

          @speed_lines.opacity = 0 if
            @speed_lines.opacity < 0
        end

        update_camera
        qte_update
      end

      @player_offset_x = 0
      @player_offset_y = 0

      clear_player_afterimages
      clear_lugia_afterimages

      @vignette_progress = 0.0
      @vignette_color =
        Color.new(
          28,
          8,
          38
        )

      swap_asset(@vignette, "vignette_threat_00")

      @vignette.opacity = 115

      @lugia.opacity = 0
    end

    #===========================================================================
    # HEART UI
    #===========================================================================

    def create_hearts
      dispose_hearts

      @hearts = MAX_HEARTS

      total_width =
        (MAX_HEARTS * HEART_WIDTH) +
        ((MAX_HEARTS - 1) * HEART_SPACING)

      start_x =
        Graphics.width -
        HEART_RIGHT_MARGIN -
        total_width

      MAX_HEARTS.times do |i|
        heart = asset_sprite("heart_full", 450)

        heart.ox = HEART_WIDTH / 4
        heart.oy = HEART_HEIGHT / 4

        heart.x =
          snap2(
            start_x +
            (HEART_WIDTH / 2) +
            (i * (HEART_WIDTH + HEART_SPACING))
          )

        heart.y =
          snap2(
            HEART_TOP_MARGIN +
            (HEART_HEIGHT / 2)
          )

        heart.opacity = 255
        @heart_sprites << heart
      end

      # Heart intro.
      @heart_sprites.each do |heart|
        heart.zoom_x = 0.0
        heart.zoom_y = 0.0
      end

      6.times do |frame|
        @heart_sprites.each_with_index do |heart, i|
          delayed = frame - i
          next if delayed < 0

          local_t = [delayed.to_f / 3.0, 1.0].min
          local_scale = 2.0 * ease_out_back(local_t)

          heart.zoom_x = local_scale
          heart.zoom_y = local_scale
        end

        Graphics.update
        Input.update
      end

      @heart_sprites.each do |heart|
        heart.zoom_x = 2.0
        heart.zoom_y = 2.0
      end
    end

    #===========================================================================
    # LOSE HEART
    #===========================================================================

    def lose_heart
      return if
        @hearts <= 0

      index =
        @hearts - 1

      heart =
        @heart_sprites[
          index
        ]

      @hearts -= 1

      return if
        !heart

      original_x =
        heart.x

      original_y =
        heart.y

      #-----------------------------------------------------------------------
      # Heart hit.
      #-----------------------------------------------------------------------

      3.times do |frame|
        t =
          frame.to_f /
          2.0

        scale =
          lerp(
            2.0,
            2.65,
            ease_out_cubic(t)
          )

        heart.zoom_x =
          scale

        heart.zoom_y =
          scale

        heart.x =
          original_x +
          (frame % 2 == 0 ? -2 : 2)

        qte_update
      end

      #-----------------------------------------------------------------------
      # Shrink the filled heart.
      #-----------------------------------------------------------------------

      5.times do |frame|
        t =
          frame.to_f /
          4.0

        heart.zoom_x =
          lerp(
            2.65,
            0.55,
            ease_in_cubic(t)
          )

        heart.zoom_y =
          lerp(
            2.65,
            0.55,
            ease_in_cubic(t)
          )

        heart.opacity =
          lerp(
            255,
            90,
            t
          ).to_i

        heart.y =
          snap2(
            original_y - (6 * t)
          )

        qte_update
      end

      # Swap the art while small so the state change reads like the heart
      # burned out rather than simply vanishing.
      swap_asset(heart, "heart_empty")

      heart.x =
        original_x

      heart.y =
        original_y

      #-----------------------------------------------------------------------
      # Bring the empty heart back in.
      #-----------------------------------------------------------------------

      5.times do |frame|
        t =
          frame.to_f /
          4.0

        eased =
          ease_out_back(t)

        scale =
          lerp(
            0.55,
            2.0,
            eased
          )

        heart.zoom_x =
          scale

        heart.zoom_y =
          scale

        heart.opacity =
          lerp(
            90,
            255,
            t
          ).to_i

        qte_update
      end

      heart.zoom_x = 2.0
      heart.zoom_y = 2.0
      heart.opacity = 255
      heart.x = original_x
      heart.y = original_y

      # Pulse the remaining hearts.
      if @hearts > 0
        4.times do |frame|
          pulse =
            frame < 2 ?
            2.18 :
            2.0

          @heart_sprites.each_with_index do |remaining, i|
            next if
              i >= @hearts

            remaining.zoom_x =
              pulse

            remaining.zoom_y =
              pulse
          end

          qte_update
        end

        @heart_sprites.each_with_index do |remaining, i|
          next if
            i >= @hearts

          remaining.zoom_x = 2.0
          remaining.zoom_y = 2.0
        end
      end
    end

    #===========================================================================
    # DRAMATIC DEATH
    #===========================================================================

    def dramatic_blackout
      dispose_meter

      reset_shake

      @speed_lines.opacity = 0

      #-----------------------------------------------------------------------
      # Death realization.
      #
      # Keep the red screen around briefly after the final heart dies.
      #-----------------------------------------------------------------------

      DEATH_HOLD_FRAMES.times do |frame|
        if frame < 10
          shake(
            frame,
            [8 - (frame / 2), 2].max
          )
        else
          reset_shake
        end

        @camera_zoom =
          lerp(
            @camera_zoom,
            1.24,
            0.08
          )

        @vignette.opacity =
          [
            @vignette.opacity + 6,
            255
          ].min

        update_camera
        qte_update
      end

      reset_shake

      #-----------------------------------------------------------------------
      # Black closes over the entire screen.
      #
      # Use impact overlay because it sits above hearts and cinematic UI.
      #-----------------------------------------------------------------------

      swap_asset(@impact_overlay, "overlay_black")

      @impact_overlay.opacity = 0

      BLACKOUT_FRAMES.times do |frame|
        t =
          frame.to_f /
          (BLACKOUT_FRAMES - 1)

        # Slow at first, then closes hard.
        eased =
          t * t

        @impact_overlay.opacity =
          lerp(
            0,
            255,
            eased
          ).to_i

        # Hearts vanish beneath black.
        @heart_sprites.each do |heart|
          heart.opacity =
            [
              heart.opacity - 18,
              0
            ].max
        end

        Graphics.update
        Input.update
      end

      @impact_overlay.opacity = 255

      BLACKOUT_HOLD_FRAMES.times do
        Graphics.update
        Input.update
      end
    end

    #===========================================================================
    # RESPAWN
    #===========================================================================

    def respawn_after_blackout
      #-----------------------------------------------------------------------
      # We are completely black here.
      #
      # First dismantle the QTE visual state while the player cannot see it.
      #-----------------------------------------------------------------------

      reset_shake

      clear_player_afterimages
      clear_lugia_afterimages

      dispose_cinematic_player

      if @world_sprite
        @world_sprite.dispose
        @world_sprite = nil
      end

      if @world_bitmap
        if !@world_bitmap.disposed?
          @world_bitmap.dispose
        end

        @world_bitmap = nil
      end

      restore_real_player

      @cinematic_active = false

      restore_follower

      #-----------------------------------------------------------------------
      # Heal before respawn if available.
      #-----------------------------------------------------------------------

      begin
        pbHealAll
      rescue
      end

      #-----------------------------------------------------------------------
      # Use the game's normal blackout/respawn system if available.
      #
      # Different Essentials builds/plugins can expose different helpers,
      # so try the standard options rather than manually assigning map coords.
      #-----------------------------------------------------------------------

      respawned = false

      begin
        if defined?(pbStartOver)
          pbStartOver
          respawned = true
        end
      rescue
      end

      if !respawned
        begin
          if defined?(pbRespawnPoint)
            pbRespawnPoint
            respawned = true
          end
        rescue
        end
      end

      #-----------------------------------------------------------------------
      # Fade black away after respawn.
      #-----------------------------------------------------------------------

      24.times do |frame|
        t =
          frame.to_f /
          23.0

        @impact_overlay.opacity =
          lerp(
            255,
            0,
            ease_out_cubic(t)
          ).to_i

        Graphics.update
        Input.update
      end

      @impact_overlay.opacity = 0
    end

    #===========================================================================
    # BETWEEN ATTACKS
    #===========================================================================

    def between_attack_hold
      @vignette_progress = 0.0
      @vignette_color =
        Color.new(
          28,
          8,
          38
        )

      swap_asset(@vignette, "vignette_threat_00")

      start_vignette =
        @vignette.opacity

      BETWEEN_ATTACK_FRAMES.times do |frame|
        t =
          frame.to_f /
          (BETWEEN_ATTACK_FRAMES - 1)

        @camera_zoom =
          BETWEEN_ATTACK_ZOOM

        @vignette.opacity =
          lerp(
            start_vignette,
            115,
            t
          ).to_i

        @dark_overlay.opacity =
          lerp(
            @dark_overlay.opacity,
            46,
            0.15
          ).to_i

        @speed_lines.opacity = 0

        update_camera
        qte_update
      end
    end

    #===========================================================================
    # END CINEMATIC
    #===========================================================================

    def end_cinematic
      return if
        !@cinematic_active

      start_zoom =
        @camera_zoom

      start_dark =
        @dark_overlay.opacity

      start_vignette =
        @vignette.opacity

      FINAL_RELEASE_FRAMES.times do |frame|
        t =
          frame.to_f /
          (FINAL_RELEASE_FRAMES - 1)

        eased =
          ease_out_cubic(t)

        @camera_zoom =
          lerp(
            start_zoom,
            1.0,
            eased
          )

        @letterbox_top.y =
          snap2(
            lerp(
              0,
              -LETTERBOX_HEIGHT,
              eased
            )
          )

        @letterbox_bottom.y =
          snap2(
            lerp(
              Graphics.height -
              LETTERBOX_HEIGHT,
              Graphics.height,
              eased
            )
          )

        @dark_overlay.opacity =
          lerp(
            start_dark,
            0,
            eased
          ).to_i

        @vignette.opacity =
          lerp(
            start_vignette,
            0,
            eased
          ).to_i

        if @speed_lines.opacity > 0
          @speed_lines.opacity -= 10

          @speed_lines.opacity = 0 if
            @speed_lines.opacity < 0
        end

        # Hearts leave gently with the cinematic.
        @heart_sprites.each do |heart|
          next if
            heart.opacity <= 0

          heart.opacity =
            lerp(
              255,
              0,
              eased
            ).to_i
        end

        update_camera
        qte_update
      end

      @camera_zoom = 1.0

      @dark_overlay.opacity  = 0
      @vignette.opacity      = 0
      @speed_lines.opacity   = 0

      dispose_cinematic_player

      if @world_sprite
        @world_sprite.dispose
        @world_sprite = nil
      end

      if @world_bitmap
        if !@world_bitmap.disposed?
          @world_bitmap.dispose
        end

        @world_bitmap = nil
      end

      restore_real_player

      @cinematic_active = false

      restore_follower

      Graphics.update

      reset_shake
    end

    #===========================================================================
    # DIRECTION HELPERS
    #===========================================================================

    def vertical_attack?(direction)
      return (
        direction == :top ||
        direction == :bottom
      )
    end

    def choose_dodge_sign(axis)
      if axis == :horizontal
        return (
          $game_player.x % 2 == 0 ?
          -1 :
          1
        )
      end

      return (
        $game_player.y % 2 == 0 ?
        -1 :
        1
      )
    end

    #===========================================================================
    # CAMERA
    #===========================================================================

    def update_camera
      if @world_sprite
        @world_sprite.zoom_x =
          @camera_zoom

        @world_sprite.zoom_y =
          @camera_zoom
      end

      apply_player_transform
      apply_lugia_transform
    end

    def camera_x(x)
      return @camera_focus_x +
        ((x - @camera_focus_x) *
        @camera_zoom)
    end

    def camera_y(y)
      return @camera_focus_y +
        ((y - @camera_focus_y) *
        @camera_zoom)
    end

    #===========================================================================
    # PLAYER LOOKUP
    #===========================================================================

    def find_player_sprite
      @map_player_sprite =
        recursive_character_sprite(
          $scene,
          $game_player,
          {},
          0
        )
    end

    def recursive_character_sprite(object, target, visited, depth)
      return nil if object.nil?
      return nil if depth > 7

      begin
        oid =
          object.object_id

        return nil if
          visited[oid]

        visited[oid] =
          true
      rescue
        return nil
      end

      begin
        if object.instance_variable_defined?(
             :@character
           )

          character =
            object.instance_variable_get(
              :@character
            )

          if character == target &&
             object.respond_to?(:x) &&
             object.respond_to?(:y)

            return object
          end
        end
      rescue
      end

      if object.is_a?(Array)
        object.each do |child|
          found =
            recursive_character_sprite(
              child,
              target,
              visited,
              depth + 1
            )

          return found if found
        end

        return nil
      end

      if object.is_a?(Hash)
        object.each_value do |child|
          found =
            recursive_character_sprite(
              child,
              target,
              visited,
              depth + 1
            )

          return found if found
        end

        return nil
      end

      begin
        object.instance_variables.each do |ivar|
          child =
            object.instance_variable_get(
              ivar
            )

          next if child.nil?
          next if child.is_a?(Numeric)
          next if child.is_a?(String)
          next if child.is_a?(Symbol)
          next if child == true
          next if child == false

          found =
            recursive_character_sprite(
              child,
              target,
              visited,
              depth + 1
            )

          return found if found
        end
      rescue
      end

      return nil
    end

    #===========================================================================
    # REAL PLAYER
    #===========================================================================

    def hide_real_player
      return if
        !@map_player_sprite

      begin
        @real_player_visible =
          @map_player_sprite.visible

        @map_player_sprite.visible =
          false
      rescue
      end
    end

    def restore_real_player
      return if
        !@map_player_sprite

      begin
        @map_player_sprite.visible =
          @real_player_visible
      rescue
      end
    end

    #===========================================================================
    # CINEMATIC PLAYER
    #===========================================================================

    def create_cinematic_player
      return if
        !@map_player_sprite

      return if
        !@map_player_sprite.bitmap

      @cinematic_player =
        Sprite.new(
          @viewport
        )

      @cinematic_player.bitmap =
        @map_player_sprite.bitmap

      rect =
        @map_player_sprite.src_rect

      # Always use the standing frame captured before the attack sequence.
      # Even if the hidden real player sprite advances internally later, the
      # cinematic representation stays planted in its idle pose.
      src_x =
        @standing_src_x.nil? ?
        rect.x :
        @standing_src_x

      src_y =
        @standing_src_y.nil? ?
        rect.y :
        @standing_src_y

      src_w =
        @standing_src_w.nil? ?
        rect.width :
        @standing_src_w

      src_h =
        @standing_src_h.nil? ?
        rect.height :
        @standing_src_h

      @cinematic_player.src_rect.set(
        src_x,
        src_y,
        src_w,
        src_h
      )

      @cinematic_player.ox =
        @map_player_sprite.ox

      @cinematic_player.oy =
        @map_player_sprite.oy

      @player_zoom_x =
        @map_player_sprite.zoom_x

      @player_zoom_y =
        @map_player_sprite.zoom_y

      @cinematic_player.z = 180

      apply_player_transform
    end

    def apply_player_transform
      return if
        !@cinematic_player

      x =
        @player_world_x +
        @player_offset_x

      y =
        @player_world_y +
        @player_offset_y

      @cinematic_player.x =
        snap2(
          camera_x(x) +
          (@shake_x || 0)
        )

      @cinematic_player.y =
        snap2(
          camera_y(y) +
          (@shake_y || 0)
        )

      @cinematic_player.zoom_x =
        @player_zoom_x *
        @camera_zoom

      @cinematic_player.zoom_y =
        @player_zoom_y *
        @camera_zoom
    end

    def dispose_cinematic_player
      if @cinematic_player
        @cinematic_player.dispose
        @cinematic_player = nil
      end
    end

    #===========================================================================
    # FOLLOWER
    #===========================================================================

    def hide_follower_immediately
      @follower_was_active =
        false

      begin
        @follower_was_active =
          FollowingPkmn.active?
      rescue
      end

      return if
        !@follower_was_active

      begin
        FollowingPkmn.toggle_off(
          false
        )
      rescue
        begin
          $PokemonGlobal.follower_toggled =
            false
        rescue
        end
      end

      begin
        FollowingPkmn.refresh(
          false
        )
      rescue
        begin
          FollowingPkmn.refresh
        rescue
        end
      end

      update_global_spriteset

      force_follower_sprite_hidden
    end

    def force_follower_sprite_hidden
      return if
        !$scene

      begin
        global =
          $scene.spritesetGlobal

        return if !global

        container =
          global.followingpkmn_sprites

        return if !container

        sprites =
          if container.respond_to?(:sprites)
            container.sprites
          else
            container.instance_variable_get(
              :@sprites
            )
          end

        return if !sprites

        sprites.each do |sprite|
          begin
            sprite.visible =
              false
          rescue
          end
        end
      rescue
      end
    end

    def restore_follower
      return if
        !@follower_was_active

      begin
        FollowingPkmn.toggle_on(
          false
        )
      rescue
        begin
          $PokemonGlobal.follower_toggled =
            true
        rescue
        end
      end

      begin
        FollowingPkmn.refresh(
          false
        )
      rescue
        begin
          FollowingPkmn.refresh
        rescue
        end
      end

      update_global_spriteset

      @follower_was_active =
        false
    end

    #===========================================================================
    # LUGIA
    #===========================================================================

    def create_lugia
      @lugia =
        Sprite.new(
          @viewport
        )

      @lugia.bitmap =
        ShadowLugiaQTE.lugia_bitmap

      @lugia.src_rect.set(
        0,
        0,
        LUGIA_FRAME_W,
        LUGIA_FRAME_H
      )

      @lugia.ox =
        LUGIA_FRAME_W / 2

      @lugia.oy =
        LUGIA_FRAME_H

      @lugia.z       = 170
      @lugia.opacity = 0
    end

    def update_lugia_frame(frame, speed)
      index =
        (frame / speed) %
        LUGIA_ANIM_FRAMES.length

      column =
        LUGIA_ANIM_FRAMES[
          index
        ]

      row =
        lugia_row_for_attack

      @lugia.src_rect.set(
        column *
        LUGIA_FRAME_W,
        row *
        LUGIA_FRAME_H,
        LUGIA_FRAME_W,
        LUGIA_FRAME_H
      )
    end

    def apply_lugia_transform
      return if
        !@lugia

      if @cinematic_active
        @lugia.x =
          snap2(
            camera_x(
              @lugia_world_x
            ) +
            (@shake_x || 0)
          )

        @lugia.y =
          snap2(
            camera_y(
              @lugia_world_y
            ) +
            (@shake_y || 0)
          )

        @lugia.zoom_x =
          @lugia_scale *
          @camera_zoom

        @lugia.zoom_y =
          @lugia_scale *
          @camera_zoom
      else
        @lugia.x =
          snap2(
            @lugia_world_x
          )

        @lugia.y =
          snap2(
            @lugia_world_y
          )

        @lugia.zoom_x =
          @lugia_scale

        @lugia.zoom_y =
          @lugia_scale
      end
    end

    #===========================================================================
    # 2PX GRAPHICS
    #===========================================================================

    def asset_sprite(name, z)
      sprite = Sprite.new(@viewport)
      sprite.bitmap = ShadowLugiaQTE.ui_bitmap(name)
      sprite.zoom_x = 2.0
      sprite.zoom_y = 2.0
      sprite.z = z
      return sprite
    end

    def screen_asset(name, z)
      sprite = asset_sprite(name, z)
      sprite.x = 0
      sprite.y = 0
      return sprite
    end

    def swap_asset(sprite, name)
      old_bitmap = sprite.bitmap
      sprite.bitmap = ShadowLugiaQTE.ui_bitmap(name)
      old_bitmap.dispose if old_bitmap && !old_bitmap.disposed?
    end

    def snap2(value)
      return (
        (value.to_f / 2.0).round *
        2
      )
    end

    #===========================================================================
    # OVERLAYS
    #===========================================================================

    def create_overlays
      @dark_overlay = screen_asset("overlay_dark", 200)
      @dark_overlay.opacity = 0

      @vignette_progress = 0.0
      @vignette_color = Color.new(28, 8, 38)
      @vignette = screen_asset("vignette_threat_00", 210)
      @vignette.opacity = 0

      @flash_overlay = screen_asset("overlay_white", 500)
      @flash_overlay.opacity = 0

      @impact_overlay = screen_asset("overlay_black", 600)
      @impact_overlay.opacity = 0
    end

    #===========================================================================
    # VIGNETTE
    #===========================================================================

    def vignette_frame(progress)
      index = (progress * 32).round
      index = 0 if index < 0
      index = 32 if index > 32
      return sprintf("vignette_threat_%02d", index)
    end

    def update_threat_vignette(progress)
      @vignette_progress = progress
      swap_asset(@vignette, vignette_frame(progress))
      @vignette.opacity = 225
    end

    def release_vignette_on_dodge
      start_opacity = @vignette.opacity

      6.times do |frame|
        t = frame.to_f / 5.0
        @vignette.opacity = lerp(start_opacity, 0, ease_out_cubic(t)).to_i
        qte_update
      end

      @vignette.opacity = 0
      @vignette_progress = 0.0
      swap_asset(@vignette, "vignette_threat_00")
    end

    def consume_vignette_on_hit
      7.times do |frame|
        swap_asset(@vignette, sprintf("vignette_hit_%02d", frame))
        @vignette.opacity = 255
        update_camera
        qte_update
      end

      @vignette_progress = 1.0
      @vignette.opacity = 255
    end

    def recolor_vignette(color)
      # Compatibility hook.
    end

    #===========================================================================
    # LETTERBOX
    #===========================================================================

    def create_letterbox
      @letterbox_top = asset_sprite("letterbox", 400)
      @letterbox_top.y = -LETTERBOX_HEIGHT

      @letterbox_bottom = asset_sprite("letterbox", 400)
      @letterbox_bottom.y = Graphics.height
    end

    #===========================================================================
    # SPEED LINES
    #===========================================================================

    def create_speed_lines
      @speed_lines = screen_asset("speed_vertical_slow_00", 160)
      @speed_lines.opacity = 0
    end

    def animate_speed_lines_directional(frame, direction, fast)
      orientation = vertical_attack?(direction) ? "vertical" : "horizontal"
      speed = fast ? "fast" : "slow"
      index = frame % 32

      swap_asset(
        @speed_lines,
        sprintf("speed_%s_%s_%02d", orientation, speed, index)
      )

      @speed_lines.opacity = fast ? 180 : 48
    end

    #===========================================================================
    # METER
    #===========================================================================

    def create_meter
      dispose_meter

      meter_x =
        snap2(
          (Graphics.width -
          METER_WIDTH) / 2
        )

      meter_y =
        snap2(
          Graphics.height -
          METER_BOTTOM_MARGIN -
          METER_HEIGHT
        )

      @meter = asset_sprite("meter", 300)

      @meter.x =
        meter_x

      @meter.y =
        meter_y + 12

      3.times do |frame|
        t =
          frame.to_f /
          2.0

        @meter.y =
          snap2(
            lerp(
              meter_y + 12,
              meter_y,
              ease_out_cubic(t)
            )
          )

        qte_update
      end

      @marker = asset_sprite("marker", 312)

      @marker.ox =
        MARKER_WIDTH / 4

      @marker.oy =
        MARKER_HEIGHT / 4

      @marker.x =
        meter_x

      @marker.y =
        meter_y +
        (METER_HEIGHT / 2)

      # Keep text native-res so the font stays crisp.
      @prompt =
        Sprite.new(
          @viewport
        )

      @prompt.bitmap =
        Bitmap.new(
          Graphics.width,
          44
        )

      @prompt.z = 320

      pbSetSystemFont(
        @prompt.bitmap
      ) rescue nil

      @prompt.bitmap.font.size = 28
      @prompt.bitmap.font.bold = true

      @prompt.bitmap.font.color =
        Color.new(
          255,
          255,
          255
        )

      @prompt.bitmap.draw_text(
        0,
        0,
        Graphics.width,
        40,
        "DODGE!",
        1
      )

      @prompt.y =
        snap2(
          meter_y - 50
        )
    end

    def animate_prompt(frame)
      return if !@prompt

      if frame < 4
        scale =
          lerp(
            1.12,
            1.0,
            frame.to_f / 3.0
          )

        @prompt.zoom_x = scale
        @prompt.zoom_y = scale
      else
        @prompt.zoom_x = 1.0
        @prompt.zoom_y = 1.0
      end
    end

    def meter_hit_snap
      2.times do |frame|
        scale =
          frame == 0 ?
          0.86 :
          1.0

        @meter.zoom_y =
          2.0 * scale

        qte_update
      end
    end

    #===========================================================================
    # PLAYER AFTERIMAGES
    #===========================================================================

    def spawn_player_afterimage
      return if
        !@cinematic_player

      sprite =
        Sprite.new(
          @viewport
        )

      sprite.bitmap =
        @cinematic_player.bitmap

      sprite.src_rect.set(
        @cinematic_player.src_rect.x,
        @cinematic_player.src_rect.y,
        @cinematic_player.src_rect.width,
        @cinematic_player.src_rect.height
      )

      sprite.ox =
        @cinematic_player.ox

      sprite.oy =
        @cinematic_player.oy

      sprite.x =
        @cinematic_player.x

      sprite.y =
        @cinematic_player.y

      sprite.zoom_x =
        @cinematic_player.zoom_x

      sprite.zoom_y =
        @cinematic_player.zoom_y

      sprite.opacity = 120
      sprite.z = 175

      @player_afterimages << {
        :sprite => sprite,
        :life   => 6
      }
    end

    def update_player_afterimages
      dead = []

      @player_afterimages.each do |entry|
        entry[:life] -= 1

        sprite =
          entry[:sprite]

        sprite.opacity -= 22

        sprite.opacity = 0 if
          sprite.opacity < 0

        dead << entry if
          entry[:life] <= 0
      end

      dead.each do |entry|
        entry[:sprite].dispose

        @player_afterimages.delete(
          entry
        )
      end
    end

    def clear_player_afterimages
      @player_afterimages.each do |entry|
        sprite =
          entry[:sprite]

        sprite.dispose if
          sprite &&
          !sprite.disposed?
      end

      @player_afterimages.clear
    end

    #===========================================================================
    # LUGIA AFTERIMAGES
    #===========================================================================

    def spawn_lugia_afterimage
      return if
        !@lugia

      sprite =
        Sprite.new(
          @viewport
        )

      sprite.bitmap =
        @lugia.bitmap

      sprite.src_rect.set(
        @lugia.src_rect.x,
        @lugia.src_rect.y,
        @lugia.src_rect.width,
        @lugia.src_rect.height
      )

      sprite.ox =
        @lugia.ox

      sprite.oy =
        @lugia.oy

      sprite.x =
        @lugia.x

      sprite.y =
        @lugia.y

      sprite.zoom_x =
        @lugia.zoom_x

      sprite.zoom_y =
        @lugia.zoom_y

      sprite.opacity = 110
      sprite.z = 165

      @lugia_afterimages << {
        :sprite => sprite,
        :life   => 7
      }
    end

    def update_lugia_afterimages
      dead = []

      @lugia_afterimages.each do |entry|
        entry[:life] -= 1

        sprite =
          entry[:sprite]

        sprite.opacity -= 18

        sprite.opacity = 0 if
          sprite.opacity < 0

        dead << entry if
          entry[:life] <= 0
      end

      dead.each do |entry|
        entry[:sprite].dispose

        @lugia_afterimages.delete(
          entry
        )
      end
    end

    def clear_lugia_afterimages
      @lugia_afterimages.each do |entry|
        sprite =
          entry[:sprite]

        sprite.dispose if
          sprite &&
          !sprite.disposed?
      end

      @lugia_afterimages.clear
    end

    #===========================================================================
    # IMPACT
    #===========================================================================

    def impact_frame(color, opacity)
      name =
        if color.red < 20 && color.green < 20 && color.blue < 20
          "overlay_black"
        elsif color.red > 240 && color.green > 240 && color.blue > 240
          "overlay_white"
        else
          "overlay_impact_red"
        end

      swap_asset(@impact_overlay, name)
      @impact_overlay.opacity = opacity
    end

    def flash(color, opacity)
      name =
        if color.red > 240 && color.green > 240 && color.blue > 240
          "overlay_white"
        elsif color.red > 180 && color.green < 40
          "overlay_red"
        else
          "overlay_purple"
        end

      swap_asset(@flash_overlay, name)
      @flash_overlay.opacity = opacity
    end

    def fade_flash(amount)
      return if
        @flash_overlay.opacity <= 0

      @flash_overlay.opacity -=
        amount

      @flash_overlay.opacity = 0 if
        @flash_overlay.opacity < 0
    end

    #===========================================================================
    # SHAKE
    #===========================================================================

    def shake(frame, power)
      x =
        frame % 2 == 0 ?
        -power :
        power

      y =
        frame % 4 < 2 ?
        -(power / 2) :
        (power / 2)

      @shake_x = snap2(x)
      @shake_y = snap2(y)

      # Only the captured world viewport moves. @viewport contains our
      # screen-space overlays/UI, so it must stay perfectly screen-locked.
      if @world_viewport
        @world_viewport.rect.x = @shake_x
        @world_viewport.rect.y = @shake_y
      end

      apply_player_transform if @cinematic_active
      apply_lugia_transform
    end

    def reset_shake
      @shake_x = 0
      @shake_y = 0

      if @world_viewport
        @world_viewport.rect.x = 0
        @world_viewport.rect.y = 0
      end

      apply_player_transform if @cinematic_active
      apply_lugia_transform
    end

    #===========================================================================
    # UPDATE
    #===========================================================================

    def qte_update
      Graphics.update
      Input.update

      update_map_spriteset

      force_follower_sprite_hidden if
        @follower_was_active

      update_camera if
        @cinematic_active
    end

    def update_map_spriteset
      return if
        !$scene

      begin
        spriteset =
          $scene.instance_variable_get(
            :@spriteset
          )

        spriteset.update if
          spriteset
      rescue
      end
    end

    def update_global_spriteset
      return if
        !$scene

      begin
        global =
          $scene.spritesetGlobal

        global.update if
          global
      rescue
      end
    end

    #===========================================================================
    # HELPERS
    #===========================================================================

    def player_screen_x
      return $game_player.screen_x
    rescue
      return Graphics.width / 2
    end

    def player_screen_y
      return $game_player.screen_y
    rescue
      return Graphics.height / 2
    end

    def lerp(a, b, t)
      return a +
        ((b - a) * t)
    end

    def ease_out_cubic(t)
      t = 0.0 if t < 0.0
      t = 1.0 if t > 1.0

      return 1.0 -
        ((1.0 - t) ** 3)
    end

    def ease_in_cubic(t)
      t = 0.0 if t < 0.0
      t = 1.0 if t > 1.0

      return t * t * t
    end

    def ease_out_back(t)
      t = 0.0 if t < 0.0
      t = 1.0 if t > 1.0

      c1 =
        1.70158

      c3 =
        c1 + 1.0

      x =
        t - 1.0

      return 1.0 +
        (c3 * x * x * x) +
        (c1 * x * x)
    end

    #===========================================================================
    # VIEWPORTS
    #===========================================================================

    def create_viewports
      @world_viewport =
        Viewport.new(
          0,
          0,
          Graphics.width,
          Graphics.height
        )

      @world_viewport.z =
        99998

      @viewport =
        Viewport.new(
          0,
          0,
          Graphics.width,
          Graphics.height
        )

      @viewport.z =
        99999
    end

    #===========================================================================
    # CLEANUP
    #===========================================================================

    def dispose_meter
      [
        @meter,
        @marker,
        @prompt
      ].each do |sprite|
        next if !sprite

        if sprite.bitmap &&
           !sprite.bitmap.disposed?

          sprite.bitmap.dispose
        end

        sprite.dispose
      end

      @meter  = nil
      @marker = nil
      @prompt = nil
    end

    def dispose_hearts
      @heart_sprites.each do |heart|
        next if !heart

        if heart.bitmap &&
           !heart.bitmap.disposed?

          heart.bitmap.dispose
        end

        heart.dispose if
          !heart.disposed?
      end

      @heart_sprites.clear
    end

    def dispose_pixel_sprite(sprite)
      return if !sprite

      if sprite.bitmap &&
         !sprite.bitmap.disposed?

        sprite.bitmap.dispose
      end

      sprite.dispose
    end

    def dispose
      return if @disposed

      dispose_meter
      dispose_hearts

      clear_player_afterimages
      clear_lugia_afterimages

      reset_shake

      dispose_cinematic_player

      restore_real_player

      if @world_sprite
        @world_sprite.dispose
        @world_sprite = nil
      end

      if @world_bitmap
        if !@world_bitmap.disposed?
          @world_bitmap.dispose
        end

        @world_bitmap = nil
      end

      # Lugia uses module-level cached bitmap.
      if @lugia
        @lugia.dispose
        @lugia = nil
      end

      dispose_pixel_sprite(
        @dark_overlay
      )

      dispose_pixel_sprite(
        @vignette
      )

      dispose_pixel_sprite(
        @flash_overlay
      )

      dispose_pixel_sprite(
        @impact_overlay
      )

      dispose_pixel_sprite(
        @letterbox_top
      )

      dispose_pixel_sprite(
        @letterbox_bottom
      )

      dispose_pixel_sprite(
        @speed_lines
      )

      @dark_overlay      = nil
      @vignette          = nil
      @flash_overlay     = nil
      @impact_overlay    = nil
      @letterbox_top     = nil
      @letterbox_bottom  = nil
      @speed_lines       = nil

      if @viewport
        @viewport.dispose
        @viewport = nil
      end

      if @world_viewport
        @world_viewport.dispose
        @world_viewport = nil
      end

      restore_follower

      @disposed = true
    end

  end
end