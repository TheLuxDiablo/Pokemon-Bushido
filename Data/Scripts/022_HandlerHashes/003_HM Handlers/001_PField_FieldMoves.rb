#===============================================================================
# Hidden move handlers
#===============================================================================
class MoveHandlerHash < HandlerHash
  def initialize
    super(:PBMoves)
  end
end



module HiddenMoveHandlers
  CanUseMove     = MoveHandlerHash.new
  ConfirmUseMove = MoveHandlerHash.new
  UseMove        = MoveHandlerHash.new

  def self.addCanUseMove(item,proc);     CanUseMove.add(item,proc);     end
  def self.addConfirmUseMove(item,proc); ConfirmUseMove.add(item,proc); end
  def self.addUseMove(item,proc);        UseMove.add(item,proc);        end

  def self.hasHandler(item)
    return CanUseMove[item]!=nil && UseMove[item]!=nil
  end

  # Returns whether move can be used
  def self.triggerCanUseMove(item,pokemon,showmsg)
    return false if !CanUseMove[item]
    return CanUseMove.trigger(item,pokemon,showmsg)
  end

  # Returns whether the player confirmed that they want to use the move
  def self.triggerConfirmUseMove(item,pokemon)
    return true if !ConfirmUseMove[item]
    return ConfirmUseMove.trigger(item,pokemon)
  end

  # Returns whether move was used
  def self.triggerUseMove(item,pokemon)
    return false if !UseMove[item]
    return UseMove.trigger(item,pokemon)
  end
end

#===============================================================================
# Cut
#===============================================================================

HiddenMoveHandlers::CanUseMove.add(:CUT,proc { |move,pkmn,showmsg|
  next false if !pbCheckHiddenMoveBadge(BADGE_FOR_CUT,showmsg)
  facingEvent = $game_player.pbFacingEvent
  if !facingEvent || !facingEvent.name[/CutTree/i]
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:CUT,proc { |move,pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  end
  facingEvent = $game_player.pbFacingEvent
  if facingEvent
    pbSmashEvent(facingEvent)
  end
  next true
})


#===============================================================================
# Dig
#===============================================================================

HiddenMoveHandlers::CanUseMove.add(:DIG,proc { |move,pkmn,showmsg|
  escape = ($PokemonGlobal.escapePoint rescue nil)
  if !escape || escape==[]
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  if $game_player.pbHasDependentEvents?
    pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::ConfirmUseMove.add(:DIG,proc { |move,pkmn|
  escape = ($PokemonGlobal.escapePoint rescue nil)
  next false if !escape || escape==[]
  mapname = pbGetMapNameFromId(escape[0])
  next pbConfirmMessage(_INTL("Want to escape from here and return to {1}?",mapname))
})

HiddenMoveHandlers::UseMove.add(:DIG,proc { |move,pokemon|
  escape = ($PokemonGlobal.escapePoint rescue nil)
  if escape
    if !pbHiddenMoveAnimation(pokemon)
      pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
    end
    pbFadeOutIn {
      $game_temp.player_new_map_id    = escape[0]
      $game_temp.player_new_x         = escape[1]
      $game_temp.player_new_y         = escape[2]
      $game_temp.player_new_direction = escape[3]
      $scene.transfer_player
      $game_map.autoplay
      $game_map.refresh
    }
    pbEraseEscapePoint
    next true
  end
  next false
})

#===============================================================================
# Dive
#===============================================================================

Events.onAction += proc { |_sender,_e|
  if $PokemonGlobal.diving
    if DIVING_SURFACE_ANYWHERE
      pbSurfacing
    else
      divemap = nil
      meta = pbLoadMetadata
      for i in 0...meta.length
        if meta[i] && meta[i][MetadataDiveMap] && meta[i][MetadataDiveMap]==$game_map.map_id
          divemap = i; break
        end
      end
      if divemap && PBTerrain.isDeepWater?($MapFactory.getTerrainTag(divemap,$game_player.x,$game_player.y))
        pbSurfacing
      end
    end
  else
    pbDive if PBTerrain.isDeepWater?($game_player.terrain_tag)
  end
}

HiddenMoveHandlers::CanUseMove.add(:DIVE,proc { |move,pkmn,showmsg|
  next false if !pbCheckHiddenMoveBadge(BADGE_FOR_DIVE,showmsg)
  if $PokemonGlobal.diving
    next true if DIVING_SURFACE_ANYWHERE
    divemap = nil
    meta = pbLoadMetadata
    for i in 0...meta.length
      if meta[i] && meta[i][MetadataDiveMap] && meta[i][MetadataDiveMap]==$game_map.map_id
        divemap = i; break
      end
    end
    if !PBTerrain.isDeepWater?($MapFactory.getTerrainTag(divemap,$game_player.x,$game_player.y))
      pbMessage(_INTL("Can't use that here.")) if showmsg
      next false
    end
  else
    if !pbGetMetadata($game_map.map_id,MetadataDiveMap)
      pbMessage(_INTL("Can't use that here.")) if showmsg
      next false
    end
    if !PBTerrain.isDeepWater?($game_player.terrain_tag)
      pbMessage(_INTL("Can't use that here.")) if showmsg
      next false
    end
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:DIVE,proc { |move,pokemon|
  wasdiving = $PokemonGlobal.diving
  if $PokemonGlobal.diving
    divemap = nil
    meta = pbLoadMetadata
    for i in 0...meta.length
      if meta[i] && meta[i][MetadataDiveMap] && meta[i][MetadataDiveMap]==$game_map.map_id
        divemap = i; break
      end
    end
  else
    divemap = pbGetMetadata($game_map.map_id,MetadataDiveMap)
  end
  next false if !divemap
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  end
  pbFadeOutIn {
    $game_temp.player_new_map_id    = divemap
    $game_temp.player_new_x         = $game_player.x
    $game_temp.player_new_y         = $game_player.y
    $game_temp.player_new_direction = $game_player.direction
    $PokemonGlobal.surfing = wasdiving
    $PokemonGlobal.diving  = !wasdiving
    pbUpdateVehicle
    $scene.transfer_player(false)
    $game_map.autoplay
    $game_map.refresh
  }
  next true
})



#===============================================================================
# Flash
#===============================================================================
HiddenMoveHandlers::CanUseMove.add(:FLASH,proc { |move,pkmn,showmsg|
  next false if !pbCheckHiddenMoveBadge(BADGE_FOR_FLASH,showmsg)
  if !pbGetMetadata($game_map.map_id,MetadataDarkMap)
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  if $PokemonGlobal.flashUsed
    pbMessage(_INTL("Flash is already being used.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:FLASH,proc { |move,pokemon|
  darkness = $PokemonTemp.darknessSprite
  next false if !darkness || darkness.disposed?
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  end
  $PokemonGlobal.flashUsed = true
  radiusDiff = 8*20/Graphics.frame_rate
  while darkness.radius<darkness.radiusMax
    Graphics.update
    Input.update
    pbUpdateSceneMap
    darkness.radius += radiusDiff
    darkness.radius = darkness.radiusMax if darkness.radius>darkness.radiusMax
  end
  next true
})



#===============================================================================
# Fly
#===============================================================================
HiddenMoveHandlers::CanUseMove.add(:FLY,proc { |move,pkmn,showmsg|
  next false if !pbCheckHiddenMoveBadge(BADGE_FOR_FLY,showmsg)
  if $game_player.pbHasDependentEvents?
    pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
    next false
  end
  if !pbGetMetadata($game_map.map_id,MetadataOutdoor)
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:FLY,proc { |move,pokemon|
  if !$PokemonTemp.flydata
    pbMessage(_INTL("Can't use that here."))
    next false
  end
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  end
  pbFadeOutIn {
    $game_temp.player_new_map_id    = $PokemonTemp.flydata[0]
    $game_temp.player_new_x         = $PokemonTemp.flydata[1]
    $game_temp.player_new_y         = $PokemonTemp.flydata[2]
    $game_temp.player_new_direction = 2
    $PokemonTemp.flydata = nil
    $scene.transfer_player
    $game_map.autoplay
    $game_map.refresh
  }
  pbEraseEscapePoint
  next true
})



#===============================================================================
# Headbutt
#===============================================================================

HiddenMoveHandlers::CanUseMove.add(:HEADBUTT,proc { |move,pkmn,showmsg|
  facingEvent = $game_player.pbFacingEvent
  if !facingEvent || !facingEvent.name[/HeadbuttTree/i]
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:HEADBUTT,proc { |move,pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  end
  facingEvent = $game_player.pbFacingEvent
  pbHeadbuttEffect(facingEvent)
})



#===============================================================================
# Rock Smash
#===============================================================================

HiddenMoveHandlers::CanUseMove.add(:ROCKSMASH,proc { |move,pkmn,showmsg|
  next false if !pbCheckHiddenMoveBadge(BADGE_FOR_ROCKSMASH,showmsg)
  facingEvent = $game_player.pbFacingEvent
  if !facingEvent || !facingEvent.name[/SmashRock/i]
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:ROCKSMASH,proc { |move,pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  end
  facingEvent = $game_player.pbFacingEvent
  if facingEvent
    pbSmashEvent(facingEvent)
    pbRockSmashRandomEncounter
  end
  next true
})



#===============================================================================
# Strength
#===============================================================================

Events.onAction += proc { |_sender,_e|
  facingEvent = $game_player.pbFacingEvent
  pbStrength if facingEvent && facingEvent.name[/StrengthBoulder/i]
}

HiddenMoveHandlers::CanUseMove.add(:STRENGTH,proc { |move,pkmn,showmsg|
  next false if !pbCheckHiddenMoveBadge(BADGE_FOR_STRENGTH,showmsg)
  if $PokemonMap.strengthUsed
    pbMessage(_INTL("Strength is already being used.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:STRENGTH,proc { |move,pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!\1",pokemon.name,PBMoves.getName(move)))
  end
  pbMessage(_INTL("{1}'s Strength made it possible to move boulders around!",pokemon.name))
  $PokemonMap.strengthUsed = true
  next true
})



#===============================================================================
# Surf
#===============================================================================

Events.onAction += proc { |_sender,_e|
  next if $PokemonGlobal.surfing
  next if pbGetMetadata($game_map.map_id,MetadataBicycleAlways)
  next if !PBTerrain.isSurfable?(pbFacingTerrainTag)
  next if !$game_map.passable?($game_player.x,$game_player.y,$game_player.direction,$game_player)
  pbSurf
}

HiddenMoveHandlers::CanUseMove.add(:SURF,proc { |move,pkmn,showmsg|
  next false if !pbCheckHiddenMoveBadge(BADGE_FOR_SURF,showmsg)
  if $PokemonGlobal.surfing
    pbMessage(_INTL("You're already surfing.")) if showmsg
    next false
  end
  if $game_player.pbHasDependentEvents?
    pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
    next false
  end
  if pbGetMetadata($game_map.map_id,MetadataBicycleAlways)
    pbMessage(_INTL("Let's enjoy cycling!")) if showmsg
    next false
  end
  if !PBTerrain.isSurfable?(pbFacingTerrainTag) ||
     !$game_map.passable?($game_player.x,$game_player.y,$game_player.direction,$game_player)
    pbMessage(_INTL("No surfing here!")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:SURF,proc { |move,pokemon|
  $game_temp.in_menu = false
  pbCancelVehicles
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  end
  surfbgm = pbGetMetadata(0,MetadataSurfBGM)
  pbCueBGM(surfbgm,0.5) if surfbgm
  pbStartSurfing
  next true
})



#===============================================================================
# Sweet Scent
#===============================================================================

HiddenMoveHandlers::CanUseMove.add(:SWEETSCENT,proc { |move,pkmn,showmsg|
  next true
})

HiddenMoveHandlers::UseMove.add(:SWEETSCENT,proc { |move,pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  end
  pbSweetScent
  next true
})



#===============================================================================
# Teleport
#===============================================================================
HiddenMoveHandlers::CanUseMove.add(:TELEPORT,proc { |move,pkmn,showmsg|
  if !pbGetMetadata($game_map.map_id,MetadataOutdoor)
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  pbMessage(_INTL("It looks like this move can't be used here...")) if showmsg
  next false
  healing = $PokemonGlobal.healingSpot
  healing = pbGetMetadata(0,MetadataHome) if !healing   # Home
  if !healing
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  if $game_player.pbHasDependentEvents?
    pbMessage(_INTL("It can't be used when you have someone with you.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::ConfirmUseMove.add(:TELEPORT,proc { |move,pkmn|
  healing = $PokemonGlobal.healingSpot
  healing = pbGetMetadata(0,MetadataHome) if !healing   # Home
  next false if !healing
  mapname = pbGetMapNameFromId(healing[0])
  next pbConfirmMessage(_INTL("Want to return to the healing spot used last in {1}?",mapname))
})

HiddenMoveHandlers::UseMove.add(:TELEPORT,proc { |move,pokemon|
  healing = $PokemonGlobal.healingSpot
  healing = pbGetMetadata(0,MetadataHome) if !healing   # Home
  next false if !healing
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  end
  pbFadeOutIn {
    $game_temp.player_new_map_id    = healing[0]
    $game_temp.player_new_x         = healing[1]
    $game_temp.player_new_y         = healing[2]
    $game_temp.player_new_direction = 2
    $scene.transfer_player
    $game_map.autoplay
    $game_map.refresh
  }
  pbEraseEscapePoint
  next true
})



#===============================================================================
# Waterfall
#===============================================================================

Events.onAction += proc { |_sender,_e|
  terrain = pbFacingTerrainTag
  if terrain==PBTerrain::Waterfall
    pbWaterfall
  elsif terrain==PBTerrain::WaterfallCrest
    pbMessage(_INTL("A wall of water is crashing down with a mighty roar."))
  end
}

HiddenMoveHandlers::CanUseMove.add(:WATERFALL,proc { |move,pkmn,showmsg|
  next false if !pbCheckHiddenMoveBadge(BADGE_FOR_WATERFALL,showmsg)
  if pbFacingTerrainTag!=PBTerrain::Waterfall
    pbMessage(_INTL("Can't use that here.")) if showmsg
    next false
  end
  next true
})

HiddenMoveHandlers::UseMove.add(:WATERFALL,proc { |move,pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  end
  pbAscendWaterfall
  next true
})

#===============================================================================
# Defog
#===============================================================================

HiddenMoveHandlers::CanUseMove.add(:DEFOG,proc { |move,pkmn,showmsg|
  next false if $game_screen.weather_type!=PBFieldWeather::Fog
  next true
})

HiddenMoveHandlers::UseMove.add(:DEFOG,proc { |move,pokemon|
  if !pbHiddenMoveAnimation(pokemon)
    pbMessage(_INTL("{1} used {2}!",pokemon.name,PBMoves.getName(move)))
  end
  pbDefog
  next true
})
