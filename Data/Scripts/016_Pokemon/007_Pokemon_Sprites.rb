#===============================================================================
# Pokémon sprite (used out of battle)
#===============================================================================
class PokemonSprite < SpriteWrapper
  def initialize(viewport=nil)
    super(viewport)
    @_iconbitmap = nil
  end

  def dispose
    @_iconbitmap.dispose if @_iconbitmap
    @_iconbitmap = nil
    self.bitmap = nil if !self.disposed?
    super
  end

  def clearBitmap
    @_iconbitmap.dispose if @_iconbitmap
    @_iconbitmap = nil
    self.bitmap = nil
  end

  def setOffset(offset=PictureOrigin::Center)
    @offset = offset
    changeOrigin
  end

  def changeOrigin
    return if !self.bitmap
    @offset = PictureOrigin::Center if !@offset
    case @offset
    when PictureOrigin::TopLeft, PictureOrigin::Left, PictureOrigin::BottomLeft
      self.ox = 0
    when PictureOrigin::Top, PictureOrigin::Center, PictureOrigin::Bottom
      self.ox = self.bitmap.width/2
    when PictureOrigin::TopRight, PictureOrigin::Right, PictureOrigin::BottomRight
      self.ox = self.bitmap.width
    end
    case @offset
    when PictureOrigin::TopLeft, PictureOrigin::Top, PictureOrigin::TopRight
      self.oy = 0
    when PictureOrigin::Left, PictureOrigin::Center, PictureOrigin::Right
      self.oy = self.bitmap.height/2
    when PictureOrigin::BottomLeft, PictureOrigin::Bottom, PictureOrigin::BottomRight
      self.oy = self.bitmap.height
    end
  end

  def setPokemonBitmap(pokemon,back=false)
    @_iconbitmap.dispose if @_iconbitmap
    @_iconbitmap = (pokemon) ? pbLoadPokemonBitmap(pokemon,back) : nil
    self.bitmap = (@_iconbitmap) ? @_iconbitmap.bitmap : nil
    self.color = Color.new(0,0,0,0)
    changeOrigin
  end

  def setPokemonBitmapSpecies(pokemon,species,back=false)
    @_iconbitmap.dispose if @_iconbitmap
    @_iconbitmap = (pokemon) ? pbLoadPokemonBitmapSpecies(pokemon,species,back) : nil
    self.bitmap = (@_iconbitmap) ? @_iconbitmap.bitmap : nil
    changeOrigin
  end

  def setSpeciesBitmap(species,female=false,form=0,shiny=false,shadow=false,back=false,egg=false)
    @_iconbitmap.dispose if @_iconbitmap
    @_iconbitmap = pbLoadSpeciesBitmap(species,female,form,shiny,shadow,back,egg)
    self.bitmap = (@_iconbitmap) ? @_iconbitmap.bitmap : nil
    changeOrigin
  end

  def update
    super
    if @_iconbitmap
      @_iconbitmap.update
      self.bitmap = @_iconbitmap.bitmap
    end
  end
end



#===============================================================================
# Pokémon icon (for defined Pokémon)
#===============================================================================
class PokemonIconSprite < SpriteWrapper
  attr_accessor :selected
  attr_reader   :pokemon
  attr_reader   :filename

  def initialize(pokemon,viewport=nil)
    super(viewport)
    @selected     = false
    @numFrames    = 0
    @currentFrame = 0
    @counter      = 0
    self.pokemon  = pokemon
    @logical_x    = 0   # Actual x coordinate
    @logical_y    = 0   # Actual y coordinate
    @adjusted_x   = 0   # Offset due to "jumping" animation in party screen
    @adjusted_y   = 0   # Offset due to "jumping" animation in party screen
    @shinyicon    = RPG::Cache.load_bitmap("Graphics/Pictures/shiny")
  end

  def dispose
    @animBitmap.dispose if @animBitmap
    @shinyicon.dispose if @shinyicon
    super
  end

  def x; return @logical_x; end
  def y; return @logical_y; end

  def x=(value)
    @logical_x = value
    super(@logical_x+@adjusted_x)
  end

  def y=(value)
    @logical_y = value
    super(@logical_y+@adjusted_y)
  end

  def pokemon=(value)
    @pokemon = value
    @animBitmap.dispose if @animBitmap
    @animBitmap = nil
    @shinyicon  = RPG::Cache.load_bitmap("Graphics/Pictures/shiny") if !@shinyicon
    if !@pokemon
      self.bitmap = nil
      @currentFrame = 0
      @counter = 0
      return
    end
    @filename = pbPokemonIconFile(value)
    @animBitmap = AnimatedBitmap.new(@filename)
    self.bitmap = @animBitmap.bitmap.clone
    self.src_rect.width  = @animBitmap.height
    self.src_rect.height = @animBitmap.height
    @numFrames    = @animBitmap.width/@animBitmap.height
    @currentFrame = 0 if @currentFrame>=@numFrames
    if @pokemon.shiny? && self.bitmap
      pbCopyBitmap(self.bitmap,@shinyicon,(self.bitmap.width/2 - 18),self.bitmap.height - 18)
      pbCopyBitmap(self.bitmap,@shinyicon,(self.bitmap.width - 18),self.bitmap.height - 18)
    end
    changeOrigin
  end

  def setOffset(offset=PictureOrigin::Center)
    @offset = offset
    changeOrigin
  end

  def changeOrigin
    return if !self.bitmap
    @offset = PictureOrigin::TopLeft if !@offset
    case @offset
    when PictureOrigin::TopLeft, PictureOrigin::Left, PictureOrigin::BottomLeft
      self.ox = 0
    when PictureOrigin::Top, PictureOrigin::Center, PictureOrigin::Bottom
      self.ox = self.src_rect.width/2
    when PictureOrigin::TopRight, PictureOrigin::Right, PictureOrigin::BottomRight
      self.ox = self.src_rect.width
    end
    case @offset
    when PictureOrigin::TopLeft, PictureOrigin::Top, PictureOrigin::TopRight
      self.oy = 0
    when PictureOrigin::Left, PictureOrigin::Center, PictureOrigin::Right
      # NOTE: This assumes the top quarter of the icon is blank, so oy is placed
      #       in the middle of the lower three quarters of the image.
      self.oy = self.src_rect.height*5/8
    when PictureOrigin::BottomLeft, PictureOrigin::Bottom, PictureOrigin::BottomRight
      self.oy = self.src_rect.height
    end
  end

  # How long to show each frame of the icon for
  def counterLimit
    return 0 if @pokemon.fainted?    # Fainted - no animation
    # ret is initially the time a whole animation cycle lasts. It is divided by
    # the number of frames in that cycle at the end.
    ret = Graphics.frame_rate/4                       # Green HP - 0.25 seconds
    if @pokemon.hp<=@pokemon.totalhp/4;    ret *= 4   # Red HP - 1 second
    elsif @pokemon.hp<=@pokemon.totalhp/2; ret *= 2   # Yellow HP - 0.5 seconds
    end
    ret /= @numFrames
    ret = 1 if ret<1
    return ret
  end

  def update
    return if !@animBitmap
    super
    # Update animation
    cl = self.counterLimit
    if cl==0
      @currentFrame = 0
    else
      @counter += 1
      if @counter>=cl
        @currentFrame = (@currentFrame+1)%@numFrames
        @counter = 0
      end
    end
    self.src_rect.x = self.src_rect.width*@currentFrame
    # Update "jumping" animation (used in party screen)
  #  if @selected
  #    @adjusted_x = 4
  #    @adjusted_y = (@currentFrame>=@numFrames/2) ? -2 : 6
  #  else
      @adjusted_x = 0
      @adjusted_y = 0
  #  end
    self.x = self.x
    self.y = self.y
  end
end



#===============================================================================
# Pokémon icon (for species)
#===============================================================================
class PokemonSpeciesIconSprite < SpriteWrapper
  attr_reader :species
  attr_reader :gender
  attr_reader :form
  attr_reader :shiny

  def initialize(species,viewport=nil)
    super(viewport)
    @species      = species
    @gender       = 0
    @form         = 0
    @shiny        = false
    @numFrames    = 0
    @currentFrame = 0
    @counter      = 0
    @shinyicon    = RPG::Cache.load_bitmap("Graphics/Pictures/shiny")
    refresh
  end

  def dispose
    @animBitmap.dispose if @animBitmap
    @shinyicon.dispose if @shinyicon
    super
  end

  def species=(value)
    @species = value
    refresh
  end

  def gender=(value)
    @gender = value
    refresh
  end

  def form=(value)
    @form = value
    refresh
  end

  def shiny=(value)
    @shiny = value
    refresh
  end

  def pbSetParams(species,gender,form,shiny=false)
    @species = species
    @gender  = gender
    @form    = form
    @shiny   = shiny
    refresh
  end

  def setOffset(offset=PictureOrigin::Center)
    @offset = offset
    changeOrigin
  end

  def changeOrigin
    return if !self.bitmap
    @offset = PictureOrigin::TopLeft if !@offset
    case @offset
    when PictureOrigin::TopLeft, PictureOrigin::Left, PictureOrigin::BottomLeft
      self.ox = 0
    when PictureOrigin::Top, PictureOrigin::Center, PictureOrigin::Bottom
      self.ox = self.src_rect.width/2
    when PictureOrigin::TopRight, PictureOrigin::Right, PictureOrigin::BottomRight
      self.ox = self.src_rect.width
    end
    case @offset
    when PictureOrigin::TopLeft, PictureOrigin::Top, PictureOrigin::TopRight
      self.oy = 0
    when PictureOrigin::Left, PictureOrigin::Center, PictureOrigin::Right
      # NOTE: This assumes the top quarter of the icon is blank, so oy is placed
      #       in the middle of the lower three quarters of the image.
      self.oy = self.src_rect.height*5/8
    when PictureOrigin::BottomLeft, PictureOrigin::Bottom, PictureOrigin::BottomRight
      self.oy = self.src_rect.height
    end
  end

  # How long to show each frame of the icon for
  def counterLimit
    # ret is initially the time a whole animation cycle lasts. It is divided by
    # the number of frames in that cycle at the end.
    ret = Graphics.frame_rate/4   # 0.25 seconds
    ret /= @numFrames
    ret = 1 if ret<1
    return ret
  end

  def refresh
    @animBitmap.dispose if @animBitmap
    @animBitmap = nil
    bitmapFileName = pbCheckPokemonIconFiles([@species,(@gender==1),@shiny,@form,false])
    @animBitmap = AnimatedBitmap.new(bitmapFileName)
    self.bitmap = @animBitmap.bitmap.clone
    self.src_rect.width  = @animBitmap.height
    self.src_rect.height = @animBitmap.height
    @numFrames = @animBitmap.width/@animBitmap.height
    @currentFrame = 0 if @currentFrame>=@numFrames
    if @shiny && @animBitmap
      pbCopyBitmap(self.bitmap,@shinyicon,(self.bitmap.width/2 - 18),self.bitmap.height - 18)
      pbCopyBitmap(self.bitmap,@shinyicon,(self.bitmap.width - 18),self.bitmap.height - 18)
    end
    changeOrigin
  end

  def update
    return if !@animBitmap
    super
    # Update animation
    @counter += 1
    if @counter>=self.counterLimit
      @currentFrame = (@currentFrame+1)%@numFrames
      @counter = 0
    end
    self.src_rect.x = self.src_rect.width*@currentFrame
  end
end



#===============================================================================
# Sprite position adjustments
#===============================================================================
def pbApplyBattlerMetricsToSprite(sprite,index,species,shadow=false,metrics=nil)
  metrics = pbLoadSpeciesMetrics if !metrics
  if shadow
    if (index&1)==1   # Foe Pokémon
      sprite.x += (metrics[MetricBattlerShadowX][species] || 0)*2
    end
  else
    if (index&1)==0   # Player's Pokémon
      sprite.x += (metrics[MetricBattlerPlayerX][species] || 0)*2
      sprite.y += (metrics[MetricBattlerPlayerY][species] || 0)*2
    else              # Foe Pokémon
      sprite.x += (metrics[MetricBattlerEnemyX][species] || 0)*2
      sprite.y += (metrics[MetricBattlerEnemyY][species] || 0)*2
      sprite.y -= (metrics[MetricBattlerAltitude][species] || 0)*2
    end
  end
end

# NOTE: The species parameter here is typically the fSpecies, which contains
#       information about both the species and the form.
def showShadow?(species)
  return true
#  metrics = pbLoadSpeciesMetrics
#  return (metrics[MetricBattlerAltitude][species] || 0)>0
end
