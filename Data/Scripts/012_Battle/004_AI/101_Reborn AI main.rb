class PokeBattle_Battle
  # Legacy method that should stop being used.
  def pbGetOwner(battlerIndex)
    if opposes?(battlerIndex)
      if @opponent.is_a?(Array)
        return (battlerIndex==1) ? @opponent[0] : @opponent[1]
      else
        return @opponent
      end
    else
      if @player.is_a?(Array)
        return (battlerIndex==0) ? @player[0] : @player[1]
      else
        return @player
      end
    end
  end

  ##############################################################################
  # Choose an action.
  ##############################################################################
  def pbChooseEnemyZMove(index)  #Put specific cases for trainers using status Z-Moves
    chosenmove=false
    chosenindex=-1
    attacker = @battlers[index]
    opponent=attacker.pbOppositeOpposing
    otheropp=opponent.pbPartner
    skill=pbGetOwner(attacker.index).skill || 0
    for i in 0..3
      move=@battlers[index].moves[i]
      if @battlers[index].pbCompatibleZMoveFromMove?(move)
        if move.id == (PBMoves::CONVERSION) ||  move.id == (PBMoves::SPLASH)
          pbRegisterZMove(index)
          pbRegisterMove(index,i,false)
          pbRegisterTarget(index,opponent.index)
          return
        end
        if !chosenmove
          chosenindex = i
          chosenmove=move
        else
          if move.basedamage>chosenmove.basedamage
            chosenindex=i
            chosenmove=move
          end
        end
      end
    end

    #oppeff1 = chosenmove.pbTypeModifier(chosenmove.type,attacker,opponent)
    oppeff1 = pbTypeModNoMessages(chosenmove.type,attacker,opponent,chosenmove,skill)
    #oppeff2 = chosenmove.pbTypeModifier(chosenmove.type,attacker,otheropp)
    oppeff2 = pbTypeModNoMessages(chosenmove.type,attacker,otheropp,chosenmove,skill)
    oppeff1 = 0 if opponent.hp<(opponent.totalhp/2.0).round
    oppeff1 = 0 if (opponent.effects[PBEffects::Substitute]>0 || opponent.effects[PBEffects::Disguise]) && attacker.item!=(PBItems::KOMMONIUMZ2)
    oppeff2 = 0 if otheropp.hp<(otheropp.totalhp/2.0).round
    oppeff2 = 0 if (otheropp.effects[PBEffects::Substitute]>0 || otheropp.effects[PBEffects::Disguise]) && attacker.item!=(PBItems::KOMMONIUMZ2)
    oppmult=0
    for i in 1..7 #iterates through all the stats
      oppmult+=opponent.stages[i] if opponent.stages[i]>0
    end
    othermult=0
    for i in 1..7
      othermult+=otheropp.stages[i] if otheropp.stages[i]>0
    end
    if (oppeff1<4) && ((oppeff2<4) || otheropp.hp==0)
      pbChooseMoves(index)
    elsif oppeff1>oppeff2
      pbRegisterZMove(index)
      pbRegisterMove(index,chosenindex,false)
      pbRegisterTarget(index,opponent.index)
    elsif oppeff1<oppeff2
      pbRegisterZMove(index)
      pbRegisterMove(index,chosenindex,false)
      pbRegisterTarget(index,otheropp.index)
    elsif oppeff1==oppeff2
      if oppmult > othermult
        pbRegisterZMove(index)
        pbRegisterMove(index,chosenindex,false)
        pbRegisterTarget(index,opponent.index)
      elsif oppmult < othermult
        pbRegisterZMove(index)
        pbRegisterMove(index,chosenindex,false)
        pbRegisterTarget(index,otheropp.index)
      else
        if otheropp.hp > opponent.hp
          pbRegisterZMove(index)
          pbRegisterMove(index,chosenindex,false)
          pbRegisterTarget(index,otheropp.index)
        else
          pbRegisterZMove(index)
          pbRegisterMove(index,chosenindex,false)
          pbRegisterTarget(index,opponent.index)
        end
      end
    end
  end

end
