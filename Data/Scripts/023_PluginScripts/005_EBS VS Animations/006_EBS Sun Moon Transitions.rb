# handled = checkIfSunMoonTransition(trainerid)
# handled = SunMoonBattleTransitions.new.evilTeam(viewport) if e_team && !handled

# returns true if game is supposed to load a Sun & Moon styled VS sequence
def checkIfSunMoonTransition(trainerid)
  ret = false
  for ext in ["trainer","special","elite","crazy","ultra","digital","plasma","skull"]
    ret = true if pbResolveBitmap(sprintf("Graphics/Transitions/SunMoon/%s%03d",ext,trainerid))
  end
  $smAnim = ret
  return ret
end

class PokemonTemp
  attr_accessor :smAnim
  def smAnim
    @smAnim = [] if !@smAnim
    return @smAnim
  end
end

#-------------------------------------------------------------------------------
#  The main class responsible for loading up the S/M styled transitions
#-------------------------------------------------------------------------------
class SunMoonBattleTransitions
  attr_accessor :scene

  attr_accessor :speed
  # creates the transition handler
  def initialize(*args)
    return if args.length < 4
    # sets up main viewports
    @viewport = args[0]
    @viewport.color = Color.new(255,255,255,0)
    @msgview = args[1]
    # sets up variables
    @disposed = false
    @sentout = false
    @scene = args[2]
    @trainerid = args[3]
    @speed = 1
    @sprites = {}
    # retreives additional parameters
    self.getParameters(@trainerid)
    # plays the animation before the main sequence
    @evilteam ? self.evilTeam : self.rainbowIntro
    @teamskull = @variant == "skull"
    self.teamSkull if @teamskull
    # initializes the backdrop
    case @variant
    when "special"
      @sprites["background"] = SunMoonSpecialBackground.new(@viewport,@trainerid,@evilteam)
    when "elite"
      @sprites["background"] = SunMoonEliteBackground.new(@viewport,@trainerid,@evilteam)
    when "crazy"
      @sprites["background"] = SunMoonCrazyBackground.new(@viewport,@trainerid,@evilteam)
    when "ultra"
      @sprites["background"] = SunMoonUltraBackground.new(@viewport,@trainerid,@evilteam)
    when "digital"
      @sprites["background"] = SunMoonDigitalBackground.new(@viewport,@trainerid,@evilteam)
    when "plasma"
      @sprites["background"] = SunMoonPlasmaBackground.new(@viewport,@trainerid,@evilteam)
    else
      @sprites["background"] = SunMoonDefaultBackground.new(@viewport,@trainerid,@evilteam,@teamskull)
    end
    @sprites["background"].speed = 24
    # trainer shadow
    @sprites["shade"] = Sprite.new(@viewport)
    @sprites["shade"].z = 250
    # trainer glow (left)
    @sprites["glow"] = Sprite.new(@viewport)
    @sprites["glow"].y = @viewport.rect.height
    @sprites["glow"].z = 250
    # trainer glow (right)
    @sprites["glow2"] = Sprite.new(@viewport)
    @sprites["glow2"].z = 250
    # trainer graphic
    @sprites["trainer"] = Sprite.new(@viewport)
    @sprites["trainer"].z = 350
    @sprites["trainer"].bitmap = Bitmap.new(@viewport.rect.width,@viewport.rect.height)
    @sprites["trainer"].ox = @sprites["trainer"].bitmap.width/2
    @sprites["trainer"].oy = @sprites["trainer"].bitmap.height/2
    @sprites["trainer"].x = @sprites["trainer"].ox if @variant != "plasma"
    @sprites["trainer"].y = @sprites["trainer"].oy
    @sprites["trainer"].tone = Tone.new(255,255,255)
    @sprites["trainer"].zoom_x = 1.32 if @variant != "plasma"
    @sprites["trainer"].zoom_y = 1.32 if @variant != "plasma"
    @sprites["trainer"].opacity = 0
    # sets a bitmap for the trainer
    bmp = Bitmap.new(sprintf("Graphics/Transitions/SunMoon/%s%03d",@variant,@trainerid))
    ox = (@sprites["trainer"].bitmap.width - bmp.width)/2
    oy = (@sprites["trainer"].bitmap.height - bmp.height)/2
    @sprites["trainer"].bitmap.blt(ox,oy,bmp,Rect.new(0,0,bmp.width,bmp.height))
    bmp = @sprites["trainer"].bitmap.clone
    # colours the shadow
    @sprites["shade"].bitmap = bmp.clone
    @sprites["shade"].color = Color.new(10,169,245,204)
    @sprites["shade"].color = Color.new(150,115,255,204) if @variant == "elite"
    @sprites["shade"].color = Color.new(115,216,145,204) if @variant == "digital"
    @sprites["shade"].opacity = 0
    @sprites["shade"].visible = false if @variant == "crazy" || @variant == "plasma"
    # creates and colours an outer glow for the trainer
    c = Color.new(0,0,0)
    c = Color.new(255,255,255) if @variant == "crazy" || @variant == "digital" || @variant == "plasma"
    @sprites["glow"].bitmap = bmp.clone
    @sprites["glow"].glow(c,35,false)
    @sprites["glow"].src_rect.set(0,@viewport.rect.height,@viewport.rect.width/2,0)
    @sprites["glow2"].bitmap = @sprites["glow"].bitmap.clone
    @sprites["glow2"].src_rect.set(@viewport.rect.width/2,0,@viewport.rect.width/2,0)
    # creates the fade-out ball graphic overlay
    @sprites["overlay"] = Sprite.new(@viewport)
    @sprites["overlay"].z = 999
    @sprites["overlay"].bitmap = Bitmap.new(@viewport.rect.width,@viewport.rect.height)
    @sprites["overlay"].opacity = 0
  end
  # starts the animation
  def start
    return if self.disposed?
    # fades in viewport
    16.times do
      @viewport.color.alpha -= 16 if @viewport.color.alpha > 0
      if @variant == "plasma"
        @sprites["trainer"].x += (@viewport.rect.width/3)/8
        self.update
      else
        @sprites["trainer"].zoom_x -= 0.02
        @sprites["trainer"].zoom_y -= 0.02
      end
      @sprites["trainer"].opacity += 32
      Graphics.update
    end
    @sprites["trainer"].zoom_x = 1
    @sprites["trainer"].zoom_y = 1
    # fades in trainer
    for i in 0...16
      @sprites["trainer"].tone.red -= 16
      @sprites["trainer"].tone.green -= 16
      @sprites["trainer"].tone.blue -= 16
      @sprites["background"].reduceAlpha(16)
      self.update
      Graphics.update
    end
    # wait
    16.times do
      self.update
      Graphics.update
    end
    # flashes trainer
    for i in 0...10
      @sprites["trainer"].tone.red -= 64*(i < 6 ? -1 : 1)
      @sprites["trainer"].tone.green -= 64*(i < 6 ? -1 : 1)
      @sprites["trainer"].tone.blue -= 64*(i < 6 ? -1 : 1)
      @sprites["background"].speed = 4 if i == 4
      self.update
      Graphics.update
    end
    # wraps glow around trainer
    16.times do
      @sprites["glow"].src_rect.height += @viewport.rect.height/16
      @sprites["glow"].src_rect.y -= @viewport.rect.height/16
      @sprites["glow"].y -= @viewport.rect.height/16
      @sprites["glow2"].src_rect.height += @viewport.rect.height/16
      self.update
      Graphics.update
    end
    # flashes viewport
    @viewport.color = Color.new(255,255,255,0)
    8.times do
      if @variant != "plasma"
        @sprites["glow"].tone.red += 32
        @sprites["glow"].tone.green += 32
        @sprites["glow"].tone.blue += 32
        @sprites["glow2"].tone.red += 32
        @sprites["glow2"].tone.green += 32
        @sprites["glow2"].tone.blue += 32
      end
      self.update
      Graphics.update
    end
    # loads additional background elements
    @sprites["background"].show
    if @variant == "plasma"
      @sprites["glow"].color = Color.new(148,90,40)
      @sprites["glow2"].color = Color.new(148,90,40)
    end
    # flashes trainer
    for i in 0...4
      @viewport.color.alpha += 32
      @sprites["trainer"].tone.red += 64
      @sprites["trainer"].tone.green += 64
      @sprites["trainer"].tone.blue += 64
      self.update
      Graphics.update
    end
    for j in 0...4
      @viewport.color.alpha += 32
      self.update
      Graphics.update
    end
    # returns everything to normal
    for i in 0...8
      @viewport.color.alpha -= 32
      @sprites["trainer"].tone.red -= 32 if @sprites["trainer"].tone.red > 0
      @sprites["trainer"].tone.green -= 32 if @sprites["trainer"].tone.green > 0
      @sprites["trainer"].tone.blue -= 32 if @sprites["trainer"].tone.blue > 0
      @sprites["shade"].opacity += 32
      @sprites["shade"].x -= 4
      self.update
      Graphics.update
    end
  end
  # main update call
  def update
    return if self.disposed?
    @sprites["background"].update
    @sprites["glow"].x = @sprites["trainer"].x - @sprites["trainer"].bitmap.width/2
    @sprites["glow2"].x = @sprites["trainer"].x
  end
  # called before Trainer sends out their Pokemon
  def finish
    return if self.disposed?
    # final transition
    viewport = @viewport
    zoom = 4.0
    obmp = pbBitmap("Graphics/Transitions/SunMoon/Common/ballTransition")
    @sprites["background"].speed = 24
    # zooms in ball graphic overlay
    for i in 0..20
      @sprites["overlay"].bitmap.clear
      ox = (1 - zoom)*viewport.rect.width*0.5
      oy = (1 - zoom)*viewport.rect.height*0.5
      width = (ox < 0 ? 0 : ox).ceil
      height = (oy < 0 ? 0 : oy).ceil
      @sprites["overlay"].bitmap.fill_rect(0,0,width,viewport.rect.height,Color.new(0,0,0))
      @sprites["overlay"].bitmap.fill_rect(viewport.rect.width-width,0,width,viewport.rect.height,Color.new(0,0,0))
      @sprites["overlay"].bitmap.fill_rect(0,0,viewport.rect.width,height,Color.new(0,0,0))
      @sprites["overlay"].bitmap.fill_rect(0,viewport.rect.height-height,viewport.rect.width,height,Color.new(0,0,0))
      @sprites["overlay"].bitmap.stretch_blt(Rect.new(ox,oy,(obmp.width*zoom).ceil,(obmp.height*zoom).ceil),obmp,Rect.new(0,0,obmp.width,obmp.height))
      @sprites["overlay"].opacity += 64
      zoom -= 4.0/20
      self.update
      Graphics.update
    end
    # disposes of current sprites
    self.dispose
    # re-loads overlay
    @sprites["overlay"] = Sprite.new(@msgview)
    @sprites["overlay"].z = 9999999
    @sprites["overlay"].bitmap = Bitmap.new(@msgview.rect.width,@msgview.rect.height)
    @sprites["overlay"].bitmap.fill_rect(0,0,@msgview.rect.width,@msgview.rect.height,Color.new(0,0,0))
  end
  # called during Trainer sendout
  def sendout
    return if @sentout
    $smAnim = false
    # transitions from VS sequence to the battle scene
    zoom = 0
    # zooms out ball graphic overlay
    21.times do
      @sprites["overlay"].bitmap.clear
      ox = (1 - zoom)*@msgview.rect.width*0.5
      oy = (1 - zoom)*@msgview.rect.height*0.5
      width = (ox < 0 ? 0 : ox).ceil
      height = (oy < 0 ? 0 : oy).ceil
      @sprites["overlay"].bitmap.fill_rect(0,0,width,@msgview.rect.height,Color.new(0,0,0))
      @sprites["overlay"].bitmap.fill_rect(@msgview.rect.width-width,0,width,@msgview.rect.height,Color.new(0,0,0))
      @sprites["overlay"].bitmap.fill_rect(0,0,@msgview.rect.width,height,Color.new(0,0,0))
      @sprites["overlay"].bitmap.fill_rect(0,@msgview.rect.height-height,@msgview.rect.width,height,Color.new(0,0,0))
      @sprites["overlay"].bitmap.stretch_blt(Rect.new(ox,oy,(@obmp.width*zoom).ceil,(@obmp.height*zoom).ceil),@obmp,@obmp.rect)
      @sprites["overlay"].opacity -= 12.8
      zoom += 4.0/20
      Graphics.update
    end
    # disposes of final graphic
    @sprites["overlay"].dispose
    @sentout = true
  end
  # disposes all sprites
  def dispose
    @disposed = true
    pbDisposeSpriteHash(@sprites)
  end
  # checks if disposed
  def disposed?; return @disposed; end
  # compatibility for pbFadeOutAndHide
  def color; end
  def color=(val); end
  # plays the little rainbow sequence before the animation (can be standalone)
  def rainbowIntro(viewport=nil)
    @viewport = viewport if !@viewport && !viewport.nil?
    @sprites = {} if !@sprites
    # takes screenshot
    bmp = Graphics.snap_to_bitmap
    # creates non-blurred overlay
    @sprites["bg1"] = Sprite.new(@viewport)
    @sprites["bg1"].bitmap = bmp
    @sprites["bg1"].ox = bmp.width/2
    @sprites["bg1"].oy = bmp.height/2
    @sprites["bg1"].x = @viewport.rect.width/2
    @sprites["bg1"].y = @viewport.rect.height/2
    # creates blurred overlay
    @sprites["bg2"] = Sprite.new(@viewport)
    @sprites["bg2"].bitmap = bmp
    @sprites["bg2"].blur_sprite(3)
    @sprites["bg2"].ox = bmp.width/2
    @sprites["bg2"].oy = bmp.height/2
    @sprites["bg2"].x = @viewport.rect.width/2
    @sprites["bg2"].y = @viewport.rect.height/2
    @sprites["bg2"].opacity = 0
    # creates rainbow rings
    for i in 1..2
      z = [0.35,0.1]
      @sprites["glow#{i}"] = Sprite.new(@viewport)
      @sprites["glow#{i}"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Common/glow")
      @sprites["glow#{i}"].ox = @sprites["glow#{i}"].bitmap.width/2
      @sprites["glow#{i}"].oy = @sprites["glow#{i}"].bitmap.height/2
      @sprites["glow#{i}"].x = @viewport.rect.width/2
      @sprites["glow#{i}"].y = @viewport.rect.height/2
      @sprites["glow#{i}"].zoom_x = z[i-1]
      @sprites["glow#{i}"].zoom_y = z[i-1]
      @sprites["glow#{i}"].opacity = 0
    end
    # main animation
    for i in 0...32
      # zooms in the two screenshots
      @sprites["bg1"].zoom_x += 0.02
      @sprites["bg1"].zoom_y += 0.02
      @sprites["bg2"].zoom_x += 0.02
      @sprites["bg2"].zoom_y += 0.02
      # fades in the blurry screenshot
      @sprites["bg2"].opacity += 12
      # fades to white
      if i >= 16
        @sprites["bg2"].tone.red += 16
        @sprites["bg2"].tone.green += 16
        @sprites["bg2"].tone.blue += 16
      end
      # zooms in rainbow rings
      if i >= 28
        @sprites["glow1"].opacity += 64
        @sprites["glow1"].zoom_x += 0.02
        @sprites["glow1"].zoom_y += 0.02
      end
      Graphics.update
    end
    # second part of animation
    for i in 0...52
      # zooms in rainbow rings
      @sprites["glow1"].zoom_x += 0.02
      @sprites["glow1"].zoom_y += 0.02
      if i >= 8
        @sprites["glow2"].opacity += 64
        @sprites["glow2"].zoom_x += 0.02
        @sprites["glow2"].zoom_y += 0.02
      end
      # fades viewport to white
      if i >= 36
        @viewport.color.alpha += 16
      end
      Graphics.update
    end
    # disposes of the elements
    pbDisposeSpriteHash(@sprites)
  end

  # displays the animation for the evil team logo (can be standalone)
  def evilTeam(viewport=nil)
    @viewport = viewport if !@viewport && !viewport.nil?
    @sprites = {} if !@sprites
    @viewport.color = Color.new(0,0,0,0)
    # fades viewport to black
    8.times do
      @viewport.color.alpha += 32
      pbWait(1)
    end
    # creates background graphic
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/EvilTeam/background")
    @sprites["bg"].color = Color.new(0,0,0)
    # creates background swirl
    @sprites["bg2"] = Sprite.new(@viewport)
    @sprites["bg2"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/EvilTeam/swirl")
    @sprites["bg2"].ox = @sprites["bg2"].bitmap.width/2
    @sprites["bg2"].oy = @sprites["bg2"].bitmap.height/2
    @sprites["bg2"].x = @viewport.rect.width/2
    @sprites["bg2"].y = @viewport.rect.height/2
    @sprites["bg2"].visible = false
    # sets up all particles
    speed = []
    for j in 0...16
      @sprites["e1_#{j}"] = Sprite.new(@viewport)
      bmp = pbBitmap("Graphics/Transitions/SunMoon/EvilTeam/ray0")
      @sprites["e1_#{j}"].bitmap = Bitmap.new(bmp.width,bmp.height)
      w = bmp.width/(1 + rand(3))
      @sprites["e1_#{j}"].bitmap.stretch_blt(Rect.new(0,0,w,bmp.height),bmp,Rect.new(0,0,bmp.width,bmp.height))
      @sprites["e1_#{j}"].oy = @sprites["e1_#{j}"].bitmap.height/2
      @sprites["e1_#{j}"].angle = rand(360)
      @sprites["e1_#{j}"].opacity = 0
      @sprites["e1_#{j}"].x = @viewport.rect.width/2
      @sprites["e1_#{j}"].y = @viewport.rect.height/2
      speed.push(4 + rand(5))
    end
    # creates logo
    @sprites["logo"] = Sprite.new(@viewport)
    @sprites["logo"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/EvilTeam/logo0")
    @sprites["logo"].ox = @sprites["logo"].bitmap.width/2
    @sprites["logo"].oy = @sprites["logo"].bitmap.height/2
    @sprites["logo"].x = @viewport.rect.width/2
    @sprites["logo"].y = @viewport.rect.height/2
    @sprites["logo"].memorize_bitmap
    @sprites["logo"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/EvilTeam/logo1")
    @sprites["logo"].zoom_x = 2
    @sprites["logo"].zoom_y = 2
    @sprites["logo"].z = 50
    # creates flash ring graphic
    @sprites["ring"] = Sprite.new(@viewport)
    @sprites["ring"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/EvilTeam/ring0")
    @sprites["ring"].ox = @sprites["ring"].bitmap.width/2
    @sprites["ring"].oy = @sprites["ring"].bitmap.height/2
    @sprites["ring"].x = @viewport.rect.width/2
    @sprites["ring"].y = @viewport.rect.height/2
    @sprites["ring"].zoom_x = 0
    @sprites["ring"].zoom_y = 0
    @sprites["ring"].z = 100
    # creates secondary particles
    for j in 0...32
      @sprites["e2_#{j}"] = Sprite.new(@viewport)
      bmp = pbBitmap("Graphics/Transitions/SunMoon/EvilTeam/ray1")
      @sprites["e2_#{j}"].bitmap = bmp
      @sprites["e2_#{j}"].oy = @sprites["e2_#{j}"].bitmap.height/2
      @sprites["e2_#{j}"].angle = rand(360)
      @sprites["e2_#{j}"].opacity = 0
      @sprites["e2_#{j}"].x = @viewport.rect.width/2
      @sprites["e2_#{j}"].y = @viewport.rect.height/2
      @sprites["e2_#{j}"].z = 100
    end
    # creates secondary flash ring
    @sprites["ring2"] = Sprite.new(@viewport)
    @sprites["ring2"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/EvilTeam/ring1")
    @sprites["ring2"].ox = @sprites["ring2"].bitmap.width/2
    @sprites["ring2"].oy = @sprites["ring2"].bitmap.height/2
    @sprites["ring2"].x = @viewport.rect.width/2
    @sprites["ring2"].y = @viewport.rect.height/2
    @sprites["ring2"].visible = false
    @sprites["ring2"].zoom_x = 0
    @sprites["ring2"].zoom_y = 0
    @sprites["ring2"].z = 100
    # first phase of animation
    for i in 0...32
      @viewport.color.alpha -= 8 if @viewport.color.alpha > 0
      @sprites["logo"].zoom_x -= 1/32.0
      @sprites["logo"].zoom_y -= 1/32.0
      for j in 0...16
        next if j > i/4
        if @sprites["e1_#{j}"].ox < -(@viewport.rect.width/2)
          speed[j] = 4 + rand(5)
          @sprites["e1_#{j}"].opacity = 0
          @sprites["e1_#{j}"].ox = 0
          @sprites["e1_#{j}"].angle = rand(360)
          bmp = pbBitmap("Graphics/Transitions/SunMoon/EvilTeam/ray1")
          @sprites["e1_#{j}"].bitmap.clear
          w = bmp.width/(1 + rand(3))
          @sprites["e1_#{j}"].bitmap.stretch_blt(Rect.new(0,0,w,bmp.height),bmp,Rect.new(0,0,bmp.width,bmp.height))
        end
        @sprites["e1_#{j}"].opacity += speed[j]
        @sprites["e1_#{j}"].ox -=  speed[j]
      end
      pbWait(1)
    end
    # configures logo graphic
    @sprites["logo"].color = Color.new(255,255,255)
    @sprites["logo"].restore_bitmap
    @sprites["ring2"].visible = true
    @sprites["bg2"].visible = true
    @viewport.color = Color.new(255,255,255)
    # final animation of background and particles
    for i in 0...144
      if i >= 128
        @viewport.color.alpha += 16
      else
        @viewport.color.alpha -= 16 if @viewport.color.alpha > 0
      end
      @sprites["logo"].color.alpha -= 16 if @sprites["logo"].color.alpha > 0
      @sprites["bg"].color.alpha -= 8 if @sprites["bg"].color.alpha > 0
      for j in 0...16
        if @sprites["e1_#{j}"].ox < -(@viewport.rect.width/2)
          speed[j] = 4 + rand(5)
          @sprites["e1_#{j}"].opacity = 0
          @sprites["e1_#{j}"].ox = 0
          @sprites["e1_#{j}"].angle = rand(360)
          bmp = pbBitmap("Graphics/Transitions/SunMoon/EvilTeam/ray0")
          @sprites["e1_#{j}"].bitmap.clear
          w = bmp.width/(1 + rand(3))
          @sprites["e1_#{j}"].bitmap.stretch_blt(Rect.new(0,0,w,bmp.height),bmp,Rect.new(0,0,bmp.width,bmp.height))
        end
        @sprites["e1_#{j}"].opacity += speed[j]
        @sprites["e1_#{j}"].ox -=  speed[j]
      end
      for j in 0...32
        next if j > i*2
        @sprites["e2_#{j}"].ox -= 16
        @sprites["e2_#{j}"].opacity += 16
      end
      @sprites["ring"].zoom_x += 0.1
      @sprites["ring"].zoom_y += 0.1
      @sprites["ring"].opacity -= 8
      @sprites["ring2"].zoom_x += 0.2 if @sprites["ring2"].zoom_x < 3
      @sprites["ring2"].zoom_y += 0.2 if @sprites["ring2"].zoom_y < 3
      @sprites["ring2"].opacity -= 16
      @sprites["bg2"].angle += 2 if $PokemonSystem.screensize < 2
      pbWait(1)
    end
    # disposes all sprites
    pbDisposeSpriteHash(@sprites)
    # fades viewport
    8.times do
      @viewport.color.red -= 255/8.0
      @viewport.color.green -= 255/8.0
      @viewport.color.blue -= 255/8.0
      pbWait(1)
    end
    return true
  end

  # plays Team Skull styled intro animation
  def teamSkull
    @fpIndex = 0
    @spIndex = 0

    pbWait(4)

    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Skull/background")
    @sprites["bg"].color = Color.new(0,0,0,92)

    for j in 0...20
      @sprites["s#{j}"] = Sprite.new(@viewport)
      @sprites["s#{j}"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Skull/smoke")
      @sprites["s#{j}"].center!(true)
      @sprites["s#{j}"].opacity = 0
    end

    for i in 0...16
      @sprites["r#{i}"] = Sprite.new(@viewport)
      @sprites["r#{i}"].opacity = 0
    end

    @sprites["logo"] = Sprite.new(@viewport)
    @sprites["logo"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Skull/logo")
    @sprites["logo"].center!(true)
    @sprites["logo"].z = 9999
    @sprites["logo"].zoom_x = 2
    @sprites["logo"].zoom_y = 2
    @sprites["logo"].color = Color.new(0,0,0)

    @sprites["shine"] = Sprite.new(@viewport)
    @sprites["shine"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Skull/shine")
    @sprites["shine"].center!(true)
    @sprites["shine"].x -= 72
    @sprites["shine"].y -= 64
    @sprites["shine"].z = 99999
    @sprites["shine"].opacity = 0
    @sprites["shine"].zoom_x = 0.6
    @sprites["shine"].zoom_y = 0.4
    @sprites["shine"].angle = 30

    @sprites["rainbow"] = Sprite.new(@viewport)
    @sprites["rainbow"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Skull/rainbow")
    @sprites["rainbow"].center!(true)
    @sprites["rainbow"].z = 99999
    @sprites["rainbow"].opacity = 0

    @sprites["glow"] = Sprite.new(@viewport)
    @sprites["glow"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Skull/glow")
    @sprites["glow"].center!(true)
    @sprites["glow"].opacity = 0
    @sprites["glow"].z = 9
    @sprites["glow"].zoom_x = 0.6
    @sprites["glow"].zoom_y = 0.6

    @sprites["burst"] = Sprite.new(@viewport)
    @sprites["burst"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Skull/burst")
    @sprites["burst"].center!(true)
    @sprites["burst"].zoom_x = 0
    @sprites["burst"].zoom_y = 0
    @sprites["burst"].opacity = 0
    @sprites["burst"].z = 999
    @sprites["burst"].color = Color.new(255,255,255,0)

    for j in 0...24
      @sprites["p#{j}"] = Sprite.new(@viewport)
      @sprites["p#{j}"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Skull/particle")
      @sprites["p#{j}"].center!(true)
      z = 1 - rand(81)/100.0
      @sprites["p#{j}"].zoom_x = z
      @sprites["p#{j}"].zoom_y = z
      @sprites["p#{j}"].param = 1 + rand(8)
      r = 256 + rand(65)
      cx, cy = randCircleCord(r)
      @sprites["p#{j}"].ex = @sprites["p#{j}"].x - r + cx
      @sprites["p#{j}"].ey = @sprites["p#{j}"].y - r + cy
      r = rand(33)/100.0
      @sprites["p#{j}"].x = @viewport.rect.width/2 - (@sprites["p#{j}"].ex - @viewport.rect.width/2)*r
      @sprites["p#{j}"].y = @viewport.rect.height/2 - (@viewport.rect.height/2 - @sprites["p#{j}"].ey)*r
      @sprites["p#{j}"].visible = false
    end

    x = [@viewport.rect.width/3,@viewport.rect.width+32,16,-32,2*@viewport.rect.width/3,@viewport.rect.width+32,0,@viewport.rect.width+64]
    y = [@viewport.rect.height+32,@viewport.rect.height+32,-32,@viewport.rect.height/2,@viewport.rect.height+64,@viewport.rect.height/2,@viewport.rect.height-64,@viewport.rect.height/2+32]
    a = [50,135,-70,10,105,165,-30,190]
    for j in 0...8
      @sprites["sl#{j}"] = Sprite.new(@viewport)
      @sprites["sl#{j}"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Skull/paint0")
      @sprites["sl#{j}"].oy = @sprites["sl#{j}"].bitmap.height/2
      @sprites["sl#{j}"].z = j < 2 ? 999 : 99999
      @sprites["sl#{j}"].ox = -@sprites["sl#{j}"].bitmap.width
      @sprites["sl#{j}"].x = x[j]
      @sprites["sl#{j}"].y = y[j]
      @sprites["sl#{j}"].angle = a[j]
      @sprites["sl#{j}"].param = (@sprites["sl#{j}"].bitmap.width/8)
    end

    for j in 0...12
      @sprites["sp#{j}"] = Sprite.new(@viewport)
      @sprites["sp#{j}"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Skull/splat#{rand(3)}")
      @sprites["sp#{j}"].center!(true)
      @sprites["sp#{j}"].x = rand(@viewport.rect.width)
      @sprites["sp#{j}"].y = rand(@viewport.rect.height)
      @sprites["sp#{j}"].visible = false
      z = 1 + rand(40)/100.0
      @sprites["sp#{j}"].zoom_x = z
      @sprites["sp#{j}"].zoom_y = z
      @sprites["sp#{j}"].z = 99999
    end

    for i in 0...32
      @viewport.color.alpha -= 16
      @sprites["logo"].zoom_x -= 1/32.0
      @sprites["logo"].zoom_y -= 1/32.0
      @sprites["logo"].color.alpha -= 8
      for j in 0...16
        next if j > @fpIndex/2
        if @sprites["r#{j}"].opacity <= 0
          bmp = pbBitmap("Graphics/Transitions/SunMoon/Skull/ray")
          w = rand(65) + 16
          @sprites["r#{j}"].bitmap = Bitmap.new(w,bmp.height)
          @sprites["r#{j}"].bitmap.stretch_blt(@sprites["r#{j}"].bitmap.rect,bmp,bmp.rect)
          @sprites["r#{j}"].center!(true)
          @sprites["r#{j}"].ox = -(64 + rand(17))
          @sprites["r#{j}"].zoom_x = 1
          @sprites["r#{j}"].zoom_y = 1
          @sprites["r#{j}"].angle = rand(360)
          @sprites["r#{j}"].param = 2 + rand(5)
        end
        @sprites["r#{j}"].ox -= @sprites["r#{j}"].param
        @sprites["r#{j}"].zoom_x += 0.001*@sprites["r#{j}"].param
        @sprites["r#{j}"].zoom_y -= 0.001*@sprites["r#{j}"].param
        if @sprites["r#{j}"].ox > -128
          @sprites["r#{j}"].opacity += 8
        else
          @sprites["r#{j}"].opacity -= 2*@sprites["r#{j}"].param
        end
      end
      if i >= 24
        @sprites["shine"].opacity += 48
        @sprites["shine"].zoom_x += 0.02
        @sprites["shine"].zoom_y += 0.02
      end
      @fpIndex += 1
      Graphics.update
    end
    @viewport.color = Color.new(0,0,0,0)
    for i in 0...128
      @sprites["shine"].opacity -= 16
      @sprites["shine"].zoom_x += 0.02
      @sprites["shine"].zoom_y += 0.02
      if i < 8
        z = (i < 4) ? 0.02 : -0.02
        @sprites["logo"].zoom_x -= z
        @sprites["logo"].zoom_y -= z
      end
      for j in 0...16
        if @sprites["r#{j}"].opacity <= 0
          bmp = pbBitmap("Graphics/Transitions/SunMoon/Skull/ray")
          w = rand(65) + 16
          @sprites["r#{j}"].bitmap = Bitmap.new(w,bmp.height)
          @sprites["r#{j}"].bitmap.stretch_blt(@sprites["r#{j}"].bitmap.rect,bmp,bmp.rect)
          @sprites["r#{j}"].center!(true)
          @sprites["r#{j}"].ox = -(64 + rand(17))
          @sprites["r#{j}"].zoom_x = 1
          @sprites["r#{j}"].zoom_y = 1
          @sprites["r#{j}"].angle = rand(360)
          @sprites["r#{j}"].param = 2 + rand(5)
        end
        @sprites["r#{j}"].ox -= @sprites["r#{j}"].param
        @sprites["r#{j}"].zoom_x += 0.001*@sprites["r#{j}"].param
        @sprites["r#{j}"].zoom_y -= 0.001*@sprites["r#{j}"].param
        if @sprites["r#{j}"].ox > -128
          @sprites["r#{j}"].opacity += 8
        else
          @sprites["r#{j}"].opacity -= 2*@sprites["r#{j}"].param
        end
      end
      for j in 0...24
        @sprites["p#{j}"].visible = true
        next if @sprites["p#{j}"].opacity <= 0
        x = (@sprites["p#{j}"].ex - @viewport.rect.width/2)/(4.0*@sprites["p#{j}"].param)
        y = (@viewport.rect.height/2 - @sprites["p#{j}"].ey)/(4.0*@sprites["p#{j}"].param)
        @sprites["p#{j}"].x -= x
        @sprites["p#{j}"].y -= y
        @sprites["p#{j}"].opacity -= @sprites["p#{j}"].param
      end
      for j in 0...20
        if @sprites["s#{j}"].opacity <= 0
          @sprites["s#{j}"].opacity = 255
          r = 160 + rand(33)
          cx, cy = randCircleCord(r)
          @sprites["s#{j}"].center!(true)
          @sprites["s#{j}"].ex = @sprites["s#{j}"].x - r + cx
          @sprites["s#{j}"].ey = @sprites["s#{j}"].y - r + cy
          @sprites["s#{j}"].toggle = rand(2)==0 ? 2 : -2
          @sprites["s#{j}"].param = 2 + rand(4)
          z = 1 - rand(41)/100.0
          @sprites["s#{j}"].zoom_x = z
          @sprites["s#{j}"].zoom_y = z
        end
        @sprites["s#{j}"].x -= (@sprites["s#{j}"].x - @sprites["s#{j}"].ex)*0.02
        @sprites["s#{j}"].y -= (@sprites["s#{j}"].y - @sprites["s#{j}"].ey)*0.02
        @sprites["s#{j}"].opacity -= @sprites["s#{j}"].param*1.5
        @sprites["s#{j}"].angle += @sprites["s#{j}"].toggle if $PokemonSystem.screensize < 2
        @sprites["s#{j}"].zoom_x -= 0.002
        @sprites["s#{j}"].zoom_y -= 0.002
      end
      @sprites["bg"].color.alpha -= 2
      @sprites["glow"].opacity += (i < 6) ? 48 : -24
      @sprites["glow"].zoom_x += 0.05
      @sprites["glow"].zoom_y += 0.05
      @sprites["rainbow"].zoom_x += 0.01
      @sprites["rainbow"].zoom_y += 0.01
      @sprites["rainbow"].opacity += (i < 16) ? 32 : -16
      @sprites["burst"].zoom_x += 0.2
      @sprites["burst"].zoom_y += 0.2
      @sprites["burst"].color.alpha += 20
      @sprites["burst"].opacity += 16
      if i >= 72
        for j in 0...8
          next if j > @spIndex/6
          @sprites["sl#{j}"].ox += @sprites["sl#{j}"].param if @sprites["sl#{j}"].ox < 0
        end
        for j in 0...12
          next if @spIndex < 4
          next if j > (@spIndex-4)/4
          @sprites["sp#{j}"].visible = true
        end
        @spIndex += 1
      end
      @viewport.color.alpha += 16 if i >= 112
      Graphics.update
    end
    pbDisposeSpriteHash(@sprites)
  end
  # fetches secondary parameters for the animations
  def getParameters(trainerid)
    # method used to check if battling against a registered evil team member
    @evilteam = false
=begin
    for val in EVIL_TEAM_LIST
      if val.is_a?(Numeric)
        id = val
      elsif val.is_a?(Symbol)
        id = getConst(PBTrainers,val)
      end
      @evilteam = true if !id.nil? && trainerid == id
    end
=end
    # methods used to determine special variants
    ext = ["trainer","special","elite","crazy","ultra","digital","plasma","skull"]
    #ext.push("trainer")
    @variant = "trainer"
    for i in 0...ext.length
      @variant = ext[i] if pbResolveBitmap(sprintf("Graphics/Transitions/SunMoon/%s%03d",ext[i],trainerid))
    end
    # sets up the rest of the variables
    @obmp = pbBitmap("Graphics/Transitions/SunMoon/Common/ballTransition")
  end
end

#-------------------------------------------------------------------------------
#  New class used to render the Sun & Moon styled VS background
#-------------------------------------------------------------------------------
class SunMoonDefaultBackground
  attr_reader :speed
  # main method to create the background
  def initialize(viewport,trainerid,evilteam=false,teamskull=false)
    @viewport = viewport
    @trainerid = trainerid
    @evilteam = evilteam
    @teamskull = teamskull
    @disposed = false
    @speed = 1
    @sprites = {}
    # reverts to default
    bg = ["Graphics/Transitions/SunMoon/Default/background",
          "Graphics/Transitions/SunMoon/Default/layer",
          "Graphics/Transitions/SunMoon/Default/final"
         ]
    # gets specific graphics
    for i in 0...3
      str = sprintf("%s%03d",bg[i],trainerid)
      evl = bg[i] + "Evil"
      skl = bg[i] + "Skull"
      bg[i] = evl if pbResolveBitmap(evl) && @evilteam
      bg[i] = skl if pbResolveBitmap(skl) && @teamskull
      bg[i] = str if pbResolveBitmap(str)
    end
    # creates the 3 background layers
    for i in 0...3
      @sprites["bg#{i}"] = ScrollingSprite.new(@viewport)
      @sprites["bg#{i}"].setBitmap(bg[i],false,(i > 0))
      @sprites["bg#{i}"].z = 200
      @sprites["bg#{i}"].ox = @sprites["bg#{i}"].src_rect.width/2
      @sprites["bg#{i}"].oy = @sprites["bg#{i}"].src_rect.height/2
      @sprites["bg#{i}"].x = viewport.rect.width/2
      @sprites["bg#{i}"].y = viewport.rect.height/2
      @sprites["bg#{i}"].angle = - 8 if $PokemonSystem.screensize < 2
      @sprites["bg#{i}"].color = Color.new(0,0,0)
    end
  end
  # sets the speed of the sprites
  def speed=(val)
    for i in 0...3
      @sprites["bg#{i}"].speed = val*(i + 1)
    end
  end
  # updates the background
  def update
    return if self.disposed?
    for i in 0...3
      @sprites["bg#{i}"].update
    end
  end
  # used to fade in from black
  def reduceAlpha(factor)
    for i in 0...3
      @sprites["bg#{i}"].color.alpha -= factor
    end
  end
  # disposes of everything
  def dispose
    @disposed = true
    pbDisposeSpriteHash(@sprites)
  end
  # checks if disposed
  def disposed?; return @disposed; end
  # used to show other elements
  def show; end
end
#-------------------------------------------------------------------------------
#  New class used to render the special Sun & Moon styled VS background
#-------------------------------------------------------------------------------
class SunMoonSpecialBackground
  attr_reader :speed
  # main method to create the background
  def initialize(viewport,trainerid,evilteam=false)
    @viewport = viewport
    @trainerid = trainerid
    @evilteam = evilteam
    @disposed = false
    @speed = 1
    @sprites = {}
    # creates the background
    @sprites["background"] = RainbowSprite.new(@viewport)
    @sprites["background"].setBitmap("Graphics/Transitions/SunMoon/Special/background")
    @sprites["background"].color = Color.new(0,0,0)
    @sprites["background"].z = 200
    # handles the particles for the animation
    @vsFp = {}
    @fpDx = []
    @fpDy = []
    @fpIndex = 0
    # loads ring effect
    @sprites["ring"] = Sprite.new(@viewport)
    @sprites["ring"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Special/ring")
    @sprites["ring"].ox = @sprites["ring"].bitmap.width/2
    @sprites["ring"].oy = @sprites["ring"].bitmap.height/2
    @sprites["ring"].x = @viewport.rect.width/2
    @sprites["ring"].y = @viewport.rect.height
    @sprites["ring"].zoom_x = 0
    @sprites["ring"].zoom_y = 0
    @sprites["ring"].z = 500
    @sprites["ring"].visible = false
    @sprites["ring"].color = Color.new(0,0,0)
    # loads sparkle particles
    for j in 0...32
      @sprites["s#{j}"] = Sprite.new(@viewport)
      @sprites["s#{j}"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Special/particle")
      @sprites["s#{j}"].ox = @sprites["s#{j}"].bitmap.width/2
      @sprites["s#{j}"].oy = @sprites["s#{j}"].bitmap.height/2
      @sprites["s#{j}"].opacity = 0
      @sprites["s#{j}"].z = 220
      @sprites["s#{j}"].color = Color.new(0,0,0)
      @fpDx.push(0)
      @fpDy.push(0)
    end
    @fpSpeed = []
    @fpOpac = []
    # loads scrolling particles
    for j in 0...3
      k = j+1
      speed = 2 + rand(5)
      @sprites["p#{j}"] = ScrollingSprite.new(@viewport)
      @sprites["p#{j}"].setBitmap("Graphics/Transitions/SunMoon/Special/glow#{j}")
      @sprites["p#{j}"].speed = speed*4
      @sprites["p#{j}"].direction = -1
      @sprites["p#{j}"].opacity = 0
      @sprites["p#{j}"].z = 220
      @sprites["p#{j}"].zoom_y = 1 + rand(10)*0.005
      @sprites["p#{j}"].color = Color.new(0,0,0)
      @fpSpeed.push(speed)
      @fpOpac.push(4) if j > 0
    end
  end
  # sets the speed of the sprites
  def speed=(val)
    val = 16 if val > 16
    for j in 0...3
      @sprites["p#{j}"].speed = val*2
    end
  end
  # updates the background
  def update
    return if self.disposed?
    # updates background
    @sprites["background"].update
    # updates ring
    if @sprites["ring"].visible && @sprites["ring"].opacity > 0
      @sprites["ring"].zoom_x += 0.2
      @sprites["ring"].zoom_y += 0.2
      @sprites["ring"].opacity -= 16
    end
    # updates sparkle particles
    for j in 0...32
      next if !@sprites["ring"].visible
      next if !@sprites["s#{j}"] || @sprites["s#{j}"].disposed?
      next if j > @fpIndex/4
      if @sprites["s#{j}"].opacity <= 1
        width = @viewport.rect.width
        height = @viewport.rect.height
        x = rand(width*0.75) + width*0.125
        y = rand(height*0.50) + height*0.25
        @fpDx[j] = x + rand(width*0.125)*(x < width/2 ? -1 : 1)
        @fpDy[j] = y - rand(height*0.25)
        z = [1,0.75,0.5,0.25][rand(4)]
        @sprites["s#{j}"].zoom_x = z
        @sprites["s#{j}"].zoom_y = z
        @sprites["s#{j}"].x = x
        @sprites["s#{j}"].y = y
        @sprites["s#{j}"].opacity = 255
        @sprites["s#{j}"].angle = rand(360)
      end
      @sprites["s#{j}"].x -= (@sprites["s#{j}"].x - @fpDx[j])*0.05
      @sprites["s#{j}"].y -= (@sprites["s#{j}"].y - @fpDy[j])*0.05
      @sprites["s#{j}"].opacity -= @sprites["s#{j}"].opacity*0.05
      @sprites["s#{j}"].zoom_x -= @sprites["s#{j}"].zoom_x*0.05
      @sprites["s#{j}"].zoom_y -= @sprites["s#{j}"].zoom_y*0.05
    end
    # updates scrolling particles
    for j in 0...3
      next if !@sprites["p#{j}"] || @sprites["p#{j}"].disposed?
      @sprites["p#{j}"].update
      if j == 0
        @sprites["p#{j}"].opacity += 5 if @sprites["p#{j}"].opacity < 155
      else
        @sprites["p#{j}"].opacity += @fpOpac[j-1]*(@fpSpeed[j]/2)
      end
      next if @fpIndex < 24
      @fpOpac[j-1] *= -1 if (@sprites["p#{j}"].opacity >= 255 || @sprites["p#{j}"].opacity < 65)
    end
    @fpIndex += 1 if @fpIndex < 150
  end
  # used to fade in from black
  def reduceAlpha(factor)
    for key in @sprites.keys
      @sprites[key].color.alpha -= factor
    end
  end
  # disposes of everything
  def dispose
    @disposed = true
    pbDisposeSpriteHash(@sprites)
  end
  # checks if disposed
  def disposed?; return @disposed; end
  # used to show other elements
  def show
    for j in 0...3
      @sprites["p#{j}"].visible = true
    end
    @sprites["ring"].visible = true
    @fpIndex = 0
  end
end
#-------------------------------------------------------------------------------
#  New class used to render the Sun & Moon kahuna VS background
#-------------------------------------------------------------------------------
class SunMoonEliteBackground
  attr_reader :speed
  # main method to create the background
  def initialize(viewport,trainerid,evilteam=false)
    @viewport = viewport
    @trainerid = trainerid
    @evilteam = evilteam
    @disposed = false
    @speed = 1
    @sprites = {}
    @fpIndex = 0
    # checks for appropriate files
    bg = ["Graphics/Transitions/SunMoon/Elite/background",
          "Graphics/Transitions/SunMoon/Elite/vacuum"
         ]
    for i in 0...2
      str = sprintf("%s%03d",bg[i],trainerid)
      bg[i] = str if pbResolveBitmap(str)
    end
    # creates the background
    @sprites["background"] = Sprite.new(@viewport)
    @sprites["background"].bitmap = pbBitmap(bg[0])
    @sprites["background"].center!
    @sprites["background"].x = @viewport.rect.width/2
    @sprites["background"].y = @viewport.rect.height/2
    @sprites["background"].color = Color.new(0,0,0)
    @sprites["background"].z = 200
    # creates particles flying out of the center
    for j in 0...16
      @sprites["e#{j}"] = Sprite.new(@viewport)
      bmp = pbBitmap("Graphics/Transitions/SunMoon/Elite/particle")
      @sprites["e#{j}"].bitmap = Bitmap.new(bmp.width,bmp.height)
      w = bmp.width/(1 + rand(3))
      @sprites["e#{j}"].bitmap.stretch_blt(Rect.new(0,0,w,bmp.height),bmp,Rect.new(0,0,bmp.width,bmp.height))
      @sprites["e#{j}"].oy = @sprites["e#{j}"].bitmap.height/2
      @sprites["e#{j}"].angle = rand(360)
      @sprites["e#{j}"].opacity = 0
      @sprites["e#{j}"].x = @viewport.rect.width/2
      @sprites["e#{j}"].y = @viewport.rect.height/2
      @sprites["e#{j}"].speed = (4 + rand(5))
      @sprites["e#{j}"].z = 220
      @sprites["e#{j}"].color = Color.new(0,0,0)
    end
    # creates vacuum waves
    for j in 0...3
      @sprites["ec#{j}"] = Sprite.new(@viewport)
      @sprites["ec#{j}"].bitmap = pbBitmap(bg[1])
      @sprites["ec#{j}"].ox = @sprites["ec#{j}"].bitmap.width/2
      @sprites["ec#{j}"].oy = @sprites["ec#{j}"].bitmap.height/2
      @sprites["ec#{j}"].x = @viewport.rect.width/2
      @sprites["ec#{j}"].y = @viewport.rect.height/2
      @sprites["ec#{j}"].zoom_x = 1.5
      @sprites["ec#{j}"].zoom_y = 1.5
      @sprites["ec#{j}"].opacity = 0
      @sprites["ec#{j}"].z = 205
      @sprites["ec#{j}"].color = Color.new(0,0,0)
    end
    # creates center glow
    @sprites["shine"] = Sprite.new(@viewport)
    @sprites["shine"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Elite/shine")
    @sprites["shine"].ox = @sprites["shine"].src_rect.width/2
    @sprites["shine"].oy = @sprites["shine"].src_rect.height/2
    @sprites["shine"].x = @viewport.rect.width/2
    @sprites["shine"].y = @viewport.rect.height/2
    @sprites["shine"].z = 210
    @sprites["shine"].visible = false
  end
  # sets the speed of the sprites
  def speed=(val); end
  # updates the background
  def update
    return if self.disposed?
    # background and shine
    @sprites["background"].angle += 1 if $PokemonSystem.screensize < 2
    @sprites["shine"].angle -= 1 if $PokemonSystem.screensize < 2
    # updates (and resets) the particles flying from the center
    for j in 0...16
      next if !@sprites["shine"].visible
      if @sprites["e#{j}"].ox < -(@sprites["e#{j}"].viewport.rect.width/2)
        @sprites["e#{j}"].speed = 4 + rand(5)
        @sprites["e#{j}"].opacity = 0
        @sprites["e#{j}"].ox = 0
        @sprites["e#{j}"].angle = rand(360)
        bmp = pbBitmap("Graphics/Transitions/SunMoon/Elite/particle")
        @sprites["e#{j}"].bitmap.clear
        w = bmp.width/(1 + rand(3))
        @sprites["e#{j}"].bitmap.stretch_blt(Rect.new(0,0,w,bmp.height),bmp,Rect.new(0,0,bmp.width,bmp.height))
      end
      @sprites["e#{j}"].opacity += @sprites["e#{j}"].speed
      @sprites["e#{j}"].ox -=  @sprites["e#{j}"].speed
    end
    # updates the vacuum waves
    for j in 0...3
      next if j > @fpIndex/50
      if @sprites["ec#{j}"].zoom_x <= 0
        @sprites["ec#{j}"].zoom_x = 1.5
        @sprites["ec#{j}"].zoom_y = 1.5
        @sprites["ec#{j}"].opacity = 0
      end
      @sprites["ec#{j}"].opacity +=  8
      @sprites["ec#{j}"].zoom_x -= 0.01
      @sprites["ec#{j}"].zoom_y -= 0.01
    end
    @fpIndex += 1 if @fpIndex < 150
  end
  # used to show other elements
  def show
    @sprites["shine"].visible = true
  end
  # used to fade in from black
  def reduceAlpha(factor)
    for key in @sprites.keys
      @sprites[key].color.alpha -= factor
    end
  end
  # disposes of everything
  def dispose
    @disposed = true
    pbDisposeSpriteHash(@sprites)
  end
  # checks if disposed
  def disposed?; return @disposed; end

end
#-------------------------------------------------------------------------------
#  New class used to render the Mother Beast Lusamine styled VS background
#-------------------------------------------------------------------------------
class SunMoonCrazyBackground
  attr_accessor :speed
  # main method to create the background
  def initialize(viewport,trainerid,evilteam=false)
    @viewport = viewport
    @trainerid = trainerid
    @evilteam = evilteam
    @disposed = false
    @speed = 1
    @sprites = {}
    # draws a black backdrop
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].drawRect(@viewport.rect.width,@viewport.rect.height,Color.new(0,0,0))
    @sprites["bg"].z = 200
    @sprites["bg"].color = Color.new(0,0,0)
    # draws the 3 circular patterns that change hue
    for j in 0...3
      @sprites["b#{j}"] = RainbowSprite.new(@viewport)
      @sprites["b#{j}"].setBitmap("Graphics/Transitions/SunMoon/Crazy/ring#{j}",8)
      @sprites["b#{j}"].ox = @sprites["b#{j}"].bitmap.width/2
      @sprites["b#{j}"].oy = @sprites["b#{j}"].bitmap.height/2
      @sprites["b#{j}"].x = @viewport.rect.width/2
      @sprites["b#{j}"].y = @viewport.rect.height/2
      @sprites["b#{j}"].zoom_x = 0.6 + 0.6*j
      @sprites["b#{j}"].zoom_y = 0.6 + 0.6*j
      @sprites["b#{j}"].opacity = 64 + 64*(1+j)
      @sprites["b#{j}"].z = 250
      @sprites["b#{j}"].color = Color.new(0,0,0)
    end
    # draws all the particles
    for j in 0...64
      @sprites["p#{j}"] = Sprite.new(@viewport)
      @sprites["p#{j}"].z = 300
      width = 16 + rand(48)
      height = 16 + rand(16)
      @sprites["p#{j}"].bitmap = Bitmap.new(width,height)
      bmp = pbBitmap("Graphics/Transitions/SunMoon/Crazy/particle")
      @sprites["p#{j}"].bitmap.stretch_blt(Rect.new(0,0,width,height),bmp,Rect.new(0,0,bmp.width,bmp.height))
      @sprites["p#{j}"].bitmap.hue_change(rand(360))
      @sprites["p#{j}"].ox = width/2
      @sprites["p#{j}"].oy = height + 192 + rand(32)
      @sprites["p#{j}"].angle = rand(360)
      @sprites["p#{j}"].speed = 1 + rand(4)
      @sprites["p#{j}"].x = @viewport.rect.width/2
      @sprites["p#{j}"].y = @viewport.rect.height/2
      @sprites["p#{j}"].zoom_x = (@sprites["p#{j}"].oy/192.0)*1.5
      @sprites["p#{j}"].zoom_y = (@sprites["p#{j}"].oy/192.0)*1.5
      @sprites["p#{j}"].color = Color.new(0,0,0)
    end
    @frame = 0
  end
  # sets the speed of the sprites
  def speed=(val); end
  # updates the background
  def update
    return if self.disposed?
    # updates the 3 circular patterns changing their hue
    for j in 0...3
      @sprites["b#{j}"].zoom_x -= 0.025
      @sprites["b#{j}"].zoom_y -= 0.025
      @sprites["b#{j}"].opacity -= 4
      if @sprites["b#{j}"].zoom_x <= 0 || @sprites["b#{j}"].opacity <= 0
        @sprites["b#{j}"].zoom_x = 2.25
        @sprites["b#{j}"].zoom_y = 2.25
        @sprites["b#{j}"].opacity = 255
      end
      @sprites["b#{j}"].update if @frame%8==0
    end
    # animates all the particles
    for j in 0...64
      @sprites["p#{j}"].angle -= @sprites["p#{j}"].speed
      @sprites["p#{j}"].opacity -= @sprites["p#{j}"].speed
      @sprites["p#{j}"].oy -= @sprites["p#{j}"].speed/2 if @sprites["p#{j}"].oy > @sprites["p#{j}"].bitmap.height
      @sprites["p#{j}"].zoom_x = (@sprites["p#{j}"].oy/192.0)*1.5
      @sprites["p#{j}"].zoom_y = (@sprites["p#{j}"].oy/192.0)*1.5
      if @sprites["p#{j}"].zoom_x <= 0 || @sprites["p#{j}"].oy <= 0 || @sprites["p#{j}"].opacity <= 0
        @sprites["p#{j}"].angle = rand(360)
        @sprites["p#{j}"].oy = @sprites["p#{j}"].bitmap.height + 192 + rand(32)
        @sprites["p#{j}"].zoom_x = (@sprites["p#{j}"].oy/192.0)*1.5
        @sprites["p#{j}"].zoom_y = (@sprites["p#{j}"].oy/192.0)*1.5
        @sprites["p#{j}"].opacity = 255
        @sprites["p#{j}"].speed = 1 + rand(4)
      end
    end
    @frame += 1
    @frame = 0 if @frame > 128
  end
  # used to fade in from black
  def reduceAlpha(factor)
    for key in @sprites.keys
      @sprites[key].color.alpha -= factor
    end
  end
  # disposes of everything
  def dispose
    @disposed = true
    pbDisposeSpriteHash(@sprites)
  end
  # checks if disposed
  def disposed?; return @disposed; end
  # used to show other elements
  def show; end

end
#-------------------------------------------------------------------------------
#  New class used to render the ultra squad Sun & Moon styled VS background
#-------------------------------------------------------------------------------
class SunMoonUltraBackground
  attr_reader :speed
  # main method to create the background
  def initialize(viewport,trainerid,evilteam=false)
    @viewport = viewport
    @trainerid = trainerid
    @evilteam = evilteam
    @disposed = false
    @speed = 1
    @fpIndex = 0
    @sprites = {}
    # creates the background layer
    @sprites["background"] = RainbowSprite.new(@viewport)
    @sprites["background"].setBitmap("Graphics/Transitions/SunMoon/Ultra/background",2)
    @sprites["background"].color = Color.new(0,0,0)
    @sprites["background"].z = 200
    @sprites["paths"] = RainbowSprite.new(@viewport)
    @sprites["paths"].setBitmap("Graphics/Transitions/SunMoon/Ultra/overlay",2)
    @sprites["paths"].center!
    @sprites["paths"].x = @viewport.rect.width/2
    @sprites["paths"].y = @viewport.rect.height/2
    @sprites["paths"].color = Color.new(0,0,0)
    @sprites["paths"].z = 200
    @sprites["paths"].opacity = 215
    @sprites["paths"].toggle = 1
    @sprites["paths"].visible = false
    # creates the shine effect
    @sprites["shine"] = Sprite.new(@viewport)
    @sprites["shine"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Ultra/shine")
    @sprites["shine"].center!
    @sprites["shine"].x = @viewport.rect.width/2
    @sprites["shine"].y = @viewport.rect.height/2
    @sprites["shine"].color = Color.new(0,0,0)
    @sprites["shine"].z = 200
    # creates the hexagonal zoom patterns
    for i in 0...12
      @sprites["h#{i}"] = Sprite.new(@viewport)
      @sprites["h#{i}"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Ultra/ring")
      @sprites["h#{i}"].center!
      @sprites["h#{i}"].x = @viewport.rect.width/2
      @sprites["h#{i}"].y = @viewport.rect.height/2
      @sprites["h#{i}"].color = Color.new(0,0,0)
      @sprites["h#{i}"].z = 220
      z = 1
      @sprites["h#{i}"].zoom_x = z
      @sprites["h#{i}"].zoom_y = z
      @sprites["h#{i}"].opacity = 255
    end
    for i in 0...16
      @sprites["p#{i}"] = Sprite.new(@viewport)
      @sprites["p#{i}"].bitmap = pbBitmap("Graphics/Transitions/SunMoon/Ultra/particle")
      @sprites["p#{i}"].oy = @sprites["p#{i}"].bitmap.height/2
      @sprites["p#{i}"].x = @viewport.rect.width/2
      @sprites["p#{i}"].y = @viewport.rect.height/2
      @sprites["p#{i}"].angle = rand(360)
      @sprites["p#{i}"].color = Color.new(0,0,0)
      @sprites["p#{i}"].z = 210
      @sprites["p#{i}"].visible = false
    end
    160.times do
      self.update(true)
    end
  end
  # sets the speed of the sprites
  def speed=(val)
  end
  # updates the background
  def update(skip=false)
    return if self.disposed?
    if !skip
      @sprites["background"].update
      @sprites["shine"].angle -= 1 if $PokemonSystem.screensize < 2
      @sprites["paths"].update
      @sprites["paths"].opacity -= @sprites["paths"].toggle*2
      @sprites["paths"].toggle *= -1 if @sprites["paths"].opacity <= 85 || @sprites["paths"].opacity >= 215
    end
    for i in 0...12
      next if i > @fpIndex/32
      if @sprites["h#{i}"].opacity <= 0
        @sprites["h#{i}"].zoom_x = 1
        @sprites["h#{i}"].zoom_y = 1
        @sprites["h#{i}"].opacity = 255
      end
      @sprites["h#{i}"].zoom_x += 0.003*(@sprites["h#{i}"].zoom_x**2)
      @sprites["h#{i}"].zoom_y += 0.003*(@sprites["h#{i}"].zoom_y**2)
      @sprites["h#{i}"].opacity -= 1
    end
    for i in 0...16
      next if i > @fpIndex/8
      if @sprites["p#{i}"].opacity <= 0
        @sprites["p#{i}"].ox = 0
        @sprites["p#{i}"].angle = rand(360)
        @sprites["p#{i}"].zoom_x = 1
        @sprites["p#{i}"].zoom_y = 1
        @sprites["p#{i}"].opacity = 255
      end
      @sprites["p#{i}"].opacity -= 2
      @sprites["p#{i}"].ox -= 4
      @sprites["p#{i}"].zoom_x += 0.001
      @sprites["p#{i}"].zoom_y += 0.001
    end
    @fpIndex += 1 if @fpIndex < 512
  end
  # used to fade in from black
  def reduceAlpha(factor)
    for key in @sprites.keys
      @sprites[key].color.alpha -= factor
    end
  end
  # disposes of everything
  def dispose
    @disposed = true
    pbDisposeSpriteHash(@sprites)
  end
  # checks if disposed
  def disposed?; return @disposed; end
  # used to show other elements
  def show
    for i in 0...16
      @sprites["p#{i}"].visible = true
    end
    @sprites["paths"].visible = true
  end
end
#-------------------------------------------------------------------------------
#  New class used to render a custom Sun & Moon styled VS background
#-------------------------------------------------------------------------------
class SunMoonDigitalBackground
  attr_reader :speed
  # main method to create the background
  def initialize(viewport,trainerid,evilteam=false)
    @viewport = viewport
    @trainerid = trainerid
    @evilteam = evilteam
    @disposed = false
    @speed = 1
    @sprites = {}
    @tiles = []
    @data = []
    @fpIndex = 0
    # allows for custom graphics as well
    files = ["Graphics/Transitions/SunMoon/Digital/background",
             "Graphics/Transitions/SunMoon/Digital/particle",
             "Graphics/Transitions/SunMoon/Digital/shine"
    ]
    for i in 0...files.length
      str = sprintf("%s%03d",files[i],trainerid)
      files[i] = str if pbResolveBitmap(str)
    end
    # creates the background layer
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = pbBitmap(files[0])
    @sprites["bg"].z = 200
    @sprites["bg"].color = Color.new(0,0,0)
    for i in 0...16
      @sprites["p#{i}"] = Sprite.new(@viewport)
      @sprites["p#{i}"].bitmap = pbBitmap(files[1])
      @sprites["p#{i}"].z = 205
      @sprites["p#{i}"].color = Color.new(0,0,0)
      @sprites["p#{i}"].oy = @sprites["p#{i}"].bitmap.height/2
      @sprites["p#{i}"].x = @viewport.rect.width/2
      @sprites["p#{i}"].y = @viewport.rect.height/2
      @sprites["p#{i}"].angle = rand(16)*22.5
      @sprites["p#{i}"].visible = false
    end
    @sprites["shine"] = Sprite.new(@viewport)
    @sprites["shine"].bitmap = pbBitmap(files[2])
    @sprites["shine"].center!
    @sprites["shine"].x = @viewport.rect.width/2
    @sprites["shine"].y = @viewport.rect.height/2
    @sprites["shine"].color = Color.new(0,0,0)
    @sprites["shine"].z = 210
    @sprites["shine"].toggle = 1
    # draws all the little tiles
    tile_size = 32.0
    opacity = 25
    offset = 2
    @x = (@viewport.rect.width/tile_size).ceil
    @y = (@viewport.rect.height/tile_size).ceil
    for i in 0...@x
      for j in 0...@y
        sprite = Sprite.new(@viewport)
        sprite.bitmap = Bitmap.new(tile_size,tile_size)
        sprite.bitmap.fill_rect(offset,offset,tile_size-offset*2,tile_size-offset*2,Color.new(255,255,255,opacity))
        sprite.x = i * tile_size
        sprite.y = j * tile_size
        sprite.color = Color.new(0,0,0)
        sprite.visible = false
        sprite.z = 220
        o = opacity + rand(156)
        sprite.opacity = 0
        @tiles.push(sprite)
        @data.push([o,rand(5)+4])
      end
    end
  end
  # sets the speed of the sprites
  def speed=(val)
  end
  # updates the background
  def update(skip=false)
    return if self.disposed?
    for i in 0...@tiles.length
      @tiles[i].opacity += @data[i][1]
      @data[i][1] *= -1 if @tiles[i].opacity <= 0 || @tiles[i].opacity >= @data[i][0]
    end
    for i in 0...16
      next if i > @fpIndex/16
      if @sprites["p#{i}"].ox < - @viewport.rect.width/2
        @sprites["p#{i}"].angle = rand(16)*22.5
        @sprites["p#{i}"].ox = 0
        @sprites["p#{i}"].opacity = 255
        @sprites["p#{i}"].zoom_x = 1
        @sprites["p#{i}"].zoom_y = 1
      end
      @sprites["p#{i}"].zoom_x += 0.001
      @sprites["p#{i}"].zoom_y += 0.001
      @sprites["p#{i}"].opacity -= 4
      @sprites["p#{i}"].ox -= 4
    end
    @sprites["shine"].zoom_x += 0.04*@sprites["shine"].toggle
    @sprites["shine"].zoom_y += 0.04*@sprites["shine"].toggle
    @sprites["shine"].toggle *= -1 if @sprites["shine"].zoom_x <= 1 || @sprites["shine"].zoom_x >= 1.4
    @fpIndex += 1 if @fpIndex < 256
  end
  # used to fade in from black
  def reduceAlpha(factor)
    for tile in @tiles
      tile.color.alpha -= factor
    end
    for key in @sprites.keys
      next if key == "bg"
      @sprites[key].color.alpha -= factor
    end
    self.update
  end
  # disposes of everything
  def dispose
    @disposed = true
    for tile in @tiles
      tile.dispose
    end
    pbDisposeSpriteHash(@sprites)
  end
  # checks if disposed
  def disposed?; return @disposed; end
  # used to show other elements
  def show
    for i in 0...16
      @sprites["p#{i}"].visible = true
    end
    for tile in @tiles
      tile.visible = true
    end
    @sprites["bg"].color.alpha = 0
  end
end
#-------------------------------------------------------------------------------
#  New class used to render a custom Sun & Moon styled VS background
#-------------------------------------------------------------------------------
class SunMoonPlasmaBackground
  attr_reader :speed
  # main method to create the background
  def initialize(viewport,trainerid,evilteam=false)
    @viewport = viewport
    @trainerid = trainerid
    @evilteam = evilteam
    @disposed = false
    @speed = 1
    @sprites = {}
    @tiles = []
    @data = []
    @fpIndex = 0
    # allows for custom graphics as well
    files = ["Graphics/Transitions/SunMoon/Plasma/background",
             "Graphics/Transitions/SunMoon/Plasma/beam",
             "Graphics/Transitions/SunMoon/Plasma/streaks",
             "Graphics/Transitions/SunMoon/Plasma/shine",
             "Graphics/Transitions/SunMoon/Plasma/particle"
    ]
    for i in 0...files.length
      str = sprintf("%s%03d",files[i],trainerid)
      files[i] = str if pbResolveBitmap(str)
    end
    # creates the background layer
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = pbBitmap(files[0])
    @sprites["bg"].z = 200
    @sprites["bg"].color = Color.new(0,0,0)
    # creates plasma beam
    for i in 0...2
      @sprites["beam#{i}"] = ScrollingSprite.new(@viewport)
      @sprites["beam#{i}"].setBitmap(files[i+1])
      @sprites["beam#{i}"].speed = [32,48][i]
      @sprites["beam#{i}"].center!
      @sprites["beam#{i}"].x = @viewport.rect.width/2
      @sprites["beam#{i}"].y = @viewport.rect.height/2 - 16
      @sprites["beam#{i}"].zoom_y = 0
      @sprites["beam#{i}"].z = 210
      @sprites["beam#{i}"].color = Color.new(0,0,0)
    end
    @sprites["shine"] = Sprite.new(@viewport)
    @sprites["shine"].bitmap = pbBitmap(files[3])
    @sprites["shine"].center!
    @sprites["shine"].x = @viewport.rect.width
    @sprites["shine"].y = @viewport.rect.height/2 - 16
    @sprites["shine"].z = 220
    @sprites["shine"].visible = false
    @sprites["shine"].toggle = 1
    for i in 0...32
      @sprites["p#{i}"] = Sprite.new(@viewport)
      @sprites["p#{i}"].bitmap = pbBitmap(files[4])
      @sprites["p#{i}"].center!
      @sprites["p#{i}"].opacity = 0
      @sprites["p#{i}"].z = 215
      @sprites["p#{i}"].visible = false
    end
  end
  # sets the speed of the sprites
  def speed=(val)
    @speed = val
  end
  # updates the background
  def update(skip=false)
    return if self.disposed?
    @sprites["shine"].angle += 8 if $PokemonSystem.screensize < 2
    @sprites["shine"].zoom_x -= 0.04*@sprites["shine"].toggle
    @sprites["shine"].zoom_y -= 0.04*@sprites["shine"].toggle
    @sprites["shine"].toggle *= -1 if @sprites["shine"].zoom_x <= 0.8 || @sprites["shine"].zoom_x >= 1.2
    for i in 0...2
      @sprites["beam#{i}"].update
    end
    for i in 0...32
      next if i > @fpIndex/4
      if @sprites["p#{i}"].opacity <= 0
        @sprites["p#{i}"].x = @sprites["shine"].x
        @sprites["p#{i}"].y = @sprites["shine"].y
        r = 256 + rand(129)
        cx, cy = randCircleCord(r)
        @sprites["p#{i}"].ex = @sprites["shine"].x - (cx - r).abs
        @sprites["p#{i}"].ey = @sprites["shine"].y - r/2 + cy/2
        z = 0.4 + rand(7)/10.0
        @sprites["p#{i}"].zoom_x = z
        @sprites["p#{i}"].zoom_y = z
        @sprites["p#{i}"].opacity = 255
      end
      @sprites["p#{i}"].opacity -= 8
      @sprites["p#{i}"].x -= (@sprites["p#{i}"].x - @sprites["p#{i}"].ex)*0.1
      @sprites["p#{i}"].y -= (@sprites["p#{i}"].y - @sprites["p#{i}"].ey)*0.1
    end
    @fpIndex += 1 if @fpIndex < 512
  end
  # used to fade in from black
  def reduceAlpha(factor)
    for key in @sprites.keys
      next if key == "bg"
      @sprites[key].color.alpha -= factor
    end
    for i in 0...2
      @sprites["beam#{i}"].zoom_y += 0.1 if @sprites["beam#{i}"].color.alpha <= 164 && @sprites["beam#{i}"].zoom_y < 1
    end
  end
  # disposes of everything
  def dispose
    @disposed = true
    pbDisposeSpriteHash(@sprites)
  end
  # checks if disposed
  def disposed?; return @disposed; end
  # used to show other elements
  def show
    @sprites["bg"].color.alpha = 0
    for key in @sprites.keys
      @sprites[key].visible = true
    end
  end
end
