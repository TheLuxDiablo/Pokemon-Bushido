class PokeBattle_Battle
  attr_accessor :scores
  attr_accessor :targets
  attr_accessor :myChoices

################################################################################
# Choose an action.
################################################################################
  def pbDefaultChooseEnemyCommand(index)
    if !pbCanShowFightMenu?(index)
      return if pbEnemyShouldUseItem?(index)
      #return if pbEnemyShouldWithdraw?(index) Old Switching Method
      return if pbShouldSwitch?(index)
      pbAutoChooseMove(index)
      return
    else
      pbBuildMoveScores(index) #grab the array of scores/targets before doing anything else
      #print 1
      return if pbShouldSwitch?(index)
      #print 2
      #return if pbEnemyShouldWithdraw?(index) Old Switching Method
      return if pbEnemyShouldUseItem?(index)
      #print 3
      #return if pbAutoFightMenu(index)
      #print 4
      pbRegisterUltraBurst(index) if pbEnemyShouldUltraBurst?(index)
      pbRegisterMegaEvolution(index) if pbEnemyShouldMegaEvolve?(index)
      #print 5
      if pbEnemyShouldZMove?(index)
        return pbChooseEnemyZMove(index)
      end
      #print 6
      pbChooseMoves(index)
      #print 7
    end
  end

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

  ################################################################################
  # Decide whether the opponent should Mega Evolve their Pokémon.
  ################################################################################
  def pbEnemyShouldMegaEvolve?(index)
    # Simple "always should if possible"
    return pbCanMegaEvolve?(index)
  end


  ################################################################################
  # Decide whether the opponent should Ultra Burst their Pokémon.
  ################################################################################
  def pbEnemyShouldUltraBurst?(index)
    # Simple "always should if possible"
    return pbCanUltraBurst?(index)
  end

################################################################################
# Other functions.
################################################################################
  def pbStdDev(scores)
    n=0
    sum=0
    scores.each{|s| sum+=s; n+=1 }
    return 0 if n==0
    mean=sum.to_f/n.to_f
    varianceTimesN=0
    for i in 0...scores.length
      if scores[i]>0
        deviation=scores[i].to_f-mean
        varianceTimesN+=deviation*deviation
      end
    end
    # Using population standard deviation
    # [(n-1) makes it a sample std dev, would be 0 with only 1 sample]
    return Math.sqrt(varianceTimesN/n)
  end
end
