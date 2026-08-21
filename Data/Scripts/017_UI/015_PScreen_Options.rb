class PokemonSystem
  attr_accessor :textspeed
  attr_accessor :battlescene
  attr_accessor :battlestyle
  attr_accessor :frame
  attr_writer   :textskin
  attr_accessor :font
  attr_accessor :screensize
  attr_writer   :language
  attr_writer   :runstyle
  attr_writer   :bgmvolume
  attr_writer   :sevolume
  attr_accessor :controlScheme

  def initialize
    @textspeed   = 1     # Text speed (0=slow, 1=normal, 2=fast)
    @battlescene = 0     # Battle effects (animations) (0=on, 1=off)
    @battlestyle = 0     # Battle style (0=switch, 1=set)
    @frame       = 0     # Default window frame (see also $TextFrames)
    @textskin    = 0     # Speech frame
    @font        = 0     # Font (see also $VersionStyles)
    @screensize  = (SCREEN_SCALE * 2).floor - 1   # 0=half size, 1=full size, 2=double size
    @language    = 0     # Language (see also LANGUAGES in script PokemonSystem)
    @runstyle    = 0     # Run key functionality (0=hold to run, 1=toggle auto-run)
    @bgmvolume   = 100   # Volume of background music and ME
    @sevolume    = 100   # Volume of sound effects
    @textinput   = 1     # Text input mode (0=cursor, 1=keyboard)
    @controlScheme = 1
  end

  def textskin;  return @textskin || 0;    end
  def language;  return @language || 0;    end
  def runstyle;  return @runstyle || 0;    end
  def bgmvolume; return @bgmvolume || 100; end
  def sevolume;  return @sevolume || 100;  end
  def textinput; return 1;   end
  def tilemap;   return MAP_VIEW_MODE;     end
  def controlScheme; return 1; end
end

#===============================================================================
# Save-specific Bushido options
#===============================================================================
class PokemonGlobalMetadata
  attr_accessor :enemyTechniques
end

#===============================================================================
# Stores game options
# Default options are at the top of script section SpriteWindow.
#===============================================================================
$SpeechFrames = [
  MessageConfig::TextSkinName,   # Default: speech hgss 1
  "speech hgss 2",
  "speech hgss 3",
  "speech hgss 4",
  "speech hgss 5",
  "speech hgss 6",
  "speech hgss 7",
  "speech hgss 8",
  "speech hgss 9",
  "speech hgss 10",
  "speech hgss 11",
  "speech hgss 12",
  "speech hgss 13",
  "speech hgss 14",
  "speech hgss 15",
  "speech hgss 16",
  "speech hgss 17",
  "speech hgss 18",
  "speech hgss 19",
  "speech hgss 20",
  "speech pl 18"
]

$TextFrames = [
  "Graphics/Windowskins/"+MessageConfig::ChoiceSkinName,   # Default: choice 1
  "Graphics/Windowskins/choice 2",
  "Graphics/Windowskins/choice 3",
  "Graphics/Windowskins/choice 4",
  "Graphics/Windowskins/choice 5",
  "Graphics/Windowskins/choice 6",
  "Graphics/Windowskins/choice 7",
  "Graphics/Windowskins/choice 8",
  "Graphics/Windowskins/choice 9",
  "Graphics/Windowskins/choice 10",
  "Graphics/Windowskins/choice 11",
  "Graphics/Windowskins/choice 12",
  "Graphics/Windowskins/choice 13",
  "Graphics/Windowskins/choice 14",
  "Graphics/Windowskins/choice 15",
  "Graphics/Windowskins/choice 16",
  "Graphics/Windowskins/choice 17",
  "Graphics/Windowskins/choice 18",
  "Graphics/Windowskins/choice 19",
  "Graphics/Windowskins/choice 20",
  "Graphics/Windowskins/choice 21",
  "Graphics/Windowskins/choice 22",
  "Graphics/Windowskins/choice 23",
  "Graphics/Windowskins/choice 24",
  "Graphics/Windowskins/choice 25",
  "Graphics/Windowskins/choice 26",
  "Graphics/Windowskins/choice 27",
  "Graphics/Windowskins/choice 28"
]

$VersionStyles = [
  [MessageConfig::FontName],   # Default font style - Power Green/"Pokemon Emerald"
  ["Power Red and Blue"],
  ["Power Red and Green"],
  ["Power Clear"]
]

def pbSettingToTextSpeed(speed)
  case speed
  when 0; return 2
  when 1; return 1
  when 2; return -2
  end
  return MessageConfig::TextSpeed || 1
end



module MessageConfig
  def self.pbDefaultSystemFrame
    begin
      return pbResolveBitmap($TextFrames[$PokemonSystem.frame]) || ""
    rescue
      return pbResolveBitmap("Graphics/Windowskins/"+MessageConfig::ChoiceSkinName) || ""
    end
  end

  def self.pbDefaultSpeechFrame
    begin
      return pbResolveBitmap("Graphics/Windowskins/"+$SpeechFrames[$PokemonSystem.textskin]) || ""
    rescue
      return pbResolveBitmap("Graphics/Windowskins/"+MessageConfig::TextSkinName) || ""
    end
  end

  def self.pbDefaultSystemFontName
    begin
      return MessageConfig.pbTryFonts($VersionStyles[$PokemonSystem.font][0],"Arial Narrow","Arial")
    rescue
      return MessageConfig.pbTryFonts(MessageConfig::FontName,"Arial Narrow","Arial")
    end
  end

  def self.pbDefaultTextSpeed
    return pbSettingToTextSpeed(($PokemonSystem.textspeed rescue nil))
  end

  def pbGetSystemTextSpeed
    begin
      return $PokemonSystem.textspeed
    rescue
      return (Graphics.frame_rate>40) ? 2 :  3
    end
  end
end



#===============================================================================
#
#===============================================================================
module PropertyMixin
  def get
    (@getProc) ? @getProc.call : nil
  end

  def set(value)
    @setProc.call(value) if @setProc
  end
end



class EnumOption
  include PropertyMixin
  attr_reader :values
  attr_reader :name

  def initialize(name,options,getProc,setProc)
    @name    = name
    @values  = options
    @getProc = getProc
    @setProc = setProc
  end

  def next(current)
    index = current+1
    index = @values.length-1 if index>@values.length-1
    return index
  end

  def prev(current)
    index = current-1
    index = 0 if index<0
    return index
  end
end



class EnumOption2
  include PropertyMixin
  attr_reader :values
  attr_reader :name

  def initialize(name,options,getProc,setProc)
    @name    = name
    @values  = options
    @getProc = getProc
    @setProc = setProc
  end

  def next(current)
    index = current+1
    index = @values.length-1 if index>@values.length-1
    return index
  end

  def prev(current)
    index = current-1
    index = 0 if index<0
    return index
  end
end



class NumberOption
  include PropertyMixin
  attr_reader :name
  attr_reader :optstart
  attr_reader :optend

  def initialize(name,optstart,optend,getProc,setProc)
    @name     = name
    @optstart = optstart
    @optend   = optend
    @getProc  = getProc
    @setProc  = setProc
  end

  def next(current)
    index = current+@optstart
    index += 1
    index = @optstart if index>@optend
    return index-@optstart
  end

  def prev(current)
    index = current+@optstart
    index -= 1
    index = @optend if index<@optstart
    return index-@optstart
  end
end



class SliderOption
  include PropertyMixin
  attr_reader :name
  attr_reader :optstart
  attr_reader :optend

  def initialize(name,optstart,optend,optinterval,getProc,setProc)
    @name        = name
    @optstart    = optstart
    @optend      = optend
    @optinterval = optinterval
    @getProc     = getProc
    @setProc     = setProc
  end

  def next(current)
    index = current+@optstart
    index += @optinterval
    index = @optend if index>@optend
    return index-@optstart
  end

  def prev(current)
    index = current+@optstart
    index -= @optinterval
    index = @optstart if index<@optstart
    return index-@optstart
  end
end



#===============================================================================
# Main options list
#===============================================================================
module BushidoOptionsStyle
  PARCHMENT       = Color.new(238,221,181)
  PARCHMENT_LIGHT = Color.new(248,237,208)
  PARCHMENT_DARK  = Color.new(211,188,142)
  INK             = Color.new(66,46,34)
  INK_SOFT        = Color.new(112,88,67)
  RED             = Color.new(154,48,39)
  RED_DARK        = Color.new(105,31,27)
  RED_SOFT        = Color.new(193,102,85)
  CREAM           = Color.new(255,246,220)

  def self.draw_border(bitmap,x,y,w,h,color,thickness=2)
    bitmap.fill_rect(x,y,w,thickness,color)
    bitmap.fill_rect(x,y+h-thickness,w,thickness,color)
    bitmap.fill_rect(x,y,thickness,h,color)
    bitmap.fill_rect(x+w-thickness,y,thickness,h,color)
  end
end



#===============================================================================
# Main options list - Bushido parchment style
#===============================================================================
class Window_PokemonOption < Window_DrawableCommand
  attr_reader :mustUpdateOptions

  def initialize(options,x,y,width,height)
    @options = options
    @optvalues = []
    @mustUpdateOptions = false
    @hover_anim = 0
    @switch_anim = 0
    @switch_dir = 0
    @last_index = 0
    for i in 0...@options.length
      @optvalues[i] = 0
    end
    super(x,y,width,height)
    self.opacity = 0
    self.back_opacity = 0
    self.contents_opacity = 255
    @last_index = self.index
    hideScrollArrows
  end

  # The stock selectable window adds scroll arrows when the list is taller
  # than its viewport. They sit on top of our custom rows, so this menu never
  # draws them. The checks keep this compatible with the different Window
  # implementations used by Essentials/mkxp.
  def hideScrollArrows
    self.arrows_visible = false if self.respond_to?(:arrows_visible=)
    for ivar in [:@uparrow, :@downarrow, :@up_arrow, :@down_arrow,
                 :@uparrowsprite, :@downarrowsprite,
                 :@upArrow, :@downArrow]
      next if !self.instance_variable_defined?(ivar)
      sprite = self.instance_variable_get(ivar)
      sprite.visible = false if sprite && sprite.respond_to?(:visible=)
    end
  end

  def [](i)
    return @optvalues[i]
  end

  def []=(i,value)
    @optvalues[i] = value
    refresh
  end

  def setValueNoRefresh(i,value)
    @optvalues[i] = value
  end

  def itemCount
    return @options.length+1
  end

  def drawItem(index,_count,rect)
    selected = (index == self.index)
    row_x = rect.x + 8
    row_y = rect.y + 3
    row_w = rect.width - 16
    row_h = rect.height - 6

    # Keep every option row as a plain rectangle. No tabs, seals, or extra lines.
    if selected
      pulse = ((Math.sin(Graphics.frame_count / 7.0) + 1.0) * 10).to_i
      self.contents.fill_rect(row_x,row_y,row_w,row_h,
        Color.new(154,48,39,48 + pulse))
      BushidoOptionsStyle.draw_border(self.contents,row_x,row_y,row_w,row_h,
        Color.new(154,48,39,190),1)
    else
      self.contents.fill_rect(row_x,row_y,row_w,row_h,
        Color.new(248,237,208,72))
      BushidoOptionsStyle.draw_border(self.contents,row_x,row_y,row_w,row_h,
        Color.new(211,188,142,70),1)
    end

    optionname = (index==@options.length) ? _INTL("Back") : @options[index].name
    optionwidth = (rect.width*9/20).floor

    # Essentials' baseline looked about two pixels high in this layout.
    text_y = rect.y + 6
    hover_offset = selected ? [@hover_anim,4].min : 0
    name_x = rect.x + 18 + hover_offset

    if selected
      name_color  = BushidoOptionsStyle::RED_DARK
      name_shadow = Color.new(248,237,208,190)
    else
      # Unfocused labels sit back into the parchment instead of competing
      # with the row the player is currently editing.
      name_color  = Color.new(66,46,34,175)
      name_shadow = Color.new(248,237,208,105)
    end

    pbDrawShadowText(self.contents,name_x,text_y,optionwidth-10,rect.height,
      optionname,name_color,name_shadow)
    return if index==@options.length

    value_x = rect.x + optionwidth
    value_w = rect.width - optionwidth - 18
    option = @options[index]
    switch_offset = 0
    if selected && @switch_anim>0
      switch_offset = @switch_dir * [(@switch_anim/3),2].min
    end

    # Configure Controls is an action, not a true two-value enum.
    if option.name == _INTL("Configure Controls")
      action_color = selected ? BushidoOptionsStyle::RED : Color.new(112,88,67,125)
      pbDrawShadowText(self.contents,value_x+switch_offset,text_y,value_w,rect.height,
        _INTL("Open"),action_color,Color.new(248,237,208,110),2)
      return
    end

    if option.is_a?(EnumOption)
      if option.values.length>1
        widths = []
        totalwidth = 0
        for value in option.values
          w = self.contents.text_size(value).width
          widths.push(w)
          totalwidth += w
        end
        spacing = (value_w-totalwidth)/(option.values.length-1) rescue 0
        spacing = 8 if spacing<8
        xpos = value_x
        for i in 0...option.values.length
          value = option.values[i]
          current_value = (i==self[index])
          if current_value
            color = selected ? BushidoOptionsStyle::RED : Color.new(154,48,39,155)
            shadow = Color.new(248,237,208,150)
            dx = switch_offset
          else
            # Non-active choices are intentionally dimmer so the current
            # value reads immediately at a glance.
            color = selected ? Color.new(112,88,67,125) : Color.new(112,88,67,88)
            shadow = Color.new(248,237,208,80)
            dx = 0
          end
          pbDrawShadowText(self.contents,xpos+dx,text_y,widths[i]+4,rect.height,
            value,color,shadow)
          xpos += widths[i] + spacing
        end
      else
        color = selected ? BushidoOptionsStyle::RED : Color.new(154,48,39,145)
        pbDrawShadowText(self.contents,value_x+switch_offset,text_y,value_w,rect.height,
          option.values[0].to_s,color,Color.new(248,237,208,120),2)
      end
    elsif option.is_a?(NumberOption)
      value = _INTL("{1} / {2}",option.optstart+self[index],
        option.optend-option.optstart+1)
      color = selected ? BushidoOptionsStyle::RED : Color.new(154,48,39,145)
      pbDrawShadowText(self.contents,value_x+switch_offset,text_y,value_w,rect.height,value,
        color,Color.new(248,237,208,120),2)
    elsif option.is_a?(SliderOption)
      number = option.optstart+self[index]
      value_text = sprintf("%d",number)
      number_w = self.contents.text_size(value_text).width + 8
      slider_x = value_x + 4
      slider_w = value_w - number_w - 12
      slider_y = rect.y + rect.height/2 + 1

      track_color = selected ? Color.new(211,188,142,210) : Color.new(211,188,142,105)
      fill_color  = selected ? BushidoOptionsStyle::RED : Color.new(154,48,39,135)
      knob_color  = selected ? BushidoOptionsStyle::RED_DARK : Color.new(105,31,27,145)

      self.contents.fill_rect(slider_x,slider_y-2,slider_w,4,track_color)
      range = option.optend-option.optstart
      ratio = (range<=0) ? 0.0 : (number-option.optstart).to_f/range.to_f
      filled = (slider_w*ratio).floor
      self.contents.fill_rect(slider_x,slider_y-2,filled,4,fill_color)
      knob_x = slider_x + filled - 3
      knob_x = slider_x if knob_x<slider_x
      knob_x = slider_x+slider_w-6 if knob_x>slider_x+slider_w-6
      knob_h = selected && @switch_anim>0 ? 16 : 14
      self.contents.fill_rect(knob_x,slider_y-(knob_h/2),6,knob_h,knob_color)

      number_color = selected ? BushidoOptionsStyle::RED : Color.new(154,48,39,145)
      pbDrawShadowText(self.contents,value_x+value_w-number_w+switch_offset,text_y,
        number_w,rect.height,value_text,number_color,Color.new(248,237,208,120),2)
    else
      value = option.values[self[index]]
      color = selected ? BushidoOptionsStyle::RED : Color.new(154,48,39,145)
      pbDrawShadowText(self.contents,value_x+switch_offset,text_y,value_w,rect.height,value,
        color,Color.new(248,237,208,120),2)
    end
  end

  def update
    oldindex = self.index
    @mustUpdateOptions = false
    super
    hideScrollArrows
    dorefresh = false

    if self.index != oldindex
      @hover_anim = 0
      @last_index = self.index
      dorefresh = true
      @mustUpdateOptions = true
    end

    if self.active && self.index<@options.length
      if Input.repeat?(Input::LEFT)
        oldvalue = self[self.index]
        self.setValueNoRefresh(self.index,@options[self.index].prev(oldvalue))
        if self[self.index] != oldvalue
          @switch_anim = 6
          @switch_dir = -1
          pbPlayCursorSE
        end
        dorefresh = true
        @mustUpdateOptions = true
      elsif Input.repeat?(Input::RIGHT)
        oldvalue = self[self.index]
        self.setValueNoRefresh(self.index,@options[self.index].next(oldvalue))
        if self[self.index] != oldvalue
          @switch_anim = 6
          @switch_dir = 1
          pbPlayCursorSE
        end
        dorefresh = true
        @mustUpdateOptions = true
      end
    end

    # A tiny 4px ease-in gives the highlighted label some life without
    # making the list wobble while the player scrolls through it.
    if self.active && @hover_anim < 4
      @hover_anim += 1
      dorefresh = true
    end

    if @switch_anim > 0
      @switch_anim -= 1
      dorefresh = true
    end

    # Refresh the active row periodically for the very soft hover pulse.
    dorefresh = true if self.active && Graphics.frame_count % 3 == 0
    refresh if dorefresh
  end
end



#===============================================================================
# Options main screen - Bushido parchment style
#===============================================================================
class PokemonOption_Scene
  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbDrawParchmentBackground(textbox_height)
    bitmap = @sprites["background"].bitmap
    w = Graphics.width
    h = Graphics.height

    bitmap.fill_rect(0,0,w,h,BushidoOptionsStyle::PARCHMENT)

    # Simple paper edge. Keep the screen framed without turning the header
    # into another giant box.
    bitmap.fill_rect(0,0,w,3,BushidoOptionsStyle::RED_DARK)
    bitmap.fill_rect(0,h-3,w,3,BushidoOptionsStyle::RED_DARK)

    # Clean title: text, one underline, one small square accent.
    pbSetSystemFont(bitmap)
    pbDrawShadowText(bitmap,22,22,220,40,_INTL("OPTIONS"),
      BushidoOptionsStyle::RED_DARK,BushidoOptionsStyle::PARCHMENT_LIGHT,0)
    bitmap.fill_rect(22,63,w-44,2,BushidoOptionsStyle::RED)
    bitmap.fill_rect(w-29,59,7,7,BushidoOptionsStyle::RED_DARK)

    # The real message window is drawn on top of this area. Don't paint a
    # fake parchment textbox here; the actual windowskin needs to stay visible
    # so Speech Frame/Menu Frame can be previewed properly.
    box_y = h-textbox_height
    bitmap.fill_rect(18,box_y-3,w-36,1,Color.new(154,48,39,105))
  end

  def pbStartScene(inloadscreen=false)
    @sprites = {}
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999

    @sprites["background"] = Sprite.new(@viewport)
    @sprites["background"].bitmap = Bitmap.new(Graphics.width,Graphics.height)
    @sprites["background"].z = 0

    # Invisible title window retained because the existing layout uses its height.
    @sprites["title"] = Window_UnformattedTextPokemon.newWithSize(
      "",0,0,Graphics.width,64,@viewport)
    @sprites["title"].opacity = 0
    @sprites["title"].back_opacity = 0
    @sprites["title"].z = 2

    @sprites["textbox"] = pbCreateMessageWindow
    # pbCreateMessageWindow does not inherit this scene's viewport. Because the
    # parchment background lives on @viewport, leaving the textbox on the default
    # viewport causes it to render behind the background and disappear.
    @sprites["textbox"].viewport = @viewport
    @sprites["textbox"].text = _INTL("Change the volume of the ingame music.")
    @sprites["textbox"].letterbyletter = false
    @sprites["textbox"].opacity = 255
    @sprites["textbox"].back_opacity = 255
    @sprites["textbox"].z = 3
    @sprites["textbox"].setSkin(MessageConfig.pbGetSpeechFrame())
    pbSetSystemFont(@sprites["textbox"].contents)

    pbDrawParchmentBackground(@sprites["textbox"].height)

    @PokemonOptions = [
       SliderOption.new(_INTL("Music Volume"),0,100,5,
         proc { $PokemonSystem.bgmvolume },
         proc { |value|
           if $PokemonSystem.bgmvolume!=value
             $PokemonSystem.bgmvolume = value
             if $game_system.playing_bgm!=nil && !inloadscreen
               playingBGM = $game_system.getPlayingBGM
               $game_system.bgm_pause
               $game_system.bgm_resume(playingBGM)
             end
           end
         }
       ),
       SliderOption.new(_INTL("SE Volume"),0,100,5,
         proc { $PokemonSystem.sevolume },
         proc { |value|
           if $PokemonSystem.sevolume!=value
             $PokemonSystem.sevolume = value
             if $game_system.playing_bgs!=nil
               $game_system.playing_bgs.volume = value
               playingBGS = $game_system.getPlayingBGS
               $game_system.bgs_pause
               $game_system.bgs_resume(playingBGS)
             end
             pbPlayCursorSE
           end
         }
       ),
       EnumOption.new(_INTL("Text Speed"),[_INTL("Slow"),_INTL("Normal"),_INTL("Fast")],
         proc { $PokemonSystem.textspeed },
         proc { |value|
           $PokemonSystem.textspeed = value
           MessageConfig.pbSetTextSpeed(pbSettingToTextSpeed(value))
         }
       ),
       EnumOption.new(_INTL("Battle Effects"),[_INTL("On"),_INTL("Off")],
         proc { $PokemonSystem.battlescene },
         proc { |value| $PokemonSystem.battlescene = value }
       ),
       EnumOption.new(_INTL("Battle Style"),[_INTL("Switch"),_INTL("Set")],
         proc { $PokemonSystem.battlestyle },
         proc { |value| $PokemonSystem.battlestyle = value }
       ),
       EnumOption.new(_INTL("Font Style"),[_INTL("Em"),_INTL("R/S"),_INTL("FRLG"),_INTL("DP")],
         proc { $PokemonSystem.font },
         proc { |value|
           $PokemonSystem.font = value
           MessageConfig.pbSetSystemFontName($VersionStyles[value])
         }
       ),
       NumberOption.new(_INTL("Speech Frame"),1,$SpeechFrames.length,
         proc { $PokemonSystem.textskin },
         proc { |value|
           $PokemonSystem.textskin = value
           MessageConfig.pbSetSpeechFrame("Graphics/Windowskins/" + $SpeechFrames[value])
         }
       ),
       NumberOption.new(_INTL("Menu Frame"),1,$TextFrames.length,
         proc { $PokemonSystem.frame },
         proc { |value|
           $PokemonSystem.frame = value
           MessageConfig.pbSetSystemFrame($TextFrames[value])
         }
       ),
       EnumOption.new(_INTL("Screen Size"),[_INTL("S"),_INTL("M"),_INTL("L"),_INTL("XL"),_INTL("Full")],
        proc { [$PokemonSystem.screensize,4].min },
        proc { |value|
          if $PokemonSystem.screensize != value
             $PokemonSystem.screensize = value
            pbSetResizeFactor($PokemonSystem.screensize)
          end
        }
      ),
      EnumOption.new(_INTL("Default Movement"),[_INTL("Walking"),_INTL("Running")],
        proc { $PokemonSystem.runstyle },
        proc { |value| $PokemonSystem.runstyle = value }
      ),
      EnumOption.new(_INTL("Configure Controls"),[_INTL(""),_INTL("")],
        proc { },
        proc { }
      )
    ]

    @Descriptions = [
      _INTL("Change the volume of the ingame music."),
      _INTL("Change the volume of the ingame sound effects."),
      _INTL("Change the speed of the text being displayed."),
      _INTL("Toggle Battle Animations On or Off."),
      _INTL("Toggle the option to switch out your Pokémon after fainting the Opponent."),
      _INTL("Change the font used for the text ingame."),
      _INTL("Change the Windowskin for Text Boxes."),
      _INTL("Change the Windowskin for Choice Boxes."),
      _INTL("Change the size of the Game Window."),
      _INTL("Change the default method of movement."),
      _INTL("Reconfigure the game's controls."),
      _INTL("Close the Options Menu.")
    ]
    if $PokemonGlobal
      idx = @PokemonOptions.length - 1
      @PokemonOptions.insert(idx, EnumOption.new(_INTL("Enemy Techniques"),[_INTL("Strong"),_INTL("Weak")],
        proc { $PokemonGlobal.enemyTechniques || 0 },
        proc { |value| $PokemonGlobal.enemyTechniques = value }
      ))
      @Descriptions.insert(idx, _INTL("Change enemy Katana Technique strength. Weak prevents most negative effects."))
    end
    @PokemonOptions = pbAddOnOptions(@PokemonOptions)
    @sprites["option"] = Window_PokemonOption.new(@PokemonOptions,8,
       @sprites["title"].height,Graphics.width-16,
       Graphics.height-@sprites["title"].height-@sprites["textbox"].height)
    @sprites["option"].viewport = @viewport
    @sprites["option"].visible  = true
    @sprites["option"].z = 2

    for i in 0...@PokemonOptions.length
      @sprites["option"].setValueNoRefresh(i,(@PokemonOptions[i].get || 0))
    end
    @sprites["option"].refresh
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbAddOnOptions(options)
    return options
  end

  # Refresh the actual message window used by the stock options screen.
  # This is intentionally a real windowskin preview, not a parchment drawing.
  def pbRefreshPreviewWindow(index)
    return if !@sprites["textbox"]

    option = (index < @PokemonOptions.length) ? @PokemonOptions[index] : nil
    option_name = option ? option.name : _INTL("Back")

    if option_name == _INTL("Menu Frame")
      begin
        skin = $TextFrames[$PokemonSystem.frame]
        @sprites["textbox"].setSkin(skin) if skin
      rescue
        @sprites["textbox"].setSkin(MessageConfig.pbGetSpeechFrame())
      end
    else
      @sprites["textbox"].setSkin(MessageConfig.pbGetSpeechFrame())
    end

    @sprites["textbox"].opacity = 255
    @sprites["textbox"].back_opacity = 255
    pbSetSystemFont(@sprites["textbox"].contents)
    @sprites["textbox"].letterbyletter = (option_name == _INTL("Text Speed"))
    @sprites["textbox"].text = @Descriptions[index] || _INTL("Close the Options Menu.")
    @sprites["textbox"].textspeed = pbSettingToTextSpeed($PokemonSystem.textspeed)
  end

  def pbOptions
    oldSystemSkin = $PokemonSystem.frame
    oldTextSkin   = $PokemonSystem.textskin
    oldFont       = $PokemonSystem.font
    pbRefreshPreviewWindow(@sprites["option"].index)
    pbActivateWindow(@sprites,"option") {
      loop do
        Graphics.update
        Input.update
        pbUpdate
        if @sprites["option"].mustUpdateOptions
          for i in 0...@PokemonOptions.length
            @PokemonOptions[i].set(@sprites["option"][i])
          end
          oldTextSkin   = $PokemonSystem.textskin if $PokemonSystem.textskin!=oldTextSkin
          oldSystemSkin = $PokemonSystem.frame    if $PokemonSystem.frame!=oldSystemSkin
          oldFont       = $PokemonSystem.font     if $PokemonSystem.font!=oldFont
          pbRefreshPreviewWindow(@sprites["option"].index)
        end
        if Input.trigger?(Input::B)
          break
        elsif Input.trigger?(Input::C)
          if @sprites["option"].index == @PokemonOptions.length
            break
          elsif @PokemonOptions[@sprites["option"].index] && @PokemonOptions[@sprites["option"].index].name == _INTL("Configure Controls")
            System.show_settings
          end
        end
      end
    }
  end

  def pbEndScene
    pbPlayCloseMenuSE
    pbFadeOutAndHide(@sprites) { pbUpdate }
    for i in 0...@PokemonOptions.length
      @PokemonOptions[i].set(@sprites["option"][i])
    end
    pbDisposeMessageWindow(@sprites["textbox"])
    if @sprites["background"] && @sprites["background"].bitmap && !@sprites["background"].bitmap.disposed?
      @sprites["background"].bitmap.dispose
    end
    pbDisposeSpriteHash(@sprites)
    pbRefreshSceneMap
    @viewport.dispose
  end
end


#===============================================================================
#
#===============================================================================
class PokemonOptionScreen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen(inloadscreen=false)
    @scene.pbStartScene(inloadscreen)
    @scene.pbOptions
    @scene.pbEndScene
  end
end
