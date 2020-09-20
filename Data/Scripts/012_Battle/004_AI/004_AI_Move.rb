class PokeBattle_AI
  #=============================================================================
  # Main move-choosing method (moves with higher scores are more likely to be
  # chosen)
  #=============================================================================
  def pbChooseMove
    # Get scores and targets for each move
    choices = pbGetMoveScores

    # Figure out useful information about the choices
    totalScore = 0
    maxScore   = 0
    choices.each do |c|
      totalScore += c[1]
      maxScore = c[1] if maxScore < c[1]
    end

    # Find any preferred moves and just choose from them
    if skill_check(PBTrainerAI.highSkill) && maxScore > 100
      stDev = pbStdDev(choices)
      if stDev >= 40 && pbAIRandom(100) < 90
        preferredMoves = []
        choices.each do |c|
          next if c[1] < 200 && c[1] < maxScore * 0.8
          preferredMoves.push(c)
          preferredMoves.push(c) if c[1] == maxScore   # Doubly prefer the best move
        end
        if preferredMoves.length > 0
          m = preferredMoves[pbAIRandom(preferredMoves.length)]
          PBDebug.log("[AI] #{@user.pbThis} (#{@user.index}) prefers #{@user.moves[m[0]].name}")
          @battle.pbRegisterMove(@user.index, m[0], false)
          @battle.pbRegisterTarget(@user.index, m[2]) if m[2] >= 0
          return
        end
      end
    end

    # Decide whether all choices are bad, and if so, try switching instead
    if !@wildBattler && skill_check(PBTrainerAI.highSkill)
      badMoves = false
      if (maxScore <= 20 && @user.turnCount > 2) ||
         (maxScore <= 40 && @user.turnCount > 5)
        badMoves = true if pbAIRandom(100) < 80
      end
      if !badMoves && totalScore < 100 && @user.turnCount > 1
        badMoves = true
        choices.each do |c|
          next if !@user.moves[c[0]].damagingMove?
          badMoves = false
          break
        end
        badMoves = false if badMoves && pbAIRandom(100) < 10
      end
      if badMoves && pbEnemyShouldWithdrawEx?(true)
        if $INTERNAL
          PBDebug.log("[AI] #{@user.pbThis} (#{@user.index}) will switch due to terrible moves")
        end
        return
      end
    end

    # If there are no calculated choices, pick one at random
    if choices.length == 0
      PBDebug.log("[AI] #{@user.pbThis} (#{@user.index}) doesn't want to use any moves; picking one at random")
      @user.eachMoveWithIndex do |_m, i|
        next if !@battle.pbCanChooseMove?(@user.index, i, false)
        choices.push([i, 100, -1])   # Move index, score, target
      end
      if choices.length == 0   # No moves are physically possible to use
        @user.eachMoveWithIndex do |_m, i|
          choices.push([i, 100, -1])   # Move index, score, target
        end
      end
    end

    # Randomly choose a move from the choices and register it
    randNum = pbAIRandom(totalScore)
    choices.each do |c|
      randNum -= c[1]
      next if randNum >= 0
      @battle.pbRegisterMove(@user.index, c[0], false)
      @battle.pbRegisterTarget(@user.index, c[2]) if c[2] >= 0
      break
    end

    # Log the result
    if @battle.choices[@user.index][2]
      PBDebug.log("[AI] #{@user.pbThis} (#{@user.index}) will use #{@battle.choices[@user.index][2].name}")
    end
  end

  #=============================================================================
  # Get scores for the user's moves
  # NOTE: A move is only added to the choices array if it has a non-zero score.
  #=============================================================================
  def pbGetMoveScores
    # Get scores and targets for each move
    choices = []
    @user.eachMoveWithIndex do |_m, i|
      next if !@battle.pbCanChooseMove?(@user.index, i, false)
      if @wildBattler
        pbRegisterMoveWild(i, choices)
      else
        pbRegisterMoveTrainer(i, choices)
      end
    end
    # Log the available choices
    if $INTERNAL
      logMsg = "[AI] Move choices for #{@user.pbThis(true)} (#{@user.index}): "
      choices.each_with_index do |c, i|
        logMsg += "#{@user.moves[c[0]].name}=#{c[1]}"
        logMsg += " (target #{c[2]})" if c[2] >= 0
        logMsg += ", " if i < choices.length-1
      end
      PBDebug.log(logMsg)
    end
    return choices
  end

  #=============================================================================
  # Get scores for the given move against each possible target
  #=============================================================================
  # Wild Pokémon choose their moves randomly.
  def pbRegisterMoveWild(idxMove, choices)
    choices.push([idxMove, 100, -1])   # Move index, score, target
  end

  # Trainer Pokémon calculate how much they want to use each of their moves.
  def pbRegisterMoveTrainer(idxMove, choices)
    move = @user.moves[idxMove]
    targetType = move.pbTarget(@user)
    if PBTargets.multipleTargets?(targetType)
      # If move affects multiple battlers and you don't choose a particular one
      totalScore = 0
      @battle.eachBattler do |b|
        next if !@battle.pbMoveCanTarget?(@user.index, b.index, targetType)
        score = pbGetMoveScore(move, b)
        totalScore += ((@user.opposes?(b)) ? score : -score)
      end
      choices.push([idxMove, totalScore, -1]) if totalScore > 0
    elsif PBTargets.noTargets?(targetType)
      # If move has no targets, affects the user, a side or the whole field
      score = pbGetMoveScore(move, @user)
      choices.push([idxMove, score, -1]) if score > 0
    else
      # If move affects one battler and you have to choose which one
      scoresAndTargets = []
      @battle.eachBattler do |b|
        next if !@battle.pbMoveCanTarget?(@user.index, b.index, targetType)
        next if PBTargets.canChooseFoeTarget?(targetType) && !@user.opposes?(b)
        score = pbGetMoveScore(move, b)
        scoresAndTargets.push([score, b.index]) if score > 0
      end
      if scoresAndTargets.length > 0
        # Get the one best target for the move
        scoresAndTargets.sort! { |a, b| b[0] <=> a[0] }
        choices.push([idxMove, scoresAndTargets[0][0], scoresAndTargets[0][1]])
      end
    end
  end

  #=============================================================================
  # Get a score for the given move being used against the given target
  #=============================================================================
  def pbGetMoveScore(move, target)
    if move.damagingMove?
      # Is also the predicted damage amount as a percentage of target's current HP
      score = pbGetDamagingMoveBaseScore(move, target)
    else   # Status moves
      # Gets base score depending on move's effect
      score = pbGetStatusMoveBaseScore(move, target)
    end
    # Use the predicted damage as the base score, and modify it according to the
    # move's effect
    score = pbGetMoveScoreFunctions(score, move, target)

    # A score of 0 here means it absolutely should not be used
    return 0 if score <= 0

    if skill_check(PBTrainerAI.mediumSkill)
      # Prefer damaging moves if AI has no more Pokémon or AI is less clever
      if @battle.pbAbleNonActiveCount(@user.idxOwnSide) == 0
        if !(skill_check(PBTrainerAI.highSkill) && @battle.pbAbleNonActiveCount(target.idxOwnSide) > 0)
          if move.statusMove?
            score /= 1.5
          elsif target.hp <= target.totalhp / 2
            score *= 1.5
          end
        end
      end
      # Don't prefer attacking the target if they'd be semi-invulnerable
      if skill_check(PBTrainerAI.highSkill) && move.accuracy > 0 &&
         (target.semiInvulnerable? || target.effects[PBEffects::SkyDrop] >= 0)
        miss = true
        miss = false if @user.hasActiveAbility?(:NOGUARD) || target.hasActiveAbility?(:NOGUARD)
        if miss && pbRoughStat(@user, PBStats::SPEED) > pbRoughStat(target, PBStats::SPEED)
          # Knows what can get past semi-invulnerability
          if target.effects[PBEffects::SkyDrop] >= 0
            miss = false if move.hitsFlyingTargets?
          else
            if target.inTwoTurnAttack?("0C9", "0CC", "0CE")   # Fly, Bounce, Sky Drop
              miss = false if move.hitsFlyingTargets?
            elsif target.inTwoTurnAttack?("0CA")          # Dig
              miss = false if move.hitsDiggingTargets?
            elsif target.inTwoTurnAttack?("0CB")          # Dive
              miss = false if move.hitsDivingTargets?
            end
          end
        end
        score -= 80 if miss
      end

      # Pick a good move for the Choice items
      if @user.hasActiveItem?([:CHOICEBAND, :CHOICESPECS, :CHOICESCARF])
        if move.baseDamage >= 60;     score += 60
        elsif move.damagingMove?;     score += 30
        elsif move.function == "0F2"; score += 70   # Trick
        else;                         score -= 60
        end
      end

      # If user is asleep, prefer moves that are usable while asleep
      if @user.status == PBStatuses::SLEEP && !move.usableWhenAsleep?
        @user.eachMove do |m|
          next unless m.usableWhenAsleep?
          score -= 60
          break
        end
      end

      # If user is frozen, prefer a move that can thaw the user
      if @user.status == PBStatuses::FROZEN
        if move.thawsUser?
          score += 40
        else
          @user.eachMove do |m|
            next unless m.thawsUser?
            score -= 60
            break
          end
        end
      end

      # If target is frozen, don't prefer moves that could thaw them
      if target.status == PBStatuses::FROZEN
        @user.eachMove do |m|
          next if m.thawsUser?
          score -= 60
          break
        end
      end
    end

    # Account for accuracy of move
    accuracy = pbRoughAccuracy(move, target)
    score *= accuracy / 100.0

    # Move has a really low score; discard it
    score = 0 if score <= 10 && skill_check(PBTrainerAI.highSkill)

    score = score.to_i
    score = 0 if score < 0
    return score
  end

  #=============================================================================
  # Add to a move's score based on how much damage it will deal (as a percentage
  # of the target's current HP)
  #=============================================================================
  def pbGetDamagingMoveBaseScore(move, target)
    # Don't prefer moves that are ineffective because of abilities or effects
    return 0 if pbCheckMoveImmunity(move, target)
    # Calculate how much damage the move will do (roughly)
    baseDmg = pbMoveBaseDamage(move, target)
    realDamage = pbRoughDamage(move, target, baseDmg)
    # Two-turn attacks waste 2 turns to deal one lot of damage
    if move.chargingTurnMove? || move.function == "0C2"   # Hyper Beam
      realDamage *= 2 / 3   # Not halved because semi-invulnerable during use or hits first turn
    end
    # Prefer flinching external effects (note that move effects which cause
    # flinching are dealt with in the function code part of score calculation)
    if skill_check(PBTrainerAI.mediumSkill)
      if !target.hasActiveAbility?(:INNERFOCUS) &&
          !target.hasActiveAbility?(:SHIELDDUST) &&
          target.effects[PBEffects::Substitute] == 0
        canFlinch = false
        if move.canKingsRock? && @user.hasActiveItem?([:KINGSROCK, :RAZORFANG])
          canFlinch = true
        end
        if @user.hasActiveAbility?(:STENCH) && !move.flinchingMove?
          canFlinch = true
        end
        realDamage *= 1.3 if canFlinch
      end
    end
    # Convert damage to percentage of target's remaining HP
    damagePercentage = realDamage * 100.0 / target.hp
    # Don't prefer weak attacks
#    damagePercentage /= 2 if damagePercentage<20
    # Prefer damaging attack if level difference is significantly high
    damagePercentage *= 1.2 if @user.level - 10 > target.level
    # Adjust score
    damagePercentage = 120 if damagePercentage > 120   # Treat all lethal moves the same
    damagePercentage += 40 if damagePercentage > 100   # Prefer moves likely to be lethal
    score = damagePercentage.to_i
    return score
  end

  def pbGetStatusMoveBaseScore(move, target)
    # TODO: Make sure all status moves are accounted for.
    # TODO: Duplicates:
    # 003 cause sleep - Dark Void (15), Grass Whistle (15), Hypnosis (15), Sing (15),
    #                   Lovely Kiss (20), Sleep Powder (20), Spore (60)
    # 005 poisons - Poison Powder (15), Poison Gas (20)
    # 007 paralyses - Stun Spore (25), Glare (30), Thunder Wave (30)
    # 013 confuses - Teeter Dance (5), Supersonic (10), Sweet Kiss (20), Confuse Ray (25)
    # 01C user's Atk +1 - Howl (10), Sharpen (10), Medicate (15)
    # 030 user's Spd +2 - Agility (15), Rock Polish (25)
    # 042 target Atk -1 - Growl (10), Baby-Doll Eyes (15)
    # 047 target acc -1 - Sand Attack (5), Flash (10), Kinesis (10), Smokescreen (10)
    # 04B target Atk -2 - Charm (10), Feather Dance (15)
    # 04D target Spd -2 - String Shot (10), Cotton Spore (15), Scary Face (15)
    # 04F target SpDef -2 - Metal Sound (10), Fake Tears (15)
    case move.function
    when "013", "047", "049", "052", "053", "057", "058", "059", "05E", "061",
         "062", "066", "067", "09C", "09D", "09E", "0A6", "0A7", "0A8", "0AB",
         "0AC", "0B1", "0B2", "0B8", "0BB", "0E6", "0E8", "0F6", "0F9", "10F",
         "114", "118", "119", "120", "124", "138", "13E", "13F", "143", "152",
         "15E", "161", "16A", "16B"
      return 5
    when "013", "01C", "01D", "01E", "023", "027", "028", "029", "037", "042",
         "043", "047", "04B", "04D", "04F", "051", "055", "060", "0B7", "0F8",
         "139", "13A", "13C", "148"
      return 10
    when "003", "005", "018", "01C", "021", "022", "030", "042", "04A", "04B",
         "04C", "04D", "04E", "04F", "05C", "05D", "065", "0B0", "0B5", "0DB",
         "0DF", "0E3", "0E4", "0FF", "100", "101", "102", "137", "13D", "140",
         "142", "151", "15C", "16E"
      return 15
    when "003", "004", "005", "013", "040", "041", "054", "056", "05F", "063",
         "064", "068", "069", "0AE", "0AF", "0B6", "0D9", "0DA", "0E5", "0EB",
         "0EF", "145", "146", "159"
      return 20
    when "006", "007", "00A", "013", "016", "01B", "02A", "02F", "030", "031",
         "033", "034", "038", "03A", "05A", "0AA", "0B9", "0BA", "0D5", "0D6",
         "0D7", "0D8", "0DC", "0E7", "0F2", "10C", "112", "117", "141", "160",
         "16D"
      return 25
    when "007", "024", "025", "02C", "0B3", "0B4", "0BC", "0ED", "103", "104",
         "105", "10D", "11F", "14C", "154", "155", "156", "15B", "173"
      return 30
    when "019", "02E", "032", "039", "05B", "0A2", "0A3", "149", "14B", "168"
      return 35
    when "026", "02B", "035", "036", "14E"
      return 40
    when "003", "153", "167"
      return 60
    end
    # "001", "01A", "048", "0A1", "0E2", "0EA", "0F3", "10E", "11A", "11D",
    # "11E", "14A"
    return 0
  end
end
