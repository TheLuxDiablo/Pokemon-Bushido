#===============================================================================
# Bushido Cinematic Messages
#===============================================================================

module BushidoCinematicMessages
  DEFAULT_FADE_IN  = 15
  DEFAULT_FADE_OUT = 15
  DEFAULT_HOLD     = 40

  CINEMATIC_TIME_SCALE = 2.00
  CINEMATIC_EXTRA_HOLD = 30
  INPUT_GRACE_FRAMES   = 10

  MARGIN = 48

  def self.extract_number!(text, tag, default)
    value = default

    if text =~ /\\#{tag}\[([0-9]+)\]/i
      value = $1.to_i
      text.gsub!(/\\#{tag}\[[0-9]+\]/i, "")
    end

    return value
  end

  def self.scaled_frames(frames)
    value = (frames.to_f * CINEMATIC_TIME_SCALE).round
    return [value, 0].max
  end

  def self.prepare_text(message)
    text = message.clone

    text.gsub!(/\\cin/i, "")

    fade_in  = scaled_frames(extract_number!(text, "fi",   DEFAULT_FADE_IN))
    fade_out = scaled_frames(extract_number!(text, "fo",   DEFAULT_FADE_OUT))
    hold     = scaled_frames(extract_number!(text, "wtnp", DEFAULT_HOLD)) + CINEMATIC_EXTRA_HOLD

    text.gsub!(/\\fs\[[0-9]+\]/i, "")
    text.gsub!(/<\/?ac>/i, "")
    text.gsub!(/\\c\[[0-9]+\]/i, "")
    text.gsub!(/\\wt\[[0-9]+\]/i, "")
    text.gsub!(/\\\^/i, "")
    text.gsub!(/\\n/i, "\n")

    return [text, fade_in, fade_out, hold]
  end

  def self.update_frame
    Graphics.update
    Input.update
  end

  def self.confirm?
    return Input.trigger?(Input::C)
  end

  def self.fade(sprite, from, to, frames, grace_frames = 0)
    frames = frames.to_i

    if frames <= 0
      sprite.opacity = to
      return
    end

    for i in 0...frames
      update_frame

      if i >= grace_frames && confirm?
        sprite.opacity = to
        return
      end

      t = (i + 1).to_f / frames.to_f
      sprite.opacity = (from + ((to - from) * t)).to_i
    end

    sprite.opacity = to
  end

  def self.hold(frames, grace_frames = 0)
    frames = frames.to_i
    return if frames <= 0

    frames.times do |i|
      update_frame
      return if i >= grace_frames && confirm?
    end
  end

  # Draws the cinematic text.
  def self.draw_centered(bitmap, text)
    bitmap.clear
    pbSetSystemFont(bitmap) if defined?(pbSetSystemFont)

    width = Graphics.width - (MARGIN * 2)

    formatted = "<ac><c3=FFFFFF,707070>#{text}</c3></ac>"

    lineheight = 32

    chars = getFormattedText(
      bitmap,
      MARGIN,
      0,
      width,
      -1,
      formatted,
      lineheight
    )

    return if !chars || chars.length == 0

    min_y = nil
    max_y = nil

    chars.each do |ch|
      next if !ch || ch.length < 5

      y = ch[2]
      h = ch[4]

      min_y = y if min_y.nil? || y < min_y
      max_y = y + h if max_y.nil? || y + h > max_y
    end

    min_y ||= 0
    max_y ||= lineheight

    block_height = max_y - min_y
    target_top = ((Graphics.height - block_height) / 2.0).round
    offset_y = target_top - min_y

    chars.each do |ch|
      next if !ch || ch.length < 3
      ch[2] += offset_y
    end

    drawFormattedChars(bitmap, chars)
  end

  # Shows a cinematic message.
  def self.show(msgwindow, message)
    text, fade_in, fade_out, hold_frames = prepare_text(message)

    old_visible = nil

    if msgwindow && msgwindow.respond_to?(:visible)
      old_visible = msgwindow.visible
      msgwindow.visible = false
    end

    viewport = Viewport.new(
      0,
      0,
      Graphics.width,
      Graphics.height
    )

    viewport.z = 99999

    text_sprite = Sprite.new(viewport)
    text_sprite.bitmap = Bitmap.new(
      Graphics.width,
      Graphics.height
    )

    draw_centered(
      text_sprite.bitmap,
      text
    )

    text_sprite.opacity = 0

    fade(
      text_sprite,
      0,
      255,
      fade_in,
      INPUT_GRACE_FRAMES
    )

    hold(
      hold_frames,
      INPUT_GRACE_FRAMES
    )

    fade(
      text_sprite,
      255,
      0,
      fade_out,
      0
    )

    text_sprite.bitmap.dispose if
      text_sprite.bitmap &&
      !text_sprite.bitmap.disposed?

    text_sprite.dispose unless
      text_sprite.disposed?

    viewport.dispose unless
      viewport.disposed?

    msgwindow.visible = old_visible if
      msgwindow &&
      !old_visible.nil?

    return nil
  end
end

#===============================================================================
# Message Hook
#===============================================================================

alias bushido_cinematic_original_pbMessageDisplay pbMessageDisplay

def pbMessageDisplay(msgwindow, message, letterbyletter=true, commandProc=nil)
  if message && message =~ /\\cin/i
    return BushidoCinematicMessages.show(
      msgwindow,
      message
    )
  end

  return bushido_cinematic_original_pbMessageDisplay(
    msgwindow,
    message,
    letterbyletter,
    commandProc
  )
end