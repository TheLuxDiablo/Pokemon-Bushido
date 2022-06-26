class SaveSlot_Selection_Scene
  class Save_Slot

    attr_reader :name
    attr_reader :slot
    attr_reader :file_name
    attr_reader :trainer
    attr_reader :map_id
    attr_reader :frame_count


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
    @sprites["bg"].bitmap      = pbBitmap("Graphics/Pictures/loadbg")
    @sprites["slots"]          = Window_SaveSlots.new([], 408)
    @sprites["slots"].viewport = @viewport
    @sprites["slots"].x        = 52
    @sprites["slots"].height   = Graphics.height - 42
    @sprites["load_panel"]     = PokemonSaveSlotPanel.new(@viewport)
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
    @sprites["slots"].index    = index
    loop do
      idx = @sprites["slots"].index
      break if idx == 0
      break if @slots[idx] && !@slots[idx].new_game?
      @sprites["slots"].index -= 1
    end
  end

  def update
    pbUpdateSpriteHash(@sprites)
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def fade_sprites(reverse = false)
    return if @faded == reverse
    @sprites.each_value { |s| s.visible = true } if reverse
    @sprites["load_panel"].visible = false
    alpha = reverse ? 255 : 0
    blk = Color.new(0, 0, 0, alpha)
    @sprites.each_value { |s| s.color = blk }
    dur = (Graphics.frame_rate / 10) * 4
    dur.times do |i|
      factor = (i + 1).to_f / dur
      factor = (1 - factor) if reverse
      Graphics.update if @fade_anim
      pbUpdateSpriteHash(@sprites)
      alpha = 255 * factor
      blk = Color.new(0, 0, 0, alpha)
      @sprites.each_value { |s| s.color = blk }
    end
    @sprites.each_value { |s| s.visible = false } if !reverse
    @sprites.each_value { |s| s.color = Color.new(0, 0, 0, 0) }
    @faded = reverse
  end

  def single_slot?
    return @slots.length <= 1
  end

  def get_save_slot
    fade_sprites(true)
    index = $PokemonSystem.save_slot
    @sprites["bg"].visible = true
    @sprites["load_panel"].visible = false
    loop do
      index   = get_save_index(index)
      confirm = confirm_slot(index)
      pbUpdateSpriteHash(@sprites)
      if (confirm == 1 && single_slot?) || index == 0
        index = 0
        break
      elsif confirm == 2
        index = delete_slot
        single = @show_new_game ? 1 : 0
        break if @slots.length <= single
      end
      break if index > 0 && confirm == 0
    end
    fade_sprites
    return index
  end

  def get_save_index(index)
    return 1 if single_slot?
    return choose_slot(index) + 1
  end

  def choose_slot(index)
    pbActivateWindow(@sprites, "slots") {
      loop do
        Graphics.update
        Input.update
        idx = @sprites["slots"].index
        update
        if Input.trigger?(Input::C)
          index = @sprites["slots"].index
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
    }
    return index
  end

  def confirm_slot(index)
    return 2 if index < 0
    return 1 if index < 1
    if (@slots[index - 1].empty? || @slots[index - 1].new_game?) && !$Trainer && !@show_new_game
      pbPlayBuzzerSE
      return 1
    end
    pbPlayDecisionSE
    return 0 if (@slots[index - 1].empty? || @slots[index - 1].new_game?) && !$Trainer && @show_new_game
    @sprites.each_value { |s| s.visible = false }
    @sprites["load_panel"].data    = @slots[index - 1]
    @sprites["load_panel"].visible = true
    @sprites["bg"].visible         = true
    commands = [_INTL("Yes"), _INTL("No")]
    commands.push(_INTL("Delete"))
    message = _INTL("\\se[]Would you like to load this file?")
    if @show_new_game
      if $Trainer
        if @slots[index - 1].empty? || @slots[index - 1].new_game?
          message = _INTL("\\se[]Would you like to save to this slot?")
        else
          message = _INTL("\\se[]Would you like to overwrite this slot?")
        end
      else
        message = _INTL("\\se[]Would you like to start a new game in this slot?")
      end
    end
    cmd = pbMessage(message, commands, 2) { update }
    pbMessage(_INTL("\\se[]{1} saved the game to Slot {2}.\\me[GUI save game]\\wtnp[30]", $Trainer.name, index)) { update } if cmd == 0 && @show_new_game && $Trainer
    @sprites.each_value { |s| s.visible = true }
    @sprites["load_panel"].visible = false
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
      @map_id      = !@data.valid? ? $game_map.map_id : @data.map_id
      init_load_panel
      refresh
    end
  end

  def visible=(value)
    super
    pbUpdateSpriteHash(@sprites) if @sprites
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
        @sprites["pokemon#{i}"].opacity = self.opacity
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
    @sprites  = {}
    if @trainer&.party
      @trainer.party.each_with_index do |pkmn, i|
        next if !pkmn
        @sprites["pokemon#{i}"] = PokemonIconSprite.new(@trainer.party[i], viewport)
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
    # textpos.push([@title, 32, 8, 0, @base_color, @shadow_color])
    textpos.push([_INTL("Badges:"), 32, 110, 0, @base_color, @shadow_color])
    textpos.push([@trainer.numbadges.to_s, 206, 110, 1, @base_color, @shadow_color])
    textpos.push([_INTL("Pokédex:"), 32, 142, 0, @base_color, @shadow_color])
    textpos.push([@trainer.pokedexOwned(2).to_s, 206, 142, 1, @base_color, @shadow_color])
    textpos.push([_INTL("Time:"), 32, 172, 0, @base_color, @shadow_color])
    hour = @frame_count / 60 / 60
    min  = @frame_count / 60 % 60
    if hour > 0
      textpos.push([_INTL("{1}h {2}m", hour, min), 206, 172, 1, @base_color, @shadow_color])
    else
      textpos.push([_INTL("{1}m", min), 206, 172, 1, @base_color, @shadow_color])
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

class Window_SaveSlots < Window_CommandPokemonEx
  def initialize(commands, width)
    @stop_refresh = true
    super(commands, width)
    @selarrow = pbBitmap("Graphics/Pictures/loadPanel1")
    self.windowskin = nil
    self.rowHeight  = @selarrow.height / 2 + 4
    self.startX     = 0
    self.startY     = 8
    @stop_refresh   = false
  end

  def refresh
    return if @stop_refresh
    super
  end

  def drawItem(index, _count, rect)
    pbSetSystemFont(self.contents)
    rect   = drawCursor(index, rect)
    slot   = @commands[index]
    offset = 8
    y_pos  = rect.y + (slot.empty? || slot.new_game? ? 28 : 16)
    pbDrawShadowText(self.contents, rect.x + offset, y_pos,
                     rect.width, rect.height, slot.name, self.baseColor, self.shadowColor)
    if !slot.empty? && slot.valid?
      pbSetSmallFont(self.contents)
      tr_name = _INTL("Kenshi: {1}", slot.trainer.name)
      pbDrawShadowText(self.contents, rect.x + offset, y_pos + 32,
                       rect.width, rect.height, tr_name, self.baseColor, self.shadowColor)
      map_name = pbGetMapNameFromId(slot.map_id)
      pbDrawShadowText(self.contents, rect.x - offset - 16, y_pos,
                       rect.width, rect.height, map_name, self.baseColor, self.shadowColor, 2)
      save_time = slot.trainer.last_save_time
      pbDrawShadowText(self.contents, rect.x - offset - 16, y_pos + 32,
                       rect.width, rect.height, save_time, self.baseColor, self.shadowColor, 2)
    end
  end

  def drawCursor(index,rect)
    offset = (self.index == index ? @selarrow.height / 2 : 0)
    rc = Rect.new(0, offset, @selarrow.width, @selarrow.height / 2)
    self.contents.blt((self.width / 2) - (@selarrow.width / 2) - 16, rect.y, @selarrow, rc, 255)
    return Rect.new(rect.x + 16, rect.y, rect.width - 16, rect.height)
  end
end
