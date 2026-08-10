def pbBushidoFontLab
  fonts = [
    ["Power Clear", MessageConfig.pbGetSystemFontName],
    ["Power Green Small", pbSmallFontName]
  ]

  font_index = 0
  font_size = 16
  page = 0

  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999

  sprite = Sprite.new(viewport)
  sprite.bitmap = Bitmap.new(Graphics.width, Graphics.height)

  bitmap = sprite.bitmap
  redraw = true

  loop do
    if redraw
      bitmap.clear
      bitmap.fill_rect(
        0,
        0,
        Graphics.width,
        Graphics.height,
        Color.new(24, 24, 24)
      )

      if page == 0
        # =========================
        # PAGE 1: FONT TESTER
        # =========================

        font_label = fonts[font_index][0]
        font_name  = fonts[font_index][1]

        bitmap.font.name = font_name
        bitmap.font.size = font_size
        bitmap.font.bold = false
        bitmap.font.italic = false
        bitmap.font.color = Color.new(255, 255, 255)

        y = 12

        bitmap.draw_text(12, y, Graphics.width - 24, 32, "BUSHIDO FONT LAB")
        y += 34

        bitmap.draw_text(12, y, Graphics.width - 24, 32, "Font: #{font_label}")
        y += 28

        bitmap.draw_text(12, y, Graphics.width - 24, 32, "Size: #{font_size}px")
        y += 42

        samples = [
          "Blissey",
          "Tyranitar ♀  Lv.100",
          "Farfetch'd",
          "Flabébé",
          "",
          "SUMMARY   SWITCH   ITEM   CANCEL",
          "324/324",
          "",
          "The quick brown fox jumps over the lazy dog.",
          "0123456789"
        ]

        samples.each do |text|
          if text == ""
            y += font_size
            next
          end

          bitmap.draw_text(
            12,
            y,
            Graphics.width - 24,
            [font_size + 12, 28].max,
            text
          )

          y += [font_size + 8, 24].max
        end

        bitmap.font.name = "Arial"
        bitmap.font.size = 14
        bitmap.font.color = Color.new(180, 180, 180)

        bitmap.draw_text(
          12,
          Graphics.height - 28,
          Graphics.width - 24,
          20,
          "LEFT/RIGHT: Font   UP/DOWN: Size   X: Mock UI   CANCEL: Exit"
        )

      else
        # =========================
        # PAGE 2: MOCK BUSHIDO UI
        # =========================

        # Header
        bitmap.font.name = MessageConfig.pbGetSystemFontName
        bitmap.font.size = 16
        bitmap.font.bold = false
        bitmap.font.italic = false
        bitmap.font.color = Color.new(255, 255, 255)

        bitmap.draw_text(
          24,
          18,
          Graphics.width - 48,
          28,
          "BLISSEY"
        )

        # Small metadata
        bitmap.font.name = pbSmallFontName
        bitmap.font.size = 12
        bitmap.font.color = Color.new(220, 220, 220)

        bitmap.draw_text(
          24,
          52,
          Graphics.width - 48,
          22,
          "Lv.100   NORMAL"
        )

        bitmap.draw_text(
          24,
          84,
          Graphics.width - 48,
          22,
          "HP"
        )

        # Main stat
        bitmap.font.name = MessageConfig.pbGetSystemFontName
        bitmap.font.size = 16
        bitmap.font.color = Color.new(255, 255, 255)

        bitmap.draw_text(
          24,
          106,
          Graphics.width - 48,
          28,
          "324 / 324"
        )

        # Divider
        bitmap.fill_rect(
          24,
          148,
          Graphics.width - 48,
          1,
          Color.new(110, 110, 110)
        )

        # Actions
        bitmap.font.name = MessageConfig.pbGetSystemFontName
        bitmap.font.size = 16

        bitmap.draw_text(24, 164, 280, 28, "SUMMARY")
        bitmap.draw_text(320, 164, 280, 28, "SWITCH")

        bitmap.draw_text(24, 198, 280, 28, "ITEM")
        bitmap.draw_text(320, 198, 280, 28, "CANCEL")

        # Description
        bitmap.font.name = pbSmallFontName
        bitmap.font.size = 12
        bitmap.font.color = Color.new(220, 220, 220)

        bitmap.draw_text(
          24,
          252,
          Graphics.width - 48,
          22,
          "A normal-type Pokémon with"
        )

        bitmap.draw_text(
          24,
          272,
          Graphics.width - 48,
          22,
          "an incredibly large egg."
        )

        # Footer
        bitmap.font.name = "Arial"
        bitmap.font.size = 14
        bitmap.font.color = Color.new(180, 180, 180)

        bitmap.draw_text(
          12,
          Graphics.height - 28,
          Graphics.width - 24,
          20,
          "X: Back to Font Tester   CANCEL: Exit"
        )
      end

      redraw = false
    end

    Graphics.update
    Input.update

    if Input.trigger?(Input::X)
      page = (page == 0) ? 1 : 0
      redraw = true

    elsif page == 0 && Input.trigger?(Input::LEFT)
      font_index -= 1
      font_index = fonts.length - 1 if font_index < 0
      redraw = true

    elsif page == 0 && Input.trigger?(Input::RIGHT)
      font_index += 1
      font_index = 0 if font_index >= fonts.length
      redraw = true

    elsif page == 0 && Input.trigger?(Input::UP)
      font_size += 1
      font_size = 32 if font_size > 32
      redraw = true

    elsif page == 0 && Input.trigger?(Input::DOWN)
      font_size -= 1
      font_size = 8 if font_size < 8
      redraw = true

    elsif Input.trigger?(Input::B)
      break
    end
  end

  sprite.bitmap.dispose
  sprite.dispose
  viewport.dispose
end