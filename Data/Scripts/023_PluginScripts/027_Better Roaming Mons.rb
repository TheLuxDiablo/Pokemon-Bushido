#===============================================================================
# * Roaming Icon - by FL (Credits will be apreciated)
#===============================================================================
#
# This script is for Pokémon Essentials. It displays icons on map for roaming
# pokémon.
#
#===============================================================================
#
# To this script works, put it above main. On script section PScreen_RegionMap,
# add line 'drawRoamingPosition(mapindex)' before line 
# 'if playerpos && mapindex==playerpos[0]'. For each roaming pokémon icon, put
# an image on "Graphics/Pictures/mapPokemonXXX.png" changing XXX for species
# number, where "Graphics/Pictures/mapPokemon000.png" is the default one.
#
#===============================================================================

class PokemonRegionMap_Scene
  def drawRoamingPosition(mapindex)
    for roamPos in $PokemonGlobal.roamPosition
      roamingData = RoamingSpecies[roamPos[0]]
      active = $game_switches[roamingData[2]] && (
        $PokemonGlobal.roamPokemon.size <= roamPos[0] || 
        $PokemonGlobal.roamPokemon[roamPos[0]]!=true
      )
      next if !active
      species=getID(PBSpecies,roamingData[0])
      next if !species || species<=0
      pokepos = $game_map ? pbGetMetadata(roamPos[1],MetadataMapPosition) : nil 
      next if mapindex!=pokepos[0]
      x = pokepos[1]
      y = pokepos[2]
      @sprites["roaming#{species}"] = IconSprite.new(0,0,@viewport)
      @sprites["roaming#{species}"].setBitmap(getRoamingIcon(species))
      @sprites["roaming#{species}"].x = -SQUAREWIDTH/2+(x*SQUAREWIDTH)+(
        Graphics.width-@sprites["map"].bitmap.width
      )/2
      @sprites["roaming#{species}"].y = -SQUAREHEIGHT/2+(y*SQUAREHEIGHT)+(
        Graphics.height-@sprites["map"].bitmap.height
      )/2
    end
  end
  
  def getRoamingIcon(species)
    return nil if !species
    fileName = sprintf("Graphics/Pictures/mapPokemon%03d", species)
    ret = pbResolveBitmap(fileName)
    if !ret
      fileName = "Graphics/Pictures/mapPokemon000"
      ret = pbResolveBitmap(fileName)
    end
    return ret
  end
end