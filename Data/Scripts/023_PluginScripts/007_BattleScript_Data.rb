#==============================================================================#
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
#==============================================================================#
#                                                                              #
#                          Mid Battle Dialogue and Script                      #
#                                       v1.5                                   #
#                                 By Golisopod User                            #
#                                                                              #
#==============================================================================#
#\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\#
#==============================================================================#
#                                                                              #
# This is the dialogue portion of the script. If for some reason the script    #
# window is too small for you, you can input the dialogue data over here and   #
# call it when needed in Battle. This will keep your events much cleaner.      #
#                                                                              #
# THIS IS ONLY AN OPTIONAL WAY OF INPUTTING BATTLE DIALOGUE,IT'S NOT NECESSARY #
#==============================================================================#

#DON'T DELETE THIS LINE
module DialogueModule


# Format to add new stuff here
# Name = data
#
# To set in a script command
# BattleScripting.setInScript("condition",:Name)
# The ":" is important

#  Joey_TurnStart0 = {"text"=>"Hello","bar"=>true}
#  BattleScripting.set("turnStart0",:Joey_TurnStart0)



  # This is an example of Scene Manipulation where I manipulate the color tone of each individual graphic in the scene to simulate a ""fade to black"
  FRLG_Turn0 = Proc.new{|battle|
                for i in 0...8
                  val = 25+(25*i)
                  battle.scene.sprites["battle_bg"].color=Color.new(-255,-255,-255,val)
                  battle.scene.sprites["base_0"].color=Color.new(-255,-255,-255,val)
                  battle.scene.sprites["base_1"].color=Color.new(-255,-255,-255,val)
                  battle.scene.sprites["dataBox_1"].color=Color.new(-255,-255,-255,val)
                  battle.scene.sprites["dataBox_0"].color=Color.new(-255,-255,-255,val)
                  battle.scene.sprites["pokemon_0"].color=Color.new(-255,-255,-255,val)
                  battle.scene.sprites["pokemon_1"].color=Color.new(-255,-255,-255,val)
                  pbWait(1)
                end
                pbMessage("\\bOh, for Pete's sake...\\nSo pushy, as always.")
                pbMessage("\\b\\PN,\\nYou've never had a Pokémon Battle before, have you?")
                pbMessage("\\bA Pokémon battle is when Trainer's pit their Pokémon against each other.")
                for i in 0...8
                  val = 200 - (25+(25*i))
                  battle.scene.sprites["dataBox_1"].color=Color.new(-255,-255,-255,val)
                  pbWait(1)
                end
                pbMessage("\\bThe Trainer that makes the other Trainer's Pokémon faint by lowering their HP to 0, wins.")
                for i in 0...8
                  val = 25+(25*i)
                  battle.scene.sprites["dataBox_1"].color=Color.new(-255,-255,-255,val)
                  pbWait(1)
                end
                pbMessage("\\bBut rather than talking about it, you'll learn more from experience.")
                pbMessage("\\bTry battling and see for yourself.")
                for i in 0...8
                  val = 200-(25+(25*i))
                  battle.scene.sprites["battle_bg"].color=Color.new(-255,-255,-255,val)
                  battle.scene.sprites["base_0"].color=Color.new(-255,-255,-255,val)
                  battle.scene.sprites["base_1"].color=Color.new(-255,-255,-255,val)
                  battle.scene.sprites["dataBox_1"].color=Color.new(-255,-255,-255,val)
                  battle.scene.sprites["dataBox_0"].color=Color.new(-255,-255,-255,val)
                  battle.scene.sprites["pokemon_0"].color=Color.new(-255,-255,-255,val)
                  battle.scene.sprites["pokemon_1"].color=Color.new(-255,-255,-255,val)
                  pbWait(1)
                end
              }

  FRLG_Damage = Proc.new{|battle|
                  for i in 0...8
                    val = 25+(25*i)
                    battle.scene.sprites["battle_bg"].color=Color.new(-255,-255,-255,val)
                    battle.scene.sprites["base_0"].color=Color.new(-255,-255,-255,val)
                    battle.scene.sprites["base_1"].color=Color.new(-255,-255,-255,val)
                    battle.scene.sprites["dataBox_1"].color=Color.new(-255,-255,-255,val)
                    battle.scene.sprites["dataBox_0"].color=Color.new(-255,-255,-255,val)
                    battle.scene.sprites["pokemon_0"].color=Color.new(-255,-255,-255,val)
                    battle.scene.sprites["pokemon_1"].color=Color.new(-255,-255,-255,val)
                    pbWait(1)
                  end
                  pbMessage("\\bInflicting damage on the foe is the key to winning a battle")
                  for i in 0...8
                    val = 200-(25+(25*i))
                    battle.scene.sprites["battle_bg"].color=Color.new(-255,-255,-255,val)
                    battle.scene.sprites["base_0"].color=Color.new(-255,-255,-255,val)
                    battle.scene.sprites["base_1"].color=Color.new(-255,-255,-255,val)
                    battle.scene.sprites["dataBox_1"].color=Color.new(-255,-255,-255,val)
                    battle.scene.sprites["dataBox_0"].color=Color.new(-255,-255,-255,val)
                    battle.scene.sprites["pokemon_0"].color=Color.new(-255,-255,-255,val)
                    battle.scene.sprites["pokemon_1"].color=Color.new(-255,-255,-255,val)
                    pbWait(1)
                  end
                }

  FRLG_End = Proc.new{|battle|
              battle.scene.pbShowOpponent(0)
              pbMessage("WHAT!\\nUnbelievable!\\nI picked the wrong Pokémon!")
              for i in 0...8
                val = 25+(25*i)
                battle.scene.sprites["trainer_1"].color=Color.new(-255,-255,-255,val)
                battle.scene.sprites["battle_bg"].color=Color.new(-255,-255,-255,val)
                battle.scene.sprites["base_0"].color=Color.new(-255,-255,-255,val)
                battle.scene.sprites["base_1"].color=Color.new(-255,-255,-255,val)
                battle.scene.sprites["dataBox_1"].color=Color.new(-255,-255,-255,val)
                battle.scene.sprites["dataBox_0"].color=Color.new(-255,-255,-255,val)
                battle.scene.sprites["pokemon_0"].color=Color.new(-255,-255,-255,val)
                battle.scene.sprites["pokemon_1"].color=Color.new(-255,-255,-255,val)
                pbWait(1)
              end
              pbMessage("\\bHm! Excellent!")
              pbMessage("\\bIf you win, you will earn prize money and your Pokémon will grow.")
              pbMessage("\\bBattle other Trainers and make your Pokémon strong!")
              for i in 0...8
                val = 200-(25+(25*i));battle.scene.sprites["trainer_1"].color=Color.new(-255,-255,-255,val);
                battle.scene.sprites["battle_bg"].color=Color.new(-255,-255,-255,val)
                battle.scene.sprites["base_0"].color=Color.new(-255,-255,-255,val)
                battle.scene.sprites["base_1"].color=Color.new(-255,-255,-255,val)
                battle.scene.sprites["dataBox_1"].color=Color.new(-255,-255,-255,val)
                battle.scene.sprites["dataBox_0"].color=Color.new(-255,-255,-255,val)
                battle.scene.sprites["pokemon_0"].color=Color.new(-255,-255,-255,val)
                battle.scene.sprites["pokemon_1"].color=Color.new(-255,-255,-255,val)
                pbWait(1)
              end
            }

  Catching_Start = {"text"=>["This is the 1st time you're catching Pokemon right Red?", "Well let me tell you it's surprisingly easy!","1st weaken the Pokemon",
                    "Healthy Pokemon are much harder to catch"],"opp"=>"trainer024"}

  Catching_Catch = Proc.new{|battle|
                      BattleScripting.set("turnStart#{battle.turnCount+1}",Proc.new{|battle|
                        battle.scene.pbShowOpponent(0)
                        # Checking for Status to display different dialogue
                        if battle.battlers[1].pbHasAnyStatus?
                          pbMessage("Nice strategy! Inflicting a status condiition on the Pokémon further increases your chance at catching it.")
                          pbMessage("Now is the perfect time to throw a PokeBall!")
                        else
                          pbMessage("Great work! You're a natural!")
                          pbMessage("Now is the perfect time to throw a PokeBall!")
                        end
                        ball=0
                        battle.scene.pbHideOpponent
                        # Forcefully Opening the Bag and Throwing the Pokevall
                        pbFadeOutIn(99999){
                          scene = PokemonBag_Scene.new
                          screen = PokemonBagScreen.new(scene,$PokemonBag)
                          while ball==0
                            ball = screen.pbChooseItemScreen(Proc.new{|item| pbIsPokeBall?(item) })
                            if pbIsPokeBall?(ball)
                              break
                            end
                          end
                        }
                        battle.pbThrowPokeBall(1,ball,300,false)
                      })
                   }
# My Goal here was to have the message appear on the end of the turn after Opal sends out her Pokemon
   Opal_Send1 = Proc.new{|battle|
                  BattleScripting.set("turnEnd#{battle.turnCount}",Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Question!")
                    # Choice Box Stuff
                    cmd=0
                    cmd= pbMessage("You...\\nDo you know my nickname?",["The Magic-User","The wizard"],0,nil,0)
                    if cmd == 1
                      pbMessage("\\se[SwShCorrect]Ding ding ding! Congratulations, you are correct!")
                      battle.scene.pbHideOpponent
                      battle.scene.disappearBar
                      battle.battlers[0].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[0])
                    else
                      pbMessage("\\se[SwShIncorrect]Bzzzzt! Too bad!")
                      battle.scene.pbHideOpponent
                      battle.scene.disappearBar
                      battle.battlers[0].pbLowerStatStage(PBStats::SPEED,1,battle.battlers[0])
                    end
                  })
                }

   Opal_Send2 = Proc.new{|battle|
                  BattleScripting.set("turnEnd#{battle.turnCount+1}",Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Question!")
                    cmd=0
                    cmd= pbMessage("What is my favorite color?",["Pink","Purple"],0,nil,0)
                    if cmd == 1
                      pbMessage("\\se[SwShCorrect]Yes, a nice, deep purple... Truly grand, don't you think?")
                      battle.scene.pbHideOpponent
                      battle.scene.disappearBar
                      battle.battlers[0].pbRaiseStatStage(PBStats::DEFENSE,1,battle.battlers[0])
                      battle.battlers[0].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[0])
                    else
                      pbMessage("\\se[SwShIncorrect]That's what I like to see in other people, but it's not what I like for myself.")
                      battle.scene.pbHideOpponent
                      battle.scene.disappearBar
                      battle.battlers[0].pbLowerStatStage(PBStats::DEFENSE,1,battle.battlers[0])
                      battle.battlers[0].pbLowerStatStage(PBStats::SPDEF,1,battle.battlers[0])
                    end
                  })
                }

   Opal_Send3 = Proc.new{|battle|
                  BattleScripting.set("turnEnd#{battle.turnCount+1}",Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Question!")
                    cmd=0
                    cmd= pbMessage("All righty then... How old am I?",["16 years old","88 years old"],1,nil,1)
                    if cmd == 0
                      pbMessage("\\se[SwShCorrect]Hah! I like your answer!")
                      battle.scene.pbHideOpponent
                      battle.scene.disappearBar
                      battle.battlers[0].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[0])
                      battle.battlers[0].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[0])
                    else
                      pbMessage("\\se[SwShIncorrect]Well, you're not wrong. But you could've been a little more sensitive.")
                      battle.scene.pbHideOpponent
                      battle.scene.disappearBar(battle)
                      battle.battlers[0].pbLowerStatStage(PBStats::ATTACK,1,battle.battlers[0])
                      battle.battlers[0].pbLowerStatStage(PBStats::SPATK,1,battle.battlers[0])
                    end
                  })
                }

   Opal_Last = Proc.new{|battle|
                 battle.scene.appearBar
                 battle.scene.pbShowOpponent(0)
                 TrainerDialogue.changeTrainerSprite("BerthaPlatinum_2",battle.scene)
                 pbMessage("My morning tea is finally kicking in...")
                 TrainerDialogue.changeTrainerSprite("trainer069",battle.scene)
                 pbWait(5)
                 pbMessage("\\xl[Opal]and not a moment too soon!")
                 battle.scene.pbHideOpponent
                 battle.scene.disappearBar
              }

   Opal_Mega = Proc.new{|battle|
                battle.scene.appearBar
                battle.scene.pbShowOpponent(0)
                TrainerDialogue.changeTrainerSprite(["BerthaPlatinum_2"],battle.scene)
                pbMessage("Are you prepared?")
                pbSEPlay("SwShImpact")
                TrainerDialogue.changeTrainerSprite(["BerthaPlatinum_2","trainer069","BerthaPlatinum"],battle.scene,2)
                pbWait(5)
                pbMessage("I'm going to have some fun with this!")
                battle.scene.pbHideOpponent
                TrainerDialogue.changeTrainerSprite(["trainer069"],battle.scene)
                battle.scene.disappearBar
              }

   Opal_LastAttack = Proc.new{|battle|
                      battle.scene.appearBar
                      battle.scene.pbShowOpponent(0)
                      TrainerDialogue.changeTrainerSprite(["BerthaPlatinum_2"],battle.scene)
                      pbMessage("You lack pink! Here, let us give you some.")
                      pbSEPlay("SwShImpact")
                      TrainerDialogue.changeTrainerSprite(["BerthaPlatinum_2","trainer069","BerthaPlatinum"],battle.scene,2)
                      pbWait(16)
                      battle.scene.pbHideOpponent
                      TrainerDialogue.changeTrainerSprite(["trainer069"],battle.scene)
                      battle.scene.disappearBar
                    }

   Brock_LastPlayer = Proc.new{|battle|
                      # Displaying Differen Dialogue if the Pokemon is a Pikachu
                        if battle.battlers[0].isSpecies?(:PIKACHU)
                          battle.scene.pbShowOpponent(0)
                          battle.scene.disappearDatabox
                          pbMessage("It's that Pikachu again.")
                          pbMessage("I honestly feel sorry for it.")
                          pbMessage("Being raised by such a weak and incapable Pokémon Trainer.")
                          pbMessage("Let's show him how weak we are Pikachu.")
                      # Setting the Geodude's typing to Water to allow Pikachu to hit it super Effectively
                          battle.battlers[1].pbChangeTypes(getConst(PBTypes,:WATER))
                          battle.scene.pbHideOpponent
                          battle.scene.appearDatabox
                        elsif battle.battlers[0].isSpecies?(:PIDGEOTTO)
                      # Setting the Geodude's typing to Grass to allow Pidgeotto to hit it super Effectively
                          battle.battlers[1].pbChangeTypes(getConst(PBTypes,:GRASS))
                          battle.battlers[1].pbChangeTypes(getConst(PBTypes,:BUG))
                        end
                      # Using the Laser Focus and Endure Effects to force a Ctitical Hit and make sure that the Player's Pokemon Endures the next hit.
                        battle.battlers[0].effects[PBEffects::LaserFocus] = 2
                        battle.battlers[0].effects[PBEffects::Endure] = true
                      }
   Brock_MockPlayer = Proc.new{|battle|
                        battle.scene.pbShowOpponent(0)
                        battle.scene.disappearDatabox
                        # If the Player starts with a Pidgeotto then show this dialogue, else the other one
                        if battle.battlers[0].pbHasType?(:FLYING)
                          pbMessage("Hmph. Bad Strategy.")
                          pbMessage("Don't you know Flying Types are weak against Rock type.")
                          pbMessage("Ummm... I guess I forgot about that.")
                          pbMessage("C'mon \\PN, use your head.")
                        else
                          pbMessage("Look's like you haven't trained a bit since last time \\PN.")
                          pbMessage("I'm gonna make you eat those words Brock!")
                        end
                        battle.scene.pbHideOpponent
                        battle.scene.appearDatabox
                      }

   Brock_GiveUp = Proc.new{|battle|
                    battle.scene.pbShowOpponent(0)
                    battle.scene.disappearDatabox
                    pbMessage("Are you giving up already, \\PN?")
                    # Forcefully Setting the Fainted Condition to be done so that it doesn't show up later.
                    TrainerDialogue.setDone("fainted")
                    battle.scene.pbHideOpponent
                    battle.scene.appearDatabox
                  }

   Brock_Sprinklers = Proc.new{|battle|
                      # Immedialtely the Next Turn after the Player's HP is less than half, do this
                        BattleScripting.set("turnStart#{battle.turnCount+1}",Proc.new{|battle|
                          battle.pbAnimation(getID(PBMoves,:BIND),battle.battlers[1],battle.battlers[0])
                          battle.pbCommonAnimation("Bind",battle.battlers[0],nil)
                          battle.scene.disappearDatabox
                          battle.pbDisplay(_INTL("Onix constricted its tail around {1}!",battle.battlers[0].pbThis(true)))
                          battle.scene.pbDamageAnimation(battle.battlers[0])
                          battle.pbDisplay(_INTL("{1} struggles to escape Onix' grasp!",battle.battlers[0].pbThis))
                          battle.scene.pbDamageAnimation(battle.battlers[0])
                          pbMessage(_INTL("{1} hang on a little longer!",battle.battlers[0].name))
                          pbMessage("...")
                          pbBGMFade(2)
                          battle.scene.pbShowOpponent(0)
                          pbMessage("Onix stop!")
                          pbMessage("No Brock, I want to play this match till the end.")
                          pbMessage("There's no point in going on, besides, I don't want to hurt your Pokémon more.")
                          pbMessage("Hrgh..")
                          battle.scene.pbHideOpponent
                          pbMessage("...")
                          battle.pbCommonAnimation("Rain",nil,nil)
                          battle.pbDisplay("The sprinklers turned on!")
                          pbPlayCrySpecies(:ONIX,0,70,70)
                          battle.pbDisplay("Onix became soaking wet!")
                          pbBGMPlay("BrockWin")
                          battle.scene.pbShowOpponent(0)
                          battle.scene.disappearDatabox
                          pbMessage("\\PN! Rock Pokemon are weakened by water!")
                          battle.battlers[0].effects[PBEffects::LaserFocus] = 2
                          battle.battlers[1].effects[PBEffects::Endure] = true
                          if battle.battlers[0].isSpecies?(:PIKACHU)
                            # Setting the Geodude's typing to Water to allow Pikachu to hit it super Effectively
                            battle.battlers[1].pbChangeTypes(getConst(PBTypes,:WATER))
                          elsif battle.battlers[0].isSpecies?(:PIDGEOTTO)
                            # Setting the Geodude's typing to Grass to allow Pidgeotto to hit it super Effectively
                            battle.battlers[1].pbChangeTypes(getConst(PBTypes,:GRASS))
                            battle.battlers[1].pbChangeTypes(getConst(PBTypes,:BUG))
                          end
                          pbMessage(_INTL("{1}! Let's get 'em!",battle.battlers[0].pbThis(true)))
                          battle.battlers[1].effects[PBEffects::Flinch]=1
                          battle.scene.appearDatabox
                        })
                      }

   Brock_Forfeit = Proc.new{|battle|
                    battle.scene.disappearDatabox
                    pbMessage(_INTL("Okay {1}! Lets finish him off with a...",battle.battlers[0].name))
                    pbBGMFade(2)
                    pbWait(10)
                    pbBGMPlay("BrockGood")
                    pbMessage("My consience is holding me back!")
                    pbMessage("I can't bring myself to beat Brock!")
                    pbMessage("I'm imagining his little brothers and sisters stopping me from defeating the one person they love!")
                    pbMessage("\\PN, I think you better open your eyes.")
                    pbMessage("Huh!")
                    pbMessage("Stop hurting our brother you big bully!")
                    pbMessage("Believe me kid! I'm no bully.")
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Stop it! Get off, all of you.")
                    pbMessage("This is an official match, and we're gonna finish this no matter what.")
                    pbMessage("But Brock, we know you love you Pokémon so much!")
                    pbMessage("That's why we can't watch Onix suffer from another attack!")
                    pbMessage("...")
                    pbMessage("...")
                    pbMessage(_INTL("{1}! Return!",battle.battlers[0].name))
                    battle.scene.pbRecall(0)
                    pbMessage("What do you think you're doing! This match isn't over yet \\PN.")
                    pbMessage("Those sprinklers going off was an accident. Winning a match because of that wouldn't have proven anything.")
                    pbMessage("Next time we meet, I'll beat you my way, fair and square!")
                    battle.scene.pbHideOpponent
                    battle.pbDisplay("You forfeited the match...")
                    battle.decision=3
                    pbMessage("Hmph! Just when he finally gets a lucky break. He decides to be a nice guy too.")
                  }
      # Basic trainer intros
      KenshiF1 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\rShow me your honorable battle style!")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      KenshiF2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\rPrepare to feel our anger! Hiyaah!")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      KenshiM1 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\bCome on, let's see what you've got!")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      BlackBelt1 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\bHyah! Feel the power of my fists!")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                  }
       KenshiF3 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\rBrace yourself, Toxel!")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
        # Komorei Intros
        Komorei1 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Shizen Forest provides natural advantages for us in the Komorei Clan.")
                    battle.pbAnimation(getID(PBMoves,:GRASSYTERRAIN),battle.battlers[1],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Grassy)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
        Komorei2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("I'll show you the power of the Komorei Clan!")
                    battle.pbAnimation(getID(PBMoves,:GRASSYTERRAIN),battle.battlers[1],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Grassy)
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
        Komorei3 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Alright Kenshi! I'm going to beat you, and turn my luck around!")
                    battle.pbAnimation(getID(PBMoves,:GRASSYTERRAIN),battle.battlers[1],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Grassy)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
        Komorei4 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You cannot hide from my love!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:CHARM),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbLowerStatStage(PBStats::ATTACK,2,battle.battlers[0])
                    battle.pbAnimation(getID(PBMoves,:GRASSYTERRAIN),battle.battlers[1],battle.battlers[1])
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Grassy)
                    battle.scene.pbHideOpponent
                  }
        KomoreiDojo1 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You must be a skilled Kenshi to have made it this far!")
                    pbMessage("Looks like the time has come for you to be fully tested by the best of the Komorei Clan!")
                    battle.pbAnimation(getID(PBMoves,:GRASSYTERRAIN),battle.battlers[1],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Grassy)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
        KomoreiDojo2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("If you want to reach Harumi, you'll have to go through me!")
                    pbMessage("Katana of Nature, Komorei Style! Blazing Sunlight!!")
                    battle.pbCommonAnimation("Sunny",nil,nil)
                    battle.scene.disappearBar
                    battle.pbStartWeather(battle.battlers[1],PBWeather::Sun,true,false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,2,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
        HarumiIntro = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("After everything, I believe I owe you a fair fight.")
                    battle.pbAnimation(getID(PBMoves,:GRASSYTERRAIN),battle.battlers[1],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Grassy)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[1],false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
        HarumiSun = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You truly are a talented Kenshi!")
                    pbMessage("Unforunately, you'll be going out in a blaze of glory!")
                    pbMessage("Katana of Nature, Komorei Style! Blazing Sunlight!!")
                    battle.pbCommonAnimation("Sunny",nil,nil)
                    battle.scene.disappearBar
                    battle.pbStartWeather(battle.battlers[1],PBWeather::Sun,true,false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
        TsukuShrineIntro = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Let's m-make this a fight worth remembering!")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
        TsukuShrineFinal = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("I told myself I wouldn't lose... I won't back down now!")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
        TsukuDuo1 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("I remember you having a shadow clone weakness!")
                    pbMessage("Here, a reminder of the time we stole your katana!")
                    pbMessage("Akui Clan Technique, Shadow Style! Clones of Darkness!!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:DOUBLETEAM),battle.battlers[0],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::EVASION,1,battle.battlers[1])
                    battle.battlers[3].pbRaiseStatStage(PBStats::EVASION,1,battle.battlers[3],false)
                    battle.scene.appearBar
                    pbMessage("And here, have some of these to add insult to injury!!")
                    pbMessage("Akui Clan Technique, Venom Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:POISONKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::POISON,1,nil)
                    battle.battlers[2].pbInflictStatus(PBStatuses::POISON,1,nil)
                    battle.scene.pbHideOpponent
                    battle.scene.appearBar
                    pbMessage("\\xn[Tsuku]\\rNow that we're f-finally fighting together, I'll do my best to m-make you proud!")
                    pbMessage("\\xn[Tsuku]\\rWe have to give it our all!")
                    pbMessage("\\xn[Tsuku]\\rKatana of Life, Konchu Style! Beetle Barrier!")
                    battle.pbAnimation(getID(PBMoves,:WIDEGUARD),battle.battlers[2],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.battlers[2].pbRaiseStatStage(PBStats::DEFENSE,3,battle.battlers[2])
                    battle.battlers[2].pbRaiseStatStage(PBStats::SPDEF,3,battle.battlers[2],false)
                    battle.battlers[0].pbRaiseStatStage(PBStats::DEFENSE,3,battle.battlers[0])
                    battle.battlers[0].pbRaiseStatStage(PBStats::SPDEF,3,battle.battlers[0],false)
                    battle.scene.appearBar
                    pbMessage("\\xn[Tsuku]\\rLet's show these Akui Grunts the power of our bonds!")
                    battle.scene.disappearBar
                  }
        TsukuDuo2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You pesky insects! It's time we crushed you!")
                    pbMessage("Akui Clan Technique, Fire Kunai!")
                    battle.scene.disappearBar
                    if !battle.battlers[1].fainted?
                      battle.pbAnimation(getID(PBMoves,:BURNKUNAI),battle.battlers[0],battle.battlers[1])
                    else
                      battle.pbAnimation(getID(PBMoves,:BURNKUNAI),battle.battlers[0],battle.battlers[3])
                    end
                    if !battle.battlers[0].fainted?
                      battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,nil)
                    end
                    if !battle.battlers[2].fainted?
                      battle.battlers[2].pbInflictStatus(PBStatuses::BURN,1,nil)
                    end
                    battle.scene.appearBar
                    pbMessage("Akui Clan Technique, Shadow Style! Muscle Control!!")
                    battle.scene.disappearBar
                    if !battle.battlers[1].fainted?
                      battle.pbAnimation(getID(PBMoves,:DRAGONDANCE),battle.battlers[1],battle.battlers[1])
                    else
                      battle.pbAnimation(getID(PBMoves,:DRAGONDANCE),battle.battlers[3],battle.battlers[3])
                    end
                    if !battle.battlers[1].fainted?
                      battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,2,battle.battlers[1],false)
                    end
                    if !battle.battlers[3].fainted?
                      battle.battlers[3].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[3])
                      battle.battlers[3].pbRaiseStatStage(PBStats::DEFENSE,2,battle.battlers[3],false)
                    end
                    battle.scene.appearBar
                    pbMessage("We'll squash you like the bugs you are!")
                    battle.scene.pbHideOpponent
                    battle.scene.appearBar
                    pbMessage("\\xn[Tsuku]\\rYou need to learn some r-respect for bugs!")
                    pbMessage("\\xn[Tsuku]\\rThey are some of the best Pokémon in the world! I'll never let you squash them!")
                    pbMessage("\\xn[Tsuku]\\rKatana of Life, Konchu Style! Dragonfly Dance!")
                    battle.scene.disappearBar
                    if !battle.battlers[2].fainted?
                      battle.pbAnimation(getID(PBMoves,:QUIVERDANCE),battle.battlers[2],battle.battlers[2])
                    else
                      battle.pbAnimation(getID(PBMoves,:QUIVERDANCE),battle.battlers[0],battle.battlers[0])
                    end
                    if !battle.battlers[2].fainted?
                      battle.battlers[2].pbRaiseStatStage(PBStats::SPATK,2,battle.battlers[2])
                      battle.battlers[2].pbRaiseStatStage(PBStats::SPDEF,2,battle.battlers[2],false)
                      battle.battlers[2].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[2],false)
                    end
                    if !battle.battlers[0].fainted?
                      battle.battlers[0].pbRaiseStatStage(PBStats::SPATK,2,battle.battlers[0])
                      battle.battlers[0].pbRaiseStatStage(PBStats::SPDEF,2,battle.battlers[0],false)
                      battle.battlers[0].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[0],false)
                    end
                    battle.scene.appearBar
                    pbMessage("\\xn[Tsuku]\\rCome on, \\PN! We'll teach them to respect b-bugs!")
                    battle.scene.disappearBar
                  }
        TsukuPG1 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[Tsuku]\\rIt feels like just the other day we both started our journies as Kenshi!")
                    pbMessage("\\xn[Tsuku]\\rLook at far we've come now!")
                    pbMessage("\\xn[Tsuku]\\rWe both should keep getting stronger, to protect Aisho together!")
                    pbMessage("\\xn[Tsuku]\\rKatana of Life, Konchu Style! Beetle Barrier!")
                    battle.pbAnimation(getID(PBMoves,:WIDEGUARD),battle.battlers[1],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,3,battle.battlers[2])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,3,battle.battlers[2],false)
                    battle.scene.appearBar
                    pbMessage("\\xn[Tsuku]\\rLet's see if you have what it takes to overcome my new team, \\PN!")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                  }
          TsukuPG2 = Proc.new{|battle|
                      battle.scene.appearBar
                      battle.scene.pbShowOpponent(0)
                      pbMessage("\\xn[Tsuku]\\rDang, I'm already down to my last Pokémon...")
                      pbMessage("\\xn[Tsuku]\\rNow's the time for me to give it me all!")
                      pbMessage("\\xn[Tsuku]\\rHere we c-come, \\PN!!")
                      pbMessage("\\xn[Tsuku]\\rKatana of Life, Konchu Style! Dragonfly Dance!")
                      battle.scene.disappearBar
                      battle.pbAnimation(getID(PBMoves,:QUIVERDANCE),battle.battlers[1],battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,2,battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,2,battle.battlers[1],false)
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1],false)
                      battle.scene.appearBar
                      pbMessage("\\xn[Tsuku]\\rI'll never give up! Just like y-you taught me!")
                      pbMessage("\\xn[Tsuku]\\rI'm stronger now, t-thanks to our bond!")
                      battle.scene.disappearBar
                      battle.scene.pbHideOpponent
                    }
      # Iwa Clan intros
      # Stealth rocks for another one?
      Iwa1 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("The Iwa Clan mean business!")
                    pbMessage("We may be small, but our spirit is unbreakable!")
                    pbMessage("I draw my power from the earth!")
                    pbMessage("Katana of Earth, Iwa Style! Shifting Sands!")
                    battle.pbCommonAnimation("Sandstorm",nil,nil)
                    battle.scene.disappearBar
                    battle.pbStartWeather(battle.battlers[1],PBWeather::Sandstorm,true,false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,2,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      # Yuki Clan intros
      Yuki1 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Even though we're a minor clan, you should take us Yuki members seriously!")
                    pbMessage("We're well on our way to forming our own dojo soon!")
                    pbMessage("Here, have a taste of what we can do!")
                    pbMessage("Katana of Ice, Yuki Style! Freezing Breath!")
                    battle.pbAnimation(getID(PBMoves,:FROSTBREATH),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.battlers[0].pbInflictStatus(PBStatuses::FROZEN,1,nil)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      Yuki2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("The Yuki Clan controls the frozen domain!")
                    pbMessage("Katana of Ice, Yuki Style! Freezing Breath!")
                    battle.pbAnimation(getID(PBMoves,:FROSTBREATH),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.battlers[0].pbInflictStatus(PBStatuses::FROZEN,1,nil)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      Yuki3 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("I hope you'll prove to be a worthy opponent!")
                    pbMessage("Not many trainers can overcome the ice-cold Yuki Clan in battle!")
                    pbMessage("Katana of Ice, Yuki Style! Freezing Breath!")
                    battle.pbAnimation(getID(PBMoves,:FROSTBREATH),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.battlers[0].pbInflictStatus(PBStatuses::FROZEN,1,nil)
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,1,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
      Yuki4 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Let us have a good duel!")
                    pbMessage("Katana of Ice, Yuki Style! Freezing Breath!")
                    battle.pbAnimation(getID(PBMoves,:FROSTBREATH),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.battlers[0].pbInflictStatus(PBStatuses::FROZEN,1,nil)
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,1,battle.battlers[1],false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
      # Nensho intros
      Nensho1 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("The way of the Nensho Clan is blazing through our opponents!")
                    pbMessage("Katana of Fire, Nensho Style! Fire Vortex!")
                    battle.pbAnimation(getID(PBMoves,:FIRESPIN),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.battlers[0].effects[PBEffects::TrappingMove] = getID(PBMoves,:FIRESPIN)
                    battle.battlers[0].effects[PBEffects::Trapping] = 5
                    battle.battlers[0].effects[PBEffects::TrappingUser] = 1
                    battle.pbDisplay(_INTL("{1} was trapped in a fiery vortex!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      Nensho2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("The Nensho Clan is unstoppable! The sunlight only makes us stronger!")
                    pbMessage("Katana of Fire, Nensho Style! Sunlight Beams!")
                    battle.pbCommonAnimation("Sunny",nil,nil)
                    battle.scene.disappearBar
                    battle.pbStartWeather(battle.battlers[1],PBWeather::Sun,true,false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      Nensho3 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Nensho Clan! Hiyaaaah!")
                    pbMessage("Katana of Fire, Nensho Style! Fire Vortex!")
                    battle.pbAnimation(getID(PBMoves,:FIRESPIN),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.battlers[0].effects[PBEffects::TrappingMove] = getID(PBMoves,:FIRESPIN)
                    battle.battlers[0].effects[PBEffects::Trapping] = 5
                    battle.battlers[0].effects[PBEffects::TrappingUser] = 1
                    battle.pbDisplay(_INTL("{1} was trapped in a fiery vortex!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
        Nensho4 = Proc.new{|battle|
                      battle.scene.appearBar
                      battle.scene.pbShowOpponent(0)
                      pbMessage("The Nensho Clan is the strongest clan there is!")
                      pbMessage("Allow me to show you why we're the best clan!")
                      pbMessage("Katana of Fire, Nensho Style! Flame Breath!")
                      battle.pbAnimation(getID(PBMoves,:FLAMETHROWER),battle.battlers[1],battle.battlers[0])
                      battle.scene.disappearBar
                      battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,nil)
                      battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                      battle.scene.pbHideOpponent
                    }
        Nensho5 = Proc.new{|battle|
                      battle.scene.appearBar
                      battle.scene.pbShowOpponent(0)
                      pbMessage("The souls of Nensho Clan members burn as bright as the sun!")
                      pbMessage("Katana of Fire, Nensho Style! Sunlight Beams!")
                      battle.pbCommonAnimation("Sunny",nil,nil)
                      battle.scene.disappearBar
                      battle.pbStartWeather(battle.battlers[1],PBWeather::Sun,true,false)
                      battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[1],false)
                      battle.scene.pbHideOpponent
                    }
        Nensho6 = Proc.new{|battle|
                      battle.scene.appearBar
                      battle.scene.pbShowOpponent(0)
                      pbMessage("You're on the final stretch! Don't burn out on me now!")
                      pbMessage("Katana of Fire, Nensho Style! Breath of Flames!")
                      battle.pbAnimation(getID(PBMoves,:FLAMETHROWER),battle.battlers[1],battle.battlers[0])
                      battle.scene.disappearBar
                      battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,nil)
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1])
                      battle.scene.pbHideOpponent
                    }
        Nori1 = Proc.new{|battle|
                      battle.scene.appearBar
                      battle.scene.pbShowOpponent(0)
                      pbMessage("\\xn[Nori]\\bHahaha! We finally face each other in battle!")
                      pbMessage("\\xn[Nori]\\bI've been looking forward to this, \\PN!")
                      pbMessage("\\xn[Nori]\\bJust so you know, I'll be giving this battle my all.")
                      pbMessage("\\xn[Nori]\\bI expect you to do the same! Now, it's time to show you the true power of the Nensho Clan!")
                      pbMessage("\\xn[Nori]\\bKatana of Fire, Nensho Style! Breath of Flames!")
                      battle.pbAnimation(getID(PBMoves,:FLAMETHROWER),battle.battlers[1],battle.battlers[0])
                      battle.scene.disappearBar
                      battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,nil)
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1],false)
                      battle.scene.appearBar
                      pbMessage("\\xn[Nori]\\bKatana of Fire, Nensho Style! Sunlight Beams!")
                      battle.pbCommonAnimation("Sunny",nil,nil)
                      battle.scene.disappearBar
                      battle.pbStartWeather(battle.battlers[1],PBWeather::Sun,true,false)
                      battle.scene.appearBar
                      pbMessage("\\xn[Nori]\\bCome at me with all you've got, \\PN! Hiyaaah!")
                      battle.scene.disappearBar
                      battle.scene.pbHideOpponent
                    }
          NoriLast = Proc.new{|battle|
                        battle.scene.appearBar
                        battle.scene.pbShowOpponent(0)
                        pbMessage("\\xn[Nori]\\bHahaha! This is so much fun!")
                        pbMessage("\\xn[Nori]\\bYou are an excellent Kenshi, \\PN!")
                        pbMessage("\\xn[Nori]\\bYou've pushed me to my limits...")
                        pbMessage("\\xn[Nori]\\bBut the battle isn't over yet! Now it's time for me to get serious!")
                        pbMessage("\\xn[Nori]\\bSecret Technique! Mountainous Roar!")
                        battle.pbAnimation(getID(PBMoves,:HOWL),battle.battlers[1],battle.battlers[0])
                        battle.scene.disappearBar
                        battle.battlers[0].pbLowerStatStage(PBStats::SPEED,2,battle.battlers[0])
                        battle.battlers[0].pbLowerStatStage(PBStats::DEFENSE,2,battle.battlers[0],false)
                        battle.battlers[0].pbLowerStatStage(PBStats::SPDEF,2,battle.battlers[0],false)
                        battle.scene.appearBar
                        pbMessage("\\xn[Nori]\\bKatana of Fire, Nensho Style! Flame Breath!")
                        battle.pbAnimation(getID(PBMoves,:FLAMETHROWER),battle.battlers[1],battle.battlers[0])
                        battle.scene.disappearBar
                        battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,nil)
                        battle.scene.appearBar
                        pbMessage("\\xn[Nori]\\bLet's finish this duel in a blaze of glory, \\PN! Yaaah!")
                        battle.scene.disappearBar
                        battle.scene.pbHideOpponent
                      }
      # Shimizu Intros
      Shimizu1 = Proc.new{|battle|
                  battle.scene.appearBar
                  battle.scene.pbShowOpponent(0)
                  pbMessage("You cannot overcome the calmness of the Shimizu Clan.")
                  pbMessage("Katana of Water, Shimizu Style! Torrential Downpour!")
                  battle.scene.disappearBar
                  battle.pbCommonAnimation("Rain",battle.battlers[0],nil)
                  battle.pbStartWeather(battle.battlers[1],PBWeather::Rain,true,false)
                  battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1])
                  battle.scene.pbHideOpponent
                }
        Shimizu2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You have to learn to move with the motion of the ocean!")
                    pbMessage("Katana of Water, Shimizu Style! Torrential Downpour!")
                    battle.scene.disappearBar
                    battle.pbCommonAnimation("Rain",battle.battlers[0],nil)
                    battle.pbStartWeather(battle.battlers[1],PBWeather::Rain,true,false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
        Shimizu3 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You better watch out!")
                    pbMessage("I'm making waves over here!")
                    pbMessage("Katana of Water, Shimizu Style! Torrential Downpour!")
                    battle.scene.disappearBar
                    battle.pbCommonAnimation("Rain",battle.battlers[0],nil)
                    battle.pbStartWeather(battle.battlers[1],PBWeather::Rain,true,false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
        Shimizu4 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Watch this!")
                    pbMessage("Not only can the Shimizu Clan make it rain...")
                    pbMessage("We can also manipulate the temperature of the rainwater!")
                    pbMessage("Katana of Water, Shimizu Style! Frigid Hail!")
                    battle.scene.disappearBar
                    battle.pbCommonAnimation("Hail",battle.battlers[0],nil)
                    battle.pbStartWeather(battle.battlers[1],PBWeather::Hail,true,false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,2,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
        Shimizu5 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Chris and Eddie have got nothing on my skills!")
                    pbMessage("Katana of Water, Shimizu Style! Raging Whirlpool!")
                    battle.pbAnimation(getID(PBMoves,:WHIRLPOOL),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.battlers[0].effects[PBEffects::TrappingMove] = getID(PBMoves,:WHIRLPOOL)
                    battle.battlers[0].effects[PBEffects::Trapping] = 5
                    battle.battlers[0].effects[PBEffects::TrappingUser] = 1
                    battle.pbDisplay(_INTL("{1} was trapped in a whirlpool!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
        Shimizu6 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Before you can get to Chikyu Village, you'll have to go through me!")
                    pbMessage("Shimizu Clan can also turn the terrain misty, to protect our Pokémon!")
                    pbMessage("Katana of Water, Shimizu Style! Misty Terrain!")
                    battle.pbAnimation(getID(PBMoves,:MISTYTERRAIN),battle.battlers[1],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Misty)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,1,battle.battlers[1],false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
          Shimizu7 = Proc.new{|battle|
                        battle.scene.appearBar
                        battle.scene.pbShowOpponent(0)
                        pbMessage("Where do you think you're going?")
                        pbMessage("Katana of Water, Shimizu Style! Raging Whirlpool!")
                        battle.pbAnimation(getID(PBMoves,:WHIRLPOOL),battle.battlers[1],battle.battlers[0])
                        battle.scene.disappearBar
                        battle.battlers[0].effects[PBEffects::TrappingMove] = getID(PBMoves,:WHIRLPOOL)
                        battle.battlers[0].effects[PBEffects::Trapping] = 5
                        battle.battlers[0].effects[PBEffects::TrappingUser] = 1
                        battle.pbDisplay(_INTL("{1} was trapped in a whirlpool!",battle.battlers[0].pbThis(true)))
                        battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                        battle.scene.pbHideOpponent
                      }
          Shimizu8 = Proc.new{|battle|
                        battle.scene.appearBar
                        battle.scene.pbShowOpponent(0)
                        pbMessage("The Shimizu Clan draw their strength from the ocean!")
                        pbMessage("It is the source of all life... It heals us with its love!")
                        pbMessage("Katana of Water, Shimizu Style! Healing Ring!")
                        battle.pbAnimation(getID(PBMoves,:AQUARING),battle.battlers[1],battle.battlers[0])
                        battle.scene.disappearBar
                        battle.battlers[1].effects[PBEffects::AquaRing] = true
                        battle.pbDisplay(_INTL("{1} was surrounded with a veil of water!",battle.battlers[1].name))
                        battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,2,battle.battlers[1])
                        battle.scene.pbHideOpponent
                      }
        Shimizu9 = Proc.new{|battle|
                      battle.scene.appearBar
                      battle.scene.pbShowOpponent(0)
                      pbMessage("It's time for me to test your skills!")
                      pbMessage("Katana of Water, Shimizu Style! Misty Terrain!")
                      battle.pbAnimation(getID(PBMoves,:MISTYTERRAIN),battle.battlers[1],battle.battlers[1])
                      battle.scene.disappearBar
                      battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Misty)
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,2,battle.battlers[1],false)
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,2,battle.battlers[1],false)
                      battle.scene.pbHideOpponent
                    }
        Shimizu10 = Proc.new{|battle|
                      battle.scene.appearBar
                      battle.scene.pbShowOpponent(0)
                      pbMessage("Show me your full potential, and I'll show you mine!")
                      pbMessage("Katana of Water, Shimizu Style! Misty Terrain!")
                      battle.pbAnimation(getID(PBMoves,:MISTYTERRAIN),battle.battlers[1],battle.battlers[1])
                      battle.scene.disappearBar
                      battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Misty)
                      battle.scene.appearBar
                      pbMessage("Katana of Water, Shimizu Style! Healing Ring!")
                      battle.pbAnimation(getID(PBMoves,:AQUARING),battle.battlers[1],battle.battlers[0])
                      battle.scene.disappearBar
                      battle.battlers[1].effects[PBEffects::AquaRing] = true
                      battle.pbDisplay(_INTL("{1} was surrounded with a veil of water!",battle.battlers[1].name))
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,2,battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1],false)
                      battle.scene.appearBar
                      pbMessage("Come at me!")
                      battle.scene.disappearBar
                      battle.scene.pbHideOpponent
                    }
        Shimizu11 = Proc.new{|battle|
                      battle.scene.appearBar
                      battle.scene.pbShowOpponent(0)
                      pbMessage("Prove to me that you are worthy of facing Mai, the leader of the Shimizu Clan!")
                      pbMessage("Katana of Water, Shimizu Style! Torrential Downpour!")
                      battle.scene.disappearBar
                      battle.pbCommonAnimation("Rain",battle.battlers[0],nil)
                      battle.pbStartWeather(battle.battlers[1],PBWeather::Rain,true,false)
                      battle.scene.appearBar
                      pbMessage("Katana of Water, Shimizu Style! Raging Whirlpool!")
                      battle.pbAnimation(getID(PBMoves,:WHIRLPOOL),battle.battlers[1],battle.battlers[0])
                      battle.scene.disappearBar
                      battle.battlers[0].effects[PBEffects::TrappingMove] = getID(PBMoves,:WHIRLPOOL)
                      battle.battlers[0].effects[PBEffects::Trapping] = 5
                      battle.battlers[0].effects[PBEffects::TrappingUser] = 1
                      battle.pbDisplay(_INTL("{1} was trapped in a whirlpool!",battle.battlers[0].name))
                      battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,2,battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,2,battle.battlers[1],false)
                      battle.scene.appearBar
                      pbMessage("Now, the real test begins!")
                      battle.scene.disappearBar
                      battle.scene.pbHideOpponent
                    }
        Mai1 = Proc.new{|battle|
                      battle.scene.appearBar
                      battle.scene.pbShowOpponent(0)
                      pbMessage("\\xn[Mai]\\rI'm glad to have you in my dojo, \\PN.")
                      pbMessage("\\xn[Mai]\\rI heard about how you defeated Harumi and Nori.")
                      pbMessage("\\xn[Mai]\\rThough they are strong clan leaders in their own right...")
                      pbMessage("\\xn[Mai]\\rI will show you why I am considered the strongest of the three.")
                      pbMessage("\\xn[Mai]\\rKatana of Water, Shimizu Style! Torrential Downpour!")
                      battle.scene.disappearBar
                      battle.pbCommonAnimation("Rain",battle.battlers[0],nil)
                      battle.pbStartWeather(battle.battlers[1],PBWeather::Rain,true,false)
                      battle.scene.appearBar
                      pbMessage("\\xn[Mai]\\rKatana of Water, Shimizu Style! Healing Ring!")
                      battle.pbAnimation(getID(PBMoves,:AQUARING),battle.battlers[1],battle.battlers[0])
                      battle.scene.disappearBar
                      battle.battlers[1].effects[PBEffects::AquaRing] = true
                      battle.pbDisplay(_INTL("Mai surrounded {1} with a veil of water!",battle.battlers[1].name))
                      battle.scene.appearBar
                      pbMessage("\\xn[Mai]\\rAnd now for my signature move!")
                      pbMessage("\\xn[Mai]\\rKatana of Water, Shimizu Style! Signature Technique! Water Meditation!")
                      battle.pbAnimation(getID(PBMoves,:COSMICPOWER),battle.battlers[1],battle.battlers[1])
                      battle.scene.disappearBar
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,1,battle.battlers[1],false)
                      battle.scene.appearBar
                      pbMessage("\\xn[Mai]\\rIf you think you can defeat me, go ahead and try!")
                      battle.scene.disappearBar
                      battle.scene.pbHideOpponent
                    }
      Mai2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[Mai]\\rHmm... No wonder you were able to handle the Akui Clan!")
                    pbMessage("\\xn[Mai]\\rYou bring great honor to the Masayoshi name.")
                    pbMessage("\\xn[Mai]\\rNow, it looks like I need to get serious, before you sweep me away!")
                    pbMessage("\\xn[Mai]\\rKatana of Water, Shimizu Style! Torrential Downpour!")
                    battle.scene.disappearBar
                    battle.pbCommonAnimation("Rain",battle.battlers[0],nil)
                    battle.pbStartWeather(battle.battlers[1],PBWeather::Rain,true,false)
                    battle.scene.appearBar
                    pbMessage("\\xn[Mai]\\rKatana of Water, Shimizu Style! Healing Ring!")
                    battle.pbAnimation(getID(PBMoves,:AQUARING),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.battlers[1].effects[PBEffects::AquaRing] = true
                    battle.pbDisplay(_INTL("Mai surrounded {1} with a veil of water!",battle.battlers[1].name))
                    battle.scene.appearBar
                    pbMessage("\\xn[Mai]\\rKatana of Water, Shimizu Style! Misty Terrain!")
                    battle.pbAnimation(getID(PBMoves,:MISTYTERRAIN),battle.battlers[1],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Misty)
                    battle.scene.appearBar
                    pbMessage("\\xn[Mai]\\rKatana of Water, Shimizu Style! Signature Technique! Water Meditation!")
                    battle.pbAnimation(getID(PBMoves,:COSMICPOWER),battle.battlers[1],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,2,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,2,battle.battlers[1],false)
                    battle.scene.appearBar
                    pbMessage("\\xn[Mai]\\rLet's see if you can keep up with my waterfall of Shimizu techniques!")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                  }
      # Rival intros
      RivalFirstIntro = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[\\v[26]]\\pogPrepare to face the full force of my Pokémon!")
                    pbMessage("\\xn[\\v[26]]\\pogHiyaaah! Signature Technique! Hashimoto Might!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SWORDSDANCE),battle.battlers[1],battle.battlers[0])
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      RivalBurn = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[\\v[26]]\\pogWe meet in battle again, \\PN!")
                    pbMessage("\\xn[\\v[26]]\\pogI've grown a lot since our last battle, so don't underestimate me!")
                    pbMessage("\\xn[\\v[26]]\\pogNow, prepare to be burned to ashes!")
                    battle.scene.disappearBar
                    #if battle.battlers[0].pbCanInflictStatus?(PBStatuses::BURN,battle.battlers[1],false)
                    battle.pbAnimation(getID(PBMoves,:EMBER),battle.battlers[1],battle.battlers[0])
                    battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,nil)
                    battle.scene.appearBar
                    pbMessage("\\xn[\\v[26]]\\pogHiyaaah! Signature Technique! Hashimoto Might!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SWORDSDANCE),battle.battlers[1],battle.battlers[0])
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      RivalLast = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[\\v[26]]\\pogLooks like it's time to get serious!")
                    pbMessage("\\xn[\\v[26]]\\pogGo #{battle.battlers[1].pokemon.speciesName}, unleash your burning passion!")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      RivalDuel2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[\\v[26]]\\pogI've grown a lot since our last battle, so don't underestimate me!")
                    pbMessage("\\xn[\\v[26]]\\pogNow, take a look at the new Katana Technique I learned!")
                    pbMessage("\\xn[\\v[26]]\\pogKatana of Fire, Nensho Style! Fire Vortex!")
                    battle.pbAnimation(getID(PBMoves,:FIRESPIN),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.battlers[0].effects[PBEffects::TrappingMove] = getID(PBMoves,:FIRESPIN)
                    battle.battlers[0].effects[PBEffects::Trapping] = 7
                    battle.battlers[0].effects[PBEffects::TrappingUser] = 1
                    battle.pbDisplay(_INTL("{1} was trapped in a fiery vortex!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
      RivalDuel2Last = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[\\v[26]]\\pogLooks like it's time to get serious!")
                    pbMessage("\\xn[\\v[26]]\\pogGo #{battle.battlers[1].pokemon.speciesName}, unleash your burning passion!")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1],false)
                    battle.pbCommonAnimation("Sunny",nil,nil)
                    battle.pbStartWeather(battle.battlers[1],PBWeather::Sun,true,false)
                    battle.scene.pbHideOpponent
                  }
      RivalPG1 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[\\v[26]]\\pogI've been waiting for this day, \\PN!")
                    pbMessage("\\xn[\\v[26]]\\pogTo face you again... a battle against the Hero of Aisho!")
                    pbMessage("\\xn[\\v[26]]\\pogI'm going to give it my all, to open the heart of my Darmanitan!")
                    pbMessage("\\xn[\\v[26]]\\pogLet's go! Hiyaaaah!")
                    pbMessage("\\xn[\\v[26]]\\pogKatana of Fire, Nensho Style! Breath of Flames!")
                    battle.pbAnimation(getID(PBMoves,:FLAMETHROWER),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,nil)
                    battle.scene.appearBar
                    pbMessage("\\xn[\\v[26]]\\pogKatana of Fire, Nensho Style! Sunlight Beams!")
                    battle.pbCommonAnimation("Sunny",nil,nil)
                    battle.scene.disappearBar
                    battle.pbStartWeather(battle.battlers[1],PBWeather::Sun,true,false)
                    battle.scene.appearBar
                    pbMessage("\\xn[\\v[26]]\\pogCome at me with all you've got, \\PN! Hiyaaah!")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,2,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                }
      RivalPG2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[\\v[26]]\\pogWe're so close \\PN! Keep it up!")
                    pbMessage("\\xn[\\v[26]]\\pogGo #{battle.battlers[1].pokemon.speciesName}, give it all you got in this last battle!")
                    pbMessage("\\xn[\\v[26]]\\pogHiyaaah! Hashimoto Might!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SWORDSDANCE),battle.battlers[1],battle.battlers[0])
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,2,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
      Ryo1 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[Ryo]\\bI've been looking forward to testing your skills in battle, \\PN!")
                    pbMessage("\\xn[Ryo]\\bYou may be the new master of the Katana of Light, but I can still do this!")
                    pbMessage("\\xn[Ryo]\\bKatana of Illumination, Masayoshi Style! Brilliant Barrier!")
                    battle.pbAnimation(getID(PBMoves,:LIGHTSCREEN),battle.battlers[1],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.battlers[1].pbOwnSide.effects[PBEffects::LightScreen] = 8
                    battle.pbDisplay(_INTL("Ryo created a wall of light in front of {1}!",battle.battlers[1].name))
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,3,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,3,battle.battlers[1],false)
                    battle.scene.appearBar
                    pbMessage("\\xn[Ryo]\\bLet's see the true strength of the Hero of Aisho!")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                }
      Ryo2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[Ryo]\\bYou really are talented, \\PN!")
                    pbMessage("\\xn[Ryo]\\bYou make me so proud as a father.")
                    pbMessage("\\xn[Ryo]\\bI hope you know that'll always love you.")
                    pbMessage("\\xn[Ryo]\\bNow, witness my ultimate technique!")
                    pbMessage("\\xn[Ryo]\\bKatana of Illumination, Masayoshi Style! Blinding Radiance!")
                    battle.pbAnimation(getID(PBMoves,:FLASH),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.battlers[0].pbLowerStatStage(PBStats::ACCURACY,2,battle.battlers[0])
                    pbMessage("\\xn[Ryo]\\bKatana of Illumination, Masayoshi Style! Brilliant Barrier!")
                    battle.pbAnimation(getID(PBMoves,:LIGHTSCREEN),battle.battlers[1],battle.battlers[1])
                    battle.battlers[1].pbOwnSide.effects[PBEffects::LightScreen] = 8
                    battle.pbDisplay(_INTL("Ryo created a wall of light in front of {1}!",battle.battlers[1].name))
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,3,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,3,battle.battlers[1],false)
                    battle.scene.appearBar
                    pbMessage("\\xn[Ryo]\\bLet's end this \\PN! Show me that you have what it takes to become the Royal Samurai!")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                }
      TsukuIntro = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[Tsuku]\\rAlright! Time for you to learn how strong b-bug Pokémon can really be!")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                  }
      TsukuLast = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[Tsuku]\\rW-wah! This isn't looking good!")
                    pbMessage("\\xn[Tsuku]\\rIt's time for defensive measures...")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,2,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,2,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
      KayokoIntro = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[Kayoko]\\rPrepare yourself. I'll be trying my best.")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                  }
      KayokoLast = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[Kayoko]\\rI can't let my family down...")
                    pbMessage("\\xn[Kayoko]\\rTime to show you my true inner strength!")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
      KayokoB2Intro = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[Kayoko]\\rPrepare yourself, \\PN. I'll be going all out.")
                    pbMessage("\\xn[Kayoko]\\rSignature Technique! Focused Mind!")
                    battle.pbAnimation(getID(PBMoves,:CALMMIND),battle.battlers[1],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,2,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,2,battle.battlers[1],false)
                    battle.scene.appearBar
                    pbMessage("\\xn[Kayoko]\\rPlease, show me your true strength.")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                  }
      KayokoB2Last = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[Kayoko]\\rIt's shocking to me how powerful you've become, \\PN.")
                    pbMessage("\\xn[Kayoko]\\rHowever, as you can see, I've done some growing as well!")
                    pbMessage("\\xn[Kayoko]\\rSignature Technique! Shocking Terrain!")
                    battle.pbAnimation(getID(PBMoves,:ELECTRICTERRAIN),battle.battlers[1],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Electric)
                    battle.scene.appearBar
                    pbMessage("\\xn[Kayoko]\\rSignature Technique! Focused Mind!")
                    battle.pbAnimation(getID(PBMoves,:CALMMIND),battle.battlers[1],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,2,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,2,battle.battlers[1],false)
                    battle.scene.appearBar
                    pbMessage("\\xn[Kayoko]\\rLet's see if you truly have what it takes to defeat me.")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                  }
      # Akui intros, make them cheat a lot!
      ShadowIntroToxic = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("The Akui Clan never falters! Take this!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:TOXICSPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Toxic spikes were scattered all around the battlefield!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::ToxicSpikes] = 2
                    battle.scene.pbHideOpponent
                  }
      ShadowIntroToxic2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Stay out of our Akui Library!")
                    pbMessage("The secrets of our clan are not meant for outsiders!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:TOXICSPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Toxic spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::ToxicSpikes] = 2
                    battle.scene.appearBar
                    pbMessage("Akui Clan Technique, Shadow Style! Clones of Darkness!!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:DOUBLETEAM),battle.battlers[0],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::EVASION,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
        ShadowIntroToxic3 = Proc.new{|battle|
                      battle.scene.appearBar
                      battle.scene.pbShowOpponent(0)
                      pbMessage("The Katana of Light belongs to the Akui Clan now!")
                      pbMessage("Get lost, and never come back, you foolish Kenshi!")
                      battle.scene.disappearBar
                      battle.pbAnimation(getID(PBMoves,:TOXICSPIKES),battle.battlers[1],battle.battlers[0])
                      battle.pbDisplay(_INTL("Toxic spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                      battle.battlers[1].pbOpposingSide.effects[PBEffects::ToxicSpikes] = 2
                      battle.scene.appearBar
                      pbMessage("Akui Clan Technique, Shadow Style! Clones of Darkness! Ultimate Evasion!")
                      battle.scene.disappearBar
                      battle.pbAnimation(getID(PBMoves,:DOUBLETEAM),battle.battlers[0],battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::EVASION,2,battle.battlers[1])
                      battle.scene.pbHideOpponent
                    }
      ShadowIntroToxic4 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You must be stopped... And I'll be the one to stop you!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:TOXICSPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Toxic spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::ToxicSpikes] = 2
                    battle.scene.appearBar
                    pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility!!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:AGILITY),battle.battlers[0],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      ShadowIntroSpikes = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Let's make this battle interesting, shall we?")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::Spikes] = 3
                    battle.scene.pbHideOpponent
                  }
      ShadowIntroSpikes2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("I'm guarding this key with my life! Stay away, you disgusting kenshi!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::Spikes] = 3
                    battle.scene.appearBar
                    pbMessage("Akui Clan Technique, Icicle Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:ICICLESPEAR),battle.battlers[1],battle.battlers[0])
                    battle.battlers[0].pbInflictStatus(PBStatuses::FROZEN,1,"Your Pokémon was frozen solid by the ice kunai!")
                    battle.scene.pbHideOpponent
                  }
      ShadowIntroSpikes3 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Stay out of my basement, you villain!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::Spikes] = 3
                    battle.scene.appearBar
                    pbMessage("Akui Clan Technique, Shock Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SHOCKKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::PARALYSIS,1,"Your Pokémon was paralyzed by the shock kunai!")
                    battle.scene.pbHideOpponent
                  }
      ShadowIntroSpikes4 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Get out of here! We can't let you come and go as you please!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::Spikes] = 3
                    battle.scene.appearBar
                    pbMessage("Akui Clan Technique, Flame Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:BURNKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,"Your Pokémon was burned by the flame kunai!")
                    battle.scene.pbHideOpponent
                  }
      ShadowEvasion = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Looks like it's time to get serious!")
                    pbMessage("Akui Clan Technique, Shadow Style! Clones of Darkness!!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:DOUBLETEAM),battle.battlers[0],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::EVASION,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      ShadowEvasion2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Invaders must be punished!")
                    pbMessage("Akui Clan Technique, Shadow Style! Clones of Darkness!!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:DOUBLETEAM),battle.battlers[0],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::EVASION,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      ShadowEvasion3 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You need to be eliminated!")
                    pbMessage("Akui Clan Technique, Shadow Style! Clones of Darkness!!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:DOUBLETEAM),battle.battlers[0],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::EVASION,1,battle.battlers[1])
                    battle.scene.appearBar
                    pbMessage("Akui Clan Technique, Shock Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SHOCKKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::PARALYSIS,1,"Your Pokémon was paralyzed by the shock kunai!")
                    battle.scene.pbHideOpponent
                  }
      ShadowEvasion4 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Hagane City is ours! Give up now!")
                    pbMessage("Akui Clan Technique, Shadow Style! Clones of Darkness!!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:DOUBLETEAM),battle.battlers[0],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::EVASION,1,battle.battlers[1])
                    battle.scene.appearBar
                    pbMessage("Akui Clan Technique, Flame Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:BURNKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,"Your Pokémon was burned by the flame kunai!")
                    battle.scene.pbHideOpponent
                  }
      ShadowSpeed = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You'll never be able to catch up to us!")
                    pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility!!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:AGILITY),battle.battlers[0],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      ShadowSpeed2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Nobody sneaks up behind me and lives to the tell the tale!")
                    pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility!!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:AGILITY),battle.battlers[0],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1])
                    battle.scene.appearBar
                    pbMessage("Akui Clan Technique, Shock Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SHOCKKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::PARALYSIS,1,"Your Pokémon was paralyzed by the shock kunai!")
                    battle.scene.pbHideOpponent
                  }
      ShadowSpeed3 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Outsiders must be eliminated! This is the way of the Akui Clan!")
                    pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility!!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:AGILITY),battle.battlers[0],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1])
                    battle.scene.appearBar
                    pbMessage("Akui Clan Technique, Icicle Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:ICICLESPEAR),battle.battlers[1],battle.battlers[0])
                    battle.battlers[0].pbInflictStatus(PBStatuses::FROZEN,1,"Your Pokémon was frozen solid by the ice kunai!")
                    battle.scene.pbHideOpponent
                  }
      ShadowSpeed4 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You will never defeat the Akui Clan!")
                    pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility!!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:AGILITY),battle.battlers[0],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1])
                    battle.pbAnimation(getID(PBMoves,:SPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::Spikes] = 3
                    battle.scene.pbHideOpponent
                  }
      ShadowPower = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("My strength is unmatched!")
                    pbMessage("Akui Clan Technique, Shadow Style! Muscle Control!!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:DRAGONDANCE),battle.battlers[1],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,2,battle.battlers[1],false)
                    battle.pbAnimation(getID(PBMoves,:SPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::Spikes] = 3
                    battle.scene.pbHideOpponent
                  }
      ShadowPower2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("It's time for our rematch! I've been working on my strength!")
                    pbMessage("Akui Clan Technique, Shadow Style! Muscle Control!!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:DRAGONDANCE),battle.battlers[1],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,3,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,3,battle.battlers[1],false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,3,battle.battlers[1],false)
                    battle.pbAnimation(getID(PBMoves,:TOXICSPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Toxic spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::ToxicSpikes] = 2
                    battle.scene.pbHideOpponent
                  }
      ShadowFreeze = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Prepare to be frozen, foolish Kenshi!")
                    pbMessage("Akui Clan Technique, Icicle Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:ICICLESPEAR),battle.battlers[1],battle.battlers[0])
                    battle.battlers[0].pbInflictStatus(PBStatuses::FROZEN,1,"Your Pokémon was frozen solid by the ice kunai!")
                    battle.scene.pbHideOpponent
                  }
      ShadowFreeze2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("To be in Akui Clan, you must have a heart as cold as ice!")
                    pbMessage("Luckily for me, I also happen to have kunai that are as cold as ice!")
                    pbMessage("Akui Clan Technique, Icicle Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:ICICLESPEAR),battle.battlers[1],battle.battlers[0])
                    battle.battlers[0].pbInflictStatus(PBStatuses::FROZEN,1,"Your Pokémon was frozen solid by the ice kunai!")
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      ShadowShock = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Prepare to be shocked, foolish Kenshi!")
                    pbMessage("Akui Clan Technique, Shock Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SHOCKKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::PARALYSIS,1,"Your Pokémon was paralyzed by the shock kunai!")
                    battle.scene.pbHideOpponent
                  }
      ShadowBurn = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("If you try to mess with the Akui Clan, you're bound to get burned!")
                    pbMessage("Akui Clan Technique, Flame Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:BURNKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,"Your Pokémon was burned by the flame kunai!")
                    battle.scene.pbHideOpponent
                  }
      ShadowPoison = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("We Akui Clan coat all our kunai with a deadly poison.")
                    pbMessage("Here, I'll give your Pokémon a taste!")
                    pbMessage("Akui Clan Technique, Venom Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:POISONKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::POISON,1,"Your Pokémon was poisoned by the venom kunai!")
                    battle.scene.pbHideOpponent
                  }
      ShadowSleep = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You're looking a little tired.")
                    pbMessage("How about your Pokémon get some rest!")
                    pbMessage("Akui Clan Technique, Tranquilizer Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SLEEPKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::SLEEP,rand(2,4),"Your Pokémon was put to sleep by the tranquilizer kunai!")
                    battle.scene.pbHideOpponent
                  }
      ShadowSleep2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("I'll be the one to put a stop to your reign of terror!")
                    pbMessage("The Akui Clan is counting on me to succeed! I can do this!")
                    pbMessage("Akui Clan Technique, Tranquilizer Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SLEEPKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::SLEEP,rand(2,4),"Your Pokémon was put to sleep by the tranquilizer kunai!")
                    battle.scene.appearBar
                    pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility! Ultimate Speed!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:AGILITY),battle.battlers[0],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      ShadowDuo1 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("The Akui Clan will be taking all the Hanatsium in this mine!")
                    pbMessage("Don't even bother trying to stop us, you little brats!")
                    pbMessage("Akui Clan Technique, Shadow Style! Multi-Clones of Darkness!!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:DOUBLETEAM),battle.battlers[0],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::EVASION,1,battle.battlers[1])
                    battle.pbAnimation(getID(PBMoves,:DOUBLETEAM),battle.battlers[0],battle.battlers[3])
                    battle.battlers[3].pbRaiseStatStage(PBStats::EVASION,1,battle.battlers[3])
                    battle.pbAnimation(getID(PBMoves,:TOXICSPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Toxic spikes were scattered all around the ground!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::ToxicSpikes] = 2
                    battle.scene.pbHideOpponent
                    battle.scene.appearBar
                    pbMessage("\\xn[\\v[26]]\\pogThose Akui guys aren't the only people who can use techniques to gain the edge in battle!")
                    pbMessage("\\xn[\\v[26]]\\pogKatana of Fire, Nensho Style! Fire Vortex!")
                    battle.pbAnimation(getID(PBMoves,:FIRESPIN),battle.battlers[2],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.battlers[1].effects[PBEffects::TrappingMove] = getID(PBMoves,:FIRESPIN)
                    battle.battlers[1].effects[PBEffects::Trapping] = 5
                    battle.battlers[1].effects[PBEffects::TrappingUser] = 1
                    battle.pbDisplay(_INTL("The enemy {1} was trapped in a fiery vortex!",battle.battlers[1].name))
                    battle.scene.appearBar
                    pbMessage("\\xn[\\v[26]]\\pogCome on \\PN, let's teach these jerks not to mess with the Nensho Clan!")
                    pbMessage("\\xn[\\v[26]]\\pogNow for my signature technique! Hashimoto Might!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SWORDSDANCE),battle.battlers[2],battle.battlers[1])
                    battle.battlers[2].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[2])
                    battle.battlers[0].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[0],false)
                  }
      ShadowDuo1Last = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Grr... You brats are actually pretty strong...")
                    pbMessage("You'll pay for crossing the Akui Clan!")
                    pbMessage("Akui Clan Technique, Shadow Style! Ninja Dance!")
                    battle.scene.disappearBar
                    if battle.battlers[1].fainted?
                      battle.pbAnimation(getID(PBMoves,:DRAGONDANCE),battle.battlers[3],battle.battlers[3])
                    else
                      battle.pbAnimation(getID(PBMoves,:DRAGONDANCE),battle.battlers[1],battle.battlers[1])
                    end
                    if !battle.battlers[1].fainted?
                      battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1],false)
                    end
                    if !battle.battlers[3].fainted?
                      battle.battlers[3].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[3])
                      battle.battlers[3].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[3],false)
                    end
                    battle.scene.pbHideOpponent
                    battle.scene.appearBar
                    pbMessage("\\xn[\\v[26]]\\pogOh no you don't! You're the one's who are going to pay!")
                    pbMessage("\\xn[\\v[26]]\\pogGraaah! Katana of Fire, Nensho Style! Flame Breath!")
                    if battle.battlers[1].fainted?
                      battle.pbAnimation(getID(PBMoves,:FLAMETHROWER),battle.battlers[2],battle.battlers[3])
                    else
                      battle.pbAnimation(getID(PBMoves,:FLAMETHROWER),battle.battlers[2],battle.battlers[1])
                    end
                    battle.scene.disappearBar
                    if !battle.battlers[1].fainted?
                      battle.battlers[1].pbInflictStatus(PBStatuses::BURN,1,nil)
                    end
                    if !battle.battlers[3].fainted?
                      battle.battlers[3].pbInflictStatus(PBStatuses::BURN,1,nil)
                    end
                    battle.scene.appearBar
                    pbMessage("\\xn[\\v[26]]\\pogLet's finish these jerks off \\PN!")
                    pbMessage("\\xn[\\v[26]]\\pogHiyaaah! Hashimoto Might!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SWORDSDANCE),battle.battlers[2],battle.battlers[1])
                    battle.battlers[2].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[2])
                    battle.battlers[0].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[0],false)
                  }
        ShadowDuo2 = Proc.new{|battle|
                      battle.scene.appearBar
                      battle.scene.pbShowOpponent(0)
                      pbMessage("You'll never be able to stop the plans of the Akui Clan!")
                      pbMessage("You're nothing but pesky thorns in our sides!")
                      pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility!!")
                      battle.scene.disappearBar
                      battle.pbAnimation(getID(PBMoves,:AGILITY),battle.battlers[0],battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1])
                      battle.battlers[3].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[3])
                      battle.scene.appearBar
                      pbMessage("And that's not all! Get a load of this, you worthless children!")
                      pbMessage("Akui Clan Technique, Shock Kunai!")
                      battle.scene.disappearBar
                      battle.pbAnimation(getID(PBMoves,:SHOCKKUNAI),battle.battlers[0],battle.battlers[1])
                      battle.battlers[0].pbInflictStatus(PBStatuses::PARALYSIS,1,nil)
                      battle.battlers[2].pbInflictStatus(PBStatuses::PARALYSIS,1,nil)
                      battle.scene.pbHideOpponent
                      battle.scene.appearBar
                      pbMessage("\\xn[\\v[26]]\\pogThese Akui grunts will never play fair...")
                      pbMessage("\\xn[\\v[26]]\\pogLuckily for us, I also have a few tricks up my sleeve!")
                      pbMessage("\\xn[\\v[26]]\\pogKatana of Fire, Nensho Style! Flame Breath!")
                      battle.pbAnimation(getID(PBMoves,:FLAMETHROWER),battle.battlers[2],battle.battlers[1])
                      battle.scene.disappearBar
                      battle.battlers[1].pbInflictStatus(PBStatuses::BURN,1,nil)
                      battle.battlers[3].pbInflictStatus(PBStatuses::BURN,1,nil)
                      battle.scene.appearBar
                      pbMessage("\\xn[\\v[26]]\\pogLet's go \\PN! We can take care of these Akui lowlifes!")
                      pbMessage("\\xn[\\v[26]]\\pogHiyaaah! Hashimoto Might!")
                      battle.scene.disappearBar
                      battle.pbAnimation(getID(PBMoves,:SWORDSDANCE),battle.battlers[2],battle.battlers[1])
                      battle.battlers[2].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[2])
                      battle.battlers[0].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[0],false)
                    }
        ShadowDuo2Last = Proc.new{|battle|
                      battle.scene.appearBar
                      battle.scene.pbShowOpponent(0)
                      pbMessage("We've been given orders to stop you from going any further!")
                      pbMessage("We will not fail! We cannot fail!")
                      pbMessage("Akui Clan Technique, Shadow Style! Ninja Dance!")
                      battle.scene.disappearBar
                      if battle.battlers[1].fainted?
                        battle.pbAnimation(getID(PBMoves,:DRAGONDANCE),battle.battlers[3],battle.battlers[3])
                      else
                        battle.pbAnimation(getID(PBMoves,:DRAGONDANCE),battle.battlers[1],battle.battlers[1])
                      end
                      if !battle.battlers[1].fainted?
                        battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                        battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1],false)
                      end
                      if !battle.battlers[3].fainted?
                        battle.battlers[3].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[3])
                        battle.battlers[3].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[3],false)
                      end
                      pbMessage("Akui Clan Technique, Shock Kunai!")
                      battle.scene.disappearBar
                      battle.pbAnimation(getID(PBMoves,:SHOCKKUNAI),battle.battlers[0],battle.battlers[1])
                      battle.battlers[0].pbInflictStatus(PBStatuses::PARALYSIS,1,nil)
                      battle.battlers[2].pbInflictStatus(PBStatuses::PARALYSIS,1,nil)
                      battle.scene.pbHideOpponent
                      battle.scene.appearBar
                      pbMessage("\\xn[\\v[26]]\\pog\\PN... I'm starting to feel pretty tired...")
                      pbMessage("\\xn[\\v[26]]\\pogI can probably only use my katana techniques a couple more times...")
                      pbMessage("\\xn[\\v[26]]\\pogBut, in times like these...")
                      pbMessage("\\xn[\\v[26]]\\pogThat's when we really need to give it our all!")
                      pbMessage("\\xn[\\v[26]]\\pogGraaaaaah! Hashimoto Might!")
                      battle.scene.disappearBar
                      battle.pbAnimation(getID(PBMoves,:SWORDSDANCE),battle.battlers[2],battle.battlers[1])
                      battle.battlers[2].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[2])
                      battle.battlers[0].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[0],false)
                    }
      ShadowDuo3 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You two brats must be skilled to have made it this far into the mine...")
                    pbMessage("Too bad for you, this is the end of your journey!")
                    pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility!!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:AGILITY),battle.battlers[0],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1])
                    battle.battlers[3].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[3])
                    battle.pbAnimation(getID(PBMoves,:SPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::Spikes] = 3
                    battle.scene.pbHideOpponent
                    battle.scene.appearBar
                    pbMessage("\\xn[\\v[26]]\\pogHey \\PN, I managed to pick up a few shock kunai off the ground after our last battle!")
                    pbMessage("\\xn[\\v[26]]\\pogLet's see how the Akui Clan likes the taste of their own medicine!")
                    pbMessage("\\xn[\\v[26]]\\pogAkui Clan Technique!\\wtnp[16] .\\wtnp[16].\\wtnp[16].\\wtnp[16]Shock Kunai?\\wtnp[30]")
                    pbMessage("\\xn[\\v[26]]\\pogForget it... I'm just going to throw these kunai as hard I can!")
                    battle.pbAnimation(getID(PBMoves,:SHOCKKUNAI),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.battlers[1].pbInflictStatus(PBStatuses::PARALYSIS,1,nil)
                    battle.battlers[3].pbInflictStatus(PBStatuses::PARALYSIS,1,nil)
                    battle.scene.appearBar
                    pbMessage("\\xn[\\v[26]]\\pogHaha! Yes, it worked!")
                    pbMessage("\\xn[\\v[26]]\\pogTake that you Akui scumbags!")
                    pbMessage("\\xn[\\v[26]]\\pogHiyaaah! Hashimoto Might!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SWORDSDANCE),battle.battlers[2],battle.battlers[1])
                    battle.battlers[2].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[2])
                    battle.battlers[0].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[0],false)
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Hey! You can't do that! That's cheating!")
                    battle.scene.pbHideOpponent
                    battle.scene.disappearBar
                  }
      ShadowDuo3Last = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Hahaha... You kids fight dirty!")
                    pbMessage("Maybe you should join the Akui Clan after all!")
                    pbMessage("Come by Yami Island sometime... after we finish pulverizing you!")
                    pbMessage("Akui Clan Technique, Shadow Style! Multi-Clones of Darkness!!")
                    battle.scene.disappearBar
                    if battle.battlers[1].fainted?
                      battle.pbAnimation(getID(PBMoves,:DOUBLETEAM),battle.battlers[0],battle.battlers[3])
                    else
                      battle.pbAnimation(getID(PBMoves,:DOUBLETEAM),battle.battlers[0],battle.battlers[1])
                    end
                    if !battle.battlers[1].fainted?
                      battle.battlers[1].pbRaiseStatStage(PBStats::EVASION,1,battle.battlers[1])
                    end
                    if !battle.battlers[3].fainted?
                      battle.battlers[3].pbRaiseStatStage(PBStats::EVASION,1,battle.battlers[3])
                    end
                    battle.pbAnimation(getID(PBMoves,:TOXICSPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Toxic spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::ToxicSpikes] = 2
                    battle.scene.pbHideOpponent
                    battle.scene.appearBar
                    pbMessage("\\xn[\\v[26]]\\pogAlright \\PN! We're so close to the end of the mine!")
                    pbMessage("\\xn[\\v[26]]\\pogLet's gather up all our strength...")
                    pbMessage("\\xn[\\v[26]]\\pogAnd then let's blast through these losers!")
                    pbMessage("\\xn[\\v[26]]\\pogGraaaah!\\wtnp[30] Hashimoto Might!\\wtnp[30]")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SWORDSDANCE),battle.battlers[2],battle.battlers[1])
                    battle.battlers[2].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[2])
                    battle.battlers[0].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[0],false)
                    battle.scene.appearBar
                    pbMessage("\\xn[\\v[26]]\\pogKatana of Fire, Nensho Style! Flame Breath!")
                    if battle.battlers[1].fainted?
                      battle.pbAnimation(getID(PBMoves,:FLAMETHROWER),battle.battlers[2],battle.battlers[3])
                    else
                      battle.pbAnimation(getID(PBMoves,:FLAMETHROWER),battle.battlers[2],battle.battlers[1])
                    end
                    battle.scene.disappearBar
                    if !battle.battlers[1].fainted?
                      battle.battlers[1].pbInflictStatus(PBStatuses::BURN,1,nil)
                    end
                    if !battle.battlers[3].fainted?
                      battle.battlers[3].pbInflictStatus(PBStatuses::BURN,1,nil)
                    end
                  }
      ShadowDuo4 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Haha! You're too late!")
                    pbMessage("We were already able to take a piece of the Hanatsium Crystal!")
                    pbMessage("After we smash you two intruders, we'll steal even more!")
                    pbMessage("Here, have a sneak peek at just how strong the Hanatsium Crystal is!")
                    pbMessage("Akui Clan Technique, Shadow Style! Hanatsium Crystal Exposure!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:WORKUP),battle.battlers[0],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,5,battle.battlers[1])
                    battle.pbAnimation(getID(PBMoves,:WORKUP),battle.battlers[0],battle.battlers[3])
                    battle.battlers[3].pbRaiseStatStage(PBStats::ATTACK,5,battle.battlers[3])
                    battle.pbAnimation(getID(PBMoves,:TOXICSPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Toxic spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::ToxicSpikes] = 2
                    battle.scene.pbHideOpponent
                    pbMessage("\\xn[\\v[26]]\\pogHere we go \\PN! This is our final battle!")
                    pbMessage("\\xn[\\v[26]]\\pogI'm going all out! 200% Power, here and now!")
                    pbMessage("\\xn[\\v[26]]\\pogKatana of Fire, Nensho Style! Fire Vortex!")
                    battle.pbAnimation(getID(PBMoves,:FIRESPIN),battle.battlers[2],battle.battlers[1])
                    battle.pbAnimation(getID(PBMoves,:FIRESPIN),battle.battlers[2],battle.battlers[3])
                    battle.scene.disappearBar
                    battle.battlers[1].effects[PBEffects::TrappingMove] = getID(PBMoves,:FIRESPIN)
                    battle.battlers[1].effects[PBEffects::Trapping] = 5
                    battle.battlers[1].effects[PBEffects::TrappingUser] = 1
                    battle.battlers[3].effects[PBEffects::TrappingMove] = getID(PBMoves,:FIRESPIN)
                    battle.battlers[3].effects[PBEffects::Trapping] = 5
                    battle.battlers[3].effects[PBEffects::TrappingUser] = 1
                    battle.pbDisplay(_INTL("The enemies were trapped in fiery vortexes!",battle.battlers[1].name))
                    battle.scene.appearBar
                    pbMessage("\\xn[\\v[26]]\\pogHiyaaah! 200% Hashimoto Might!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SWORDSDANCE),battle.battlers[2],battle.battlers[1])
                    battle.battlers[2].pbRaiseStatStage(PBStats::ATTACK,4,battle.battlers[2])
                    battle.battlers[0].pbRaiseStatStage(PBStats::ATTACK,4,battle.battlers[0],false)
                  }
      MashiroIntro = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Tch. We were so close to getting Virizion's power, but you all had to come mess it up.")
                    pbMessage("I'll show you who you're messing with!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:TOXICSPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Toxic spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::ToxicSpikes] = 2
                  #  battle.scene.appearBar
                  #  pbMessage("Akui Clan Technique, Toxic Kunai!")
                  #  battle.scene.disappearBar
                  #  battle.pbAnimation(getID(PBMoves,:ICICLESPEAR),battle.battlers[1],battle.battlers[0])
                  #  battle.battlers[0].pbInflictStatus(PBStatuses::POISON,1,nil)
                    battle.scene.appearBar
                    pbMessage("I won't let you brats get in my way!")
                    pbMessage("I'm going to put you in your place, you miserable worm!")
                    battle.scene.disappearBar
                  #  battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      Mashiro2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Why are you so persistent on being annoying?!")
                    pbMessage("Ugh... I don't have any Kunai anymore...")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                  }
      Mashiro3 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Did you actually believe that I ran out of Icicle Kunai?")
                    pbMessage("You're even more foolish than you look!")
                    pbMessage("Akui Clan Technique, Shock Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SHOCKKUNAI),battle.battlers[1],battle.battlers[0])
                    battle.battlers[0].pbInflictStatus(PBStatuses::PARALYSIS,1,nil)
                    battle.scene.appearBar
                    pbMessage("Do you see now why the codes of Bushido are worthless? Without honor and respect, I can do whatever I want.")
                    battle.scene.disappearBar
                    if battle.battlers[1].hasActiveAbility?(:CONTRARY)
                      battle.battlers[1].pbLowerStatStage(PBStats::SPEED,2,battle.battlers[1])
                    else
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1])
                    end
                    battle.scene.pbHideOpponent
                  }
      MashiroLast = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Wow, you managed to bring me down to my last Pokémon...")
                    pbMessage("Unfortunately for you, this is my strongest!")
                    pbMessage("Don't even bother trying to steal my Pokémon! I know all about your dirty tricks!")
                    pbMessage("We Akui Admins are a step above. We'll always be able to hit your Poké Balls away!")
                    pbMessage("Now, you're lucky that I'm actually out of Kunai...")
                    pbMessage("...")
                    pbMessage("Just kidding, of course I have more Kunai!")
                    pbMessage("Akui Clan Technique, Icicle Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:ICICLESPEAR),battle.battlers[1],battle.battlers[0])
                    battle.battlers[0].pbInflictStatus(PBStatuses::FROZEN,1,nil)
                    battle.scene.appearBar
                    pbMessage("You'll never be able to defeat me!")
                    battle.scene.disappearBar
                    if battle.battlers[1].hasActiveAbility?(:CONTRARY)
                      battle.battlers[1].pbLowerStatStage(PBStats::SPDEF,1,battle.battlers[1])
                    else
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1])
                    end
                    battle.scene.pbHideOpponent
                  }
      MashiroRematchIntro = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("I won't let you humiliate me like last time!")
                    pbMessage("You'll never be able to beat me again!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:TOXICSPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Toxic spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::ToxicSpikes] = 2
                    battle.scene.appearBar
                    pbMessage("Now, for a special surprise!")
                    pbMessage("When we were in Tsuchi Village, I studied the katana techniques of the Komorei Clan.")
                    pbMessage("And now I've been able to perfect them as my own!")
                    pbMessage("Akui Admin Technique, Komorei Style! Lush Terrain!")
                    battle.pbAnimation(getID(PBMoves,:GRASSYTERRAIN),battle.battlers[1],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Grassy)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,2,battle.battlers[1],false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,2,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
      MashiroRematch2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Grr... You've got some nerve.")
                    pbMessage("I won't allow you to annoy me any more!")
                    pbMessage("Akui Clan Technique, Icicle Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:ICICLESPEAR),battle.battlers[1],battle.battlers[0])
                    battle.battlers[0].pbInflictStatus(PBStatuses::FROZEN,1,"Your Pokémon was frozen solid by the ice kunai!")
                    battle.scene.appearBar
                    pbMessage("Akui Admin Technique, Komorei Style! Blazing Sunlight!")
                    battle.pbCommonAnimation("Sunny",nil,nil)
                    battle.scene.disappearBar
                    battle.pbStartWeather(battle.battlers[1],PBWeather::Sun,true,false)
                    if battle.battlers[1].hasActiveAbility?(:CONTRARY)
                      battle.battlers[1].pbLowerStatStage(PBStats::ATTACK,2,battle.battlers[1])
                      battle.battlers[1].pbLowerStatStage(PBStats::SPEED,2,battle.battlers[1],false)
                      battle.battlers[1].pbLowerStatStage(PBStats::SPATK,2,battle.battlers[1],false)
                    else
                      battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1],false)
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,2,battle.battlers[1],false)
                    end
                    battle.scene.pbHideOpponent
                  }
      MashiroRematchLast = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You'll never defeat me! I won't allow it!")
                    pbMessage("Akui Clan Technique, Venom Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:POISONKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::POISON,1,"Your Pokémon was poisoned by the venom kunai!")
                    battle.scene.appearBar
                    pbMessage("Akui Clan Technique, Shadow Style! Muscle Control!!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:DRAGONDANCE),battle.battlers[1],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,2,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,2,battle.battlers[1],false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,2,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
      HotokeIntro = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\wtnp[20].\\wtnp[20].\\wtnp[20].\\wtnp[20]")
                    pbMessage("Don't look at me...")
                    pbMessage("You should disappear...")
                    battle.scene.disappearBar
                    battle.pbCommonAnimation("Sandstorm",nil,nil)
                    battle.pbStartWeather(battle.battlers[1],PBWeather::Sandstorm,true,false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,2,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,2,battle.battlers[1],false)
                    battle.battlers[3].pbRaiseStatStage(PBStats::DEFENSE,2,battle.battlers[3])
                    battle.battlers[3].pbRaiseStatStage(PBStats::SPDEF,2,battle.battlers[3],false)
                    battle.scene.appearBar
                    pbMessage("...")
                    pbMessage("Leave me alone...")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                    battle.scene.appearBar
                    pbMessage("\\xn[Nori]\\bCome on \\PN, let's show these cowards how a real Kenshi battles!")
                    pbMessage("\\xn[Nori]\\bKatana of Fire, Nensho Style! Breath of Flames!")
                    battle.pbAnimation(getID(PBMoves,:FLAMETHROWER),battle.battlers[2],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.battlers[1].pbInflictStatus(PBStatuses::BURN,1,nil)
                    battle.battlers[3].pbInflictStatus(PBStatuses::BURN,1,nil)
                  }
      Hotoke2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\wtnp[20].\\wtnp[20].\\wtnp[20].\\wtnp[20]")
                    pbMessage("Stop... stop it...")
                    battle.scene.disappearBar
                    battle.pbCommonAnimation("Sandstorm",nil,nil)
                    if battle.battlers[1].fainted?
                      battle.pbStartWeather(battle.battlers[3],PBWeather::Sandstorm,true,false)
                    else
                      battle.pbStartWeather(battle.battlers[1],PBWeather::Sandstorm,true,false)
                    end
                    if !battle.battlers[1].fainted?
                      battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,3,battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,3,battle.battlers[1],false)
                    end
                    if !battle.battlers[3].fainted?
                      battle.battlers[3].pbRaiseStatStage(PBStats::DEFENSE,3,battle.battlers[3])
                      battle.battlers[3].pbRaiseStatStage(PBStats::SPDEF,3,battle.battlers[3],false)
                    end
                    battle.scene.appearBar
                    pbMessage("Akui Clan Technique... Toxic Spikes...")
                    battle.scene.disappearBar
                    if battle.battlers[1].fainted?
                      battle.pbAnimation(getID(PBMoves,:TOXICSPIKES),battle.battlers[3],battle.battlers[0])
                      battle.pbDisplay(_INTL("Toxic spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                      battle.battlers[3].pbOpposingSide.effects[PBEffects::ToxicSpikes] = 2
                    else
                      battle.pbAnimation(getID(PBMoves,:TOXICSPIKES),battle.battlers[1],battle.battlers[0])
                      battle.pbDisplay(_INTL("Toxic spikes were scattered all around the battlefield!!",battle.battlers[0].pbThis(true)))
                      battle.battlers[1].pbOpposingSide.effects[PBEffects::ToxicSpikes] = 2
                    end
                    battle.scene.appearBar
                    pbMessage("Get away...")
                    pbMessage("Get away from me! Get away!")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                    battle.scene.appearBar
                    pbMessage("\\xn[Nori]\\bIt's time to finish off these Akui clowns!")
                    pbMessage("\\xn[Nori]\\bSecret Technique! Mountainous Roar!")
                    battle.pbAnimation(getID(PBMoves,:HOWL),battle.battlers[2],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.battlers[1].pbLowerStatStage(PBStats::SPEED,2,battle.battlers[1])
                    battle.battlers[1].pbLowerStatStage(PBStats::DEFENSE,2,battle.battlers[1],false)
                    battle.battlers[1].pbLowerStatStage(PBStats::SPDEF,2,battle.battlers[1],false)
                  }
      Hotoke3 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Get away! I can't let you win!")
                    battle.scene.disappearBar
                    battle.pbCommonAnimation("Sandstorm",nil,nil)
                    battle.pbStartWeather(battle.battlers[1],PBWeather::Sandstorm,true,false)
                    if !battle.battlers[1].fainted?
                      battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,3,battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,3,battle.battlers[1],false)
                    end
                    if !battle.battlers[3].fainted?
                      battle.battlers[3].pbRaiseStatStage(PBStats::DEFENSE,3,battle.battlers[3])
                      battle.battlers[3].pbRaiseStatStage(PBStats::SPDEF,3,battle.battlers[3],false)
                    end
                    battle.scene.appearBar
                    pbMessage("Akui Clan Technique... Shock Kunai...")
                    battle.scene.disappearBar
                    if battle.battlers[1].fainted?
                      battle.pbAnimation(getID(PBMoves,:SHOCKKUNAI),battle.battlers[0],battle.battlers[3])
                    else
                      battle.pbAnimation(getID(PBMoves,:SHOCKKUNAI),battle.battlers[0],battle.battlers[1])
                    end
                    battle.battlers[0].pbInflictStatus(PBStatuses::PARALYSIS,1,nil)
                    if !battle.battlers[2].fainted?
                      battle.battlers[2].pbInflictStatus(PBStatuses::PARALYSIS,1,nil)
                    end
                    battle.scene.appearBar
                    pbMessage("Get away...")
                    pbMessage("Get away from me! Get away!")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                  }
    HotokeRematchIntro = Proc.new{|battle|
                  battle.scene.appearBar
                  battle.scene.pbShowOpponent(0)
                  pbMessage("I don't like you...")
                  pbMessage("It's time for you to leave forever...")
                  battle.scene.disappearBar
                  battle.pbCommonAnimation("Sandstorm",nil,nil)
                  battle.pbStartWeather(battle.battlers[1],PBWeather::Sandstorm,true,false)
                  battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,2,battle.battlers[1])
                  battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,2,battle.battlers[1],false)
                  battle.scene.appearBar
                  pbMessage("...")
                  pbMessage("Now, for a new technique...")
                  pbMessage("Akui Admin Technique... Nensho Style... Flame Breath...")
                  battle.pbAnimation(getID(PBMoves,:FLAMETHROWER),battle.battlers[1],battle.battlers[0])
                  battle.scene.disappearBar
                  battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,nil)
                  battle.scene.pbHideOpponent
                }
    HotokeRematch2 = Proc.new{|battle|
                  battle.scene.appearBar
                  battle.scene.pbShowOpponent(0)
                  pbMessage("It's time to burn you again...")
                  pbMessage("Akui Admin Technique... Nensho Style... Flame Breath...")
                  battle.pbAnimation(getID(PBMoves,:FLAMETHROWER),battle.battlers[1],battle.battlers[0])
                  battle.scene.disappearBar
                  battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,nil)
                  battle.scene.appearBar
                  pbMessage("And now... Another new technique...")
                  pbMessage("Akui Admin Technique... Nensho Style... Crimson Vortex...")
                  battle.pbAnimation(getID(PBMoves,:FIRESPIN),battle.battlers[1],battle.battlers[0])
                  battle.scene.disappearBar
                  battle.battlers[0].effects[PBEffects::TrappingMove] = getID(PBMoves,:FIRESPIN)
                  battle.battlers[0].effects[PBEffects::Trapping] = 5
                  battle.battlers[0].effects[PBEffects::TrappingUser] = 1
                  battle.pbDisplay(_INTL("{1} was trapped in a fiery vortex!",battle.battlers[0].pbThis(true)))
                  battle.scene.appearBar
                  pbMessage("You'll never win...")
                  pbMessage("Never...")
                  battle.pbCommonAnimation("Sandstorm",nil,nil)
                  battle.scene.disappearBar
                  battle.pbStartWeather(battle.battlers[1],PBWeather::Sandstorm,true,false)
                  battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,3,battle.battlers[1])
                  battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,3,battle.battlers[1],false)
                  battle.scene.pbHideOpponent
                }
      HotokeRematchLast = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("No...")
                    pbMessage("No! This can't happen!")
                    pbMessage("Get away from me!!")
                    pbMessage("Akui Admin Technique, Nensho Style! Crimson Vortex!")
                    battle.pbAnimation(getID(PBMoves,:FIRESPIN),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.battlers[0].effects[PBEffects::TrappingMove] = getID(PBMoves,:FIRESPIN)
                    battle.battlers[0].effects[PBEffects::Trapping] = 5
                    battle.battlers[0].effects[PBEffects::TrappingUser] = 1
                    battle.pbDisplay(_INTL("{1} was trapped in a fiery vortex!",battle.battlers[0].pbThis(true)))
                    battle.scene.appearBar
                    pbMessage("You can't win...")
                    pbMessage("You can never win!")
                    pbMessage("Akui Clan Technique! Shock Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SHOCKKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::PARALYSIS,1,nil)
                    battle.pbCommonAnimation("Sandstorm",nil,nil)
                    battle.scene.disappearBar
                    battle.pbStartWeather(battle.battlers[1],PBWeather::Sandstorm,true,false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
      KuroIntro = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("I'm so looking forward to picking you apart, stupid Kenshi!")
                    pbMessage("Your obsession with honor and dignity will be your downfall!")
                    pbMessage("Here, let me show you the benefits ignoring the Bushido code!")
                    pbMessage("Akui Clan Technique! Tranquilizer Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SLEEPKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::SLEEP,rand(2,4),"Your Pokémon was put to sleep by the tranquilizer kunai!")
                    battle.scene.appearBar
                    pbMessage("Hahaha! Are you having fun yet?!")
                    pbMessage("\\shBecause I sure am!")
                    pbMessage("Now come on, show me what you're made of!")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
      Kuro2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("I'm growing tired of playing with you, Kenshi.")
                    pbMessage("I think it's about time I started taking this battle seriously!")
                    pbMessage("Akui Clan Technique! Berserker Dance!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:CLANGOROUSSOUL),battle.battlers[0],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,3,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,3,battle.battlers[1],false)
                    battle.battlers[1].pbLowerStatStage(PBStats::DEFENSE,2,battle.battlers[1])
                    battle.battlers[1].pbLowerStatStage(PBStats::SPDEF,2,battle.battlers[1],false)
                    battle.scene.appearBar
                    pbMessage("You can't possibly hope to defeat me!")
                    pbMessage("I am the Hound of Cruelty, the strongest of the Akui Admins!")
                    pbMessage("Akui Clan Technique, Flame Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:BURNKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,"Your Pokémon was burned by the flame kunai!")
                    battle.scene.pbHideOpponent
                  }
    KuroLast = Proc.new{|battle|
                  battle.scene.appearBar
                  battle.scene.pbShowOpponent(0)
                  pbMessage("\\shHow dare you?!")
                  pbMessage("Pawns of the Shogun need to be taught their place!")
                  pbMessage("And that place... is six feet underground!")
                  pbMessage("Akui Clan Technique! Berserker Dance!")
                  battle.scene.disappearBar
                  battle.pbAnimation(getID(PBMoves,:CLANGOROUSSOUL),battle.battlers[0],battle.battlers[1])
                  battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,3,battle.battlers[1])
                  battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,3,battle.battlers[1],false)
                  battle.battlers[1].pbLowerStatStage(PBStats::DEFENSE,2,battle.battlers[1])
                  battle.battlers[1].pbLowerStatStage(PBStats::SPDEF,2,battle.battlers[1],false)
                  battle.scene.appearBar
                  pbMessage("Akui Clan Technique, Venom Kunai!")
                  battle.scene.disappearBar
                  battle.pbAnimation(getID(PBMoves,:POISONKUNAI),battle.battlers[0],battle.battlers[1])
                  battle.battlers[0].pbInflictStatus(PBStatuses::POISON,1,"Your Pokémon was poisoned by the venom kunai!")
                  battle.scene.pbHideOpponent
                }
    KuroRematchIntro = Proc.new{|battle|
                  battle.scene.appearBar
                  battle.scene.pbShowOpponent(0)
                  pbMessage("I had my fun toying with you before, but now playtime is over!")
                  pbMessage("Witness the new techniques I stole from that stupid Shimizu Clan leader!")
                  pbMessage("Akui Admin Technique, Shimizu Style! Healing Ring!")
                  battle.pbAnimation(getID(PBMoves,:AQUARING),battle.battlers[1],battle.battlers[0])
                  battle.scene.disappearBar
                  battle.battlers[1].effects[PBEffects::AquaRing] = true
                  battle.pbDisplay(_INTL("Kuro surrounded {1} with a veil of water!",battle.battlers[1].name))
                  battle.scene.appearBar
                  pbMessage("And now, how about I change the terrain!")
                  pbMessage("Akui Admin Technique, Shimizu Style! Misty Terrain!")
                  battle.pbAnimation(getID(PBMoves,:MISTYTERRAIN),battle.battlers[1],battle.battlers[1])
                  battle.scene.disappearBar
                  battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Misty)
                  battle.scene.appearBar
                  pbMessage("And don't you dare forget about my signature move!")
                  pbMessage("Akui Clan Technique! Tranquilizer Kunai!")
                  battle.scene.disappearBar
                  battle.pbAnimation(getID(PBMoves,:SLEEPKUNAI),battle.battlers[0],battle.battlers[1])
                  battle.battlers[0].pbInflictStatus(PBStatuses::SLEEP,rand(2,4),"Your Pokémon was put to sleep by the tranquilizer kunai!")
                  battle.scene.appearBar
                  pbMessage("Hahaha! Now, isn't this fun?!")
                  pbMessage("Come on now! Show me what you're made of!")
                  battle.scene.disappearBar
                  battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                  battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1],false)
                  battle.scene.pbHideOpponent
                }
      KuroRematch2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Are you having fun yet?!")
                    pbMessage("Because I'm having the time of my life!")
                    pbMessage("Now, I'd hate rain on the parade, but...")
                    pbMessage("Akui Admin Technique, Shimizu Style! Torrential Downpour!")
                    battle.scene.disappearBar
                    battle.pbCommonAnimation("Rain",battle.battlers[0],nil)
                    battle.pbStartWeather(battle.battlers[1],PBWeather::Rain,true,false)
                    battle.scene.appearBar
                    pbMessage("Now, how should I torture you next?")
                    pbMessage("Oh! I know! How about some more kunai?")
                    pbMessage("Akui Clan Technique, Shock Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SHOCKKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::PARALYSIS,1,"Your Pokémon was paralyzed by the shock kunai!")
                    battle.scene.appearBar
                    pbMessage("Actually... No, I don't think paralysis is good enough!")
                    pbMessage("How about I burn your Pokémon instead?")
                    pbMessage("Akui Clan Technique, Flame Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:BURNKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,"Your Pokémon was burned by the flame kunai!")
                    battle.scene.appearBar
                    pbMessage("You know, I still don't think this is good enough...")
                    pbMessage("Plus, your Pokémon is looking tired!")
                    pbMessage("How about I just go back to using my favorite kunai?")
                    pbMessage("Akui Clan Technique! Tranquilizer Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SLEEPKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::SLEEP,rand(2,4),"Your Pokémon was put to sleep by the tranquilizer kunai!")
                    battle.scene.appearBar
                    pbMessage("Hahahahaha! Thank you for being such an obedient little puppet!")
                    pbMessage("You really are my favorite plaything!")
                    pbMessage("Akui Clan Technique! Berserker Dance!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:DRAGONDANCE),battle.battlers[1],battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,3,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,3,battle.battlers[1],false)
                    battle.battlers[1].pbLowerStatStage(PBStats::DEFENSE,2,battle.battlers[1])
                    battle.battlers[1].pbLowerStatStage(PBStats::SPDEF,2,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
      KuroRematchLast = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You're managing to keep up pretty well, \\PN!")
                    pbMessage("Too bad for you, you're nothing but a worthless toy.")
                    pbMessage("And just like an old toy, you've lost your value to me.")
                    pbMessage("It's time for me to break you!")
                    pbMessage("Akui Admin Technique, Shimizu Style! Healing Ring!")
                    battle.pbAnimation(getID(PBMoves,:AQUARING),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.battlers[1].effects[PBEffects::AquaRing] = true
                    battle.pbDisplay(_INTL("Kuro surrounded {1} with a veil of water!",battle.battlers[1].name))
                    battle.scene.appearBar
                    pbMessage("Katana of Water, Shimizu Style! Raging Whirlpool!")
                    battle.pbAnimation(getID(PBMoves,:WHIRLPOOL),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.battlers[0].effects[PBEffects::TrappingMove] = getID(PBMoves,:WHIRLPOOL)
                    battle.battlers[0].effects[PBEffects::Trapping] = 6
                    battle.battlers[0].effects[PBEffects::TrappingUser] = 1
                    battle.pbDisplay(_INTL("{1} was trapped in a whirlpool!",battle.battlers[0].pbThis(true)))
                    battle.scene.appearBar
                    pbMessage("It's time for you to go to sleep forever!")
                    pbMessage("Akui Clan Technique! Tranquilizer Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SLEEPKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::SLEEP,rand(2,4),"Your Pokémon was put to sleep by the tranquilizer kunai!")
                    battle.scene.appearBar
                    pbMessage("You don't stand a chance against me!")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
    HattoriIntro = Proc.new{|battle|
                  battle.scene.appearBar
                  battle.scene.pbShowOpponent(0)
                  pbMessage("\\xn[Hattori]\\rYou and Ryo will never be able stop me.")
                  pbMessage("\\xn[Hattori]\\rYou see, I'm not afraid of the Katana of Light at all...")
                  pbMessage("\\xn[Hattori]\\rIt's you who should fear my Katana of Shadows!")
                  pbMessage("\\xn[Hattori]\\rKatana of Shadows, Akui Secret Technique! Nightmare Void!")
                  battle.pbAnimation(getID(PBMoves,:DARKVOID),battle.battlers[1],battle.battlers[0])
                  battle.scene.disappearBar
                  battle.battlers[0].pbInflictStatus(PBStatuses::SLEEP,rand(5,6),"Your Pokémon was put into a deep sleep by the Katana of Shadows!")
                  battle.battlers[0].effects[PBEffects::Nightmare] = true
                  battle.pbDisplay(_INTL("{1} began having a nightmare!",battle.battlers[0].name))
                  battle.pbAnimation(getID(PBMoves,:SPIKES),battle.battlers[1],battle.battlers[0])
                  battle.pbDisplay(_INTL("Spikes were scattered all around the battlefield!",battle.battlers[0].pbThis(true)))
                  battle.battlers[1].pbOpposingSide.effects[PBEffects::Spikes] = 3
                  battle.scene.appearBar
                  pbMessage("\\xn[Hattori]\\rFoolish child, witness my true power! You'll never stop our plans!")
                  battle.scene.disappearBar
                  battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                  battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[1],false)
                  battle.scene.pbHideOpponent
                }
    Hattori2 = Proc.new{|battle|
                  battle.scene.appearBar
                  battle.scene.pbShowOpponent(0)
                  pbMessage("\\xn[Hattori]\\r\\PN, have you had enough yet?")
                  pbMessage("\\xn[Hattori]\\rBecause I'm just getting started!")
                  pbMessage("\\xn[Hattori]\\rYou'll never block my path to the throne!")
                  pbMessage("\\xn[Hattori]\\rKatana of Shadows, Akui Secret Technique! Wonder Room!")
                  battle.pbAnimation(getID(PBMoves,:WONDERROOM),battle.battlers[1],battle.battlers[1])
                  battle.scene.disappearBar
                  battle.field.effects[PBEffects::WonderRoom] = 6
                  battle.pbDisplay(_INTL("Hattori created a bizarre area in which the Defense and Sp. Def stats are swapped!"))
                  battle.scene.appearBar
                  pbMessage("\\xn[Hattori]\\rWeaklings like you and Ryo...")
                  pbMessage("\\xn[Hattori]\\rYou have no place in my new world!")
                  pbMessage("\\xn[Hattori]\\rAkui Clan Technique, Venom Kunai!")
                  battle.scene.disappearBar
                  battle.pbAnimation(getID(PBMoves,:POISONKUNAI),battle.battlers[0],battle.battlers[1])
                  battle.battlers[0].pbInflictStatus(PBStatuses::POISON,1,"Your Pokémon was poisoned by the venom kunai!")
                  battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                  battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[1],false)
                  battle.scene.pbHideOpponent
                }
      Hattori3 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[Hattori]\\r\\PN, you're doing a decent job of keeping up.")
                    pbMessage("\\xn[Hattori]\\rThat must be my strong blood flowing through you.")
                    pbMessage("\\xn[Hattori]\\rYou owe all of your success to me! Your father is just a weakling!")
                    pbMessage("\\xn[Hattori]\\rYou should have joined me in the Akui Clan, traitorous child!")
                    pbMessage("\\xn[Hattori]\\rKatana of Shadows, Akui Secret Technique! Psychic Terrain!")
                    battle.pbAnimation(getID(PBMoves,:PSYCHICTERRAIN),battle.battlers[1],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Psychic)
                    battle.scene.appearBar
                    pbMessage("\\xn[Hattori]\\rKatana of Shadows, Akui Secret Technique! Trick Room!")
                    battle.pbAnimation(getID(PBMoves,:TRICKROOM),battle.battlers[1],battle.battlers[1])
                    battle.scene.disappearBar
                    battle.field.effects[PBEffects::TrickRoom] = 5
                    battle.pbDisplay(_INTL("Hattori twisted the dimensions with the Katana of Shadows!"))
                    battle.scene.appearBar
                    pbMessage("\\xn[Hattori]\\rI cannot stand to look at you any longer...")
                    pbMessage("\\xn[Hattori]\\rBegone, \\PN!")
                    pbMessage("\\xn[Hattori]\\rAkui Clan Technique, Flame Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:BURNKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,"Your Pokémon was burned by the flame kunai!")
                    battle.scene.pbHideOpponent
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
        HattoriLast = Proc.new{|battle|
                      battle.scene.appearBar
                      battle.scene.pbShowOpponent(0)
                      pbWait(14)
                      pbBGMFade(3)
                      pbMessage("\\xn[Hattori]\\rYou've made a grave mistake now, my child.")
                      pbMessage("\\xn[Hattori]\\rYou cannot even begin to comprehend the power of my Shadow Lugia!")
                      pbBGMPlay("Botw-Ganon")
                      pbMessage("\\xn[Hattori]\\rIt looks like I'll have to teach you one final lesson!")
                      pbMessage("\\sh\\xn[Hattori]\\rGo Shadow Lugia! Eliminate \\PN, and that foolish Royal Samurai Ryo!")
                      pbSEPlay("249Cry")
                      pbWait(26)
                      pbMessage("\\xn[Hattori]\\rThe codes of Bushido will be dissolved after today!")
                      pbMessage("\\xn[Hattori]\\rAkui Secret Technique! Hanatsium Crystal Exposure!")
                      battle.scene.disappearBar
                      battle.pbAnimation(getID(PBMoves,:WORKUP),battle.battlers[1],battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,2,battle.battlers[1],false)
                      battle.battlers[1].pbLowerStatStage(PBStats::DEFENSE,1,battle.battlers[1])
                      battle.battlers[1].pbLowerStatStage(PBStats::SPDEF,1,battle.battlers[1],false)
                      battle.scene.appearBar
                      pbMessage("\\xn[Hattori]\\rYour journey ends here, my child!")
                      pbMessage("\\xn[Hattori]\\rGoodbye,\\PN!")
                      battle.scene.disappearBar
                      battle.scene.pbHideOpponent
                    }
    # Katana awakens
    KatanaIntro = Proc.new{|battle|
                  battle.scene.appearBar
                  battle.scene.pbShowOpponent(0)
                  pbMessage("Kenshi scum like you are worth NOTHING. I'll take you out here and now.")
                  pbMessage("It's time to unleash my full power.")
                  battle.scene.disappearBar
                  battle.pbAnimation(getID(PBMoves,:SPIKES),battle.battlers[1],battle.battlers[0])
                  battle.pbDisplay(_INTL("Spikes were scattered all around the battlefield!",battle.battlers[0].pbThis(true)))
                  battle.battlers[1].pbOpposingSide.effects[PBEffects::Spikes] = 3
                  battle.scene.appearBar
                  pbMessage("Akui Clan Technique, Shadow Style! Ninja Agility!!")
                  battle.scene.disappearBar
                  battle.pbAnimation(getID(PBMoves,:AGILITY),battle.battlers[0],battle.battlers[1])
                  battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1])
                  battle.scene.pbHideOpponent
                }
    KatanaAwakens = Proc.new{|battle|
                  battle.scene.appearBar
                  battle.scene.pbShowOpponent(0)
                  pbMessage("Give it up! It's impossible to beat our viscious Shadow Pokemon.")
                  pbMessage("Wait, what's that ligh-\\wtnp[20]")
                  battle.scene.disappearBar
                  viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
                  viewport.z = 999999
                  viewport.color = Color.new(243,243,99,100)
                  pbSEPlay("shadowkatana")
                  (Graphics.frame_rate/3).times do
                    viewport.color.alpha += 255/(Graphics.frame_rate/3)
                    Graphics.update
                  end
                  pbWait(20)
                  (Graphics.frame_rate/3).times do
                    viewport.color.alpha -= 255/(Graphics.frame_rate/3)
                    Graphics.update
                  end
                  viewport.dispose
                  pbMessage("You feel your father's energy flowing through the Ancient Katana and into your body...")
                  pbMessage(".\\wtnp[18].\\wtnp[18].\\wtnp[18]")
                  pbMessage("\\me[Conquest-LevelUpWarlord]The Ancient Katana transformed into the Katana of Light!")
                  vRI("KATANALIGHT",1)
                  if vHI("KATANABASIC")
                    vDI("KATANABASIC")
                  end
                  pbMessage("You may now steal Shadow Pokémon from the Akui Clan!")
                  pbMessage("\\xn[Shogun]\\PN! You must use the power of light to counter these Shadow Pokemon! Capture their Pokemon and purify them for good!")
                  $game_switches[67]=true
                  $game_switches[62]=true
                  $PokemonGlobal.snagMachine=true
                  viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
                  viewport.z = 999999
                  viewport.color = Color.new(243,243,99,100)
                  pbSEPlay("shadowkatana")
                  (Graphics.frame_rate/3).times do
                    viewport.color.alpha += 255/(Graphics.frame_rate/3)
                    Graphics.update
                  end
                  pbWait(20)
                  (Graphics.frame_rate/3).times do
                    viewport.color.alpha -= 255/(Graphics.frame_rate/3)
                    Graphics.update
                  end
                  viewport.dispose
                  battle.scene.appearBar
                  pbMessage("Hngh- That light... what was it!?")
                  battle.scene.disappearBar
                  battle.scene.pbHideOpponent
                }
    # Sukiro quiz
     Sukiro1 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Question time, \\PN!")
                    # Choice Box Stuff
                    cmd=0
                    cmd= pbMessage("What is a Kenshi's most important moral code?",["The Code of Honor","The Code of Power","The Code of Intelligence"],0,nil,0)
                    if cmd == 0
                      pbMessage("\\se[SwShCorrect]As expected of my student! Brilliant!")
                      battle.scene.pbHideOpponent
                      battle.scene.disappearBar
                      battle.battlers[0].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[0])
                    else
                      pbMessage("\\se[SwShIncorrect]Hmm... It seems like we still have some work to do.")
                      pbMessage("The correct answer is the \"Code of Honor,\" which all Kenshi are expected to follow.")
                      battle.scene.pbHideOpponent
                      battle.scene.disappearBar
                      battle.battlers[0].pbLowerStatStage(PBStats::ATTACK,1,battle.battlers[0])
                    end
                  }

     Sukiro2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Prepare yourself for another question \\PN!")
                    cmd=0
                    cmd= pbMessage("What is a Kenshi's source of power?",["Spear","Pokémon","Katana"],0,nil,0)
                    if cmd == 1
                      pbMessage("\\se[SwShCorrect]Well done! You have been paying attention!")
                      pbMessage("A Kenshi's true strength, comes from the bonds they establish with their Pokémon!")
                      battle.scene.pbHideOpponent
                      battle.scene.disappearBar
                      battle.battlers[0].pbRaiseStatStage(PBStats::DEFENSE,1,battle.battlers[0])
                    else
                      pbMessage("\\se[SwShIncorrect]Hmm... It seems like we still have some work to do.")
                      pbMessage("While Katanas and Spears are effective weapons in their own right...")
                      pbMessage("A Kenshi's true strength, comes from the bonds they establish with their Pokémon!")
                      battle.scene.pbHideOpponent
                      battle.scene.disappearBar
                      battle.battlers[0].pbLowerStatStage(PBStats::DEFENSE,1,battle.battlers[0])
                    end
                  }

     Sukiro3 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You're doing well \\PN. But are you prepared for another question?")
                    pbMessage("Answer me this...")
                    cmd=0
                    cmd= pbMessage("What determines the clan that a Kenshi will join?",["Affinity","Money","Family"],0,nil,0)
                    if cmd == 0
                      pbMessage("\\se[SwShCorrect]Well done, \\PN!")
                      pbMessage("The correct answer is \"Affinity\", which is determined by the strength of a Kenshi's soul!")
                      battle.scene.pbHideOpponent
                      battle.scene.disappearBar
                      battle.battlers[0].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[0])
                    elsif cmd == 1
                      pbMessage("\\se[SwShIncorrect]That is incorrect!")
                      pbMessage("It would be incredibly shameful for a Kenshi to attempt to buy their way into a clan!")
                      pbMessage("The correct answer is \"Affinity\", which is determined by the strength of a Kenshi's soul!")
                      battle.scene.pbHideOpponent
                      battle.scene.disappearBar
                      battle.battlers[0].pbLowerStatStage(PBStats::SPEED,1,battle.battlers[0])
                    else
                      pbMessage("\\se[SwShIncorrect]Hmm... It seems like we still have some work to do.")
                      pbMessage("The correct answer is \"Affinity\", which is determined by the strength of a Kenshi's soul!")
                      battle.scene.pbHideOpponent
                      battle.scene.disappearBar
                      battle.battlers[0].pbLowerStatStage(PBStats::SPEED,1,battle.battlers[0])
                    end
                  }
      Sukiro4 = Proc.new{|battle|
                     battle.scene.appearBar
                     battle.scene.pbShowOpponent(0)
                     pbMessage("Alright \\PN! Prepare yourself for my hardest question yet!")
                     cmd=0
                     cmd= pbMessage("What type of Pokémon is strongest against the Shimizu Clan?",["Rock","Electric","Fire"],0,nil,0)
                     if cmd == 1
                       pbMessage("\\se[SwShCorrect]Haha! That is correct! Excellent work, \\PN!")
                       pbMessage("Shimizu Clan members have a water affinity, so Electric is the correct answer!")
                       battle.scene.pbHideOpponent
                       battle.scene.disappearBar
                       battle.battlers[0].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[0])
                     else
                       pbMessage("\\se[SwShIncorrect]Hmm... that is incorrect.")
                       pbMessage("Shimizu Clan members have a water affinity, so Electric would be the correct answer.")
                       battle.scene.pbHideOpponent
                       battle.scene.disappearBar
                       battle.battlers[0].pbLowerStatStage(PBStats::SPATK,1,battle.battlers[0])
                     end
                   }
       Sukiro5 = Proc.new{|battle|
                      battle.scene.appearBar
                      battle.scene.pbShowOpponent(0)
                      pbMessage("A truly honorable Kenshi must never forget their teachings.")
                      pbMessage("Now, answer me this, \\PN.")
                      cmd=0
                      cmd= pbMessage("What is the most important moral code of the Kenshi?",["The Code of Power","The Code of Honor","The Code of Wisdom"],0,nil,0)
                      if cmd == 1
                        pbMessage("\\se[SwShCorrect]Correct!")
                        pbMessage("\\PN, you must never forget that the codes of honor and Bushido are what guide us.")
                        pbMessage("Those in the Akui Clan have forgetten this message, and have lost their way.")
                        pbMessage("It is our purpose as righteous Kenshi to bring them to justice!")
                        battle.scene.pbHideOpponent
                        battle.scene.disappearBar
                        battle.battlers[0].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[0])
                      else
                        pbMessage("\\se[SwShIncorrect]Hmm... that is incorrect.")
                        pbMessage("\\PN, you must never forget that the codes of honor and Bushido are what guide us.")
                        pbMessage("Those in the Akui Clan have forgetten this message, and have lost their way.")
                        pbMessage("It is our purpose as righteous Kenshi to bring them to justice!")
                        battle.scene.pbHideOpponent
                        battle.scene.disappearBar
                        battle.battlers[0].pbLowerStatStage(PBStats::ATTACK,1,battle.battlers[0])
                      end
                    }
       Lugia = Proc.new{|battle|
                      battle.scene.appearBar
                      pbMessage("Lugia's soul is completely corrupted! It's driven only by hatred!")
                      battle.pbAnimation(getID(PBMoves,:DRAGONDANCE),battle.battlers[1],battle.battlers[1])
                      battle.scene.disappearBar
                      battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,2,battle.battlers[1],false)
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1],false)
                      battle.battlers[1].pbLowerStatStage(PBStats::DEFENSE,2,battle.battlers[1])
                      battle.battlers[1].pbLowerStatStage(PBStats::SPDEF,2,battle.battlers[1],false)
                      battle.scene.pbHideOpponent
                     }
        Virizion = Proc.new{|battle|
                       battle.scene.appearBar
                       pbMessage("Virizion's soul is locked away!")
                       battle.scene.disappearBar
                       battle.battlers[1].pbLowerStatStage(PBStats::ATTACK,2,battle.battlers[1])
                       battle.battlers[1].pbLowerStatStage(PBStats::SPATK,2,battle.battlers[1],false)
                       battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,1,battle.battlers[1])
                       battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1],false)
                       battle.scene.pbHideOpponent
                      }
        Terrakion = Proc.new{|battle|
                       battle.scene.appearBar
                       pbMessage("Terrakion's soul is locked away!")
                       battle.scene.disappearBar
                       battle.battlers[1].pbLowerStatStage(PBStats::ATTACK,2,battle.battlers[1])
                       battle.battlers[1].pbLowerStatStage(PBStats::SPATK,2,battle.battlers[1],false)
                       battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,1,battle.battlers[1])
                       battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1],false)
                       battle.scene.pbHideOpponent
                      }
        Cobalion = Proc.new{|battle|
                       battle.scene.appearBar
                       pbMessage("Cobalion's soul is locked away!")
                       battle.scene.disappearBar
                       battle.battlers[1].pbLowerStatStage(PBStats::ATTACK,2,battle.battlers[1])
                       battle.battlers[1].pbLowerStatStage(PBStats::SPATK,2,battle.battlers[1],false)
                       battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,1,battle.battlers[1])
                       battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1],false)
                       battle.scene.pbHideOpponent
                      }
        # Dev intros
        CamIntro = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\xn[Cam]\\bI'm excited to face you in battle!")
                    pbMessage("\\xn[Cam]\\bNow, let me show you my signature move!")
                    pbMessage("\\xn[Cam]\\bThundaga Katana! Lightning Stream!")
                    battle.pbAnimation(getID(PBMoves,:THUNDERBOLT),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.battlers[0].pbInflictStatus(PBStatuses::PARALYSIS,1,"Your Pokémon was paralyzed by the quality of Thundaga's stream!")
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,2,battle.battlers[1],false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1],false)
                    battle.scene.appearBar
                    pbMessage("\\xn[Cam]\\bI'm going to go all out!")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                  }
          CamLast = Proc.new{|battle|
                      battle.scene.appearBar
                      battle.scene.pbShowOpponent(0)
                      pbMessage("\\xn[Cam]\\bWow, you're an amazing Kenshi, \\PN!")
                      pbMessage("\\xn[Cam]\\bIt is an honor to have someone as skilled as you playing our game!")
                      pbMessage("\\xn[Cam]\\bHere, have a reward for your efforts!")
                      battle.scene.disappearBar
                      battle.battlers[0].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[0])
                      battle.scene.appearBar
                      pbMessage("\\xn[Cam]\\bDon't get too comfortable though, \\PN!")
                      pbMessage("\\xn[Cam]\\bI'm still your opponent right now!")
                      pbMessage("\\xn[Cam]\\bThundaga Katana! Lightning Stream!")
                      battle.pbAnimation(getID(PBMoves,:THUNDERBOLT),battle.battlers[1],battle.battlers[0])
                      battle.scene.disappearBar
                      battle.battlers[0].pbInflictStatus(PBStatuses::PARALYSIS,1,"Your Pokémon was paralyzed by the quality of Thundaga's stream!")
                      battle.scene.appearBar
                      pbMessage("\\xn[Cam]\\bThundaga Katana! Electric Terrain!")
                      battle.pbAnimation(getID(PBMoves,:ELECTRICTERRAIN),battle.battlers[1],battle.battlers[1])
                      battle.scene.disappearBar
                      battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Electric)
                      battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,2,battle.battlers[1],false)
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1],false)
                      battle.scene.appearBar
                      pbMessage("\\xn[Cam]\\bLet's goooooo!")
                      pbMessage("\\sh\\xn[Cam]\\bBUSHIDOOOOOOOO!")
                      battle.scene.disappearBar
                      battle.scene.pbHideOpponent
                    }

# DONT DELETE THIS END
end
