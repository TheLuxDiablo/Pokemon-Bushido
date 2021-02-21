#==============================================================================#
#                                    HM Items                                  #
#                                    by Marin                                  #
#==============================================================================#
#                       No coding knowledge required at all.                   #
#                                                                              #
#  Because the items override the actual moves' functionality, the items have  #
#      switches to toggle them, as you see below (USING_SURF_ITEM, etc.)       #
#   If they're set to true, the items will be active and will override some    #
#                 in-field functionality of the moves themselves.              #
#==============================================================================#
#      Rock Smash, Strength and Cut all use the default Essentials events.     #
#==============================================================================#
#                    Please give credit when using this.                       #
#==============================================================================#

# Future updates may contain: Flash, Headbutt, Sweet Scent, Rock Climb.


# The internal name of the item that will trigger Surf
SURF_ITEM = :KATANALIGHT4

# The internal name of the item that will trigger Rock Smash
ROCK_SMASH_ITEM = :KATANALIGHT2

# The internal name of the item that will trigger Fly
FLY_ITEM = :KATANALIGHT3

# The internal name of the item that will trigger Strength
STRENGTH_ITEM = :STRENGTHITEM

# The internal name of the item that will trigger Cut
CUT_ITEM = :KATANABASIC

# The internal name of the item that will trigger Flash
FLASH_ITEM = :KATANALIGHT5



# When true, this overrides the old surfing mechanics.
USING_SURF_ITEM = true

# When true, this overrides the old rock smash mechanics.
USING_ROCK_SMASH_ITEM = true

# When true, this overrides the old fly mechanics.
USING_FLY_ITEM = true

# When true, this overrides the old strength mechanics.
USING_STRENGTH_ITEM = true

# When true, this overrides the old cut mechanics.
USING_CUT_ITEM = true

# When true, this overrides the old flash mechanics.
USING_FLASH_ITEM = true


#==============================================================================#
# This section of code contains minor utility methods.                         #
#==============================================================================#

class Game_Map
  attr_reader :map
end

class Game_Player
  attr_writer :x
  attr_writer :y
end

class HandlerHash
  def delete(sym)
    id = fromSymbol(sym)
    @hash.delete(id) if id && @hash[id]
    symbol = toSymbol(sym)
    @hash.delete(symbol) if symbol && @hash[symbol]
  end
end

def pbSmashEvent(event)
  return unless event
  if event.name == "Tree"
    pbSEPlay("Cut", 80)
  elsif event.name == "Rock"
    pbSEPlay("Cut", 90)
    pbWait(2)
    pbSEPlay("Rock Smash", 70)
  end
  pbMoveRoute(event,[
     PBMoveRoute::TurnDown,
     PBMoveRoute::Wait, 2,
     PBMoveRoute::TurnLeft,
     PBMoveRoute::Wait, 2,
     PBMoveRoute::TurnRight,
     PBMoveRoute::Wait, 2,
     PBMoveRoute::TurnUp,
     PBMoveRoute::Wait, 2
  ])
  pbWait(16)
  event.erase
  $PokemonMap.addErasedEvent(event.id) if $PokemonMap
end


#==============================================================================#
# This section of the code handles the item that calls Surf.                   #
#==============================================================================#

if USING_SURF_ITEM
  HiddenMoveHandlers::CanUseMove.delete(:SURF)
  HiddenMoveHandlers::UseMove.delete(:SURF)

  def pbSurf
    return false if $game_player.pbFacingEvent
    return false if $game_player.pbHasDependentEvents?
    if !$PokemonBag.pbHasItem?(SURF_ITEM) && !$DEBUG
      return false
    end
    if pbConfirmMessage(_INTL("The water is a deep blue...\nWould you like to surf on it?"))
      pbMessage(_INTL("{1} used the {2}!", $Trainer.name, PBItems.getName(getConst(PBItems,SURF_ITEM))))
      pbKatanaMoveAnimation(4)
      pbCancelVehicles
      surfbgm = pbGetMetadata(0,MetadataSurfBGM)
      pbCueBGM(surfbgm,0.5) if surfbgm
      pbStartSurfing
      return true
    end
    return false
  end

  ItemHandlers::UseInField.add(SURF_ITEM, proc do |item|
    $game_temp.in_menu = false
    pbSurf
    return true
  end)

  ItemHandlers::UseFromBag.add(SURF_ITEM, proc do |item|
    return false if $PokemonGlobal.surfing ||
                    pbGetMetadata($game_map.map_id,MetadataBicycleAlways) ||
                    !PBTerrain.isSurfable?(pbFacingTerrainTag) ||
                    !$game_map.passable?($game_player.x,$game_player.y,$game_player.direction,$game_player)
    return 2
  end)
end


#==============================================================================#
# This section of the code handles the item that calls Fly.                    #
#==============================================================================#

if USING_FLY_ITEM
  ItemHandlers::UseFromBag.add(FLY_ITEM, proc do |item|
    return false unless pbGetMetadata($game_map.map_id,MetadataOutdoor)
    if defined?(BetterRegionMap)
      ret = pbBetterRegionMap(nil, true, true)
    else
      ret = pbFadeOutIn(99999) do
        scene = PokemonRegionMap_Scene.new(-1, false)
        screen = PokemonRegionMapScreen.new(scene)
        next screen.pbStartFlyScreen
      end
    end
    if ret
      $PokemonTemp.flydata = ret
      return 2
    end
    return 0
  end)

  ItemHandlers::UseInField.add(FLY_ITEM, proc do |item|
    $game_temp.in_menu = false
    if !pbGetMetadata($game_map.map_id,MetadataOutdoor)
     pbMessage(_INTL("The Gale Flute can't be used indoors!"))
     return false
    end
    if !$PokemonTemp.flydata
        ret = pbFadeOutIn(99999) do
          scene = PokemonRegionMap_Scene.new(-1, false)
          screen = PokemonRegionMapScreen.new(scene)
          next screen.pbStartFlyScreen
        end
      if ret
        $PokemonTemp.flydata = ret
      elsif
        pbMessage(_INTL("No fly location was selected!"))
        return false
      end
    end
    pbMessage(_INTL("{1} used the {2}!", $Trainer.name,PBItems.getName(getConst(PBItems,FLY_ITEM))))
    pbKatanaMoveAnimation(3)
    #pbMEPlay("flute")
    #pbWait(200)
    pbSEPlay("wind1")
    #pbWait(8)
    pbFadeOutIn(99999) do
       $game_temp.player_new_map_id    = $PokemonTemp.flydata[0]
       $game_temp.player_new_x         = $PokemonTemp.flydata[1]
       $game_temp.player_new_y         = $PokemonTemp.flydata[2]
       $game_temp.player_new_direction = 2
       pbCancelVehicles
       $PokemonTemp.flydata = nil
       $scene.transfer_player
       $game_map.autoplay
       $game_map.refresh
    end
    pbEraseEscapePoint
    return true
  end)
end


#==============================================================================#
# This section of the code handles the item that calls Rock Smash.             #
#==============================================================================#

if USING_ROCK_SMASH_ITEM
  HiddenMoveHandlers::CanUseMove.delete(:ROCKSMASH)
  HiddenMoveHandlers::UseMove.delete(:ROCKSMASH)

  ItemHandlers::UseFromBag.add(ROCK_SMASH_ITEM, proc do |item|
    if $game_player.pbFacingEvent && $game_player.pbFacingEvent.name == "Rock"
      return 2
    end
    return false
  end)

  ItemHandlers::UseInField.add(ROCK_SMASH_ITEM, proc do |item|
    if $game_player.pbFacingEvent
      $game_player.pbFacingEvent.start
      return true
    else
      pbMessage(_INTL("There are no rocks for the Katana of Light to slice!"))
      return false
    end
  end)

  def pbRockSmash
    if !$PokemonBag.pbHasItem?(ROCK_SMASH_ITEM)
      pbMessage(_INTL("It's a rugged rock, but a skilled warrior who has mastered the Solid Strike may be able to slice through it."))
      return false
    end
    item = PBItems.getName(getConst(PBItems,ROCK_SMASH_ITEM))
    if pbConfirmMessage(_INTL("This rock appears to be breakable. Would you like to use the {1}?", item))
      pbMessage(_INTL("{1} used the {2}, Solid Strike style!",$Trainer.name, item))
      pbKatanaMoveAnimation(1)
      return true
    end
    return false
  end
end


#==============================================================================#
# This section of code handles the item that calls Strength.                   #
#==============================================================================#

if USING_STRENGTH_ITEM
  HiddenMoveHandlers::CanUseMove.delete(:STRENGTH)
  HiddenMoveHandlers::UseMove.delete(:STRENGTH)

  def pbStrength
    if $PokemonMap.strengthUsed
      pbMessage(_INTL("The Strength Gloves made it possible to move boulders around."))
      return false
    end
    if !$PokemonBag.pbHasItem?(:STRENGTHITEM) && !$DEBUG
      pbMessage(_INTL("It's a big boulder, but an item may be able to push it aside."))
      return false
    end
    itemname = PBItems.getName(getConst(PBItems,STRENGTH_ITEM))
    if !$game_player.pbFacingEvent || !$game_player.pbFacingEvent.name == "Boulder"
      pbMessage(_INTL("The strength gloves cannot be used here!"))
      return false
    end
    pbMessage(_INTL("It's a big boulder, but an item may be able to push it aside.\1"))
    if pbConfirmMessage(_INTL("Would you like to use the {1}?", itemname))
      pbMessage(_INTL("{1} used the {2}!",
          $Trainer.name, itemname))
      pbMessage(_INTL("The {1} made it possible to move boulders around!",itemname))
      $PokemonMap.strengthUsed = true
      return true
    end
    return false
  end

  ItemHandlers::UseFromBag.add(STRENGTH_ITEM, proc do
    if $game_player.pbFacingEvent && $game_player.pbFacingEvent.name == "Boulder"
      return 2
    end
    return false
  end)

  ItemHandlers::UseInField.add(STRENGTH_ITEM, proc { pbStrength })
end


#==============================================================================#
# This section of code handles the item that calls Cut.                        #
#==============================================================================#

if USING_CUT_ITEM
  HiddenMoveHandlers::CanUseMove.delete(:CUT)
  HiddenMoveHandlers::UseMove.delete(:CUT)

  def pbCut
    if !$PokemonBag.pbHasItem?(CUT_ITEM) && !$DEBUG
      pbMessage(_INTL("This tree looks like it can be cut down by a skilled warrior who has mastered the Wind Blade technique."))
      return false
    end
    pbMessage(_INTL("This tree looks like it can be cut down by a master of the Wind Blade technique!\1"))
    if pbConfirmMessage(_INTL("Would you like to cut it down?"))
      itemname = PBItems.getName(getConst(PBItems,CUT_ITEM))
      pbMessage(_INTL("{1} used the {2}, Wind Blade!",$Trainer.name,itemname))
      pbKatanaMoveAnimation(2)
      pbSmashEvent($game_player.pbFacingEvent)
      return true
    end
    return false
  end

  ItemHandlers::UseFromBag.add(CUT_ITEM, proc do
    if $game_player.pbFacingEvent && $game_player.pbFacingEvent.name == "Tree"
      return 2
    end
    return false
  end)

  ItemHandlers::UseInField.add(CUT_ITEM, proc do
    if !$game_player.pbFacingEvent || !$game_player.pbFacingEvent.name == "Tree"
      pbMessage(_INTL("There are no trees to cut with the Katana of Light!"))
      return false
    end
    $game_player.pbFacingEvent.start
  end)
end

#==============================================================================#
# This section of code handles the item that calls Flash.                      #
#==============================================================================#

if USING_FLASH_ITEM
  HiddenMoveHandlers::CanUseMove.delete(:FLASH)
  HiddenMoveHandlers::UseMove.delete(:FLASH)

  def pbFlash
    darkness = $PokemonTemp.darknessSprite
    if !darkness || darkness.disposed?
      pbMessage(_INTL("The Katana of Light cannot be used to illuminate this location!"))
      return false
    end
    if $PokemonGlobal.flashUsed
      pbMessage(_INTL("The Katana of Light is already illuminated!"))
    else
      pbMessage(_INTL("You used the Katana of Light to illuminate!"))
    end
    $PokemonGlobal.flashUsed = true
    pbKatanaMoveAnimation(6)
    while darkness.radius<176
      Graphics.update
      Input.update
      pbUpdateSceneMap
      darkness.radius += 4
     end
   return true
  end

  ItemHandlers::UseFromBag.add(FLASH_ITEM, proc do
    if !pbGetMetadata($game_map.map_id,MetadataDarkMap)
      pbMessage(_INTL("This map is already perfectly lit!"))
      return false
    elsif $PokemonGlobal.flashUsed
       pbMessage(_INTL("The Katana of Light has already illuminated this area!"))
       return false
     else
       return 2
    end
  end)

  ItemHandlers::UseInField.add(FLASH_ITEM, proc { pbFlash })
end

#=================================================================
