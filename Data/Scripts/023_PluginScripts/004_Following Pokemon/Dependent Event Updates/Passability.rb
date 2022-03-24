#-----------------------------------------------------------------------------
# Update method which checks Dependent Event passabilities to account for
# Following Pokemon
#-----------------------------------------------------------------------------
class Game_Map
  def passableStrict?(x, y, d, self_event = nil)
    return false if !valid?(x, y)
    bit = (1 << (d / 2 - 1)) & 0x0f
    for event in events.values
      next if event == self_event || event.tile_id < 0 || event.through
      next if event.x != x || event.y != y
      return false if PBTerrain.isLedge?(@terrain_tags[event.tile_id])
      if self_event != $game_player
        return true if PBTerrain.isBridge?(@terrain_tags[event.tile_id])
        return true if PBTerrain.isIce?(@terrain_tags[event.tile_id])
        return true if PBTerrain.isWater?(@terrain_tags[event.tile_id])
      end
      passage = @passages[event.tile_id] || 0
      return false if passage & bit != 0 || passage & 0x0f == 0x0f
      return true if @priorities[event.tile_id] == 0
    end
    for i in [2, 1, 0]
      tile_id = data[x, y, i]
      return false if PBTerrain.isLedge?(@terrain_tags[tile_id])
      if self_event != $game_player
        return true if PBTerrain.isBridge?(@terrain_tags[tile_id])
        return true if PBTerrain.isIce?(@terrain_tags[tile_id])
        return true if PBTerrain.isWater?(@terrain_tags[tile_id])
      end
      passage = @passages[tile_id] || 0
      return false if passage & bit != 0 || passage & 0x0f == 0x0f
      return true if @priorities[tile_id] == 0
    end
    return true
  end
end

#-------------------------------------------------------------------------------
# Prevent other events from passing through Following Pokemon. Toggleable
#-------------------------------------------------------------------------------
class Game_Character
  alias __followingpkmn__passableEx? passableEx? unless method_defined?(:__followingpkmn__passableEx?)
  def passableEx?(x, y, d, strict = false)
    ret = __followingpkmn__passableEx?(x, y, d, strict)
    if ret && FollowingPkmn::IMPASSABLE_FOLLOWER && self != $game_player && !self.is_a?(Game_FollowerEvent)
      new_x = x + (d == 6 ? 1 : d == 4 ? -1 : 0)
      new_y = y + (d == 2 ? 1 : d == 8 ? -1 : 0)
      $PokemonTemp.dependentEvents.realEvents.each do |e|
        return false if e.x == new_x && e.y == new_y && !e.through && e.is_a?(Game_FollowerEvent) && FollowingPkmn.active?
      end
    end
    return ret
  end
end


class PokemonMapFactory
  #-----------------------------------------------------------------------------
  # Fix for followers having animations (grass, etc) when toggled off
  # Treats followers as if they are under a bridge when toggled
  #-----------------------------------------------------------------------------
  alias __followingpkmn__getTerrainTag getTerrainTag unless method_defined?(:__followingpkmn__getTerrainTag)
  def getTerrainTag(*args)
    ret = __followingpkmn__getTerrainTag(*args)
    return ret if FollowingPkmn.active?
    x = args[1]
    y = args[2]
    for devent in $PokemonGlobal.dependentEvents
      if devent && devent[8][/FollowerPkmn/] && devent[3] == x &&
         devent[4] == y && PBTerrain.isGrass?(ret)
        ret = PBTerrain::Bridge
        break
      end
    end
    return ret
  end
  #-----------------------------------------------------------------------------
  # Fixed Relative Postions being incorrectly calculated
  #-----------------------------------------------------------------------------
  def getRelativePos(thisMapID, thisX, thisY, otherMapID, otherX, otherY)
    if thisMapID == otherMapID   # Both events share the same map
      return [otherX - thisX, otherY - thisY]
    end
    conns = MapFactoryHelper.getMapConnections
    if conns[thisMapID]
      for conn in conns[thisMapID]
        if conn[0] == otherMapID
          posX = conn[4] - conn[1] + otherX - thisX
          posY = conn[5] - conn[2] + otherY - thisY
          return [posX, posY]
        elsif conn[3] == otherMapID
          posX =  conn[1] - conn[4] + otherX - thisX
          posY =  conn[2] - conn[5] + otherY - thisY
          return [posX, posY]
        end
      end
    end
    return [0, 0]
  end
end
