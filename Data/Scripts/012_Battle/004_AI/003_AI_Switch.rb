class PokeBattle_AI
  #=============================================================================
  # Decide whether the opponent should switch Pokémon
  #=============================================================================
  def pbEnemyShouldWithdraw?(idxBattler)
    return pbEnemyShouldWithdrawEx?(idxBattler,false)
  end

  def pbEnemyShouldWithdrawEx?(idxBattler,forceSwitch)
    return false #Thundaga, make enemies NEVER try to switch
    return false if @battle.wildBattle?
    shouldSwitch = forceSwitch
    batonPass = -1
    moveType = -1
    skill = @battle.pbGetOwnerFromBattlerIndex(idxBattler).skill || 0
    battler = @battle.battlers[idxBattler]
    # If Pokémon is within 6 levels of the foe, and foe's last move was
    # super-effective and powerful
    if !shouldSwitch && battler.turnCount>0 && skill>=PBTrainerAI.highSkill
      target = battler.pbDirectOpposing(true)
      if !target.fainted? && target.lastMoveUsed>0 &&
         (target.level-battler.level).abs<=6
        moveData = pbGetMoveData(target.lastMoveUsed)
        moveType = moveData[MOVE_TYPE]
        typeMod = pbCalcTypeMod(moveType,target,battler)
        if PBTypes.superEffective?(typeMod) && moveData[MOVE_BASE_DAMAGE]>50
          switchChance = (moveData[MOVE_BASE_DAMAGE]>70) ? 30 : 20
          shouldSwitch = (pbAIRandom(100)<switchChance)
        end
      end
    end
    # Pokémon can't do anything (must have been in battle for at least 5 rounds)
    if !@battle.pbCanChooseAnyMove?(idxBattler) &&
       battler.turnCount && battler.turnCount>=5
      shouldSwitch = true
    end
    # Pokémon is Perish Songed and has Baton Pass
    if skill>=PBTrainerAI.highSkill && battler.effects[PBEffects::PerishSong]==1
      battler.eachMoveWithIndex do |m,i|
        next if m.function!="0ED"   # Baton Pass
        next if !@battle.pbCanChooseMove?(idxBattler,i,false)
        batonPass = i
        break
      end
    end
    # Pokémon will faint because of bad poisoning at the end of this round, but
    # would survive at least one more round if it were regular poisoning instead
    if battler.status==PBStatuses::POISON && battler.statusCount>0 &&
       skill>=PBTrainerAI.highSkill
      toxicHP = battler.totalhp/16
      nextToxicHP = toxicHP*(battler.effects[PBEffects::Toxic]+1)
      if battler.hp<=nextToxicHP && battler.hp>toxicHP*2
        shouldSwitch = true if pbAIRandom(100)<80
      end
    end
    # Pokémon is Encored into an unfavourable move
    if battler.effects[PBEffects::Encore]>0 && skill>=PBTrainerAI.mediumSkill
      idxEncoredMove = battler.pbEncoredMoveIndex
      if idxEncoredMove>=0
        scoreSum   = 0
        scoreCount = 0
        battler.eachOpposing do |b|
          scoreSum += pbGetMoveScore(battler.moves[idxEncoredMove],battler,b,skill)
          scoreCount += 1
        end
        if scoreCount>0 && scoreSum/scoreCount<=20
          shouldSwitch = true if pbAIRandom(100)<80
        end
      end
    end
    # If there is a single foe and it is resting after Hyper Beam or is
    # Truanting (i.e. free turn)
    if @battle.pbSideSize(battler.index+1)==1 &&
       !battler.pbDirectOpposing.fainted? && skill>=PBTrainerAI.highSkill
      opp = battler.pbDirectOpposing
      if opp.effects[PBEffects::HyperBeam]>0 ||
         (opp.hasActiveAbility?(:TRUANT) && opp.effects[PBEffects::Truant])
        shouldSwitch = false if pbAIRandom(100)<80
      end
    end
    # Sudden Death rule - I'm not sure what this means
    if @battle.rules["suddendeath"] && battler.turnCount>0
      if battler.hp<=battler.totalhp/4 && pbAIRandom(100)<30
        shouldSwitch = true
      elsif battler.hp<=battler.totalhp/2 && pbAIRandom(100)<80
        shouldSwitch = true
      end
    end
    # Pokémon is about to faint because of Perish Song
    if battler.effects[PBEffects::PerishSong]==1
      shouldSwitch = true
    end
    if shouldSwitch
      list = []
      @battle.pbParty(idxBattler).each_with_index do |pkmn,i|
        next if !@battle.pbCanSwitch?(idxBattler,i)
        # If perish count is 1, it may be worth it to switch
        # even with Spikes, since Perish Song's effect will end
        if battler.effects[PBEffects::PerishSong]!=1
          # Will contain effects that recommend against switching
          spikes = battler.pbOwnSide.effects[PBEffects::Spikes]
          # Don't switch to this if too little HP
          if spikes>0
            spikesDmg = [8,6,4][spikes-1]
            if pkmn.hp<=pkmn.totalhp/spikesDmg
              next if !pkmn.hasType?(:FLYING) && !pkmn.hasActiveAbility?(:LEVITATE)
            end
          end
        end
        # moveType is the type of the target's last used move
        if moveType>=0 && PBTypes.ineffective?(pbCalcTypeMod(moveType,battler,battler))
          weight = 65
          typeMod = pbCalcTypeModPokemon(pkmn,battler.pbDirectOpposing(true))
          if PBTypes.superEffective?(typeMod.to_f/PBTypeEffectivenesss::NORMAL_EFFECTIVE)
            # Greater weight if new Pokemon's type is effective against target
            weight = 85
          end
          list.unshift(i) if pbAIRandom(100)<weight   # Put this Pokemon first
        elsif moveType>=0 && PBTypes.resistant?(pbCalcTypeMod(moveType,battler,battler))
          weight = 40
          typeMod = pbCalcTypeModPokemon(pkmn,battler.pbDirectOpposing(true))
          if PBTypes.superEffective?(typeMod.to_f/PBTypeEffectivenesss::NORMAL_EFFECTIVE)
            # Greater weight if new Pokemon's type is effective against target
            weight = 60
          end
          list.unshift(i) if pbAIRandom(100)<weight   # Put this Pokemon first
        else
          list.push(i)   # put this Pokemon last
        end
      end
      if list.length>0
        if batonPass>=0 && @battle.pbRegisterMove(idxBattler,batonPass,false)
          PBDebug.log("[AI] #{battler.pbThis} (#{idxBattler}) will use Baton Pass to avoid Perish Song")
          return true
        end
        if @battle.pbRegisterSwitch(idxBattler,list[0])
          PBDebug.log("[AI] #{battler.pbThis} (#{idxBattler}) will switch with " +
                      "#{@battle.pbParty(idxBattler)[list[0]].name}")
          return true
        end
      end
    end
    return false
  end

  #=============================================================================
  # Choose a replacement Pokémon
  #=============================================================================
  def pbDefaultChooseNewEnemy(idxBattler,party)
    enemies = []
    party.each_with_index do |_p,i|
      enemies.push(i) if @battle.pbCanSwitchLax?(idxBattler,i)
    end
    return -1 if enemies.length==0
    return pbChooseBestNewEnemy(idxBattler,party,enemies)
  end

  def pbChooseBestNewEnemy(idxBattler,party,enemies)
    return -1 if !enemies || enemies.length==0
    best    = -1
    bestSum = 0
    movesData = pbLoadMovesData
    enemies.each do |i|
      pkmn = party[i]
      sum  = 0
      pkmn.moves.each do |m|
        next if m.id==0
        moveData = movesData[m.id]
        next if moveData[MOVE_BASE_DAMAGE]==0
        @battle.battlers[idxBattler].eachOpposing do |b|
          bTypes = b.pbTypes(true)
          sum += PBTypes.getCombinedEffectiveness(moveData[MOVE_TYPE],
             bTypes[0],bTypes[1],bTypes[2])
        end
      end
      if best==-1 || sum>bestSum
        best = i
        bestSum = sum
      end
    end
    return best
  end
end
