#===============================================================================
# Evolution animation metafiles and related methods
#===============================================================================
class SpriteMetafile
  VIEWPORT      = 0
  TONE          = 1
  SRC_RECT      = 2
  VISIBLE       = 3
  X             = 4
  Y             = 5
  Z             = 6
  OX            = 7
  OY            = 8
  ZOOM_X        = 9
  ZOOM_Y        = 10
  ANGLE         = 11
  MIRROR        = 12
  BUSH_DEPTH    = 13
  OPACITY       = 14
  BLEND_TYPE    = 15
  COLOR         = 16
  FLASHCOLOR    = 17
  FLASHDURATION = 18
  BITMAP        = 19

  def length
    return @metafile.length
  end

  def [](i)
    return @metafile[i]
  end

  def initialize(viewport=nil)
    @metafile=[]
    @values=[
       viewport,
       Tone.new(0,0,0,0),Rect.new(0,0,0,0),
       true,
       0,0,0,0,0,100,100,
       0,false,0,255,0,
       Color.new(0,0,0,0),Color.new(0,0,0,0),
       0
    ]
  end

  def disposed?
    return false
  end

  def dispose; end

  def flash(color,duration)
    if duration>0
      @values[FLASHCOLOR]=color.clone
      @values[FLASHDURATION]=duration
      @metafile.push([FLASHCOLOR,color])
      @metafile.push([FLASHDURATION,duration])
    end
  end

  def x
    return @values[X]
  end

  def x=(value)
    @values[X]=value
    @metafile.push([X,value])
  end

  def y
    return @values[Y]
  end

  def y=(value)
    @values[Y]=value
    @metafile.push([Y,value])
  end

  def bitmap
    return nil
  end

  def bitmap=(value)
    if value && !value.disposed?
      @values[SRC_RECT].set(0,0,value.width,value.height)
      @metafile.push([SRC_RECT,@values[SRC_RECT].clone])
    end
  end

  def src_rect
    return @values[SRC_RECT]
  end

  def src_rect=(value)
    @values[SRC_RECT]=value
    @metafile.push([SRC_RECT,value])
  end

  def visible
    return @values[VISIBLE]
  end

  def visible=(value)
    @values[VISIBLE]=value
    @metafile.push([VISIBLE,value])
  end

  def z
    return @values[Z]
  end

  def z=(value)
    @values[Z]=value
    @metafile.push([Z,value])
  end

  def ox
    return @values[OX]
  end

  def ox=(value)
    @values[OX]=value
    @metafile.push([OX,value])
  end

  def oy
    return @values[OY]
  end

  def oy=(value)
    @values[OY]=value
    @metafile.push([OY,value])
  end

  def zoom_x
    return @values[ZOOM_X]
  end

  def zoom_x=(value)
    @values[ZOOM_X]=value
    @metafile.push([ZOOM_X,value])
  end

  def zoom_y
    return @values[ZOOM_Y]
  end

  def zoom_y=(value)
    @values[ZOOM_Y]=value
    @metafile.push([ZOOM_Y,value])
  end

  def zoom=(value)
    @values[ZOOM_X]=value
    @metafile.push([ZOOM_X,value])
    @values[ZOOM_Y]=value
    @metafile.push([ZOOM_Y,value])
  end

  def angle
    return @values[ANGLE]
  end

  def angle=(value)
    @values[ANGLE]=value
    @metafile.push([ANGLE,value])
  end

  def mirror
    return @values[MIRROR]
  end

  def mirror=(value)
    @values[MIRROR]=value
    @metafile.push([MIRROR,value])
  end

  def bush_depth
    return @values[BUSH_DEPTH]
  end

  def bush_depth=(value)
    @values[BUSH_DEPTH]=value
    @metafile.push([BUSH_DEPTH,value])
  end

  def opacity
    return @values[OPACITY]
  end

  def opacity=(value)
    @values[OPACITY]=value
    @metafile.push([OPACITY,value])
  end

  def blend_type
    return @values[BLEND_TYPE]
  end

  def blend_type=(value)
    @values[BLEND_TYPE]=value
    @metafile.push([BLEND_TYPE,value])
  end

  def color
    return @values[COLOR]
  end

  def color=(value)
    @values[COLOR]=value.clone
    @metafile.push([COLOR,@values[COLOR]])
  end

  def tone
    return @values[TONE]
  end

  def tone=(value)
    @values[TONE]=value.clone
    @metafile.push([TONE,@values[TONE]])
  end

  def update
    @metafile.push([-1,nil])
  end
end



class SpriteMetafilePlayer
  def initialize(metafile,sprite=nil)
    @metafile=metafile
    @sprites=[]
    @playing=false
    @index=0
    @sprites.push(sprite) if sprite
  end

  def add(sprite)
    @sprites.push(sprite)
  end

  def playing?
    return @playing
  end

  def play
    @playing=true
    @index=0
  end

  def update
    if @playing
      for j in @index...@metafile.length
        @index=j+1
        break if @metafile[j][0]<0
        code=@metafile[j][0]
        value=@metafile[j][1]
        for sprite in @sprites
          case code
          when SpriteMetafile::X; sprite.x=value
          when SpriteMetafile::Y; sprite.y=value
          when SpriteMetafile::OX; sprite.ox=value
          when SpriteMetafile::OY; sprite.oy=value
          when SpriteMetafile::ZOOM_X; sprite.zoom_x=value
          when SpriteMetafile::ZOOM_Y; sprite.zoom_y=value
          when SpriteMetafile::SRC_RECT; sprite.src_rect=value
          when SpriteMetafile::VISIBLE; sprite.visible=value
          when SpriteMetafile::Z; sprite.z=value # prevent crashes
          when SpriteMetafile::ANGLE; sprite.angle=(value==180) ? 179.9 : value
          when SpriteMetafile::MIRROR; sprite.mirror=value
          when SpriteMetafile::BUSH_DEPTH; sprite.bush_depth=value
          when SpriteMetafile::OPACITY; sprite.opacity=value
          when SpriteMetafile::BLEND_TYPE; sprite.blend_type=value
          when SpriteMetafile::COLOR; sprite.color=value
          when SpriteMetafile::TONE; sprite.tone=value
          end
        end
      end
      @playing=false if @index==@metafile.length
    end
  end
end



def pbSaveSpriteState(sprite)
  state=[]
  return state if !sprite || sprite.disposed?
  state[SpriteMetafile::BITMAP]     = sprite.x
  state[SpriteMetafile::X]          = sprite.x
  state[SpriteMetafile::Y]          = sprite.y
  state[SpriteMetafile::SRC_RECT]   = sprite.src_rect.clone
  state[SpriteMetafile::VISIBLE]    = sprite.visible
  state[SpriteMetafile::Z]          = sprite.z
  state[SpriteMetafile::OX]         = sprite.ox
  state[SpriteMetafile::OY]         = sprite.oy
  state[SpriteMetafile::ZOOM_X]     = sprite.zoom_x
  state[SpriteMetafile::ZOOM_Y]     = sprite.zoom_y
  state[SpriteMetafile::ANGLE]      = sprite.angle
  state[SpriteMetafile::MIRROR]     = sprite.mirror
  state[SpriteMetafile::BUSH_DEPTH] = sprite.bush_depth
  state[SpriteMetafile::OPACITY]    = sprite.opacity
  state[SpriteMetafile::BLEND_TYPE] = sprite.blend_type
  state[SpriteMetafile::COLOR]      = sprite.color.clone
  state[SpriteMetafile::TONE]       = sprite.tone.clone
  return state
end

def pbRestoreSpriteState(sprite,state)
  return if !state || !sprite || sprite.disposed?
  sprite.x          = state[SpriteMetafile::X]
  sprite.y          = state[SpriteMetafile::Y]
  sprite.src_rect   = state[SpriteMetafile::SRC_RECT]
  sprite.visible    = state[SpriteMetafile::VISIBLE]
  sprite.z          = state[SpriteMetafile::Z]
  sprite.ox         = state[SpriteMetafile::OX]
  sprite.oy         = state[SpriteMetafile::OY]
  sprite.zoom_x     = state[SpriteMetafile::ZOOM_X]
  sprite.zoom_y     = state[SpriteMetafile::ZOOM_Y]
  sprite.angle      = state[SpriteMetafile::ANGLE]
  sprite.mirror     = state[SpriteMetafile::MIRROR]
  sprite.bush_depth = state[SpriteMetafile::BUSH_DEPTH]
  sprite.opacity    = state[SpriteMetafile::OPACITY]
  sprite.blend_type = state[SpriteMetafile::BLEND_TYPE]
  sprite.color      = state[SpriteMetafile::COLOR]
  sprite.tone       = state[SpriteMetafile::TONE]
end

def pbSaveSpriteStateAndBitmap(sprite)
  return [] if !sprite || sprite.disposed?
  state=pbSaveSpriteState(sprite)
  state[SpriteMetafile::BITMAP]=sprite.bitmap
  return state
end

def pbRestoreSpriteStateAndBitmap(sprite,state)
  return if !state || !sprite || sprite.disposed?
  sprite.bitmap=state[SpriteMetafile::BITMAP]
  pbRestoreSpriteState(sprite,state)
  return state
end

#===============================================================================
# Evolution screen
# Bushido scripted evolution presentation
#===============================================================================
class PokemonEvolutionScene
  # ---------------------------------------------------------------------------
  # Tuning
  # ---------------------------------------------------------------------------
  EVOLUTION_BG      = Color.new(18,16,14)
  EVOLUTION_BG_2    = Color.new(24,21,18)
  EVOLUTION_INK     = Color.new(232,226,214)
  EVOLUTION_INK_DIM = Color.new(154,148,138)

  RING_RADIUS       = 104
  RING_POINTS       = 320
  PARTICLE_COUNT    = 42
  AFTERIMAGE_COUNT  = 4

  EVOLUTION_ASSET_PATH = "Graphics/Pictures/Evolution/"

  private

  def pbFrames(seconds)
    ret = (Graphics.frame_rate * seconds).round
    return (ret < 1) ? 1 : ret
  end

  def pbClamp(value, min, max)
    return min if value < min
    return max if value > max
    return value
  end

  def pbLerp(a, b, t)
    return a + ((b - a) * t)
  end

  def pbEaseOut(t)
    t = pbClamp(t, 0.0, 1.0)
    return 1.0 - ((1.0 - t) * (1.0 - t))
  end

  def pbEaseInOut(t)
    t = pbClamp(t, 0.0, 1.0)
    return (t < 0.5) ? (2.0 * t * t) : (1.0 - ((-2.0 * t + 2.0) ** 2) / 2.0)
  end

  def pbOwnBitmap(bitmap)
    @owned_bitmaps.push(bitmap)
    return bitmap
  end

  def pbClearBitmap(bitmap)
    if bitmap.respond_to?(:clear)
      bitmap.clear
    else
      bitmap.fill_rect(0,0,bitmap.width,bitmap.height,Color.new(0,0,0,0))
    end
  end

  def pbCreateSprite(key, viewport, bitmap, z=0)
    sprite = Sprite.new(viewport)
    sprite.bitmap = bitmap
    sprite.z = z
    @sprites[key] = sprite
    return sprite
  end

  # ---------------------------------------------------------------------------
  # Generated visuals
  # ---------------------------------------------------------------------------
  def pbLoadEvolutionBitmap(filename)
    return pbOwnBitmap(Bitmap.new(EVOLUTION_ASSET_PATH + filename + ".png"))
  end

  def pbBuildBackgroundBitmap
    return pbLoadEvolutionBitmap("background")
  end

  def pbBuildBlackCircleBitmap
    return pbLoadEvolutionBitmap("black_circle")
  end

  def pbBuildRingPoints
    @ring_points = []
    RING_POINTS.times do |i|
      angle = (Math::PI * 2.0 * i) / RING_POINTS
      radius_jitter = rand(11) - 5
      size = (rand(100) < 68) ? 2 : 4
      alpha = 120 + rand(116)

      # Leave a rough brush-tail gap instead of a mathematically perfect circle.
      phase = i.to_f / RING_POINTS
      if phase > 0.86 && phase < 0.96
        alpha = (alpha * 0.35).to_i
        size = 2
      end

      @ring_points.push([angle,radius_jitter,size,alpha])

      # Occasional doubled fleck makes the edge feel painted.
      if rand(100) < 14
        @ring_points.push([
          angle + ((rand(7)-3) * 0.0025),
          radius_jitter + (rand(9)-4),
          2,
          70 + rand(95)
        ])
      end
    end
  end

  def pbDrawRing(progress=1.0, radius_scale=1.0, opacity=255, rotation=0.0)
    bmp = @sprites["ring"].bitmap
    pbClearBitmap(bmp)
    return if opacity <= 0

    progress = pbClamp(progress,0.0,1.0)
    count = (@ring_points.length * progress).to_i
    cx = Graphics.width / 2
    cy = (Graphics.height - 64) / 2

    count.times do |i|
      point = @ring_points[i]
      angle = point[0] + rotation
      radius = (RING_RADIUS + point[1]) * radius_scale
      x = cx + Math.cos(angle) * radius
      y = cy + Math.sin(angle) * radius
      size = point[2]
      a = (point[3] * opacity / 255.0).to_i
      next if a <= 0
      c = Color.new(EVOLUTION_INK.red,EVOLUTION_INK.green,EVOLUTION_INK.blue,a)
      bmp.fill_rect(x.to_i-size/2,y.to_i-size/2,size,size,c)
    end
  end

  def pbBuildBurstLines
    @burst_lines = []
    34.times do
      angle = (Math::PI * 2.0 * rand(10000)) / 10000.0
      inner = 32 + rand(42)
      length = 32 + rand(98)
      width = (rand(100) < 80) ? 2 : 4
      delay = rand(1000) / 1000.0
      @burst_lines.push([angle,inner,length,width,delay])
    end
  end

  def pbDrawBurst(progress, opacity=255)
    bmp = @sprites["burst"].bitmap
    pbClearBitmap(bmp)
    return if progress <= 0.0 || opacity <= 0

    cx = Graphics.width / 2
    cy = (Graphics.height - 64) / 2
    progress = pbClamp(progress,0.0,1.0)

    @burst_lines.each do |line|
      local = (progress - line[4]) / [1.0-line[4],0.001].max
      next if local <= 0.0
      local = pbClamp(local,0.0,1.0)
      drawn = line[2] * pbEaseOut(local)
      steps = (drawn / 4.0).to_i
      steps.times do |s|
        dist = line[1] + s*4
        x = cx + Math.cos(line[0]) * dist
        y = cy + Math.sin(line[0]) * dist
        fade = 1.0 - (s.to_f / [steps,1].max)
        a = (opacity * fade * 0.72).to_i
        next if a <= 0
        bmp.fill_rect(
          x.to_i-line[3]/2,
          y.to_i-line[3]/2,
          line[3],
          4,
          Color.new(EVOLUTION_INK.red,EVOLUTION_INK.green,EVOLUTION_INK.blue,a)
        )
      end
    end
  end

  def pbBuildFlashBitmap
    return pbLoadEvolutionBitmap("flash")
  end

  def pbBuildSheenBitmap
    return pbLoadEvolutionBitmap("wipe")
  end

  # ---------------------------------------------------------------------------
  # Particles / afterimages
  # ---------------------------------------------------------------------------
  def pbCreateParticlePool
    @particles = []
    particle_bitmap = pbLoadEvolutionBitmap("particle")

    PARTICLE_COUNT.times do
      sprite = Sprite.new(@viewport)
      sprite.bitmap = particle_bitmap
      sprite.ox = 2
      sprite.oy = 2
      sprite.z = 28
      sprite.visible = false
      @particles.push({
        :sprite => sprite,
        :x => 0.0,
        :y => 0.0,
        :vx => 0.0,
        :vy => 0.0,
        :life => 0,
        :maxlife => 1
      })
    end
  end

  def pbResetParticles
    @particles.each do |p|
      p[:life] = 0
      p[:sprite].opacity = 0
      p[:sprite].visible = false
    end
  end

  def pbSpawnParticle(strength=1.0)
    slot = nil
    @particles.each do |p|
      if p[:life] <= 0
        slot = p
        break
      end
    end
    return if !slot

    cx = Graphics.width / 2
    cy = (Graphics.height - 64) / 2
    angle = (Math::PI * 2.0 * rand(10000)) / 10000.0
    radius = 26 + rand(52)
    speed = (0.75 + rand(160)/100.0) * strength

    slot[:x] = cx + Math.cos(angle) * radius
    slot[:y] = cy + Math.sin(angle) * radius
    slot[:vx] = Math.cos(angle) * speed
    slot[:vy] = Math.sin(angle) * speed
    slot[:maxlife] = pbFrames(0.35 + rand(35)/100.0)
    slot[:life] = slot[:maxlife]

    sprite = slot[:sprite]
    sprite.x = slot[:x].to_i
    sprite.y = slot[:y].to_i
    sprite.zoom_x = (rand(100) < 72) ? 0.5 : 1.0
    sprite.zoom_y = sprite.zoom_x
    sprite.opacity = 150 + rand(106)
    sprite.visible = true
  end

  def pbUpdateParticles
    @particles.each do |p|
      if p[:life] <= 0
        p[:sprite].opacity = 0
        p[:sprite].visible = false
        next
      end

      p[:x] += p[:vx]
      p[:y] += p[:vy]
      p[:vx] *= 0.985
      p[:vy] *= 0.985
      p[:life] -= 1

      sprite = p[:sprite]
      sprite.x = p[:x].to_i
      sprite.y = p[:y].to_i

      remaining = pbClamp(p[:life].to_f / [p[:maxlife],1].max,0.0,1.0)
      sprite.opacity = (255 * remaining * remaining).to_i

      if p[:life] <= 0 || sprite.opacity <= 0
        p[:life] = 0
        sprite.opacity = 0
        sprite.visible = false
      end
    end
  end

  def pbFadeOutParticles(seconds=0.22)
    active = []
    @particles.each do |p|
      next if !p[:sprite].visible
      next if p[:sprite].opacity <= 0
      active.push([p,p[:sprite].opacity])
    end
    return if active.length == 0

    frames = pbFrames(seconds)
    frames.times do |i|
      t = (i+1).to_f / frames

      active.each do |entry|
        p = entry[0]
        start_opacity = entry[1]

        p[:x] += p[:vx]
        p[:y] += p[:vy]
        p[:vx] *= 0.96
        p[:vy] *= 0.96

        sprite = p[:sprite]
        sprite.x = p[:x].to_i
        sprite.y = p[:y].to_i
        sprite.opacity = (start_opacity * (1.0-t) * (1.0-t)).to_i
      end

      Graphics.update
      Input.update
      pbUpdate(true)
    end

    pbResetParticles
  end

  def pbCreateAfterimages
    @afterimages = []
    AFTERIMAGE_COUNT.times do |i|
      sprite = Sprite.new(@viewport)
      sprite.z = 18 + i
      sprite.visible = false
      sprite.opacity = 0
      @afterimages.push(sprite)
    end
  end

  def pbHideAfterimages
    @afterimages.each { |sprite| sprite.visible = false }
  end

  def pbUpdateAfterimages(source, intensity, frame)
    return pbHideAfterimages if !source || source.disposed? || !source.bitmap
    intensity = pbClamp(intensity,0.0,1.0)
    if intensity < 0.08
      pbHideAfterimages
      return
    end

    @afterimages.each_with_index do |sprite,i|
      angle = frame*0.33 + i*(Math::PI*2.0/@afterimages.length)
      distance = 2 + (intensity * (4+i*1.5))
      sprite.bitmap = source.bitmap
      sprite.src_rect = source.src_rect.clone
      sprite.ox = source.ox
      sprite.oy = source.oy
      sprite.x = source.x + Math.cos(angle)*distance
      sprite.y = source.y + Math.sin(angle)*distance
      sprite.zoom_x = source.zoom_x
      sprite.zoom_y = source.zoom_y
      sprite.angle = source.angle
      sprite.mirror = source.mirror
      sprite.color = Color.new(255,255,255,190)
      sprite.opacity = (intensity * (100 - i*14)).to_i
      sprite.visible = true
    end
  end

  # ---------------------------------------------------------------------------
  # Scene visual state
  # ---------------------------------------------------------------------------
  def pbSetPokemonWhite(alpha)
    alpha = pbClamp(alpha.to_i,0,255)
    c = Color.new(255,255,255,alpha)
    @sprites["rsprite1"].color = c
    @sprites["rsprite2"].color = c
  end

  def pbSetPokemonZoom(zoom_x, zoom_y)
    @sprites["rsprite1"].zoom_x = zoom_x
    @sprites["rsprite1"].zoom_y = zoom_y
    @sprites["rsprite2"].zoom_x = zoom_x
    @sprites["rsprite2"].zoom_y = zoom_y
  end

  def pbShowEvolutionForm(show_evolved)
    @sprites["rsprite1"].visible = !show_evolved
    @sprites["rsprite2"].visible = show_evolved
    @sprites["rsprite1"].opacity = 255
    @sprites["rsprite2"].opacity = 255
  end

  def pbCurrentPokemonSprite
    return @sprites["rsprite2"] if @sprites["rsprite2"].visible
    return @sprites["rsprite1"]
  end

  def pbClearTransientVisuals
    pbHideAfterimages
    pbResetParticles
    pbDrawBurst(0.0,0)
    @sprites["flash"].opacity = 0
    @sprites["sheen"].opacity = 0
    @sprites["sheen"].visible = false
  end

  def pbAnimationFrame
    Graphics.update
    Input.update
    pbUpdate(true)
    pbUpdateParticles
  end

  def pbCanceled?(cancancel)
    return false if !cancancel
    return Input.trigger?(Input::B)
  end

  # ---------------------------------------------------------------------------
  # Animation phases
  # ---------------------------------------------------------------------------
  def pbEvolutionIntro(cancancel)
    frames = pbFrames(0.85)
    frames.times do |i|
      t = (i+1).to_f / frames
      eased = pbEaseOut(t)

      pbDrawRing(eased,0.92 + 0.08*eased,(255*eased).to_i,-0.08*(1.0-eased))
      @sprites["halo"].opacity = (50 + 85*eased).to_i
      pbSetPokemonWhite((130*eased).to_i)

      if i % 4 == 0 && rand(100) < 55
        pbSpawnParticle(0.55)
      end

      pbAnimationFrame
      return true if pbCanceled?(cancancel)
    end
    return false
  end

  def pbEvolutionTransform(cancancel)
    frames = pbFrames(3.15)
    show_evolved = false
    last_toggle = -99

    frames.times do |i|
      t = (i+1).to_f / frames
      intensity = pbEaseInOut(t)
      interval = (11 - intensity*9).to_i
      interval = 2 if interval < 2

      if i-last_toggle >= interval
        show_evolved = !show_evolved
        pbShowEvolutionForm(show_evolved)
        last_toggle = i
      end

      # A stepped squash/stretch rather than perfectly smooth tweening.
      wobble = Math.sin(i * (0.22 + intensity*0.34))
      step_wobble = (wobble*4).round / 4.0
      zx = 1.0 + intensity*0.055 + step_wobble*0.035*intensity
      zy = 1.0 + intensity*0.085 - step_wobble*0.030*intensity
      pbSetPokemonZoom(zx,zy)

      white = 130 + (125*intensity)
      pbSetPokemonWhite(white.to_i)

      ring_scale = 1.0 + Math.sin(i*0.15)*0.015*intensity
      pbDrawRing(1.0,ring_scale,255,(i*0.0025))
      @sprites["halo"].opacity = (115 + 100*intensity).to_i

      if intensity > 0.34
        burst_t = (intensity-0.34)/0.66
        pbDrawBurst(burst_t,(70 + 155*burst_t).to_i)
      end

      spawn_chance = (8 + intensity*42).to_i
      pbSpawnParticle(0.65 + intensity*1.15) if rand(100) < spawn_chance

      pbUpdateAfterimages(pbCurrentPokemonSprite,intensity,i)
      pbAnimationFrame
      return true if pbCanceled?(cancancel)
    end
    return false
  end

  def pbEvolutionCollapse
    frames = pbFrames(0.42)
    frames.times do |i|
      t = (i+1).to_f / frames
      eased = t*t
      show_evolved = ((i / 2) % 2 == 0)
      pbShowEvolutionForm(show_evolved)
      pbSetPokemonWhite(255)
      pbSetPokemonZoom(1.05 + 0.10*eased,1.08 + 0.14*eased)

      ring_scale = pbLerp(1.0,0.14,eased)
      ring_opacity = (255*(1.0-t*0.35)).to_i
      pbDrawRing(1.0,ring_scale,ring_opacity,i*0.01)
      pbDrawBurst(1.0,(190 + 65*t).to_i)

      2.times { pbSpawnParticle(1.6 + t) }
      pbUpdateAfterimages(pbCurrentPokemonSprite,1.0,i)
      pbAnimationFrame
    end
  end

  def pbEvolutionImpact
    @sprites["rsprite1"].visible = false
    @sprites["rsprite2"].visible = false
    pbHideAfterimages
    pbDrawRing(0.0,1.0,0)
    pbDrawBurst(0.0,0)

    # Hard white impact.
    upframes = pbFrames(0.10)
    upframes.times do |i|
      t = (i+1).to_f / upframes
      @sprites["flash"].opacity = (255*pbEaseOut(t)).to_i
      3.times { pbSpawnParticle(2.0) }
      pbAnimationFrame
    end

    hold = pbFrames(0.08)
    hold.times { pbAnimationFrame }

    # Snap back to the dark scene.
    downframes = pbFrames(0.16)
    downframes.times do |i|
      t = (i+1).to_f / downframes
      @sprites["flash"].opacity = (255*(1.0-t)).to_i
      pbAnimationFrame
    end
    @sprites["flash"].opacity = 0
    pbFadeOutParticles(0.18)
  end

  def pbEvolutionSilhouetteReveal
    evo = @sprites["rsprite2"]
    reveal = @sprites["reveal"]

    evo.visible = true
    evo.opacity = 255
    evo.zoom_x = 1.04
    evo.zoom_y = 1.04
    evo.color = Color.new(0,0,0,255)

    reveal.bitmap = evo.bitmap
    reveal.ox = evo.ox
    reveal.oy = evo.oy
    reveal.x = evo.x
    reveal.y = evo.y
    reveal.zoom_x = evo.zoom_x
    reveal.zoom_y = evo.zoom_y
    reveal.src_rect = Rect.new(0,0,0,evo.bitmap.height)
    reveal.visible = false
    reveal.opacity = 255
    reveal.color = Color.new(0,0,0,0)

    @sprites["halo"].opacity = 70

    # Quiet silhouette hold.
    pbFrames(0.48).times do
      pbAnimationFrame
    end

    sheen = @sprites["sheen"]
    sheen.visible = true
    sheen.opacity = 0

    start_x = -sheen.bitmap.width
    end_x   = Graphics.width + sheen.bitmap.width

    sprite_left  = evo.x - (evo.ox * evo.zoom_x)
    sprite_width = evo.bitmap.width * evo.zoom_x

    frames = pbFrames(0.72)
    frames.times do |i|
      t = (i+1).to_f / frames
      eased = pbEaseInOut(t)

      sheen.x = pbLerp(start_x,end_x,eased).to_i
      sheen.opacity = (230 * Math.sin(Math::PI*t)).to_i

      frontier = sheen.x + sheen.bitmap.width/2

      if frontier > sprite_left
        passed = pbClamp((frontier-sprite_left) / [sprite_width,1.0].max,0.0,1.0)
        source_width = (evo.bitmap.width * passed).to_i

        reveal.src_rect = Rect.new(0,0,source_width,evo.bitmap.height)
        reveal.visible = (source_width > 0)
      else
        reveal.visible = false
      end

      # Start the celebration before the wipe is fully gone. This makes the
      # reveal and burst feel like one continuous release of energy.
      if t > 0.72
        burst_t = (t-0.72) / 0.28
        pbDrawRing(1.0,pbLerp(0.74,0.96,burst_t),(190*burst_t).to_i)
        pbDrawBurst(burst_t,(120*burst_t).to_i)

        spawn = (burst_t * 3).to_i
        spawn.times { pbSpawnParticle(1.05 + 0.45*burst_t) }
      end

      pbAnimationFrame
    end

    reveal.visible = false
    reveal.src_rect = Rect.new(0,0,0,evo.bitmap.height)

    evo.color = Color.new(0,0,0,0)

    # Keep the reveal scale through the handoff. The final burst owns the
    # scale settle so there is no visible snap between phases.
    sheen.visible = false
    sheen.opacity = 0
  end

  def pbEvolutionFinalBurst
    evo = @sprites["rsprite2"]
    base_x = evo.x
    base_y = evo.y

    # The wipe hands us a slightly enlarged sprite. Rather than snapping it
    # back to normal, the burst turns that scale into a stamp-like impact.
    start_zoom_x = evo.zoom_x
    start_zoom_y = evo.zoom_y

    frames = pbFrames(0.68)
    frames.times do |i|
      t = (i+1).to_f / frames
      eased = pbEaseOut(t)

      scale = pbLerp(0.96,1.34,eased)
      opacity = (210*(1.0-t)).to_i

      pbDrawRing(1.0,scale,opacity,-0.025*(1.0-t))
      pbDrawBurst(1.0,(150*(1.0-t)).to_i)
      @sprites["halo"].opacity = (105*(1.0-t)).to_i

      if i < frames/2 && (i % 2 == 0)
        pbSpawnParticle(1.15 + 0.25*(1.0-t))
      end

      # Stamp pulse:
      # 0.00 -> inherit wipe scale (~1.04)
      # 0.18 -> compress slightly
      # 0.38 -> punch outward
      # 1.00 -> settle exactly at 1.0
      if t < 0.18
        local = t / 0.18
        pokemon_zoom = pbLerp(start_zoom_x,0.97,pbEaseInOut(local))
      elsif t < 0.38
        local = (t-0.18) / 0.20
        pokemon_zoom = pbLerp(0.97,1.095,pbEaseOut(local))
      else
        local = (t-0.38) / 0.62
        pokemon_zoom = pbLerp(1.095,1.0,pbEaseInOut(local))
      end

      # Slight vertical squash/stretch makes it feel like an ink stamp hitting.
      if t < 0.38
        squash = Math.sin(Math::PI * pbClamp(t/0.38,0.0,1.0))
        evo.zoom_x = pokemon_zoom + 0.018*squash
        evo.zoom_y = pokemon_zoom - 0.014*squash
      else
        evo.zoom_x = pokemon_zoom
        evo.zoom_y = pokemon_zoom
      end

      # Slow physical shake tied to the impact rather than floating separately.
      impact = Math.sin(Math::PI*t)
      shake_strength = impact * 2.2
      evo.x = base_x + (Math.sin(i*0.9) * shake_strength).round
      evo.y = base_y + (Math.cos(i*0.7) * shake_strength * 0.40).round

      pbAnimationFrame
    end

    evo.x = base_x
    evo.y = base_y
    evo.zoom_x = 1.0
    evo.zoom_y = 1.0

    pbDrawRing(0.0,1.0,0)
    pbDrawBurst(0.0,0)
    @sprites["halo"].opacity = 55

    pbFadeOutParticles(0.20)

    # Tiny breath before the cry.
    pbFrames(0.10).times do
      pbAnimationFrame
    end

    frames = pbCryFrameLength(@newspecies,@pokemon.form)
    pbPlayCrySpecies(@newspecies,@pokemon.form)
    frames.times do
      Graphics.update
      pbUpdate
    end
  end

  def pbCancelEvolution(oldstate,oldstate2)
    pbBGMStop
    pbPlayCancelSE

    # Pull the ring inward and let the energy die instead of using the old
    # full-screen evolution flash.
    frames = pbFrames(0.28)
    frames.times do |i|
      t = (i+1).to_f / frames
      pbDrawRing(1.0,pbLerp(1.0,0.78,t),(255*(1.0-t)).to_i)
      @sprites["halo"].opacity = (120*(1.0-t)).to_i
      pbSetPokemonWhite((255*(1.0-t)).to_i)
      pbAnimationFrame
    end

    pbRestoreSpriteState(@sprites["rsprite1"],oldstate)
    pbRestoreSpriteState(@sprites["rsprite2"],oldstate2)
    @sprites["rsprite1"].zoom_x = 1.0
    @sprites["rsprite1"].zoom_y = 1.0
    @sprites["rsprite1"].color = Color.new(0,0,0,0)
    @sprites["rsprite1"].visible = true
    @sprites["rsprite2"].visible = false
    pbClearTransientVisuals
    pbDrawRing(0.0,1.0,0)
    @sprites["halo"].opacity = 45
    @sprites["msgwindow"].visible = true
  end

  public

  def pbUpdate(animating=false)
    if animating
      @sprites["background"].update if @sprites["background"] && !@sprites["background"].disposed?
    else
      pbUpdateSpriteHash(@sprites)
    end
  end

  # Compatibility with the old scene. The Bushido presentation no longer
  # letterboxes the background during evolution.
  def pbUpdateNarrowScreen; end
  def pbUpdateExpandScreen; end

  def pbStartScreen(pokemon,newspecies)
    @pokemon = pokemon
    @newspecies = newspecies
    @sprites = {}
    @owned_bitmaps = []
    @particles = []
    @afterimages = []

    # Keep every visual element on one viewport. This avoids RMXP/Essentials
    # edge cases where generic fade helpers tint one viewport's sprites while
    # another viewport is already rendering.
    @bgviewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @bgviewport.z = 99999
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @msgviewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @msgviewport.z = 99999

    background = pbCreateSprite("background",@bgviewport,pbBuildBackgroundBitmap,0)
    background.visible = true
    background.opacity = 255

    halo = pbCreateSprite("halo",@viewport,pbBuildBlackCircleBitmap,-40)
    halo.ox = halo.bitmap.width/2
    halo.oy = halo.bitmap.height/2
    halo.x = Graphics.width/2
    halo.y = (Graphics.height-64)/2
    halo.opacity = 150
    halo.visible = true
    halo.blend_type = 0

    ring_bitmap = pbOwnBitmap(Bitmap.new(Graphics.width,Graphics.height))
    pbClearBitmap(ring_bitmap)
    ring = pbCreateSprite("ring",@viewport,ring_bitmap,-20)
    ring.visible = true
    ring.opacity = 255

    burst_bitmap = pbOwnBitmap(Bitmap.new(Graphics.width,Graphics.height))
    pbClearBitmap(burst_bitmap)
    burst = pbCreateSprite("burst",@viewport,burst_bitmap,-10)
    burst.visible = true
    burst.opacity = 255

    rsprite1 = PokemonSprite.new(@viewport)
    rsprite1.setOffset(PictureOrigin::Center)
    rsprite1.setPokemonBitmap(@pokemon,false)
    rsprite1.x = Graphics.width/2
    rsprite1.y = (Graphics.height-64)/2
    rsprite1.z = 20
    rsprite1.opacity = 255
    rsprite1.visible = true
    rsprite1.color = Color.new(0,0,0,0)

    rsprite2 = PokemonSprite.new(@viewport)
    rsprite2.setOffset(PictureOrigin::Center)
    rsprite2.setPokemonBitmapSpecies(@pokemon,@newspecies,false)
    rsprite2.x = rsprite1.x
    rsprite2.y = rsprite1.y
    rsprite2.z = 20
    rsprite2.opacity = 255
    rsprite2.visible = false
    rsprite2.color = Color.new(0,0,0,0)

    @sprites["rsprite1"] = rsprite1
    @sprites["rsprite2"] = rsprite2

    # Full-color evolved sprite used only for the left-to-right wipe reveal.
    # The black silhouette remains underneath until the wipe has physically
    # crossed each part of the sprite.
    reveal = Sprite.new(@viewport)
    reveal.bitmap = rsprite2.bitmap
    reveal.src_rect = Rect.new(0,0,0,rsprite2.bitmap.height)
    reveal.ox = rsprite2.ox
    reveal.oy = rsprite2.oy
    reveal.x = rsprite2.x
    reveal.y = rsprite2.y
    reveal.z = 22
    reveal.opacity = 255
    reveal.visible = false
    @sprites["reveal"] = reveal

    flash = pbCreateSprite("flash",@viewport,pbBuildFlashBitmap,80)
    flash.visible = true
    flash.opacity = 0
    flash.color = Color.new(0,0,0,0)

    sheen = pbCreateSprite("sheen",@viewport,pbBuildSheenBitmap,35)
    sheen.ox = sheen.bitmap.width/2
    sheen.y = 0
    sheen.opacity = 0
    sheen.visible = false
    sheen.blend_type = 1

    pbBuildRingPoints
    pbBuildBurstLines
    pbCreateParticlePool
    pbCreateAfterimages

    @sprites["msgwindow"] = pbCreateMessageWindow(@msgviewport)

    # Do NOT use pbFadeInAndShow here. Essentials' generic helper changes the
    # Color of every sprite in @sprites, while this evolution scene deliberately
    # uses Sprite#color for silhouettes and whitening.
    @viewport.color = Color.new(0,0,0,255)
    @bgviewport.color = Color.new(0,0,0,255)
    fadeframes = pbFrames(0.35)
    fadeframes.times do |i|
      alpha = (255 * (1.0 - ((i+1).to_f/fadeframes))).to_i
      @viewport.color = Color.new(0,0,0,alpha)
      @bgviewport.color = Color.new(0,0,0,alpha)
      Graphics.update
      pbUpdate(false)
    end
    @viewport.color = Color.new(0,0,0,0)
    @bgviewport.color = Color.new(0,0,0,0)

    # Reassert the opening state after the fade. Nothing outside this scene is
    # allowed to decide which Pokémon sprite should be visible.
    @sprites["background"].visible = true
    @sprites["halo"].visible = true
    @sprites["ring"].visible = true
    @sprites["burst"].visible = true
    @sprites["rsprite1"].visible = true
    @sprites["rsprite1"].opacity = 255
    @sprites["rsprite1"].zoom_x = 1.0
    @sprites["rsprite1"].zoom_y = 1.0
    @sprites["rsprite1"].color = Color.new(0,0,0,0)
    @sprites["rsprite2"].visible = false
    @sprites["flash"].visible = true
    @sprites["flash"].opacity = 0
    @sprites["sheen"].visible = false
  end

  # Closes the evolution screen.
  def pbEndScreen
    pbDisposeMessageWindow(@sprites["msgwindow"])

    pbFadeOutAndHide(@sprites) { pbUpdate }

    @afterimages.each do |sprite|
      sprite.dispose if sprite && !sprite.disposed?
    end

    @particles.each do |p|
      sprite = p[:sprite]
      sprite.dispose if sprite && !sprite.disposed?
    end

    pbDisposeSpriteHash(@sprites)

    @owned_bitmaps.each do |bitmap|
      bitmap.dispose if bitmap && !bitmap.disposed?
    end

    @viewport.dispose if @viewport && !@viewport.disposed?
    @bgviewport.dispose if @bgviewport && !@bgviewport.disposed?
    @msgviewport.dispose if @msgviewport && !@msgviewport.disposed?
  end

  # Opens the evolution screen.
  def pbEvolution(cancancel=true)
    pbBGMStop
    pbPlayCry(@pokemon)
    pbMessageDisplay(@sprites["msgwindow"],
       _INTL("\\se[]What? {1} is evolving!\\^",@pokemon.name)) { pbUpdate }
    pbMessageWaitForInput(@sprites["msgwindow"],50,true) { pbUpdate }
    pbPlayDecisionSE

    oldstate  = pbSaveSpriteState(@sprites["rsprite1"])
    oldstate2 = pbSaveSpriteState(@sprites["rsprite2"])

    @sprites["msgwindow"].text = ""
    @sprites["msgwindow"].visible = false

    pbBGMPlay("PLA 039 Evolution")

    canceled = pbEvolutionIntro(cancancel)
    canceled = pbEvolutionTransform(cancancel) if !canceled

    if canceled
      pbCancelEvolution(oldstate,oldstate2)
      pbMessageDisplay(@sprites["msgwindow"],
         _INTL("Huh? {1} stopped evolving!",@pokemon.name)) { pbUpdate }
      return
    end

    pbEvolutionCollapse
    pbEvolutionImpact
    pbEvolutionSilhouetteReveal
    pbEvolutionFinalBurst

    @sprites["msgwindow"].visible = true
    pbEvolutionSuccess
  end

  def pbEvolutionSuccess
    # The evolved species cry already played at the end of the reveal.
    pbBGMStop

    # Success jingle/message.
    pbMEPlay("PLA 040 Congratulations, Your Pokemon Evolved!")
    newspeciesname = PBSpecies.getName(@newspecies)
    oldspeciesname = PBSpecies.getName(@pokemon.species)
    pbMessageDisplay(@sprites["msgwindow"],
       _INTL("\\se[]Congratulations! Your {1} evolved into {2}!\\wt[80]",
       @pokemon.name,newspeciesname)) { pbUpdate }
    @sprites["msgwindow"].text = ""

    # Check for consumed item and check if Pokémon should be duplicated.
    pbEvolutionMethodAfterEvolution

    # Modify Pokémon to make it evolved.
    @pokemon.species = @newspecies
    @pokemon.name    = newspeciesname if @pokemon.name==oldspeciesname
    @pokemon.form    = 0 if @pokemon.isSpecies?(:MOTHIM)
    @pokemon.calcStats

    # See and own evolved species.
    $Trainer.seen[@newspecies]  = true
    $Trainer.owned[@newspecies] = true
    pbSeenForm(@pokemon)

    # Learn moves upon evolution for evolved species.
    movelist = @pokemon.getMoveList
    for i in movelist
      next if i[0]!=0 && i[0]!=@pokemon.level
      pbLearnMove(@pokemon,i[1],true) { pbUpdate }
    end
  end

  def pbEvolutionMethodAfterEvolution
    pbCheckEvolutionEx(@pokemon) { |pkmn, method, parameter, new_species|
      success = PBEvolution.call(
        "afterEvolution",method,pkmn,new_species,parameter,@newspecies
      )
      next (success) ? 1 : -1
    }
  end

  def self.pbDuplicatePokemon(pkmn, new_species)
    new_pkmn = pkmn.clone
    new_pkmn.species  = new_species
    new_pkmn.name     = PBSpecies.getName(new_species)
    new_pkmn.markings = 0
    new_pkmn.ballused = 0
    new_pkmn.setItem(0)
    new_pkmn.clearAllRibbons
    new_pkmn.calcStats
    new_pkmn.heal

    # Add duplicate Pokémon to party.
    $Trainer.party.push(new_pkmn)

    # See and own duplicate Pokémon.
    $Trainer.seen[new_species]  = true
    $Trainer.owned[new_species] = true
    pbSeenForm(new_pkmn)
  end
end

