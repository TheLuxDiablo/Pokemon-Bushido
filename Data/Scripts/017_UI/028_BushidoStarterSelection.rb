#===============================================================================
# Pokémon Bushido - Custom Starter Selection
# Pokémon Essentials v18.1
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

  # The old starter events still look at these variables, so keep them filled.
  STARTER_VARIABLE_IDS = [73, 74, 75]
  STARTER_CHOICE_VARIABLE_ID = 1031

  # Matches the old event's 1-in-201 shiny roll.
  SHINY_ROLL_MAX    = 200
  SHINY_ROLL_RESULT = 1

  #=============================================================================
  # Debug testing
  #=============================================================================
  # :OFF    - Normal behavior
  # :SHINY  - Force all three starters shiny
  # :RANDOM - Force three random species
  # :BOTH   - Force random species and shininess
  #
  # Put this back to :OFF before release.
  DEBUG_MODE = :BOTH

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
  # Debug helpers
  #=============================================================================

  def self.debugRandom?
    return DEBUG_MODE == :RANDOM || DEBUG_MODE == :BOTH
  end

  def self.debugShiny?
    return DEBUG_MODE == :SHINY || DEBUG_MODE == :BOTH
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

    return allowed_species.sample
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

    pokemon = PokeBattle_Pokemon.new(
      species,
      STARTER_LEVEL,
      $Trainer
    )

    pokemon.form = form if pokemon.respond_to?(:form=)

    # The real randomizer only runs here when debug random is off.
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

    CENTER_X = Graphics.width / 2

    # Keep the Pokémon row clear of the text at the bottom.
    POKEMON_ROW_Y = (Graphics.height / 2) - 42
    SIDE_DISTANCE = 150

    SELECTED_Y_OFFSET = -8
    SIDE_Y_OFFSET     = 16

    INFO_Y = Graphics.height - 112

    #---------------------------------------------------------------------------
    # Scale and silhouettes
    #---------------------------------------------------------------------------

    SELECTED_ZOOM = 1.25
    SIDE_ZOOM     = 0.85

    SELECTED_DIM_ALPHA = 0
    SIDE_DIM_ALPHA     = 255

    #---------------------------------------------------------------------------
    # Carousel timing
    #---------------------------------------------------------------------------

    POSITION_SPEED = 0.16
    ZOOM_SPEED     = 0.13
    DIM_SPEED      = 0.12

    SETTLE_POSITION_EPSILON = 0.75
    SETTLE_ZOOM_EPSILON     = 0.01
    SETTLE_DIM_EPSILON      = 2.0

    #---------------------------------------------------------------------------
    # Text and type badges
    #---------------------------------------------------------------------------

    NAME_BASE_COLOR   = Color.new(248, 248, 248)
    NAME_SHADOW_COLOR = Color.new(72, 72, 80)

    TEXT_BASE_COLOR   = Color.new(216, 216, 224)
    TEXT_SHADOW_COLOR = Color.new(56, 56, 64)

    TYPE_BADGE_PATH   = "Graphics/Pictures/types"
    TYPE_BADGE_WIDTH  = 64
    TYPE_BADGE_HEIGHT = 28
    TYPE_BADGE_GAP    = 8
    TYPE_BADGE_Y      = INFO_Y + 34

    #---------------------------------------------------------------------------
    # Shiny feedback
    #---------------------------------------------------------------------------

    SHINY_SE = "Battle shiny"

    SHINY_FEEDBACK_FRAMES = 36
    SHINY_SPARKLE_COUNT   = 10

    #---------------------------------------------------------------------------
    # Confirmation timing
    #---------------------------------------------------------------------------

    CONFIRM_HOP_FRAMES = 42
    CONFIRM_HOP_HEIGHT = 22
    CONFIRM_ZOOM_BOOST = 0.14
    CONFIRM_HOLD_FRAMES = 12

    WHITE_OUT_FRAMES = 30
    RETURN_FADE_FRAMES = 28

    #---------------------------------------------------------------------------
    # Setup
    #---------------------------------------------------------------------------

    def initialize(starters)
      @starter_pokemon = starters
    end

    def pbStartScene
      @viewport = Viewport.new(
        0,
        0,
        Graphics.width,
        Graphics.height
      )
      @viewport.z = 99999

      @sprites = {}

      @selected_index = 0
      @chosen_pokemon = nil
      @pending_reveal_feedback = false
      @input_locked = false
      @white_out_complete = false

      @target_x    = {}
      @target_y    = {}
      @target_zoom = {}
      @target_dim  = {}
      @current_dim = {}

      createBackground
      createStarterSprites
      createStarterInfo
      createShinyFeedback
      createTransitionOverlay

      refreshStarterTargets(true)
      refreshStarterInfo

      # Freeze the map before drawing the new scene, then transition into it.
      Graphics.transition(24)
      playRevealFeedback
    end

    #---------------------------------------------------------------------------
    # Scene graphics
    #---------------------------------------------------------------------------

    def createBackground
      sprite = Sprite.new(@viewport)
      sprite.bitmap = Bitmap.new(Graphics.width, Graphics.height)

      sprite.bitmap.fill_rect(
        0,
        0,
        Graphics.width,
        Graphics.height,
        Color.new(20, 20, 28)
      )

      sprite.z = 0
      @sprites["background"] = sprite
    end

    def createStarterSprites
      @starter_pokemon.each_with_index do |pokemon, index|
        sprite = PokemonSprite.new(@viewport)
        sprite.setPokemonBitmap(pokemon)

        sprite.ox = sprite.bitmap.width / 2
        sprite.oy = sprite.bitmap.height / 2

        sprite.x = CENTER_X
        sprite.y = POKEMON_ROW_Y

        sprite.zoom_x = SIDE_ZOOM
        sprite.zoom_y = SIDE_ZOOM

        sprite.color = Color.new(0, 0, 0, SIDE_DIM_ALPHA)

        @current_dim[index] = SIDE_DIM_ALPHA
        @sprites["starter_#{index}"] = sprite
      end
    end

    def createStarterInfo
      @sprites["info"] = BitmapSprite.new(
        Graphics.width,
        Graphics.height,
        @viewport
      )
      pbSetSystemFont(@sprites["info"].bitmap)
      @sprites["info"].z = 20

      @sprites["type1"] = Sprite.new(@viewport)
      @sprites["type1"].bitmap = Bitmap.new(TYPE_BADGE_PATH)
      @sprites["type1"].z = 21
      @sprites["type1"].visible = false

      @sprites["type2"] = Sprite.new(@viewport)
      @sprites["type2"].bitmap = Bitmap.new(TYPE_BADGE_PATH)
      @sprites["type2"].z = 21
      @sprites["type2"].visible = false
    end

    def createShinyFeedback
      @sprites["shiny_feedback"] = BitmapSprite.new(
        Graphics.width,
        Graphics.height,
        @viewport
      )
      @sprites["shiny_feedback"].z = 30
      @sprites["shiny_feedback"].visible = false
    end

    def createTransitionOverlay
      sprite = Sprite.new(@viewport)
      sprite.bitmap = Bitmap.new(Graphics.width, Graphics.height)
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

      category = pbGetMessage(
        MessageTypes::Kinds,
        pokemon.species
      ).to_s

      category_text = category.length > 0 ?
        "The #{category} Pokémon" :
        ""

      text_positions = [
        [
          pokemon.name,
          Graphics.width / 2,
          INFO_Y,
          2,
          NAME_BASE_COLOR,
          NAME_SHADOW_COLOR
        ],
        [
          category_text,
          Graphics.width / 2,
          INFO_Y + 68,
          2,
          TEXT_BASE_COLOR,
          TEXT_SHADOW_COLOR
        ]
      ]

      pbDrawTextPositions(bitmap, text_positions)
      refreshTypeBadges(pokemon)
    end

    def refreshTypeBadges(pokemon)
      type1_sprite = @sprites["type1"]
      type2_sprite = @sprites["type2"]

      type1 = pokemon.type1
      type2 = pokemon.type2

      setTypeBadge(type1_sprite, type1)

      if type2 == type1
        type1_sprite.x = Graphics.width / 2 - TYPE_BADGE_WIDTH / 2
        type1_sprite.y = TYPE_BADGE_Y
        type1_sprite.visible = true
        type2_sprite.visible = false
        return
      end

      setTypeBadge(type2_sprite, type2)

      total_width = TYPE_BADGE_WIDTH * 2 + TYPE_BADGE_GAP
      start_x = Graphics.width / 2 - total_width / 2

      type1_sprite.x = start_x
      type1_sprite.y = TYPE_BADGE_Y
      type1_sprite.visible = true

      type2_sprite.x = start_x + TYPE_BADGE_WIDTH + TYPE_BADGE_GAP
      type2_sprite.y = TYPE_BADGE_Y
      type2_sprite.visible = true
    end

    def setTypeBadge(sprite, type)
      sprite.src_rect.set(
        0,
        type * TYPE_BADGE_HEIGHT,
        TYPE_BADGE_WIDTH,
        TYPE_BADGE_HEIGHT
      )
    end

    #---------------------------------------------------------------------------
    # Carousel targets
    #---------------------------------------------------------------------------

    def refreshStarterTargets(instant = false)
      starter_count = @starter_pokemon.length

      @starter_pokemon.each_with_index do |_pokemon, index|
        sprite = @sprites["starter_#{index}"]
        next if !sprite

        relative_position = index - @selected_index

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
          sprite.z = 10
        elsif relative_position < 0
          @target_x[index] = CENTER_X - SIDE_DISTANCE
          @target_y[index] = POKEMON_ROW_Y + SIDE_Y_OFFSET
          @target_zoom[index] = SIDE_ZOOM
          @target_dim[index] = SIDE_DIM_ALPHA
          sprite.z = 5
        else
          @target_x[index] = CENTER_X + SIDE_DISTANCE
          @target_y[index] = POKEMON_ROW_Y + SIDE_Y_OFFSET
          @target_zoom[index] = SIDE_ZOOM
          @target_dim[index] = SIDE_DIM_ALPHA
          sprite.z = 5
        end

        next if !instant

        sprite.x = @target_x[index]
        sprite.y = @target_y[index]
        sprite.zoom_x = @target_zoom[index]
        sprite.zoom_y = @target_zoom[index]

        @current_dim[index] = @target_dim[index]
        applySpriteDim(sprite, @current_dim[index])
      end
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
      end

      updatePendingRevealFeedback
    end

    def updateStarterPosition(sprite, index)
      sprite.x += (@target_x[index] - sprite.x) * POSITION_SPEED
      sprite.y += (@target_y[index] - sprite.y) * POSITION_SPEED

      sprite.x = @target_x[index] if
        (sprite.x - @target_x[index]).abs < SETTLE_POSITION_EPSILON

      sprite.y = @target_y[index] if
        (sprite.y - @target_y[index]).abs < SETTLE_POSITION_EPSILON
    end

    def updateStarterZoom(sprite, index)
      zoom = sprite.zoom_x +
        (@target_zoom[index] - sprite.zoom_x) * ZOOM_SPEED

      sprite.zoom_x = zoom
      sprite.zoom_y = zoom

      if (sprite.zoom_x - @target_zoom[index]).abs < SETTLE_ZOOM_EPSILON
        sprite.zoom_x = @target_zoom[index]
        sprite.zoom_y = @target_zoom[index]
      end
    end

    def updateStarterDimming(sprite, index)
      current = @current_dim[index]
      target = @target_dim[index]

      current += (target - current) * DIM_SPEED
      current = target if (current - target).abs < SETTLE_DIM_EPSILON

      @current_dim[index] = current
      applySpriteDim(sprite, current)
    end

    def applySpriteDim(sprite, alpha)
      sprite.color = Color.new(0, 0, 0, alpha.to_i)
    end

    def selectedStarterSettled?
      index = @selected_index
      sprite = @sprites["starter_#{index}"]
      return false if !sprite

      position_done =
        (sprite.x - @target_x[index]).abs < SETTLE_POSITION_EPSILON &&
        (sprite.y - @target_y[index]).abs < SETTLE_POSITION_EPSILON

      zoom_done =
        (sprite.zoom_x - @target_zoom[index]).abs < SETTLE_ZOOM_EPSILON

      reveal_done =
        (@current_dim[index] - SELECTED_DIM_ALPHA).abs <
        SETTLE_DIM_EPSILON

      return position_done && zoom_done && reveal_done
    end

    #---------------------------------------------------------------------------
    # Selection
    #---------------------------------------------------------------------------

    def moveSelectionLeft
      return if @input_locked

      @selected_index -= 1
      @selected_index = @starter_pokemon.length - 1 if @selected_index < 0

      selectionChanged
    end

    def moveSelectionRight
      return if @input_locked

      @selected_index += 1
      @selected_index = 0 if @selected_index >= @starter_pokemon.length

      selectionChanged
    end

    def selectionChanged
      refreshStarterTargets
      refreshStarterInfo

      # Wait until the Pokémon is centered and fully revealed before feedback.
      @pending_reveal_feedback = true
    end

    def updatePendingRevealFeedback
      return if !@pending_reveal_feedback
      return if !selectedStarterSettled?

      @pending_reveal_feedback = false
      playRevealFeedback
    end

    def playRevealFeedback
      pokemon = @starter_pokemon[@selected_index]
      return if !pokemon

      pbPlayCry(pokemon)
      playShinyFeedback if pokemon.shiny?
    end

    #---------------------------------------------------------------------------
    # Shiny feedback
    #---------------------------------------------------------------------------

    def playShinyFeedback
      pokemon = @starter_pokemon[@selected_index]
      return if !pokemon || !pokemon.shiny?

      begin
        pbSEPlay(SHINY_SE)
      rescue
        # A missing optional SFX should not break starter selection.
      end

      feedback = @sprites["shiny_feedback"]
      bitmap = feedback.bitmap
      feedback.visible = true

      SHINY_FEEDBACK_FRAMES.times do |frame|
        bitmap.clear

        progress = frame / (SHINY_FEEDBACK_FRAMES - 1).to_f
        drawShinySparkles(
          bitmap,
          CENTER_X,
          POKEMON_ROW_Y - 16,
          progress
        )

        updateSceneFrame(false)
      end

      bitmap.clear
      feedback.visible = false
    end

    def drawShinySparkles(bitmap, center_x, center_y, progress)
      bright = Color.new(255, 245, 120)
      shadow = Color.new(184, 120, 32)

      radius = 24 + progress * 58
      pulse = Math.sin(progress * Math::PI)

      SHINY_SPARKLE_COUNT.times do |index|
        angle =
          Math::PI * 2 * index / SHINY_SPARKLE_COUNT +
          progress * 0.45

        x = center_x + Math.cos(angle) * radius
        y = center_y + Math.sin(angle) * radius
        size = 2 + (pulse * 4).to_i

        drawSparkle(
          bitmap,
          x.to_i,
          y.to_i,
          size,
          bright,
          shadow
        )
      end
    end

    def drawSparkle(bitmap, x, y, size, color, shadow)
      return if size <= 0

      bitmap.fill_rect(
        x - 1,
        y - size - 1,
        3,
        size * 2 + 3,
        shadow
      )

      bitmap.fill_rect(
        x - size - 1,
        y - 1,
        size * 2 + 3,
        3,
        shadow
      )

      bitmap.fill_rect(
        x,
        y - size,
        1,
        size * 2 + 1,
        color
      )

      bitmap.fill_rect(
        x - size,
        y,
        size * 2 + 1,
        1,
        color
      )
    end

    #---------------------------------------------------------------------------
    # Confirmation
    #---------------------------------------------------------------------------

    def playConfirmationSequence
      @input_locked = true
      @pending_reveal_feedback = false

      sprite = @sprites["starter_#{@selected_index}"]
      pokemon = @starter_pokemon[@selected_index]
      return if !sprite || !pokemon

      base_x = @target_x[@selected_index]
      base_y = @target_y[@selected_index]
      base_zoom = @target_zoom[@selected_index]

      hideSelectionInfo
      pbPlayCry(pokemon)

      CONFIRM_HOP_FRAMES.times do |frame|
        progress = frame / (CONFIRM_HOP_FRAMES - 1).to_f

        hop = Math.sin(progress * Math::PI) * CONFIRM_HOP_HEIGHT
        zoom = Math.sin(progress * Math::PI) * CONFIRM_ZOOM_BOOST

        sprite.x = base_x
        sprite.y = base_y - hop
        sprite.zoom_x = base_zoom + zoom
        sprite.zoom_y = base_zoom + zoom

        updateSceneFrame(false)
      end

      sprite.x = base_x
      sprite.y = base_y
      sprite.zoom_x = base_zoom
      sprite.zoom_y = base_zoom

      waitFrames(CONFIRM_HOLD_FRAMES)
      whiteOutScene
    end

    def hideSelectionInfo
      @sprites["info"].visible = false
      @sprites["type1"].visible = false
      @sprites["type2"].visible = false
      @sprites["shiny_feedback"].visible = false
    end

    def whiteOutScene
      overlay = @sprites["transition"]
      overlay.visible = true

      WHITE_OUT_FRAMES.times do |frame|
        progress = frame / (WHITE_OUT_FRAMES - 1).to_f

        # Smoothstep keeps the white fade from feeling linear or abrupt.
        eased = progress * progress * (3.0 - 2.0 * progress)
        alpha = (255 * eased).to_i

        overlay.bitmap.clear
        overlay.bitmap.fill_rect(
          0,
          0,
          Graphics.width,
          Graphics.height,
          Color.new(255, 255, 255, alpha)
        )

        updateSceneFrame(false)
      end

      overlay.bitmap.clear
      overlay.bitmap.fill_rect(
        0,
        0,
        Graphics.width,
        Graphics.height,
        Color.new(255, 255, 255, 255)
      )

      @white_out_complete = true
    end

    #---------------------------------------------------------------------------
    # Scene loop
    #---------------------------------------------------------------------------

    def updateSceneFrame(update_carousel = true)
      Graphics.update
      Input.update
      pbUpdateSpriteHash(@sprites)

      updateStarterAnimation if update_carousel
    end

    def waitFrames(frames)
      frames.times do
        updateSceneFrame(false)
      end
    end

    def pbMain
      loop do
        updateSceneFrame

        if Input.trigger?(Input::LEFT)
          moveSelectionLeft
        elsif Input.trigger?(Input::RIGHT)
          moveSelectionRight
        elsif Input.trigger?(Input::C) && !@input_locked
          @chosen_pokemon = @starter_pokemon[@selected_index]
          playConfirmationSequence

          return [
            @chosen_pokemon,
            @selected_index
          ]
        end
      end
    end

    #---------------------------------------------------------------------------
    # Cleanup
    #---------------------------------------------------------------------------

    def pbEndScene
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
      # Capture the current map so the opening transition does not blink.
      Graphics.freeze

      @scene.pbStartScene
      result = @scene.pbMain

      # Freeze on the full-white frame, remove the menu, then fade back to map.
      Graphics.freeze if @scene.whiteOutComplete?
      @scene.pbEndScene

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
      selected_index = result[1]

      pbSet(
        STARTER_CHOICE_VARIABLE_ID,
        selected_index + 1
      )
    end

    return result
  end
end