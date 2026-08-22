#===============================================================================
# Bushido Kenshi Record
# Essentials v18.1
#
# Call:
#   pbKenshiRecord
#===============================================================================

module BushidoKenshiRecord
  #-----------------------------------------------------------------------------
  # Journey mark configuration
  #-----------------------------------------------------------------------------
  MARKS = [
    {
      :type     => :dojo,
      :name     => "Komorei Dojo",
      :subtitle => "Shogun's Quest",
      :leader   => "Unknown",
      :location => "Tsuchi Village",
      :mark     => "I",
      :color    => Color.new(174, 64, 55)
    },
    {
      :type     => :dojo,
      :name     => "Nensho Dojo",
      :subtitle => "Shogun's Quest",
      :leader   => "Unknown",
      :location => "Hanatsu Village",
      :mark     => "II",
      :color    => Color.new(67, 98, 151)
    },
    {
      :type     => :dojo,
      :name     => "Shimizu Dojo",
      :subtitle => "Shogun's Quest",
      :leader   => "Unknown",
      :location => "Chikyu Village",
      :mark     => "III",
      :color    => Color.new(130, 76, 145)
    },
    {
      :type     => :completion,
      :name     => "Journey Complete",
      :subtitle => "Final Record",
      :leader   => nil,
      :location => nil,
      :mark     => "完",
      :color    => Color.new(176, 52, 42)
    }
  ]

  #-----------------------------------------------------------------------------
  # Progression variables
  #-----------------------------------------------------------------------------
  POKEDEX_UNLOCK_VARIABLE    = 0
  TECHNIQUES_UNLOCK_VARIABLE = 0
  TECHNIQUES_COUNT_VARIABLE  = 0
  PROVINCE_VARIABLE          = 0

  DEFAULT_PROVINCE = "Ezo"

  #-----------------------------------------------------------------------------
  # Layout
  #-----------------------------------------------------------------------------
  PAPER_X = 24
  PAPER_Y = 28
  PAPER_W = 464
  PAPER_H = 328

  HEADER_BOX  = Rect.new(18, 12, 428, 42)
  PROFILE_BOX = Rect.new(18, 66, 246, 166)
  MARKS_BOX   = Rect.new(276, 66, 170, 166)
  STATS_BOX   = Rect.new(18, 244, 428, 66)

  STAMP_SIZE = 44

  #-----------------------------------------------------------------------------
  # Colors
  #-----------------------------------------------------------------------------
  PAPER_EDGE  = Color.new(149, 119, 81)
  PAPER       = Color.new(232, 216, 179)
  PAPER_LIGHT = Color.new(243, 231, 199)

  INK         = Color.new(61, 48, 37)
  INK_SOFT    = Color.new(102, 80, 58)
  INK_FAINT   = Color.new(145, 120, 87)

  TEXT_SHADOW = Color.new(213, 193, 153)
  SELECT      = Color.new(201, 153, 68)

  #=============================================================================
  # Progression helpers
  #=============================================================================

  def self.variable_enabled?(id)
    return false if id <= 0
    return false if !$game_variables

    value = $game_variables[id]

    return false if value == nil
    return false if value == false
    return false if value == 0
    return false if value == ""

    return true
  end

  def self.pokedex_unlocked?
    if POKEDEX_UNLOCK_VARIABLE > 0
      return variable_enabled?(POKEDEX_UNLOCK_VARIABLE)
    end

    return false if !$Trainer

    begin
      return $Trainer.pokedex ? true : false
    rescue
    end

    return false
  end

  def self.techniques_unlocked?
    return false if TECHNIQUES_UNLOCK_VARIABLE <= 0
    return variable_enabled?(TECHNIQUES_UNLOCK_VARIABLE)
  end

  def self.game_completed?
    return false if !$PokemonSystem
    return false if !$PokemonSystem.respond_to?(:game_modes_won)
    return false if !$PokemonSystem.game_modes_won

    return $PokemonSystem.game_modes_won[0] ? true : false
  end

  #=============================================================================
  # Marks
  #=============================================================================

  def self.visible_marks
    marks = [
      MARKS[0],
      MARKS[1],
      MARKS[2]
    ]

    marks.push(MARKS[3]) if game_completed?

    return marks
  end

  def self.mark_owned?(index)
    marks = visible_marks

    return false if index < 0
    return false if index >= marks.length

    mark = marks[index]

    if mark[:type] == :completion
      return game_completed?
    end

    return false if !$Trainer
    return false if !$Trainer.respond_to?(:badges)
    return false if !$Trainer.badges

    return $Trainer.badges[index] ? true : false
  end

  #=============================================================================
  # Player data
  #=============================================================================

  def self.player_name
    return "Kenshi" if !$Trainer
    return $Trainer.name.to_s
  end

  def self.player_id
    return "-----" if !$Trainer

    begin
      return sprintf("%05d", $Trainer.public_ID)
    rescue
    end

    begin
      return sprintf("%05d", $Trainer.id & 0xFFFF)
    rescue
    end

    return "-----"
  end

  def self.province
    if PROVINCE_VARIABLE > 0 &&
       $game_variables &&
       $game_variables[PROVINCE_VARIABLE] &&
       $game_variables[PROVINCE_VARIABLE].to_s != ""
      return $game_variables[PROVINCE_VARIABLE].to_s
    end

    return DEFAULT_PROVINCE
  end

  def self.technique_count
    return 0 if TECHNIQUES_COUNT_VARIABLE <= 0
    return 0 if !$game_variables

    value = $game_variables[TECHNIQUES_COUNT_VARIABLE]

    return 0 if value == nil

    return value.to_i
  end

  def self.seen_count
    return 0 if !$Trainer

    begin
      values = $Trainer.seen
      count = 0

      for i in 0...values.length
        count += 1 if values[i]
      end

      return count
    rescue
    end

    return 0
  end

  def self.caught_count
    return 0 if !$Trainer

    begin
      values = $Trainer.owned
      count = 0

      for i in 0...values.length
        count += 1 if values[i]
      end

      return count
    rescue
    end

    return 0
  end

  def self.money
    return 0 if !$Trainer

    begin
      return $Trainer.money
    rescue
    end

    return 0
  end

  def self.comma_number(number)
    text = number.to_i.to_s

    while text.sub!(/^(-?\d+)(\d{3})/, '\1,\2')
    end

    return text
  end

  def self.play_time
    seconds = Graphics.frame_count / Graphics.frame_rate
    hours   = seconds / 3600
    minutes = (seconds / 60) % 60

    return sprintf("%d:%02d", hours, minutes)
  end

  def self.visible_stats
    stats = []

    if pokedex_unlocked?
      stats.push(["SEEN", seen_count.to_s])
      stats.push(["CAUGHT", caught_count.to_s])
    end

    if techniques_unlocked?
      stats.push(["TECHNIQUES", technique_count.to_s])
    end

    stats.push([
      "MONEY",
      "$" + comma_number(money)
    ])

    stats.push([
      "TIME",
      play_time
    ])

    return stats
  end
end


#===============================================================================
# Scene
#===============================================================================

class BushidoKenshiRecord_Scene
  include BushidoKenshiRecord

  def pbStartScene
    @viewport = Viewport.new(
      0,
      0,
      Graphics.width,
      Graphics.height
    )
    @viewport.z = 99999

    @sprites       = {}
    @owned_bitmaps = []

    @selected     = 0
    @frame        = 0
    @detailsOpen  = false
    @visible_marks = BushidoKenshiRecord.visible_marks

    create_background
    create_shadow
    create_paper
    create_text_layer
    create_portrait
    create_stamps
    create_cursor
    create_detail_sprites

    prepare_intro
    play_intro
  end

  #=============================================================================
  # Background
  #=============================================================================

  def create_background
    sprite = Sprite.new(@viewport)
    sprite.bitmap = Bitmap.new(
      Graphics.width,
      Graphics.height
    )

    @owned_bitmaps.push(sprite.bitmap)

    sprite.bitmap.fill_rect(
      0,
      0,
      Graphics.width,
      Graphics.height,
      Color.new(26, 22, 18)
    )

    @sprites["background"] = sprite
  end

  #=============================================================================
  # Shadow
  #=============================================================================

  def create_shadow
    sprite = Sprite.new(@viewport)

    sprite.bitmap = Bitmap.new(
      PAPER_W + 12,
      PAPER_H + 12
    )

    @owned_bitmaps.push(sprite.bitmap)

    sprite.bitmap.fill_rect(
      6,
      8,
      PAPER_W,
      PAPER_H,
      Color.new(0, 0, 0, 115)
    )

    sprite.x = PAPER_X - 6
    sprite.y = PAPER_Y - 4

    sprite.ox = sprite.bitmap.width / 2
    sprite.oy = sprite.bitmap.height / 2

    sprite.x += sprite.ox
    sprite.y += sprite.oy

    @sprites["shadow"] = sprite
  end

  #=============================================================================
  # Paper
  #=============================================================================

  def create_paper
    sprite = Sprite.new(@viewport)
    sprite.bitmap = Bitmap.new(PAPER_W, PAPER_H)

    @owned_bitmaps.push(sprite.bitmap)

    bmp = sprite.bitmap

    bmp.fill_rect(
      0,
      0,
      PAPER_W,
      PAPER_H,
      PAPER_EDGE
    )

    bmp.fill_rect(
      2,
      2,
      PAPER_W - 4,
      PAPER_H - 4,
      PAPER
    )

    bmp.fill_rect(
      6,
      6,
      PAPER_W - 12,
      PAPER_H - 12,
      PAPER_LIGHT
    )

    border = Color.new(105, 81, 56, 55)

    draw_box(bmp, HEADER_BOX, border)
    draw_box(bmp, PROFILE_BOX, border)
    draw_box(bmp, MARKS_BOX, border)
    draw_box(bmp, STATS_BOX, border)

    sprite.x = PAPER_X
    sprite.y = PAPER_Y

    sprite.ox = PAPER_W / 2
    sprite.oy = PAPER_H / 2

    sprite.x += sprite.ox
    sprite.y += sprite.oy

    @sprites["paper"] = sprite
  end

  #=============================================================================
  # Text
  #=============================================================================

  def create_text_layer
    sprite = Sprite.new(@viewport)
    sprite.bitmap = Bitmap.new(PAPER_W, PAPER_H)

    @owned_bitmaps.push(sprite.bitmap)

    sprite.x = PAPER_X
    sprite.y = PAPER_Y

    @sprites["text"] = sprite

    refresh_text
  end

  def refresh_text
    bmp = @sprites["text"].bitmap
    bmp.clear

    # Header
    system_text(
      bmp,
      "KENSHI RECORD",
      HEADER_BOX.x + 12,
      HEADER_BOX.y + 7,
      0,
      INK
    )

    # Profile
    profile_text_x = PROFILE_BOX.x + 114

    small_text(
      bmp,
      "KENSHI",
      profile_text_x,
      PROFILE_BOX.y + 9,
      0,
      INK_FAINT
    )

    system_text(
      bmp,
      BushidoKenshiRecord.player_name,
      profile_text_x,
      PROFILE_BOX.y + 26,
      0,
      INK
    )

    small_text(
      bmp,
      "PROVINCE",
      profile_text_x,
      PROFILE_BOX.y + 60,
      0,
      INK_FAINT
    )

    system_text(
      bmp,
      BushidoKenshiRecord.province,
      profile_text_x,
      PROFILE_BOX.y + 77,
      0,
      INK
    )

    small_text(
      bmp,
      "KENSHI ID",
      profile_text_x,
      PROFILE_BOX.y + 111,
      0,
      INK_FAINT
    )

    system_text(
      bmp,
      BushidoKenshiRecord.player_id,
      profile_text_x,
      PROFILE_BOX.y + 128,
      0,
      INK
    )

    marks_title =
      BushidoKenshiRecord.game_completed? ?
      "JOURNEY MARKS" :
      "DOJO MARKS"

    system_text(
      bmp,
      marks_title,
      MARKS_BOX.x + 12,
      MARKS_BOX.y + 8,
      0,
      INK
    )

    draw_visible_stats(bmp)
  end

  #=============================================================================
  # Stats
  #=============================================================================

  def draw_visible_stats(bitmap)
    stats = BushidoKenshiRecord.visible_stats

    return if stats.length <= 0

    inner_x     = STATS_BOX.x + 8
    inner_width = STATS_BOX.width - 16

    cell_width = inner_width / stats.length

    for i in 0...stats.length
      label = stats[i][0]
      value = stats[i][1]

      cell_x =
        inner_x +
        cell_width * i

      center =
        cell_x +
        cell_width / 2

      small_text(
        bitmap,
        label,
        center,
        STATS_BOX.y + 9,
        1,
        INK_FAINT
      )

      system_text(
        bitmap,
        value,
        center,
        STATS_BOX.y + 31,
        1,
        INK
      )
    end
  end

  #=============================================================================
  # Portrait
  #=============================================================================

  def create_portrait
    sprite = IconSprite.new(
      PAPER_X + PROFILE_BOX.x + 53,
      PAPER_Y + PROFILE_BOX.y + 84,
      @viewport
    )

    begin
      path = pbTrainerSpriteFile(
        $Trainer.trainertype
      )

      if path
        sprite.setBitmap(path)

        if sprite.bitmap
          sprite.ox =
            sprite.bitmap.width / 2

          sprite.oy =
            sprite.bitmap.height / 2
        end
      end
    rescue
    end

    sprite.opacity = 0

    @sprites["portrait"] = sprite
  end

  #=============================================================================
  # Marks
  #=============================================================================

  def create_stamps
    for i in 0...@visible_marks.length
      sprite = Sprite.new(@viewport)

      sprite.bitmap = Bitmap.new(
        STAMP_SIZE,
        STAMP_SIZE
      )

      @owned_bitmaps.push(sprite.bitmap)

      draw_stamp(
        sprite.bitmap,
        i
      )

      sprite.ox = STAMP_SIZE / 2
      sprite.oy = STAMP_SIZE / 2

      sprite.x = stamp_center_x(i)
      sprite.y = stamp_center_y(i)

      sprite.opacity = 0

      @sprites["stamp#{i}"] = sprite
    end
  end

  def stamp_center_x(index)
    center_x =
      PAPER_X +
      MARKS_BOX.x +
      MARKS_BOX.width / 2

    count = @visible_marks.length

    # 3 marks
    #
    #       1
    #    2     3
    if count == 3
      case index
      when 0
        return center_x
      when 1
        return center_x - 34
      when 2
        return center_x + 34
      end
    end

    # 4 marks
    #
    #    1   2
    #    3   4
    col = index % 2

    return center_x + (col == 0 ? -32 : 32)
  end

  def stamp_center_y(index)
    top_y =
      PAPER_Y +
      MARKS_BOX.y

    count = @visible_marks.length

    if count == 3
      case index
      when 0
        return top_y + 78
      when 1, 2
        return top_y + 128
      end
    end

    row = index / 2

    return top_y + (row == 0 ? 78 : 132)
  end

  def draw_stamp(bitmap, index)
    bitmap.clear

    mark =
      @visible_marks[index]

    owned =
      BushidoKenshiRecord.mark_owned?(index)

    center = STAMP_SIZE / 2

    if owned
      color = mark[:color]

      stamp_circle(
        bitmap,
        center,
        center,
        18,
        Color.new(
          color.red,
          color.green,
          color.blue,
          220
        ),
        2
      )

      stamp_circle(
        bitmap,
        center,
        center,
        14,
        Color.new(
          color.red,
          color.green,
          color.blue,
          125
        ),
        1
      )

      if mark[:type] == :completion
        stamp_circle(
          bitmap,
          center,
          center,
          10,
          Color.new(
            color.red,
            color.green,
            color.blue,
            90
          ),
          1
        )
      end

      pbSetSystemFont(bitmap)

      pbDrawTextPositions(
        bitmap,
        [
          [
            mark[:mark],
            center,
            center - 12,
            1,
            color,
            Color.new(
              color.red,
              color.green,
              color.blue,
              45
            )
          ]
        ]
      )
    else
      ghost = Color.new(
        INK_FAINT.red,
        INK_FAINT.green,
        INK_FAINT.blue,
        60
      )

      stamp_circle(
        bitmap,
        center,
        center,
        18,
        ghost,
        1
      )

      pbSetSystemFont(bitmap)

      pbDrawTextPositions(
        bitmap,
        [
          [
            "?",
            center,
            center - 12,
            1,
            ghost,
            Color.new(0, 0, 0, 0)
          ]
        ]
      )
    end
  end

  #=============================================================================
  # Cursor
  #=============================================================================

  def create_cursor
    sprite = Sprite.new(@viewport)
    sprite.bitmap = Bitmap.new(54, 54)

    @owned_bitmaps.push(sprite.bitmap)

    color = Color.new(
      SELECT.red,
      SELECT.green,
      SELECT.blue,
      180
    )

    bmp = sprite.bitmap

    bmp.fill_rect(3, 3, 10, 2, color)
    bmp.fill_rect(3, 3, 2, 10, color)

    bmp.fill_rect(41, 3, 10, 2, color)
    bmp.fill_rect(49, 3, 2, 10, color)

    bmp.fill_rect(3, 49, 10, 2, color)
    bmp.fill_rect(3, 41, 2, 10, color)

    bmp.fill_rect(41, 49, 10, 2, color)
    bmp.fill_rect(49, 41, 2, 10, color)

    sprite.ox = 27
    sprite.oy = 27

    sprite.opacity = 0

    @sprites["cursor"] = sprite

    update_cursor_position
  end

  def update_cursor_position
    @sprites["cursor"].x =
      stamp_center_x(@selected)

    @sprites["cursor"].y =
      stamp_center_y(@selected)
  end

  #=============================================================================
  # Detail popup
  #=============================================================================

  def create_detail_sprites
    dim = Sprite.new(@viewport)

    dim.bitmap = Bitmap.new(
      Graphics.width,
      Graphics.height
    )

    @owned_bitmaps.push(dim.bitmap)

    dim.bitmap.fill_rect(
      0,
      0,
      Graphics.width,
      Graphics.height,
      Color.new(0, 0, 0, 145)
    )

    dim.opacity = 0
    dim.visible = false

    @sprites["detaildim"] = dim

    detail = Sprite.new(@viewport)
    detail.bitmap = Bitmap.new(320, 190)

    @owned_bitmaps.push(detail.bitmap)

    detail.ox = 160
    detail.oy = 95

    detail.x = Graphics.width / 2
    detail.y = Graphics.height / 2

    detail.opacity = 0
    detail.visible = false

    @sprites["detail"] = detail
  end

  def refresh_detail
    bmp = @sprites["detail"].bitmap
    bmp.clear

    mark =
      @visible_marks[@selected]

    owned =
      BushidoKenshiRecord.mark_owned?(
        @selected
      )

    bmp.fill_rect(
      0,
      0,
      320,
      190,
      PAPER_EDGE
    )

    bmp.fill_rect(
      2,
      2,
      316,
      186,
      PAPER
    )

    bmp.fill_rect(
      6,
      6,
      308,
      178,
      PAPER_LIGHT
    )

    seal = Bitmap.new(64, 64)

    if owned
      color = mark[:color]

      stamp_circle(
        seal,
        32,
        32,
        27,
        Color.new(
          color.red,
          color.green,
          color.blue,
          220
        ),
        2
      )

      if mark[:type] == :completion
        stamp_circle(
          seal,
          32,
          32,
          21,
          Color.new(
            color.red,
            color.green,
            color.blue,
            100
          ),
          1
        )
      end

      pbSetSystemFont(seal)

      pbDrawTextPositions(
        seal,
        [
          [
            mark[:mark],
            32,
            19,
            1,
            color,
            Color.new(
              color.red,
              color.green,
              color.blue,
              45
            )
          ]
        ]
      )
    else
      ghost = Color.new(
        INK_FAINT.red,
        INK_FAINT.green,
        INK_FAINT.blue,
        60
      )

      stamp_circle(
        seal,
        32,
        32,
        27,
        ghost,
        1
      )

      pbSetSystemFont(seal)

      pbDrawTextPositions(
        seal,
        [
          [
            "?",
            32,
            19,
            1,
            ghost,
            Color.new(0, 0, 0, 0)
          ]
        ]
      )
    end

    bmp.blt(
      18,
      28,
      seal,
      Rect.new(
        0,
        0,
        64,
        64
      )
    )

    seal.dispose

    text_x     = 98
    text_width = 204

    system_text(
      bmp,
      mark[:name],
      text_x,
      17,
      0,
      INK
    )

    wrapped_small_text(
      bmp,
      mark[:subtitle],
      text_x,
      45,
      text_width,
      20,
      INK_SOFT
    )

    if mark[:type] == :completion
      wrapped_small_text(
        bmp,
        "This seal records the completion of your journey.",
        text_x,
        84,
        text_width,
        20,
        INK_FAINT
      )

      return
    end

    if owned
      small_text(
        bmp,
        "LEADER",
        text_x,
        77,
        0,
        INK_FAINT
      )

      wrapped_system_text(
        bmp,
        mark[:leader],
        text_x,
        94,
        text_width,
        24,
        INK
      )

      small_text(
        bmp,
        "LOCATION",
        text_x,
        126,
        0,
        INK_FAINT
      )

      wrapped_system_text(
        bmp,
        mark[:location],
        text_x,
        143,
        text_width,
        24,
        INK
      )
    else
      wrapped_small_text(
        bmp,
        "No victory has been recorded for this dojo.",
        text_x,
        84,
        text_width,
        20,
        INK_FAINT
      )
    end
  end

  #=============================================================================
  # Intro
  #=============================================================================

  def prepare_intro
    @sprites["paper"].zoom_x  = 0.03
    @sprites["shadow"].zoom_x = 0.03

    @sprites["paper"].zoom_y  = 0.98
    @sprites["shadow"].zoom_y = 0.98

    @sprites["shadow"].opacity   = 0
    @sprites["text"].opacity     = 0
    @sprites["portrait"].opacity = 0
    @sprites["cursor"].opacity   = 0

    for i in 0...@visible_marks.length
      sprite = @sprites["stamp#{i}"]

      sprite.opacity = 0
      sprite.zoom_x  = 1.28
      sprite.zoom_y  = 1.28
    end
  end

  def play_intro
    pbSEPlay("GUI menu open") rescue nil

    14.times do |i|
      t = (i + 1) / 14.0
      eased = ease_out_cubic(t)

      zoom =
        0.03 +
        0.97 * eased

      @sprites["paper"].zoom_x  = zoom
      @sprites["shadow"].zoom_x = zoom

      @sprites["shadow"].opacity =
        (145 * eased).to_i

      Graphics.update
    end

    @sprites["paper"].zoom_x  = 1.0
    @sprites["shadow"].zoom_x = 1.0

    9.times do |i|
      opacity =
        ((i + 1) * 255 / 9)

      @sprites["text"].opacity =
        opacity

      @sprites["portrait"].opacity =
        opacity

      Graphics.update
    end

    for i in 0...@visible_marks.length
      animate_stamp_in(i)
    end

    6.times do |i|
      @sprites["cursor"].opacity =
        ((i + 1) * 255 / 6)

      Graphics.update
    end
  end

  def animate_stamp_in(index)
    sprite =
      @sprites["stamp#{index}"]

    4.times do |i|
      t = (i + 1) / 4.0

      sprite.opacity =
        (255 * t).to_i

      zoom =
        1.28 -
        0.28 *
        ease_out_cubic(t)

      sprite.zoom_x = zoom
      sprite.zoom_y = zoom

      Graphics.update
    end

    if BushidoKenshiRecord.mark_owned?(index)
      sprite.zoom_x = 0.94
      sprite.zoom_y = 0.94

      pbSEPlay("GUI sel cursor") rescue nil

      Graphics.update

      2.times do |i|
        t = (i + 1) / 2.0

        sprite.zoom_x =
          0.94 +
          0.06 * t

        sprite.zoom_y =
          0.94 +
          0.06 * t

        Graphics.update
      end
    end

    sprite.opacity = 255
    sprite.zoom_x  = 1.0
    sprite.zoom_y  = 1.0
  end

  #=============================================================================
  # Main loop
  #=============================================================================

  def pbScene
    loop do
      Graphics.update
      Input.update

      update

      if @detailsOpen
        update_detail_input
      else
        break if update_main_input
      end
    end

    # Prevent the same X/B press from closing the parent pause menu.
    release_menu_input
  end

  def release_menu_input
    loop do
      Graphics.update
      Input.update

      break if !Input.press?(Input::B) &&
               !Input.press?(Input::C)
    end

    Graphics.update
    Input.update
  end

  def update
    @frame += 1

    update_cursor
    update_stamp_motion
  end

  def update_cursor
    return if @detailsOpen

    pulse = (
      Math.sin(@frame / 7.0) +
      1.0
    ) / 2.0

    @sprites["cursor"].opacity = (
      145 +
      pulse * 95
    ).to_i

    zoom =
      0.98 +
      pulse * 0.045

    @sprites["cursor"].zoom_x =
      zoom

    @sprites["cursor"].zoom_y =
      zoom
  end

  def update_stamp_motion
    for i in 0...@visible_marks.length
      sprite =
        @sprites["stamp#{i}"]

      target = 1.0

      if !@detailsOpen &&
         i == @selected
        target = 1.07
      end

      sprite.zoom_x += (
        target -
        sprite.zoom_x
      ) * 0.22

      sprite.zoom_y += (
        target -
        sprite.zoom_y
      ) * 0.22
    end
  end

  #=============================================================================
  # Navigation
  #=============================================================================

  def update_main_input
    old = @selected
    count = @visible_marks.length

    if count == 3
      if Input.trigger?(Input::LEFT)
        @selected -= 1
        @selected = count - 1 if @selected < 0

      elsif Input.trigger?(Input::RIGHT)
        @selected += 1
        @selected = 0 if @selected >= count

      elsif Input.trigger?(Input::UP)
        if @selected == 0
          @selected = 2
        else
          @selected = 0
        end

      elsif Input.trigger?(Input::DOWN)
        if @selected == 0
          @selected = 1
        else
          @selected = 0
        end

      elsif Input.trigger?(Input::C)
        open_details

      elsif Input.trigger?(Input::B)
        play_outro
        return true
      end
    else
      row = @selected / 2
      col = @selected % 2

      if Input.trigger?(Input::LEFT)
        col = (col + 1) % 2
        @selected = row * 2 + col

      elsif Input.trigger?(Input::RIGHT)
        col = (col + 1) % 2
        @selected = row * 2 + col

      elsif Input.trigger?(Input::UP)
        row = (row + 1) % 2
        @selected = row * 2 + col

      elsif Input.trigger?(Input::DOWN)
        row = (row + 1) % 2
        @selected = row * 2 + col

      elsif Input.trigger?(Input::C)
        open_details

      elsif Input.trigger?(Input::B)
        play_outro
        return true
      end
    end

    if old != @selected
      update_cursor_position
      animate_selection(
        old,
        @selected
      )

      pbSEPlay("GUI sel cursor") rescue nil
    end

    return false
  end

  def animate_selection(old_index, new_index)
    old_sprite =
      @sprites["stamp#{old_index}"]

    new_sprite =
      @sprites["stamp#{new_index}"]

    3.times do |i|
      t = (i + 1) / 3.0

      old_zoom =
        1.07 -
        0.07 * t

      new_zoom =
        1.00 +
        0.07 * t

      old_sprite.zoom_x =
        old_zoom

      old_sprite.zoom_y =
        old_zoom

      new_sprite.zoom_x =
        new_zoom

      new_sprite.zoom_y =
        new_zoom

      Graphics.update
    end
  end

  #=============================================================================
  # Detail interaction
  #=============================================================================

  def open_details
    @detailsOpen = true

    refresh_detail

    dim =
      @sprites["detaildim"]

    detail =
      @sprites["detail"]

    dim.visible    = true
    detail.visible = true

    detail.zoom_x = 0.86
    detail.zoom_y = 0.86

    detail.opacity = 0
    dim.opacity    = 0

    pbSEPlay("GUI menu open") rescue nil

    7.times do |i|
      t = (i + 1) / 7.0

      detail.opacity =
        (255 * t).to_i

      dim.opacity =
        (145 * t).to_i

      zoom =
        0.86 +
        0.14 *
        ease_out_back(t)

      detail.zoom_x = zoom
      detail.zoom_y = zoom

      Graphics.update
    end

    detail.zoom_x = 1.0
    detail.zoom_y = 1.0
  end

  def update_detail_input
    if Input.trigger?(Input::B) ||
       Input.trigger?(Input::C)

      close_details
      return
    end

    old = @selected
    count = @visible_marks.length

    if count == 3
      if Input.trigger?(Input::LEFT)
        @selected -= 1
        @selected = count - 1 if @selected < 0

      elsif Input.trigger?(Input::RIGHT)
        @selected += 1
        @selected = 0 if @selected >= count

      elsif Input.trigger?(Input::UP)
        if @selected == 0
          @selected = 2
        else
          @selected = 0
        end

      elsif Input.trigger?(Input::DOWN)
        if @selected == 0
          @selected = 1
        else
          @selected = 0
        end
      end
    else
      row = @selected / 2
      col = @selected % 2

      if Input.trigger?(Input::LEFT)
        col = (col + 1) % 2
        @selected = row * 2 + col

      elsif Input.trigger?(Input::RIGHT)
        col = (col + 1) % 2
        @selected = row * 2 + col

      elsif Input.trigger?(Input::UP)
        row = (row + 1) % 2
        @selected = row * 2 + col

      elsif Input.trigger?(Input::DOWN)
        row = (row + 1) % 2
        @selected = row * 2 + col
      end
    end

    if old != @selected
      update_cursor_position
      refresh_detail

      pbSEPlay("GUI sel cursor") rescue nil
    end
  end

  def close_details
    dim =
      @sprites["detaildim"]

    detail =
      @sprites["detail"]

    pbSEPlay("GUI menu close") rescue nil

    5.times do |i|
      t = (i + 1) / 5.0

      detail.opacity = (
        255 *
        (1.0 - t)
      ).to_i

      dim.opacity = (
        145 *
        (1.0 - t)
      ).to_i

      detail.zoom_x =
        1.0 -
        0.08 * t

      detail.zoom_y =
        1.0 -
        0.08 * t

      Graphics.update
    end

    dim.visible    = false
    detail.visible = false

    @detailsOpen = false
  end

  #=============================================================================
  # Outro
  #=============================================================================

  def play_outro
    pbSEPlay("GUI menu close") rescue nil

    10.times do |i|
      t =
        (i + 1) /
        10.0

      eased =
        ease_in_cubic(t)

      zoom =
        1.0 -
        0.97 * eased

      @sprites["paper"].zoom_x =
        zoom

      @sprites["shadow"].zoom_x =
        zoom

      opacity = (
        255 *
        (1.0 - t)
      ).to_i

      @sprites["text"].opacity =
        opacity

      @sprites["portrait"].opacity =
        opacity

      @sprites["cursor"].opacity =
        opacity

      for j in 0...@visible_marks.length
        @sprites["stamp#{j}"].opacity =
          opacity
      end

      Graphics.update
    end
  end

  #=============================================================================
  # Layout helpers
  #=============================================================================

  def draw_box(bitmap, rect, color)
    bitmap.fill_rect(
      rect.x,
      rect.y,
      rect.width,
      1,
      color
    )

    bitmap.fill_rect(
      rect.x,
      rect.y + rect.height - 1,
      rect.width,
      1,
      color
    )

    bitmap.fill_rect(
      rect.x,
      rect.y,
      1,
      rect.height,
      color
    )

    bitmap.fill_rect(
      rect.x + rect.width - 1,
      rect.y,
      1,
      rect.height,
      color
    )
  end

  #=============================================================================
  # Font helpers
  #=============================================================================

  def system_text(
    bitmap,
    text,
    x,
    y,
    align = 0,
    base = INK
  )
    pbSetSystemFont(bitmap)

    pbDrawTextPositions(
      bitmap,
      [
        [
          text.to_s,
          x,
          y,
          align,
          base,
          TEXT_SHADOW
        ]
      ]
    )
  end

  def small_text(
    bitmap,
    text,
    x,
    y,
    align = 0,
    base = INK_SOFT
  )
    pbSetSmallFont(bitmap)

    pbDrawTextPositions(
      bitmap,
      [
        [
          text.to_s,
          x,
          y,
          align,
          base,
          TEXT_SHADOW
        ]
      ]
    )
  end

  def wrapped_small_text(
    bitmap,
    text,
    x,
    y,
    width,
    line_height = 20,
    base = INK_SOFT
  )
    pbSetSmallFont(bitmap)

    lines =
      wrapped_lines(
        bitmap,
        text.to_s,
        width
      )

    for i in 0...lines.length
      pbDrawTextPositions(
        bitmap,
        [
          [
            lines[i],
            x,
            y + i * line_height,
            0,
            base,
            TEXT_SHADOW
          ]
        ]
      )
    end
  end

  def wrapped_system_text(
    bitmap,
    text,
    x,
    y,
    width,
    line_height = 24,
    base = INK
  )
    pbSetSystemFont(bitmap)

    lines =
      wrapped_lines(
        bitmap,
        text.to_s,
        width
      )

    for i in 0...lines.length
      pbDrawTextPositions(
        bitmap,
        [
          [
            lines[i],
            x,
            y + i * line_height,
            0,
            base,
            TEXT_SHADOW
          ]
        ]
      )
    end
  end

  def wrapped_lines(bitmap, text, width)
    words = text.split(/\s+/)

    return [""] if words.length <= 0

    lines   = []
    current = ""

    for word in words
      test =
        current == "" ?
        word :
        current + " " + word

      measured =
        bitmap.text_size(test).width

      if measured <= width
        current = test
      else
        lines.push(current) if current != ""
        current = word
      end
    end

    lines.push(current) if current != ""

    return lines
  end

  #=============================================================================
  # Circle helper
  #=============================================================================

  def stamp_circle(
    bitmap,
    cx,
    cy,
    radius,
    color,
    thickness = 1
  )
    for layer in 0...thickness
      r = radius - layer

      x = r
      y = 0
      error = 0

      while x >= y
        stamp_circle_points(
          bitmap,
          cx,
          cy,
          x,
          y,
          color
        )

        y += 1

        if error <= 0
          error +=
            2 * y + 1
        end

        if error > 0
          x -= 1

          error -=
            2 * x + 1
        end
      end
    end
  end

  def stamp_circle_points(
    bitmap,
    cx,
    cy,
    x,
    y,
    color
  )
    points = [
      [cx + x, cy + y],
      [cx + y, cy + x],
      [cx - y, cy + x],
      [cx - x, cy + y],
      [cx - x, cy - y],
      [cx - y, cy - x],
      [cx + y, cy - x],
      [cx + x, cy - y]
    ]

    for point in points
      px = point[0]
      py = point[1]

      next if px < 0
      next if py < 0
      next if px >= bitmap.width
      next if py >= bitmap.height

      bitmap.set_pixel(
        px,
        py,
        color
      )
    end
  end

  #=============================================================================
  # Easing
  #=============================================================================

  def ease_out_cubic(t)
    value =
      t - 1.0

    return (
      value *
      value *
      value +
      1.0
    )
  end

  def ease_in_cubic(t)
    return t * t * t
  end

  def ease_out_back(t)
    s = 1.70158
    value = t - 1.0

    return (
      value *
      value *
      (
        (s + 1.0) *
        value +
        s
      ) +
      1.0
    )
  end

  #=============================================================================
  # Cleanup
  #=============================================================================

  def pbEndScene
    pbDisposeSpriteHash(@sprites)

    for bitmap in @owned_bitmaps
      next if !bitmap
      next if bitmap.disposed?

      bitmap.dispose
    end

    @owned_bitmaps.clear

    @viewport.dispose
  end
end


#===============================================================================
# Screen wrapper
#===============================================================================

class BushidoKenshiRecordScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
    @scene.pbScene
    @scene.pbEndScene
  end
end


#===============================================================================
# Public call
#===============================================================================

def pbKenshiRecord
  scene =
    BushidoKenshiRecord_Scene.new

  screen =
    BushidoKenshiRecordScreen.new(
      scene
    )

  screen.pbStartScreen
end