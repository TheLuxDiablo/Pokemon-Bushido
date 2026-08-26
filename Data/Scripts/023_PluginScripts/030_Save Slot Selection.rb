class SaveSlot_Selection_Scene
  class Save_Slot

    attr_reader :slot
    attr_reader :file_name
    attr_reader :trainer
    attr_reader :map_id
    attr_reader :frame_count

    attr_accessor :name

    def initialize(file_name, new_game = false)
      @file_name = file_name
      @state     = :Invalid
      if new_game
        @state = :NewGame
        @name  = _INTL("New Game")
      elsif !load_file
        @name = _INTL("Empty Slot")
      else
        @state = :Valid
        file  = @file_name[/Game_(\d+).rxdata/i]
        @slot  = $1.to_i
        @name = _INTL("Slot {1}", @slot)
      end
    end

    def load_file
      @state = :Empty
      return false if @new_game
      return false if !safeExists?(@file_name)
      @state      = :Invalid
      trainer     = nil
      frame_count = nil
      map_id      = nil
      File.open(@file_name) { |f|
        trainer     = Marshal.load(f)
        map_id      = Marshal.load(f)
        frame_count = Marshal.load(f)
      }
      valid  = true
      valid  = false if !trainer.is_a?(PokeBattle_Trainer)
      valid  = false if !map_id.is_a?(Numeric)
      valid  = false if !frame_count.is_a?(Numeric)
      valid  = false if trainer.seen.length < PBSpecies.maxValue
      return false if !valid
      @state       = :Valid
      @trainer     = trainer
      @frame_count = frame_count
      @map_id      = map_id
      return true
    end

    def new_game?; return @state == :NewGame; end
    def empty?;    return @state == :Empty;   end
    def invalid?;  return @state == :Invalid; end
    def valid?;    return @state == :Valid;   end
  end

  attr_reader :slots

  def initialize(show_new_game = false, fade_anim = false)
    @show_new_game             = show_new_game
    @fade_anim                 = fade_anim
    @viewport                  = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z                = 99999
    @sprites                   = {}
    @sprites["bg"]             = Sprite.new(@viewport)
    @sprites["bg"].bitmap      = pbBitmap("Graphics/Pictures/LoadScreen/load_bg")

    @sprites["slots"]          = BushidoSaveCarousel.new([], @viewport, @show_new_game)
    @sprites["slots"].x        = 0
    @sprites["slots"].y        = 0

    @sprites["load_panel"]     = PokemonSaveSlotPanel.new(@viewport)
    @sprites["load_panel"].visible = false
    @sprites["load_panel"].x   = (Graphics.width - @sprites["load_panel"].bg_bmp.width) / 2
    @sprites["load_panel"].y   = ((Graphics.height - @sprites["load_panel"].bg_bmp.height) / 2) - 48
    space = "        "
    @sprites["messagebox"]     = Window_AdvancedTextPokemon.new(_INTL("C: Select") + space + _INTL("B: Back") + space + _INTL("A: Delete"))
    @sprites["messagebox"].y   = Graphics.height - @sprites["messagebox"].height
    @sprites["messagebox"].x   = (Graphics.width - @sprites["messagebox"].width) / 2
    @sprites["messagebox"].viewport       = @viewport
    @sprites["messagebox"].visible        = false
    @sprites["messagebox"].letterbyletter = false
    @sprites["messagebox"].setSkin(MessageConfig.pbGetSystemFrame)
    @sprites.each_value { |s| s.visible = false }
    pbDeactivateWindows(@sprites)
    refresh_save_slots($PokemonSystem.save_slot - 1)
  end

  def refresh_save_slots(index = 0)
    @slots    = []
    saves     = []
    max_count = 0
    Dir.foreach(RTP.getSaveFolder) do |f|
      next if f == "." || f == ".."
      next if File.directory?(RTP.getSaveFileName("#{f}"))
      next if !f[/Game_(\d+).rxdata/i]
      num = $1.to_i
      next if num < 1
      max_count = num if max_count < num
    end
    max_count.times do |i|
      file_name = RTP.getSaveFileName("Game_#{i + 1}.rxdata")
      saves << file_name
      saves << file_name + ".bak" if File.file?(file_name + ".bak")
    end
    saves.each_with_index do |f, i|
      slot = Save_Slot.new(f)
      next if slot.invalid?
      if f.end_with?("bak")
        new_name  = f.gsub(".bak", "")
        next if File.file?(new_name)
        temp_slot = Save_Slot.new(new_name)
        next if temp_slot.invalid?
        File.move(f, new_name)
        @slots.push(temp_slot)
      else
        @slots.push(slot)
      end
    end
    @slots.push(Save_Slot.new(nil, true)) if @show_new_game
    @sprites["slots"].commands = @slots
    index                      = 0 if index < 0
    @sprites["slots"].index    = index
    loop do
      idx = @sprites["slots"].index
      break if idx == 0
      break if @slots[idx] && (!@slots[idx].new_game? || $Trainer)
      @sprites["slots"].index -= 1
    end
  end

  def update
    pbUpdateSpriteHash(@sprites)
  end

  # Reloads the just-written slot from disk and redraws the same card in place.
  # Save slots are 1-based; carousel indexes are 0-based.
  def refresh_after_save(slot)
    slot = slot.to_i
    return if slot <= 0

    carousel = @sprites["slots"]

    if carousel
      # Dispose all dynamically-created card sprites before rebuilding.
      # These are created outside the main @sprites hash and otherwise linger
      # visually after a save refresh.
      begin
        if carousel.instance_variable_defined?(:@party_sprites)
          party_sprites = carousel.instance_variable_get(:@party_sprites)
          if party_sprites
            party_sprites.each_value do |sprite|
              begin
                sprite.dispose if sprite && !sprite.disposed?
              rescue
              end
            end
            party_sprites.clear
          end
        end

        if carousel.instance_variable_defined?(:@player_sprites)
          player_sprites = carousel.instance_variable_get(:@player_sprites)
          if player_sprites
            player_sprites.each_value do |sprite|
              begin
                sprite.dispose if sprite && !sprite.disposed?
              rescue
              end
            end
            player_sprites.clear
          end
        end

        if carousel.instance_variable_defined?(:@card_sprites)
          card_sprites = carousel.instance_variable_get(:@card_sprites)
          if card_sprites
            card_sprites.each_value do |sprite|
              begin
                sprite.dispose if sprite && !sprite.disposed?
              rescue
              end
            end
            card_sprites.clear
          end
        end
      rescue
      end
    end

    # Reload the selected slot from disk so every visible field comes from
    # the newly-written save.
    refresh_save_slots(slot - 1)

    carousel = @sprites["slots"]
    if carousel
      carousel.index = slot - 1

      centered_scroll = (slot - 1) * BushidoSaveCarousel::CARD_SPACING
      carousel.instance_variable_set(:@scroll_x, centered_scroll.to_f)
      carousel.instance_variable_set(:@target_scroll, centered_scroll.to_f)
      carousel.instance_variable_set(:@entry_offset, 0.0)
      carousel.instance_variable_set(:@exit_offset, 0.0)
      carousel.instance_variable_set(:@confirm, 0)

      carousel.refresh
      carousel.send(:refresh_card_sprites)
    end

    update
    Graphics.update
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def fade_sprites(reverse = false)
    return if @faded == reverse

    if reverse
      @sprites["bg"].visible         = true
      @sprites["slots"].visible      = true
      @sprites["load_panel"].visible = false
      @sprites["messagebox"].visible = false
    else
      @sprites.each_value { |s| s.visible = false }
    end

    @faded = reverse
  end

  def single_slot?
    return @slots.length <= 1
  end

  def get_save_slot
    @sprites["slots"].prepare_entry if @sprites["slots"].respond_to?(:prepare_entry)
    fade_sprites(true)
    @sprites["slots"].play_entry if @sprites["slots"].visible && @sprites["slots"].respond_to?(:play_entry)

    index = $PokemonSystem.save_slot
    confirm = nil

    loop do
      index   = get_save_index(index)
      confirm = confirm_slot(index)
      pbUpdateSpriteHash(@sprites)

      if index == 0
        index = 0
        break
      elsif confirm == 2
        index = delete_slot
        single = @show_new_game ? 1 : 0
        if @slots.length <= single
          index = -1
          break
        end
      end

      break if index > 0 && confirm == 0
    end

    # When the current player is saving, leave the selected card exactly where
    # it is. PokemonSaveScreen will write the file and refresh this same card
    # in place before showing the confirmation message.
    hold_for_save = (@show_new_game && $Trainer && index > 0 && confirm == 0)

    if !hold_for_save
      @sprites["slots"].play_exit if @sprites["slots"].visible && @sprites["slots"].respond_to?(:play_exit)
      fade_sprites
    end

    return index
  end

  def get_save_index(index)
    return choose_slot(index) + 1
  end

  def choose_slot(index)
    @sprites["slots"].active = true

    loop do
      Graphics.update
      Input.update
      update

      if Input.trigger?(Input::LEFT)
        @sprites["slots"].move_left
      elsif Input.trigger?(Input::RIGHT)
        @sprites["slots"].move_right
      elsif Input.trigger?(Input::C)
        index = @sprites["slots"].index
        @sprites["slots"].confirm!
        6.times do
          Graphics.update
          Input.update
          update
        end
        break
      elsif Input.trigger?(Input::B)
        pbPlayDecisionSE
        index = -1
        break
      elsif Input.trigger?(Input::A)
        index = -2
        break
      end
    end

    @sprites["slots"].active = false
    return index
  end

  def confirm_slot(index)
    return 2 if index < 0
    return 1 if index < 1

    slot = @slots[index - 1]

    if (slot.empty? || slot.new_game?) && !$Trainer && !@show_new_game
      pbPlayBuzzerSE
      return 1
    end

    pbPlayDecisionSE

    # A brand-new empty slot can immediately continue into New Game.
    return 0 if (slot.empty? || slot.new_game?) && !$Trainer && @show_new_game

    commands = [_INTL("Yes"), _INTL("No")]
    commands.push(_INTL("Delete")) if slot.valid?

    message = _INTL("\\se[]Would you like to load this file?")

    if @show_new_game
      if $Trainer
        if slot.empty? || slot.new_game?
          message = _INTL("\\se[]Would you like to save to this slot?")
        else
          message = _INTL("\\se[]Would you like to overwrite this slot?")
        end
      else
        message = _INTL("\\se[]Would you like to start a new game in this slot?")
      end
    end

    # Keep the carousel, trainer sprite and party icons visible underneath.
    cmd = pbMessage(message, commands, 2) { update }

    return cmd
  end

  def delete_slot
    index = @sprites["slots"].index
    slot  = @slots[index]
    if !@slots[index] || !@slots[index].valid?
      pbPlayBuzzerSE
      return @sprites["slots"].index + 1
    end
    old_vis = {}
    @sprites.each do |key, s|
      old_vis[key] = s.visible
      s.visible = !$Trainer.nil?
    end
    if !pbConfirmMessageSerious(_INTL("Would you like to delete saved data from Slot {1}?", slot.slot))
      @sprites.each { |key, s| s.visible = old_vis[key] }
      return @sprites["slots"].index + 1
    end
    File.delete(slot.file_name) if slot.valid?
    pbMessage(_INTL("Slot {1} was deleted.", slot.slot))
    refresh_save_slots(index)
    @sprites.each { |key, s| s.visible = old_vis[key] }
    return @sprites["slots"].index + 1
  end
end

class PokeBattle_Trainer
  def set_last_save_time
    @last_save_time = Time.now.strftime("%l:%M %P")
  end

  def last_save_time
    set_last_save_time if !@last_save_time
    return @last_save_time
  end
end

class PokemonSaveSlotPanel < Sprite

  attr_reader   :bg_bmp

  def initialize(viewport)
    super(viewport)
    @bg_bmp       = pbBitmap("Graphics/Pictures/loadPanel2")
    @base_color   = Color.new(88, 88, 88)
    @shadow_color = Color.new(168, 168, 168)
  end

  def data=(value)
    @data        = value
    if @data
      @title       = @data.name
      @trainer     = !@data.valid? ? $Trainer : @data.trainer
      @frame_count = !@data.valid? ? Graphics.frame_count : @data.frame_count
      @frame_count /= Graphics.frame_rate
      @map_id      = !@data.valid? ? $game_map.map_id : @data.map_id
      init_load_panel
      refresh
    end
  end

  def visible=(value)
    super
    @sprites.each_value { |s| s.visible = value } if @sprites
  end

  def color=(value)
    super
    @sprites.each_value { |s| s.color = value } if @sprites
  end

  def update
    super
    return if !@sprites || @sprites.empty?
    pbUpdateSpriteHash(@sprites)
    if @trainer.party
      @trainer.party.each_with_index do |pkmn, i|
        next if !@sprites["pokemon#{i}"]
        @sprites["pokemon#{i}"].x       = self.x + 254 + (66 * (i % 2))
        @sprites["pokemon#{i}"].y       = self.y + 48 + (50 * (i / 2))
        @sprites["pokemon#{i}"].color   = self.color
        @sprites["pokemon#{i}"].tone    = self.tone
        
        begin
          fainted_opacity = (pkmn.hp <= 0) ? 100 : 255
        rescue
          fainted_opacity = 255
        end

        @sprites["pokemon#{i}"].opacity = (self.opacity * fainted_opacity / 255.0).to_i

        @sprites["pokemon#{i}"].visible = self.visible
      end
    end
    @sprites["player"].ox      = @sprites["player"].bitmap.width / 8
    @sprites["player"].oy      = @sprites["player"].bitmap.height / 4
    @sprites["player"].x       = self.x + @sprites["player"].bitmap.height / 8 + 36
    @sprites["player"].y       = self.y + @sprites["player"].bitmap.height / 4 + 48
    @sprites["player"].tone    = self.tone
    @sprites["player"].color   = self.color
    @sprites["player"].opacity = self.opacity
    @sprites["player"].visible = self.visible
  end

    def init_load_panel
      pbDisposeSpriteHash(@sprites)
      @sprites = {}

      if @trainer&.party
        @trainer.party.each_with_index do |pkmn, i|
          next if !pkmn

          @sprites["pokemon#{i}"] = PokemonIconSprite.new(pkmn, viewport)

          begin
            @sprites["pokemon#{i}"].opacity = (pkmn.hp <= 0) ? 100 : 255
          rescue
            @sprites["pokemon#{i}"].opacity = 255
          end
        end
      end

      if @trainer
        meta = pbGetMetadata(0, MetadataPlayerA + @trainer.metaID)
        if meta
          filename = pbGetPlayerCharset(meta, 1, @trainer, true)
          @sprites["player"] = TrainerWalkingCharSprite.new(filename, viewport)
          @sprites["player"].bitmap = Bitmap.new(8, 8) if !@sprites["player"].bitmap
          charwidth  = @sprites["player"].bitmap.width
          charheight = @sprites["player"].bitmap.height
        end
      end
    end

  def dispose
    @bg_bmp.dispose
    pbDisposeSpriteHash(@sprites)
    self.bitmap&.dispose
    super
  end

  def refresh
    return if disposed?
    if !self.bitmap || self.bitmap.disposed?
      self.bitmap = BitmapWrapper.new(@bg_bmp.width, @bg_bmp.height)
      pbSetSystemFont(self.bitmap)
    end
    self.bitmap.clear if self.bitmap
    self.bitmap.blt(0, 0, @bg_bmp, Rect.new(0, 0, @bg_bmp.width, @bg_bmp.height))
    refresh_load
    self.update
  end

  def refresh_load
    textpos = []
    textpos.push([@title, 32, 8, 0, @base_color, @shadow_color])
    textpos.push([_INTL("Chapter:"), 32, 110, 0, @base_color, @shadow_color])
    textpos.push([@trainer.chapter.to_s, 226, 110, 1, @base_color, @shadow_color])
    textpos.push([_INTL("Journal:"), 32, 142, 0, @base_color, @shadow_color])
    dex_num = @trainer.nat_dex_show ? -1 : 2
    dex_str = _INTL("{1} / {2}", @trainer.pokedexOwned(dex_num), pbGetRegionalDexLength(dex_num))
    textpos.push([dex_str, 226, 142, 1, @base_color, @shadow_color])
    textpos.push([_INTL("Time:"), 32, 172, 0, @base_color, @shadow_color])
    hour = @frame_count / 60 / 60
    min  = @frame_count / 60 % 60
    if hour > 0
      textpos.push([_INTL("{1}h {2}m", hour, min), 226, 172, 1, @base_color, @shadow_color])
    else
      textpos.push([_INTL("{1}m", min), 226, 172, 1, @base_color, @shadow_color])
    end
    if @trainer.male?
      textpos.push([@trainer.name, 114, 66, 0, Color.new(56, 160, 248), Color.new(56, 104, 168)])
    elsif @trainer.female?
      textpos.push([@trainer.name, 114, 66, 0, Color.new(240, 72, 88), Color.new(160, 64, 64)])
    else
      textpos.push([@trainer.name, 114, 66, 0, @base_color, @shadow_color])
    end
    mapname = pbGetMapNameFromId(@map_id)
    mapname.gsub!(/\\PN/, @trainer.name)
    textpos.push([mapname, 386, 8, 1, @base_color, @shadow_color])
    pbDrawTextPositions(self.bitmap, textpos)
  end
end

#===============================================================================
# Horizontal save carousel
# Vertical cards, unlimited save count, left/right navigation.
#===============================================================================
class BushidoSaveCarousel < SpriteWrapper
  attr_accessor :active
  attr_reader :index

  CARD_W       = 220
  CARD_H       = 298
  CARD_SPACING = 238
  CENTER_X     = Graphics.width / 2
  CARD_Y       = 48

  INK        = Color.new(68, 48, 37)
  SOFT       = Color.new(111, 84, 64)
  RED        = Color.new(154, 48, 47)
  RED_DARK   = Color.new(102, 33, 34)
  PAPER      = Color.new(238, 219, 185)
  PAPER_SEL  = Color.new(246, 228, 194)
  BORDER     = Color.new(157, 127, 94)
  SHADOW     = Color.new(225, 205, 176)
  SHADOW_SEL = Color.new(218, 194, 163)
  TEXT_SHADOW = Color.new(229, 204, 169)

  def initialize(commands, viewport, new_game_mode = false)
    super(viewport)
    @commands      = commands || []
    @new_game_mode = new_game_mode
    @index         = 0
    @active        = false
    @anim_frame    = 0
    @scroll_x      = 0.0
    @target_scroll = 0.0
    @entry_offset  = 0.0
    @exit_offset   = 0.0
    @confirm       = 0

    self.bitmap = BitmapWrapper.new(Graphics.width, Graphics.height)
    pbSetSystemFont(self.bitmap)

    @card_normal   = pbBitmap("Graphics/Pictures/SaveSlots/save_card")
    @card_selected = pbBitmap("Graphics/Pictures/SaveSlots/save_card_selected")

    @card_sprites = {}
    refresh
    refresh_card_sprites
  end

  def commands
    return @commands
  end

  def commands=(value)
    @commands = value || []
    @index = 0 if @index >= @commands.length
    @target_scroll = @index * CARD_SPACING
    @scroll_x = @target_scroll if @commands.length <= 1
    refresh
    refresh_card_sprites
  end

  def index=(value)
    return if @commands.empty?
    value = [[value || 0, 0].max, @commands.length - 1].min
    @index = value
    @target_scroll = @index * CARD_SPACING
    refresh
    refresh_card_sprites
  end

  def move_left
    return if @index <= 0
    @index -= 1
    @target_scroll = @index * CARD_SPACING
    pbPlayCursorSE rescue nil
  end

  def move_right
    return if @index >= @commands.length - 1
    @index += 1
    @target_scroll = @index * CARD_SPACING
    pbPlayCursorSE rescue nil
  end

  def confirm!
    @confirm = 6
  end

  def prepare_entry
    @entry_offset = 112.0
    @exit_offset = 0.0
    refresh
    refresh_card_sprites
  end

  def play_entry
    # Smooth horizontal ease into place.
    # No vertical offsets or stagger, which were causing the visible jump.
    16.times do
      @entry_offset *= 0.74

      Graphics.update
      Input.update
      refresh
      refresh_card_sprites
      update_card_sprites
    end

    @entry_offset = 0.0
    refresh
    refresh_card_sprites
  end

  def play_exit
    @exit_offset = 0.0

    10.times do |i|
      t = (i + 1) / 10.0
      @exit_offset = 116.0 * (t * t)

      Graphics.update
      Input.update
      refresh
      refresh_card_sprites
      update_card_sprites
    end
  end

  def update
    @anim_frame += 1

    delta = @target_scroll - @scroll_x
    if delta.abs > 0.5
      @scroll_x += delta * 0.22
    else
      @scroll_x = @target_scroll
    end

    @confirm -= 1 if @confirm > 0

    refresh
    refresh_card_sprites
    update_card_sprites
  end

  def refresh
    return if disposed?
    self.bitmap.clear
    pbSetSystemFont(self.bitmap)

    draw_header

    @commands.each_with_index do |slot, i|
      draw_card(slot, i)
    end

    draw_edge_hints
  end

  def draw_header
    title = @new_game_mode ? _INTL("Choose a Save Slot") : _INTL("Load Game")
    pbDrawTextPositions(self.bitmap, [
      [title, Graphics.width / 2, 12, 2, RED, TEXT_SHADOW]
    ])
  end

  def card_position(i)
    x = CENTER_X - (CARD_W / 2)
    x += (i * CARD_SPACING) - @scroll_x
    x += @entry_offset
    x += @exit_offset

    y = CARD_Y

    if i == @index
      y += (Math.sin(@anim_frame / 14.0) * 2).round
      y += 2 if @confirm > 0
    end

    return x.round, y.round
  end

  def draw_card(slot, i)
    x, y = card_position(i)
    return if x < -CARD_W || x > Graphics.width

    selected = (i == @index)

    card = selected ? @card_selected : @card_normal
    self.bitmap.blt(
      x,
      y,
      card,
      Rect.new(0, 0, card.width, card.height)
    )

    draw_card_text(slot, x, y, selected)
  end

  def wrap_lines(text, max_width, max_lines = 3)
    words = text.to_s.split(/\s+/)
    return [""] if words.empty?

    lines = []
    line = ""

    words.each do |word|
      test = line.empty? ? word : "#{line} #{word}"

      if self.bitmap.text_size(test).width <= max_width
        line = test
      else
        lines.push(line) if !line.empty?
        line = word
        break if lines.length >= max_lines - 1
      end
    end

    lines.push(line) if !line.empty? && lines.length < max_lines
    return lines
  end

  def draw_card_text(slot, x, y, selected)
    center = x + CARD_W / 2
    text_color = selected ? RED_DARK : INK

    pbSetSystemFont(self.bitmap)

    if slot.new_game?
      pbDrawTextPositions(self.bitmap, [
        [_INTL("New Game"), center, y + 124, 2, RED, TEXT_SHADOW]
      ])
      return
    end

    if slot.empty?
      pbDrawTextPositions(self.bitmap, [
        [slot.name, center, y + 18, 2, text_color, TEXT_SHADOW],
        [_INTL("Empty"), center, y + 122, 2, SOFT, TEXT_SHADOW]
      ])
      return
    end

    return if !slot.valid?

    trainer = slot.trainer
    mapname = pbGetMapNameFromId(slot.map_id)
    mapname = _INTL("Unknown") if !mapname || mapname.empty?
    mapname.gsub!(/\\PN/, trainer.name) rescue nil

    total = slot.frame_count / Graphics.frame_rate
    hour  = total / 3600
    min   = (total / 60) % 60
    chapter = trainer.chapter rescue 0

    # Player name first.
    pbDrawTextPositions(self.bitmap, [
      [trainer.name, center, y + 14, 2, text_color, TEXT_SHADOW]
    ])

    # Full location name. Wrap naturally instead of truncating.
    pbSetSmallFont(self.bitmap)
    lines = wrap_lines(mapname, CARD_W - 30, 3)
    lines.each_with_index do |line, idx|
      pbDrawTextPositions(self.bitmap, [
        [line, center, y + 48 + (idx * 20), 2, SOFT, TEXT_SHADOW]
      ])
    end

    meta_y = y + 142
    pbDrawTextPositions(self.bitmap, [
      [_INTL("Chapter: {1}", chapter), x + 18, meta_y, 0, RED_DARK, TEXT_SHADOW],
      # Playtime deliberately has no label.
      [_INTL("{1}:{2}", sprintf("%02d", hour), sprintf("%02d", min)),
        x + CARD_W - 18, meta_y, 1, INK, TEXT_SHADOW]
    ])
  end

  def refresh_card_sprites
    wanted = {}

    first = [@index - 1, 0].max
    last  = [@index + 1, @commands.length - 1].min

    (first..last).each do |slot_index|
      slot = @commands[slot_index]
      next if !slot || !slot.valid?

      trainer = slot.trainer
      next if !trainer

      x, y = card_position(slot_index)

      # Player running sprite.
      player_key = "player_#{slot_index}"
      wanted[player_key] = true

      if !@card_sprites[player_key]
        begin
          meta = pbGetMetadata(0, MetadataPlayerA + trainer.metaID)
          if meta
            filename = pbGetPlayerCharset(meta, 1, trainer, true)
            @card_sprites[player_key] = TrainerWalkingCharSprite.new(filename, self.viewport)
            @card_sprites[player_key].z = self.z + 5
          end
        rescue
        end
      end

      player = @card_sprites[player_key]
      if player && player.bitmap
        # Bushido player sheets are 4x4, with each frame treated as a 64x64
        # square. Use the first row and cycle across its four frames.
        frame_w = 64
        frame_h = 64
        frame = (@anim_frame / 14) % 4

        player.src_rect = Rect.new(frame * frame_w, 0, frame_w, frame_h)

        # Center the 64x64 frame horizontally in the card and place it
        # directly beneath the wrapped location block.
        player.x = x + ((CARD_W - frame_w) / 2)
        player.y = y + 76

        player.visible = self.visible && x > -CARD_W && x < Graphics.width
      end

      # Party: all six members, 3x2.
      if trainer.party
        trainer.party.each_with_index do |pkmn, party_index|
          break if party_index >= 6

          key = "party_#{slot_index}_#{party_index}"
          wanted[key] = true

          if !@card_sprites[key]
            @card_sprites[key] = PokemonIconSprite.new(pkmn, self.viewport)
            @card_sprites[key].setOffset(PictureOrigin::Center)
            @card_sprites[key].z = self.z + 5
          end

          icon = @card_sprites[key]
          col = party_index % 3
          row = party_index / 3

          icon.x = x + 52 + (col * 58)
          icon.y = y + 202 + (row * 52)

          begin
            icon.opacity = (pkmn.hp <= 0) ? 100 : 255
          rescue
            icon.opacity = 255
          end

          icon.visible = self.visible && x > -CARD_W && x < Graphics.width
        end
      end
    end

    @card_sprites.keys.each do |key|
      next if wanted[key]
      sprite = @card_sprites[key]
      sprite.dispose if sprite && !sprite.disposed?
      @card_sprites.delete(key)
    end
  end

  def update_card_sprites
    @card_sprites.each do |key, sprite|
      next if key.start_with?("player_")
      sprite.update if sprite.respond_to?(:update)
    end
  end

  def draw_edge_hints
    if @index > 0
      pbDrawTextPositions(self.bitmap, [
        ["<", 16, Graphics.height / 2 - 8, 0, SOFT, TEXT_SHADOW]
      ])
    end

    if @index < @commands.length - 1
      pbDrawTextPositions(self.bitmap, [
        [">", Graphics.width - 16, Graphics.height / 2 - 8, 1, SOFT, TEXT_SHADOW]
      ])
    end
  end

  def visible=(value)
    super
    @card_sprites.each_value do |sprite|
      sprite.visible = value if sprite.respond_to?(:visible=)
    end
  end

  def dispose
    pbDisposeSpriteHash(@card_sprites)
    @card_sprites = {}

    @card_normal.dispose if @card_normal && !@card_normal.disposed?
    @card_selected.dispose if @card_selected && !@card_selected.disposed?

    super
  end
end
#===============================================================================
# Bushido save flow
# Keeps the selected save card visible, reloads the newly written file from
# disk immediately, then shows the save confirmation over the refreshed card.
#===============================================================================
class PokemonSaveScreen
  def initialize(scene)
    @scene = scene
  end

  def pbSaveScreen
    ret = false

    slot_scene = SaveSlot_Selection_Scene.new(true, true)
    slot = slot_scene.get_save_slot

    if slot <= 0
      slot_scene.dispose
      Graphics.update
      return false
    end

    $PokemonSystem.save_slot = slot
    success = pbSave

    if success
      # Reload the actual file that was just written so every piece of visible
      # information comes from disk: party, location, chapter, playtime, etc.
      slot_scene.refresh_after_save(slot)

      # Force the refreshed party/location/card to hit the screen before
      # opening the confirmation message.
      2.times do
        slot_scene.update
        Graphics.update
      end

      pbMessage(_INTL("\\se[]{1} saved the game to Slot {2}.\\me[GUI save game]\\wtnp[30]",
                      $Trainer.name, slot)) {
        slot_scene.update
      }

      ret = true
    else
      pbPlayBuzzerSE rescue nil
      ret = false
    end

    slot_scene.dispose
    Graphics.update
    return ret
  end
end
