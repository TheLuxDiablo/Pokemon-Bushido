#===============================================================================
# Overwriting the default Player Send Out animation
#===============================================================================
class PokeballPlayerSendOutAnimation < PokeBattle_Animation
  include PokeBattle_BallAnimationMixin

  def initialize(sprites,viewport,idxTrainer,battler,startBattle,idxOrder=0)
    @index          = 0
    @delay          = 0
    @idxTrainer     = idxTrainer
    @battler        = battler
    @showingTrainer = startBattle
    @idxOrder       = idxOrder
    @trainer        = @battler.battle.pbGetOwnerFromBattlerIndex(@battler.index)
    @shadowVisible  = sprites["shadow_#{battler.index}"].visible
    @sprites        = sprites
    @viewport       = viewport
    @pictureEx      = []   # For all the PictureEx
    @pictureSprites = []   # For all the sprites
    @tempSprites    = []   # For sprites that exist only for this animation
    @animDone       = false
    if defined?(FollowingPkmn)
      if FollowingPkmn.active? && startBattle &&
         battler.index == 0 && FollowingPkmn::SLIDE_INTO_BATTLE
        createFollowerProcesses
      else
        createProcesses
      end
    else
      @followAnim     = false
      @followAnim     = true if $PokemonTemp.dependentEvents.refresh_sprite(false,true) && battler.index == 0 && startBattle
      createProcesses
    end
  end

  def createProcesses
    batSprite = @sprites["pokemon_#{@battler.index}"]
    shaSprite = @sprites["shadow_#{@battler.index}"]
    traSprite = @sprites["player_#{@idxTrainer}"]
    # Calculate the Poké Ball graphic to use
    ballType = 0
    if !batSprite.pkmn.nil?
      ballType = batSprite.pkmn.ballused || 0
    end
    # Calculate the color to turn the battler sprite
    col = getBattlerColorFromBallType(ballType)
    col.alpha = 255
    # Calculate start and end coordinates for battler sprite movement
    ballPos = PokeBattle_SceneConstants.pbBattlerPosition(@battler.index,batSprite.sideSize)
    battlerStartX = ballPos[0]   # Is also where the Ball needs to end
    battlerStartY = ballPos[1]   # Is also where the Ball needs to end + 18
    battlerEndX = batSprite.x
    battlerEndY = batSprite.y
    # Calculate start and end coordinates for Poké Ball sprite movement
    ballStartX = -6
    ballStartY = 202
    ballMidX = 0   # Unused in trajectory calculation
    ballMidY = battlerStartY-144
    # Set up Poké Ball sprite
    ball = addBallSprite(ballStartX,ballStartY,ballType)
    ball.setZ(0,25)
    ball.setVisible(0,false)
    # Poké Ball tracking the player's hand animation (if trainer is visible)
    if @showingTrainer && !@followAnim && traSprite && traSprite.x>0
      ball.setZ(0,traSprite.z-1)
      ballStartX, ballStartY = ballTracksHand(ball,traSprite)
    end
    delay = ball.totalDuration   # 0 or 7
    # Poké Ball trajectory animation
    createBallTrajectory(ball,delay,12,
       ballStartX,ballStartY,ballMidX,ballMidY,battlerStartX,battlerStartY-18) if !@followAnim
    ball.setZ(9,batSprite.z-1)
    delay = ball.totalDuration+4
    delay += 10*@idxOrder   # Stagger appearances if multiple Pokémon are sent out at once
    if !@followAnim
      @delay = delay
      ballOpenUp(ball,delay-2,ballType)
      @ballAnim = EBBallBurst.new(@viewport,battlerEndX,battlerEndY - 40,100,2,ballType)
      ball.moveOpacity(delay+2,2,0)
    end
    # Set up battler sprite
    battler = addSprite(batSprite,PictureOrigin::Bottom)
    if !@followAnim
      battler.setXY(0,battlerStartX,battlerStartY)
      battler.setZoom(0,0)
      battler.setColor(0,col)
      # Battler animation
      battlerAppear(battler,delay,battlerEndX,battlerEndY,batSprite,col)
    else
      battler.setVisible(delay-ball.totalDuration,true)
      battler.setOpacity(delay-ball.totalDuration,255)
      battler.setXY(0,-192,battlerEndY)
      battler.moveXY(delay-ball.totalDuration+1,16,battlerStartX,battlerEndY)
      #battler.setSE(delay-ball.totalDuration+18,"GUI naming tab swap start",100)
      battler.setCallback(delay-ball.totalDuration+18,[batSprite,:pbPlayIntroAnimation])
    end
    if @shadowVisible
      # Set up shadow sprite
      shadow = addSprite(shaSprite,PictureOrigin::Center)
      shadow.setOpacity(0,0)
      # Shadow animation
      shadow.setVisible(delay,@shadowVisible)
      shadow.moveOpacity(delay+5,10,255)
    end
  end

  def update
    value = @delay
    @ballAnim.update if @index>(value*(Graphics.frame_rate/20)) && !@followAnim && @ballAnim
    @index += 1
    return if @index == ((value+54)*(Graphics.frame_rate/20)) && @animDone
    @tempSprites.each { |s| s.update if s }
    finished = true
    @pictureEx.each_with_index do |p,i|
      next if !p.running?
      finished = false
      p.update
      setPictureIconSprite(@pictureSprites[i],p)
    end
    @animDone = true if finished
  end

  def dispose
    @ballAnim.dispose if @ballAnim
    super
  end
end

#===============================================================================
# Overwriting the default Trainer Send Out animation
#===============================================================================
class PokeballTrainerSendOutAnimation < PokeBattle_Animation
  include PokeBattle_BallAnimationMixin

  def initialize(sprites,viewport,idxTrainer,battler,startBattle,idxOrder)
    @idxTrainer     = idxTrainer
    @battler        = battler
    @showingTrainer = startBattle
    @idxOrder       = idxOrder
    @index = 0
    @delay = 0
    sprites["pokemon_#{battler.index}"].visible = false
    @shadowVisible = sprites["shadow_#{battler.index}"].visible
    sprites["shadow_#{battler.index}"].visible = false
    super(sprites,viewport)
  end

  def createProcesses
    batSprite = @sprites["pokemon_#{@battler.index}"]
    shaSprite = @sprites["shadow_#{@battler.index}"]
    # Calculate the Poké Ball graphic to use
    ballType = 0
    if !batSprite.pkmn.nil?
      ballType = batSprite.pkmn.ballused || 0
    end
    # Calculate the color to turn the battler sprite
    col = getBattlerColorFromBallType(ballType)
    col.alpha = 255
    # Calculate start and end coordinates for battler sprite movement
    ballPos = PokeBattle_SceneConstants.pbBattlerPosition(@battler.index,batSprite.sideSize)
    battlerStartX = ballPos[0]
    battlerStartY = ballPos[1]
    battlerEndX = batSprite.x
    battlerEndY = batSprite.y
    # Set up Poké Ball sprite
    ball = addBallSprite(0,0,ballType)
    ball.setZ(0,batSprite.z-1)
    # Poké Ball animation
    createBallTrajectory(ball,battlerStartX,battlerStartY)
    delay = ball.totalDuration+6
    delay += 10 if @showingTrainer   # Give time for trainer to slide off screen
    @delay = delay
    ballOpenUp(ball,delay-2,ballType)
    @ballAnim = EBBallBurst.new(@viewport,battlerEndX,battlerEndY - 40,100,2,ballType)
    ball.moveOpacity(delay+2,2,0)
    # Set up battler sprite
    battler = addSprite(batSprite,PictureOrigin::Bottom)
    battler.setXY(0,battlerStartX,battlerStartY)
    battler.setZoom(0,0)
    battler.setColor(0,col)
    # Battler animation
    battlerAppear(battler,delay,battlerEndX,battlerEndY,batSprite,col)
    if @shadowVisible
      # Set up shadow sprite
      shadow = addSprite(shaSprite,PictureOrigin::Center)
      shadow.setOpacity(0,0)
      # Shadow animation
      shadow.setVisible(delay,@shadowVisible)
      shadow.moveOpacity(delay+5,10,255)
    end
  end

  def update
    value = @delay
    @ballAnim.update if @index>(value*(Graphics.frame_rate/20))
    @index += 1
    return if @index==((value+54)*(Graphics.frame_rate/20)) && @animDone
    @tempSprites.each { |s| s.update if s }
    finished = true
    @pictureEx.each_with_index do |p,i|
      next if !p.running?
      finished = false
      p.update
      setPictureIconSprite(@pictureSprites[i],p)
    end
    @animDone = true if finished
  end

  def dispose
    @ballAnim.dispose
    super
  end
end

#===============================================================================
# Overwriting the default Pokemon Recall animation
#===============================================================================
class BattlerRecallAnimation < PokeBattle_Animation
  include PokeBattle_BallAnimationMixin

  def initialize(sprites,viewport,idxBattler)
    @idxBattler = idxBattler
    @index = 0
    super(sprites,viewport)
  end

  def createProcesses
    batSprite = @sprites["pokemon_#{@idxBattler}"]
    shaSprite = @sprites["shadow_#{@idxBattler}"]
    # Calculate the Poké Ball graphic to use
    ballType = 0
    if !batSprite.pkmn.nil?
      ballType = batSprite.pkmn.ballused || 0
    end
    # Calculate the color to turn the battler sprite
    col = getBattlerColorFromBallType(ballType)
    col.alpha = 0
    # Calculate end coordinates for battler sprite movement
    ballPos = PokeBattle_SceneConstants.pbBattlerPosition(@idxBattler,batSprite.sideSize)
    battlerEndX = ballPos[0]
    battlerEndY = ballPos[1]
    # Set up battler sprite
    battler = addSprite(batSprite,PictureOrigin::Bottom)
    battler.setVisible(0,true)
    battler.setColor(0,col)
    # Set up Poké Ball sprite
    ball = addBallSprite(battlerEndX,battlerEndY,ballType)
    ball.setZ(0,batSprite.z+1)
    # Poké Ball animation
    ballOpenUp(ball,0,ballType)
    delay = ball.totalDuration
    ball_anim_y = battlerEndY - (@idxBattler%2 == 0 ? 10 : 30)
    @ballAnim = EBBallBurst.new(@viewport,battlerEndX,ball_anim_y,100,2,ballType)
    @ballAnim.recall
    ball.moveOpacity(10,2,0)
    # Battler animation
    battlerAbsorb(battler,delay,battlerEndX,battlerEndY,col)
    if shaSprite.visible
      # Set up shadow sprite
      shadow = addSprite(shaSprite,PictureOrigin::Center)
      # Shadow animation
      shadow.moveOpacity(0,10,0)
      shadow.setVisible(delay,false)
    end
  end

  def update
    @ballAnim.update# if @index>(12*(Graphics.frame_rate/20))
    @index += 1
    return if @index==((54)*(Graphics.frame_rate/20)) && @animDone
    @tempSprites.each { |s| s.update if s }
    finished = true
    @pictureEx.each_with_index do |p,i|
      next if !p.running?
      finished = false
      p.update
      setPictureIconSprite(@pictureSprites[i],p)
    end
    @animDone = true if finished
  end

  def dispose
    @ballAnim.dispose
    super
  end
end


#===============================================================================
# Overwriting the default Pokeball Capture animation
#===============================================================================
class PokeballThrowCaptureAnimation < PokeBattle_Animation
  include PokeBattle_BallAnimationMixin

  def initialize(sprites,viewport,
                 ballType,numShakes,critCapture,battler,showingTrainer)
    @ballType       = ballType
    @numShakes      = (critCapture) ? 1 : numShakes
    @critCapture    = critCapture
    @battler        = battler
    @showingTrainer = showingTrainer    # Only true if a Safari Zone battle
    @shadowVisible  = sprites["shadow_#{battler.index}"].visible
    @trainer        = battler.battle.pbPlayer
    @index = 0
    @catchStarted = false
    super(sprites,viewport)
  end

  def createProcesses
    # Calculate start and end coordinates for battler sprite movement
    batSprite = @sprites["pokemon_#{@battler.index}"]
    shaSprite = @sprites["shadow_#{@battler.index}"]
    traSprite = @sprites["player_1"]
    ballPos = PokeBattle_SceneConstants.pbBattlerPosition(@battler.index,batSprite.sideSize)
    battlerStartX = batSprite.x
    battlerStartY = batSprite.y
    ballStartX = -6
    ballStartY = 246
    ballMidX   = 0   # Unused in arc calculation
    ballMidY   = 78
    ballEndX   = ballPos[0]
    ballEndY   = 112
    ballGroundY = ballPos[1]-4
    # Set up Poké Ball sprite
    ball = addBallSprite(ballStartX,ballStartY,@ballType)
    ball.setZ(0,batSprite.z+1)
    @ballSpriteIndex = (@numShakes>=4 || @critCapture) ? @tempSprites.length-1 : -1
    # Set up trainer sprite (only visible in Safari Zone battles)
    if @showingTrainer && traSprite
      if traSprite.bitmap.width>=traSprite.bitmap.height*2
        trainer = addSprite(traSprite,PictureOrigin::Bottom)
        # Trainer animation
        ballStartX, ballStartY = trainerThrowingFrames(ball,trainer,traSprite)
      end
    end
    delay = ball.totalDuration   # 0 or 7
    # Poké Ball arc animation
    ball.setSE(delay,"Battle throw")
    createBallTrajectory(ball,delay,16,
       ballStartX,ballStartY,ballMidX,ballMidY,ballEndX,ballEndY)
    ball.setZ(9,batSprite.z+1)
    ball.setSE(delay+16,"Battle ball hit")
    # Poké Ball opens up
    delay = ball.totalDuration+6
    ballOpenUp(ball,delay,@ballType,true,false)
    # Set up battler sprite
    battler = addSprite(batSprite,PictureOrigin::Bottom)
    # Poké Ball absorbs battler
    delay = ball.totalDuration
    @ballAnim = EBBallBurst.new(@viewport,ballEndX,ballEndY,100,1,@ballType)
    @delay = delay + 4
    delay = ball.totalDuration+4
    # NOTE: The Pokémon does not change color while being absorbed into a Poké
    #       Ball during a capture attempt. This may be an oversight in HGSS.
    battler.setSE(delay,"Battle jump to ball")
    battler.moveXY(delay,5,ballEndX,ballEndY)
    battler.moveZoom(delay,5,0)
    battler.setVisible(delay+5,false)
    if @shadowVisible
      # Set up shadow sprite
      shadow = addSprite(shaSprite,PictureOrigin::Center)
      # Shadow animation
      shadow.moveOpacity(delay,5,0)
      shadow.moveZoom(delay,5,0)
      shadow.setVisible(delay+5,false)
    end
    # Poké Ball closes
    delay = battler.totalDuration
    ballSetClosed(ball,delay,@ballType)
    ball.moveTone(delay,3,Tone.new(96,64,-160,160))
    ball.moveTone(delay+5,3,Tone.new(0,0,0,0))
    # Poké Ball critical capture animation
    delay = ball.totalDuration+3
    if @critCapture
      ball.setSE(delay,"Battle ball shake")
      ball.moveXY(delay,1,ballEndX+4,ballEndY)
      ball.moveXY(delay+1,2,ballEndX-4,ballEndY)
      ball.moveXY(delay+3,2,ballEndX+4,ballEndY)
      ball.setSE(delay+4,"Battle ball shake")
      ball.moveXY(delay+5,2,ballEndX-4,ballEndY)
      ball.moveXY(delay+7,1,ballEndX,ballEndY)
      delay = ball.totalDuration+3
    end
    @delay2 = delay + 4
    # Poké Ball drops to the ground
    for i in 0...4
      t = [4,4,3,2][i]   # Time taken to rise or fall for each bounce
      d = [1,2,4,8][i]   # Fraction of the starting height each bounce rises to
      delay -= t if i==0
      if i>0
        ball.setZoomXY(delay,100+5*(5-i),100-5*(5-i))   # Squish
        ball.moveZoom(delay,2,100)                      # Unsquish
        ball.moveXY(delay,t,ballEndX,ballGroundY-(ballGroundY-ballEndY)/d)
      end
      ball.moveXY(delay+t,t,ballEndX,ballGroundY)
      ball.setSE(delay+2*t,"Battle ball drop",100-i*7)
      delay = ball.totalDuration
    end
    battler.setXY(ball.totalDuration,ballEndX,ballGroundY)
    # Poké Ball shakes
    delay = ball.totalDuration+12
    for i in 0...[@numShakes,3].min
      ball.setSE(delay,"Battle ball shake")
      ball.moveXY(delay,2,ballEndX-2*(4-i),ballGroundY)
      ball.moveAngle(delay,2,5*(4-i))   # positive means counterclockwise
      ball.moveXY(delay+2,4,ballEndX+2*(4-i),ballGroundY)
      ball.moveAngle(delay+2,4,-5*(4-i))   # negative means clockwise
      ball.moveXY(delay+6,2,ballEndX,ballGroundY)
      ball.moveAngle(delay+6,2,0)
      delay = ball.totalDuration+8
    end
    if @numShakes==0 || (@numShakes<4 && !@critCapture)
      # Poké Ball opens
      ball.setZ(delay,batSprite.z-1)
      ballOpenUp(ball,delay,@ballType,false)
      ball.moveOpacity(delay+2,2,0)
      # Battler emerges
      col = getBattlerColorFromBallType(@ballType)
      col.alpha = 255
      battler.setColor(delay,col)
      battlerAppear(battler,delay,battlerStartX,battlerStartY,batSprite,col)
      if @shadowVisible
        shadow.setVisible(delay+5,true)
        shadow.setZoom(delay+5,100)
        shadow.moveOpacity(delay+5,10,255)
      end
    else
      # Pokémon was caught
      ballCaptureSuccess(ball,delay,ballEndX,ballGroundY)
    end
  end

  def update
    value = @delay
    if @index > (value*(Graphics.frame_rate/20)) && @index < (@delay2*(Graphics.frame_rate/20))
      @ballAnim.catching if !@catchStarted
      @catchStarted = true
      @ballAnim.update
    end
    @index += 1
    return if @index==((value+54)*(Graphics.frame_rate/20)) && @animDone
    @tempSprites.each { |s| s.update if s }
    finished = true
    @pictureEx.each_with_index do |p,i|
      next if !p.running?
      finished = false
      p.update
      setPictureIconSprite(@pictureSprites[i],p)
    end
    @animDone = true if finished
  end

  def dispose
    @ballAnim.dispose
    if @ballSpriteIndex>=0
      # Capture was successful, the Poké Ball sprite should stay around after
      # this animation has finished.
      @sprites["captureBall"] = @tempSprites[@ballSpriteIndex]
      @tempSprites[@ballSpriteIndex] = nil
    end
    super
  end
end

#===============================================================================
#  Class handling the ball burst animation. Credits to Luka SJ for this.
#===============================================================================
class EBBallBurst

  def delta; return Graphics.frame_rate/40.0; end

  #-----------------------------------------------------------------------------
  #  class constructor; setting up all the particles
  #-----------------------------------------------------------------------------
  def initialize(viewport, x = 0, y = 0, z = 50, factor = 1, balltype = 0)
    # defaults to regular Pokeball particles if specific ones cannot be found
    balltype = 0 if pbResolveBitmap("Graphics/Battle animations/Ball Anim/shine#{balltype}").nil?
    # configuring main variables
    @balltype = balltype
    @viewport = viewport
    @factor = factor
    @fp = {}; @index = 0; @tone = 255.0
    @pzoom = []; @szoom = []; @poy = []; @rangl = []; @rad = []
    @catching = false
    @recall = false
    @x = x; @y = y; @z = z
    # ray particles
    for j in 0...9
      @fp["s#{j}"] = Sprite.new(@viewport)
      @fp["s#{j}"].bmp("Graphics/Battle animations/Ball Anim/ray#{balltype}")
      @fp["s#{j}"].oy = @fp["s#{j}"].bitmap.height/2
      @fp["s#{j}"].zoom_x = 0
      @fp["s#{j}"].zoom_y = 0
      @fp["s#{j}"].tone = Tone.new(255,255,255)
      @fp["s#{j}"].x = x
      @fp["s#{j}"].y = @y
      @fp["s#{j}"].z = z
      @fp["s#{j}"].angle = rand(270) - 45
      @szoom.push([1.5,0.75,1.25,1][rand(4)]*@factor)
    end
    # inner glow particle
    @fp["cir"] = Sprite.new(@viewport)
    @fp["cir"].bmp("Graphics/Battle animations/Ball Anim/shine#{balltype}")
    @fp["cir"].ox = @fp["cir"].bitmap.width/2
    @fp["cir"].oy = @fp["cir"].bitmap.height/2
    @fp["cir"].x = x
    @fp["cir"].y = @y
    @fp["cir"].zoom_x = 0
    @fp["cir"].zoom_y = 0
    @fp["cir"].tone = Tone.new(255,255,255)
    @fp["cir"].z = z
    # additional particle effects
    for k in 0...16
      str = ["particle","eff"][rand(2)]
      @fp["p#{k}"] = Sprite.new(@viewport)
      @fp["p#{k}"].bmp("Graphics/Battle animations/Ball Anim/#{str}#{balltype}")
      @fp["p#{k}"].ox = @fp["p#{k}"].bitmap.width/2
      @fp["p#{k}"].oy = @fp["p#{k}"].bitmap.height/2
      @pzoom.push([1.5,0.75,1.25,1][rand(4)]*@factor)
      @fp["p#{k}"].zoom_x = 1*@factor
      @fp["p#{k}"].zoom_y = 1*@factor
      @fp["p#{k}"].tone = Tone.new(255,255,255)
      @fp["p#{k}"].x = x
      @fp["p#{k}"].y = @y
      @fp["p#{k}"].z = z
      @fp["p#{k}"].opacity = 0
      @fp["p#{k}"].angle = rand(270) - 45
      @rangl.push(rand(270) - 45)
      @poy.push(rand(4)+3)
      @rad.push(0)
    end
    # applies coordinates throughout whole class
  end
  #-----------------------------------------------------------------------------
  #  updates the entire animation
  #-----------------------------------------------------------------------------
  def update
    # reverses the animation if capturing a Pokemon
    return self.reverse if @catching
    # @index mainly used for animation frame separation
    # animates ray particles
    for j in 0...9
      next if @index < 4.delta_add; next if j > ((@index-4)/2).delta_add
      @fp["s#{j}"].zoom_x += (@szoom[j]*0.1).delta_sub(false)
      @fp["s#{j}"].zoom_y += (@szoom[j]*0.1).delta_sub(false)
      @fp["s#{j}"].opacity -= 8.delta_sub(false) if @fp["s#{j}"].zoom_x >= 1
    end
    # animaties additional particle effects
    for k in 0...16
      next if @index < 4.delta_add; next if k > (@index-4).delta_add
      @fp["p#{k}"].opacity += 25.5.delta_sub(false) if @index < 22.delta_add
      @fp["p#{k}"].zoom_x -= ((@fp["p#{k}"].zoom_x - @pzoom[k])*0.1).delta_sub(false)
      @fp["p#{k}"].zoom_y -= ((@fp["p#{k}"].zoom_y - @pzoom[k])*0.1).delta_sub(false)
      a = @rangl[k]
      @rad[k] += @poy[k]*@factor; r = @rad[k]
      x = @x + r*Math.cos(a*(Math::PI/180))
      y = @y - r*Math.sin(a*(Math::PI/180))
      @fp["p#{k}"].x = x
      @fp["p#{k}"].y = y
      @fp["p#{k}"].angle += 4.delta_sub(false)
    end
    # changes the opacity value depending on position in animation
    if @index >= 22.delta_add
      for j in 0...9
        @fp["s#{j}"].opacity -= 26.delta_sub(false)
      end
      for k in 0...16
        @fp["p#{k}"].opacity -= 26.delta_sub(false)
      end
      @fp["cir"].opacity -= 26.delta_sub(false)
    end
    # changes tone of animation depending on position in animation
    @tone -= 25.5.delta_sub(false) if @index >= 4.delta_add && @tone > 0
    for j in 0...9
      @fp["s#{j}"].tone = Tone.new(@tone,@tone,@tone)
    end
    for k in 0...16
      @fp["p#{k}"].tone = Tone.new(@tone,@tone,@tone)
    end
    # animates center shine
    @fp["cir"].tone = Tone.new(@tone,@tone,@tone)
    @fp["cir"].zoom_x += ((@factor*1.5 - @fp["cir"].zoom_x)*0.06).delta_sub(false)
    @fp["cir"].zoom_y += ((@factor*1.5 - @fp["cir"].zoom_y)*0.06).delta_sub(false)
    @fp["cir"].angle -= 4.delta_sub(false) if $PokemonSystem.screensize < 2
    # increments index
    @index += 1
  end
  #-----------------------------------------------------------------------------
  #  plays reversed animation
  #-----------------------------------------------------------------------------
  def reverse
    # changes tone of animation depending on position in animation
    @tone -= 25.5.delta_sub(false) if @index >= 4.delta_add && @tone > 0
    # animates shine (but not if recalling battlers)
    for j in 0...9
      next if @index < 4.delta_add; next if j > ((@index-4)/2).delta_add; next if @recall
      @fp["s#{j}"].zoom_x += (@szoom[j]*0.1).delta_sub(false)
      @fp["s#{j}"].zoom_y += (@szoom[j]*0.1).delta_sub(false)
      @fp["s#{j}"].opacity -= 8.delta_sub(false) if @fp["s#{j}"].zoom_x >= 1
    end
    if @index >= 22.delta_add
      for j in 0...9
        @fp["s#{j}"].opacity -= 26.delta_sub(false)
      end
    end
    for j in 0...9
      @fp["s#{j}"].tone = Tone.new(@tone,@tone,@tone)
    end
    # animates additional particles
    for k in 0...16
      a = k*22.5 + 11.5 + @index*4
      r = 128*@factor - @index*8*@factor
      x = @x + r*Math.cos(a*(Math::PI/180))
      y = @y - r*Math.sin(a*(Math::PI/180))
      @fp["p#{k}"].x = x
      @fp["p#{k}"].y = y
      @fp["p#{k}"].angle += 8.delta_sub(false)
      @fp["p#{k}"].opacity += 32.delta_sub(false) if @index < 8.delta_add
      @fp["p#{k}"].opacity -= 32.delta_sub(false) if @index >= 8.delta_add
    end
    # animates central shine particle
    @fp["cir"].tone = Tone.new(@tone,@tone,@tone)
    @fp["cir"].zoom_x -= ((@fp["cir"].zoom_x - 0.5*@factor)*0.06).delta_sub(false)
    @fp["cir"].zoom_y -= ((@fp["cir"].zoom_y - 0.5*@factor)*0.06).delta_sub(false)
    @fp["cir"].opacity += 25.5.delta_sub(false) if @index < 16.delta_add
    @fp["cir"].opacity -= 16.delta_sub(false) if @index >= 16.delta_add
    @fp["cir"].angle -= 4.delta_sub(false) if $PokemonSystem.screensize < 2
    # increments index
    @index += 1
  end
  #-----------------------------------------------------------------------------
  #  disposes all particle effects
  #-----------------------------------------------------------------------------
  def dispose
    pbDisposeSpriteHash(@fp)
  end
  #-----------------------------------------------------------------------------
  #  configures animation for when capturing Pokemon
  #-----------------------------------------------------------------------------
  def catching
    @catching = true
    for k in 0...16
      a = k*22.5 + 11.5
      r = 128*@factor
      x = @x + r*Math.cos(a*(Math::PI/180))
      y = @y - r*Math.sin(a*(Math::PI/180))
      @fp["p#{k}"].x = x
      @fp["p#{k}"].y = y
      @fp["p#{k}"].tone = Tone.new(0,0,0)
      @fp["p#{k}"].opacity = 0
      str = ["particle","eff"][k%2]
      @fp["p#{k}"].bmp("Graphics/Battle animations/Ball Anim/#{str}#{@balltype}")
      @fp["p#{k}"].ox = @fp["p#{k}"].bitmap.width/2
      @fp["p#{k}"].oy = @fp["p#{k}"].bitmap.height/2
    end
    @fp["cir"].zoom_x = 2*@factor
    @fp["cir"].zoom_y = 2*@factor
  end
  #-----------------------------------------------------------------------------
  #  configures animation for when Recalling
  #-----------------------------------------------------------------------------
  def recall
    @recall = true
    self.catching
  end
  #-----------------------------------------------------------------------------
end

#===============================================================================
#  Extensions for `Numeric` data types by Luka S.J.
#===============================================================================
class ::Numeric
  #-----------------------------------------------------------------------------
  #  Delta offset for frame rates
  #-----------------------------------------------------------------------------
  def delta(type = :add, round = true)
    d = Graphics.frame_rate/40.0
    a = round ? (self*d).to_i : (self*d)
    s = round ? (self/d).floor : (self/d)
    return type == :add ? a : s
  end
  def delta_add(round = true)
    return self.delta(:add, round)
  end
  def delta_sub(round = true)
    return self.delta(:sub, round)
  end
  #-----------------------------------------------------------------------------
  #  Superior way to round stuff
  #-----------------------------------------------------------------------------
	alias quick_mafs round unless method_defined?(:quick_mafs)
	def round(n = 0)
		# gets the current float to an actually roundable integer
		t = self*(10.0**n)
		# returns the rounded value
		return t.quick_mafs/(10.0**n)
	end
end

PluginManager.register({
  :name => "Ball Burst Animation",
  :credits => ["Luka S.J.", "lichenprincess"]
})
