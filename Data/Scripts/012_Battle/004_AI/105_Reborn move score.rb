class PokeBattle_Battle
  ##############################################################################
  # Get a score for each move being considered (trainer-owned Pokémon only).
  # Moves with higher scores are more likely to be chosen.
  ##############################################################################
  def pbGetMoveScore(move,attacker,opponent,skill=100,roughdamage=10,initialscores=[],scoreindex=-1)
    if roughdamage<1
      roughdamage=1
    end
    PBDebug.log(sprintf("%s: initial score: %d",PBMoves.getName(move.id),roughdamage)) if $INTERNAL
    skill=PBTrainerAI.minimumSkill if skill<PBTrainerAI.minimumSkill
    #score=(pbRoughDamage(move,attacker,opponent,skill,move.basedamage)*100/opponent.hp) #roughdamage
    score=roughdamage
    #Temporarly mega-ing pokemon if it can    #perry
    if pbCanMegaEvolve?(attacker.index)
      attacker.pokemon.makeMega
      attacker.pbUpdate(true)
      attacker.form=attacker.startform
      megaEvolved=true
    end
    #Little bit of prep before getting into the case statement
    oppitemworks = opponent.itemWorks?
    attitemworks = attacker.itemWorks?
    aimem = getAIMemory(skill,opponent.pokemonIndex)
    bettertype = move.pbType(move.type,attacker,opponent)
    opponent=attacker.pbOppositeOpposing if !opponent
    opponent=opponent.pbPartner if opponent && opponent.isFainted?
    roles = pbGetMonRole(attacker,opponent,skill)
    if move.priority>0 || (move.basedamage==0 && !attacker.abilitynulled && attacker.ability == PBAbilities::PRANKSTER)
      if move.basedamage>0
        PBDebug.log(sprintf("Priority Check Begin")) if $INTERNAL
        fastermon = (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
        if fastermon
          PBDebug.log(sprintf("AI Pokemon is faster.")) if $INTERNAL
        else
          PBDebug.log(sprintf("Player Pokemon is faster.")) if $INTERNAL
        end
        if score>100
          if @doublebattle
            score*=1.3
          else
            if fastermon
              score*=1.3
            else
              score*=2
            end
          end
        else
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::STANCECHANGE)
            if !fastermon
              score*=0.7
            end
          end
        end
        movedamage = -1
        opppri = false
        pridam = -1
        if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          if aimem.length > 0
            for i in aimem
              tempdam = pbRoughDamage(i,opponent,attacker,skill,i.basedamage)
              if i.priority>0
                opppri=true
                if tempdam>pridam
                  pridam = tempdam
                end
              end
              if tempdam>movedamage
                movedamage = tempdam
              end
            end
          end
        end
        PBDebug.log(sprintf("Expected damage taken: %d",movedamage)) if $INTERNAL
        if !fastermon
          if movedamage>attacker.hp
            if @doublebattle
              score+=75
            else
              score+=150
            end
          end
        end
        if opppri
          score*=1.1
          if pridam>attacker.hp
            if fastermon
              score*=3
            else
              score*=0.5
            end
          end
        end
        if !fastermon && opponent.effects[PBEffects::TwoTurnAttack]>0
          score*=0
        end
        if $fefieldeffect==37
          score*=0
        end
        if !opponent.abilitynulled && (opponent.ability == PBAbilities::DAZZLING || opponent.ability == PBAbilities::QUEENLYMAJESTY)
          score*=0
        end
      end
      score*=0.2 if checkAImoves([PBMoves::QUICKGUARD],aimem)
      PBDebug.log(sprintf("Priority Check End")) if $INTERNAL
    elsif move.priority<0
      if fastermon
        score*=0.9
        if move.basedamage>0
          if opponent.effects[PBEffects::TwoTurnAttack]>0
            score*=2
          end
        end
      end
    end
    ##### Alter score depending on the move's function code ########################
    case move.function
      when 0x00 # No extra effect
        if skill>=PBTrainerAI.bestSkill
          if $fefieldeffect == 30 # Mirror Arena
            if move.id==(PBMoves::DAZZLINGGLEAM)
              if (attacker.stages[PBStats::ACCURACY] < 0 || opponent.stages[PBStats::EVASION] > 0 ||
                 (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER) || (oppitemworks && opponent.item == PBItems::LAXINCENSE) ||
                 ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
                 ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL) ||
                 opponent.vanished) &&
                 !(!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD) &&
                 !(!attacker.abilitynulled && attacker.ability == PBAbilities::NOGUARD)
                score*=2
              end
            end
            if move.id==(PBMoves::BOOMBURST) || move.id==(PBMoves::HYPERVOICE)
              score*=0.3
            end
          end
          if $fefieldeffect == 33 # Flower Garden
            if $fecounter < 0
              if move.id==(PBMoves::CUT)
                goodmon = false
                for i in pbParty(attacker.index)
                  next if i.nil?
                  if i.hasType?(:GRASS) || i.hasType?(:BUG)
                    goodmon=true
                  end
                end
                if goodmon
                  score*=0.3
                else
                  score*=2
                end
              end
              if move.id==(PBMoves::PETALBLIZZARD) && $fecounter==4
                if @doublebattle
                  score*=1.5
                end
              end
            end
          end
          if $fefieldeffect == 23 # Cave
            if move.id==(PBMoves::POWERGEM)
              score*=1.3
              goodmon = false
              for i in pbParty(attacker.index)
                next if i.nil?
                if i.hasType?(:DRAGON) || i.hasType?(:FLYING) || i.hasType?(:ROCK)
                  goodmon=true
                end
              end
              if goodmon
                score*=1.3
              end
            end
          end
        end
      when 0x01 # Splash
        if skill>=PBTrainerAI.bestSkill
          if $fefieldeffect == 21 # Water Surface
            if opponent.stages[PBStats::ACCURACY]==-6 || opponent.stages[PBStats::ACCURACY]>0 ||
              (!opponent.abilitynulled && opponent.ability == PBAbilities::CONTRARY)
              score=0
            else
              miniscore = 100
              if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
                miniscore*=1.3
              end
              count = -1
              sweepvar = false
              for i in pbParty(attacker.index)
                count+=1
                next if i.nil?
                temprole = pbGetMonRole(i,opponent,skill,count,pbParty(attacker.index))
                if temprole.include?(PBMonRoles::SWEEPER)
                  sweepvar = true
                end
              end
              miniscore*=1.1 if sweepvar
              livecount = 0
              for i in pbParty(opponent.index)
                next if i.nil?
                livecount+=1 if i.hp!=0
              end
              if livecount==1 || (!attacker.abilitynulled && attacker.ability == PBAbilities::SHADOWTAG) || opponent.effects[PBEffects::MeanLook]>0
                miniscore*=1.4
              end
              if opponent.status==PBStatuses::BURN || opponent.status==PBStatuses::POISON
                miniscore*=1.3
              end
              if opponent.stages[PBStats::ACCURACY]<0
                minimini = 5*opponent.stages[PBStats::ACCURACY]
                minimini+=100
                minimini/=100.0
                miniscore*=minimini
              end
              miniscore/=100.0
              score*=miniscore
            end
          end
        end
      when 0x02 # Struggle
      when 0x03 # Sleep
        if opponent.pbCanSleep?(false) && opponent.effects[PBEffects::Yawn]==0
          miniscore=100
          miniscore*=1.3
          if attacker.pbHasMove?(:DREAMEATER) || attacker.pbHasMove?(:NIGHTMARE) ||
            (!attacker.abilitynulled && attacker.ability == PBAbilities::BADDREAMS)
            miniscore*=1.5
          end
          miniscore*=1.3 if attacker.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
          if attacker.pbHasMove?(:LEECHSEED)
            miniscore*=1.3
          end
          if attacker.pbHasMove?(:SUBSTITUTE)
            miniscore*=1.3
          end
          if opponent.hp==opponent.totalhp
            miniscore*=1.2
          end
          ministat = statchangecounter(opponent,1,7)
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          miniscore*=0.1 if checkAImoves([PBMoves::SLEEPTALK,PBMoves::SNORE],aimem)
          if !opponent.abilitynulled
            miniscore*=0.3 if opponent.ability == PBAbilities::NATURALCURE
            miniscore*=0.7 if opponent.ability == PBAbilities::MARVELSCALE
            miniscore*=0.5 if opponent.ability == PBAbilities::SYNCHRONIZE && attacker.status==0
          end
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL) ||
             roles.include?(PBMonRoles::CLERIC) || roles.include?(PBMonRoles::PIVOT)
            miniscore*=1.2
          end
          if (pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed) ^ (@trickroom!=0)
            miniscore*=1.3
          end
          if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::POISONHEAL) &&
             attacker.status==PBStatuses::POISON)
            miniscore*=1.2
          end
          if opponent.effects[PBEffects::Confusion]>0
            miniscore*=0.6
          end
          if opponent.effects[PBEffects::Attract]>=0
            miniscore*=0.7
          end
          if initialscores.length>0
            miniscore*=1.3 if hasbadmoves(initialscores,scoreindex,35)
          end
          if skill>=PBTrainerAI.bestSkill
            if move.id==(PBMoves::SING)
              if $fefieldeffect==6 # Big Top
                miniscore*=2
              end
              if (!opponent.abilitynulled && opponent.ability == PBAbilities::SOUNDPROOF)
                miniscore=0
              end
            end
            if move.id==(PBMoves::GRASSWHISTLE)
              if $fefieldeffect==2 # Grassy Terrain
                miniscore*=1.6
              end
              if (!opponent.abilitynulled && opponent.ability == PBAbilities::SOUNDPROOF)
                miniscore=0
              end
            end
          end
          if move.id==(PBMoves::SPORE)
            if (oppitemworks && opponent.item == PBItems::SAFETYGOGGLES) ||
               (!opponent.abilitynulled && opponent.ability == PBAbilities::OVERCOAT) || opponent.pbHasType?(:GRASS)
              miniscore=0
            end
          end
          if skill>=PBTrainerAI.bestSkill
            if move.id==(PBMoves::SLEEPPOWDER)
              if $fefieldeffect==8 || $fefieldeffect==10 # Swamp or Corrosive
                miniscore*=2
              end
              if (oppitemworks && opponent.item == PBItems::SAFETYGOGGLES) ||
                 (!opponent.abilitynulled && opponent.ability == PBAbilities::OVERCOAT) || opponent.pbHasType?(:GRASS)
                miniscore=0
              end
              if $fefieldeffect==33 # Flower Garden
                miniscore*=1.3
                if @doublebattle
                  miniscore*= 2
                end
              end
            end
            if move.id==(PBMoves::HYPNOSIS)
              if $fefieldeffect==37 # Psychic Terrain
                miniscore*=1.8
              end
            end
            if move.id==(PBMoves::DARKVOID)
              if $fefieldeffect==4 || $fefieldeffect==35 # Dark Crystal or New World
                miniscore*=2
              elsif $fefieldeffect==25 # Crystal Cavern
                miniscore*=1.6
              end
            end
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::HYDRATION) &&
             (pbWeather==PBWeather::RAINDANCE || $fefieldeffect == 21 || $fefieldeffect == 22)
            miniscore=0
          end
          if move.basedamage>0
            miniscore-=100
            if move.addlEffect.to_f != 100
              miniscore*=(move.addlEffect.to_f/100)
              if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
                miniscore*=2
              end
            end
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          else
            miniscore/=100.0
            score*=miniscore
          end
          if (move.id == PBMoves::DARKVOID) && !(attacker.species == PBSpecies::DARKRAI)
            score=0
          end
        else
          if move.basedamage==0
            score=0
          end
        end
      when 0x04 # Yawn
        if opponent.effects[PBEffects::Yawn]<=0 && opponent.pbCanSleep?(false)
          score*=1.2
          if attacker.pbHasMove?(:DREAMEATER) ||
            attacker.pbHasMove?(:NIGHTMARE) ||
            (!attacker.abilitynulled && attacker.ability == PBAbilities::BADDREAMS)
            score*=1.4
          end
          if opponent.hp==opponent.totalhp
            score*=1.2
          end
          ministat = statchangecounter(opponent,1,7)
          if ministat>0
            miniscore=10*ministat
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
          score*=0.1 if checkAImoves([PBMoves::SLEEPTALK,PBMoves::SNORE],aimem)
          if !opponent.abilitynulled
            score*=0.1 if opponent.ability == PBAbilities::NATURALCURE
            score*=0.8 if opponent.ability == PBAbilities::MARVELSCALE
          end
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL) ||
             roles.include?(PBMonRoles::CLERIC) || roles.include?(PBMonRoles::PIVOT)
            score*=1.2
          end
          if opponent.effects[PBEffects::Confusion]>0
            score*=0.4
          end
          if opponent.effects[PBEffects::Attract]>=0
            score*=0.5
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::HYDRATION) &&
             (pbWeather==PBWeather::RAINDANCE || $fefieldeffect == 21 || $fefieldeffect == 22)
            miniscore=0
          end
          if initialscores.length>0
            score*=1.3 if hasbadmoves(initialscores,scoreindex,30)
          end
        else
          score=0
        end
      when 0x05 # Poison
        if opponent.pbCanPoison?(false)
          miniscore=100
          miniscore*=1.2
          ministat=0
          ministat+=opponent.stages[PBStats::DEFENSE]
          ministat+=opponent.stages[PBStats::SPDEF]
          ministat+=opponent.stages[PBStats::EVASION]
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if !opponent.abilitynulled
            miniscore*=0.3 if opponent.ability == PBAbilities::NATURALCURE
            miniscore*=0.7 if opponent.ability == PBAbilities::MARVELSCALE
            miniscore*=0.2 if opponent.ability == PBAbilities::TOXICBOOST || opponent.ability == PBAbilities::GUTS || opponent.ability == PBAbilities::QUICKFEET
            miniscore*=0.1 if opponent.ability == PBAbilities::POISONHEAL || opponent.ability == PBAbilities::MAGICGUARD
            miniscore*=0.7 if opponent.ability == PBAbilities::SHEDSKIN
            miniscore*=1.1 if opponent.ability == PBAbilities::STURDY && move.basedamage>0
            miniscore*=0.5 if opponent.ability == PBAbilities::SYNCHRONIZE && attacker.status==0 && !attacker.pbHasType?(:POISON) && !attacker.pbHasType?(:STEEL)
          end
          miniscore*=0.2 if checkAImoves([PBMoves::FACADE],aimem)
          miniscore*=0.1 if checkAImoves([PBMoves::REST],aimem)
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            miniscore*=1.5
          end
          if initialscores.length>0
            miniscore*=1.2 if hasbadmoves(initialscores,scoreindex,30)
          end
          if attacker.pbHasMove?(:VENOSHOCK) ||
            attacker.pbHasMove?(:VENOMDRENCH) ||
            (!attacker.abilitynulled && attacker.ability == PBAbilities::MERCILESS)
            miniscore*=1.6
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=0.4
          end
          if skill>=PBTrainerAI.bestSkill
            if move.id==(PBMoves::SLUDGEWAVE)
              if $fefieldeffect==21 || $fefieldeffect==22 # Water Surface/Underwater
                poisonvar=false
                watervar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:WATER)
                    watervar=true
                  end
                  if mon.hasType?(:POISON)
                    poisonvar=true
                  end
                end
                if poisonvar && !watervar
                  miniscore*=1.75
                end
              end
            end
            if move.id==(PBMoves::SMOG) || move.id==(PBMoves::POISONGAS)
              if $fefieldeffect==3 # Misty Terrain
                poisonvar=false
                fairyvar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:FAIRY)
                    fairyvar=true
                  end
                  if mon.hasType?(:POISON)
                    poisonvar=true
                  end
                end
                if poisonvar && !fairyvar
                  miniscore*=1.75
                end
              end
            end
            if move.id==(PBMoves::POISONPOWDER)
              if $fefieldeffect==10 || ($fefieldeffect==33 && $fecounter>0)  # Corrosive/Flower Garden Stage 2+
                miniscore*=1.25
              end
              if (oppitemworks && opponent.item == PBItems::SAFETYGOGGLES) ||
                 (!opponent.abilitynulled && opponent.ability == PBAbilities::OVERCOAT) || opponent.pbHasType?(:GRASS)
                miniscore=0
              end
            end
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::HYDRATION) &&
             (pbWeather==PBWeather::RAINDANCE || $fefieldeffect == 21 || $fefieldeffect == 22)
            miniscore=0
          end
          if move.basedamage>0
            miniscore-=100
            if move.addlEffect.to_f != 100
              miniscore*=(move.addlEffect.to_f/100)
              if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
                miniscore*=2
              end
            end
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          else
            miniscore/=100.0
            score*=miniscore
          end
        else
          poisonvar=false
          fairyvar=false
          for mon in pbParty(attacker.index)
            next if mon.nil?
            if mon.hasType?(:FAIRY)
              fairyvar=true
            end
            if mon.hasType?(:POISON)
              poisonvar=true
            end
          end
          if skill>=PBTrainerAI.bestSkill
            if move.id==(PBMoves::SMOG)
              if $fefieldeffect==3 # Misty Terrain
                if poisonvar && !fairyvar
                  score*=1.75
                end
              end
            end
          end
          if move.basedamage<=0
            score=0
            if skill>=PBTrainerAI.bestSkill
              if move.id==(PBMoves::SMOG) || move.id==(PBMoves::POISONGAS)
                if $fefieldeffect==3 # Misty Terrain
                  if poisonvar && !fairyvar
                    score = 15
                  end
                end
              end
            end
          end
        end
      when 0x06 # Toxic
        if opponent.pbCanPoison?(false)
          miniscore=100
          miniscore*=1.3
          ministat=0
          ministat+=opponent.stages[PBStats::DEFENSE]
          ministat+=opponent.stages[PBStats::SPDEF]
          ministat+=opponent.stages[PBStats::EVASION]
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
            PBDebug.log(sprintf("kll2")) if $INTERNAL
          end
          miniscore*=2 if checkAIhealing(aimem)
          if !opponent.abilitynulled
            miniscore*=0.2 if opponent.ability == PBAbilities::NATURALCURE
            miniscore*=0.8 if opponent.ability == PBAbilities::MARVELSCALE
            miniscore*=0.2 if opponent.ability == PBAbilities::TOXICBOOST || opponent.ability == PBAbilities::GUTS || opponent.ability == PBAbilities::QUICKFEET
            miniscore*=0.1 if opponent.ability == PBAbilities::POISONHEAL || opponent.ability == PBAbilities::MAGICGUARD
            miniscore*=0.7 if opponent.ability == PBAbilities::SHEDSKIN
            miniscore*=1.1 if opponent.ability == PBAbilities::STURDY && move.basedamage>0
            miniscore*=0.5 if opponent.ability == PBAbilities::SYNCHRONIZE && attacker.status==0 && !attacker.pbHasType?(:POISON) && !attacker.pbHasType?(:STEEL)
          end
          miniscore*=0.3 if checkAImoves([PBMoves::FACADE],aimem)
          miniscore*=0.1 if checkAImoves([PBMoves::REST],aimem)
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            miniscore*=1.6
          end
          if initialscores.length>0
            miniscore*=1.3 if hasbadmoves(initialscores,scoreindex,30)
          end
          if attacker.pbHasMove?(:VENOSHOCK) ||
            attacker.pbHasMove?(:VENOMDRENCH) ||
            (!attacker.abilitynulled && attacker.ability == PBAbilities::MERCILESS)
            miniscore*=1.6
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=0.1
          end
          if move.id==(PBMoves::TOXIC)
            if attacker.pbHasType?(:POISON)
              miniscore*=1.1
            end
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::HYDRATION) &&
             (pbWeather==PBWeather::RAINDANCE || $fefieldeffect == 21 || $fefieldeffect == 22)
            miniscore=0
          end
          if move.basedamage>0
            miniscore-=100
            if move.addlEffect.to_f != 100
              miniscore*=(move.addlEffect.to_f/100)
              if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
                miniscore*=2
              end
            end
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          else
            miniscore/=100.0
            score*=miniscore
          end
        else
          if move.basedamage<=0
            PBDebug.log(sprintf("KILL")) if $INTERNAL
            score=0
          end
        end
      when 0x07 # Paralysis
        wavefail=false
        if move.id==(PBMoves::THUNDERWAVE)
          typemod=move.pbTypeModifier(move.type,attacker,opponent)
          if typemod==0
            wavefail=true
          end
        end
        if opponent.pbCanParalyze?(false) && !wavefail
          miniscore=100
          miniscore*=1.1 if attacker.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
          if opponent.hp==opponent.totalhp
            miniscore*=1.2
          end
          ministat=0
          ministat+=opponent.stages[PBStats::ATTACK]
          ministat+=opponent.stages[PBStats::SPATK]
          ministat+=opponent.stages[PBStats::SPEED]
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if !opponent.abilitynulled
            miniscore*=0.3 if opponent.ability == PBAbilities::NATURALCURE
            miniscore*=0.5 if opponent.ability == PBAbilities::MARVELSCALE
            miniscore*=0.2 if opponent.ability == PBAbilities::GUTS || opponent.ability == PBAbilities::QUICKFEET
            miniscore*=0.7 if opponent.ability == PBAbilities::SHEDSKIN
            miniscore*=0.5 if opponent.ability == PBAbilities::SYNCHRONIZE && attacker.status==0
          end
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL) || roles.include?(PBMonRoles::PIVOT)
            miniscore*=1.2
          end
          if roles.include?(PBMonRoles::TANK)
            miniscore*=1.3
          end
          if pbRoughStat(opponent,PBStats::SPEED,skill)>attacker.pbSpeed &&
             (pbRoughStat(opponent,PBStats::SPEED,skill)/2.0)<attacker.pbSpeed && @trickroom==0
            miniscore*=1.5
          end
          if pbRoughStat(opponent,PBStats::SPATK,skill)>pbRoughStat(opponent,PBStats::ATTACK,skill)
            miniscore*=1.1
          end
          count = -1
          sweepvar = false
          for i in pbParty(attacker.index)
            count+=1
            next if i.nil?
            temprole = pbGetMonRole(i,opponent,skill,count,pbParty(attacker.index))
            if temprole.include?(PBMonRoles::SWEEPER)
              sweepvar = true
            end
          end
          miniscore*=1.1 if sweepvar
          if opponent.effects[PBEffects::Confusion]>0
            miniscore*=1.1
          end
          if opponent.effects[PBEffects::Attract]>=0
            miniscore*=1.1
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=0.4
          end
          #if move.id==(PBMoves::NUZZLE)
          #  score+=40
          #end
          if skill>=PBTrainerAI.bestSkill
            if move.id==(PBMoves::ZAPCANNON)
              if $fefieldeffect==18 # Short-Circuit
                miniscore*=1.3
              end
            end
            if move.id==(PBMoves::DISCHARGE)
              ghostvar=false
              for mon in pbParty(attacker.index)
                next if mon.nil?
                if mon.hasType?(:GHOST)
                  ghostvar=true
                end
              end
              if $fefieldeffect==17# Factory
                miniscore*=1.1
                if ghostvar
                  miniscore*=1.3
                end
              end
              if $fefieldeffect==18  # Short-Circuit
                miniscore*=1.1
                if ghostvar
                  miniscore*=0.8
                end
              end
            end
            if move.id==(PBMoves::STUNSPORE)
              if $fefieldeffect==10 || ($fefieldeffect==33 && $fecounter>0)  # Corrosive/Flower Garden Stage 2+
                miniscore*=1.25
              end
              if (oppitemworks && opponent.item == PBItems::SAFETYGOGGLES) ||
                 (!opponent.abilitynulled && opponent.ability == PBAbilities::OVERCOAT) || opponent.pbHasType?(:GRASS)
                miniscore=0
              end
            end
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::HYDRATION) &&
             (pbWeather==PBWeather::RAINDANCE || $fefieldeffect == 21 || $fefieldeffect == 22)
            miniscore=0
          end
          if move.basedamage>0
            miniscore-=100
            if move.addlEffect.to_f != 100
              miniscore*=(move.addlEffect.to_f/100)
              if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
                miniscore*=2
              end
            end
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          else
            miniscore/=100.0
            score*=miniscore
          end
        else
          if move.basedamage==0
            score=0
          end
        end
      when 0x08 # Thunder + Paralyze
        if opponent.pbCanParalyze?(false) && opponent.effects[PBEffects::Yawn]<=0
          miniscore=100
          miniscore*=1.1 if attacker.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
          if opponent.hp==opponent.totalhp
            miniscore*=1.2
          end
          ministat=0
          ministat+=opponent.stages[PBStats::ATTACK]
          ministat+=opponent.stages[PBStats::SPATK]
          ministat+=opponent.stages[PBStats::SPEED]
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if !opponent.abilitynulled
            miniscore*=0.3 if opponent.ability == PBAbilities::NATURALCURE
            miniscore*=0.5 if opponent.ability == PBAbilities::MARVELSCALE
            miniscore*=0.2 if opponent.ability == PBAbilities::GUTS || opponent.ability == PBAbilities::QUICKFEET
            miniscore*=0.7 if opponent.ability == PBAbilities::SHEDSKIN
            miniscore*=0.5 if opponent.ability == PBAbilities::SYNCHRONIZE && attacker.status==0
          end
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL) || roles.include?(PBMonRoles::PIVOT)
            miniscore*=1.2
          end
          if roles.include?(PBMonRoles::TANK)
            miniscore*=1.3
          end
          if pbRoughStat(opponent,PBStats::SPEED,skill)>attacker.pbSpeed &&
             (pbRoughStat(opponent,PBStats::SPEED,skill)/2.0)<attacker.pbSpeed && @trickroom==0
            miniscore*=1.5
          end
          if pbRoughStat(opponent,PBStats::SPATK,skill)>pbRoughStat(opponent,PBStats::ATTACK,skill)
            miniscore*=1.1
          end
          count = -1
          sweepvar = false
          for i in pbParty(attacker.index)
            count+=1
            next if i.nil?
            temprole = pbGetMonRole(i,opponent,skill,count,pbParty(attacker.index))
            if temprole.include?(PBMonRoles::SWEEPER)
              sweepvar = true
            end
          end
          miniscore*=1.1 if sweepvar
          if opponent.effects[PBEffects::Confusion]>0
            miniscore*=1.1
          end
          if opponent.effects[PBEffects::Attract]>=0
            miniscore*=1.1
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=0.4
          end
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
          invulmove=$pkmn_move[opponent.effects[PBEffects::TwoTurnAttack]][0]
          if invulmove==0xC9 || invulmove==0xCC || invulmove==0xCE
            if (pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed) ^ (@trickroom!=0)
              score*=2
            end
          end
          if (pbRoughStat(opponent,PBStats::SPEED,skill)>attacker.pbSpeed) ^ (@trickroom!=0)
            score*=1.2 if checkAImoves(PBStuff::TWOTURNAIRMOVE,aimem)
          end
        end
      when 0x09 # Paralysis + Flinch
        if opponent.pbCanParalyze?(false)
          miniscore=100
          miniscore*=1.1 if attacker.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
          if opponent.hp==opponent.totalhp
            miniscore*=1.1
          end
          ministat=0
          ministat+=opponent.stages[PBStats::ATTACK]
          ministat+=opponent.stages[PBStats::SPATK]
          ministat+=opponent.stages[PBStats::SPEED]
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if !opponent.abilitynulled
            miniscore*=0.3 if opponent.ability == PBAbilities::NATURALCURE
            miniscore*=0.5 if opponent.ability == PBAbilities::MARVELSCALE
            miniscore*=0.2 if opponent.ability == PBAbilities::GUTS || opponent.ability == PBAbilities::QUICKFEET
            miniscore*=0.7 if opponent.ability == PBAbilities::SHEDSKIN
            miniscore*=0.5 if opponent.ability == PBAbilities::SYNCHRONIZE && attacker.status==0
          end
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL) || roles.include?(PBMonRoles::PIVOT)
            miniscore*=1.2
          end
          if roles.include?(PBMonRoles::TANK)
            miniscore*=1.1
          end
          if pbRoughStat(opponent,PBStats::SPEED,skill)>attacker.pbSpeed &&
             (pbRoughStat(opponent,PBStats::SPEED,skill)/2)<attacker.pbSpeed && @trickroom==0
            miniscore*=1.1
          end
          if pbRoughStat(opponent,PBStats::SPATK,skill)>pbRoughStat(opponent,PBStats::ATTACK,skill)
            miniscore*=1.1
          end
          count = -1
          sweepvar = false
          for i in pbParty(attacker.index)
            count+=1
            next if i.nil?
            temprole = pbGetMonRole(i,opponent,skill,count,pbParty(attacker.index))
            if temprole.include?(PBMonRoles::SWEEPER)
              sweepvar = true
            end
          end
          miniscore*=1.1 if sweepvar
          if opponent.effects[PBEffects::Confusion]>0
            miniscore*=1.1
          end
          if opponent.effects[PBEffects::Attract]>=0
            miniscore*=1.1
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=0.4
          end
          if opponent.effects[PBEffects::Substitute]==0 && !(!opponent.abilitynulled && opponent.ability == PBAbilities::INNERFOCUS)
            if (pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed) ^ (@trickroom!=0)
              miniscore*=1.1
              if skill>=PBTrainerAI.bestSkill
                if $fefieldeffect==14 # Rocky
                  miniscore*=1.1
                end
              end
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::STEADFAST)
              miniscore*=0.3
            end
          end
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
        end
      when 0x0A # Burn
        if opponent.pbCanBurn?(false)
          miniscore=100
          miniscore*=1.2
          ministat=0
          ministat+=opponent.stages[PBStats::ATTACK]
          ministat+=opponent.stages[PBStats::SPATK]
          ministat+=opponent.stages[PBStats::SPEED]
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if !opponent.abilitynulled
            miniscore*=0.3 if opponent.ability == PBAbilities::NATURALCURE
            miniscore*=0.7 if opponent.ability == PBAbilities::MARVELSCALE
            miniscore*=0.1 if opponent.ability == PBAbilities::GUTS || opponent.ability == PBAbilities::FLAREBOOST
            miniscore*=0.7 if opponent.ability == PBAbilities::SHEDSKIN
            miniscore*=0.5 if opponent.ability == PBAbilities::SYNCHRONIZE && attacker.status==0
            miniscore*=0.5 if opponent.ability == PBAbilities::MAGICGUARD
            miniscore*=0.3 if opponent.ability == PBAbilities::QUICKFEET
            miniscore*=1.1 if opponent.ability == PBAbilities::STURDY && move.basedamage>0
          end
          miniscore*=0.1 if checkAImoves([PBMoves::REST],aimem)
          miniscore*=0.3 if checkAImoves([PBMoves::FACADE],aimem)
          if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
            miniscore*=1.4
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=0.4
          end
          if skill>=PBTrainerAI.bestSkill
            if move.id==(PBMoves::HEATWAVE) || move.id==(PBMoves::SEARINGSHOT) || move.id==(PBMoves::LAVAPLUME)
              if $fefieldeffect==2 || $fefieldeffect==15 || ($fefieldeffect==33 && $fecounter>1)  # Grassy/Forest/Flower Garden
                roastvar=false
                firevar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:GRASS) || mon.hasType?(:BUG)
                    roastvar=true
                  end
                  if mon.hasType?(:FIRE)
                    firevar=true
                  end
                end
                if firevar && !roastvar
                  miniscore*=2
                end
              end
              if $fefieldeffect==16 # Superheated
                firevar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:FIRE)
                    firevar=true
                  end
                end
                if firevar
                  miniscore*=2
                end
              end
              if $fefieldeffect==11 # Corrosive Mist
                poisonvar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:POISON)
                    poisonvar=true
                  end
                end
                if !poisonvar
                  miniscore*=1.2
                end
                if (attacker.hp.to_f)/attacker.totalhp<0.2
                  miniscore*=2
                end
                count=0
                for mon in pbParty(opponent.index)
                  next if mon.nil?
                  count+=1 if mon.hp>0
                end
                if count==1
                  miniscore*=5
                end
              end
              if $fefieldeffect==13 || $fefieldeffect==28 # Icy/Snowy Mountain
                icevar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:ICE)
                    icevar=true
                  end
                end
                if !icevar
                  miniscore*=1.5
                end
              end
            end
            if move.id==(PBMoves::WILLOWISP)
              if $fefieldeffect==7 # Burning
                miniscore*=1.5
              end
            end
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::HYDRATION) &&
             (pbWeather==PBWeather::RAINDANCE || $fefieldeffect == 21 || $fefieldeffect == 22)
            miniscore=0
          end
          if move.basedamage>0
            miniscore-=100
            if move.addlEffect.to_f != 100
              miniscore*=(move.addlEffect.to_f/100)
              if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
                miniscore*=2
              end
            end
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          else
            miniscore/=100.0
            score*=miniscore
          end
        else
          if move.basedamage==0
            score=0
          end
        end
      when 0x0B # Burn + Flinch
        if opponent.pbCanBurn?(false)
          miniscore=100
          ministat=0
          ministat+=opponent.stages[PBStats::ATTACK]
          ministat+=opponent.stages[PBStats::SPATK]
          ministat+=opponent.stages[PBStats::SPEED]
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if !opponent.abilitynulled
            miniscore*=0.3 if opponent.ability == PBAbilities::NATURALCURE
            miniscore*=0.7 if opponent.ability == PBAbilities::MARVELSCALE
            miniscore*=0.1 if opponent.ability == PBAbilities::GUTS || opponent.ability == PBAbilities::FLAREBOOST
            miniscore*=0.7 if opponent.ability == PBAbilities::SHEDSKIN
            miniscore*=0.5 if opponent.ability == PBAbilities::SYNCHRONIZE && attacker.status==0
            miniscore*=0.5 if opponent.ability == PBAbilities::MAGICGUARD
            miniscore*=0.3 if opponent.ability == PBAbilities::QUICKFEET
            miniscore*=1.1 if opponent.ability == PBAbilities::STURDY && move.basedamage>0
          end
          miniscore*=0.1 if checkAImoves([PBMoves::REST],aimem)
          miniscore*=0.3 if checkAImoves([PBMoves::FACADE],aimem)
          if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
            miniscore*=1.4
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=0.4
          end
          if opponent.effects[PBEffects::Substitute]==0 && !(!opponent.abilitynulled && opponent.ability == PBAbilities::INNERFOCUS)
            if (pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed) ^ (@trickroom!=0)
              miniscore*=1.1
              if skill>=PBTrainerAI.bestSkill
                if $fefieldeffect==14 # Rocky
                  miniscore*=1.1
                end
              end
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::STEADFAST)
              miniscore*=0.3
            end
          end
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
        end
      when 0x0C # Freeze
        if opponent.pbCanFreeze?(false)
          miniscore=100
          miniscore*=1.2
          miniscore*=0 if checkAImoves(PBStuff::UNFREEZEMOVE,aimem)
          miniscore*=1.2 if attacker.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
          miniscore*=1.2 if checkAIhealing(aimem)
          ministat = statchangecounter(opponent,1,7)
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if !opponent.abilitynulled
            miniscore*=0.3 if opponent.ability == PBAbilities::NATURALCURE
            miniscore*=0.8 if opponent.ability == PBAbilities::MARVELSCALE
            miniscore*=0.5 if opponent.ability == PBAbilities::SYNCHRONIZE && attacker.status==0
          end
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==13 # Icy Field
              miniscore*=2
            end
          end
          score*=miniscore
        end
      when 0x0D # Blizzard Freeze
        if opponent.pbCanFreeze?(false)
          miniscore=100
          miniscore*=1.4
          miniscore*=0 if checkAImoves(PBStuff::UNFREEZEMOVE,aimem)
          miniscore*=1.3 if attacker.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
          miniscore*=1.2 if checkAIhealing(aimem)
          ministat = statchangecounter(opponent,1,7)
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if !opponent.abilitynulled
            miniscore*=0.3 if opponent.ability == PBAbilities::NATURALCURE
            miniscore*=0.8 if opponent.ability == PBAbilities::MARVELSCALE
            miniscore*=0.5 if opponent.ability == PBAbilities::SYNCHRONIZE && attacker.status==0
          end
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==13 # Icy Field
              miniscore*=2
            end
          end
          score*=miniscore
        #  if pbWeather == PBWeather::HAIL
        #    score*=1.3
        #  end
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==26 # Murkwater Surface
              icevar=false
              murkvar=false
              for mon in pbParty(attacker.index)
                next if mon.nil?
                if mon.hasType?(:ICE)
                  icevar=true
                end
                if mon.hasType?(:POISON) || mon.hasType?(:WATER)
                  murkvar=true
                end
              end
              if icevar
                score*=1.3
              end
              if !murkvar
                score*=1.3
              else
                score*=0.5
              end
            end
            if $fefieldeffect==21 # Water Surface
              icevar=false
              wayervar=false
              for mon in pbParty(attacker.index)
                next if mon.nil?
                if mon.hasType?(:ICE)
                  icevar=true
                end
                if mon.hasType?(:WATER)
                  watervar=true
                end
              end
              if icevar
                score*=1.3
              end
              if !watervar
                score*=1.3
              else
                score*=0.5
              end
            end
            if $fefieldeffect==27 # Mountain
              icevar=false
              for mon in pbParty(attacker.index)
                next if mon.nil?
                if mon.hasType?(:ICE)
                  icevar=true
                end
              end
              if icevar
                score*=1.3
              end
            end
            if $fefieldeffect==16 # Superheated Field
              icevar=false
              firevar=false
              for mon in pbParty(attacker.index)
                next if mon.nil?
                if mon.hasType?(:ICE)
                  icevar=true
                end
                if mon.hasType?(:FIRE)
                  firevar=true
                end
              end
              if icevar
                score*=1.3
              end
              if !firevar
                score*=1.3
              else
                score*=0.5
              end
            end
            if $fefieldeffect==24 # Glitch
              score*=1.2
            end
          end
        end
      when 0x0E # Freeze + Flinch
        if opponent.pbCanFreeze?(false)
          miniscore=100
          miniscore*=1.1
          miniscore*=0 if checkAImoves(PBStuff::UNFREEZEMOVE,aimem)
          miniscore*=1.3 if attacker.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
          miniscore*=1.2 if checkAIhealing(aimem)
          ministat = statchangecounter(opponent,1,7)
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if !opponent.abilitynulled
            miniscore*=0.3 if opponent.ability == PBAbilities::NATURALCURE
            miniscore*=0.8 if opponent.ability == PBAbilities::MARVELSCALE
            miniscore*=0.5 if opponent.ability == PBAbilities::SYNCHRONIZE && attacker.status==0
          end
          if opponent.effects[PBEffects::Substitute]==0 && !(!opponent.abilitynulled && opponent.ability == PBAbilities::INNERFOCUS)
            if (pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed) ^ (@trickroom!=0)
              miniscore*=1.1
              if skill>=PBTrainerAI.bestSkill
                if $fefieldeffect==14 # Rocky
                  miniscore*=1.1
                end
              end
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::STEADFAST)
              miniscore*=0.3
            end
          end
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==13 # Icy Field
              miniscore*=2
            end
          end
          score*=miniscore
        end
      when 0x0F # Flinch
        if opponent.effects[PBEffects::Substitute]==0 && !(!opponent.abilitynulled && opponent.ability == PBAbilities::INNERFOCUS)
          if (pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed)  ^ (@trickroom!=0)
            miniscore=100
            miniscore*=1.3
            if skill>=PBTrainerAI.bestSkill
              if $fefieldeffect==14 # Rocky
                miniscore*=1.2
              end
              if move.id==(PBMoves::DARKPULSE) && $fefieldeffect==25 # Crystal Cavern
                miniscore*=1.3
                dragonvar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:DRAGON)
                    dragonvar=true
                  end
                end
                if !dragonvar
                  miniscore*=1.3
                end
              end
            end
            if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN ||
               (pbWeather == PBWeather::HAIL && !opponent.pbHasType?(:ICE)) ||
               (pbWeather == PBWeather::SANDSTORM && !opponent.pbHasType?(:ROCK) && !opponent.pbHasType?(:GROUND) && !opponent.pbHasType?(:STEEL)) ||
               opponent.effects[PBEffects::LeechSeed]>-1 || opponent.effects[PBEffects::Curse]
              miniscore*=1.1
              if opponent.effects[PBEffects::Toxic]>0
                miniscore*=1.2
              end
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::STEADFAST)
              miniscore*=0.3
            end
            miniscore-=100
            if move.addlEffect.to_f != 100
              miniscore*=(move.addlEffect.to_f/100)
              if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
                miniscore*=2
              end
            end
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
        end
      when 0x10 # Stomp
        if opponent.effects[PBEffects::Substitute]==0 && !(!opponent.abilitynulled && opponent.ability == PBAbilities::INNERFOCUS)
          if (pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed) ^ (@trickroom!=0)
            miniscore=100
            miniscore*=1.3
            if skill>=PBTrainerAI.bestSkill
              if $fefieldeffect==14 # Rocky
                miniscore*=1.2
              end
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::STEADFAST)
              miniscore*=0.3
            end
            miniscore-=100
            if move.addlEffect.to_f != 100
              miniscore*=(move.addlEffect.to_f/100)
              if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
                miniscore*=2
              end
            end
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
        end
        score*=2 if opponent.effects[PBEffects::Minimize]
      when 0x11 # Snore
        if attacker.status==PBStatuses::SLEEP
          score*=2
          if opponent.effects[PBEffects::Substitute]!=0
            score*=1.3
          end
          if !(!opponent.abilitynulled && opponent.ability == PBAbilities::INNERFOCUS) &&
             ((pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed) ^ (@trickroom!=0))
            miniscore=100
            miniscore*=1.3
            if skill>=PBTrainerAI.bestSkill
              if $fefieldeffect==14 # Rocky
                miniscore*=1.2
              end
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::STEADFAST)
              miniscore*=0.3
            end
            miniscore-=100
            if move.addlEffect.to_f != 100
              miniscore*=(move.addlEffect.to_f/100)
              if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
                miniscore*=2
              end
            end
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
        else
          score=0
        end
      when 0x12 # Fake Out
        if attacker.turncount==0
          if opponent.effects[PBEffects::Substitute]==0 &&
             !(!opponent.abilitynulled && opponent.ability == PBAbilities::INNERFOCUS)
            if score>1
              score+=115
            end
            if skill>=PBTrainerAI.bestSkill
              if $fefieldeffect==14 # Rocky
                score*=1.2
              end
            end
            if @doublebattle
              score*=0.7
            end
            if (attitemworks && attacker.item == PBItems::NORMALGEM)
              score*=1.1
              if (!attacker.abilitynulled && attacker.ability == PBAbilities::UNBURDEN)
                score*=1.5
              end
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::STEADFAST)
              score*=0.3
            end
            score*=0.3 if checkAImoves([PBMoves::ENCORE],aimem)
          end
        else
          score=0
        end
      when 0x13 # Confusion
        if opponent.pbCanConfuse?(false)
          miniscore=100
          miniscore*=1.2
          ministat=0
          ministat+=opponent.stages[PBStats::ATTACK]
          if ministat>0
            minimini=10*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
            miniscore*=1.2
          end
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            miniscore*=1.3
          end
          if opponent.effects[PBEffects::Attract]>=0
            miniscore*=1.1
          end
          if opponent.status==PBStatuses::PARALYSIS
            miniscore*=1.1
          end
          if opponent.effects[PBEffects::Yawn]>0 || opponent.status==PBStatuses::SLEEP
            miniscore*=0.4
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::TANGLEDFEET)
            miniscore*=0.7
          end
          if attacker.pbHasMove?(:SUBSTITUTE)
            miniscore*=1.2
            if attacker.effects[PBEffects::Substitute]>0
              miniscore*=1.3
            end
          end
          if skill>=PBTrainerAI.bestSkill
            if move.id==(PBMoves::SIGNALBEAM)
              if $fefieldeffect==30 # Mirror Arena
                if (attacker.stages[PBStats::ACCURACY] < 0 || opponent.stages[PBStats::EVASION] > 0 ||
                   (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER) || (oppitemworks && opponent.item == PBItems::LAXINCENSE) ||
                   ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
                   ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL) ||
                   opponent.vanished) &&
                   !(!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD) &&
                   !(!attacker.abilitynulled && attacker.ability == PBAbilities::NOGUARD)
                  miniscore*=2
                end
              end
            end
            if move.id==(PBMoves::SWEETKISS)
              if $fefieldeffect==3 # Misty
                miniscore*=1.25
              end
              if $fefieldeffect==31 # Fairy Tale
                if opponent.status==PBStatuses::SLEEP
                  miniscore*=0.2
                end
              end
            end
          end
          if initialscores.length>0
            miniscore*=1.4 if hasbadmoves(initialscores,scoreindex,40)
          end
          if move.basedamage>0
            miniscore-=100
            if move.addlEffect.to_f != 100
              miniscore*=(move.addlEffect.to_f/100)
              if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
                miniscore*=2
              end
            end
            miniscore+=100
          end
          miniscore/=100.0
          score*=miniscore
        else
          if move.basedamage<=0
            score=0
          end
        end
      when 0x14 # Chatter
        #This is no longer used, Chatter works off of the standard confusion
        #function code, 0x13
      when 0x15 # Hurricane
        if opponent.pbCanConfuse?(false)
          miniscore=100
          miniscore*=1.2
          ministat=0
          ministat+=opponent.stages[PBStats::ATTACK]
          if ministat>0
            minimini=10*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
            miniscore*=1.2
          end
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            miniscore*=1.3
          end
          if opponent.effects[PBEffects::Attract]>=0
            miniscore*=1.1
          end
          if opponent.status==PBStatuses::PARALYSIS
            miniscore*=1.1
          end
          if opponent.effects[PBEffects::Yawn]>0 || opponent.status==PBStatuses::SLEEP
            miniscore*=0.4
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::TANGLEDFEET)
            miniscore*=0.7
          end
          if attacker.pbHasMove?(:SUBSTITUTE)
            miniscore*=1.2
            if attacker.effects[PBEffects::Substitute]>0
              miniscore*=1.3
            end
          end
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==3 # Misty
              score*=1.3
              fairyvar=false
              for mon in pbParty(attacker.index)
                next if mon.nil?
                if mon.hasType?(:FAIRY)
                  fairyvar=true
                end
              end
              if !fairyvar
                score*=1.3
              else
                score*=0.6
              end
            end
            if $fefieldeffect==7 # Burning
              firevar=false
              for mon in pbParty(attacker.index)
                next if mon.nil?
                if mon.hasType?(:FIRE)
                  firevar=true
                end
              end
              if !firevar
                score*=1.8
              else
                score*=0.5
              end
            end
            if $fefieldeffect==11 # Corrosive Mist
              poisonvar=false
              for mon in pbParty(attacker.index)
                next if mon.nil?
                if mon.hasType?(:POISON)
                  poisonvar=true
                end
              end
              if !poisonvar
                score*=3
              else
                score*=0.8
              end
            end
          end
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
        end
        invulmove=$pkmn_move[opponent.effects[PBEffects::TwoTurnAttack]][0] #the function code of the current move
        if invulmove==0xC9 || invulmove==0xCC || invulmove==0xCE
          if (pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed) ^ (@trickroom!=0)
            score*=2
          end
        end
        if (pbRoughStat(opponent,PBStats::SPEED,skill)>attacker.pbSpeed) ^ (@trickroom!=0)
          score*=1.2 if checkAImoves(PBStuff::TWOTURNAIRMOVE,aimem)
        end
      when 0x16 # Attract
        canattract=true
        agender=attacker.gender
        ogender=opponent.gender
        if agender==2 || ogender==2 || agender==ogender # Pokemon are genderless or same gender
          canattract=false
        elsif opponent.effects[PBEffects::Attract]>=0
          canattract=false
        elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::OBLIVIOUS)
          canattract=false
        elsif pbCheckSideAbility(:AROMAVEIL,opponent)!=nil && !(opponent.moldbroken)
          canattract = false
        end
        if canattract
          score*=1.2
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CUTECHARM)
            score*=0.7
          end
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            score*=1.3
          end
          if opponent.effects[PBEffects::Confusion]>0
            score*=1.1
          end
          if opponent.status==PBStatuses::PARALYSIS
            score*=1.1
          end
          if opponent.effects[PBEffects::Yawn]>0 || opponent.status==PBStatuses::SLEEP
            score*=0.5
          end
          if (oppitemworks && opponent.item == PBItems::DESTINYKNOT)
            score*=0.1
          end
          if attacker.pbHasMove?(:SUBSTITUTE)
            score*=1.2
            if attacker.effects[PBEffects::Substitute]>0
              score*=1.3
            end
          end
        else
          score=0
        end
      when 0x17 # Tri Attack
        if opponent.status==0
          miniscore=100
          miniscore*=1.4
          ministat = statchangecounter(opponent,1,7)
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if !opponent.abilitynulled
            miniscore*=0.3 if opponent.ability == PBAbilities::NATURALCURE
            miniscore*=0.7 if opponent.ability == PBAbilities::MARVELSCALE
            miniscore*=0.3 if opponent.ability == PBAbilities::GUTS || opponent.ability == PBAbilities::QUICKFEET
            miniscore*=0.7 if opponent.ability == PBAbilities::SHEDSKIN
            miniscore*=0.5 if opponent.ability == PBAbilities::SYNCHRONIZE && attacker.status==0
          end
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
        end
      when 0x18 # Refresh
        if attacker.status==PBStatuses::BURN || attacker.status==PBStatuses::POISON || attacker.status==PBStatuses::PARALYSIS
          score*=3
        else
          score=0
        end
        if (attacker.hp.to_f)/attacker.totalhp>0.5
          score*=1.5
        else
          score*=0.3
        end
        if opponent.effects[PBEffects::Yawn]>0
          score*=0.1
        end
        score*=0.1 if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
        if opponent.effects[PBEffects::Toxic]>2
          score*=1.3
        end
        score*=1.3 if checkAImoves([PBMoves::HEX],aimem)
      when 0x19 # Aromatherapy
        party=pbParty(attacker.index)
        statuses=0
        for i in 0...party.length
          statuses+=1 if party[i] && party[i].status!=0
        end
        if statuses!=0
          score*=1.2
          statuses=0
          count=-1
          for i in 0...party.length
            count+=1
            next if party[i].nil?
            temproles = pbGetMonRole(party[i],opponent,skill,count,party)
            if party[i].status==PBStatuses::POISON && (party[i].ability == PBAbilities::POISONHEAL)
              score*=0.5
            end
            if (party[i].ability == PBAbilities::GUTS) ||
               (party[i].ability == PBAbilities::QUICKFEET) || party[i].knowsMove?(:FACADE)
              score*=0.8
            end
            if party[i].status==PBStatuses::SLEEP || party[i].status==PBStatuses::FROZEN
              score*=1.1
            end
            if (temproles.include?(PBMonRoles::PHYSICALWALL) ||
               temproles.include?(PBMonRoles::SPECIALWALL)) && party[i].status==PBStatuses::POISON
              score*=1.2
            end
            if temproles.include?(PBMonRoles::SWEEPER) && party[i].status==PBStatuses::PARALYSIS
              score*=1.2
            end
            if party[i].attack>party[i].spatk && party[i].status==PBStatuses::BURN
              score*=1.2
            end
          end
          if attacker.status!=0
            score*=1.3
          end
          if attacker.effects[PBEffects::Toxic]>2
            score*=1.3
          end
          score*=1.1 if checkAIhealing(aimem)
        else
          score=0
        end
      when 0x1A # Safeguard
        if attacker.pbOwnSide.effects[PBEffects::Safeguard]<=0 &&
           ((pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed) ^ (@trickroom!=0)) &&
           attacker.status==0 && !roles.include?(PBMonRoles::STATUSABSORBER)
          score+=50 if checkAImoves([PBMoves::SPORE],aimem)
        end
      when 0x1B # Psycho Shift
        if attacker.status!=0 && opponent.effects[PBEffects::Substitute]<=0
          score*=1.3
          if opponent.status==0 && opponent.effects[PBEffects::Yawn]==0
            score*=1.3
            if attacker.status==PBStatuses::BURN && opponent.pbCanBurn?(false)
              if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
                score*=1.2
              end
              if (!opponent.abilitynulled && opponent.ability == PBAbilities::FLAREBOOST)
                score*=0.7
              end
            end
            if attacker.status==PBStatuses::PARALYSIS && opponent.pbCanParalyze?(false)
              if pbRoughStat(opponent,PBStats::ATTACK,skill)<pbRoughStat(opponent,PBStats::SPATK,skill)
                score*=1.1
              end
              if (pbRoughStat(opponent,PBStats::SPEED,skill)>attacker.pbSpeed) ^ (@trickroom!=0)
                score*=1.2
              end
            end
            if attacker.status==PBStatuses::POISON && opponent.pbCanPoison?(false)
              score*=1.1 if checkAIhealing(aimem)
              if attacker.effects[PBEffects::Toxic]>0
                score*=1.4
              end
              if (!opponent.abilitynulled && opponent.ability == PBAbilities::POISONHEAL)
                score*=0.3
              end
              if (!opponent.abilitynulled && opponent.ability == PBAbilities::TOXICBOOST)
                score*=0.7
              end
            end
            if !opponent.abilitynulled && (opponent.ability == PBAbilities::SHEDSKIN ||
               opponent.ability == PBAbilities::NATURALCURE ||
               opponent.ability == PBAbilities::GUTS ||
               opponent.ability == PBAbilities::QUICKFEET ||
               opponent.ability == PBAbilities::MARVELSCALE)
              score*=0.7
            end
            score*=0.7 if checkAImoves([PBMoves::HEX],aimem)
          end
          if attacker.pbHasMove?(:HEX)
            score*=1.3
          end
        else
          score=0
        end
      when 0x1C # Howl
        miniscore = setupminiscore(attacker,opponent,skill,move,true,1,false,initialscores,scoreindex)
        if attacker.stages[PBStats::SPEED]<0
          ministat=attacker.stages[PBStats::SPEED]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        ministat+=opponent.stages[PBStats::SPATK]
        ministat+=opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore*=1.3 if checkAIhealing(aimem)
        if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          miniscore*=1.5
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.3
        end
        if attacker.status==PBStatuses::BURN || attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.5
        end
        miniscore*=0.3 if checkAImoves([PBMoves::FOULPLAY],aimem)
        if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
          miniscore*=0.6
        end
        if skill>=PBTrainerAI.bestSkill
          if move.id==(PBMoves::MEDITATE)
            if $fefieldeffect==9 # Rainbow
              miniscore*=2
            end
            if $fefieldeffect==20 || $fefieldeffect==37 # Ashen Beach/Psychic Terrain
              miniscore*=3
            end
          end
        end
        if move.basedamage>0
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          if attacker.pbTooHigh?(PBStats::ATTACK)
            miniscore=1
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            miniscore*=0.5
          end
        else
          miniscore/=100.0
          if attacker.pbTooHigh?(PBStats::ATTACK)
            miniscore=0
          end
          miniscore*=0 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            miniscore*=0
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
            miniscore=1
          end
        end
        score*=miniscore
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
        if move.basedamage==0 && $fefieldeffect!=37
          physmove=false
          for j in attacker.moves
            if j.pbIsPhysical?(j.type)
              physmove=true
            end
          end
          score=0 if !physmove
        end
      when 0x1D # Harden
        miniscore = setupminiscore(attacker,opponent,skill,move,false,2,false,initialscores,scoreindex)
        if attacker.stages[PBStats::DEFENSE]>0
          ministat=attacker.stages[PBStats::DEFENSE]
          minimini=-15*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
          miniscore*=1.3
        end
        if skill>=PBTrainerAI.mediumSkill
          miniscore*=0.3 if (checkAIdamage(aimem,attacker,opponent,skill).to_f/attacker.hp)<0.12 && (aimem.length > 0)
        end
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.3
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.2
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        if move.basedamage>0
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          if attacker.pbTooHigh?(PBStats::DEFENSE)
            miniscore=1
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            miniscore*=0.5
          end
        else
          miniscore/=100.0
          if attacker.pbTooHigh?(PBStats::DEFENSE)
            miniscore=0
          end
          miniscore*=0 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            miniscore*=0
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
            miniscore=1
          end
        end
        score*=miniscore
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x1E # Defense Curl
        miniscore = setupminiscore(attacker,opponent,skill,move,false,2,false,initialscores,scoreindex)
        if attacker.stages[PBStats::DEFENSE]>0
          ministat=attacker.stages[PBStats::DEFENSE]
          minimini=-15*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
          miniscore*=1.3
        end
        if skill>=PBTrainerAI.mediumSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if (maxdam.to_f/attacker.hp)<0.12 && (aimem.length > 0)
            miniscore*=0.3
          end
        end
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.3
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.2
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        if move.basedamage>0
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          if attacker.pbTooHigh?(PBStats::DEFENSE)
            miniscore=1
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            miniscore*=0.5
          end
        else
          miniscore/=100.0
          if attacker.pbTooHigh?(PBStats::DEFENSE)
            miniscore=0
          end
          miniscore*=0 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            miniscore*=0
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
            miniscore=1
          end
        end
        score*=miniscore
        if attacker.pbHasMove?(:ROLLOUT) && attacker.effects[PBEffects::DefenseCurl]==false
          score*=1.3
        end
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x1F # Flame Charge
        miniscore = setupminiscore(attacker,opponent,skill,move,true,16,false,initialscores,scoreindex)
        if attacker.attack<attacker.spatk
          if attacker.stages[PBStats::SPATK]<0
            ministat=attacker.stages[PBStats::SPATK]
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
        else
          if attacker.stages[PBStats::ATTACK]<0
            ministat=attacker.stages[PBStats::ATTACK]
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
        end
        ministat=0
        ministat+=opponent.stages[PBStats::DEFENSE]
        ministat+=opponent.stages[PBStats::SPDEF]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end

        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.3
        end
        if @trickroom!=0 || checkAImoves([PBMoves::TRICKROOM],aimem)
          miniscore*=0.2
        end
        if attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.2
        end
        if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::MOXIE)
          miniscore*=1.3
        end
        if move.basedamage>0
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          if attacker.pbTooHigh?(PBStats::SPEED)
            miniscore=1
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            miniscore*=0.5
          end
        else
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
            miniscore*=0.6
          end
          miniscore/=100.0
          if attacker.pbTooHigh?(PBStats::SPEED)
            miniscore=0
          end
          miniscore*=0 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            miniscore*=0
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
            miniscore=1
          end
        end
        score*=miniscore
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x20 # Charge Beam
        miniscore = setupminiscore(attacker,opponent,skill,move,true,4,false,initialscores,scoreindex)
        if attacker.stages[PBStats::SPEED]<0
          ministat=attacker.stages[PBStats::SPEED]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        ministat+=opponent.stages[PBStats::SPATK]
        ministat+=opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore*=1.3 if checkAIhealing(aimem)
        if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          miniscore*=1.5
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.3
        end
        if attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.5
        end
        if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
          miniscore*=0.6
        end
        if skill>=PBTrainerAI.bestSkill
          if move.id==(PBMoves::CHARGEBEAM)
            if $fefieldeffect==18 # Short Circuit
              miniscore*=1.2
            end
          end
        end
        if move.basedamage>0
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          if attacker.pbTooHigh?(PBStats::SPATK)
            miniscore=1
          end
          if miniscore<1
            miniscore = 1
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            miniscore*=0.5
          end
        else
          miniscore/=100.0
          if attacker.pbTooHigh?(PBStats::SPATK)
            miniscore=0
          end
          miniscore*=0 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            miniscore*=0
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
            miniscore=1
          end
        end
        score*=miniscore
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
        if move.basedamage==0
          specmove=false
          for j in attacker.moves
            if j.pbIsSpecial?(j.type)
              specmove=true
            end
          end
          score=0 if !specmove
        end
      when 0x21 # Charge
        miniscore = setupminiscore(attacker,opponent,skill,move,false,8,false,initialscores,scoreindex)
        if attacker.stages[PBStats::SPDEF]>0
          ministat=attacker.stages[PBStats::SPDEF]
          minimini=-15*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if pbRoughStat(opponent,PBStats::ATTACK,skill)<pbRoughStat(opponent,PBStats::SPATK,skill)
          miniscore*=1.1
        end
        if skill>=PBTrainerAI.mediumSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if (maxdam.to_f/attacker.hp)<0.12 && (aimem.length > 0)
            miniscore*=0.3
          end
        end
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.3
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.2
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        if move.basedamage>0
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          if attacker.pbTooHigh?(PBStats::SPDEF)
            miniscore=1
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            miniscore*=0.5
          end
        else
          miniscore/=100.0
          if attacker.pbTooHigh?(PBStats::SPDEF)
            miniscore=0
          end
          miniscore*=0 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            miniscore*=0
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
            miniscore=1
          end
        end
        elecmove=false
        for j in attacker.moves
          if j.type==13 # Move is Electric
            if j.basedamage>0
              elecmove=true
            end
          end
        end
        if elecmove==true && attacker.effects[PBEffects::Charge]==0
          miniscore*=1.5
        end
        score*=miniscore
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x22 # Double Team
        miniscore = setupminiscore(attacker,opponent,skill,move,false,0,false,initialscores,scoreindex)
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.3
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.2
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD) || checkAIaccuracy(aimem)
          miniscore*=0.2
        end
        if (attitemworks && attacker.item == PBItems::BRIGHTPOWDER) || (attitemworks && attacker.item == PBItems::LAXINCENSE) ||
          ((!attacker.abilitynulled && attacker.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
          ((!attacker.abilitynulled && attacker.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL)
          miniscore*=1.3
        end
        if skill>=PBTrainerAI.bestSkill
          if move.id==(PBMoves::DOUBLETEAM)
            if $fefieldeffect==30 # Mirror Arena
              miniscore*=2
            end
          end
        end
        if move.basedamage>0
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          if attacker.pbTooHigh?(PBStats::EVASION)
            miniscore=1
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            miniscore*=0.5
          end
        else
          miniscore/=100.0
          if attacker.pbTooHigh?(PBStats::EVASION)
            miniscore=0
          end
          miniscore*=0 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            miniscore*=0
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
            miniscore=1
          end
        end
        score*=miniscore
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x23 # Focus Energy
        if attacker.effects[PBEffects::FocusEnergy]!=2
          if (attacker.hp.to_f)/attacker.totalhp>0.75
            score*=1.2
          end
          if (attacker.hp.to_f)/attacker.totalhp<0.33
            score*=0.3
          end
          if (attacker.hp.to_f)/attacker.totalhp<0.75 &&
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::EMERGENCYEXIT) ||
             (!attacker.abilitynulled && attacker.ability == PBAbilities::WIMPOUT) ||
             (attitemworks && attacker.item == PBItems::EJECTBUTTON))
            score*=0.3
          end
          if attacker.pbOpposingSide.effects[PBEffects::Retaliate]
            score*=0.3
          end
          if opponent.effects[PBEffects::HyperBeam]>0
            score*=1.3
          end
          if opponent.effects[PBEffects::Yawn]>0
            score*=1.7
          end
          score*=1.2 if (attacker.hp/4.0)>checkAIdamage(aimem,attacker,opponent,skill) && (aimem.length > 0)
          if attacker.turncount<2
            score*=1.2
          end
          if opponent.status!=0
            score*=1.2
          end
          if opponent.status==PBStatuses::SLEEP || opponent.status==PBStatuses::FROZEN
            score*=1.3
          end
          if opponent.effects[PBEffects::Encore]>0
            if opponent.moves[(opponent.effects[PBEffects::EncoreIndex])].basedamage==0
              score*=1.5
            end
          end
          if attacker.effects[PBEffects::Confusion]>0
            score*=0.2
          end
          if attacker.effects[PBEffects::LeechSeed]>=0 || attacker.effects[PBEffects::Attract]>=0
            score*=0.6
          end
          score*=0.5 if checkAImoves(PBStuff::SWITCHOUTMOVE,aimem)
          if @doublebattle
            score*=0.5
          end
          if !attacker.abilitynulled && (attacker.ability == PBAbilities::SUPERLUCK || attacker.ability == PBAbilities::SNIPER)
            score*=2
          end
          if attitemworks && (attacker.item == PBItems::SCOPELENS ||
             attacker.item == PBItems::RAZORCLAW ||
             (attacker.item == PBItems::STICK && attacker.species==83) ||
             (attacker.item == PBItems::LUCKYPUNCH && attacker.species==113))
            score*=1.2
          end
          if (attitemworks && attacker.item == PBItems::LANSATBERRY)
            score*=1.3
          end
          if !opponent.abilitynulled && (opponent.ability == PBAbilities::ANGERPOINT ||
             opponent.ability == PBAbilities::SHELLARMOR || opponent.ability == PBAbilities::BATTLEARMOR)
            score*=0.2
          end
          if attacker.pbHasMove?(:LASERFOCUS) ||
             attacker.pbHasMove?(:FROSTBREATH) ||
             attacker.pbHasMove?(:STORMTHROW)
            score*=0.5
          end
          for j in attacker.moves
            if j.hasHighCriticalRate?
              score*=2
            end
          end
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==20 # Ashen Beach
              score*=1.5
            end
          end
        else
          score=0
        end
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x24 # Bulk Up
        miniscore = setupminiscore(attacker,opponent,skill,move,true,3,false,initialscores,scoreindex)
        if attacker.stages[PBStats::SPEED]<0
          ministat=attacker.stages[PBStats::SPEED]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        ministat+=opponent.stages[PBStats::SPATK]
        ministat+=opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore/=100.0
        score*=miniscore
        miniscore=100
        miniscore*=1.3 if checkAIhealing(aimem)
        if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          miniscore*=1.5
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.3
        end
        if attacker.status==PBStatuses::BURN || attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.5
        end
        miniscore*=0.3 if checkAImoves([PBMoves::FOULPLAY],aimem)
        if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
          miniscore*=0.6
        end
        physmove=false
        for j in attacker.moves
          if j.pbIsPhysical?(j.type)
            physmove=true
          end
        end
        if physmove && !attacker.pbTooHigh?(PBStats::ATTACK)
          miniscore/=100.0
          score*=miniscore
        end
        miniscore=100
        if attacker.effects[PBEffects::Toxic]>0
          miniscore*=0.2
        end
        if pbRoughStat(opponent,PBStats::SPATK,skill)<pbRoughStat(opponent,PBStats::ATTACK,skill)
          if !(roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL))
            if ((attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) && (attacker.hp.to_f)/attacker.totalhp>0.75
              miniscore*=1.3
            elsif (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              miniscore*=0.7
            end
          end
          miniscore*=1.3
        end
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.2
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.2
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        if !attacker.pbTooHigh?(PBStats::DEFENSE)
          miniscore/=100.0
          score*=miniscore
        end
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          score=0
        end
        if attacker.pbTooHigh?(PBStats::ATTACK) && attacker.pbTooHigh?(PBStats::DEFENSE)
          score*=0
        end
      when 0x25 # Coil
        miniscore = setupminiscore(attacker,opponent,skill,move,true,5,false,initialscores,scoreindex)
        if attacker.stages[PBStats::SPEED]<0
          ministat=attacker.stages[PBStats::SPEED]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        ministat+=opponent.stages[PBStats::SPATK]
        ministat+=opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore/=100.0
        score*=miniscore
        miniscore=100
        miniscore*=1.3 if checkAIhealing(aimem)
        if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          miniscore*=1.3
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.1
        end
        if attacker.status==PBStatuses::BURN || attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.5
        end
        miniscore*=0.3 if checkAImoves([PBMoves::FOULPLAY],aimem)
        if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
          miniscore*=0.6
        end
        physmove=false
        for j in attacker.moves
          if j.pbIsPhysical?(j.type)
            physmove=true
          end
        end
        if physmove && !attacker.pbTooHigh?(PBStats::ATTACK)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==2 # Grassy Terrain
              miniscore*=2
            end
          end
          miniscore/=100.0
          score*=miniscore
        end
        miniscore=100
        if attacker.effects[PBEffects::Toxic]>0
          miniscore*=0.2
        end
        if pbRoughStat(opponent,PBStats::SPATK,skill)<pbRoughStat(opponent,PBStats::ATTACK,skill)
          if !(roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL))
            if ((attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) &&
               (attacker.hp.to_f)/attacker.totalhp>0.75
              miniscore*=1.1
            elsif (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              miniscore*=0.7
            end
          end
          miniscore*=1.1
        end
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.1
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.1
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.2
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.2
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        if !attacker.pbTooHigh?(PBStats::DEFENSE)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==2 # Grassy Terrain
              miniscore*=2
            end
          end
          miniscore/=100.0
          score*=miniscore
        end
        miniscore=100
        weakermove=false
        for j in attacker.moves
          if j.basedamage<95
            weakermove=true
          end
        end
        if weakermove
          miniscore*=1.1
        end
        if opponent.stages[PBStats::EVASION]>0
          ministat=opponent.stages[PBStats::EVASION]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER) || (oppitemworks && opponent.item == PBItems::LAXINCENSE) ||
          ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
          ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL)
          miniscore*=1.1
        end
        if !attacker.pbTooHigh?(PBStats::ACCURACY)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==2 # Grassy Terrain
              miniscore*=2
            end
          end
          miniscore/=100.0
          score*=miniscore
        end
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          score=0
        end
        if attacker.pbTooHigh?(PBStats::ATTACK) && attacker.pbTooHigh?(PBStats::DEFENSE) && attacker.pbTooHigh?(PBStats::ACCURACY)
          score*=0
        end
      when 0x26 # Dragon Dance
        miniscore = setupminiscore(attacker,opponent,skill,move,true,17,false,initialscores,scoreindex)
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        ministat+=opponent.stages[PBStats::SPATK]
        ministat+=opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore/=100.0
        score*=miniscore
        miniscore=100
        miniscore*=1.2 if checkAIhealing(aimem)
        if (attacker.pbSpeed<=pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          miniscore*=1.3
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.3
        end
        if attacker.status==PBStatuses::BURN || attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.5
        end
        miniscore*=0.3 if checkAImoves([PBMoves::FOULPLAY],aimem)
        if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
          miniscore*=0.3
        end
        physmove=false
        for j in attacker.moves
          if j.pbIsPhysical?(j.type)
            physmove=true
          end
        end
        if physmove && !attacker.pbTooHigh?(PBStats::ATTACK)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==6 || $fefieldeffect==32 # Big Top/Dragon's Den
              miniscore*=2
            end
          end
          miniscore/=100.0
          score*=miniscore
        end
        miniscore=100
        if attacker.stages[PBStats::ATTACK]<0
          ministat=attacker.stages[PBStats::ATTACK]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          miniscore*=0.8
        end
        if @trickroom!=0
          miniscore*=0.2
        else
          miniscore*=0.2 if checkAImoves([PBMoves::TRICKROOM],aimem)
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::MOXIE)
          miniscore*=1.3
        end
        if !attacker.pbTooHigh?(PBStats::SPEED)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==6 || $fefieldeffect==32 # Big Top/Dragon's Den
              miniscore*=2
            end
          end
          miniscore/=100.0
          score*=miniscore
        end
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)

        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          score=0
        end
        if attacker.pbTooHigh?(PBStats::ATTACK) && attacker.pbTooHigh?(PBStats::SPEED)
          score*=0
        end
      when 0x27 # Work Up
        miniscore = setupminiscore(attacker,opponent,skill,move,true,5,false,initialscores,scoreindex)
        if attacker.stages[PBStats::SPEED]<0
          ministat=attacker.stages[PBStats::SPEED]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        ministat+=opponent.stages[PBStats::SPATK]
        ministat+=opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore/=100.0
        score*=miniscore
        miniscore=100
        miniscore*=1.3 if checkAIhealing(aimem)
        if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          miniscore*=1.5
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.3
        end
        specmove=false
        for j in attacker.moves
          if j.pbIsSpecial?(j.type)
            specmove=true
          end
        end
        if attacker.status==PBStatuses::BURN && !specmove
          miniscore*=0.5
        end
        if attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.5
        end
        miniscore*=0.3 if checkAImoves([PBMoves::FOULPLAY],aimem)
        if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
          miniscore*=0.6
        end
        physmove=false
        for j in attacker.moves
          if j.pbIsPhysical?(j.type)
            physmove=true
          end
        end
        if (physmove && !attacker.pbTooHigh?(PBStats::ATTACK)) || (specmove && !attacker.pbTooHigh?(PBStats::SPATK))
          miniscore/=100.0
          score*=miniscore
        end
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          score=0
        end
        if attacker.pbTooHigh?(PBStats::SPATK) && attacker.pbTooHigh?(PBStats::ATTACK)
          score*=0
        end
      when 0x28 # Growth
        miniscore = setupminiscore(attacker,opponent,skill,move,true,5,false,initialscores,scoreindex)
        if attacker.stages[PBStats::SPEED]<0
          ministat=attacker.stages[PBStats::SPEED]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        ministat+=opponent.stages[PBStats::SPATK]
        ministat+=opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore/=100.0
        score*=miniscore
        miniscore=100
        miniscore*=1.3 if checkAIhealing(aimem)
        if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          miniscore*=1.5
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.3
        end
        specmove=false
        for j in attacker.moves
          if j.pbIsSpecial?(j.type)
            specmove=true
          end
        end
        if attacker.status==PBStatuses::BURN && !specmove
          miniscore*=0.5
        end
        if attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.5
        end
        miniscore*=0.3 if checkAImoves([PBMoves::FOULPLAY],aimem)
        if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        physmove=false
        for j in attacker.moves
          if j.pbIsPhysical?(j.type)
            physmove=true
          end
        end
        if (physmove && !attacker.pbTooHigh?(PBStats::ATTACK)) || (specmove && !attacker.pbTooHigh?(PBStats::SPATK))
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==2 || $fefieldeffect==15 || pbWeather==PBWeather::SUNNYDAY # Grassy/Forest
              miniscore*=2
            end
            if ($fefieldeffect==33) # Flower Garden
              if $fecounter>2
                miniscore*=3
              else
                miniscore*=2
              end
            end
          end
          miniscore/=100.0
          score*=miniscore
        end
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          score=0
        end
        if attacker.pbTooHigh?(PBStats::SPATK) && attacker.pbTooHigh?(PBStats::ATTACK)
          score*=0
        end
      when 0x29 # Hone Claws
        miniscore = setupminiscore(attacker,opponent,skill,move,true,1,false,initialscores,scoreindex)
        if attacker.stages[PBStats::SPEED]<0
          ministat=attacker.stages[PBStats::SPEED]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        ministat+=opponent.stages[PBStats::SPATK]
        ministat+=opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore*=1.3 if checkAIhealing(aimem)
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          miniscore*=1.5
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.3
        end
        if attacker.status==PBStatuses::BURN || attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.5
        end
        miniscore*=0.3 if checkAImoves([PBMoves::FOULPLAY],aimem)
        if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
          miniscore*=0.6
        end
        physmove=false
        for j in attacker.moves
          if j.pbIsPhysical?(j.type)
            physmove=true
          end
        end
        if physmove && !attacker.pbTooHigh?(PBStats::ATTACK)
          miniscore/=100.0
          score*=miniscore
        end
        miniscore=100
        weakermove=false
        for j in attacker.moves
          if j.basedamage<95
            weakermove=true
          end
        end
        if weakermove
          miniscore*=1.3
        end
        if opponent.stages[PBStats::EVASION]>0
          ministat=opponent.stages[PBStats::EVASION]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER) || (oppitemworks && opponent.item == PBItems::LAXINCENSE) ||
          ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
          ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL)
          miniscore*=1.3
        end
        if !attacker.pbTooHigh?(PBStats::ACCURACY)
          miniscore/=100.0
          score*=miniscore
        end
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          score=0
        end
        if attacker.pbTooHigh?(PBStats::ACCURACY) && attacker.pbTooHigh?(PBStats::ATTACK)
          score*=0
        end
      when 0x2A # Cosmic Power
        miniscore = setupminiscore(attacker,opponent,skill,move,false,10,false,initialscores,scoreindex)
        if attacker.stages[PBStats::SPDEF]>0 || attacker.stages[PBStats::DEFENSE]>0
          ministat=attacker.stages[PBStats::SPDEF]
          ministat+=attacker.stages[PBStats::DEFENSE]
          minimini=-5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if skill>=PBTrainerAI.mediumSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if (maxdam.to_f/attacker.hp)<0.12 && (aimem.length > 0)
            miniscore*=0.3
          end
        end
        miniscore/=100.0
        score*=miniscore
        miniscore=100
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.5
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.2
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.7
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        if !attacker.pbTooHigh?(PBStats::SPDEF) || !attacker.pbTooHigh?(PBStats::DEFENSE)
          if skill>=PBTrainerAI.bestSkill
            if move.id==(PBMoves::COSMICPOWER)
              if $fefieldeffect==29 || $fefieldeffect==34 || $fefieldeffect==35 # Holy/Starlight Arena/New World
                miniscore*=2
              end
            end
            if move.id==(PBMoves::DEFENDORDER)
              if $fefieldeffect==15 # Forest
                miniscore*=2
              end
            end
          end
          miniscore/=100.0
          score*=miniscore
        end
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          score=0
        end
        if attacker.pbTooHigh?(PBStats::SPDEF) && attacker.pbTooHigh?(PBStats::DEFENSE)
          score*=0
        end
      when 0x2B # Quiver Dance
        miniscore = setupminiscore(attacker,opponent,skill,move,true,28,false,initialscores,scoreindex)
        miniscore/=100.0
        score*=miniscore
        miniscore=100
        if attacker.stages[PBStats::SPEED]<0
          ministat=attacker.stages[PBStats::SPEED]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        ministat+=opponent.stages[PBStats::SPATK]
        ministat+=opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore*=1.3 if checkAIhealing(aimem)
        if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          miniscore*=1.5
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.3
        end
        if attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.5
        end
        if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        specmove=false
        for j in attacker.moves
          if j.pbIsSpecial?(j.type)
            specmove=true
          end
        end
        if specmove && !attacker.pbTooHigh?(PBStats::SPATK)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==6 # Big Top
              miniscore*=2
            end
          end
          miniscore/=100.0
          score*=miniscore
        end
        miniscore=100
        if attacker.effects[PBEffects::Toxic]>0
          miniscore*=0.2
        end
        if pbRoughStat(opponent,PBStats::SPATK,skill)>pbRoughStat(opponent,PBStats::ATTACK,skill)
          if !(roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL))
            if ((attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) &&
               (attacker.hp.to_f)/attacker.totalhp>0.75
              miniscore*=1.3
            elsif (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              miniscore*=0.7
            end
          end
          miniscore*=1.3
        end
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.3
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.2
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        if !attacker.pbTooHigh?(PBStats::SPDEF)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==6 # Big Top
              miniscore*=2
            end
          end
          miniscore/=100.0
          score*=miniscore
        end
        miniscore=100
        if attacker.stages[PBStats::SPATK]<0
          ministat=attacker.stages[PBStats::SPATK]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          miniscore*=0.8
        end
        if @trickroom!=0
          miniscore*=0.2
        else
          miniscore*=0.2 if checkAImoves([PBMoves::TRICKROOM],aimem)
        end
        if !attacker.pbTooHigh?(PBStats::SPEED)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==6 # Big Top
              miniscore*=2
            end
          end
          miniscore/=100.0
          score*=miniscore
        end
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          score=0
        end
        if attacker.pbTooHigh?(PBStats::SPATK) && attacker.pbTooHigh?(PBStats::SPDEF) && attacker.pbTooHigh?(PBStats::SPEED)
          score*=0
        end
      when 0x2C # Calm Mind
        miniscore = setupminiscore(attacker,opponent,skill,move,true,12,false,initialscores,scoreindex)
        miniscore/=100.0
        score*=miniscore
        miniscore=100
        if attacker.stages[PBStats::SPEED]<0
          ministat=attacker.stages[PBStats::SPEED]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        ministat+=opponent.stages[PBStats::SPATK]
        ministat+=opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore*=1.3 if checkAIhealing(aimem)
        if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          miniscore*=1.5
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.3
        end
        if attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.5
        end
        if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
          miniscore*=0.6
        end
        specmove=false
        for j in attacker.moves
          if j.pbIsSpecial?(j.type)
            specmove=true
          end
        end
        if specmove && !attacker.pbTooHigh?(PBStats::SPATK)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==5 || $fefieldeffect==20 || $fefieldeffect==37 # Chess/Ashen Beach/Psychic Terrain
              miniscore*=2
            end
          end
          miniscore/=100.0
          score*=miniscore
        end
        miniscore=100
        if attacker.effects[PBEffects::Toxic]>0
          miniscore*=0.2
        end
        if pbRoughStat(opponent,PBStats::SPATK,skill)>pbRoughStat(opponent,PBStats::ATTACK,skill)
          if !(roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL))
            if ((attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) &&
               (attacker.hp.to_f)/attacker.totalhp>0.75
              miniscore*=1.3
            elsif (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              miniscore*=0.7
            end
          end
          miniscore*=1.3
        end
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.3
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.2
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        if !attacker.pbTooHigh?(PBStats::SPDEF)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==5 || $fefieldeffect==20 || $fefieldeffect==37 # Chess/Ashen Beach/Psychic Terrain
              miniscore*=2
            end
          end
          miniscore/=100.0
          score*=miniscore
        end
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          score=0
        end
        if attacker.pbTooHigh?(PBStats::SPATK) && attacker.pbTooHigh?(PBStats::SPDEF)
          score*=0
        end
      when 0x2D # Ancient power
        miniscore=100
        miniscore*=2
        if score == 110
          miniscore *= 1.3
        end
        if (attacker.hp.to_f)/attacker.totalhp>0.75
          miniscore*=1.1
        end
        if opponent.effects[PBEffects::HyperBeam]>0
          miniscore*=1.2
        end
        if opponent.effects[PBEffects::Yawn]>0
          miniscore*=1.3
        end
        if skill>=PBTrainerAI.mediumSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if maxdam<(attacker.hp/3.0) && (aimem.length > 0)
            miniscore*=1.1
          else
            if move.basedamage==0
              miniscore*=0.8
              if maxdam>attacker.hp
                miniscore*=0.1
              end
            end
          end
        end
        if attacker.turncount<2
          miniscore*=1.1
        end
        if opponent.status!=0
          miniscore*=1.1
        end
        if opponent.status==PBStatuses::SLEEP || opponent.status==PBStatuses::FROZEN
          miniscore*=1.3
        end
        if opponent.effects[PBEffects::Encore]>0
          if opponent.moves[(opponent.effects[PBEffects::EncoreIndex])].basedamage==0
            miniscore*=1.3
          end
        end
        miniscore*=0.2 if checkAImoves(PBStuff::SWITCHOUTMOVE,aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::SIMPLE)
          miniscore*=2
        end
        if @doublebattle
          miniscore*=0.3
        end
        if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        miniscore-=100
        if move.addlEffect.to_f != 100
          miniscore*=(move.addlEffect.to_f/100)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
            miniscore*=2
          end
        end
        miniscore+=100
        miniscore/=100.0
        if attacker.pbTooHigh?(PBStats::ATTACK) && attacker.pbTooHigh?(PBStats::DEFENSE) &&
           attacker.pbTooHigh?(PBStats::SPATK) && attacker.pbTooHigh?(PBStats::SPDEF) &&
           attacker.pbTooHigh?(PBStats::SPEED)
          miniscore=0
        end
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
        miniscore*=0 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score *= 0.9
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          miniscore*=0.9
        end
        if miniscore > 1
          score*=miniscore
        end
      when 0x2E # Swords Dance
        miniscore = setupminiscore(attacker,opponent,skill,move,true,1,true,initialscores,scoreindex)
        if attacker.stages[PBStats::SPEED]<0
          ministat=attacker.stages[PBStats::SPEED]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        ministat+=opponent.stages[PBStats::SPATK]
        ministat+=opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore*=1.3 if checkAIhealing(aimem)
        if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          miniscore*=1.5
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.2
        end
        if attacker.status==PBStatuses::BURN || attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.5
        end
        miniscore*=0.2 if checkAImoves([PBMoves::FOULPLAY],aimem)
        if attacker.hp==attacker.totalhp &&
           (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.5
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
          miniscore*=0.6
        end
        if skill>=PBTrainerAI.bestSkill
          if move.id==(PBMoves::SWORDSDANCE)
            if $fefieldeffect==6 || $fefieldeffect==31  # Big Top/Fairy Tale
              miniscore*=1.5
            end
          end
        end
        miniscore/=100.0
        if attacker.pbTooHigh?(PBStats::ATTACK)
          miniscore=0
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          miniscore*=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          miniscore*=1
        end
        physmove=false
        for j in attacker.moves
          if j.pbIsPhysical?(j.type)
            physmove=true
          end
        end
        miniscore=0 if !physmove
        score*=miniscore
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x2F # Iron Defense
        miniscore = setupminiscore(attacker,opponent,skill,move,false,2,true,initialscores,scoreindex)
        if attacker.stages[PBStats::DEFENSE]>0
          ministat=attacker.stages[PBStats::DEFENSE]
          minimini=-15*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
          miniscore*=1.3
        end
        if skill>=PBTrainerAI.mediumSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if (maxdam.to_f/attacker.hp)<0.12 && (aimem.length > 0)
            miniscore*=0.3
          end
        end
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.3
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.2
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        if skill>=PBTrainerAI.bestSkill
          if move.id==(PBMoves::IRONDEFENSE)
            if $fefieldeffect==17 # Factory
              miniscore*=1.5
            end
          end
          if move.id==(PBMoves::DIAMONDSTORM)
            if $fefieldeffect==23 # Cave
              miniscore*=1.5
            end
          end
        end
        if move.basedamage>0
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          if attacker.pbTooHigh?(PBStats::DEFENSE)
            miniscore=1
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            miniscore*=0.5
          end
        else
          miniscore/=100.0
          if attacker.pbTooHigh?(PBStats::DEFENSE)
            miniscore=0
          end
          miniscore*=0 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            miniscore*=0
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
            miniscore*=1
          end
        end
        score*=miniscore
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x30 # Agility
        miniscore = setupminiscore(attacker,opponent,skill,move,true,16,true,initialscores,scoreindex)
        if attacker.attack<attacker.spatk
          if attacker.stages[PBStats::SPATK]<0
            ministat=attacker.stages[PBStats::SPATK]
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
        else
          if attacker.stages[PBStats::ATTACK]<0
            ministat=attacker.stages[PBStats::ATTACK]
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
        end
        ministat=0
        ministat+=opponent.stages[PBStats::DEFENSE]
        ministat+=opponent.stages[PBStats::SPDEF]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          miniscore*=0.3
          livecount=0
          for i in pbParty(opponent.index)
            next if i.nil?
            livecount+=1 if i.hp!=0
          end
          if livecount==1
              miniscore*=0.1
          end
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.3
        end
        if @trickroom!=0
          miniscore*=0.2
        else
          miniscore*=0.2 if checkAImoves([PBMoves::TRICKROOM],aimem)
        end
        if attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.2
        end
        if attacker.hp==attacker.totalhp &&
           (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
          miniscore*=0.6
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::MOXIE)
          miniscore*=1.3
        end
        if skill>=PBTrainerAI.bestSkill
          if move.id==(PBMoves::ROCKPOLISH)
            if $fefieldeffect==14 # Rocky Field
              miniscore*=1.5
            end
            if $fefieldeffect==25 # Crystal Cavern
              miniscore*=2
            end
          end
        end
        miniscore/=100.0
        if attacker.pbTooHigh?(PBStats::SPEED)
          miniscore=0
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          miniscore*=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          miniscore*=1
        end
        score*=miniscore
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x31 # Autotomize
        miniscore = setupminiscore(attacker,opponent,skill,move,true,16,true,initialscores,scoreindex)
        if attacker.attack<attacker.spatk
          if attacker.stages[PBStats::SPATK]<0
            ministat=attacker.stages[PBStats::SPATK]
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
        else
          if attacker.stages[PBStats::ATTACK]<0
            ministat=attacker.stages[PBStats::ATTACK]
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
        end
        ministat=0
        ministat+=opponent.stages[PBStats::DEFENSE]
        ministat+=opponent.stages[PBStats::SPDEF]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          miniscore*=0.3
          livecount=0
          for i in pbParty(opponent.index)
            next if i.nil?
            livecount+=1 if i.hp!=0
          end
          if livecount==1
              miniscore*=0.1
          end
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.3
        end
        if @trickroom!=0
          miniscore*=0.2
        else
          miniscore*=0.2 if checkAImoves([PBMoves::TRICKROOM],aimem)
        end
        if attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.2
        end
        if attacker.hp==attacker.totalhp &&
           (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
          miniscore*=0.6
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::MOXIE)
          miniscore*=1.3
        end
        if skill>=PBTrainerAI.bestSkill
          if $fefieldeffect==17 # Factory
            miniscore*=1.5
          end
        end
        miniscore*=1.5 if checkAImoves([PBMoves::LOWKICK,PBMoves::GRASSKNOT],aimem)
        miniscore*=0.5 if checkAImoves([PBMoves::HEATCRASH,PBMoves::HEAVYSLAM],aimem)
        if attacker.pbHasMove?(:HEATCRASH) || attacker.pbHasMove?(:HEAVYSLAM)
          miniscore*=0.8
        end
        miniscore/=100.0
        if attacker.pbTooHigh?(PBStats::SPEED)
          miniscore=0
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          miniscore*=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          miniscore*=1
        end
        score*=miniscore
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x32 # Nasty Plot
        miniscore = setupminiscore(attacker,opponent,skill,move,true,4,true,initialscores,scoreindex)
        if attacker.stages[PBStats::SPEED]<0
          ministat=attacker.stages[PBStats::SPEED]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        ministat+=opponent.stages[PBStats::SPATK]
        ministat+=opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore*=1.3 if checkAIhealing(aimem)
        if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          miniscore*=1.5
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.3
        end
        if attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.5
        end
        if attacker.hp==attacker.totalhp &&
           (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
          miniscore*=0.6
        end
        if skill>=PBTrainerAI.bestSkill
          if $fefieldeffect==5 || $fefieldeffect==37 # Chess/Psychic Terrain
            miniscore*=1.5
          end
        end
        miniscore/=100.0
        if attacker.pbTooHigh?(PBStats::SPATK)
          miniscore=0
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          miniscore*=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          miniscore*=1
        end
        specmove=false
        for j in attacker.moves
          if j.pbIsSpecial?(j.type)
            specmove=true
          end
        end
        miniscore=0 if !specmove
        score*=miniscore
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x33 # Amnesia
        miniscore = setupminiscore(attacker,opponent,skill,move,false,0,true,initialscores,scoreindex)
        if attacker.stages[PBStats::SPDEF]>0
          ministat=attacker.stages[PBStats::SPDEF]
          minimini=-15*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if pbRoughStat(opponent,PBStats::ATTACK,skill)<pbRoughStat(opponent,PBStats::SPATK,skill)
          miniscore*=1.3
        end
        if skill>=PBTrainerAI.mediumSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if (maxdam.to_f/attacker.hp)<0.12 && (aimem.length > 0)
            miniscore*=0.3
          end
        end
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.3
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.2
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        miniscore/=100.0
        if attacker.pbTooHigh?(PBStats::SPDEF)
          miniscore=0
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          miniscore*=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          miniscore*=1
        end
        score*=miniscore
        if skill>=PBTrainerAI.bestSkill
          if $fefieldeffect==25 # Glitch
            score *= 2
          end
        end
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x34 # Minimize
        miniscore = setupminiscore(attacker,opponent,skill,move,false,0,true,initialscores,scoreindex)
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.3
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.2
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD) || checkAIaccuracy(aimem)
          miniscore*=0.2
        end
        if (attitemworks && (attacker.item == PBItems::BRIGHTPOWDER || attacker.item == PBItems::LAXINCENSE)) ||
          ((!attacker.abilitynulled && attacker.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
          ((!attacker.abilitynulled && attacker.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL)
          miniscore*=1.3
        end
        miniscore/=100.0
        if attacker.pbTooHigh?(PBStats::EVASION)
          miniscore=0
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          miniscore*=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          miniscore*=1
        end
        score*=miniscore
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x35 # Shell Smash
        miniscore = setupminiscore(attacker,opponent,skill,move,true,21,true,initialscores,scoreindex)
        miniscore/=100.0
        score*=miniscore
        miniscore=100
        miniscore*=1.3 if checkAIhealing(aimem)
        if attacker.pbSpeed<=pbRoughStat(opponent,PBStats::SPEED,skill) &&
           (2*attacker.pbSpeed)>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          miniscore*=1.3
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.5
        end
        specmove=false
        for j in attacker.moves
          if j.pbIsSpecial?(j.type)
            specmove=true
          end
        end
        if attacker.status==PBStatuses::BURN && !specmove
          miniscore*=0.5
        end
        if attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.5
        end
        if attacker.hp==attacker.totalhp &&
           (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.5
        end
        miniscore*=0.2 if checkAIpriority(aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
          miniscore*=0.6
        end
        miniscore/=100.0
        score*=miniscore
        miniscore=100
        if (attitemworks && attacker.item == PBItems::WHITEHERB)
          miniscore *= 1.5
        else
          if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            miniscore*=0.1
          end
        end
        if @trickroom!=0
          miniscore*=0.2
        else
          miniscore*=0.2 if checkAImoves([PBMoves::TRICKROOM],aimem)
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::MOXIE)
          miniscore*=1.3
        end
        if (attitemworks && attacker.item == PBItems::WHITEHERB)
          miniscore*=1.5
        end
        if !attacker.pbTooHigh?(PBStats::SPEED)
          miniscore/=100.0
          score*=miniscore
        end
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY) && !healmove
          score=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          score=0
        end
      when 0x36 # Shift Gear
        miniscore = setupminiscore(attacker,opponent,skill,move,true,17,false,initialscores,scoreindex)
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        ministat+=opponent.stages[PBStats::SPATK]
        ministat+=opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore/=100.0
        score*=miniscore
        miniscore=100
        miniscore*=1.3 if checkAIhealing(aimem)
        if (attacker.pbSpeed<=pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          miniscore*=1.3
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.5
        end
        if attacker.status==PBStatuses::BURN || attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.5
        end
        miniscore*=0.3 if checkAImoves([PBMoves::FOULPLAY],aimem)
        if attacker.hp==attacker.totalhp &&
           (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
          miniscore*=0.6
        end
        physmove=false
        for j in attacker.moves
          if j.pbIsPhysical?(j.type)
            physmove=true
          end
        end
        if physmove && !attacker.pbTooHigh?(PBStats::ATTACK)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==17 # Factory Field
              miniscore*=1.5
            end
          end
          miniscore/=100.0
          score*=miniscore
        end
        miniscore=100
        if attacker.stages[PBStats::ATTACK]<0
          ministat=attacker.stages[PBStats::ATTACK]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          miniscore*=0.8
        end
        if @trickroom!=0 || checkAImoves([PBMoves::TRICKROOM],aimem)
          miniscore*=0.1
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::MOXIE)
          miniscore*=1.3
        end
        if !attacker.pbTooHigh?(PBStats::SPEED)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==17 # Factory Field
              miniscore*=1.5
            end
          end
          miniscore/=100.0
          score*=miniscore
        end
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          score = 0
        end
      when 0x37 # Acupressure
        miniscore = setupminiscore(attacker,opponent,skill,move,false,0,false,initialscores,scoreindex)
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.3
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.2
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD) || checkAIaccuracy(aimem)
          miniscore*=0.2
        end
        if (attitemworks && attacker.item == PBItems::BRIGHTPOWDER) || (attitemworks && attacker.item == PBItems::LAXINCENSE) ||
          ((!attacker.abilitynulled && attacker.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
          ((!attacker.abilitynulled && attacker.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL)
          miniscore*=1.3
        end
        miniscore/=100.0
        maxstat=0
        maxstat+=1 if attacker.pbTooHigh?(PBStats::ATTACK)
        maxstat+=1 if attacker.pbTooHigh?(PBStats::DEFENSE)
        maxstat+=1 if attacker.pbTooHigh?(PBStats::SPATK)
        maxstat+=1 if attacker.pbTooHigh?(PBStats::SPDEF)
        maxstat+=1 if attacker.pbTooHigh?(PBStats::SPEED)
        maxstat+=1 if attacker.pbTooHigh?(PBStats::ACCURACY)
        maxstat+=1 if attacker.pbTooHigh?(PBStats::EVASION)
        if maxstat>1
          miniscore=0
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          miniscore*=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          miniscore*=1
        end
        score*=miniscore
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x38 # Cotton Guard
        miniscore = setupminiscore(attacker,opponent,skill,move,false,2,true,initialscores,scoreindex)
        if attacker.stages[PBStats::DEFENSE]>0
          ministat=attacker.stages[PBStats::DEFENSE]
          minimini=-15*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
          miniscore*=1.3
        end
        if skill>=PBTrainerAI.mediumSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if (maxdam.to_f/attacker.hp)<0.12 && (aimem.length > 0)
            miniscore*=0.3
          end
        end
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.3
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.2
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        miniscore/=100.0
        if attacker.pbTooHigh?(PBStats::DEFENSE)
          miniscore=0
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          miniscore*=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          miniscore*=1
        end
        score*=miniscore
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x39 # Tail Glow
        miniscore = setupminiscore(attacker,opponent,skill,move,true,4,true,initialscores,scoreindex)
        if attacker.stages[PBStats::SPEED]<0
          ministat=attacker.stages[PBStats::SPEED]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        ministat+=opponent.stages[PBStats::SPATK]
        ministat+=opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore*=1.3 if checkAIhealing(aimem)
        if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          miniscore*=1.5
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.3
        end
        if attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.5
        end
        if attacker.hp==attacker.totalhp &&
           (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          miniscore*=1.4
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
          miniscore*=0.6
        end
        miniscore/=100.0
        if attacker.pbTooHigh?(PBStats::SPATK)
          miniscore=0
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          miniscore*=0
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          miniscore*=1
        end
        specmove=false
        for j in attacker.moves
          if j.pbIsSpecial?(j.type)
            specmove=true
          end
        end
        miniscore=0 if !specmove
        score*=miniscore
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x3A # Belly Drum
        miniscore=100
        if attacker.effects[PBEffects::Substitute]>0 || attacker.effects[PBEffects::Disguise]
          miniscore*=1.5
        end
        if initialscores.length>0
          miniscore*=1.3 if hasbadmoves(initialscores,scoreindex,20)
        end
        if (attacker.hp.to_f)/attacker.totalhp>0.85
          miniscore*=1.2
        end
        if opponent.effects[PBEffects::HyperBeam]>0
          miniscore*=1.5
        end
        if opponent.effects[PBEffects::Yawn]>0
          miniscore*=1.7
        end
        if skill>=PBTrainerAI.mediumSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if maxdam<(attacker.hp/4.0) && (aimem.length > 0)
            miniscore*=1.4
          else
            if move.basedamage==0
              miniscore*=0.8
              if maxdam>attacker.hp
                miniscore*=0.1
              end
            end
          end
        else
          if move.basedamage==0
            effcheck = PBTypes.getCombinedEffectiveness(opponent.type1,attacker.type1,attacker.type2)
            if effcheck > 4
              miniscore*=0.5
            end
            effcheck2 = PBTypes.getCombinedEffectiveness(opponent.type2,attacker.type1,attacker.type2)
            if effcheck2 > 4
              miniscore*=0.5
            end
          end
        end
        if attacker.turncount<1
          miniscore*=1.2
        end
        if opponent.status!=0
          miniscore*=1.2
        end
        if opponent.status==PBStatuses::SLEEP || opponent.status==PBStatuses::FROZEN
          miniscore*=1.4
        end
        if opponent.effects[PBEffects::Encore]>0
          if opponent.moves[(opponent.effects[PBEffects::EncoreIndex])].basedamage==0
            miniscore*=1.5
          end
        end
        if attacker.effects[PBEffects::Confusion]>0
          miniscore*=0.1
        end
        if attacker.effects[PBEffects::LeechSeed]>=0 || attacker.effects[PBEffects::Attract]>=0
          miniscore*=0.2
        end
        miniscore*=0.1 if checkAImoves(PBStuff::SWITCHOUTMOVE,aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          miniscore*=0
        end
        if @doublebattle
          miniscore*=0.1
        end
        if attacker.stages[PBStats::SPEED]<0
          ministat=attacker.stages[PBStats::SPEED]
          minimini=10*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        ministat+=opponent.stages[PBStats::SPATK]
        ministat+=opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini=(-10)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore*=1.3 if checkAIhealing(aimem)
        if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          miniscore*=1.5
        else
          primove=false
          for j in attacker.moves
            if j.priority>0
              primove=true
            end
          end
          if !primove
            miniscore*=0.3
          end
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.3
        end
        if attacker.status==PBStatuses::BURN
          miniscore*=0.8
        end
        if attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.2
        end
        miniscore*=0.1 if checkAImoves([PBMoves::FOULPLAY],aimem)
        miniscore*=0.1 if checkAIpriority(aimem)
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
          miniscore*=0.6
        end
        if skill>=PBTrainerAI.bestSkill
          if $fefieldeffect==6  # Big Top
            miniscore*=1.5
          end
        end
        miniscore/=100.0
        if attacker.pbTooHigh?(PBStats::ATTACK)
          miniscore=0
        end
        score*=0.3 if checkAImoves([PBMoves::CLEARSMOG,PBMoves::HAZE],aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          miniscore*=0
        end
        physmove=false
        for j in attacker.moves
          if j.pbIsPhysical?(j.type)
            physmove=true
          end
        end
        miniscore=0 if !physmove
        score*=miniscore
        if (opponent.level-5)>attacker.level
          score*=0.6
          if (opponent.level-10)>attacker.level
            score*=0.2
          end
        end
      when 0x3B # Superpower
        thisinitial = score
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score*=1.7
        else
          if thisinitial<100
            score*=0.9
            if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=1.2
            else
              score*=0.5 if checkAIhealing(aimem)
            end
          end
          if initialscores.length>0
            score*=0.7 if hasgreatmoves(initialscores,scoreindex,skill)
          end
          miniscore=100
          livecount=0
          for i in pbParty(opponent.index)
            next if i.nil?
            livecount+=1 if i.hp!=0
          end
          if livecount>1
            miniscore*=(livecount-3)
            miniscore/=100.0
            miniscore*=0.05
            miniscore=(1-miniscore)
            score*=miniscore
          end
          count=-1
          party=pbParty(attacker.index)
          pivotvar=false
          for i in 0...party.length
            count+=1
            next if party[i].nil?
            temproles = pbGetMonRole(party[i],opponent,skill,count,party)
            if temproles.include?(PBMonRoles::PIVOT)
              pivotvar=true
            end
          end
          if pivotvar && !@doublebattle
            score*=1.2
          end
          livecount2=0
          for i in pbParty(attacker.index)
            next if i.nil?
            livecount2+=1 if i.hp!=0
          end
          if livecount>1 && livecount2==1
            score*=0.8
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::MOXIE)
            score*=1.5
          end
        end
      when 0x3C # Close Combat
        thisinitial = score
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score*=1.5
        else
          if thisinitial<100
            score*=0.9
            if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=1.3
            else
              score*=0.7 if checkAIpriority(aimem)
            end
            score*=0.7 if checkAIhealing(aimem)
          end
          if initialscores.length>0
            score*=0.7 if hasgreatmoves(initialscores,scoreindex,skill)
          end
          miniscore=100
          livecount=0
          for i in pbParty(opponent.index)
            next if i.nil?
            livecount+=1 if i.hp!=0
          end
          if livecount>1
            miniscore*=(livecount-3)
            miniscore/=100.0
            miniscore*=0.05
            miniscore=(1-miniscore)
            score*=miniscore
          end
          count=-1
          party=pbParty(attacker.index)
          pivotvar=false
          for i in 0...party.length
            count+=1
            next if party[i].nil?
            temproles = pbGetMonRole(party[i],opponent,skill,count,party)
            if temproles.include?(PBMonRoles::PIVOT)
              pivotvar=true
            end
          end
          if pivotvar && !@doublebattle
            score*=1.2
          end
          livecount2=0
          for i in pbParty(attacker.index)
            next if i.nil?
            livecount2+=1 if i.hp!=0
          end
          if livecount>1 && livecount2==1
            score*=0.9
          end
        end
      when 0x3D # V-Create
        thisinitial = score
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score*=1.7
        else
          if thisinitial<100
            score*=0.8
            if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=1.3
            else
              livecount=0
              for i in pbParty(opponent.index)
                next if i.nil?
                livecount+=1 if i.hp!=0
              end
              livecount2=0
              for i in pbParty(attacker.index)
                next if i.nil?
                livecount2+=1 if i.hp!=0
              end
              if livecount>1 && livecount2==1
                score*=0.7
              end
              score*=0.7 if checkAIpriority(aimem)
            end
          end
          if initialscores.length>0
            score*=0.7 if hasgreatmoves(initialscores,scoreindex,skill)
          end
          miniscore=100
          livecount=0
          for i in pbParty(opponent.index)
            next if i.nil?
            livecount+=1 if i.hp!=0
          end
          if livecount>1
            miniscore*=(livecount-3)
            miniscore/=100.0
            miniscore*=0.05
            miniscore=(1-miniscore)
            score*=miniscore
          end
          count=-1
          party=pbParty(attacker.index)
          pivotvar=false
          for i in 0...party.length
            count+=1
            next if party[i].nil?
            temproles = pbGetMonRole(party[i],opponent,skill,count,party)
            if temproles.include?(PBMonRoles::PIVOT)
              pivotvar=true
            end
          end
          if pivotvar && !@doublebattle
            score*=1.2
          end
        end
      when 0x3E # Hammer Arm
        thisinitial = score
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score*=1.3
        else
          if thisinitial<100
            score*=0.9
          end
          if initialscores.length>0
            score*=0.7 if hasgreatmoves(initialscores,scoreindex,skill)
          end
          livecount=0
          for i in pbParty(opponent.index)
            next if i.nil?
            livecount+=1 if i.hp!=0
          end
          livecount2=0
          for i in pbParty(attacker.index)
            next if i.nil?
            livecount2+=1 if i.hp!=0
          end
          if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=0.8
            if livecount>1 && livecount2==1
              score*=0.8
            end
          else
            score*=1.1
          end
          if roles.include?(PBMonRoles::TANK)
            score*=1.1
          end
          miniscore=100
          livecount=0
          for i in pbParty(opponent.index)
            next if i.nil?
            livecount+=1 if i.hp!=0
          end
          if livecount>1
            miniscore*=(livecount-3)
            miniscore/=100.0
            miniscore*=0.05
            miniscore=(1-miniscore)
            score*=miniscore
          end
          count=-1
          party=pbParty(attacker.index)
          pivotvar=false
          for i in 0...party.length
            count+=1
            next if party[i].nil?
            temproles = pbGetMonRole(party[i],opponent,skill,count,party)
            if temproles.include?(PBMonRoles::PIVOT)
              pivotvar=true
            end
          end
          if pivotvar && !@doublebattle
            score*=1.2
          end
        end
      when 0x3F # Overheat
        thisinitial = score
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score*=1.7
        else
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==24 # Glitch
              if attacker.spdef>attacker.spatk
                score*=1.4
              end
            end
          end
          if thisinitial<100
            score*=0.9
            score*=0.5 if checkAIhealing(aimem)
          end
          if initialscores.length>0
            score*=0.7 if hasgreatmoves(initialscores,scoreindex,skill)
          end
          miniscore=100
          livecount=0
          for i in pbParty(opponent.index)
            next if i.nil?
            livecount+=1 if i.hp!=0
          end
          if livecount>1
            miniscore*=(livecount-1)
            miniscore/=100.0
            miniscore*=0.05
            miniscore=(1-miniscore)
            score*=miniscore
          end
          count=-1
          party=pbParty(attacker.index)
          pivotvar=false
          for i in 0...party.length
            count+=1
            next if party[i].nil?
            temproles = pbGetMonRole(party[i],opponent,skill,count,party)
            if temproles.include?(PBMonRoles::PIVOT)
              pivotvar=true
            end
          end
          if pivotvar && !@doublebattle
            score*=1.2
          end
          livecount2=0
          for i in pbParty(attacker.index)
            next if i.nil?
            livecount2+=1 if i.hp!=0
          end
          if livecount>1 && livecount2==1
            score*=0.8
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::SOULHEART)
            score*=1.3
          end
        end
      when 0x40 # Flatter
        if opponent != attacker.pbPartner
          if opponent.pbCanConfuse?(false)
            miniscore=100
            ministat=0
            ministat+=opponent.stages[PBStats::ATTACK]
            if ministat>0
              minimini=10*ministat
              minimini+=100
              minimini/=100.0
              miniscore*=minimini
            end
            if opponent.attack>opponent.spatk
              miniscore*=1.5
            else
              miniscore*=0.3
            end
            if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
              miniscore*=1.3
            end
            if opponent.effects[PBEffects::Attract]>=0
              miniscore*=1.1
            end
            if opponent.status==PBStatuses::PARALYSIS
              miniscore*=1.1
            end
            if opponent.effects[PBEffects::Yawn]>0 || opponent.status==PBStatuses::SLEEP
              miniscore*=0.4
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::TANGLEDFEET)
              miniscore*=0.7
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::CONTRARY)
              miniscore*=1.5
            end
            if attacker.pbHasMove?(:SUBSTITUTE)
              miniscore*=1.2
              if attacker.effects[PBEffects::Substitute]>0
                miniscore*=1.3
              end
            end
            miniscore/=100.0
            score*=miniscore
          else
            score=0
          end
        else
          if opponent.pbCanConfuse?(false)
            score*=0.5
          else
            score*=1.5
          end
          if opponent.attack<opponent.spatk
            score*=1.5
          end
          if (1.0/opponent.totalhp)*opponent.hp < 0.6
            score*=0.3
          end
          if opponent.effects[PBEffects::Attract]>=0 || opponent.status==PBStatuses::PARALYSIS ||
             opponent.effects[PBEffects::Yawn]>0 || opponent.status==PBStatuses::SLEEP
            score*=0.3
          end
          if oppitemworks && (opponent.item == PBItems::PERSIMBERRY || opponent.item == PBItems::LUMBERRY)
            score*=1.2
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::CONTRARY)
            score*=0
          end
          if opponent.effects[PBEffects::Substitute]>0
            score*=0
          end
          opp1 = attacker.pbOppositeOpposing
          opp2 = opp1.pbPartner
          if opponent.pbSpeed > opp1.pbSpeed && opponent.pbSpeed > opp2.pbSpeed
            score*=1.3
          else
            score*=0.7
          end
        end
      when 0x41 # Swagger
        if opponent != attacker.pbPartner
          if opponent.pbCanConfuse?(false)
            miniscore=100
            if opponent.attack<opponent.spatk
              miniscore*=1.5
            else
              miniscore*=0.7
            end
            if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
              miniscore*=1.3
            end
            if opponent.effects[PBEffects::Attract]>=0
              miniscore*=1.3
            end
            if opponent.status==PBStatuses::PARALYSIS
              miniscore*=1.3
            end
            if opponent.effects[PBEffects::Yawn]>0 || opponent.status==PBStatuses::SLEEP
              miniscore*=0.4
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::TANGLEDFEET)
              miniscore*=0.7
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::CONTRARY)
              miniscore*=1.5
            end
            if attacker.pbHasMove?(:SUBSTITUTE)
              miniscore*=1.2
              if attacker.effects[PBEffects::Substitute]>0
                miniscore*=1.3
              end
            end
            if attacker.pbHasMove?(:FOULPLAY)
              miniscore*=1.5
            end
            miniscore/=100.0
            score*=miniscore
          else
            score=0
          end
        else
          if opponent.pbCanConfuse?(false)
            score*=0.5
          else
            score*=1.5
          end
          if opponent.attack>opponent.spatk
            score*=1.5
          end
          if (1.0/opponent.totalhp)*opponent.hp < 0.6
            score*=0.3
          end
          if opponent.effects[PBEffects::Attract]>=0 || opponent.status==PBStatuses::PARALYSIS ||
             opponent.effects[PBEffects::Yawn]>0 || opponent.status==PBStatuses::SLEEP
            score*=0.3
          end
          if (oppitemworks && opponent.item == PBItems::PERSIMBERRY) ||
             (oppitemworks && opponent.item == PBItems::LUMBERRY)
            score*=1.2
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::CONTRARY)
            score*=0
          end
          if opponent.effects[PBEffects::Substitute]>0
            score*=0
          end
          opp1 = attacker.pbOppositeOpposing
          opp2 = opp1.pbPartner
          if opponent.pbSpeed > opp1.pbSpeed && opponent.pbSpeed > opp2.pbSpeed
            score*=1.3
          else
            score*=0.7
          end
          if opp1.pbHasMove?(:FOULPLAY) || opp2.pbHasMove?(:FOULPLAY)
            score*=0.3
          end
        end
      when 0x42 # Growl
        if (pbRoughStat(opponent,PBStats::SPATK,skill)>pbRoughStat(opponent,PBStats::ATTACK,skill)) ||
           opponent.stages[PBStats::ATTACK]>0 || !opponent.pbCanReduceStatStage?(PBStats::ATTACK)
          if move.basedamage==0
            score=0
          end
        else
          miniscore=100
          if skill>=PBTrainerAI.bestSkill
            if move.id==(PBMoves::LUNGE)
              if $fefieldeffect==13 # Icy Field
                miniscore*=1.5
              end
            end
            if move.id==(PBMoves::AURORABEAM)
              if $fefieldeffect==30 # Mirror Field
                if (attacker.stages[PBStats::ACCURACY] < 0 || opponent.stages[PBStats::EVASION] > 0 ||
                   (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER) || (oppitemworks && opponent.item == PBItems::LAXINCENSE) ||
                   ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
                   ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL) ||
                   opponent.vanished) &&
                   !(!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD) &&
                   !(!attacker.abilitynulled && attacker.ability == PBAbilities::NOGUARD)
                  miniscore*=2
                end
              end
            end
          end
          miniscore *= unsetupminiscore(attacker,opponent,skill,move,roles,1,true)
          miniscore/=100.0
          score*=miniscore
        end
      when 0x43 # Tail Whip
        physmove=false
        for j in attacker.moves
          if j.pbIsPhysical?(j.type)
            physmove=true
          end
        end
        if !physmove || opponent.stages[PBStats::DEFENSE]>0 || !opponent.pbCanReduceStatStage?(PBStats::DEFENSE)
          if move.basedamage==0
            score=0
          end
        else
          score*=unsetupminiscore(attacker,opponent,skill,move,roles,2,true)
        end
      when 0x44 # Rock Tomb / Bulldoze / Glaciate
        if ((pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed) ^ (@trickroom!=0)) ||
           opponent.stages[PBStats::SPEED]>0 || !opponent.pbCanReduceStatStage?(PBStats::SPEED)
          if move.basedamage==0
            score=0
          end
        else
          miniscore=100
          if opponent.stages[PBStats::SPEED]<0
            minimini = 5*opponent.stages[PBStats::SPEED]
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if skill>=PBTrainerAI.bestSkill
            if move.id==(PBMoves::GLACIATE)
              if $fefieldeffect==26 # Murkwater Surface
                poisonvar=false
                watervar=false
                icevar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:POISON)
                    poisonvar=true
                  end
                  if mon.hasType?(:WATER)
                    watervar=true
                  end
                  if mon.hasType?(:ICE)
                    icevar=true
                  end
                end
                if !poisonvar && !watervar
                  miniscore*=1.3
                end
                if icevar
                  miniscore*=1.5
                end
              end
              if $fefieldeffect==21 # Water Surface
                watervar=false
                icevar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:WATER)
                    watervar=true
                  end
                  if mon.hasType?(:ICE)
                    icevar=true
                  end
                end
                if !watervar
                  miniscore*=1.3
                end
                if icevar
                  miniscore*=1.5
                end
              end
              if $fefieldeffect==32 # Dragon's Den
                dragonvar=false
                rockvar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:DRAGON)
                    dragonvar=true
                  end
                  if mon.hasType?(:ROCK)
                    rockvar=true
                  end
                end
                if !dragonvar
                  miniscore*=1.3
                end
                if rockvar
                  miniscore*=1.3
                end
              end
              if $fefieldeffect==16 # Superheated
                firevar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:FIRE)
                    firevar=true
                  end
                end
                if !firevar
                  miniscore*=1.5
                end
              end
            end
            if move.id==(PBMoves::BULLDOZE)
              if $fefieldeffect==4 # Dark Crystal Cavern
                darkvar=false
                rockvar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:DARK)
                    darkvar=true
                  end
                  if mon.hasType?(:ROCK)
                    rockvar=true
                  end
                end
                if !darkvar
                  miniscore*=1.3
                end
                if rockvar
                  miniscore*=1.2
                end
              end
              if $fefieldeffect==25 # Crystal Cavern
                dragonvar=false
                rockvar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:DRAGON)
                    dragonvar=true
                  end
                  if mon.hasType?(:ROCK)
                    rockvar=true
                  end
                end
                if !dragonvar
                  miniscore*=1.3
                end
                if rockvar
                  miniscore*=1.2
                end
              end
              if $fefieldeffect==13 # Icy Field
                icevar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:ICE)
                    icevar=true
                  end
                end
                if !icevar
                  miniscore*=1.5
                end
              end
              if $fefieldeffect==17 # Factory
                miniscore*=1.2
                darkvar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:DARK)
                    darkvar=true
                  end
                end
                if darkvar
                  miniscore*=1.3
                end
              end
              if $fefieldeffect==23 # Cave
                if !(!attacker.abilitynulled && attacker.ability == PBAbilities::ROCKHEAD) &&
                   !(!attacker.abilitynulled && attacker.ability == PBAbilities::BULLETPROOF)
                  miniscore*=0.7
                  if $fecounter >=1
                    miniscore *= 0.3
                  end
                end
              end
              if $fefieldeffect==30 # Mirror Arena
                if opponent.stages[PBStats::EVASION] > 0 ||
                  (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER) || (oppitemworks && opponent.item == PBItems::LAXINCENSE) ||
                  ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
                  ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL)
                  miniscore*=1.3
                else
                  miniscore*=0.5
                end
              end
            end
          end
          greatmoves = hasgreatmoves(initialscores,scoreindex,skill)
          miniscore*=unsetupminiscore(attacker,opponent,skill,move,roles,3,false,greatmoves)
          miniscore/=100.0
          score*=miniscore
        end
      when 0x45 # Snarl
        if (pbRoughStat(opponent,PBStats::SPATK,skill)<pbRoughStat(opponent,PBStats::ATTACK,skill)) ||
           opponent.stages[PBStats::SPATK]>0 || !opponent.pbCanReduceStatStage?(PBStats::SPATK)
          if move.basedamage==0
            score=0
          end
        else
          score*=unsetupminiscore(attacker,opponent,skill,move,roles,1,false)
        end
      when 0x46 # Psychic
        specmove=false
        for j in attacker.moves
          if j.pbIsSpecial?(j.type)
            specmove=true
          end
        end
        if !specmove || opponent.stages[PBStats::SPDEF]>0 || !opponent.pbCanReduceStatStage?(PBStats::SPDEF)
          if move.basedamage==0
            score=0
          end
        else
          miniscore=100
          if opponent.stages[PBStats::SPDEF]<0
            minimini = 5*opponent.stages[PBStats::SPDEF]
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if skill>=PBTrainerAI.bestSkill
            if move.id==(PBMoves::FLASHCANNON) || move.id==(PBMoves::LUSTERPURGE)
              if $fefieldeffect==30 # Mirror Arena
                if (attacker.stages[PBStats::ACCURACY] < 0 || opponent.stages[PBStats::EVASION] > 0 ||
                   (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER) || (oppitemworks && opponent.item == PBItems::LAXINCENSE) ||
                   ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
                   ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL) ||
                   opponent.vanished) &&
                   !(!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD) &&
                   !(!attacker.abilitynulled && attacker.ability == PBAbilities::NOGUARD)
                  miniscore*=2
                end
              end
            end
          end
          miniscore*= unsetupminiscore(attacker,opponent,skill,move,roles,2,false)
          miniscore/=100.0
          score*=miniscore
        end
      when 0x47 # Sand Attack
        if checkAIaccuracy(aimem) || opponent.stages[PBStats::ACCURACY]>0 || !opponent.pbCanReduceStatStage?(PBStats::ACCURACY)
          if move.basedamage==0
            score=0
          end
        else
          miniscore=100
          if opponent.stages[PBStats::ACCURACY]<0
            minimini = 5*opponent.stages[PBStats::ACCURACY]
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if skill>=PBTrainerAI.bestSkill
            if move.id==(PBMoves::KINESIS)
              if $fefieldeffect==20 # Ashen Beach
                miniscore*=1.3
              end
              if $fefieldeffect==37 # Psychic Terrain
                miniscore*=1.6
              end
            end
            if move.id==(PBMoves::SANDATTACK)
              if $fefieldeffect==20 || $fefieldeffect==12 # Ashen Beach/Desert
                miniscore*=1.3
              end
            end
            if move.id==(PBMoves::MIRRORSHOT)
              if $fefieldeffect==30 # Mirror Arena
                if (attacker.stages[PBStats::ACCURACY] < 0 || opponent.stages[PBStats::EVASION] > 0 ||
                  (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER) || (oppitemworks && opponent.item == PBItems::LAXINCENSE) ||
                  ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
                  ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL) ||
                  opponent.vanished) &&
                   !(!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD) &&
                   !(!attacker.abilitynulled && attacker.ability == PBAbilities::NOGUARD)
                  miniscore*=2
                end
              end
            end
            if move.id==(PBMoves::MUDDYWATER)
              if $fefieldeffect==7 # Burning
                firevar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:FIRE)
                    firevar=true
                  end
                end
                if firevar
                  miniscore*=0
                else
                  miniscore*=2
                end
              end
              if $fefieldeffect==16 # Superheated
                miniscore*=0.7
              end
              if $fefieldeffect==32 # Dragon's Den
                firevar=false
                dragonvar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:FIRE)
                    firevar=true
                  end
                  if mon.hasType?(:DRAGON)
                    dragonvar=true
                  end
                end
                if firevar || dragonvar
                  miniscore*=0
                else
                  miniscore*=1.5
                end
              end
            end
            if move.id==(PBMoves::NIGHTDAZE)
              if $fefieldeffect==25 # Crystal Cavern
                darkvar=false
                dragonvar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:DARK)
                    darkvar=true
                  end
                  if mon.hasType?(:DRAGON)
                    dragonvar=true
                  end
                end
                if darkvar
                  miniscore*=2
                end
                if dragonvar
                  miniscore*=0.75
                end
              end
            end
            if move.id==(PBMoves::LEAFTORNADO)
              if $fefieldeffect==20 # Ahsen Beach
                miniscore*=0.7
              end
            end
            if move.id==(PBMoves::FLASH)
              if $fefieldeffect==4 || $fefieldeffect==18 || $fefieldeffect==30 ||
                 $fefieldeffect==34 || $fefieldeffect==35 # Dark Crystal Cavern/Short-Circuit/Mirror/Starlight/New World
                miniscore*=1.3
              end
            end
            if move.id==(PBMoves::SMOKESCREEN)
              if $fefieldeffect==7 || $fefieldeffect==11 # Burning/Corrosive Mist
                miniscore*=1.3
              end
            end
          end
          miniscore*= unsetupminiscore(attacker,opponent,skill,move,roles,1,false)
          miniscore/=100.0
          score*=miniscore
        end
      when 0x48 # Sweet Scent
        score=0 #no
      when 0x49 # Defog
        miniscore=100
        livecount1=0
        for i in pbParty(attacker.index)
          next if i.nil?
          livecount1+=1 if i.hp!=0
        end
        livecount2=0
        for i in pbParty(opponent.index)
          next if i.nil?
          livecount2+=1 if i.hp!=0
        end
        if livecount1>1
          miniscore*=2 if attacker.pbOwnSide.effects[PBEffects::StealthRock]
          miniscore*=3 if attacker.pbOwnSide.effects[PBEffects::StickyWeb]
          miniscore*=(1.5**attacker.pbOwnSide.effects[PBEffects::Spikes])
          miniscore*=(1.7**attacker.pbOwnSide.effects[PBEffects::ToxicSpikes])
        end
        miniscore-=100
        miniscore*=(livecount1-1) if livecount1>1
        minimini=100
        if livecount2>1
          minimini*=0.5 if attacker.pbOwnSide.effects[PBEffects::StealthRock]
          minimini*=0.3 if attacker.pbOwnSide.effects[PBEffects::StickyWeb]
          minimini*=(0.7**attacker.pbOwnSide.effects[PBEffects::Spikes])
          minimini*=(0.6**attacker.pbOwnSide.effects[PBEffects::ToxicSpikes])
        end
        minimini-=100
        minimini*=(livecount2-1) if livecount2>1
        miniscore+=minimini
        miniscore+=100
        if miniscore<0
          miniscore=0
        end
        miniscore/=100.0
        score*=miniscore
        if opponent.pbOwnSide.effects[PBEffects::Reflect]>0
          score*=2
        end
        if opponent.pbOwnSide.effects[PBEffects::LightScreen]>0
          score*=2
        end
        if opponent.pbOwnSide.effects[PBEffects::Safeguard]>0
          score*=1.3
        end
        if opponent.pbOwnSide.effects[PBEffects::AuroraVeil]>0
          score*=3
        end
        if opponent.pbOwnSide.effects[PBEffects::Mist]>0
          score*=1.3
        end
      when 0x4A # Tickle
        miniscore=100
        if (pbRoughStat(opponent,PBStats::SPATK,skill)>pbRoughStat(opponent,PBStats::ATTACK,skill)) ||
           opponent.stages[PBStats::ATTACK]>0 || !opponent.pbCanReduceStatStage?(PBStats::ATTACK)
          if move.basedamage==0
            miniscore*=0.5
          end
        else
          if opponent.stages[PBStats::ATTACK]+opponent.stages[PBStats::DEFENSE]<0
            minimini = 5*opponent.stages[PBStats::ATTACK]
            minimini+= 5*opponent.stages[PBStats::DEFENSE]
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          miniscore*= unsetupminiscore(attacker,opponent,skill,move,roles,1,true)
        end
        miniscore/=100.0
        score*=miniscore
        miniscore=100
        physmove=false
        for j in attacker.moves
          if j.pbIsPhysical?(j.type)
            physmove=true
          end
        end
        if !physmove || opponent.stages[PBStats::DEFENSE]>0 || !opponent.pbCanReduceStatStage?(PBStats::DEFENSE)
          if move.basedamage==0
            miniscore*=0.5
          end
        else
          miniscore*= unsetupminiscore(attacker,opponent,skill,move,roles,2,true)
        end
        miniscore/=100.0
        score*=miniscore
      when 0x4B # Feather Dance
        if (pbRoughStat(opponent,PBStats::SPATK,skill)>pbRoughStat(opponent,PBStats::ATTACK,skill)) ||
           opponent.stages[PBStats::ATTACK]>1 || !opponent.pbCanReduceStatStage?(PBStats::ATTACK)
          if move.basedamage==0
            score=0
          end
        else
          miniscore=100
          if opponent.stages[PBStats::ATTACK]<0
            minimini = 5*opponent.stages[PBStats::ATTACK]
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==6 # Big Top
              miniscore*=1.5
            end
          end
          miniscore*= unsetupminiscore(attacker,opponent,skill,move,roles,1,true)
          miniscore/=100.0
          score*=miniscore
        end
      when 0x4C # Screech
        physmove=false
        for j in attacker.moves
          if j.pbIsPhysical?(j.type)
            physmove=true
          end
        end
        if !physmove || opponent.stages[PBStats::DEFENSE]>1 || !opponent.pbCanReduceStatStage?(PBStats::DEFENSE)
          if move.basedamage==0
            score=0
          end
        else
          if opponent.stages[PBStats::DEFENSE]<0
            minimini = 5*opponent.stages[PBStats::DEFENSE]
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          miniscore*= unsetupminiscore(attacker,opponent,skill,move,roles,2,true)
          miniscore/=100.0
          score*=miniscore
        end
      when 0x4D # Scary Face
        if ((pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed) ^ (@trickroom!=0)) ||
           opponent.stages[PBStats::SPEED]>1 || !opponent.pbCanReduceStatStage?(PBStats::SPEED)
          if move.basedamage==0
            score=0
          end
        else
          miniscore=100
          if opponent.stages[PBStats::SPEED]<0
            minimini = 5*opponent.stages[PBStats::SPEED]
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          greatmoves = hasgreatmoves(initialscores,scoreindex,skill)
          miniscore*=unsetupminiscore(attacker,opponent,skill,move,roles,3,false,greatmoves)
          miniscore/=100.0
          score*=miniscore
        end
      when 0x4E # Captivate
        canattract=true
        agender=attacker.gender
        ogender=opponent.gender
        if agender==2 || ogender==2 || agender==ogender # Pokemon are genderless or same gender
          canattract=false
        elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::OBLIVIOUS)
          canattract=false
        end
        if (pbRoughStat(opponent,PBStats::SPATK,skill)<pbRoughStat(opponent,PBStats::ATTACK,skill)) ||
           opponent.stages[PBStats::SPATK]>1 || !opponent.pbCanReduceStatStage?(PBStats::SPATK)
          if move.basedamage==0
            score=0
          end
        elsif !canattract
          score=0
        else
          miniscore=100
          if opponent.stages[PBStats::SPATK]<0
            minimini = 5*opponent.stages[PBStats::SPATK]
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          miniscore*= unsetupminiscore(attacker,opponent,skill,move,roles,1,false)
          miniscore/=100.0
          score*=miniscore
        end
      when 0x4F # Acid Spray
        specmove=false
        for j in attacker.moves
          if j.pbIsSpecial?(j.type)
            specmove=true
          end
        end
        if !specmove || opponent.stages[PBStats::SPDEF]>1 || !opponent.pbCanReduceStatStage?(PBStats::SPDEF)
          if move.basedamage==0
            score=0
          end
        else
          miniscore=100
          if skill>=PBTrainerAI.bestSkill
            if move.id==(PBMoves::METALSOUND)
              if $fefieldeffect==17 || $fefieldeffect==18 # Factory/Short-Circuit
                miniscore*=1.5
              end
            end
            if move.id==(PBMoves::SEEDFLARE)
              if $fefieldeffect==10 # Corrosive
                poisonvar=false
                grassvar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:POISON)
                    poisonvar=true
                  end
                  if mon.hasType?(:GRASS)
                    grassvar=true
                  end
                end
                if !poisonvar
                  miniscore*=1.5
                end
                if grassvar
                  miniscore*=1.5
                end
              end
            end
          end
          miniscore*= unsetupminiscore(attacker,opponent,skill,move,roles,2,false)
          miniscore/=100.0
          score*=miniscore
        end
      when 0x50 # Clear Smog
        if opponent.effects[PBEffects::Substitute]<=0
          miniscore = 5*statchangecounter(opponent,1,7)
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
            score*=1.1
          end
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==3 # Misty
              poisonvar=false
              fairyvar=false
              for mon in pbParty(attacker.index)
                next if mon.nil?
                if mon.hasType?(:POISON)
                  poisonvar=true
                end
                if mon.hasType?(:FAIRY)
                  fairyvar=true
                end
              end
              if poisonvar
                score*=1.3
              end
              if !fairyvar
                score*=1.3
              end
            end
          end
        end
      when 0x51 # Haze
        miniscore = (-10)* statchangecounter(attacker,1,7)
        minimini = (10)* statchangecounter(opponent,1,7)
        if @doublebattle
          if attacker.pbPartner.hp>0
            miniscore+= (-10)* statchangecounter(attacker.pbPartner,1,7)
          end
          if opponent.pbPartner.hp>0
            minimini+= (10)* statchangecounter(opponent.pbPartner,1,7)
          end
        end
        if miniscore==0 && minimini==0
          score*=0
        else
          miniscore+=minimini
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST) ||
           checkAImoves(PBStuff::SETUPMOVE,aimem)
          score*=0.8
        end
      when 0x52 # Power Swap
        stages=0
        stages+=attacker.stages[PBStats::ATTACK]
        stages+=attacker.stages[PBStats::SPATK]
        miniscore = (-10)*stages
        if attacker.attack > attacker.spatk
          if attacker.stages[PBStats::ATTACK]!=0
            miniscore*=2
          end
        else
          if attacker.stages[PBStats::SPATK]!=0
            miniscore*=2
          end
        end
        stages=0
        stages+=opponent.stages[PBStats::ATTACK]
        stages+=opponent.stages[PBStats::SPATK]
        minimini = (10)*stages
        if opponent.attack > opponent.spatk
          if opponent.stages[PBStats::ATTACK]!=0
            minimini*=2
          end
        else
          if opponent.stages[PBStats::SPATK]!=0
            minimini*=2
          end
        end
        if miniscore==0 && minimini==0
          score*=0
        else
          miniscore+=minimini
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
          if @doublebattle
            score*=0.8
          end
        end
      when 0x53 # Guard Swap
        stages=0
        stages+=attacker.stages[PBStats::DEFENSE]
        stages+=attacker.stages[PBStats::SPDEF]
        miniscore = (-10)*stages
        if attacker.defense > attacker.spdef
          if attacker.stages[PBStats::DEFENSE]!=0
            miniscore*=2
          end
        else
          if attacker.stages[PBStats::SPDEF]!=0
            miniscore*=2
          end
        end
        stages=0
        stages+=opponent.stages[PBStats::DEFENSE]
        stages+=opponent.stages[PBStats::SPDEF]
        minimini = (10)*stages
        if opponent.defense > opponent.spdef
          if opponent.stages[PBStats::DEFENSE]!=0
            minimini*=2
          end
        else
          if opponent.stages[PBStats::SPDEF]!=0
            minimini*=2
          end
        end
        if miniscore==0 && minimini==0
          score*=0
        else
          miniscore+=minimini
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
          if @doublebattle
            score*=0.8
          end
        end
      when 0x54 # Heart Swap
        stages=0
        stages+=attacker.stages[PBStats::ATTACK] unless attacker.attack<attacker.spatk
        stages+=attacker.stages[PBStats::DEFENSE] unless opponent.attack<opponent.spatk
        stages+=attacker.stages[PBStats::SPEED]
        stages+=attacker.stages[PBStats::SPATK] unless attacker.attack>attacker.spatk
        stages+=attacker.stages[PBStats::SPDEF] unless opponent.attack>opponent.spatk
        stages+=attacker.stages[PBStats::EVASION]
        stages+=attacker.stages[PBStats::ACCURACY]
        miniscore = (-10)*stages
        stages=0
        stages+=opponent.stages[PBStats::ATTACK] unless opponent.attack<opponent.spatk
        stages+=opponent.stages[PBStats::DEFENSE] unless attacker.attack<attacker.spatk
        stages+=opponent.stages[PBStats::SPEED]
        stages+=opponent.stages[PBStats::SPATK] unless opponent.attack>opponent.spatk
        stages+=opponent.stages[PBStats::SPDEF] unless attacker.attack>attacker.spatk
        stages+=opponent.stages[PBStats::EVASION]
        stages+=opponent.stages[PBStats::ACCURACY]
        minimini = (10)*stages
        if !(miniscore==0 && minimini==0)
          miniscore+=minimini
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
          if @doublebattle
            score*=0.8
          end
        else
          if $fefieldeffect==35 # New World
            score=25
          else
            score=0
          end
        end
        if $fefieldeffect==35 # New World
          ministat = opponent.hp + attacker.hp*0.5
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if maxdam>ministat
            score*=0.5
          else
            if maxdam>attacker.hp
              if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
                score*=2
              else
                score*=0*5
              end
            else
              miniscore = opponent.hp * (1.0/attacker.hp)
              score*=miniscore
            end
          end
        end
      when 0x55 # Psych Up
        stages=0
        stages+=attacker.stages[PBStats::ATTACK] unless attacker.attack<attacker.spatk
        stages+=attacker.stages[PBStats::DEFENSE] unless opponent.attack<opponent.spatk
        stages+=attacker.stages[PBStats::SPEED]
        stages+=attacker.stages[PBStats::SPATK] unless attacker.attack>attacker.spatk
        stages+=attacker.stages[PBStats::SPDEF] unless opponent.attack>opponent.spatk
        stages+=attacker.stages[PBStats::EVASION]
        stages+=attacker.stages[PBStats::ACCURACY]
        miniscore = (-10)*stages
        stages=0
        stages+=opponent.stages[PBStats::ATTACK] unless attacker.attack<attacker.spatk
        stages+=opponent.stages[PBStats::DEFENSE] unless opponent.attack<opponent.spatk
        stages+=opponent.stages[PBStats::SPEED]
        stages+=opponent.stages[PBStats::SPATK] unless attacker.attack>attacker.spatk
        stages+=opponent.stages[PBStats::SPDEF] unless opponent.attack>opponent.spatk
        stages+=opponent.stages[PBStats::EVASION]
        stages+=opponent.stages[PBStats::ACCURACY]
        minimini = (10)*stages
        if !(miniscore==0 && minimini==0)
          miniscore+=minimini
          miniscore+=100
          miniscore/=100
          score*=miniscore
        else
          if $fefieldeffect==37 # Psychic Terrain
            score=35
          else
            score=0
          end
        end
        if $fefieldeffect==37 # Psychic Terrain
          miniscore=100
          if initialscores.length>0
            miniscore*=1.3 if hasbadmoves(initialscores,scoreindex,20)
          end
          if attacker.hp*(1.0/attacker.totalhp)>=0.75
            miniscore*=1.2
          end
          if opponent.effects[PBEffects::HyperBeam]>0
            miniscore*=1.3
          end
          if opponent.status==PBStatuses::SLEEP || opponent.status==PBStatuses::FROZEN
            miniscore*=1.3
          end
          if opponent.effects[PBEffects::Encore]>0
            if opponent.moves[(opponent.effects[PBEffects::EncoreIndex])].basedamage==0
              miniscore*=1.5
            end
          end
          if attacker.effects[PBEffects::Confusion]>0
            miniscore*=0.5
          end
          if attacker.effects[PBEffects::LeechSeed]>=0 || attacker.effects[PBEffects::Attract]>=0
            miniscore*=0.5
          end
          if skill>=PBTrainerAI.bestSkill
            miniscore*=1.3 if checkAIhealing(aimem)
            miniscore*=0.6 if checkAIpriority(aimem)
          end
          if roles.include?(PBMonRoles::SWEEPER)
            miniscore*=1.3
          end
          specialvar = false
          for i in attacker.moves
            if i.pbIsSpecial?(i.type)
              special=true
            end
          end
          if attacker.stages[PBStats::SPATK]!=6 && specialvar
            score*=miniscore
          else
            score=0
          end
        end
      when 0x56 # Mist
        miniscore = 1
        minimini = 1
        if attacker.pbOwnSide.effects[PBEffects::Mist]==0
          minimini*=1.1
          movecheck=false
          # check opponent for stat decreasing moves
          if aimem.length > 0
            for j in aimem
              movecheck=true if (j.function==0x42 || j.function==0x43 || j.function==0x44 ||
                                j.function==0x45 || j.function==0x46 || j.function==0x47 ||
                                j.function==0x48 || j.function==0x49 || j.function==0x4A ||
                                j.function==0x4B || j.function==0x4C || j.function==0x4D ||
                                j.function==0x4E || j.function==0x4F || j.function==0xE2 ||
                                j.function==0x138 || j.function==0x13B || j.function==0x13F)
            end
          end
          if movecheck
            minimini*=1.3
          end
        end
        if $fefieldeffect!=3 && $fefieldeffect!=22 && $fefieldeffect!=35# (not) Misty Terrain
          miniscore*=getFieldDisruptScore(attacker,opponent,skill)
          fairyvar=false
          for mon in pbParty(attacker.index)
            next if mon.nil?
            if mon.hasType?(:FAIRY)
              fairyvar=true
            end
          end
          if fairyvar
            miniscore*=1.3
          end
          if opponent.pbHasType?(:DRAGON) && !attacker.pbHasType?(:FAIRY)
            miniscore*=1.3
          end
          if attacker.pbHasType?(:DRAGON)
            miniscore*=0.5
          end
          if opponent.pbHasType?(:FAIRY)
            miniscore*=0.5
          end
          if attacker.pbHasType?(:FAIRY) && opponent.spatk>opponent.attack
            miniscore*=1.5
          end
          if (attitemworks && attacker.item == PBItems::AMPLIFIELDROCK)
            miniscore*=2
          end
        end
        score*=miniscore
        score*=minimini
        if miniscore<=1 && minimini<=1
          score*=0
        end
      when 0x57 # Power Trick
        if attacker.attack - attacker.defense >= 100
          if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) ||
             (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom!=0)
            score*=1.5
          end
          if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
            score*=2
          end
          healmove=false
          for j in attacker.moves
            if j.isHealingMove?
              healmove=true
            end
          end
          if healmove
            score*=2
          end
        elsif attacker.defense - attacker.attack >= 100
          if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) ||
             (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom!=0)
            score*=1.5
            if attacker.hp==attacker.totalhp &&
               (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
               ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
               (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
               (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
              score*=2
            end
          else
            score*=0
          end
        else
          score*=0.1
        end
        if attacker.effects[PBEffects::PowerTrick]
          score*=0.1
        end
      when 0x58 # Power Split
        if  pbRoughStat(opponent,PBStats::ATTACK,skill)> pbRoughStat(opponent,PBStats::SPATK,skill)
          if attacker.attack > pbRoughStat(opponent,PBStats::ATTACK,skill)
            score*=0
          else
            miniscore = pbRoughStat(opponent,PBStats::ATTACK,skill) - attacker.attack
            miniscore+=100
            miniscore/=100
            if attacker.attack>attacker.spatk
              miniscore*=2
            else
              miniscore*=0.5
            end
            score*=miniscore
          end
        else
          if attacker.spatk > pbRoughStat(opponent,PBStats::SPATK,skill)
            score*=0
          else
            miniscore = pbRoughStat(opponent,PBStats::SPATK,skill) - attacker.spatk
            miniscore+=100
            miniscore/=100
            if attacker.attack<attacker.spatk
              miniscore*=2
            else
              miniscore*=0.5
            end
            score*=miniscore
          end
        end
      when 0x59 # Guard Split
        if  pbRoughStat(opponent,PBStats::ATTACK,skill)> pbRoughStat(opponent,PBStats::SPATK,skill)
          if attacker.defense > pbRoughStat(opponent,PBStats::DEFENSE,skill)
            score*=0
          else
            miniscore = pbRoughStat(opponent,PBStats::DEFENSE,skill) - attacker.defense
            miniscore+=100
            miniscore/=100
            if attacker.attack>attacker.spatk
              miniscore*=2
            else
              miniscore*=0.5
            end
            score*=miniscore
          end
        else
          if attacker.spdef > pbRoughStat(opponent,PBStats::SPDEF,skill)
            score*=0
          else
            miniscore = pbRoughStat(opponent,PBStats::SPDEF,skill) - attacker.spdef
            miniscore+=100
            miniscore/=100
            if attacker.attack<attacker.spatk
              miniscore*=2
            else
              miniscore*=0.5
            end
            score*=miniscore
          end
        end
      when 0x5A # Pain Split
        if opponent.effects[PBEffects::Substitute]<=0
          ministat = opponent.hp + (attacker.hp/2.0)
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if maxdam>ministat
            score*=0
          elsif maxdam>attacker.hp
            if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=2
            else
              score*=0
            end
          else
            miniscore=(opponent.hp/(attacker.hp).to_f)
            score*=miniscore
          end
        else
          score*=0
        end
      when 0x5B # Tailwind
        if attacker.pbOwnSide.effects[PBEffects::Tailwind]>0
          score = 0
        else
          score*=1.5
          if ((attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) && !roles.include?(PBMonRoles::LEAD)
            score*=0.9
            livecount=0
            for i in pbParty(attacker.index)
              next if i.nil?
              livecount+=1 if i.hp!=0
            end
            if livecount==1
                score*=0.4
            end
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
            score*=0.5
          end
          score*=0.1 if @trickroom!=0 || checkAImoves([PBMoves::TRICKROOM],aimem)
          if roles.include?(PBMonRoles::LEAD)
            score*=1.4
          end
          if @opponent.is_a?(Array) == false
            if @opponent.trainertype==PBTrainers::ADRIENN
              score *= 2.5
            end
          end
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==3 # Misty
              fairyvar=false
              for mon in pbParty(attacker.index)
                next if mon.nil?
                if mon.hasType?(:FAIRY)
                  fairyvar=true
                end
              end
              if !fairyvar
                score*=1.5
              end
              if !@opponent.is_a?(Array)
                if @opponent.trainertype==PBTrainers::ADRIENN
                  score*=2
                end
              end
            end
            if $fefieldeffect==7 # Burning
              firevar=false
              for mon in pbParty(attacker.index)
                next if mon.nil?
                if mon.hasType?(:FIRE)
                  firevar=true
                end
                if !firevar
                  score*=1.2
                end
              end
            end
            if $fefieldeffect==11 # Corromist
              poisonvar=false
              for mon in pbParty(attacker.index)
                next if mon.nil?
                if mon.hasType?(:POISON)
                  poisonvar=true
                end
                if !poisonvar
                  score*=1.2
                end
              end
            end
            if $fefieldeffect==27 || $fefieldeffect==28 # Mountain/Snowy Mountain
              score*=1.5
              for mon in pbParty(attacker.index)
                flyingvar=false
                next if mon.nil?
                if mon.hasType?(:FLYING)
                  flyingvar=true
                end
                if flyingvar
                  score*=1.5
                end
              end
            end
          end
        end
      when 0x5C # Mimic
        blacklist=[
          0x02,   # Struggle
          0x14,   # Chatter
          0x5C,   # Mimic
          0x5D,   # Sketch
          0xB6    # Metronome
        ]
        miniscore = $pkmn_move[opponent.lastMoveUsed][1]
        if miniscore=0
          miniscore=40
        end
        miniscore+=100
        miniscore/=100.0
        if miniscore<=1.5
          miniscore*=0.5
        end
        score*=miniscore
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          if blacklist.include?($pkmn_move[opponent.lastMoveUsed][1]) || opponent.lastMoveUsed<0
            score*=0
          end
        else
          score*=0.5
        end
        if opponent.effects[PBEffects::Substitute] > 0
          score*=0
        end
      when 0x5D # Sketch
        blacklist=[
          0x02,   # Struggle
          0x14,   # Chatter
          0x5D,   # Sketch
        ]
        miniscore = $pkmn_move[opponent.lastMoveUsedSketch][1]
        if miniscore=0
          miniscore=40
        end
        miniscore+=100
        miniscore/=100.0
        if miniscore<=1.5
          miniscore*=0.5
        end
        score*=miniscore
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          if blacklist.include?($pkmn_move[opponent.lastMoveUsedSketch][0]) || opponent.lastMoveUsedSketch<0
            score*=0
          end
        else
          score*=0.5
        end
        if opponent.effects[PBEffects::Substitute]>0
          score*= 0
        end
      when 0x5E # Conversion
        miniscore = [PBTypes.getCombinedEffectiveness(opponent.type1,attacker.type1,attacker.type2),
                     PBTypes.getCombinedEffectiveness(opponent.type2,attacker.type1,attacker.type2)].max
        minimini = [PBTypes.getEffectiveness(opponent.type1,attacker.moves[0].type),
                    PBTypes.getEffectiveness(opponent.type2,attacker.moves[0].type)].max
        if minimini < miniscore
          score*=3
          if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=1.2
          else
            score*=0.5
          end
          stabvar = false
          for i in attacker.moves
            if i.type==attacker.type1 || i.type==attacker.type2
              stabvar = true
            end
          end
          if !stabvar
            score*=1.3
          end
          if $feconversionuse==1
            score*=0.3
          end
        else
          score*=0
        end
        if $fefieldeffect!=24 && $fefieldeffect!=22 && $fefieldeffect!=35
          miniscore = getFieldDisruptScore(attacker,opponent,skill)
          if $feconversionuse!=2
            miniscore-=1
            miniscore/=2.0
            miniscore+=1
          end
          score*=miniscore
        end
        if (attacker.moves[0].type == attacker.type1 && attacker.moves[0].type == attacker.type2)
          score = 0
        end
      when 0x5F # Conversion 2
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=1.2
        else
          score*=0.7
        end
        stabvar = false
        for i in attacker.moves
          if i.type==attacker.type1 || i.type==attacker.type2
            stabvar = true
          end
        end
        if stabvar
          score*=1.3
        else
          score*=0.7
        end
        if $feconversionuse==2
          score*=0.3
        end
        if $fefieldeffect!=24 && $fefieldeffect!=22 && $fefieldeffect!=35
          miniscore = getFieldDisruptScore(attacker,opponent,skill)
          if $feconversionuse!=1
            miniscore-=1
            miniscore/=2.0
            miniscore+=1
          end
          score*=miniscore
        end
      when 0x60 # Camouflage
        type = 0
        case $fefieldeffect
          when 25
            type = PBTypes::QMARKS #type is random
          when 35
            type = PBTypes::QMARKS
          else
            camotypes = FieldEffects::MIMICRY
            type = camotypes[$fefieldeffect]
        end
        miniscore = [PBTypes.getCombinedEffectiveness(opponent.type1,attacker.type1,attacker.type2),
                     PBTypes.getCombinedEffectiveness(opponent.type2,attacker.type1,attacker.type2)].max
        minimini = [PBTypes.getEffectiveness(opponent.type1,type),
                    PBTypes.getEffectiveness(opponent.type2,type)].max
        if minimini < miniscore
          score*=2
          if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=1.2
          else
            score*=0.7
          end
          stabvar = false
          for i in attacker.moves
            if i.type==attacker.type1 || i.type==attacker.type2
              stabvar = true
            end
          end
          if !stabvar
            score*=1.2
          else
            score*=0.6
          end
        else
          score*=0
        end
      when 0x61 # Soak
        sevar = false
        for i in attacker.moves
          if (i.type == PBTypes::ELECTRIC) || (i.type == PBTypes::GRASS)
            sevar = true
          end
        end
        if sevar
          score*=1.5
        else
          score*=0.7
        end
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          if attacker.pbHasMove?(:TOXIC)
            if attacker.pbHasType?(:STEEL) || attacker.pbHasType?(:POISON)
              score*=1.5
            end
          end
        end
        if aimem.length > 0
          movecheck=false
          for j in aimem
            movecheck=true if (j.type == PBTypes::WATER)
          end
          if movecheck
            score*=0.5
          else
            score*=1.1
          end
        end
        if opponent.type1==(PBTypes::WATER) && opponent.type1==(PBTypes::WATER)
          score=0
        end
      when 0x62 # Reflect Type
        typeid=getID(PBTypes,type)
        miniscore = [PBTypes.getCombinedEffectiveness(opponent.type1,attacker.type1,attacker.type2),
                     PBTypes.getCombinedEffectiveness(opponent.type2,attacker.type1,attacker.type2)].max
        minimini = [PBTypes.getCombinedEffectiveness(opponent.type1,opponent.type1,opponent.type2),
                    PBTypes.getCombinedEffectiveness(opponent.type2,opponent.type1,opponent.type2)].max
        if minimini < miniscore
          score*=3
          if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=1.2
          else
            score*=0.7
          end
          stabvar = false
          oppstab = false
          for i in attacker.moves
            if i.type == attacker.type1 || i.type == attacker.type2
              stabvar = true
            end
            if i.type == opponent.type1 || i.type == opponent.type2
              oppstab = true
            end
          end
          if !stabvar
            score*=1.2
          end
          if oppstab
            score*=1.3
          end
        else
          score*=0
        end
        if (attacker.ability == PBAbilities::MULTITYPE) ||
           (attacker.type1 == opponent.type1 && attacker.type2 == opponent.type2) ||
           (attacker.type1 == opponent.type2 && attacker.type2 == opponent.type1)
          score*=0
        end
      when 0x63 # Simple Beam
        score = 0 if opponent.unstoppableAbility? ||
                     isConst?(opponent.ability, PBAbilities, :TRUANT) ||
                     isConst?(opponent.ability, PBAbilities, :SIMPLE)
        if score > 0
          miniscore = getAbilityDisruptScore(move,attacker,opponent,skill)
          if opponent == attacker.pbPartner
            if miniscore < 2
              miniscore = 2 - miniscore
            else
              miniscore = 0
            end
          end
          score*=miniscore
          if checkAImoves(PBStuff::SETUPMOVE,aimem)
            if opponent==attacker.pbPartner
              score*=1.3
            else
              score*=0.5
            end
          end
        end
      when 0x64 # Worry Seed
        score = 0 if opponent.unstoppableAbility? ||
                     isConst?(opponent.ability, PBAbilities, :TRUANT) ||
                     isConst?(opponent.ability, PBAbilities, :INSOMNIA)
        score = 0 if opponent.effects[PBEffects::Substitute] > 0
        if score > 0
          miniscore = getAbilityDisruptScore(move,attacker,opponent,skill)
          score*=miniscore
          if checkAImoves([PBMoves::SNORE,PBMoves::SLEEPTALK],aimem)
            score*=1.3
          end
          if checkAImoves([PBMoves::REST],aimem)
            score*=2
          end
          if attacker.pbHasMove?(:SPORE) ||
             attacker.pbHasMove?(:SLEEPPOWDER) ||
             attacker.pbHasMove?(:HYPNOSIS) ||
             attacker.pbHasMove?(:SING) ||
             attacker.pbHasMove?(:GRASSWHISTLE) ||
             attacker.pbHasMove?(:DREAMEATER) ||
             attacker.pbHasMove?(:NIGHTMARE) ||
             (!attacker.abilitynulled && attacker.ability == PBAbilities::BADDREAMS)
            score*=0.3
          end
        end
      when 0x65 # Role Play
        score = 0 if opponent.ungainableAbility? ||
                     isConst?(opponent.ability, PBAbilities, :POWEROFALCHEMY) ||
                     isConst?(opponent.ability, PBAbilities, :RECEIVER) ||
                     isConst?(opponent.ability, PBAbilities, :TRACE) ||
                     isConst?(opponent.ability, PBAbilities, :WONDERGUARD)
        score = 0 if attacker.unstoppableAbility?
        score = 0 if opponent.ability == 0 || attacker.ability == opponent.ability
        if score != 0
          miniscore = getAbilityDisruptScore(move,opponent,attacker,skill)
          minimini = getAbilityDisruptScore(move,attacker,opponent,skill)
          score *= (1 + (minimini-miniscore))
        end
      when 0x66 # Entrainment
        score = 0 if attacker.ungainableAbility? ||
                     isConst?(attacker.ability, PBAbilities, :POWEROFALCHEMY) ||
                     isConst?(attacker.ability, PBAbilities, :RECEIVER) ||
                     isConst?(attacker.ability, PBAbilities, :TRACE)
        score = 0 if opponent.unstoppableAbility? ||
                     isConst?(opponent.ability, PBAbilities, :TRUANT)
        score = 0 if attacker.ability == 0 || attacker.ability == opponent.ability
        if score > 0
          miniscore = getAbilityDisruptScore(move,opponent,attacker,skill)
          minimini = getAbilityDisruptScore(move,attacker,opponent,skill)
          if opponent != attacker.pbPartner
            score *= (1 + (minimini-miniscore))
            if (attacker.ability == PBAbilities::TRUANT)
              score*=3
            elsif (attacker.ability == PBAbilities::WONDERGUARD)
              score=0
            end
          else
            score *= (1 + (miniscore-minimini))
            if (attacker.ability == PBAbilities::WONDERGUARD)
              score +=85
            elsif (attacker.ability == PBAbilities::SPEEDBOOST)
              score +=25
            elsif (opponent.ability == PBAbilities::DEFEATIST)
              score +=30
            elsif (opponent.ability == PBAbilities::SLOWSTART)
              score +=50
            end
          end
        end
      when 0x67 # Skill Swap
        score = 0 if attacker.unstoppableAbility? || opponent.unstoppableAbility?
        score = 0 if attacker.ungainableAbility? || isConst?(attacker.ability, PBAbilities, :WONDERGUARD)
        score = 0 if opponent.ungainableAbility? || isConst?(opponent.ability, PBAbilities, :WONDERGUARD)
        score = 0 if attacker.ability == 0 || opponent.ability == 0 ||
                     (attacker.ability == opponent.ability && !NEWEST_BATTLE_MECHANICS)
        if score > 0
          miniscore = getAbilityDisruptScore(move,opponent,attacker,skill)
          minimini = getAbilityDisruptScore(move,attacker,opponent,skill)
          if opponent == attacker.pbPartner
            if minimini < 2
              minimini = 2 - minimini
            else
              minimini = 0
            end
          end
          score *= (1 + (minimini-miniscore)*2)
          if (attacker.ability == PBAbilities::TRUANT) && opponent!=attacker.pbPartner
            score*=2
          end
          if (opponent.ability == PBAbilities::TRUANT) && opponent==attacker.pbPartner
            score*=2
          end
        end
      when 0x68 # Gastro Acid
        score = 0 if opponent.effects[PBEffects::GastroAcid] ||
                     opponent.effects[PBEffects::Substitute] > 0
        score = 0 if opponent.unstoppableAbility?
        if score > 0
          miniscore = getAbilityDisruptScore(move,attacker,opponent,skill)
          score*=miniscore
        end
      when 0x69 # Transform
        if !(attacker.effects[PBEffects::Transform] ||
           attacker.effects[PBEffects::Illusion] ||
           attacker.effects[PBEffects::Substitute]>0)
          miniscore = opponent.level
          miniscore -= attacker.level
          miniscore*=5
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
          miniscore=(10)*statchangecounter(opponent,1,5)
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
          miniscore=(-10)*statchangecounter(attacker,1,5)
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
        else
          score=0
        end
      when 0x6A # Sonicboom
      when 0x6B # Dragon Rage
      when 0x6C # Super Fang
      when 0x6D # Seismic Toss
      when 0x6E # Endeavor
        if attacker.hp > opponent.hp
          score=0
        else
          privar = false
          for i in attacker.moves
            if i.priority>0
              privar=true
            end
          end
          if privar
            score*=1.5
          end
          if ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) ||
             (attitemworks && attacker.item == PBItems::FOCUSSASH)) && attacker.hp == attacker.totalhp
            score*=1.5
          end
          if pbWeather==PBWeather::SANDSTORM && (!opponent.pbHasType?(:ROCK) && !opponent.pbHasType?(:GROUND) && !opponent.pbHasType?(:STEEL))
            score*=1.5
          end
          if opponent.level - attacker.level > 9
            score*=2
          end
        end
      when 0x6F # Psywave
      when 0x70 # Fissure
        if !(opponent.level>attacker.level) &&
           !(!opponent.abilitynulled && opponent.ability == PBAbilities::STURDY)
          if opponent.effects[PBEffects::LockOn]>0
            score*=3.5
          else
            score*=0.7
          end
        else
          score*=0
        end
        if move.id==(PBMoves::FISSURE)
          if $fefieldeffect==17 # Factory
            score*=1.2
            darkvar=false
            for mon in pbParty(attacker.index)
              next if mon.nil?
              if mon.hasType?(:DARK)
                darkvar=true
              end
            end
            if darkvar
              score*=1.5
            end
          end
        end
      when 0x71 # Counter
        maxdam = checkAIdamage(aimem,attacker,opponent,skill)
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=0.5
        end
        if ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) ||
           (attitemworks && attacker.item == PBItems::FOCUSSASH)) && attacker.hp == attacker.totalhp
          score*=1.2
        else
          score*=0.8
          if maxdam>attacker.hp
            score*=0.8
          end
        end
        if $pkmn_move[attacker.lastMoveUsed][0]==0x71
          score*=0.7
        end
        score*=0.6 if checkAImoves(PBStuff::SETUPMOVE,aimem)
        miniscore = attacker.hp*(1.0/attacker.totalhp)
        score*=miniscore
        if opponent.spatk>opponent.attack
          score*=0.3
        end
        score*=0.05 if checkAIbest(aimem,3,[],false,attacker,opponent,skill)
        if $pkmn_move[attacker.lastMoveUsed][0]==0x72
          score*=1.1
        end
      when 0x72 # Mirror Coat
        maxdam = checkAIdamage(aimem,attacker,opponent,skill)
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=0.5
        end
        if ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) ||
           (attitemworks && attacker.item == PBItems::FOCUSSASH)) && attacker.hp == attacker.totalhp
          score*=1.2
        else
          score*=0.8
          if maxdam>attacker.hp
            score*=0.8
          end
        end
        if $pkmn_move[attacker.lastMoveUsed][0]==0x72
          score*=0.7
        end
        score*=0.6 if checkAImoves(PBStuff::SETUPMOVE,aimem)
        miniscore = attacker.hp*(1.0/attacker.totalhp)
        score*=miniscore
        if opponent.spatk<opponent.attack
          score*=0.3
        end
        score*=0.05 if checkAIbest(aimem,2,[],false,attacker,opponent,skill)
        if $pkmn_move[attacker.lastMoveUsed][0]==0x71
          score*=1.1
        end
      when 0x73 # Metal Burst
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=0.01
        end
        if ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) ||
           (attitemworks && attacker.item == PBItems::FOCUSSASH)) && attacker.hp == attacker.totalhp
          score*=1.2
        else
          score*=0.8 if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
        end
        if $pkmn_move[attacker.lastMoveUsed][0]==0x73
          score*=0.7
        end
        movecheck=false
        score*=0.6 if checkAImoves(PBStuff::SETUPMOVE,aimem)
        miniscore = attacker.hp*(1.0/attacker.totalhp)
        score*=miniscore
      when 0x74 # Flame Burst
        if @doublebattle && opponent.pbPartner.hp>0
          score*=1.1
        end
        roastvar=false
        firevar=false
        poisvar=false
        icevar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:GRASS) || mon.hasType?(:BUG)
            roastvar=true
          end
          if mon.hasType?(:FIRE)
            firevar=true
          end
          if mon.hasType?(:POISON)
            poisvar=true
          end
          if mon.hasType?(:ICE)
            icevar=true
          end
        end
        if $fefieldeffect==2 || $fefieldeffect==15 || ($fefieldeffect==33 && $fecounter>1)
          if firevar && !roastvar
            score*=2
          end
        end
        if $fefieldeffect==16
          if firevar
            score*=2
          end
        end
        if $fefieldeffect==11
          if !poisvar
            score*=1.2
          end
          if attacker.hp*(1.0/attacker.totalhp)<0.2
            score*=2
          end
          if pbPokemonCount(pbParty(opponent.index))==1
            score*=5
          end
        end
        if $fefieldeffect==13 || $fefieldeffect==28
          if !icevar
            score*=1.5
          end
        end
      when 0x75 # Surf
        firevar=false
        dragvar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:FIRE)
            firevar=true
          end
          if mon.hasType?(:DRAGON)
            dragvar=true
          end
        end
        if $fefieldeffect==7
          if firevar
            score=0
          else
            score*=2
          end
        end
        if $fefieldeffect==16
          score*=0.7
        end
        if $fefieldeffect==32
          if dragvar || firevar
            score=0
          else
            score*=1.5
          end
        end
      when 0x76 # Earthquake
        darkvar=false
        rockvar=false
        dragvar=false
        icevar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:DARK)
            darkvar=true
          end
          if mon.hasType?(:ROCK)
            rockvar=true
          end
          if mon.hasType?(:DRAGON)
            dragvar=true
          end
          if mon.hasType?(:ICE)
            icevar=true
          end
        end
        if $fefieldeffect==4
          if !darkvar
            score*=1.3
            if rockvar
              score*=1.2
            end
          end
        end
        if $fefieldeffect==25
          if !dragonvar
            score*=1.3
            if rockvar
              score*=1.2
            end
          end
        end
        if $fefieldeffect==13
          if !icevar
            score*=1.5
          end
        end
        if $fefieldeffect==17
          score*=1.2
          if darkvar
            score*=1.3
          end
        end
        if $fefieldeffect==23
          if !(!attacker.abilitynulled && attacker.ability == PBAbilities::ROCKHEAD) &&
             !(!attacker.abilitynulled && attacker.ability == PBAbilities::BULLETPROOF)
            score*=0.7
            if $fecounter >=1
              score *= 0.3
            end
          end
        end
        if $fefieldeffect==30
          if (opponent.stages[PBStats::EVASION] > 0 ||
             (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER) ||
             (oppitemworks && opponent.item == PBItems::LAXINCENSE) ||
             ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
             ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL))
            score*=1.3
          else
            score*=0.5
          end
        end
      when 0x77 # Gust
        fairvar=false
        firevar=false
        poisvar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:FAIRY)
            fairvar=true
          end
          if mon.hasType?(:FIRE)
            firevar=true
          end
          if mon.hasType?(:POISON)
            poisvar=true
          end
        end
        if $fefieldeffect==3
          score*=1.3
          if !fairyvar
            score*=1.3
          else
            score*=0.6
          end
        end
        if $fefieldeffect==7
          if !firevar
            score*=1.8
          else
            score*=0.5
          end
        end
        if $fefieldeffect==11
          if !poisvar
            score*=3
          else
            score*=0.8
          end
        end
      when 0x78 # Twister
        if opponent.effects[PBEffects::Substitute]==0 && !(!opponent.abilitynulled && opponent.ability == PBAbilities::INNERFOCUS)
          if (pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed) ^ (@trickroom!=0)
            miniscore=100
            miniscore*=1.3
            if skill>=PBTrainerAI.bestSkill
              if $fefieldeffect==14 # Rocky
                miniscore*=1.2
              end
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::STEADFAST)
              miniscore*=0.3
            end
            miniscore-=100
            if move.addlEffect.to_f != 100
              miniscore*=(move.addlEffect.to_f/100)
            end
            miniscore+=100
            if move.addlEffect.to_f != 100
              if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
                miniscore*=2
              end
            end
            miniscore/=100.0
            score*=miniscore
          end
        end
        fairvar=false
        firevar=false
        poisvar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:FAIRY)
            fairvar=true
          end
          if mon.hasType?(:FIRE)
            firevar=true
          end
          if mon.hasType?(:POISON)
            poisvar=true
          end
        end
        if $fefieldeffect==3
          score*=1.3
          if !fairyvar
            score*=1.3
          else
            score*=0.6
          end
        end
        if $fefieldeffect==7
          if !firevar
            score*=1.8
          else
            score*=0.5
          end
        end
        if $fefieldeffect==11
          if !poisvar
            score*=3
          else
            score*=0.8
          end
        end
        if $fefieldeffect==20
          score*=0.7
        end
      when 0x79 # Fusion Bolt
      when 0x7A # Fusion Flare
      when 0x7B # Venoshock
      when 0x7C # Smelling Salts
        if opponent.status==PBStatuses::PARALYSIS  && opponent.effects[PBEffects::Substitute]<=0
          score*=0.8
          if opponent.speed>attacker.speed && opponent.speed/2.0<attacker.speed
            score*=0.5
          end
        end
      when 0x7D # Wake-Up Slap
        if opponent.status==PBStatuses::SLEEP && opponent.effects[PBEffects::Substitute]<=0
          score*=0.8
          if (!attacker.abilitynulled &&
             attacker.ability == PBAbilities::BADDREAMS) ||
             attacker.pbHasMove?(:DREAMEATER) ||
             attacker.pbHasMove?(:NIGHTMARE)
            score*=0.3
          end
          if opponent.pbHasMove?(:SNORE) ||
            opponent.pbHasMove?(:SLEEPTALK)
            score*=1.3
          end
        end
      when 0x7E # Facade
      when 0x7F # Hex
      when 0x80 # Brine
      when 0x81 # Revenge
        if (pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed) ^ (@trickroom!=0)
          score*=0.5
        else
          score*=1.5
        end
        if attacker.hp==attacker.totalhp
          score*=1.2
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) ||
             (attitemworks && attacker.item == PBItems::FOCUSSASH)
            score*=1.1
          end
        else
          score*=0.3 if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
        end
        score*=0.8 if checkAImoves(PBStuff::SETUPMOVE,aimem)
        #miniscore=attacker.hp*(1.0/attacker.totalhp)
        #score*=miniscore
      when 0x82 # Assurance
        if (pbRoughStat(opponent,PBStats::SPEED,skill)>attacker.pbSpeed) ^ (@trickroom!=0)
          score*=1.5
        end
      when 0x83 # Round
        if @doublebattle && attacker.pbPartner.pbHasMove?(:ROUND)
          score*=1.5
        end
      when 0x84 # Payback
        if (pbRoughStat(opponent,PBStats::SPEED,skill)>attacker.pbSpeed) ^ (@trickroom!=0)
          score*=2
        end
      when 0x85 # Retaliate
      when 0x86 # Acrobatics
      when 0x87 # Weather Ball
      when 0x88 # Pursuit
        miniscore=(-10)*statchangecounter(opponent,1,7,-1)
        miniscore+=100
        miniscore/=100.0
        score*=miniscore
        if opponent.effects[PBEffects::Confusion]>0
          score*=1.2
        end
        if opponent.effects[PBEffects::LeechSeed]>=0
          score*=1.5
        end
        if opponent.effects[PBEffects::Attract]>=0
          score*=1.3
        end
        if opponent.effects[PBEffects::Substitute]>0
          score*=0.7
        end
        if opponent.effects[PBEffects::Yawn]>0
          score*=1.5
        end
        if pbTypeModNoMessages(bettertype,attacker,opponent,move,skill)>4
          score*=1.5
        end
      when 0x89 # Return
      when 0x8A # Frustration
      when 0x8B # Water Spout
        if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=0.5
        end
        if skill>=PBTrainerAI.bestSkill
          if move.id==(PBMoves::WATERSPOUT)
            if $fefieldeffect==7 # Burning
              firevar=false
              watervar=false
              for mon in pbParty(attacker.index)
                next if mon.nil?
                if mon.hasType?(:FIRE)
                  firevar=true
                end
                if mon.hasType?(:WATER)
                  watervar=true
                end
                if !firevar
                  score*=1.5
                end
                if watervar
                  score*=1.5
                end
              end
            end
            if $fefieldeffect==16 # Superheated
              score*=0.7
            end
          end
          if move.id==(PBMoves::ERUPTION)
            if $fefieldeffect==2 # Grassy
              if pbWeather!=PBWeather::RAINDANCE && @field.effects[PBEffects::WaterSport]==0
                firevar=false
                grassvar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:FIRE)
                    firevar=true
                  end
                  if mon.hasType?(:GRASS)
                    grassvar=true
                  end
                  if firevar
                    score*=1.5
                  end
                  if !grassvar
                    score*=1.5
                  end
                end
              end
            end
            if $fefieldeffect==11 # Corromist
              poisonvar=false
              for mon in pbParty(attacker.index)
                next if mon.nil?
                if mon.hasType?(:POISON)
                  poisonvar=true
                end
              end
              if !poisonvar
                score*=1.5
              end
              if (attacker.hp.to_f)/attacker.totalhp<0.5
                score*=2
              end
            end
            if $fefieldeffect==13 # Icy
              watervar=false
              icevar=false
              for mon in pbParty(attacker.index)
                next if mon.nil?
                if mon.hasType?(:WATER)
                  watervar=true
                end
                if mon.hasType?(:ICE)
                  grassvar=true
                end
                if watervar
                  score*=1.3
                end
                if !icevar
                  score*=1.2
                end
              end
            end
            if $fefieldeffect==15 # Forest
              if pbWeather!=PBWeather::RAINDANCE && @field.effects[PBEffects::WaterSport]==0
                firevar=false
                grassvar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:FIRE)
                    firevar=true
                  end
                  if mon.hasType?(:GRASS)
                    grassvar=true
                  end
                  if firevar
                    score*=1.5
                  end
                  if !grassvar
                    score*=1.5
                  end
                end
              end
            end
            if $fefieldeffect==16 # Superheated
              if pbWeather!=PBWeather::RAINDANCE && @field.effects[PBEffects::WaterSport]==0
                firevar=false
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:FIRE)
                    firevar=true
                  end
                  if firevar
                    score*=2
                  end
                end
              end
            end
            if $fefieldeffect==28 # Snowy Mountain
              icevar=false
              for mon in pbParty(attacker.index)
                next if mon.nil?
                if mon.hasType?(:ICE)
                  grassvar=true
                end
                if !icevar
                  score*=1.5
                end
              end
            end
            if $fefieldeffect==33 && $fecounter>=2 # Flower Garden
              if pbWeather!=PBWeather::RAINDANCE && @field.effects[PBEffects::WaterSport]==0
                firevar=false
                grassvar=false
                bugvar=falsw
                for mon in pbParty(attacker.index)
                  next if mon.nil?
                  if mon.hasType?(:FIRE)
                    firevar=true
                  end
                  if mon.hasType?(:GRASS)
                    grassvar=true
                  end
                  if mon.hasType?(:BUG)
                    bugvar=true
                  end
                  if firevar
                    score*=1.5
                  end
                  if !grassvar && !bugvar
                    score*=1.5
                  end
                end
              end
            end
          end
        end
      when 0x8C # Crush Grip
      when 0x8D # Gyro Ball
      when 0x8E # Stored Power
      when 0x8F # Punishment
      when 0x90 # Hidden Power
      when 0x91 # Fury Cutter
        if attacker.status==PBStatuses::PARALYSIS
          score*=0.7
        end
        if attacker.effects[PBEffects::Confusion]>0
          score*=0.7
        end
        if attacker.effects[PBEffects::Attract]>=0
          score*=0.7
        end
        if attacker.stages[PBStats::ACCURACY]<0
          ministat = attacker.stages[PBStats::ACCURACY]
          minimini = 15 * ministat
          minimini += 100
          minimini /= 100.0
          score*=minimini
        end
        miniscore = opponent.stages[PBStats::EVASION]
        miniscore*=(-5)
        miniscore+=100
        miniscore/=100.0
        score*=miniscore
        if attacker.hp==attacker.totalhp
          score*=1.3
        end
        score*=1.5 if checkAIdamage(aimem,attacker,opponent,skill)<(attacker.hp/3.0) && (aimem.length > 0)
        score*=0.8 if checkAImoves(PBStuff::PROTECTMOVE,aimem)
      when 0x92 # Echoed Voice
        if attacker.status==PBStatuses::PARALYSIS
          score*=0.7
        end
        if attacker.effects[PBEffects::Confusion]>0
          score*=0.7
        end
        if attacker.effects[PBEffects::Attract]>=0
          score*=0.7
        end
        if attacker.hp==attacker.totalhp
          score*=1.3
        end
        score*=1.5 if checkAIdamage(aimem,attacker,opponent,skill)<(attacker.hp/3.0) && (aimem.length > 0)
      when 0x93 # Rage
        if attacker.attack>attacker.spatk
          score*=1.2
        end
        if attacker.hp==attacker.totalhp
          score*=1.3
        end
        score*=1.3 if checkAIdamage(aimem,attacker,opponent,skill)<(attacker.hp/4.0) && (aimem.length > 0)
      when 0x94 # Present
        if opponent.hp==opponent.totalhp
          score*=1.2
        end
      when 0x95 # Magnitude
        darkvar=false
        rockvar=false
        dragvar=false
        icevar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:DARK)
            darkvar=true
          end
          if mon.hasType?(:ROCK)
            rockvar=true
          end
          if mon.hasType?(:DRAGON)
            dragvar=true
          end
          if mon.hasType?(:ICE)
            icevar=true
          end
        end
        if $fefieldeffect==4
          if !darkvar
            score*=1.3
            if rockvar
              score*=1.2
            end
          end
        end
        if $fefieldeffect==25
          if !dragonvar
            score*=1.3
            if rockvar
              score*=1.2
            end
          end
        end
        if $fefieldeffect==13
          if !icevar
            score*=1.5
          end
        end
        if $fefieldeffect==17
          score*=1.2
          if darkvar
            score*=1.3
          end
        end
        if $fefieldeffect==23
          if !(!attacker.abilitynulled && attacker.ability == PBAbilities::ROCKHEAD) &&
             !(!attacker.abilitynulled && attacker.ability == PBAbilities::BULLETPROOF)
            score*=0.7
            if $fecounter >=1
              score *= 0.3
            end
          end
        end
        if $fefieldeffect==30
          if (opponent.stages[PBStats::EVASION] > 0 ||
             (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER) ||
             (oppitemworks && opponent.item == PBItems::LAXINCENSE) ||
             ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
             ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL))
            score*=1.3
          else
            score*=0.5
          end
        end
      when 0x96 # Natural Gift
        if !pbIsBerry?(attacker.item) || (!attacker.abilitynulled && attacker.ability == PBAbilities::KLUTZ) ||
           @field.effects[PBEffects::MagicRoom]>0 || attacker.effects[PBEffects::Embargo]>0 ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::UNNERVE)
          score*=0
        end
      when 0x97 # Trump Card
        if attacker.hp==attacker.totalhp
          score*=1.2
        end
        score*=1.3 if checkAIdamage(aimem,attacker,opponent,skill)<(attacker.hp/3.0) && (aimem.length > 0)
      when 0x98 # Reversal
        if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=1.1
          if attacker.hp<attacker.totalhp
            score*=1.3
          end
        end
      when 0x99 # Electro Ball
      when 0x9A # Low Kick
      when 0x9B # Heat Crash
      when 0x9C # Helping Hand
        if @doublebattle
          effvar = false
          for i in attacker.moves
            if pbTypeModNoMessages(i.type,attacker,opponent,i,skill)>=4
              effvar = true
            end
          end
          if !effvar
            score*=2
          end
          if ((attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) &&
             ((attacker.pbSpeed<pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0))
            score*=1.2
            if attacker.hp*(1.0/attacker.totalhp) < 0.33
              score*=1.5
            end
            if attacker.pbPartner.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill) &&
               attacker.pbPartner.pbSpeed<pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)
              score*=1.5
            end
          end
          ministat = [attacker.pbPartner.attack,attacker.pbPartner.spatk].max
          minimini = [attacker.attack,attacker.spatk].max
          ministat-=minimini
          ministat+=100
          ministat/=100.0
          score*=ministat
          if attacker.pbPartner.hp==0
            score*=0
          end
        else
          score*=0
        end
      when 0x9D # Mud Sport
        if @field.effects[PBEffects::MudSport]==0
          eff1 = PBTypes.getCombinedEffectiveness(PBTypes::ELECTRIC,attacker.type1,attacker.type2)
          eff2 = PBTypes.getCombinedEffectiveness(PBTypes::ELECTRIC,attacker.pbPartner.type1,attacker.pbPartner.type2)
          if eff1>4 || eff2>4 && opponent.hasType?(:ELECTRIC)
            score*=1.5
          end
          elevar=false
          for mon in pbParty(attacker.index)
            next if mon.nil?
            if mon.hasType?(:ELECTRIC)
              elevar=true
            end
          end
          if elevar
            score*=0.7
          end
          if $fefieldeffect==1
            if !elevar
              score*=2
            else
              score*=0.3
            end
          end
        else
          score*=0
        end
      when 0x9E # Water Sport
        if @field.effects[PBEffects::WaterSport]==0
          eff1 = PBTypes.getCombinedEffectiveness(PBTypes::FIRE,attacker.type1,attacker.type2)
          eff2 = PBTypes.getCombinedEffectiveness(PBTypes::FIRE,attacker.pbPartner.type1,attacker.pbPartner.type2)
          if eff1>4 || eff2>4 && opponent.hasType?(:FIRE)
            score*=1.5
          end
          firevar=false
          grassvar=false
          bugvar=false
          for mon in pbParty(attacker.index)
            next if mon.nil?
            if mon.hasType?(:FIRE)
              firevar=true
            end
            if mon.hasType?(:GRASS)
              grassvar=true
            end
            if mon.hasType?(:BUG)
              bugvar=true
            end
          end
          if firevar
            score*=0.7
          end
          if $fefieldeffect==7
            if !firevar
              score*=2
            else
              score*=0
            end
          elsif $fefieldeffect==16
            score*=0.7
            if !firevar
              score*=1.8
            else
              score*=0
            end
          elsif $fefieldeffect==2 || $fefieldeffect==15 || $fefieldeffect==33
            if !attacker.hasType?(:FIRE) && opponent.hasType?(:FIRE)
              score*=3
            end
            if grassvar || bugvar
              score*=2
              if $fefieldeffect==33 && $fecounter<4
                score*=3
              end
            end
            if firevar
              score*=0.5
            end
          end
        else
          score*=0
        end
      when 0x9F # Judgement
      when 0xA0 # Frost Breath
        thisinitial = score
        if !(!opponent.abilitynulled && opponent.ability == PBAbilities::BATTLEARMOR) &&
           !(!opponent.abilitynulled && opponent.ability == PBAbilities::SHELLARMOR) &&
           attacker.effects[PBEffects::LaserFocus]==0
          miniscore = 100
          ministat = 0
          ministat += opponent.stages[PBStats::DEFENSE] if opponent.stages[PBStats::DEFENSE]>0
          ministat += opponent.stages[PBStats::SPDEF] if opponent.stages[PBStats::SPDEF]>0
          miniscore += 10*ministat
          ministat = 0
          ministat -= attacker.stages[PBStats::ATTACK] if attacker.stages[PBStats::ATTACK]<0
          ministat -= attacker.stages[PBStats::SPATK] if attacker.stages[PBStats::SPATK]<0
          miniscore += 10*ministat
          if attacker.effects[PBEffects::FocusEnergy]>0
            miniscore -= 10*attacker.effects[PBEffects::FocusEnergy]
          end
          miniscore/=100.0
          score*=miniscore
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::ANGERPOINT) && opponent.stages[PBStats::ATTACK]!=6
            if opponent == attacker.pbPartner
              if opponent.attack>opponent.spatk
                if thisinitial>99
                  score=0
                else
                  score = (100-thisinitial)
                  enemy1 = attacker.pbOppositeOpposing
                  enemy2 = enemy1.pbPartner
                  if opponent.pbSpeed > enemy1.pbSpeed && opponent.pbSpeed > enemy2.pbSpeed
                    score*=1.3
                  else
                    score*=0.7
                  end
                end
              end
            else
              if thisinitial<100
                score*=0.7
                if opponent.attack>opponent.spatk
                  score*=0.2
                end
              end
            end
          else
            if opponent == attacker.pbPartner
              score = 0
            end
          end
        else
          score*=0.7
        end
      when 0xA1 # Lucky Chant
        if attacker.pbOwnSide.effects[PBEffects::LuckyChant]==0 &&
           !(!attacker.abilitynulled && attacker.ability == PBAbilities::BATTLEARMOR) ||
           !(!attacker.abilitynulled && attacker.ability == PBAbilities::SHELLARMOR) &&
           (opponent.effects[PBEffects::FocusEnergy]>1 || opponent.effects[PBEffects::LaserFocus]>0)
          score+=20
        end
      when 0xA2 # Reflect
        if attacker.pbOwnSide.effects[PBEffects::Reflect]<=0
          score*=1.2
          if attacker.pbOwnSide.effects[PBEffects::AuroraVeil]>0
            score*=0.5
          end
          if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
            score*=1.3
          end
          if (attitemworks && attacker.item == PBItems::LIGHTCLAY)
            score*=1.5
          end
          if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=1.1
            if skill>=PBTrainerAI.bestSkill
              if aimem.length > 0
                maxdam=0
                for j in aimem
                  if !j.pbIsPhysical?(j.type)
                    next
                  end
                  tempdam = pbRoughDamage(j,opponent,attacker,skill,j.basedamage)
                  maxdam=tempdam if maxdam<tempdam
                end
                if maxdam>attacker.hp && (maxdam/2.0)<attacker.hp
                  score*=2
                end
              end
            end
          end
          livecount=0
          for i in pbParty(opponent.index)
            next if i.nil?
            livecount+=1 if i.hp!=0
          end
          if livecount<=2
            score*=0.7
            if livecount==1
              score*=0.7
            end
          end
          if (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
             (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
             (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
            score*=1.3
          end
          score*=0.1 if checkAImoves(PBStuff::PBStuff::SCREENBREAKERMOVE,aimem)
        else
          score=0
        end
      when 0xA3 # Light Screen
        if attacker.pbOwnSide.effects[PBEffects::LightScreen]<=0
          score*=1.2
          if attacker.pbOwnSide.effects[PBEffects::AuroraVeil]>0
            score*=0.5
          end
          if pbRoughStat(opponent,PBStats::ATTACK,skill)<pbRoughStat(opponent,PBStats::SPATK,skill)
            score*=1.3
          end
          if (attitemworks && attacker.item == PBItems::LIGHTCLAY)
            score*=1.5
          end
          if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=1.1
            if aimem.length > 0
              maxdam=0
              for j in aimem
                if !j.pbIsSpecial?(j.type)
                  next
                end
                tempdam = pbRoughDamage(j,opponent,attacker,skill,j.basedamage)
                maxdam=tempdam if maxdam<tempdam
              end
              if maxdam>attacker.hp && (maxdam/2.0)<attacker.hp
                score*=2
              end
            end
          end
          livecount=0
          for i in pbParty(opponent.index)
            next if i.nil?
            livecount+=1 if i.hp!=0
          end
          if livecount<=2
            score*=0.7
            if livecount==1
              score*=0.7
            end
          end
          if (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
             (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
             (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
            score*=1.3
          end
          score*=0.1 if checkAImoves(PBStuff::PBStuff::SCREENBREAKERMOVE,aimem)
        else
          score=0
        end
      when 0xA4 # Secret Power
        score*=1.2
      when 0xA5 # Never Miss
        if score==110
          score*=1.05
        end
        if !(!attacker.abilitynulled && attacker.ability == PBAbilities::NOGUARD) &&
           !(!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD)
          if attacker.stages[PBStats::ACCURACY]<0
            miniscore = (-5)*attacker.stages[PBStats::ACCURACY]
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
          if opponent.stages[PBStats::EVASION]>0
            miniscore = (5)*opponent.stages[PBStats::EVASION]
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
          if (oppitemworks && opponent.item == PBItems::LAXINCENSE) ||
             (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER)
            score*=1.2
          end
          if ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
            ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL)
            score*=1.3
          end
          if opponent.vanished && ((attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0))
            score*=3
          end
        end
      when 0xA6 # Lock On
        if opponent.effects[PBEffects::LockOn]>0 ||  opponent.effects[PBEffects::Substitute]>0
          score*=0
        else
          if attacker.pbHasMove?(:INFERNO) ||
             attacker.pbHasMove?(:ZAPCANNON) ||
             attacker.pbHasMove?(:DYNAMICPUNCH)
            if !(!attacker.abilitynulled && attacker.ability == PBAbilities::NOGUARD) &&
               !(!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD)
              score*=3
            end
          end
          if attacker.pbHasMove?(:GUILLOTINE) ||
             attacker.pbHasMove?(:SHEERCOLD) ||
             attacker.pbHasMove?(:GUILLOTINE) ||
             attacker.pbHasMove?(:FISSURE) ||
             attacker.pbHasMove?(:HORNDRILL)
            score*=10
          end
          ministat=0
          ministat = attacker.stages[PBStats::ACCURACY] if attacker.stages[PBStats::ACCURACY]<0
          ministat*=10
          ministat+=100
          ministat/=100.0
          score*=ministat
          ministat = opponent.stages[PBStats::EVASION]
          ministat*=10
          ministat+=100
          ministat/=100.0
          score*=ministat
        end
        if $fefieldeffect==37
          if (move.id == PBMoves::MINDREADER)
            if attacker.stages[PBStats::SPATK]<6
              score+=10
            end
            if attacker.spatk>attacker.attack
              score*=2
            end
            if attacker.hp==attacker.totalhp
              score*=1.5
            else
              score*=0.8
            end
            if roles.include?(PBMonRoles::SWEEPER)
              score*=1.3
            end
            if attacker.hp<attacker.totalhp*0.5
              score*=0.5
            end
          end
        end
      when 0xA7 # Foresight
        if opponent.effects[PBEffects::Foresight]
          score*=0
        else
          ministat = 0
          ministat = opponent.stages[PBStats::EVASION] if opponent.stages[PBStats::EVASION]>0
          ministat*=10
          ministat+=100
          ministat/=100.0
          score*=ministat
          if opponent.pbHasType?(:GHOST)
            score*=1.5
            effectvar = false
            for i in attacker.moves
              next if i.basedamage==0
              if !(i.type == PBTypes::NORMAL) && !(i.type == PBTypes::FIGHTING)
                effectvar = true
                break
              end
            end
            if !effectvar && !(!attacker.abilitynulled && attacker.ability == PBAbilities::SCRAPPY)
              score*=5
            end
          end
        end
      when 0xA8 # Miracle Eye
        if opponent.effects[PBEffects::MiracleEye]
          score*=0
        else
          ministat = 0
          ministat = opponent.stages[PBStats::EVASION] if opponent.stages[PBStats::EVASION]>0
          ministat*=10
          ministat+=100
          ministat/=100.0
          score*=ministat
          if opponent.pbHasType?(:DARK)
            score*=1.1
            effectvar = false
            for i in attacker.moves
              next if i.basedamage==0
              if !(i.type == PBTypes::PSYCHIC)
                effectvar = true
                break
              end
            end
            if !effectvar
              score*=2
            end
          end
        end
        if $fefieldeffect==37 || $fefieldeffect==29 || $fefieldeffect==31
          if attacker.stages[PBStats::SPATK]<6
            score+=10
          end
          if attacker.spatk>attacker.attack
            score*=2
          end
          if attacker.hp==attacker.totalhp
            score*=1.5
          else
            score*=0.8
          end
          if roles.include?(PBMonRoles::SWEEPER)
            score*=1.3
          end
          if attacker.hp<attacker.totalhp*0.5
            score*=0.5
          end
        end
      when 0xA9 # Chip Away
        ministat = 0
        ministat+=opponent.stages[PBStats::EVASION] if opponent.stages[PBStats::EVASION]>0
        ministat+=opponent.stages[PBStats::DEFENSE] if opponent.stages[PBStats::DEFENSE]>0
        ministat+=opponent.stages[PBStats::SPDEF] if opponent.stages[PBStats::SPDEF]>0
        ministat*=5
        ministat+=100
        ministat/=100.0
        score*=ministat
      when 0xAA # Protect
        score*=0.3 if opponent.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::SPEEDBOOST) &&
           attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          score*=4
          #experimental -- cancels out drop if killing moves
          if initialscores.length>0
            score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
          end
          #end experimental
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON)) ||
           attacker.effects[PBEffects::Ingrain] || attacker.effects[PBEffects::AquaRing] ||
           $fefieldeffect==2
          score*=1.2
        end
        if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN
          score*=1.2
          if opponent.effects[PBEffects::Toxic]>0
            score*=1.3
          end
        end
        if attacker.status==PBStatuses::POISON || attacker.status==PBStatuses::BURN
          score*=0.7
          if attacker.effects[PBEffects::Toxic]>0
            score*=0.3
          end
        end
        if opponent.effects[PBEffects::LeechSeed]>=0
          score*=1.3
        end
        if opponent.effects[PBEffects::PerishSong]!=0
          score*=2
        end
        if opponent.status==PBStatuses::SLEEP || opponent.status==PBStatuses::FROZEN
          score*=0.3
        end
        if opponent.vanished
          score*=2
          if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=1.5
          end
        end
        score*=0.1 if checkAImoves(PBStuff::PROTECTIGNORINGMOVE,aimem)
        if attacker.effects[PBEffects::Wish]>0
          if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
            score*=10
          else
            score*=3
          end
        end
        ratesharers=[
        391,   # Protect
        121,   # Detect
        122,   # Quick Guard
        515,   # Wide Guard
        361,   # Endure
        584,   # King's Shield
        603,    # Spiky Shield
        641    # Baneful Bunker
          ]
        if ratesharers.include?(attacker.lastMoveUsed)
          score/=(attacker.effects[PBEffects::ProtectRate]*2.0)
        end
      when 0xAB # Quick Guard
        ratesharers=[
        391,   # Protect
        121,   # Detect
        122,   # Quick Guard
        515,   # Wide Guard
        361,   # Endure
        584,   # King's Shield
        603,    # Spiky Shield
        641    # Baneful Bunker
          ]
        if ratesharers.include?(attacker.lastMoveUsed)
          score/=(attacker.effects[PBEffects::ProtectRate]*2.0)
        end

        if ((!opponent.abilitynulled && opponent.ability == PBAbilities::GALEWINGS) &&
           opponent.hp == opponent.totalhp) || ((!opponent.abilitynulled &&
           opponent.ability == PBAbilities::PRANKSTER) &&
           attacker.pbHasType?(:POISON)) || checkAIpriority(aimem)
          score*=2
          if @doublebattle
            score*=1.3
            score*=0.3 if checkAIhealing(aimem) || checkAImoves(PBStuff::SETUPMOVE,aimem)
            score*=0.1 if checkAImoves(PBStuff::PROTECTIGNORINGMOVE,aimem)
            if attacker.effects[PBEffects::Wish]>0
              score*=2 if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp ||
                          (attacker.pbPartner.hp*(1.0/attacker.pbPartner.totalhp))<0.25
            end
          end
        else
          score*=0
        end
      when 0xAC # Wide Guard
        ratesharers=[
        391,   # Protect
        121,   # Detect
        122,   # Quick Guard
        515,   # Wide Guard
        361,   # Endure
        584,   # King's Shield
        603,    # Spiky Shield
        641    # Baneful Bunker
          ]
        if ratesharers.include?(attacker.lastMoveUsed)
          score/=(attacker.effects[PBEffects::ProtectRate]*2.0)
        end
        widevar = false
        if aimem.length > 0
          for j in aimem
            widevar = true if (j.target == PBTargets::AllOpposing || j.target == PBTargets::AllNonUsers)
          end
        end
        if @doublebattle
          if widevar
            score*=2
            score*=0.3 if checkAIhealing(aimem) || checkAImoves(PBStuff::SETUPMOVE,aimem)
            score*=0.1 if checkAImoves(PBStuff::PROTECTIGNORINGMOVE,aimem)
            if attacker.effects[PBEffects::Wish]>0
              maxdam = checkAIdamage(aimem,attacker,opponent,skill)
              if maxdam>attacker.hp || (attacker.pbPartner.hp*(1.0/attacker.pbPartner.totalhp))<0.25
                score*=2
              end
            end
            if $fefieldeffect==11
              score*=2 if checkAImoves([PBMoves::HEATWAVE,PBMoves::LAVAPLUME,PBMoves::ERUPTION,PBMoves::MINDBLOWN],aimem)
            end
            if $fefieldeffect==23
              score*=2 if checkAImoves([PBMoves::MAGNITUDE,PBMoves::EARTHQUAKE,PBMoves::BULLDOZE],aimem)
            end
            if $fefieldeffect==30
              score*=2 if (checkAImoves([PBMoves::MAGNITUDE,PBMoves::EARTHQUAKE,PBMoves::BULLDOZE],aimem) ||
                          checkAImoves([PBMoves::HYPERVOICE,PBMoves::BOOMBURST],aimem))
            end
          end
        else
          score*=0
        end
      when 0xAD # Feint
        if checkAImoves(PBStuff::PROTECTIGNORINGMOVE,aimem)
          score*=1.1
          ratesharers=[
          391,   # Protect
          121,   # Detect
          122,   # Quick Guard
          515,   # Wide Guard
          361,   # Endure
          584,   # King's Shield
          603,    # Spiky Shield
          641    # Baneful Bunker
            ]
          if !ratesharers.include?(opponent.lastMoveUsed)
            score*=1.2
          end
        end
      when 0xAE # Mirror Move
        if opponent.lastMoveUsed>0
          mirrored = PBMove.new(opponent.lastMoveUsed)
          mirrmove = PokeBattle_Move.pbFromPBMove(self,mirrored,attacker)
          if mirrmove.flags&0x10==0
            score*=0
          else
            rough = pbRoughDamage(mirrmove,attacker,opponent,skill,mirrmove.basedamage)
            mirrorscore = pbGetMoveScore(mirrmove,attacker,opponent,skill,rough,initialscores,scoreindex)
            score = mirrorscore
            if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=0.5
            end
          end
        else
          score*=0
        end
      when 0xAF # Copycat
        if opponent.lastMoveUsed>0  && opponent.effects[PBEffects::Substitute]<=0
          copied = PBMove.new(opponent.lastMoveUsed)
          copymove = PokeBattle_Move.pbFromPBMove(self,copied,attacker)
          if copymove.flags&0x10==0
            score*=0
          else
            rough = pbRoughDamage(copymove,attacker,opponent,skill,copymove.basedamage)
            copyscore = pbGetMoveScore(copymove,attacker,opponent,skill,rough,initialscores,scoreindex)
            score = copyscore
            if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=0.5
            end
            if $fefieldeffect==30
              score*=1.5
            end
          end
        else
          score*=0
        end
      when 0xB0 # Me First
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          if checkAImoves(PBStuff::SETUPMOVE,aimem)
            score*=0.8
          else
            score*=1.5
          end
          if checkAIpriority(aimem) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::PRANKSTER) ||
             ((!opponent.abilitynulled && opponent.ability == PBAbilities::GALEWINGS) && opponent.hp==opponent.totalhp)
            score*=0.6
          else
            score*=1.5
          end
          if opponent.hp>0 && initialscores.length>0
            if checkAIdamage(aimem,attacker,opponent,skill)/(1.0*opponent.hp)>initialscores.max
              score*=2
            else
              score*=0.5
            end
          end
        else
          score*=0
        end
      when 0xB1 # Magic Coat
        if attacker.lastMoveUsed>0
          olddata = PBMove.new(attacker.lastMoveUsed)
          oldmove = PokeBattle_Move.pbFromPBMove(self,olddata,attacker)
          if oldmove.function==0xB1
            score*=0.5
          else
            if attacker.hp==attacker.totalhp
              score*=1.5
            end
            statvar = true
            for i in opponent.moves
              if i.basedamage>0
                statvar=false
              end
            end
            if statvar
              score*=3
            end
          end
        else
          if attacker.hp==attacker.totalhp
            score*=1.5
          end
          statvar = true
          for i in opponent.moves
            if i.basedamage>0
              statvar=false
            end
          end
          if statvar
            score*=3
          end
        end
      when 0xB2 # Snatch
        if attacker.lastMoveUsed>0
          olddata = PBMove.new(attacker.lastMoveUsed)
          oldmove = PokeBattle_Move.pbFromPBMove(self,olddata,attacker)
          if oldmove.function==0xB2
            score*=0.5
          else
            if opponent.hp==opponent.totalhp
              score*=1.5
            end
            score*=2 if checkAImoves(PBStuff::SETUPMOVE,aimem)
            if opponent.attack>opponent.spatk
              if attacker.attack>attacker.spatk
                score*=1.5
              else
                score*=0.7
              end
            else
              if attacker.spatk>attacker.attack
                score*=1.5
              else
                score*=0.7
              end
            end
          end
        else
          if opponent.hp==opponent.totalhp
            score*=1.5
          end
          score*=2 if checkAImoves(PBStuff::SETUPMOVE,aimem)
          if opponent.attack>opponent.spatk
            if attacker.attack>attacker.spatk
              score*=1.5
            else
              score*=0.7
            end
          else
            if attacker.spatk>attacker.attack
              score*=1.5
            else
              score*=0.7
            end
          end
        end
      when 0xB3 # Nature Power
        case $fefieldeffect
          when 33
            if $fecounter == 4
              newmove=PBMoves::PETALBLIZZARD
            else
              newmove=PBMoves::GROWTH
            end
          else
            if $fefieldeffect > 0 && $fefieldeffect <= 37
              naturemoves = FieldEffects::NATUREMOVES
              newmove= naturemoves[$fefieldeffect]
            else
              newmove=PBMoves::TRIATTACK
            end
          end
        newdata = PBMove.new(newmove)
        naturemove = PokeBattle_Move.pbFromPBMove(self,newdata,attacker)
        if naturemove.basedamage<=0
          naturedam=pbStatusDamage(naturemove)
        else
          tempdam=pbRoughDamage(naturemove,attacker,opponent,skill,naturemove.basedamage)
          naturedam=(tempdam*100)/(opponent.hp.to_f)
        end
        naturedam=110 if naturedam>110
        score = pbGetMoveScore(naturemove,attacker,opponent,skill,naturedam)
      when 0xB4 # Sleep Talk
        if attacker.status==PBStatuses::SLEEP
          if attacker.statusCount<=1
            score*=0
          else
            if attacker.pbHasMove?(:SNORE)
              count=-1
              for k in attacker.moves
                count+=1
                if k.id == 312 # Snore index
                  break
                end
              end
              if initialscores
                snorescore = initialscores[count]
                otherscores = 0
                for s in initialscores
                  next if s.index==scoreindex
                  next if s.index==count
                  otherscores+=s
                end
                otherscores/=2.0
                if otherscores>snorescore
                  score*=0.1
                else
                  score*=5
                end
              end
            end
          end
        else
          score*=0
        end
      when 0xB5 # Assist
        if attacker.pbNonActivePokemonCount > 0
          if initialscores.length>0
            scorecheck = false
            for s in initialscores
              next if initialscores.index(s) == scoreindex
              scorecheck=true if s>25
            end
            if scorecheck
              score*=0.5
            else
              score*=1.5
            end
          end
        else
          score*=0
        end
      when 0xB6 # Metronome
        if $fefieldeffect==24
          if initialscores.length>0
            scorecheck = false
            for s in initialscores
              next if initialscores.index(s) == scoreindex
              scorecheck=true if s>40
            end
            if scorecheck
              score*=0.8
            else
              score*=2
            end
          end
        else
          if initialscores.length>0
            scorecheck = false
            for s in initialscores
              next if initialscores.index(s) == scoreindex
              scorecheck=true if s>21
            end
            if scorecheck
              score*=0.5
            else
              score*=1.2
            end
          end
        end
      when 0xB7 # Torment
        olddata = PBMove.new(attacker.lastMoveUsed)
        oldmove = PokeBattle_Move.pbFromPBMove(self,olddata,attacker)
        maxdam = 0
        moveid = -1
        if aimem.length > 0
          for j in aimem
            tempdam = pbRoughDamage(j,opponent,attacker,skill,j.basedamage)
            if tempdam>maxdam
              maxdam=tempdam
              moveid = j.id
            end
          end
        end
        if opponent.effects[PBEffects::Torment] || (pbCheckSideAbility(:AROMAVEIL,opponent)!=nil && !(opponent.moldbroken))
          score=0
        else
          if ((attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) ||
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::PRANKSTER) && !opponent.pbHasType?(:DARK))
            score*=1.2
          else
            score*=0.7
          end
          if oldmove.basedamage>0
            score*=1.5
            if moveid == oldmove.id
              score*=1.3
              if maxdam*3<attacker.totalhp
                score*=1.5
              end
            end
            if attacker.pbHasMove?(:PROTECT)
              score*=1.5
            end
            if (attitemworks && attacker.item == PBItems::LEFTOVERS)
              score*=1.3
            end
          else
            score*=0.5
          end
        end
      when 0xB8 # Imprison
        if attacker.effects[PBEffects::Imprison]
          score*=0
        else
          miniscore=1
          ourmoves = []
          olddata = PBMove.new(attacker.lastMoveUsed)
          oldmove = PokeBattle_Move.pbFromPBMove(self,olddata,attacker)
          for m in attacker.moves
            ourmoves.push(m.id) unless m.id<1
          end
          if ourmoves.include?(oldmove.id)
            score*=1.3
          end
          if aimem.length > 0
            for j in aimem
              if ourmoves.include?(j.id)
                miniscore+=1
                if j.isHealingMove?
                  score*=1.5
                end
              else
                score*=0.5
              end
            end
          end
          score*=miniscore
        end
      when 0xB9 # Disable
        olddata = PBMove.new(opponent.lastMoveUsed)
        oldmove = PokeBattle_Move.pbFromPBMove(self,olddata,attacker)
        maxdam = 0
        moveid = -1
        if aimem.length > 0
          for j in aimem
            tempdam = pbRoughDamage(j,opponent,attacker,skill,j.basedamage)
            if tempdam>maxdam
              maxdam=tempdam
              moveid = j.id
            end
          end
        end
        if oldmove.id == -1 && (((attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::PRANKSTER) && !opponent.pbHasType?(:DARK)))
          score=0
        end
        if opponent.effects[PBEffects::Disable]>0 || (pbCheckSideAbility(:AROMAVEIL,opponent)!=nil && !(opponent.moldbroken))
          score=0
        else
          if ((attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) ||
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::PRANKSTER) && !opponent.pbHasType?(:DARK))
            score*=1.2
          else
            score*=0.3
          end
          if oldmove.basedamage>0 || oldmove.isHealingMove?
            score*=1.5
            if moveid == oldmove.id
              score*=1.3
              if maxdam*3<attacker.totalhp
                score*=1.5
              end
            end
          else
            score*=0.5
          end
        end
      when 0xBA # Taunt
        olddata = PBMove.new(attacker.lastMoveUsed)
        oldmove = PokeBattle_Move.pbFromPBMove(self,olddata,attacker)
        if opponent.effects[PBEffects::Taunt]>0 || (pbCheckSideAbility(:AROMAVEIL,opponent)!=nil && !(opponent.moldbroken))
          score=0
        else
          if ((attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) ||
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::PRANKSTER) && !opponent.pbHasType?(:DARK))
            score*=1.5
          else
            score*=0.7
          end
          if (pbGetMonRole(opponent,attacker,skill)).include?(PBMonRoles::LEAD)
            score*=1.2
          else
            score*=0.8
          end
          if opponent.turncount<=1
            score*=1.1
          else
            score*=0.9
          end
          if oldmove.isHealingMove?
            score*=1.3
          end
          if @doublebattle
            score *= 0.6
          end
        end
      when 0xBB # Heal Block
        olddata = PBMove.new(attacker.lastMoveUsed)
        oldmove = PokeBattle_Move.pbFromPBMove(self,olddata,attacker)
        if opponent.effects[PBEffects::HealBlock]>0 ||
           (pbCheckSideAbility(:AROMAVEIL,opponent)!=nil && !(opponent.moldbroken)) ||
           opponent.effects[PBEffects::Substitute]>0
          score=0
        else
          if ((attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) ||
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::PRANKSTER) && !opponent.pbHasType?(:DARK))
            score*=1.5
          end
          if oldmove.isHealingMove?
            score*=2.5
          end
          if (oppitemworks && opponent.item == PBItems::LEFTOVERS)
            score*=1.3
          end
        end
      when 0xBC # Encore
        olddata = PBMove.new(opponent.lastMoveUsed)
        oldmove = PokeBattle_Move.pbFromPBMove(self,olddata,attacker)
        if opponent.effects[PBEffects::Encore]>0 ||
           (pbCheckSideAbility(:AROMAVEIL,opponent)!=nil && !(opponent.moldbroken))
          score=0
        else
          if opponent.lastMoveUsed<=0
            score*=0.2
          else
            if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=1.5
            else
              if ((!attacker.abilitynulled && attacker.ability == PBAbilities::PRANKSTER) && !opponent.pbHasType?(:DARK))
                score*=2
              else
                score*=0.2
              end
            end
            if oldmove.basedamage>0 && pbRoughDamage(oldmove,opponent,attacker,skill,oldmove.basedamage)*5>attacker.hp
              score*=0.3
            else
              if opponent.stages[PBStats::SPEED]>0
                if (opponent.pbHasType?(:DARK) ||
                   !(!attacker.abilitynulled && attacker.ability == PBAbilities::PRANKSTER) ||
                   (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST))
                  score*=0.5
                else
                  score*=2
                end
              else
                score*=2
              end
            end
            if $fefieldeffect == 6
              score*=1.5
            end
          end
        end
      when 0xBD # Double Kick
        if (oppitemworks && opponent.item == PBItems::ROCKYHELMET) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::IRONBARBS) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::ROUGHSKIN)
          score*=0.9
        end
        if opponent.hp==opponent.totalhp &&
           ((oppitemworks && opponent.item == PBItems::FOCUSSASH) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::STURDY))
          score*=1.3
        end
        if opponent.effects[PBEffects::Substitute]>0
          score*=1.3
        end
        if (attitemworks && attacker.item == PBItems::RAZORFANG) ||
           (attitemworks && attacker.item == PBItems::KINGSROCK)
          score*=1.1
        end
      when 0xBE # Twinneedle
        if opponent.pbCanPoison?(false)
          miniscore=100
          miniscore*=1.2
          ministat=0
          ministat+=opponent.stages[PBStats::DEFENSE]
          ministat+=opponent.stages[PBStats::SPDEF]
          ministat+=opponent.stages[PBStats::EVASION]
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::NATURALCURE)
            miniscore*=0.3
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::MARVELSCALE)
            miniscore*=0.7
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::TOXICBOOST) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::GUTS)
            miniscore*=0.2
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::POISONHEAL) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::MAGICGUARD)
            miniscore*=0.1
          end
          miniscore*=0.1 if checkAImoves([PBMoves::REST],aimem)
          miniscore*=0.2 if checkAImoves([PBMoves::FACADE],aimem)
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            miniscore*=1.5
          end
          if initialscores.length>0
            miniscore*=1.2 if hasbadmoves(initialscores,scoreindex,30)
          end
          if attacker.pbHasMove?(:VENOSHOCK) ||
            attacker.pbHasMove?(:VENOMDRENCH) ||
            (!attacker.abilitynulled && attacker.ability == PBAbilities::MERCILESS)
            miniscore*=1.6
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=0.4
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SHEDSKIN)
            miniscore*=0.7
          end
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
        end
        if (oppitemworks && opponent.item == PBItems::ROCKYHELMET) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::IRONBARBS) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::ROUGHSKIN)
          score*=0.8
        end
        if opponent.hp==opponent.totalhp && ((oppitemworks && opponent.item == PBItems::FOCUSSASH) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::STURDY))
          score*=1.3
        end
        if opponent.effects[PBEffects::Substitute]>0
          score*=1.3
        end
        if (attitemworks && attacker.item == PBItems::RAZORFANG) ||
           (attitemworks && attacker.item == PBItems::KINGSROCK)
          score*=1.1
        end
      when 0xBF # Triple Kick
        if (oppitemworks && opponent.item == PBItems::ROCKYHELMET) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::IRONBARBS) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::ROUGHSKIN)
          score*=0.8
        end
        if opponent.hp==opponent.totalhp &&
           ((oppitemworks && opponent.item == PBItems::FOCUSSASH) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::STURDY))
          score*=1.3
        end
        if opponent.effects[PBEffects::Substitute]>0
          score*=1.3
        end
        if (attitemworks && attacker.item == PBItems::RAZORFANG) ||
           (attitemworks && attacker.item == PBItems::KINGSROCK)
          score*=1.2
        end
      when 0xC0 # Bullet Seed
        if (oppitemworks && opponent.item == PBItems::ROCKYHELMET) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::IRONBARBS) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::ROUGHSKIN)
          score*=0.7
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::SKILLLINK)
            score*=0.5
          end
        end
        if opponent.hp==opponent.totalhp &&
           ((oppitemworks && opponent.item == PBItems::FOCUSSASH) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::STURDY))
          score*=1.3
        end
        if opponent.effects[PBEffects::Substitute]>0
          score*=1.3
        end
        if (attitemworks && attacker.item == PBItems::RAZORFANG) ||
           (attitemworks && attacker.item == PBItems::KINGSROCK)
          score*=1.3
        end
      when 0xC1 # Beat Up
        count = -1
        for mon in pbParty(attacker.index)
          next if mon.nil?
          count+=1 if mon.hp>0
        end
        if count>0
          if (oppitemworks && opponent.item == PBItems::ROCKYHELMET) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::IRONBARBS) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::ROUGHSKIN)
            score*=0.7
          end
          if opponent.hp==opponent.totalhp &&
             ((oppitemworks && opponent.item == PBItems::FOCUSSASH) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::STURDY))
            score*=1.3
          end
          if opponent.effects[PBEffects::Substitute]>0
            score*=1.3
          end
          if (attitemworks && attacker.item == PBItems::RAZORFANG) ||
             (attitemworks && attacker.item == PBItems::KINGSROCK)
            score*=1.3
          end
          if opponent == attacker.pbPartner &&
             (!opponent.abilitynulled && opponent.ability == PBAbilities::JUSTIFIED)
            if opponent.stages[PBStats::ATTACK]<1 && opponent.attack>opponent.spatk
              score= 100-thisinitial
              enemy1 = attacker.pbOppositeOpposing
              enemy2 = enemy1.pbPartner
              if opponent.pbSpeed > enemy1.pbSpeed && opponent.pbSpeed > enemy2.pbSpeed
                score*=1.3
              else
                score*=0.7
              end
            end
          end
          if opponent == attacker.pbPartner &&
             !(!opponent.abilitynulled && opponent.ability == PBAbilities::JUSTIFIED)
            score=0
          end
        end
      when 0xC2 # Hyper Beam
        if $fefieldeffect == 24
          if score >=110
            score*=1.3
          end
        else
          thisinitial = score
          if thisinitial<100
            score*=0.5
            score*=0.5 if checkAIhealing(aimem)
          end
          if initialscores.length>0
            score*=0.3 if hasgreatmoves(initialscores,scoreindex,skill)
          end
          miniscore=100
          livecount=0
          for i in pbParty(opponent.index)
            next if i.nil?
            livecount+=1 if i.hp!=0
          end
          if livecount>1
            miniscore*=(livecount-1)
            miniscore/=100.0
            miniscore*=0.1
            miniscore=(1-miniscore)
            score*=miniscore
          else
            score*=1.1
          end
          if @doublebattle
            score*=0.5
          end
          livecount2=0
          for i in pbParty(attacker.index)
            next if i.nil?
            livecount2+=1 if i.hp!=0
          end
          if livecount>1 && livecount2==1
            score*=0.7
          end
          if !@doublebattle
            if @opponent.trainertype==PBTrainers::ZEL
              score=thisinitial
              score *= 2
            end
          end
        end
      when 0xC3 # Razor Wind
        if !(attitemworks && attacker.item == PBItems::POWERHERB)
          if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
            score*=0.4
          else
            if attacker.hp*(1.0/attacker.totalhp)<0.5
              score*=0.6
            end
          end
          if opponent.effects[PBEffects::TwoTurnAttack]!=0
            if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=2
            else
              score*=0.5
            end
          end
          greatmove = false
          thisko = false
          if initialscores.length>0
            if initialscores[scoreindex] >= 100
              thisko = true
            end
            for i in initialscores
              if i>=100
                greatmove=true
              end
            end
          end
          if greatmove
            score*=0.1
          end
          if @doublebattle
            score*=0.5
          end
          score*=0.1 if checkAImoves(PBStuff::PROTECTMOVE,aimem)
          if !thisko
            score*=0.7
          end
        else
          score*=1.2
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::UNBURDEN)
            score*=1.5
          end
        end
        fairyvar = false
        firevar = false
        poisonvar = false
        for p in pbParty(attacker.index)
          next if p.nil?
          fairyvar = true if p.hasType?(:FAIRY)
          firevar = true if p.hasType?(:FIRE)
          poisonvar = true if p.hasType?(:POISON)
        end
        if $fefieldeffect==3
          score*=1.3
          if !fairyvar
            score*=1.3
          else
            score*=0.6
          end
        elsif $fefieldeffect==7
          if !firevar
            score*=1.8
          else
            score*=0.5
          end
        elsif $fefieldeffect==11
          if !poisonvar
            score*=3
          else
            score*=0.8
          end
        end
      when 0xC4 # Solar Beam
        if !(attitemworks && attacker.item == PBItems::POWERHERB) && pbWeather!=PBWeather::SUNNYDAY
          if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
            score*=0.4
          else
            if attacker.hp*(1.0/attacker.totalhp)<0.5
              score*=0.6
            end
          end
          if opponent.effects[PBEffects::TwoTurnAttack]!=0
            if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=2
            else
              score*=0.5
            end
          end
          greatmove = false
          thisko = false
          if initialscores.length>0
            if initialscores[scoreindex] >= 100
              thisko = true
            end
            for i in initialscores
              if i>=100
                greatmove=true
              end
            end
          end
          if greatmove
            score*=0.1
          end
          if @doublebattle
            score*=0.5
          end
          score*=0.1 if checkAImoves(PBStuff::PROTECTMOVE,aimem)
          if !thisko
            score*=0.7
          end
        else
          score*=1.2
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::UNBURDEN) &&
             pbWeather!=PBWeather::SUNNYDAY
            score*=1.5
          end
        end
        if $fefieldeffect==4
          score*=0
        end
      when 0xC5 # Freeze Shock
        if !(attitemworks && attacker.item == PBItems::POWERHERB)
          if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
            score*=0.4
          else
            if attacker.hp*(1.0/attacker.totalhp)<0.5
              score*=0.6
            end
          end
          if opponent.effects[PBEffects::TwoTurnAttack]!=0
            if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=2
            else
              score*=0.5
            end
          end
          greatmove = false
          thisko = false
          if initialscores.length>0
            if initialscores[scoreindex] >= 100
              thisko = true
            end
            for i in initialscores
              if i>=100
                greatmove=true
              end
            end
          end
          if greatmove
            score*=0.1
          end
          if @doublebattle
            score*=0.5
          end
          score*=0.1 if checkAImoves(PBStuff::PROTECTMOVE,aimem)
          if !thisko
            score*=0.7
          end
        else
          score*=1.2
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::UNBURDEN)
            score*=1.5
          end
        end
        if opponent.pbCanParalyze?(false)
          miniscore=100
          miniscore*=1.1
          miniscore*=1.3 if attacker.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
          if opponent.hp==opponent.totalhp
            miniscore*=1.2
          end
          ministat=0
          ministat+=opponent.stages[PBStats::ATTACK]
          ministat+=opponent.stages[PBStats::SPATK]
          ministat+=opponent.stages[PBStats::SPEED]
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::NATURALCURE)
            miniscore*=0.3
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::MARVELSCALE)
            miniscore*=0.5
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::QUICKFEET) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::GUTS)
            miniscore*=0.2
          end
          if roles.include?(PBMonRoles::PHYSICALWALL) ||
             roles.include?(PBMonRoles::SPECIALWALL) ||
             roles.include?(PBMonRoles::PIVOT)
            miniscore*=1.2
          end
          if roles.include?(PBMonRoles::TANK)
            miniscore*=1.5
          end
          if pbRoughStat(opponent,PBStats::SPEED,skill)>attacker.pbSpeed &&
             (pbRoughStat(opponent,PBStats::SPEED,skill)/2.0)<attacker.pbSpeed && @trickroom==0
            miniscore*=1.5
          end
          if pbRoughStat(opponent,PBStats::SPATK,skill)>pbRoughStat(opponent,PBStats::ATTACK,skill)
            miniscore*=1.3
          end
          count = -1
          sweepvar = false
          for i in pbParty(attacker.index)
            count+=1
            next if i.nil?
            temprole = pbGetMonRole(i,opponent,skill,count,pbParty(attacker.index))
            if temprole.include?(PBMonRoles::SWEEPER)
              sweepvar = true
            end
          end
          miniscore*=1.3 if sweepvar
          if opponent.effects[PBEffects::Confusion]>0
            miniscore*=1.1
          end
          if opponent.effects[PBEffects::Attract]>=0
            miniscore*=1.1
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=0.4
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SHEDSKIN)
            miniscore*=0.7
          end
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
        end
      when 0xC6 # Ice Burn
        if !(attitemworks && attacker.item == PBItems::POWERHERB)
          if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
            score*=0.4
          else
            if attacker.hp*(1.0/attacker.totalhp)<0.5
              score*=0.6
            end
          end
          if opponent.effects[PBEffects::TwoTurnAttack]!=0
            if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=2
            else
              score*=0.5
            end
          end
          greatmove = false
          thisko = false
          if initialscores.length>0
            if initialscores[scoreindex] >= 100
              thisko = true
            end
            for i in initialscores
              if i>=100
                greatmove=true
              end
            end
          end
          if greatmove
            score*=0.1
          end
          if @doublebattle
            score*=0.5
          end
          score*=0.1 if checkAImoves(PBStuff::PROTECTMOVE,aimem)
          if !thisko
            score*=0.7
          end
        else
          score*=1.2
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::UNBURDEN)
            score*=1.5
          end
        end
        if opponent.pbCanBurn?(false)
          miniscore=100
          miniscore*=1.2
          ministat=0
          ministat+=opponent.stages[PBStats::ATTACK]
          ministat+=opponent.stages[PBStats::SPATK]
          ministat+=opponent.stages[PBStats::SPEED]
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::NATURALCURE)
            miniscore*=0.3
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::MARVELSCALE)
            miniscore*=0.7
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::QUICKFEET) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::FLAREBOOST) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::MAGICGUARD)
            miniscore*=0.3
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::GUTS)
            miniscore*=0.1
          end
          miniscore*=0.3 if checkAImoves([PBMoves::FACADE],aimem)
          miniscore*=0.1 if checkAImoves([PBMoves::REST],aimem)
          if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
            miniscore*=1.7
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=0.4
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SHEDSKIN)
            miniscore*=0.7
          end
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
        end
      when 0xC7 # Sky Attack
        if !(attitemworks && attacker.item == PBItems::POWERHERB)
          if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
            score*=0.4
          else
            if attacker.hp*(1.0/attacker.totalhp)<0.5
              score*=0.6
            end
          end
          if opponent.effects[PBEffects::TwoTurnAttack]!=0
            if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=2
            else
              score*=0.5
            end
          end
          greatmove = false
          thisko = false
          if initialscores.length>0
            if initialscores[scoreindex] >= 100
              thisko = true
            end
            for i in initialscores
              if i>=100
                greatmove=true
              end
            end
          end
          if greatmove
            score*=0.1
          end
          if @doublebattle
            score*=0.5
          end
          score*=0.1 if checkAImoves(PBStuff::PROTECTMOVE,aimem)
          if !thisko
            score*=0.7
          end
        else
          score*=1.2
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::UNBURDEN)
            score*=1.5
          end
        end
        if opponent.effects[PBEffects::Substitute]==0 &&
           !(!opponent.abilitynulled && opponent.ability == PBAbilities::INNERFOCUS)
          if (pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed)   ^ (@trickroom!=0)
            miniscore=100
            miniscore*=1.3
            if skill>=PBTrainerAI.bestSkill
              if $fefieldeffect==14 # Rocky
                miniscore*=1.2
              end
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::STEADFAST)
              miniscore*=0.3
            end
            miniscore-=100
            if move.addlEffect.to_f != 100
              miniscore*=(move.addlEffect.to_f/100)
              if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
                miniscore*=2
              end
            end
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
        end
      when 0xC8 # Skull Bash
        if !(attitemworks && attacker.item == PBItems::POWERHERB)
          if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
            score*=0.4
          else
            if attacker.hp*(1.0/attacker.totalhp)<0.5
              score*=0.6
            end
          end
          if opponent.effects[PBEffects::TwoTurnAttack]!=0
            if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=2
            else
              score*=0.5
            end
          end
          greatmove = false
          thisko = false
          if initialscores.length>0
            if initialscores[scoreindex] >= 100
              thisko = true
            end
            for i in initialscores
              if i>=100
                greatmove=true
              end
            end
          end
          if greatmove
            score*=0.1
          end
          if @doublebattle
            score*=0.5
          end
          score*=0.1 if checkAImoves(PBStuff::PROTECTMOVE,aimem)
          if !thisko
            score*=0.7
          end
        else
          score*=1.2
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::UNBURDEN)
            score*=1.5
          end
        end
        miniscore=100
        if attacker.effects[PBEffects::Substitute]>0 || attacker.effects[PBEffects::Disguise]
          miniscore*=1.3
        end
        if (attacker.hp.to_f)/attacker.totalhp>0.75
          miniscore*=1.1
        end
        if opponent.effects[PBEffects::HyperBeam]>0
          miniscore*=1.2
        end
        if opponent.effects[PBEffects::Yawn]>0
          miniscore*=1.3
        end
        if skill>=PBTrainerAI.mediumSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if maxdam<(attacker.hp/3.0) && (aimem.length > 0)
            miniscore*=1.1
          end
        end
        if attacker.turncount<2
          miniscore*=1.1
        end
        if opponent.status!=0
          miniscore*=1.1
        end
        if opponent.status==PBStatuses::SLEEP || opponent.status==PBStatuses::FROZEN
          miniscore*=1.3
        end
        if opponent.effects[PBEffects::Encore]>0
          if opponent.moves[(opponent.effects[PBEffects::EncoreIndex])].basedamage==0
            miniscore*=1.3
          end
        end
        if attacker.effects[PBEffects::Confusion]>0
          miniscore*=0.3
        end
        if attacker.effects[PBEffects::LeechSeed]>=0 || attacker.effects[PBEffects::Attract]>=0
          miniscore*=0.3
        end
        if attacker.effects[PBEffects::Toxic]>0
          miniscore*=0.2
        end
        miniscore*=0.2 if checkAImoves(PBStuff::SWITCHOUTMOVE,aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::SIMPLE)
          miniscore*=2
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          miniscore*=0.5
        end
        if @doublebattle
          miniscore*=0.3
        end
        if attacker.stages[PBStats::DEFENSE]>0
          ministat=attacker.stages[PBStats::DEFENSE]
          minimini=-15*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
          miniscore*=1.3
        end
        if skill>=PBTrainerAI.mediumSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if (maxdam.to_f/attacker.hp)<0.12 && (aimem.length > 0)
            miniscore*=0.3
          end
        end
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.3
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
          ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.2
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        miniscore-=100
        if move.addlEffect.to_f != 100
          miniscore*=(move.addlEffect.to_f/100)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
            miniscore*=2
          end
        end
        miniscore+=100
        miniscore/=100.0
        if attacker.pbTooHigh?(PBStats::DEFENSE)
          miniscore=1
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          miniscore*=0.5
        end
        score*=miniscore
      when 0xC9 # Fly
        livecount1=0
        for i in pbParty(opponent.index)
          next if i.nil?
          livecount1+=1 if i.hp!=0
        end
        livecount2=0
        for i in pbParty(attacker.index)
          next if i.nil?
          livecount2+=1 if i.hp!=0
        end
        if skill<PBTrainerAI.bestSkill || $fefieldeffect!=23 # Not in a cave
          if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN ||
             opponent.effects[PBEffects::LeechSeed]>=0 ||
             opponent.effects[PBEffects::MultiTurn]>0 ||
             opponent.effects[PBEffects::Curse]
            score*=1.2
          else
            if livecount1>1
              score*=0.8
            end
          end
          if attacker.status!=0 || attacker.effects[PBEffects::Curse] ||
             attacker.effects[PBEffects::Attract]>-1 ||
             attacker.effects[PBEffects::Confusion]>0
            score*=0.5
          end
          if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
             ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
            score*=1.1
          end
          if attacker.pbOwnSide.effects[PBEffects::Tailwind]>0 ||
             attacker.pbOwnSide.effects[PBEffects::Reflect]>0 ||
             attacker.pbOwnSide.effects[PBEffects::LightScreen]>0
            score*=0.7
          end
          if opponent.effects[PBEffects::PerishSong]!=0 && attacker.effects[PBEffects::PerishSong]==0
            score*=1.3
          end
          if (attitemworks && attacker.item == PBItems::POWERHERB)
            score*=1.5
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::NOGUARD) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD)
            score*=0.1
          end
          if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            if opponent.vanished
              score*=3
            end
            score*=1.1
          else
            score*=0.8
            score*=0.5 if checkAIhealing(aimem)
            score*=0.7 if checkAIaccuracy(aimem)
          end
          score*=0.3 if checkAImoves([PBMoves::THUNDER,PBMoves::HURRICANE],aimem)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==22
              if !attacker.pbHasType?(PBTypes::WATER)
                score*=2
              end
            end
          end
        end
        if @field.effects[PBEffects::Gravity]>0
          score*=0
        end
      when 0xCA # Dig
        livecount1=0
        for i in pbParty(opponent.index)
          next if i.nil?
          livecount1+=1 if i.hp!=0
        end
        livecount2=0
        for i in pbParty(attacker.index)
          next if i.nil?
          livecount2+=1 if i.hp!=0
        end
        if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN ||
           opponent.effects[PBEffects::LeechSeed]>=0 ||
           opponent.effects[PBEffects::MultiTurn]>0 ||
           opponent.effects[PBEffects::Curse]
          score*=1.2
        else
          if livecount1>1
            score*=0.8
          end
        end
        if attacker.status!=0 || attacker.effects[PBEffects::Curse] ||
           attacker.effects[PBEffects::Attract]>-1 ||
           attacker.effects[PBEffects::Confusion]>0
          score*=0.5
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          score*=1.1
        end
        if attacker.pbOwnSide.effects[PBEffects::Tailwind]>0 ||
           attacker.pbOwnSide.effects[PBEffects::Reflect]>0 ||
           attacker.pbOwnSide.effects[PBEffects::LightScreen]>0
          score*=0.7
        end
        if opponent.effects[PBEffects::PerishSong]!=0 && attacker.effects[PBEffects::PerishSong]==0
          score*=1.3
        end
        if (attitemworks && attacker.item == PBItems::POWERHERB)
          score*=1.5
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::NOGUARD) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD)
          score*=0.1
        end
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          if opponent.vanished
            score*=3
          end
          score*=1.1
        else
          score*=0.8
          score*=0.5 if checkAIhealing(aimem)
          score*=0.7 if checkAIaccuracy(aimem)
        end
        score*=0.3 if checkAImoves([PBMoves::EARTHQUAKE],aimem)
      when 0xCB # Dive
        livecount1=0
        for i in pbParty(opponent.index)
          next if i.nil?
          livecount1+=1 if i.hp!=0
        end
        livecount2=0
        for i in pbParty(attacker.index)
          next if i.nil?
          livecount2+=1 if i.hp!=0
        end
        if skill>=PBTrainerAI.bestSkill && ($fefieldeffect==21 || $fefieldeffect==22)  # Water Surface/Underwater
          if $fefieldeffect==21 # Water Surface
            if !opponent.pbHasType?(PBTypes::WATER)
              score*=2
            else
              for mon in pbParty(attacker.index)
                watervar=false
                next if mon.nil?
                if mon.hasType?(:WATER)
                  watervar=true
                end
                if watervar
                  score*=1.3
                end
              end
            end
          else
            if !attacker.pbHasType?(PBTypes::WATER)
              score*=2
            else
              for mon in pbParty(attacker.index)
                watervar=false
                next if mon.nil?
                if mon.hasType?(:WATER)
                  watervar=true
                end
                if watervar
                  score*=0.6
                end
              end
            end
          end
        else
          if $fefieldeffect==26 # Murkwater Surface
            if !attacker.pbHasType?(PBTypes::POISON) && !attacker.pbHasType?(PBTypes::STEEL)
              score*=0.3
            end
          end
          if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN ||
             opponent.effects[PBEffects::LeechSeed]>=0 ||
             opponent.effects[PBEffects::MultiTurn]>0 ||
             opponent.effects[PBEffects::Curse]
            score*=1.2
          else
            if livecount1>1
              score*=0.8
            end
          end
          if attacker.status!=0 ||
             attacker.effects[PBEffects::Curse] ||
             attacker.effects[PBEffects::Attract]>-1 ||
             attacker.effects[PBEffects::Confusion]>0
            score*=0.5
          end
          if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
             ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
            score*=1.1
          end
          if attacker.pbOwnSide.effects[PBEffects::Tailwind]>0 ||
             attacker.pbOwnSide.effects[PBEffects::Reflect]>0 ||
             attacker.pbOwnSide.effects[PBEffects::LightScreen]>0
            score*=0.7
          end
          if opponent.effects[PBEffects::PerishSong]!=0 && attacker.effects[PBEffects::PerishSong]==0
            score*=1.3
          end
          if (attitemworks && attacker.item == PBItems::POWERHERB)
            score*=1.5
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::NOGUARD) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD)
            score*=0.1
          end
          if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            if opponent.vanished
              score*=3
            end
            score*=1.1
          else
            score*=0.8
            score*=0.5 if checkAIhealing(aimem)
            score*=0.7 if checkAIaccuracy(aimem)
          end
          score*=0.3 if checkAImoves([PBMoves::SURF],aimem)
        end
      when 0xCC # Bounce
        if opponent.pbCanParalyze?(false)
          miniscore=100
          miniscore*=1.1 if attacker.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
          if opponent.hp==opponent.totalhp
            miniscore*=1.2
          end
          ministat=0
          ministat+=opponent.stages[PBStats::ATTACK]
          ministat+=opponent.stages[PBStats::SPATK]
          ministat+=opponent.stages[PBStats::SPEED]
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::NATURALCURE)
            miniscore*=0.3
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::MARVELSCALE)
            miniscore*=0.5
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::QUICKFEET) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::GUTS)
            miniscore*=0.2
          end
          if roles.include?(PBMonRoles::PHYSICALWALL) ||
             roles.include?(PBMonRoles::SPECIALWALL) ||
             roles.include?(PBMonRoles::PIVOT)
            miniscore*=1.2
          end
          if roles.include?(PBMonRoles::TANK)
            miniscore*=1.3
          end
          if pbRoughStat(opponent,PBStats::SPEED,skill)>attacker.pbSpeed &&
             (pbRoughStat(opponent,PBStats::SPEED,skill)/2)<attacker.pbSpeed && @trickroom==0
            miniscore*=1.5
          end
          if pbRoughStat(opponent,PBStats::SPATK,skill)>pbRoughStat(opponent,PBStats::ATTACK,skill)
            miniscore*=1.1
          end
          count = -1
          sweepvar = false
          for i in pbParty(attacker.index)
            count+=1
            next if i.nil?
            temprole = pbGetMonRole(i,opponent,skill,count,pbParty(attacker.index))
            if temprole.include?(PBMonRoles::SWEEPER)
              sweepvar = true
            end
          end
          miniscore*=1.1 if sweepvar
          if opponent.effects[PBEffects::Confusion]>0
            miniscore*=1.1
          end
          if opponent.effects[PBEffects::Attract]>=0
            miniscore*=1.1
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=0.4
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SHEDSKIN)
            miniscore*=0.7
          end
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
        end
        livecount1=0
        for i in pbParty(opponent.index)
          next if i.nil?
          livecount1+=1 if i.hp!=0
        end
        livecount2=0
        for i in pbParty(attacker.index)
          next if i.nil?
          livecount2+=1 if i.hp!=0
        end
        if skill<PBTrainerAI.bestSkill || $fefieldeffect!=23 # Not in a cave
          if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN ||
             opponent.effects[PBEffects::LeechSeed]>=0 ||
             opponent.effects[PBEffects::MultiTurn]>0 ||
             opponent.effects[PBEffects::Curse]
            score*=1.2
          else
            if livecount1>1
              score*=0.7
            end
          end
          if attacker.status!=0 || attacker.effects[PBEffects::Curse] ||
             attacker.effects[PBEffects::Attract]>-1 ||
             attacker.effects[PBEffects::Confusion]>0
            score*=0.5
          end
          if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
             ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
            score*=1.1
          end
          if attacker.pbOwnSide.effects[PBEffects::Tailwind]>0 ||
             attacker.pbOwnSide.effects[PBEffects::Reflect]>0 ||
             attacker.pbOwnSide.effects[PBEffects::LightScreen]>0
            score*=0.7
          end
          if opponent.effects[PBEffects::PerishSong]!=0 && attacker.effects[PBEffects::PerishSong]==0
            score*=1.3
          end
          if (attitemworks && attacker.item == PBItems::POWERHERB)
            score*=1.5
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::NOGUARD) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD)
            score*=0.1
          end
          if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            if opponent.vanished
              score*=3
            end
            score*=1.1
          else
            score*=0.8
            score*=0.5 if checkAIhealing(aimem)
            score*=0.7 if checkAIaccuracy(aimem)
          end
          score*=0.3 if checkAImoves([PBMoves::THUNDER,PBMoves::HURRICANE],aimem)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==22
              if !attacker.pbHasType?(PBTypes::WATER)
                score*=2
              end
            end
          end
        end
        if @field.effects[PBEffects::Gravity]>0
          score*=0
        end
      when 0xCD # Phantom Force
        livecount1=0
        for i in pbParty(opponent.index)
          next if i.nil?
          livecount1+=1 if i.hp!=0
        end
        livecount2=0
        for i in pbParty(attacker.index)
          next if i.nil?
          livecount2+=1 if i.hp!=0
        end
        if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN ||
           opponent.effects[PBEffects::LeechSeed]>=0 ||
           opponent.effects[PBEffects::MultiTurn]>0 ||
           opponent.effects[PBEffects::Curse]
          score*=1.2
        else
          if livecount1>1
            score*=0.8
          end
        end
        if attacker.status!=0 || attacker.effects[PBEffects::Curse] ||
           attacker.effects[PBEffects::Attract]>-1 ||
           attacker.effects[PBEffects::Confusion]>0
          score*=0.5
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          score*=1.1
        end
        if attacker.pbOwnSide.effects[PBEffects::Tailwind]>0 ||
           attacker.pbOwnSide.effects[PBEffects::Reflect]>0 ||
           attacker.pbOwnSide.effects[PBEffects::LightScreen]>0
          score*=0.7
        end
        if opponent.effects[PBEffects::PerishSong]!=0 && attacker.effects[PBEffects::PerishSong]==0
          score*=1.3
        end
        if (attitemworks && attacker.item == PBItems::POWERHERB)
          score*=1.5
        end
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=1.1
        else
          score*=0.8
          score*=0.5 if checkAIhealing(aimem)
          score*=0.7 if checkAIaccuracy(aimem)
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::NOGUARD) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD)
          score*=0.1
        else
          miniscore=100
          if attacker.stages[PBStats::ACCURACY]<0
            miniscore = (-5)*attacker.stages[PBStats::ACCURACY]
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
          if opponent.stages[PBStats::EVASION]>0
            miniscore = (5)*opponent.stages[PBStats::EVASION]
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
          if (oppitemworks && opponent.item == PBItems::LAXINCENSE) ||
             (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER)
            score*=1.2
          end
          if ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
             ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL)
            score*=1.3
          end
          if opponent.vanished && ((attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0))
            score*=3
          end
        end
      when 0xCE # Sky Drop
        if opponent.pbHasType?(:FLYING)
          score = 5
        end
        livecount1=0
        for i in pbParty(opponent.index)
          next if i.nil?
          livecount1+=1 if i.hp!=0
        end
        livecount2=0
        for i in pbParty(attacker.index)
          next if i.nil?
          livecount2+=1 if i.hp!=0
        end
        if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN ||
           opponent.effects[PBEffects::LeechSeed]>=0 ||
           opponent.effects[PBEffects::MultiTurn]>0 ||
           opponent.effects[PBEffects::Curse]
          score*=1.5
        else
          if livecount1>1
            score*=0.8
          end
        end
        if attacker.status!=0 || attacker.effects[PBEffects::Curse] ||
           attacker.effects[PBEffects::Attract]>-1 ||
           attacker.effects[PBEffects::Confusion]>0
          score*=0.5
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          score*=1.1
        end
        if attacker.pbOwnSide.effects[PBEffects::Tailwind]>0 ||
           attacker.pbOwnSide.effects[PBEffects::Reflect]>0 ||
           attacker.pbOwnSide.effects[PBEffects::LightScreen]>0
          score*=0.7
        end
        if opponent.effects[PBEffects::PerishSong]!=0 && attacker.effects[PBEffects::PerishSong]==0
          score*=1.3
        end
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill))  ^ (@trickroom!=0)
          score*=1.1
        else
          score*=0.8
        end
        if $fefieldeffect==22
          if !attacker.pbHasType?(:WATER)
            score*=2
          end
        end
        if @field.effects[PBEffects::Gravity]>0 || $fefieldeffect==23 || opponent.effects[PBEffects::Substitute]>0
          score*=0
        end
      when 0xCF # Fire Spin
        if opponent.effects[PBEffects::MultiTurn]==0 && opponent.effects[PBEffects::Substitute]<=0
          score*=1.2
          if initialscores.length>0
            score*=1.2 if hasbadmoves(initialscores,scoreindex,30)
          end
          ministat=(-5)*statchangecounter(opponent,1,7,1)
          ministat+=100
          ministat/=100.0
          score*=ministat
          if opponent.totalhp == opponent.hp
            score*=1.2
          elsif opponent.hp*2 < opponent.totalhp
            score*=0.8
          end
          if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
            score*=0.7
          elsif attacker.hp*3<attacker.totalhp
            score*=0.7
          end
          if opponent.effects[PBEffects::LeechSeed]>=0
            score*=1.5
          end
          if opponent.effects[PBEffects::Attract]>-1
            score*=1.3
          end
          if opponent.effects[PBEffects::Confusion]>0
            score*=1.3
          end
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            score*=1.2
          end
          movecheck = false
          for j in attacker.moves
            movecheck = true if j.id==(PBMoves::PROTECT) || j.id==(PBMoves::DETECT) ||
                                j.id==(PBMoves::BANEFULBUNKER) || j.id==(PBMoves::SPIKYSHIELD)
          end
          if movecheck
            score*=1.1
          end
          if (attitemworks && attacker.item == PBItems::BINDINGBAND)
            score*=1.3
          end
          if (attitemworks && attacker.item == PBItems::GRIPCLAW)
            score*=1.1
          end
        end
        if move.id==(PBMoves::FIRESPIN)
          if $fefieldeffect==20
            score*=0.7
          end
        end
        if move.id==(PBMoves::MAGMASTORM)
          if $fefieldeffect==32
            score*=1.3
          end
        end
        if move.id==(PBMoves::SANDTOMB)
          if $fefieldeffect==12
            score*=1.3
          elsif $fefieldeffect==20
            score*=1.5 unless opponent.stages[PBStats::ACCURACY]<(-2)
          end
        end
        if move.id==(PBMoves::INFESTATION)
          if $fefieldeffect==15
            score*=1.3
          elsif $fefieldeffect==33
            score*=1.3
            if $fecounter == 3
              score*=1.3
            end
            if $fecounter == 4
              score*=1.5
            end
          end
        end
      when 0xD0 # Whirlpool
        if opponent.effects[PBEffects::MultiTurn]==0 && opponent.effects[PBEffects::Substitute]<=0
          score*=1.2
          if initialscores.length>0
            score*=1.2 if hasbadmoves(initialscores,scoreindex,30)
          end
          ministat=(-5)*statchangecounter(opponent,1,7,1)
          ministat+=100
          ministat/=100.0
          score*=ministat
          if opponent.totalhp == opponent.hp
            score*=1.2
          elsif opponent.hp*2 < opponent.totalhp
            score*=0.8
          end
          if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
            score*=0.7
          elsif attacker.hp*3<attacker.totalhp
            score*=0.7
          end
          if opponent.effects[PBEffects::LeechSeed]>=0
            score*=1.5
          end
          if opponent.effects[PBEffects::Attract]>-1
            score*=1.3
          end
          if opponent.effects[PBEffects::Confusion]>0
            score*=1.3
          end
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            score*=1.2
          end
          movecheck = false
          for j in attacker.moves
            movecheck = true if j.id==(PBMoves::PROTECT) || j.id==(PBMoves::DETECT) ||
                                j.id==(PBMoves::BANEFULBUNKER) || j.id==(PBMoves::SPIKYSHIELD)
          end
          if movecheck
            score*=1.1
          end
          if (attitemworks && attacker.item == PBItems::BINDINGBAND)
            score*=1.3
          end
          if (attitemworks && attacker.item == PBItems::GRIPCLAW)
            score*=1.1
          end
          if $pkmn_move[opponent.effects[PBEffects::TwoTurnAttack]][0] #the function code of the current move==0xCB
            score*=1.3
          end
        end
        watervar = false
        poisonvar = false
        for p in pbParty(attacker.index)
          next if p.nil?
          watervar = true if p.hasType?(:WATER)
          poisonvar = true if p.hasType?(:POISON)
        end
        if $fefieldeffect==20
          score*=0.7
        end
        if $fefieldeffect==21 || $fefieldeffect==22
          score*=1.3
          if opponent.effects[PBEffects::Confusion]<=0
            score*=1.5
          end
        end
        if $fefieldeffect==26
          if score==0
            score+=10
          end
          if !(attacker.pbHasType?(:POISON) || attacker.pbHasType?(:STEEL))
            score*=1.5
          end
          if !poisonvar
            score*=2
          end
          if watervar
            score*=2
          end
        end
      when 0xD1 # Uproar
        if opponent.status==PBStatuses::SLEEP
          score*=0.7
        end
        if opponent.pbHasMove?(:REST)
          score*=1.8
        end
        if opponent.pbNonActivePokemonCount==0 ||
           (!attacker.abilitynulled && attacker.ability == PBAbilities::SHADOWTAG) ||
           opponent.effects[PBEffects::MeanLook]>0
          score*=1.1
        end
        typemod=move.pbTypeModifier(move.type,attacker,opponent)
        if typemod<4
          score*=0.7
        end
        if attacker.hp*(1.0/attacker.totalhp)<0.75
          score*=0.75
        end
        if attacker.stages[PBStats::SPATK]<0
          minimini = attacker.stages[PBStats::SPATK]
          minimini*=5
          minimini+=100
          minimini/=100.0
          score*=minimini
        end
        if opponent.pbNonActivePokemonCount>1
          miniscore = opponent.pbNonActivePokemonCount*0.05
          miniscore = 1-miniscore
          score*=miniscore
        end
      when 0xD2 # Outrage
        livecount1=0
        thisinitial = score
        for i in pbParty(opponent.index)
          next if i.nil?
          livecount1+=1 if i.hp!=0
        end
        #this isn't used?
        #livecount2=0
        #for i in pbParty(attacker.index)
        #  next if i.nil?
        #  livecount2+=1 if i.hp!=0
        #end
        if !(!attacker.abilitynulled && attacker.ability == PBAbilities::OWNTEMPO)
          if thisinitial<100
            score*=0.85
          end
          if (attitemworks && attacker.item == PBItems::LUMBERRY) ||
             (attitemworks && attacker.item == PBItems::PERSIMBERRY)
            score*=1.3
          end
          if attacker.stages[PBStats::ATTACK]>0
            miniscore = (-5)*attacker.stages[PBStats::ATTACK]
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
          if livecount1>2
            miniscore=100
            miniscore*=(livecount1-1)
            miniscore*=0.01
            miniscore*=0.025
            miniscore=1-miniscore
            score*=miniscore
          end
          score*=0.7 if checkAImoves(PBStuff::PROTECTMOVE,aimem)
          score*=0.7 if checkAIhealing(aimem)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==16 # Superheated Field
              score*=0.5
            end
          end
        else
            score *= 1.2
        end
        if move.id==(PBMoves::PETALDANCE)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==33 && $fecounter>1
              score*=1.5
            end
          end
        elsif move.id==(PBMoves::OUTRAGE)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect!=36
              fairyvar = false
              for mon in pbParty(opponent.index)
                next if mon.nil?
                ghostvar=true if mon.hasType?(:FAIRY)
              end
              if fairyvar
                score*=0.8
              end
            end
          end
        elsif move.id==(PBMoves::THRASH)
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect!=36
              ghostvar = false
              for mon in pbParty(opponent.index)
                next if mon.nil?
                ghostvar=true if mon.hasType?(:GHOST)
              end
              if ghostvar
                score*=0.8
              end
            end
          end
        end
      when 0xD3 # Rollout
        if opponent.pbNonActivePokemonCount==0 ||
           (!attacker.abilitynulled && attacker.ability == PBAbilities::SHADOWTAG) ||
           opponent.effects[PBEffects::MeanLook]>0
          score*=1.1
        end
        if attacker.hp*(1.0/attacker.totalhp)<0.75
          score*=0.75
        end
        if attacker.stages[PBStats::ACCURACY]<0
            miniscore = (5)*attacker.stages[PBStats::ATTACK]
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
          if attacker.stages[PBStats::ATTACK]<0
            miniscore = (5)*attacker.stages[PBStats::ATTACK]
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
          if opponent.stages[PBStats::EVASION]>0
            miniscore = (-5)*attacker.stages[PBStats::ATTACK]
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
          if (oppitemworks && opponent.item == PBItems::LAXINCENSE) ||
             (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER)
            score*=0.8
          end
          if ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
             ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL)
            score*=0.8
          end
          if attacker.status==PBStatuses::PARALYSIS
            score*=0.5
          end
          if attacker.effects[PBEffects::Confusion]>0
            score*=0.5
          end
          if attacker.effects[PBEffects::Attract]>=0
            score*=0.5
          end
          if opponent.pbNonActivePokemonCount>1
            miniscore = 1 - (opponent.pbNonActivePokemonCount*0.05)
            score*=miniscore
          end
          if attacker.effects[PBEffects::DefenseCurl]
            score*=1.2
          end
          if checkAIdamage(aimem,attacker,opponent,skill)*3<attacker.hp && (aimem.length > 0)
            score*=1.5
          end
          score*=0.8 if checkAImoves(PBStuff::PROTECTMOVE,aimem)
          if $fefieldeffect==13
            if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=1.3
            end
          end
      when 0xD4 # Bide
        statmove = false
        movelength = -1
        if aimem.length > 0
          for j in aimem
            movelength = aimem.length
            if j.basedamage==0
              statmove=true
            end
          end
        end
        if ((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           (!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY))
          score*=1.2
        end
        miniscore = attacker.hp*(1.0/attacker.totalhp)
        score*=miniscore
        if checkAIdamage(aimem,attacker,opponent,skill)*2 > attacker.hp
          score*=0.2
        end
        if attacker.hp*3<attacker.totalhp
          score*=0.7
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          score*=1.1
        end
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          score*=1.3
        end
        if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=1.3
        end
        score*=0.5 if checkAImoves(PBStuff::SETUPMOVE,aimem)
        if statmove
          score*=0.8
        else
          if movelength==4
            score*=1.3
          end
        end
      when 0xD5 # Recover
        if aimem.length > 0 && skill>=PBTrainerAI.bestSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if maxdam>attacker.hp
            if maxdam>(attacker.hp*1.5)
              score=0
            else
              score*=5
            #experimental -- cancels out drop if killing moves
              if initialscores.length>0
                score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
              end
              #end experimental
            end
          else
            if maxdam*1.5>attacker.hp
              score*=2
            end
            if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              if maxdam*2>attacker.hp
                score*=5
                #experimental -- cancels out drop if killing moves
                if initialscores.length>0
                  score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
                end
                #end experimental
              end
            end
          end
        elsif skill>=PBTrainerAI.bestSkill #no highest expected damage yet
          if ((attacker.hp.to_f)/attacker.totalhp)<0.5
            score*=3
            if ((attacker.hp.to_f)/attacker.totalhp)<0.25
              score*=3
            end
            #experimental -- cancels out drop if killing moves
            if initialscores.length>0
              score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
            end
            #end experimental
          end
        elsif skill>=PBTrainerAI.mediumSkill
          score*=3 if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
        end
        score*=0.7 if opponent.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
        if (attacker.hp.to_f)/attacker.totalhp<0.5
          score*=1.5
          if attacker.effects[PBEffects::Curse]
            score*=2
          end
          if attacker.hp*4<attacker.totalhp
            if attacker.status==PBStatuses::POISON
              score*=1.5
            end
            if attacker.effects[PBEffects::LeechSeed]>=0
              score*=2
            end
            if attacker.hp<attacker.totalhp*0.13
              if attacker.status==PBStatuses::BURN
                score*=2
              end
              if (pbWeather==PBWeather::HAIL && !attacker.pbHasType?(:ICE)) ||
                 (pbWeather==PBWeather::SANDSTORM && !attacker.pbHasType?(:ROCK) && !attacker.pbHasType?(:GROUND) && !attacker.pbHasType?(:STEEL))
                score*=2
              end
            end
          end
        else
          score*=0.9
        end
        if attacker.effects[PBEffects::Toxic]>0
          score*=0.5
          if attacker.effects[PBEffects::Toxic]>4
            score*=0.5
          end
        end
        if attacker.status==PBStatuses::PARALYSIS ||
           attacker.effects[PBEffects::Attract]>=0 ||
           attacker.effects[PBEffects::Confusion]>0
          score*=1.1
        end
        if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN ||
           opponent.effects[PBEffects::LeechSeed]>=0 || opponent.effects[PBEffects::Curse]
          score*=1.3
          if opponent.effects[PBEffects::Toxic]>0
            score*=1.3
          end
        end
        score*=1.3 if checkAImoves(PBStuff::CONTRARYBAITMOVE,aimem)
        if opponent.vanished || opponent.effects[PBEffects::HyperBeam]>0
          score*=1.2
        end
        if skill>=PBTrainerAI.bestSkill
          if move.id==(PBMoves::HEALORDER)
            if $fefieldeffect==15 # Forest
              score*=1.3
            end
          end
        end
        if ((attacker.hp.to_f)/attacker.totalhp)>0.8
          score=0
        elsif ((attacker.hp.to_f)/attacker.totalhp)>0.6
          score*=0.6
        elsif ((attacker.hp.to_f)/attacker.totalhp)<0.25
          score*=2
        end
        if attacker.effects[PBEffects::Wish]>0
            score=0
        end
      when 0xD6 # Roost
        besttype=-1
        if aimem.length > 0 && skill>=PBTrainerAI.bestSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if maxdam>attacker.hp
            if maxdam>(attacker.hp*1.5)
              score=0
            else
              score*=5
            #experimental -- cancels out drop if killing moves
              if initialscores.length>0
                score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
              end
              #end experimental
            end
          else
            if maxdam*1.5>attacker.hp
              score*=2
            end
            if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              if maxdam*2>attacker.hp
                score*=5
                #experimental -- cancels out drop if killing moves
                if initialscores.length>0
                  score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
                end
                #end experimental
              end
            end
          end
        elsif skill>=PBTrainerAI.bestSkill #no highest expected damage yet
          if ((attacker.hp.to_f)/attacker.totalhp)<0.5
            score*=3
            if ((attacker.hp.to_f)/attacker.totalhp)<0.25
              score*=3
            end
            #experimental -- cancels out drop if killing moves
            if initialscores.length>0
              score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
            end
            #end experimental
          end
        elsif skill>=PBTrainerAI.mediumSkill
          score*=3 if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
        end
        score*=0.7 if opponent.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
        if (attacker.hp.to_f)/attacker.totalhp<0.5
          score*=1.5
          if attacker.effects[PBEffects::Curse]
            score*=2
          end
          if attacker.hp*4<attacker.totalhp
            if attacker.status==PBStatuses::POISON
              score*=1.5
            end
            if attacker.effects[PBEffects::LeechSeed]>=0
              score*=2
            end
            if attacker.hp<attacker.totalhp*0.13
              if attacker.status==PBStatuses::BURN
                score*=2
              end
              if (pbWeather==PBWeather::HAIL && !attacker.pbHasType?(:ICE)) ||
                 (pbWeather==PBWeather::SANDSTORM && !attacker.pbHasType?(:ROCK) && !attacker.pbHasType?(:GROUND) && !attacker.pbHasType?(:STEEL))
                score*=2
              end
            end
          end
        else
          score*=0.9
        end
        if attacker.effects[PBEffects::Toxic]>0
          score*=0.5
          if attacker.effects[PBEffects::Toxic]>4
            score*=0.5
          end
        end
        if attacker.status==PBStatuses::PARALYSIS ||
           attacker.effects[PBEffects::Attract]>=0 ||
           attacker.effects[PBEffects::Confusion]>0
          score*=1.1
        end
        #if !(roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL))
        #  score*=0.8
        #end
        if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN ||
           opponent.effects[PBEffects::LeechSeed]>=0 || opponent.effects[PBEffects::Curse]
          score*=1.3
          if opponent.effects[PBEffects::Toxic]>0
            score*=1.3
          end
        end
        score*=1.3 if checkAImoves(PBStuff::CONTRARYBAITMOVE,aimem)
        if opponent.vanished || opponent.effects[PBEffects::HyperBeam]>0
          score*=1.2
        end
        if besttype!=-1
          if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            if (m.type == PBTypes::ROCK) || (m.type == PBTypes::ICE) || (m.type == PBTypes::ELECTRIC)
              score*=1.5
            else
              if (m.type == PBTypes::BUG) || (m.type == PBTypes::FIGHTING) ||
                 (m.type == PBTypes::GRASS) || (m.type == PBTypes::GROUND)
                score*=0.5
              end
            end
          end
        end
        if ((attacker.hp.to_f)/attacker.totalhp)>0.8
          score=0
        elsif ((attacker.hp.to_f)/attacker.totalhp)>0.6
          score*=0.6
        elsif ((attacker.hp.to_f)/attacker.totalhp)<0.25
          score*=2
        end
        if attacker.effects[PBEffects::Wish]>0
            score=0
        end
      when 0xD7 # Wish
        protectmove=false
        for j in attacker.moves
          protectmove = true if j.id==(PBMoves::PROTECT) || j.id==(PBMoves::DETECT) ||
                                j.id==(PBMoves::BANEFULBUNKER) || j.id==(PBMoves::SPIKYSHIELD)
        end
        if aimem.length > 0 && skill>=PBTrainerAI.bestSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if maxdam>attacker.hp
            if maxdam>(attacker.hp*1.5)
              score=0
            else
              score*=5
            #experimental -- cancels out drop if killing moves
              if initialscores.length>0
                score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
              end
              #end experimental
            end
          else
            if maxdam*1.5>attacker.hp
              score*=2
            end
            if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              if maxdam*2>attacker.hp
                score*=5
                #experimental -- cancels out drop if killing moves
                if initialscores.length>0
                  score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
                end
                #end experimental
              end
            end
          end
        elsif skill>=PBTrainerAI.bestSkill #no highest expected damage yet
          if ((attacker.hp.to_f)/attacker.totalhp)<0.5
            score*=3
            if ((attacker.hp.to_f)/attacker.totalhp)<0.25
              score*=3
            end
            #experimental -- cancels out drop if killing moves
            if initialscores.length>0
              score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
            end
            #end experimental
          end
        elsif skill>=PBTrainerAI.mediumSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if maxdam>attacker.hp
            score*=3
          end
        end
        score*=0.7 if opponent.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
        if (attacker.hp.to_f)/attacker.totalhp<0.5
          if attacker.effects[PBEffects::Curse]
            score*=2
          end
          if attacker.hp*4<attacker.totalhp
            if attacker.status==PBStatuses::POISON
              score*=1.5
            end
            if attacker.effects[PBEffects::LeechSeed]>=0
              score*=2
            end
            if attacker.hp<attacker.totalhp*0.13
              if attacker.status==PBStatuses::BURN
                score*=2
              end
              if (pbWeather==PBWeather::HAIL && !attacker.pbHasType?(:ICE)) ||
                 (pbWeather==PBWeather::SANDSTORM && !attacker.pbHasType?(:ROCK) && !attacker.pbHasType?(:GROUND) && !attacker.pbHasType?(:STEEL))
                score*=2
              end
            end
          end
        else
          score*=0.7
        end
        if attacker.effects[PBEffects::Toxic]>0
          score*=0.5
          if attacker.effects[PBEffects::Toxic]>4
            score*=0.5
          end
        end
        if attacker.status==PBStatuses::PARALYSIS ||
           attacker.effects[PBEffects::Attract]>=0 ||
           attacker.effects[PBEffects::Confusion]>0
          score*=1.1
        end
        if !(roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL))
          score*=0.8
        end
        if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN ||
           opponent.effects[PBEffects::LeechSeed]>=0 || opponent.effects[PBEffects::Curse]
          score*=1.3
          if opponent.effects[PBEffects::Toxic]>0
            score*=1.3
          end
        end
        score*=1.3 if checkAImoves(PBStuff::CONTRARYBAITMOVE,aimem)
        if opponent.vanished || opponent.effects[PBEffects::HyperBeam]>0
          score*=1.2
        end
        if roles.include?(PBMonRoles::CLERIC)
          wishpass=false
          for i in pbParty(attacker.index)
            next if i.nil?
            if (i.hp.to_f)/(i.totalhp.to_f)<0.6 && (i.hp.to_f)/(i.totalhp.to_f)>0.3
              wishpass=true
            end
          end
          score*=1.3 if wishpass
        end
        if skill>=PBTrainerAI.bestSkill
          if $fefieldeffect==3 || $fefieldeffect==9 || $fefieldeffect==29 ||
             $fefieldeffect==31 || $fefieldeffect==34 # Misty/Rainbow/Holy/Fairytale/Starlight
            score*=1.5
          end
        end
        if attacker.effects[PBEffects::Wish]>0
          score=0
        end
      when 0xD8 # Synthesis
        if aimem.length > 0 && skill>=PBTrainerAI.bestSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if maxdam>attacker.hp
            if maxdam>(attacker.hp*1.5)
              score=0
            else
              score*=5
            #experimental -- cancels out drop if killing moves
              if initialscores.length>0
                score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
              end
              #end experimental
            end
          else
            if maxdam*1.5>attacker.hp
              score*=2
            end
            if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              if maxdam*2>attacker.hp
                score*=5
                #experimental -- cancels out drop if killing moves
                if initialscores.length>0
                  score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
                end
                #end experimental
              end
            end
          end
        elsif skill>=PBTrainerAI.bestSkill #no highest expected damage yet
          if ((attacker.hp.to_f)/attacker.totalhp)<0.5
            score*=3
            if ((attacker.hp.to_f)/attacker.totalhp)<0.25
              score*=3
            end
            #experimental -- cancels out drop if killing moves
            if initialscores.length>0
              score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
            end
            #end experimental
          end
        elsif skill>=PBTrainerAI.mediumSkill
          score*=3 if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
        end
        score*=0.7 if opponent.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
        if (attacker.hp.to_f)/attacker.totalhp<0.5
          score*=1.5
          if attacker.effects[PBEffects::Curse]
            score*=2
          end
          if attacker.hp*4<attacker.totalhp
            if attacker.status==PBStatuses::POISON
              score*=1.5
            end
            if attacker.effects[PBEffects::LeechSeed]>=0
              score*=2
            end
            if attacker.hp<attacker.totalhp*0.13
              if attacker.status==PBStatuses::BURN
                score*=2
              end
              if (pbWeather==PBWeather::HAIL && !attacker.pbHasType?(:ICE)) ||
                 (pbWeather==PBWeather::SANDSTORM && !attacker.pbHasType?(:ROCK) && !attacker.pbHasType?(:GROUND) && !attacker.pbHasType?(:STEEL))
                score*=2
              end
            end
          end
        else
          score*=0.9
        end
        if attacker.effects[PBEffects::Toxic]>0
          score*=0.5
          if attacker.effects[PBEffects::Toxic]>4
            score*=0.5
          end
        end
        if attacker.status==PBStatuses::PARALYSIS ||
           attacker.effects[PBEffects::Attract]>=0 ||
           attacker.effects[PBEffects::Confusion]>0
          score*=1.1
        end
        if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN ||
           opponent.effects[PBEffects::LeechSeed]>=0 || opponent.effects[PBEffects::Curse]
          score*=1.3
          if opponent.effects[PBEffects::Toxic]>0
            score*=1.3
          end
        end
        score*=1.3 if checkAImoves(PBStuff::CONTRARYBAITMOVE,aimem)
        if opponent.vanished || opponent.effects[PBEffects::HyperBeam]>0
          score*=1.2
        end
        if pbWeather==PBWeather::SUNNYDAY
          score*=1.3
        elsif pbWeather==PBWeather::SANDSTORM || pbWeather==PBWeather::RAINDANCE || pbWeather==PBWeather::HAIL
          score*=0.5
        end
        if skill>=PBTrainerAI.bestSkill
          if move.id==(PBMoves::MOONLIGHT)
            if $fefieldeffect==4 || $fefieldeffect==34 || $fefieldeffect==35  # Dark Crystal/Starlight/New World
              score*=1.3
            end
          else
            if $fefieldeffect==4
              score*=0.5
            end
          end
        end
        if ((attacker.hp.to_f)/attacker.totalhp)>0.8
          score=0
        elsif ((attacker.hp.to_f)/attacker.totalhp)>0.6
          score*=0.6
        elsif ((attacker.hp.to_f)/attacker.totalhp)<0.25
          score*=2
        end
        if attacker.effects[PBEffects::Wish]>0
            score=0
        end
      when 0xD9 # Rest
        if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
          score*=3
        else
          if skill>=PBTrainerAI.bestSkill
            if checkAIdamage(aimem,attacker,opponent,skill)*1.5>attacker.hp
              score*=1.5
            end
            if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              if checkAIdamage(aimem,attacker,opponent,skill)*2>attacker.hp
                score*=2
              end
            end
          end
        end
        if (attacker.hp.to_f)/attacker.totalhp<0.5
          score*=1.5
        else
          score*=0.5
        end
        if (roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL))
          score*=1.2
        end
        if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN ||
           opponent.effects[PBEffects::LeechSeed]>=0 || opponent.effects[PBEffects::Curse]
          score*=1.3
          if opponent.effects[PBEffects::Toxic]>0
            score*=1.3
          end
        end
        if attacker.status==PBStatuses::POISON
          score*=1.3
          if opponent.effects[PBEffects::Toxic]>0
            score*=1.3
          end
        end
        if attacker.status==PBStatuses::BURN
          score*=1.3
          if attacker.spatk<attacker.attack
            score*=1.5
          end
        end
        if attacker.status==PBStatuses::PARALYSIS
          score*=1.3
        end
        score*=1.3 if checkAImoves(PBStuff::CONTRARYBAITMOVE,aimem)
        if attacker.hp*(1.0/attacker.totalhp)>=0.8
          score*=0
        end
        if !((attitemworks && attacker.item == PBItems::LUMBERRY) ||
           (attitemworks && attacker.item == PBItems::CHESTOBERRY) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::HYDRATION) && (pbWeather==PBWeather::RAINDANCE ||
           $fefieldeffect==21 || $fefieldeffect==22)))
          score*=0.8
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if maxdam*2 > attacker.totalhp
            score*=0.4
          else
            if maxdam*3 < attacker.totalhp
              score*=1.3
              #experimental -- cancels out drop if killing moves
              if initialscores.length>0
                score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
              end
              #end experimental
            end
          end
          if checkAImoves([PBMoves::WAKEUPSLAP,PBMoves::NIGHTMARE,PBMoves::DREAMEATER],aimem) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::BADDREAMS)
            score*=0.7
          end
          if attacker.pbHasMove?(:SLEEPTALK)
            score*=1.3
          end
          if attacker.pbHasMove?(:SNORE)
            score*=1.2
          end
          if !attacker.abilitynulled && (attacker.ability == PBAbilities::SHEDSKIN ||
             attacker.ability == PBAbilities::EARLYBIRD)
            score*=1.1
          end
          if @doublebattle
            score*=0.8
          end
        else
          if attitemworks && (attacker.item == PBItems::LUMBERRY ||
             attacker.item == PBItems::CHESTOBERRY)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::HARVEST)
              score*=1.2
            else
              score*=0.8
            end
          end
        end
        if attacker.status!=0
          score*=1.4
          if attacker.effects[PBEffects::Toxic]>0
            score*=1.2
          end
        end
        if !attacker.pbCanSleep?(false,true,true)
          score*=0
        end
      when 0xDA # Aqua Ring
        if !attacker.effects[PBEffects::AquaRing]
          if attacker.hp*(1.0/attacker.totalhp)>0.75
            score*=1.2
          end
          if attacker.hp*(1.0/attacker.totalhp)<0.50
            score*=0.7
            if attacker.hp*(1.0/attacker.totalhp)<0.33
              score*=0.5
            end
          end
          if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::RAINDISH) && pbWeather==PBWeather::RAINDANCE) ||
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::ICEBODY) && pbWeather==PBWeather::HAIL) ||
             attacker.effects[PBEffects::Ingrain] ||
             ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON)) ||
             $fefieldeffect==2
            score*=1.2
          end
          if attacker.moves.any? {|moveloop| (PBStuff::PROTECTMOVE).include?(moveloop)}
            score*=1.2
          end
          if attacker.moves.any? {|moveloop| (PBStuff::PIVOTMOVE).include?(moveloop)}
            score*=0.8
          end
          if checkAIdamage(aimem,attacker,opponent,skill)*5 < attacker.totalhp && (aimem.length > 0)
            score*=1.2
          elsif checkAIdamage(aimem,attacker,opponent,skill) > attacker.totalhp*0.4
            score*=0.3
          end
          if (roles.include?(PBMonRoles::PHYSICALWALL) ||
             roles.include?(PBMonRoles::SPECIALWALL) ||
             roles.include?(PBMonRoles::TANK))
            score*=1.2
          end
          score*=0.3 if checkAImoves(PBStuff::SWITCHOUTMOVE,aimem)
          if @doublebattle
            score*=0.5
          end
          if $fefieldeffect==3 || $fefieldeffect==8 || $fefieldeffect==21 || $fefieldeffect==22
            score*=1.3
          end
          if $fefieldeffect==7
            score*=1.3
          end
          if $fefieldeffect==11
            score*=0.3
          end
        else
          score*=0
        end
      when 0xDB # Ingrain
        if !attacker.effects[PBEffects::Ingrain]
          if attacker.hp*(1.0/attacker.totalhp)>0.75
            score*=1.2
          end
          if attacker.hp*(1.0/attacker.totalhp)<0.50
            score*=0.7
            if attacker.hp*(1.0/attacker.totalhp)<0.33
              score*=0.5
            end
          end
          if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::RAINDISH) && pbWeather==PBWeather::RAINDANCE) ||
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::ICEBODY) && pbWeather==PBWeather::HAIL) ||
             attacker.effects[PBEffects::AquaRing] ||
             ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON)) ||
             $fefieldeffect==2
            score*=1.2
          end
          if attacker.moves.any? {|moveloop| (PBStuff::PROTECTMOVE).include?(moveloop)}
            score*=1.2
          end
          if attacker.moves.any? {|moveloop| (PBStuff::PIVOTMOVE).include?(moveloop)}
            score*=0.8
          end
          if checkAIdamage(aimem,attacker,opponent,skill)*5 < attacker.totalhp && (aimem.length > 0)
            score*=1.2
          elsif checkAIdamage(aimem,attacker,opponent,skill) > attacker.totalhp*0.4
            score*=0.3
          end
          if (roles.include?(PBMonRoles::PHYSICALWALL) ||
             roles.include?(PBMonRoles::SPECIALWALL) ||
             roles.include?(PBMonRoles::TANK))
            score*=1.2
          end

          score*=0.3 if checkAImoves(PBStuff::SWITCHOUTMOVE,aimem)
          if @doublebattle
            score*=0.5
          end
          if $fefieldeffect==15 || $fefieldeffect==33
            score*=1.3
            if $fefieldeffect==33 && $fecounter>3
              score*=1.3
            end
          end
          if $fefieldeffect==8
            score*=0.1 unless (attacker.pbHasType?(:POISON) || attacker.pbHasType?(:STEEL))
          end
          if $fefieldeffect==10
            score*=0.1
          end
        else
          score*=0
        end
      when 0xDC # Leech Seed
        if opponent.effects[PBEffects::LeechSeed]<0 && ! opponent.pbHasType?(:GRASS) &&
           opponent.effects[PBEffects::Substitute]<=0
          if (roles.include?(PBMonRoles::PHYSICALWALL) ||
             roles.include?(PBMonRoles::SPECIALWALL) ||
             roles.include?(PBMonRoles::TANK))
            score*=1.2
          end
          if attacker.effects[PBEffects::Substitute]>0
            score*=1.3
          end
          if opponent.hp==opponent.totalhp
            score*=1.1
          else
            score*=(opponent.hp*(1.0/opponent.totalhp))
          end
          if (oppitemworks && opponent.item == PBItems::LEFTOVERS) ||
             (oppitemworks && opponent.item == PBItems::BIGROOT) ||
             ((oppitemworks && opponent.item == PBItems::BLACKSLUDGE) && opponent.pbHasType?(:POISON))
            score*=1.2
          end
          if opponent.status==PBStatuses::PARALYSIS || opponent.status==PBStatuses::SLEEP
            score*=1.2
          end
          if opponent.effects[PBEffects::Confusion]>0
            score*=1.2
          end
          if opponent.effects[PBEffects::Attract]>=0
            score*=1.2
          end
          if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN
            score*=1.1
          end
          score*=0.2 if checkAImoves([PBMoves::RAPIDSPIN,PBMoves::UTURN,PBMoves::VOLTSWITCH],aimem)
          if opponent.hp*2<opponent.totalhp
            score*=0.8
            if opponent.hp*4<opponent.totalhp
              score*=0.2
            end
          end
          protectmove=false
          for j in attacker.moves
            protectmove = true if j.id==(PBMoves::PROTECT) || j.id==(PBMoves::DETECT) ||
                                  j.id==(PBMoves::BANEFULBUNKER) || j.id==(PBMoves::SPIKYSHIELD)
          end
          if protectmove
            score*=1.2
          end
          ministat= (5)* statchangecounter(opponent,1,7,1)
          ministat+=100
          ministat/=100.0
          score*=ministat
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::LIQUIDOOZE) ||
             opponent.effects[PBEffects::Substitute]>0
            score*=0
          end
        else
          score*=0
        end
      when 0xDD # Drain Punch
        minimini = score*0.01
        miniscore = (opponent.hp*minimini)/2.0
        if miniscore > (attacker.totalhp-attacker.hp)
          miniscore = (attacker.totalhp-attacker.hp)
        end
        if attacker.totalhp>0
          miniscore/=(attacker.totalhp).to_f
        end
        if (attitemworks && attacker.item == PBItems::BIGROOT)
          miniscore*=1.3
        end
        miniscore *= 0.5 #arbitrary multiplier to make it value the HP less
        miniscore+=1
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::LIQUIDOOZE)
          miniscore = (2-miniscore)
        end
        if (attacker.hp!=attacker.totalhp ||
           ((attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0))) &&
           opponent.effects[PBEffects::Substitute]==0
          score*=miniscore
        end
        ghostvar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:GHOST)
            ghostvar=true
          end
        end
        if move.id==(PBMoves::PARABOLICCHARGE)
          if $fefieldeffect==18
            score*=1.1
            if ghostvar
              score*=0.8
            end
          end
        end
      when 0xDE # Dream Eater
        if opponent.status==PBStatuses::SLEEP
          minimini = score*0.01
          miniscore = (opponent.hp*minimini)/2.0
          if miniscore > (attacker.totalhp-attacker.hp)
            miniscore = (attacker.totalhp-attacker.hp)
          end
          if attacker.totalhp>0
            miniscore/=(attacker.totalhp).to_f
          end
          if (attitemworks && attacker.item == PBItems::BIGROOT)
            miniscore*=1.3
          end
          miniscore+=1
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::LIQUIDOOZE)
            miniscore = (2-miniscore)
          end
          if (attacker.hp!=attacker.totalhp ||
             ((attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0))) &&
             opponent.effects[PBEffects::Substitute]==0
            score*=miniscore
          end
        else
          score*=0
        end
      when 0xDF # Heal Pulse
        if !@doublebattle || attacker.pbIsOpposing?(opponent.index)
          score*=0
        else
          if !attacker.pbIsOpposing?(opponent.index)
            if opponent.hp*(1.0/opponent.totalhp)<0.7 && opponent.hp*(1.0/opponent.totalhp)>0.3
              score*=3
            elsif opponent.hp*(1.0/opponent.totalhp)<0.3
              score*=1.7
            end
            if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN ||
               opponent.effects[PBEffects::LeechSeed]>=0 || opponent.effects[PBEffects::Curse]
              score*=0.8
              if opponent.effects[PBEffects::Toxic]>0
                score*=0.7
              end
            end
            if opponent.hp*(1.0/opponent.totalhp)>0.8
              if ((attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) &&
                 ((attacker.pbSpeed<pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0))
                score*=0.5
              else
                score*=0
              end
            end
          else
            score*=0
          end
        end
      when 0xE0 # Explosion
        score*=0.7
        if attacker.hp==attacker.totalhp
          score*=0.2
        else
          miniscore = attacker.hp*(1.0/attacker.totalhp)
          miniscore = 1-miniscore
          score*=miniscore
          if attacker.hp*4<attacker.totalhp
            score*=1.3
            if (attitemworks && attacker.item == PBItems::CUSTAPBERRY)
              score*=1.4
            end
          end
        end
        if roles.include?(PBMonRoles::LEAD)
          score*=1.2
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::DISGUISE) ||
           opponent.effects[PBEffects::Substitute]>0
          score*=0.3
        end
        score*=0.3 if checkAImoves(PBStuff::PROTECTMOVE,aimem)
        firevar=false
        poisonvar=false
        ghostvar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:FIRE)
            firevar=true
          end
          if mon.hasType?(:POISON)
            poisonvar=true
          end
          if mon.hasType?(:GHOST)
            ghostvar=true
          end
        end
        if $fefieldeffect==16
          if pbWeather!=PBWeather::RAINDANCE && @field.effects[PBEffects::WaterSport]==0
            if firevar
              score*=2
            else
              score*=0.5
            end
          end
        elsif $fefieldeffect==11
          if !poisonvar
            score*=1.5
          else
            score*=0.5
          end
        elsif $fefieldeffect==24
          score*=1.5
        elsif $fefieldeffect==17
          score*=1.1
          if ghostvar
            score*=1.3
          end
        end
        if $fefieldeffect==3 || $fefieldeffect==8 || pbCheckGlobalAbility(:DAMP)
          score*=0
        end
      when 0xE1 # Final Gambit
        score*=0.7
        if attacker.hp > opponent.hp
          score*=1.1
        else
          score*=0.5
        end
        if (attacker.pbSpeed>pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=1.1
        else
          score*=0.5
        end
        if (oppitemworks && opponent.item == PBItems::FOCUSSASH) || (!opponent.abilitynulled && opponent.ability == PBAbilities::STURDY)
          score*=0.2
        end
      when 0xE2 # Memento
        if initialscores.length>0
          score = 15 if hasbadmoves(initialscores,scoreindex,10)
        end
        if attacker.hp==attacker.totalhp
          score*=0.2
        else
          miniscore = attacker.hp*(1.0/attacker.totalhp)
          miniscore = 1-miniscore
          score*=miniscore
          if attacker.hp*4<attacker.totalhp
            score*=1.3
          end
        end
        if opponent.attack > opponent.spatk
          if opponent.stages[PBStats::ATTACK]<-1
            score*=0.1
          end
        else
          if opponent.stages[PBStats::SPATK]<-1
            score*=0.1
          end
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::CLEARBODY) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::WHITESMOKE)
          score*=0
        end
      when 0xE3 # Healing Wish
        count=0
        for mon in pbParty(opponent.index)
          next if mon.nil?
          count+=1 if mon.hp!=mon.totalhp
        end
        count-=1 if attacker.hp!=attacker.totalhp
        if count==0
          score*=0
        else
          maxscore = 0
          for mon in pbParty(opponent.index)
            next if mon.nil?
            if mon.hp!=mon.totalhp
              miniscore = 1 - mon.hp*(1.0/mon.totalhp)
              miniscore*=2 if mon.status!=0
              maxscore=miniscore if miniscore>maxscore
            end
          end
          score*=maxscore
        end
        if attacker.hp==attacker.totalhp
          score*=0.2
        else
          miniscore = attacker.hp*(1.0/attacker.totalhp)
          miniscore = 1-miniscore
          score*=miniscore
          if attacker.hp*4<attacker.totalhp
            score*=1.3
            if (attitemworks && attacker.item == PBItems::CUSTAPBERRY)
              score*=1.4
            end
          end
        end
        if (attacker.pbSpeed>pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=1.1
        else
          score*=0.5
        end
        if $fefieldeffect==31 || $fefieldeffect==34
          score*=1.4
        end
      when 0xE4 # Lunar Dance
        count=0
        for mon in pbParty(opponent.index)
          next if mon.nil?
          count+=1 if mon.hp!=mon.totalhp
        end
        count-=1 if attacker.hp!=attacker.totalhp
        if count==0
          score*=0
        else
          maxscore = 0
          score*=1.2
          for mon in pbParty(opponent.index)
            next if mon.nil?
            if mon.hp!=mon.totalhp
              miniscore = 1 - mon.hp*(1.0/mon.totalhp)
              miniscore*=2 if mon.status!=0
              maxscore=miniscore if miniscore>maxscore
            end
          end
          score*=maxscore
        end
        if attacker.hp==attacker.totalhp
          score*=0.2
        else
          miniscore = attacker.hp*(1.0/attacker.totalhp)
          miniscore = 1-miniscore
          score*=miniscore
          if attacker.hp*4<attacker.totalhp
            score*=1.3
            if (attitemworks && attacker.item == PBItems::CUSTAPBERRY)
              score*=1.4
            end
          end
        end
        if (attacker.pbSpeed>pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=1.1
        else
          score*=0.5
        end
        if $fefieldeffect==31 || $fefieldeffect==34
          score*=1.4
        elsif $fefieldeffect==35
          score*=2
        end
      when 0xE5 # Perish Song
        livecount1=0
        for i in pbParty(opponent.index)
          next if i.nil?
          livecount1+=1 if i.hp!=0
        end
        livecount2=0
        for i in pbParty(attacker.index)
          next if i.nil?
          livecount2+=1 if i.hp!=0
        end
        if livecount1==1 || (livecount1==2 && @doublebattle)
          score*=4
        else
          if attacker.pbHasMove?(:UTURN) || attacker.pbHasMove?(:VOLTSWITCH)
            score*=1.5
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::SHADOWTAG) || opponent.effects[PBEffects::MeanLook]>0
            score*=3
          end
          if attacker.pbHasMove?(:PROTECT)
            score*=1.2
          end
          count = -1
          sweepvar = false
          for i in pbParty(attacker.index)
            count+=1
            next if i.nil?
            temprole = pbGetMonRole(i,opponent,skill,count,pbParty(attacker.index))
            if temprole.include?(PBMonRoles::SWEEPER)
              sweepvar = true
            end
          end
          score*=1.2 if sweepvar
          for j in attacker.moves
            if j.isHealingMove?
              score*=1.2
              break
            end
          end
          miniscore=(-5)*statchangecounter(attacker,1,7)
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
          miniscore= 5*statchangecounter(opponent,1,7)
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
          score*=0.5 if checkAImoves(PBStuff::PIVOTMOVE,aimem)
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SHADOWTAG) || attacker.effects[PBEffects::MeanLook]>0
            score*=0.1
          end
          count = -1
          pivotvar = false
          for i in pbParty(attacker.index)
            count+=1
            next if i.nil?
            temprole = pbGetMonRole(i,opponent,skill,count,pbParty(attacker.index))
            if temprole.include?(PBMonRoles::PIVOT)
              pivotvar = true
            end
          end
          score*=1.5 if pivotvar
          if livecount2==1 || (livecount2==2 && @doublebattle)
            score*=0
          end
        end
        score*=0 if opponent.effects[PBEffects::PerishSong]>0
      when 0xE6 # Grudge
        movenum = 0
        damcount =0
        if aimem.length > 0
          for j in aimem
            movenum+=1
            if j.basedamage>0
              damcount+=1
            end
          end
        end
        if movenum==4 && damcount==1
          score*=3
        end
        if attacker.hp==attacker.totalhp
          score*=0.2
        else
          miniscore = attacker.hp*(1.0/attacker.totalhp)
          miniscore = 1-miniscore
          score*=miniscore
          if attacker.hp*4<attacker.totalhp
            score*=1.3
            if (attitemworks && attacker.item == PBItems::CUSTAPBERRY)
              score*=1.3
            end
          end
        end
        if (attacker.pbSpeed>pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=1.3
        else
          score*=0.5
        end
      when 0xE7 # Destiny Bond
        movenum = 0
        damcount =0
        if aimem.length > 0
          for j in aimem
            movenum+=1
            if j.basedamage>0
              damcount+=1
            end
          end
        end
        if movenum==4 && damcount==4
          score*=3
        end
        if initialscores.length>0
          score*=0.1 if hasgreatmoves(initialscores,scoreindex,skill)
        end
        if attacker.hp==attacker.totalhp
          score*=0.2
        else
          miniscore = attacker.hp*(1.0/attacker.totalhp)
          miniscore = 1-miniscore
          score*=miniscore
          if attacker.hp*4<attacker.totalhp
            score*=1.3
            if (attitemworks && attacker.item == PBItems::CUSTAPBERRY)
              score*=1.5
            end
          end
        end
        if (attacker.pbSpeed>pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=1.5
        else
          score*=0.5
        end
        if attacker.effects[PBEffects::DestinyRate]>1
          score*=0
        end
      when 0xE8 # Endure
        if attacker.hp>1
          if attacker.hp==attacker.totalhp && ((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
             (!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY))
            score*=0
          end
          if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
            score*=2
          end
          if (attacker.pbSpeed>pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=1.3
          else
            score*=0.5
          end
          if (pbWeather==PBWeather::HAIL && !attacker.pbHasType?(:ICE)) ||
             (pbWeather==PBWeather::SANDSTORM && !(attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
            score*=0
          end
          if $fefieldeffect==7 || $fefieldeffect==26
            score*=0
          end
          if attacker.status==PBStatuses::POISON || attacker.status==PBStatuses::BURN ||
            attacker.effects[PBEffects::LeechSeed]>=0 || attacker.effects[PBEffects::Curse]
            score*=0
          end
          if attacker.pbHasMove?(:PAINSPLIT) ||
             attacker.pbHasMove?(:FLAIL) ||
             attacker.pbHasMove?(:REVERSAL)
            score*=2
          end
          if attacker.pbHasMove?(:ENDEAVOR)
            score*=3
          end
          if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN ||
             opponent.effects[PBEffects::LeechSeed]>=0 || opponent.effects[PBEffects::Curse]
            score*=1.5
          end
          if opponent.effects[PBEffects::TwoTurnAttack]!=0
            if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=15
            end
          end
        else
          score*=0
        end
      when 0xE9 # False Swipe
        if score>=100
          score*=0.1
        end
      when 0xEA # Teleport
        score*=0
      when 0xEB # Roar
        if opponent.pbOwnSide.effects[PBEffects::StealthRock]
          score*=1.3
        else
          score*=0.8
        end
        if opponent.pbOwnSide.effects[PBEffects::Spikes]>0
          score*=(1.2**opponent.pbOwnSide.effects[PBEffects::Spikes])
        else
          score*=0.8
        end
        if opponent.pbOwnSide.effects[PBEffects::ToxicSpikes]>0
          score*=1.1
        end
        ministat = 10*statchangecounter(opponent,1,7)
        ministat+=100
        ministat/=100.0
        score*=ministat
        if opponent.effects[PBEffects::PerishSong]>0 || opponent.effects[PBEffects::Yawn]>0
          score*=0
        end
        if opponent.status==PBStatuses::SLEEP
          score*=1.3
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::SLOWSTART)
          score*=1.3
        end
        if opponent.item ==0 && (!opponent.abilitynulled && opponent.ability == PBAbilities::UNBURDEN)
          score*=1.5
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::INTIMIDATE)
          score*=0.7
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::REGENERATOR) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::NATURALCURE)
          score*=0.5
        end
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=0.8
        end
        if attacker.effects[PBEffects::Substitute]>0
          score*=1.4
        end
        firevar=false
        poisonvar=false
        fairytvar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:FIRE)
            firevar=true
          end
          if mon.hasType?(:POISON)
            poisonvar=true
          end
          if mon.hasType?(:FAIRY)
            fairyvar=true
          end
        end
        if $fefieldeffect==3
          score*=1.3
          if !fairyvar
            score*=1.3
          else
            score*=0.8
          end
        elsif $fefielfeffect==7
          if !firevar
            score*=1.8
          else
            score*=0.5
          end
        elsif $fefieldeffect==11
          if !poisonvar
            score*=3
          else
            score*=0.8
          end
        end
        if opponent.effects[PBEffects::Ingrain] || (!opponent.abilitynulled &&
           opponent.ability == PBAbilities::SUCTIONCUPS) || opponent.pbNonActivePokemonCount==0
          score*=0
        end
      when 0xEC # Dragon Tail
        if opponent.effects[PBEffects::Substitute]<=0
          miniscore=1
          if opponent.pbOwnSide.effects[PBEffects::StealthRock]
            miniscore*=1.3
          else
            miniscore*=0.8
          end
          if opponent.pbOwnSide.effects[PBEffects::Spikes]>0
            miniscore*=(1.2**opponent.pbOwnSide.effects[PBEffects::Spikes])
          else
            miniscore*=0.8
          end
          if opponent.pbOwnSide.effects[PBEffects::ToxicSpikes]>0
            miniscore*=1.1
          end
          ministat = 10*statchangecounter(opponent,1,7)
          ministat+=100
          ministat/=100.0
          miniscore*=ministat
          if opponent.status==PBStatuses::SLEEP
            miniscore*=1.3
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SLOWSTART)
            miniscore*=1.3
          end
          if opponent.item ==0 && (!opponent.abilitynulled && opponent.ability == PBAbilities::UNBURDEN)
            miniscore*=1.5
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::INTIMIDATE)
            miniscore*=0.7
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::REGENERATOR) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::NATURALCURE)
            miniscore*=0.5
          end
          if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            miniscore*=0.8
          end
          if opponent.effects[PBEffects::PerishSong]>0 || opponent.effects[PBEffects::Yawn]>0
            miniscore=1
          end
          if attacker.effects[PBEffects::Substitute]>0
            miniscore=1
          end
          if opponent.effects[PBEffects::Ingrain] || (!opponent.abilitynulled &&
             opponent.ability == PBAbilities::SUCTIONCUPS) || opponent.pbNonActivePokemonCount==0
            miniscore=1
          end
          score*=miniscore
        end
      when 0xED # Baton Pass
        if pbCanChooseNonActive?(attacker.index)
          ministat = 10*statchangecounter(attacker,1,7)
          ministat+=100
          ministat/=100.0
          score*=ministat
          if attacker.effects[PBEffects::Substitute]>0
            score*=1.3
          end
          if attacker.effects[PBEffects::Confusion]>0
            score*=0.5
          end
          if attacker.effects[PBEffects::LeechSeed]>=0
            score*=0.5
          end
          if attacker.effects[PBEffects::Curse]
            score*=0.5
          end
          if attacker.effects[PBEffects::Yawn]>0
            score*=0.5
          end
          if attacker.turncount<1
            score*=0.5
          end
          damvar = false
          for i in attacker.moves
            if i.basedamage>0
              damvar=true
            end
          end
          if !damvar
            score*=1.3
          end
          if attacker.effects[PBEffects::Ingrain] || attacker.effects[PBEffects::AquaRing]
            score*=1.2
          end
          if attacker.effects[PBEffects::PerishSong]>0
            score*=0
          else
            if initialscores.length>0
              if damvar
                if initialscores.max>30
                  score*=0.7
                  if initialscores.max>50
                    score*=0.3
                  end
                end
              end
            end
          end
        else
          score*=0
        end
      when 0xEE # U-Turn
        livecount=0
        for i in pbParty(attacker.index)
          next if i.nil?
          livecount+=1 if i.hp!=0
        end
        if livecount>1
          if livecount==2
            if $game_switches[1000]
              score*=0
            end
          end
          if initialscores.length>0
            greatmoves=false
            badmoves=true
            iffymoves=true
            for i in 0...initialscores.length
              next if i==scoreindex
              if initialscores[i]>=110
                greatmoves=true
              end
              if initialscores[i]>=25
                badmoves=false
              end
              if initialscores[i]>=50
                iffymoves=false
              end
            end
            score*=0.5 if greatmoves
            if badmoves == true
              score+=40
            elsif iffymoves == true
              score+=20
            end
          end
          if attacker.pbOwnSide.effects[PBEffects::StealthRock]
            score*=0.7
          end
          if attacker.pbOwnSide.effects[PBEffects::StickyWeb]
            score*=0.6
          end
          if attacker.pbOwnSide.effects[PBEffects::Spikes]>0
            score*=0.9**attacker.pbOwnSide.effects[PBEffects::Spikes]
          end
          if attacker.pbOwnSide.effects[PBEffects::ToxicSpikes]>0
            score*=0.9**attacker.pbOwnSide.effects[PBEffects::ToxicSpikes]
          end
          count = -1
          sweepvar = false
          for i in pbParty(attacker.index)
            count+=1
            next if i.nil?
            temprole = pbGetMonRole(i,opponent,skill,count,pbParty(attacker.index))
            if temprole.include?(PBMonRoles::SWEEPER)
              sweepvar = true
            end
          end
          if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=1.2
          else
            if sweepvar
              score*=1.2
            end
          end
          if roles.include?(PBMonRoles::LEAD)
            score*=1.2
          end
          if roles.include?(PBMonRoles::PIVOT)
            score*=1.1
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::REGENERATOR) &&
             ((attacker.hp.to_f)/attacker.totalhp)<0.75
            score*=1.2
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::REGENERATOR) &&
               ((attacker.hp.to_f)/attacker.totalhp)<0.5
              score*=1.2
            end
          end
          loweredstats=0
          loweredstats+=attacker.stages[PBStats::ATTACK] if attacker.stages[PBStats::ATTACK]<0
          loweredstats+=attacker.stages[PBStats::DEFENSE] if attacker.stages[PBStats::DEFENSE]<0
          loweredstats+=attacker.stages[PBStats::SPEED] if attacker.stages[PBStats::SPEED]<0
          loweredstats+=attacker.stages[PBStats::SPATK] if attacker.stages[PBStats::SPATK]<0
          loweredstats+=attacker.stages[PBStats::SPDEF] if attacker.stages[PBStats::SPDEF]<0
          loweredstats+=attacker.stages[PBStats::EVASION] if attacker.stages[PBStats::EVASION]<0
          miniscore= (-15)*loweredstats
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
          raisedstats=0
          raisedstats+=attacker.stages[PBStats::ATTACK] if attacker.stages[PBStats::ATTACK]>0
          raisedstats+=attacker.stages[PBStats::DEFENSE] if attacker.stages[PBStats::DEFENSE]>0
          raisedstats+=attacker.stages[PBStats::SPEED] if attacker.stages[PBStats::SPEED]>0
          raisedstats+=attacker.stages[PBStats::SPATK] if attacker.stages[PBStats::SPATK]>0
          raisedstats+=attacker.stages[PBStats::SPDEF] if attacker.stages[PBStats::SPDEF]>0
          raisedstats+=attacker.stages[PBStats::EVASION] if attacker.stages[PBStats::EVASION]>0
          miniscore= (-25)*raisedstats
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
          if attacker.effects[PBEffects::Toxic]>0 || attacker.effects[PBEffects::Attract]>-1 ||
             attacker.effects[PBEffects::Confusion]>0
            score*=1.3
          end
          if attacker.effects[PBEffects::LeechSeed]>-1
            score*=1.5
          end
        end
      when 0xEF # Mean Look
        if !(opponent.effects[PBEffects::MeanLook]>=0 || opponent.effects[PBEffects::Ingrain] ||
           opponent.pbHasType?(:GHOST)) && opponent.effects[PBEffects::Substitute]<=0
          score*=0.1 if checkAImoves(PBStuff::PIVOTMOVE,aimem)
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::RUNAWAY)
            score*=0.1
          end
          if attacker.pbHasMove?(:PERISHSONG)
            score*=1.5
          end
          if opponent.effects[PBEffects::PerishSong]>0
            score*=4
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::ARENATRAP) ||
             (!attacker.abilitynulled && attacker.ability == PBAbilities::SHADOWTAG)
            score*=0
          end
          if opponent.effects[PBEffects::Attract]>=0
            score*=1.3
          end
          if opponent.effects[PBEffects::LeechSeed]>=0
            score*=1.3
          end
          if opponent.effects[PBEffects::Curse]
            score*=1.5
          end
          miniscore*=0.7 if attacker.moves.any? {|moveloop| (PBStuff::SWITCHOUTMOVE).include?(moveloop)}
          ministat = (-5)*statchangecounter(opponent,1,7)
          ministat+=100
          ministat/=100.0
          score*=ministat
          if opponent.effects[PBEffects::Confusion]>0
            score*=1.1
          end
        else
          score*=0
        end
      when 0x0EF # Thousand Waves
        if !(opponent.effects[PBEffects::MeanLook]>=0 || opponent.effects[PBEffects::Ingrain] || opponent.pbHasType?(:GHOST)) && opponent.effects[PBEffects::Substitute]<=0
          score*=0.1 if checkAImoves(PBStuff::PIVOTMOVE,aimem)
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::RUNAWAY)
            score*=0.1
          end
          if attacker.pbHasMove?(:PERISHSONG)
            score*=1.5
          end
          if opponent.effects[PBEffects::PerishSong]>0
            score*=4
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::ARENATRAP) || (!attacker.abilitynulled && attacker.ability == PBAbilities::SHADOWTAG)
            score*=0
          end
          if opponent.effects[PBEffects::Attract]>=0
            score*=1.3
          end
          if opponent.effects[PBEffects::LeechSeed]>=0
            score*=1.3
          end
          if opponent.effects[PBEffects::Curse]
            score*=1.5
          end
          miniscore*=0.7 if attacker.moves.any? {|moveloop| (PBStuff::SWITCHOUTMOVE).include?(moveloop)}
          ministat=(-5)*statchangecounter(opponent,1,7)
          ministat+=100
          ministat/=100.0
          score*=ministat
          if opponent.effects[PBEffects::Confusion]>0
            score*=1.1
          end
        end
      when 0xF0 # Knock Off
        if !hasgreatmoves(initialscores,scoreindex,skill) && opponent.effects[PBEffects::Substitute]<=0
          if (!(!opponent.abilitynulled && opponent.ability == PBAbilities::STICKYHOLD) ||
             opponent.moldbroken) && opponent.item!=0 && !pbIsUnlosableItem(opponent,opponent.item)
            score*=1.1
            if oppitemworks
              if opponent.item == PBItems::LEFTOVERS || (opponent.item == PBItems::BLACKSLUDGE) &&
                 opponent.pbHasType?(:POISON)
                score*=1.2
              elsif opponent.item == PBItems::LIFEORB || opponent.item == PBItems::CHOICESCARF ||
                    opponent.item == PBItems::CHOICEBAND || opponent.item == PBItems::CHOICESPECS ||
                    opponent.item == PBItems::ASSAULTVEST
                score*=1.1
              end
            end
          end
        end
      when 0xF1 # Covet
        if (!(!opponent.abilitynulled && opponent.ability == PBAbilities::STICKYHOLD) ||
           opponent.moldbroken) && opponent.item!=0 && !pbIsUnlosableItem(opponent,opponent.item) &&
           attacker.item ==0 && opponent.effects[PBEffects::Substitute]<=0
          miniscore = 1.2
          case opponent.item
            when (PBItems::LEFTOVERS), (PBItems::LIFEORB), (PBItems::LUMBERRY), (PBItems::SITRUSBERRY)
              miniscore*=1.5
            when (PBItems::ASSAULTVEST), (PBItems::ROCKYHELMET), (PBItems::MAGICALSEED),
                 (PBItems::SYNTHETICSEED), (PBItems::TELLURICSEED), (PBItems::ELEMENTALSEED)
              miniscore*=1.3
            when (PBItems::FOCUSSASH), (PBItems::MUSCLEBAND), (PBItems::WISEGLASSES),
                 (PBItems::EXPERTBELT), (PBItems::WIDELENS)
              miniscore*=1.2
            when (PBItems::CHOICESCARF)
              if attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
                miniscore*=1.1
              end
            when (PBItems::CHOICEBAND)
              if attacker.attack>attacker.spatk
                miniscore*=1.1
              end
            when (PBItems::CHOICESPECS)
              if attacker.spatk>attacker.attack
                miniscore*=1.1
              end
            when (PBItems::BLACKSLUDGE)
              if attacker.pbHasType?(:POISON)
                miniscore*=1.5
              else
                miniscore*=0.5
              end
            when (PBItems::TOXICORB), (PBItems::FLAMEORB), (PBItems::LAGGINGTAIL),
                 (PBItems::IRONBALL), (PBItems::STICKYBARB)
              miniscore*=0.5
          end
          score*=miniscore
        end
      when 0xF2 # Trick
        statvar = false
        for m in opponent.moves
          if m.basedamage==0
            statvar=true
          end
        end
        if (!(!opponent.abilitynulled && opponent.ability == PBAbilities::STICKYHOLD) ||
            opponent.moldbroken) && opponent.effects[PBEffects::Substitute]<=0
          miniscore = 1
          minimini = 1
          if opponent.item!=0 && !pbIsUnlosableItem(opponent,opponent.item)
            miniscore*=1.2
            case opponent.item
              when (PBItems::LEFTOVERS), (PBItems::LIFEORB), (PBItems::LUMBERRY), (PBItems::SITRUSBERRY)
                miniscore*=1.5
              when (PBItems::ASSAULTVEST), (PBItems::ROCKYHELMET), (PBItems::MAGICALSEED),
                   (PBItems::SYNTHETICSEED), (PBItems::TELLURICSEED), (PBItems::ELEMENTALSEED)
                miniscore*=1.3
              when (PBItems::FOCUSSASH), (PBItems::MUSCLEBAND), (PBItems::WISEGLASSES),
                   (PBItems::EXPERTBELT), (PBItems::WIDELENS)
                miniscore*=1.2
              when (PBItems::CHOICESCARF)
                if ((attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0))
                  miniscore*=1.1
                end
              when (PBItems::CHOICEBAND)
                if attacker.attack>attacker.spatk
                  miniscore*=1.1
                end
              when (PBItems::CHOICESPECS)
                if attacker.spatk>attacker.attack
                  miniscore*=1.1
                end
              when (PBItems::BLACKSLUDGE)
                if attacker.pbHasType?(:POISON)
                  miniscore*=1.5
                else
                  miniscore*=0.5
                end
              when (PBItems::TOXICORB), (PBItems::FLAMEORB), (PBItems::LAGGINGTAIL),
                   (PBItems::IRONBALL), (PBItems::STICKYBARB)
                miniscore*=0.5
            end
          end
          if attacker.item!=0 && !pbIsUnlosableItem(attacker,attacker.item)
            minimini*=0.8
            case attacker.item
              when (PBItems::LEFTOVERS), (PBItems::LIFEORB), (PBItems::LUMBERRY), (PBItems::SITRUSBERRY)
                minimini*=0.5
              when (PBItems::ASSAULTVEST), (PBItems::ROCKYHELMET), (PBItems::MAGICALSEED),
                   (PBItems::SYNTHETICSEED), (PBItems::TELLURICSEED), (PBItems::ELEMENTALSEED)
                minimini*=0.7
              when (PBItems::FOCUSSASH), (PBItems::MUSCLEBAND), (PBItems::WISEGLASSES),
                   (PBItems::EXPERTBELT), (PBItems::WIDELENS)
                minimini*=0.8
              when (PBItems::CHOICESCARF)
                if ((attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0))
                  minimini*=1.5
                else
                  minimini*=0.9
                end
                if statvar
                  minimini*=1.3
                end
              when (PBItems::CHOICEBAND)
                if opponent.attack<opponent.spatk
                  minimini*=1.7
                end
                if attacker.attack>attacker.spatk
                  minimini*=0.8
                end
                if statvar
                  minimini*=1.3
                end
              when (PBItems::CHOICESPECS)
                if opponent.attack>opponent.spatk
                  minimini*=1.7
                end
                if attacker.attack<attacker.spatk
                  minimini*=0.8
                end
                if statvar
                  minimini*=1.3
                end
              when (PBItems::BLACKSLUDGE)
                if !attacker.pbHasType?(:POISON)
                  minimini*=1.5
                else
                  minimini*=0.5
                end
                if !opponent.pbHasType?(:POISON)
                  minimini*=1.3
                end
              when (PBItems::TOXICORB), (PBItems::FLAMEORB), (PBItems::LAGGINGTAIL),
                   (PBItems::IRONBALL), (PBItems::STICKYBARB)
                minimini*=1.5
            end
          end
          score*=(miniscore*minimini)
        else
          score*=0
        end
        if attacker.item ==opponent.item
          score*=0
        end
      when 0xF3 # Bestow
        if (!(!opponent.abilitynulled && opponent.ability == PBAbilities::STICKYHOLD) ||
           opponent.moldbroken) && attacker.item!=0 && opponent.item ==0 &&
           !pbIsUnlosableItem(attacker,attacker.item) && opponent.effects[PBEffects::Substitute]<=0
          case attacker.item
            when (PBItems::CHOICESPECS)
              if opponent.attack>opponent.spatk
                score+=35
              end
            when (PBItems::CHOICESCARF)
              if (opponent.pbSpeed>attacker.pbSpeed) ^ (@trickroom!=0)
                score+=25
              end
            when (PBItems::CHOICEBAND)
              if opponent.attack<opponent.spatk
                score+=35
              end
            when (PBItems::BLACKSLUDGE)
              if !attacker.pbHasType?(:POISON)
                score+=15
              end
              if !opponent.pbHasType?(:POISON)
                score+=15
              end
            when (PBItems::TOXICORB), (PBItems::FLAMEORB)
              score+=35
            when (PBItems::LAGGINGTAIL), (PBItems::IRONBALL)
              score+=20
            when (PBItems::STICKYBARB)
              score+=25
          end
        else
          score*=0
        end
      when 0xF4 # Bug Bite
        if opponent.effects[PBEffects::Substitute]==0 && pbIsBerry?(opponent.item)
          case opponent.item
            when (PBItems::LUMBERRY)
              score*=2 if attacker.stats!=0
            when (PBItems::SITRUSBERRY)
              score*=1.6 if attacker.hp*(1.0/attacker.totalhp)<0.66
            when (PBItems::LIECHIBERRY)
              score*=1.5 if attacker.attack>attacker.spatk
            when (PBItems::PETAYABERRY)
              score*=1.5 if attacker.spatk>attacker.attack
            when (PBItems::CUSTAPBERRY), (PBItems::SALACBERRY)
              score*=1.1
              score*=1.4 if ((attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0))
          end
        end
      when 0xF5 # Incinerate
        if (pbIsBerry?(opponent.item) || pbIsTypeGem?(opponent.item)) &&
           !(!opponent.abilitynulled && opponent.ability == PBAbilities::STICKYHOLD) &&
           opponent.effects[PBEffects::Substitute]<=0
          if pbIsBerry?(opponent.item) && opponent.item!=(PBItems::OCCABERRY)
            score*=1.2
          end
          if opponent.item ==(PBItems::LUMBERRY) || opponent.item ==(PBItems::SITRUSBERRY) ||
             opponent.item ==(PBItems::PETAYABERRY) || opponent.item ==(PBItems::LIECHIBERRY) ||
             opponent.item ==(PBItems::SALACBERRY) || opponent.item ==(PBItems::CUSTAPBERRY)
            score*=1.3
          end
          if pbIsTypeGem?(opponent.item)
            score*=1.4
          end
          firevar=false
          poisonvar=false
          bugvar=false
          grassvar=false
          icevar=false
          for mon in pbParty(attacker.index)
            next if mon.nil?
            if mon.hasType?(:FIRE)
              firevar=true
            end
            if mon.hasType?(:POISON)
              poisonvar=true
            end
            if mon.hasType?(:BUG)
              bugvar=true
            end
            if mon.hasType?(:GRASS)
              grassvar=true
            end
            if mon.hasType?(:ICE)
              icevar=true
            end
          end
          if $fefieldeffect==2 || $fefieldeffect==15 || ($fefieldeffect==33 && $fecounter>1)
            if firevar && !(bugvar || grassvar)
              score*=2
            end
          elsif $fefieldeffect==16
            if firevar
              score*=2
            end
          elsif $fefieldeffect==13 || $fefieldeffect==28
            if !icevar
              score*=1.5
            end
          end
        end
      when 0xF6 # Recycle
        if attacker.pokemon.itemRecycle!=0
          score*=2
          case attacker.pokemon.itemRecycle
            when (PBItems::LUMBERRY)
              score*=2 if attacker.stats!=0
            when (PBItems::SITRUSBERRY)
              score*=1.6 if attacker.hp*(1.0/attacker.totalhp)<0.66
              if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
                score*=1.5
              end
          end
          if pbIsBerry?(attacker.pokemon.itemRecycle)
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNNERVE)
              score*=0
            end
            score*=0 if checkAImoves([PBMoves::INCINERATE,PBMoves::PLUCK,PBMoves::BUGBITE],aimem)
          end
          score*=0 if (!opponent.abilitynulled && opponent.ability == PBAbilities::MAGICIAN) ||
                      checkAImoves([PBMoves::KNOCKOFF,PBMoves::THIEF,PBMoves::COVET],aimem)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::UNBURDEN) ||
             (!attacker.abilitynulled && attacker.ability == PBAbilities::HARVEST) ||
             attacker.pbHasMove?(:ACROBATICS)
            score*=0
          end
        else
          score*=0
        end
      when 0xF7 # Fling
        if attacker.item ==0 || pbIsUnlosableItem(attacker,attacker.item) ||
           (!attacker.abilitynulled && attacker.ability == PBAbilities::KLUTZ) ||
           (pbIsBerry?(attacker.item) && (!opponent.abilitynulled && opponent.ability == PBAbilities::UNNERVE)) ||
           attacker.effects[PBEffects::Embargo]>0 || @field.effects[PBEffects::MagicRoom]>0
          score*=0
        else
          case attacker.item
            when (PBItems::POISONBARB)
              if opponent.pbCanPoison?(false) && !(!opponent.abilitynulled && opponent.ability == PBAbilities::POISONHEAL)
                score*=1.2
              end
            when (PBItems::TOXICORB)
              if opponent.pbCanPoison?(false) && !(!opponent.abilitynulled && opponent.ability == PBAbilities::POISONHEAL)
                score*=1.2
                if attacker.pbCanPoison?(false) && !(!attacker.abilitynulled && attacker.ability == PBAbilities::POISONHEAL)
                  score*=2
                end
              end
            when (PBItems::FLAMEORB)
              if opponent.pbCanBurn?(false) && !(!opponent.abilitynulled && opponent.ability == PBAbilities::GUTS)
                score*=1.3
                if attacker.pbCanBurn?(false) && !(!attacker.abilitynulled && attacker.ability == PBAbilities::GUTS)
                  score*=2
                end
              end
            when (PBItems::LIGHTBALL)
              if opponent.pbCanParalyze?(false) && !(!opponent.abilitynulled && opponent.ability == PBAbilities::QUICKFEET)
                score*=1.3
              end
            when (PBItems::KINGSROCK), (PBItems::RAZORCLAW)
              if !(!opponent.abilitynulled && opponent.ability == PBAbilities::INNERFOCUS) && ((attacker.pbSpeed>opponent.pbSpeed) ^ (@trickroom!=0))
                score*=1.3
              end
            when (PBItems::POWERHERB)
              score*=0
            when (PBItems::MENTALHERB)
              score*=0
            when (PBItems::LAXINCENSE), (PBItems::CHOICESCARF), (PBItems::CHOICEBAND),
                 (PBItems::CHOICESPECS), (PBItems::SYNTHETICSEED), (PBItems::TELLURICSEED),
                 (PBItems::ELEMENTALSEED), (PBItems::MAGICALSEED), (PBItems::EXPERTBELT),
                 (PBItems::FOCUSSASH), (PBItems::LEFTOVERS), (PBItems::MUSCLEBAND),
                 (PBItems::WISEGLASSES), (PBItems::LIFEORB), (PBItems::EVIOLITE),
                 (PBItems::ASSAULTVEST), (PBItems::BLACKSLUDGE)
              score*=0
            when (PBItems::STICKYBARB)
              score*=1.2
            when (PBItems::LAGGINGTAIL)
              score*=3
            when (PBItems::IRONBALL)
              score*=1.5
          end
          if pbIsBerry?(attacker.item)
            if attacker.item ==(PBItems::FIGYBERRY) || attacker.item ==(PBItems::WIKIBERRY) ||
               attacker.item ==(PBItems::MAGOBERRY) || attacker.item ==(PBItems::AGUAVBERRY) ||
               attacker.item ==(PBItems::IAPAPABERRY)
              if opponent.pbCanConfuse?(false)
                score*=1.3
              end
            else
              score*=0
            end
          end
        end
      when 0xF8 # Embargo
        startscore = score
        if opponent.effects[PBEffects::Embargo]>0  && opponent.effects[PBEffects::Substitute]>0
          score*=0
        else
          if opponent.item!=0
            score*=1.1
            if pbIsBerry?(opponent.item)
              score*=1.1
            end
            case opponent.item
              when (PBItems::LAXINCENSE), (PBItems::SYNTHETICSEED), (PBItems::TELLURICSEED),
                   (PBItems::ELEMENTALSEED), (PBItems::MAGICALSEED), (PBItems::EXPERTBELT),
                   (PBItems::MUSCLEBAND), (PBItems::WISEGLASSES), (PBItems::LIFEORB),
                   (PBItems::EVIOLITE), (PBItems::ASSAULTVEST)
                score*=1.2
              when (PBItems::LEFTOVERS), (PBItems::BLACKSLUDGE)
                score*=1.3
            end
            if opponent.hp*2<opponent.totalhp
              score*=1.4
            end
          end
          if score==startscore
            score*=0
          end
        end
      when 0xF9 # Magic Room
        if @field.effects[PBEffects::MagicRoom]>0
          score*=0
        else
          if (attitemworks && attacker.item == PBItems::AMPLIFIELDROCK) || $fefieldeffect==35 || $fefieldeffect==37
            score*=1.3
          end
          if opponent.item!=0
            score*=1.1
            if pbIsBerry?(opponent.item)
              score*=1.1
            end
            case opponent.item
              when (PBItems::LAXINCENSE), (PBItems::SYNTHETICSEED), (PBItems::TELLURICSEED),
                   (PBItems::ELEMENTALSEED), (PBItems::MAGICALSEED), (PBItems::EXPERTBELT),
                   (PBItems::MUSCLEBAND), (PBItems::WISEGLASSES), (PBItems::LIFEORB),
                   (PBItems::EVIOLITE), (PBItems::ASSAULTVEST)
                score*=1.2
              when (PBItems::LEFTOVERS), (PBItems::BLACKSLUDGE)
                score*=1.3
            end
          end
          if attacker.item!=0
            score*=0.8
            if pbIsBerry?(opponent.item)
              score*=0.8
            end
            case opponent.item
              when (PBItems::LAXINCENSE), (PBItems::SYNTHETICSEED), (PBItems::TELLURICSEED),
                   (PBItems::ELEMENTALSEED), (PBItems::MAGICALSEED), (PBItems::EXPERTBELT),
                   (PBItems::MUSCLEBAND), (PBItems::WISEGLASSES), (PBItems::LIFEORB),
                   (PBItems::EVIOLITE), (PBItems::ASSAULTVEST)
                score*=0.6
              when (PBItems::LEFTOVERS), (PBItems::BLACKSLUDGE)
                score*=0.4
            end
          end
        end
      when 0xFA # Take Down
        if !(!attacker.abilitynulled && attacker.ability == PBAbilities::ROCKHEAD)
          score*=0.9
          if attacker.hp==attacker.totalhp && ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) ||
             (attitemworks && attacker.item == PBItems::FOCUSSASH))
            score*=0.7
          end
          if attacker.hp*(1.0/attacker.totalhp)>0.1 && attacker.hp*(1.0/attacker.totalhp)<0.4
            score*=0.8
          end
        end
        ghostvar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:GHOST)
            ghostvar=true
          end
        end
        if move.id==(PBMoves::WILDCHARGE)
          if $fefieldeffect==18
            score*=1.1
            if ghostvar
              score*=0.8
            end
          end
        end
      when 0xFB # Wood Hammer
        if !(!attacker.abilitynulled && attacker.ability == PBAbilities::ROCKHEAD)
          score*=0.9
          if attacker.hp==attacker.totalhp && ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) ||
             (attitemworks && attacker.item == PBItems::FOCUSSASH))
            score*=0.7
          end
          if attacker.hp*(1.0/attacker.totalhp)>0.15 && attacker.hp*(1.0/attacker.totalhp)<0.4
            score*=0.8
          end
        end
      when 0xFC # Head Smash
        if !(!attacker.abilitynulled && attacker.ability == PBAbilities::ROCKHEAD)
          score*=0.9
          if attacker.hp==attacker.totalhp && ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) ||
             (attitemworks && attacker.item == PBItems::FOCUSSASH))
            score*=0.7
          end
          if attacker.hp*(1.0/attacker.totalhp)>0.2 && attacker.hp*(1.0/attacker.totalhp)<0.4
            score*=0.8
          end
        end
      when 0xFD # Volt Tackle
        if !(!attacker.abilitynulled && attacker.ability == PBAbilities::ROCKHEAD)
          score*=0.9
          if attacker.hp==attacker.totalhp && ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) ||
             (attitemworks && attacker.item == PBItems::FOCUSSASH))
            score*=0.7
          end
          if attacker.hp*(1.0/attacker.totalhp)>0.15 && attacker.hp*(1.0/attacker.totalhp)<0.4
            score*=0.8
          end
        end
        if opponent.pbCanParalyze?(false)
          miniscore=100
          miniscore*=1.1
          miniscore*=1.3 if attacker.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
          if opponent.hp==opponent.totalhp
            miniscore*=1.2
          end
          ministat=0
          ministat+=opponent.stages[PBStats::ATTACK]
          ministat+=opponent.stages[PBStats::SPATK]
          ministat+=opponent.stages[PBStats::SPEED]
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::NATURALCURE)
            miniscore*=0.3
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::MARVELSCALE)
            miniscore*=0.5
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::QUICKFEET) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::GUTS)
            miniscore*=0.2
          end
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL) || roles.include?(PBMonRoles::PIVOT)
            miniscore*=1.2
          end
          if roles.include?(PBMonRoles::TANK)
            miniscore*=1.5
          end
          if pbRoughStat(opponent,PBStats::SPEED,skill)>attacker.pbSpeed &&
             (pbRoughStat(opponent,PBStats::SPEED,skill)/2)<attacker.pbSpeed && @trickroom==0
            miniscore*=1.5
          end
          if pbRoughStat(opponent,PBStats::SPATK,skill)>pbRoughStat(opponent,PBStats::ATTACK,skill)
            miniscore*=1.3
          end
          count = -1
          sweepvar = false
          for i in pbParty(attacker.index)
            count+=1
            next if i.nil?
            temprole = pbGetMonRole(i,opponent,skill,count,pbParty(attacker.index))
            if temprole.include?(PBMonRoles::SWEEPER)
              sweepvar = true
            end
          end
          miniscore*=1.3 if sweepvar
          if opponent.effects[PBEffects::Confusion]>0
            miniscore*=1.1
          end
          if opponent.effects[PBEffects::Attract]>=0
            miniscore*=1.1
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=0.4
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SHEDSKIN)
            miniscore*=0.7
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SYNCHRONIZE) &&
             attacker.status==0 && !attacker.pbHasType?(:ELECTRIC) && !attacker.pbHasType?(:GROUND)
            miniscore*=0.5
          end
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
        end
      when 0xFE # Flare Blitz
        if !(!attacker.abilitynulled && attacker.ability == PBAbilities::ROCKHEAD)
          score*=0.9
          if attacker.hp==attacker.totalhp &&
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) ||
             (attitemworks && attacker.item == PBItems::FOCUSSASH))
            score*=0.7
          end
          if attacker.hp*(1.0/attacker.totalhp)>0.2 && attacker.hp*(1.0/attacker.totalhp)<0.4
            score*=0.8
          end
        end
        if opponent.pbCanBurn?(false)
          miniscore=100
          miniscore*=1.2
          ministat=0
          ministat+=opponent.stages[PBStats::ATTACK]
          ministat+=opponent.stages[PBStats::SPATK]
          ministat+=opponent.stages[PBStats::SPEED]
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::NATURALCURE)
            miniscore*=0.3
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::MARVELSCALE)
            miniscore*=0.7
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::QUICKFEET) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::FLAREBOOST) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::MAGICGUARD)
            miniscore*=0.3
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::GUTS)
            miniscore*=0.1
          end
          miniscore*=0.3 if checkAImoves([PBMoves::FACADE],aimem)
          miniscore*=0.1 if checkAImoves([PBMoves::REST],aimem)
          if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
            miniscore*=1.7
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=0.4
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SYNCHRONIZE) && attacker.status==0
            miniscore*=0.5
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SHEDSKIN)
            miniscore*=0.7
          end
          if move.basedamage>0
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::STURDY)
              miniscore*=1.1
            end
          end
          miniscore-=100
          if move.addlEffect.to_f != 100
            miniscore*=(move.addlEffect.to_f/100)
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SERENEGRACE)
              miniscore*=2
            end
          end
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
        end
      when 0xFF # Sunny Day
        if pbCheckGlobalAbility(:AIRLOCK) ||
          pbCheckGlobalAbility(:CLOUDNINE) ||
          pbCheckGlobalAbility(:DELTASTREAM) ||
          pbCheckGlobalAbility(:DESOLATELAND) ||
          pbCheckGlobalAbility(:PRIMORDIALSEA) ||
          pbWeather==PBWeather::SUNNYDAY
          score*=0
        end
        if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          score*=1.3
        end
        if roles.include?(PBMonRoles::LEAD)
          score*=1.2
        end
        if (attitemworks && attacker.item == PBItems::HEATROCK)
          score*=1.3
        end
        if attacker.pbHasMove?(:WEATHERBALL) || (!attacker.abilitynulled && attacker.ability == PBAbilities::FORECAST)
          score*=2
        end
        if pbWeather!=0 && pbWeather!=PBWeather::SUNNYDAY
          score*=1.5
        end
        if attacker.pbHasMove?(:MOONLIGHT) || attacker.pbHasMove?(:SYNTHESIS) ||
           attacker.pbHasMove?(:MORNINGSUN) || attacker.pbHasMove?(:GROWTH) ||
           attacker.pbHasMove?(:SOLARBEAM) || attacker.pbHasMove?(:SOLARBLADE)
          score*=1.5
        end
        if attacker.pbHasType?(:FIRE)
          score*=1.5
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CHLOROPHYLL) ||
           (!attacker.abilitynulled && attacker.ability == PBAbilities::FLOWERGIFT)
          score*=2
          if (attitemworks && attacker.item == PBItems::FOCUSSASH)
            score*=2
          end
          if attacker.effects[PBEffects::KingsShield]== true ||
          attacker.effects[PBEffects::BanefulBunker]== true ||
          attacker.effects[PBEffects::SpikyShield]== true
            score *=3
          end
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::SOLARPOWER) ||
           (!attacker.abilitynulled && attacker.ability == PBAbilities::LEAFGUARD)
          score*=1.3
        end
        watervar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:WATER)
            watervar=true
          end
        end
        if watervar
          score*=0.5
        end
        if attacker.pbHasMove?(:THUNDER) || attacker.pbHasMove?(:HURRICANE)
          score*=0.7
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::DRYSKIN)
          score*=0.5
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::HARVEST)
          score*=1.5
        end
        if pbWeather==PBWeather::RAINDANCE
          miniscore = getFieldDisruptScore(attacker,opponent,skill)
          if attacker.pbHasType?(:NORMAL)
            miniscore*=1.2
          end
          score*=miniscore
        end
        if skill>=PBTrainerAI.bestSkill
          if $fefieldeffect==12 || $fefieldeffect==27 || $fefieldeffect==28 # Desert/Mountian/Snowy Mountain
            score*=1.3
          end
          if $fefieldeffect==33 # Flower Garden
            score*=2
          end
          if $fefieldeffect==4 # Dark Crystal
            darkvar=false
            for mon in pbParty(attacker.index)
              next if mon.nil?
              if mon.hasType?(:DARK)
                darkvar=true
              end
            end
            if !darkvar
              score*=3
            end
          end
          if $fefieldeffect==22 || $fefieldeffect==35 # Underwater or New World
            score*=0
          end
        end
      when 0x100 # Rain Dance
        if pbCheckGlobalAbility(:AIRLOCK) ||
          pbCheckGlobalAbility(:CLOUDNINE) ||
          pbCheckGlobalAbility(:DELTASTREAM) ||
          pbCheckGlobalAbility(:DESOLATELAND) ||
          pbCheckGlobalAbility(:PRIMORDIALSEA) ||
          pbWeather==PBWeather::RAINDANCE
          score*=0
        end
        if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          score*=1.3
        end
        if roles.include?(PBMonRoles::LEAD)
          score*=1.2
        end
        if (attitemworks && attacker.item == PBItems::DAMPROCK)
          score*=1.3
        end
        if attacker.pbHasMove?(:WEATHERBALL) || (!attacker.abilitynulled && attacker.ability == PBAbilities::FORECAST)
          score*=2
        end
        if pbWeather!=0 && pbWeather!=PBWeather::RAINDANCE
          score*=1.3
        end
        if attacker.pbHasMove?(:THUNDER) || attacker.pbHasMove?(:HURRICANE)
          score*=1.5
        end
        if attacker.pbHasType?(:WATER)
          score*=1.5
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::SWIFTSWIM)
          score*=2
          if (attitemworks && attacker.item == PBItems::FOCUSSASH)
            score*=2
          end
          if attacker.effects[PBEffects::KingsShield]== true ||
          attacker.effects[PBEffects::BanefulBunker]== true ||
          attacker.effects[PBEffects::SpikyShield]== true
            score *=3
          end
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::DRYSKIN) || pbWeather==PBWeather::RAINDANCE
          score*=1.5
        end
        if pbWeather==PBWeather::SUNNYDAY
          miniscore = getFieldDisruptScore(attacker,opponent,skill)
          if attacker.pbHasType?(:NORMAL)
            miniscore*=1.2
          end
          score*=miniscore
        end
        firevar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:FIRE)
            firevar=true
          end
        end
        if firevar
          score*=0.5
        end
        if attacker.pbHasMove?(:MOONLIGHT) || attacker.pbHasMove?(:SYNTHESIS) ||
           attacker.pbHasMove?(:MORNINGSUN) || attacker.pbHasMove?(:GROWTH) ||
           attacker.pbHasMove?(:SOLARBEAM) || attacker.pbHasMove?(:SOLARBLADE)
          score*=0.5
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::HYDRATION)
          score*=1.5
        end
        if @opponent.is_a?(Array) == false
          if (@opponent.trainertype==PBTrainers::SHELLY || @opponent.trainertype==PBTrainers::BENNETTLAURA) && # Shelly / Laura
          ($fefieldeffect == 2 || $fefieldeffect == 15 || $fefieldeffect == 33)
            score *= 3.5
            #experimental -- cancels out drop if killing moves
            if initialscores.length>0
              score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
            end
            #end experimental
          end
        end
        if skill>=PBTrainerAI.bestSkill
          if $fefieldeffect==6 # Big Top
            score*=1.2
          end
          if $fefieldeffect==2 || $fefieldeffect==15 || $fefieldeffect==16 # Grassy/Forest/Superheated
            score*=1.5
          end
          if $fefieldeffect==7 || $fefieldeffect==33 # Burning/Flower Garden
            score*=2
          end
          if $fefieldeffect==34 # Starlight
            darkvar=false
            fairyvar=false
            psychicvar=false
            for mon in pbParty(attacker.index)
              next if mon.nil?
              if mon.hasType?(:DARK)
                darkvar=true
              end
              if mon.hasType?(:FAIRY)
                fairyvar=true
              end
              if mon.hasType?(:PSYCHIC)
                psychicvar=true
              end
            end
            if !darkvar && !fairyvar && !psychicvar
              score*=2
            end
          end
          if $fefieldeffect==22 || $fefieldeffect==35 # Underwater or New World
            score*=0
          end
        end
      when 0x101 # Sandstorm
        if pbCheckGlobalAbility(:AIRLOCK) ||
          pbCheckGlobalAbility(:CLOUDNINE) ||
          pbCheckGlobalAbility(:DELTASTREAM) ||
          pbCheckGlobalAbility(:DESOLATELAND) ||
          pbCheckGlobalAbility(:PRIMORDIALSEA) ||
          pbWeather==PBWeather::SANDSTORM
          score*=0
        end
        if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          score*=1.3
        end
        if roles.include?(PBMonRoles::LEAD)
          score*=1.2
        end
        if (attitemworks && attacker.item == PBItems::SMOOTHROCK)
          score*=1.3
        end
        if attacker.pbHasMove?(:WEATHERBALL) || (!attacker.abilitynulled && attacker.ability == PBAbilities::FORECAST)
          score*=2
        end
        if pbWeather!=0 && pbWeather!=PBWeather::SANDSTORM
          score*=2
        end
        if attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)
          score*=1.3
        else
          score*=0.7
        end
        if attacker.pbHasType?(:ROCK)
          score*=1.5
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::SANDRUSH)
          score*=2
          if (attitemworks && attacker.item == PBItems::FOCUSSASH)
            score*=2
          end
          if attacker.effects[PBEffects::KingsShield]== true ||
          attacker.effects[PBEffects::BanefulBunker]== true ||
          attacker.effects[PBEffects::SpikyShield]== true
            score *=3
          end
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::SANDVEIL)
          score*=1.3
        end
        if attacker.pbHasMove?(:MOONLIGHT) || attacker.pbHasMove?(:SYNTHESIS) ||
           attacker.pbHasMove?(:MORNINGSUN) || attacker.pbHasMove?(:GROWTH) ||
           attacker.pbHasMove?(:SOLARBEAM) || attacker.pbHasMove?(:SOLARBLADE)
          score*=0.5
        end
        if attacker.pbHasMove?(:SHOREUP)
          score*=1.5
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::SANDFORCE)
          score*=1.5
        end
        if skill>=PBTrainerAI.bestSkill
          if $fefieldeffect==20 || $fefieldeffect==12 # Ashen Beach/Desert
            score*=1.3
          end
          if $fefieldeffect==9 # Rainbow
            score*=1.5
          end
          if $fefieldeffect==7 # Burning
            score*=3
          end
          if $fefieldeffect==34 # Starlight
            darkvar=false
            fairyvar=false
            psychicvar=false
            for mon in pbParty(attacker.index)
              next if mon.nil?
              if mon.hasType?(:DARK)
                darkvar=true
              end
              if mon.hasType?(:FAIRY)
                fairyvar=true
              end
              if mon.hasType?(:PSYCHIC)
                psychicvar=true
              end
            end
            if !darkvar && !fairyvar && !psychicvar
              score*=2
            end
          end
          if $fefieldeffect==22 || $fefieldeffect==35 # Underwater or New World
            score*=0
          end
        end
      when 0x102 # Hail
        if pbCheckGlobalAbility(:AIRLOCK) ||
          pbCheckGlobalAbility(:CLOUDNINE) ||
          pbCheckGlobalAbility(:DELTASTREAM) ||
          pbCheckGlobalAbility(:DESOLATELAND) ||
          pbCheckGlobalAbility(:PRIMORDIALSEA) ||
          pbWeather==PBWeather::HAIL
          score*=0
        end
        if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
           ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
           (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
           (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
          score*=1.3
        end
        if roles.include?(PBMonRoles::LEAD)
          score*=1.2
        end
        if (attitemworks && attacker.item == PBItems::ICYROCK)
          score*=1.3
        end
        if attacker.pbHasMove?(:WEATHERBALL) || (!attacker.abilitynulled && attacker.ability == PBAbilities::FORECAST)
          score*=2
        end
        if pbWeather!=0 && pbWeather!=PBWeather::HAIL
          score*=1.3
        end
        if attacker.pbHasType?(:ICE)
          score*=5
        else
          score*=0.7
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::SLUSHRUSH)
          score*=2
          if (attitemworks && attacker.item == PBItems::FOCUSSASH)
            score*=2
          end
          if attacker.effects[PBEffects::KingsShield]== true ||
          attacker.effects[PBEffects::BanefulBunker]== true ||
          attacker.effects[PBEffects::SpikyShield]== true
            score *=3
          end
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::SNOWCLOAK) ||
           (!attacker.abilitynulled && attacker.ability == PBAbilities::ICEBODY)
          score*=1.3
        end
        if attacker.pbHasMove?(:MOONLIGHT) || attacker.pbHasMove?(:SYNTHESIS) ||
           attacker.pbHasMove?(:MORNINGSUN) || attacker.pbHasMove?(:GROWTH) ||
           attacker.pbHasMove?(:SOLARBEAM) || attacker.pbHasMove?(:SOLARBLADE)
          score*=0.5
        end
        if attacker.pbHasMove?(:AURORAVEIL)
          score*=2
        end
        if attacker.pbHasMove?(:BLIZZARD)
          score*=1.3
        end
        if skill>=PBTrainerAI.bestSkill
          if $fefieldeffect==13 || $fefieldeffect==28 # Icy/Snowy Mountain
            score*=1.2
          end
          if $fefieldeffect==9 || $fefieldeffect==27 # Rainbow/Mountian
            score*=1.5
          end
          if $fefieldeffect==16 # Superheated
            score*=0
          end
          if $fefieldeffect==34 # Starlight
            darkvar=false
            fairyvar=false
            psychicvar=false
            for mon in pbParty(attacker.index)
              next if mon.nil?
              if mon.hasType?(:DARK)
                darkvar=true
              end
              if mon.hasType?(:FAIRY)
                fairyvar=true
              end
              if mon.hasType?(:PSYCHIC)
                psychicvar=true
              end
            end
            if !darkvar && !fairyvar && !psychicvar
              score*=2
            end
          end
          if $fefieldeffect==22 || $fefieldeffect==35 # Underwater or New World
            score*=0
          end
        end
      when 0x103 # Spikes
        if attacker.pbOpposingSide.effects[PBEffects::Spikes]!=3
          if roles.include?(PBMonRoles::LEAD)
            score*=1.1
          end
          if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
             (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
             (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
            score*=1.1
          end
          if attacker.turncount<2
            score*=1.2
          end
          livecount1=0
          for i in pbParty(opponent.index)
            next if i.nil?
            livecount1+=1 if i.hp!=0
          end
          livecount2=0
          for i in pbParty(attacker.index)
            next if i.nil?
            livecount2+=1 if i.hp!=0
          end
          if livecount1>3
            miniscore=(livecount1-1)
            miniscore*=0.2
            score*=miniscore
          else
            score*=0.1
          end
          if attacker.pbOpposingSide.effects[PBEffects::Spikes]>0
            score*=0.9
          end
          if skill>=PBTrainerAI.bestSkill
            for k in 0...pbParty(opponent.index).length
              next if pbParty(opponent.index)[k].nil?
              if @aiMoveMemory[2][k].length>0
                movecheck=false
                for j in @aiMoveMemory[2][k]
                  movecheck=true if j.id==(PBMoves::DEFOG) || j.id==(PBMoves::RAPIDSPIN)
                end
                score*=0.3 if movecheck
              end
            end
          elsif skill>=PBTrainerAI.mediumSkill
            score*=0.3 if checkAImoves([PBMoves::DEFOG,PBMoves::RAPIDSPIN],aimem)
          end
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==21 || $fefieldeffect==26 # (Murk)Water Surface
              score*=0
            end
          end
        else
          score*=0
        end
        if skill>=PBTrainerAI.bestSkill
          if $fefieldeffect==19 # Wasteland
            score = ((opponent.totalhp/3.0)/opponent.hp)*100
            score*=1.5 if @doublebattle
          end
        end
      when 0x104 # Toxic Spikes
        if attacker.pbOpposingSide.effects[PBEffects::ToxicSpikes]!=2
          if roles.include?(PBMonRoles::LEAD)
            score*=1.1
          end
          if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
             (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
             (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
            score*=1.1
          end
          if attacker.turncount<2
            score*=1.2
          end
          livecount1=0
          for i in pbParty(opponent.index)
            next if i.nil?
            livecount1+=1 if i.hp!=0
          end
          livecount2=0
          for i in pbParty(attacker.index)
            next if i.nil?
            livecount2+=1 if i.hp!=0
          end
          if livecount1>3
            miniscore=(livecount1-1)
            miniscore*=0.2
            score*=miniscore
          else
            score*=0.1
          end
          if attacker.pbOpposingSide.effects[PBEffects::ToxicSpikes]>0
            score*=0.9
          end
          if skill>=PBTrainerAI.bestSkill
            for k in 0...pbParty(opponent.index).length
              next if pbParty(opponent.index)[k].nil?
              if @aiMoveMemory[2][k].length>0
                movecheck=false
                for j in @aiMoveMemory[2][k]
                  movecheck=true if j.id==(PBMoves::DEFOG) || j.id==(PBMoves::RAPIDSPIN)
                end
                score*=0.3 if movecheck
              end
            end
          elsif skill>=PBTrainerAI.mediumSkill
            score*=0.3 if checkAImoves([PBMoves::DEFOG,PBMoves::RAPIDSPIN],aimem)
          end
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==21 || $fefieldeffect==26 # (Murk)Water Surface
              score*=0
            end
            if $fefieldeffect==10 # Corrosive
              score*=1.2
            end
          end
        else
          score*=0
        end
        if skill>=PBTrainerAI.bestSkill
          if $fefieldeffect==19 # Wasteland
            score = ((opponent.totalhp*0.13)/opponent.hp)*100
            if opponent.pbCanPoison?(false)
              score*=1.5
            else
              score*=0
            end
            score*=1.5 if @doublebattle
            if opponent.hasType?(:POISON)
              score*=0
            end
          end
        end
      when 0x105 # Stealth Rock
        if !attacker.pbOpposingSide.effects[PBEffects::StealthRock]
          if roles.include?(PBMonRoles::LEAD)
            score*=1.1
          end
          if attacker.hp==attacker.totalhp &&
             (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
             (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
             (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
            score*=1.4
          end
          if attacker.turncount<2
            score*=1.3
          end
          livecount1=0
          for i in pbParty(opponent.index)
            next if i.nil?
            livecount1+=1 if i.hp!=0
          end
          livecount2=0
          for i in pbParty(attacker.index)
            next if i.nil?
            livecount2+=1 if i.hp!=0
          end
          if livecount1>3
            miniscore=(livecount1-1)
            miniscore*=0.2
            score*=miniscore
          else
            score*=0.1
          end
          if skill>=PBTrainerAI.bestSkill
            for k in 0...pbParty(opponent.index).length
              next if pbParty(opponent.index)[k].nil?
              if @aiMoveMemory[2][k].length>0
                movecheck=false
                for j in @aiMoveMemory[2][k]
                  movecheck=true if j.id==(PBMoves::DEFOG) || j.id==(PBMoves::RAPIDSPIN)
                end
                score*=0.3 if movecheck
              end
            end
          elsif skill>=PBTrainerAI.mediumSkill
            score*=0.3 if checkAImoves([PBMoves::DEFOG,PBMoves::RAPIDSPIN],aimem)
          end
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect==23 || $fefieldeffect==14 # Cave/Rocky
              score*=2
            end
            if $fefieldeffect==25 # Crystal Cavern
              score*=1.3
            end
          end
        else
          score*=0
        end
        if skill>=PBTrainerAI.bestSkill
          if $fefieldeffect==19 # Wasteland
            atype=(PBTypes::ROCK)
            score = ((opponent.totalhp/4.0)/opponent.hp)*100
            score*=2 if pbTypeModNoMessages(atype,attacker,opponent,move,skill)>4
            score*=1.5 if @doublebattle
          end
        end
      when 0x106 # Grass Pledge
        if $fepledgefield != 3
          miniscore = getFieldDisruptScore(attacker,opponent,skill)
          if $fepledgefield!=1 && $fepledgefield!=2
            miniscore*=0.7
          else
            firevar=false
            for mon in pbParty(attacker.index)
              next if mon.nil?
              if mon.hasType?(:FIRE)
                firevar=true
              end
            end
            if $fepledgefield==1
              if attacker.pbHasType?(:FIRE)
                miniscore*=1.4
              else
                miniscore*=0.3
              end
              if opponent.pbHasType?(:FIRE)
                miniscore*=0.3
              else
                miniscore*=1.4
              end
              if firevar
                miniscore*=1.4
              else
                miniscore*=1.3
              end
            end
          end
          score*=miniscore
        end
      when 0x107 # Fire Pledge
        firevar=false
        poisonvar=false
        bugvar=false
        grassvar=false
        icevar=false
        poisonvar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:FIRE)
            firevar=true
          end
          if mon.hasType?(:POISON)
            poisonvar=true
          end
          if mon.hasType?(:BUG)
            bugvar=true
          end
          if mon.hasType?(:GRASS)
            grassvar=true
          end
          if mon.hasType?(:ICE)
            icevar=true
          end
          if mon.hasType?(:POISON)
            poisonvar=true
          end
        end
        if $fepledgefield != 1
          miniscore = getFieldDisruptScore(attacker,opponent,skill)
          if $fepledgefield!=3 && $fepledgefield!=2
            miniscore*=0.7
          else
            if $fepledgefield==3
              if attacker.pbHasType?(:FIRE)
                miniscore*=1.4
              else
                miniscore*=0.3
              end
              if opponent.pbHasType?(:FIRE)
                miniscore*=0.3
              else
                miniscore*=1.4
              end
              if firevar
                miniscore*=1.4
              else
                miniscore*=1.3
              end
            end
            if $fepledgefield==2
              miniscore*=1.2
              if attacker.pbHasType?(:NORMAL)
                miniscore*=1.2
              end
            end
          end
          score*=miniscore
        end
        if $fefieldeffect==2 || $fefieldeffect==15 || ($fefieldeffect==33 && $fecounter>1)
          if firevar && !(bugvar || grassvar)
            score*=2
          end
        elsif $fefieldeffect==16
          if firevar
            score*=2
          end
        elsif $fefieldeffect==11
          if !poisonvar
            score*=1.1
          end
          if attacker.hp*5<attacker.totalhp
            score*=2
          end
          if opponent.pbNonActivePokemonCount==0
            score*=5
          end
        elsif $fefieldeffect==13 || $fefieldeffect==28
          if !icevar
            score*=1.5
          end
        end
      when 0x108 # Water Pledge
        if $fepledgefield != 2
          miniscore = getFieldDisruptScore(attacker,opponent,skill)
          if $fepledgefield!=1 && $fepledgefield!=3
            miniscore*=0.7
          else
            firevar=false
            for mon in pbParty(attacker.index)
              next if mon.nil?
              if mon.hasType?(:FIRE)
                firevar=true
              end
            end
            if $fepledgefield==1
              miniscore*=1.2
              if attacker.pbHasType?(:NORMAL)
                miniscore*=1.2
              end
            end
          end
          score*=miniscore
        end
        if $fefieldeffect==7
          if firevar
            score*=0
          else
            score*=2
          end
        end
      when 0x109 # Pay Day
      when 0x10A # Brick Break
        if attacker.pbOpposingSide.effects[PBEffects::Reflect]>0
          score*=1.8
        end
        if attacker.pbOpposingSide.effects[PBEffects::LightScreen]>0
          score*=1.3
        end
        if attacker.pbOpposingSide.effects[PBEffects::AuroraVeil]>0
          score*=2.0
        end
      when 0x10B # Hi Jump Kick
        if score < 100
          score *= 0.8
        end
        score*=0.5 if checkAImoves(PBStuff::PROTECTMOVE,aimem)
        ministat=opponent.stages[PBStats::EVASION]
        ministat*=(-10)
        ministat+=100
        ministat/=100.0
        score*=ministat
        ministat=attacker.stages[PBStats::ACCURACY]
        ministat*=(10)
        ministat+=100
        ministat/=100.0
        score*=ministat
        if ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) || ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL)
          score*=0.7
        end
        if (oppitemworks && opponent.item == PBItems::LAXINCENSE) || (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER)
          score*=0.7
        end
        if attacker.index != 2
          if skill>=PBTrainerAI.bestSkill
            if $fefieldeffect!=36
              ghostvar = false
              for mon in pbParty(opponent.index)
                next if mon.nil?
                ghostvar=true if mon.hasType?(:GHOST)
              end
              if ghostvar
                score*=0.5
              end
            end
          end
        end
      when 0x10C # Substitute
        if attacker.hp*4>attacker.totalhp
          if attacker.effects[PBEffects::Substitute]>0
            if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=0
            else
              if opponent.effects[PBEffects::LeechSeed]<0
                score*=0
              end
            end
          else
            if attacker.hp==attacker.totalhp
              score*=1.1
            else
              score*= (attacker.hp*(1.0/attacker.totalhp))
            end
            if opponent.effects[PBEffects::LeechSeed]>=0
              score*=1.2
            end
            if (attitemworks && attacker.item == PBItems::LEFTOVERS)
              score*=1.2
            end
            for j in attacker.moves
              if j.isHealingMove?
                score*=1.2
                break
              end
            end
            if opponent.pbHasMove?(:SPORE) || opponent.pbHasMove?(:SLEEPPOWDER)
              score*=1.2
            end
            if attacker.pbHasMove?(:FOCUSPUNCH)
              score*=1.5
            end
            if opponent.status==PBStatuses::SLEEP
              score*=1.5
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::INFILTRATOR)
              score*=0.3
            end
            if opponent.pbHasMove?(:UPROAR) || opponent.pbHasMove?(:HYPERVOICE) ||
               opponent.pbHasMove?(:ECHOEDVOICE) || opponent.pbHasMove?(:SNARL) ||
               opponent.pbHasMove?(:BUGBUZZ) || opponent.pbHasMove?(:BOOMBURST)
              score*=0.3
            end
            score*=2 if checkAIdamage(aimem,attacker,opponent,skill)*4<attacker.totalhp && (aimem.length > 0)
            if opponent.effects[PBEffects::Confusion]>0
              score*=1.3
            end
            if opponent.status==PBStatuses::PARALYSIS
              score*=1.3
            end
            if opponent.effects[PBEffects::Attract]>=0
              score*=1.3
            end
            if attacker.pbHasMove?(:BATONPASS)
              score*=1.2
            end
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SPEEDBOOST)
              score*=1.1
            end
            if @doublebattle
              score*=0.5
            end
          end
        else
          score*=0
        end
      when 0x10D # Curse
        if attacker.pbHasType?(:GHOST)
          if opponent.effects[PBEffects::Curse] || attacker.hp*2<attacker.totalhp
            score*=0
          else
            score*=0.7
            if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=0.5
            end
            if checkAIdamage(aimem,attacker,opponent,skill)*5 < attacker.hp && (aimem.length > 0)
              score*=1.3
            end
            for j in attacker.moves
              if j.isHealingMove?
                score*=1.2
                break
              end
            end
            ministat= 5*statchangecounter(opponent,1,7)
            ministat+=100
            ministat/=100.0
            score*=ministat
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SHADOWTAG) ||
               (!attacker.abilitynulled && attacker.ability == PBAbilities::ARENATRAP) ||
               opponent.effects[PBEffects::MeanLook]>=0 ||  opponent.pbNonActivePokemonCount==0
              score*=1.3
            else
              score*=0.8
            end
            if @doublebattle
              score*=0.5
            end
            if initialscores.length>0
              score*=1.3 if hasbadmoves(initialscores,scoreindex,25)
            end
            if $fefieldeffect==29
              score*=0
            end
          end
        else
          miniscore=100
          if attacker.effects[PBEffects::Substitute]>0 || attacker.effects[PBEffects::Disguise]
            miniscore*=1.3
          end
          if initialscores.length>0
            miniscore*=1.3 if hasbadmoves(initialscores,scoreindex,20)
          end
          if (attacker.hp.to_f)/attacker.totalhp>0.75
            miniscore*=1.2
          end
          if (attacker.hp.to_f)/attacker.totalhp<0.33
            miniscore*=0.3
          end
          if (attacker.hp.to_f)/attacker.totalhp<0.75 &&
             ((!attacker.abilitynulled && attacker.ability == PBAbilities::EMERGENCYEXIT) ||
             (!attacker.abilitynulled && attacker.ability == PBAbilities::WIMPOUT) ||
             (attitemworks && attacker.item == PBItems::EJECTBUTTON))
            miniscore*=0.3
          end
          if attacker.pbOpposingSide.effects[PBEffects::Retaliate]
            miniscore*=0.3
          end
          if opponent.effects[PBEffects::HyperBeam]>0
            miniscore*=1.3
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=1.7
          end
          if checkAIdamage(aimem,attacker,opponent,skill)<(attacker.hp/4.0) && (aimem.length > 0)
            miniscore*=1.2
          elsif checkAIdamage(aimem,attacker,opponent,skill)>(attacker.hp/2.0)
            miniscore*=0.3
          end
          if attacker.turncount<2
            miniscore*=1.1
          end
          if opponent.status!=0
            miniscore*=1.2
          end
          if opponent.status==PBStatuses::SLEEP || opponent.status==PBStatuses::FROZEN
            miniscore*=1.3
          end
          if opponent.effects[PBEffects::Encore]>0
            if opponent.moves[(opponent.effects[PBEffects::EncoreIndex])].basedamage==0
              miniscore*=1.5
            end
          end
          if attacker.effects[PBEffects::Confusion]>0
            miniscore*=0.3
          end
          if attacker.effects[PBEffects::LeechSeed]>=0 || attacker.effects[PBEffects::Attract]>=0
            miniscore*=0.3
          end
          score*=0.3 if checkAImoves(PBStuff::SWITCHOUTMOVE,aimem)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::SIMPLE)
            miniscore*=2
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
            miniscore*=0.5
          end
          if @doublebattle
            miniscore*=0.5
          end
          if attacker.stages[PBStats::SPEED]<0
            ministat=attacker.stages[PBStats::SPEED]
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          ministat=0
          ministat+=opponent.stages[PBStats::ATTACK]
          ministat+=opponent.stages[PBStats::SPATK]
          ministat+=opponent.stages[PBStats::SPEED]
          if ministat>0
            minimini=(-5)*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          miniscore/=100.0
          score*=miniscore
          miniscore=100
          miniscore*=1.3 if checkAIhealing(aimem)
          if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
            miniscore*=0.5
          else
            miniscore*=1.1
          end
          if attacker.status==PBStatuses::BURN
            miniscore*=0.5
          end
          if attacker.status==PBStatuses::PARALYSIS
            miniscore*=0.5
          end
          miniscore*=0.8 if checkAImoves([PBMoves::FOULPLAY],aimem)
          physmove=false
          for j in attacker.moves
            if j.pbIsPhysical?(j.type)
              physmove=true
            end
          end
          if physmove && !attacker.pbTooHigh?(PBStats::ATTACK)
            miniscore/=100.0
            score*=miniscore
          end
          miniscore=100
          if attacker.effects[PBEffects::Toxic]>0
            miniscore*=0.2
          end
          if pbRoughStat(opponent,PBStats::SPATK,skill)<pbRoughStat(opponent,PBStats::ATTACK,skill)
            if !(roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL))
              if ((attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) && (attacker.hp.to_f)/attacker.totalhp>0.75
                miniscore*=1.3
              elsif (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
                miniscore*=0.7
              end
            end
            miniscore*=1.3
          end
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            miniscore*=1.1
          end
          if (attitemworks && attacker.item == PBItems::LEFTOVERS) || ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
            miniscore*=1.1
          end
          healmove=false
          for j in attacker.moves
            if j.isHealingMove?
              healmove=true
            end
          end
          if healmove
            miniscore*=1.2
          end
          if attacker.pbHasMove?(:LEECHSEED)
            miniscore*=1.3
          end
          if attacker.pbHasMove?(:PAINSPLIT)
            miniscore*=1.2
          end
          if !attacker.pbTooHigh?(PBStats::DEFENSE)
            miniscore/=100.0
            score*=miniscore
          end
          if (opponent.level-5)>attacker.level
            score*=0.6
            if (opponent.level-10)>attacker.level
              score*=0.2
            end
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            score=0
          end
          if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=0.7
          end
          if attacker.pbTooHigh?(PBStats::DEFENSE) && attacker.pbTooHigh?(PBStats::ATTACK)
            score *= 0
          end
        end
      when 0x10E # Spite
        count=0
        for i in opponent.moves
          if i.basedamage>0
            count+=1
          end
        end
        lastmove = PBMove.new(opponent.lastMoveUsed)
        if lastmove.basedamage>0 && count==1
          score+=10
        end
        if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=0.5
        end
        if lastmove.totalpp==5
          score*=1.5
        else
          if lastmove.totalpp==10
            score*=1.2
          else
            score*=0.7
          end
        end
      when 0x10F # Nightmare
        if !opponent.effects[PBEffects::Nightmare] && opponent.status==PBStatuses::SLEEP && opponent.effects[PBEffects::Substitute]<=0
          if opponent.statusCount>2
            score*=4
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::EARLYBIRD)
            score*=0.5
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::COMATOSE)
            score*=6
          end
          if initialscores.length>0
            score*=6 if hasbadmoves(initialscores,scoreindex,25)
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SHEDSKIN)
            score*=0.5
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::SHADOWTAG) ||
             (!attacker.abilitynulled && attacker.ability == PBAbilities::ARENATRAP) ||
             opponent.effects[PBEffects::MeanLook]>=0 ||  opponent.pbNonActivePokemonCount==0
            score*=1.3
          else
            score*=0.8
          end
          if @doublebattle
            score*=0.5
          end
          if $fefieldeffect==9
            score*=0
          end
        else
          score*=0
        end
      when 0x110 # Rapid Spin
        if attacker.effects[PBEffects::LeechSeed]>=0
          score+=20
        end
        if attacker.effects[PBEffects::MultiTurn]>0
          score+=10
        end
        if attacker.pbNonActivePokemonCount>0
          score+=25 if attacker.pbOwnSide.effects[PBEffects::StealthRock]
          score+=25 if attacker.pbOwnSide.effects[PBEffects::StickyWeb]
          score += (10*attacker.pbOwnSide.effects[PBEffects::Spikes])
          score += (15*attacker.pbOwnSide.effects[PBEffects::ToxicSpikes])
        end
      when 0x111 # Future Sight
        whichdummy = 0
        if move.id == 516
          whichdummy = 637
        elsif move.id == 450
          whichdummy = 636
        end
        dummydata = PBMove.new(whichdummy)
        dummymove = PokeBattle_Move.pbFromPBMove(self,dummydata,attacker)
        tempdam=pbRoughDamage(dummymove,attacker,opponent,skill,dummymove.basedamage)
        dummydam=(tempdam*100)/(opponent.hp.to_f)
        dummydam=110 if dummydam>110
        score = pbGetMoveScore(dummymove,attacker,opponent,skill,dummydam)
        if opponent.effects[PBEffects::FutureSight]>0
          score*=0
        else
          score*=0.6
          if @doublebattle
            score*=0.7
          end
          if attacker.pbNonActivePokemonCount==0
            score*=0.7
          end
          if attacker.effects[PBEffects::Substitute]>0
            score*=1.2
          end
          protectmove=false
          for j in attacker.moves
            protectmove = true if j.id==(PBMoves::PROTECT) || j.id==(PBMoves::DETECT) ||
                                  j.id==(PBMoves::BANEFULBUNKER) || j.id==(PBMoves::SPIKYSHIELD)
          end
          if protectmove
            score*=1.2
          end
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            score*=1.1
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::MOODY) ||
             attacker.pbHasMove?(:QUIVERDANCE) ||
             attacker.pbHasMove?(:NASTYPLOT) ||
             attacker.pbHasMove?(:TAILGLOW)
            score*=1.2
          end
        end
      when 0x112 # Stockpile
        miniscore=100
        if attacker.effects[PBEffects::Substitute]>0 || attacker.effects[PBEffects::Disguise]
          miniscore*=1.3
        end
        if initialscores.length>0
          miniscore*=1.3 if hasbadmoves(initialscores,scoreindex,20)
        end
        if (attacker.hp.to_f)/attacker.totalhp>0.75
          miniscore*=1.1
        end
        if opponent.effects[PBEffects::HyperBeam]>0
          miniscore*=1.2
        end
        if opponent.effects[PBEffects::Yawn]>0
          miniscore*=1.3
        end
        if skill>=PBTrainerAI.mediumSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if maxdam<(attacker.hp/4.0) && (aimem.length > 0)
            miniscore*=1.1
          else
            if move.basedamage==0
              miniscore*=0.8
              if maxdam>attacker.hp
                miniscore*=0.1
              end
            end
          end
        end
        if attacker.turncount<2
          miniscore*=1.1
        end
        if opponent.status!=0
          miniscore*=1.1
        end
        if opponent.status==PBStatuses::SLEEP || opponent.status==PBStatuses::FROZEN
          miniscore*=1.3
        end
        if opponent.effects[PBEffects::Encore]>0
          if opponent.moves[(opponent.effects[PBEffects::EncoreIndex])].basedamage==0
            miniscore*=1.5
          end
        end
        if attacker.effects[PBEffects::Confusion]>0
          miniscore*=0.5
        end
        if attacker.effects[PBEffects::LeechSeed]>=0 || attacker.effects[PBEffects::Attract]>=0
          miniscore*=0.3
        end
        if attacker.effects[PBEffects::Toxic]>0
          miniscore*=0.2
        end
        miniscore*=0.2 if checkAImoves(PBStuff::SWITCHOUTMOVE,aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::SIMPLE)
          miniscore*=2
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          miniscore*=0.5
        end
        if @doublebattle
          miniscore*=0.3
        end
        if skill>=PBTrainerAI.mediumSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if (maxdam.to_f/attacker.hp)<0.12 && (aimem.length > 0)
            miniscore*=0.3
          end
        end
        miniscore/=100.0
        score*=miniscore
        miniscore=100
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.5
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) || ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.2
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.7
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        if attacker.pbHasMove?(:SPITUP) || attacker.pbHasMove?(:SWALLOW)
          miniscore*=1.6
        end
        if attacker.effects[PBEffects::Stockpile]<3
          miniscore/=100.0
          score*=miniscore
        else
          score=0
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score=0
        end
        if attacker.pbTooHigh?(PBStats::SPDEF) && attacker.pbTooHigh?(PBStats::DEFENSE)
          score*=0
        end
      when 0x113 # Spit Up
        startscore = score
        if attacker.effects[PBEffects::Stockpile]==0
          score*=0
        else
          score*=0.8
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            score*=0.7
          end
          if roles.include?(PBMonRoles::TANK)
            score*=0.9
          end
          count=0
          for m in attacker.moves
            count+=1 if m.basedamage>0
          end
          if count>1
            score*=0.5
          end
          if opponent.pbNonActivePokemonCount==0
            score*=0.7
          else
            score*=1.2
          end
          if startscore < 110
            score*=0.5
          else
            score*=1.3
          end
          if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=1.1
          else
            score*=0.8
          end
          if attacker.pbHasMove?(:SWALLOW)
            if attacker.hp/(attacker.totalhp.to_f) < 0.66
              score*=0.8
              if attacker.hp/(attacker.totalhp.to_f) < 0.4
                score*=0.5
              end
            end
          end
        end
      when 0x114 # Swallow
        startscore = score
        if attacker.effects[PBEffects::Stockpile]==0
          score*=0
        else
          score+= 10*attacker.effects[PBEffects::Stockpile]
          score*=0.8
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            score*=0.9
          end
          if roles.include?(PBMonRoles::TANK)
            score*=0.9
          end
          count=0
          for m in attacker.moves
            count+=1 if m.isHealingMove?
          end
          if count>1
            score*=0.5
          end
          if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=1.1
          else
            score*=0.8
          end
          if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
            score*=2
          elsif checkAIdamage(aimem,attacker,opponent,skill)*1.5 > attacker.hp
            score*=1.5
          end
          if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            if checkAIdamage(aimem,attacker,opponent,skill)*2 > attacker.hp
              score*=2
            else
              score*=0.2
            end
          end
          score*=0.7 if checkAImoves(PBStuff::SETUPMOVE,aimem)
          if attacker.hp*2 < attacker.totalhp
            score*=1.5
          end
          if attacker.status==PBStatuses::BURN || attacker.status==PBStatuses::POISON || attacker.effects[PBEffects::Curse] || attacker.effects[PBEffects::LeechSeed]>=0
            score*=1.3
            if attacker.effects[PBEffects::Toxic]>0
              score*=1.3
            end
          end
          if opponent.effects[PBEffects::HyperBeam]>0
            score*=1.2
          end
          if attacker.hp/(attacker.totalhp.to_f) > 0.8
            score*=0
          end
        end
      when 0x115 # Focus Punch
        startscore=score
        soundcheck=false
        multicheck=false
        if aimem.length > 0
          for j in aimem
            soundcheck=true if (j.isSoundBased? && j.basedamage>0)
            multicheck=true if j.pbNumHits(opponent)>1
          end
        end
        if attacker.effects[PBEffects::Substitute]>0
          if multicheck || soundcheck || (!opponent.abilitynulled && opponent.ability == PBAbilities::INFILTRATOR)
            score*=0.9
          else
            score*=1.3
          end
        else
          score *= 0.8
        end
        if opponent.status==PBStatuses::SLEEP && !(!opponent.abilitynulled && opponent.ability == PBAbilities::EARLYBIRD) && !(!opponent.abilitynulled && opponent.ability == PBAbilities::SHEDSKIN)
          score*=1.2
        end
        if @doublebattle
          score *= 0.5
        end
        #if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) ^ @trickroom!=0
        #  score*=0.9
        #end
        if opponent.effects[PBEffects::HyperBeam]>0
          score*=1.5
        end
        if score<=startscore
          score*=0.3
        end
      when 0x116 # Sucker Punch
        knowncount = 0
        alldam = true
        if aimem.length > 0
          for j in aimem
            knowncount+=1
            if j.basedamage<=0
              alldam = false
            end
          end
        end
        if knowncount==4 && alldam
          score*=1.3
        else
          score*=0.6 if checkAIhealing(aimem)
          score*=0.8 if checkAImoves(PBStuff::SETUPMOVE,aimem)
          if attacker.lastMoveUsed==26 # Sucker Punch last turn
            check = rand(3)
            if check != 1
              score*=0.3
            end
            if checkAImoves(PBStuff::SETUPMOVE,aimem)
              score*=0.5
            end
          end
          if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=0.8
            if initialscores.length>0
              test = initialscores[scoreindex]
              if initialscores.max!=test
                score*=0.6
              end
            end
          else
            if checkAIpriority(aimem)
              score*=0.5
            else
              score*=1.3
            end
          end
        end
      when 0x117 # Follow Me
        if @doublebattle && attacker.pbPartner.hp!=0
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            score*=1.2
          end

          if (!attacker.pbPartner.abilitynulled && attacker.pbPartner.ability == PBAbilities::MOODY)
            score*=1.3
          end
          if attacker.pbPartner.turncount<1
            score*=1.2
          else
            score*=0.8
          end
          if attacker.hp==attacker.totalhp
            score*=1.2
          else
            score*=0.8
            if attacker.hp*2 < attacker.totalhp
              score*=0.5
            end
          end
          if attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill) || attacker.pbSpeed<pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)
            score*=1.2
          end
        else
          score*=0
        end
      when 0x118 # Gravity
        maxdam=0
        maxid = -1
        if aimem.length > 0
          for j in aimem
            tempdam = pbRoughDamage(j,opponent,attacker,skill,j.basedamage)
            if tempdam>maxdam
              maxdam=tempdam
              maxid = j.id
            end
          end
        end
        if @field.effects[PBEffects::Gravity]>0
          score*=0
        else
          for i in attacker.moves
            if i.accuracy<=70
              score*=2
              break
            end
          end
          if attacker.pbHasMove?(:ZAPCANNON) || attacker.pbHasMove?(:INFERNO)
            score*=3
          end
          if maxid==(PBMoves::SKYDROP) || maxid==(PBMoves::BOUNCE) || maxid==(PBMoves::FLY) ||
             maxid==(PBMoves::JUMPKICK) || maxid==(PBMoves::FLYINGPRESS) ||
             maxid==(PBMoves::HIJUMPKICK) || maxid==(PBMoves::SPLASH)
            score*=2
          end
          for m in attacker.moves
            if m.id==(PBMoves::SKYDROP) || m.id==(PBMoves::BOUNCE) || m.id==(PBMoves::FLY) ||
               m.id==(PBMoves::JUMPKICK) || m.id==(PBMoves::FLYINGPRESS) ||
               m.id==(PBMoves::HIJUMPKICK) || m.id==(PBMoves::SPLASH)
              score*=0
              break
            end
          end
          if attacker.pbHasType?(:GROUND) &&
             (opponent.pbHasType?(:FLYING) || (!opponent.abilitynulled && opponent.ability == PBAbilities::LEVITATE) || (oppitemworks && opponent.item == PBItems::AIRBALLOON))
            score*=2
          end
          if (attitemworks && attacker.item == PBItems::AMPLIFIELDROCK) || $fefieldeffect==37
            score*=1.5
          end
          psyvar=false
          poisonvar=false
          fairyvar=false
          darkvar=false
          for mon in pbParty(attacker.index)
            next if mon.nil?
            if mon.hasType?(:PSYCHIC)
              psyvar=true
            end
            if mon.hasType?(:POISON)
              poisonvar=true
            end
            if mon.hasType?(:FAIRY)
              fairyvar=true
            end
            if mon.hasType?(:DARK)
              darkvar=true
            end
          end
          if $fefieldeffect==11
            if !attacker.pbHasType?(:POISON)
              score*=3
            else
              score*=0.5
            end
            if !poisonvar
              score*=3
            end
          elsif $fefieldeffect==21
            if attacker.pbHasType?(:WATER)
              score*=2
            else
              score*=0.5
            end
          elsif $fefieldeffect==35
            if !attacker.pbHasType?(:FLYING) && !(!attacker.abilitynulled && attacker.ability == PBAbilities::LEVITATE)
              score*=2
            end
            if opponent.pbHasType?(:FLYING) || (!opponent.abilitynulled && opponent.ability == PBAbilities::LEVITATE)
              score*=2
            end
            if psyvar || fairyvar || darkvar
              score*=2
              if attacker.pbHasType?(:PSYCHIC) || attacker.pbHasType?(:FAIRY) || attacker.pbHasType?(:DARK)
                score*=2
              end
            end
          end
        end
      when 0x119 # Magnet Rise
        if !(attacker.effects[PBEffects::MagnetRise]>0 || attacker.effects[PBEffects::Ingrain] || attacker.effects[PBEffects::SmackDown])
          if checkAIbest(aimem,1,[PBTypes::GROUND],false,attacker,opponent,skill)# Highest expected dam from a ground move
            score*=3
          end
          if opponent.pbHasType?(:GROUND)
            score*=3
          end
          if $fefieldeffect==1 || $fefieldeffect==17 || $fefieldeffect==18
            score*=1.3
          end
        else
          score*=0
        end
      when 0x11A # Telekinesis
        if !(opponent.effects[PBEffects::Telekinesis]>0 || opponent.effects[PBEffects::Ingrain] ||
           opponent.effects[PBEffects::SmackDown] || @field.effects[PBEffects::Gravity]>0 ||
           (oppitemworks && opponent.item == PBItems::IRONBALL) ||
           opponent.species==50 || opponent.species==51 || opponent.species==769 || opponent.species==770 || (opponent.species==94 && opponent.form==1))
          for i in attacker.moves
            if i.accuracy<=70
              score+=10
              break
            end
          end
          if attacker.pbHasMove?(:ZAPCANNON) || attacker.pbHasMove?(:INFERNO)
            score*=2
          end
          if $fefieldeffect==37
            if !(!opponent.abilitynulled && opponent.ability == PBAbilities::CLEARBODY) && !(!opponent.abilitynulled && opponent.ability == PBAbilities::WHITESMOKE)
              score+=15
              miniscore=100
              miniscore*=1.3 if checkAIhealing(aimem)
              if (!attacker.abilitynulled && attacker.ability == PBAbilities::SHADOWTAG) ||
                 (!attacker.abilitynulled && attacker.ability == PBAbilities::ARENATRAP) ||
                 opponent.effects[PBEffects::MeanLook]>=0 ||  opponent.pbNonActivePokemonCount==0
                miniscore*=1.4
              end
              if opponent.status==PBStatuses::BURN || opponent.status==PBStatuses::POISON
                miniscore*=1.2
              end
              ministat= 5*statchangecounter(opponent,1,7,-1)
              ministat+=100
              ministat/=100.0
              miniscore*=ministat
              if attacker.pbNonActivePokemonCount==0
                miniscore*=0.5
              end
              if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE) ||
                 (!opponent.abilitynulled && opponent.ability == PBAbilities::DEFIANT) ||
                 (!opponent.abilitynulled && opponent.ability == PBAbilities::COMPETITIVE) ||
                 (!opponent.abilitynulled && opponent.ability == PBAbilities::CONTRARY)
                miniscore*=0.1
              end
              if attacker.status!=0
                miniscore*=0.7
              end
              miniscore/=100.0
              score*=miniscore
            end
          end
        else
          score*=0
        end
      when 0x11B # Sky Uppercut
      when 0x11C # Smack Down
        if !(opponent.effects[PBEffects::Ingrain] ||
           opponent.effects[PBEffects::SmackDown] ||
           @field.effects[PBEffects::Gravity]>0 ||
           (oppitemworks && opponent.item == PBItems::IRONBALL)) && opponent.effects[PBEffects::Substitute]<=0
          miniscore=100
          if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            if opponent.pbHasMove?(:BOUNCE) || opponent.pbHasMove?(:FLY) || opponent.pbHasMove?(:SKYDROP)
              miniscore*=1.3
            else
              opponent.effects[PBEffects::TwoTurnAttack]!=0
              miniscore*=2
            end
          end
          groundmove = false
          for i in attacker.moves
            if i.type == 4
              groundmove = true
            end
          end
          if opponent.pbHasType?(:FLYING) || (!opponent.abilitynulled && opponent.ability == PBAbilities::LEVITATE)
            miniscore*=2
          end
          miniscore/=100.0
          score*=miniscore
        end
      when 0x11D # After You
      when 0x11E # Quash
      when 0x11F # Trick Room
        count = -1
        sweepvar = false
        for i in pbParty(attacker.index)
          count+=1
          next if i.nil?
          temprole = pbGetMonRole(i,opponent,skill,count,pbParty(attacker.index))
          if temprole.include?(PBMonRoles::SWEEPER)
            sweepvar = true
          end
        end
        if !sweepvar
          score*=1.3
        end
        if roles.include?(PBMonRoles::TANK) || roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          score*=1.3
        end
        if roles.include?(PBMonRoles::LEAD)
          score*=1.5
        end
        if @doublebattle
          score*=1.3
        end
        if (attitemworks && attacker.item == PBItems::AMPLIFIELDROCK) || (attitemworks && attacker.item == PBItems::FOCUSSASH)
          score*=1.5
        end
        if skill>=PBTrainerAI.bestSkill
          if $fefieldeffect==5 || $fefieldeffect==35 || $fefieldeffect==37 # Chess/New World/Psychic Terrain
            score*=1.5
          end
        end
        if attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill) || (attitemworks && attacker.item == PBItems::IRONBALL)
          if @trickroom > 0
            score*=0
          else
            score*=2
            #experimental -- cancels out drop if killing moves
            if initialscores.length>0
              score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
            end
            #end experimental
          end
        else
          if @trickroom > 0
            score*=1.3
          else
            score*=0
          end
        end
      when 0x120 # Ally Switch
        if checkAIdamage(aimem,attacker,opponent,skill)<attacker.hp && attacker.pbNonActivePokemonCount!=0 && (aimem.length > 0)
          score*=1.3
          sweepvar = false
          for i in pbParty(attacker.index)
            next if i.nil?
            temprole = pbGetMonRole(i,opponent,skill,count,pbParty(attacker.index))
            if temprole.include?(PBMonRoles::SWEEPER)
              sweepvar = true
            end
          end
          if sweepvar
            score*=2
          end
          if attacker.pbNonActivePokemonCount<3
            score*=2
          end
          if attacker.pbOwnSide.effects[PBEffects::StealthRock] || attacker.pbOwnSide.effects[PBEffects::Spikes]>0
            score*=0.5
          end
        else
          score*=0
        end
      when 0x121 # Foul Play
      when 0x122 # Secret Sword
      when 0x123 # Synchonoise
        if !opponent.pbHasType?(attacker.type1) && !opponent.pbHasType?(attacker.type2)
          score*=0
        end
      when 0x124 # Wonder Room
        if @field.effects[PBEffects::WonderRoom]!=0
          score*=0
        else
          if (attitemworks && attacker.item == PBItems::AMPLIFIELDROCK) || $fefieldeffect==35 || $fefieldeffect==37
            score*=1.3
          end
          if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
            if attacker.defense>attacker.spdef
              score*=0.5
            else
              score*=2
            end
          else
            if attacker.defense<attacker.spdef
              score*=0.5
            else
              score*=2
            end
          end
          if attacker.attack>attacker.spatk
            if pbRoughStat(opponent,PBStats::DEFENSE,skill)>pbRoughStat(opponent,PBStats::SPDEF,skill)
              score*=2
            else
              score*=0.5
            end
          else
            if pbRoughStat(opponent,PBStats::DEFENSE,skill)<pbRoughStat(opponent,PBStats::SPDEF,skill)
              score*=2
            else
              score*=0.5
            end
          end
        end
      when 0x125 # Last Resort
        totalMoves = []
        for i in attacker.moves
          totalMoves[i.id] = false
          if i.function == 0x125
            totalMoves[i.id] = true
          end
          if i.id == 0
            totalMoves[i.id] = true
          end
        end
        for i in attacker.movesUsed
          for j in attacker.moves
            if i == j.id
              totalMoves[j.id] = true
            end
          end
        end
        for i in attacker.moves
          if !totalMoves[i.id]
            score=0
          end
        end
      when 0x126 # Shadow Stuff
        score*=1.2 # Shadow moves are more preferable
      when 0x127 # Shadow Stuff
        score*=1.2 # Shadow moves are more preferable
        if opponent.pbCanParalyze?(false)
          score*=1.3
          if skill>=PBTrainerAI.mediumSkill
            aspeed=pbRoughStat(attacker,PBStats::SPEED,skill)
            ospeed=pbRoughStat(opponent,PBStats::SPEED,skill)
            if aspeed<ospeed
              score*=1.3
            elsif aspeed>ospeed
              score*=0.6
            end
          end
          if skill>=PBTrainerAI.highSkill
            score*=0.6 if (!opponent.abilitynulled && opponent.ability == PBAbilities::GUTS)
            score*=0.6 if (!opponent.abilitynulled && opponent.ability == PBAbilities::MARVELSCALE)
            score*=0.6 if (!opponent.abilitynulled && opponent.ability == PBAbilities::QUICKFEET)
          end
        end
      when 0x128 # Shadow Stuff
        score*=1.2 # Shadow moves are more preferable
        if opponent.pbCanBurn?(false)
          score*=1.3
          if skill>=PBTrainerAI.highSkill
            score*=0.6 if (!opponent.abilitynulled && opponent.ability == PBAbilities::GUTS)
            score*=0.6 if (!opponent.abilitynulled && opponent.ability == PBAbilities::MARVELSCALE)
            score*=0.6 if (!opponent.abilitynulled && opponent.ability == PBAbilities::QUICKFEET)
            score*=0.6 if (!opponent.abilitynulled && opponent.ability == PBAbilities::FLAREBOOST)
          end
        end
      when 0x129 # Shadow Stuff
        score*=1.2 # Shadow moves are more preferable
        if opponent.pbCanFreeze?(false)
          score*=1.3
          if skill>=PBTrainerAI.highSkill
            score*=0.8 if (!opponent.abilitynulled && opponent.ability == PBAbilities::MARVELSCALE)
          end
        end
      when 0x12A # Shadow Stuff
        score*=1.2 # Shadow moves are more preferable
        if opponent.pbCanConfuse?(false)
          score*=1.3
        else
          if skill>=PBTrainerAI.mediumSkill
            score*=0.1
          end
        end
      when 0x12B # Shadow Stuff
        score*=1.2 # Shadow moves are more preferable
        if !opponent.pbCanReduceStatStage?(PBStats::DEFENSE)
          score*=0.1
        else
          score*=1.4 if attacker.turncount==0
          score+=opponent.stages[PBStats::DEFENSE]*20
        end
      when 0x12C # Shadow Stuff
        score*=1.2 # Shadow moves are more preferable
        if !opponent.pbCanReduceStatStage?(PBStats::EVASION)
          score*=0.1
        else
          score+=opponent.stages[PBStats::EVASION]*15
        end
      when 0x12D # Shadow Stuff
        score*=1.2 # Shadow moves are more preferable
      when 0x12E # Shadow Stuff
        score*=1.2 # Shadow moves are more preferable
        score*=1.2 if opponent.hp>=(opponent.totalhp/2.0)
        score*=0.8 if attacker.hp<(attacker.hp/2.0)
      when 0x12F # Shadow Stuff
        score*=1.2 # Shadow moves are more preferable
        score*=0 if opponent.effects[PBEffects::MeanLook]>=0
      when 0x130 # Shadow Stuff
        score*=1.2 # Shadow moves are more preferable
        score*=0.6
      when 0x131 # Shadow Stuff
        score*=1.2 # Shadow moves are more preferable
        if pbCheckGlobalAbility(:AIRLOCK) ||
          pbCheckGlobalAbility(:CLOUDNINE)
          score*=0.1
        elsif pbWeather==PBWeather::SHADOWSKY
          score*=0.1
        end
      when 0x132 # Shadow Stuff
        score*=1.2 # Shadow moves are more preferable
        if opponent.pbOwnSide.effects[PBEffects::Reflect]>0 ||
          opponent.pbOwnSide.effects[PBEffects::LightScreen]>0 ||
          opponent.pbOwnSide.effects[PBEffects::Safeguard]>0
          score*=1.3
          score*=0.1 if attacker.pbOwnSide.effects[PBEffects::Reflect]>0 ||
                      attacker.pbOwnSide.effects[PBEffects::LightScreen]>0 ||
                      attacker.pbOwnSide.effects[PBEffects::Safeguard]>0
        else
          score*=0
        end
      when 0x133 # Hold Hands
      when 0x134 # Celebrate
      when 0x137 # Magnetic Flux
        if !((!attacker.abilitynulled && attacker.ability == PBAbilities::PLUS) ||
           (!attacker.abilitynulled && attacker.ability == PBAbilities::MINUS) ||
           (!attacker.pbPartner.abilitynulled && attacker.pbPartner.ability == PBAbilities::PLUS) || (!attacker.pbPartner.abilitynulled && attacker.pbPartner.ability == PBAbilities::MINUS))
          score*=0
        else
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::PLUS) || (!attacker.abilitynulled && attacker.ability == PBAbilities::MINUS)
            miniscore = setupminiscore(attacker,opponent,skill,move,false,10,true,initialscores,scoreindex)
            score*=miniscore
            miniscore=100
            if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
              miniscore*=1.5
            end
            if (attitemworks && attacker.item == PBItems::LEFTOVERS) || ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
              miniscore*=1.2
            end
            healmove=false
            for j in attacker.moves
              if j.isHealingMove?
                healmove=true
              end
            end
            if healmove
              miniscore*=1.7
            end
            if attacker.pbHasMove?(:LEECHSEED)
              miniscore*=1.3
            end
            if attacker.pbHasMove?(:PAINSPLIT)
              miniscore*=1.2
            end
            if attacker.stages[PBStats::SPDEF]!=6 && attacker.stages[PBStats::DEFENSE]!=6
              score*=miniscore
            end
          elsif @doublebattle && attacker.pbPartner.stages[PBStats::SPDEF]!=6 && attacker.pbPartner.stages[PBStats::DEFENSE]!=6
            score*=0.7
            if initialscores.length>0
              score*=1.3 if hasbadmoves(initialscores,scoreindex,20)
            end
            if attacker.pbPartner.hp >= attacker.pbPartner.totalhp*0.75
              score*=1.1
            end
            if attacker.pbPartner.effects[PBEffects::Yawn]>0 ||
               attacker.pbPartner.effects[PBEffects::LeechSeed]>=0 ||
               attacker.pbPartner.effects[PBEffects::Attract]>=0 ||
               attacker.pbPartner.status!=0
              score*=0.3
            end
            if movecheck
              score*=0.3
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
              score*=0.5
            end
            if attacker.pbPartner.hasWorkingItem(:LEFTOVERS) || (attacker.pbPartner.hasWorkingItem(:BLACKSLUDGE) && attacker.pbPartner.pbHasType?(:POISON))
              score*=1.2
            end
          else
            score*=0
          end
        end
      when 0x138 # Aromatic Mist
        newopp = attacker.pbOppositeOpposing
        movecheck = false
        if skill>=PBTrainerAI.bestSkill
          if @aiMoveMemory[2][newopp.pokemonIndex].length>0
            for j in @aiMoveMemory[2][newopp.pokemonIndex]
              movecheck=true if (PBStuff::PHASEMOVE).include?(j.id)
            end
          end
        elsif skill>=PBTrainerAI.mediumSkill
          movecheck=checkAImoves(PBStuff::PHASEMOVE,aimem)
        end
        if @doublebattle && opponent==attacker.pbPartner && opponent.stages[PBStats::SPDEF]!=6
          if newopp.spatk > newopp.attack
            score*=2
          else
            score*=0.5
          end
          if initialscores.length>0
            score*=1.3 if hasbadmoves(initialscores,scoreindex,20)
          end
          if opponent.hp*(1.0/opponent.totalhp)>0.75
            score*=1.1
          end
          if opponent.effects[PBEffects::Yawn]>0 ||
             opponent.effects[PBEffects::LeechSeed]>=0 ||
             opponent..effects[PBEffects::Attract]>=0 ||
             opponent.status!=0
            score*=0.3
          end
          if movecheck
            score*=0.2
          end
          if !opponent.abilitynulled && opponent.ability == PBAbilities::SIMPLE
            score*=2
          end
          if !newopp.abilitynulled && newopp.ability == PBAbilities::UNAWARE
            score*=0.5
          end
          if (oppitemworks && opponent.item == PBItems::LEFTOVERS) ||
             ((oppitemworks && opponent.item == PBItems::BLACKSLUDGE) && opponent.pbHasType?(:POISON))
            score*=1.2
          end
          if !opponent.abilitynulled && opponent.ability == PBAbilities::CONTRARY
            score*=0
          end
          if $fefieldeffect==3
            score*=2
          end
        else
          score*=0
        end
      when 0x13A # Noble Roar
        if (!opponent.pbCanReduceStatStage?(PBStats::ATTACK) &&
           !opponent.pbCanReduceStatStage?(PBStats::SPATK)) ||
           (opponent.stages[PBStats::ATTACK]==-6 && opponent.stages[PBStats::SPATK]==-6) ||
           (opponent.stages[PBStats::ATTACK]>0 && opponent.stages[PBStats::SPATK]>0)
          score*=0
        else
          miniscore=100
          ministat= 5*statchangecounter(opponent,1,7,-1)
          ministat+=100
          ministat/=100.0
          miniscore*=ministat
              if $fefieldeffect==31 || $fefieldeffect==32
            miniscore*=2
          end
          miniscore*= unsetupminiscore(attacker,opponent,skill,move,roles,1,false)
          miniscore/=100.0
          score*=miniscore
        end
      when 0x13B # Hyperspace Fury
        startscore = score
        if attacker.species==720 && attacker.form==1 # Hoopa-U
          if checkAImoves(PBStuff::PROTECTMOVE,aimem)
            score*=1.1
            ratesharers=[
              391,   # Protect
              121,   # Detect
              122,   # Quick Guard
              515,   # Wide Guard
              361,   # Endure
              584,   # King's Shield
              603,    # Spiky Shield
              641    # Baneful Bunker
            ]
            if !ratesharers.include?(opponent.lastMoveUsed)
              score*=1.2
            end
          end
          if !(!attacker.abilitynulled && attacker.ability == PBAbilities::NOGUARD) && !(!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD)
            if attacker.stages[PBStats::ACCURACY]<0
              miniscore = (-5)*attacker.stages[PBStats::ACCURACY]
              miniscore+=100
              miniscore/=100.0
              score*=miniscore
            end
            if opponent.stages[PBStats::EVASION]>0
              miniscore = (5)*opponent.stages[PBStats::EVASION]
              miniscore+=100
              miniscore/=100.0
              score*=miniscore
            end
            if (oppitemworks && opponent.item == PBItems::LAXINCENSE) || (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER)
              score*=1.2
            end
            if ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
               ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL)
              score*=1.3
            end
            if opponent.vanished && (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=3
            end
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            score*=1.7
          else
            if startscore<100
              score*=0.8
              if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
                score*=1.2
              else
                score*=0.8
              end
              score*=0.7 if checkAIhealing(aimem)
              if initialscores.length>0
                score*=0.5 if hasgreatmoves(initialscores,scoreindex,skill)
              end
              miniscore=100
              if opponent.pbNonActivePokemonCount!=0
                miniscore*=opponent.pbNonActivePokemonCount
                miniscore/=1000.0
                miniscore= 1-miniscore
                score*=miniscore
              end
              if opponent.pbNonActivePokemonCount!=0 && attacker.pbNonActivePokemonCount==0
                score*=0.7
              end
            end
          end
        else
          score*=0
        end
      when 0x13D # Eerie Impulse
        if (pbRoughStat(opponent,PBStats::SPATK,skill)<pbRoughStat(opponent,PBStats::ATTACK,skill)) || opponent.stages[PBStats::SPATK]>1 || !opponent.pbCanReduceStatStage?(PBStats::SPATK)
          if move.basedamage==0
            score=0
          end
        else
          miniscore=100
          if opponent.stages[PBStats::SPATK]<0
            minimini = 5*opponent.stages[PBStats::SPATK]
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          miniscore*= unsetupminiscore(attacker,opponent,skill,move,roles,1,false)
          miniscore/=100.0
          score*=miniscore
        end
      when 0x13E # Rototiller
        opp1 = attacker.pbOppositeOpposing
        opp2 = opp1.pbPartner
        if @doublebattle && opponent.pbHasType?(:GRASS) && opponent==attacker.pbPartner &&
           opponent.stages[PBStats::SPATK]!=6 && opponent.stages[PBStats::ATTACK]!=6
          if initialscores.length>0
            score*=1.3 if hasbadmoves(initialscores,scoreindex,20)
          end
          if (opponent.hp.to_f)/opponent.totalhp>0.75
            score*=1.1
          end
          if opponent.effects[PBEffects::LeechSeed]>=0 || opponent.effects[PBEffects::Attract]>=0 || opponent.status!=0 || opponent.effects[PBEffects::Yawn]>0
            score*=0.3
          end
          if movecheck
            score*=0.2
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SIMPLE)
            score*=2
          end
          if (!opp1.abilitynulled && opp1.ability == PBAbilities::UNAWARE)
            score*=0.5
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::CONTRARY)
            score*=0
          end
          if $fefieldeffect==33 && $fecounter!=4
            score+=30
          end
          if $fefieldeffect==33
            score+=20
            miniscore=100
            if attacker.effects[PBEffects::Substitute]>0 || attacker.effects[PBEffects::Disguise]
              miniscore*=1.3
            end
            if initialscores.length>0
              miniscore*=1.3 if hasbadmoves(initialscores,scoreindex,20)
            end
            if (opponent.hp.to_f)/opponent.totalhp>0.75
              miniscore*=1.1
            end
            if opp1.effects[PBEffects::HyperBeam]>0
              miniscore*=1.2
            end
            if opp1.effects[PBEffects::Yawn]>0
              miniscore*=1.3
            end
            miniscore*=1.1 if checkAIdamage(aimem,attacker,opponent,skill) < opponent.hp*0.25 && (aimem.length > 0)
            if opponent.turncount<2
              miniscore*=1.1
            end
            if opp1.status!=0
              miniscore*=1.1
            end
            if opp1.status==PBStatuses::SLEEP || opp1.status==PBStatuses::FROZEN
              miniscore*=1.3
            end
            if opp1.effects[PBEffects::Encore]>0
              if opp1.moves[(opp1.effects[PBEffects::EncoreIndex])].basedamage==0
                miniscore*=1.5
              end
            end
            if opponent.effects[PBEffects::Confusion]>0
              miniscore*=0.2
            end
            if opponent.effects[PBEffects::LeechSeed]>=0 || attacker.effects[PBEffects::Attract]>=0
              miniscore*=0.6
            end
            miniscore*=0.5 if checkAImoves(PBStuff::SWITCHOUTMOVE,aimem)
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::SIMPLE)
              miniscore*=2
            end
            if (!opp1.abilitynulled && opp1.ability == PBAbilities::UNAWARE)
              miniscore*=0.5
            end
            if @doublebattle
              miniscore*=0.3
            end
            ministat=0
            ministat+=opponent.stages[PBStats::SPEED] if opponent.stages[PBStats::SPEED]<0
            ministat*=5
            ministat+=100
            ministat/=100.0
            miniscore*=ministat
            ministat=0
            ministat+=opponent.stages[PBStats::ATTACK]
            ministat+=opponent.stages[PBStats::SPEED]
            ministat+=opponent.stages[PBStats::SPATK]
            if ministat > 0
              ministat*=(-5)
              ministat+=100
              ministat/=100.0
              miniscore*=ministat
            end
            miniscore/=100.0
            score*=miniscore
            miniscore=100
            miniscore*=1.3 if checkAIhealing(aimem)
            if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
              miniscore*=1.5
            end
            if roles.include?(PBMonRoles::SWEEPER)
              miniscore*=1.3
            end
            if attacker.status==PBStatuses::PARALYSIS
              miniscore*=0.5
            end
            miniscore*=0.3 if checkAImoves([PBMoves::FOULPLAY],aimem)
            if attacker.hp==attacker.totalhp && (attitemworks && attacker.item == PBItems::FOCUSSASH)
              miniscore*=1.4
            end
            miniscore*=0.4 if checkAIpriority(aimem)
            if attacker.stages[PBStats::SPATK]!=6 && attacker.stages[PBStats::ATTACK]!=6
              score*=miniscore
            end
          end
        else
          score*=0
        end
      when 0x13F # Flower Shield
        opp1 = attacker.pbOppositeOpposing
        opp2 = opp1.pbPartner
        if @doublebattle && opponent.pbHasType?(:GRASS) && opponent==attacker.pbPartner && opponent.stages[PBStats::DEFENSE]!=6
          if $fefieldeffect!=33 || $fecounter==0
            if opp1.attack>opp1.spatk
              score*=2
            else
              score*=0.5
            end
            if opp2.attack>opp2.spatk
              score*=2
            else
              score*=0.5
            end
          else
            score*=2
          end
          if initialscores.length>0
            score*=1.3 if hasbadmoves(initialscores,scoreindex,20)
          end
          if (opponent.hp.to_f)/opponent.totalhp>0.75
            score*=1.1
          end
          if opponent.effects[PBEffects::LeechSeed]>=0 || opponent.effects[PBEffects::Attract]>=0 || opponent.status!=0 || opponent.effects[PBEffects::Yawn]>0
            score*=0.3
          end
          if movecheck
            score*=0.2
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SIMPLE)
            score*=2
          end
          if (!opp1.abilitynulled && opp1.ability == PBAbilities::UNAWARE)
            score*=0.5
          end
          if $fefieldeffect==33 && $fecounter!=4
            score+=30
          end
          if ($fefieldeffect==33 && $fecounter>0) || $fefieldeffect==31
            score+=20
            miniscore=100
            if attacker.effects[PBEffects::Substitute]>0 || attacker.effects[PBEffects::Disguise]
              miniscore*=1.3
            end
            if initialscores.length>0
              miniscore*=1.3 if hasbadmoves(initialscores,scoreindex,20)
            end
            if (opponent.hp.to_f)/opponent.totalhp>0.75
              miniscore*=1.1
            end
            if opp1.effects[PBEffects::HyperBeam]>0
              miniscore*=1.2
            end
            if opp1.effects[PBEffects::Yawn]>0
              miniscore*=1.3
            end
            miniscore*=1.1 if checkAIdamage(aimem,attacker,opponent,skill) < opponent.hp*0.3 && (aimem.length > 0)
            if opponent.turncount<2
              miniscore*=1.1
            end
            if opp1.status!=0
              miniscore*=1.1
            end
            if opp1.status==PBStatuses::SLEEP || opp1.status==PBStatuses::FROZEN
              miniscore*=1.3
            end
            if opp1.effects[PBEffects::Encore]>0
              if opp1.moves[(opp1.effects[PBEffects::EncoreIndex])].basedamage==0
                miniscore*=1.5
              end
            end
            if opponent.effects[PBEffects::Confusion]>0
              miniscore*=0.5
            end
            if opponent.effects[PBEffects::LeechSeed]>=0 || attacker.effects[PBEffects::Attract]>=0
              miniscore*=0.3
            end
            if opponent.effects[PBEffects::Toxic]>0
              miniscore*=0.2
            end
            miniscore*=0.2 if checkAImoves(PBStuff::SWITCHOUTMOVE,aimem)
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::SIMPLE)
              miniscore*=2
            end
            if (!opp1.abilitynulled && opp1.ability == PBAbilities::UNAWARE)
              miniscore*=0.5
            end
            if @doublebattle
              miniscore*=0.3
            end
            miniscore*=0.3 if checkAIdamage(aimem,attacker,opponent,skill)<opponent.hp*0.12 && (aimem.length > 0)
            miniscore/=100.0
            score*=miniscore
            miniscore=100
            if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
              miniscore*=1.5
            end
            if (attitemworks && attacker.item == PBItems::LEFTOVERS) || ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
              miniscore*=1.2
            end
            healmove=false
            for j in attacker.moves
              if j.isHealingMove?
                healmove=true
              end
            end
            if healmove
              miniscore*=1.7
            end
            if attacker.pbHasMove?(:LEECHSEED)
              miniscore*=1.3
            end
            if attacker.pbHasMove?(:PAINSPLIT)
              miniscore*=1.2
            end
            if attacker.stages[PBStats::SPDEF]!=6 && attacker.stages[PBStats::DEFENSE]!=6
              score*=miniscore
            end
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
              score=0
            end
          end
        else
          score*=0
        end
      when 0x140 # Venom Drench
        if opponent.status==PBStatuses::POISON || $fefieldeffect==10 || $fefieldeffect==11 || $fefieldeffect==19 || $fefieldeffect==26
          if (!opponent.pbCanReduceStatStage?(PBStats::ATTACK) &&
             !opponent.pbCanReduceStatStage?(PBStats::SPATK)) ||
             (opponent.stages[PBStats::ATTACK]==-6 && opponent.stages[PBStats::SPATK]==-6) ||
             (opponent.stages[PBStats::ATTACK]>0 && opponent.stages[PBStats::SPATK]>0)
            score*=0.5
          else
            miniscore=100
            if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
              miniscore*=1.4
            end
            sweepvar = false
            for i in pbParty(attacker.index)
              next if i.nil?
              temprole = pbGetMonRole(i,opponent,skill,count,pbParty(attacker.index))
              if temprole.include?(PBMonRoles::SWEEPER)
                sweepvar = true
              end
            end
            if sweepvar
              miniscore*=1.1
            end
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SHADOWTAG) ||
               (!attacker.abilitynulled && attacker.ability == PBAbilities::ARENATRAP) ||
               opponent.effects[PBEffects::MeanLook]>=0 ||  opponent.pbNonActivePokemonCount==0
              miniscore*=1.5
            end
            ministat= 5*statchangecounter(opponent,1,7,-1)
            ministat+=100
            ministat/=100.0
            miniscore*=ministat
            if attacker.pbHasMove?(:FOULPLAY)
              miniscore*=0.5
            end
            miniscore/=100.0
            score*=miniscore
          end
          if (pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed) ||
            opponent.stages[PBStats::SPEED]>0 || !opponent.pbCanReduceStatStage?(PBStats::SPEED)
            score*=0.5
          else
            miniscore=100
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
              miniscore*=0.9
            end
            if attacker.pbHasMove?(:ELECTROBALL)
              miniscore*=1.5
            end
            if attacker.pbHasMove?(:GYROBALL)
              miniscore*=0.5
            end
            if (oppitemworks && opponent.item == PBItems::LAGGINGTAIL) || (oppitemworks && opponent.item == PBItems::IRONBALL)
              miniscore*=0.8
            end
            miniscore*=0.1 if checkAImoves([PBMoves::TRICKROOM],aimem) || @trickroom!=0
            miniscore*=1.3 if checkAImoves([PBMoves::ELECTROBALL],aimem)
            miniscore*=0.5 if checkAImoves([PBMoves::GYROBALL],aimem)
            miniscore/=100.0
            score*=miniscore
            if attacker.pbNonActivePokemonCount==0
              score*=0.5
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE) ||
               (!opponent.abilitynulled && opponent.ability == PBAbilities::CONTRARY) ||
               (!opponent.abilitynulled && opponent.ability == PBAbilities::DEFIANT)
              score*=0
            end
          end
        else
          score*=0
        end
      when 0x141 # Topsy-Turvy
        ministat= 10* statchangecounter(opponent,1,7)
        ministat+=100
        if ministat<0
          ministat=0
        end
        ministat/=100.0
        if opponent == attacker.pbPartner
          ministat = 2-ministat
        end
        score*=ministat
        if $fefieldeffect!=22 && $fefieldeffect!=35 && $fefieldeffect!=36
          effcheck = PBTypes.getCombinedEffectiveness(opponent.type1,attacker.type1,attacker.type2)
          if effcheck>4
            score*=2
          else
            if effcheck!=0 && effcheck<4
              score*=0.5
            end
            if effcheck==0
              score*=0.1
            end
          end
          effcheck = PBTypes.getCombinedEffectiveness(opponent.type2,attacker.type1,attacker.type2)
          if effcheck>4
            score*=2
          else
            if effcheck!=0 && effcheck<4
              score*=0.5
            end
            if effcheck==0
              score*=0.1
            end
          end
          effcheck = PBTypes.getCombinedEffectiveness(attacker.type1,opponent.type1,opponent.type2)
          if effcheck>4
            score*=0.5
          else
            if effcheck!=0 && effcheck<4
              score*=2
            end
            if effcheck==0
              score*=3
            end
          end
          effcheck = PBTypes.getCombinedEffectiveness(attacker.type2,opponent.type1,opponent.type2)
          if effcheck>4
            score*=0.5
          else
            if effcheck!=0 && effcheck<4
              score*=2
            end
            if effcheck==0
              score*=3
            end
          end
        end
      when 0x142 # Trick or Treat
        ghostvar = false
        if aimem.length > 0
          for j in aimem
            ghostvar = true if (j.type == PBTypes::GHOST)
          end
        end
        effmove = false
        for m in attacker.moves
          if (m.type == PBTypes::DARK) || (m.type == PBTypes::GHOST)
            effmove = true
            break
          end
        end
        if effmove
          score*=1.5
        else
          score*=0.7
        end
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          if attacker.pbHasMove?(:TOXIC) && (opponent.pbHasType?(:STEEL) || opponent.pbHasType?(:POISON))
            score*=1.5
          end
        end
        if ghostvar
          score*=0.5
        else
          score*=1.1
        end
        if (opponent.ability == PBAbilities::MULTITYPE) || (opponent.ability == PBAbilities::RKSSYSTEM) ||
           (opponent.type1==(PBTypes::GHOST) && opponent.type2==(PBTypes::GHOST)) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::PROTEAN) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::COLORCHANGE)
          score*=0
        end
      when 0x143 # Forest's Curse
        grassvar = false
        if aimem.length > 0
          for j in aimem
            grassvar = true if (j.type == PBTypes::GRASS)
          end
        end
        effmove = false
        for m in attacker.moves
          if (m.type == PBTypes::FIRE) || (m.type == PBTypes::ICE) || (m.type == PBTypes::BUG) || (m.type == PBTypes::FLYING) || (m.type == PBTypes::POISON)
            effmove = true
            break
          end
        end
        if effmove
          score*=1.5
        else
          score*=0.7
        end
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          if attacker.pbHasMove?(:TOXIC) && (opponent.pbHasType?(:STEEL) || opponent.pbHasType?(:POISON))
            score*=1.5
          end
        end
        if grassvar
          score*=0.5
        else
          score*=1.1
        end
        if (opponent.ability == PBAbilities::MULTITYPE) || (opponent.ability == PBAbilities::RKSSYSTEM) ||
           (opponent.type1==(PBTypes::GRASS) && opponent.type2==(PBTypes::GRASS)) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::PROTEAN) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::COLORCHANGE)
          score*=0
        end
        if $fefieldeffect == 15 || $fefieldeffect == 31
          if !opponent.effects[PBEffects::Curse]
            score+=25
            ministat= 5*statchangecounter(opponent,1,7)
            ministat+=100
            ministat/=100.0
            score*=ministat
            if opponent.pbNonActivePokemonCount==0 || (!attacker.abilitynulled && attacker.ability == PBAbilities::SHADOWTAG) || opponent.effects[PBEffects::MeanLook]>0
              score*=1.3
            else
              score*=0.8
            end
            if @doublebattle
              score*=0.5
            end
            if initialscores.length>0
              score*=1.3 if hasbadmoves(initialscores,scoreindex,25)
            end
          end
        end
      when 0x144 # Flying Press
        if opponent.effects[PBEffects::Minimize]
          score*=2
        end
        if @field.effects[PBEffects::Gravity]>0
          score*=0
        end
      when 0x145 # Electrify
        startscore = score
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::VOLTABSORB)
            if attacker.hp<attacker.totalhp*0.8
              score*=1.5
            else
              score*=0.1
            end
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::LIGHTNINGROD)
            if attacker.spatk > attacker.attack && attacker.stages[PBStats::SPATK]!=6
              score*=1.5
            else
              score*=0.1
            end
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::MOTORDRIVE)
            if attacker.stages[PBStats::SPEED]!=6
              score*=1.2
            else
              score*=0.1
            end
          end
          if attacker.pbHasType?(:GROUND)
            score*=1.3
          end
          if score==startscore
            score*=0.1
          end
          score*=0.5 if checkAIpriority(aimem)
        else
          score*=0
        end
      when 0x146 # Ion Deluge
        maxnormal = checkAIbest(aimem,1,[PBTypes::NORMAL],false,attacker,opponent,skill)
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=0.9
        elsif (!attacker.abilitynulled && attacker.ability == PBAbilities::MOTORDRIVE)
          if maxnormal
            score*=1.5
          end
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::LIGHTNINGROD) || (!attacker.abilitynulled && attacker.ability == PBAbilities::VOLTABSORB)
          if ((attacker.hp.to_f)/attacker.totalhp)<0.6
            if maxnormal
              score*=1.5
            end
          end
        end
        if attacker.pbHasType?(:GROUND)
          score*=1.1
        end
        if @doublebattle
          if (!attacker.pbPartner.abilitynulled && attacker.pbPartner.ability == PBAbilities::MOTORDRIVE) ||
             (!attacker.pbPartner.abilitynulled && attacker.pbPartner.ability == PBAbilities::LIGHTNINGROD) ||
             (!attacker.pbPartner.abilitynulled && attacker.pbPartner.ability == PBAbilities::VOLTABSORB)
            score*=1.2
          end
          if attacker.pbPartner.pbHasType?(:GROUND)
            score*=1.1
          end
        end
        if !maxnormal
          score*=0.5
        end
        if $fefieldeffect != 35 && $fefieldeffect != 1 && $fefieldeffect != 22
          miniscore = getFieldDisruptScore(attacker,opponent,skill)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::SURGESURFER)
            miniscore*=1.5
          end
          if attacker.pbHasType?(:ELECTRIC)
            miniscore*=1.5
          end
          elecvar=false
          for mon in pbParty(attacker.index)
            next if mon.nil?
            if mon.hasType?(:ELECTRIC)
              elecvar=true
            end
          end
          if elecvar
            miniscore*=1.5
          end
          if opponent.pbHasType?(:ELECTRIC)
            miniscore*=0.5
          end
          for m in attacker.moves
            if m.function==0x03
              miniscore*=0.5
              break
            end
          end
          if sleepcheck
            miniscore*=2
          end
          if (attitemworks && attacker.item == PBItems::AMPLIFIELDROCK)
            miniscore*=2
          end
          score*=miniscore
        end
      when 0x146 # Plasma Fists
        maxdam = 0
        maxtype = -1
        if aimem.length > 0
          for j in aimem
            tempdam = pbRoughDamage(j,opponent,attacker,skill,j.basedamage)
            if tempdam>maxdam
              maxdam=tempdam
              maxtype = j.type
            end
          end
        end
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          miniscore=100
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::VOLTABSORB)
            if attacker.hp<attacker.totalhp*0.8
              miniscore*=1.5
            end
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::LIGHTNINGROD)
            if attacker.spatk > attacker.attack && attacker.stages[PBStats::SPATK]!=6
              miniscore*=1.5
            end
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::MOTORDRIVE)
            if attacker.stages[PBStats::SPEED]!=6
              miniscore*=1.2
            end
          end
          if attacker.pbHasType?(:GROUND)
            miniscore*=1.3
          end
          miniscore*=0.5 if checkAIpriority(aimem)
          if maxtype == (PBTypes::NORMAL)
            miniscore*=2
          end
          score*=miniscore
        end
      when 0x147 # Hyperspace Hole
        if checkAImoves(PBStuff::PROTECTMOVE,aimem)
          score*=1.1
          ratesharers=[
            391,   # Protect
            121,   # Detect
            122,   # Quick Guard
            515,   # Wide Guard
            361,   # Endure
            584,   # King's Shield
            603,    # Spiky Shield
            641    # Baneful Bunker
          ]
          if !ratesharers.include?(opponent.lastMoveUsed)
            score*=1.2
          end
        end
        if !(!attacker.abilitynulled && attacker.ability == PBAbilities::NOGUARD) && !(!opponent.abilitynulled && opponent.ability == PBAbilities::NOGUARD)
          if attacker.stages[PBStats::ACCURACY]<0
            miniscore = (-5)*attacker.stages[PBStats::ACCURACY]
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
          if opponent.stages[PBStats::EVASION]>0
            miniscore = (5)*opponent.stages[PBStats::EVASION]
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
          end
          if (oppitemworks && opponent.item == PBItems::LAXINCENSE) || (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER)
            score*=1.2
          end
          if ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
             ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL)
            score*=1.3
          end
          if opponent.vanished && ((attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0))
            score*=3
          end
        end
      when 0x148 # Powder
        firecheck = false
        movecount = 0
        if aimem.length > 0
          for j in aimem
            movecount+=1
            if j.type == (PBTypes::FIRE)
              firecheck = true
            end
          end
        end
        if !(opponent.pbHasType?(:GRASS) || (!opponent.abilitynulled && opponent.ability == PBAbilities::OVERCOAT) || (oppitemworks && opponent.item == PBItems::SAFETYGOGGLES))
          if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=1.2
          end
          if checkAIbest(aimem,1,[PBTypes::FIRE],false,attacker,opponent,skill)
            score*=3
          else
            if opponent.pbHasType?(:FIRE)
              score*=2
            else
              score*=0.2
            end
          end
          effcheck = PBTypes.getCombinedEffectiveness((PBTypes::FIRE),attacker.type1,attacker.type2)
          if effcheck>4
            score*=2
            if effcheck>8
              score*=2
            end
          end
          if attacker.lastMoveUsed==600
            score*=0.6
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::MAGICGUARD)
            score*=0.5
          end
          if !firecheck && movecount==4
            score*=0
          end
        else
          score*=0
        end
      when 0x149 # Mat Block
        if attacker.turncount==0
          if @doublebattle
            score*=1.3
            if ((attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) && ((attacker.pbSpeed>pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0))
              score*=1.2
            else
              score*=0.7
              if ((attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) && ((attacker.pbSpeed<pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0))
                score*=0
              end
            end
            score*=0.3 if checkAImoves(PBStuff::SETUPMOVE,aimem) && checkAIhealing(aimem)
            if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
               ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON)) ||
               attacker.effects[PBEffects::Ingrain] || attacker.effects[PBEffects::AquaRing] || $fefieldeffect==2
              score*=1.2
            end
            if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN
              score*=1.2
              if opponent.effects[PBEffects::Toxic]>0
                score*=1.3
              end
            end
            if attacker.status==PBStatuses::POISON || attacker.status==PBStatuses::BURN
              score*=0.7
              if attacker.effects[PBEffects::Toxic]>0
                score*=0.3
              end
            end
            if opponent.effects[PBEffects::LeechSeed]>=0
              score*=1.3
            end
            if opponent.effects[PBEffects::PerishSong]!=0
              score*=2
            end
            if opponent.status==PBStatuses::SLEEP || opponent.status==PBStatuses::FROZEN
              score*=0.3
            end
            if opponent.vanished
              score*=2
              if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
                score*=1.5
              end
            end
            score*=0.1 if checkAImoves(PBStuff::PROTECTMOVE,aimem)
            if attacker.effects[PBEffects::Wish]>0
              score*=1.3
            end
          end
        else
          score*=0
        end
      when 0x14A # Crafty Shield
        if attacker.lastMoveUsed==565
          score*=0.5
        else
          nodam = true
          for m in opponent.moves
            if m.basedamage>0
              nodam=false
              break
            end
          end
          if nodam
            score+=10
          end
          if attacker.hp==attacker.totalhp
            score*=1.5
          end
        end
        if $fefieldeffect==31
          score+=25
          miniscore=100
          if attacker.effects[PBEffects::Substitute]>0 || attacker.effects[PBEffects::Disguise]
            miniscore*=1.3
          end
          if initialscores.length>0
            miniscore*=1.3 if hasbadmoves(initialscores,scoreindex,20)
          end
          if (attacker.hp.to_f)/attacker.totalhp>0.75
            miniscore*=1.1
          end
          if opponent.effects[PBEffects::HyperBeam]>0
            miniscore*=1.2
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=1.3
          end
          miniscore*=1.1 if checkAIdamage(aimem,attacker,opponent,skill) < attacker.hp*0.3 && (aimem.length > 0)
          if attacker.turncount<2
            miniscore*=1.1
          end
          if opponent.status!=0
            miniscore*=1.1
          end
          if opponent.status==PBStatuses::SLEEP || opponent.status==PBStatuses::FROZEN
            miniscore*=1.3
          end
          if opponent.effects[PBEffects::Encore]>0
            if opponent.moves[(opponent.effects[PBEffects::EncoreIndex])].basedamage==0
              miniscore*=1.5
            end
          end
          if attacker.effects[PBEffects::Confusion]>0
            miniscore*=0.5
          end
          if attacker.effects[PBEffects::LeechSeed]>=0 || attacker.effects[PBEffects::Attract]>=0
            miniscore*=0.3
          end
          if attacker.effects[PBEffects::Toxic]>0
            miniscore*=0.2
          end
          miniscore*=0.2 if checkAImoves(PBStuff::SWITCHOUTMOVE,aimem)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::SIMPLE)
            miniscore*=2
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
            miniscore*=0.5
          end
          if @doublebattle
            miniscore*=0.3
          end
          miniscore*=0.3 if checkAIdamage(aimem,attacker,opponent,skill)<attacker.hp*0.12 && (aimem.length > 0)
          miniscore/=100.0
          score*=miniscore
          miniscore=100
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            miniscore*=1.5
          end
          if (attitemworks && attacker.item == PBItems::LEFTOVERS) || ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
            miniscore*=1.2
          end
          healmove=false
          for j in attacker.moves
            if j.isHealingMove?
              healmove=true
            end
          end
          if healmove
            miniscore*=1.7
          end
          if attacker.pbHasMove?(:LEECHSEED)
            miniscore*=1.3
          end
          if attacker.pbHasMove?(:PAINSPLIT)
            miniscore*=1.2
          end
          if attacker.stages[PBStats::SPDEF]!=6 && attacker.stages[PBStats::DEFENSE]!=6
            score*=miniscore
          end
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
            score=0
          end
        end
      when 0x14B # Kings Shield
        if opponent.turncount==0
          score*=1.5
        end
        score*=0.6 if opponent.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::SPEEDBOOST) && attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          score*=4
          #experimental -- cancels out drop if killing moves
          if initialscores.length>0
            score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
          end
          #end experimental
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON)) ||
           attacker.effects[PBEffects::Ingrain] || attacker.effects[PBEffects::AquaRing] || $fefieldeffect==2
          score*=1.2
        end
        if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN
          score*=1.2
          if opponent.effects[PBEffects::Toxic]>0
            score*=1.3
          end
        end
        if attacker.status==PBStatuses::POISON || attacker.status==PBStatuses::BURN
          score*=0.8
          if attacker.effects[PBEffects::Toxic]>0
            score*=0.3
          end
        end
        if opponent.effects[PBEffects::LeechSeed]>=0
          score*=1.3
        end
        if opponent.effects[PBEffects::PerishSong]!=0
          score*=2
        end
        if opponent.status==PBStatuses::SLEEP || opponent.status==PBStatuses::FROZEN
          score*=0.3
        end
        if opponent.vanished
          score*=2
          if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=1.5
          end
        end
        if ((attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) && (attacker.species == PBSpecies::AEGISLASH) && attacker.form==1
          score*=4
          #experimental -- cancels out drop if killing moves
          if initialscores.length>0
            score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
          end
          #end experimental
        else
          score*=0.8
        end
        score*=0.3 if checkAImoves(PBStuff::PROTECTIGNORINGMOVE,aimem)
        if attacker.effects[PBEffects::Wish]>0
          if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
            score*=3
          else
            score*=1.4
          end
        end
        if aimem.length > 0
          contactcheck=false
          for j in aimem
            contactcheck=j.isContactMove?
          end
          if contactcheck
            score*=1.3
          end
        end
        if skill>=PBTrainerAI.bestSkill && $fefieldeffect==31 # Fairy Tale
          score*=1.4
        else
          if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
            score*=1.5
          end
          if attacker.status==0
            score*=0.1 if checkAImoves([PBMoves::WILLOWISP,PBMoves::THUNDERWAVE,PBMoves::TOXIC],aimem)
          end
        end
        ratesharers=[
          391,   # Protect
          121,   # Detect
          122,   # Quick Guard
          515,   # Wide Guard
          361,   # Endure
          584,   # King's Shield
          603,    # Spiky Shield
          641    # Baneful Bunker
        ]
        if ratesharers.include?(attacker.lastMoveUsed)
          score/=(attacker.effects[PBEffects::ProtectRate]*2.0)
        end
      when 0x14C # Spiky Shield
        if opponent.turncount==0
          score*=1.5
        end
        score*=0.3 if opponent.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::SPEEDBOOST) && attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          score*=4
          #experimental -- cancels out drop if killing moves
          if initialscores.length>0
            score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
          end
          #end experimental
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON)) ||
           attacker.effects[PBEffects::Ingrain] || attacker.effects[PBEffects::AquaRing] || $fefieldeffect==2
          score*=1.2
        end
        if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN
          score*=1.2
          if opponent.effects[PBEffects::Toxic]>0
            score*=1.3
          end
        end
        if attacker.status==PBStatuses::POISON || attacker.status==PBStatuses::BURN
          score*=0.7
          if attacker.effects[PBEffects::Toxic]>0
            score*=0.3
          end
        end
        if opponent.effects[PBEffects::LeechSeed]>=0
          score*=1.3
        end
        if opponent.effects[PBEffects::PerishSong]!=0
          score*=2
        end
        if opponent.status==PBStatuses::SLEEP || opponent.status==PBStatuses::FROZEN
          score*=0.3
        end
        if opponent.vanished
          score*=2
          if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=1.5
          end
        end
        score*=0.1 if checkAImoves(PBStuff::PROTECTIGNORINGMOVE,aimem)
        if attacker.effects[PBEffects::Wish]>0
          if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
            score*=3
          else
            score*=1.4
          end
        end
        if aimem.length > 0
          contactcheck=false
          maxdam=0
          for j in aimem
            contactcheck=j.isContactMove?
          end
          if contactcheck
            score*=1.3
          end
        end
        if attacker.status==0
          score*=0.7 if checkAImoves([PBMoves::WILLOWISP,PBMoves::THUNDERWAVE,PBMoves::TOXIC],aimem)
        end
        ratesharers=[
        391,   # Protect
        121,   # Detect
        122,   # Quick Guard
        515,   # Wide Guard
        361,   # Endure
        584,   # King's Shield
        603,    # Spiky Shield
        641    # Baneful Bunker
          ]
        if ratesharers.include?(attacker.lastMoveUsed)
          score/=(attacker.effects[PBEffects::ProtectRate]*2.0)
        end
      when 0x14E # Geomancy
        maxdam = checkAIdamage(aimem,attacker,opponent,skill)
        if !(attitemworks && attacker.item == PBItems::POWERHERB)
          if maxdam>attacker.hp
            score*=0.4
          elsif attacker.hp*(1.0/attacker.totalhp)<0.5
            score*=0.6
          end
          if attacker.turncount<2
            score*=1.5
          else
            score*=0.7
          end
          if opponent.effects[PBEffects::TwoTurnAttack]!=0 || opponent.effects[PBEffects::HyperBeam]>0
            score*=2
          end
          if @doublebattle
            score*=0.5
          end
        else
          score*=2
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::UNBURDEN)
            score*=1.5
          end
        end
        miniscore=100
        if attacker.effects[PBEffects::Substitute]>0 || attacker.effects[PBEffects::Disguise]
          miniscore*=1.3
        end
        if initialscores.length>0
          miniscore*=1.3 if hasbadmoves(initialscores,scoreindex,40)
        end
        if (attacker.hp.to_f)/attacker.totalhp>0.75
          miniscore*=1.2
        end
        if opponent.effects[PBEffects::Yawn]>0
          miniscore*=1.7
        end
        if maxdam*4<attacker.hp
          miniscore*=1.2
        else
          if move.basedamage==0
            miniscore*=0.8
            if maxdam>attacker.hp
              miniscore*=0.1
            end
          end
        end
        if opponent.status!=0
          miniscore*=1.2
        end
        if opponent.status==PBStatuses::SLEEP || opponent.status==PBStatuses::FROZEN
          miniscore*=1.3
        end
        if opponent.effects[PBEffects::Encore]>0
          if opponent.moves[(opponent.effects[PBEffects::EncoreIndex])].basedamage==0
            miniscore*=1.5
          end
        end
        if attacker.effects[PBEffects::Confusion]>0
          miniscore*=0.5
        end
        if attacker.effects[PBEffects::LeechSeed]>=0 || attacker.effects[PBEffects::Attract]>=0
          miniscore*=0.3
        end
        miniscore*=0.5 if checkAImoves(PBStuff::SWITCHOUTMOVE,aimem)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::SIMPLE)
          miniscore*=2
        end
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
          miniscore*=0.5
        end
        miniscore/=100.0
        score*=miniscore
        miniscore=100
        if attacker.stages[PBStats::SPEED]<0
          ministat=attacker.stages[PBStats::SPEED]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        ministat=0
        ministat+=opponent.stages[PBStats::ATTACK]
        ministat+=opponent.stages[PBStats::SPATK]
        ministat+=opponent.stages[PBStats::SPEED]
        if ministat>0
          minimini=(-5)*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        miniscore*=1.3 if checkAIhealing(aimem)
        if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          miniscore*=1.5
        end
        if roles.include?(PBMonRoles::SWEEPER)
          miniscore*=1.3
        end
        if attacker.status==PBStatuses::PARALYSIS
          miniscore*=0.5
        end
        miniscore*=0.6 if checkAIpriority(aimem)
        miniscore/=100.0
        if !attacker.pbTooHigh?(PBStats::SPATK)
          score*=miniscore
        end
        miniscore=100
        if attacker.effects[PBEffects::Toxic]>0
          miniscore*=0.2
        end
        if pbRoughStat(opponent,PBStats::ATTACK,skill)<pbRoughStat(opponent,PBStats::SPATK,skill)
          miniscore*=1.3
        end
        if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
          miniscore*=1.3
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) || ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON))
          miniscore*=1.2
        end
        healmove=false
        for j in attacker.moves
          if j.isHealingMove?
            healmove=true
          end
        end
        if healmove
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:LEECHSEED)
          miniscore*=1.3
        end
        if attacker.pbHasMove?(:PAINSPLIT)
          miniscore*=1.2
        end
        miniscore/=100.0
        if !attacker.pbTooHigh?(PBStats::SPDEF)
          score*=miniscore
        end
        miniscore=100
        if attacker.stages[PBStats::SPATK]<0
          ministat=attacker.stages[PBStats::SPATK]
          minimini=5*ministat
          minimini+=100
          minimini/=100.0
          miniscore*=minimini
        end
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          miniscore*=0.8
        end
        if @trickroom!=0
          miniscore*=0.2
        else
          miniscore*=0.2 if checkAImoves([PBMoves::TRICKROOM],aimem)
        end
        miniscore/=100.0
        if !attacker.pbTooHigh?(PBStats::SPEED)
          score*=miniscore=0
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score*=0
        end
        psyvar=false
        fairyvar=false
        darkvar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:PSYCHIC)
            psyvar=true
          end
          if mon.hasType?(:FAIRY)
            fairyvar=true
          end
          if mon.hasType?(:DARK)
            darkvar=true
          end
        end
        if $fefieldeffect==35
          if !(!attacker.abilitynulled && attacker.ability == PBAbilities::LEVITATE) && !attacker.pbHasType?(:FLYING)
            score*=2
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::LEVITATE) || opponent.pbHasType?(:FLYING)
            score*=2
          end
          if psyvar || fairyvar || darkvar
            score*=2
            if attacker.pbHasType?(:PSYCHIC) || attacker.pbHasType?(:FAIRY) || attacker.pbHasType?(:DARK)
              score*=2
            end
          end
        end
        if attacker.pbTooHigh?(PBStats::SPATK) && attacker.pbTooHigh?(PBStats::SPDEF) && attacker.pbTooHigh?(PBStats::SPEED)
          score*=0
        end
      when 0x14F # Draining Kiss
        minimini = score*0.01
        miniscore = (opponent.hp*minimini)*(3.0/4.0)
        if miniscore > (attacker.totalhp-attacker.hp)
          miniscore = (attacker.totalhp-attacker.hp)
        end
        if attacker.totalhp>0
          miniscore/=(attacker.totalhp).to_f
        end
        if (attitemworks && attacker.item == PBItems::BIGROOT)
          miniscore*=1.3
        end
        miniscore+=1
        if (!opponent.abilitynulled && opponent.ability == PBAbilities::LIQUIDOOZE)
          miniscore = (2-miniscore)
        end
        if (attacker.hp!=attacker.totalhp || ((attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0))) && opponent.effects[PBEffects::Substitute]==0
          score*=miniscore
        end
        if $fefieldeffect==31 && move.id==(PBMoves::DRAININGKISS)
          if opponent.status==PBStatuses::SLEEP
            score*=0.2
          end
        end
      when 0x150 # Fell Stinger
        if attacker.stages[PBStats::ATTACK]!=6
          if score>=100
            score*=2
            if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=2
            end
          end
        end
      when 0x151 # Parting Shot
        if (!opponent.pbCanReduceStatStage?(PBStats::ATTACK) &&
           !opponent.pbCanReduceStatStage?(PBStats::SPATK)) ||
           (opponent.stages[PBStats::ATTACK]==-6 && opponent.stages[PBStats::SPATK]==-6) ||
           (opponent.stages[PBStats::ATTACK]>0 && opponent.stages[PBStats::SPATK]>0)
          score*=0
        else
          if attacker.pbNonActivePokemonCount==0
            if attacker.pbOwnSide.effects[PBEffects::StealthRock]
              score*=0.7
            end
            if attacker.pbOwnSide.effects[PBEffects::StickyWeb]
              score*=0.6
            end
            if attacker.pbOwnSide.effects[PBEffects::Spikes]>0
              score*=0.9**attacker.pbOwnSide.effects[PBEffects::Spikes]
            end
            if attacker.pbOwnSide.effects[PBEffects::ToxicSpikes]>0
              score*=0.9**attacker.pbOwnSide.effects[PBEffects::ToxicSpikes]
            end
            if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=1.1
            end
            sweepvar = false
            for i in pbParty(attacker.index)
              next if i.nil?
              temprole = pbGetMonRole(i,opponent,skill,count,pbParty(attacker.index))
              if temprole.include?(PBMonRoles::SWEEPER)
                sweepvar = true
              end
            end
            if sweepvar
              score*=1.5
            end
            if roles.include?(PBMonRoles::LEAD)
              score*=1.1
            end
            if roles.include?(PBMonRoles::PIVOT)
              score*=1.2
            end
            ministat= 5*statchangecounter(opponent,1,7,-1)
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
            miniscore= (-5)*statchangecounter(attacker,1,7,1)
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
            if attacker.effects[PBEffects::Toxic]>0 || attacker.effects[PBEffects::Attract]>-1 || attacker.effects[PBEffects::Confusion]>0
              score*=1.3
            end
            if attacker.effects[PBEffects::LeechSeed]>-1
              score*=1.5
            end
            miniscore=130
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::SHADOWTAG) ||
               (!attacker.abilitynulled && attacker.ability == PBAbilities::ARENATRAP) ||
               opponent.effects[PBEffects::MeanLook]>=0 ||  opponent.pbNonActivePokemonCount==0
              miniscore*=1.4
            end
            ministat= 5*statchangecounter(opponent,1,7,-1)
            ministat+=100
            ministat/=100.0
            miniscore*=ministat
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE) ||
               (!opponent.abilitynulled && opponent.ability == PBAbilities::DEFIANT) ||
               (!opponent.abilitynulled && opponent.ability == PBAbilities::COMPETITIVE) ||
               (!opponent.abilitynulled && opponent.ability == PBAbilities::CONTRARY)
              miniscore*=0.1
            end
            miniscore/=100.0
            score*=miniscore
          end
        end
      when 0x152 # Fairy Lock
        if attacker.effects[PBEffects::PerishSong]==1 || attacker.effects[PBEffects::PerishSong]==2
          score*=0
        else
          if opponent.effects[PBEffects::PerishSong]==2
            score*=10
          end
          if opponent.effects[PBEffects::PerishSong]==1
            score*=20
          end
          if attacker.effects[PBEffects::LeechSeed]>=0
            score*=0.8
          end
          if opponent.effects[PBEffects::LeechSeed]>=0
            score*=1.2
          end
          if opponent.effects[PBEffects::Curse]
            score*=1.3
          end
          if attacker.effects[PBEffects::Curse]
            score*=0.7
          end
          if opponent.effects[PBEffects::Confusion]>0
            score*=1.1
          end
          if attacker.effects[PBEffects::Confusion]>0
            score*=1.1
          end
        end
      when 0x153 # Sticky Web
        if !attacker.pbOpposingSide.effects[PBEffects::StickyWeb]
          if roles.include?(PBMonRoles::LEAD)
            score*=1.3
          end
          if (attitemworks && attacker.item == PBItems::FOCUSSASH) && attacker.hp==attacker.totalhp
            score*=1.3
          end
          if attacker.turncount<2
            score*=1.3
          end
          if opponent.pbNonActivePokemonCount>1
            miniscore = opponent.pbNonActivePokemonCount
            miniscore/=100.0
            miniscore*=0.3
            miniscore+=1
            score*=miniscore
          else
            score*=0.2
          end
          if skill>=PBTrainerAI.bestSkill
            for k in 0...pbParty(opponent.index).length
              next if pbParty(opponent.index)[k].nil?
              if @aiMoveMemory[2][k].length>0
                movecheck=false
                for j in @aiMoveMemory[2][k]
                  movecheck=true if j.id==(PBMoves::DEFOG) || j.id==(PBMoves::RAPIDSPIN)
                end
                score*=0.3 if movecheck
              end
            end
          elsif skill>=PBTrainerAI.mediumSkill
            score*=0.3 if checkAImoves([PBMoves::DEFOG,PBMoves::RAPIDSPIN],aimem)
          end
          if $fefieldeffect==15
            score*=2
          end
        else
          score*=0
        end
        if $fefieldeffect==19
          if attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) || opponent.stages[PBStats::SPEED]>0 || !opponent.pbCanReduceStatStage?(PBStats::SPEED)
            score*=0
          else
            score+=15
            miniscore=100
            if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
              miniscore*=1.1
            end
            if opponent.pbNonActivePokemonCount==0 || (!attacker.abilitynulled && attacker.ability == PBAbilities::SHADOWTAG) || opponent.effects[PBEffects::MeanLook]>0
              miniscore*=1.3
            end
            if opponent.stages[PBStats::SPEED]<0
              minimini = 5*opponent.stages[PBStats::SPEED]
              minimini+=100
              minimini/=100.0
              miniscore*=minimini
            end
            if attacker.pbNonActivePokemonCount==0
              miniscore*=0.5
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE) ||
               (!opponent.abilitynulled && opponent.ability == PBAbilities::COMPETITIVE) ||
               (!opponent.abilitynulled && opponent.ability == PBAbilities::DEFIANT) ||
               (!opponent.abilitynulled && opponent.ability == PBAbilities::CONTRARY)
              miniscore*=0.1
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
              miniscore*=0.5
            end
            if attacker.pbHasMove?(:ELECTROBALL)
              miniscore*=1.5
            end
            if attacker.pbHasMove?(:GYROBALL)
              miniscore*=0.5
            end
            if (oppitemworks && opponent.item == PBItems::LAGGINGTAIL) || (oppitemworks && opponent.item == PBItems::IRONBALL)
              miniscore*=0.1
            end
            miniscore*=0.1 if checkAImoves([PBMoves::TRICKROOM],aimem) || @trickroom!=0
            miniscore*=1.3 if checkAImoves([PBMoves::ELECTROBALL],aimem)
            miniscore*=0.5 if checkAImoves([PBMoves::GYROBALL],aimem)
            miniscore/=100.0
            score*=miniscore
          end
        end
      when 0x154 # Electric Terrain
        sleepvar=false
        if aimem.length > 0
          for j in aimem
            sleepvar = true if j.function==0x03
          end
        end
        if @field.effects[PBEffects::Terrain]==0 && $fefieldeffect!=1 &&
          $fefieldeffect!=22 && $fefieldeffect!=35
          miniscore = getFieldDisruptScore(attacker,opponent,skill)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::SURGESURFER)
            miniscore*=1.5
          end
          if attacker.pbHasType?(:ELECTRIC)
            miniscore*=1.5
          end
          elecvar=false
          for mon in pbParty(attacker.index)
            next if mon.nil?
            if mon.hasType?(:ELECTRIC)
              elecvar=true
            end
          end
          if elecvar
            miniscore*=2
          end
          if opponent.pbHasType?(:ELECTRIC)
            miniscore*=0.5
          end
          for m in attacker.moves
            if m.function==0x03
              miniscore*=0.5
              break
            end
          end
          if sleepvar
            miniscore*=2
          end
          if (attitemworks && attacker.item == PBItems::AMPLIFIELDROCK)
            miniscore*=2
          end
          score*=miniscore
        else
          score*=0
        end
      when 0x155 # Grassy Terrain
        firevar=false
        grassvar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:FIRE)
            firevar=true
          end
          if mon.hasType?(:GRASS)
            grassvar=true
          end
        end
        if @field.effects[PBEffects::Terrain]==0 && $fefieldeffect!=2 &&
          $fefieldeffect!=22 && $fefieldeffect!=35
          miniscore = getFieldDisruptScore(attacker,opponent,skill)
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            miniscore*=1.5
          end
          if attacker.pbHasType?(:FIRE)
            miniscore*=2
          end
          if firevar
            miniscore*=2
          end
          if opponent.pbHasType?(:FIRE)
            miniscore*=0.5
            if pbWeather!=PBWeather::RAINDANCE
              miniscore*=0.5
            end
            if attacker.pbHasType?(:GRASS)
              miniscore*=0.5
            end
          else
            if attacker.pbHasType?(:GRASS)
              miniscore*=2
            end
          end
          if grassvar
            miniscore*=2
          end
          miniscore*=0.5 if checkAIhealing(aimem)
          miniscore*=0.5 if checkAImoves([PBMoves::SLUDGEWAVE],aimem)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::GRASSPELT)
            miniscore*=1.5
          end
          if (attitemworks && attacker.item == PBItems::AMPLIFIELDROCK)
            miniscore*=2
          end
          score*=miniscore
        else
          score*=0
        end
      when 0x156 # Misty Terrain
        fairyvar=false
        dragonvar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:FAIRY)
            fairyvar=true
          end
          if mon.hasType?(:DRAGON)
            dragonvar=true
          end
        end
        if @field.effects[PBEffects::Terrain]==0 && $fefieldeffect!=3 &&
          $fefieldeffect!=22 && $fefieldeffect!=35
          miniscore = getFieldDisruptScore(attacker,opponent,skill)
          if fairyvar
            miniscore*=2
          end
          if !attacker.pbHasType?(:FAIRY) && opponent.pbHasType?(:DRAGON)
            miniscore*=2
          end
          if attacker.pbHasType?(:DRAGON)
            miniscore*=0.5
          end
          if opponent.pbHasType?(:FAIRY)
            miniscore*=0.5
          end
          if attacker.pbHasType?(:FAIRY) && opponent.spatk>opponent.attack
            miniscore*=2
          end
          if (attitemworks && attacker.item == PBItems::AMPLIFIELDROCK)
            miniscore*=2
          end
          score*=miniscore
        else
          score*=0
        end
      when 0x15A # Sparkling Aria
        if opponent.status==PBStatuses::BURN
          score*=0.6
        end
      when 0x158 # Belch
        if attacker.effects[PBEffects::Belch]==false
          score*=0
        end
      when 0x159 # Toxic Thread
        if opponent.pbCanPoison?(false)
          miniscore=100
          miniscore*=1.2
          ministat=0
          ministat+=opponent.stages[PBStats::DEFENSE]
          ministat+=opponent.stages[PBStats::SPDEF]
          ministat+=opponent.stages[PBStats::EVASION]
          if ministat>0
            minimini=5*ministat
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::NATURALCURE)
            miniscore*=0.3
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::MARVELSCALE)
            miniscore*=0.7
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::TOXICBOOST) || (!opponent.abilitynulled && opponent.ability == PBAbilities::GUTS)
            miniscore*=0.2
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::POISONHEAL) || (!opponent.abilitynulled && opponent.ability == PBAbilities::MAGICGUARD)
            miniscore*=0.1
          end
          miniscore*=0.2 if checkAImoves([PBMoves::FACADE],aimem)
          miniscore*=0.1 if checkAImoves([PBMoves::REST],aimem)
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            miniscore*=1.5
          end
          if initialscores.length>0
            miniscore*=1.2 if hasbadmoves(initialscores,scoreindex,30)
          end
          if attacker.pbHasMove?(:VENOSHOCK) ||
            attacker.pbHasMove?(:VENOMDRENCH) ||
            (!attacker.abilitynulled && attacker.ability == PBAbilities::MERCILESS)
            miniscore*=1.6
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=0.4
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SHEDSKIN)
            miniscore*=0.7
          end
          miniscore/=100.0
          score*=miniscore
        else
          score*=0.5
        end
        if opponent.stages[PBStats::SPEED]>0 || opponent.stages[PBStats::SPEED]==-6
          score*=0.5
        else
          miniscore=100
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            miniscore*=1.1
          end
          livecount1=0
          for i in pbParty(attacker.index)
            next if i.nil?
            livecount1+=1 if i.hp!=0
          end
          livecount2=0
          for i in pbParty(opponent.index)
            next if i.nil?
            livecount2+=1 if i.hp!=0
          end
          if livecount2==1 || (!attacker.abilitynulled && attacker.ability == PBAbilities::SHADOWTAG) || opponent.effects[PBEffects::MeanLook]>0
            miniscore*=1.4
          end
          if opponent.stages[PBStats::SPEED]<0
            minimini = 5*opponent.stages[PBStats::SPEED]
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if livecount1==1
            miniscore*=0.5
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::COMPETITIVE) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::DEFIANT) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::CONTRARY)
            miniscore*=0.1
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SPEEDBOOST)
            miniscore*=0.5
          end
          if attacker.pbHasMove?(:ELECTROBALL)
            miniscore*=1.5
          end
          if attacker.pbHasMove?(:GYROBALL)
            miniscore*=0.5
          end
          miniscore*=0.1 if  @trickroom!=0 || checkAImoves([PBMoves::TRICKROOM],aimem)
          if (oppitemworks && opponent.item == PBItems::LAGGINGTAIL) || (oppitemworks && opponent.item == PBItems::IRONBALL)
            miniscore*=0.1
          end
          miniscore*=1.3 if checkAImoves([PBMoves::ELECTROBALL],aimem)
          miniscore*=0.5 if checkAImoves([PBMoves::GYROBALL],aimem)
          if (attacker.pbSpeed>pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=0.5
          end
          miniscore/=100.0
          score*=miniscore
        end
      when 0x15B # Purify
        if opponent==attacker.pbPartner && opponent.status!=0
          score*=1.5
          if opponent.hp>opponent.totalhp*0.8
            score*=0.8
          else
            if opponent.hp>opponent.totalhp*0.3
              score*=2
            end
          end
          if opponent.effects[PBEffects::Toxic]>3
            score*=1.3
          end
          if opponent.pbHasMove?(:HEX)
            score*=1.3
          end
        else
          score*=0
        end
      when 0x15C # Gear Up
        if !((!attacker.abilitynulled && attacker.ability == PBAbilities::PLUS) || (!attacker.abilitynulled && attacker.ability == PBAbilities::MINUS) ||
           (!attacker.pbPartner.abilitynulled && attacker.pbPartner.ability == PBAbilities::PLUS) || (!attacker.pbPartner.abilitynulled && attacker.pbPartner.ability == PBAbilities::MINUS))
          score*=0
        else
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::PLUS) || (!attacker.abilitynulled && attacker.ability == PBAbilities::MINUS)
            miniscore = setupminiscore(attacker,opponent,skill,move,true,5,false,initialscores,scoreindex)
            if opponent.stages[PBStats::SPEED]<0
              ministat = 5*opponent.stages[PBStats::SPEED]
              ministat+=100
              ministat/=100.0
              miniscore*=ministat
            end
            ministat=0
            ministat+=opponent.stages[PBStats::ATTACK]
            ministat+=opponent.stages[PBStats::SPEED]
            ministat+=opponent.stages[PBStats::SPATK]
            if ministat>0
              ministat*=(-5)
              ministat+=100
              ministat/=100.0
              miniscore*=ministat
            end
            score*=miniscore
            miniscore=100
            miniscore*=1.3 if checkAIhealing(aimem)
            if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              miniscore*=1.5
            end
            if roles.include?(PBMonRoles::SWEEPER)
              miniscore*=1.3
            end
            if attacker.status==PBStatuses::BURN
              miniscore*=0.5
            end
            if attacker.status==PBStatuses::PARALYSIS
              miniscore*=0.5
            end
            miniscore*=0.3 if checkAImoves([PBMoves::FOULPLAY],aimem)
            if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
               ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
               (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
               (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
              miniscore*=1.4
            end
            miniscore*=0.3 if checkAIpriority(aimem)
            physmove=false
            for j in attacker.moves
              if j.pbIsPhysical?(j.type)
                physmove=true
              end
            end
            specmove=false
            for j in attacker.moves
              if j.pbIsSpecial?(j.type)
                specmove=true
              end
            end
            if (!physmove || !attacker.pbTooHigh?(PBStats::ATTACK)) && (!specmove || !attacker.pbTooHigh?(PBStats::SPATK))
              miniscore/=100.0
              score*=miniscore
            end
          elsif @doublebattle && (!attacker.pbPartner.abilitynulled && attacker.pbPartner.ability == PBAbilities::PLUS) ||
             (!attacker.pbPartner.abilitynulled && attacker.pbPartner.ability == PBAbilities::MINUS)
            if initialscores.length>0
              score*=1.3 if hasbadmoves(initialscores,scoreindex,20)
            end
            if attacker.pbPartner.hp>attacker.pbPartner.totalhp*0.75
              score*=1.1
            end
            if attacker.pbPartner.effects[PBEffects::Yawn]>0 || attacker.pbPartner.effects[PBEffects::LeechSeed]>=0 ||
               attacker.pbPartner.effects[PBEffects::Attract]>=0 || attacker.pbPartner.status!=0
              score*=0.3
            end
            if movecheck
              score*=0.3
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
              score*=0.5
            end
          else
            score*=0
          end
        end
      when 0x15D # Spectral Thief
        if opponent.effects[PBEffects::Substitute]>0
          score*=1.2
        end
        ministat= 10*statchangecounter(opponent,1,7)
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          ministat*=(-1)
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::SIMPLE)
          ministat*=2
        end
        ministat+=100
        ministat/=100.0
        score*=ministat
      when 0x15E # Laser Focus
        if !(!opponent.abilitynulled && opponent.ability == PBAbilities::BATTLEARMOR) &&
           !(!opponent.abilitynulled && opponent.ability == PBAbilities::SHELLARMOR) &&
           attacker.effects[PBEffects::LaserFocus]==0
          miniscore = 100
          ministat=0
          ministat+=opponent.stages[PBStats::DEFENSE]
          ministat+=opponent.stages[PBStats::SPDEF]
          if ministat>0
            miniscore+= 10*ministat
          end
          ministat=0
          ministat+=attacker.stages[PBStats::ATTACK]
          ministat+=attacker.stages[PBStats::SPATK]
          if ministat>0
            miniscore+= 10*ministat
          end
          if attacker.effects[PBEffects::FocusEnergy]>0
            miniscore *= 0.8**attacker.effects[PBEffects::FocusEnergy]
          end
          miniscore/=100.0
          score*=miniscore
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::ANGERPOINT) && opponent.stages[PBStats::ATTACK] !=6
            score*=0.7
            if opponent.attack>opponent.spatk
              score*=0.2
            end
          end
        else
          score*=0
        end
      when 0x15F # Clanging Scales
        maxdam=0
        maxphys = false
        healvar=false
        privar=false
        if aimem.length > 0
          for j in aimem
            healvar=true if j.isHealingMove?
            privar=true if j.priority>0
            tempdam = pbRoughDamage(j,opponent,attacker,skill,j.basedamage)
            if tempdam>maxdam
              maxdam=tempdam
              maxphys = j.pbIsPhysical?(j.type)
            end
          end
        end
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::CONTRARY)
          score*=1.5
        else
          if score<100
            score*=0.8
            if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=1.3
            else
              score*=1.2 if checkAIpriority(aimem)
            end
            score*=0.5 if checkAIhealing(aimem)
          end
          if initialscores.length>0
            score*=0.5 if hasgreatmoves(initialscores,scoreindex,skill)
          end
          miniscore=100
          if opponent.pbNonActivePokemonCount!=0
            miniscore*=opponent.pbNonActivePokemonCount
            miniscore/=100.0
            miniscore*=0.05
            miniscore = 1-miniscore
            score*=miniscore
          end
          if attacker.pbNonActivePokemonCount==0 && opponent.pbNonActivePokemonCount!=0
            score*=0.7
          end
          if opponent.attack>opponent.spatk
            score*=0.7
          end
          score*=0.7 if checkAIbest(aimem,2,[],false,attacker,opponent,skill)
        end
      when 0x160 # Strength Sap
        if opponent.effects[PBEffects::Substitute]<=0
          if attacker.effects[PBEffects::HealBlock]>0
            score*=0
          else
            if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
              score*=3
              if skill>=PBTrainerAI.bestSkill
                if checkAIdamage(aimem,attacker,opponent,skill)*1.5 > attacker.hp
                  score*=1.5
                end
                if (attacker.pbSpeed<pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0)
                  if checkAIdamage(aimem,attacker,opponent,skill)*2 > attacker.hp
                    score*=2
                  else
                    score*=0.2
                  end
                end
              end
            end
          end
          if opponent.pbHasMove?(:CALMMIND) || opponent.pbHasMove?(:WORKUP) ||
             opponent.pbHasMove?(:NASTYPLOT) || opponent.pbHasMove?(:TAILGLOW) ||
             opponent.pbHasMove?(:GROWTH) || opponent.pbHasMove?(:QUIVERDANCE)
            score*=0.7
          end
          if (attacker.hp.to_f)/attacker.totalhp<0.5
            score*=1.5
          else
            score*=0.5
          end
          if !(roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL))
            score*=0.8
          end
          if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN || opponent.effects[PBEffects::LeechSeed]>=0 || opponent.effects[PBEffects::Curse]
            score*=1.3
            if opponent.effects[PBEffects::Toxic]>0
              score*=1.3
            end
          end
          score*=1.2 if checkAImoves(PBStuff::CONTRARYBAITMOVE,aimem)
          if opponent.vanished || opponent.effects[PBEffects::HyperBeam]>0
            score*=1.2
          end
          ministat = opponent.attack
          ministat/=(attacker.totalhp).to_f
          ministat+=0.5
          score*=ministat
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::LIQUIDOOZE)
            score*=0.2
          end
          if $fefieldeffect==15 || $fefieldeffect==8
            score*=1.3
          end
          if (attitemworks && attacker.item == PBItems::BIGROOT)
            score*=1.3
          end
          miniscore=100
          if roles.include?(PBMonRoles::PHYSICALWALL) || roles.include?(PBMonRoles::SPECIALWALL)
            miniscore*=1.3
          end
          count=-1
          party=pbParty(attacker.index)
          sweepvar=false
          for i in 0...party.length
            count+=1
            next if (count==attacker.pokemonIndex || party[i].nil?)
            temproles = pbGetMonRole(party[i],opponent,skill,count,party)
            if temproles.include?(PBMonRoles::SWEEPER)
              sweepvar=true
            end
          end
          if sweepvar
            miniscore*=1.1
          end
          livecount2=0
          for i in pbParty(opponent.index)
            next if i.nil?
            livecount2+=1 if i.hp!=0
          end
          if livecount2==1 || (!attacker.abilitynulled && attacker.ability == PBAbilities::SHADOWTAG) || opponent.effects[PBEffects::MeanLook]>0
            miniscore*=1.4
          end
          if opponent.status==PBStatuses::POISON
            miniscore*=1.2
          end
          if opponent.stages[PBStats::ATTACK]<0
            minimini = 5*opponent.stages[PBStats::ATTACK]
            minimini+=100
            minimini/=100.0
            miniscore*=minimini
          end
          if attacker.pbHasMove?(:FOULPLAY)
            miniscore*=0.5
          end
          if opponent.status==PBStatuses::BURN
            miniscore*=0.5
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE) || (!opponent.abilitynulled && opponent.ability == PBAbilities::COMPETITIVE)
            miniscore*=0.1
          end
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::DEFIANT) || (!opponent.abilitynulled && opponent.ability == PBAbilities::CONTRARY)
            miniscore*=0.5
          end
          miniscore/=100.0
          if attacker.stages[PBStats::ATTACK]!=6
            score*=miniscore
          end
        else
          score = 0
        end
      when 0x161 # Speed Swap
        if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          miniscore= (10)*opponent.stages[PBStats::SPEED]
          minimini= (-10)*attacker.stages[PBStats::SPEED]
          if miniscore==0 && minimini==0
            score*=0
          else
            miniscore+=minimini
            miniscore+=100
            miniscore/=100.0
            score*=miniscore
            if @doublebattle
              score*=0.8
            end
          end
        else
          score*=0
        end
      when 0x162 # Burn Up
        maxdam=0
        maxtype = -1
        healvar=false
        if aimem.length > 0
          for j in aimem
            healvar=true if j.isHealingMove?
            tempdam = pbRoughDamage(j,opponent,attacker,skill,j.basedamage)
            if tempdam>maxdam
              maxdam=tempdam
              maxtype = j.type
            end
          end
        end
        if !attacker.pbHasType?(:FIRE)
          score*=0
        else
          if score<100
            score*=0.9
            if healvar
              score*=0.5
            end
          end
          if initialscores.length>0
            score*=0.5 if hasgreatmoves(initialscores,scoreindex,skill)
          end
          miniscore=100
          if opponent.pbNonActivePokemonCount!=0
            miniscore*=opponent.pbNonActivePokemonCount
            miniscore/=100.0
            miniscore*=0.05
            miniscore = 1-miniscore
            score*=miniscore
          end
          if attacker.pbNonActivePokemonCount==0 && opponent.pbNonActivePokemonCount!=0
            score*=0.7
          end
          effcheck = PBTypes.getCombinedEffectiveness(opponent.type1,(PBTypes::FIRE),(PBTypes::FIRE))
          if effcheck > 4
            score*=1.5
          else
            if effcheck<4
              score*=0.5
            end
          end
          effcheck = PBTypes.getCombinedEffectiveness(opponent.type2,(PBTypes::FIRE),(PBTypes::FIRE))
          if effcheck > 4
            score*=1.5
          else
            if effcheck<4
              score*=0.5
            end
          end
          if maxtype!=-1
            effcheck = PBTypes.getCombinedEffectiveness(maxtype,(PBTypes::FIRE),(PBTypes::FIRE))
            if effcheck > 4
              score*=1.5
            else
              if effcheck<4
                score*=0.5
              end
            end
          end
        end
      when 0x163 # Moongeist Beam
        damcount = 0
        firemove = false
        for m in attacker.moves
          if m.basedamage>0
            damcount+=1
            if m.type==(PBTypes::FIRE)
              firemove = true
            end
          end
        end
        if !opponent.moldbroken && !opponent.abilitynulled
          if opponent.ability == PBAbilities::SANDVEIL
            if pbWeather!=PBWeather::SANDSTORM
              score*=1.1
            end
          elsif opponent.ability == PBAbilities::VOLTABSORB || opponent.ability == PBAbilities::LIGHTNINGROD
            if move.type==(PBTypes::ELECTRIC)
              if damcount==1
                score*=3
              end
              if PBTypes.getCombinedEffectiveness((PBTypes::ELECTRIC),opponent.type1,opponent.type2)>4
                score*=2
              end
            end
          elsif opponent.ability == PBAbilities::WATERABSORB || opponent.ability == PBAbilities::STORMDRAIN || opponent.ability == PBAbilities::DRYSKIN
            if move.type==(PBTypes::WATER)
              if damcount==1
                score*=3
              end
              if PBTypes.getCombinedEffectiveness((PBTypes::WATER),opponent.type1,opponent.type2)>4
                score*=2
              end
            end
            if opponent.ability == PBAbilities::DRYSKIN && firemove
              score*=0.5
            end
          elsif opponent.ability == PBAbilities::FLASHFIRE
            if move.type==(PBTypes::FIRE)
              if damcount==1
                score*=3
              end
              if PBTypes.getCombinedEffectiveness((PBTypes::FIRE),opponent.type1,opponent.type2)>4
                score*=2
              end
            end
          elsif opponent.ability == PBAbilities::LEVITATE
            if move.type==(PBTypes::GROUND)
              if damcount==1
                score*=3
              end
              if PBTypes.getCombinedEffectiveness((PBTypes::GROUND),opponent.type1,opponent.type2)>4
                score*=2
              end
            end
          elsif opponent.ability == PBAbilities::WONDERGUARD
            score*=5
          elsif opponent.ability == PBAbilities::SOUNDPROOF
            if move.isSoundBased?
              score*=3
            end
          elsif opponent.ability == PBAbilities::THICKFAT
            if move.type==(PBTypes::FIRE) || move.type==(PBTypes::ICE)
              score*=1.5
            end
          elsif opponent.ability == PBAbilities::MOLDBREAKER
            score*=1.1
          elsif opponent.ability == PBAbilities::UNAWARE
            score*=1.7
          elsif opponent.ability == PBAbilities::MULTISCALE
            if attacker.hp==attacker.totalhp
              score*=1.5
            end
          elsif opponent.ability == PBAbilities::SAPSIPPER
            if move.type==(PBTypes::GRASS)
              if damcount==1
                score*=3
              end
              if PBTypes.getCombinedEffectiveness((PBTypes::GRASS),opponent.type1,opponent.type2)>4
                score*=2
              end
            end
          elsif opponent.ability == PBAbilities::SNOWCLOAK
            if pbWeather!=PBWeather::HAIL
              score*=1.1
            end
          elsif opponent.ability == PBAbilities::FURCOAT
            if attacker.attack>attacker.spatk
              score*=1.5
            end
          elsif opponent.ability == PBAbilities::FLUFFY
            score*=1.5
            if move.type==(PBTypes::FIRE)
              score*=0.5
            end
          elsif opponent.ability == PBAbilities::WATERBUBBLE
            score*=1.5
            if move.type==(PBTypes::FIRE)
              score*=1.3
            end
          end
        end
      when 0x164 # Photon Geyser
        damcount = 0
        firemove = false
        for m in attacker.moves
          if m.basedamage>0
            damcount+=1
            if m.type==(PBTypes::FIRE)
              firemove = true
            end
          end
        end
        if !opponent.moldbroken
          if (!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL)
            if pbWeather!=PBWeather::SANDSTORM
              score*=1.1
            end
          elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::VOLTABSORB) || (!opponent.abilitynulled && opponent.ability == PBAbilities::LIGHTNINGROD)
            if move.type==(PBTypes::ELECTRIC)
              if damcount==1
                score*=3
              end
              if PBTypes.getCombinedEffectiveness((PBTypes::ELECTRIC),opponent.type1,opponent.type2)>4
                score*=2
              end
            end
          elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::WATERABSORB) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::STORMDRAIN) ||
             (!opponent.abilitynulled && opponent.ability == PBAbilities::DRYSKIN)
            if move.type==(PBTypes::WATER)
              if damcount==1
                score*=3
              end
              if PBTypes.getCombinedEffectiveness((PBTypes::WATER),opponent.type1,opponent.type2)>4
                score*=2
              end
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::DRYSKIN) && firemove
              score*=0.5
            end
          elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::FLASHFIRE)
            if move.type==(PBTypes::FIRE)
              if damcount==1
                score*=3
              end
              if PBTypes.getCombinedEffectiveness((PBTypes::FIRE),opponent.type1,opponent.type2)>4
                score*=2
              end
            end
          elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::LEVITATE)
            if move.type==(PBTypes::GROUND)
              if damcount==1
                score*=3
              end
              if PBTypes.getCombinedEffectiveness((PBTypes::GROUND),opponent.type1,opponent.type2)>4
                score*=2
              end
            end
          elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::WONDERGUARD)
            score*=5
          elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::SOUNDPROOF)
            if move.isSoundBased?
              score*=3
            end
          elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::THICKFAT)
            if move.type==(PBTypes::FIRE) || move.type==(PBTypes::ICE)
              score*=1.5
            end
          elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::MOLDBREAKER)
            score*=1.1
          elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::UNAWARE)
            score*=1.7
          elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::MULTISCALE)
            if attacker.hp==attacker.totalhp
              score*=1.5
            end
          elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::SAPSIPPER)
            if move.type==(PBTypes::GRASS)
              if damcount==1
                score*=3
              end
              if PBTypes.getCombinedEffectiveness((PBTypes::GRASS),opponent.type1,opponent.type2)>4
                score*=2
              end
            end
          elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK)
            if pbWeather!=PBWeather::HAIL
              score*=1.1
            end
          elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::FURCOAT)
            if attacker.attack>attacker.spatk
              score*=1.5
            end
          elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::FLUFFY)
            score*=1.5
            if move.type==(PBTypes::FIRE)
              score*=0.5
            end
          elsif (!opponent.abilitynulled && opponent.ability == PBAbilities::WATERBUBBLE)
            score*=1.5
            if move.type==(PBTypes::FIRE)
              score*=1.3
            end
          end
        end
      when 0x165 # Core Enforcer
        if !opponent.unstoppableAbility? && !opponent.effects[PBEffects::GastroAcid]
          miniscore = getAbilityDisruptScore(move,attacker,opponent,skill)
          if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            miniscore*=1.3
          else
            miniscore*=0.5
          end
          miniscore*=1.3 if checkAIpriority(aimem)
          score*=miniscore
        end
      when 0x166 # Stomping Tantrum
        if $fefieldeffect==5
          psyvar=false
          for mon in pbParty(attacker.index)
            next if mon.nil?
            if mon.hasType?(:PSYCHIC)
              psyvar=true
            end
          end
          if !attacker.pbHasType?(:PSYCHIC)
            score*=1.3
          end
          if !psyvar
            score*=1.8
          else
            score*=0.7
          end
        end
      when 0x167 # Aurora Veil
        if attacker.pbOwnSide.effects[PBEffects::AuroraVeil]<=0
          if pbWeather==PBWeather::HAIL || (skill>=PBTrainerAI.bestSkill &&
             ($fefieldeffect==28 || $fefieldeffect==30 || $fefieldeffect==34 || $fefieldeffect==4 || $fefieldeffect==9 || $fefieldeffect==13 || $fefieldeffect==25))
            score*=1.5
            if attacker.pbOwnSide.effects[PBEffects::AuroraVeil]>0
              score*=0.1
            end
            if (attitemworks && attacker.item == PBItems::LIGHTCLAY)
              score*=1.5
            end
            if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=1.1
              score*=2 if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp && (checkAIdamage(aimem,attacker,opponent,skill)/2.0)<attacker.hp
            end
            if attacker.hp==attacker.totalhp && (((attitemworks && attacker.item == PBItems::FOCUSSASH) ||
               ((!attacker.abilitynulled && attacker.ability == PBAbilities::STURDY) && !attacker.moldbroken)) &&
               (pbWeather!=PBWeather::HAIL || attacker.pbHasType?(:ICE)) &&
               (pbWeather!=PBWeather::SANDSTORM || attacker.pbHasType?(:ROCK) || attacker.pbHasType?(:GROUND) || attacker.pbHasType?(:STEEL)))
              score*=1.3
            end
            score*=0.1 if checkAImoves([PBMoves::DEFOG,PBMoves::RAPIDSPIN],aimem)
            if skill>=PBTrainerAI.bestSkill
              if $fefieldeffect==30 # Mirror
                score*=1.5
              end
            end
          else
            score=0
          end
        else
          score=0
        end
      when 0x168 # Baneful Bunker
        if opponent.turncount==0
          score*=1.5
        end
        score*=0.3 if opponent.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
        if (!attacker.abilitynulled && attacker.ability == PBAbilities::SPEEDBOOST) && attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill) && @trickroom==0
          score*=4
          #experimental -- cancels out drop if killing moves
          if initialscores.length>0
            score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
          end
          #end experimental
        end
        if (attitemworks && attacker.item == PBItems::LEFTOVERS) ||
           ((attitemworks && attacker.item == PBItems::BLACKSLUDGE) && attacker.pbHasType?(:POISON)) ||
           attacker.effects[PBEffects::Ingrain] || attacker.effects[PBEffects::AquaRing] || $fefieldeffect==2
          score*=1.2
        end
        if opponent.status!=0
          score*=0.8
        else
          if opponent.pbCanPoison?(false)
            score*=1.3
            if (!attacker.abilitynulled && attacker.ability == PBAbilities::MERCILESS)
              score*=1.3
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::POISONHEAL)
              score*=0.3
            end
            if (!opponent.abilitynulled && opponent.ability == PBAbilities::TOXICBOOST)
              score*=0.7
            end
          end
        end
        if attacker.status==PBStatuses::POISON || attacker.status==PBStatuses::BURN
          score*=0.7
          if attacker.effects[PBEffects::Toxic]>0
            score*=0.3
          end
        end
        if opponent.effects[PBEffects::LeechSeed]>=0
          score*=1.3
        end
        if opponent.effects[PBEffects::PerishSong]!=0
          score*=2
        end
        if opponent.status==PBStatuses::SLEEP || opponent.status==PBStatuses::FROZEN
          score*=0.3
        end
        if opponent.vanished
          score*=2
          if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=1.5
          end
        end
        score*=0.1 if checkAImoves(PBStuff::PROTECTMOVE,aimem)
        if attacker.effects[PBEffects::Wish]>0
          if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
            score*=3
          else
            score*=1.4
          end
        end
        if aimem.length > 0
          contactcheck=false
          for j in aimem
            contactcheck=j.isContactMove?
          end
          if contactcheck
            score*=1.3
          end
        end
        ratesharers=[
          391,   # Protect
          121,   # Detect
          122,   # Quick Guard
          515,   # Wide Guard
          361,   # Endure
          584,   # King's Shield
          603,    # Spiky Shield
          641    # Baneful Bunker
        ]
        if ratesharers.include?(attacker.lastMoveUsed)
          score/=(attacker.effects[PBEffects::ProtectRate]*2.0)
        end
      when 0x169 # Revelation Dance
      when 0x16A # Spotlight
        maxdam=0
        maxtype = -1
        contactcheck = false
        if aimem.length > 0
          for j in aimem
            tempdam = pbRoughDamage(j,opponent,attacker,skill,j.basedamage)
            if tempdam>maxdam
              maxdam=tempdam
              maxtype = j.type
              contactcheck = j.isContactMove?
            end
          end
        end
        if @doublebattle && opponent==attacker.pbPartner
          if !opponent.abilitynulled
            if opponent.ability == PBAbilities::FLASHFIRE
              score*=3 if checkAIbest(aimem,1,[PBTypes::FIRE],false,attacker,opponent,skill)
            elsif opponent.ability == PBAbilities::STORMDRAIN || opponent.ability == PBAbilities::DRYSKIN || opponent.ability == PBAbilities::WATERABSORB
              score*=3 if checkAIbest(aimem,1,[PBTypes::WATER],false,attacker,opponent,skill)
            elsif opponent.ability == PBAbilities::MOTORDRIVE || opponent.ability == PBAbilities::LIGHTNINGROD || opponent.ability == PBAbilities::VOLTABSORB
              score*=3 if checkAIbest(aimem,1,[PBTypes::ELECTRIC],false,attacker,opponent,skill)
            elsif opponent.ability == PBAbilities::SAPSIPPER
              score*=3 if checkAIbest(aimem,1,[PBTypes::GRASS],false,attacker,opponent,skill)
            end
          end
          if opponent.pbHasMove?(:KINGSSHIELD) || opponent.pbHasMove?(:BANEFULBUNKER) || opponent.pbHasMove?(:SPIKYSHIELD)
            if checkAIbest(aimem,4,[],false,attacker,opponent,skill)
              score*=2
            end
          end
          if opponent.pbHasMove?(:COUNTER) || opponent.pbHasMove?(:METALBURST) || opponent.pbHasMove?(:MIRRORCOAT)
            score*=2
          end
          if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=1.5
          end
          if (attacker.pbSpeed<pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0)
            score*=1.5
          end
        else
          score=1
        end
      when 0x16B # Instruct
        if !@doublebattle || opponent!=attacker.pbPartner || opponent.lastMoveUsedSketch<=0
          score=1
        else
          score*=3
          #if @opponent.trainertype==PBTrainers::MIME
          #  score+=35
          #end
          if attacker.pbPartner.hp*2 < attacker.pbPartner.totalhp
            score*=0.5
          else
            if attacker.pbPartner.hp==attacker.pbPartner.totalhp
              score*=1.2
            end
          end
          if initialscores.length>0
            badmoves=true
            for i in 0...initialscores.length
              next if attacker.moves[i].basedamage<=0
              next if i==scoreindex
              if initialscores[i]>20
                badmoves=false
              end
            end
            score*=1.2 if badmoves
          end
          if ((attacker.pbPartner.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) &&
             ((attacker.pbPartner.pbSpeed<pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0))
            score*=1.4
          end
          ministat = [attacker.pbPartner.attack,attacker.pbPartner.spatk].max
          minimini = [attacker.attack,attacker.spatk].max
          ministat-=minimini
          ministat+=100
          ministat/=100.0
          score*=ministat
          if attacker.pbPartner.hp==0
            score=1
          end
        end
      when 0x16C # Throat Chop
        maxdam=0
        maxsound = false
        soundcheck = false
        if aimem.length > 0
          for j in aimem
            soundcheck=true if j.isSoundBased?
            tempdam = pbRoughDamage(j,opponent,attacker,skill,j.basedamage)
            if tempdam>maxdam
              maxdam=tempdam
              maxsound = j.isSoundBased?
            end
          end
        end
        if maxsound
          score*=1.5
        else
          if soundcheck
            score*=1.3
          end
        end
      when 0x16D # Shore Up
        if aimem.length > 0 && skill>=PBTrainerAI.bestSkill
          maxdam = checkAIdamage(aimem,attacker,opponent,skill)
          if maxdam>attacker.hp
            if maxdam>(attacker.hp*1.5)
              score=0
            else
              score*=5
            #experimental -- cancels out drop if killing moves
              if initialscores.length>0
                score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
              end
              #end experimental
            end
          else
            if maxdam*1.5>attacker.hp
              score*=2
            end
            if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              if maxdam*2>attacker.hp
                score*=5
                #experimental -- cancels out drop if killing moves
                if initialscores.length>0
                  score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
                end
                #end experimental
              end
            end
          end
        elsif skill>=PBTrainerAI.bestSkill #no highest expected damage yet
          if ((attacker.hp.to_f)/attacker.totalhp)<0.5
            score*=3
            if ((attacker.hp.to_f)/attacker.totalhp)<0.25
              score*=3
            end
            #experimental -- cancels out drop if killing moves
            if initialscores.length>0
              score*=6 if hasgreatmoves(initialscores,scoreindex,skill)
            end
            #end experimental
          end
        elsif skill>=PBTrainerAI.mediumSkill
          score*=3 if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
        end
        score*=0.7 if opponent.moves.any? {|moveloop| (PBStuff::SETUPMOVE).include?(moveloop)}
        if (attacker.hp.to_f)/attacker.totalhp<0.5
          score*=1.5
          if attacker.effects[PBEffects::Curse]
            score*=2
          end
          if attacker.hp*4<attacker.totalhp
            if attacker.status==PBStatuses::POISON
              score*=1.5
            end
            if attacker.effects[PBEffects::LeechSeed]>=0
              score*=2
            end
            if attacker.hp<attacker.totalhp*0.13
              if attacker.status==PBStatuses::BURN
                score*=2
              end
              if (pbWeather==PBWeather::HAIL && !attacker.pbHasType?(:ICE)) ||
                 (pbWeather==PBWeather::SANDSTORM && !attacker.pbHasType?(:ROCK) && !attacker.pbHasType?(:GROUND) && !attacker.pbHasType?(:STEEL))
                score*=2
              end
            end
          end
        else
          score*=0.9
        end
        if attacker.effects[PBEffects::Toxic]>0
          score*=0.5
          if attacker.effects[PBEffects::Toxic]>4
            score*=0.5
          end
        end
        if attacker.status==PBStatuses::PARALYSIS || attacker.effects[PBEffects::Attract]>=0 || attacker.effects[PBEffects::Confusion]>0
          score*=1.1
        end
        if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN || opponent.effects[PBEffects::LeechSeed]>=0 || opponent.effects[PBEffects::Curse]
          score*=1.3
          if opponent.effects[PBEffects::Toxic]>0
            score*=1.3
          end
        end
        score*=1.2 if checkAImoves(PBStuff::CONTRARYBAITMOVE,aimem)
        if opponent.vanished || opponent.effects[PBEffects::HyperBeam]>0
          score*=1.2
        end
        if pbWeather==PBWeather::SANDSTORM
          score*=1.5
        end
        if skill>=PBTrainerAI.bestSkill
          if $fefieldeffect==12 # Desert
            score*=1.3
          end
          if $fefieldeffect==20 # Ashen Beach
            score*=1.5
          end
          if $fefieldeffect==21 || $fefieldeffect==26 # (Murk)Water Surface
            if pbRoughStat(opponent,PBStats::ATTACK,skill)>pbRoughStat(opponent,PBStats::SPATK,skill)
              score*=1.5
            end
          end
        end
        if ((attacker.hp.to_f)/attacker.totalhp)>0.8
          score=0
        elsif ((attacker.hp.to_f)/attacker.totalhp)>0.6
          score*=0.6
        elsif ((attacker.hp.to_f)/attacker.totalhp)<0.25
          score*=2
        end
        if attacker.effects[PBEffects::Wish]>0
            score=0
        end
      when 0x16E # Floral Healing
        if !@doublebattle || attacker.pbIsOpposing?(opponent.index)
          score*=0
        else
          if !attacker.pbIsOpposing?(opponent.index)
            if opponent.hp*(1.0/opponent.totalhp)<0.7 && opponent.hp*(1.0/opponent.totalhp)>0.3
              score*=3
            end
            if opponent.hp*(1.0/opponent.totalhp)<0.3
              score*=1.7
            end
            if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN || opponent.effects[PBEffects::LeechSeed]>=0 || opponent.effects[PBEffects::Curse]
              score*=0.8
              if opponent.effects[PBEffects::Toxic]>0
                score*=0.7
              end
            end
            if opponent.hp*(1.0/opponent.totalhp)>0.8
              if ((attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) && ((attacker.pbSpeed<pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0))
                score*=0.5
              else
                score*=0
              end
            end
          else
            score*=0
          end
        end
        if $fefieldeffect==2 || $fefieldeffect==31 || ($fefieldeffect==33 && $fecounter>1)
          score*=1.5
        end
        if attacker.status!=PBStatuses::POISON && ($fefieldeffect==10 || $fefieldeffect==11)
          score*=0.2
        end
      when 0x16F # Pollen Puff
        if opponent==attacker.pbPartner
          score = 15
          if opponent.hp>opponent.totalhp*0.3 && opponent.hp<opponent.totalhp*0.7
            score*=3
          end
          if opponent.hp*(1.0/opponent.totalhp)<0.3
            score*=1.7
          end
          if opponent.status==PBStatuses::POISON || opponent.status==PBStatuses::BURN || opponent.effects[PBEffects::LeechSeed]>=0 || opponent.effects[PBEffects::Curse]
            score*=0.8
            if opponent.effects[PBEffects::Toxic]>0
              score*=0.7
            end
          end
          if opponent.hp*(1.0/opponent.totalhp)>0.8
            if ((attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)) && ((attacker.pbSpeed<pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0))
              score*=0.5
            else
              score*=0
            end
          end
          if attacker.effects[PBEffects::HealBlock]>0 || opponent.effects[PBEffects::HealBlock]>0
            score*=0
          end
        end
      when 0x170 # Mind Blown
        startscore = score
        maxdam = checkAIdamage(aimem,attacker,opponent,skill)
        if (!(!attacker.abilitynulled && attacker.ability == PBAbilities::MAGICGUARD) &&
           attacker.hp<attacker.totalhp*0.5) || (attacker.hp<attacker.totalhp*0.75 &&
           ((opponent.pbSpeed>attacker.pbSpeed) ^ (@trickroom!=0))) ||  $fefieldeffect==3 || $fefieldeffect==8 || pbCheckGlobalAbility(:DAMP)
          score*=0
          if !(!attacker.abilitynulled && attacker.ability == PBAbilities::MAGICGUARD)
            score*=0.7
            if startscore < 100
              score*=0.7
            end
            if (attacker.pbSpeed<pbRoughStat(opponent.pbPartner,PBStats::SPEED,skill)) ^ (@trickroom!=0)
              score*=0.5
            end
            if maxdam < attacker.totalhp*0.2
              score*=1.3
            end
            healcheck = false
            for m in attacker.moves
              healcheck=true if m.isHealingMove?
              break
            end
            if healcheck
              score*=1.2
            end
            if initialscores.length>0
              score*=1.3 if hasbadmoves(initialscores,scoreindex,25)
            end
            score*=0.5 if checkAImoves(PBStuff::PROTECTMOVE,aimem)
            ministat=0
            ministat+=opponent.stages[PBStats::EVASION]
            minimini=(-10)*ministat
            minimini+=100
            minimini/=100.0
            score*=minimini
            ministat=0
            ministat+=attacker.stages[PBStats::ACCURACY]
            minimini=(10)*ministat
            minimini+=100
            minimini/=100.0
            score*=minimini
            if (oppitemworks && opponent.item == PBItems::LAXINCENSE) || (oppitemworks && opponent.item == PBItems::BRIGHTPOWDER)
              score*=0.7
            end
            if ((!opponent.abilitynulled && opponent.ability == PBAbilities::SANDVEIL) && pbWeather==PBWeather::SANDSTORM) ||
               ((!opponent.abilitynulled && opponent.ability == PBAbilities::SNOWCLOAK) && pbWeather==PBWeather::HAIL)
              score*=0.7
            end
          else
            score*=1.1
          end
          firevar=false
          grassvar=false
          bugvar=false
          poisonvar=false
          icevar=false
          for mon in pbParty(attacker.index)
            next if mon.nil?
            if mon.hasType?(:FIRE)
              firevar=true
            end
            if mon.hasType?(:GRASS)
              grassvar=true
            end
            if mon.hasType?(:BUG)
              bugvar=true
            end
            if mon.hasType?(:POISON)
              poisonvar=true
            end
            if mon.hasType?(:ICE)
              icevar=true
            end
          end
          if $fefieldeffect==2 || $fefieldeffect==15 || ($fefieldeffect==33 && $fecounter>1)
            if firevar && !bugvar && !grassvar
              score*=2
            end
          elsif $fefieldeffect==16
            if firevar
              score*=2
            end
          elsif $fefieldeffect==11
            if !poisonvar
              score*=1.2
            end
            if attacker.hp*5 < attacker.totalhp
              score*=2
            end
            if opponent.pbNonActivePokemonCount==0
              score*=5
            end
          elsif $fefieldeffect==13 || $fefieldeffect==28
            if !icevar
              score*=1.5
            end
          end
        end
      when 0x171 # Shell Trap
        maxdam=0
        specialvar = false
        if aimem.length > 0
        for j in aimem
            tempdam = pbRoughDamage(j,opponent,attacker,skill,j.basedamage)
            if tempdam>maxdam
              maxdam=tempdam
              if j.pbIsSpecial?(j.type)
                specialvar = true
              else
                specialvar = false
              end
            end
          end
        end
        if (attacker.pbSpeed<pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=0.5
        end
        if attacker.hp==attacker.totalhp && (attitemworks && attacker.item == PBItems::FOCUSSASH)
          score*=1.2
        else
          score*=0.8
          score*=0.8 if checkAIdamage(aimem,attacker,opponent,skill)>attacker.hp
        end
        if attacker.lastMoveUsed==671
          score*=0.7
        end
        score*=0.6 if checkAImoves(PBStuff::SETUPMOVE,aimem)
        miniscore = attacker.hp*(1.0/attacker.totalhp)
        score*=miniscore
        if opponent.spatk > opponent.attack
          score*=0.3
        end
        score*=0.05 if checkAIbest(aimem,3,[],false,attacker,opponent,skill)
      when 0x172 # Beak Blast
        contactcheck = false
        if aimem.length > 0
          for j in aimem
            if j.isContactMove?
              contactcheck=true
            end
          end
        end
        if opponent.pbCanBurn?(false)
          miniscore=120
          ministat = 5*opponent.stages[PBStats::ATTACK]
          if ministat>0
            ministat+=100
            ministat/=100.0
            miniscore*=ministat
          end
          if !opponent.abilitynulled
            miniscore*=0.3 if opponent.ability == PBAbilities::NATURALCURE
            miniscore*=0.7 if opponent.ability == PBAbilities::MARVELSCALE
            miniscore*=0.1 if opponent.ability == PBAbilities::GUTS || opponent.ability == PBAbilities::FLAREBOOST
            miniscore*=0.7 if opponent.ability == PBAbilities::SHEDSKIN
            miniscore*=0.5 if opponent.ability == PBAbilities::SYNCHRONIZE && attacker.status==0
            miniscore*=0.5 if opponent.ability == PBAbilities::MAGICGUARD
            miniscore*=0.3 if opponent.ability == PBAbilities::QUICKFEET
            miniscore*=1.1 if opponent.ability == PBAbilities::STURDY
          end
          miniscore*=0.1 if checkAImoves([PBMoves::REST],aimem)
          miniscore*=0.2 if checkAImoves([PBMoves::FACADE],aimem)
          if opponent.attack > opponent.spatk
            miniscore*=1.7
          end
          if opponent.effects[PBEffects::Yawn]>0
            miniscore*=0.4
          end
          if startscore==110
            miniscore*=0.8
          end
          miniscore-=100
          minimini = 100
          if contactcheck
            minimini*=1.5
          else
            if opponent.attack>opponent.spatk
              minimini*=1.3
            else
              minimini*=0.3
            end
          end
          minimini/=100.0
          miniscore*=minimini
          miniscore+=100
          miniscore/=100.0
          score*=miniscore
        end
        if (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          score*=0.7
        end
      when 0x173 # Psychic Terrain
        psyvar=false
        for mon in pbParty(attacker.index)
          next if mon.nil?
          if mon.hasType?(:PSYCHIC)
            psyvar=true
          end
        end
        pricheck = false
        for m in attacker.moves
          if m.priority>0
            pricheck=true
            break
          end
        end
        if @field.effects[PBEffects::Terrain]==0 && $fefieldeffect!=22
          $fefieldeffect!=35 && $fefieldeffect!=37
          miniscore = getFieldDisruptScore(attacker,opponent,skill)
          if (!attacker.abilitynulled && attacker.ability == PBAbilities::TELEPATHY)
            miniscore*=1.5
          end
          if attacker.pbHasType?(:PSYCHIC)
            miniscore*=1.5
          end
          if psyvar
            miniscore*=2
          end
          if opponent.pbHasType?(:PSYCHIC)
            miniscore*=0.5
          end
          if pricheck
            miniscore*=0.7
          end
          miniscore*=1.3 if checkAIpriority(aimem)
          if (attitemworks && attacker.item == PBItems::AMPLIFIELDROCK)
            miniscore*=2
          end
          score*=miniscore
        else
          score*=0
        end
      when 0x174 # First Impression
        score = 0 if attacker.turncount!=0
        score *= 1.1 if score==110
      end
    ###### END FUNCTION CODES
    if (!opponent.abilitynulled && opponent.ability == PBAbilities::DANCER)
      if (PBStuff::DANCEMOVE).include?(move.id)
        score*=0.5
        score*=0.1 if $fefieldeffect==6
      end
    end
    ioncheck = false
    destinycheck = false
    widecheck = false
    powdercheck = false
    shieldcheck = false
    if skill>=PBTrainerAI.highSkill
      for j in aimem
        ioncheck = true if j.id==(PBMoves::IONDELUGE)
        destinycheck = true if j.id==(PBMoves::DESTINYBOND)
        widecheck = true if j.id==(PBMoves::WIDEGUARD)
        powdercheck = true if j.id==(PBMoves::POWDER)
        shieldcheck = true if j.id==(PBMoves::SPIKYSHIELD) ||
        j.id==(PBMoves::KINGSSHIELD) ||  j.id==(PBMoves::BANEFULBUNKER)
      end
      if @doublebattle && @aiMoveMemory[2][opponent.pbPartner.pokemonIndex].length>0
        for j in @aiMoveMemory[2][opponent.pbPartner.pokemonIndex]
          widecheck = true if j.id==(PBMoves::WIDEGUARD)
          powdercheck = true if j.id==(PBMoves::POWDER)
        end
      end
    end
    if ioncheck == true
      if move.type == 0
        if (!opponent.pbPartner.abilitynulled && opponent.pbPartner.ability == PBAbilities::LIGHTNINGROD) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::LIGHTNINGROD) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::VOLTABSORB) ||
           (!opponent.abilitynulled && opponent.ability == PBAbilities::MOTORDRIVE)
          score *= 0.3
        end
      end
    end
    if (move.target==PBTargets::SingleNonUser || move.target==PBTargets::RandomOpposing ||
       move.target==PBTargets::AllOpposing || move.target==PBTargets::SingleOpposing ||
       move.target==PBTargets::OppositeOpposing)
      if move.type==13 || (ioncheck == true && move.type == 0)
        if (!opponent.pbPartner.abilitynulled && opponent.pbPartner.ability == PBAbilities::LIGHTNINGROD)
          score*=0
        elsif (!attacker.pbPartner.abilitynulled && attacker.pbPartner.ability == PBAbilities::LIGHTNINGROD)
          score*=0.3
        end
      elsif move.type==11
        if (!opponent.pbPartner.abilitynulled && opponent.pbPartner.ability == PBAbilities::LIGHTNINGROD)
          score*=0
        elsif (!attacker.pbPartner.abilitynulled && attacker.pbPartner.ability == PBAbilities::LIGHTNINGROD)
          score*=0.3
        end
      end
    end
    if move.isSoundBased?
      if ((!opponent.abilitynulled && opponent.ability == PBAbilities::SOUNDPROOF) && !opponent.moldbroken) || attacker.effects[PBEffects::ThroatChop]!=0
        score*=0
      else
        score *= 0.6 if checkAImoves([PBMoves::THROATCHOP],aimem)
      end
    end
    if move.flags&0x80!=0 # Boosted crit moves
      if !((!opponent.abilitynulled && opponent.ability == PBAbilities::SHELLARMOR) ||
         (!opponent.abilitynulled && opponent.ability == PBAbilities::BATTLEARMOR) ||
         attacker.effects[PBEffects::LaserFocus]>0)
        boostercount = 0
        if move.pbIsPhysical?(move.type)
          boostercount += opponent.stages[PBStats::DEFENSE] if opponent.stages[PBStats::DEFENSE]>0
          boostercount -= attacker.stages[PBStats::ATTACK] if attacker.stages[PBStats::ATTACK]<0
        elsif move.pbIsSpecial?(move.type)
          boostercount += opponent.stages[PBStats::SPDEF] if opponent.stages[PBStats::SPDEF]>0
          boostercount -= attacker.stages[PBStats::SPATK] if attacker.stages[PBStats::SPATK]<0
        end
        score*=(1.05**boostercount)
      end
    end
    if move.basedamage>0
      if skill>=PBTrainerAI.highSkill
        if opponent.effects[PBEffects::DestinyBond]
          score*=0.2
        else
          if ((opponent.pbSpeed>attacker.pbSpeed) ^ (@trickroom!=0)) && destinycheck
            score*=0.7
          end
        end
      end
    end
    if widecheck && ((move.target == PBTargets::AllOpposing) || (move.target == PBTargets::AllNonUsers))
      score*=0.2
    end
    if powdercheck && move.type==10
      score*=0.2
    end
    if move.isContactMove? && !(attacker.item == PBItems::PROTECTIVEPADS) && !(!attacker.abilitynulled && attacker.ability == PBAbilities::LONGREACH)
      if (oppitemworks && opponent.item == PBItems::ROCKYHELMET) || shieldcheck
        score*=0.85
      end
      if !opponent.abilitynulled
        if opponent.ability == PBAbilities::ROUGHSKIN || opponent.ability == PBAbilities::IRONBARBS
          score*=0.85
        elsif opponent.ability == PBAbilities::EFFECTSPORE
          score*=0.75
        elsif opponent.ability == PBAbilities::FLAMEBODY && attacker.pbCanBurn?(false)
          score*=0.75
        elsif opponent.ability == PBAbilities::STATIC && attacker.pbCanParalyze?(false)
          score*=0.75
        elsif opponent.ability == PBAbilities::POISONPOINT && attacker.pbCanPoison?(false)
          score*=0.75
        elsif opponent.ability == PBAbilities::CUTECHARM && attacker.effects[PBEffects::Attract]<0
          if initialscores.length>0
            if initialscores[scoreindex] < 102
              score*=0.8
            end
          end
        elsif opponent.ability == PBAbilities::GOOEY || opponent.ability == PBAbilities::TANGLINGHAIR
          if attacker.pbCanReduceStatStage?(PBStats::SPEED)
            score*=0.9
            if ((pbRoughStat(opponent,PBStats::SPEED,skill)<attacker.pbSpeed) ^ (@trickroom!=0))
              score*=0.8
            end
          end
        elsif opponent.ability == PBAbilities::MUMMY
          if !attacker.abilitynulled && !attacker.unstoppableAbility? &&
             attacker.ability != opponent.ability && attacker.ability != PBAbilities::SHIELDDUST
            mummyscore = getAbilityDisruptScore(move,opponent,attacker,skill)
            if mummyscore < 2
              mummyscore = 2 - mummyscore
            else
              mummyscore = 0
            end
            score*=mummyscore
          end
        end
      end
      if (!attacker.abilitynulled && attacker.ability == PBAbilities::POISONTOUCH) && opponent.pbCanPoison?(false)
        score*=1.1
      end
      if (!attacker.abilitynulled && attacker.ability == PBAbilities::PICKPOCKET) && opponent.item!=0 && !pbIsUnlosableItem(opponent,opponent.item)
        score*=1.1
      end
      if opponent.effects[PBEffects::KingsShield]== true ||
      opponent.effects[PBEffects::BanefulBunker]== true ||
      opponent.effects[PBEffects::SpikyShield]== true
        score *=0.1
      end
    end
    if move.basedamage>0 && (opponent.effects[PBEffects::SpikyShield] ||
      opponent.effects[PBEffects::BanefulBunker] || opponent.effects[PBEffects::KingsShield])
      score*=0.1
    end
    if move.basedamage==0
      if hasgreatmoves(initialscores,scoreindex,skill)
        maxdam=checkAIdamage(aimem,attacker,opponent,skill)
        if maxdam>0 && maxdam<(attacker.hp*0.3)
          score*=0.6
        else
          score*=0.2 ### highly controversial, revert to 0.1 if shit sucks
        end
      end
    end
    ispowder = (move.id==214 || move.id==218 || move.id==220 || move.id==445 || move.id==600 || move.id==18 || move.id==219)
    if ispowder && (opponent.type==(PBTypes::GRASS) ||
       (!opponent.abilitynulled && opponent.ability == PBAbilities::OVERCOAT) ||
       (oppitemworks && opponent.item == PBItems::SAFETYGOGGLES))
      score*=0
    end
    # A score of 0 here means it should absolutely not be used
    if score<=0
      PBDebug.log(sprintf("%s: final score: 0",PBMoves.getName(move.id))) if $INTERNAL
      PBDebug.log(sprintf(" ")) if $INTERNAL
      attacker.pbUpdate(true) if defined?(megaEvolved) && megaEvolved==true #perry
      return score
    end
    ##### Other score modifications ################################################
    # Prefer damaging moves if AI has no more Pokémon
    if attacker.pbNonActivePokemonCount==0
      if skill>=PBTrainerAI.mediumSkill &&
        !(skill>=PBTrainerAI.highSkill && opponent.pbNonActivePokemonCount>0)
        if move.basedamage==0
          PBDebug.log("[Not preferring status move]") if $INTERNAL
          score*=0.9
        elsif opponent.hp<=opponent.totalhp/2.0
          PBDebug.log("[Preferring damaging move]") if $INTERNAL
          score*=1.1
        end
      end
    end
    # Don't prefer attacking the opponent if they'd be semi-invulnerable
    if opponent.effects[PBEffects::TwoTurnAttack]>0 &&
      skill>=PBTrainerAI.highSkill
      invulmove=$pkmn_move[opponent.effects[PBEffects::TwoTurnAttack]][0] #the function code of the current move
      if move.accuracy>0 &&   # Checks accuracy, i.e. targets opponent
        ([0xC9,0xCA,0xCB,0xCC,0xCD,0xCE].include?(invulmove) ||
        opponent.effects[PBEffects::SkyDrop]) &&
        ((attacker.pbSpeed>opponent.pbSpeed) ^ (@trickroom!=0))
        if skill>=PBTrainerAI.bestSkill   # Can get past semi-invulnerability
          miss=false
          case invulmove
            when 0xC9, 0xCC # Fly, Bounce
              miss=true unless move.function==0x08 ||  # Thunder
                              move.function==0x15 ||  # Hurricane
                              move.function==0x77 ||  # Gust
                              move.function==0x78 ||  # Twister
                              move.function==0x11B || # Sky Uppercut
                              move.function==0x11C || # Smack Down
                              (move.id == PBMoves::WHIRLWIND)
            when 0xCA # Dig
              miss=true unless move.function==0x76 || # Earthquake
                              move.function==0x95    # Magnitude
            when 0xCB # Dive
              miss=true unless move.function==0x75 || # Surf
                              move.function==0xD0 || # Whirlpool
                              move.function==0x12D   # Shadow Storm
            when 0xCD # Shadow Force
              miss=true
            when 0xCE # Sky Drop
              miss=true unless move.function==0x08 ||  # Thunder
                              move.function==0x15 ||  # Hurricane
                              move.function==0x77 ||  # Gust
                              move.function==0x78 ||  # Twister
                              move.function==0x11B || # Sky Uppercut
                              move.function==0x11C    # Smack Down
          end
          if opponent.effects[PBEffects::SkyDrop]
            miss=true unless move.function==0x08 ||  # Thunder
                            move.function==0x15 ||  # Hurricane
                            move.function==0x77 ||  # Gust
                            move.function==0x78 ||  # Twister
                            move.function==0x11B || # Sky Uppercut
                            move.function==0x11C    # Smack Down
          end
          score*=0 if miss
        else
          score*=0
        end
      end
    end
    # Pick a good move for the Choice items
    if attitemworks && (attacker.item == PBItems::CHOICEBAND ||
       attacker.item == PBItems::CHOICESPECS || attacker.item == PBItems::CHOICESCARF)
      if move.basedamage==0 && move.function!=0xF2 # Trick
        score*=0.1
      end
      if ((move.type == PBTypes::NORMAL) && $fefieldeffect!=29) ||
         (move.type == PBTypes::GHOST) || (move.type == PBTypes::FIGHTING) ||
         (move.type == PBTypes::DRAGON) || (move.type == PBTypes::PSYCHIC) ||
         (move.type == PBTypes::GROUND) || (move.type == PBTypes::ELECTRIC) ||
         (move.type == PBTypes::POISON)
        score*=0.95
      end
      if (move.type == PBTypes::FIRE) || (move.type == PBTypes::WATER) ||
         (move.type == PBTypes::GRASS) || (move.type == PBTypes::ELECTRIC)
        score*=0.95
      end
      if move.accuracy > 0
        miniacc = (move.accuracy/100.0)
        score *= miniacc
      end
      if move.pp < 6
        score *= 0.9
      end
    end
    #If user is frozen, prefer a move that can thaw the user
    if attacker.status==PBStatuses::FROZEN
      if skill>=PBTrainerAI.mediumSkill
        if move.canThawUser?
          score+=30
        else
          hasFreezeMove=false
          for m in attacker.moves
            if m.canThawUser?
              hasFreezeMove=true; break
            end
          end
          score*=0 if hasFreezeMove
        end
      end
    end
    # If target is frozen, don't prefer moves that could thaw them
    if opponent.status==PBStatuses::FROZEN
      if (move.type == PBTypes::FIRE)
        score *= 0.1
      end
    end
    # Adjust score based on how much damage it can deal
    if move.basedamage>0
      typemod=pbTypeModNoMessages(bettertype,attacker,opponent,move,skill)
      if typemod==0 || score<=0
        score=0
      elsif skill>=PBTrainerAI.mediumSkill && !(!attacker.abilitynulled &&
         (attacker.ability == PBAbilities::MOLDBREAKER ||
          attacker.ability == PBAbilities::TURBOBLAZE ||
          attacker.ability == PBAbilities::TERAVOLT))
        if !opponent.abilitynulled
          if (typemod<=4 && opponent.ability == PBAbilities::WONDERGUARD) ||
            (move.type == PBTypes::GROUND && (opponent.ability == PBAbilities::LEVITATE || (oppitemworks && opponent.item == PBItems::AIRBALLOON) || opponent.effects[PBEffects::MagnetRise]>0)) ||
            (move.type == PBTypes::FIRE && opponent.ability == PBAbilities::FLASHFIRE) ||
            (move.type == PBTypes::WATER && (opponent.ability == PBAbilities::WATERABSORB || opponent.ability == PBAbilities::STORMDRAIN || opponent.ability == PBAbilities::DRYSKIN)) ||
            (move.type == PBTypes::GRASS && opponent.ability == PBAbilities::SAPSIPPER) ||
            (move.type == PBTypes::ELECTRIC)&& (opponent.ability == PBAbilities::VOLTABSORB || opponent.ability == PBAbilities::LIGHTNINGROD || opponent.ability == PBAbilities::MOTORDRIVE)
            score=0
          end
        end
      else
        if move.type == PBTypes::GROUND && (opponent.ability == PBAbilities::LEVITATE || (oppitemworks && opponent.item == PBItems::AIRBALLOON) || opponent.effects[PBEffects::MagnetRise]>0)
          score=0
        end
      end
      if score != 0
        # Calculate how much damage the move will do (roughly)
        realBaseDamage=move.basedamage
        realBaseDamage=60 if move.basedamage==1
        if skill>=PBTrainerAI.mediumSkill
          realBaseDamage=pbBetterBaseDamage(move,attacker,opponent,skill,realBaseDamage)
        end
      end
    else # non-damaging moves
      if !opponent.abilitynulled
        if (move.type == PBTypes::GROUND && (opponent.ability == PBAbilities::LEVITATE || (oppitemworks && opponent.item == PBItems::AIRBALLOON) || opponent.effects[PBEffects::MagnetRise]>0)) ||
          (move.type == PBTypes::FIRE && opponent.ability == PBAbilities::FLASHFIRE) ||
          (move.type == PBTypes::WATER && (opponent.ability == PBAbilities::WATERABSORB || opponent.ability == PBAbilities::STORMDRAIN || opponent.ability == PBAbilities::DRYSKIN)) ||
          (move.type == PBTypes::GRASS && opponent.ability == PBAbilities::SAPSIPPER) ||
          (move.type == PBTypes::ELECTRIC)&& (opponent.ability == PBAbilities::VOLTABSORB || opponent.ability == PBAbilities::LIGHTNINGROD || opponent.ability == PBAbilities::MOTORDRIVE)
          score=0
        end
      end
    end
    accuracy=pbRoughAccuracy(move,attacker,opponent,skill)
    score*=accuracy/100.0
    #score=0 if score<=10 && skill>=PBTrainerAI.highSkill
    if (move.basedamage==0 && !(move.id == PBMoves::NATUREPOWER)) &&
       (move.target==PBTargets::SingleNonUser || move.target==PBTargets::RandomOpposing ||
       move.target==PBTargets::AllOpposing || move.target==PBTargets::OpposingSide ||
       move.target==PBTargets::SingleOpposing || move.target==PBTargets::OppositeOpposing) &&
       ((!opponent.abilitynulled && opponent.ability == PBAbilities::MAGICBOUNCE) ||
       (!opponent.pbPartner.abilitynulled && opponent.pbPartner.ability == PBAbilities::MAGICBOUNCE))
      score=0
    end
    if skill>=PBTrainerAI.mediumSkill
      if (!attacker.abilitynulled && attacker.ability == PBAbilities::PRANKSTER)
        if opponent.pbHasType?(:DARK)
          if move.basedamage==0 && move.priority>-1
            score=0
          end
        end
      end
    end
    # Avoid shiny wild pokemon if you're an AI partner
    if pbIsWild?
      if attacker.index == 2
        if opponent.pokemon.isShiny?
          score *= 0.15
        end
      end
    end
    score=score.to_i
    score=0 if score<0
    PBDebug.log(sprintf("%s: final score: %d",PBMoves.getName(move.id),score)) if $INTERNAL
    PBDebug.log(sprintf(" ")) if $INTERNAL
    attacker.pbUpdate(true) if defined?(megaEvolved) && megaEvolved==true #perry
    return score
  end
end
