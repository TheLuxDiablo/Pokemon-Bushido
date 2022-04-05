###############################################################################
#
# Pokémon Legends Arceus Content
#
###############################################################################
#
# This script updates the scripts to account for Frostbite, Drowsy, and the
# new moves for Pokémon Legends Arceus.
# Copy/paste this script in a new script above Main.
#
###############################################################################


PLA_STATUS_MODE_FROSTBITE = 1
PLA_STATUS_MODE_DROWSY = 1
# 0 = new moves inflict Drowsy and Frostbite (respectively), old moves keep
#     inflicting Sleep and Freeze.
# 1 = new moves AND old moves inflict Drowsy and Frostbite.
#     NB: Value 1 does not change the behaviour of Rest, Comatose and Yawn
#     and I don't want to waste my time.
# 2 = new moves AND old moves inflict Sleep and Freeze.


###############################################################################
# Adding the new effects Victory Dance, Ceaseless Edge and such.
###############################################################################

module PBEffects
  # Starts from 300 to avoid conflicts with other plugins.
  PowerShift          = 300
  StoneAxe            = 301
  CeaselessEdge       = 302
  VictoryDance        = 303
end

class PokeBattle_Battler
  alias __pla__pbInitEffects pbInitEffects
  def pbInitEffects(batonPass)
    __pla__pbInitEffects(batonPass)
    if batonPass
      if @effects[PBEffects::PowerShift]
        @attack,@defense = @defense,@attack
        @spatk,@spdef = @spdef,@spatk
      end
    else
      @effects[PBEffects::VictoryDance]      = false
      @effects[PBEffects::PowerShift]        = false
    end

    @effects[PBEffects::StoneAxe]            = -1
    @effects[PBEffects::CeaselessEdge]       = -1
  end
end

###############################################################################
# Adding the new statuses Frostbite and Drowsy.
###############################################################################

class PokeBattle_Battler
  #=============================================================================
  # Freeze
  #=============================================================================
  alias __pla__pbCanFreeze pbCanFreeze?
  def pbCanFreeze?(user,showMessages,move=nil)
    case PLA_STATUS_MODE_FROSTBITE
    when 1 # Frostbite instead.
      return pbCanInflictStatus?(PBStatuses::FROSTBITE,user,showMessages,move)
    else
      return __pla__pbCanFreeze(user,showMessages,move)
    end
  end

  alias __pla__pbFreeze pbFreeze
  def pbFreeze(msg=nil)
    case PLA_STATUS_MODE_FROSTBITE
    when 1 # Frostbite instead.
      pbInflictStatus(PBStatuses::FROSTBITE,0,msg)
    else
      __pla__pbFreeze(msg)
    end
  end

  #=============================================================================
  # Frostbitten (Pokémon Legends: Arceus)
  #=============================================================================
  def frostbitten?
    return pbHasStatus?(PBStatuses::FROSTBITE)
  end

  def pbCanFrostbite?(user,showMessages,move=nil)
    case PLA_STATUS_MODE_FROSTBITE
    when 2 # Freeze instead.
      return __pla__pbCanFreeze(user,showMessages,move)
    else
      return pbCanInflictStatus?(PBStatuses::FROSTBITE,user,showMessages,move)
    end
  end

  def pbCanFrostbiteSynchronize?(target)
    return false if PLA_STATUS_MODE_FROSTBITE == 2 # Can't synchronize Freeze.
    return pbCanSynchronizeStatus?(PBStatuses::FROSTBITE,target)
  end

  def pbFrostbite(user=nil,msg=nil)
    case PLA_STATUS_MODE_FROSTBITE
    when 2 # Freeze instead.
      __pla__pbFreeze(msg)
    else
      pbInflictStatus(PBStatuses::FROSTBITE,0,msg,user)
    end
  end
  #=============================================================================
  # Sleep
  #=============================================================================
  alias __pla__pbCanSleep pbCanSleep?
  def pbCanSleep?(user,showMessages,move=nil,ignoreStatus=false)
    case PLA_STATUS_MODE_DROWSY
    when 1 # Drowse instead.
      return pbCanInflictStatus?(PBStatuses::DROWSY,user,showMessages,move,ignoreStatus)
    else
      return __pla__pbCanSleep(user,showMessages,move,ignoreStatus)
    end
  end

  alias __pla__pbSleep pbSleep
  def pbSleep(msg=nil)
    case PLA_STATUS_MODE_DROWSY
    when 1 # Drowse instead.
      pbInflictStatus(PBStatuses::DROWSY,0,msg)
    else
      __pla__pbSleep(msg)
    end
  end

  alias __pla__pbSleepSelf pbSleepSelf
  def pbSleepSelf(msg=nil,duration=-1)
    case PLA_STATUS_MODE_DROWSY
    when 1 # Drowse instead.
      pbInflictStatus(PBStatuses::DROWSY,0,msg)
    else
      __pla__pbSleepSelf(msg,duration)
    end
  end


  #=============================================================================
  # Drowsy (Pokémon Legends: Arceus)
  #=============================================================================
  def drowsy?
    return pbHasStatus?(PBStatuses::DROWSY)
  end

  def pbCanDrowse?(user,showMessages,move=nil)
    case PLA_STATUS_MODE_DROWSY
    when 2 # Sleep instead.
      return pbCanInflictStatus?(PBStatuses::SLEEP,user,showMessages,move)
    else
      return pbCanInflictStatus?(PBStatuses::DROWSY,user,showMessages,move)
    end
  end

  def pbCanDrowseSynchronize?(target)
    return false if PLA_STATUS_MODE_DROWSY == 2 # Can't synchronize Sleep.
    return pbCanSynchronizeStatus?(PBStatuses::DROWSY,target)
  end

  def pbDrowse(user=nil,msg=nil)
    case PLA_STATUS_MODE_DROWSY
    when 2 # Sleep instead.
      pbInflictStatus(PBStatuses::SLEEP,pbSleepDuration,msg)
    else
      pbInflictStatus(PBStatuses::DROWSY,0,msg,user)
    end
  end

=begin
  #=============================================================================
  # Un-drowse / de-frostbite at the end of a move.
  #=============================================================================
  alias __pla__pbEffectsAfterMove pbEffectsAfterMove
  def pbEffectsAfterMove(user,targets,move,numHits)
    # Un-drowse
    if move.damagingMove?
      targets.each do |b|
        next if b.damageState.unaffected || b.damageState.substitute
        next if b.status!=PBStatuses::DROWSY
        # NOTE: non-cannon.
        # I decide that Electric moves un-drowse the target.
        if isConst?(move.calcType,PBTypes,:ELECTRIC) ||
           (NEWEST_BATTLE_MECHANICS && move.undrowsesUser?)
          b.pbCureStatus
        end
      end
    end
    # De-frostbite
    if move.damagingMove?
      targets.each do |b|
        next if b.damageState.unaffected || b.damageState.substitute
        next if b.status!=PBStatuses::FROSTBITE
        # NOTE: non-cannon.
        # I decide that Fire-type moves un-frostbite the target.
        if isConst?(move.calcType,PBTypes,:FIRE) ||
           (NEWEST_BATTLE_MECHANICS && move.thawsUser?)
          b.pbCureStatus
        end
      end
    end
    __pla__pbEffectsAfterMove(user,targets,move,numHits)
  end
=end
end


# Weaken most moves if the Pokémon is Frostbitten.
class PokeBattle_Move
  def damageReducedByFrostbite?; return true;  end

  def undrowsesUser?
    return [PBMoves::WILDCHARGE, PBMoves::SPARK, PBMoves::VOLTTACKLE].include?(@id)
  end
end



###############################################################################
# Updated moves to take into account the new statuses Drowsy and Frostbite.
###############################################################################

#===============================================================================
# Cures user of burn, poison and paralysis. (Refresh)
# Now also cures Frostbite and Drowsy.
#===============================================================================
class PokeBattle_Move_018 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    if user.status!=PBStatuses::BURN &&
       user.status!=PBStatuses::POISON &&
       user.status!=PBStatuses::PARALYSIS &&
       user.status!=PBStatuses::FROSTBITE &&
       user.status!=PBStatuses::DROWSY
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    t = user.status
    user.pbCureStatus(false)
    case t
    when PBStatuses::BURN
      @battle.pbDisplay(_INTL("{1} healed its burn!",user.pbThis))
    when PBStatuses::POISON
      @battle.pbDisplay(_INTL("{1} cured its poisoning!",user.pbThis))
    when PBStatuses::PARALYSIS
      @battle.pbDisplay(_INTL("{1} cured its paralysis!",user.pbThis))
    when PBStatuses::FROSTBITE
      @battle.pbDisplay(_INTL("{1} healed its frostbite",curedName))
    when PBStatuses::DROWSY
      @battle.pbDisplay(_INTL("{1} is longer drowsy!",curedName))
    end
  end
end

#===============================================================================
# Cures all party Pokémon of permanent status problems. (Aromatherapy, Heal Bell)
# Now also cures Frostbite and Drowsy.
#===============================================================================
class PokeBattle_Move_019 < PokeBattle_Move
  def pbAromatherapyHeal(pkmn,battler=nil)
    oldStatus = (battler) ? battler.status : pkmn.status
    curedName = (battler) ? battler.pbThis : pkmn.name
    if battler
      battler.pbCureStatus(false)
    else
      pkmn.status      = PBStatuses::NONE
      pkmn.statusCount = 0
    end
    case oldStatus
    when PBStatuses::SLEEP
      @battle.pbDisplay(_INTL("{1} was woken from sleep.",curedName))
    when PBStatuses::POISON
      @battle.pbDisplay(_INTL("{1} was cured of its poisoning.",curedName))
    when PBStatuses::BURN
      @battle.pbDisplay(_INTL("{1}'s burn was healed.",curedName))
    when PBStatuses::PARALYSIS
      @battle.pbDisplay(_INTL("{1} was cured of paralysis.",curedName))
    when PBStatuses::FROZEN
      @battle.pbDisplay(_INTL("{1} was thawed out.",curedName))
    when PBStatuses::FROSTBITE
      @battle.pbDisplay(_INTL("{1}'s frostbite was healed.",curedName))
    when PBStatuses::DROWSY
      @battle.pbDisplay(_INTL("{1} was pulled out of drowsiness.",curedName))
    end
  end
end

#===============================================================================
# User passes its status problem to the target. (Psycho Shift)
# Now also passes Frostbite and Drowsy.
#===============================================================================
class PokeBattle_Move_01B < PokeBattle_Move
  def pbEffectAgainstTarget(user,target)
    msg = ""
    case user.status
    when PBStatuses::SLEEP
      target.pbSleep
      msg = _INTL("{1} woke up.",user.pbThis)
    when PBStatuses::POISON
      target.pbPoison(user,nil,user.statusCount!=0)
      msg = _INTL("{1} was cured of its poisoning.",user.pbThis)
    when PBStatuses::BURN
      target.pbBurn(user)
      msg = _INTL("{1}'s burn was healed.",user.pbThis)
    when PBStatuses::PARALYSIS
      target.pbParalyze(user)
      msg = _INTL("{1} was cured of paralysis.",user.pbThis)
    when PBStatuses::FROZEN
      target.pbFreeze
      msg = _INTL("{1} was thawed out.",user.pbThis)
    when PBStatuses::FROSTBITE
      target.pbFrostbite(user)
      msg = _INTL("{1}'s frostbite was healed.",user.pbThis)
    when PBStatuses::DROWSY
      target.pbDrowse(user)
      msg = _INTL("{1} is no longer drowsy.",user.pbThis)
    end
    if msg!=""
      user.pbCureStatus(false)
      @battle.pbDisplay(msg)
    end
  end
end

#===============================================================================
# Power is doubled if the target is asleep. Wakes the target up. (Wake-Up Slap)
# Also cures Drowsy.
#===============================================================================
class PokeBattle_Move_07D < PokeBattle_Move
  def pbEffectAfterAllHits(user,target)
    return if target.fainted?
    return if target.damageState.unaffected || target.damageState.substitute
    return if target.status!=PBStatuses::SLEEP && target.status!=PBStatuses::DROWSY
    target.pbCureStatus
  end
end

#===============================================================================
# User must use this move for 2 more rounds. No battlers can sleep. (Uproar)
# Also cures Drowsy.
#===============================================================================
class PokeBattle_Move_0D1 < PokeBattle_Move
  def pbEffectGeneral(user)
    return if user.effects[PBEffects::Uproar]>0
    user.effects[PBEffects::Uproar] = 3
    user.currentMove = @id
    @battle.pbDisplay(_INTL("{1} caused an uproar!",user.pbThis))
    @battle.pbPriority(true).each do |b|
      next if b.fainted? || (b.status!=PBStatuses::SLEEP && b.status!=PBStatuses::DROWSY)
      next if b.hasActiveAbility?(:SOUNDPROOF)
      b.pbCureStatus
    end
  end
end

#===============================================================================
# Removes trapping moves, entry hazards and Leech Seed on user/user's side.
# (Rapid Spin)
# Also removes Ceaseless Edge, and Stone Axe.
#===============================================================================
class PokeBattle_Move_110 < PokeBattle_Move
  def pbEffectAfterAllHits(user,target)
    return if user.fainted? || target.damageState.unaffected
    if user.effects[PBEffects::Trapping]>0
      trapMove = PBMoves.getName(user.effects[PBEffects::TrappingMove])
      trapUser = @battle.battlers[user.effects[PBEffects::TrappingUser]]
      @battle.pbDisplay(_INTL("{1} got free of {2}'s {3}!",user.pbThis,trapUser.pbThis(true),trapMove))
      user.effects[PBEffects::Trapping]     = 0
      user.effects[PBEffects::TrappingMove] = 0
      user.effects[PBEffects::TrappingUser] = -1
    end
    if user.effects[PBEffects::LeechSeed]>=0
      user.effects[PBEffects::LeechSeed] = -1
      @battle.pbDisplay(_INTL("{1} shed Leech Seed!",user.pbThis))
    end
    if user.pbOwnSide.effects[PBEffects::StealthRock]
      user.pbOwnSide.effects[PBEffects::StealthRock] = false
      @battle.pbDisplay(_INTL("{1} blew away stealth rocks!",user.pbThis))
    end
    if user.pbOwnSide.effects[PBEffects::Spikes]>0
      user.pbOwnSide.effects[PBEffects::Spikes] = 0
      @battle.pbDisplay(_INTL("{1} blew away spikes!",user.pbThis))
    end
    if user.pbOwnSide.effects[PBEffects::ToxicSpikes]>0
      user.pbOwnSide.effects[PBEffects::ToxicSpikes] = 0
      @battle.pbDisplay(_INTL("{1} blew away poison spikes!",user.pbThis))
    end
    if user.pbOwnSide.effects[PBEffects::StickyWeb]
      user.pbOwnSide.effects[PBEffects::StickyWeb] = false
      user.pbOwnSide.effects[PBEffects::StickyWebUser] = -1
      @battle.pbDisplay(_INTL("{1} blew away sticky webs!",user.pbThis))
    end
    # Pokémon Legends: Arceus
    if user.effects[PBEffects::CeaselessEdge] > -1 ||
      user.effects[PBEffects::StoneAxe] > -1
      user.pbOwnSide.effects[PBEffects::StoneAxe] = -1
      user.pbOwnSide.effects[PBEffects::CeaselessEdge] = -1
      @battle.pbDisplay(_INTL("{1} blew away the splinters!",user.pbThis))
    end
    user.pbRaiseStatStage(PBStats::SPEED,1,user) if user.pbCanRaiseStatStage?(PBStats::SPEED, user, self)
  end
end


#===============================================================================
# Cures the target's burn and frostbite. (Sparkling Aria)
#===============================================================================
class PokeBattle_Move_15A < PokeBattle_Move
  def pbAdditionalEffect(user,target)
    return if target.fainted? || target.damageState.substitute
    return if target.status!=PBStatuses::BURN && target.status!=PBStatuses::FROSTBITE
    target.pbCureStatus
  end
end



###############################################################################
#
# New moves from Pokémon Legends Arceus
#
###############################################################################

#===============================================================================
# Paralyzes, poisons or forces the target to sleep. (Dire Claw)
# Note: the sleep effect is adapted from Pokémon Legends: Arceus's Drowsy status.
#===============================================================================
class PokeBattle_Move_200 < PokeBattle_Move
  def pbAdditionalEffect(user,target)
    return if target.damageState.substitute
    case @battle.pbRandom(3)
    when 0; target.pbDrowse(user) if target.pbCanDrowse?(user,false,self)
    when 1; target.pbPoison(user) if target.pbCanPoison?(user,false,self)
    when 2; target.pbParalyze(user) if target.pbCanParalyze?(user,false,self)
    end
  end
end

#===============================================================================
# Swaps the user's offensive and defensive stats. (Power Shift)
# Note: To me this means inverting both attack / special attack with
# defense / special defense.
#===============================================================================
class PokeBattle_Move_201 < PokeBattle_Move
  def pbEffectGeneral(user)
    user.attack,user.defense = user.defense,user.attack
    user.spatk,user.spdef = user.spdef,user.spatk
    user.effects[PBEffects::PowerShift] = !user.effects[PBEffects::PowerShift]
    @battle.pbDisplay(_INTL("{1} switched its offensive and defensive stats!",user.pbThis))
  end
end

#===============================================================================
# After the hit, leaves a specific damaging effect. (Stone Axe, Ceaseless Edge)
#===============================================================================
class PokeBattle_Move_202 < PokeBattle_Move
  def pbEffectAgainstTarget(user,target)
    return if target.effects[PBEffects::StoneAxe] > -1
    target.effects[PBEffects::StoneAxe] = 3+rand(3)
    @battle.pbDisplay(_INTL("Splinters spread around {1}!",target.pbThis(true)))
  end
end

class PokeBattle_Move_203 < PokeBattle_Move
  def pbEffectAgainstTarget(user,target)
    return if target.effects[PBEffects::CeaselessEdge] > -1
    target.effects[PBEffects::CeaselessEdge] = 3+rand(3)
    @battle.pbDisplay(_INTL("Splinters spread around {1}!",target.pbThis(true)))
  end
end

#===============================================================================
# Either boost the user's offensive stats, or decreases the target's defensive
# stats, depending on form. (Springtide Storm)
#===============================================================================
class PokeBattle_Move_204 < PokeBattle_Move
  def initialize(battle,move)
    super
    @statUp = [PBStats::ATTACK,1,PBStats::SPATK,1]
    @statDown = [PBStats::DEFENSE,1,PBStats::SPDEF,1]
  end

  def pbAdditionalEffect(user,target)
    # return if user.species != PBSpecies::ENAMORUS # DEBUG
    showAnim = true

    if user.form == 1
      # Decreases the target's stats.
      return if target.damageState.substitute
      for i in 0...@statDown.length/2
        next if !target.pbCanLowerStatStage?(@statDown[i*2],user,self)
        if target.pbLowerStatStage(@statDown[i*2],@statDown[i*2+1],user,showAnim)
          showAnim = false
        end
      end
    else
      # Increases the user's stats.
      for i in 0...@statUp.length/2
        next if !user.pbCanRaiseStatStage?(@statUp[i*2],user,self)
        if user.pbRaiseStatStage(@statUp[i*2],@statUp[i*2+1],user,showAnim)
          showAnim = false
        end
      end
    end
  end
end

#===============================================================================
# Either boost offensive stats, or defensive stats, depending on the stats of
# the Pokémon. (Mystical Power)
#===============================================================================
class PokeBattle_Move_205 < PokeBattle_Move
  def pbAdditionalEffect(user,target)
    showAnim = true
    statUp = []
    if user.attack + user.spatk >= user.defense + user.spdef
      # Increases the user's offensive stats.
      statUp = [PBStats::ATTACK,1,PBStats::SPATK,1]
    else
      statUp = [PBStats::DEFENSE,1,PBStats::SPDEF,1]
    end

    for i in 0...statUp.length/2
      next if !user.pbCanRaiseStatStage?(statUp[i*2],user,self)
      if user.pbRaiseStatStage(statUp[i*2],statUp[i*2+1],user,showAnim)
        showAnim = false
      end
    end
  end
end

#===============================================================================
# Recoil + boosts the user's speed. (Wave Crash)
#===============================================================================
class PokeBattle_Move_206 < PokeBattle_StatUpMove
  def initialize(battle,move)
    super
    @statUp = [PBStats::SPEED,1]
  end

  def recoilMove?;                 return true; end

  def pbRecoilDamage(user,target)
    return (target.damageState.totalHPLost/4.0).round
  end

  def pbEffectAfterAllHits(user,target)
    return if target.damageState.unaffected
    return if !user.takesIndirectDamage?
    return if user.hasActiveAbility?(:ROCKHEAD)
    amt = pbRecoilDamage(user,target)
    amt = 1 if amt<1
    user.pbReduceHP(amt,false)
    @battle.pbDisplay(_INTL("{1} is damaged by recoil!",user.pbThis))
    user.pbItemHPHealCheck
  end
end

#===============================================================================
# Heavy recoil + decreases the user's speed. (Chloroblast)
#===============================================================================
class PokeBattle_Move_207 < PokeBattle_StatDownMove
  def initialize(battle,move)
    super
    @statDown = [PBStats::SPEED,1]
  end

  def recoilMove?;                 return true; end

  def pbRecoilDamage(user,target)
    return (target.damageState.totalHPLost/2.0).round
  end

  def pbEffectAfterAllHits(user,target)
    return if target.damageState.unaffected
    return if !user.takesIndirectDamage?
    return if user.hasActiveAbility?(:ROCKHEAD)
    amt = pbRecoilDamage(user,target)
    amt = 1 if amt<1
    user.pbReduceHP(amt,false)
    @battle.pbDisplay(_INTL("{1} is damaged by recoil!",user.pbThis))
    user.pbItemHPHealCheck
  end
end

#===============================================================================
# Boosts stats + bonus effect. (Victory Dance)
#===============================================================================
class PokeBattle_Move_208 < PokeBattle_MultiStatUpMove
  def initialize(battle,move)
    super
    @statUp = [PBStats::ATTACK,1,PBStats::DEFENSE,1,
               PBStats::SPATK,1,PBStats::SPDEF,1]
  end

  def pbAdditionalEffect(user,target)
    super

    if !user.effects[PBEffects::VictoryDance]
      user.effects[PBEffects::VictoryDance] = true
      @battle.pbDisplay(_INTL("{1} dances in victory!", user.pbThis))
    end
  end
end

#===============================================================================
# Bonus damage if target has a status effect + can inflict status.
# (Barb Barrage, Bitter Malice, Infernal Parade)
#===============================================================================

class PokeBattle_StatusAndBonusDamageMove < PokeBattle_Move
  def initialize(battle,move)
    super
    @status = PBStatuses::NONE
  end

  def pbBaseDamage(baseDmg,user,target)
    if target.pbHasAnyStatus? &&
       (target.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(user))
      baseDmg *= 2
    end
    return baseDmg
  end

  def pbAdditionalEffect(user,target)
    return if target.damageState.substitute
    target.pbInflictStatus(@status,0,nil,user) if target.pbCanInflictStatus?(@status,user,false,self)
  end
end

# Barb Barrage
class PokeBattle_Move_209 < PokeBattle_StatusAndBonusDamageMove
  def initialize(battle,move)
    super
    @status = PBStatuses::POISON
  end
end

# Bitter Malice
class PokeBattle_Move_210 < PokeBattle_StatusAndBonusDamageMove
  def initialize(battle,move)
    super
    @status = PBStatuses::FROSTBITE
  end
end

# Infernal Parade
class PokeBattle_Move_211 < PokeBattle_StatusAndBonusDamageMove
  def initialize(battle,move)
    super
    @status = PBStatuses::BURN
  end
end

#===============================================================================
# Raises critical hit ratio + decreases defense. (Triple Arrows)
#===============================================================================

class PokeBattle_Move_212 < PokeBattle_TargetStatDownMove
  def initialize(battle,move)
    super
    @statDown = [PBStats::DEFENSE, 1]
  end

  def pbEffectAfterAllHits(user,target)
    return if user.effects[PBEffects::FocusEnergy] > 2
    user.effects[PBEffects::FocusEnergy] = 2
    @battle.pbDisplay(_INTL("{1} is getting pumped!",user.pbThis))
  end
end


#===============================================================================
# Generic Frostbite-inflicting move.
#===============================================================================
class PokeBattle_FrostbiteMove < PokeBattle_Move
  def pbFailsAgainstTarget?(user,target)
    return false if damagingMove?
    return !target.pbCanFrostbite?(user,true,self)
  end

  def pbEffectAgainstTarget(user,target)
    return if damagingMove?
    target.pbFrostbite(user,nil)
  end

  def pbAdditionalEffect(user,target)
    return if target.damageState.substitute
    target.pbFrostbite(user,nil) if target.pbCanFrostbite?(user,false,self)
  end
end

#===============================================================================
# Generic Drowsiness-inflicting move.
#===============================================================================
class PokeBattle_DrowsyMove < PokeBattle_Move
  def pbFailsAgainstTarget?(user,target)
    return false if damagingMove?
    return !target.pbCanDrowse?(user,true,self)
  end

  def pbEffectAgainstTarget(user,target)
    return if damagingMove?
    target.pbDrowse(user,nil)
  end

  def pbAdditionalEffect(user,target)
    return if target.damageState.substitute
    target.pbDrowse(user,nil) if target.pbCanDrowse?(user,false,self)
  end
end

#===============================================================================
# Inflicts Frostbite. (Bleakwind Storm)
#===============================================================================
class PokeBattle_Move_213 < PokeBattle_FrostbiteMove
end

#===============================================================================
# Heals the user + cures its status. (Lunar Blessing)
#===============================================================================
class PokeBattle_Move_214 < PokeBattle_HealingMove
  def pbHealAmount(user)
    return (user.totalhp/3.0).round
  end
  def pbMoveFailed?(user,targets)
    return false if user.pbHasAnyStatus?
    return super
  end
  def pbEffectGeneral(user)
    user.pbCureStatus
    super
  end
end

#===============================================================================
# Cures the user's status + raises its stats. (Take Heart)
#===============================================================================
class PokeBattle_Move_215 < PokeBattle_MultiStatUpMove
  def initialize(battle,move)
    super
    @statUp = [PBStats::ATTACK, 1, PBStats::DEFENSE, 1,
                  PBStats::SPATK, 1, PBStats::SPDEF, 1]
  end

  def pbMoveFailed?(user,targets)
    return false if user.pbHasAnyStatus?
    return super
  end

  def pbEffectGeneral(user)
    user.pbCureStatus if user.pbHasAnyStatus?
    super
  end
end


###############################################################################
#
# Update to abilities
#
###############################################################################


BattleHandlers::StatusImmunityAbility.add(:INSOMNIA,
  proc { |ability,battler,status|
    next true if status==PBStatuses::SLEEP
    next true if status==PBStatuses::DROWSY
  }
)

BattleHandlers::StatusImmunityAllyAbility.add(:SWEETVEIL,
  proc { |ability,battler,status|
    next true if status==PBStatuses::SLEEP
    next true if status==PBStatuses::DROWSY
  }
)


BattleHandlers::StatusImmunityAbility.add(:MAGMAARMOR,
  proc { |ability,battler,status|
    next true if status==PBStatuses::FROZEN
    next true if status==PBStatuses::FROSTBITE
  }
)


BattleHandlers::StatusCureAbility.add(:INSOMNIA,
  proc { |ability,battler|
    next if (battler.status!=PBStatuses::SLEEP && battler.status!=PBStatuses::DROWSY)
    battler.battle.pbShowAbilitySplash(battler)
    battler.pbCureStatus(PokeBattle_SceneConstants::USE_ABILITY_SPLASH)
    if !PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      battler.battle.pbDisplay(_INTL("{1}'s {2} woke it up!",battler.pbThis,battler.abilityName))
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

BattleHandlers::AbilityOnStatusInflicted.add(:SYNCHRONIZE,
  proc { |ability,battler,user,status|
    next if !user || user.index==battler.index
    case status
    when PBStatuses::POISON
      if user.pbCanPoisonSynchronize?(battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !PokeBattle_SceneConstants::USE_ABILITY_SPLASH
          msg = _INTL("{1}'s {2} poisoned {3}!",battler.pbThis,battler.abilityName,user.pbThis(true))
        end
        user.pbPoison(nil,msg,(battler.statusCount>0))
        battler.battle.pbHideAbilitySplash(battler)
      end
    when PBStatuses::BURN
      if user.pbCanBurnSynchronize?(battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !PokeBattle_SceneConstants::USE_ABILITY_SPLASH
          msg = _INTL("{1}'s {2} burned {3}!",battler.pbThis,battler.abilityName,user.pbThis(true))
        end
        user.pbBurn(nil,msg)
        battler.battle.pbHideAbilitySplash(battler)
      end
    when PBStatuses::PARALYSIS
      if user.pbCanParalyzeSynchronize?(battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !PokeBattle_SceneConstants::USE_ABILITY_SPLASH
          msg = _INTL("{1}'s {2} paralyzed {3}! It may be unable to move!",
             battler.pbThis,battler.abilityName,user.pbThis(true))
        end
        user.pbParalyze(nil,msg)
        battler.battle.pbHideAbilitySplash(battler)
      end
    when PBStatuses::FROSTBITE
      if user.pbCanFrostbiteSynchronize?(battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !PokeBattle_SceneConstants::USE_ABILITY_SPLASH
          msg = _INTL("{1}'s {2} frostbit {3}!",battler.pbThis,battler.abilityName,user.pbThis(true))
        end
        user.pbFrostbite(nil,msg)
        battler.battle.pbHideAbilitySplash(battler)
      end
    when PBStatuses::DROWSY
      if user.pbCanDrowseSynchronize?(battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !PokeBattle_SceneConstants::USE_ABILITY_SPLASH
          msg = _INTL("{1}'s {2} made {3} drowsy!",
             battler.pbThis,battler.abilityName,user.pbThis(true))
        end
        user.pbDrowse(nil,msg)
        battler.battle.pbHideAbilitySplash(battler)
      end
    end
  }
)


BattleHandlers::EORHealingAbility.add(:HEALER,
  proc { |ability,battler,battle|
    next unless battle.pbRandom(100)<30
    battler.eachAlly do |b|
      next if b.status==PBStatuses::NONE
      battle.pbShowAbilitySplash(battler)
      oldStatus = b.status
      b.pbCureStatus(PokeBattle_SceneConstants::USE_ABILITY_SPLASH)
      if !PokeBattle_SceneConstants::USE_ABILITY_SPLASH
        case oldStatus
        when PBStatuses::SLEEP
          battle.pbDisplay(_INTL("{1}'s {2} woke its partner up!",battler.pbThis,battler.abilityName))
        when PBStatuses::POISON
          battle.pbDisplay(_INTL("{1}'s {2} cured its partner's poison!",battler.pbThis,battler.abilityName))
        when PBStatuses::BURN
          battle.pbDisplay(_INTL("{1}'s {2} healed its partner's burn!",battler.pbThis,battler.abilityName))
        when PBStatuses::PARALYSIS
          battle.pbDisplay(_INTL("{1}'s {2} cured its partner's paralysis!",battler.pbThis,battler.abilityName))
        when PBStatuses::FROZEN
          battle.pbDisplay(_INTL("{1}'s {2} defrosted its partner!",battler.pbThis,battler.abilityName))
        when PBStatuses::FROSTBITE
          battle.pbDisplay(_INTL("{1}'s {2} healed its partner's frostbite!",battler.pbThis,battler.abilityName))
        when PBStatuses::DROWSY
          battle.pbDisplay(_INTL("{1}'s {2} pulled its partner out of drowsiness!",battler.pbThis,battler.abilityName))
        end
      end
      battle.pbHideAbilitySplash(battler)
    end
  }
)

BattleHandlers::EORHealingAbility.add(:HYDRATION,
  proc { |ability,battler,battle|
  if !battler.hasUtilityUmbrella?
    next if battler.status==PBStatuses::NONE
    curWeather = battle.pbWeather
    next if curWeather!=PBWeather::Rain && curWeather!=PBWeather::HeavyRain
    battle.pbShowAbilitySplash(battler)
    oldStatus = battler.status
    battler.pbCureStatus(PokeBattle_SceneConstants::USE_ABILITY_SPLASH)
    if !PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      case oldStatus
      when PBStatuses::SLEEP
        battle.pbDisplay(_INTL("{1}'s {2} woke it up!",battler.pbThis,battler.abilityName))
      when PBStatuses::POISON
        battle.pbDisplay(_INTL("{1}'s {2} cured its poison!",battler.pbThis,battler.abilityName))
      when PBStatuses::BURN
        battle.pbDisplay(_INTL("{1}'s {2} healed its burn!",battler.pbThis,battler.abilityName))
      when PBStatuses::PARALYSIS
        battle.pbDisplay(_INTL("{1}'s {2} cured its paralysis!",battler.pbThis,battler.abilityName))
      when PBStatuses::FROZEN
        battle.pbDisplay(_INTL("{1}'s {2} defrosted it!",battler.pbThis,battler.abilityName))
      when PBStatuses::FROSTBITE
        battle.pbDisplay(_INTL("{1}'s {2} healed its frostbite!",battler.pbThis,battler.abilityName))
      when PBStatuses::DROWSY
        battle.pbDisplay(_INTL("{1}'s {2} pulled it out of drowsiness!",battler.pbThis,battler.abilityName))
      end
    end
    battle.pbHideAbilitySplash(battler)
  end
  }
)

BattleHandlers::EORHealingAbility.add(:SHEDSKIN,
  proc { |ability,battler,battle|
    next if battler.status==PBStatuses::NONE
    next unless battle.pbRandom(100)<30
    battle.pbShowAbilitySplash(battler)
    oldStatus = battler.status
    battler.pbCureStatus(PokeBattle_SceneConstants::USE_ABILITY_SPLASH)
    if !PokeBattle_SceneConstants::USE_ABILITY_SPLASH
      case oldStatus
      when PBStatuses::SLEEP
        battle.pbDisplay(_INTL("{1}'s {2} woke it up!",battler.pbThis,battler.abilityName))
      when PBStatuses::POISON
        battle.pbDisplay(_INTL("{1}'s {2} cured its poison!",battler.pbThis,battler.abilityName))
      when PBStatuses::BURN
        battle.pbDisplay(_INTL("{1}'s {2} healed its burn!",battler.pbThis,battler.abilityName))
      when PBStatuses::PARALYSIS
        battle.pbDisplay(_INTL("{1}'s {2} cured its paralysis!",battler.pbThis,battler.abilityName))
      when PBStatuses::FROZEN
        battle.pbDisplay(_INTL("{1}'s {2} defrosted it!",battler.pbThis,battler.abilityName))
      when PBStatuses::FROSTBITE
        battle.pbDisplay(_INTL("{1}'s {2} healed its frostbite!",battler.pbThis,battler.abilityName))
      when PBStatuses::DROWSY
        battle.pbDisplay(_INTL("{1}'s {2} pulled it out of drowsiness!",battler.pbThis,battler.abilityName))
      end
    end
    battle.pbHideAbilitySplash(battler)
  }
)

###############################################################################
#
# Updated items
#
###############################################################################


BattleHandlers::StatusCureItem.add(:CHESTOBERRY,
  proc { |item,battler,battle,forced|
    next false if !forced && !battler.canConsumeBerry?
    next false if (battler.status!=PBStatuses::SLEEP && battler.status!=PBStatuses::DROWSY)
    itemName = PBItems.getName(item)
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}") if forced
    battle.pbCommonAnimation("EatBerry",battler) if !forced
    battler.pbCureStatus(forced)
    battle.pbDisplay(_INTL("{1}'s {2} woke it up!",battler.pbThis,itemName)) if !forced
    next true
  }
)

BattleHandlers::StatusCureItem.add(:LUMBERRY,
  proc { |item,battler,battle,forced|
    next false if !forced && !battler.canConsumeBerry?
    next false if battler.status==PBStatuses::NONE &&
                  battler.effects[PBEffects::Confusion]==0
    itemName = PBItems.getName(item)
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}") if forced
    battle.pbCommonAnimation("EatBerry",battler) if !forced
    oldStatus = battler.status
    oldConfusion = (battler.effects[PBEffects::Confusion]>0)
    battler.pbCureStatus(forced)
    battler.pbCureConfusion
    if forced
      battle.pbDisplay(_INTL("{1} snapped out of its confusion.",battler.pbThis)) if oldConfusion
    else
      case oldStatus
      when PBStatuses::SLEEP
        battle.pbDisplay(_INTL("{1}'s {2} woke it up!",battler.pbThis,itemName))
      when PBStatuses::POISON
        battle.pbDisplay(_INTL("{1}'s {2} cured its poisoning!",battler.pbThis,itemName))
      when PBStatuses::BURN
        battle.pbDisplay(_INTL("{1}'s {2} healed its burn!",battler.pbThis,itemName))
      when PBStatuses::PARALYSIS
        battle.pbDisplay(_INTL("{1}'s {2} cured its paralysis!",battler.pbThis,itemName))
      when PBStatuses::FROZEN
        battle.pbDisplay(_INTL("{1}'s {2} defrosted it!",battler.pbThis,itemName))
      when PBStatuses::FROSTBITE
        battle.pbDisplay(_INTL("{1}'s {2} healed its frostbite!",battler.pbThis,itemName))
      when PBStatuses::DROWSY
        battle.pbDisplay(_INTL("{1}'s {2} pulled it out of drowsiness!",battler.pbThis,itemName))
      end
      if oldConfusion
        battle.pbDisplay(_INTL("{1}'s {2} snapped it out of its confusion!",battler.pbThis,itemName))
      end
    end
    next true
  }
)
