def pbChangeEventSpriteToMon(eventID, mon, shiny = false)
    # Get the event from its id
    thisevent = $game_map.events[eventID]
    monid = mon.species
    # Setting up shininess, form and stuffs
    fname = _INTL("")
    fname += _INTL("0") if monid < 100
    fname += _INTL("0") if monid < 10
    fname += _INTL("{1}",monid)
    fname += _INTL("s") if shiny
    fname += _INTL(".png")
    # Finally sets the graphic
    thisevent.character_name = fname
    thisevent.character_hue = 0
    echoln fname
end

def generateRandomPkmn(species,level)
    pkmn = PokeBattle_Pokemon.new(species,level,$Trainer)
    newpkmn = randomizeSpecies(pkmn, true)
    return newpkmn
end

def pbAddPokemonNoRandomizer(pokemon,level=nil,seeform=true)
    return if !pokemon
    if pbBoxesFull?
      pbMessage(_INTL("There's no more room for Pokémon!\1"))
      pbMessage(_INTL("The Pokémon Boxes are full and can't accept any more!"))
      return false
    end
    pokemon = getID(PBSpecies,pokemon)
    if pokemon.is_a?(Integer) && level.is_a?(Integer)
      pokemon = pbNewPkmn(pokemon,level)
    end
    speciesname = PBSpecies.getName(pokemon.species)
    pbMessage(_INTL("\\me[Pkmn get]{1} obtained {2}!\1",$Trainer.name,speciesname))
    pbNicknameAndStore(pokemon)
    pbSeenForm(pokemon) if seeform
    return true
  end