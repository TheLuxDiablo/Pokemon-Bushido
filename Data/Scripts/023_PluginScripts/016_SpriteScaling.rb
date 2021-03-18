FRONT_SCALE = 2
BACK_SCALE = 3

class EBSBitmapWrapper
  attr_reader :width
  attr_reader :height
  attr_reader :totalFrames
  attr_reader :animationFrames
  attr_reader :currentIndex
  attr_accessor :scale
  attr_reader :actualBitmap

  @@disableBitmapAnimation = false

  def initialize(file,scale=2)
    raise "filename is nil" if file==nil
    raise ".gif files are not supported!" if File.extname(file)==".gif"

    @scale = scale
    @width = 0
    @height = 0
    @frame = 0
    @frames = 2
    @direction = +1
    @animationFinish = false
    @totalFrames = 0
    @currentIndex = 0
    @speed = 1
      # 0 - not moving at all
      # 1 - normal speed
      # 2 - medium speed
      # 3 - slow speed
    bmp = BitmapCache.load_bitmap(file)
    @bitmapFile=Bitmap.new(bmp.width,bmp.height); @bitmapFile.blt(0,0,bmp,Rect.new(0,0,bmp.width,bmp.height))
    bmp.dispose
    # initializes full Pokemon bitmap
    @bitmap=Bitmap.new(@bitmapFile.width,@bitmapFile.height)
    @bitmap.blt(0,0,@bitmapFile,Rect.new(0,0,@bitmapFile.width,@bitmapFile.height))
    @width=@bitmapFile.height*@scale
    @height=@bitmap.height*@scale

    @totalFrames=@bitmap.width/@bitmap.height
    @animationFrames=@totalFrames*@frames
    # calculates total number of frames
    @loop_points=[0,@totalFrames]
    # first value is start, second is end

    @actualBitmap=Bitmap.new(@width,@height)
    @actualBitmap.clear
    @actualBitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmap,Rect.new(@currentIndex*(@width/@scale),0,@width/@scale,@height/@scale))
  end
  alias initialize_elite initialize unless self.method_defined?(:initialize_elite)

  def length; @totalFrames; end
  def disposed?; @actualBitmap.disposed?; end
  def dispose
    @bitmap.dispose
  @bitmapFile.dispose
    @actualBitmap.dispose
  end
  def copy; @actualBitmap.clone; end
  def bitmap; @actualBitmap; end
  def bitmap=(val); @actualBitmap=val; end
  def each; end
  def alterBitmap(index); return @strip[index]; end

  def prepareStrip
    @strip=[]
    for i in 0...@totalFrames
      bitmap=Bitmap.new(@width,@height)
      bitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmapFile,Rect.new((@width/@scale)*i,0,@width/@scale,@height/@scale))
      @strip.push(bitmap)
    end
  end
  def compileStrip
    @bitmap.clear
    for i in 0...@strip.length
      @bitmap.stretch_blt(Rect.new((@width/@scale)*i,0,@width/@scale,@height/@scale),@strip[i],Rect.new(0,0,@width,@height))
    end
  end

  def reverse
    if @direction  >  0
      @direction=-1
    elsif @direction < 0
      @direction=+1
    end
  end

  def setLoop(start, finish)
    @loop_points=[start,finish]
  end

  def setSpeed(value)
    @speed=value
  end

  def toFrame(frame)
    if frame.is_a?(String)
      if frame=="last"
        frame=@totalFrames-1
      else
        frame=0
      end
    end
    frame=@totalFrames if frame > @totalFrames
    frame=0 if frame < 0
    @currentIndex=frame
    @actualBitmap.clear
    @actualBitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmap,Rect.new(@currentIndex*(@width/@scale),0,@width/@scale,@height/@scale))
  end

  def play
    return if @currentIndex >= @loop_points[1]-1
    self.update
  end

  def finished?
    return (@currentIndex==@totalFrames-1)
  end

  def update
  return false if @@disableBitmapAnimation
    return false if @actualBitmap.disposed?
    return false if @speed < 1
    case @speed
    # frame skip
    when 1
      @frames=2
    when 2
      @frames=4
    when 3
      @frames=5
    end
    @frame+=1
    if @frame >= @frames
      # processes animation speed
      @currentIndex+=@direction
      @currentIndex=@loop_points[0] if @currentIndex >=@loop_points[1]
      @currentIndex=@loop_points[1]-1 if @currentIndex < @loop_points[0]
      @frame=0
    end
    @actualBitmap.clear
    @actualBitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmap,Rect.new(@currentIndex*(@width/@scale),0,@width/@scale,@height/@scale))
    # updates the actual bitmap
  end
  alias update_elite update unless self.method_defined?(:update_elite)

  # returns bitmap to original state
  def deanimate
    @frame=0
    @currentIndex=0
    @actualBitmap.clear
    @actualBitmap.stretch_blt(Rect.new(0,0,@width,@height),@bitmap,Rect.new(@currentIndex*(@width/@scale),0,@width/@scale,@height/@scale))
  end
end
#===============================================================================
#  New Sprite class to utilize the animated bitmap wrappers
#===============================================================================
class EBSBitmapSprite < Sprite

  def setBitmap(file,scale=FRONT_SCALE)
    @ebsBitmap = EBSBitmapWrapper.new(file,scale)
    self.bitmap = @ebsBitmap.bitmap.clone
  end

  def setSpeciesBitmap(species,female=false,form=0,shiny=false,shadow=false,back=false,egg=false)
    if species > 0
      pokemon = PokeBattle_Pokemon.new(species,5)
      @ebsBitmap = pbLoadPokemonBitmapSpecies(pokemon, species, back)
    else
      @ebsBitmap = EBSBitmapWrapper.new("Graphics/Battlers/000")
    end
    self.bitmap = @ebsBitmap.bitmap.clone
  end

  def play
    @ebsBitmap.play
    self.bitmap = @ebsBitmap.bitmap.clone
  end

  def finished?; return @ebsBitmap.finished?; end
  def ebsBitmap; return @ebsBitmap; end

  alias update_wrapper update unless self.method_defined?(:update_wrapper)
  def update
    update_wrapper
    return if @ebsBitmap.nil?
    @ebsBitmap.update
    self.bitmap = @ebsBitmap.bitmap.clone
  end

end

class AnimatedSpriteWrapper < EBSBitmapSprite; end
#===============================================================================
#  Aliases old PokemonBitmap generating functions and creates new ones,
#  utilizing the new BitmapWrapper
#===============================================================================
if !defined?(EliteBattle)
  def pbLoadPokemonBitmap(pokemon, back=false,scale=FRONT_SCALE)
    return pbLoadPokemonBitmapSpecies(pokemon,pokemon.species,back,scale)
  end

  def pbLoadPokemonBitmapSpecies(pokemon, species, back=false, scale=FRONT_SCALE)
    ret=nil
    if pokemon.isEgg?
      bitmapFileName=sprintf("Graphics/Battlers/%03degg",species) rescue nil
      if !pbResolveBitmap(bitmapFileName)
        bitmapFileName=sprintf("Graphics/Battlers/egg")
      end
      bitmapFileName=pbResolveBitmap(bitmapFileName)
    else
      bitmapFileName=pbCheckPokemonBitmapFiles([species,back,
                                                (pokemon.isFemale?),
                                                pokemon.isShiny?,
                                                (pokemon.form rescue 0),
                                                (pokemon.isShadow? rescue false)])
    end
    raise missingPokeSpriteError(pokemon,back) if bitmapFileName.nil?
    scale = BACK_SCALE if back
    ebsBitmap=EBSBitmapWrapper.new(bitmapFileName,scale) if bitmapFileName
    ret = ebsBitmap if bitmapFileName
    # Full compatibility with the alterBitmap methods is maintained
    # but unless the alterBitmap method gets rewritten and sprite animations get
    # hardcoded in the system, the bitmap alterations will not function properly
    # as they will not account for the sprite animation itself

    # alterBitmap methods for static sprites will work just fine
    alterBitmap=(MultipleForms.getFunction(species,"alterBitmap") rescue nil) if !pokemon.isEgg? && ebsBitmap && ebsBitmap.totalFrames==1 # remove this totalFrames clause to allow for dynamic sprites too
    if bitmapFileName && alterBitmap
      ebsBitmap.prepareStrip
      for i in 0...ebsBitmap.totalFrames
        alterBitmap.call(pokemon,ebsBitmap.alterBitmap(i))
      end
      ebsBitmap.compileStrip
      ret=ebsBitmap
    end
    return ret
  end

  def pbLoadSpeciesBitmap(species,female=false,form=0,shiny=false,shadow=false,back=false,egg=false,scale=FRONT_SCALE)
    ret = nil
    if egg
      bitmapFileName=sprintf("Graphics/Battlers/%03degg",species) rescue nil
      if !pbResolveBitmap(bitmapFileName)
        bitmapFileName = sprintf("Graphics/Battlers/egg")
      end
      bitmapFileName=pbResolveBitmap(bitmapFileName)
    else
      bitmapFileName = pbCheckPokemonBitmapFiles([species,back,female,shiny,form,shadow])
    end
    if bitmapFileName
      scale = BACK_SCALE if back
      ret = EBSBitmapWrapper.new(bitmapFileName,scale)
    end
    return ret
  end

  class PokemonPokedexInfo_Scene
    def pbUpdateDummyPokemon
      @species = @dexlist[@index][0]
      @gender  = ($Trainer.formlastseen[@species][0] rescue 0)
      @form    = ($Trainer.formlastseen[@species][1] rescue 0)
      @sprites["infosprite"].setSpeciesBitmap(@species,(@gender==1),@form)
      if @sprites["formfront"]
        @sprites["formfront"].setSpeciesBitmap(@species,(@gender==1),@form)
      end
      if @sprites["formback"]
        @sprites["formback"].setSpeciesBitmap(@species,(@gender==1),@form,false,false,true)
        @sprites["formback"].x = 380
        @sprites["formback"].y = 100
        fSpecies = pbGetFSpeciesFromForm(@species,@form)
        @sprites["formback"].y += (pbLoadSpeciesMetrics[MetricBattlerPlayerY][fSpecies] || 0)*2
        @sprites["formback"].zoom_x = 0.66 #(FRONT_SCALE/BACK_SCALE) if BACK_SCALE > FRONT_SCALE
        @sprites["formback"].zoom_y = 0.66 #(FRONT_SCALE/BACK_SCALE) if BACK_SCALE > FRONT_SCALE
      end
      if @sprites["formicon"]
        @sprites["formicon"].pbSetParams(@species,@gender,@form)
      end
    end
  end

  class PokeBattle_Scene
    def pbCreateTrainerFrontSprite(idxTrainer,trainerType,numTrainers=1)
      trainerFile = pbTrainerSpriteFile(trainerType)
      spriteX, spriteY = PokeBattle_SceneConstants.pbTrainerPosition(1,idxTrainer,numTrainers)
      trainer = pbAddSprite("trainer_#{idxTrainer+1}",spriteX,spriteY,trainerFile,@viewport)
      return if !trainer.bitmap
      # Alter position of sprite
      trainer.z  = 7+idxTrainer
      trainer.ox = trainer.src_rect.width/2
      trainer.oy = trainer.bitmap.height
      trainer.zoom_x = FRONT_SCALE if trainer.bitmap.height <= 96
      trainer.zoom_y = FRONT_SCALE if trainer.bitmap.height <= 96
    end
  end

  def findTop(bitmap)
    return 0 if !bitmap
    for i in 1..bitmap.height
      for j in 0..bitmap.width-1
        return i if bitmap.get_pixel(j,bitmap.height-i).alpha>0
      end
    end
    return 0
  end

  class SpritePositioner
    def pbAutoPosition
      oldmetric1 = (@metrics[MetricBattlerPlayerY][@species] || 0)
      oldmetric3 = (@metrics[MetricBattlerEnemyY][@species] || 0)
      oldmetric4 = (@metrics[MetricBattlerAltitude][@species] || 0)
      bitmap1 = @sprites["pokemon_0"].bitmap
      bitmap2 = @sprites["pokemon_1"].bitmap
      bottom = findBottom(bitmap1)
      top = findTop(bitmap1)
      actualHeight = bottom - top
      value = actualHeight < (bitmap1.height/2) ? 5 : 3
      newmetric1 = (bitmap1.height - bottom + (bottom/value) + 1)/2
      newmetric3 = (bitmap2.height-(findBottom(bitmap2)+1))/2
      newmetric3 += 4   # Just because
      if newmetric1!=oldmetric1 || newmetric3!=oldmetric3 || oldmetric4!=0
        @metrics[MetricBattlerPlayerY][@species]  = newmetric1
        @metrics[MetricBattlerEnemyY][@species]   = newmetric3
        @metrics[MetricBattlerAltitude][@species] = 0
        @metricsChanged = true
        refresh
      end
    end
  end

  def pbAutoPositionAll
    metrics = pbLoadSpeciesMetrics
    for i in 1..PBSpecies.maxValueF
      s = pbGetSpeciesFromFSpecies(i)
      Graphics.update if i%50==0
      bitmap1 = pbLoadSpeciesBitmap(s[0],false,s[1],false,false,true)
      bitmap2 = pbLoadSpeciesBitmap(s[0],false,s[1])
      metrics[MetricBattlerPlayerX][i]    = 0   # Player's x
      if bitmap1 && bitmap1.bitmap   # Player's y
        bottom = findBottom(bitmap1.bitmap)
        top = findTop(bitmap1.bitmap)
        actualHeight = bottom - top
        value = actualHeight < (bitmap1.bitmap.height/2) ? 5 : 3
        newmetric1 = (bitmap1.bitmap.height - bottom + (bottom/value) + 1)/2
        metrics[MetricBattlerPlayerY][i]  = newmetric1
      end
      metrics[MetricBattlerEnemyX][i]     = 0   # Foe's x
      if bitmap2 && bitmap2.bitmap   # Foe's y
        metrics[MetricBattlerEnemyY][i]   = (bitmap2.height-(findBottom(bitmap2.bitmap)+1))/2
        metrics[MetricBattlerEnemyY][i]   += 4   # Just because
      end
      metrics[MetricBattlerAltitude][i]   = 0   # Foe's altitude, not used now
      metrics[MetricBattlerShadowX][i]    = 0   # Shadow's x
      metrics[MetricBattlerShadowSize][i] = 2   # Shadow size
      bitmap1.dispose if bitmap1
      bitmap2.dispose if bitmap2
    end
    save_data(metrics,"Data/species_metrics.dat")
    $PokemonTemp.speciesMetrics = nil
    pbSavePokemonData
    pbSavePokemonFormsData
  end
end
