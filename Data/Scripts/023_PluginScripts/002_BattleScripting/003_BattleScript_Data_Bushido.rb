def strong_katanas?
  return $PokemonSystem.enemyTechniques == 0
end

module DialogueModule
  # Basic trainer intros
  KenshiF1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    battler = battlers[1]
    pbMessage("\\rShow me your honorable battle style!")
    scene.disappearBar
    battler.pbRaiseStatStageEx(:DEFENSE, 1)
    scene.pbHideOpponent
  }

  KenshiF2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    battler = battlers[1]
    pbMessage("\\rPrepare to feel our anger! Hiyaah!")
    scene.disappearBar
    battler.pbRaiseStatStageEx(:SPATK, 1)
    scene.pbHideOpponent
  }

  KenshiF3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    battler = battlers[1]
    pbMessage("\\rYou don't stand a chance against me!")
    scene.disappearBar
    stat = (strong_katanas? ? 3 : 1)
    battler.pbRaiseStatStageEx([:ATTACK, :SPATK], stat, forced: true)
    scene.pbHideOpponent
  }

  KenshiM1 = Proc.new{ |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    battler = battlers[1]
    pbMessage("\\bCome on, let's see what you've got!")
    scene.disappearBar
    battler.pbRaiseStatStageEx(:SPEED, 1)
    scene.pbHideOpponent
  }

  BlackBelt1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    pbMessage("\\bHyah! Feel the power of my fists!")
    scene.disappearBar
    scene.pbHideOpponent
  }

  BlackBelt2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\bLet me show you why they call me the Machamp King!")
    pbMessage("\\bYou're going nowhere!")
    scene.disappearBar
    target.pbTrapWithMove(:MEANLOOK, user, forced: true)
    scene.appearBar
    pbMessage("\\bWe got you for 3 minutes! 3 minutes of playtime!")
    scene.disappearBar
    user.pbRaiseStatStageEx([:ATTACK, :DEFENSE, :SPEED], 2, :FOCUSENERGY)
    scene.pbHideOpponent
  }

  BlackBelt3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\bI'm putting everything into this next punch! Kiiiyaaaaah!")
    scene.disappearBar
    user.pbRaiseStatStageEx(:ATTACK, 4, :FOCUSENERGY)
    user.pbLowerStatStageEx([:DEFENSE, :SPDEF], 2)
    scene.pbHideOpponent
  }

  KenshiF3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\rBrace yourself, #{user.name}!")
    scene.disappearBar
    user.pbRaiseStatStageEx(:DEFENSE, 1)
    scene.pbHideOpponent
  }

  # Komorei Intros
  Komorei1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("Shizen Forest provides natural advantages for us in the Komorei Clan.")
    scene.disappearBar
    battle.pbStartTerrainEx(user, :Grassy)
    user.pbRaiseStatStageEx(:SPDEF, 1)
    scene.pbHideOpponent
  }

  Komorei2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("I'll show you the power of the Komorei Clan!")
    scene.disappearBar
    battle.pbStartTerrainEx(user, :Grassy)
    user.pbRaiseStatStageEx(:ATTACK, 1)
    scene.pbHideOpponent
  }

  Komorei3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("Alright Kenshi! I'm going to beat you, and turn my luck around!")
    scene.disappearBar
    battle.pbStartTerrainEx(user, :Grassy)
    user.pbRaiseStatStageEx(:SPATK, 1)
    scene.pbHideOpponent
  }

  Komorei4 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("You cannot hide from my love!")
    scene.disappearBar
    target.pbLowerStatStageEx(:ATTACK, 2, :CHARM, user)
    battle.pbStartTerrainEx(user, :Grassy)
    scene.pbHideOpponent
  }

  Komorei5 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\rHere we go! Feel the embrace of the forest!")
    scene.disappearBar
    battle.pbStartTerrainEx(user, :Grassy)
    user.pbRaiseStatStageEx(:SPEED, 2)
    scene.pbHideOpponent
  }

  Komorei6 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\bKatana of Nature, Komorei Style! Blazing Sunlight!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Sun)
    user.pbRaiseStatStageEx(:SPEED, 1)
    scene.pbHideOpponent
  }

  KomoreiDojo1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("You must be a skilled Kenshi to have made it this far!")
    pbMessage("Looks like the time has come for you to be fully tested by the best of the Komorei Clan!")
    scene.disappearBar
    battle.pbStartTerrainEx(user, :Grassy)
    user.pbRaiseStatStageEx(:SPEED, 2)
    scene.pbHideOpponent
  }

  KomoreiDojo2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("If you want to reach Harumi, you'll have to go through me!")
    pbMessage("Katana of Nature, Komorei Style! Blazing Sunlight!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Sun)
    user.pbRaiseStatStageEx(:SPATK, 2)
    scene.pbHideOpponent
  }

  HarumiIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("After everything, I believe I owe you a fair fight.")
    scene.disappearBar
    battle.pbStartTerrainEx(user, :Grassy)
    user.pbRaiseStatStageEx([:SPEED, :SPATK, :SPDEF], 1)
    scene.pbHideOpponent
  }

  HarumiSun = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("You truly are a talented Kenshi!")
    pbMessage("Unforunately, you'll be going out in a blaze of glory!")
    pbMessage("Katana of Nature, Komorei Style! Blazing Sunlight!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Sun)
    user.pbRaiseStatStageEx(:SPATK, 1)
    scene.pbHideOpponent
  }

  TsukuShrineIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("Let's m-make this a fight worth remembering!")
    scene.disappearBar
    user.pbRaiseStatStageEx(:SPDEF, 1)
    scene.pbHideOpponent
  }

  TsukuShrineFinal = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("I told myself I wouldn't lose... I won't back down now!")
    scene.disappearBar
    user.pbRaiseStatStageEx(:DEFENSE, 1)
    scene.pbHideOpponent
  }

  TsukuDuo1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user    = battlers[1]
    target  = battlers[0]
    target2 = battlers[2]
    pbMessage("I remember you having a shadow clone weakness!")
    pbMessage("Here, a reminder of the time we stole your katana!")
    pbMessage("Akui Clan Technique, Shadow Style! Clones of Darkness!")
    if strong_katanas?
      scene.disappearBar
      ret = user.pbRaiseStatStageEx(:EVASION, 1, :DOUBLETEAM)
      battlers[3].pbRaiseStatStageEx(:EVASION, 1, ret || :DOUBLETEAM, user)
      scene.appearBar
      pbMessage("And here, have some of these to add insult to injury!")
      pbMessage("Akui Clan Technique, Venom Kunai!")
      scene.disappearBar
      target.pbInflictStatusEx(:POISON, 1, :POISONKUNAI, user)
      target2.pbInflictStatusEx(:POISON, 1, :POISONKUNAI, user)
      scene.pbHideOpponent
      scene.appearBar
      pbMessage("\\xn[Tsuku]\\rNow that we're f-finally fighting together, I'll do my best to m-make you proud!")
      pbMessage("\\xn[Tsuku]\\rWe have to give it our all!")
      pbMessage("\\xn[Tsuku]\\rKatana of Life, Konchu Style! Beetle Barrier!")
      scene.disappearBar
      ret = target2.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 3, :WIDEGUARD)
      target.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 3, ret || :WIDEGUARD, target2)
      scene.appearBar
    end
    pbMessage("\\xn[Tsuku]\\rLet's show these Akui Grunts the power of our bonds!")
    scene.disappearBar
  }

  TsukuDuo2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user    = battlers[1]
    target  = battlers[0]
    target2 = battlers[2]
    pbMessage("You pesky insects! It's time we crushed you!")
    if strong_katanas?
      pbMessage("Akui Clan Technique, Fire Kunai!")
      scene.disappearBar
      target.pbInflictStatusEx(:BURN, 0, :BURNKUNAI, user)
      target2.pbInflictStatusEx(:BURN, 0, :BURNKUNAI, user)
      scene.appearBar
      pbMessage("Akui Clan Technique, Shadow Style! Muscle Control!")
      scene.disappearBar
      ret = user.pbRaiseStatStageEx([:ATTACK, :DEFENSE], 3, :DRAGONDANCE)
      battlers[3].pbRaiseStatStageEx([:ATTACK, :DEFENSE], 3, ret || :DRAGONDANCE, user)
      scene.appearBar
      pbMessage("We'll squash you like the bugs you are!")
      scene.pbHideOpponent
      pbMessage("\\xn[Tsuku]\\rYou need to learn some r-respect for bugs!")
      pbMessage("\\xn[Tsuku]\\rThey are some of the best Pokémon in the world! I'll never let you squash them!")
      pbMessage("\\xn[Tsuku]\\rKatana of Life, Konchu Style! Dragonfly Dance!")
      scene.disappearBar
      ret = target2.pbRaiseStatStageEx([:SPATK, :SPDEF, :SPEED], 3, :QUIVERDANCE)
      target.pbRaiseStatStageEx([:SPATK, :SPDEF, :SPEED], 3, ret || :QUIVERDANCE, target2)
      scene.appearBar
    end
    pbMessage("\\xn[Tsuku]\\rCome on, \\PN! We'll teach them to respect b-bugs!")
    scene.disappearBar
  }

  TsukuPG1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\xn[Tsuku]\\rIt feels like just the other day we both started our journies as Kenshi!")
    pbMessage("\\xn[Tsuku]\\rLook at far we've come now!")
    pbMessage("\\xn[Tsuku]\\rWe both should keep getting stronger, to protect Aisho together!")
    if strong_katanas?
      pbMessage("\\xn[Tsuku]\\rKatana of Life, Konchu Style! Beetle Barrier!")
      scene.disappearBar
      user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 3, :WIDEGUARD)
      scene.appearBar
    end
    pbMessage("\\xn[Tsuku]\\rLet's see if you have what it takes to overcome my new team, \\PN!")
    scene.disappearBar
    scene.pbHideOpponent
  }

  TsukuPG2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\xn[Tsuku]\\rDang, I'm already down to my last Pokémon...")
    pbMessage("\\xn[Tsuku]\\rNow's the time for me to give it me all!")
    pbMessage("\\xn[Tsuku]\\rHere we c-come, \\PN!")
    if strong_katanas?
      pbMessage("\\xn[Tsuku]\\rKatana of Life, Konchu Style! Dragonfly Dance!")
      scene.disappearBar
      user.pbRaiseStatStageEx([:SPATK, :SPDEF, :SPEED], 2, :QUIVERDANCE)
      scene.appearBar
    end
    pbMessage("\\xn[Tsuku]\\rI'll never give up! Just like y-you taught me!")
    pbMessage("\\xn[Tsuku]\\rI'm stronger now, t-thanks to our bond!")
    scene.disappearBar
    scene.pbHideOpponent
  }

  # Iwa Clan intros
  # Stealth rocks for another one?
  Iwa1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\bThe Iwa Clan mean business!")
    pbMessage("\\bWe may be small, but our spirit is unbreakable!")
    pbMessage("\\bI draw my power from the earth!")
    pbMessage("\\bKatana of Earth, Iwa Style! Shifting Sands!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Sandstorm)
    user.pbRaiseStatStageEx(:DEFENSE, 2)
    scene.pbHideOpponent
  }

  Iwa2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    if strong_katanas?
      pbMessage("\\rIwa battle cry! Mountainous Roar!")
      scene.disappearBar
      target.pbLowerStatStageEx([:SPEED, :DEFENSE, :SPDEF], 2, :NOBLEROAR, user)
      scene.appearBar
      pbMessage("\\rAnd now for my secret technique, Rocky Domain!")
      scene.disappearBar
      target.pbSetHazards(:STEALTHROCK, user)
    else
      pbMessage("\\rThe Iwa Clan is rock solid! Hiyaah!")
      battle.scene.disappearBar
    end
    scene.pbHideOpponent
  }

  Iwa3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\rI'm one of the best trainers out there!")
    pbMessage("\\rKatana of Earth, Iwa Style! Shifting Sands!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Sandstorm)
    target.pbSetHazards(:STEALTHROCK, user)
    user.pbRaiseStatStageEx(:DEFENSE, 2)
    scene.pbHideOpponent
  }

  # Raikami Clan intros
  # 1 is Rohan
  Raikami1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Rohan]\\bThe Raikami Clan act on the will of the gods!")
    pbMessage("\\xn[Rohan]\\bBy summoning lightning, we are channeling the energy of the heavens themselves!")
    if strong_katanas?
      pbMessage("\\xn[Rohan]\\bKatana of Lightning, Raikami Style! Thunderclap!")
      scene.disappearBar
      target.pbInflictStatusEx(:PARALYSIS, 0, :THUNDERBOLT, user)
      scene.appearBar
    end
    pbMessage("\\xn[Rohan]\\bKatana of Lightning, Raikami Style! Heaven's Domain!")
    scene.disappearBar
    battle.pbStartTerrainEx(user, :Electric)
    user.pbRaiseStatStageEx(:SPATK, 2)
    scene.pbHideOpponent
  }

  Raikami2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("The Raikami Clan act on the will of the gods!")
    if strong_katanas?
      pbMessage("By summoning lightning, we are channeling the energy of the heavens themselves!")
      pbMessage("Katana of Lightning, Raikami Style! Thunderclap!")
    end
    scene.disappearBar
    target.pbInflictStatusEx(:PARALYSIS, 0, :THUNDERBOLT, user)
    user.pbRaiseStatStageEx(:SPATK, 1)
    scene.pbHideOpponent
  }

  Raikami3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\rThe Raikami Clan is the best clan of all!")
    pbMessage("\\rWe can summon lightning, like this!")
    if strong_katanas?
      scene.disappearBar
      target.pbInflictStatusEx(:PARALYSIS, 0, :THUNDERBOLT, user)
      scene.appearBar
    end
    pbMessage("\\rKatana of Lightning, Raikami Style! Heaven's Domain!")
    scene.disappearBar
    battle.pbStartTerrainEx(user, :Electric)
    user.pbRaiseStatStageEx(:SPEED, 2)
    scene.pbHideOpponent
  }

  Raikami4 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[0]
    if strong_katanas?
      pbMessage("\\bKatana of Lightning, Raikami Style! Galvanizing Jolt!")
    else
      pbMessage("\\bPrepare to be shocked by my strength!")
    end
    scene.disappearBar
    user.pbRaiseStatStageEx([:SPEED, :ATTACK, :SPATK], [4, 2, 2], :THUNDER)
    scene.pbHideOpponent
  }

  # Yuki Clan intros
  Yuki1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Even though we're a minor clan, you should take us Yuki members seriously!")
    pbMessage("We're well on our way to forming our own dojo soon!")
    if strong_katanas?
      pbMessage("Here, have a taste of what we can do!")
      pbMessage("Katana of Ice, Yuki Style! Freezing Breath!")
    end
    scene.disappearBar
    target.pbInflictStatusEx(:FROZEN, 0, :FROSTBREATH, user)
    user.pbRaiseStatStageEx(:SPATK, 1)
    scene.pbHideOpponent
  }

  Yuki2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("The Yuki Clan controls the frozen domain!")
    pbMessage("Katana of Ice, Yuki Style! Freezing Breath!") if strong_katanas?
    scene.disappearBar
    target.pbInflictStatusEx(:FROZEN, 0, :FROSTBREATH, user)
    user.pbRaiseStatStageEx(:SPEED, 1)
    scene.pbHideOpponent
  }

  Yuki3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("I hope you'll prove to be a worthy opponent!")
    pbMessage("Not many trainers can overcome the ice-cold Yuki Clan in battle!")
    pbMessage("Katana of Ice, Yuki Style! Freezing Breath!") if strong_katanas?
    scene.disappearBar
    target.pbInflictStatusEx(:FROZEN, 0, :FROSTBREATH, user)
    user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 1)
    scene.pbHideOpponent
  }

  Yuki4 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Let us have a good duel!")
    pbMessage("Katana of Ice, Yuki Style! Freezing Breath!") if strong_katanas?
    scene.disappearBar
    target.pbInflictStatusEx(:FROZEN, 0, :FROSTBREATH, user)
    user.pbRaiseStatStageEx([:ATTACK, :DEFENSE, :SPEED], 1)
    scene.pbHideOpponent
  }

  Yuki5 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    if strong_katanas?
      pbMessage("\\rKatana of Ice, Yuki Style! Frigid Hail!")
    else
      pbMessage("\\rWatch out for the Yuki Clan! We're stronger than you think!")
    end
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Hail)
    user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 2)
    scene.pbHideOpponent
  }

  # Nensho intros
  Nensho1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("The way of the Nensho Clan is blazing through our opponents!")
    pbMessage("Katana of Fire, Nensho Style! Fire Vortex!") if strong_katanas?
    scene.disappearBar
    target.pbTrapWithMove(:FIRESPIN, user)
    user.pbRaiseStatStageEx(:ATTACK, 1)
    scene.pbHideOpponent
  }

  Nensho2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("The Nensho Clan is unstoppable! The sunlight only makes us stronger!")
    pbMessage("Katana of Fire, Nensho Style! Sunlight Beams!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Sun)
    user.pbRaiseStatStageEx(:SPEED, 1)
    scene.pbHideOpponent
  }

  Nensho3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Nensho Clan! Hiyaaaah!")
    pbMessage("Katana of Fire, Nensho Style! Fire Vortex!") if strong_katanas?
    scene.disappearBar
    target.pbTrapWithMove(:FIRESPIN, user)
    user.pbRaiseStatStageEx(:SPATK, 1)
    scene.pbHideOpponent
  }

  Nensho4 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("The Nensho Clan is the strongest clan there is!")
    pbMessage("Allow me to show you why we're the best clan!")
    pbMessage("Katana of Fire, Nensho Style! Flame Breath!") if strong_katanas?
    scene.disappearBar
    target.pbInflictStatusEx(:BURN, 0, :FLAMETHROWER, user)
    user.pbRaiseStatStageEx(:ATTACK, 1)
    scene.pbHideOpponent
  }

  Nensho5 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("The souls of Nensho Clan members burn as bright as the sun!")
    pbMessage("Katana of Fire, Nensho Style! Sunlight Beams!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Sun)
    user.pbRaiseStatStageEx([:ATTACK, :SPATK], 1)
    scene.pbHideOpponent
  }

  Nensho6 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("You're on the final stretch! Don't burn out on me now!")
    pbMessage("Katana of Fire, Nensho Style! Breath of Flames!") if strong_katanas?
    scene.disappearBar
    target.pbInflictStatusEx(:BURN, 0, :FLAMETHROWER, user)
    user.pbRaiseStatStageEx(:SPEED, 1)
    scene.pbHideOpponent
  }

  Nensho7 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\bNo ocean can extinquish the fire deep within my heart!")
    pbMessage("\\bKatana of Fire, Nensho Style! Breath of Flames!") if strong_katanas?
    scene.disappearBar
    target.pbInflictStatusEx(:BURN, 0, :FLAMETHROWER, user)
    user.pbRaiseStatStageEx([:ATTACK, :SPEED], 2)
    scene.pbHideOpponent
  }

  Nensho8 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    if strong_katanas?
      pbMessage("\\rKatana of Fire, Nensho Style! Fire Vortex!")
    else
      pbMessage("\\rYou can't beat me! My soul blazes brightly!")
    end
    scene.disappearBar
    target.pbTrapWithMove(:FIRESPIN, user)
    user.pbRaiseStatStageEx(:SPATK, 1)
    scene.pbHideOpponent
  }

  Nori1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Nori]\\bHahaha! We finally face each other in battle!")
    pbMessage("\\xn[Nori]\\bI've been looking forward to this, \\PN!")
    pbMessage("\\xn[Nori]\\bJust so you know, I'll be giving this battle my all.")
    pbMessage("\\xn[Nori]\\bI expect you to do the same! Now, it's time to show you the true power of the Nensho Clan!")
    if strong_katanas?
      pbMessage("\\xn[Nori]\\bKatana of Fire, Nensho Style! Breath of Flames!")
      scene.disappearBar
      target.pbInflictStatusEx(:BURN, 0, :FLAMETHROWER, user)
      user.pbRaiseStatStageEx([:SPATK, :SPEED], 1)
      scene.appearBar
    end
    pbMessage("\\xn[Nori]\\bKatana of Fire, Nensho Style! Sunlight Beams!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Sun)
    scene.appearBar
    pbMessage("\\xn[Nori]\\bCome at me with all you've got, \\PN! Hiyaaah!")
    scene.disappearBar
    scene.pbHideOpponent
  }

  NoriLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Nori]\\bHahaha! This is so much fun!")
    pbMessage("\\xn[Nori]\\bYou are an excellent Kenshi, \\PN!")
    pbMessage("\\xn[Nori]\\bYou've pushed me to my limits...")
    pbMessage("\\xn[Nori]\\bBut the battle isn't over yet! Now it's time for me to get serious!")
    if strong_katanas?
      pbMessage("\\xn[Nori]\\bSecret Technique! Mountainous Roar!")
      scene.disappearBar
      target.pbLowerStatStageEx([:SPEED, :DEFENSE, :SPDEF], 2, :NOBLEROAR, user)
      scene.appearBar
      pbMessage("\\xn[Nori]\\bKatana of Fire, Nensho Style! Flame Breath!")
      scene.disappearBar
      target.pbInflictStatusEx(:BURN, 0, :FLAMETHROWER, user)
      scene.appearBar
    end
    pbMessage("\\xn[Nori]\\bLet's finish this duel in a blaze of glory, \\PN! Yaaah!")
    scene.disappearBar
    scene.pbHideOpponent
  }

  # Shimizu Intros
  Shimizu1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("You cannot overcome the calmness of the Shimizu Clan.")
    pbMessage("Katana of Water, Shimizu Style! Torrential Downpour!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Rain)
    user.pbRaiseStatStageEx(:SPDEF, 1)
    scene.pbHideOpponent
  }

  Shimizu2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("You have to learn to move with the motion of the ocean!")
    pbMessage("Katana of Water, Shimizu Style! Torrential Downpour!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Rain)
    user.pbRaiseStatStageEx(:SPEED, 2)
    scene.pbHideOpponent
  }

  Shimizu3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("You better watch out!")
    pbMessage("I'm making waves over here!")
    pbMessage("Katana of Water, Shimizu Style! Torrential Downpour!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Rain)
    user.pbRaiseStatStageEx(:ATTACK, 2)
    scene.pbHideOpponent
  }

  Shimizu4 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("Watch this!")
    pbMessage("Not only can the Shimizu Clan make it rain...")
    pbMessage("We can also manipulate the temperature of the rainwater!")
    pbMessage("Katana of Water, Shimizu Style! Frigid Hail!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Hail)
    user.pbRaiseStatStageEx(:SPATK, 2)
    scene.pbHideOpponent
  }

  Shimizu5 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Chris and Eddie have got nothing on my skills!")
    if strong_katanas?
      pbMessage("Katana of Water, Shimizu Style! Raging Whirlpool!")
      scene.disappearBar
      target.pbTrapWithMove(:WHIRLPOOL, user)
      user.pbRaiseStatStageEx([:ATTACK, :SPEED], 1)
    end
    scene.pbHideOpponent
  }

  Shimizu6 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("Before you can get to Chikyu Village, you'll have to go through me!")
    pbMessage("Shimizu Clan can also turn the terrain misty, to protect our Pokémon!")
    pbMessage("Katana of Water, Shimizu Style! Misty Terrain!")
    scene.disappearBar
    battle.pbStartTerrainEx(user, :Misty)
    user.pbRaiseStatStageEx([:SPEED, :DEFENSE, :SPDEF], 1)
    scene.pbHideOpponent
  }

  Shimizu7 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Where do you think you're going?")
    pbMessage("Katana of Water, Shimizu Style! Raging Whirlpool!") if strong_katanas?
    scene.disappearBar
    target.pbTrapWithMove(:WHIRLPOOL, user)
    user.pbRaiseStatStageEx(:ATTACK, 1)
    scene.pbHideOpponent
  }

  Shimizu8 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("The Shimizu Clan draw their strength from the ocean!")
    pbMessage("It is the source of all life... It heals us with its love!")
    pbMessage("Katana of Water, Shimizu Style! Healing Ring!") if strong_katanas?
    scene.disappearBar
    battle.pbAnimation(:AQUARING, user, user)
    user.effects[PBEffects::AquaRing] = true
    battle.pbDisplay(_INTL("{1} was surrounded with a veil of water!", user.pbThis))
    user.pbRaiseStatStageEx(:SPATK, 2)
    scene.pbHideOpponent
  }

  Shimizu9 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("It's time for me to test your skills!")
    pbMessage("Katana of Water, Shimizu Style! Misty Terrain!")
    scene.disappearBar
    battle.pbAnimation(:MISTYTERRAIN, user, user)
    battle.pbStartTerrainEx(user, :Misty)
    user.pbRaiseStatStageEx([:SPEED, :DEFENSE, :SPDEF], 2)
    scene.pbHideOpponent
  }

  Shimizu10 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("Show me your full potential, and I'll show you mine!")
    pbMessage("Katana of Water, Shimizu Style! Misty Terrain!")
    scene.disappearBar
    battle.pbStartTerrainEx(user, :Misty)
    if strong_katanas?
      scene.appearBar
      pbMessage("Katana of Water, Shimizu Style! Healing Ring!")
      scene.disappearBar
      battle.pbAnimation(:AQUARING, user, user)
      user.effects[PBEffects::AquaRing] = true
      battle.pbDisplay(_INTL("{1} was surrounded with a veil of water!", user.pbThis))
      user.pbRaiseStatStageEx([:SPATK, :SPEED], 2)
      scene.appearBar
      pbMessage("Come at me!")
      scene.disappearBar
    end

    scene.pbHideOpponent
  }

  Shimizu11 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Prove to me that you are worthy of facing Mai, the leader of the Shimizu Clan!")
    pbMessage("Katana of Water, Shimizu Style! Torrential Downpour!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Rain)
    if strong_katanas?
      scene.appearBar
      pbMessage("Katana of Water, Shimizu Style! Raging Whirlpool!")
      scene.disappearBar
      target.pbTrapWithMove(:WHIRLPOOL, user)
      user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 2)
      scene.appearBar
      pbMessage("Now, the real test begins!")
      scene.disappearBar
    end
    scene.pbHideOpponent
  }

  Shimizu12 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("Katana of Water, Shimizu Style! Torrential Downpour!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Rain)
    user.pbRaiseStatStageEx(:SPATK, 2)
    scene.pbHideOpponent
  }

  Shimizu13 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\rKatana of Water, Shimizu Style! Misty Terrain!")
    scene.disappearBar
    battle.pbStartTerrainEx(user, :Misty)
    if scene.disappearBar
      battle.pbAnimation(:AQUARING, user, user)
      user.effects[PBEffects::AquaRing] = true
      battle.pbDisplay(_INTL("{1} was surrounded with a veil of water!", user.pbThis))
    end
    scene.pbHideOpponent
  }

  Mai1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\xn[Mai]\\rI'm glad to have you in my dojo, \\PN.")
    pbMessage("\\xn[Mai]\\rI heard about how you defeated Harumi and Nori.")
    pbMessage("\\xn[Mai]\\rThough they are strong clan leaders in their own right...")
    pbMessage("\\xn[Mai]\\rI will show you why I am considered the strongest of the three.")
    pbMessage("\\xn[Mai]\\rKatana of Water, Shimizu Style! Torrential Downpour!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Rain)
    if strong_katanas?
      scene.appearBar
      pbMessage("\\xn[Mai]\\rKatana of Water, Shimizu Style! Healing Ring!")
      scene.disappearBar
      battle.pbAnimation(:AQUARING, user, user)
      user.effects[PBEffects::AquaRing] = true
      battle.pbDisplay(_INTL("{1} was surrounded with a veil of water!", user.pbThis))
      scene.appearBar
      pbMessage("\\xn[Mai]\\rAnd now for my signature move!")
      pbMessage("\\xn[Mai]\\rKatana of Water, Shimizu Style! Signature Technique! Water Meditation!")
      scene.disappearBar
      user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 1, :COSMICPOWER)
    end
    scene.appearBar
    pbMessage("\\xn[Mai]\\rIf you think you can defeat me, go ahead and try!")
    scene.disappearBar
    scene.pbHideOpponent
  }

  Mai2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\xn[Mai]\\rHmm... No wonder you were able to handle the Akui Clan!")
    pbMessage("\\xn[Mai]\\rYou bring great honor to the Masayoshi name.")
    pbMessage("\\xn[Mai]\\rNow, it looks like I need to get serious, before you sweep me away!")
    pbMessage("\\xn[Mai]\\rKatana of Water, Shimizu Style! Torrential Downpour!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Rain)
    scene.appearBar
    pbMessage("\\xn[Mai]\\rKatana of Water, Shimizu Style! Healing Ring!")
    scene.disappearBar
    battle.pbAnimation(:AQUARING, user, user)
    user.effects[PBEffects::AquaRing] = true
    battle.pbDisplay(_INTL("{1} was surrounded with a veil of water!", user.pbThis))
    scene.appearBar
    if strong_katanas?
      pbMessage("\\xn[Mai]\\rKatana of Water, Shimizu Style! Misty Terrain!")
      scene.disappearBar
      battle.pbStartTerrainEx(user, :Misty)
      scene.appearBar
      pbMessage("\\xn[Mai]\\rKatana of Water, Shimizu Style! Signature Technique! Water Meditation!")
      scene.disappearBar
      user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 2, :COSMICPOWER)
      scene.appearBar
    end
    pbMessage("\\xn[Mai]\\rLet's see if you can keep up with my waterfall of Shimizu techniques!")
    scene.disappearBar
    scene.pbHideOpponent
  }

  # Rival intros
  RivalFirstIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\xn[\\v[26]]\\pogPrepare to face the full force of my Pokémon!")
    pbMessage("\\xn[\\v[26]]\\pogHiyaaah! Signature Technique! Hashimoto Might!") if strong_katanas?
    scene.disappearBar
    user.pbRaiseStatStageEx(:ATTACK, 1, :SWORDSDANCE)
    scene.pbHideOpponent
  }

  RivalBurn = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[\\v[26]]\\pogWe meet in battle again, \\PN!")
    pbMessage("\\xn[\\v[26]]\\pogI've grown a lot since our last battle, so don't underestimate me!")
    pbMessage("\\xn[\\v[26]]\\pogNow, prepare to be burned to ashes!")
    if strong_katanas?
      scene.disappearBar
      target.pbInflictStatusEx(:BURN, 1, :EMBER, user)
      scene.appearBar
      pbMessage("\\xn[\\v[26]]\\pogHiyaaah! Signature Technique! Hashimoto Might!")
    end
    scene.disappearBar
    user.pbRaiseStatStageEx(:ATTACK, 1, :SWORDSDANCE)
    scene.pbHideOpponent
  }

  RivalLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\xn[\\v[26]]\\pogLooks like it's time to get serious!")
    pbMessage("\\xn[\\v[26]]\\pogGo #{user.name}, unleash your burning passion!")
    scene.disappearBar
    user.pbRaiseStatStageEx(:SPEED, 1)
    scene.pbHideOpponent
  }

  RivalDuel2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[\\v[26]]\\pogI've grown a lot since our last battle, so don't underestimate me!")
    pbMessage("\\xn[\\v[26]]\\pogNow, take a look at the new Katana Technique I learned!") if strong_katanas?
    pbMessage("\\xn[\\v[26]]\\pogKatana of Fire, Nensho Style! Fire Vortex!") if strong_katanas?
    scene.disappearBar
    target.pbTrapWithMove(:FIRESPIN, user, true)
    user.pbRaiseStatStageEx([:ATTACK, :SPEED], 1)
    scene.pbHideOpponent
  }

  RivalDuel2Last = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[\\v[26]]\\pogLooks like it's time to get serious!")
    pbMessage("\\xn[\\v[26]]\\pogGo #{user.name}, unleash your burning passion!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Sun)
    user.pbRaiseStatStageEx([:ATTACK, :SPEED], 2)
    scene.pbHideOpponent
  }

  RivalPG1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[\\v[26]]\\pogI've been waiting for this day, \\PN!")
    pbMessage("\\xn[\\v[26]]\\pogTo face you again... a battle against the Hero of Aisho!")
    pbMessage("\\xn[\\v[26]]\\pogI'm going to give it my all, to open the heart of my Darmanitan!")
    pbMessage("\\xn[\\v[26]]\\pogLet's go! Hiyaaaah!")
    if strong_katanas?
      pbMessage("\\xn[\\v[26]]\\pogKatana of Fire, Nensho Style! Breath of Flames!")
      scene.disappearBar
      target.pbInflictStatusEx(:BURN, 0, :FLAMETHROWER, user)
      scene.appearBar
      pbMessage("\\xn[\\v[26]]\\pogKatana of Fire, Nensho Style! Sunlight Beams!")
      scene.disappearBar
      battle.pbStartWeatherEx(user, :Sun)
      scene.appearBar
      pbMessage("\\xn[\\v[26]]\\pogCome at me with all you've got, \\PN! Hiyaaah!")
    end
    scene.disappearBar
    user.pbRaiseStatStageEx([:SPATK, :SPEED], 2)
    scene.pbHideOpponent
  }

  RivalPG2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\xn[\\v[26]]\\pogWe're so close \\PN! Keep it up!")
    pbMessage("\\xn[\\v[26]]\\pogGo #{user.name}, give it all you got in this last battle!")
    pbMessage("\\xn[\\v[26]]\\pogHiyaaah! Hashimoto Might!") if strong_katanas?
    scene.disappearBar
    user.pbRaiseStatStageEx([:ATTACK, :DEFENSE], 2, :SWORDSDANCE)
    scene.pbHideOpponent
  }

  Ryo1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\xn[Ryo]\\bI've been looking forward to testing your skills in battle, \\PN!")
    if strong_katanas?
      pbMessage("\\xn[Ryo]\\bYou may be the new master of the Katana of Light, but I can still do this!")
      pbMessage("\\xn[Ryo]\\bKatana of Illumination, Masayoshi Style! Brilliant Barrier!")
      scene.disappearBar
      battle.pbAnimation(:LIGHTSCREEN, user, user)
      user.pbOwnSide.effects[PBEffects::Reflect] = 4
      user.pbOwnSide.effects[PBEffects::LightScreen] = 4
      battle.pbDisplay(_INTL("A wall of light protects {1}!", user.pbTeam(true)))
      user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 3)
      scene.appearBar
    end
    pbMessage("\\xn[Ryo]\\bLet's see the true strength of the Hero of Aisho!")
    scene.disappearBar
    scene.pbHideOpponent
  }

  Ryo2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Ryo]\\bYou really are talented, \\PN!")
    pbMessage("\\xn[Ryo]\\bYou make me so proud as a father.")
    pbMessage("\\xn[Ryo]\\bI hope you know that'll always love you.")
    if strong_katanas?
      pbMessage("\\xn[Ryo]\\bNow, witness my ultimate technique!")
      pbMessage("\\xn[Ryo]\\bKatana of Illumination, Masayoshi Style! Blinding Radiance!")
      scene.disappearBar
      target.pbLowerStatStageEx(:ACCURACY, 2, :FLASH, user)
      scene.appearBar
      pbMessage("\\xn[Ryo]\\bKatana of Illumination, Masayoshi Style! Brilliant Barrier!")
      scene.disappearBar
      battle.pbAnimation(:LIGHTSCREEN, user, user)
      user.pbOwnSide.effects[PBEffects::Reflect] = 4
      user.pbOwnSide.effects[PBEffects::LightScreen] = 4
      battle.pbDisplay(_INTL("A wall of light protects {1}!", user.pbTeam(true)))
      user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 3)
      scene.appearBar
    end
    pbMessage("\\xn[Ryo]\\bLet's end this \\PN! Show me that you have what it takes to become the Royal Samurai!")
    scene.disappearBar
    scene.pbHideOpponent
  }

  TsukuIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    pbMessage("\\xn[Tsuku]\\rAlright! Time for you to learn how strong b-bug Pokémon can really be!")
    scene.disappearBar
    scene.pbHideOpponent
  }

  TsukuLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\xn[Tsuku]\\rW-wah! This isn't looking good!")
    pbMessage("\\xn[Tsuku]\\rIt's time for defensive measures...")
    scene.disappearBar
    user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 2)
    scene.pbHideOpponent
  }

  KayokoIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    pbMessage("\\xn[Kayoko]\\rPrepare yourself. I'll be trying my best.")
    scene.disappearBar
    scene.pbHideOpponent
  }

  KayokoLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\xn[Kayoko]\\rI can't let my family down...")
    pbMessage("\\xn[Kayoko]\\rTime to show you my true inner strength!")
    scene.disappearBar
    user.pbRaiseStatStageEx([:SPATK, :SPDEF], 1)
    scene.pbHideOpponent
  }

  KayokoB2Intro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\xn[Kayoko]\\rPrepare yourself, \\PN. I'll be going all out.")
    if strong_katanas?
      pbMessage("\\xn[Kayoko]\\rSignature Technique! Focused Mind!")
      scene.disappearBar
      user.pbRaiseStatStageEx([:SPATK, :SPDEF], 2, :CALMMIND)
      scene.appearBar
    end
    pbMessage("\\xn[Kayoko]\\rPlease, show me your true strength.")
    scene.disappearBar
    scene.pbHideOpponent
  }

  KayokoB2Last = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\xn[Kayoko]\\rIt's shocking to me how powerful you've become, \\PN.")
    pbMessage("\\xn[Kayoko]\\rHowever, as you can see, I've done some growing as well!")
    pbMessage("\\xn[Kayoko]\\rSignature Technique! Shocking Terrain!")
    scene.disappearBar
    battle.pbStartTerrainEx(user, :Electric)
    if strong_katanas?
      scene.appearBar
      pbMessage("\\xn[Kayoko]\\rSignature Technique! Focused Mind!")
      scene.disappearBar
      user.pbRaiseStatStageEx([:SPATK, :SPDEF], 2, :CALMMIND)
    end
    scene.appearBar
    pbMessage("\\xn[Kayoko]\\rLet's see if you truly have what it takes to defeat me.")
    scene.disappearBar
    scene.pbHideOpponent
  }

  KayokoB3Intro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("\\xn[Kayoko]\\rEven if you've managed to defeat the Akui Clan, I still won't go easy!")
    pbMessage("\\xn[Kayoko]\\rSignature Technique! Vaporized Terrain!")
    scene.disappearBar
    battle.pbAnimation(:MISTYTERRAIN, user, user)
    if strong_katanas?
      scene.appearBar
      pbMessage("\\xn[Kayoko]\\rSignature Technique! Focused Mind!")
      scene.disappearBar
    end
    user.pbRaiseStatStageEx([:SPATK, :SPDEF], 2, :CALMMIND)
    scene.pbHideOpponent

  }

  KayokoB3Last = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    if user.isSpecies?(:ZOROARK)
      pbMessage("\\xn[Kayoko]\\rMy Hisuian partner will lead me to victory!")
    else
      pbMessage("\\xn[Kayoko]\\rMy partner will lead me to victory!")
    end
    pbMessage("\\xn[Kayoko]\\r#{user.name}, Signature Technique! Malicious Boost!") if strong_katanas?
    scene.disappearBar
    user.pbRaiseStatStageEx([:ATTACK, :DEFENSE, :SPATK, :SPDEF], 1, :WORKUP)
    scene.pbHideOpponent
  }

  # Akui intros, make them cheat a lot!
  ShadowIntroToxic = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("The Akui Clan never falters! Take this!")
    scene.disappearBar
    target.pbSetHazards(:TOXICSPIKES, user)
    scene.pbHideOpponent
  }

  ShadowIntroToxic2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Stay out of our Akui Library!")
    pbMessage("The secrets of our clan are not meant for outsiders!")
    if strong_katanas?
      scene.disappearBar
      target.pbSetHazards(:TOXICSPIKES, user)
      scene.appearBar
      pbMessage("Akui Clan Technique, Shadow Style! Clones of Darkness!")
    end
    scene.disappearBar
    user.pbRaiseStatStageEx(:EVASION, 1, :DOUBLETEAM)
    scene.pbHideOpponent
  }

  ShadowIntroToxic3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("The Katana of Light belongs to the Akui Clan now!")
    pbMessage("Get lost, and never come back, you foolish Kenshi!")
    if strong_katanas?
      scene.disappearBar
      target.pbSetHazards(:TOXICSPIKES, user)
      scene.appearBar
      pbMessage("Akui Clan Technique, Shadow Style! Clones of Darkness! Ultimate Evasion!")
    end
    scene.disappearBar
    user.pbRaiseStatStageEx(:EVASION, 2, :DOUBLETEAM)
    scene.pbHideOpponent
  }

  ShadowIntroToxic4 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("You must be stopped... And I'll be the one to stop you!")
    if strong_katanas?
      scene.disappearBar
      target.pbSetHazards(:TOXICSPIKES, user)
      scene.appearBar
      pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility!")
    end
    scene.disappearBar
    user.pbRaiseStatStageEx(:SPEED, 2, :AGILITY)
    scene.pbHideOpponent
  }

  ShadowIntroSpikes = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    if strong_katanas?
      pbMessage("Let's make this battle interesting, shall we?")
      scene.disappearBar
      target.pbSetHazards(:SPIKES, user)
    else
      pbMessage("I'll teach you not to mess with the Akui Clan!")
      battle.scene.disappearBar
    end
    scene.pbHideOpponent
  }

  ShadowIntroSpikes2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("I'm guarding this key with my life! Stay away, you disgusting kenshi!")
    if strong_katanas?
      scene.disappearBar
      target.pbSetHazards(:SPIKES, user)
      scene.appearBar
      pbMessage("Akui Clan Technique, Icicle Kunai!")
    end
    scene.disappearBar
    target.pbInflictStatusEx(:FROZEN, 0, :ICICLESPEAR, user)
    scene.pbHideOpponent
  }

  ShadowIntroSpikes3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Stay out of my basement, you villain!")
    if strong_katanas?
      scene.disappearBar
      target.pbSetHazards(:SPIKES, user)
      scene.appearBar
      pbMessage("Akui Clan Technique, Shock Kunai!")
    end
    scene.disappearBar
    target.pbInflictStatusEx(:PARALYSIS, 0, :SHOCKKUNAI, user)
    scene.pbHideOpponent
  }

  ShadowIntroSpikes4 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Get out of here! We can't let you come and go as you please!")
    if strong_katanas?
      scene.disappearBar
      target.pbSetHazards(:SPIKES, user)
      scene.appearBar
      pbMessage("Akui Clan Technique, Flame Kunai!")
    end
    scene.disappearBar
    target.pbInflictStatusEx(:BURN, 0, :BURNKUNAI, user)
    scene.pbHideOpponent
  }

  ShadowEvasion = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("Looks like it's time to get serious!")
    pbMessage("Akui Clan Technique, Shadow Style! Clones of Darkness!") if strong_katanas?
    scene.disappearBar
    user.pbRaiseStatStageEx(:EVASION, 1, :DOUBLETEAM)
    scene.pbHideOpponent
  }

  ShadowEvasion2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("Invaders must be punished!")
    pbMessage("Akui Clan Technique, Shadow Style! Clones of Darkness!") if strong_katanas?
    scene.disappearBar
    user.pbRaiseStatStageEx(:EVASION, 1, :DOUBLETEAM)
    scene.pbHideOpponent
  }

  ShadowEvasion3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("You need to be eliminated!")
    if strong_katanas?
      pbMessage("Akui Clan Technique, Shadow Style! Clones of Darkness!")
      scene.disappearBar
      user.pbRaiseStatStageEx(:EVASION, 1, :DOUBLETEAM)
      scene.appearBar
      pbMessage("Akui Clan Technique, Shock Kunai!")
    end
    scene.disappearBar
    target.pbInflictStatusEx(:PARALYSIS, 0, :SHOCKKUNAI, user)
    scene.pbHideOpponent
  }

  ShadowEvasion4 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Hagane City is ours! Give up now!")
    if strong_katanas?
      pbMessage("Akui Clan Technique, Shadow Style! Clones of Darkness!")
      scene.disappearBar
      user.pbRaiseStatStageEx(:EVASION, 1, :DOUBLETEAM)
      scene.appearBar
      pbMessage("Akui Clan Technique, Flame Kunai!")
    end
    scene.disappearBar
    target.pbInflictStatusEx(:BURN, 0, :BURNKUNAI, user)
    scene.pbHideOpponent
  }

  ShadowSpeed = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user = battlers[1]
    pbMessage("You'll never be able to catch up to us!")
    pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility!") if strong_katanas?
    scene.disappearBar
    user.pbRaiseStatStageEx(:SPEED, 1, :AGILITY)
    scene.pbHideOpponent
  }

  ShadowSpeed2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Nobody sneaks up behind me and lives to the tell the tale!")
    if strong_katanas?
      pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility!")
      scene.disappearBar
      user.pbRaiseStatStageEx(:SPEED, 2, :AGILITY)
      scene.appearBar
      pbMessage("Akui Clan Technique, Shock Kunai!")
    end
    scene.disappearBar
    target.pbInflictStatusEx(:PARALYSIS, 0, :SHOCKKUNAI, user)
    scene.pbHideOpponent
  }

  ShadowSpeed3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Outsiders must be eliminated! This is the way of the Akui Clan!")
    if strong_katanas?
      pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility!")
      scene.disappearBar
      user.pbRaiseStatStageEx(:SPEED, 2, :AGILITY)
      scene.appearBar
      pbMessage("Akui Clan Technique, Icicle Kunai!")
    end
    scene.disappearBar
    target.pbInflictStatusEx(:FROZEN, 0, :ICICLESPEAR, user)
    scene.pbHideOpponent
  }

  ShadowSpeed4 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("You will never defeat the Akui Clan!")
    pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility!") if strong_katanas?
    scene.disappearBar
    user.pbRaiseStatStageEx(:SPEED, 2, :AGILITY)
    target.pbSetHazards(:SPIKES, user)
    scene.pbHideOpponent
  }

  ShadowPower = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("My strength is unmatched!")
    pbMessage("Akui Clan Technique, Shadow Style! Muscle Control!") if strong_katanas?
    scene.disappearBar
    user.pbRaiseStatStageEx([:ATTACK, :DEFENSE], 2, :DRAGONDANCE)
    target.pbSetHazards(:SPIKES, user)
    scene.pbHideOpponent
  }

  ShadowPower2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("It's time for our rematch! I've been working on my strength!")
    pbMessage("Akui Clan Technique, Shadow Style! Muscle Control!") if strong_katanas?
    scene.disappearBar
    user.pbRaiseStatStageEx([:ATTACK, :DEFENSE, :SPDEF], 3, :DRAGONDANCE)
    target.pbSetHazards(:TOXICSPIKES, user)
    scene.pbHideOpponent
  }

  ShadowFreeze = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    if strong_katanas?
      pbMessage("Prepare to be frozen, foolish Kenshi!")
      pbMessage("Akui Clan Technique, Icicle Kunai!")
    else
      pbMessage("Prepare to be destroyed, foolish Kenshi!")
    end
    scene.disappearBar
    target.pbInflictStatusEx(:FROZEN, 0, :ICICLESPEAR, user)
    scene.pbHideOpponent
  }

  ShadowFreeze2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("To be in Akui Clan, you must have a heart as cold as ice!")
    if strong_katanas?
      pbMessage("Luckily for me, I also happen to have kunai that are as cold as ice!")
      pbMessage("Akui Clan Technique, Icicle Kunai!")
    end
    scene.disappearBar
    target.pbInflictStatusEx(:FROZEN, 0, :ICICLESPEAR, user)
    user.pbRaiseStatStageEx(:ATTACK, 2)
    scene.pbHideOpponent
  }

  ShadowShock = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    if strong_katanas?
      pbMessage("Prepare to be shocked, foolish Kenshi!")
    else
      pbMessage("You don't stand a chance, foolish Kenshi!")
    end
    pbMessage("Akui Clan Technique, Shock Kunai!")
    scene.disappearBar
    target.pbInflictStatusEx(:PARALYSIS, 0, :SHOCKKUNAI, user)
    scene.pbHideOpponent
  }

  ShadowBurn = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    if strong_katanas?
      pbMessage("If you try to mess with the Akui Clan, you're bound to get burned!")
      pbMessage("Akui Clan Technique, Flame Kunai!")
    else
      pbMessage("Nobody messes with the Akui Clan!")
    end
    scene.disappearBar
    target.pbInflictStatusEx(:BURN, 0, :BURNKUNAI, user)
    scene.pbHideOpponent
  }

  ShadowPoison = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    if strong_katanas?
      pbMessage("We Akui Clan coat all our kunai with a deadly poison.")
      pbMessage("Here, I'll give your Pokémon a taste!")
      pbMessage("Akui Clan Technique, Venom Kunai!")
    else
      pbMessage("The Akui Clan is unstoppable!")
    end
    scene.disappearBar
    target.pbInflictStatusEx(:POISON, 1, :POISONKUNAI, user)
    scene.pbHideOpponent
  }

  ShadowSleep = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    if strong_katanas?
      pbMessage("You're looking a little tired.")
      pbMessage("How about your Pokémon get some rest!")
      pbMessage("Akui Clan Technique, Tranquilizer Kunai!")
    else
      pbMessage("The Akui Clan won't rest until our enemies are destroyed!")
    end
    scene.disappearBar
    target.pbInflictStatusEx(:SLEEP, target.pbSleepDuration, :SLEEPKUNAI, user)
    scene.pbHideOpponent
  }

  ShadowSleep2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("I'll be the one to put a stop to your reign of terror!")
    pbMessage("The Akui Clan is counting on me to succeed! I can do this!")
    if strong_katanas?
      pbMessage("Akui Clan Technique, Tranquilizer Kunai!")
      scene.disappearBar
      target.pbInflictStatusEx(:SLEEP, target.pbSleepDuration, :SLEEPKUNAI, user)
      scene.appearBar
      pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility! Ultimate Speed!")
    end
    scene.disappearBar
    user.pbRaiseStatStageEx(:SPEED, 2, :AGILITY)
    scene.pbHideOpponent
  }

  ShadowDuo1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user    = battlers[1]
    target  = battlers[0]
    target2 = battlers[2]
    pbMessage("The Akui Clan will be taking all the Hanatsium in this mine!")
    pbMessage("Don't even bother trying to stop us, you little brats!")
    if strong_katanas?
      pbMessage("Akui Clan Technique, Shadow Style! Multi-Clones of Darkness!")
      scene.disappearBar
      ret = user.pbRaiseStatStageEx(:EVASION, 1, :DOUBLETEAM)
      battlers[3].pbRaiseStatStageEx(:EVASION, 1, ret || :DOUBLETEAM, user)
      target.pbSetHazards(:TOXICSPIKES, user)
      scene.pbHideOpponent
      scene.appearBar
      pbMessage("\\xn[\\v[26]]\\pogThose Akui guys aren't the only people who can use techniques to gain the edge in battle!")
      pbMessage("\\xn[\\v[26]]\\pogKatana of Fire, Nensho Style! Fire Vortex!")
      scene.disappearBar
      user.pbTrapWithMove(:FIRESPIN, target2)
      battlers[3].pbTrapWithMove(:FIRESPIN, target2)
      scene.appearBar
    end
    pbMessage("\\xn[\\v[26]]\\pogCome on \\PN, let's teach these jerks not to mess with the Nensho Clan!")
    pbMessage("\\xn[\\v[26]]\\pogNow for my signature technique! Hashimoto Might!") if strong_katanas?
    scene.disappearBar
    ret = target2.pbRaiseStatStageEx(:ATTACK, 2, :SWORDSDANCE)
    target.pbRaiseStatStageEx(:ATTACK, 2, (ret || :SWORDSDANCE), target2)
    scene.pbHideOpponent if !strong_katanas?
  }

  ShadowDuo1Last = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user    = battlers[1]
    target  = battlers[0]
    target2 = battlers[2]
    pbMessage("Grr... You brats are actually pretty strong...")
    pbMessage("You'll pay for crossing the Akui Clan!")
    if strong_katanas?
      pbMessage("Akui Clan Technique, Shadow Style! Ninja Dance!")
      scene.disappearBar
      ret = user.pbRaiseStatStageEx([:ATTACK, :SPEED], 1, :DRAGONDANCE)
      battlers[3].pbRaiseStatStageEx([:ATTACK, :SPEED], 1, (ret || :DRAGONDANCE), user)
      scene.pbHideOpponent
      scene.appearBar
      pbMessage("\\xn[\\v[26]]\\pogOh no you don't! You're the one's who are going to pay!")
      pbMessage("\\xn[\\v[26]]\\pogGraaah! Katana of Fire, Nensho Style! Flame Breath!")
      scene.disappearBar
      move_user = (target2&.fainted? ? target : target2)
      user.pbInflictStatusEx(:BURN, 0, :FLAMETHROWER, move_user)
      battlers[3].pbInflictStatusEx(:BURN, 0, :FLAMETHROWER, move_user)
      scene.appearBar
    else
      pbMessage("\\xn[\\v[26]]\\pogYou're the one's who are going to pay!")
    end
    pbMessage("\\xn[\\v[26]]\\pogLet's finish these jerks off \\PN!")
    pbMessage("\\xn[\\v[26]]\\pogHiyaaah! Hashimoto Might!") if strong_katanas?
    scene.disappearBar
    ret = target2.pbRaiseStatStageEx(:ATTACK, 2, :SWORDSDANCE)
    target.pbRaiseStatStageEx(:ATTACK, 2, (ret || :SWORDSDANCE), target2)
    scene.pbHideOpponent if !strong_katanas?
  }

  ShadowDuo2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user    = battlers[1]
    target  = battlers[0]
    target2 = battlers[2]
    pbMessage("You'll never be able to stop the plans of the Akui Clan!")
    pbMessage("You're nothing but pesky thorns in our sides!")
    if strong_katanas?
      pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility!")
      scene.disappearBar
      ret = user.pbRaiseStatStageEx(:SPEED, 2, :AGILITY)
      battlers[3].pbRaiseStatStageEx(:SPEED, 2, (ret || :AGILITY), user)
      scene.appearBar
      pbMessage("And that's not all! Get a load of this, you worthless children!")
      pbMessage("Akui Clan Technique, Shock Kunai!")
      scene.disappearBar
      target.pbInflictStatusEx(:PARALYSIS, 0, :SHOCKKUNAI, user)
      target2.pbInflictStatusEx(:PARALYSIS, 0, :SHOCKKUNAI, user)
      scene.pbHideOpponent
      scene.appearBar
      pbMessage("\\xn[\\v[26]]\\pogThese Akui grunts will never play fair...")
      pbMessage("\\xn[\\v[26]]\\pogLuckily for us, I also have a few tricks up my sleeve!")
      pbMessage("\\xn[\\v[26]]\\pogKatana of Fire, Nensho Style! Flame Breath!")
      scene.disappearBar
      move_user = (target2&.fainted? ? target : target2)
      user.pbInflictStatusEx(:BURN, 0, :FLAMETHROWER, move_user)
      battlers[3].pbInflictStatusEx(:BURN, 0, :FLAMETHROWER, move_user)
      scene.appearBar
    end
    pbMessage("\\xn[\\v[26]]\\pogLet's go \\PN! We can take care of these Akui lowlifes!")
    pbMessage("\\xn[\\v[26]]\\pogHiyaaah! Hashimoto Might!") if strong_katanas?
    scene.disappearBar
    ret = target2.pbRaiseStatStageEx(:ATTACK, 2, :SWORDSDANCE)
    target.pbRaiseStatStageEx(:ATTACK, 2, (ret || :SWORDSDANCE), target2)
    scene.pbHideOpponent if !strong_katanas?
  }

  ShadowDuo2Last = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user    = battlers[1]
    target  = battlers[0]
    target2 = battlers[2]
    pbMessage("We've been given orders to stop you from going any further!")
    pbMessage("We will not fail! We cannot fail!")
    if strong_katanas?
      pbMessage("Akui Clan Technique, Shadow Style! Ninja Dance!")
      scene.disappearBar
      ret = user.pbRaiseStatStageEx([:ATTACK, :SPEED], 1, :DRAGONDANCE)
      battlers[3].pbRaiseStatStageEx([:ATTACK, :SPEED], 1, (ret || :DRAGONDANCE), user)
      pbMessage("Akui Clan Technique, Shock Kunai!")
      scene.disappearBar
      move_user = (user&.fainted? ? battlers[3] : user)
      target.pbInflictStatusEx(:PARALYSIS, 0, :SHOCKKUNAI, move_user)
      target2.pbInflictStatusEx(:PARALYSIS, 0, :SHOCKKUNAI, move_user)
      scene.pbHideOpponent
      scene.appearBar
    end
    pbMessage("\\xn[\\v[26]]\\pog\\PN... I'm starting to feel pretty tired...")
    pbMessage("\\xn[\\v[26]]\\pogI can probably only use my katana techniques a couple more times...") if strong_katanas?
    pbMessage("\\xn[\\v[26]]\\pogBut, in times like these...")
    pbMessage("\\xn[\\v[26]]\\pogThat's when we really need to give it our all!")
    pbMessage("\\xn[\\v[26]]\\pogGraaaaaah! Hashimoto Might!") if strong_katanas?
    scene.disappearBar
    ret = target2.pbRaiseStatStageEx(:ATTACK, 2, :SWORDSDANCE)
    target.pbRaiseStatStageEx(:ATTACK, 2, (ret || :SWORDSDANCE), target2)
    scene.pbHideOpponent if !strong_katanas?
  }

  ShadowDuo3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user    = battlers[1]
    target  = battlers[0]
    target2 = battlers[2]
    pbMessage("You two brats must be skilled to have made it this far into the mine...")
    pbMessage("Too bad for you, this is the end of your journey!")
    if strong_katanas?
      pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility!")
      scene.disappearBar
      ret = user.pbRaiseStatStageEx(:SPEED, 2, :AGILITY)
      battlers[3].pbRaiseStatStageEx(:SPEED, 2, (ret || :AGILITY), user)
      target.pbSetHazards(:SPIKES, user)
      scene.pbHideOpponent
      scene.appearBar
      pbMessage("\\xn[\\v[26]]\\pogHey \\PN, I managed to pick up a few shock kunai off the ground after our last battle!")
      pbMessage("\\xn[\\v[26]]\\pogLet's see how the Akui Clan likes the taste of their own medicine!")
      pbMessage("\\xn[\\v[26]]\\pogAkui Clan Technique!\\wtnp[16] .\\wtnp[16].\\wtnp[16].\\wtnp[16]Shock Kunai?\\wtnp[30]")
      pbMessage("\\xn[\\v[26]]\\pogForget it... I'm just going to throw these kunai as hard I can!")
      user.pbInflictStatusEx(:PARALYSIS, 0, :SHOCKKUNAI, target2)
      battlers[3].pbInflictStatusEx(:PARALYSIS, 0, :SHOCKKUNAI, target2)
      scene.appearBar
      pbMessage("\\xn[\\v[26]]\\pogHaha! Yes, it worked!")
      pbMessage("\\xn[\\v[26]]\\pogTake that you Akui scumbags!")
      pbMessage("\\xn[\\v[26]]\\pogHiyaaah! Hashimoto Might!")
      scene.disappearBar
      ret = target2.pbRaiseStatStageEx(:ATTACK, 2, :SWORDSDANCE)
      target.pbRaiseStatStageEx(:ATTACK, 2, (ret || :SWORDSDANCE), target2)
      scene.appearBar
      scene.pbShowOpponent(0)
      pbMessage("Hey! You can't do that! That's cheating!")
    else
      pbMessage("\\xn[\\v[26]]\\pogYou Akui scumbags are going down!")
    end
    scene.disappearBar
    scene.pbHideOpponent
  }

  ShadowDuo3Last = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user    = battlers[1]
    target  = battlers[0]
    target2 = battlers[2]
    pbMessage("Hahaha... You kids fight dirty!")
    pbMessage("Maybe you should join the Akui Clan after all!")
    pbMessage("Come by Yami Island sometime... after we finish pulverizing you!")
    if strong_katanas?
      pbMessage("Akui Clan Technique, Shadow Style! Multi-Clones of Darkness!")
      scene.disappearBar
      ret = user.pbRaiseStatStageEx(:EVASION, 1, :DOUBLETEAM)
      battlers[3].pbRaiseStatStageEx(:EVASION, 1, (ret || :DOUBLETEAM), user)
      move_user = (user&.fainted? ? battlers[3] : user)
      move_target = (target&.fainted? ? target2 : target)
      move_target.pbSetHazards(:TOXICSPIKES, move_user)
      scene.pbHideOpponent
      scene.appearBar
    end
    pbMessage("\\xn[\\v[26]]\\pogAlright \\PN! We're so close to the end of the mine!")
    pbMessage("\\xn[\\v[26]]\\pogLet's gather up all our strength...")
    pbMessage("\\xn[\\v[26]]\\pogAnd then let's blast through these losers!")
    if strong_katanas?
      pbMessage("\\xn[\\v[26]]\\pogGraaaah!\\wtnp[30] Hashimoto Might!\\wtnp[30]")
      scene.disappearBar
      ret = target2.pbRaiseStatStageEx(:ATTACK, 2, :SWORDSDANCE)
      target.pbRaiseStatStageEx(:ATTACK, 2, (ret || :SWORDSDANCE), target2)
      scene.appearBar
      pbMessage("\\xn[\\v[26]]\\pogKatana of Fire, Nensho Style! Flame Breath!")
    end
    scene.disappearBar
    move_user = (target2&.fainted? ? target : target2)
    user.pbInflictStatusEx(:BURN, 0, :FLAMETHROWER, move_user)
    battlers[3].pbInflictStatusEx(:BURN, 0, :FLAMETHROWER, move_user)
  }

  ShadowDuo4 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user    = battlers[1]
    target  = battlers[0]
    target2 = battlers[2]
    pbMessage("Haha! You're too late!")
    pbMessage("We were already able to take a piece of the Hanatsium Crystal!")
    pbMessage("After we smash you two intruders, we'll steal even more!")
    if strong_katanas?
      pbMessage("Here, have a sneak peek at just how strong the Hanatsium Crystal is!")
      pbMessage("Akui Clan Technique, Shadow Style! Hanatsium Crystal Exposure!")
      scene.disappearBar
      user.pbRaiseStatStageEx(:ATTACK, 5, :WORKUP)
      battlers[3].pbRaiseStatStageEx(:ATTACK, 5, :WORKUP)
      target.pbSetHazards(:TOXICSPIKES, user)
      scene.pbHideOpponent
    end
    pbMessage("\\xn[\\v[26]]\\pogHere we go \\PN! This is our final battle!")
    pbMessage("\\xn[\\v[26]]\\pogI'm going all out! 200% Power, here and now!")
    if strong_katanas?
      pbMessage("\\xn[\\v[26]]\\pogKatana of Fire, Nensho Style! Fire Vortex!")
      battle.pbAnimation(:FIRESPIN,battlers[2],battlers[1])
      battle.pbAnimation(:FIRESPIN,battlers[2],battlers[3])
      scene.disappearBar
      user.pbTrapWithMove(:FIRESPIN, target2)
      battlers[3].pbTrapWithMove(:FIRESPIN, target2)
      scene.appearBar
      pbMessage("\\xn[\\v[26]]\\pogHiyaaah! 200% Hashimoto Might!")
    end
    scene.disappearBar
    ret = target2.pbRaiseStatStageEx(:ATTACK, 4, :SWORDSDANCE)
    target.pbRaiseStatStageEx(:ATTACK, 4, (ret || :SWORDSDANCE), target2)
    scene.pbHideOpponent if !strong_katanas?
  }

  MashiroIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Tch. We were so close to getting Virizion's power, but you all had to come mess it up.")
    pbMessage("I'll show you who you're messing with!")
    if strong_katanas?
      scene.disappearBar
      target.pbSetHazards(:TOXICSPIKES, user)
      scene.appearBar
      pbMessage("Akui Clan Technique, Toxic Kunai!")
      scene.disappearBar
      target.pbInflictStatusEx(:POISON, 1, :POISONKUNAI, user)
      scene.appearBar
      pbMessage("I won't let you brats get in my way!")
      pbMessage("I'm going to put you in your place, you miserable worm!")
    end
    scene.disappearBar
    user.pbRaiseStatStageEx(:SPATK, 1)
    scene.pbHideOpponent
  }

  Mashiro2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    pbMessage("Why are you so insistent on being annoying?!")
    pbMessage("Ugh... I don't have any Kunai anymore...") if strong_katanas?
    scene.disappearBar
    scene.pbHideOpponent
  }

  Mashiro3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    if strong_katanas?
      pbMessage("Did you actually believe that I ran out of Kunai?")
      pbMessage("You're even more foolish than you look!")
      pbMessage("Akui Clan Technique, Shock Kunai!")
      scene.disappearBar
      target.pbInflictStatusEx(:PARALYSIS, 0, :SHOCKKUNAI, user)
      scene.appearBar
      pbMessage("Do you see now why the codes of Bushido are worthless? Without honor and respect, I can do whatever I want.")
    else
      pbMessage("The codes of Bushido are worthless, and I'll prove it to you!")
    end
    scene.disappearBar
    user.pbRaiseStatStageEx(:SPEED, 2)
    scene.pbHideOpponent
  }

  MashiroLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Wow, you managed to bring me down to my last Pokémon...")
    pbMessage("Unfortunately for you, this is my strongest!")
    pbMessage("Don't even bother trying to steal my Pokémon! I know all about your dirty tricks!")
    pbMessage("We Akui Admins are a step above. We'll always be able to hit your Poké Balls away!")
    if strong_katanas?
      pbMessage("Now, you're lucky that I'm actually out of Kunai...")
      pbMessage("...")
      pbMessage("Just kidding, of course I have more Kunai!")
      pbMessage("Akui Clan Technique, Icicle Kunai!")
      scene.disappearBar
      target.pbInflictStatusEx(:FROZEN, 0, :ICICLESPEAR, user)
      scene.appearBar
    end
    pbMessage("You'll never be able to defeat me!")
    scene.disappearBar
    user.pbRaiseStatStageEx(:SPDEF, 1)
    scene.pbHideOpponent
  }

  MashiroRematchIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("I won't let you humiliate me like last time!")
    pbMessage("You'll never be able to beat me again!")
    if strong_katanas?
      scene.disappearBar
      target.pbSetHazards(:TOXICSPIKES, user)
      scene.appearBar
      pbMessage("Now, for a special surprise!")
    end
    pbMessage("When we were in Tsuchi Village, I studied the katana techniques of the Komorei Clan.")
    pbMessage("And now I've been able to perfect them as my own!")
    pbMessage("Akui Admin Technique, Komorei Style! Lush Terrain!")
    scene.disappearBar
    battle.pbStartTerrainEx(user, :Grassy)
    user.pbRaiseStatStageEx([:SPEED, :SPATK, :SPDEF], 2)
    scene.pbHideOpponent
  }

  MashiroRematch2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Grr... You've got some nerve.")
    pbMessage("I won't allow you to annoy me any more!")
    if strong_katanas?
      pbMessage("Akui Clan Technique, Icicle Kunai!")
      scene.disappearBar
      target.pbInflictStatusEx(:FROZEN, 0, :ICICLESPEAR, user)
      scene.appearBar
    end
    pbMessage("Akui Admin Technique, Komorei Style! Blazing Sunlight!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Sun)
    user.pbRaiseStatStageEx([:ATTACK, :SPATK, :SPEED], 2)
    scene.pbHideOpponent
  }

  MashiroRematchLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("You'll never defeat me! I won't allow it!")
    if strong_katanas?
      pbMessage("Akui Clan Technique, Venom Kunai!")
      scene.disappearBar
      target.pbInflictStatusEx(:POISON, 1, :POISONKUNAI, user)
      scene.appearBar
      pbMessage("Akui Clan Technique, Shadow Style! Muscle Control!")
    end
    scene.disappearBar
    user.pbRaiseStatStageEx([:SPATK, :DEFENSE, :SPDEF], 2, :DRAGONDANCE)
    scene.pbHideOpponent
  }

  HotokeIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user    = battlers[1]
    target  = battlers[0]
    target2 = battlers[2]
    pbMessage("\\wtnp[20].\\wtnp[20].\\wtnp[20].\\wtnp[20]")
    pbMessage("Don't look at me...")
    pbMessage("You should disappear...")
    scene.disappearBar
    move_user = (user&.fainted? ? user : battlers[3])
    battle.pbStartWeatherEx(move_user, :Sandstorm)
    if strong_katanas?
      user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 2)
      battlers[3]&.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 2, user)
      scene.appearBar
      pbMessage("...")
      pbMessage("Leave me alone...")
      scene.disappearBar
      scene.pbHideOpponent
    end
    scene.appearBar
    pbMessage("\\xn[Nori]\\bCome on \\PN, let's show these cowards how a real Kenshi battles!")
    pbMessage("\\xn[Nori]\\bKatana of Fire, Nensho Style! Breath of Flames!") if strong_katanas?
    scene.disappearBar
    move_user = (target2&.fainted? ? target : target2)
    user.pbInflictStatusEx(:BURN, 0, :FLAMETHROWER, move_user)
    battlers[3]&.pbInflictStatusEx(:BURN, 0, :FLAMETHROWER, move_user)
  }

  Hotoke2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user    = battlers[1]
    target  = battlers[0]
    target2 = battlers[2]
    pbMessage("\\wtnp[20].\\wtnp[20].\\wtnp[20].\\wtnp[20]")
    pbMessage("Stop... stop it...")
    scene.disappearBar
    move_user = (user&.fainted? ? battlers[3] : user)
    move_target = (target2&.fainted? ? target : target2)
    battle.pbStartWeatherEx(move_user, :Sandstorm)
    if strong_katanas?
      user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 3)
      battlers[3]&.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 3, user)
      scene.appearBar
      pbMessage("Akui Clan Technique... Toxic Spikes...")
      scene.disappearBar
      move_target.pbSetHazards(:TOXICSPIKES, move_user)
      scene.appearBar
      pbMessage("Get away...")
      pbMessage("Get away from me! Get away!")
      scene.disappearBar
      scene.pbHideOpponent
      scene.appearBar
    end
    pbMessage("\\xn[Nori]\\bIt's time to finish off these Akui clowns!")
    pbMessage("\\xn[Nori]\\bSecret Technique! Mountainous Roar!")
    scene.disappearBar
    ret = target.pbLowerStatStageEx([:DEFENSE, :SPDEF, :SPEED], 3, :NOBLEROAR, move_target)
    battlers[3]&.pbLowerStatStageEx([:DEFENSE, :SPDEF, :SPEED], 3, (ret || :NOBLEROAR), move_target)
  }

  Hotoke3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user    = battlers[1]
    target  = battlers[0]
    target2 = battlers[2]
    pbMessage("Get away! I can't let you win...")
    scene.disappearBar
    move_user = (user&.fainted? ? battlers[3] : user)
    battle.pbStartWeatherEx(move_user, :Sandstorm)
    if strong_katanas?
      user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 3)
      battlers[3]&.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 3, user)
      scene.appearBar
      pbMessage("Akui Clan Technique... Shock Kunai...")
      scene.disappearBar
      target.pbInflictStatusEx(:PARALYSIS, 0, :SHOCKKUNAI, user)
      target2.pbInflictStatusEx(:PARALYSIS, 0, :SHOCKKUNAI, user)
    end
    scene.appearBar
    pbMessage("Get away...")
    pbMessage("Get away from me! Get away!")
    scene.disappearBar
    scene.pbHideOpponent
  }

  HotokeRematchIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("I don't like you...")
    pbMessage("It's time for you to leave forever...")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Sandstorm)
    if strong_katanas?
      user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 3)
      scene.appearBar
      pbMessage("...")
      pbMessage("Now, for a new technique...")
      pbMessage("Akui Admin Technique... Nensho Style... Flame Breath...")
      scene.disappearBar
      target.pbInflictStatusEx(:BURN, 0, :FLAMETHROWER, user)
    end
    scene.pbHideOpponent
  }

  HotokeRematch2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    if strong_katanas?
      pbMessage("It's time to burn you again...")
      pbMessage("Akui Admin Technique... Nensho Style... Flame Breath...")
      target.pbInflictStatusEx(:BURN, 0, :FLAMETHROWER, user)
      scene.appearBar
      pbMessage("And now... Another new technique...")
      pbMessage("Akui Admin Technique... Nensho Style... Crimson Vortex...")
      scene.disappearBar
      target.pbTrapWithMove(:FIRESPIN, user)
      scene.appearBar
    end
    pbMessage("You'll never win...")
    pbMessage("Never...")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Sandstorm)
    user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 3)
    scene.pbHideOpponent
  }

  HotokeRematchLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("No...")
    pbMessage("No! This can't happen!")
    pbMessage("Get away from me!")
    if strong_katanas?
      pbMessage("Akui Admin Technique... Nensho Style... Crimson Vortex...")
      scene.disappearBar
      target.pbTrapWithMove(:FIRESPIN, user)
      scene.appearBar
      pbMessage("You can't win...")
      pbMessage("You can never win!")
      pbMessage("Akui Clan Technique... Shock Kunai...")
      scene.disappearBar
      target.pbInflictStatusEx(:PARALYSIS, 0, :SHOCKKUNAI, user)
    end
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Sandstorm)
    user.pbRaiseStatStageEx([:ATTACK, :SPEED], 2)
    scene.pbHideOpponent
  }

  KuroIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("I'm so looking forward to picking you apart, stupid Kenshi!")
    pbMessage("Your obsession with honor and dignity will be your downfall!")
    if strong_katanas?
      pbMessage("Here, let me show you the benefits ignoring the Bushido code!")
      pbMessage("Akui Clan Technique! Tranquilizer Kunai!")
      scene.disappearBar
      target.pbInflictStatusEx(:SLEEP, target.pbSleepDuration, :SLEEPKUNAI, user)
      scene.appearBar
      pbMessage("Hahaha! Are you having fun yet?!")
      pbMessage("\\shBecause I sure am!")
    end
    pbMessage("Now come on, show me what you're made of!")
    scene.disappearBar
    scene.pbHideOpponent
  }

  Kuro2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("I'm growing tired of playing with you, Kenshi.")
    pbMessage("I think it's about time I started taking this battle seriously!")
    if strong_katanas?
      pbMessage("Akui Clan Technique! Berserker Dance!")
      scene.disappearBar
      battle.pbAnimation(:GEOMANCY, user, target)
      ret = user.pbRaiseStatStageEx([:ATTACK, :SPEED], 2, :GEOMANCY)
      user.pbLowerStatStageEx([:DEFENSE, :SPDEF], 1, ret || :GEOMANCY)
      scene.appearBar
    end
    pbMessage("You can't possibly hope to defeat me!")
    pbMessage("I am the Hound of Cruelty, the strongest of the Akui Admins!")
    pbMessage("Akui Clan Technique, Flame Kunai!") if strong_katanas?
    scene.disappearBar
    target.pbInflictStatusEx(:BURN, 0, :BURNKUNAI, user)
    scene.pbHideOpponent
  }

  KuroLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\shHow dare you?!")
    pbMessage("Pawns of the Shogun need to be taught their place!")
    pbMessage("And that place... is six feet underground!")
    if strong_katanas?
      pbMessage("Akui Clan Technique! Berserker Dance!")
      scene.disappearBar
      battle.pbAnimation(:GEOMANCY, user, target)
      ret = user.pbRaiseStatStageEx([:ATTACK, :SPEED], 2, :GEOMANCY)
      user.pbLowerStatStageEx([:DEFENSE, :SPDEF], 1, ret || :GEOMANCY)
      scene.appearBar
      pbMessage("Akui Clan Technique, Venom Kunai!")
    end
    scene.disappearBar
    target.pbInflictStatusEx(:POISON, 2, :POISONKUNAI, user)
    scene.pbHideOpponent
  }

  KuroRematchIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("I had my fun toying with you before, but now playtime is over!")
    pbMessage("Witness the new techniques I stole from that stupid Shimizu Clan leader!")
    pbMessage("Akui Admin Technique, Shimizu Style! Healing Ring!")
    scene.disappearBar
    battle.pbAnimation(:AQUARING, user, user)
    user.effects[PBEffects::AquaRing] = true
    battle.pbDisplay(_INTL("{1} was surrounded with a veil of water!", user.pbThis))
    scene.appearBar
    if strong_katanas?
      pbMessage("And don't you dare forget about my signature move!")
      pbMessage("Akui Clan Technique! Tranquilizer Kunai!")
      scene.disappearBar
      target.pbInflictStatusEx(:SLEEP, target.pbSleepDuration, :SLEEPKUNAI, user)
      scene.appearBar
      pbMessage("Hahaha! Now, isn't this fun?!")
    end
    pbMessage("And now, how about I change the terrain!")
    pbMessage("Akui Admin Technique, Shimizu Style! Misty Terrain!")
    scene.disappearBar
    battle.pbStartTerrainEx(user, :Misty)
    scene.appearBar
    pbMessage("Come on now! Show me what you're made of!")
    scene.disappearBar
    scene.pbHideOpponent
  }

  KuroRematch2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Are you having fun yet?!")
    pbMessage("Because I'm having the time of my life!")
    pbMessage("Now, I'd hate rain on the parade, but...")
    pbMessage("Akui Admin Technique, Shimizu Style! Torrential Downpour!")
    scene.disappearBar
    battle.pbStartWeatherEx(user, :Rain)
    if strong_katanas?
      scene.appearBar
      pbMessage("Now, how should I torture you next?")
      pbMessage("Oh! I know! How about some more kunai?")
      pbMessage("Akui Clan Technique, Shock Kunai!")
      scene.disappearBar
      battle.pbAnimation(:SHOCKKUNAI, user, target)
      battle.pbCommonAnimation("Paralysis", target)
      scene.appearBar
      pbMessage("Actually... No, I don't think that's good enough!")
      pbMessage("How about I burn your Pokémon instead?")
      pbMessage("Akui Clan Technique, Flame Kunai!")
      scene.disappearBar
      battle.pbAnimation(:BURNKUNAI, user, target)
      battle.pbCommonAnimation("Burn", target)
      scene.appearBar
      pbMessage("You know, I still don't think this is good enough...")
      pbMessage("Hmm...")
      pbMessage("How about I just go back to using my favorite kunai?")
      pbMessage("Akui Clan Technique! Tranquilizer Kunai!")
      scene.disappearBar
      target.pbInflictStatusEx(:SLEEP, target.pbSleepDuration, :SLEEPKUNAI, user, true)
      scene.appearBar
      pbMessage("Hahahahaha! Thank you for being such an obedient little puppet!")
      pbMessage("You really are my favorite plaything!")
      pbMessage("Akui Clan Technique! Berserker Dance!")
      scene.disappearBar
    end
    battle.pbAnimation(:GEOMANCY, user, target)
    ret = user.pbRaiseStatStageEx([:ATTACK, :SPEED], 3, :GEOMANCY)
    user.pbLowerStatStageEx([:DEFENSE, :SPDEF], 2, ret || :GEOMANCY)
    scene.pbHideOpponent
  }

  KuroRematchLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("You're managing to keep up pretty well, \\PN!")
    pbMessage("Too bad for you, you're nothing but a worthless toy.")
    pbMessage("And just like an old toy, you've lost your value to me.")
    pbMessage("It's time for me to break you!")
    pbMessage("Akui Admin Technique, Shimizu Style! Healing Ring!")
    scene.disappearBar
    battle.pbAnimation(:AQUARING, user, user)
    user.effects[PBEffects::AquaRing] = true
    battle.pbDisplay(_INTL("{1} was surrounded with a veil of water!", user.pbThis))
    if strong_katanas?
      scene.appearBar
      pbMessage("Katana of Water, Shimizu Style! Raging Whirlpool!")
      scene.disappearBar
      target.pbTrapWithMove(:WHIRLPOOL, user, true)
      scene.appearBar
      pbMessage("It's time for you to go to sleep forever!")
      pbMessage("Akui Clan Technique! Tranquilizer Kunai!")
      scene.disappearBar
      target.pbInflictStatusEx(:SLEEP, target.pbSleepDuration(rand(4, 5)), :SLEEPKUNAI, user)
      scene.appearBar
      pbMessage("You don't stand a chance against me!")
      scene.disappearBar
    end
    user.pbRaiseStatStageEx(:ATTACK, 1)
    scene.pbHideOpponent
  }

  HattoriIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Hattori]\\rYou and Ryo will never be able stop me.")
    pbMessage("\\xn[Hattori]\\rYou see, I'm not afraid of the Katana of Light at all...")
    pbMessage("\\xn[Hattori]\\rIt's you who should fear my Katana of Shadows!")
    if strong_katanas?
      pbMessage("\\xn[Hattori]\\rKatana of Shadows, Akui Secret Technique! Nightmare Void!")
      scene.disappearBar
      ret = target.pbInflictStatusEx(:SLEEP, target.pbSleepDuration(rand(5, 6)), :DARKVOID, user)
      if ret
        target.effects[PBEffects::Nightmare] = true
        battle.pbDisplay(_INTL("{1} began having a nightmare!", target.pbThis))
      end
      target.pbSetHazards(:SPIKES, user)
      scene.appearBar
      pbMessage("\\xn[Hattori]\\rFoolish child, witness my true power! You'll never stop our plans!")
    end
    scene.disappearBar
    user.pbRaiseStatStageEx([:ATTACK, :SPATK], 1)
    scene.pbHideOpponent
  }

  Hattori2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Hattori]\\r\\PN, have you had enough yet?")
    pbMessage("\\xn[Hattori]\\rBecause I'm just getting started!")
    pbMessage("\\xn[Hattori]\\rYou'll never block my path to the throne!")
    pbMessage("\\xn[Hattori]\\rKatana of Shadows, Akui Secret Technique! Wonder Room!")
    scene.disappearBar
    battle.pbAnimation(:WONDERROOM, user, target)
    battle.field.effects[PBEffects::WonderRoom] = 6
    battle.pbDisplay(_INTL("Wonder Room created a bizarre area in which Defense and Sp. Def are swapped!"))
    if strong_katanas?
      scene.appearBar
      pbMessage("\\xn[Hattori]\\rWeaklings like you and Ryo...")
      pbMessage("\\xn[Hattori]\\rYou have no place in my new world!")
      pbMessage("\\xn[Hattori]\\rAkui Clan Technique, Venom Kunai!")
      scene.disappearBar
      target.pbInflictStatusEx(:POISON, 1, :POISONKUNAI, user)
      user.pbRaiseStatStageEx([:ATTACK, :SPATK], 1)
    end
    scene.pbHideOpponent
  }

  Hattori3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Hattori]\\r\\PN, you're doing a decent job of keeping up.")
    pbMessage("\\xn[Hattori]\\rThat must be my strong blood flowing through you.")
    pbMessage("\\xn[Hattori]\\rYou owe all of your success to me! Your father is just a weakling!")
    pbMessage("\\xn[Hattori]\\rYou should have joined me in the Akui Clan, traitorous child!")
    pbMessage("\\xn[Hattori]\\rKatana of Shadows, Akui Secret Technique! Psychic Terrain!")
    scene.disappearBar
    battle.pbStartTerrainEx(user, :Psychic)
    scene.appearBar
    pbMessage("\\xn[Hattori]\\rKatana of Shadows, Akui Secret Technique! Trick Room!")
    battle.pbAnimation(:TRICKROOM, user, user)
    scene.disappearBar
    battle.field.effects[PBEffects::TrickRoom] = 5
    battle.pbDisplay(_INTL("The dimensions were twisted!"))
    if strong_katanas?
      scene.appearBar
      pbMessage("\\xn[Hattori]\\rI cannot stand to look at you any longer...")
      pbMessage("\\xn[Hattori]\\rBegone, \\PN!")
      pbMessage("\\xn[Hattori]\\rAkui Clan Technique, Flame Kunai!")
      scene.disappearBar
      target.pbInflictStatusEx(:BURN, 0, :BURNKUNAI, user)
      user.pbRaiseStatStageEx([:ATTACK, :SPATK], 1)
    end
    scene.pbHideOpponent
  }

  HattoriLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Hattori]\\rThis is the end for you!")
    pbMessage("\\xn[Hattori]\\rKatana of Shadows, Akui Secret Technique! Cleansing Haze!")
    scene.disappearBar
    failed = true
    failed2 = true
    if strong_katanas?
      PBStats.eachBattleStat do |s|
        next if user.stages[s] <= 0
        user.stages[s] = 0
        failed = false
      end
      if !failed
        battle.pbAnimation(:CLEARSMOG, user, target)
        battle.pbDisplay(_INTL("#{user.pbThis}'s negative stat changes were eliminated!"))
      end
      PBStats.eachBattleStat do |s|
        next if target.stages[s] <= 0
        target.stages[s] = 0
        failed2 = false
      end
      if !failed2
        battle.pbAnimation(:SMOKESCREEN, user, target)
        battle.pbDisplay(_INTL("#{target.pbThis}'s positive stat changes were eliminated!"))
      end
    end
    if (failed && failed2) || !strong_katanas?
      battle.pbAnimation(:HAZE, user, target)
      battle.eachBattler { |b| b.pbResetStatStages }
      battle.pbDisplay(_INTL("All stat changes were eliminated!"))
    end
    scene.appearBar
    pbBGMFade(1)
    dur = (Graphics.frame_rate / 2)
    dur.times do |i|
      pbWait(1)
      scene.pbUpdate if scene.inPartyAnimation?
    end
    pbMessage("\\xn[Hattori]\\rYou've made a grave mistake now, my child.")
    pbMessage("\\xn[Hattori]\\rYou cannot even begin to comprehend the power of my Shadow Lugia!")
    pbBGMPlay("Botw-Ganon")
    pbMessage("\\xn[Hattori]\\rIt looks like I'll have to teach you one final lesson!")
    pbMessage("\\sh\\xn[Hattori]\\rGo Shadow #{user.name}! Eliminate \\PN, and that foolish Royal Samurai Ryo!")
    dur = pbCryFrameLength(user.pokemon)
    pbPlayCry(user.pokemon)
    dur.times do |i|
      pbWait(1)
      scene.pbUpdate if scene.inPartyAnimation?
    end
    pbMessage("\\xn[Hattori]\\rThe codes of Bushido will be dissolved after today!")
    if strong_katanas?
      pbMessage("\\xn[Hattori]\\rAkui Secret Technique! Hanatsium Crystal Exposure!")
      scene.disappearBar
      user.pbRaiseStatStageEx([:ATTACK, :DEFENSE, :SPATK, :SPDEF, :SPEEF], 1, :WORKUP)
      scene.appearBar
    end
    pbMessage("\\xn[Hattori]\\rYour journey ends here, my child!")
    pbMessage("\\xn[Hattori]\\rGoodbye, \\PN!")
    scene.disappearBar
    scene.pbHideOpponent
  }

  # Katana awakens
  KatanaIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Kenshi scum like you are worth NOTHING. I'll take you out here and now.")
    pbMessage("It's time to unleash my full power.")
    if strong_katanas?
      scene.disappearBar
      target.pbSetHazards(:SPIKES, user)
      scene.appearBar
      pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility!")
    end
    scene.disappearBar
    user.pbRaiseStatStageEx(:SPEED, 1, :AGILITY)
    scene.pbHideOpponent
  }

  KatanaAwakens = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    pbMessage("Give it up! It's impossible to beat our vicious Shadow Pokemon.")
    pbMessage("Wait, what's that ligh-\\wtnp[20]")
    scene.disappearBar
    viewport   = Viewport.new(0, 0, Graphics.width, Graphics.height)
    viewport.z = 999999
    viewport.color = Color.new(243, 243, 99, 0)
    pbSEPlay("shadowkatana")
    dur = (Graphics.frame_rate / 2)
    dur.times do |i|
      Graphics.update
      factor = ((i + 1).to_f / dur)
      viewport.color.alpha = 255 * factor
    end
    pbWait(Graphics.frame_rate / 4 * 3)
    pbMessage("You feel your father's energy flowing through the Ancient Katana and into your body...")
    pbMessage(".\\wtnp[18].\\wtnp[18].\\wtnp[18]")
    pbMessage("\\me[Conquest-LevelUpWarlord]The Ancient Katana transformed into the Katana of Light!")
    vRI("KATANALIGHT", 1)
    vDI("KATANABASIC") if vHI("KATANABASIC")
    pbMessage("You may now steal Shadow Pokémon from the Akui Clan!")
    pbWait(Graphics.frame_rate / 4 * 3)
    dur.times do |i|
      Graphics.update
      factor = ((i + 1).to_f / dur)
      viewport.color.alpha = 255 * (1 - factor)
    end
    scene.appearBar
    pbMessage("\\xn[Shogun]\\PN! You must use the power of light to counter these Shadow Pokemon! Capture their Pokemon and purify them for good!")
    scene.disappearBar
    $game_switches[67] = true
    $game_switches[62] = true
    $PokemonGlobal.snagMachine = true
    pbSEPlay("shadowkatana")
    dur = (Graphics.frame_rate / 4)
    dur.times do |i|
      Graphics.update
      factor = ((i + 1).to_f / dur)
      viewport.color.alpha = 255 * factor
    end
    pbWait(Graphics.frame_rate / 3)
    dur.times do |i|
      Graphics.update
      factor = ((i + 1).to_f / dur)
      viewport.color.alpha = 255 * (1 - factor)
    end
    viewport.dispose
    scene.appearBar
    pbMessage("Hngh- That light... what was it!?")
    scene.disappearBar
    scene.pbHideOpponent
  }

  # Sukiro quiz
  Sukiro1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Question time, \\PN!")
    # Choice Box Stuff
    cmd = pbMessage("What is a Kenshi's most important moral code?", ["The Code of Honor", "The Code of Power", "The Code of Intelligence"])
    if cmd == 0
      pbMessage("\\se[SwShCorrect]As expected of my student! Brilliant!")
      scene.pbHideOpponent
      scene.disappearBar
      target.pbRaiseStatStageEx(:ATTACK, 1, true, user)
    else
      pbMessage("\\se[SwShIncorrect]Hmm... It seems like we still have some work to do.")
      pbMessage("The correct answer is the \"Code of Honor,\" which all Kenshi are expected to follow.")
      scene.pbHideOpponent
      scene.disappearBar
      target.pbLowerStatStageEx(:ATTACK, 1, true, user)
    end
  }

  Sukiro2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Prepare yourself for another question \\PN!")
    cmd= pbMessage("What is a Kenshi's source of power?", ["Spear", "Pokémon", "Katana"])
    if cmd == 1
      pbMessage("\\se[SwShCorrect]Well done! You have been paying attention!")
      pbMessage("A Kenshi's true strength, comes from the bonds they establish with their Pokémon!")
      scene.pbHideOpponent
      scene.disappearBar
      target.pbRaiseStatStageEx(:DEFENSE, 1, true, user)
    else
      pbMessage("\\se[SwShIncorrect]Hmm... It seems like we still have some work to do.")
      pbMessage("While Katanas and Spears are effective weapons in their own right...")
      pbMessage("A Kenshi's true strength, comes from the bonds they establish with their Pokémon!")
      scene.pbHideOpponent
      scene.disappearBar
      target.pbLowerStatStageEx(:DEFENSE, 1, true, user)
    end
  }

  Sukiro3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("You're doing well \\PN. But are you prepared for another question?")
    pbMessage("Answer me this...")
    cmd = pbMessage("What determines the clan that a Kenshi will join?", ["Affinity", "Money", "Family"])
    if cmd == 0
      pbMessage("\\se[SwShCorrect]Well done, \\PN!")
      pbMessage("The correct answer is \"Affinity\", which is determined by the strength of a Kenshi's soul!")
      scene.pbHideOpponent
      scene.disappearBar
      target.pbRaiseStatStageEx(:SPEED, 1, true, user)
    elsif cmd == 1
      pbMessage("\\se[SwShIncorrect]That is incorrect!")
      pbMessage("It would be incredibly shameful for a Kenshi to attempt to buy their way into a clan!")
      pbMessage("The correct answer is \"Affinity\", which is determined by the strength of a Kenshi's soul!")
      scene.pbHideOpponent
      scene.disappearBar
      target.pbLowerStatStageEx(:SPEED, 2, true, user)
    else
      pbMessage("\\se[SwShIncorrect]Hmm... It seems like we still have some work to do.")
      pbMessage("The correct answer is \"Affinity\", which is determined by the strength of a Kenshi's soul!")
      scene.pbHideOpponent
      scene.disappearBar
      target.pbLowerStatStageEx(:SPEED, 1, true, user)
    end
  }

  Sukiro4 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("Alright \\PN! Prepare yourself for my hardest question yet!")
    cmd = pbMessage("What type of Pokémon is strongest against the Shimizu Clan?", ["Rock", "Electric", "Fire"])
    if cmd == 1
      pbMessage("\\se[SwShCorrect]Haha! That is correct! Excellent work, \\PN!")
      pbMessage("Shimizu Clan members have a water affinity, so Electric is the correct answer!")
      scene.pbHideOpponent
      scene.disappearBar
      target.pbRaiseStatStageEx(:SPATK, 1, true, user)
    else
      pbMessage("\\se[SwShIncorrect]Hmm... that is incorrect.")
      pbMessage("Shimizu Clan members have a water affinity, so Electric would be the correct answer.")
      scene.pbHideOpponent
      scene.disappearBar
      target.pbLowerStatStageEx(:SPATK, 1, true, user)
    end
  }

  Sukiro5 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("A truly honorable Kenshi must never forget their teachings.")
    pbMessage("Now, answer me this, \\PN.")
    cmd = pbMessage("What is the most important moral code of the Kenshi?", ["The Code of Power", "The Code of Honor", "The Code of Wisdom"])
    if cmd == 1
      pbMessage("\\se[SwShCorrect]Correct!")
    else
      pbMessage("\\se[SwShIncorrect]Hmm... that is incorrect.")
    end
    pbMessage("\\PN, you must never forget that the codes of honor and Bushido are what guide us.")
    pbMessage("Those in the Akui Clan have forgetten this message, and have lost their way.")
    pbMessage("It is our purpose as righteous Kenshi to bring them to justice!")
    scene.pbHideOpponent
    scene.disappearBar
    if cmd == 1
      target.pbRaiseStatStageEx([:ATTACK, :SPATK], 1, true, user)
    else
      target.pbLowerStatStageEx([:ATTACK, :SPATK], 1, true, user)
    end
  }

  Lugia = Proc.new { |battle, scene, battlers|
    scene.appearBar
    user = battlers[1]
    pbMessage("#{user.pbThis}'s soul is completely corrupted! It's driven only by hatred!")
    scene.disappearBar
    pbPlayCry(user.pokemon)
    pbWait(Graphics.frame_rate / 5)
    ret = user.pbRaiseStatStageEx([:ATTACK, :SPATK, :SPEED], 1, :DRAGONDANCE)
    user.pbLowerStatStageEx([:DEFENSE, :SPDEF], 1, ret || :DRAGONDANCE)
  }

  Hooh = Proc.new { |battle, scene, battlers|
    scene.appearBar
    user = battlers[1]
    pbMessage("#{user.pbThis}'s pure soul blazes forward!")
    scene.disappearBar
    pbPlayCry(user.pokemon)
    pbWait(Graphics.frame_rate / 5)
    user.pbRaiseStatStageEx([:ATTACK, :SPATK, :SPEED], 1, "Solar Beam charging")
  }

  Celebi = Proc.new { |battle, scene, battlers|
    scene.appearBar
    user = battlers[1]
    pbMessage("#{user.pbThis}'s pure soul grants it resolve!")
    scene.disappearBar
    pbPlayCry(user.pokemon)
    pbWait(Graphics.frame_rate / 5)
    if strong_katanas?
      user.pbRaiseStatStageEx([:DEFENSE, :SPATK, :SPDEF], 2, :HEALORDER)
    else
      user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 1, :HEALORDER, forced: true)
    end
  }

  Virizion = Proc.new { |battle, scene, battlers|
    scene.appearBar
    user = battlers[1]
    pbMessage("#{user.pbThis}'s soul is locked away!")
    pbMessage("It cannot be caught!")
    scene.disappearBar
    pbPlayCry(user.pokemon)
    pbWait(Graphics.frame_rate / 5)
    ret = user.pbRaiseStatStageEx([:ATTACK, :SPATK, :SPEED], 1, "CurseNoGhost", forced: true)
    user.pbLowerStatStageEx([:DEFENSE, :SPDEF], 1, ret || "CurseNoGhost", forced: true)
  }

  Terrakion = Proc.new { |battle, scene, battlers|
    scene.appearBar
    user = battlers[1]
    pbMessage("#{user.pbThis}'s soul is locked away!")
    pbMessage("It cannot be caught!")
    scene.disappearBar
    pbPlayCry(user.pokemon)
    pbWait(Graphics.frame_rate / 5)
    ret = user.pbRaiseStatStageEx([:ATTACK, :SPATK, :SPEED], 1, "CurseNoGhost", forced: true)
    user.pbLowerStatStageEx([:DEFENSE, :SPDEF], 1, ret || "CurseNoGhost", forced: true)
  }

  Cobalion = Proc.new { |battle, scene, battlers|
    scene.appearBar
    user = battlers[1]
    pbMessage("#{user.pbThis}'s soul is locked away!")
    pbMessage("It cannot be caught!")
    scene.disappearBar
    pbPlayCry(user.pokemon)
    pbWait(Graphics.frame_rate / 5)
    ret = user.pbRaiseStatStageEx([:ATTACK, :SPATK, :SPEED], 1, "CurseNoGhost", forced: true)
    user.pbLowerStatStageEx([:DEFENSE, :SPDEF], 1, ret || "CurseNoGhost", forced: true)
  }

  Dragonite = Proc.new { |battle, scene, battlers|
    scene.appearBar
    user = battlers[1]
    pbMessage("#{user.pbThis} is on a rampage!")
    scene.disappearBar
    pbPlayCry(user.pokemon)
    pbWait(Graphics.frame_rate / 5)
    if strong_katanas?
      user.pbRaiseStatStageEx([:ATTACK, :DEFENSE, :SPDEF], 2, :DRAGONDANCE)
    else
      user.pbRaiseStatStageEx([:ATTACK], 2, :DRAGONDANCE, forced: true)
    end
  }

  Darkrai = Proc.new { |battle, scene, battlers|
    scene.appearBar
    user   = battlers[1]
    target = battlers[0]
    pbMessage("#{user.pbThis}'s nightmare aura engulfs the battlefield!")
    scene.disappearBar
    ret = target.pbInflictStatusEx(:SLEEP, target.pbSleepDuration(rand(5, 6)), :DARKVOID, user, forced: true)
    if ret
      target.effects[PBEffects::Nightmare] = true
      battle.pbDisplay(_INTL("{1} began having a nightmare!", target.pbThis))
    end
  }

  Cresselia = Proc.new { |battle, scene, battlers|
    scene.appearBar
    user = battlers[1]
    pbMessage("#{user.pbThis}'s lunar presence envelopes the battlefield!")
    scene.disappearBar
    battle.pbAnimation(:MOONLIGHT, user, user)
    battle.pbStartTerrainEx(user, :Psychic, false)
  }

  # Dev intros
  CamIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Cam]\\bI'm excited to face you in battle!")
    pbMessage("\\xn[Cam]\\bNow, let me show you my signature move!")
    pbMessage("\\xn[Cam]\\bThundaga Katana! Lightning Stream!")
    scene.disappearBar
    if strong_katanas?
      target.pbInflictStatusEx(:PARALYSIS, 0, :THUNDERBOLT, user)
      scene.appearBar
    end
    pbMessage("\\xn[Cam]\\bI'm going to go all out!")
    scene.disappearBar
    user.pbRaiseStatStageEx([:ATTACK, :DEFENSE, :SPEED], 2, :CHARGE)
    scene.pbHideOpponent
  }

  CamLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Cam]\\bWow, you're an amazing Kenshi, \\PN!")
    pbMessage("\\xn[Cam]\\bIt is an honor to have someone as skilled as you playing our game!")
    pbMessage("\\xn[Cam]\\bHere, have a reward for your efforts!")
    scene.disappearBar
    target.pbRaiseStatStageEx(:SPEED, 1, :CHARGE, user)
    scene.appearBar
    pbMessage("\\xn[Cam]\\bDon't get too comfortable though, \\PN!")
    pbMessage("\\xn[Cam]\\bI'm still your opponent right now!")
    if strong_katanas?
      pbMessage("\\xn[Cam]\\bThundaga Katana! Lightning Stream!")
      scene.disappearBar
      target.pbInflictStatusEx(:PARALYSIS, 0, :THUNDERBOLT, user)
      scene.appearBar
    end
    pbMessage("\\xn[Cam]\\bThundaga Katana! Electric Terrain!")
    scene.disappearBar
    battle.pbStartTerrainEx(user, :Electric)
    user.pbRaiseStatStageEx([:ATTACK, :DEFENSE, :SPEED], 2)
    scene.appearBar
    pbMessage("\\xn[Cam]\\bLet's goooooo!")
    pbMessage("\\sh\\xn[Cam]\\bBUSHIDO BOIS!")
    scene.disappearBar
    scene.pbHideOpponent
  }

  LuxIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Lux]\\bGet ready, \\PN!")
    pbMessage("\\xn[Lux]\\bI don't plan on going easy on you.")
    if strong_katanas?
      pbMessage("\\xn[Lux]\\bKatana of Demons, First Style! Berserk Inferno!")
      scene.disappearBar
      target.pbTrapWithMove(:MAGMASTORM, user)
      user.pbRaiseStatStageEx([:ATTACK, :SPATK, :SPEED], 2)
      scene.appearBar
    end
    pbMessage("\\xn[Lux]\\bI'm always aiming for the top! And you're gonna have to go down.")
    scene.disappearBar
    scene.pbHideOpponent
  }

  LuxLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Lux]\\bI must admit, you've taken me by surprise, \\PN.")
    if strong_katanas?
      pbMessage("\\xn[Lux]\\bLets' see how you deal with this!")
      pbMessage("\\xn[Lux]\\bKatana of Demons, Lux's Signature Style! Devil's Wrath!")
      scene.disappearBar
      target.pbLowerStatStageEx([:ATTACK, :SPATK, :SPEED], [1, 1, 2], :SCARYFACE)
      scene.appearBar
    end
    pbMessage("\\xn[Lux]\\bDon't get too cocky. I'm going to win this, of course.")
    scene.disappearBar
    user.pbRaiseStatStageEx([:ATTACK, :SPATK, :SPEED], 2)
    scene.pbHideOpponent
  }

  TristanIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Tristan]\\bYou're in for a rude awakening if you think it's going to be easy, \\PN.")
    pbMessage("\\xn[Tristan]\\bLet's dance!")
    if strong_katanas?
      pbMessage("\\xn[Tristan]\\bKatana of the Abyss, Signature Style! Maniacal Glare!")
      scene.disappearBar
      battle.pbAnimation(:MEANLOOK, user, target)
      battle.pbDisplay(_INTL("{1} was afflicted with a Curse!", target.pbThis))
      target.effects[PBEffects::Curse] = true
      target.pbLowerStatStageEx([:SPEED, :SPDEF], 2, true, user)
      user.pbRaiseStatStageEx([:SPEED, :SPATK], 2)
      scene.appearBar
      pbMessage("\\xn[Tristan]\\bHaha! How do you like that?")
    end
    scene.disappearBar
    scene.pbHideOpponent
  }

  TristanLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Tristan]\\bYou've tested the limits of my strength so far...")
    pbMessage("\\xn[Tristan]\\bBut now #{user.name} and I are going to teach you why they call me Thunderfist!")
    if strong_katanas?
      pbMessage("\\xn[Tristan]\\bFists of Tristan, Signature Style! Thunder Fist!")
      scene.disappearBar
      target.pbInflictStatusEx(:PARALYSIS, 0, :THUNDERPUNCH, user)
      target.pbLowerStatStageEx([:DEFENSE, :SPEED], 2, true, user)
      user.pbRaiseStatStageEx([:ATTACK, :SPEED], 2)
      scene.appearBar
    end
    pbMessage("\\xn[Tristan]\\bCome at me, \\PN!")
    scene.disappearBar
    scene.pbHideOpponent
  }

  HauntedIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Haunted]\\bI've been waiting for this battle with you, \\PN!")
    pbMessage("\\xn[Haunted]\\bNow, let me show you why they call me \"Haunted\" Art Studio!")
    pbMessage("\\xn[Haunted]\\bKatana of Fear, Signature Style! Terrifying Stare!")
    scene.disappearBar
    target.pbTrapWithMove(:MEANLOOK, user, forced: true)
    target.pbLowerStatStageEx([:DEFENSE, :SPDEF, :SPEED], 2, :SNARL, user)
    scene.appearBar
    pbMessage("\\xn[Haunted]\\bHahahaha! You should have seen your face!")
    scene.disappearBar
    user.pbRaiseStatStageEx([:ATTACK, :SPEED], 2)
    scene.pbHideOpponent
  }

  HauntedLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Haunted]\\bThings are going pretty well for you in this battle, \\PN!")
    pbMessage("\\xn[Haunted]\\bIt would be a shame if you... were haunted!")
    pbMessage("\\xn[Haunted]\\bKatana of Fear, Signature Style! Terrifying Stare!")
    scene.disappearBar
    target.pbTrapWithMove(:MEANLOOK, user, forced: true)
    target.pbLowerStatStageEx([:DEFENSE, :SPDEF, :SPEED], 2, :SNARL, user)
    if strong_katanas?
      scene.appearBar
      pbMessage("\\xn[Haunted]\\bAnd that's not all, \\PN! Far from it!")
      pbMessage("\\xn[Haunted]\\bKatana of Fear, Signature Style! Spirit Flames!")
      scene.disappearBar
      target.pbInflictStatusEx(:BURN, 0, :WILLOWISP, user)
      scene.appearBar
      pbMessage("\\xn[Haunted]\\bCan you handle my haunting? Let's find out!")
      scene.disappearBar
    end
    user.pbRaiseStatStageEx([:ATTACK, :SPEED], 2)
    scene.pbHideOpponent
  }

  # Post-Cresselia Double BATTLE
  PostCress1 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[1]
    target = battlers[0]
    pbMessage("\\xn[Ryo]\\PN! Show Kayoko your true strength! No holding back!")
    pbMessage("\\xn[Ryo]\\bKatana of Illumination, Masayoshi Style! Brilliant Barrier!")
    scene.disappearBar
    battle.pbAnimation(:LIGHTSCREEN, user, user)
    user.pbOwnSide.effects[PBEffects::Reflect] = 4
    user.pbOwnSide.effects[PBEffects::LightScreen] = 4
    battle.pbDisplay(_INTL("A wall of light protects {1}!", user.pbTeam(true)))
    user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 3)
    battlers[3].pbRaiseStatStageEx([:DEFENSE, :SPDEF], 3)
    scene.pbHideOpponent
    scene.appearBar
    scene.pbShowOpponent(1)
    pbMessage("\\xn[Kayoko]\\rI can't lose now! This is my first step to  being a true Kenshi!")
    pbMessage("\\xn[Kayoko]\\rSignature Technique! Focused Mind!")
    scene.disappearBar
    stat = [:SPATK]
    stat.push(:SPDEF) if strong_katanas?
    ret = battlers[3].pbRaiseStatStageEx([:SPATK, :SPDEF], 2, :CALMMIND, forced: true)
    user.pbRaiseStatStageEx([:SPATK, :SPDEF], 2, ret || :CALMMIND, battlers[3], forced: true)
    scene.pbHideOpponent(1)
  }

  PostCress2 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[3]
    target = battlers[0]
    pbMessage("\\xn[]\\bLet's see how you handle this!")
    pbMessage("\\xn[Ryo]\\bKatana of Illumination, Masayoshi Style! Blinding Radiance!")
    scene.disappearBar
    stat = (strong_katanas? ? 2 : 1)
    ret = target.pbLowerStatStageEx(:ACCURACY, stat, :FLASH, user, forced: true)
    battlers[2].pbLowerStatStageEx(:ACCURACY, stat, ret || :FLASH, user, forced: true)
    scene.pbHideOpponent
  }

  PostCress3 = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(1)
    user = battlers[3]
    pbMessage("\\xn[Kayoko]\\rI've learned some things too!")
    pbMessage("\\xn[Kayoko]\\rKatana of Illumination! Brilliant Barrier!")
    scene.disappearBar
    battle.pbAnimation(:LIGHTSCREEN, user, user)
    user.pbOwnSide.effects[PBEffects::Reflect] = 3
    user.pbOwnSide.effects[PBEffects::LightScreen] = 3
    battle.pbDisplay(_INTL("A wall of light protects {1}!", user.pbTeam(true)))
    user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], 3)
    battlers[1].pbRaiseStatStageEx([:DEFENSE, :SPDEF], 3, user)
    scene.pbHideOpponent(1)
  }

  PostCressFinal = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    user   = battlers[3]
    target = battlers[0]
    pbMessage("\\xn[Ryo]\\bKayoko! You've done well thus far! Let's finish this now!")
    scene.pbHideOpponent
    scene.pbShowOpponent(1)
    pbMessage("\\xn[Kayoko]\\rYes, sir!")
    pbMessage("\\xn[Kayoko]\\rSignature Technique! Malicious Boost!")
    scene.disappearBar
    stat = [:ATTACK]
    stat.push(:SPATK) if strong_katanas?
    ret = user.pbRaiseStatStageEx(stat, 1, :WORKUP, forced: true)
    battlers[1].pbRaiseStatStageEx(stat, 1, ret || :WORKUP, user, forced: true)
    scene.pbHideOpponent(1)
    scene.appearBar
    scene.pbShowOpponent(0)
    pbMessage("\\xn[Ryo]\\bKatana of Illumination, Masayoshi Style! Radiant Shield!")
    scene.disappearBar
    user.pbOwnSide.effects[PBEffects::Reflect] = 5
    user.pbOwnSide.effects[PBEffects::LightScreen] = 5
    battle.pbDisplay(_INTL("A strong wall of light protects {1}!", user.pbTeam(true)))
    stat = (strong_katanas? ? 3 : 1)
    battlers[1].pbRaiseStatStageEx([:DEFENSE, :SPDEF], stat, forced: true)
    user.pbRaiseStatStageEx([:DEFENSE, :SPDEF], stat, true, battlers[1], forced: true)
    scene.pbHideOpponent
  }

  GoliIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    battler = battlers[1]
    pbMessage("\\bGoli Intro Placeholder!")
    scene.disappearBar
    stat = (strong_katanas? ? 3 : 1)
    battler.pbRaiseStatStageEx(:ATTACK, stat, forced: true)
    scene.pbHideOpponent
  }

  GoliLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    battler = battlers[1]
    pbMessage("\\bGoli Last Placeholder!")
    scene.disappearBar
    stat = (strong_katanas? ? 3 : 1)
    battler.pbRaiseStatStageEx(:ATTACK, stat, forced: true)
    scene.pbHideOpponent
  }

  ENLSIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    battler = battlers[1]
    pbMessage("\\bENLS Intro Placeholder!")
    scene.disappearBar
    stat = (strong_katanas? ? 3 : 1)
    battler.pbRaiseStatStageEx(:ATTACK, stat, forced: true)
    scene.pbHideOpponent
  }

  ENLSLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    battler = battlers[1]
    pbMessage("\\bENLS Last Placeholder!")
    scene.disappearBar
    stat = (strong_katanas? ? 3 : 1)
    battler.pbRaiseStatStageEx(:ATTACK, stat, forced: true)
    scene.pbHideOpponent
  }

  VoltsIntro = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    battler = battlers[1]
    pbMessage("\\bVoltseon Intro Placeholder!")
    scene.disappearBar
    stat = (strong_katanas? ? 3 : 1)
    battler.pbRaiseStatStageEx(:ATTACK, stat, forced: true)
    scene.pbHideOpponent
  }

  VoltsLast = Proc.new { |battle, scene, battlers|
    scene.appearBar
    scene.pbShowOpponent(0)
    battler = battlers[1]
    pbMessage("\\bVoltseon Last Placeholder!")
    scene.disappearBar
    stat = (strong_katanas? ? 3 : 1)
    battler.pbRaiseStatStageEx(:ATTACK, stat, forced: true)
    scene.pbHideOpponent
  }
end
