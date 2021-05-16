

def pbCanUseHiddenMove?(pkmn,move,showmsg=true)
  return HiddenMoveHandlers.triggerCanUseMove(move,pkmn,showmsg)
end

def pbConfirmUseHiddenMove(pokemon,move)
  return HiddenMoveHandlers.triggerConfirmUseMove(move,pokemon)
end

def pbUseHiddenMove(pokemon,move)
  return HiddenMoveHandlers.triggerUseMove(move,pokemon)
end

# Unused
def pbHiddenMoveEvent
  Events.onAction.trigger(nil)
end

def pbCheckHiddenMoveBadge(badge=-1,showmsg=true)
  return true if badge<0   # No badge requirement
  return true if $DEBUG
  if (FIELD_MOVES_COUNT_BADGES) ? $Trainer.numbadges>=badge : $Trainer.badges[badge]
    return true
  end
  pbMessage(_INTL("Sorry, a new Badge is required.")) if showmsg
  return false
end



#===============================================================================
# Hidden move animation
#===============================================================================
def pbHiddenMoveAnimation(pokemon)
  return false if !pokemon
  viewport=Viewport.new(0,0,0,0)
  viewport.z=99999
  bg=Sprite.new(viewport)
  bg.bitmap=RPG::Cache.load_bitmap("Graphics/Pictures/hiddenMovebg")
  sprite=PokemonSprite.new(viewport)
  sprite.setOffset(PictureOrigin::Center)
  sprite.setPokemonBitmap(pokemon)
  sprite.z=1
  sprite.visible=false
  strobebitmap=AnimatedBitmap.new("Graphics/Pictures/hiddenMoveStrobes")
  strobes=[]
  15.times do |i|
    strobe=BitmapSprite.new(26*2,8*2,viewport)
    strobe.bitmap.blt(0,0,strobebitmap.bitmap,Rect.new(0,(i%2)*8*2,26*2,8*2))
    strobe.z=((i%2)==0 ? 2 : 0)
    strobe.visible=false
    strobes.push(strobe)
  end
  strobebitmap.dispose
  interp=RectInterpolator.new(
     Rect.new(0,Graphics.height/2,Graphics.width,0),
     Rect.new(0,(Graphics.height-bg.bitmap.height)/2,Graphics.width,bg.bitmap.height),
     Graphics.frame_rate/4)
  ptinterp=nil
  phase=1
  frames=0
  strobeSpeed = 64*20/Graphics.frame_rate
  loop do
    Graphics.update
    Input.update
    sprite.update
    case phase
    when 1   # Expand viewport height from zero to full
      interp.update
      interp.set(viewport.rect)
      bg.oy=(bg.bitmap.height-viewport.rect.height)/2
      if interp.done?
        phase=2
        ptinterp=PointInterpolator.new(
           Graphics.width+(sprite.bitmap.width/2),bg.bitmap.height/2,
           Graphics.width/2,bg.bitmap.height/2,
           Graphics.frame_rate*4/10)
      end
    when 2   # Slide Pokémon sprite in from right to centre
      ptinterp.update
      sprite.x=ptinterp.x
      sprite.y=ptinterp.y
      sprite.visible=true
      if ptinterp.done?
        phase=3
        pbPlayCry(pokemon)
        frames=0
      end
    when 3   # Wait
      frames+=1
      if frames>Graphics.frame_rate*3/4
        phase=4
        ptinterp=PointInterpolator.new(
           Graphics.width/2,bg.bitmap.height/2,
           -(sprite.bitmap.width/2),bg.bitmap.height/2,
           Graphics.frame_rate*4/10)
        frames=0
      end
    when 4   # Slide Pokémon sprite off from centre to left
      ptinterp.update
      sprite.x=ptinterp.x
      sprite.y=ptinterp.y
      if ptinterp.done?
        phase=5
        sprite.visible=false
        interp=RectInterpolator.new(
           Rect.new(0,(Graphics.height-bg.bitmap.height)/2,Graphics.width,bg.bitmap.height),
           Rect.new(0,Graphics.height/2,Graphics.width,0),
           Graphics.frame_rate/4)
      end
    when 5   # Shrink viewport height from full to zero
      interp.update
      interp.set(viewport.rect)
      bg.oy=(bg.bitmap.height-viewport.rect.height)/2
      phase=6 if interp.done?
    end
    # Constantly stream the strobes across the screen
    for strobe in strobes
      strobe.ox=strobe.viewport.rect.x
      strobe.oy=strobe.viewport.rect.y
      if !strobe.visible   # Initial placement of strobes
        randomY = 16*(1+rand(bg.bitmap.height/16-2))
        strobe.y = randomY+(Graphics.height-bg.bitmap.height)/2
        strobe.x = rand(Graphics.width)
        strobe.visible = true
      elsif strobe.x<Graphics.width   # Move strobe right
        strobe.x += strobeSpeed
      else   # Strobe is off the screen, reposition it to the left of the screen
        randomY = 16*(1+rand(bg.bitmap.height/16-2))
        strobe.y = randomY+(Graphics.height-bg.bitmap.height)/2
        strobe.x = -strobe.bitmap.width-rand(Graphics.width/4)
      end
    end
    pbUpdateSceneMap
    break if phase==6
  end
  sprite.dispose
  for strobe in strobes
    strobe.dispose
  end
  strobes.clear
  bg.dispose
  viewport.dispose
  return true
end

#===============================================================================
# Katana move animation
#===============================================================================
def pbKatanaMoveAnimation(color=1)
  viewport=Viewport.new(0,0,0,0)
  viewport.z=99999
  bg=Sprite.new(viewport)
  if color == 1
    bg.bitmap=RPG::Cache.load_bitmap("Graphics/Pictures/hiddenMovebg1")
  elsif color == 2
    bg.bitmap=RPG::Cache.load_bitmap("Graphics/Pictures/hiddenMovebg2")
  elsif color == 3
    bg.bitmap=RPG::Cache.load_bitmap("Graphics/Pictures/hiddenMovebg3")
  elsif color == 4
    bg.bitmap=RPG::Cache.load_bitmap("Graphics/Pictures/hiddenMovebg4")
  elsif color == 5
    bg.bitmap=RPG::Cache.load_bitmap("Graphics/Pictures/hiddenMovebg5")
  elsif color == 6
    bg.bitmap=RPG::Cache.load_bitmap("Graphics/Pictures/hiddenMovebg6")
  else
    bg.bitmap=RPG::Cache.load_bitmap("Graphics/Pictures/hiddenMovebg")
  end
  sprite = IconSprite.new(200,400,@viewport)
  sprite.setBitmap(pbPlayerSpriteFile($Trainer.trainertype))
  sprite.ox = (sprite.bitmap.width/2)
  sprite.oy = (sprite.bitmap.height/2)-100
  sprite.z=999999
  sprite.visible=false
  strobebitmap=AnimatedBitmap.new("Graphics/Pictures/hiddenMoveStrobes")
  strobes=[]
  15.times do |i|
    strobe=BitmapSprite.new(26*2,8*2,viewport)
    strobe.bitmap.blt(0,0,strobebitmap.bitmap,Rect.new(0,(i%2)*8*2,26*2,8*2))
    strobe.z=((i%2)==0 ? 2 : 0)
    strobe.visible=false
    strobes.push(strobe)
  end
  strobebitmap.dispose
  interp=RectInterpolator.new(
     Rect.new(0,Graphics.height/2,Graphics.width,0),
     Rect.new(0,(Graphics.height-bg.bitmap.height)/2,Graphics.width,bg.bitmap.height),
     Graphics.frame_rate/4)
  ptinterp=nil
  phase=1
  frames=0
  strobeSpeed = 64*20/Graphics.frame_rate
  loop do
    Graphics.update
    Input.update
    sprite.update
    case phase
    when 1   # Expand viewport height from zero to full
      interp.update
      interp.set(viewport.rect)
      bg.oy=(bg.bitmap.height-viewport.rect.height)/2
      if interp.done?
        phase=2
        ptinterp=PointInterpolator.new(
           Graphics.width+(sprite.bitmap.width/2),bg.bitmap.height/2,
           Graphics.width/2,bg.bitmap.height/2,
           Graphics.frame_rate*4/10)
      end
    when 2   # Slide Pokémon sprite in from right to centre
      ptinterp.update
      sprite.x=ptinterp.x
      sprite.y=ptinterp.y
      sprite.visible=true
      if ptinterp.done?
        phase=3
        #pbPlayCry(pokemon)
        # Add trainer grunt SFX
        i = rand(4)
        if $Trainer.gender==0 # Male grunts = Marth
          case i
          when 0
            pbSEPlay("Marth0",100)
          when 1
            pbSEPlay("Marth1",100)
          when 2
            pbSEPlay("Marth2",100)
          else
            pbSEPlay("Marth3",100)
          end
        else  # Female grunts = Lucina
          case i
          when 0
            pbSEPlay("Lucina0",100)
          when 1
            pbSEPlay("Lucina1",100)
          when 2
            pbSEPlay("Lucina2",100)
          else
            pbSEPlay("Lucina3",100)
          end
        end
        frames=0
      end
    when 3   # Wait
      frames+=1
      if frames>Graphics.frame_rate*3/4
        phase=4
        ptinterp=PointInterpolator.new(
           Graphics.width/2,bg.bitmap.height/2,
           -(sprite.bitmap.width/2),bg.bitmap.height/2,
           Graphics.frame_rate*4/10)
        frames=0
      end
    when 4   # Slide Pokémon sprite off from centre to left
      ptinterp.update
      sprite.x=ptinterp.x
      sprite.y=ptinterp.y
      if ptinterp.done?
        phase=5
        sprite.visible=false
        interp=RectInterpolator.new(
           Rect.new(0,(Graphics.height-bg.bitmap.height)/2,Graphics.width,bg.bitmap.height),
           Rect.new(0,Graphics.height/2,Graphics.width,0),
           Graphics.frame_rate/4)
      end
    when 5   # Shrink viewport height from full to zero
      interp.update
      interp.set(viewport.rect)
      bg.oy=(bg.bitmap.height-viewport.rect.height)/2
      phase=6 if interp.done?
    end
    # Constantly stream the strobes across the screen
    for strobe in strobes
      strobe.ox=strobe.viewport.rect.x
      strobe.oy=strobe.viewport.rect.y
      if !strobe.visible   # Initial placement of strobes
        randomY = 16*(1+rand(bg.bitmap.height/16-2))
        strobe.y = randomY+(Graphics.height-bg.bitmap.height)/2
        strobe.x = rand(Graphics.width)
        strobe.visible = true
      elsif strobe.x<Graphics.width   # Move strobe right
        strobe.x += strobeSpeed
      else   # Strobe is off the screen, reposition it to the left of the screen
        randomY = 16*(1+rand(bg.bitmap.height/16-2))
        strobe.y = randomY+(Graphics.height-bg.bitmap.height)/2
        strobe.x = -strobe.bitmap.width-rand(Graphics.width/4)
      end
    end
    pbUpdateSceneMap
    break if phase==6
  end
  sprite.dispose
  for strobe in strobes
    strobe.dispose
  end
  strobes.clear
  bg.dispose
  viewport.dispose
  return true
end

#===============================================================================
# Talonflame Fly Animation
#===============================================================================
def pbTalonflameMoveAnimation(color=1)
  viewport=Viewport.new(0,0,0,0)
  viewport.z=99999
  bg=Sprite.new(viewport)
  if color == 1
    bg.bitmap=RPG::Cache.load_bitmap("Graphics/Pictures/hiddenMovebg1")
  elsif color == 2
    bg.bitmap=RPG::Cache.load_bitmap("Graphics/Pictures/hiddenMovebg2")
  elsif color == 3
    bg.bitmap=RPG::Cache.load_bitmap("Graphics/Pictures/hiddenMovebg3")
  elsif color == 4
    bg.bitmap=RPG::Cache.load_bitmap("Graphics/Pictures/hiddenMovebg4")
  elsif color == 5
    bg.bitmap=RPG::Cache.load_bitmap("Graphics/Pictures/hiddenMovebg5")
  elsif color == 6
    bg.bitmap=RPG::Cache.load_bitmap("Graphics/Pictures/hiddenMovebg6")
  else
    bg.bitmap=RPG::Cache.load_bitmap("Graphics/Pictures/hiddenMovebg")
  end
  sprite = IconSprite.new(200,400,@viewport)
  #sprite.setOffset(PictureOrigin::Center)
  sprite.bitmap=RPG::Cache.load_bitmap("Graphics/Pictures/663")
  sprite.ox = (sprite.bitmap.width/2)
  sprite.z=999999
  sprite.visible=false
  strobebitmap=AnimatedBitmap.new("Graphics/Pictures/hiddenMoveStrobes")
  strobes=[]
  15.times do |i|
    strobe=BitmapSprite.new(26*2,8*2,viewport)
    strobe.bitmap.blt(0,0,strobebitmap.bitmap,Rect.new(0,(i%2)*8*2,26*2,8*2))
    strobe.z=((i%2)==0 ? 2 : 0)
    strobe.visible=false
    strobes.push(strobe)
  end
  strobebitmap.dispose
  interp=RectInterpolator.new(
     Rect.new(0,Graphics.height/2,Graphics.width,0),
     Rect.new(0,(Graphics.height-bg.bitmap.height)/2,Graphics.width,bg.bitmap.height),
     Graphics.frame_rate/4)
  ptinterp=nil
  phase=1
  frames=0
  strobeSpeed = 64*20/Graphics.frame_rate
  loop do
    Graphics.update
    Input.update
    sprite.update
    case phase
    when 1   # Expand viewport height from zero to full
      interp.update
      interp.set(viewport.rect)
      bg.oy=(bg.bitmap.height-viewport.rect.height)/2
      if interp.done?
        phase=2
        ptinterp=PointInterpolator.new(
           Graphics.width+(sprite.bitmap.width/2),bg.bitmap.height/2,
           Graphics.width/2,bg.bitmap.height/2,
           Graphics.frame_rate*4/10)
      end
    when 2   # Slide Pokémon sprite in from right to centre
      ptinterp.update
      sprite.x=ptinterp.x
      sprite.y=ptinterp.y
      sprite.visible=true
      if ptinterp.done?
        phase=3
        #pbPlayCry(pokemon)
        frames=0
      end
    when 3   # Wait
      frames+=1
      if frames>Graphics.frame_rate*3/4
        phase=4
        ptinterp=PointInterpolator.new(
           Graphics.width/2,bg.bitmap.height/2,
           -(sprite.bitmap.width/2),bg.bitmap.height/2,
           Graphics.frame_rate*4/10)
        frames=0
      end
    when 4   # Slide Pokémon sprite off from centre to left
      ptinterp.update
      sprite.x=ptinterp.x
      sprite.y=ptinterp.y
      if ptinterp.done?
        phase=5
        sprite.visible=false
        interp=RectInterpolator.new(
           Rect.new(0,(Graphics.height-bg.bitmap.height)/2,Graphics.width,bg.bitmap.height),
           Rect.new(0,Graphics.height/2,Graphics.width,0),
           Graphics.frame_rate/4)
      end
    when 5   # Shrink viewport height from full to zero
      interp.update
      interp.set(viewport.rect)
      bg.oy=(bg.bitmap.height-viewport.rect.height)/2
      phase=6 if interp.done?
    end
    # Constantly stream the strobes across the screen
    for strobe in strobes
      strobe.ox=strobe.viewport.rect.x
      strobe.oy=strobe.viewport.rect.y
      if !strobe.visible   # Initial placement of strobes
        randomY = 16*(1+rand(bg.bitmap.height/16-2))
        strobe.y = randomY+(Graphics.height-bg.bitmap.height)/2
        strobe.x = rand(Graphics.width)
        strobe.visible = true
      elsif strobe.x<Graphics.width   # Move strobe right
        strobe.x += strobeSpeed
      else   # Strobe is off the screen, reposition it to the left of the screen
        randomY = 16*(1+rand(bg.bitmap.height/16-2))
        strobe.y = randomY+(Graphics.height-bg.bitmap.height)/2
        strobe.x = -strobe.bitmap.width-rand(Graphics.width/4)
      end
    end
    pbUpdateSceneMap
    break if phase==6
  end
  sprite.dispose
  for strobe in strobes
    strobe.dispose
  end
  strobes.clear
  bg.dispose
  viewport.dispose
  return true
end

#===============================================================================
# Cut
#===============================================================================
def pbCut
  move = getID(PBMoves,:CUT)
  movefinder = pbCheckMove(move)
  if !pbCheckHiddenMoveBadge(BADGE_FOR_CUT,false) || (!$DEBUG && !movefinder)
    pbMessage(_INTL("This tree looks like it can be cut down."))
    return false
  end
  pbMessage(_INTL("This tree looks like it can be cut down!\1"))
  if pbConfirmMessage(_INTL("Would you like to cut it?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!",speciesname,PBMoves.getName(move)))
    pbHiddenMoveAnimation(movefinder)
    return true
  end
  return false
end

def pbSmashEvent(event)
  return if !event
  if event.name[/CutTree/i];    pbSEPlay("Cut",80)
  elsif event.name[/SmashRock/i]; pbSEPlay("Rock Smash",80)
  end
  pbMoveRoute(event,[
     PBMoveRoute::Wait,2,
     PBMoveRoute::TurnLeft,
     PBMoveRoute::Wait,2,
     PBMoveRoute::TurnRight,
     PBMoveRoute::Wait,2,
     PBMoveRoute::TurnUp,
     PBMoveRoute::Wait,2
  ])
  pbWait(Graphics.frame_rate*4/10)
  event.erase
  $PokemonMap.addErasedEvent(event.id) if $PokemonMap
end

#===============================================================================
# Dive
#===============================================================================
def pbDive
  divemap = pbGetMetadata($game_map.map_id,MetadataDiveMap)
  return false if !divemap
  move = getID(PBMoves,:DIVE)
  movefinder = pbCheckMove(move)
  if !pbCheckHiddenMoveBadge(BADGE_FOR_DIVE,false) || (!$DEBUG && !movefinder)
    pbMessage(_INTL("The sea is deep here. A Pokémon may be able to go underwater."))
    return false
  end
  if pbConfirmMessage(_INTL("The sea is deep here. Would you like to use Dive?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!",speciesname,PBMoves.getName(move)))
    pbHiddenMoveAnimation(movefinder)
    pbFadeOutIn {
       $game_temp.player_new_map_id    = divemap
       $game_temp.player_new_x         = $game_player.x
       $game_temp.player_new_y         = $game_player.y
       $game_temp.player_new_direction = $game_player.direction
       $PokemonGlobal.surfing = false
       $PokemonGlobal.diving  = true
       pbUpdateVehicle
       $scene.transfer_player(false)
       $game_map.autoplay
       $game_map.refresh
    }
    return true
  end
  return false
end

def pbSurfacing
  return if !$PokemonGlobal.diving
  divemap = nil
  meta = pbLoadMetadata
  for i in 0...meta.length
    if meta[i] && meta[i][MetadataDiveMap] && meta[i][MetadataDiveMap]==$game_map.map_id
      divemap = i; break
    end
  end
  return if !divemap
  move = getID(PBMoves,:DIVE)
  movefinder = pbCheckMove(move)
  if !pbCheckHiddenMoveBadge(BADGE_FOR_DIVE,false) || (!$DEBUG && !movefinder)
    pbMessage(_INTL("Light is filtering down from above. A Pokémon may be able to surface here."))
    return false
  end
  if pbConfirmMessage(_INTL("Light is filtering down from above. Would you like to use Dive?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!",speciesname,PBMoves.getName(move)))
    pbHiddenMoveAnimation(movefinder)
    pbFadeOutIn {
       $game_temp.player_new_map_id    = divemap
       $game_temp.player_new_x         = $game_player.x
       $game_temp.player_new_y         = $game_player.y
       $game_temp.player_new_direction = $game_player.direction
       $PokemonGlobal.surfing = true
       $PokemonGlobal.diving  = false
       pbUpdateVehicle
       $scene.transfer_player(false)
       surfbgm = pbGetMetadata(0,MetadataSurfBGM)
       (surfbgm) ?  pbBGMPlay(surfbgm) : $game_map.autoplayAsCue
       $game_map.refresh
    }
    return true
  end
  return false
end

def pbTransferUnderwater(mapid,x,y,direction=$game_player.direction)
  pbFadeOutIn {
    $game_temp.player_new_map_id    = mapid
    $game_temp.player_new_x         = x
    $game_temp.player_new_y         = y
    $game_temp.player_new_direction = direction
    $scene.transfer_player(false)
    $game_map.autoplay
    $game_map.refresh
  }
end

#===============================================================================
# Headbutt
#===============================================================================
def pbHeadbuttEffect(event=nil)
  event = $game_player.pbFacingEvent(true) if !event
  a = (event.x+(event.x/24).floor+1)*(event.y+(event.y/24).floor+1)
  a = (a*2/5)%10   # Even 2x as likely as odd, 0 is 1.5x as likely as odd
  b = ($Trainer.publicID)%10   # Practically equal odds of each value
  chance = 1                             # ~50%
  if a==b;                  chance = 8   # 10%
  elsif a>b && (a-b).abs<5; chance = 5   # ~30.3%
  elsif a<b && (a-b).abs>5; chance = 5   # ~9.7%
  end
  if rand(10)>=chance
    pbMessage(_INTL("Nope. Nothing..."))
  else
    enctype = (chance==1) ? EncounterTypes::HeadbuttLow : EncounterTypes::HeadbuttHigh
    if !pbEncounter(enctype)
      pbMessage(_INTL("Nope. Nothing..."))
    end
  end
end

def pbHeadbutt(event=nil)
  move = getID(PBMoves,:HEADBUTT)
  movefinder = pbCheckMove(move)
  if !$DEBUG && !movefinder
    pbMessage(_INTL("A Pokémon could be in this tree. Maybe a Pokémon could shake it."))
    return false
  end
  if pbConfirmMessage(_INTL("A Pokémon could be in this tree. Would you like to use Headbutt?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!",speciesname,PBMoves.getName(move)))
    pbHiddenMoveAnimation(movefinder)
    pbHeadbuttEffect(event)
    return true
  end
  return false
end

#===============================================================================
# Rock Smash
#===============================================================================

def pbRockSmashRandomEncounter
  if rand(100)<25
    pbEncounter(EncounterTypes::RockSmash)
  end
end

def pbRockSmash
  move = getID(PBMoves,:ROCKSMASH)
  movefinder = pbCheckMove(move)
  if !pbCheckHiddenMoveBadge(BADGE_FOR_ROCKSMASH,false) || (!$DEBUG && !movefinder)
    pbMessage(_INTL("It's a rugged rock, but a Pokémon may be able to smash it."))
    return false
  end
  if pbConfirmMessage(_INTL("This rock appears to be breakable. Would you like to use Rock Smash?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!",speciesname,PBMoves.getName(move)))
    pbHiddenMoveAnimation(movefinder)
    return true
  end
  return false
end

#===============================================================================
# Strength
#===============================================================================

def pbStrength
  if $PokemonMap.strengthUsed
    pbMessage(_INTL("Strength made it possible to move boulders around."))
    return false
  end
  move = getID(PBMoves,:STRENGTH)
  movefinder = pbCheckMove(move)
  if !pbCheckHiddenMoveBadge(BADGE_FOR_STRENGTH,false) || (!$DEBUG && !movefinder)
    pbMessage(_INTL("It's a big boulder, but a Pokémon may be able to push it aside."))
    return false
  end
  pbMessage(_INTL("It's a big boulder, but a Pokémon may be able to push it aside.\1"))
  if pbConfirmMessage(_INTL("Would you like to use Strength?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!",speciesname,PBMoves.getName(move)))
    pbHiddenMoveAnimation(movefinder)
    pbMessage(_INTL("{1}'s Strength made it possible to move boulders around!",speciesname))
    $PokemonMap.strengthUsed = true
    return true
  end
  return false
end

#===============================================================================
# Surf
#===============================================================================

def pbSurf
  return false if $game_player.pbFacingEvent
  return false if $game_player.pbHasDependentEvents?
  move = getID(PBMoves,:SURF)
  movefinder = pbCheckMove(move)
  if !pbCheckHiddenMoveBadge(BADGE_FOR_SURF,false) || (!$DEBUG && !movefinder)
    return false
  end
  if pbConfirmMessage(_INTL("The water is a deep blue...\nWould you like to surf on it?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!",speciesname,PBMoves.getName(move)))
    pbCancelVehicles
    pbHiddenMoveAnimation(movefinder)
    surfbgm = pbGetMetadata(0,MetadataSurfBGM)
    pbCueBGM(surfbgm,0.5) if surfbgm
    pbStartSurfing
    return true
  end
  return false
end

def pbStartSurfing
  pbCancelVehicles
  $PokemonEncounters.clearStepCount
  $PokemonGlobal.surfing = true
  pbUpdateVehicle
  $PokemonTemp.surfJump = $MapFactory.getFacingCoords($game_player.x,$game_player.y,$game_player.direction)
  pbJumpToward
  $PokemonTemp.surfJump = nil
  $game_player.check_event_trigger_here([1,2])
end

def pbEndSurf(_xOffset,_yOffset)
  return false if !$PokemonGlobal.surfing
  x = $game_player.x
  y = $game_player.y
  currentTag = $game_map.terrain_tag(x,y)
  facingTag = pbFacingTerrainTag
  if PBTerrain.isSurfable?(currentTag) && !PBTerrain.isSurfable?(facingTag)
    $PokemonTemp.surfJump = [x,y]
    if pbJumpToward(1,false,true)
      $game_map.autoplayAsCue
      $game_player.increase_steps
      result = $game_player.check_event_trigger_here([1,2])
      pbOnStepTaken(result)
    end
    $PokemonTemp.surfJump = nil
    return true
  end
  return false
end

def pbTransferSurfing(mapid,xcoord,ycoord,direction=$game_player.direction)
  pbFadeOutIn {
    $game_temp.player_new_map_id    = mapid
    $game_temp.player_new_x         = xcoord
    $game_temp.player_new_y         = ycoord
    $game_temp.player_new_direction = direction
    $scene.transfer_player(false)
    $game_map.autoplay
    $game_map.refresh
  }
end

#===============================================================================
# Sweet Scent
#===============================================================================
def pbSweetScent
  if $game_screen.weather_type!=PBFieldWeather::None
    pbMessage(_INTL("The sweet scent faded for some reason..."))
    return
  end
  viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z = 99999
  count = 0
  viewport.color.red   = 255
  viewport.color.green = 0
  viewport.color.blue  = 0
  viewport.color.alpha -= 10
  alphaDiff = 12 * 20 / Graphics.frame_rate
  loop do
    if count==0 && viewport.color.alpha<128
      viewport.color.alpha += alphaDiff
    elsif count>Graphics.frame_rate/4
      viewport.color.alpha -= alphaDiff
    else
      count += 1
    end
    Graphics.update
    Input.update
    pbUpdateSceneMap
    break if viewport.color.alpha<=0
  end
  viewport.dispose
  enctype = $PokemonEncounters.pbEncounterType
  if enctype<0 || !$PokemonEncounters.isEncounterPossibleHere? ||
     !pbEncounter(enctype)
    pbMessage(_INTL("There appears to be nothing here..."))
  end
end

#===============================================================================
# Waterfall
#===============================================================================
def pbAscendWaterfall(event=nil)
  event = $game_player if !event
  return if !event
  return if event.direction!=8   # can't ascend if not facing up
  oldthrough   = event.through
  oldmovespeed = event.move_speed
  terrain = pbFacingTerrainTag
  return if !PBTerrain.isWaterfall?(terrain)
  event.through = true
  event.move_speed = 2
  loop do
    event.move_up
    terrain = pbGetTerrainTag(event)
    break if !PBTerrain.isWaterfall?(terrain)
  end
  event.through    = oldthrough
  event.move_speed = oldmovespeed
end

def pbDescendWaterfall(event=nil)
  event = $game_player if !event
  return if !event
  return if event.direction!=2   # Can't descend if not facing down
  oldthrough   = event.through
  oldmovespeed = event.move_speed
  terrain = pbFacingTerrainTag
  return if !PBTerrain.isWaterfall?(terrain)
  event.through = true
  event.move_speed = 2
  loop do
    event.move_down
    terrain = pbGetTerrainTag(event)
    break if !PBTerrain.isWaterfall?(terrain)
  end
  event.through    = oldthrough
  event.move_speed = oldmovespeed
end

def pbWaterfall
  move = getID(PBMoves,:WATERFALL)
  movefinder = pbCheckMove(move)
  if !pbCheckHiddenMoveBadge(BADGE_FOR_WATERFALL,false) || (!$DEBUG && !movefinder)
    pbMessage(_INTL("A wall of water is crashing down with a mighty roar."))
    return false
  end
  if pbConfirmMessage(_INTL("It's a large waterfall. Would you like to use Waterfall?"))
    speciesname = (movefinder) ? movefinder.name : $Trainer.name
    pbMessage(_INTL("{1} used {2}!",speciesname,PBMoves.getName(move)))
    pbHiddenMoveAnimation(movefinder)
    pbAscendWaterfall
    return true
  end
  return false
end

#===============================================================================
# Defog
#===============================================================================
def pbDefog
  $game_screen.weather(0,0,0)
end
