#===============================================================================
# Data box for regular battles
#===============================================================================
class PokemonDataBox < SpriteWrapper
  attr_reader   :battler
  attr_accessor :selected
  attr_reader   :animatingHP
  attr_reader   :animatingExp

  # Time in seconds to fully fill the Exp bar (from empty).
  EXP_BAR_FILL_TIME  = 1.75
  # Maximum time in seconds to make a change to the HP bar.
  HP_BAR_CHANGE_TIME = 1.0
  STATUS_ICON_HEIGHT = 16
  NAME_BASE_COLOR         = Color.new(64,64,64)
  NAME_SHADOW_COLOR       = Color.new(216,208,176)
  LEVEL_BASE_COLOR        = NAME_BASE_COLOR
  LEVEL_SHADOW_COLOR      = NAME_SHADOW_COLOR
  HP_NUMBERS_BASE_COLOR   = NAME_BASE_COLOR
  HP_NUMBERS_SHADOW_COLOR = NAME_SHADOW_COLOR
  MALE_BASE_COLOR         = Color.new(48,96,216)
  MALE_SHADOW_COLOR       = NAME_SHADOW_COLOR
  FEMALE_BASE_COLOR       = Color.new(248,88,40)
  FEMALE_SHADOW_COLOR     = NAME_SHADOW_COLOR

  def initialize(battler,sideSize,viewport=nil)
    super(viewport)
    @battler      = battler
    @sprites      = {}
    @spriteX      = 0
    @spriteY      = 0
    @spriteBaseX  = 0
    @selected     = 0
    @frame        = 0
    @showHP       = false   # Specifically, show the HP numbers
    @animatingHP  = false
    @showExp      = false   # Specifically, show the Exp bar
    @animatingExp = false
    @expFlash     = 0
    initializeDataBoxGraphic(sideSize)
    initializeOtherGraphics(viewport)
    refresh
  end

  def initializeDataBoxGraphic(sideSize)
    onPlayerSide = ((@battler.index%2)==0)
    # Get the data box graphic and set whether the HP numbers/Exp bar are shown
    if sideSize==1   # One Pokémon on side, use the regular dara box BG
      bgFilename = ["Graphics/Pictures/Battle/databox_normal",
                    "Graphics/Pictures/Battle/databox_normal_foe"][@battler.index%2]
      if onPlayerSide
        @showHP  = true
        @showExp = true
      end
    elsif sideSize==2    # Multiple Pokémon on side, use the thin dara box BG
      bgFilename = ["Graphics/Pictures/Battle/databox_thin",
                    "Graphics/Pictures/Battle/databox_thin_foe"][@battler.index%2]
    else #Side size is 3, use more transparent databoxes
      bgFilename = ["Graphics/Pictures/Battle/databox_thin_3",
                    "Graphics/Pictures/Battle/databox_thin_foe_3"][@battler.index%2]
    end
    @databoxBitmap  = AnimatedBitmap.new(bgFilename)
    # Determine the co-ordinates of the data box and the left edge padding width
    if onPlayerSide
      @spriteX = Graphics.width - 274
      @spriteY = Graphics.height - 176
      @spriteBaseX = 34
    else
      @spriteX = -8
      @spriteY = 36
      @spriteBaseX = 16
    end
    case sideSize
    when 2
      @spriteX += [8,  -22,  8, -22][@battler.index]
      @spriteY += [-26, -34, 24, 18][@battler.index]
    when 3
      @spriteX += [8, -22, 8, -22, 8, -22][@battler.index]
      @spriteY += [-48, -34, -10, 16, 26, 68][@battler.index]
    end
  end

  def initializeOtherGraphics(viewport)
    # Create other bitmaps
    @numbersBitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/Battle/icon_numbers"))
    @hpBarBitmap   = AnimatedBitmap.new(_INTL("Graphics/Pictures/Battle/overlay_hp"))
    @expBarBitmap  = AnimatedBitmap.new(_INTL("Graphics/Pictures/Battle/overlay_exp"))
    # Create sprite to draw HP numbers on
    @hpNumbers = BitmapSprite.new(124,16,viewport)
    pbSetSmallFont(@hpNumbers.bitmap)
    @sprites["hpNumbers"] = @hpNumbers
    # Create sprite wrapper that displays HP bar
    @hpBar = SpriteWrapper.new(viewport)
    @hpBar.bitmap = @hpBarBitmap.bitmap
    @hpBar.src_rect.height = @hpBarBitmap.height/3
    @sprites["hpBar"] = @hpBar
    # Create sprite wrapper that displays Exp bar
    @expBar = SpriteWrapper.new(viewport)
    @expBar.bitmap = @expBarBitmap.bitmap
    @sprites["expBar"] = @expBar
    # Create sprite wrapper that displays everything except the above
    @contents = BitmapWrapper.new(@databoxBitmap.width,@databoxBitmap.height)
    self.bitmap  = @contents
    self.visible = false
    self.z       = 150+((@battler.index)/2)*5
    pbSetSystemFont(self.bitmap)
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @databoxBitmap.dispose
    @numbersBitmap.dispose
    @hpBarBitmap.dispose
    @expBarBitmap.dispose
    @contents.dispose
    super
  end

  def x=(value)
    super
    @hpBar.x     = value+148
    @expBar.x    = value+@spriteBaseX+82
    @hpNumbers.x = value+@spriteBaseX+110
  end

  def y=(value)
    super
    @hpBar.y     = value+38
    @expBar.y    = value+70
    @hpNumbers.y = value+48
  end

  def z=(value)
    super
    @hpBar.z     = value+1
    @expBar.z    = value+1
    @hpNumbers.z = value+2
  end

  def opacity=(value)
    super
    for i in @sprites
      i[1].opacity = value if !i[1].disposed?
    end
  end

  def visible=(value)
    super
    for i in @sprites
      i[1].visible = value if !i[1].disposed?
    end
    @expBar.visible = (value && @showExp)
  end

  def color=(value)
    super
    for i in @sprites
      i[1].color = value if !i[1].disposed?
    end
  end

  def battler=(b)
    @battler = b
    self.visible = (@battler && !@battler.fainted?)
  end

  def hp
    return (@animatingHP) ? @currentHP : @battler.hp
  end

  def expFraction
    return (@animatingExp) ? @currentExp.to_f/@rangeExp : @battler.pokemon.expFraction
  end

  def animateHP(oldHP,newHP,rangeHP)
    @currentHP   = oldHP
    @endHP       = newHP
    @rangeHP     = rangeHP
    # NOTE: A change in HP takes the same amount of time to animate, no matter
    #       how big a change it is.
    @hpIncPerFrame = (newHP-oldHP).abs/(HP_BAR_CHANGE_TIME*Graphics.frame_rate)
    # minInc is the smallest amount that HP is allowed to change per frame.
    # This avoids a tiny change in HP still taking HP_BAR_CHANGE_TIME seconds.
    minInc = (rangeHP*4)/(@hpBarBitmap.width*HP_BAR_CHANGE_TIME*Graphics.frame_rate)
    @hpIncPerFrame = minInc if @hpIncPerFrame<minInc
    @animatingHP   = true
  end

  def animateExp(oldExp,newExp,rangeExp)
    @currentExp     = oldExp
    @endExp         = newExp
    @rangeExp       = rangeExp
    # NOTE: Filling the Exp bar from empty to full takes EXP_BAR_FILL_TIME
    #       seconds no matter what. Filling half of it takes half as long, etc.
    @expIncPerFrame = rangeExp/(EXP_BAR_FILL_TIME*Graphics.frame_rate)
    @animatingExp   = true
    pbSEPlay("Pkmn exp gain") if @showExp
  end

  def pbDrawNumber(number,btmp,startX,startY,align=0)
    n = (number==-1) ? [10] : number.to_i.digits   # -1 means draw the / character
    charWidth  = @numbersBitmap.width/11
    charHeight = @numbersBitmap.height
    startX -= charWidth*n.length if align==1
    n.each do |i|
      btmp.blt(startX,startY,@numbersBitmap.bitmap,Rect.new(i*charWidth,0,charWidth,charHeight))
      startX += charWidth
    end
  end

  def refresh
    self.bitmap.clear
    return if !@battler.pokemon
    textPos = []
    imagePos = []
    # Draw background panel
    self.bitmap.blt(0,0,@databoxBitmap.bitmap,Rect.new(0,0,@databoxBitmap.width,@databoxBitmap.height))
    # Draw Pokémon's name
    nameWidth = self.bitmap.text_size(@battler.name).width
    nameOffset = 0
    nameOffset = nameWidth-116 if nameWidth>116
    textPos.push([@battler.name,50-nameOffset,4,false,NAME_BASE_COLOR,NAME_SHADOW_COLOR])
    # Draw Pokémon's gender symbol
    case @battler.displayGender
    when 0   # Male
      #textPos.push([_INTL("♂"),@spriteBaseX+nameWidth+14,6,false,MALE_BASE_COLOR,MALE_SHADOW_COLOR])
      imagePos.push(["Graphics/Pictures/Battle/MaleIcon",52-nameOffset+nameWidth,12])
    when 1   # Female
      #textPos.push([_INTL("♀"),@spriteBaseX+nameWidth+14,6,false,FEMALE_BASE_COLOR,FEMALE_SHADOW_COLOR])
      imagePos.push(["Graphics/Pictures/Battle/FemaleIcon",52-nameOffset+nameWidth,12])
    end
    pbDrawTextPositions(self.bitmap,textPos)
    # Draw Pokémon's level
    if @battler.level >= 100
      imagePos.push(["Graphics/Pictures/Battle/overlay_lv",198,10])
      pbDrawNumber(@battler.level,self.bitmap,216,10)
    elsif @battler.level < 10
      imagePos.push(["Graphics/Pictures/Battle/overlay_lv",218,10])
      pbDrawNumber(@battler.level,self.bitmap,236,10)
    else
      imagePos.push(["Graphics/Pictures/Battle/overlay_lv",208,10])
      pbDrawNumber(@battler.level,self.bitmap,226,10)
    end
    # Draw shiny icon
    if @battler.shiny?
      #shinyX = (@battler.opposes?(0)) ? 206 : -6   # Foe's/player's
      imagePos.push(["Graphics/Pictures/shiny",44,32])
    end
    # Draw Mega Evolution/Primal Reversion icon
    if @battler.mega?
      imagePos.push(["Graphics/Pictures/Battle/icon_mega",@spriteBaseX+8,34])
    elsif @battler.primal?
      primalX = (@battler.opposes?) ? 208 : -28   # Foe's/player's
      if isConst?(@battler.pokemon.species,PBSpecies,:KYOGRE)
        imagePos.push(["Graphics/Pictures/Battle/icon_primal_Kyogre",@spriteBaseX+primalX,4])
      elsif isConst?(@battler.pokemon.species,PBSpecies,:GROUDON)
        imagePos.push(["Graphics/Pictures/Battle/icon_primal_Groudon",@spriteBaseX+primalX,4])
      end
    end
    # Draw owned icon (foe Pokémon only)
    if @battler.owned? && @battler.opposes?(0) && @battler.status==0 #Dont draw if they have a status
      imagePos.push(["Graphics/Pictures/Battle/icon_own",@spriteBaseX+80,34])
    end
    # Draw status icon
    if @battler.status>0
      s = @battler.status
      s = 6 if s==PBStatuses::POISON && @battler.statusCount>0   # Badly poisoned
      imagePos.push(["Graphics/Pictures/Battle/icon_statuses",66,34,
         0,(s-1)*STATUS_ICON_HEIGHT,-1,STATUS_ICON_HEIGHT])
    end
    pbDrawImagePositions(self.bitmap,imagePos)
    refreshHP
    refreshExp
  end

  def refreshHP
    @hpNumbers.bitmap.clear
    return if !@battler.pokemon
    # Show HP numbers
    if @showHP
      pbDrawNumber(self.hp,@hpNumbers.bitmap,54,2,1)
      pbDrawNumber(-1,@hpNumbers.bitmap,54,2)   # / char
      pbDrawNumber(@battler.totalhp,@hpNumbers.bitmap,68,2)
    end
    # Resize HP bar
    w = 0
    if self.hp>0
      w = @hpBarBitmap.width.to_f*self.hp/@battler.totalhp
      w = 1 if w<1
      # NOTE: The line below snaps the bar's width to the nearest 2 pixels, to
      #       fit in with the rest of the graphics which are doubled in size.
      w = ((w/2.0).round)*2
    end
    @hpBar.src_rect.width = w
    hpColor = 0                                  # Green bar
    hpColor = 1 if self.hp<=@battler.totalhp/2   # Yellow bar
    hpColor = 2 if self.hp<=@battler.totalhp/4   # Red bar
    @hpBar.src_rect.y = hpColor*@hpBarBitmap.height/3
  end

  def refreshExp
    return if !@showExp
    w = self.expFraction*@expBarBitmap.width
    # NOTE: The line below snaps the bar's width to the nearest 2 pixels, to
    #       fit in with the rest of the graphics which are doubled in size.
    w = ((w/2).round)*2
    @expBar.src_rect.width = w
  end

  def updateHPAnimation
    return if !@animatingHP
    if @currentHP<@endHP      # Gaining HP
      @currentHP += @hpIncPerFrame
      @currentHP = @endHP if @currentHP>=@endHP
    elsif @currentHP>@endHP   # Losing HP
      @currentHP -= @hpIncPerFrame
      @currentHP = @endHP if @currentHP<=@endHP
    end
    # Refresh the HP bar/numbers
    refreshHP
    @animatingHP = false if @currentHP==@endHP
  end

  def updateExpAnimation
    return if !@animatingExp
    if !@showExp   # Not showing the Exp bar, no need to waste time animating it
      @currentExp = @endExp
      @animatingExp = false
      return
    end
    if @currentExp<@endExp   # Gaining Exp
      @currentExp += @expIncPerFrame
      @currentExp = @endExp if @currentExp>=@endExp
    elsif @currentExp>@endExp   # Losing Exp
      @currentExp -= @expIncPerFrame
      @currentExp = @endExp if @currentExp<=@endExp
    end
    # Refresh the Exp bar
    refreshExp
    return if @currentExp!=@endExp   # Exp bar still has more to animate
    # Exp bar is completely filled, level up with a flash and sound effect
    if @currentExp>=@rangeExp
      if @expFlash==0
        pbSEStop
        @expFlash = Graphics.frame_rate/5
        pbSEPlay("Pkmn exp full")
        self.flash(Color.new(64,200,248,192),@expFlash)
        for i in @sprites
          i[1].flash(Color.new(64,200,248,192),@expFlash) if !i[1].disposed?
        end
      else
        @expFlash -= 1
        @animatingExp = false if @expFlash==0
      end
    else
      pbSEStop
      # Exp bar has finished filling, end animation
      @animatingExp = false
    end
  end

  QUARTER_ANIM_PERIOD = Graphics.frame_rate*3/20

  def updatePositions(frameCounter)
    self.x = @spriteX
    self.y = @spriteY
    # Data box bobbing while Pokémon is selected
    #thundaga remove box bobbing
    #if @selected==1 || @selected==2   # Choosing commands/targeted or damaged
    #  case (frameCounter/QUARTER_ANIM_PERIOD).floor
    #  when 1; self.y = @spriteY-2
    #  when 3; self.y = @spriteY+2
    #  end
    #end
  end

  def update(frameCounter=0)
    super()
    # Animate HP bar
    updateHPAnimation
    # Animate Exp bar
    updateExpAnimation
    # Update coordinates of the data box
    updatePositions(frameCounter)
    pbUpdateSpriteHash(@sprites)
  end
end



#===============================================================================
# Splash bar to announce a triggered ability
#===============================================================================
class AbilitySplashBar < SpriteWrapper
  attr_reader :battler

  TEXT_BASE_COLOR   = Color.new(64,64,64)
  TEXT_SHADOW_COLOR = Color.new(216,208,176)

  def initialize(side,viewport=nil)
    super(viewport)
    @side    = side
    @battler = nil
    # Create sprite wrapper that displays background graphic
    @bgBitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/Battle/ability_bar"))
    @bgSprite = SpriteWrapper.new(viewport)
    @bgSprite.bitmap = @bgBitmap.bitmap
    @bgSprite.src_rect.y      = (side==0) ? 0 : @bgBitmap.height/2
    @bgSprite.src_rect.height = @bgBitmap.height/2
    # Create bitmap that displays the text
    @contents = BitmapWrapper.new(@bgBitmap.width,@bgBitmap.height/2)
    self.bitmap = @contents
    pbSetSmallFont(self.bitmap)
    # Position the bar
    self.x       = (side==0) ? -Graphics.width/2 : Graphics.width
    self.y       = (side==0) ? 180 : 80 #abilityheight thundaga
    self.z       = 120
    self.visible = false
  end

  def dispose
    @bgSprite.dispose
    @bgBitmap.dispose
    @contents.dispose
    super
  end

  def x=(value)
    super
    @bgSprite.x = value
  end

  def y=(value)
    super
    @bgSprite.y = value
  end

  def z=(value)
    super
    @bgSprite.z = value-1
  end

  def opacity=(value)
    super
    @bgSprite.opacity = value
  end

  def visible=(value)
    super
    @bgSprite.visible = value
  end

  def color=(value)
    super
    @bgSprite.color = value
  end

  def battler=(value)
    @battler = value
    refresh
  end

  def refresh
    self.bitmap.clear
    return if !@battler
    textPos = []
    textX = (@side==0) ? 15 : self.bitmap.width-12
    # Draw Pokémon's name
    textPos.push([_INTL("{1}'s",@battler.name),textX,3,@side==1,
       Color.new(248,248,248),Color.new(123,115,131)])
    # Draw Pokémon's ability
    textPos.push([@battler.abilityName,textX,31,@side==1,
       TEXT_BASE_COLOR,TEXT_SHADOW_COLOR])
    pbDrawTextPositions(self.bitmap,textPos)
  end

  def update
    super
    @bgSprite.update
  end
end



#===============================================================================
# Pokémon sprite (used in battle)
#===============================================================================
class PokemonBattlerSprite < RPG::Sprite
  attr_reader   :pkmn
  attr_accessor :index
  attr_accessor :selected
  attr_reader   :sideSize

  def initialize(viewport,sideSize,index,battleAnimations)
    super(viewport)
    @pkmn             = nil
    @sideSize         = sideSize
    @index            = index
    @battleAnimations = battleAnimations
    # @selected: 0 = not selected, 1 = choosing action bobbing for this Pokémon,
    #            2 = flashing when targeted
    @selected         = 0
    @frame            = 0
    @updating         = false
    @spriteX          = 0   # Actual x coordinate
    @spriteY          = 0   # Actual y coordinate
    @spriteXExtra     = 0   # Offset due to "bobbing" animation
    @spriteYExtra     = 0   # Offset due to "bobbing" animation
    @_iconBitmap      = nil
    self.visible      = false
  end

  def dispose
    @_iconBitmap.dispose if @_iconBitmap
    @_iconBitmap = nil
    self.bitmap = nil if !self.disposed?
    super
  end

  def x; return @spriteX; end
  def y; return @spriteY; end

  def x=(value)
    @spriteX = value
    super(value+@spriteXExtra)
  end

  def y=(value)
    @spriteY = value
    super(value+@spriteYExtra)
  end

  def width;  return (self.bitmap) ? self.bitmap.width : 0;  end
  def height; return (self.bitmap) ? self.bitmap.height : 0; end

  def visible=(value)
    @spriteVisible = value if !@updating   # For selection/targeting flashing
    super
  end

  # Set sprite's origin to bottom middle
  def pbSetOrigin
    return if !@_iconBitmap
    self.ox = @_iconBitmap.width/2
    self.oy = @_iconBitmap.height
  end

  def pbSetPosition
    return if !@_iconBitmap
    pbSetOrigin
    if (@index%2)==0
      self.z = 50+5*@index/2
    else
      self.z = 50-5*(@index+1)/2
    end
    # Set original position
    p = PokeBattle_SceneConstants.pbBattlerPosition(@index,@sideSize)
    @spriteX = p[0]
    @spriteY = p[1]
    # Apply metrics
    pbApplyBattlerMetricsToSprite(self,@index,@pkmn.fSpecies)
  end

  def setPokemonBitmap(pkmn,back=false)
    @pkmn = pkmn
    @_iconBitmap.dispose if @_iconBitmap
    @_iconBitmap = pbLoadPokemonBitmap(@pkmn,back)
    self.bitmap = (@_iconBitmap) ? @_iconBitmap.bitmap : nil
    pbSetPosition
  end

  # This method plays the battle entrance animation of a Pokémon. By default
  # this is just playing the Pokémon's cry, but you can expand on it. The
  # recommendation is to create a PictureEx animation and push it into the
  # @battleAnimations array.
  def pbPlayIntroAnimation(pictureEx=nil)
    return if !@pkmn
    cry = pbCryFile(@pkmn)
    pbSEPlay(cry) if cry
  end

  QUARTER_ANIM_PERIOD = Graphics.frame_rate*3/20
  SIXTH_ANIM_PERIOD   = Graphics.frame_rate*2/20

  def update(frameCounter=0)
    return if !@_iconBitmap
    @updating = true
    # Update bitmap
    @_iconBitmap.update
    self.bitmap = @_iconBitmap.bitmap
    # Pokémon sprite bobbing while Pokémon is selected
    @spriteYExtra = 0
    if @selected==1    # When choosing commands for this Pokémon
      case (frameCounter/QUARTER_ANIM_PERIOD).floor
      when 1; @spriteYExtra = 2
      when 3; @spriteYExtra = -2
      end
    end
    self.x       = self.x
    self.y       = self.y
    self.visible = @spriteVisible
    # Pokémon sprite blinking when targeted
    if @selected==2 && @spriteVisible
      case (frameCounter/SIXTH_ANIM_PERIOD).floor
      when 2, 5; self.visible = false
      else;      self.visible = true
      end
    end
    @updating = false
  end
end



#===============================================================================
# Shadow sprite for Pokémon (used in battle)
#===============================================================================
class PokemonBattlerShadowSprite < RPG::Sprite
  attr_reader   :pkmn
  attr_accessor :index
  attr_accessor :selected

  def initialize(viewport,sideSize,index)
    super(viewport)
    @pkmn        = nil
    @sideSize    = sideSize
    @index       = index
    @_iconBitmap = nil
    self.visible = false
  end

  def dispose
    @_iconBitmap.dispose if @_iconBitmap
    @_iconBitmap = nil
    self.bitmap = nil if !self.disposed?
    super
  end

  def width;  return (self.bitmap) ? self.bitmap.width : 0;  end
  def height; return (self.bitmap) ? self.bitmap.height : 0; end

  # Set sprite's origin to centre
  def pbSetOrigin
    return if !@_iconBitmap
    self.ox = @_iconBitmap.width/2
    self.oy = @_iconBitmap.height/2
  end

  def pbSetPosition
    return if !@_iconBitmap
    pbSetOrigin
    self.z = 3
    # Set original position
    p = PokeBattle_SceneConstants.pbBattlerPosition(@index,@sideSize)
    self.x = p[0]
    self.y = p[1]
    # Apply metrics
    pbApplyBattlerMetricsToSprite(self,@index,@pkmn.fSpecies,true)
  end

  def setPokemonBitmap(pkmn)
    @pkmn = pkmn
    @_iconBitmap.dispose if @_iconBitmap
    @_iconBitmap = pbLoadPokemonShadowBitmap(@pkmn)
    self.bitmap = (@_iconBitmap) ? @_iconBitmap.bitmap : nil
    pbSetPosition
  end

  def update(frameCounter=0)
    return if !@_iconBitmap
    # Update bitmap
    @_iconBitmap.update
    self.bitmap = @_iconBitmap.bitmap
  end
end
