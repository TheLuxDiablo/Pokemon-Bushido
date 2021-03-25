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

=begin
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
=end


# Make enemy trainer pokemon evolve automatically if their level is high enough
=begin
Events.onTrainerPartyLoad+=proc {|sender,e|
   if e[0] # Trainer data should exist to be loaded, but may not exist somehow
     trainer=e[0][0] # A PokeBattle_Trainer object of the loaded trainer
     items=e[0][1]   # An array of the trainer's items they can use
     party=e[0][2]   # An array of the trainer's Pokémon
     for i in 0...party.length
       party[i].calcStats
       party[i].resetMoves
       evolvePokemonSilent(party[i])
       evolvePokemonSilent(party[i])
     end
   end
}

=begin
Events.onWildPokemonCreate+=proc {|sender,e|
   pokemon=e[0]
   #3-15 = pollen path and iron pass
   sector1=[78,80]
   #10-25 = verdant valley and lumigen hills and folian grove
   sector2=[108,92,103]
   #3-30 = plunge pass, lappy lake, and magnet cave 1, and moncto town, cascade
   sector3=[98,99,89,91,43,150,81,79,146]
   #15-25 = ferrous cave and stacona woods
   sector4=[107,111,121]
   #20-30 = costa path and lush road
   sector5=[77,84,110,93,96,123]
   #25-40 = dim cave and dev room
   sector6=[100,106,90]
   #30-40 = maple trail and yama pass and haunted hollow
   sector7=[105,86,101,151,152]
   #20-50
   sector8=[147]
   #1-1 EV training room
   sector9=[149]
   #40-50 = stacona sea
   #45-55 = route 11 and island forest
   if $game_map.map_id!=0 && $game_switches[99]
     if sector1.include?($game_map.map_id)
       MINLEVEL=2
       MAXLEVEL=15
     elsif sector2.include?($game_map.map_id)
       MINLEVEL=10
       MAXLEVEL=25
     elsif sector3.include?($game_map.map_id)
       MINLEVEL=3
       MAXLEVEL=30
     elsif sector4.include?($game_map.map_id)
       MINLEVEL=15
       MAXLEVEL=25
     elsif sector5.include?($game_map.map_id)
       MINLEVEL=20
       MAXLEVEL=35
     elsif sector6.include?($game_map.map_id)
       MINLEVEL=25
       MAXLEVEL=40
     elsif sector7.include?($game_map.map_id)
       MINLEVEL=30
       MAXLEVEL=45
     elsif sector8.include?($game_map.map_id)
       MINLEVEL=20
       MAXLEVEL=50
     elsif sector9.include?($game_map.map_id)
       MINLEVEL=1
       MAXLEVEL=10
     else
       MINLEVEL=3
       MAXLEVEL=100
     end
     newlevel=pbBalancedLevel($Trainer.party) - 4 + rand(4)   # For variety
     newlevel=1 if newlevel<1
     #newlevel=PBExperience::MAXLEVEL if newlevel>PBExperience::MAXLEVEL
     for pkmn in $Trainer.party
       if pkmn.level > newlevel
          newlevel = pkmn.level
       end
     end
     if $game_switches[97]
       newlevel=newlevel+5-rand(2)
       MAXLEVEL=40
     else
       newlevel=newlevel - 5 + rand(5)
     end
     newlevel=MINLEVEL if newlevel<=MINLEVEL
     newlevel=MAXLEVEL if newlevel>=MAXLEVEL
     newlevel=newlevel-rand(2)+1 if newlevel<=6
     newlevel = newlevel.clamp(1,PBExperience.maxLevel)
     pokemon.level=newlevel
     #pokemon.level=newlevel
     pokemon.calcStats
     pokemon.resetMoves
     evolvePokemonSilent(pokemon)
     evolvePokemonSilent(pokemon)
     evolvePokemonSilent(pokemon)
   end
}





# This is the basis of a trainer modifier.  It works both for trainers loaded
# when you battle them, and for partner trainers when they are registered.
# Note that you can only modify a partner trainer's Pokémon, and not the trainer
# themselves nor their items this way, as those are generated from scratch
# before each battle.
Events.onTrainerPartyLoad+=proc {|sender,e|
   if e[0] # Trainer data should exist to be loaded, but may not exist somehow
     trainer=e[0][0] # A PokeBattle_Trainer object of the loaded trainer
     items=e[0][1]   # An array of the trainer's items they can use
     party=e[0][2]   # An array of the trainer's Pokémon
     #3-15 = pollen path and iron pass
     sector1=[78,80]
     #10-25 = verdant valley and lumigen hills and folian grove
     sector2=[108,92,103]
     #3-30 = plunge pass, lappy lake, and magnet cave 1, and moncto town and Lumigen/Fleural, Cascade
     sector3=[98,99,89,91,43,150,81,79,146]
     #15-25 = ferrous cave and stacona woods
     sector4=[107,111,121]
     #20-30 = costa path and lush road
     sector5=[77,84,110,93,96,123]
     #25-35 = Driftwood and lab
     sectorLAB=[127,113,109]
     #25-40 = dim cave and dev room
     sector6=[100,106,90]
     #30-45 = maple trail and yama pass and secret labs and haunted hollow
     sector7=[105,86,101,143,112,145,151,152]
     #20-50 = blighted bog
     sector8=[147]
     #1-1 EV training room
     sector9=[149]
     #40-50 = stacona sea
     #45-55 = route 11 and island forest
    if $game_map.map_id!=0 && $game_switches[100]
     if sector1.include?($game_map.map_id)
       MINLEVEL=3
       MAXLEVEL=15
     elsif sector2.include?($game_map.map_id)
       MINLEVEL=10
       MAXLEVEL=25
     elsif sector3.include?($game_map.map_id)
       MINLEVEL=3
       MAXLEVEL=30
     elsif sector4.include?($game_map.map_id)
       MINLEVEL=15
       MAXLEVEL=25
     elsif sector5.include?($game_map.map_id)
       MINLEVEL=20
       MAXLEVEL=35
     elsif sectorLAB.include?($game_map.map_id)
       MINLEVEL=25
       MAXLEVEL=40
     elsif sector6.include?($game_map.map_id)
       MINLEVEL=25
       MAXLEVEL=45
     elsif sector7.include?($game_map.map_id)
       MINLEVEL=30
       MAXLEVEL=45
     elsif sector8.include?($game_map.map_id)
       MINLEVEL=20
       MAXLEVEL=50
     elsif sector9.include?($game_map.map_id)
       MINLEVEL=1
       MAXLEVEL=10
     else
       MINLEVEL=3
       MAXLEVEL=100
     end
       newlevel=pbBalancedLevel($Trainer.party) - 2 + rand(3)   # For variety
       newlevel=1 if newlevel<1
       #newlevel=PBExperience::MAXLEVEL if newlevel>PBExperience::MAXLEVEL
       for pkmn in $Trainer.party
         if pkmn.level > newlevel
            newlevel = pkmn.level
         end
       end
       for i in 0...party.length
         randlevel=newlevel
         if $game_switches[96]
           MAXLEVEL=100
           randlevel=randlevel+15-rand(3)
         elsif $game_switches[98]
           randlevel=randlevel+6-rand(4)
         else
           randlevel=randlevel-3+rand(3)
         end
         randlevel=MINLEVEL if randlevel<=MINLEVEL
         randlevel=MAXLEVEL if randlevel>=MAXLEVEL
         randlevel=randlevel-rand(2) if randlevel<=5
         randlevel = randlevel.clamp(1,PBExperience.maxLevel)
         party[i].level=randlevel
         party[i].calcStats
         party[i].resetMoves
         evolvePokemonSilent(party[i])
         evolvePokemonSilent(party[i])
         evolvePokemonSilent(party[i])
       end
      end
   end
}
=end
