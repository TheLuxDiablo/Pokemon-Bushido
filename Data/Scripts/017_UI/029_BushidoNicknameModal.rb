#===============================================================================
# Bushido Naming Scroll
# Pokémon Bushido v2.0.0 / Pokémon Essentials v18.1
#
# Drop-in replacement for the stock full-screen naming UI.
#
# Goals:
# - True modal over the current map/battle screen
# - Pixel-art parchment scroll with obvious curled side rolls
# - Keyboard-first text entry
# - No stock red/white textbox
# - Pokémon sprite + gender when naming a Pokémon
# - Clean keycap controls: [ENTER] Confirm   [ESC] Cancel
# - Custom-drawn text/cursor so typed text can NEVER be clipped by a Window
# - Works with the normal pbEnterText/pbEnterPokemonName/etc. call chain
#
# INSTALL:
# Put this script AFTER the original naming/text-entry scripts in 017_UI.
# Disable/remove any older experimental Bushido nickname modal scripts.
#
# TEST EVENT:
#   pbBushidoNamingTest
#
# Normal game calls to pbEnterPokemonName will automatically use this UI.
#===============================================================================

module BushidoNaming
  #-----------------------------------------------------------------------------
  # Layout
  #-----------------------------------------------------------------------------
  PANEL_WIDTH        = 440
  PANEL_HEIGHT       = 224
  PANEL_Y_OFFSET     = -4

  BODY_LEFT          = 35
  BODY_RIGHT         = 35
  BODY_TOP           = 24
  BODY_BOTTOM        = 24

  PROMPT_Y           = 36

  SUBJECT_X          = 96
  SUBJECT_Y          = 111

  NAME_X_WITH_ICON   = 164
  NAME_X_NO_ICON     = 86
  NAME_Y             = 104
  NAME_RIGHT_MARGIN  = 54

  UNDERLINE_Y        = 139
  CONTROLS_Y         = 163

  #-----------------------------------------------------------------------------
  # Modal behavior
  #-----------------------------------------------------------------------------
  DIM_ALPHA          = 112
  OPEN_FRAMES        = 10
  CLOSE_FRAMES       = 8

  #-----------------------------------------------------------------------------
  # Bushido parchment palette
  # Kept close to the Habitat Scroll palette.
  #-----------------------------------------------------------------------------
  PARCHMENT_LIGHT    = Color.new(244, 226, 190)
  PARCHMENT          = Color.new(227, 206, 165)
  PARCHMENT_MID      = Color.new(212, 184, 136)
  PARCHMENT_DARK     = Color.new(188, 151, 102)
  PARCHMENT_DEEP     = Color.new(139, 101, 66)

  INK                = Color.new(56, 39, 27)
  MUTED              = Color.new(122, 91, 61)
  GOLD               = Color.new(156, 116, 62)
  SHADOW             = Color.new(83, 55, 33, 80)

  MALE_COLOR         = Color.new(55, 104, 170)
  FEMALE_COLOR       = Color.new(176, 72, 79)

  #-----------------------------------------------------------------------------
  # Helpers
  #-----------------------------------------------------------------------------
  def self.clamp(value, min_value, max_value)
    value = min_value if value < min_value
    value = max_value if value > max_value
    return value
  end

  def self.ease_out(t)
    # Smooth, simple easing that works fine on old Ruby.
    return 1.0 - ((1.0 - t) * (1.0 - t))
  end

  def self.ease_in(t)
    return t * t
  end
end


#===============================================================================
# Invisible keyboard input buffer
#
# We deliberately do NOT render the Window_TextEntry_Keyboard itself.
# It only handles keyboard editing. The actual name and caret are drawn by the
# Bushido scene, which eliminates the clipping/padding/windowskin problems that
# happen when making the stock input window transparent.
#===============================================================================
class BushidoNameInput < Window_TextEntry_Keyboard
  def cursor_index
    begin
      return @helper.cursor
    rescue
      return self.text.scan(/./m).length
    end
  end
end


#===============================================================================
# Bushido naming scene
#===============================================================================
class PokemonEntryScene
  USEKEYBOARD = true

  #-----------------------------------------------------------------------------
  # Scene start
  #-----------------------------------------------------------------------------
  def pbStartScene(helptext, minlength, maxlength, initialText,
                   subject = 0, pokemon = nil)
    @sprites     = {}
    @minlength   = minlength
    @maxlength   = maxlength
    @subjectType = subject
    @pokemon     = pokemon
    @helptext    = helptext
    @lastText    = nil
    @lastCursor  = nil
    @closing     = false

    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999

    @panelX = (Graphics.width - BushidoNaming::PANEL_WIDTH) / 2
    @panelY = (Graphics.height - BushidoNaming::PANEL_HEIGHT) / 2 +
              BushidoNaming::PANEL_Y_OFFSET

    createDimmer
    createScroll
    createOverlay
    createInput(initialText)
    createSubject(subject, pokemon)

    Input.text_input = true

    refreshUI(true)
    playOpenAnimation
  end

  #-----------------------------------------------------------------------------
  # Dark modal backing
  #-----------------------------------------------------------------------------
  def createDimmer
    @sprites["dimmer"] = BitmapSprite.new(
      Graphics.width,
      Graphics.height,
      @viewport
    )

    @sprites["dimmer"].bitmap.fill_rect(
      0, 0,
      Graphics.width,
      Graphics.height,
      Color.new(0, 0, 0, BushidoNaming::DIM_ALPHA)
    )

    @sprites["dimmer"].opacity = 0
  end

  #-----------------------------------------------------------------------------
  # Scroll sprite
  #-----------------------------------------------------------------------------
  def createScroll
    @sprites["scroll"] = Sprite.new(@viewport)
    @sprites["scroll"].bitmap = Bitmap.new(
      BushidoNaming::PANEL_WIDTH,
      BushidoNaming::PANEL_HEIGHT
    )

    # Center-origin lets zoom_x look like the parchment is unfurling.
    @sprites["scroll"].ox = BushidoNaming::PANEL_WIDTH / 2
    @sprites["scroll"].oy = BushidoNaming::PANEL_HEIGHT / 2
    @sprites["scroll"].x  = Graphics.width / 2
    @sprites["scroll"].y  = @panelY + BushidoNaming::PANEL_HEIGHT / 2

    drawScroll(@sprites["scroll"].bitmap)
  end

  #-----------------------------------------------------------------------------
  # Full-screen UI overlay. Text is drawn here rather than in a Window.
  #-----------------------------------------------------------------------------
  def createOverlay
    @sprites["overlay"] = BitmapSprite.new(
      Graphics.width,
      Graphics.height,
      @viewport
    )
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["overlay"].opacity = 0
  end

  #-----------------------------------------------------------------------------
  # Hidden input buffer
  #-----------------------------------------------------------------------------
  def createInput(initialText)
    # The input object is intentionally invisible. Its dimensions therefore do
    # not affect the visible text in any way.
    @sprites["entry"] = BushidoNameInput.new(
      initialText,
      -500,
      -500,
      320,
      96,
      "",
      true
    )
    @sprites["entry"].viewport  = @viewport
    @sprites["entry"].maxlength = @maxlength
    @sprites["entry"].visible   = false
    @sprites["entry"].active    = true
  end

  #=============================================================================
  # Scroll art
  #
  # Everything is hard-edged and aligned to integer pixels so it reads like a
  # deliberately pixel-art interpretation of an old parchment scroll rather
  # than a smooth UI rectangle.
  #=============================================================================
  def drawScroll(bmp)
    bmp.clear

    w = BushidoNaming::PANEL_WIDTH
    h = BushidoNaming::PANEL_HEIGHT

    light = BushidoNaming::PARCHMENT_LIGHT
    body  = BushidoNaming::PARCHMENT
    mid   = BushidoNaming::PARCHMENT_MID
    dark  = BushidoNaming::PARCHMENT_DARK
    deep  = BushidoNaming::PARCHMENT_DEEP
    ink   = BushidoNaming::INK

    #-------------------------------------------------------------------------
    # Soft blocky drop shadow
    #-------------------------------------------------------------------------
    bmp.fill_rect(30, 22, w - 52, h - 30, Color.new(0, 0, 0, 34))
    bmp.fill_rect(24, 28, w - 40, h - 34, Color.new(0, 0, 0, 26))

    #-------------------------------------------------------------------------
    # Main paper body
    #-------------------------------------------------------------------------
    bmp.fill_rect(28, 20, w - 56, h - 40, dark)
    bmp.fill_rect(31, 23, w - 62, h - 46, body)
    bmp.fill_rect(35, 27, w - 70, h - 54, light)

    #-------------------------------------------------------------------------
    # Irregular/torn top edge
    #-------------------------------------------------------------------------
    top_blocks = [
      [36, 23, 25, 4], [64, 20, 31, 7], [99, 22, 22, 5],
      [124, 19, 37, 8], [165, 21, 20, 6], [189, 18, 39, 9],
      [233, 21, 29, 6], [266, 19, 42, 8], [312, 22, 25, 5],
      [341, 20, 34, 7], [379, 22, 25, 5]
    ]
    top_blocks.each do |r|
      bmp.fill_rect(r[0], r[1], r[2], r[3], light)
    end

    # Small dark nicks/notches.
    [[70,23,3,6],[119,23,2,5],[180,22,3,7],[260,23,2,5],
     [332,23,3,6],[397,23,2,5]].each do |r|
      bmp.fill_rect(r[0], r[1], r[2], r[3], dark)
    end

    #-------------------------------------------------------------------------
    # Irregular/torn bottom edge
    #-------------------------------------------------------------------------
    bottom_y = h - 27
    bottom_blocks = [
      [36, bottom_y, 30, 5], [70, bottom_y + 2, 24, 3],
      [99, bottom_y - 1, 32, 6], [135, bottom_y + 1, 28, 4],
      [168, bottom_y - 2, 38, 7], [211, bottom_y + 1, 23, 4],
      [239, bottom_y - 1, 35, 6], [279, bottom_y + 2, 29, 3],
      [312, bottom_y - 1, 41, 6], [358, bottom_y + 1, 44, 4]
    ]
    bottom_blocks.each do |r|
      bmp.fill_rect(r[0], r[1], r[2], r[3], light)
    end

    [[80,bottom_y-1,3,6],[153,bottom_y-1,2,5],[227,bottom_y-1,3,6],
     [300,bottom_y-1,2,5],[369,bottom_y-1,3,6]].each do |r|
      bmp.fill_rect(r[0], r[1], r[2], r[3], dark)
    end

    #-------------------------------------------------------------------------
    # LEFT wooden/paper roll
    #
    # Wide outer lip + narrow core + highlight creates an unmistakable curled
    # cylinder instead of a flat decorative bar.
    #-------------------------------------------------------------------------
    bmp.fill_rect(9, 13, 23, h - 26, deep)
    bmp.fill_rect(12, 10, 17, h - 20, dark)
    bmp.fill_rect(15, 13, 11, h - 26, mid)
    bmp.fill_rect(18, 15, 5, h - 30, light)

    # Top-left cap/curl
    bmp.fill_rect(5, 8, 28, 9, deep)
    bmp.fill_rect(8, 5, 22, 9, dark)
    bmp.fill_rect(11, 7, 16, 5, light)
    bmp.fill_rect(7, 14, 10, 5, deep)

    # Bottom-left cap/curl
    bmp.fill_rect(5, h - 17, 28, 9, deep)
    bmp.fill_rect(8, h - 14, 22, 9, dark)
    bmp.fill_rect(11, h - 12, 16, 5, light)
    bmp.fill_rect(7, h - 19, 10, 5, deep)

    # Inner curl shadow where paper wraps around rod
    bmp.fill_rect(26, 26, 6, h - 52, deep)
    bmp.fill_rect(29, 30, 4, h - 60, dark)

    #-------------------------------------------------------------------------
    # RIGHT roll, mirrored
    #-------------------------------------------------------------------------
    rx = w - 32
    bmp.fill_rect(rx, 13, 23, h - 26, deep)
    bmp.fill_rect(rx + 3, 10, 17, h - 20, dark)
    bmp.fill_rect(rx + 6, 13, 11, h - 26, mid)
    bmp.fill_rect(rx + 9, 15, 5, h - 30, light)

    bmp.fill_rect(w - 33, 8, 28, 9, deep)
    bmp.fill_rect(w - 30, 5, 22, 9, dark)
    bmp.fill_rect(w - 27, 7, 16, 5, light)
    bmp.fill_rect(w - 17, 14, 10, 5, deep)

    bmp.fill_rect(w - 33, h - 17, 28, 9, deep)
    bmp.fill_rect(w - 30, h - 14, 22, 9, dark)
    bmp.fill_rect(w - 27, h - 12, 16, 5, light)
    bmp.fill_rect(w - 17, h - 19, 10, 5, deep)

    bmp.fill_rect(w - 33, 26, 6, h - 52, deep)
    bmp.fill_rect(w - 33, 30, 4, h - 60, dark)

    #-------------------------------------------------------------------------
    # Subtle paper shading
    #-------------------------------------------------------------------------
    bmp.fill_rect(39, 31, w - 78, 3, Color.new(255, 245, 217, 90))
    bmp.fill_rect(39, h - 35, w - 78, 3, Color.new(139, 101, 66, 40))

    # Sparse pixel fibers/creases. Deliberate and quiet, not noisy.
    fibers = [
      [63,55,22,1], [104,74,17,1], [294,54,31,1], [349,89,18,1],
      [70,146,28,1], [263,151,20,1], [329,139,25,1],
      [143,47,1,12], [222,60,1,9], [312,111,1,13]
    ]
    fibers.each do |r|
      bmp.fill_rect(r[0], r[1], r[2], r[3], Color.new(188,151,102,48))
    end

    #-------------------------------------------------------------------------
    # Decorative Bushido corner strokes inside the writable body
    #-------------------------------------------------------------------------
    bmp.fill_rect(49, 42, 28, 2, BushidoNaming::GOLD)
    bmp.fill_rect(49, 42, 2, 10, BushidoNaming::GOLD)

    bmp.fill_rect(w - 77, 42, 28, 2, BushidoNaming::GOLD)
    bmp.fill_rect(w - 51, 42, 2, 10, BushidoNaming::GOLD)

    # Divider above controls
    bmp.fill_rect(55, 151, w - 110, 2, dark)
    bmp.fill_rect(55, 153, w - 110, 1, Color.new(255, 245, 217, 80))
  end

  #=============================================================================
  # Subject graphics
  #=============================================================================
  def createSubject(subject, pokemon)
    case subject
    when 1
      createPlayerSubject
    when 2
      createPokemonSubject(pokemon)
    when 3
      createNPCSubject(pokemon)
    when 4
      createStorageSubject
    end
  end

  def createPlayerSubject
    begin
      meta = pbGetMetadata(0, MetadataPlayerA + $PokemonGlobal.playerID)
      return if !meta

      filename = pbGetPlayerCharset(meta, 1, nil, true)
      @sprites["subject"] = TrainerWalkingCharSprite.new(filename, @viewport)

      cw = @sprites["subject"].bitmap.width
      ch = @sprites["subject"].bitmap.height

      @sprites["subject"].x = @panelX + BushidoNaming::SUBJECT_X - cw / 8
      @sprites["subject"].y = @panelY + BushidoNaming::SUBJECT_Y - ch / 4
      @sprites["subject"].opacity = 0
    rescue
      @sprites.delete("subject")
    end
  end

  def createPokemonSubject(pokemon)
    return if !pokemon

    begin
      # Small backing card gives the icon a deliberate home without turning
      # into another "textbox".
      @sprites["subjectBack"] = BitmapSprite.new(76, 76, @viewport)
      @sprites["subjectBack"].x = @panelX + 64
      @sprites["subjectBack"].y = @panelY + 82

      b = @sprites["subjectBack"].bitmap
      b.fill_rect(0, 0, 76, 76, BushidoNaming::PARCHMENT_DARK)
      b.fill_rect(3, 3, 70, 70, BushidoNaming::PARCHMENT_LIGHT)
      b.fill_rect(9, 69, 52, 2, BushidoNaming::GOLD)

      @sprites["subject"] = PokemonIconSprite.new(pokemon, @viewport)
      @sprites["subject"].setOffset(PictureOrigin::Center)
      @sprites["subject"].x = @panelX + 102
      @sprites["subject"].y = @panelY + 122

      # Gender sits near the portrait, not near the typed text.
      @sprites["gender"] = BitmapSprite.new(28, 28, @viewport)
      @sprites["gender"].x = @panelX + 122
      @sprites["gender"].y = @panelY + 80
      pbSetSystemFont(@sprites["gender"].bitmap)

      genderText = []
      if pokemon.male?
        genderText.push([
          _INTL("♂"), 0, 0, 0,
          BushidoNaming::MALE_COLOR,
          BushidoNaming::SHADOW
        ])
      elsif pokemon.female?
        genderText.push([
          _INTL("♀"), 0, 0, 0,
          BushidoNaming::FEMALE_COLOR,
          BushidoNaming::SHADOW
        ])
      end
      pbDrawTextPositions(@sprites["gender"].bitmap, genderText)

      @sprites["subjectBack"].opacity = 0
      @sprites["subject"].opacity     = 0
      @sprites["gender"].opacity      = 0
    rescue
      # Naming should never fail just because a decorative subject couldn't load.
      @sprites.delete("subjectBack")
      @sprites.delete("subject")
      @sprites.delete("gender")
    end
  end

  def createNPCSubject(id)
    begin
      @sprites["subject"] = TrainerWalkingCharSprite.new(id.to_s, @viewport)
      cw = @sprites["subject"].bitmap.width
      ch = @sprites["subject"].bitmap.height
      @sprites["subject"].x = @panelX + BushidoNaming::SUBJECT_X - cw / 8
      @sprites["subject"].y = @panelY + BushidoNaming::SUBJECT_Y - ch / 4
      @sprites["subject"].opacity = 0
    rescue
      @sprites.delete("subject")
    end
  end

  def createStorageSubject
    begin
      @sprites["subject"] = TrainerWalkingCharSprite.new(nil, @viewport)
      @sprites["subject"].altcharset = "Graphics/Pictures/Naming/icon_storage"
      @sprites["subject"].animspeed = 4

      cw = @sprites["subject"].bitmap.width
      ch = @sprites["subject"].bitmap.height
      @sprites["subject"].x = @panelX + BushidoNaming::SUBJECT_X - cw / 8
      @sprites["subject"].y = @panelY + BushidoNaming::SUBJECT_Y - ch / 2
      @sprites["subject"].opacity = 0
    rescue
      @sprites.delete("subject")
    end
  end

  #=============================================================================
  # Exact text drawing helpers
  #
  # Bushido's MKXP Bitmap#draw_text override forces the draw height to the
  # font's measured height. That means "fake" rectangles and y-offset hacks are
  # unreliable for vertical centering. These helpers measure the actual glyph
  # height and draw from an explicit top-left pixel position instead.
  #=============================================================================
  def drawExactText(bmp, text, x, y, width,
                    baseColor = BushidoNaming::INK,
                    shadowColor = BushidoNaming::SHADOW,
                    align = 0)
    h = bmp.text_size("Ag").height

    oldColor = bmp.font.color

    bmp.font.color = shadowColor
    bmp.draw_text(x + 2, y + 2, width, h, text, align)

    bmp.font.color = baseColor
    bmp.draw_text(x, y, width, h, text, align)

    bmp.font.color = oldColor

    return h
  end

  def measuredTextHeight(bmp)
    return bmp.text_size("Ag").height
  end

  #=============================================================================
  # UI drawing
  #=============================================================================
  def refreshUI(force = false)
    entry = @sprites["entry"]
    return if !entry

    text   = entry.text
    cursor = entry.cursor_index

    return if !force && text == @lastText && cursor == @lastCursor

    @lastText   = text.clone
    @lastCursor = cursor

    bmp = @sprites["overlay"].bitmap
    bmp.clear
    pbSetSystemFont(bmp)

    drawPrompt(bmp)
    drawNameEntry(bmp, text, cursor)
    drawControls(bmp)
  end

  def drawPrompt(bmp)
    pbDrawTextPositions(bmp, [[
      @helptext,
      Graphics.width / 2,
      @panelY + BushidoNaming::PROMPT_Y,
      2,
      BushidoNaming::INK,
      BushidoNaming::SHADOW
    ]])
  end

  def drawNameEntry(bmp, text, cursor)
    hasSubject = (@subjectType != 0 && @sprites["subject"])

    x = @panelX +
        (hasSubject ? BushidoNaming::NAME_X_WITH_ICON :
                      BushidoNaming::NAME_X_NO_ICON)

    fullRight = @panelX + BushidoNaming::PANEL_WIDTH -
                BushidoNaming::NAME_RIGHT_MARGIN

    y = @panelY + BushidoNaming::NAME_Y
    lineY = @panelY + BushidoNaming::UNDERLINE_Y

    # Character count lives on the SAME baseline as the nickname, at the far
    # right. Reserve real space for it instead of drawing it on top of the line.
    chars = text.scan(/./m)
    countText = _INTL("{1}/{2}", chars.length, @maxlength)

    countW = bmp.text_size(countText).width
    countGap = 12

    textRight = fullRight - countW - countGap
    textWidth = textRight - x

    # Underline spans the whole name region, including the count.
    bmp.fill_rect(
      x,
      lineY,
      fullRight - x,
      2,
      BushidoNaming::PARCHMENT_DARK
    )

    # Name: normal Bushido font, explicit top coordinate.
    drawExactText(
      bmp,
      text,
      x,
      y,
      textWidth,
      BushidoNaming::INK,
      BushidoNaming::SHADOW,
      0
    )

    # Count: same font and baseline, just muted and right-aligned.
    drawExactText(
      bmp,
      countText,
      fullRight - countW,
      y,
      countW,
      BushidoNaming::MUTED,
      BushidoNaming::SHADOW,
      2
    )

    # Caret at the real edit cursor.
    cursor = 0 if cursor < 0
    cursor = chars.length if cursor > chars.length
    before = chars[0, cursor].join("")

    caretX = x + bmp.text_size(before).width
    caretX = textRight - 2 if caretX > textRight - 2

    textH = measuredTextHeight(bmp)

    if ((Graphics.frame_count / 15) & 1) == 0
      caretTop = y + 4
      caretBottom = [lineY - 4, y + textH - 2].min
      caretH = caretBottom - caretTop
      caretH = 2 if caretH < 2

      bmp.fill_rect(
        caretX,
        caretTop,
        2,
        caretH,
        BushidoNaming::INK
      )
    end
  end

  # Draw one keyboard keycap plus its action.
  #
  # Everything uses the normal system font. The box dimensions are derived
  # from text_size, so the letters are genuinely centered rather than visually
  # "nudged" into a hardcoded rectangle.
  def drawKeyPair(bmp, x, y, keyText, actionText)
    textH = measuredTextHeight(bmp)

    keyTextW = bmp.text_size(keyText).width
    actionW  = bmp.text_size(actionText).width

    padX = 8
    padY = 3

    keyW = keyTextW + (padX * 2)
    keyH = textH + (padY * 2)

    # Pixel shadow.
    bmp.fill_rect(
      x + 2,
      y + 2,
      keyW,
      keyH,
      Color.new(83, 55, 33, 45)
    )

    # Keycap border + face.
    bmp.fill_rect(
      x,
      y,
      keyW,
      keyH,
      BushidoNaming::PARCHMENT_DARK
    )

    bmp.fill_rect(
      x + 2,
      y + 2,
      keyW - 4,
      keyH - 4,
      BushidoNaming::PARCHMENT_LIGHT
    )

    # Explicit top coordinate: exactly padY pixels from the cap's top.
    drawExactText(
      bmp,
      keyText,
      x + padX,
      y + padY,
      keyTextW,
      BushidoNaming::INK,
      BushidoNaming::SHADOW,
      0
    )

    # Keep action tightly attached to its keycap.
    actionGap = 7
    actionX = x + keyW + actionGap

    drawExactText(
      bmp,
      actionText,
      actionX,
      y + padY,
      actionW,
      BushidoNaming::INK,
      BushidoNaming::SHADOW,
      0
    )

    return keyW + actionGap + actionW
  end

  def drawControls(bmp)
    y = @panelY + BushidoNaming::CONTROLS_Y

    enterKey = "ENTER"
    enterAct = _INTL("Confirm")

    textH = measuredTextHeight(bmp)
    padX  = 8

    enterKeyW = bmp.text_size(enterKey).width + (padX * 2)
    enterActW = bmp.text_size(enterAct).width
    enterTotal = enterKeyW + 7 + enterActW

    if @minlength == 0
      escKey = "ESC"
      escAct = _INTL("Cancel")

      escKeyW = bmp.text_size(escKey).width + (padX * 2)
      escActW = bmp.text_size(escAct).width
      escTotal = escKeyW + 7 + escActW

      # Pair gap is the ONLY large gap. Inside each pair, key and action are
      # intentionally close together.
      pairGap = 24
      total = enterTotal + pairGap + escTotal
      startX = (Graphics.width - total) / 2

      used = drawKeyPair(
        bmp,
        startX,
        y,
        enterKey,
        enterAct
      )

      drawKeyPair(
        bmp,
        startX + used + pairGap,
        y,
        escKey,
        escAct
      )
    else
      startX = (Graphics.width - enterTotal) / 2

      drawKeyPair(
        bmp,
        startX,
        y,
        enterKey,
        enterAct
      )
    end
  end

  #=============================================================================
  # Input
  #=============================================================================
  def pbEntry
    ret = ""

    loop do
      Graphics.update
      Input.update

      # Escape/cancel is only valid when minlength permits an empty result.
      if Input.triggerex?(0x1B) && @minlength == 0
        pbPlayCancelSE()
        ret = ""
        break
      end

      # Enter/confirm.
      if Input.triggerex?(0x0D)
        if @sprites["entry"].text.length >= @minlength &&
           @sprites["entry"].text.length <= @maxlength
          pbPlayDecisionSE()
          ret = @sprites["entry"].text
          break
        else
          pbPlayBuzzerSE()
        end
      end

      # Hidden stock keyboard editor handles:
      # typing, Backspace, Left, Right, repeat timing and max length.
      @sprites["entry"].update

      # Subject animation.
      @sprites["subject"].update if @sprites["subject"]

      # We redraw only if text/cursor changed, plus during caret blink boundaries.
      blinkFrame = (Graphics.frame_count % 15 == 0)
      refreshUI(blinkFrame)
    end

    Input.update
    return ret
  end

  def pbUpdate
    @sprites["subject"].update if @sprites["subject"]
  end

  #=============================================================================
  # Animations
  #=============================================================================
  def playOpenAnimation
    frames = BushidoNaming::OPEN_FRAMES
    frames = 1 if frames < 1

    @sprites["scroll"].zoom_x = 0.08
    @sprites["scroll"].opacity = 0

    for i in 0...frames
      Graphics.update

      t = (i + 1).to_f / frames
      e = BushidoNaming.ease_out(t)

      @sprites["dimmer"].opacity  = (255 * e).to_i
      @sprites["scroll"].opacity  = (255 * e).to_i
      @sprites["scroll"].zoom_x   = 0.08 + (0.92 * e)
      @sprites["overlay"].opacity = (255 * e).to_i

      setSubjectOpacity((255 * e).to_i)
    end

    @sprites["scroll"].zoom_x   = 1.0
    @sprites["scroll"].opacity  = 255
    @sprites["dimmer"].opacity  = 255
    @sprites["overlay"].opacity = 255
    setSubjectOpacity(255)
  end

  def playCloseAnimation
    return if @closing
    @closing = true

    frames = BushidoNaming::CLOSE_FRAMES
    frames = 1 if frames < 1

    for i in 0...frames
      Graphics.update

      t = (i + 1).to_f / frames
      e = BushidoNaming.ease_in(t)
      remain = 1.0 - e

      @sprites["dimmer"].opacity  = (255 * remain).to_i
      @sprites["scroll"].opacity  = (255 * remain).to_i
      @sprites["scroll"].zoom_x   = 0.08 + (0.92 * remain)
      @sprites["overlay"].opacity = (255 * remain).to_i

      setSubjectOpacity((255 * remain).to_i)
    end
  end

  def setSubjectOpacity(value)
    @sprites["subjectBack"].opacity = value if @sprites["subjectBack"]
    @sprites["subject"].opacity     = value if @sprites["subject"]
    @sprites["gender"].opacity      = value if @sprites["gender"]
  end

  #=============================================================================
  # Scene end
  #=============================================================================
  def pbEndScene
    Input.text_input = false
    playCloseAnimation

    pbDisposeSpriteHash(@sprites)

    if @viewport && !@viewport.disposed?
      @viewport.dispose
    end

    # Bushido modification from the original naming scene.
    pbAllowSpeedup()
  end
end


#===============================================================================
# Entry-point overrides
#
# The stock v18 pbEnterText wraps the naming scene in pbFadeOutIn, which is what
# makes it full-screen/black before the naming UI appears. We intentionally
# remove that wrapper so the current scene remains visible beneath the modal.
#===============================================================================
def pbEnterText(helptext, minlength, maxlength, initialText = "",
                mode = 0, pokemon = nil, nofadeout = false)
  scene  = PokemonEntryScene.new
  screen = PokemonEntry.new(scene)

  return screen.pbStartScreen(
    helptext,
    minlength,
    maxlength,
    initialText,
    mode,
    pokemon
  )
end

def pbEnterPlayerName(helptext, minlength, maxlength,
                      initialText = "", nofadeout = false)
  return pbEnterText(
    helptext, minlength, maxlength,
    initialText, 1, nil, nofadeout
  )
end

def pbEnterPokemonName(helptext, minlength, maxlength,
                       initialText = "", pokemon = nil, nofadeout = false)
  return pbEnterText(
    helptext, minlength, maxlength,
    initialText, 2, pokemon, nofadeout
  )
end

def pbEnterNPCName(helptext, minlength, maxlength,
                   initialText = "", id = 0, nofadeout = false)
  return pbEnterText(
    helptext, minlength, maxlength,
    initialText, 3, id, nofadeout
  )
end

def pbEnterBoxName(helptext, minlength, maxlength,
                   initialText = "", nofadeout = false)
  return pbEnterText(
    helptext, minlength, maxlength,
    initialText, 4, nil, nofadeout
  )
end


#===============================================================================
# Debug/test helpers
#===============================================================================

# Test the actual first Pokémon in the player's party.
#
# Event Script:
#   pbBushidoNamingTest
#
def pbBushidoNamingTest
  if !$Trainer || !$Trainer.party || $Trainer.party.length == 0
    pbMessage(_INTL("Put a Pokémon in your party first."))
    return
  end

  pokemon = $Trainer.party[0]
  oldName = pokemon.name

  # Prefer the project's own name-size constant if available.
  maxLength = 12
  begin
    maxLength = Pokemon::MAX_NAME_SIZE
  rescue
  end

  newName = pbEnterPokemonName(
    _INTL("Give {1} a new name.", oldName),
    0,
    maxLength,
    oldName,
    pokemon
  )

  if newName && newName != ""
    pokemon.name = newName
    pbMessage(_INTL("{1} is now named {2}!", oldName, newName))
  end
end


# Raw modal test without requiring a party Pokémon.
#
# Event Script:
#   pbBushidoNamingTextTest
#
def pbBushidoNamingTextTest
  result = pbEnterText(
    _INTL("Name this Pokémon."),
    0,
    12,
    "",
    0,
    nil
  )

  if result && result != ""
    pbMessage(_INTL("You entered: {1}", result))
  end
end
