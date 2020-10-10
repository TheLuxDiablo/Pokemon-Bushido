class PokeBattle_AI
  #=============================================================================
  # Apply additional effect chance to a move's score
  # TODO: Apply all the additional effect chance modifiers.
  #=============================================================================
  def apply_effect_chance_to_score(score)
    if @move.damagingMove?
      # TODO: Doesn't return the correct value for "014" (Chatter).
      effect_chance = @move.addlEffect
      if effect_chance > 0
        effect_chance *= 2 if @user.hasActiveAbility?(:SERENEGRACE) ||
                              @user.pbOwnSide.effects[PBEffects::Rainbow] > 0
        effect_multiplier = [effect_chance.to_f, 100].min / 100
        score = ((score - 1) * effect_multiplier) + 1
      end
    end
    return score
  end

  #=============================================================================
  #
  #=============================================================================
  # TODO: These function codes need to have an attr_reader :statUp and for them
  #       to be set when the move is initialised.
  #       035 Shell Smash
  #       037 Acupressure
  #       137 Magnetic Flux
  #       15C Gear Up
  def get_mini_score_for_user_stat_raise
    mini_score = 1.0
    # Determine whether the move boosts Attack, Special Attack or Speed (Bulk Up
    # is sometimes not considered a sweeping move)
    sweeping_stat = false
    offensive_stat = false
    @move.stat_up.each_with_index do |stat, idx|
      next if idx.odd?
      next if ![:ATTACK, :SPATK, :SPEED].include?(stat)
      sweeping_stat = true
      next if @move.function == "024"   # Bulk Up (+Atk +Def)
      offensive_stat = true
      break
    end

    # Prefer if user has most of its HP
    if @user.hp >= @user.totalhp * 3 / 4
      mini_score *= (sweeping_stat) ? 1.2 : 1.1
    end
    # Prefer if user hasn't been in battle for long
    if @user.turnCount < 2
      mini_score *= (sweeping_stat) ? 1.2 : 1.1
    end
    # Prefer if user has the ability Simple
    mini_score *= 2 if @user.hasActiveAbility?(:SIMPLE)
    # TODO: Prefer if user's moves won't do much damage.
    # Prefer if user has something that will limit damage taken
    mini_score *= 1.3 if @user.effects[PBEffects::Substitute] >0 ||
                         (@user.form == 0 && isConst?(@user.ability, PBAbilities, :DISGUISE))

    # Don't prefer if user doesn't have much HP left
    mini_score *= 0.3 if @user.hp < @user.totalhp / 3
    # Don't prefer if user is badly poisoned
    mini_score *= 0.2 if @user.effects[PBEffects::Toxic] > 0 && !offensive_stat
    # Don't prefer if user is confused
    if @user.effects[PBEffects::Confusion] > 0
      # TODO: Especially don't prefer if the move raises Atk. Even more so if
      #       the move raises the stat by 2+. Not quite so much if the move also
      #       raises Def.
      mini_score *= 0.5
    end
    # Don't prefer if user is infatuated or Leech Seeded
    if @user.effects[PBEffects::Attract] >= 0 || @user.effects[PBEffects::LeechSeed] >= 0
      mini_score *= (offensive_stat) ? 0.6 : 0.3
    end
    # Don't prefer if user has an ability or item that will force it to switch
    # out
    if @user.hp < @user.totalhp * 3 / 4
      mini_score *= 0.3 if @user.hasActiveAbility?([:EMERGENCYEXIT, :WIMPOUT])
      mini_score *= 0.3 if @user.hasActiveItem?(:EJECTBUTTON)
    end

    # Prefer if target has a status problem
    if @target.status != PBStatuses::NONE
      mini_score *= (sweeping_stat) ? 1.2 : 1.1
      case @target.status
      when PBStatuses::SLEEP, PBStatuses::FROZEN
        mini_score *= 1.3
      when PBStatuses::BURN
        # TODO: Prefer if the move boosts Sp Def.
        mini_score *= 1.1 if !offensive_stat
      end
    end
    # Prefer if target is yawning
    if @target.effects[PBEffects::Yawn] > 0
      mini_score *= (sweeping_stat) ? 1.7 : 1.3
    end
    # Prefer if target is recovering after Hyper Beam
    if @target.effects[PBEffects::HyperBeam] > 0
      mini_score *= (sweeping_stat) ? 1.3 : 1.2
    end
    # Prefer if target is Encored into a status move
    if @target.effects[PBEffects::Encore] > 0 &&
       pbGetMoveData(@target.effects[PBEffects::EncoreMove], MOVE_CATEGORY) == 2   # Status move
      # TODO: Why should this check greatly prefer raising both the user's defences?
      if sweeping_stat || @move.function == "02A"   # +Def +SpDef
        mini_score *= 1.5
      else
        mini_score *= 1.3
      end
    end
    # TODO: Don't prefer if target has previously used a move that would force
    #       the user to switch (or Yawn/Perish Song which encourage it). Prefer
    #       instead if the move raises evasion. Note this comes after the
    #       dissociation of Bulk Up from sweeping_stat.

    if skill_check(AILevel.medium)
      # TODO: Prefer if the maximum damage the target has dealt wouldn't hurt
      #       the user much.
    end
    # Don't prefer if foe's side is able to use a boosted Retaliate
    # TODO: I think this is what Reborn means. Reborn doesn't check for the
    #       existence of the move Retaliate, just whether it can be boosted.
    if @user.pbOpposingSide.effects[PBEffects::LastRoundFainted] == @battle.turnCount - 1
      mini_score *= 0.3
    end

    # Don't prefer if it's not a single battle
    if !@battle.singleBattle?
      mini_score *= (offensive_stat) ? 0.25 : 0.5
    end

    return mini_score
  end
end
