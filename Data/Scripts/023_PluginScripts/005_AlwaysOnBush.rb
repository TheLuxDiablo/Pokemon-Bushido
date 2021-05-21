#===============================================================================
# Always on bush by KleinStudio
# wahpokemon (dot) com
# pokemonfangames (dot) com
#
# additional editing by derFischae
# to assure that game_characters don't stay on water
# which could be useful for overworld encounters in water.
#
# Installation: As simple as it can be. Insert a new script file above main in
# the RPGMakerXP script editor. Name it always_on_bush & copy this code into it.
#===============================================================================

#===============================================================================
# overrides the method bush_depth in the class Game_Character
#===============================================================================

class Game_Character
# The original code
#  def bush_depth
#    return 0 if @tile_id>0 or @always_on_top
#    if @jump_count <= 0
#      xbehind=(@direction==4) ? @x+1 : (@direction==6) ? @x-1 : @x
#      ybehind=(@direction==8) ? @y+1 : (@direction==2) ? @y-1 : @y
#      return 32 if self.map.deepBush?(@x,@y) and self.map.deepBush?(xbehind,ybehind)
#      return 12 if self.map.bush?(@x,@y) and !moving?
#    end
#    return 0
#  end

# Die von KleinStudio geaenderte Version
  def bush_depth
    if @tile_id > 0 or @always_on_top
      return 0
    end
    xnext=(@direction==4) ? @x-1 : (@direction==6) ? @x+1 : @x
    ynext=(@direction==8) ? @y-1 : (@direction==2) ? @y+1 : @y

    xbehind=(@direction==4) ? @x+1 : (@direction==6) ? @x-1 : @x
    ybehind=(@direction==8) ? @y+1 : (@direction==2) ? @y-1 : @y

    if @jump_count <= 0 and self.map.bush?(@x, @y) and
      !self.map.bush?(xbehind, ybehind) and !moving?
      return 12
    elsif @jump_count <= 0 and self.map.bush?(@x, @y) and
      self.map.bush?(xbehind, ybehind)
      return 12
    # Hier habe ich etwas fuer das wasser hinzugefuegt
    elsif @jump_count <= 0 and self.map.water?(@x, @y) and
      !self.map.water?(xbehind, ybehind) and !moving?
      return 12
    elsif @jump_count <= 0 and self.map.water?(@x, @y) and
      self.map.water?(xbehind, ybehind)
      return 12
    else
      return 0
    end
  end
end

#===============================================================================
# overrides the method bush_depth in the class Game_Player
#===============================================================================

class Game_Player < Game_Character
  def bush_depth
    return 0 if @tile_id > 0 or @always_on_top
    xbehind=(@direction==4) ? @x+1 : (@direction==6) ? @x-1 : @x
    ybehind=(@direction==8) ? @y+1 : (@direction==2) ? @y-1 : @y
    if !$game_map.valid?(@x,@y) || !$game_map.valid?(xbehind,ybehind)
      return 0 if !$MapFactory
      newhere=$MapFactory.getNewMap(@x,@y)
      newbehind=$MapFactory.getNewMap(xbehind,ybehind)
      if $game_map.valid?(@x,@y)
        heremap=self.map; herex=@x; herey=@y
      elsif newhere && newhere[0]
        heremap=newhere[0]; herex=newhere[1]; herey=newhere[2]
      else
        return 0
      end
      if $game_map.valid?(xbehind,ybehind)
        behindmap=self.map; behindx=xbehind; behindy=ybehind
      elsif newbehind && newbehind[0]
        behindmap=newbehind[0]; behindx=newbehind[1]; behindy=newbehind[2]
      else
        return 0
      end
      if @jump_count <= 0 and heremap.deepBush?(herex, herey) and
                              behindmap.deepBush?(behindx, behindy)
        return 32
      elsif @jump_count <= 0 and heremap.bush?(herex, herey) and !moving?
        return 12
      else
        return 0
      end
    else
      if @tile_id > 0 or @always_on_top
        return 0
      end
      xnext=(@direction==4) ? @x-1 : (@direction==6) ? @x+1 : @x
      ynext=(@direction==8) ? @y-1 : (@direction==2) ? @y+1 : @y

      xbehind=(@direction==4) ? @x+1 : (@direction==6) ? @x-1 : @x
      ybehind=(@direction==8) ? @y+1 : (@direction==2) ? @y-1 : @y

      if @jump_count <= 0 and self.map.bush?(@x, @y) and
        !self.map.bush?(xbehind, ybehind) and !moving?
        return 12
      elsif @jump_count <= 0 and self.map.bush?(@x, @y) and
        self.map.bush?(xbehind, ybehind)
        return 12
      else
        return 0
      end
    end
  end
end

#===============================================================================
# adds new method water?(x,y) to the class Game-Map (originally defined in script Game_Map)
#===============================================================================

class Game_Map
  def water?(x,y)
    if @map_id != 0
      for i in [2, 1, 0]
        tile_id = data[x, y, i]
        if tile_id == nil
          return false
        elsif PBTerrain.isBridge?(@terrain_tags[tile_id]) && $PokemonGlobal &&
              $PokemonGlobal.bridge>0
          return false
        elsif (@terrain_tags[tile_id]==PBTerrain::Sand)
          return false
        elsif #@passages[tile_id] & 0x40 == 0x40 &&
             (@terrain_tags[tile_id]==PBTerrain::Water ||
              @terrain_tags[tile_id]==PBTerrain::StillWater ||
              @terrain_tags[tile_id]==PBTerrain::DeepWater ||
              @terrain_tags[tile_id]==PBTerrain::WaterfallCrest ||
              @terrain_tags[tile_id]==PBTerrain::Waterfall)
          return true
        end
      end
    end
    return false
  end
end
