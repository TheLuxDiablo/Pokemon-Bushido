# Just fixes a little bug in the "elsif" line.

class PokemonMapFactory
  def getRelativePos(thisMapID, thisX, thisY, otherMapID, otherX, otherY)
    if thisMapID == otherMapID   # Both events share the same map
      return [otherX - thisX, otherY - thisY]
    end
    conns = MapFactoryHelper.getMapConnections
    if conns[thisMapID]
      for conn in conns[thisMapID]
        if conn[0] == otherMapID
          posX = thisX + conn[1] - conn[4] + otherX
          posY = thisY + conn[2] - conn[5] + otherY
          return [posX, posY]
        elsif conn[3] == otherMapID
          posX = thisX + conn[4] - conn[1] + otherX
          posY = thisY + conn[5] - conn[2] + otherY
          return [posX, posY]
        end
      end
    end
    return [0, 0]
  end
end

class Game_Map
  def set_tile(x, y, layer, id = 0)
    self.data[x, y, layer] = id
  end

  def erase_tile(x, y, layer)
    set_tile(x, y, layer, 0)
  end
end
