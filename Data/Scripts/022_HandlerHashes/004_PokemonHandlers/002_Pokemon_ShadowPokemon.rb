ItemHandlers::UseOnPokemon.add(:JOYSCENT,proc { |item,pokemon,scene|
  pbRaiseHappinessAndReduceHeart(pokemon,scene,500)
})

ItemHandlers::UseOnPokemon.add(:EXCITESCENT,proc { |item,pokemon,scene|
  pbRaiseHappinessAndReduceHeart(pokemon,scene,1000)
})

ItemHandlers::UseOnPokemon.add(:VIVIDSCENT,proc { |item,pokemon,scene|
  pbRaiseHappinessAndReduceHeart(pokemon,scene,2000)
})

ItemHandlers::UseOnPokemon.add(:SUSHI1,proc { |item,pokemon,scene|
  if pokemon.fainted? || pokemon.hp==pokemon.totalhp
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  if pokemon.shadowPokemon?
    pbRaiseHappinessAndReduceHeart(pokemon,scene,300)
  end
  pbHPItem(pokemon,30,scene)
  next true
})

ItemHandlers::UseOnPokemon.add(:SUSHI2,proc { |item,pokemon,scene|
  if pokemon.fainted? || pokemon.hp==pokemon.totalhp
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  if pokemon.shadowPokemon?
    pbRaiseHappinessAndReduceHeart(pokemon,scene,600)
  end
  pbHPItem(pokemon,60,scene)
  next true
})

ItemHandlers::UseOnPokemon.add(:SUSHI3,proc { |item,pokemon,scene|
  if pokemon.fainted? || pokemon.hp==pokemon.totalhp
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  if pokemon.shadowPokemon?
    pbRaiseHappinessAndReduceHeart(pokemon,scene,900)
  end
  pbHPItem(pokemon,90,scene)
  next true
})

ItemHandlers::UseOnPokemon.add(:SUSHI4,proc { |item,pokemon,scene|
  if pokemon.fainted? || pokemon.hp==pokemon.totalhp
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  if pokemon.shadowPokemon?
    pbRaiseHappinessAndReduceHeart(pokemon,scene,1200)
  end
  pbHPItem(pokemon,120,scene)
  next true
})

ItemHandlers::UseOnPokemon.add(:TIMEFLUTE,proc { |item,pokemon,scene|
  if !pokemon.shadowPokemon?
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  pokemon.heartgauge = 0
  pbReadyToPurify(pokemon)
  next true
})
