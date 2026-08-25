#===============================================================================
# Pokémon Bushido - Load Screen (PNG asset pass)
# Main menu visual pass based on the new Bushido wireframe.
#
# This pass only replaces the MAIN load menu presentation.
# SaveSlot_Selection_Scene is intentionally untouched for now.
#===============================================================================

class BushidoLoadMenuSprite < SpriteWrapper
  RED          = Color.new(154, 48, 47)
  RED_DARK     = Color.new(102, 33, 34)
  INK          = Color.new(68, 48, 37)
  INK_SOFT     = Color.new(111, 84, 64)

  PAPER_TOP    = Color.new(246, 232, 204)
  PAPER_BOTTOM = Color.new(232, 211, 176)
  PAPER_PANEL  = Color.new(241, 224, 193)
  PAPER_BUTTON = Color.new(238, 219, 185)
  PAPER_SELECT = Color.new(246, 228, 194)

  SHADOW       = Color.new(225, 204, 174)

  attr_accessor :index

  def initialize(commands, preview, viewport)
    super(viewport)

    $PokemonTemp = PokemonTemp.new if !$PokemonTemp
    
    @commands = commands
    @preview = preview
    @index = 0
    @anim_frame = 0
    @confirm_anim = 0
    @transition_mode = false

    self.bitmap = BitmapWrapper.new(Graphics.width, Graphics.height)
    pbSetSystemFont(self.bitmap)
    
    refresh
  end

  def commands=(value)
    @commands = value
    refresh
  end

  def preview=(value)
    @preview = value
    refresh
  end

  def index=(value)
    value = 0 if value.nil?
    value = [[value, 0].max, @commands.length - 1].min
    return if @index == value
    @index = value
    refresh
  end

  def confirm!
    @confirm_anim = 6
    refresh
  end

  def update
    @anim_frame += 1

    # Keep the selected button gently floating at all times.
    # Refresh every other frame so the motion stays smooth without needless redraws.
    refresh if @anim_frame % 2 == 0

    if @confirm_anim > 0
      @confirm_anim -= 1
      refresh
    end
  end

  def mix_color(a, b, t)
    Color.new(
      (a.red   + ((b.red   - a.red)   * t)).to_i,
      (a.green + ((b.green - a.green) * t)).to_i,
      (a.blue  + ((b.blue  - a.blue)  * t)).to_i
    )
  end

  def fill_gradient(x, y, w, h, top, bottom)
    h.times do |i|
      t = h <= 1 ? 0.0 : i.to_f / (h - 1)
      self.bitmap.fill_rect(x, y + i, w, 1, mix_color(top, bottom, t))
    end
  end

  def fit_text(text, max_width)
    value = text.to_s
    return value if self.bitmap.text_size(value).width <= max_width
    while value.length > 1
      value = value[0, value.length - 1]
      shortened = value + "..."
      return shortened if self.bitmap.text_size(shortened).width <= max_width
    end
    return "..."
  end

  def draw_background
    bg = pbBitmap("Graphics/Pictures/LoadScreen/load_bg")
    self.bitmap.blt(0, 0, bg, Rect.new(0, 0, bg.width, bg.height))
  end

  def draw_button(x, y, w, h, selected)
    pressed = selected && @confirm_anim > 0

    # Gentle idle float.
    if selected && !pressed
      y += (Math.sin(@anim_frame / 12.0) * 2).round
    elsif pressed
      y += 2
    end

    file = if pressed
             "load_button_pressed"
           elsif selected
             "load_button_selected"
           else
             "load_button"
           end

    button = pbBitmap("Graphics/Pictures/LoadScreen/#{file}")
    self.bitmap.blt(x, y, button, Rect.new(0, 0, button.width, button.height))
  end

  def draw_right_panel
    panel = pbBitmap("Graphics/Pictures/LoadScreen/load_right_panel")
    self.bitmap.blt(220, 0, panel, Rect.new(0, 0, panel.width, panel.height))
  end

  def transition_mode=(value)
    @transition_mode = value
    refresh
  end

  def refresh
    return if disposed?
    self.bitmap.clear
    pbSetSystemFont(self.bitmap)

    draw_background

    if !@transition_mode
      draw_menu
      draw_right_panel
      draw_preview
    end
  end

  def draw_menu
    base_x = 20
    row_w  = 184
    row_h  = 48
    gap    = 10

    total_h = (@commands.length * row_h) + ((@commands.length - 1) * gap)
    base_y = ((Graphics.height - total_h) / 2).to_i

    @commands.each_with_index do |command, i|
      y = base_y + (i * (row_h + gap))
      selected = (i == @index)

      draw_button(base_x, y, row_w, row_h, selected)

      color = selected ? RED_DARK : INK
      shadow = selected ? Color.new(226, 192, 156) : Color.new(232, 211, 178)

      text_y = y + 11
      if selected && @confirm_anim <= 0
        text_y += (Math.sin(@anim_frame / 12.0) * 2).round
      elsif selected && @confirm_anim > 0
        text_y += 2
      end

      pbDrawTextPositions(self.bitmap, [
        [command, base_x + 18, text_y, 0, color, shadow]
      ])
    end
  end

  def draw_preview
    return if !@preview || !@preview[:trainer]

    x = 220
    y = 0
    w = Graphics.width - x - 12

    trainer  = @preview[:trainer]
    mapid    = @preview[:mapid] || 0
    frames   = @preview[:framecount] || 0
    totalsec = frames / Graphics.frame_rate
    hour     = totalsec / 3600
    min      = (totalsec / 60) % 60

    chapter = trainer.chapter rescue 0
    journal = trainer.pokedexOwned(2) rescue 0
    mapname = pbGetMapNameFromId(mapid) rescue _INTL("Unknown")
    mapname = _INTL("Unknown") if !mapname || mapname.empty?
    mapname.gsub!(/\\PN/, trainer.name) rescue nil
    mapname = fit_text(mapname, 174)

    # Keep text treatment simple and readable.
    shadow = Color.new(229, 204, 169)

    pbDrawTextPositions(self.bitmap, [
      [_INTL("Last Played"), x + 18, y + 18, 0, RED, shadow],

      [trainer.name, x + 74, y + 62, 0, INK, shadow],
      [mapname,      x + 74, y + 91, 0, INK_SOFT, shadow],

      [_INTL("Chapter: {1}", chapter), x + 18, y + 136, 0, RED_DARK, shadow],
      [_INTL("Journal: {1}", journal), x + 146, y + 136, 0, INK, shadow],

      [_INTL("Playtime: {1}:{2}", sprintf("%02d", hour), sprintf("%02d", min)),
        x + 18, y + 174, 0, INK, shadow]
    ])
  end

  def draw_footer
  end
end

class PokemonLoad_Scene
  def pbStartScene(commands, showContinue, trainer, framecount, mapid)
    @commands = commands
    @sprites = {}

    if !@viewport
      @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
      @viewport.z = 99998
    end

    @preview = bushido_find_last_save

    @sprites["ui"] = BushidoLoadMenuSprite.new(@commands, @preview, @viewport)

    @sprites["cmdwindow"] = Window_CommandPokemon.new([])
    @sprites["cmdwindow"].viewport = @viewport
    @sprites["cmdwindow"].visible = false

    bushido_create_preview_sprites(@preview)

    pbBGMPlay("CONS-MainMenu", 80, 100)
  end

  def pbStartScene2
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartDeleteScene
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99998
    @sprites["ui"] = BushidoLoadMenuSprite.new([], nil, @viewport)
  end

  def pbUpdate
    oldi = @sprites["ui"].index rescue 0
    pbUpdateSpriteHash(@sprites)
    newi = @sprites["cmdwindow"].index rescue 0

    if oldi != newi
      @sprites["ui"].index = newi
      pbPlayCursorSE rescue nil
    end
  end

  def pbChoose(commands)
    @sprites["cmdwindow"].commands = commands
    @sprites["cmdwindow"].index = 0 if @sprites["cmdwindow"].index.nil?
    @sprites["ui"].index = @sprites["cmdwindow"].index

    loop do
      Graphics.update
      Input.update
      pbUpdate

      if Input.trigger?(Input::C)
        @sprites["ui"].confirm! if @sprites["ui"].respond_to?(:confirm!)
        6.times do
          Graphics.update
          Input.update
          pbUpdate
        end
        pbPlayDecisionSE rescue nil
        return @sprites["cmdwindow"].index
      end
    end
  end

  def pbResetScene(commands)
    Graphics.freeze
    pbDisposeSpriteHash(@sprites)
    @sprites = {}
    pbStartScene(commands, false, nil, 0, 0)
    Graphics.transition(0)
  end

  # Hide the external trainer/party sprites used by Last Played.
  def bushido_hide_preview_sprites
    @sprites.each do |key, sprite|
      next if key == "ui" || key == "cmdwindow"
      sprite.visible = false if sprite.respond_to?(:visible=)
    end
  end

  def bushido_show_preview_sprites
    @sprites.each do |key, sprite|
      next if key == "cmdwindow"
      sprite.visible = true if sprite.respond_to?(:visible=)
    end
  end

  # Shared transition for Load Game and New Game.
  #
  # The main menu splits away:
  # - left/menu portion exits left
  # - right preview panel exits right
  # - parchment background remains
  #
  # The slot browser then enters on the clean background.
  def pbTransitionToSlots(mode = :load)
    snap = Graphics.snap_to_bitmap

    split_x = 220
    left_w  = split_x
    right_w = Graphics.width - split_x

    left_bitmap = Bitmap.new(left_w, Graphics.height)
    left_bitmap.blt(0, 0, snap, Rect.new(0, 0, left_w, Graphics.height))

    right_bitmap = Bitmap.new(right_w, Graphics.height)
    right_bitmap.blt(0, 0, snap, Rect.new(split_x, 0, right_w, Graphics.height))

    snap.dispose

    @transition_left = Sprite.new(@viewport)
    @transition_left.bitmap = left_bitmap
    @transition_left.x = 0
    @transition_left.y = 0
    @transition_left.z = @viewport.z + 40

    @transition_right = Sprite.new(@viewport)
    @transition_right.bitmap = right_bitmap
    @transition_right.x = split_x
    @transition_right.y = 0
    @transition_right.z = @viewport.z + 40

    bushido_hide_preview_sprites
    @sprites["ui"].transition_mode = true

    # Same visual language for both modes. New Game is just slightly softer/slower.
    frames = (mode == :new_game) ? 14 : 12

    frames.times do |i|
      t = (i + 1) / frames.to_f
      ease = 1.0 - ((1.0 - t) * (1.0 - t))

      @transition_left.x = (0 - (left_w + 16) * ease).round
      @transition_right.x = (split_x + ((right_w + 16) * ease)).round

      Graphics.update
      Input.update
      pbUpdate
    end
  end

  def pbTransitionBackFromSlots(mode = :load)
    return if !@transition_left || !@transition_right

    split_x = 220
    left_w  = split_x
    right_w = Graphics.width - split_x
    frames  = (mode == :new_game) ? 12 : 10

    frames.times do |i|
      t = (i + 1) / frames.to_f
      ease = t * t

      @transition_left.x =
        (-(left_w + 16) + ((left_w + 16) * ease)).round

      @transition_right.x =
        ((Graphics.width + 16) - ((right_w + 16) * ease)).round

      Graphics.update
      Input.update
      pbUpdate
    end

    @transition_left.bitmap.dispose if @transition_left.bitmap && !@transition_left.bitmap.disposed?
    @transition_left.dispose
    @transition_left = nil

    @transition_right.bitmap.dispose if @transition_right.bitmap && !@transition_right.bitmap.disposed?
    @transition_right.dispose
    @transition_right = nil

    @sprites["ui"].transition_mode = false
    bushido_show_preview_sprites
  end

  def bushido_dispose_transition_sprites
    if @transition_left
      @transition_left.bitmap.dispose if @transition_left.bitmap && !@transition_left.bitmap.disposed?
      @transition_left.dispose
      @transition_left = nil
    end

    if @transition_right
      @transition_right.bitmap.dispose if @transition_right.bitmap && !@transition_right.bitmap.disposed?
      @transition_right.dispose
      @transition_right = nil
    end
  end

  # Smooth final handoff into gameplay.
  # Fade the load-screen music and image together, then freeze on black so
  # there is no bright/abrupt frame while the game state is being rebuilt.
  def pbFadeOutToGame
    pbBGMStop(1.0)

    black = Sprite.new(@viewport)
    black.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    black.bitmap.fill_rect(0, 0, Graphics.width, Graphics.height, Color.black)
    black.opacity = 0
    black.z = @viewport.z + 9999

    24.times do
      black.opacity += 11
      black.opacity = 255 if black.opacity > 255

      Graphics.update
      Input.update
      pbUpdate
    end

    Graphics.freeze

    black.bitmap.dispose
    black.dispose
  end

  def pbEndScene
    bushido_dispose_transition_sprites
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  # Kept for compatibility with any older load-screen calls.
  def pbSetParty(trainer)
  end

  def pbHideParty(trainer)
  end

  # Finds the newest existing Game_X.rxdata and reads only the preview fields:
  # Trainer, map ID and frame count. It does not load the actual game.
  def bushido_find_last_save
    newest = nil
    newest_time = nil

    for slot in 1..99
      file = RTP.getSaveFileName("Game_#{slot}.rxdata")
      next if !safeExists?(file)

      begin
        modified = File.mtime(file)
      rescue
        modified = Time.at(0)
      end

      if newest.nil? || modified > newest_time
        newest = file
        newest_time = modified
      end
    end

    return nil if newest.nil?

    begin
      trainer = nil
      mapid = 0
      framecount = 0
      File.open(newest) do |f|
        trainer = Marshal.load(f)
        mapid = Marshal.load(f)
        framecount = Marshal.load(f)
      end
      return {
        :trainer => trainer,
        :mapid => mapid,
        :framecount => framecount,
        :file => newest
      }
    rescue
      return nil
    end
  end

  def bushido_create_preview_sprites(preview)
    return if !preview || !preview[:trainer]

    trainer = preview[:trainer]
    card_x = 220
    card_y = 0

    # Player sprite
    begin
      meta = pbGetMetadata(0, MetadataPlayerA + trainer.metaID)
      if meta
        filename = pbGetPlayerCharset(meta, 1, trainer, true)
        @sprites["preview_player"] = TrainerWalkingCharSprite.new(filename, @viewport)
        sprite = @sprites["preview_player"]
        charwidth = sprite.bitmap.width
        charheight = sprite.bitmap.height
        sprite.src_rect = Rect.new(0, 0, charwidth / 4, charheight / 4)
        sprite.x = card_x + 12
        sprite.y = card_y + 56
        sprite.z = @viewport.z + 10
      end
    rescue
    end

    # Party icons: two rows of three.
    begin
      trainer.party.each_with_index do |pkmn, i|
        break if i >= 6
        key = "preview_party#{i}"
        @sprites[key] = PokemonIconSprite.new(pkmn, @viewport)
        @sprites[key].setOffset(PictureOrigin::Center)

        col = i % 3
        row = i / 3

        @sprites[key].x = card_x + 50 + (col * 78)
        @sprites[key].y = card_y + 266 + (row * 46)
        @sprites[key].z = @viewport.z + 10
      end
    rescue
    end
  end
end


class PokemonLoadScreen


  def initialize(scene)
    @scene      = scene
    @load_scene = SaveSlot_Selection_Scene.new
    @ng_scene   = SaveSlot_Selection_Scene.new(true)
  end

  def create_load_commands(reset = false)
    @commands        = []
    @cmd_new_game    = -1
    @cmd_continue    = -1
    @cmd_options     = -1
    @cmd_language    = -1
    @cmd_debug       = -1
    @cmd_quit        = -1
    @commands[@cmd_continue = @commands.length] = _INTL("Load Game") if !@load_scene.slots.empty?
    @commands[@cmd_new_game = @commands.length] = _INTL("New Game")
    @commands[@cmd_options = @commands.length]  = _INTL("Options")
    @commands[@cmd_language = @commands.length] = _INTL("Language") if LANGUAGES.length >= 2
    @commands[@cmd_debug = @commands.length]    = _INTL("Debug") if $DEBUG
    @commands[@cmd_quit = @commands.length]     = _INTL("Quit Game")
    return if !reset
    @scene.pbResetScene(@commands)
    @load_scene.refresh_save_slots($PokemonSystem.save_slot - 1)
    @ng_scene.refresh_save_slots($PokemonSystem.save_slot - 1)
  end

  def pbEndScene
    @scene.pbEndScene
    @load_scene.dispose
    @ng_scene.dispose
  end

  def pbStartLoadScreen
    $game_temp     = Game_Temp.new
    $PokemonTemp   = PokemonTemp.new if !$PokemonTemp
    $game_system   = Game_System.new if !$game_system
    $PokemonSystem = PokemonSystem.new if !$PokemonSystem
    data_system = load_data("Data/System.rxdata")
    mapfile = sprintf("Data/Map%03d.rxdata",data_system.start_map_id)
    if data_system.start_map_id == 0 || !pbRgssExists?(mapfile)
      pbMessage(_INTL("No starting position was set in the map editor.\1"))
      pbMessage(_INTL("The game cannot continue."))
      pbEndScene
      $scene = nil
      return
    end
    create_load_commands
    @scene.pbStartScene(@commands, false, nil, 0, 0)
    @scene.pbStartScene2
    loop do
      command = @scene.pbChoose(@commands)
      case command
      when @cmd_continue
        pbPlayDecisionSE
        old_slot_length = @load_scene.slots.length

        @scene.pbTransitionToSlots(:load)
        slot = @load_scene.get_save_slot

        if slot <= 0
          @scene.pbTransitionBackFromSlots(:load)
          create_load_commands(true) if old_slot_length != @load_scene.slots.length
          next
        end
        $PokemonSystem.save_slot = slot
        save_file = RTP.getSaveFileName("Game_#{slot}.rxdata")
        unless safeExists?(save_file)
          pbPlayBuzzerSE
          next
        end

        @scene.pbFadeOutToGame
        pbEndScene
        metadata = nil
        File.open(save_file) { |f|
          $Trainer             = Marshal.load(f)
          Marshal.load(f)   # Current map id no longer needed
          Graphics.frame_count = Marshal.load(f)
          $game_switches       = Marshal.load(f)
          $game_variables      = Marshal.load(f)
          $game_self_switches  = Marshal.load(f)
          $game_screen         = Marshal.load(f)
          $MapFactory          = Marshal.load(f)
          $game_map            = $MapFactory.map
          $game_player         = Marshal.load(f)
          $PokemonGlobal       = Marshal.load(f)
          metadata             = Marshal.load(f)
          $PokemonBag          = Marshal.load(f)
          $PokemonStorage      = Marshal.load(f)
          $SaveVersion         = Marshal.load(f) unless f.eof?
          magicNumberMatches = false
          if $data_system.respond_to?("magic_number")
            magicNumberMatches = ($game_system.magic_number == $data_system.magic_number)
          else
            magicNumberMatches = ($game_system.magic_number == $data_system.version_id)
          end
          if !magicNumberMatches || $PokemonGlobal.safesave
            pbMapInterpreter.setup(nil, 0) if pbMapInterpreterRunning?
            begin
              $MapFactory.setup($game_map.map_id)   # calls setMapChanged
            rescue Errno::ENOENT
              end_game = true
              if $DEBUG
                pbMessage(_INTL("Map {1} was not found.", $game_map.map_id))
                map = pbWarpToMap
                if map
                  end_game = false
                  $MapFactory.setup(map[0])
                  $game_player.moveto(map[1],map[2])
                end
              end
              if end_game
                $game_map = nil
                $scene = nil
                pbMessage(_INTL("The map was not found. The game cannot continue."))
                return
              end
            end
            $game_player.center($game_player.x, $game_player.y)
          else
            $MapFactory.setMapChanged($game_map.map_id)
          end
        }
        if !$game_map.events   # Map wasn't set up
          $game_map = nil
          $scene = nil
          pbMessage(_INTL("The map is corrupt. The game cannot continue."))
          return
        end
        $PokemonMap = metadata
        $PokemonEncounters = PokemonEncounters.new
        $PokemonEncounters.setup($game_map.map_id)
        pbAutoplayOnSave
        $game_map.update
        $PokemonMap.updateMap
        $scene = Scene_Map.new
        Graphics.transition(20)
=begin
        #Thundaga force fog onto map in chapter 6
        if $game_variables[99]==6 && ($game_map.map_id==85 || $game_map.map_id==88)
          $game_map.fog_name = 'clouds3'
          $game_map.fog_hue = 0
          $game_map.fog_opacity = 170
          $game_map.fog_blend_type = 0
          $game_map.fog_zoom = 150
          $game_map.fog_sx = 8
          $game_map.fog_sy = 2
          if($game_map.map_id==88 and $game_player.x>55)
            pbBGMPlay('PKMNMovie15-TruePower')
          elsif $game_map.map_id==88
            pbBGMPlay('Conquest-EventTheme05')
          else
            pbBGMPlay('Conquest-EventTheme03')
          end
          $game_map.update
        end
=end
        return
      when @cmd_new_game
        pbPlayDecisionSE
        old_slot_length = @ng_scene.slots.length

        @scene.pbTransitionToSlots(:new_game)
        slot = @ng_scene.get_save_slot

        if slot <= 0
          @scene.pbTransitionBackFromSlots(:new_game)
          create_load_commands(true) if old_slot_length != @ng_scene.slots.length
          next
        end
        $PokemonSystem.save_slot = slot

        @scene.pbFadeOutToGame
        pbEndScene

        $game_map.events.each_value { |e| e.clear_starting } if $game_map && $game_map.events
        $game_temp.common_event_id = 0 if $game_temp
        $scene               = Scene_Map.new
        Graphics.frame_count = 0
        $game_switches       = Game_Switches.new
        $game_variables      = Game_Variables.new
        $game_self_switches  = Game_SelfSwitches.new
        $game_screen         = Game_Screen.new
        $game_player         = Game_Player.new
        $PokemonMap          = PokemonMapMetadata.new
        $PokemonGlobal       = PokemonGlobalMetadata.new
        $PokemonStorage      = PokemonStorage.new
        $PokemonEncounters   = PokemonEncounters.new
        # $PokemonTemp.begunNewGame = true
        $data_system         = load_data("Data/System.rxdata")
        $MapFactory          = PokemonMapFactory.new($data_system.start_map_id)   # calls setMapChanged
        $game_player.moveto($data_system.start_x, $data_system.start_y)
        $game_player.refresh
        $game_map.autoplay
        $game_map.update
        Graphics.transition(20)
        return
      when @cmd_options
        pbPlayDecisionSE
        pbFadeOutIn {
          scene = PokemonOption_Scene.new
          screen = PokemonOptionScreen.new(scene)
          screen.pbStartScreen(true)
        }
      when @cmd_language
        pbPlayDecisionSE
        @scene.pbEndScene
        $PokemonSystem.language = pbChooseLanguage
        pbLoadMessages("Data/" + LANGUAGES[$PokemonSystem.language][1])
        save_data = []
        settings  = RTP.getSaveFileName("Settings.rxdata")
        if safeExists?(settings)
          File.open(settings) { |f| 2.times { save_data.push(Marshal.load(f)) } }
          save_data[0] = $PokemonSystem
          begin
            File.open(settings) { |f| 2.times { |i| Marshal.dump(save_data[i]) } }
          rescue
          end
        end
        $scene = pbCallTitle
        return
      when @cmd_debug
        pbPlayDecisionSE
        pbFadeOutIn { pbDebugMenu(false) }
      when @cmd_quit
        pbPlayCloseMenuSE
        @scene.pbEndScene
        $scene = nil
        return
      end
    end
  end
end

class PokemonSystem
  attr_accessor :save_slot

  def save_slot
    @save_slot = 0 if !@save_slot
    return @save_slot
  end
end
