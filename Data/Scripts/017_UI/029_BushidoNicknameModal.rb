#===============================================================================
# Bushido Nickname Modal
#===============================================================================

def pbBushidoNicknameModalTest
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999

  # Dim the current scene behind the modal
  overlay = Sprite.new(viewport)
  overlay.bitmap = Bitmap.new(Graphics.width, Graphics.height)
  overlay.bitmap.fill_rect(
    0,
    0,
    Graphics.width,
    Graphics.height,
    Color.new(0, 0, 0, 120)
  )

  # Temporary modal box
  box = Sprite.new(viewport)
  box.bitmap = Bitmap.new(320, 140)

  box.bitmap.fill_rect(
    0,
    0,
    box.bitmap.width,
    box.bitmap.height,
    Color.new(240, 235, 210)
  )

  box.x = (Graphics.width - box.bitmap.width) / 2
  box.y = (Graphics.height - box.bitmap.height) / 2

  loop do
    Graphics.update
    Input.update

    break if Input.trigger?(Input::BACK)
  end

  box.bitmap.dispose
  box.dispose

  overlay.bitmap.dispose
  overlay.dispose

  viewport.dispose
end