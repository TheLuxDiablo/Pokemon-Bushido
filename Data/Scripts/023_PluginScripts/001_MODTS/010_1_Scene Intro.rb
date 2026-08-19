#===============================================================================
#  New animated and modular Title Screen for Pokemon Essentials
#    by Luka S.J.
#
#  ONLY FOR Essentials v17.x and v18.x
# ----------------
#  Adds new visual styles to the Pokemon Essentials title screen, and animates
#  depending on the styles selected.
#
#  A lot of time and effort went into making this an extensive and comprehensive
#  resource. So please be kind enough to give credit when using it.
#===============================================================================
class Scene_Intro

  def main
    Graphics.transition(0)
    # Loads up a species cry for the title screen
    species = MTS_SPECIES
    species = species.upcase.to_sym if species.is_a?(String)
    species = getConst(PBSpecies, MTS_SPECIES) if !MTS_SPECIES.nil? && !MTS_SPECIES.is_a?(Numeric)
    @cry = pbCryFile(species, MTS_SPECIES_FORM) if !species.nil?
    # Shows the native-text intro slides
    @skip = false
    self.showIntroText
    # loads the modular title screen
    @screen = ModularTitleScreen.new
    # Plays the title screen intro (is skippable)
    # BGM starts after the logo is fully revealed.
    @screen.intro
    # Creates/updates the main title screen loop
    self.update
    Graphics.freeze
  end

  # update for the title screen
  def update
    ret = 0
    loop do
      @screen.update
      Graphics.update
      Input.update
      if Input.press?(Input::DOWN) && Input.press?(Input::B) && Input.press?(Input::CTRL)
        ret = 1
        break
      end
      if Input.trigger?(Input::C) || Input.trigger?(Input::A) || Input.trigger?(Input::B) || Input.triggerex?(:ENTER)
        ret = 2
        break
      end
    end
    case ret
    when 1
      closeTitleDelete
    when 2
      @screen.confirmEffect if @screen.respond_to?(:confirmEffect)
      closeTitle
    end
  end

  def closeTitle
    # Play Cobalion's configured cry and keep the title alive while it finishes.
    pbSEPlay(@cry, 100, 100) if @cry

    # The Essentials cry helper doesn't expose reliable playback state here.
    # Give Cobalion's full cry enough room to finish before starting any fade.
    # 100 frames is about 2.5 seconds at Essentials' normal 40 FPS.
    100.times do
      @screen.update
      Graphics.update
    end

    # Only after the cry is finished do we transition away.
    pbBGMStop(0.8)

    fade_viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    fade_viewport.z = 9999999

    fade = Sprite.new(fade_viewport)
    fade.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    fade.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.black)
    fade.opacity = 0

    24.times do
      fade.opacity += 11
      fade.opacity = 255 if fade.opacity > 255
      @screen.update
      Graphics.update
    end

    disposeTitle

    fade.bitmap.dispose
    fade.dispose
    fade_viewport.dispose

    sscene = PokemonLoad_Scene.new
    sscreen = PokemonLoadScreen.new(sscene)
    sscreen.pbStartLoadScreen
  end

  def closeTitleDelete
    pbBGMStop(1.0)
    # disposes current title screen
    disposeTitle
    # initializes delete screen
    sscene = PokemonLoad_Scene.new
    sscreen = PokemonLoadScreen.new(sscene)
    sscreen.pbStartLoadScreen
  end

  def disposeTitle
    @screen.dispose
  end

  def wait(frames, advance = true)
    return false if @skip
    frames.times do
      Graphics.update
      Input.update
      if Input.trigger?(Input::C)
        @skip = true
        return false
      end
    end
    return true
  end

  def showIntroText
    slides = [
      [
        "First made for the Relic Castle",
        "Winter Game Jam #2",
        "1/31/21 - 3/14/21",
        "",
        "theluxdiablo",
        "Thundaga",
        "TristantineTheGreat",
        "HauntedArtStudio"
      ],
      [
        "The Bushido v2 update was made",
        "possible with help from:",
        "",
        "GolisopodUser",
        "ENLS",
        "Voltseon",
        "Pyvetal"
      ],
      [
        "Pokémon Bushido is an unofficial,",
        "non-commercial fan project.",
        "",
        "It is not affiliated with, endorsed by,",
        "or associated with Nintendo,",
        "The Pokémon Company, or Game Freak.",
        "",
        "Pokémon and all related trademarks",
        "and intellectual property belong to",
        "their respective owners."
      ]
    ]

    viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    viewport.z = 999999

    sprite = Sprite.new(viewport)
    sprite.bitmap = Bitmap.new(Graphics.width, Graphics.height)

    # Use Essentials' configured game font at its native size.
    # Don't manually resize the font, since that was causing the ugly scaling.
    pbSetSystemFont(sprite.bitmap)

    base = Color.new(255, 255, 255)
    shadow = Color.new(0, 0, 0)

    slides.each do |lines|
      sprite.bitmap.clear

      # Reapply the configured font after clearing, but keep its native size.
      pbSetSystemFont(sprite.bitmap)

      line_height = sprite.bitmap.font.size + 6
      block_height = lines.length * line_height
      start_y = ((Graphics.height - block_height) / 2).to_i

      # Pre-calculate each line's exact width so the typewriter stays centered
      # without shifting as new letters appear.
      layout = []
      lines.each_with_index do |line, i|
        width = line.empty? ? 0 : sprite.bitmap.text_size(line).width
        layout.push({
          :text => line,
          :x => ((Graphics.width - width) / 2).to_i,
          :y => start_y + (i * line_height),
          :width => width
        })
      end

      # Type the slide character-by-character directly onto the bitmap.
      # Each glyph is only drawn once, which keeps the text much cleaner.
      finished = false
      layout.each do |line_data|
        break if finished
        next if line_data[:text].empty?

        x = line_data[:x]
        char_count = 0

        line_data[:text].each_char do |char|
          char_width = sprite.bitmap.text_size(char).width

          # Native shadow + text. No sprite zooming or pre-rendered text image.
          sprite.bitmap.font.color = shadow
          sprite.bitmap.draw_text(
            x + 2, line_data[:y] + 2,
            char_width + 8, line_height,
            char
          )

          sprite.bitmap.font.color = base
          sprite.bitmap.draw_text(
            x, line_data[:y],
            char_width + 8, line_height,
            char
          )

          x += char_width
          char_count += 1

          # Draw three characters before advancing a frame.
          next if char_count % 3 != 0

          Graphics.update
          Input.update

          # Confirm while typing instantly completes the current slide.
          if Input.trigger?(Input::C)
            self.drawFullIntroSlide(sprite.bitmap, layout, base, shadow, line_height)
            finished = true
            break
          end
        end

        # Update once for any leftover characters at the end of the line.
        if !finished && char_count % 3 != 0
          Graphics.update
          Input.update
          if Input.trigger?(Input::C)
            self.drawFullIntroSlide(sprite.bitmap, layout, base, shadow, line_height)
            finished = true
          end
        end
      end

      # If we typed normally, the slide is already complete.
      # If we fast-forwarded, drawFullIntroSlide completed it for us.
      unless finished
        self.drawFullIntroSlide(sprite.bitmap, layout, base, shadow, line_height)
      end

      # Hold until confirm, or auto-advance after a short pause.
      advance = false
      90.times do
        Graphics.update
        Input.update
        if Input.trigger?(Input::C)
          advance = true
          break
        end
      end

      # Small clean fade between slides.
      12.times do
        sprite.opacity -= 22
        sprite.opacity = 0 if sprite.opacity < 0
        Graphics.update
        Input.update
      end

      sprite.opacity = 255
    end

    sprite.bitmap.dispose
    sprite.dispose
    viewport.dispose
  end

  def drawFullIntroSlide(bitmap, layout, base, shadow, line_height)
    bitmap.clear
    pbSetSystemFont(bitmap)

    layout.each do |line_data|
      next if line_data[:text].empty?

      bitmap.font.color = shadow
      bitmap.draw_text(
        line_data[:x] + 2,
        line_data[:y] + 2,
        line_data[:width] + 16,
        line_height,
        line_data[:text]
      )

      bitmap.font.color = base
      bitmap.draw_text(
        line_data[:x],
        line_data[:y],
        line_data[:width] + 16,
        line_height,
        line_data[:text]
      )
    end
  end
end
#===============================================================================
