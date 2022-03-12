################################################################################
# Increase an ally's critical hit rate by 2 stages, and decreases the foe's Defense by 1 stage.
################################################################################
class PokeBattle_Move_601 < PokeBattle_Move
  def pbEffectGeneral(user)
    user.effects[PBEffects::FocusEnergy] = 2
    @statDown = [PBStats::DEFENSE,1]
  end
end

################################################################################
# Burns the target, and move's power is doubled if target has a status condition.
################################################################################
class PokeBattle_Move_602 < PokeBattle_BurnMove
  def pbBaseDamage(baseDmg,user,target)
    if target.pbHasAnyStatus? &&
       (target.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(user))
      baseDmg *= 2
    end
    return baseDmg
  end
end

################################################################################
# Freezes the target, and move's power is doubled if target has a status condition.
################################################################################
class PokeBattle_Move_603 < PokeBattle_FreezeMove
  def pbBaseDamage(baseDmg,user,target)
    if target.pbHasAnyStatus? &&
       (target.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(user))
      baseDmg *= 2
    end
    return baseDmg
  end
end

################################################################################
# Lowers the target's defense, and raises our critical hit chance. (Triple Arrows PLA)
################################################################################
class PokeBattle_Move_604 < PokeBattle_TargetStatDownMove
  def initialize(battle,move)
    super
    @statDown = [PBStats::DEFENSE,1,PBStats::SPDEF,1]
  end
  def pbEffectGeneral(user)
    user.effects[PBEffects::FocusEnergy] = 2
    @battle.pbDisplay(_INTL("{1} is getting focused!",user.pbThis))
  end
end

#===============================================================================
# Power is doubled if the target has a status problem, and has a chance to burn. (Infernal Parade)
#===============================================================================
class PokeBattle_Move_605 < PokeBattle_Move
  def pbAdditionalEffect(user,target)
    return if target.damageState.substitute
    chance = pbAdditionalEffectChance(user,target,30)
    return if chance==0
    if @battle.pbRandom(100)<chance
      target.pbBurn(user) if target.pbCanBurn?(user,false,self)
    end
  end

  def pbBaseDamage(baseDmg,user,target)
    if target.pbHasAnyStatus? &&
       (target.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(user))
      baseDmg *= 2
    end
    return baseDmg
  end
end
