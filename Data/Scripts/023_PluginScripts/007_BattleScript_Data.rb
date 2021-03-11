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
                    battle.pbAnimation(getID(PBMoves,:GRASSYTERRAIN),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Grassy)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1])
                    pbMessage("The Kenshi's grass affinity boosted the power of their Pokemon!")
                    battle.scene.pbHideOpponent
                  }
        Komorei2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("I'll show you the power of the Komorei Clan!")
                    battle.pbAnimation(getID(PBMoves,:GRASSYTERRAIN),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Grassy)
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,1,battle.battlers[1])
                    pbMessage("The Kenshi's grass affinity boosted the power of their Pokemon!")
                    battle.scene.pbHideOpponent
                  }
        Komorei3 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Alright Kenshi! I'm going to beat you, and turn my luck around!")
                    battle.pbAnimation(getID(PBMoves,:GRASSYTERRAIN),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Grassy)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[1])
                    pbMessage("The Kenshi's grass affinity boosted the power of their Pokemon!")
                    battle.scene.pbHideOpponent
                  }
        Komorei4 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You cannot hide from my love!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:CHARM),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbLowerStatStage(PBStats::ATTACK,2,battle.battlers[0])
                    battle.pbAnimation(getID(PBMoves,:GRASSYTERRAIN),battle.battlers[1],battle.battlers[0])
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Grassy)
                    battle.scene.pbHideOpponent
                  }
        KomoreiDojo1 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("You must be a skilled Kenshi to have made it this far!")
                    pbMessage("Looks like the time has come for you to be fully tested by the best of the Komorei Clan!")
                    battle.pbAnimation(getID(PBMoves,:GRASSYTERRAIN),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Grassy)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1])
                    pbMessage("The Kenshi's grass affinity boosted the power of their Pokemon!")
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
                    pbMessage("The Kenshi's grass affinity boosted the power of their Pokemon!")
                    battle.scene.pbHideOpponent
                  }
        HarumiIntro = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("After everything, I believe I owe you a fair fight.")
                    battle.pbAnimation(getID(PBMoves,:GRASSYTERRAIN),battle.battlers[1],battle.battlers[0])
                    battle.scene.disappearBar
                    battle.pbStartTerrain(battle.battlers[1],PBBattleTerrains::Grassy)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[1],false)
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1],false)
                    pbMessage("Harumi's grass affinity boosted the power of her Pokemon!")
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
                    pbMessage("L- Let's make this a fight worth remembering!")
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
                      pbMessage("Hahaha! We finally face each other in battle!")
                      pbMessage("I've been looking forward to this, \\PN!")
                      pbMessage("Just so you know, I'll be giving this battle my all.")
                      pbMessage("I expect you to do the same! Now, it's time to show you the true power of the Nensho Clan!")
                      pbMessage("Katana of Fire, Nensho Style! Breath of Flames!")
                      battle.pbAnimation(getID(PBMoves,:FLAMETHROWER),battle.battlers[1],battle.battlers[0])
                      battle.scene.disappearBar
                      battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,nil)
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,1,battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1],false)
                      battle.scene.appearBar
                      pbMessage("Katana of Fire, Nensho Style! Sunlight Beams!")
                      battle.pbCommonAnimation("Sunny",nil,nil)
                      battle.scene.disappearBar
                      battle.pbStartWeather(battle.battlers[1],PBWeather::Sun,true,false)
                      battle.scene.appearBar
                      pbMessage("Come at me with all you've got, \\PN! Hiyaaah!")
                      battle.scene.disappearBar
                      battle.scene.pbHideOpponent
                    }
          NoriLast = Proc.new{|battle|
                        battle.scene.appearBar
                        battle.scene.pbShowOpponent(0)
                        pbMessage("Hahaha! This is so much fun!")
                        pbMessage("You are an excellent Kenshi, \\PN!")
                        pbMessage("You've pushed me to my limits...")
                        pbMessage("But the battle isn't over yet! Now it's time for me to get serious!")
                        pbMessage("Secret Technique! Mountainous Roar!")
                        battle.pbAnimation(getID(PBMoves,:HOWL),battle.battlers[1],battle.battlers[0])
                        battle.scene.disappearBar
                        battle.battlers[0].pbLowerStatStage(PBStats::SPEED,2,battle.battlers[0])
                        battle.battlers[0].pbLowerStatStage(PBStats::DEFENSE,2,battle.battlers[0],false)
                        battle.battlers[0].pbLowerStatStage(PBStats::SPDEF,2,battle.battlers[0],false)
                        battle.scene.appearBar
                        pbMessage("Katana of Fire, Nensho Style! Flame Breath!")
                        battle.pbAnimation(getID(PBMoves,:FLAMETHROWER),battle.battlers[1],battle.battlers[0])
                        battle.scene.disappearBar
                        battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,nil)
                        battle.scene.appearBar
                        pbMessage("Let's finish this duel in a blaze of glory, \\PN! Yaaah!")
                        battle.scene.disappearBar
                        battle.scene.pbHideOpponent
                      }
      # Shimizu Intros
      Shimizu1 = Proc.new{|battle|
                  battle.scene.appearBar
                  battle.scene.pbShowOpponent(0)
                  pbMessage("You cannot overcome the calmness of the Shimizu Clan.")
                  battle.scene.disappearBar
                  battle.pbCommonAnimation("Rain",battle.battlers[0],nil)
                  battle.pbStartWeather(battle.battlers[1],PBWeather::Rain,true,false)
                  battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1])
                  pbMessage("The Kenshi's water affinity boosted the power of their Pokemon!")
                  battle.scene.pbHideOpponent
                }
      # Rival intros
      RivalFirstIntro = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\pogPrepare to face the full force of my Pokémon!")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                  }
      RivalBurn = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\pogWe meet in battle again, \\PN!")
                    pbMessage("\\pogI've grown a lot since our last battle, so don't underestimate me!")
                    pbMessage("\\pogNow, prepare to be burned to ashes!")
                    battle.scene.disappearBar
                    #if battle.battlers[0].pbCanInflictStatus?(PBStatuses::BURN,battle.battlers[1],false)
                    battle.pbAnimation(getID(PBMoves,:EMBER),battle.battlers[1],battle.battlers[0])
                    battle.battlers[0].pbInflictStatus(PBStatuses::BURN,1,nil)
                    battle.scene.pbHideOpponent
                  }
      RivalLast = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\pogLooks like it's time to get serious!")
                    pbMessage("\\pogGo #{battle.battlers[1].pokemon.speciesName}, unleash your burning passion!")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,1,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      RivalDuel2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\pogI've grown a lot since our last battle, so don't underestimate me!")
                    pbMessage("\\pogNow, take a look at the new Katana Technique I learned!")
                    pbMessage("\\pogKatana of Fire, Nensho Style! Fire Vortex!")
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
                    pbMessage("\\pogLooks like it's time to get serious!")
                    pbMessage("\\pogGo #{battle.battlers[1].pokemon.speciesName}, unleash your burning passion!")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::ATTACK,2,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPEED,2,battle.battlers[1],false)
                    battle.pbCommonAnimation("Sunny",nil,nil)
                    battle.pbStartWeather(battle.battlers[1],PBWeather::Sun,true,false)
                    battle.scene.pbHideOpponent
                  }
      TsukuIntro = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\rAlright! T-time for you to learn how strong b-bug Pokémon can really be!")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                  }
      TsukuLast = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\rW-wah! This isn't l-looking good!")
                    pbMessage("\\rIt's time for defensive measures! Tsukutsuku...")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,2,battle.battlers[1])
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,2,battle.battlers[1],false)
                    battle.scene.pbHideOpponent
                  }
      KayokoIntro = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\rPrepare yourself. I'll be trying my best.")
                    battle.scene.disappearBar
                    battle.scene.pbHideOpponent
                  }
      KayokoLast = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("\\rI can't let my family down...")
                    pbMessage("\\rTime to show you my true inner strength!")
                    battle.scene.disappearBar
                    battle.battlers[1].pbRaiseStatStage(PBStats::SPATK,2,battle.battlers[1])
                    battle.scene.pbHideOpponent
                  }
      # Akui intros, make them cheat a lot!
      ShadowIntroToxic = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("The Akui Clan never falters! Take this!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:TOXICSPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Toxic spikes were scattered all around {1}'s feet!",battle.battlers[0].pbThis(true)))
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
                    battle.pbDisplay(_INTL("Toxic spikes were scattered all around {1}'s feet!",battle.battlers[0].pbThis(true)))
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
                      battle.pbDisplay(_INTL("Toxic spikes were scattered all around {1}'s feet!",battle.battlers[0].pbThis(true)))
                      battle.battlers[1].pbOpposingSide.effects[PBEffects::ToxicSpikes] = 2
                      battle.scene.appearBar
                      pbMessage("Akui Clan Technique, Shadow Style! Clones of Darkness! Ultimate Evasion!")
                      battle.scene.disappearBar
                      battle.pbAnimation(getID(PBMoves,:DOUBLETEAM),battle.battlers[0],battle.battlers[1])
                      battle.battlers[1].pbRaiseStatStage(PBStats::EVASION,2,battle.battlers[1])
                      battle.scene.pbHideOpponent
                    }
      ShadowIntroSpikes = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("Let's make this battle interesting, shall we?")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Spikes were scattered all around {1}'s feet!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::Spikes] = 3
                    battle.scene.pbHideOpponent
                  }
      ShadowIntroSpikes2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("I'm guarding this key with my life! Stay away, you disgusting kenshi!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SPIKES),battle.battlers[1],battle.battlers[0])
                    battle.pbDisplay(_INTL("Spikes were scattered all around {1}'s feet!",battle.battlers[0].pbThis(true)))
                    battle.battlers[1].pbOpposingSide.effects[PBEffects::Spikes] = 3
                    battle.scene.appearBar
                    pbMessage("Akui Clan Technique, Icicle Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:ICICLESPEAR),battle.battlers[1],battle.battlers[0])
                    battle.battlers[0].pbInflictStatus(PBStatuses::FROZEN,1,"Your Pokémon was frozen solid by the ice kunai!")
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
      ShadowShock2 = Proc.new{|battle|
                    battle.scene.appearBar
                    battle.scene.pbShowOpponent(0)
                    pbMessage("I'll be the one to put a stop to your reign of terror!")
                    pbMessage("The Akui Clan is counting on me to succeed! I can do this!")
                    pbMessage("Akui Clan Technique, Shock Kunai!")
                    battle.scene.disappearBar
                    battle.pbAnimation(getID(PBMoves,:SHOCKKUNAI),battle.battlers[0],battle.battlers[1])
                    battle.battlers[0].pbInflictStatus(PBStatuses::PARALYSIS,1,"Your Pokémon was paralyzed by the shock kunai!")
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
                      battle.pbAnimation(getID(PBMoves,:DRAGONDANCE),battle.battlers[0],battle.battlers[3])
                    else
                      battle.pbAnimation(getID(PBMoves,:DRAGONDANCE),battle.battlers[0],battle.battlers[1])
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
                        battle.pbAnimation(getID(PBMoves,:DRAGONDANCE),battle.battlers[0],battle.battlers[3])
                      else
                        battle.pbAnimation(getID(PBMoves,:DRAGONDANCE),battle.battlers[0],battle.battlers[1])
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
                    battle.pbDisplay(_INTL("Spikes were scattered all around {1}'s feet!",battle.battlers[0].pbThis(true)))
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
                    battle.pbDisplay(_INTL("Toxic spikes were scattered all around {1}'s feet!",battle.battlers[0].pbThis(true)))
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
                    battle.pbDisplay(_INTL("Toxic spikes were scattered all around {1}'s feet!",battle.battlers[0].pbThis(true)))
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
                    battle.pbDisplay(_INTL("Toxic spikes were scattered all around {1}'s feet!",battle.battlers[0].pbThis(true)))
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
                    pbMessage("You're lucky that I'm actually out of Kunai now...")
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
                      battle.pbDisplay(_INTL("Toxic spikes were scattered all around {1}'s feet!",battle.battlers[0].pbThis(true)))
                      battle.battlers[3].pbOpposingSide.effects[PBEffects::ToxicSpikes] = 2
                    else
                      battle.pbAnimation(getID(PBMoves,:TOXICSPIKES),battle.battlers[1],battle.battlers[0])
                      battle.pbDisplay(_INTL("Toxic spikes were scattered all around {1}'s feet!",battle.battlers[0].pbThis(true)))
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
    # Katana awakens
    KatanaIntro = Proc.new{|battle|
                  battle.scene.appearBar
                  battle.scene.pbShowOpponent(0)
                  pbMessage("Kenshi scum like you are worth NOTHING. I'll take you out here and now.")
                  pbMessage("It's time to unleash my full power.")
                  battle.scene.disappearBar
                  battle.pbAnimation(getID(PBMoves,:SPIKES),battle.battlers[1],battle.battlers[0])
                  battle.pbDisplay(_INTL("Spikes were scattered all around {1}'s feet!",battle.battlers[0].pbThis(true)))
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
        Virizion = Proc.new{|battle|
                       battle.scene.appearBar
                       pbMessage("\Virizion's soul is locked away!")
                       battle.scene.disappearBar
                       battle.battlers[1].pbLowerStatStage(PBStats::ATTACK,2,battle.battlers[1])
                       battle.battlers[1].pbLowerStatStage(PBStats::SPATK,2,battle.battlers[1],false)
                       battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,1,battle.battlers[1])
                       battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1],false)
                       battle.scene.pbHideOpponent
                      }
        Terrakion = Proc.new{|battle|
                       battle.scene.appearBar
                       pbMessage("\Terrakion's soul is locked away!")
                       battle.scene.disappearBar
                       battle.battlers[1].pbLowerStatStage(PBStats::ATTACK,2,battle.battlers[1])
                       battle.battlers[1].pbLowerStatStage(PBStats::SPATK,2,battle.battlers[1],false)
                       battle.battlers[1].pbRaiseStatStage(PBStats::DEFENSE,1,battle.battlers[1])
                       battle.battlers[1].pbRaiseStatStage(PBStats::SPDEF,1,battle.battlers[1],false)
                       battle.scene.pbHideOpponent
                      }

# DONT DELETE THIS END
end
