class PokeBattle_Battle
  ################################################################################
  # Choose a move to use.
  ################################################################################
    def pbBuildMoveScores(index) #Generates an array of movescores for decisions
      # Ally targetting stuff marked with ###
      attacker=@battlers[index]
      @scores=[0,0,0,0]
      @targets=nil
      @myChoices=[]
      totalscore=0
      target=-1
      skill=0
      wildbattle=!@opponent && pbIsOpposing?(index)
      if wildbattle # If wild battle
        preference = attacker.personalID % 16
        preference = preference % 4
        for i in 0...4
          if pbCanChooseMove?(index,i,false)
            @scores[i]=100
            if preference == i # for personality
              @scores[i]+=100
            end
            @myChoices.push(i)
          end
        end
      else
        skill=pbGetOwner(attacker.index).skill || 0
        opponent=attacker.pbOppositeOpposing
        fastermon = (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
        if fastermon && opponent
          PBDebug.log(sprintf("AI Pokemon #{attacker.name} is faster than #{opponent.name}.")) if $INTERNAL
        elsif opponent
          PBDebug.log(sprintf("Player Pokemon #{opponent.name} is faster than #{attacker.name}.")) if $INTERNAL
        end
        #if @doublebattle && !opponent.isFainted? && !opponent.pbPartner.isFainted?
        if @doublebattle && ((!opponent.isFainted? && !opponent.pbPartner.isFainted?) || !attacker.pbPartner.isFainted?)
          # Choose a target and move.  Also care about partner.
          otheropp=opponent.pbPartner
          fastermon = (attacker.pbSpeed>pbRoughStat(opponent,PBStats::SPEED,skill)) ^ (@trickroom!=0)
          if fastermon && otheropp
            PBDebug.log(sprintf("AI Pokemon #{attacker.name} is faster than #{otheropp.name}.")) if $INTERNAL
          elsif otheropp
            PBDebug.log(sprintf("Player Pokemon #{otheropp.name} is faster than #{attacker.name}.")) if $INTERNAL
          end
          notopp=attacker.pbPartner ###
          scoresAndTargets=[]
          @targets=[-1,-1,-1,-1]
          maxscore1=0
          maxscore2=0
          totalscore1=0
          totalscore2=0
          baseDamageArray=[]
          baseDamageArray2=[]
          baseDamageArray3=[] ###
          for j in 0...4
            next if attacker.moves[j].id < 1
            # check attacker.moves[j].basedamage and if this is 0 instead check the status method
            dmgValue = pbRoughDamage(attacker.moves[j],attacker,opponent,skill,attacker.moves[j].basedamage)
            if attacker.moves[j].basedamage!=0
              if opponent.hp==0
                dmgPercent = 0
              else
                dmgPercent = (dmgValue*100)/(opponent.hp)
                dmgPercent = 110 if dmgPercent > 110
              end
            else
              dmgPercent = pbStatusDamage(attacker.moves[j])
            end
            baseDamageArray.push(dmgPercent)
            #Second opponent
            dmgValue2 = pbRoughDamage(attacker.moves[j],attacker,otheropp,skill,attacker.moves[j].basedamage)
            if attacker.moves[j].basedamage!=0
              if otheropp.hp==0
                dmgPercent2=0
              else
                dmgPercent2 = (dmgValue2*100)/(otheropp.hp)
                dmgPercent2 = 110 if dmgPercent2 > 110
              end
            else
              dmgPercent2 = pbStatusDamage(attacker.moves[j])
            end
            baseDamageArray2.push(dmgPercent2)
            #Partner ###
            dmgValue3 = pbRoughDamage(attacker.moves[j],attacker,notopp,skill,attacker.moves[j].basedamage)
            if attacker.moves[j].basedamage!=0
              if notopp.hp==0
                dmgPercent3=0
              else
                dmgPercent3 = (dmgValue3*100)/(notopp.hp)
                dmgPercent3 = 110 if dmgPercent3 > 110
              end
            else
              dmgPercent3 = pbStatusDamage(attacker.moves[j])
            end
            baseDamageArray3.push(dmgPercent3)
          end
          for i in 0...4
            if pbCanChooseMove?(index,i,false)
              score1=pbGetMoveScore(attacker.moves[i],attacker,opponent,skill,baseDamageArray[i],baseDamageArray,i)
              score2=pbGetMoveScore(attacker.moves[i],attacker,otheropp,skill,baseDamageArray2[i],baseDamageArray2,i)
              totalscore = score1+score2
              if (attacker.moves[i].target&0x08)!=0 # Targets all users
                score1=totalscore # Consider both scores as it will hit BOTH targets
                score2=totalscore
                if attacker.pbPartner.isFainted? || (!attacker.pbPartner.abilitynulled && attacker.pbPartner.ability == PBAbilities::TELEPATHY) # No partner
                    score1*=1.66
                    score2*=1.66
                else
                  # If this move can also target the partner, get the partner's
                  # score too
                  v=pbRoughDamage(attacker.moves[i],attacker,attacker.pbPartner,skill,attacker.moves[i].basedamage)
                  p=(v*100)/(attacker.pbPartner.hp)
                  s=pbGetMoveScore(attacker.moves[i],attacker,attacker.pbPartner,skill,p)
                  s=110 if s>110
                  if !attacker.pbPartner.abilitynulled &&
                     (attacker.moves[i].type == PBTypes::FIRE && attacker.pbPartner.ability == PBAbilities::FLASHFIRE) ||
                     (attacker.moves[i].type == PBTypes::WATER && (attacker.pbPartner.ability == PBAbilities::WATERABSORB || attacker.pbPartner.ability == PBAbilities::STORMDRAIN || attacker.pbPartner.ability == PBAbilities::DRYSKIN)) ||
                     (attacker.moves[i].type == PBTypes::GRASS && attacker.pbPartner.ability == PBAbilities::SAPSIPPER) ||
                     (attacker.moves[i].type == PBTypes::ELECTRIC) && (attacker.pbPartner.ability == PBAbilities::VOLTABSORB || attacker.pbPartner.ability == PBAbilities::LIGHTNINGROD || attacker.pbPartner.ability == PBAbilities::MOTORDRIVE)
                    score1*=2.00
                    score2*=2.00
                  else
                    if (attacker.pbPartner.hp.to_f)/attacker.pbPartner.totalhp>0.10 || ((attacker.pbPartner.pbSpeed<attacker.pbSpeed) ^ (@trickroom!=0))
                      s = 100-s
                      s=0 if s<0
                      s/=100.0
                      s * 0.5 # multiplier to control how much to arbitrarily care about hitting partner; lower cares more
                      if (attacker.pbPartner.pbSpeed<attacker.pbSpeed) ^ (@trickroom!=0)
                        s * 0.5 # care more if we're faster and would knock it out before it attacks
                      end
                      score1*=s
                      score2*=s
                    end
                  end
                end
                score1=score1.to_i
                score2=score2.to_i
                PBDebug.log(sprintf("%s: Final Score after Multi-Target Adjustment: %d",PBMoves.getName(attacker.moves[i].id),score1))
                PBDebug.log(sprintf(""))
              end
              if attacker.moves[i].target==PBTargets::AllOpposing # Consider both scores as it will hit BOTH targets
                totalscore = score1+score2
                score1=totalscore
                score2=totalscore
                PBDebug.log(sprintf("%s: Final Score after Multi-Target Adjustment: %d",PBMoves.getName(attacker.moves[i].id),score1))
                PBDebug.log(sprintf(""))
              end
              @myChoices.push(i)
              scoresAndTargets.push([i*2,i,score1,opponent.index])
              scoresAndTargets.push([i*2+1,i,score2,otheropp.index])
            else
              scoresAndTargets.push([i*2,i,-1,opponent.index])
              scoresAndTargets.push([i*2+1,i,-1,otheropp.index])
            end
          end
          for i in 0...4 ### This whole bit
            if pbCanChooseMove?(index,i,false)
              movecode = attacker.moves[i].function
              if movecode == 0xDF || movecode == 0x63 || movecode == 0x67 || #Heal Pulse, Simple Beam, Skill Swap,
                movecode == 0xA0 || movecode == 0xC1 || movecode == 0x142 || #Frost Breath, Beat Up, Topsy-Turvy,
                movecode == 0x162 || movecode == 0x164 || movecode == 0x167 || #Floral Healing, Instruct, Pollen Puff,
                movecode == 0x169 || movecode == 0x170 || movecode == 0x55 || #Purify, Spotlight, Psych Up,
                movecode == 0x40 || movecode == 0x41 || movecode == 0x66  #Swagger, Flatter, Entrainment
                partnerscore=pbGetMoveScore(attacker.moves[i],attacker,notopp,skill,baseDamageArray3[i],baseDamageArray3,i)
                PBDebug.log(sprintf("%s: Score for using on partner: %d",PBMoves.getName(attacker.moves[i].id),partnerscore))
                PBDebug.log(sprintf(""))
                scoresAndTargets.push([i*10,i,partnerscore,notopp.index])
              end
            end
          end
          scoresAndTargets.sort!{|a,b|
             if a[2]==b[2] # if scores are equal
               a[0]<=>b[0] # sort by index (for stable comparison)
             else
               b[2]<=>a[2]
             end
          }
          for i in 0...scoresAndTargets.length
            idx=scoresAndTargets[i][1]
            thisScore=scoresAndTargets[i][2]
            if thisScore>0 || thisScore==-1
              if scores[idx]==0 || ((scores[idx]==thisScore && pbAIRandom(10)<5) ||
                 (scores[idx] < thisScore))
             #    (scores[idx]!=thisScore && pbAIRandom(10)<3))
                @scores[idx]=thisScore
                @targets[idx]=scoresAndTargets[i][3]
              end
            end
          end
        else
          # Choose a move. There is only 1 opposing Pokémon.
          if @doublebattle && opponent.isFainted?
            opponent=opponent.pbPartner
          end
          baseDamageArray=[]
          baseDamageArrayAdj=[]
          for j in 0...4
            next if attacker.moves[j].id < 1
            # check attacker.moves[j].basedamage and if this is 0 instead check the status method
            dmgValue = pbRoughDamage(attacker.moves[j],attacker,opponent,skill,attacker.moves[j].basedamage)
            if attacker.moves[j].basedamage!=0
              dmgPercent = (dmgValue*100)/(opponent.hp)
              dmgPercent = 110 if dmgPercent > 110
              if attacker.moves[j].function == 0x115 || attacker.moves[j].function == 0xC3 ||
               attacker.moves[j].function == 0xC4 || attacker.moves[j].function == 0xC5 ||
               attacker.moves[j].function == 0xC6 || attacker.moves[j].function == 0xC7 ||
               attacker.moves[j].function == 0xC8
                 dmgPercentAdj = (dmgPercent * 0.5)
              else
                 dmgPercentAdj = dmgPercent
              end
            else
              dmgPercent = pbStatusDamage(attacker.moves[j])
              dmgPercentAdj = dmgPercent
            end
            baseDamageArray.push(dmgPercent)
            baseDamageArrayAdj.push(dmgPercentAdj)
          end
          for i in 0...4
            if pbCanChooseMove?(index,i,false)
              @scores[i]=pbGetMoveScore(attacker.moves[i],attacker,opponent,skill,baseDamageArray[i],baseDamageArrayAdj,i)
              @myChoices.push(i)
            else
              @scores[i] = -1
            end
          end
        end
      end
    end

    def pbChooseMoves(index)
      maxscore=0
      totalscore=0
      attacker=@battlers[index]
      skill=pbGetOwner(attacker.index).skill rescue 0
      wildbattle=!@opponent && pbIsOpposing?(index)
      for i in 0...4
        #next if scores[i] == -1
        @scores[i]=0 if @scores[i]<0
        maxscore=@scores[i] if @scores[i]>maxscore
        totalscore+=@scores[i]
      end
      # Minmax choices depending on AI
      if !wildbattle && skill>=PBTrainerAI.mediumSkill
        threshold=(skill>=PBTrainerAI.bestSkill) ? 1.5 : (skill>=PBTrainerAI.highSkill) ? 2 : 3
        newscore=(skill>=PBTrainerAI.bestSkill) ? 5 : (skill>=PBTrainerAI.highSkill) ? 10 : 15
        for i in 0...@scores.length
          if @scores[i]>newscore && @scores[i]*threshold<maxscore
            totalscore-=(@scores[i]-newscore)
            @scores[i]=newscore
          end
        end
      end
      if $INTERNAL
        x="[#{attacker.pbThis}: "
        j=0
        for i in 0...4
          if attacker.moves[i].id!=0
            x+=", " if j>0
            x+=PBMoves.getName(attacker.moves[i].id)+"="+@scores[i].to_s
            j+=1
          end
        end
        x+="]"
        PBDebug.log(x)
      end
      if !wildbattle #&& maxscore>100
        stdev=pbStdDev(@scores)
          preferredMoves=[]
          for i in 0...4
            if attacker.moves[i].id!=0 && (@scores[i] >= (maxscore*0.95)) && pbCanChooseMove?(index,i,false)
              preferredMoves.push(i)
              preferredMoves.push(i) if @scores[i]==maxscore # Doubly prefer the best move
            end
          end
          if preferredMoves.length>0
            i=preferredMoves[pbAIRandom(preferredMoves.length)]
            PBDebug.log("[Prefer "+PBMoves.getName(attacker.moves[i].id)+"]") if $INTERNAL
            pbRegisterMove(index,i,false)
            target=@targets[i] if @targets
            if @doublebattle && target && target>=0
              pbRegisterTarget(index,target)
            end
            return
          end
        #end
      end
      PBDebug.log("If this battle is not wild, something has gone wrong in scoring moves (no preference chosen).") if $INTERNAL
      if !wildbattle && attacker.turncount
        badmoves=false
        if ((maxscore<=20 && attacker.turncount>2) ||
           (maxscore<=30 && attacker.turncount>5)) && pbAIRandom(10)<8
          badmoves=true
        end
        if totalscore<100 && attacker.turncount>1
          badmoves=true
          movecount=0
          for i in 0...4
            if attacker.moves[i].id!=0
              if @scores[i]>0 && attacker.moves[i].basedamage>0
                badmoves=false
              end
              movecount+=1
            end
          end
          badmoves=badmoves && pbAIRandom(10)!=0
        end
      end
      if maxscore<=0
        # If all scores are 0 or less, choose a move at random
        if @myChoices.length>0
          pbRegisterMove(index,@myChoices[pbAIRandom(@myChoices.length)],false)
        else
          pbAutoChooseMove(index)
        end
      else
        randnum=pbAIRandom(totalscore)
        cumtotal=0
        for i in 0...4
          if @scores[i]>0
            cumtotal+=@scores[i]
            if randnum<cumtotal
              pbRegisterMove(index,i,false)
              target=@targets[i] if @targets
              break
            end
          end
        end
      end
      if @doublebattle && target && target>=0
        pbRegisterTarget(index,target)
      end
    end

    ################################################################################
    # Decide whether the opponent should use a Z-Move.
    ################################################################################
    def pbEnemyShouldZMove?(index)
      return pbCanZMove?(index) #Conditions based on effectiveness and type handled later
    end
end
