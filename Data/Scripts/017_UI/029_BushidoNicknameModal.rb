# Bushido naming scroll
# replacement keyboard naming UI for Essentials v18.1

module BushidoNaming
  # layout values are all in one place so I can tweak the screen without hunting through the drawing code
  PANEL_WIDTH        = 440
  PANEL_HEIGHT       = 224
  PANEL_Y_OFFSET     = -4

  BODY_LEFT          = 35
  BODY_RIGHT         = 35
  BODY_TOP           = 24
  BODY_BOTTOM        = 24

  PROMPT_Y           = 40

  SUBJECT_X          = 96
  SUBJECT_Y          = 103

  NAME_X_WITH_ICON   = 164
  NAME_X_NO_ICON     = 86
  NAME_Y             = 101
  NAME_RIGHT_MARGIN  = 54

  UNDERLINE_Y        = 132
  CONTROLS_Y         = 160

  DIM_ALPHA          = 112
  # short enough to feel snappy, but still sells the scroll opening/closing
  OPEN_FRAMES        = 10
  CLOSE_FRAMES       = 8

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

  def self.clamp(value, min_value, max_value)
    value = min_value if value < min_value
    value = max_value if value > max_value
    return value
  end

  def self.ease_out(t)
    return 1.0 - ((1.0 - t) * (1.0 - t))
  end

  def self.ease_in(t)
    return t * t
  end
end


# using the stock keyboard entry for editing only; the visible text is drawn separately below
class BushidoNameInput < Window_TextEntry_Keyboard
  def cursor_index
    begin
      return @helper.cursor
    rescue
      return self.text.scan(/./m).length
    end
  end
end


class PokemonEntryScene
  USEKEYBOARD = true

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

    # don't fade out the map here, this is meant to read as a modal

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

  def createScroll
    @sprites["scroll"] = Sprite.new(@viewport)
    @sprites["scroll"].bitmap = Bitmap.new(
      BushidoNaming::PANEL_WIDTH,
      BushidoNaming::PANEL_HEIGHT
    )

    # centered origin makes zoom_x look like the scroll is unfurling from the middle
    @sprites["scroll"].ox = BushidoNaming::PANEL_WIDTH / 2
    @sprites["scroll"].oy = BushidoNaming::PANEL_HEIGHT / 2
    @sprites["scroll"].x  = Graphics.width / 2
    @sprites["scroll"].y  = @panelY + BushidoNaming::PANEL_HEIGHT / 2

    drawScroll(@sprites["scroll"].bitmap)
  end

  def createOverlay
    @sprites["overlay"] = BitmapSprite.new(
      Graphics.width,
      Graphics.height,
      @viewport
    )
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @sprites["overlay"].opacity = 0
  end

  def createInput(initialText)
    # keep this offscreen/invisible; it only handles typing, backspace and cursor movement
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

  def drawScroll(bmp)
    bmp.clear

    w = BushidoNaming::PANEL_WIDTH
    h = BushidoNaming::PANEL_HEIGHT

    light = BushidoNaming::PARCHMENT_LIGHT
    body  = BushidoNaming::PARCHMENT
    mid   = BushidoNaming::PARCHMENT_MID
    dark  = BushidoNaming::PARCHMENT_DARK
    deep  = BushidoNaming::PARCHMENT_DEEP

    # draw the paper as an actual silhouette instead of stacking rectangles.
    # this makes the rough top/bottom edges the real edge of the bitmap.
    paper_left  = 31
    paper_right = w - 32
    top_base    = 22
    bottom_base = h - 24

    top_profile = [
      3,3,3,2,2,2,1,1,1,0,0,0,
      2,2,1,1,0,0,0,1,1,1,3,3,
      2,2,2,1,0,0,1,1,2,2,1,1,
      0,0,0,2,2,2,3,3,1,1,0,0
    ]

    bottom_profile = [
      0,0,1,1,2,2,3,3,2,2,1,1,
      3,3,4,4,2,2,1,1,0,0,2,2,
      3,3,1,1,0,0,2,2,4,4,3,3,
      1,1,2,2,3,3,1,1,0,0,2,2
    ]

    x = paper_left
    while x <= paper_right
      index = (x - paper_left) % top_profile.length

      top_y    = top_base + top_profile[index]
      bottom_y = bottom_base - bottom_profile[index]
      column_h = bottom_y - top_y + 1

      if column_h > 0
        bmp.fill_rect(x, top_y, 1, column_h, dark)

        inner_top    = top_y + 2
        inner_bottom = bottom_y - 2

        if inner_bottom >= inner_top
          bmp.fill_rect(
            x,
            inner_top,
            1,
            inner_bottom - inner_top + 1,
            light
          )
        end

        shade_top = bottom_y - 8
        if shade_top > inner_top
          bmp.fill_rect(
            x,
            shade_top,
            1,
            [6, bottom_y - shade_top].min,
            body
          )
        end
      end

      x += 1
    end

    # a few little cuts keep the edge from looking too procedural
    top_nicks = [
      [71,24,3,6],
      [119,23,2,5],
      [181,24,3,7],
      [261,23,2,5],
      [333,24,3,6],
      [397,23,2,5]
    ]

    top_nicks.each do |r|
      bmp.fill_rect(r[0], r[1], r[2], r[3], dark)
    end

    bottom_nicks = [
      [79,bottom_base - 8,3,6],
      [151,bottom_base - 6,2,5],
      [226,bottom_base - 9,3,7],
      [299,bottom_base - 7,2,5],
      [368,bottom_base - 8,3,6]
    ]

    bottom_nicks.each do |r|
      bmp.fill_rect(r[0], r[1], r[2], r[3], dark)
    end

    # left roll
    bmp.fill_rect(9, 13, 23, h - 26, deep)
    bmp.fill_rect(12, 10, 17, h - 20, dark)
    bmp.fill_rect(15, 13, 11, h - 26, mid)
    bmp.fill_rect(18, 15, 5, h - 30, light)

    bmp.fill_rect(5, 8, 28, 9, deep)
    bmp.fill_rect(8, 5, 22, 9, dark)
    bmp.fill_rect(11, 7, 16, 5, light)
    bmp.fill_rect(7, 14, 10, 5, deep)

    bmp.fill_rect(5, h - 17, 28, 9, deep)
    bmp.fill_rect(8, h - 14, 22, 9, dark)
    bmp.fill_rect(11, h - 12, 16, 5, light)
    bmp.fill_rect(7, h - 19, 10, 5, deep)

    bmp.fill_rect(26, 26, 6, h - 52, deep)
    bmp.fill_rect(29, 30, 4, h - 60, dark)

    # right roll
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

    # keep the parchment texture quiet
    fibers = [
      [63,55,22,1], [104,74,17,1], [294,54,31,1], [349,89,18,1],
      [70,146,28,1], [263,151,20,1], [329,139,25,1],
      [143,47,1,12], [222,60,1,9], [312,111,1,13]
    ]

    fibers.each do |r|
      bmp.fill_rect(
        r[0],
        r[1],
        r[2],
        r[3],
        BushidoNaming::PARCHMENT_DARK
      )
    end

    bmp.fill_rect(49, 42, 28, 2, BushidoNaming::GOLD)
    bmp.fill_rect(49, 42, 2, 10, BushidoNaming::GOLD)

    bmp.fill_rect(w - 77, 42, 28, 2, BushidoNaming::GOLD)
    bmp.fill_rect(w - 51, 42, 2, 10, BushidoNaming::GOLD)

    bmp.fill_rect(55, 154, w - 110, 2, dark)
    bmp.fill_rect(55, 156, w - 110, 1, light)
  end

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
    # the little backing card keeps the icon readable without bringing back the old textbox look
    return if !pokemon

    begin
      @sprites["subjectBack"] = BitmapSprite.new(76, 76, @viewport)
      @sprites["subjectBack"].x = @panelX + 64
      @sprites["subjectBack"].y = @panelY + 72

      b = @sprites["subjectBack"].bitmap
      b.fill_rect(0, 0, 76, 76, BushidoNaming::PARCHMENT_DARK)
      b.fill_rect(3, 3, 70, 70, BushidoNaming::PARCHMENT_LIGHT)
      b.fill_rect(9, 69, 52, 2, BushidoNaming::GOLD)

      @sprites["subject"] = PokemonIconSprite.new(pokemon, @viewport)
      @sprites["subject"].setOffset(PictureOrigin::Center)
      @sprites["subject"].x = @panelX + 102
      @sprites["subject"].y = @panelY + 112

      @sprites["gender"] = BitmapSprite.new(28, 28, @viewport)
      @sprites["gender"].x = @panelX + 122
      @sprites["gender"].y = @panelY + 70
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
      # the naming screen should still work even if a decorative sprite fails to load
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

  # draw_text in our MKXP setup ignores the height we pass it, so positioning from the measured font height is way more reliable
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

    chars = text.scan(/./m)
    countText = _INTL("{1}/{2}", chars.length, @maxlength)

    # reserve actual room for the count so a long nickname can't draw underneath it
    countW = bmp.text_size(countText).width
    countGap = 12

    textRight = fullRight - countW - countGap
    textWidth = textRight - x

    bmp.fill_rect(
      x,
      lineY,
      fullRight - x,
      2,
      BushidoNaming::PARCHMENT_DARK
    )

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

  def drawKeyPair(bmp, x, y, keyText, actionText)
    # size the keycap from the real text dimensions instead of eyeballing the box
    textH = measuredTextHeight(bmp)

    keyTextW = bmp.text_size(keyText).width
    actionW  = bmp.text_size(actionText).width

    padX = 8
    padY = 3

    keyW = keyTextW + (padX * 2)
    keyH = textH + (padY * 2)

    bmp.fill_rect(
      x + 2,
      y + 2,
      keyW,
      keyH,
      Color.new(139, 101, 66)
    )

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

      # only the two commands get a larger gap; the key and its action should stay visually paired
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

  def pbEntry
    ret = ""

    loop do
      Graphics.update
      Input.update

      if Input.triggerex?(0x1B) && @minlength == 0
        pbPlayCancelSE()
        ret = ""
        break
      end

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

      # stock entry window handles typing/backspace/arrows, we just never render the window itself
      @sprites["entry"].update

      @sprites["subject"].update if @sprites["subject"]

      blinkFrame = (Graphics.frame_count % 15 == 0)
      refreshUI(blinkFrame)
    end

    Input.update
    return ret
  end

  def pbUpdate
    @sprites["subject"].update if @sprites["subject"]
  end

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

  def pbEndScene
    Input.text_input = false
    playCloseAnimation

    pbDisposeSpriteHash(@sprites)

    if @viewport && !@viewport.disposed?
      @viewport.dispose
    end

    # naming used to manage this in Bushido already, so make sure speed-up is restored on the way out
    pbAllowSpeedup()
  end
end


# stock v18 fades before opening this scene; skipping that fade is what lets the map stay visible underneath
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


# quick event test: pbBushidoNamingTest
def pbBushidoNamingTest
  if !$Trainer || !$Trainer.party || $Trainer.party.length == 0
    pbMessage(_INTL("Put a Pokémon in your party first."))
    return
  end

  pokemon = $Trainer.party[0]
  oldName = pokemon.name

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