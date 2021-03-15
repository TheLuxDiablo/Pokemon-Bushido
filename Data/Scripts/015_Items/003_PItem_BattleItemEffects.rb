#===============================================================================
# CanUseInBattle handlers
#===============================================================================
ItemHandlers::CanUseInBattle.add(:GUARDSPEC,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  if !battler || battler.pbOwnSide.effects[PBEffects::Mist]>0
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next true
})

ItemHandlers::CanUseInBattle.add(:POKEDOLL,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  if !battle.wildBattle?
    if showMessages
      scene.pbDisplay(_INTL("Oak's words echoed... There's a time and place for everything! But not now."))
    end
    next false
  end
  next true
})

ItemHandlers::CanUseInBattle.copy(:POKEDOLL,:FLUFFYTAIL,:POKETOY)

ItemHandlers::CanUseInBattle.addIf(proc { |item| pbIsPokeBall?(item) },   # Poké Balls
  proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
    if battle.pbPlayer.party.length>=6 && $PokemonStorage.full?
      scene.pbDisplay(_INTL("There is no room left in the PC!")) if showMessages
      next false
    end
    # NOTE: Using a Poké Ball consumes all your actions for the round. The code
    #       below is one half of making this happen; the other half is in def
    #       pbItemUsesAllActions?.
    if !firstAction
      scene.pbDisplay(_INTL("It's impossible to aim without being focused!")) if showMessages
      next false
    end
    if battler.semiInvulnerable?
      scene.pbDisplay(_INTL("It's no good! It's impossible to aim at a Pokémon that's not in sight!")) if showMessages
      next false
    end
    # NOTE: The code below stops you from throwing a Poké Ball if there is more
    #       than one unfainted opposing Pokémon. (Snag Balls can be thrown in
    #       this case, but only in trainer battles, and the trainer will deflect
    #       them if they are trying to catch a non-Shadow Pokémon.)
    if battle.pbOpposingBattlerCount>1 && !(pbIsSnagBall?(item) && battle.trainerBattle?)
      if battle.pbOpposingBattlerCount==2
        scene.pbDisplay(_INTL("It's no good! It's impossible to aim when there are two Pokémon!")) if showMessages
      else
        scene.pbDisplay(_INTL("It's no good! It's impossible to aim when there are more than one Pokémon!")) if showMessages
      end
      next false
    end
    next true
  }
)

ItemHandlers::CanUseInBattle.add(:JOYSCENT,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  if !battler || !battler.shadowPokemon? || !battler.inHyperMode?
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next true
})
ItemHandlers::CanUseInBattle.copy(:JOYSCENT,:EXCITESCENT,:VIVIDSCENT)

ItemHandlers::CanUseInBattle.add(:POTION,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  if !pokemon.able? || pokemon.hp==pokemon.totalhp
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next true
})

ItemHandlers::CanUseInBattle.copy(:POTION,
   :SUPERPOTION,:HYPERPOTION,:MAXPOTION,:BERRYJUICE,:SWEETHEART,:FRESHWATER,
   :SODAPOP,:LEMONADE,:MOOMOOMILK,:ORANBERRY,:SITRUSBERRY,:ENERGYPOWDER,
   :ENERGYROOT,:JAM1,:JAM2,:JAM3,:JAM4,:RAMEN1,:RAMEN2,:RAMEN3,:BENTO,:SUSHI1,:SUSHI2,:SUSHI3,:SUSHI4)
ItemHandlers::CanUseInBattle.copy(:POTION,:RAGECANDYBAR) if !NEWEST_BATTLE_MECHANICS

ItemHandlers::CanUseInBattle.add(:AWAKENING,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  next pbBattleItemCanCureStatus?(PBStatuses::SLEEP,pokemon,scene,showMessages)
})

ItemHandlers::CanUseInBattle.copy(:AWAKENING,:CHESTOBERRY)

ItemHandlers::CanUseInBattle.add(:BLUEFLUTE,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  if battler && battler.hasActiveAbility?(:SOUNDPROOF)
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next pbBattleItemCanCureStatus?(PBStatuses::SLEEP,pokemon,scene,showMessages)
})

ItemHandlers::CanUseInBattle.add(:ANTIDOTE,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  next pbBattleItemCanCureStatus?(PBStatuses::POISON,pokemon,scene,showMessages)
})

ItemHandlers::CanUseInBattle.copy(:ANTIDOTE,:PECHABERRY)

ItemHandlers::CanUseInBattle.add(:BURNHEAL,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  next pbBattleItemCanCureStatus?(PBStatuses::BURN,pokemon,scene,showMessages)
})

ItemHandlers::CanUseInBattle.copy(:BURNHEAL,:RAWSTBERRY)

ItemHandlers::CanUseInBattle.add(:PARALYZEHEAL,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  next pbBattleItemCanCureStatus?(PBStatuses::PARALYSIS,pokemon,scene,showMessages)
})

ItemHandlers::CanUseInBattle.copy(:PARALYZEHEAL,:PARLYZHEAL,:CHERIBERRY)

ItemHandlers::CanUseInBattle.add(:ICEHEAL,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  next pbBattleItemCanCureStatus?(PBStatuses::FROZEN,pokemon,scene,showMessages)
})

ItemHandlers::CanUseInBattle.copy(:ICEHEAL,:ASPEARBERRY)

ItemHandlers::CanUseInBattle.add(:FULLHEAL,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  if !pokemon.able? ||
     (pokemon.status==PBStatuses::NONE &&
     (!battler || battler.effects[PBEffects::Confusion]==0))
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next true
})

ItemHandlers::CanUseInBattle.copy(:FULLHEAL,
   :LAVACOOKIE,:OLDGATEAU,:CASTELIACONE,:LUMIOSEGALETTE,:SHALOURSABLE,
   :BIGMALASADA,:LUMBERRY,:HEALPOWDER)
ItemHandlers::CanUseInBattle.copy(:FULLHEAL,:RAGECANDYBAR) if NEWEST_BATTLE_MECHANICS

ItemHandlers::CanUseInBattle.add(:FULLRESTORE,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  if !pokemon.able? ||
     (pokemon.hp==pokemon.totalhp && pokemon.status==PBStatuses::NONE &&
     (!battler || battler.effects[PBEffects::Confusion]==0))
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next true
})

ItemHandlers::CanUseInBattle.copy(:FULLRESTORE,:CURRY)

ItemHandlers::CanUseInBattle.add(:REVIVE,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  if pokemon.able? || pokemon.egg?
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next true
})

ItemHandlers::CanUseInBattle.copy(:REVIVE,:MAXREVIVE,:REVIVALHERB)

ItemHandlers::CanUseInBattle.add(:ETHER,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  if !pokemon.able? || move<0 ||
     pokemon.moves[move].totalpp<=0 ||
     pokemon.moves[move].pp==pokemon.moves[move].totalpp
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next true
})

ItemHandlers::CanUseInBattle.copy(:ETHER,:MAXETHER,:LEPPABERRY)

ItemHandlers::CanUseInBattle.add(:ELIXIR,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  if !pokemon.able?
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  canRestore = false
  for m in pokemon.moves
    next if m.id==0
    next if m.totalpp<=0 || m.pp==m.totalpp
    canRestore = true
    break
  end
  if !canRestore
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next true
})

ItemHandlers::CanUseInBattle.copy(:ELIXIR,:MAXELIXIR)

ItemHandlers::CanUseInBattle.add(:REDFLUTE,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  if !battler || battler.effects[PBEffects::Attract]<0 ||
     battler.hasActiveAbility?(:SOUNDPROOF)
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next true
})

ItemHandlers::CanUseInBattle.add(:PERSIMBERRY,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  if !battler || battler.effects[PBEffects::Confusion]==0
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next true
})

ItemHandlers::CanUseInBattle.add(:YELLOWFLUTE,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  if !battler || battler.effects[PBEffects::Confusion]==0 ||
     battler.hasActiveAbility?(:SOUNDPROOF)
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next true
})

ItemHandlers::CanUseInBattle.add(:XATTACK,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  next pbBattleItemCanRaiseStat?(PBStats::ATTACK,battler,scene,showMessages)
})

ItemHandlers::CanUseInBattle.copy(:XATTACK,:XATTACK2,:XATTACK3,:XATTACK6)

ItemHandlers::CanUseInBattle.add(:XDEFENSE,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  next pbBattleItemCanRaiseStat?(PBStats::DEFENSE,battler,scene,showMessages)
})

ItemHandlers::CanUseInBattle.copy(:XDEFENSE,
   :XDEFENSE2,:XDEFENSE3,:XDEFENSE6,:XDEFEND,:XDEFEND2,:XDEFEND3,:XDEFEND6)

ItemHandlers::CanUseInBattle.add(:XSPATK,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  next pbBattleItemCanRaiseStat?(PBStats::SPATK,battler,scene,showMessages)
})

ItemHandlers::CanUseInBattle.copy(:XSPATK,
   :XSPATK2,:XSPATK3,:XSPATK6,:XSPECIAL,:XSPECIAL2,:XSPECIAL3,:XSPECIAL6)

ItemHandlers::CanUseInBattle.add(:XSPDEF,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  next pbBattleItemCanRaiseStat?(PBStats::SPDEF,battler,scene,showMessages)
})

ItemHandlers::CanUseInBattle.copy(:XSPDEF,:XSPDEF2,:XSPDEF3,:XSPDEF6)

ItemHandlers::CanUseInBattle.add(:XSPEED,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  next pbBattleItemCanRaiseStat?(PBStats::SPEED,battler,scene,showMessages)
})

ItemHandlers::CanUseInBattle.copy(:XSPEED,:XSPEED2,:XSPEED3,:XSPEED6)

ItemHandlers::CanUseInBattle.add(:XACCURACY,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  next pbBattleItemCanRaiseStat?(PBStats::ACCURACY,battler,scene,showMessages)
})

ItemHandlers::CanUseInBattle.copy(:XACCURACY,:XACCURACY2,:XACCURACY3,:XACCURACY6)

ItemHandlers::CanUseInBattle.add(:DIREHIT,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  if !battler || battler.effects[PBEffects::FocusEnergy]>=1
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next true
})

ItemHandlers::CanUseInBattle.add(:DIREHIT2,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  if !battler || battler.effects[PBEffects::FocusEnergy]>=2
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next true
})

ItemHandlers::CanUseInBattle.add(:DIREHIT3,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  if !battler || battler.effects[PBEffects::FocusEnergy]>=3
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next true
})

ItemHandlers::CanUseInBattle.add(:POKEFLUTE,proc { |item,pokemon,battler,move,firstAction,battle,scene,showMessages|
  anyAsleep = false
  battle.eachBattler do |b|
    next if b.status!=PBStatuses::SLEEP || b.hasActiveAbility?(:SOUNDPROOF)
    anyAsleep = true
    break
  end
  if !anyAsleep
    scene.pbDisplay(_INTL("It won't have any effect.")) if showMessages
    next false
  end
  next true
})

#===============================================================================
# UseInBattle handlers
# For items used directly or on an opposing battler
#===============================================================================
ItemHandlers::UseInBattle.add(:GUARDSPEC,proc { |item,battler,battle|
  battler.pbOwnSide.effects[PBEffects::Mist] = 5
  battle.pbDisplay(_INTL("{1} became shrouded in mist!",battler.pbTeam))
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::UseInBattle.add(:POKEDOLL,proc { |item,battler,battle|
  battle.decision = 3
  battle.pbDisplayPaused(_INTL("You got away safely!"))
})

ItemHandlers::UseInBattle.copy(:POKEDOLL,:FLUFFYTAIL,:POKETOY)

ItemHandlers::UseInBattle.add(:POKEFLUTE,proc { |item,battler,battle|
  battle.eachBattler do |b|
    next if b.status!=PBStatuses::SLEEP || b.hasActiveAbility?(:SOUNDPROOF)
    b.pbCureStatus(false)
  end
  scene.pbRefresh
  scene.pbDisplay(_INTL("All Pokémon were roused by the tune!"))
})

ItemHandlers::UseInBattle.addIf(proc { |item| pbIsPokeBall?(item) },   # Poké Balls
  proc { |item,battler,battle|
    battle.pbThrowPokeBall(battler.index,item)
  }
)

#===============================================================================
# BattleUseOnPokemon handlers
# For items used on Pokémon or on a Pokémon's move
#===============================================================================
ItemHandlers::BattleUseOnPokemon.add(:RAMEN1,proc { |item,pokemon,battler,choices,scene|
  pokemon.changeHappiness("ramen1")
  pbBattleHPItem(pokemon,battler,50,scene)
})
ItemHandlers::BattleUseOnPokemon.add(:RAMEN2,proc { |item,pokemon,battler,choices,scene|
  pokemon.changeHappiness("ramen2")
  pbBattleHPItem(pokemon,battler,80,scene)
})
ItemHandlers::BattleUseOnPokemon.add(:RAMEN3,proc { |item,pokemon,battler,choices,scene|
  pokemon.changeHappiness("ramen3")
  pbBattleHPItem(pokemon,battler,120,scene)
})
ItemHandlers::BattleUseOnPokemon.add(:BENTO,proc { |item,pokemon,battler,choices,scene|
  pokemon.changeHappiness("ramen3")
  pbBattleHPItem(pokemon,battler,pokemon.totalhp-pokemon.hp,scene)
})
ItemHandlers::BattleUseOnPokemon.add(:CURRY,proc { |item,pokemon,battler,choices,scene|
  pokemon.healStatus
  battler.pbCureStatus(false) if battler
  battler.pbCureConfusion if battler
  name = (battler) ? battler.pbThis : pokemon.name
  if pokemon.hp<pokemon.totalhp
    pbBattleHPItem(pokemon,battler,100,scene)
  else
    scene.pbRefresh
    scene.pbDisplay(_INTL("{1} became healthy.",name))
  end
})


ItemHandlers::BattleUseOnPokemon.add(:POTION,proc { |item,pokemon,battler,choices,scene|
  pbBattleHPItem(pokemon,battler,20,scene)
})

ItemHandlers::BattleUseOnPokemon.copy(:POTION,:BERRYJUICE,:SWEETHEART,:JAM1)
ItemHandlers::BattleUseOnPokemon.copy(:POTION,:RAGECANDYBAR) if !NEWEST_BATTLE_MECHANICS

ItemHandlers::BattleUseOnPokemon.add(:SUPERPOTION,proc { |item,pokemon,battler,choices,scene|
  pbBattleHPItem(pokemon,battler,50,scene)
})
ItemHandlers::BattleUseOnPokemon.copy(:SUPERPOTION,:JAM2)

ItemHandlers::BattleUseOnPokemon.add(:HYPERPOTION,proc { |item,pokemon,battler,choices,scene|
  pbBattleHPItem(pokemon,battler,200,scene)
})
ItemHandlers::BattleUseOnPokemon.copy(:HYPERPOTION,:JAM3)

ItemHandlers::BattleUseOnPokemon.add(:MAXPOTION,proc { |item,pokemon,battler,choices,scene|
  pbBattleHPItem(pokemon,battler,pokemon.totalhp-pokemon.hp,scene)
})
ItemHandlers::BattleUseOnPokemon.copy(:MAXPOTION,:JAM4)

ItemHandlers::BattleUseOnPokemon.add(:JOYSCENT,proc { |item,battler,scene|
  battler.pokemon.hypermode = false
  battler.pokemon.adjustHeart(-500)
  scene.pbDisplay(_INTL("{1} came to its senses from the {2}!",battler.pbThis,PBItems.getName(item)))
  next true
})

ItemHandlers::BattleUseOnPokemon.add(:EXCITESCENT,proc { |item,battler,scene|
  battler.pokemon.hypermode = false
  battler.pokemon.adjustHeart(-1000)
  scene.pbDisplay(_INTL("{1} came to its senses from the {2}!",battler.pbThis,PBItems.getName(item)))
  next true
})

ItemHandlers::BattleUseOnPokemon.add(:VIVIDSCENT,proc { |item,battler,scene|
  battler.pokemon.hypermode = false
  battler.pokemon.adjustHeart(-2000)
  scene.pbDisplay(_INTL("{1} came to its senses from the {2}!",battler.pbThis,PBItems.getName(item)))
  next true
})

ItemHandlers::BattleUseOnPokemon.add(:SUSHI1,proc { |item,battler,scene|
  pbBattleHPItem(pokemon,battler,30,scene)
  if battler.inHyperMode?
    battler.pokemon.hypermode = false
    scene.pbDisplay(_INTL("{1} came to its senses from the {2}!",battler.pbThis,PBItems.getName(item)))
  end
  if battler.shadowPokemon?
    battler.pokemon.adjustHeart(-400)
  end
  next true
})

ItemHandlers::BattleUseOnPokemon.add(:SUSHI2,proc { |item,battler,scene|
  pbBattleHPItem(pokemon,battler,60,scene)
  if battler.inHyperMode?
    battler.pokemon.hypermode = false
    scene.pbDisplay(_INTL("{1} came to its senses from the {2}!",battler.pbThis,PBItems.getName(item)))
  end
  if battler.shadowPokemon?
    battler.pokemon.adjustHeart(-800)
  end
  next true
})

ItemHandlers::BattleUseOnPokemon.add(:SUSHI3,proc { |item,battler,scene|
  pbBattleHPItem(pokemon,battler,90,scene)
  if battler.inHyperMode?
    battler.pokemon.hypermode = false
    scene.pbDisplay(_INTL("{1} came to its senses from the {2}!",battler.pbThis,PBItems.getName(item)))
  end
  if battler.shadowPokemon?
    battler.pokemon.adjustHeart(-1600)
  end
  next true
})

ItemHandlers::BattleUseOnPokemon.add(:SUSHI4,proc { |item,battler,scene|
  pbBattleHPItem(pokemon,battler,120,scene)
  if battler.inHyperMode?
    battler.pokemon.hypermode = false
    scene.pbDisplay(_INTL("{1} came to its senses from the {2}!",battler.pbThis,PBItems.getName(item)))
  end
  if battler.shadowPokemon?
    battler.pokemon.adjustHeart(-2400)
  end
  next true
})

ItemHandlers::BattleUseOnPokemon.add(:FRESHWATER,proc { |item,pokemon,battler,choices,scene|
  pbBattleHPItem(pokemon,battler,50,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:SODAPOP,proc { |item,pokemon,battler,choices,scene|
  pbBattleHPItem(pokemon,battler,60,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:LEMONADE,proc { |item,pokemon,battler,choices,scene|
  pbBattleHPItem(pokemon,battler,80,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:MOOMOOMILK,proc { |item,pokemon,battler,choices,scene|
  pbBattleHPItem(pokemon,battler,100,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:ORANBERRY,proc { |item,pokemon,battler,choices,scene|
  pbBattleHPItem(pokemon,battler,10,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:SITRUSBERRY,proc { |item,pokemon,battler,choices,scene|
  pbBattleHPItem(pokemon,battler,pokemon.totalhp/4,scene)
})

ItemHandlers::BattleUseOnPokemon.add(:AWAKENING,proc { |item,pokemon,battler,choices,scene|
  pokemon.healStatus
  battler.pbCureStatus(false) if battler
  name = (battler) ? battler.pbThis : pokemon.name
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} woke up.",name))
})

ItemHandlers::BattleUseOnPokemon.copy(:AWAKENING,:CHESTOBERRY,:BLUEFLUTE)

ItemHandlers::BattleUseOnPokemon.add(:ANTIDOTE,proc { |item,pokemon,battler,choices,scene|
  pokemon.healStatus
  battler.pbCureStatus(false) if battler
  name = (battler) ? battler.pbThis : pokemon.name
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} was cured of its poisoning.",name))
})

ItemHandlers::BattleUseOnPokemon.copy(:ANTIDOTE,:PECHABERRY)

ItemHandlers::BattleUseOnPokemon.add(:BURNHEAL,proc { |item,pokemon,battler,choices,scene|
  pokemon.healStatus
  battler.pbCureStatus(false) if battler
  name = (battler) ? battler.pbThis : pokemon.name
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1}'s burn was healed.",name))
})

ItemHandlers::BattleUseOnPokemon.copy(:BURNHEAL,:RAWSTBERRY)

ItemHandlers::BattleUseOnPokemon.add(:PARALYZEHEAL,proc { |item,pokemon,battler,choices,scene|
  pokemon.healStatus
  battler.pbCureStatus(false) if battler
  name = (battler) ? battler.pbThis : pokemon.name
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} was cured of paralysis.",name))
})

ItemHandlers::BattleUseOnPokemon.copy(:PARALYZEHEAL,:PARLYZHEAL,:CHERIBERRY)

ItemHandlers::BattleUseOnPokemon.add(:ICEHEAL,proc { |item,pokemon,battler,choices,scene|
  pokemon.healStatus
  battler.pbCureStatus(false) if battler
  name = (battler) ? battler.pbThis : pokemon.name
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} was thawed out.",name))
})

ItemHandlers::BattleUseOnPokemon.copy(:ICEHEAL,:ASPEARBERRY)

ItemHandlers::BattleUseOnPokemon.add(:FULLHEAL,proc { |item,pokemon,battler,choices,scene|
  pokemon.healStatus
  battler.pbCureStatus(false) if battler
  battler.pbCureConfusion if battler
  name = (battler) ? battler.pbThis : pokemon.name
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} became healthy.",name))
})

ItemHandlers::BattleUseOnPokemon.copy(:FULLHEAL,
   :LAVACOOKIE,:OLDGATEAU,:CASTELIACONE,:LUMIOSEGALETTE,:SHALOURSABLE,
   :BIGMALASADA,:LUMBERRY)
ItemHandlers::BattleUseOnPokemon.copy(:FULLHEAL,:RAGECANDYBAR) if NEWEST_BATTLE_MECHANICS

ItemHandlers::BattleUseOnPokemon.add(:FULLRESTORE,proc { |item,pokemon,battler,choices,scene|
  pokemon.healStatus
  battler.pbCureStatus(false) if battler
  battler.pbCureConfusion if battler
  name = (battler) ? battler.pbThis : pokemon.name
  if pokemon.hp<pokemon.totalhp
    pbBattleHPItem(pokemon,battler,pokemon.totalhp,scene)
  else
    scene.pbRefresh
    scene.pbDisplay(_INTL("{1} became healthy.",name))
  end
})

ItemHandlers::BattleUseOnPokemon.add(:REVIVE,proc { |item,pokemon,battler,choices,scene|
  pokemon.hp = pokemon.totalhp/2
  pokemon.hp = 1 if pokemon.hp<=0
  pokemon.healStatus
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} recovered from fainting!",pokemon.name))
})

ItemHandlers::BattleUseOnPokemon.add(:MAXREVIVE,proc { |item,pokemon,battler,choices,scene|
  pokemon.healHP
  pokemon.healStatus
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} recovered from fainting!",pokemon.name))
})

ItemHandlers::BattleUseOnPokemon.add(:ENERGYPOWDER,proc { |item,pokemon,battler,choices,scene|
  if pbBattleHPItem(pokemon,battler,50,scene)
    pokemon.changeHappiness("powder")
  end
})

ItemHandlers::BattleUseOnPokemon.add(:ENERGYROOT,proc { |item,pokemon,battler,choices,scene|
  if pbBattleHPItem(pokemon,battler,200,scene)
    pokemon.changeHappiness("energyroot")
  end
})

ItemHandlers::BattleUseOnPokemon.add(:HEALPOWDER,proc { |item,pokemon,battler,choices,scene|
  pokemon.healStatus
  battler.pbCureStatus(false) if battler
  battler.pbCureConfusion if battler
  pokemon.changeHappiness("powder")
  name = (battler) ? battler.pbThis : pokemon.name
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} became healthy.",name))
})

ItemHandlers::BattleUseOnPokemon.add(:REVIVALHERB,proc { |item,pokemon,battler,choices,scene|
  pokemon.healHP
  pokemon.healStatus
  pokemon.changeHappiness("revivalherb")
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1} recovered from fainting!",pokemon.name))
})

ItemHandlers::BattleUseOnPokemon.add(:ETHER,proc { |item,pokemon,battler,choices,scene|
  idxMove = choices[3]
  pbBattleRestorePP(pokemon,battler,idxMove,10)
  scene.pbDisplay(_INTL("PP was restored."))
})

ItemHandlers::BattleUseOnPokemon.copy(:ETHER,:LEPPABERRY)

ItemHandlers::BattleUseOnPokemon.add(:MAXETHER,proc { |item,pokemon,battler,choices,scene|
  idxMove = choices[3]
  pbBattleRestorePP(pokemon,battler,idxMove,pokemon.moves[idxMove].totalpp)
  scene.pbDisplay(_INTL("PP was restored."))
})

ItemHandlers::BattleUseOnPokemon.add(:ELIXIR,proc { |item,pokemon,battler,choices,scene|
  for i in 0...pokemon.moves.length
    pbBattleRestorePP(pokemon,battler,i,10)
  end
  scene.pbDisplay(_INTL("PP was restored."))
})

ItemHandlers::BattleUseOnPokemon.add(:MAXELIXIR,proc { |item,pokemon,battler,choices,scene|
  for i in 0...pokemon.moves.length
    pbBattleRestorePP(pokemon,battler,i,pokemon.moves[i].totalpp)
  end
  scene.pbDisplay(_INTL("PP was restored."))
})

#===============================================================================
# BattleUseOnBattler handlers
# For items used on a Pokémon in battle
#===============================================================================

ItemHandlers::BattleUseOnBattler.add(:REDFLUTE,proc { |item,battler,scene|
  battler.pbCureAttract
  scene.pbDisplay(_INTL("{1} got over its infatuation.",battler.pbThis))
})

ItemHandlers::BattleUseOnBattler.add(:YELLOWFLUTE,proc { |item,battler,scene|
  battler.pbCureConfusion
  scene.pbDisplay(_INTL("{1} snapped out of its confusion.",battler.pbThis))
})

ItemHandlers::BattleUseOnBattler.copy(:YELLOWFLUTE,:PERSIMBERRY)

ItemHandlers::BattleUseOnBattler.add(:XATTACK,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::ATTACK,(NEWEST_BATTLE_MECHANICS) ? 2 : 1,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:XATTACK2,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::ATTACK,2,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:XATTACK3,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::ATTACK,3,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:XATTACK6,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::ATTACK,6,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:XDEFENSE,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::DEFENSE,(NEWEST_BATTLE_MECHANICS) ? 2 : 1,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.copy(:XDEFENSE,:XDEFEND)

ItemHandlers::BattleUseOnBattler.add(:XDEFENSE2,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::DEFENSE,2,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.copy(:XDEFENSE2,:XDEFEND2)

ItemHandlers::BattleUseOnBattler.add(:XDEFENSE3,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::DEFENSE,3,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.copy(:XDEFENSE3,:XDEFEND3)

ItemHandlers::BattleUseOnBattler.add(:XDEFENSE6,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::DEFENSE,6,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.copy(:XDEFENSE6,:XDEFEND6)

ItemHandlers::BattleUseOnBattler.add(:XSPATK,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::SPATK,(NEWEST_BATTLE_MECHANICS) ? 2 : 1,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.copy(:XSPATK,:XSPECIAL)

ItemHandlers::BattleUseOnBattler.add(:XSPATK2,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::SPATK,2,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.copy(:XSPATK2,:XSPECIAL2)

ItemHandlers::BattleUseOnBattler.add(:XSPATK3,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::SPATK,3,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.copy(:XSPATK3,:XSPECIAL3)

ItemHandlers::BattleUseOnBattler.add(:XSPATK6,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::SPATK,6,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.copy(:XSPATK6,:XSPECIAL6)

ItemHandlers::BattleUseOnBattler.add(:XSPDEF,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::SPDEF,(NEWEST_BATTLE_MECHANICS) ? 2 : 1,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:XSPDEF2,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::SPDEF,2,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:XSPDEF3,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::SPDEF,3,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:XSPDEF6,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::SPDEF,6,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:XSPEED,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::SPEED,(NEWEST_BATTLE_MECHANICS) ? 2 : 1,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:XSPEED2,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::SPEED,2,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:XSPEED3,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::SPEED,3,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:XSPEED6,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::SPEED,6,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:XACCURACY,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::ACCURACY,(NEWEST_BATTLE_MECHANICS) ? 2 : 1,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:XACCURACY2,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::ACCURACY,2,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:XACCURACY3,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::ACCURACY,3,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:XACCURACY6,proc { |item,battler,scene|
  battler.pbRaiseStatStage(PBStats::ACCURACY,6,battler)
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:DIREHIT,proc { |item,battler,scene|
  battler.effects[PBEffects::FocusEnergy] = 2
  scene.pbDisplay(_INTL("{1} is getting pumped!",battler.pbThis))
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:DIREHIT2,proc { |item,battler,scene|
  battler.effects[PBEffects::FocusEnergy] = 2
  scene.pbDisplay(_INTL("{1} is getting pumped!",battler.pbThis))
  battler.pokemon.changeHappiness("battleitem")
})

ItemHandlers::BattleUseOnBattler.add(:DIREHIT3,proc { |item,battler,scene|
  battler.effects[PBEffects::FocusEnergy] = 3
  scene.pbDisplay(_INTL("{1} is getting pumped!",battler.pbThis))
  battler.pokemon.changeHappiness("battleitem")
})
