################################################################################
# This section was created solely for you to put various bits of code that
# modify various wild Pokémon and trainers immediately prior to battling them.
# Be sure that any code you use here ONLY applies to the Pokémon/trainers you
# want it to apply to!
################################################################################

# Make all wild Pokémon shiny while a certain Switch is ON (see Settings).
Events.onWildPokemonCreate += proc { |_sender, e|
  pokemon = e[0]
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


# Hidden Ability in Wild Pokemon and Ability Charm Code
Events.onWildPokemonCreate+=proc {|sender,e|
   pokemon=e[0]
   value = $PokemonBag.pbHasItem?(:ABILITYCHARM) ? 10 : 20
   if rand(value)<1
     abils=pokemon.getAbilityList
     abilIndex=[]
     for i in abils
       abilIndex.push(i[1]) if i[0]>0 && i[1]>1
     end
     pokemon.setAbility(abilIndex[rand(abilIndex.length)])
   end
}

# Used in the random dungeon map.  Makes the levels of all wild Pokémon in that
# map depend on the levels of Pokémon in the player's party.
# This is a simple method, and can/should be modified to account for evolutions
# and other such details.  Of course, you don't HAVE to use this code.
Events.onWildPokemonCreate += proc { |_sender, e|
  pokemon = e[0]
  if $game_map.map_id == 0
    max_level = PBExperience.maxLevel
    new_level = pbBalancedLevel($Trainer.party) - 4 + rand(5)   # For variety
    new_level = 1 if new_level < 1
    new_level = max_level if new_level > max_level
    pokemon.level = new_level
    pokemon.calcStats
    pokemon.resetMoves
  end
}

# This is the basis of a trainer modifier.  It works both for trainers loaded
# when you battle them, and for partner trainers when they are registered.
# Note that you can only modify a partner trainer's Pokémon, and not the trainer
# themselves nor their items this way, as those are generated from scratch
# before each battle.
#Events.onTrainerPartyLoad += proc { |_sender, e|
#  if e[0] # Trainer data should exist to be loaded, but may not exist somehow
#    trainer = e[0][0] # A PokeBattle_Trainer object of the loaded trainer
#    items = e[0][1]   # An array of the trainer's items they can use
#    party = e[0][2]   # An array of the trainer's Pokémon
#    YOUR CODE HERE
#  end
#}
