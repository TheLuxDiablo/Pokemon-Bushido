class PokeBattle_AI
  #=============================================================================
  # Get a score for the given move based on its effect
  #=============================================================================
  def pbGetMoveScoreFunctions(score)
    case @move.function
    #---------------------------------------------------------------------------
    when "000"   # No extra effect
    #---------------------------------------------------------------------------
    when "001"   # Splash (does nothing)
    #---------------------------------------------------------------------------
    when "002"   # Struggle
    #---------------------------------------------------------------------------
    when "003"   # Make target fall asleep
      # Can't use Dark Void if user isn't Darkrai
      if NEWEST_BATTLE_MECHANICS && isConst?(@move.id, PBMoves, :DARKVOID)
        return 0 if !@user.isSpecies?(:DARKRAI) &&
                    !isConst?(@user.effects[PBEffects::TransformSpecies], PBSpecies, :DARKRAI)
      end
      # Check whether the target can be put to sleep
      if @target.pbCanSleep?(@user, false) && @target.effects[PBEffects::Yawn] == 0
        mini_score = 1.0
        # Inherently prefer
        mini_score *= 1.3

        # Prefer if user has a move that depends on the target being asleep
        mini_score *= 1.5 if @user.pbHasMoveFunction?("0DE", "10F")   # Dream Eater, Nightmare
        # Prefer if user has an ability that depends on the target being asleep
        mini_score *= 1.5 if skill_check(AILevel.medium) && @user.hasActiveAbility?(:BADDREAMS)
        # TODO: Prefer if user has certain roles (walls/cleric/pivot).
        # TODO: Prefer if user has any setup moves (i.e. it wants to stall to
        #       get them set up).
        # Prefer if user knows some moves that work with stalling tactics
        mini_score *= 1.5 if @user.pbHasMoveFunction?("0DC", "10C")   # Leech Seed, Substitute
        # Prefer if user can heal at the end of each round
        # TODO: Needs to account for more healing effects. Aqua Ring, Black
        #       Sludge, etc.
        if skill_check(AILevel.medium) &&
           (@user.hasActiveItem?(:LEFTOVERS) ||
           (@user.hasActiveAbility?(:POISONHEAL) && user.poisoned?))
          mini_score *= 1.2
        end

        # Prefer if target is at full HP
        mini_score *= 1.2 if @target.hp == @target.totalhp
        # Prefer if target's stats are raised
        sum_stages = 0
        PBStats.eachBattleStat { |s| sum_stages += @target.stages[s] }
        mini_score *= 1 + sum_stages * 0.05 if sum_stages > 0
        # Don't prefer if target is confused or infatuated
        mini_score *= 0.6 if @target.effects[PBEffects::Confusion] > 0
        mini_score *= 0.7 if @target.effects[PBEffects::Attract] >= 0
        # TODO: Don't prefer if target has previously used a move that is usable
        #       while asleep.
        if skill_check(AILevel.best)
          mini_score *= 0.1 if check_for_move(@target) { |move| move.usableWhenAsleep? }
        end
        # Don't prefer if target can cure itself, benefits from being asleep, or
        # can pass sleep back to the user
        # TODO: Check for other effects to list here.
        if skill_check(AILevel.best) && @target.abilityActive?
          if isConst?(@target.ability, PBAbilities, :SHEDSKIN)
            return 0
          elsif isConst?(@target.ability, PBAbilities, :HYDRATION) &&
             [PBWeather::Rain, PBWeather::HeavyRain].include?(@battle.pbWeather)
            return 0
          elsif isConst?(@target.ability, PBAbilities, :NATURALCURE)
            mini_score *= 0.3
          elsif isConst?(@target.ability, PBAbilities, :MARVELSCALE)
            mini_score *= 0.7
          elsif isConst?(@target.ability, PBAbilities, :SYNCHRONIZE) && @user.pbHasAnyStatus?
            mini_score *= 0.3
          end
        end

        # Prefer if user is faster than the target
        mini_score *= 1.3 if @user_faster
        # TODO: Prefer if user's moves won't do much damage to the target.

        # Apply mini_score to score
        mini_score = apply_effect_chance_to_score(mini_score)
        score *= mini_score
      else
        return 0 if @move.statusMove?
      end
    #---------------------------------------------------------------------------
    when "004"   # Yawn (target falls asleep at end of next round)
      return 0 if @target.effects[PBEffects::Yawn] > 0 || !@target.pbCanSleep?(@user, false)
      mini_score = 1.0
      # Inherently prefer
      mini_score *= 1.2

      # Prefer if user has a move that depends on the target being asleep
      mini_score *= 1.4 if @user.pbHasMoveFunction?("0DE", "10F")   # Dream Eater, Nightmare
      # Prefer if user has an ability that depends on the target being asleep
      mini_score *= 1.4 if skill_check(AILevel.medium) && @user.hasActiveAbility?(:BADDREAMS)
      # TODO: Prefer if user has certain roles (walls/cleric/pivot).

      # Prefer if target is at full HP
      mini_score *= 1.2 if @target.hp == @target.totalhp
      # Prefer if target's stats are raised
      sum_stages = 0
      PBStats.eachBattleStat { |s| sum_stages += @target.stages[s] }
      mini_score *= 1 + sum_stages * 0.1 if sum_stages > 0
      # Don't prefer if target is confused or infatuated
      mini_score *= 0.4 if @target.effects[PBEffects::Confusion] > 0
      mini_score *= 0.5 if @target.effects[PBEffects::Attract] >= 0
      # TODO: Don't prefer if target has previously used a move that is usable
      #       while asleep.
      if skill_check(AILevel.best)
        mini_score *= 0.1 if check_for_move(@target) { |move| move.usableWhenAsleep? }
      end
      # Don't prefer if target can cure itself, benefits from being asleep, or
      # can pass sleep back to the user
      # TODO: Check for other effects to list here.
      if skill_check(AILevel.best) && @target.abilityActive?
        if isConst?(@target.ability, PBAbilities, :SHEDSKIN)
          return 0
        elsif isConst?(@target.ability, PBAbilities, :HYDRATION) &&
           [PBWeather::Rain, PBWeather::HeavyRain].include?(@battle.pbWeather)
          return 0
        elsif isConst?(@target.ability, PBAbilities, :NATURALCURE)
          mini_score *= 0.1
        elsif isConst?(@target.ability, PBAbilities, :MARVELSCALE)
          mini_score *= 0.8
        end
      end

      # TODO: Prefer if user's moves won't do much damage to the target.

      # Apply mini_score to score
      mini_score = apply_effect_chance_to_score(mini_score)
      score *= mini_score
    #---------------------------------------------------------------------------
    when "005", "0BE"   # Poisons the target
      if @target.pbCanPoison?(@user, false)
        mini_score = 1.0
        # Inherently prefer
        mini_score *= 1.2

        # Prefer if user has a move that benefits from the target being poisoned
        mini_score *= 1.6 if @user.pbHasMoveFunction?("08B", "140")   # Venoshock, Venom Drench
        # Prefer if user has an ability that benefits from the target being poisoned
        mini_score *= 1.6 if skill_check(AILevel.medium) && @user.hasActiveAbility?(:MERCILESS)
        # TODO: Prefer if user has certain roles (walls).

        # Prefer if some of target's stats are raised
        sum_stages = 0
        [PBStats::DEFENSE, PBStats::SPDEF, PBStats::EVASION].each do |s|
          sum_stages += @target.stages[s]
        end
        mini_score *= 1 + sum_stages * 0.05 if sum_stages > 0
        # Prefer if target has Sturdy
        if skill_check(AILevel.best) && @target.hasActiveAbility?(:STURDY) && @move.damagingMove?
          mini_score *= 1.1
        end
        # Don't prefer if target is yawning
        mini_score *= 0.4 if @target.effects[PBEffects::Yawn] > 0
        # TODO: Don't prefer if target has previously used a move that benefits
        #       from being poisoned or can clear poisoning.
        if skill_check(AILevel.best)
          mini_score *= 0.2 if check_for_move(@target) { |move| isConst?(move.id, PBMoves, :FACADE) }
          mini_score *= 0.1 if check_for_move(@target) { |move| isConst?(move.id, PBMoves, :REST) }
        end
        # Don't prefer if target can cure itself, benefits from being poisoned,
        # or can pass poisoning back to the user
        # TODO: Check for other effects to list here.
        if skill_check(AILevel.best) && @target.abilityActive?
          if isConst?(@target.ability, PBAbilities, :SHEDSKIN)
            mini_score *= 0.7
          elsif isConst?(@target.ability, PBAbilities, :HYDRATION) &&
             [PBWeather::Rain, PBWeather::HeavyRain].include?(@battle.pbWeather)
            return 0
          elsif isConst?(@target.ability, PBAbilities, :TOXICBOOST) ||
                isConst?(@target.ability, PBAbilities, :GUTS) ||
                isConst?(@target.ability, PBAbilities, :QUICKFEET)
            mini_score *= 0.2
          elsif isConst?(@target.ability, PBAbilities, :POISONHEAL) ||
                isConst?(@target.ability, PBAbilities, :MAGICGUARD)
            mini_score *= 0.1
          elsif isConst?(@target.ability, PBAbilities, :NATURALCURE)
            mini_score *= 0.3
          elsif isConst?(@target.ability, PBAbilities, :MARVELSCALE)
            mini_score *= 0.7
          elsif isConst?(@target.ability, PBAbilities, :SYNCHRONIZE) && @user.pbHasAnyStatus?
            mini_score *= 0.5
          end
        end

        # TODO: Prefer if user's moves won't do much damage to the target.

        # Apply mini_score to score
        mini_score = apply_effect_chance_to_score(mini_score)
        score *= mini_score
      else
        return 0 if @move.statusMove?
      end
    #---------------------------------------------------------------------------
    when "006"   # Badly poisons the target (Toxic)
      if @target.pbCanPoison?(@user, false)
        mini_score = 1.0
        # Inherently prefer
        mini_score *= 1.3

        # Prefer if user has a move that benefits from the target being poisoned
        mini_score *= 1.6 if @user.pbHasMoveFunction?("08B", "140")   # Venoshock, Venom Drench
        # Prefer if user has an ability that benefits from the target being poisoned
        mini_score *= 1.6 if skill_check(AILevel.medium) && @user.hasActiveAbility?(:MERCILESS)
        # TODO: Prefer if user has certain roles (walls).
        # Prefer if status move and user is Poison-type (can't miss)
        mini_score *= 1.1 if NEWEST_BATTLE_MECHANICS && @move.statusMove? &&
                             @user.pbHasType?(:POISON)

        # Prefer if some of target's stats are raised
        sum_stages = 0
        [PBStats::DEFENSE, PBStats::SPDEF, PBStats::EVASION].each do |s|
          sum_stages += @target.stages[s]
        end
        mini_score *= 1 + sum_stages * 0.05 if sum_stages > 0
        # Prefer if target has Sturdy
        if skill_check(AILevel.best) && @target.hasActiveAbility?(:STURDY) && @move.damagingMove?
          mini_score *= 1.1
        end
        # TODO: Prefer if target has previously used a HP-restoring move.
        if skill_check(AILevel.best)
          mini_score *= 2 if check_for_move(@target) { |move| move.healingMove? }
        end
        # Don't prefer if target is yawning
        mini_score *= 0.1 if @target.effects[PBEffects::Yawn] > 0
        # TODO: Don't prefer if target has previously used a move that benefits
        #       from being poisoned or can clear poisoning.
        if skill_check(AILevel.best)
          mini_score *= 0.3 if check_for_move(@target) { |move| isConst?(move.id, PBMoves, :FACADE) }
          mini_score *= 0.1 if check_for_move(@target) { |move| isConst?(move.id, PBMoves, :REST) }
        end
        # Don't prefer if target can cure itself, benefits from being poisoned,
        # or can pass poisoning back to the user
        # TODO: Check for other effects to list here.
        if skill_check(AILevel.best) && @target.abilityActive?
          if isConst?(@target.ability, PBAbilities, :SHEDSKIN)
            mini_score *= 0.7
          elsif isConst?(@target.ability, PBAbilities, :HYDRATION) &&
             [PBWeather::Rain, PBWeather::HeavyRain].include?(@battle.pbWeather)
            return 0
          elsif isConst?(@target.ability, PBAbilities, :TOXICBOOST) ||
                isConst?(@target.ability, PBAbilities, :GUTS) ||
                isConst?(@target.ability, PBAbilities, :QUICKFEET)
            mini_score *= 0.2
          elsif isConst?(@target.ability, PBAbilities, :POISONHEAL) ||
                isConst?(@target.ability, PBAbilities, :MAGICGUARD)
            mini_score *= 0.1
          elsif isConst?(@target.ability, PBAbilities, :NATURALCURE)
            mini_score *= 0.2
          elsif isConst?(@target.ability, PBAbilities, :MARVELSCALE)
            mini_score *= 0.8
          elsif isConst?(@target.ability, PBAbilities, :SYNCHRONIZE) && @user.pbHasAnyStatus?
            mini_score *= 0.5
          end
        end

        # TODO: Prefer if user's moves won't do much damage to the target.

        # Apply mini_score to score
        mini_score = apply_effect_chance_to_score(mini_score)
        score *= mini_score
      else
        return 0 if @move.statusMove?
      end
    #---------------------------------------------------------------------------
    when "007", "0C5"   # Paralyses the target
      return 0 if isConst?(@move.id, PBMoves, :THUNDERWAVE) &&
                  PBTypes.ineffective?(pbCalcTypeMod(@move.type, @user, @target))

      if @target.pbCanParalyze?(@user, false)
        mini_score = 1.0

        # TODO: Prefer if user has certain roles (walls/pivot/tank).
        # TODO: Prefer if user has any setup moves (i.e. it wants to stall to
        #       get them set up).

        # Prefer if target is at full HP
        mini_score *= 1.2 if @target.hp == @target.totalhp
        # Prefer if target is confused or infatuated
        mini_score *= 1.1 if @target.effects[PBEffects::Confusion] > 0
        mini_score *= 1.1 if @target.effects[PBEffects::Attract] >= 0
        # Prefer if some of target's stats are raised
        sum_stages = 0
        [PBStats::ATTACK, PBStats::SPATK, PBStats::SPEED].each do |s|
          sum_stages += @target.stages[s]
        end
        mini_score *= 1 + sum_stages * 0.05 if sum_stages > 0
        # Don't prefer if target is yawning
        mini_score *= 0.4 if @target.effects[PBEffects::Yawn] > 0
        # Don't prefer if target can cure itself, benefits from being paralysed,
        # or can pass paralysis back to the user
        # TODO: Check for other effects to list here.
        if skill_check(AILevel.best) && @target.abilityActive?
          if isConst?(@target.ability, PBAbilities, :SHEDSKIN)
            mini_score *= 0.7
          elsif isConst?(@target.ability, PBAbilities, :HYDRATION) &&
             [PBWeather::Rain, PBWeather::HeavyRain].include?(@battle.pbWeather)
            return 0
          elsif isConst?(@target.ability, PBAbilities, :GUTS) ||
                isConst?(@target.ability, PBAbilities, :QUICKFEET)
            mini_score *= 0.2
          elsif isConst?(@target.ability, PBAbilities, :NATURALCURE)
            mini_score *= 0.3
          elsif isConst?(@target.ability, PBAbilities, :MARVELSCALE)
            mini_score *= 0.5
          elsif isConst?(@target.ability, PBAbilities, :SYNCHRONIZE) && @user.pbHasAnyStatus?
            mini_score *= 0.5
          end
        end

        # Prefer if user is slower than the target but will be faster if target
        # is paralysed
        if !@user_faster && skill_check(AILevel.best) && !@target.hasActiveAbility?(:QUICKFEET)
          user_speed   = pbRoughStat(@user, PBStats::SPEED)
          target_speed = pbRoughStat(@target, PBStats::SPEED)
          paralysis_factor = (NEWEST_BATTLE_MECHANICS) ? 2 : 4
          if (user_speed > target_speed / paralysis_factor) ^ (@battle.field.effects[PBEffects::TrickRoom] > 0)
            mini_score *= 1.5
          end
        end

        # TODO: Prefer if any Pokémon in the user's party has the Sweeper role.

        # Apply mini_score to score
        mini_score = apply_effect_chance_to_score(mini_score)
        score *= mini_score
      else
        return 0 if @move.statusMove?
      end
    #---------------------------------------------------------------------------
    when "008"   # Paralyses the target, weather-dependent accuracy
      if @target.pbCanParalyze?(@user, false) && @target.effects[PBEffects::Yawn] == 0
        mini_score = 1.0

        # TODO: Prefer if user has certain roles (walls/pivot/tank).
        # TODO: Prefer if user has any setup moves (i.e. it wants to stall to
        #       get them set up).

        # Prefer if target is at full HP
        mini_score *= 1.2 if @target.hp == @target.totalhp
        # Prefer if target is confused or infatuated
        mini_score *= 1.1 if @target.effects[PBEffects::Confusion] > 0
        mini_score *= 1.1 if @target.effects[PBEffects::Attract] >= 0
        # Prefer if some of target's stats are raised
        sum_stages = 0
        [PBStats::ATTACK, PBStats::SPATK, PBStats::SPEED].each do |s|
          sum_stages += @target.stages[s]
        end
        mini_score *= 1 + sum_stages * 0.05 if sum_stages > 0
        # TODO: Prefer if user is slower and target has previously used a move
        #       that makes it semi-invulnerable in the air (Fly, Bounce, Sky Drop).
        if !@user_faster && skill_check(AILevel.best)
          if check_for_move(@target) { |move| ["0C9", "0CC", "0CE"].include?(move.function) }
            mini_score *= 1.2
          end
        end
        # Don't prefer if target can cure itself, benefits from being paralysed,
        # or can pass paralysis back to the user
        # TODO: Check for other effects to list here.
        if skill_check(AILevel.best) && @target.abilityActive?
          if isConst?(@target.ability, PBAbilities, :SHEDSKIN)
            mini_score *= 0.7
          elsif isConst?(@target.ability, PBAbilities, :GUTS) ||
                isConst?(@target.ability, PBAbilities, :QUICKFEET)
            mini_score *= 0.2
          elsif isConst?(@target.ability, PBAbilities, :NATURALCURE)
            mini_score *= 0.3
          elsif isConst?(@target.ability, PBAbilities, :MARVELSCALE)
            mini_score *= 0.5
          elsif isConst?(@target.ability, PBAbilities, :SYNCHRONIZE) && @user.pbHasAnyStatus?
            mini_score *= 0.5
          end
        end

        # Prefer if user is slower than the target but will be faster if target
        # is paralysed
        if !@user_faster && skill_check(AILevel.best) && !@target.hasActiveAbility?(:QUICKFEET)
          user_speed   = pbRoughStat(@user, PBStats::SPEED)
          target_speed = pbRoughStat(@target, PBStats::SPEED)
          paralysis_factor = (NEWEST_BATTLE_MECHANICS) ? 2 : 4
          if (user_speed > target_speed / paralysis_factor) ^ (@battle.field.effects[PBEffects::TrickRoom] > 0)
            mini_score *= 1.5
          end
        end

        # TODO: Prefer if any Pokémon in the user's party has the Sweeper role.

        # Apply mini_score to score
        mini_score = apply_effect_chance_to_score(mini_score)
        score *= mini_score
      else
        return 0 if @move.statusMove?
      end
    #---------------------------------------------------------------------------
    when "009"   # Paralyses the target, makes the target flinch
    #---------------------------------------------------------------------------
    when "00A", "00B", "0C6"
      if @target.pbCanBurn?(@user,false)
        score += 30
        if skill_check(AILevel.high)
          score -= 40 if @target.hasActiveAbility?([:GUTS,:MARVELSCALE,:QUICKFEET,:FLAREBOOST])
        end
      else
        if skill_check(AILevel.medium)
          score -= 90 if @move.statusMove?
        end
      end
    #---------------------------------------------------------------------------
    when "00C", "00D", "00E"
      if @target.pbCanFreeze?(@user,false)
        score += 30
        if skill_check(AILevel.high)
          score -= 20 if @target.hasActiveAbility?(:MARVELSCALE)
        end
      else
        if skill_check(AILevel.medium)
          score -= 90 if @move.statusMove?
        end
      end
    #---------------------------------------------------------------------------
    when "00F"
      score += 30
      if skill_check(AILevel.high)
        score += 30 if !@target.hasActiveAbility?(:INNERFOCUS) &&
                       @target.effects[PBEffects::Substitute]==0
      end
    #---------------------------------------------------------------------------
    when "010"
      if skill_check(AILevel.high)
        score += 30 if !@target.hasActiveAbility?(:INNERFOCUS) &&
                       @target.effects[PBEffects::Substitute]==0
      end
      score += 30 if @target.effects[PBEffects::Minimize]
    #---------------------------------------------------------------------------
    when "011"
      if @user.asleep?
        score += 100   # Because it can only be used while asleep
        if skill_check(AILevel.high)
          score += 30 if !@target.hasActiveAbility?(:INNERFOCUS) &&
                         @target.effects[PBEffects::Substitute]==0
        end
      else
        score -= 90   # Because it will fail here
        score = 0 if skill_check(AILevel.best)
      end
    #---------------------------------------------------------------------------
    when "012"
      if @user.turnCount==0
        if skill_check(AILevel.high)
          score += 30 if !@target.hasActiveAbility?(:INNERFOCUS) &&
                         @target.effects[PBEffects::Substitute]==0
        end
      else
        score -= 90   # Because it will fail here
        score = 0 if skill_check(AILevel.best)
      end
    #---------------------------------------------------------------------------
    when "013", "014", "015"
      if @target.pbCanConfuse?(@user,false)
        score += 30
      else
        if skill_check(AILevel.medium)
          score -= 90 if @move.statusMove?
        end
      end
    #---------------------------------------------------------------------------
    when "016"
      canattract = true
      agender = @user.gender
      ogender = @target.gender
      if agender==2 || ogender==2 || agender==ogender
        score -= 90; canattract = false
      elsif @target.effects[PBEffects::Attract]>=0
        score -= 80; canattract = false
      elsif skill_check(AILevel.best) && @target.hasActiveAbility?(:OBLIVIOUS)
        score -= 80; canattract = false
      end
      if skill_check(AILevel.high)
        if canattract && @target.hasActiveItem?(:DESTINYKNOT) &&
           @user.pbCanAttract?(@target,false)
          score -= 30
        end
      end
    #---------------------------------------------------------------------------
    when "017"
      score += 30 if @target.status==PBStatuses::NONE
    #---------------------------------------------------------------------------
    when "018"
      case @user.status
      when PBStatuses::POISON
        score += 40
        if skill_check(AILevel.medium)
          if @user.hp<@user.totalhp/8
            score += 60
          elsif skill_check(AILevel.high) &&
             @user.hp<(@user.effects[PBEffects::Toxic]+1)*@user.totalhp/16
            score += 60
          end
        end
      when PBStatuses::BURN, PBStatuses::PARALYSIS
        score += 40
      else
        score -= 90
      end
    #---------------------------------------------------------------------------
    when "019"
      statuses = 0
      @battle.pbParty(@user.index).each do |pkmn|
        statuses += 1 if pkmn && pkmn.status!=PBStatuses::NONE
      end
      if statuses==0
        score -= 80
      else
        score += 20*statuses
      end
    #---------------------------------------------------------------------------
    when "01A"
      if @user.pbOwnSide.effects[PBEffects::Safeguard]>0
        score -= 80
      elsif @user.status!=0
        score -= 40
      else
        score += 30
      end
    #---------------------------------------------------------------------------
    when "01B"
      if @user.status==PBStatuses::NONE
        score -= 90
      else
        score += 40
      end
    #---------------------------------------------------------------------------
    when "01C"
      if @move.statusMove?
        if @user.statStageAtMax?(PBStats::ATTACK)
          score -= 90
        else
          score -= @user.stages[PBStats::ATTACK]*20
          if skill_check(AILevel.medium)
            hasPhysicalAttack = false
            @user.eachMove do |m|
              next if !m.physicalMove?(m.type)
              hasPhysicalAttack = true
              break
            end
            if hasPhysicalAttack
              score += 20
            elsif skill_check(AILevel.high)
              score -= 90
            end
          end
        end
      else
        score += 20 if @user.stages[PBStats::ATTACK]<0
        if skill_check(AILevel.medium)
          hasPhysicalAttack = false
          @user.eachMove do |m|
            next if !m.physicalMove?(m.type)
            hasPhysicalAttack = true
            break
          end
          score += 20 if hasPhysicalAttack
        end
      end
    #---------------------------------------------------------------------------
    when "01D", "01E", "0C8"
      if @move.statusMove?
        if @user.statStageAtMax?(PBStats::DEFENSE)
          score -= 90
        else
          score -= @user.stages[PBStats::DEFENSE]*20
        end
      else
        score += 20 if @user.stages[PBStats::DEFENSE]<0
      end
    #---------------------------------------------------------------------------
    when "01F"
      if @move.statusMove?
        if @user.statStageAtMax?(PBStats::SPEED)
          score -= 90
        else
          score -= @user.stages[PBStats::SPEED]*10
          if skill_check(AILevel.high)
            aspeed = pbRoughStat(@user,PBStats::SPEED)
            ospeed = pbRoughStat(@target,PBStats::SPEED)
            score += 30 if aspeed<ospeed && aspeed*2>ospeed
          end
        end
      else
        score += 20 if @user.stages[PBStats::SPEED]<0
      end
    #---------------------------------------------------------------------------
    when "020"
      if @move.statusMove?
        if @user.statStageAtMax?(PBStats::SPATK)
          score -= 90
        else
          score -= @user.stages[PBStats::SPATK]*20
          if skill_check(AILevel.medium)
            hasSpecicalAttack = false
            @user.eachMove do |m|
              next if !m.specialMove?(m.type)
              hasSpecicalAttack = true
              break
            end
            if hasSpecicalAttack
              score += 20
            elsif skill_check(AILevel.high)
              score -= 90
            end
          end
        end
      else
        score += 20 if @user.stages[PBStats::SPATK]<0
        if skill_check(AILevel.medium)
          hasSpecicalAttack = false
          @user.eachMove do |m|
            next if !m.specialMove?(m.type)
            hasSpecicalAttack = true
            break
          end
          score += 20 if hasSpecicalAttack
        end
      end
    #---------------------------------------------------------------------------
    when "021"
      foundMove = false
      @user.eachMove do |m|
        next if !isConst?(m.type,PBTypes,:ELECTRIC) || !m.damagingMove?
        foundMove = true
        break
      end
      score += 20 if foundMove
      if @move.statusMove?
        if @user.statStageAtMax?(PBStats::SPDEF)
          score -= 90
        else
          score -= @user.stages[PBStats::SPDEF]*20
        end
      else
        score += 20 if @user.stages[PBStats::SPDEF]<0
      end
    #---------------------------------------------------------------------------
    when "022"
      if @move.statusMove?
        if @user.statStageAtMax?(PBStats::EVASION)
          score -= 90
        else
          score -= @user.stages[PBStats::EVASION]*10
        end
      else
        score += 20 if @user.stages[PBStats::EVASION]<0
      end
    #---------------------------------------------------------------------------
    when "023"
      if @move.statusMove?
        if @user.effects[PBEffects::FocusEnergy]>=2
          score -= 80
        else
          score += 30
        end
      else
        score += 30 if @user.effects[PBEffects::FocusEnergy]<2
      end
    #---------------------------------------------------------------------------
    when "024"
      if @user.statStageAtMax?(PBStats::ATTACK) &&
         @user.statStageAtMax?(PBStats::DEFENSE)
        score -= 90
      else
        score -= @user.stages[PBStats::ATTACK]*10
        score -= @user.stages[PBStats::DEFENSE]*10
        if skill_check(AILevel.medium)
          hasPhysicalAttack = false
          @user.eachMove do |m|
            next if !m.physicalMove?(m.type)
            hasPhysicalAttack = true
            break
          end
          if hasPhysicalAttack
            score += 20
          elsif skill_check(AILevel.high)
            score -= 90
          end
        end
      end
    #---------------------------------------------------------------------------
    when "025"
      if @user.statStageAtMax?(PBStats::ATTACK) &&
         @user.statStageAtMax?(PBStats::DEFENSE) &&
         @user.statStageAtMax?(PBStats::ACCURACY)
        score -= 90
      else
        score -= @user.stages[PBStats::ATTACK]*10
        score -= @user.stages[PBStats::DEFENSE]*10
        score -= @user.stages[PBStats::ACCURACY]*10
        if skill_check(AILevel.medium)
          hasPhysicalAttack = false
          @user.eachMove do |m|
            next if !m.physicalMove?(m.type)
            hasPhysicalAttack = true
            break
          end
          if hasPhysicalAttack
            score += 20
          elsif skill_check(AILevel.high)
            score -= 90
          end
        end
      end
    #---------------------------------------------------------------------------
    when "026"
      score += 40 if @user.turnCount==0   # Dragon Dance tends to be popular
      if @user.statStageAtMax?(PBStats::ATTACK) &&
         @user.statStageAtMax?(PBStats::SPEED)
        score -= 90
      else
        score -= @user.stages[PBStats::ATTACK]*10
        score -= @user.stages[PBStats::SPEED]*10
        if skill_check(AILevel.medium)
          hasPhysicalAttack = false
          @user.eachMove do |m|
            next if !m.physicalMove?(m.type)
            hasPhysicalAttack = true
            break
          end
          if hasPhysicalAttack
            score += 20
          elsif skill_check(AILevel.high)
            score -= 90
          end
        end
        if skill_check(AILevel.high)
          aspeed = pbRoughStat(@user,PBStats::SPEED)
          ospeed = pbRoughStat(@target,PBStats::SPEED)
          score += 20 if aspeed<ospeed && aspeed*2>ospeed
        end
      end
    #---------------------------------------------------------------------------
    when "027", "028"
      if @user.statStageAtMax?(PBStats::ATTACK) &&
         @user.statStageAtMax?(PBStats::SPATK)
        score -= 90
      else
        score -= @user.stages[PBStats::ATTACK]*10
        score -= @user.stages[PBStats::SPATK]*10
        if skill_check(AILevel.medium)
          hasDamagingAttack = false
          @user.eachMove do |m|
            next if !m.damagingMove?
            hasDamagingAttack = true
            break
          end
          if hasDamagingAttack
            score += 20
          elsif skill_check(AILevel.high)
            score -= 90
          end
        end
        if @move.function=="028"   # Growth
          score += 20 if @battle.pbWeather==PBWeather::Sun ||
                         @battle.pbWeather==PBWeather::HarshSun
        end
      end
    #---------------------------------------------------------------------------
    when "029"
      if @user.statStageAtMax?(PBStats::ATTACK) &&
         @user.statStageAtMax?(PBStats::ACCURACY)
        score -= 90
      else
        score -= @user.stages[PBStats::ATTACK]*10
        score -= @user.stages[PBStats::ACCURACY]*10
        if skill_check(AILevel.medium)
          hasPhysicalAttack = false
          @user.eachMove do |m|
            next if !m.physicalMove?(m.type)
            hasPhysicalAttack = true
            break
          end
          if hasPhysicalAttack
            score += 20
          elsif skill_check(AILevel.high)
            score -= 90
          end
        end
      end
    #---------------------------------------------------------------------------
    when "02A"
      if @user.statStageAtMax?(PBStats::DEFENSE) &&
         @user.statStageAtMax?(PBStats::SPDEF)
        score -= 90
      else
        score -= @user.stages[PBStats::DEFENSE]*10
        score -= @user.stages[PBStats::SPDEF]*10
      end
    #---------------------------------------------------------------------------
    when "02B"
      if @user.statStageAtMax?(PBStats::SPEED) &&
         @user.statStageAtMax?(PBStats::SPATK) &&
         @user.statStageAtMax?(PBStats::SPDEF)
        score -= 90
      else
        score -= @user.stages[PBStats::SPATK]*10
        score -= @user.stages[PBStats::SPDEF]*10
        score -= @user.stages[PBStats::SPEED]*10
        if skill_check(AILevel.medium)
          hasSpecicalAttack = false
          @user.eachMove do |m|
            next if !m.specialMove?(m.type)
            hasSpecicalAttack = true
            break
          end
          if hasSpecicalAttack
            score += 20
          elsif skill_check(AILevel.high)
            score -= 90
          end
        end
        if skill_check(AILevel.high)
          aspeed = pbRoughStat(@user,PBStats::SPEED)
          ospeed = pbRoughStat(@target,PBStats::SPEED)
          if aspeed<ospeed && aspeed*2>ospeed
            score += 20
          end
        end
      end
    #---------------------------------------------------------------------------
    when "02C"
      if @user.statStageAtMax?(PBStats::SPATK) &&
         @user.statStageAtMax?(PBStats::SPDEF)
        score -= 90
      else
        score += 40 if @user.turnCount==0   # Calm Mind tends to be popular
        score -= @user.stages[PBStats::SPATK]*10
        score -= @user.stages[PBStats::SPDEF]*10
        if skill_check(AILevel.medium)
          hasSpecicalAttack = false
          @user.eachMove do |m|
            next if !m.specialMove?(m.type)
            hasSpecicalAttack = true
            break
          end
          if hasSpecicalAttack
            score += 20
          elsif skill_check(AILevel.high)
            score -= 90
          end
        end
      end
    #---------------------------------------------------------------------------
    when "02D"
      PBStats.eachMainBattleStat { |s| score += 10 if @user.stages[s]<0 }
      if skill_check(AILevel.medium)
        hasDamagingAttack = false
        @user.eachMove do |m|
          next if !m.damagingMove?
          hasDamagingAttack = true
          break
        end
        score += 20 if hasDamagingAttack
      end
    #---------------------------------------------------------------------------
    when "02E"
      if @move.statusMove?
        if @user.statStageAtMax?(PBStats::ATTACK)
          score -= 90
        else
          score += 40 if @user.turnCount==0
          score -= @user.stages[PBStats::ATTACK]*20
          if skill_check(AILevel.medium)
            hasPhysicalAttack = false
            @user.eachMove do |m|
              next if !m.physicalMove?(m.type)
              hasPhysicalAttack = true
              break
            end
            if hasPhysicalAttack
              score += 20
            elsif skill_check(AILevel.high)
              score -= 90
            end
          end
        end
      else
        score += 10 if @user.turnCount==0
        score += 20 if @user.stages[PBStats::ATTACK]<0
        if skill_check(AILevel.medium)
          hasPhysicalAttack = false
          @user.eachMove do |m|
            next if !m.physicalMove?(m.type)
            hasPhysicalAttack = true
            break
          end
          score += 20 if hasPhysicalAttack
        end
      end
    #---------------------------------------------------------------------------
    when "02F"
      if @move.statusMove?
        if @user.statStageAtMax?(PBStats::DEFENSE)
          score -= 90
        else
          score += 40 if @user.turnCount==0
          score -= @user.stages[PBStats::DEFENSE]*20
        end
      else
        score += 10 if @user.turnCount==0
        score += 20 if @user.stages[PBStats::DEFENSE]<0
      end
    #---------------------------------------------------------------------------
    when "030", "031"
      if @move.statusMove?
        if @user.statStageAtMax?(PBStats::SPEED)
          score -= 90
        else
          score += 20 if @user.turnCount==0
          score -= @user.stages[PBStats::SPEED]*10
          if skill_check(AILevel.high)
            aspeed = pbRoughStat(@user,PBStats::SPEED)
            ospeed = pbRoughStat(@target,PBStats::SPEED)
            score += 30 if aspeed<ospeed && aspeed*2>ospeed
          end
        end
      else
        score += 10 if @user.turnCount==0
        score += 20 if @user.stages[PBStats::SPEED]<0
      end
    #---------------------------------------------------------------------------
    when "032"
      if @move.statusMove?
        if @user.statStageAtMax?(PBStats::SPATK)
          score -= 90
        else
          score += 40 if @user.turnCount==0
          score -= @user.stages[PBStats::SPATK]*20
          if skill_check(AILevel.medium)
            hasSpecicalAttack = false
            @user.eachMove do |m|
              next if !m.specialMove?(m.type)
              hasSpecicalAttack = true
              break
            end
            if hasSpecicalAttack
              score += 20
            elsif skill_check(AILevel.high)
              score -= 90
            end
          end
        end
      else
        score += 10 if @user.turnCount==0
        score += 20 if @user.stages[PBStats::SPATK]<0
        if skill_check(AILevel.medium)
          hasSpecicalAttack = false
          @user.eachMove do |m|
            next if !m.specialMove?(m.type)
            hasSpecicalAttack = true
            break
          end
          score += 20 if hasSpecicalAttack
        end
      end
    #---------------------------------------------------------------------------
    when "033"
      if @move.statusMove?
        if @user.statStageAtMax?(PBStats::SPDEF)
          score -= 90
        else
          score += 40 if @user.turnCount==0
          score -= @user.stages[PBStats::SPDEF]*20
        end
      else
        score += 10 if @user.turnCount==0
        score += 20 if @user.stages[PBStats::SPDEF]<0
      end
    #---------------------------------------------------------------------------
    when "034"
      if @move.statusMove?
        if @user.statStageAtMax?(PBStats::EVASION)
          score -= 90
        else
          score += 40 if @user.turnCount==0
          score -= @user.stages[PBStats::EVASION]*10
        end
      else
        score += 10 if @user.turnCount==0
        score += 20 if @user.stages[PBStats::EVASION]<0
      end
    #---------------------------------------------------------------------------
    when "035"
      score -= @user.stages[PBStats::ATTACK]*20
      score -= @user.stages[PBStats::SPEED]*20
      score -= @user.stages[PBStats::SPATK]*20
      score += @user.stages[PBStats::DEFENSE]*10
      score += @user.stages[PBStats::SPDEF]*10
      if skill_check(AILevel.medium)
        hasDamagingAttack = false
        @user.eachMove do |m|
          next if !m.damagingMove?
          hasDamagingAttack = true
          break
        end
        score += 20 if hasDamagingAttack
      end
    #---------------------------------------------------------------------------
    when "036"
      if @user.statStageAtMax?(PBStats::ATTACK) &&
         @user.statStageAtMax?(PBStats::SPEED)
        score -= 90
      else
        score -= @user.stages[PBStats::ATTACK]*10
        score -= @user.stages[PBStats::SPEED]*10
        if skill_check(AILevel.medium)
          hasPhysicalAttack = false
          @user.eachMove do |m|
            next if !m.physicalMove?(m.type)
            hasPhysicalAttack = true
            break
          end
          if hasPhysicalAttack
            score += 20
          elsif skill_check(AILevel.high)
            score -= 90
          end
        end
        if skill_check(AILevel.high)
          aspeed = pbRoughStat(@user,PBStats::SPEED)
          ospeed = pbRoughStat(@target,PBStats::SPEED)
          score += 30 if aspeed<ospeed && aspeed*2>ospeed
        end
      end
    #---------------------------------------------------------------------------
    when "037"
      avgStat = 0; canChangeStat = false
      PBStats.eachBattleStat do |s|
        next if @target.statStageAtMax?(s)
        avgStat -= @target.stages[s]
        canChangeStat = true
      end
      if canChangeStat
        avgStat = avgStat/2 if avgStat<0   # More chance of getting even better
        score += avgStat*10
      else
        score -= 90
      end
    #---------------------------------------------------------------------------
    when "038"
      if @move.statusMove?
        if @user.statStageAtMax?(PBStats::DEFENSE)
          score -= 90
        else
          score += 40 if @user.turnCount==0
          score -= @user.stages[PBStats::DEFENSE]*30
        end
      else
        score += 10 if @user.turnCount==0
        score += 30 if @user.stages[PBStats::DEFENSE]<0
      end
    #---------------------------------------------------------------------------
    when "039"
      if @move.statusMove?
        if @user.statStageAtMax?(PBStats::SPATK)
          score -= 90
        else
          score += 40 if @user.turnCount==0
          score -= @user.stages[PBStats::SPATK]*30
          if skill_check(AILevel.medium)
            hasSpecicalAttack = false
            @user.eachMove do |m|
              next if !m.specialMove?(m.type)
              hasSpecicalAttack = true
              break
            end
            if hasSpecicalAttack
              score += 20
            elsif skill_check(AILevel.high)
              score -= 90
            end
          end
        end
      else
        score += 10 if @user.turnCount==0
        score += 30 if @user.stages[PBStats::SPATK]<0
        if skill_check(AILevel.medium)
          hasSpecicalAttack = false
          @user.eachMove do |m|
            next if !m.specialMove?(m.type)
            hasSpecicalAttack = true
            break
          end
          score += 30 if hasSpecicalAttack
        end
      end
    #---------------------------------------------------------------------------
    when "03A"
      if @user.statStageAtMax?(PBStats::ATTACK) ||
         @user.hp<=@user.totalhp/2
        score -= 100
      else
        score += (6-@user.stages[PBStats::ATTACK])*10
        if skill_check(AILevel.medium)
          hasPhysicalAttack = false
          @user.eachMove do |m|
            next if !m.physicalMove?(m.type)
            hasPhysicalAttack = true
            break
          end
          if hasPhysicalAttack
            score += 40
          elsif skill_check(AILevel.high)
            score -= 90
          end
        end
      end
    #---------------------------------------------------------------------------
    when "03B"
      avg =  @user.stages[PBStats::ATTACK]*10
      avg += @user.stages[PBStats::DEFENSE]*10
      score += avg/2
    #---------------------------------------------------------------------------
    when "03C"
      avg =  @user.stages[PBStats::DEFENSE]*10
      avg += @user.stages[PBStats::SPDEF]*10
      score += avg/2
    #---------------------------------------------------------------------------
    when "03D"
      avg =  @user.stages[PBStats::DEFENSE]*10
      avg += @user.stages[PBStats::SPEED]*10
      avg += @user.stages[PBStats::SPDEF]*10
      score += (avg/3).floor
    #---------------------------------------------------------------------------
    when "03E"
      score += @user.stages[PBStats::SPEED]*10
    #---------------------------------------------------------------------------
    when "03F"
      score += @user.stages[PBStats::SPATK]*10
    #---------------------------------------------------------------------------
    end
    return score
  end
end
