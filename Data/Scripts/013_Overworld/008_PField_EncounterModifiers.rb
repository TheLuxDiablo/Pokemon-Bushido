################################################################################
# This section was created solely for you to put various bits of code that
# modify various wild Pokémon and trainers immediately prior to battling them.
# Be sure that any code you use here ONLY applies to the Pokémon/trainers you
# want it to apply to!
################################################################################

# Make all wild Pokémon shiny while a certain Switch is ON (see Settings).
Events.onWildPokemonCreate+=proc {|sender,e|
   pokemon=e[0]
   if $game_switches[SHINY_WILD_POKEMON_SWITCH]
     pokemon.makeShiny
   end
}

Events.onWildPokemonCreate+=proc {|sender,e|
   pokemon=e[0]
   if $game_switches[90]
     pokemon.makeNotShiny
     pokemon.makeShadow
   end
}

Events.onWildPokemonCreate+=proc {|sender,e|
   pokemon=e[0]
   if rand(69)<1
     abils=pokemon.getAbilityList
     abilIndex=[]
     for i in abils
       abilIndex.push(i[1]) if i[0]>0 && i[1]>1
     end
     pokemon.setAbility(abilIndex[rand(abilIndex.length)])
   end
}


Events.onWildPokemonCreate+=proc {|sender,e|
   evolvePokemonSilent(pokemon)
   evolvePokemonSilent(pokemon)
}
