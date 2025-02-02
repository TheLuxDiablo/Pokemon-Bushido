#-------------------------------------------------------------------------------
# These are used to define whether the follower should appear or disappear when
# refreshing it. "next true" will let it stay and "next false" will make it
# disappear
#-------------------------------------------------------------------------------
Events.FollowerRefresh += proc { |_pkmn|
  # The Pokemon disappears if the player is cycling
  next false if $PokemonGlobal.bicycle
  # Pokeride Compatibility
  next false if defined?($PokemonGlobal.mount) && $PokemonGlobal.mount
}

Events.FollowerRefresh += proc { |_pkmn|
  # The Pokemon disappears if the name of the map is Cedolan Gym
  next false if $game_map.name.include?("Cedolan Gym")
}

Events.FollowerRefresh += proc { |pkmn|
  if $PokemonGlobal.surfing
    next true if pkmn.hasType?(:WATER)
    next false if FollowingPkmn::SURFING_FOLLOWERS_EXCEPTIONS.any? do |s|
                    getID(PBSpecies, s) == pkmn.species
                  end
    next true if pkmn.hasType?(:FLYING)
    next true if pkmn.hasAbility?(:LEVITATE)
    next true if FollowingPkmn::SURFING_FOLLOWERS.any? do |s|
                   getID(PBSpecies, s) == pkmn.species
                 end
    next false
  end
}

Events.FollowerRefresh += proc { |pkmn|
  if $PokemonGlobal.diving
    next true if pkmn.hasType?(:WATER)
    next false
  end
}
