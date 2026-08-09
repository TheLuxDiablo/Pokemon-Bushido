#===============================================================================
# Pokémon Bushido - Custom Starter Selection
#===============================================================================

module BushidoStarterSelection
  #=============================================================================
  # Starter setup
  #=============================================================================

  DEFAULT_STARTERS = [
    :TREECKO,
    :OSHAWOTT,
    :FENNEKIN
  ]

  STARTER_LEVEL = 5

  STARTER_VARIABLE_IDS       = [73, 74, 75]
  STARTER_CHOICE_VARIABLE_ID = 1031

  # Matches the old starter event's 1-in-201 shiny roll.
  SHINY_ROLL_MAX    = 200
  SHINY_ROLL_RESULT = 1

  # Set true only if the event calling this screen safely handles cancellation.
  ALLOW_CANCEL = false

  #=============================================================================
  # Debug testing
  #=============================================================================
  # :OFF    - Normal behavior
  # :SHINY  - Force all three starters shiny
  # :RANDOM - Force three random species
  # :BOTH   - Force random species and shininess
  #
  # Put this back to :OFF before release.
  DEBUG_MODE = :OFF

  #=============================================================================
  # Regional forms
  #=============================================================================
  # Form numbers are project-specific. Only add forms that exist in Bushido.
  #
  # Example:
  # REGIONAL_FORMS = {
  #   :TYPHLOSION => [1],
  #   :SAMUROTT   => [1],
  #   :DECIDUEYE  => [1]
  # }
  REGIONAL_FORMS = {}

  # Only applies to randomized species listed above.
  RANDOM_REGIONAL_FORM_CHANCE = 100

  #=============================================================================
  # Optional audio
  #=============================================================================

  MOVE_SE    = "GUI sel cursor"
  CONFIRM_SE = "GUI sel decision"
  CANCEL_SE  = "GUI sel cancel"
  SHINY_SE   = "Battle shiny"

  #=============================================================================
  # Debug helpers
  #=============================================================================

  def self.debugRandom?
    return DEBUG_MODE == :RANDOM || DEBUG_MODE == :BOTH
  end

  def self.debugShiny?
    return DEBUG_MODE == :SHINY || DEBUG_MODE == :BOTH
  end

  def self.safeSEPlay(name, volume = 80, pitch = 100)
    return if !name || name.to_s.length == 0
    begin
      pbSEPlay(name, volume, pitch)
    rescue
      # Optional UI audio must never break starter selection.
    end
  end

  def self.getDebugRandomSpecies
    allowed_species = nil

    if $PokemonGlobal &&
       $PokemonGlobal.randomizedData &&
       $PokemonGlobal.randomizedData[:ALLOWED_SPECIES]
      allowed_species = $PokemonGlobal.randomizedData[:ALLOWED_SPECIES].clone
    end

    allowed_species = (1..PBSpecies.maxValue).to_a if
      !allowed_species || allowed_species.length == 0

    allowed_species.compact!
    allowed_species.delete_if do |species|
      !species.is_a?(Numeric) || species <= 0
    end

    raise "No valid species were available for starter testing." if
      allowed_species.length == 0

    return allowed_species[rand(allowed_species.length)]
  end

  #=============================================================================
  # Starter generation
  #=============================================================================

  def self.generateStarters
    starters = []

    DEFAULT_STARTERS.each_with_index do |entry, index|
      pokemon = generateStarter(entry)

      applyRandomRegionalForm(pokemon)
      applyShinyRoll(pokemon)
      finalizePokemon(pokemon)

      starters.push(pokemon)

      variable_id = STARTER_VARIABLE_IDS[index]
      pbSet(variable_id, pokemon) if variable_id
    end

    return starters
  end

  def self.generateStarter(entry)
    species = nil
    form = 0

    if entry.is_a?(Hash)
      species = entry[:species]
      form = entry[:form] || 0
    else
      species = entry
    end

    if debugRandom?
      species = getDebugRandomSpecies
      form = 0
    elsif species.is_a?(Symbol) || species.is_a?(String)
      species = getID(PBSpecies, species)
    end

    raise "Could not resolve starter species #{entry.inspect}." if
      !species || species == 0

    pokemon = PokeBattle_Pokemon.new(
      species,
      STARTER_LEVEL,
      $Trainer
    )

    pokemon.form = form if pokemon.respond_to?(:form=)

    pokemon = randomizeStarter(pokemon) if
      !debugRandom? && defined?(randomizeStarter)

    return pokemon
  end

  def self.applyRandomRegionalForm(pokemon)
    return pokemon if !pokemon
    return pokemon if RANDOM_REGIONAL_FORM_CHANCE <= 0
    return pokemon if rand(100) >= RANDOM_REGIONAL_FORM_CHANCE
    return pokemon if !pokemon.respond_to?(:form=)

    species_name = getConstantName(PBSpecies, pokemon.species)
    return pokemon if !species_name

    forms = REGIONAL_FORMS[species_name.to_sym]
    return pokemon if !forms || !forms.is_a?(Array) || forms.length == 0

    pokemon.form = forms[rand(forms.length)]
    return pokemon
  end

  def self.applyShinyRoll(pokemon)
    return pokemon if !pokemon

    if debugShiny?
      pokemon.makeShiny
      return pokemon
    end

    pokemon.makeShiny if rand(SHINY_ROLL_MAX + 1) == SHINY_ROLL_RESULT
    return pokemon
  end

  def self.finalizePokemon(pokemon)
    return pokemon if !pokemon

    pokemon.calcStats
    pokemon.resetMoves if pokemon.respond_to?(:resetMoves)

    return pokemon
  end

  def self.validateStarters(starters)
    raise "The starter selector generated no Pokémon." if
      !starters || starters.length == 0

    raise "Starter selection requires at least 2 Pokémon." if starters.length < 2

    starters.each_with_index do |pokemon, index|
      next if pokemon && pokemon.respond_to?(:species)

      raise(
        "Starter slot #{index + 1} is invalid. " +
        "Expected a Pokémon object, but received #{pokemon.inspect}."
      )
    end
  end

  #=============================================================================
  # Starter selection scene
  #=============================================================================

  class Scene
    #---------------------------------------------------------------------------
    # Layout
    #---------------------------------------------------------------------------

    SCREEN_W = Graphics.width
    SCREEN_H = Graphics.height
    CENTER_X = SCREEN_W / 2

    SUBHEADER_Y   = 10
    DIVIDER_Y     = 40

    CARD_WIDTH    = 142
    CARD_HEIGHT   = 220
    CARD_CENTER_Y = 166
    SIDE_DISTANCE = 158

    CARD_BITMAP_HEIGHT    = CARD_HEIGHT + 12
    CARD_RING_LOCAL_Y     = 99
    SELECTED_CARD_CENTER_Y = CARD_CENTER_Y - 3

    BACKGROUND_RING_Y =
      SELECTED_CARD_CENTER_Y -
      (CARD_BITMAP_HEIGHT / 2) +
      CARD_RING_LOCAL_Y

    POKEMON_ROW_Y = 166

    SELECTED_Y_OFFSET = -6
    SIDE_Y_OFFSET     = 9

    INFO_PANEL_H = 104
    INFO_PANEL_Y = SCREEN_H - INFO_PANEL_H - 8

    INFO_NAME_Y     = INFO_PANEL_Y + 15
    INFO_TYPE_Y     = INFO_PANEL_Y + 46
    INFO_CATEGORY_Y = INFO_PANEL_Y + 78

    #---------------------------------------------------------------------------
    # Scale and silhouettes
    #---------------------------------------------------------------------------

    SELECTED_ZOOM = 1.20
    SIDE_ZOOM     = 0.78

    SELECTED_CARD_ZOOM = 1.00
    SIDE_CARD_ZOOM     = 0.92

    SELECTED_DIM_ALPHA = 0
    SIDE_DIM_ALPHA     = 170

    #---------------------------------------------------------------------------
    # Carousel timing
    #---------------------------------------------------------------------------

    POSITION_SPEED = 0.18
    ZOOM_SPEED     = 0.14
    DIM_SPEED      = 0.18

    SETTLE_POSITION_EPSILON = 0.75
    SETTLE_ZOOM_EPSILON     = 0.01
    SETTLE_DIM_EPSILON      = 2.0

    REVEAL_FEEDBACK_ALPHA = 32

    INTRO_FADE_FRAMES   = 24
    INTRO_SETTLE_FRAMES = 30
    INTRO_START_OFFSET  = 26

    #---------------------------------------------------------------------------
    # Input behavior
    #---------------------------------------------------------------------------

    INPUT_INITIAL_DELAY = 14
    INPUT_REPEAT_DELAY  = 5

    REVEAL_FEEDBACK_DELAY = 7

    #---------------------------------------------------------------------------
    # Bushido palette
    #---------------------------------------------------------------------------

    INK            = Color.new(16, 14, 18)
    INK_SOFT       = Color.new(31, 27, 31)
    INK_FAINT      = Color.new(53, 45, 48)
    PAPER          = Color.new(235, 224, 202)
    PAPER_DARK     = Color.new(205, 189, 161)
    PAPER_SHADOW   = Color.new(146, 126, 102)
    BUSHIDO_RED    = Color.new(150, 34, 40)
    BUSHIDO_RED_2  = Color.new(102, 21, 28)
    GOLD           = Color.new(190, 150, 79)
    WHITE          = Color.new(250, 247, 239)
    MUTED_WHITE    = Color.new(213, 205, 192)
    BLACK          = Color.new(0, 0, 0)

    NAME_BASE_COLOR   = WHITE
    NAME_SHADOW_COLOR = Color.new(55, 34, 35)

    TEXT_BASE_COLOR   = Color.new(50, 42, 44)
    TEXT_SHADOW_COLOR = Color.new(218, 205, 184)

    #---------------------------------------------------------------------------
    # Type badges
    #---------------------------------------------------------------------------

    TYPE_BADGE_PATH   = "Graphics/Pictures/types"
    TYPE_BADGE_WIDTH  = 64
    TYPE_BADGE_HEIGHT = 28
    TYPE_BADGE_GAP    = 8
    TYPE_BADGE_Y      = INFO_TYPE_Y

    #---------------------------------------------------------------------------
    # Ambient falling leaves
    #---------------------------------------------------------------------------

    PETAL_COUNT = 45

    LEAF_Z = 2

    LEAF_MIN_SPEED = 0.60
    LEAF_MAX_SPEED = 1.35

    LEAF_MIN_DRIFT = -0.58
    LEAF_MAX_DRIFT = -0.14

    LEAF_MIN_OPACITY = 135
    LEAF_MAX_OPACITY = 210

    #---------------------------------------------------------------------------
    # Shiny feedback
    #---------------------------------------------------------------------------

    SHINY_FEEDBACK_FRAMES = 24
    SHINY_SPARKLE_COUNT   = 10

    #---------------------------------------------------------------------------
    # Confirmation timing
    #---------------------------------------------------------------------------

    CONFIRM_HOP_FRAMES  = 36
    CONFIRM_HOP_HEIGHT  = 20
    CONFIRM_ZOOM_BOOST  = 0.13
    CONFIRM_HOLD_FRAMES = 10

    WHITE_OUT_FRAMES  = 28
    RETURN_FADE_FRAMES = 24

    #---------------------------------------------------------------------------
    # Setup
    #---------------------------------------------------------------------------

    def initialize(starters)
      @starter_pokemon = starters
    end

    def pbStartScene
      @viewport = Viewport.new(0, 0, SCREEN_W, SCREEN_H)
      @viewport.z = 99999

      @sprites = {}
      @petals  = []

      @selected_index = 0
      @chosen_pokemon = nil
      @pending_reveal_feedback = false
      @reveal_feedback_frames = 0

      @shiny_feedback_active = false
      @shiny_feedback_frame = 0
      @shiny_feedback_index = nil

      @input_locked = true
      @intro_active = true
      @white_out_complete = false

      @left_hold_frames  = 0
      @right_hold_frames = 0

      @target_x          = {}
      @target_y          = {}
      @target_zoom       = {}
      @target_dim        = {}
      @current_dim       = {}
      @target_card_x     = {}
      @target_card_y     = {}
      @target_card_zoom  = {}

      createBackground
      createAmbientPetals
      createChrome
      createStarterCards
      createStarterSprites
      createStarterInfo
      createShinyFeedback
      createTransitionOverlay

      refreshStarterTargets(true)
      refreshChrome
      refreshStarterInfo

      prepareIntroPositions
      Graphics.transition(INTRO_FADE_FRAMES)
      playIntroAnimation

      @intro_active = false
      @input_locked = false

      playRevealFeedback
    end

    #---------------------------------------------------------------------------
    # Drawing helpers
    #---------------------------------------------------------------------------

    def drawDiamond(bitmap, cx, cy, radius, color)
      radius = radius.to_i
      (-radius..radius).each do |dy|
        half = radius - dy.abs
        bitmap.fill_rect(cx - half, cy + dy, half * 2 + 1, 1, color)
      end
    end

    def drawRing(bitmap, cx, cy, radius, thickness, color)
      outer = radius
      inner = [radius - thickness, 0].max

      (-outer..outer).each do |dy|
        outer_half = Math.sqrt([outer * outer - dy * dy, 0].max).to_i
        inner_half = if dy.abs <= inner
                       Math.sqrt([inner * inner - dy * dy, 0].max).to_i
                     else
                       -1
                     end

        if inner_half < 0
          bitmap.fill_rect(cx - outer_half, cy + dy, outer_half * 2 + 1, 1, color)
        else
          left_width = outer_half - inner_half
          if left_width > 0
            bitmap.fill_rect(cx - outer_half, cy + dy, left_width, 1, color)
            bitmap.fill_rect(cx + inner_half + 1, cy + dy, left_width, 1, color)
          end
        end
      end
    end

    def drawPanel(bitmap, x, y, width, height, fill, border, border_size = 2)
      bitmap.fill_rect(x, y, width, height, fill)
      border_size.times do |i|
        bitmap.fill_rect(x + i, y + i, width - i * 2, 1, border)
        bitmap.fill_rect(x + i, y + height - 1 - i, width - i * 2, 1, border)
        bitmap.fill_rect(x + i, y + i, 1, height - i * 2, border)
        bitmap.fill_rect(x + width - 1 - i, y + i, 1, height - i * 2, border)
      end
    end

    def drawCornerMarks(bitmap, x, y, width, height, color, length = 11)
      bitmap.fill_rect(x, y, length, 2, color)
      bitmap.fill_rect(x, y, 2, length, color)

      bitmap.fill_rect(x + width - length, y, length, 2, color)
      bitmap.fill_rect(x + width - 2, y, 2, length, color)

      bitmap.fill_rect(x, y + height - 2, length, 2, color)
      bitmap.fill_rect(x, y + height - length, 2, length, color)

      bitmap.fill_rect(x + width - length, y + height - 2, length, 2, color)
      bitmap.fill_rect(x + width - 2, y + height - length, 2, length, color)
    end

    def drawCenteredText(bitmap, text, y, base, shadow, size = 22, bold = false)
      old_size = bitmap.font.size
      old_bold = bitmap.font.bold

      bitmap.font.size = size
      bitmap.font.bold = bold

      pbDrawTextPositions(bitmap, [[text, CENTER_X, y, 2, base, shadow]])

      bitmap.font.size = old_size
      bitmap.font.bold = old_bold
    end

    def drawLeftText(bitmap, text, x, y, base, shadow, size = 20, bold = false)
      old_size = bitmap.font.size
      old_bold = bitmap.font.bold

      bitmap.font.size = size
      bitmap.font.bold = bold

      pbDrawTextPositions(bitmap, [[text, x, y, 0, base, shadow]])

      bitmap.font.size = old_size
      bitmap.font.bold = old_bold
    end

    def safePokemonName(pokemon)
      return "UNKNOWN" if !pokemon
      return pokemon.name.to_s.upcase
    rescue
      return "UNKNOWN"
    end

    def safeCategory(pokemon)
      return "" if !pokemon

      begin
        category = pbGetMessage(MessageTypes::Kinds, pokemon.species).to_s
        return category.length > 0 ? "The #{category} Pokémon" : ""
      rescue
        return ""
      end
    end

    def safeTypeName(type)
      begin
        return PBTypes.getName(type).to_s.upcase
      rescue
        return type.to_s.upcase
      end
    end

    def typeAccentColor(type, alpha = 255)
      name = safeTypeName(type)

      rgb = case name
            when "NORMAL"   then [116, 108, 96]
            when "FIGHTING" then [164, 61, 49]
            when "FLYING"   then [110, 126, 184]
            when "POISON"   then [137, 75, 147]
            when "GROUND"   then [170, 126, 70]
            when "ROCK"     then [133, 105, 67]
            when "BUG"      then [109, 137, 58]
            when "GHOST"    then [91, 72, 130]
            when "STEEL"    then [100, 116, 126]
            when "FIRE"     then [191, 70, 44]
            when "WATER"    then [52, 125, 176]
            when "GRASS"    then [76, 139, 72]
            when "ELECTRIC" then [199, 157, 49]
            when "PSYCHIC"  then [177, 73, 118]
            when "ICE"      then [79, 155, 168]
            when "DRAGON"   then [93, 75, 158]
            when "DARK"     then [75, 65, 64]
            when "FAIRY"    then [185, 104, 139]
            when "SHADOW"   then [74, 54, 91]
            else                  [150, 34, 40]
            end

      return Color.new(rgb[0], rgb[1], rgb[2], alpha)
    end

    def pokemonAccentColor(pokemon, alpha = 255)
      return Color.new(150, 34, 40, alpha) if !pokemon
      return typeAccentColor(pokemon.type1, alpha)
    rescue
      return Color.new(150, 34, 40, alpha)
    end

    #---------------------------------------------------------------------------
    # Intro
    #---------------------------------------------------------------------------

    def prepareIntroPositions
      @starter_pokemon.each_with_index do |_pokemon, index|
        sprite = @sprites["starter_#{index}"]
        next if !sprite

        sprite.y = @target_y[index] + INTRO_START_OFFSET

        card = @sprites["card_#{index}"]
        card.y = @target_card_y[index] + INTRO_START_OFFSET if card

        @current_dim[index] = SIDE_DIM_ALPHA
        applySpriteDim(sprite, SIDE_DIM_ALPHA)
      end
    end

    def playIntroAnimation
      INTRO_SETTLE_FRAMES.times do |frame|
        progress = INTRO_SETTLE_FRAMES <= 1 ? 1.0 :
          frame / (INTRO_SETTLE_FRAMES - 1).to_f
        eased = progress * progress * (3.0 - 2.0 * progress)

        @starter_pokemon.each_with_index do |_pokemon, index|
          sprite = @sprites["starter_#{index}"]
          next if !sprite

          start_y = @target_y[index] + INTRO_START_OFFSET
          target_y = @target_y[index]
          sprite.y = start_y + (target_y - start_y) * eased

          card = @sprites["card_#{index}"]
          if card
            card_start_y = @target_card_y[index] + INTRO_START_OFFSET
            card.y = card_start_y + (@target_card_y[index] - card_start_y) * eased
          end

          start_dim = SIDE_DIM_ALPHA
          target_dim = @target_dim[index]
          current_dim = start_dim + (target_dim - start_dim) * eased

          @current_dim[index] = current_dim
          applySpriteDim(sprite, current_dim)
        end

        updateAmbientPetals
        Graphics.update
        Input.update
        pbUpdateSpriteHash(@sprites)
      end

      refreshStarterTargets(true)
    end

    #---------------------------------------------------------------------------
    # Scene graphics
    #---------------------------------------------------------------------------

    def createBackground
      sprite = Sprite.new(@viewport)
      sprite.bitmap = Bitmap.new(SCREEN_W, SCREEN_H)
      sprite.z = 0

      bitmap = sprite.bitmap

      SCREEN_H.times do |y|
        t = y / [SCREEN_H - 1, 1].max.to_f
        r = (238 - 32 * t).to_i
        g = (228 - 38 * t).to_i
        b = (207 - 41 * t).to_i
        bitmap.fill_rect(0, y, SCREEN_W, 1, Color.new(r, g, b))
      end

      drawRing(
        bitmap,
        CENTER_X,
        BACKGROUND_RING_Y,
        105,
        4,
        Color.new(131, 47, 44, 54)
      )
      drawRing(
        bitmap,
        CENTER_X,
        BACKGROUND_RING_Y,
        98,
        1,
        Color.new(131, 47, 44, 38)
      )

      bitmap.fill_rect(0, 64, 112, 5, Color.new(28, 24, 27, 32))
      bitmap.fill_rect(0, 72, 78, 2, Color.new(28, 24, 27, 25))
      bitmap.fill_rect(SCREEN_W - 126, 58, 126, 4, Color.new(28, 24, 27, 30))
      bitmap.fill_rect(SCREEN_W - 84, 66, 84, 2, Color.new(28, 24, 27, 24))

      @sprites["background"] = sprite
    end

    def createAmbientPetals
      PETAL_COUNT.times do |index|
        sprite = Sprite.new(@viewport)
        sprite.bitmap = createLeafBitmap(index)
        sprite.ox = sprite.bitmap.width / 2
        sprite.oy = sprite.bitmap.height / 2

        sprite.z = LEAF_Z

        data = {
          :sprite => sprite,
          :speed  => randomLeafRange(LEAF_MIN_SPEED, LEAF_MAX_SPEED),
          :drift  => randomLeafRange(LEAF_MIN_DRIFT, LEAF_MAX_DRIFT),
          :spin   => randomLeafRange(-2.4, 2.4),
          :sway   => randomLeafRange(0.10, 0.32),
          :phase  => rand(360),
          :scale  => 0.90 + rand(71) / 100.0
        }

        sprite.zoom_x = data[:scale]
        sprite.zoom_y = data[:scale]

        resetPetal(data, true, index)
        @petals.push(data)
      end
    end

    def createLeafBitmap(index)
      bitmap = Bitmap.new(11, 11)

      palettes = [
        [
          Color.new(151, 24, 30),
          Color.new(191, 42, 41),
          Color.new(111, 16, 24)
        ],
        [
          Color.new(176, 36, 31),
          Color.new(211, 61, 42),
          Color.new(124, 22, 23)
        ],
        [
          Color.new(128, 24, 33),
          Color.new(173, 39, 46),
          Color.new(91, 18, 26)
        ]
      ]

      palette = palettes[index % palettes.length]
      base    = palette[0]
      light   = palette[1]
      dark    = palette[2]

      bitmap.fill_rect(5, 1, 1, 8, dark)

      bitmap.fill_rect(4, 2, 3, 1, base)
      bitmap.fill_rect(3, 3, 5, 1, base)
      bitmap.fill_rect(2, 4, 7, 1, base)
      bitmap.fill_rect(1, 5, 9, 1, base)
      bitmap.fill_rect(3, 6, 5, 1, base)
      bitmap.fill_rect(4, 7, 3, 1, base)

      bitmap.fill_rect(0, 4, 3, 1, base)
      bitmap.fill_rect(8, 4, 3, 1, base)
      bitmap.fill_rect(2, 2, 2, 1, base)
      bitmap.fill_rect(7, 2, 2, 1, base)
      bitmap.fill_rect(2, 6, 2, 1, dark)
      bitmap.fill_rect(7, 6, 2, 1, dark)

      bitmap.fill_rect(4, 3, 2, 1, light)
      bitmap.fill_rect(3, 4, 2, 1, light)

      bitmap.fill_rect(5, 8, 1, 3, dark)

      return bitmap
    end

    def randomLeafRange(minimum, maximum)
      return minimum + rand(1001) / 1000.0 * (maximum - minimum)
    end

    def resetPetal(data, initial = false, index = 0)
      sprite = data[:sprite]

      if initial
        sprite.x = rand(SCREEN_W + 60) - 20
        sprite.y = rand(SCREEN_H + 70) - 40
      else
        if rand(100) < 30
          sprite.x = SCREEN_W + 8 + rand(42)
          sprite.y = rand((SCREEN_H * 0.72).to_i)
        else
          sprite.x = rand(SCREEN_W + 70)
          sprite.y = -14 - rand(70)
        end
      end

      sprite.opacity =
        LEAF_MIN_OPACITY +
        rand(LEAF_MAX_OPACITY - LEAF_MIN_OPACITY + 1)

      sprite.angle = rand(360)

      if initial && index % 4 == 0
        sprite.x = SCREEN_W - rand(140)
      end

      updateLeafVisibility(data)
    end

    def updateAmbientPetals
      @petals.each do |data|
        sprite = data[:sprite]
        next if !sprite || sprite.disposed?

        frame = Graphics.frame_count + data[:phase]

        sprite.y += data[:speed]
        sprite.x +=
          data[:drift] +
          Math.sin(frame / 22.0) * data[:sway]

        sprite.angle += data[:spin]

        flutter = 0.82 + Math.sin(frame / 13.0).abs * 0.18
        sprite.zoom_x = data[:scale] * flutter
        sprite.zoom_y = data[:scale]

        if sprite.y > SCREEN_H + 16 ||
           sprite.x < -12 ||
           sprite.x > SCREEN_W + 55
          resetPetal(data)
          next
        end

        updateLeafVisibility(data)
      end
    end

    def updateLeafVisibility(data)
      sprite = data[:sprite]
      return if !sprite || sprite.disposed?
      sprite.visible = true
    end

    def createChrome
      @sprites["chrome"] = BitmapSprite.new(SCREEN_W, SCREEN_H, @viewport)

      @sprites["chrome"].z = 3
      pbSetSystemFont(@sprites["chrome"].bitmap)
    end

    def refreshChrome
      bitmap = @sprites["chrome"].bitmap
      bitmap.clear

      global_frame_bottom = INFO_PANEL_Y + INFO_PANEL_H
      global_frame_height = global_frame_bottom - 8 + 1
      drawCornerMarks(
        bitmap,
        9,
        8,
        SCREEN_W - 18,
        global_frame_height,
        INK_FAINT,
        17
      )

      drawCenteredText(
        bitmap,
        "CHOOSE YOUR FIRST COMPANION",
        SUBHEADER_Y,
        INK,
        PAPER_DARK,
        24,
        true
      )

      bitmap.fill_rect(
        CENTER_X - 116,
        DIVIDER_Y,
        232,
        1,
        Color.new(93, 74, 65, 150)
      )
      drawDiamond(
        bitmap,
        CENTER_X,
        DIVIDER_Y,
        4,
        pokemonAccentColor(@starter_pokemon[@selected_index])
      )
      drawDiamond(bitmap, CENTER_X - 123, DIVIDER_Y, 2, GOLD)
      drawDiamond(bitmap, CENTER_X + 123, DIVIDER_Y, 2, GOLD)

      # Navigation arrows stay fixed while the companions/cards rotate through.
      drawLeftText(bitmap, "<", CENTER_X - 91, 165, INK, PAPER_DARK, 28, true)
      drawLeftText(bitmap, ">", CENTER_X + 80, 165, INK, PAPER_DARK, 28, true)

      # ------------------------------------------------------------------------
      # Bottom companion information panel
      # ------------------------------------------------------------------------
      pokemon = @starter_pokemon[@selected_index]
      accent = pokemonAccentColor(pokemon)
      accent_soft = pokemonAccentColor(pokemon, 92)

      panel_x = 28
      panel_y = INFO_PANEL_Y
      panel_w = SCREEN_W - 56
      panel_h = INFO_PANEL_H

      drawPanel(
        bitmap,
        panel_x,
        panel_y,
        panel_w,
        panel_h,
        Color.new(242, 233, 215, 238),
        Color.new(76, 62, 58, 175),
        1
      )

      inset = 4
      drawPanel(
        bitmap,
        panel_x + inset,
        panel_y + inset,
        panel_w - inset * 2,
        panel_h - inset * 2,
        Color.new(0, 0, 0, 0),
        Color.new(122, 102, 88, 72),
        1
      )

      rule_y = panel_y + 9
      rule_margin = 18
      rule_w = panel_w - rule_margin * 2
      bitmap.fill_rect(
        panel_x + rule_margin,
        rule_y,
        rule_w,
        2,
        accent
      )

      bitmap.fill_rect(CENTER_X - 8, rule_y - 1, 16, 4,
                       Color.new(242, 233, 215, 255))
      drawDiamond(bitmap, CENTER_X, rule_y, 3, GOLD)
      drawDiamond(bitmap, CENTER_X, rule_y, 1, accent)

      drawCornerMarks(
        bitmap,
        panel_x + 7,
        panel_y + 7,
        panel_w - 14,
        panel_h - 14,
        Color.new(accent.red, accent.green, accent.blue, 125),
        9
      )

      ornament_y = panel_y + panel_h - 17
      bitmap.fill_rect(panel_x + 18, ornament_y, 24, 1, accent_soft)
      drawDiamond(bitmap, panel_x + 46, ornament_y, 2, GOLD)
      bitmap.fill_rect(panel_x + 50, ornament_y, 16, 1, accent_soft)

      bitmap.fill_rect(panel_x + panel_w - 42, ornament_y, 24, 1, accent_soft)
      drawDiamond(bitmap, panel_x + panel_w - 46, ornament_y, 2, GOLD)
      bitmap.fill_rect(panel_x + panel_w - 66, ornament_y, 16, 1, accent_soft)
    end

    #---------------------------------------------------------------------------
    # Moving companion cards
    #---------------------------------------------------------------------------

    def createStarterCards
      @starter_pokemon.each_with_index do |pokemon, index|
        sprite = Sprite.new(@viewport)
        sprite.bitmap = Bitmap.new(CARD_WIDTH + 12, CARD_HEIGHT + 12)
        sprite.ox = sprite.bitmap.width / 2
        sprite.oy = sprite.bitmap.height / 2
        sprite.x = CENTER_X
        sprite.y = CARD_CENTER_Y
        sprite.z = 5

        @sprites["card_#{index}"] = sprite
        refreshStarterCard(index, false)
      end
    end

    def refreshStarterCards
      @starter_pokemon.each_index do |index|
        refreshStarterCard(index, index == @selected_index)
      end
    end

    def refreshStarterCard(index, selected)
      sprite = @sprites["card_#{index}"]
      pokemon = @starter_pokemon[index]
      return if !sprite || !sprite.bitmap

      bitmap = sprite.bitmap
      bitmap.clear

      pad = 6
      x = pad
      y = pad
      width = CARD_WIDTH
      height = CARD_HEIGHT

      accent = pokemonAccentColor(pokemon)
      muted_accent = pokemonAccentColor(pokemon, selected ? 118 : 62)

      fill = selected ?
        Color.new(246, 239, 223, 230) :
        Color.new(229, 218, 197, 150)

      border = selected ? accent : Color.new(89, 73, 67, 105)
      border_size = selected ? 3 : 1

      drawPanel(bitmap, x, y, width, height, fill, border, border_size)
      drawCornerMarks(
        bitmap,
        x + 5, y + 5, width - 10, height - 10,
        selected ? accent : Color.new(93, 78, 70, 92),
        selected ? 14 : 9
      )

      ring_cx = sprite.bitmap.width / 2
      ring_cy = CARD_RING_LOCAL_Y
      ring_radius = selected ? 68 : 62
      drawRing(bitmap, ring_cx, ring_cy, ring_radius, 2, muted_accent)
      drawRing(bitmap, ring_cx, ring_cy, ring_radius - 5, 1,
               pokemonAccentColor(pokemon, selected ? 72 : 30)) if selected

      drawDiamond(bitmap, ring_cx, 21, selected ? 7 : 5,
                  selected ? accent : pokemonAccentColor(pokemon, 145))

      ornament_y = height - 8
      bitmap.fill_rect(ring_cx - 23, ornament_y, 46, 1,
                       selected ? accent : Color.new(93, 78, 70, 72))
      drawDiamond(bitmap, ring_cx, ornament_y, 2, selected ? GOLD : Color.new(130, 112, 87, 100))
    end

    def createStarterSprites
      @starter_pokemon.each_with_index do |pokemon, index|
        sprite = PokemonSprite.new(@viewport)
        sprite.setPokemonBitmap(pokemon)

        if sprite.bitmap
          sprite.ox = sprite.bitmap.width / 2
          sprite.oy = sprite.bitmap.height / 2
        end

        sprite.x = CENTER_X
        sprite.y = POKEMON_ROW_Y
        sprite.zoom_x = SIDE_ZOOM
        sprite.zoom_y = SIDE_ZOOM
        sprite.color = Color.new(0, 0, 0, SIDE_DIM_ALPHA)
        sprite.z = 8

        @current_dim[index] = SIDE_DIM_ALPHA
        @sprites["starter_#{index}"] = sprite
      end
    end

    def createStarterInfo
      @sprites["info"] = BitmapSprite.new(SCREEN_W, SCREEN_H, @viewport)
      pbSetSystemFont(@sprites["info"].bitmap)
      @sprites["info"].z = 20

      @type_badges_available = false

      begin
        type_bitmap = Bitmap.new(TYPE_BADGE_PATH)
        if type_bitmap && !type_bitmap.disposed?
          @sprites["type1"] = Sprite.new(@viewport)
          @sprites["type1"].bitmap = type_bitmap
          @sprites["type1"].z = 21
          @sprites["type1"].visible = false

          @sprites["type2"] = Sprite.new(@viewport)
          @sprites["type2"].bitmap = Bitmap.new(TYPE_BADGE_PATH)
          @sprites["type2"].z = 21
          @sprites["type2"].visible = false

          @type_badges_available = true
        end
      rescue
        @type_badges_available = false
      end
    end

    def createShinyFeedback
      @sprites["shiny_feedback"] = BitmapSprite.new(SCREEN_W, SCREEN_H, @viewport)
      @sprites["shiny_feedback"].z = 30
      @sprites["shiny_feedback"].visible = false
    end

    def createTransitionOverlay
      sprite = Sprite.new(@viewport)
      sprite.bitmap = Bitmap.new(SCREEN_W, SCREEN_H)
      sprite.z = 999
      sprite.visible = false
      @sprites["transition"] = sprite
    end

    #---------------------------------------------------------------------------
    # Selected Pokémon info
    #---------------------------------------------------------------------------

    def refreshStarterInfo
      bitmap = @sprites["info"].bitmap
      bitmap.clear

      pokemon = @starter_pokemon[@selected_index]
      return if !pokemon

      name = safePokemonName(pokemon)
      category_text = safeCategory(pokemon)
      accent = pokemonAccentColor(pokemon)

      drawCenteredText(
        bitmap,
        name,
        INFO_NAME_Y,
        INK,
        PAPER_DARK,
        23,
        true
      )

      drawCenteredText(
        bitmap,
        category_text,
        INFO_CATEGORY_Y,
        TEXT_BASE_COLOR,
        Color.new(0, 0, 0, 0),
        15,
        false
      )

      refreshTypeBadges(pokemon)
    end

    def refreshTypeBadges(pokemon)
      if !@type_badges_available
        drawFallbackTypeText(pokemon)
        return
      end

      type1_sprite = @sprites["type1"]
      type2_sprite = @sprites["type2"]
      return drawFallbackTypeText(pokemon) if !type1_sprite || !type2_sprite

      type1 = pokemon.type1
      type2 = pokemon.type2

      begin
        setTypeBadge(type1_sprite, type1)

        if type2.nil? || type2 == type1
          type1_sprite.x = CENTER_X - TYPE_BADGE_WIDTH / 2
          type1_sprite.y = TYPE_BADGE_Y
          type1_sprite.visible = true
          type2_sprite.visible = false
          return
        end

        setTypeBadge(type2_sprite, type2)

        total_width = TYPE_BADGE_WIDTH * 2 + TYPE_BADGE_GAP
        start_x = CENTER_X - total_width / 2

        type1_sprite.x = start_x
        type1_sprite.y = TYPE_BADGE_Y
        type1_sprite.visible = true

        type2_sprite.x = start_x + TYPE_BADGE_WIDTH + TYPE_BADGE_GAP
        type2_sprite.y = TYPE_BADGE_Y
        type2_sprite.visible = true
      rescue
        type1_sprite.visible = false if type1_sprite
        type2_sprite.visible = false if type2_sprite
        drawFallbackTypeText(pokemon)
      end
    end

    def setTypeBadge(sprite, type)
      raise "Missing type badge sprite." if !sprite || !sprite.bitmap
      raise "Missing Pokémon type." if type.nil?

      y = type.to_i * TYPE_BADGE_HEIGHT
      raise "Type badge index is outside types.png." if
        y < 0 || y + TYPE_BADGE_HEIGHT > sprite.bitmap.height

      sprite.src_rect.set(0, y, TYPE_BADGE_WIDTH, TYPE_BADGE_HEIGHT)
    end

    def drawFallbackTypeText(pokemon)
      bitmap = @sprites["info"].bitmap
      type1 = safeTypeName(pokemon.type1)
      type2 = pokemon.type2

      text = type1
      text += " / #{safeTypeName(type2)}" if !type2.nil? && type2 != pokemon.type1

      drawCenteredText(
        bitmap,
        text,
        TYPE_BADGE_Y + 3,
        pokemonAccentColor(pokemon),
        PAPER_DARK,
        16,
        true
      )
    end

    #---------------------------------------------------------------------------
    # Carousel targets
    #---------------------------------------------------------------------------

    def refreshStarterTargets(instant = false)
      starter_count = @starter_pokemon.length

      @starter_pokemon.each_with_index do |_pokemon, index|
        sprite = @sprites["starter_#{index}"]
        card = @sprites["card_#{index}"]
        next if !sprite

        relative_position = index - @selected_index

        # Wrap around so the closest choices remain on either side.
        if relative_position > starter_count / 2
          relative_position -= starter_count
        elsif relative_position < -(starter_count / 2)
          relative_position += starter_count
        end

        if relative_position == 0
          @target_x[index] = CENTER_X
          @target_y[index] = POKEMON_ROW_Y + SELECTED_Y_OFFSET
          @target_zoom[index] = SELECTED_ZOOM
          @target_dim[index] = SELECTED_DIM_ALPHA

          @target_card_x[index] = CENTER_X
          @target_card_y[index] = CARD_CENTER_Y - 3
          @target_card_zoom[index] = SELECTED_CARD_ZOOM

          sprite.z = 12
          card.z = 7 if card
        elsif relative_position < 0
          @target_x[index] = CENTER_X - SIDE_DISTANCE
          @target_y[index] = POKEMON_ROW_Y + SIDE_Y_OFFSET
          @target_zoom[index] = SIDE_ZOOM
          @target_dim[index] = SIDE_DIM_ALPHA

          @target_card_x[index] = CENTER_X - SIDE_DISTANCE
          @target_card_y[index] = CARD_CENTER_Y + 5
          @target_card_zoom[index] = SIDE_CARD_ZOOM

          sprite.z = 8
          card.z = 4 if card
        else
          @target_x[index] = CENTER_X + SIDE_DISTANCE
          @target_y[index] = POKEMON_ROW_Y + SIDE_Y_OFFSET
          @target_zoom[index] = SIDE_ZOOM
          @target_dim[index] = SIDE_DIM_ALPHA

          @target_card_x[index] = CENTER_X + SIDE_DISTANCE
          @target_card_y[index] = CARD_CENTER_Y + 5
          @target_card_zoom[index] = SIDE_CARD_ZOOM

          sprite.z = 8
          card.z = 4 if card
        end

        next if !instant

        sprite.x = @target_x[index]
        sprite.y = @target_y[index]
        sprite.zoom_x = @target_zoom[index]
        sprite.zoom_y = @target_zoom[index]

        if card
          card.x = @target_card_x[index]
          card.y = @target_card_y[index]
          card.zoom_x = @target_card_zoom[index]
          card.zoom_y = @target_card_zoom[index]
        end

        @current_dim[index] = @target_dim[index]
        applySpriteDim(sprite, @current_dim[index])
      end

      refreshStarterCards
    end

    #---------------------------------------------------------------------------
    # Carousel animation
    #---------------------------------------------------------------------------

    def updateStarterAnimation
      @starter_pokemon.each_with_index do |_pokemon, index|
        sprite = @sprites["starter_#{index}"]
        next if !sprite

        updateStarterPosition(sprite, index)
        updateStarterZoom(sprite, index)
        updateStarterDimming(sprite, index)
        updateStarterCardAnimation(index)
      end

      updatePendingRevealFeedback
    end

    def updateStarterPosition(sprite, index)
      target_x = @target_x[index]
      target_y = @target_y[index]
      return if target_x.nil? || target_y.nil?

      sprite.x += (target_x - sprite.x) * POSITION_SPEED
      sprite.y += (target_y - sprite.y) * POSITION_SPEED

      sprite.x = target_x if (sprite.x - target_x).abs < SETTLE_POSITION_EPSILON
      sprite.y = target_y if (sprite.y - target_y).abs < SETTLE_POSITION_EPSILON
    end

    def updateStarterZoom(sprite, index)
      target = @target_zoom[index]
      return if target.nil?

      zoom = sprite.zoom_x + (target - sprite.zoom_x) * ZOOM_SPEED
      sprite.zoom_x = zoom
      sprite.zoom_y = zoom

      if (sprite.zoom_x - target).abs < SETTLE_ZOOM_EPSILON
        sprite.zoom_x = target
        sprite.zoom_y = target
      end
    end

    def updateStarterDimming(sprite, index)
      current = @current_dim[index] || SIDE_DIM_ALPHA
      target = @target_dim[index] || SIDE_DIM_ALPHA

      current += (target - current) * DIM_SPEED
      current = target if (current - target).abs < SETTLE_DIM_EPSILON

      @current_dim[index] = current
      applySpriteDim(sprite, current)
    end

    def updateStarterCardAnimation(index)
      card = @sprites["card_#{index}"]
      return if !card

      target_x = @target_card_x[index]
      target_y = @target_card_y[index]
      target_zoom = @target_card_zoom[index]
      return if target_x.nil? || target_y.nil? || target_zoom.nil?

      card.x += (target_x - card.x) * POSITION_SPEED
      card.y += (target_y - card.y) * POSITION_SPEED

      zoom = card.zoom_x + (target_zoom - card.zoom_x) * ZOOM_SPEED
      card.zoom_x = zoom
      card.zoom_y = zoom

      card.x = target_x if (card.x - target_x).abs < SETTLE_POSITION_EPSILON
      card.y = target_y if (card.y - target_y).abs < SETTLE_POSITION_EPSILON

      if (card.zoom_x - target_zoom).abs < SETTLE_ZOOM_EPSILON
        card.zoom_x = target_zoom
        card.zoom_y = target_zoom
      end
    end

    def applySpriteDim(sprite, alpha)
      alpha = [[alpha.to_i, 0].max, 255].min
      sprite.color = Color.new(0, 0, 0, alpha)
    end

    #---------------------------------------------------------------------------
    # Selection
    #---------------------------------------------------------------------------

    def moveSelectionLeft
      return if @input_locked
      return if @starter_pokemon.length <= 1

      @selected_index -= 1
      @selected_index = @starter_pokemon.length - 1 if @selected_index < 0

      selectionChanged
    end

    def moveSelectionRight
      return if @input_locked
      return if @starter_pokemon.length <= 1

      @selected_index += 1
      @selected_index = 0 if @selected_index >= @starter_pokemon.length

      selectionChanged
    end

    def selectionChanged
      stopShinyFeedback
      BushidoStarterSelection.safeSEPlay(MOVE_SE, 72, 100)

      refreshStarterTargets
      refreshChrome
      refreshStarterInfo

      @pending_reveal_feedback = true
      @reveal_feedback_frames = REVEAL_FEEDBACK_DELAY
    end

    def updatePendingRevealFeedback
      return if !@pending_reveal_feedback

      if @reveal_feedback_frames > 0
        @reveal_feedback_frames -= 1
        return
      end

      @pending_reveal_feedback = false
      playRevealFeedback
    end

    def playRevealFeedback
      pokemon = @starter_pokemon[@selected_index]
      return if !pokemon

      begin
        pbPlayCry(pokemon)
      rescue
      end

      startShinyFeedback if pokemon.shiny?
    end

    #---------------------------------------------------------------------------
    # Input repeat
    #---------------------------------------------------------------------------

    def updateDirectionalInput
      if Input.press?(Input::LEFT)
        @left_hold_frames += 1
        @right_hold_frames = 0

        if @left_hold_frames == 1 ||
           (@left_hold_frames > INPUT_INITIAL_DELAY &&
            (@left_hold_frames - INPUT_INITIAL_DELAY) % INPUT_REPEAT_DELAY == 0)
          moveSelectionLeft
        end
      elsif Input.press?(Input::RIGHT)
        @right_hold_frames += 1
        @left_hold_frames = 0

        if @right_hold_frames == 1 ||
           (@right_hold_frames > INPUT_INITIAL_DELAY &&
            (@right_hold_frames - INPUT_INITIAL_DELAY) % INPUT_REPEAT_DELAY == 0)
          moveSelectionRight
        end
      else
        @left_hold_frames = 0
        @right_hold_frames = 0
      end
    end

    #---------------------------------------------------------------------------
    # Shiny feedback
    #---------------------------------------------------------------------------

    def startShinyFeedback
      pokemon = @starter_pokemon[@selected_index]
      return if !pokemon || !pokemon.shiny?

      @shiny_feedback_active = true
      @shiny_feedback_frame = 0
      @shiny_feedback_index = @selected_index

      feedback = @sprites["shiny_feedback"]
      feedback.bitmap.clear
      feedback.visible = true

      BushidoStarterSelection.safeSEPlay(SHINY_SE, 90, 100)
    end

    def updateShinyFeedback
      return if !@shiny_feedback_active

      if @shiny_feedback_index != @selected_index
        stopShinyFeedback
        return
      end

      feedback = @sprites["shiny_feedback"]
      return stopShinyFeedback if !feedback || !feedback.bitmap

      bitmap = feedback.bitmap
      denominator = [SHINY_FEEDBACK_FRAMES - 1, 1].max
      progress = @shiny_feedback_frame / denominator.to_f
      eased_progress = 1.0 - (1.0 - progress) ** 3

      bitmap.clear
      drawShinySparkles(bitmap, CENTER_X, POKEMON_ROW_Y - 20, eased_progress)

      @shiny_feedback_frame += 1
      stopShinyFeedback if @shiny_feedback_frame >= SHINY_FEEDBACK_FRAMES
    end

    def stopShinyFeedback
      @shiny_feedback_active = false
      @shiny_feedback_frame = 0
      @shiny_feedback_index = nil

      feedback = @sprites["shiny_feedback"]
      return if !feedback

      feedback.bitmap.clear if feedback.bitmap
      feedback.visible = false
    end

    def drawShinySparkles(bitmap, center_x, center_y, progress)
      bright = Color.new(255, 244, 143)
      shadow = Color.new(165, 97, 34)

      radius = 22 + progress * 62
      pulse = Math.sin(progress * Math::PI)

      SHINY_SPARKLE_COUNT.times do |index|
        angle = Math::PI * 2 * index / SHINY_SPARKLE_COUNT + progress * 0.45
        x = center_x + Math.cos(angle) * radius
        y = center_y + Math.sin(angle) * radius
        size = 2 + (pulse * 4).to_i
        drawSparkle(bitmap, x.to_i, y.to_i, size, bright, shadow)
      end
    end

    def drawSparkle(bitmap, x, y, size, color, shadow)
      return if size <= 0

      bitmap.fill_rect(x - 1, y - size - 1, 3, size * 2 + 3, shadow)
      bitmap.fill_rect(x - size - 1, y - 1, size * 2 + 3, 3, shadow)
      bitmap.fill_rect(x, y - size, 1, size * 2 + 1, color)
      bitmap.fill_rect(x - size, y, size * 2 + 1, 1, color)
    end

    #---------------------------------------------------------------------------
    # Confirmation
    #---------------------------------------------------------------------------

    def playConfirmationSequence
      @input_locked = true
      @pending_reveal_feedback = false
      @reveal_feedback_frames = 0
      stopShinyFeedback

      sprite = @sprites["starter_#{@selected_index}"]
      pokemon = @starter_pokemon[@selected_index]
      return if !sprite || !pokemon

      base_x = @target_x[@selected_index]
      base_y = @target_y[@selected_index]
      base_zoom = @target_zoom[@selected_index]

      hideSelectionInfo
      BushidoStarterSelection.safeSEPlay(CONFIRM_SE, 85, 100)

      begin
        pbPlayCry(pokemon)
      rescue
      end

      CONFIRM_HOP_FRAMES.times do |frame|
        denominator = [CONFIRM_HOP_FRAMES - 1, 1].max
        progress = frame / denominator.to_f

        hop = Math.sin(progress * Math::PI) * CONFIRM_HOP_HEIGHT
        zoom = Math.sin(progress * Math::PI) * CONFIRM_ZOOM_BOOST

        sprite.x = base_x
        sprite.y = base_y - hop
        sprite.zoom_x = base_zoom + zoom
        sprite.zoom_y = base_zoom + zoom

        updateConfirmationSeal(progress)
        updateSceneFrame(false)
      end

      sprite.x = base_x
      sprite.y = base_y
      sprite.zoom_x = base_zoom
      sprite.zoom_y = base_zoom

      waitFrames(CONFIRM_HOLD_FRAMES)
      whiteOutScene
    end

    def updateConfirmationSeal(progress)
      feedback = @sprites["shiny_feedback"]
      return if !feedback || !feedback.bitmap

      feedback.visible = true
      bitmap = feedback.bitmap
      bitmap.clear

      pulse = Math.sin(progress * Math::PI)
      radius = 18 + (pulse * 44).to_i
      alpha = (165 * pulse).to_i

      accent = pokemonAccentColor(@starter_pokemon[@selected_index], alpha)
      drawRing(bitmap, CENTER_X, POKEMON_ROW_Y - 12, radius, 3, accent)
      drawDiamond(bitmap, CENTER_X, POKEMON_ROW_Y - 12,
                  [4 + (pulse * 7).to_i, 2].max,
                  Color.new(190, 150, 79, alpha))
    end

    def hideSelectionInfo
      @sprites["info"].visible = false if @sprites["info"]
      @sprites["type1"].visible = false if @sprites["type1"]
      @sprites["type2"].visible = false if @sprites["type2"]
    end

    def whiteOutScene
      overlay = @sprites["transition"]
      overlay.visible = true

      WHITE_OUT_FRAMES.times do |frame|
        denominator = [WHITE_OUT_FRAMES - 1, 1].max
        progress = frame / denominator.to_f
        eased = progress * progress * (3.0 - 2.0 * progress)
        alpha = (255 * eased).to_i

        overlay.bitmap.clear
        overlay.bitmap.fill_rect(0, 0, SCREEN_W, SCREEN_H,
                                 Color.new(255, 250, 238, alpha))

        updateSceneFrame(false)
      end

      overlay.bitmap.clear
      overlay.bitmap.fill_rect(0, 0, SCREEN_W, SCREEN_H,
                               Color.new(255, 250, 238, 255))

      @white_out_complete = true
    end

    def cancelScene
      return nil if !ALLOW_CANCEL || @input_locked

      @input_locked = true
      BushidoStarterSelection.safeSEPlay(CANCEL_SE, 75, 100)
      Graphics.freeze
      return nil
    end

    #---------------------------------------------------------------------------
    # Scene loop
    #---------------------------------------------------------------------------

    def updateSceneFrame(update_carousel = true)
      Graphics.update
      Input.update
      pbUpdateSpriteHash(@sprites)

      updateAmbientPetals
      updateStarterAnimation if update_carousel
      updateShinyFeedback
    end

    def waitFrames(frames)
      frames.times { updateSceneFrame(false) }
    end

    def pbMain
      loop do
        updateSceneFrame

        updateDirectionalInput if !@input_locked

        if Input.trigger?(Input::C) && !@input_locked
          @chosen_pokemon = @starter_pokemon[@selected_index]
          playConfirmationSequence

          return [@chosen_pokemon, @selected_index]
        elsif ALLOW_CANCEL && Input.trigger?(Input::B) && !@input_locked
          return cancelScene
        end
      end
    end

    #---------------------------------------------------------------------------
    # Cleanup
    #---------------------------------------------------------------------------

    def pbEndScene
      @petals.each do |data|
        sprite = data[:sprite]
        next if !sprite || sprite.disposed?
        sprite.bitmap.dispose if sprite.bitmap && !sprite.bitmap.disposed?
        sprite.dispose
      end
      @petals.clear

      pbDisposeSpriteHash(@sprites)

      if @viewport && !@viewport.disposed?
        @viewport.dispose
      end
    end

    def whiteOutComplete?
      return @white_out_complete
    end
  end

  #=============================================================================
  # Screen wrapper
  #=============================================================================

  class Screen
    def initialize(scene)
      @scene = scene
    end

    def pbStartScreen
      Graphics.freeze

      result = nil

      begin
        @scene.pbStartScene
        result = @scene.pbMain

        Graphics.freeze if @scene.whiteOutComplete?
      ensure
        @scene.pbEndScene
      end

      Graphics.transition(Scene::RETURN_FADE_FRAMES)
      return result
    end
  end

  #=============================================================================
  # Public entry point
  #=============================================================================

  def self.pbStart
    starters = generateStarters
    validateStarters(starters)

    scene = Scene.new(starters)
    screen = Screen.new(scene)
    result = screen.pbStartScreen

    if result
      chosen_pokemon = result[0]
      selected_index = result[1]

      # Save which starter slot was chosen
      pbSet(STARTER_CHOICE_VARIABLE_ID, selected_index + 1)

      # Add the chosen starter to the player's party
      $Trainer.party.push(chosen_pokemon)

      # Save the starter's name into variable 90
      $game_variables[90] = PBSpecies.getName(chosen_pokemon.species)
    end

    return result
  end
end 