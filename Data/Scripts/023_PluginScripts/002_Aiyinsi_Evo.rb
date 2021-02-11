def evolvePokemonSilent(pokemon)
  newspecies = pbCheckEvolution(pokemon)
  if newspecies == -1
    return pokemon
  end
  newspeciesname = PBSpecies.getName(newspecies)
  oldspeciesname = pokemon.name
  pokemon.species = newspecies
  pokemon.name = newspeciesname if pokemon.name == oldspeciesname
  pokemon.calcStats
  pokemon.resetMoves
  return pokemon
end

def revertToBaby(pkmn)
  nick = pkmn.nicknamed?
  newSpecies = pbGetBabySpecies(pkmn.species) # revert to the first evolution
#  return if newSpecies < 1
  newName = PBSpecies.getName(newSpecies)
  pkmn.species = newSpecies
  pkmn.name = newName if !nick
  pkmn.level = 5
  pkmn.item = 0
  pkmn.calcStats
  pkmn.resetMoves
end
