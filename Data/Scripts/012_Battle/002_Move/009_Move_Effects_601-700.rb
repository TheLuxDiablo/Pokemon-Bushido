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
