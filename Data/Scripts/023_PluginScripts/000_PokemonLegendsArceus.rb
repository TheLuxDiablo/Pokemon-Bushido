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


PLA_STATUS_MODE_FROSTBITE = 0
PLA_STATUS_MODE_DROWSY = 0
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
  Splinters           = 301
  VictoryDance        = 302
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
    
    @effects[PBEffects::Splinters]           = -1
  end 
end 

#===============================================================================
# Removes trapping moves, entry hazards and Leech Seed on user/user's side.
# (Rapid Spin)
# Recommended you add the Splinters code after old Rapid Spin code!
# Also removes Ceaseless Edge, and Stone Axe.
#===============================================================================
class PokeBattle_Move_110 < PokeBattle_Move
  def pbEffectAfterAllHits(user,target)
    return if user.fainted? || target.damageState.unaffected
	# ... skip code until
    if user.pbOwnSide.effects[PBEffects::StickyWeb]
      user.pbOwnSide.effects[PBEffects::StickyWeb] = false
      user.pbOwnSide.effects[PBEffects::StickyWebUser] = -1
      @battle.pbDisplay(_INTL("{1} blew away sticky webs!",user.pbThis))
    end
    # Pokémon Legends: Arceus
    if user.effects[PBEffects::Splinters] > -1
      user.pbOwnSide.effects[PBEffects::Splinters] = -1
      @battle.pbDisplay(_INTL("{1} blew away the splinters!",user.pbThis))
    end
    user.pbRaiseStatStage(:SPEED,1,user)
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
    #when 0 then target.pbDrowse(user) if target.pbCanSleepYawn?(user,false,self)
	when 0 ; target.effects[PBEffects::Yawn] = 2 if target.pbCanSleepYawn?(user,false,self)
    when 1 then target.pbPoison(user) if target.pbCanPoison?(user,false,self)
    when 2 then target.pbParalyze(user) if target.pbCanParalyze?(user,false,self)
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
    return if target.effects[PBEffects::Splinters] > -1
    target.effects[PBEffects::Splinters] = 3+rand(3)
    @battle.pbDisplay(_INTL("Splinters spread around {1}!",target.pbThis(true)))
  end
end

#===============================================================================
# Either boost the user's offensive stats, or decreases the target's defensive 
# stats, depending on form. (Springtide Storm)
#===============================================================================
class PokeBattle_Move_203 < PokeBattle_Move
  def initialize(battle,move)
    super
    @statUp = [:ATTACK,1,:SPECIAL_ATTACK,1]
    @statDown = [:DEFENSE,1,:SPECIAL_DEFENSE,1]
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
class PokeBattle_Move_204 < PokeBattle_Move
  def pbAdditionalEffect(user,target)
    showAnim = true
    statUp = []
    if user.attack + user.spatk >= user.defense + user.spdef
      # Increases the user's offensive stats.
      statUp = [:ATTACK,1,:SPECIAL_ATTACK,1]
    else 
      statUp = [:DEFENSE,1,:SPECIAL_DEFENSE,1]
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
class PokeBattle_Move_205 < PokeBattle_StatUpMove
  def initialize(battle,move)
    super
    @statUp = [:SPEED,1]
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
class PokeBattle_Move_206 < PokeBattle_StatDownMove
  def initialize(battle,move)
    super
    @statDown = [:SPEED,1]
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
class PokeBattle_Move_207 < PokeBattle_MultiStatUpMove
  def initialize(battle,move)
    super
    @statUp = [:ATTACK,1,:DEFENSE,1,
               :SPECIAL_ATTACK,1,:SPECIAL_DEFENSE,1]
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
    @status = :NONE
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
class PokeBattle_Move_208 < PokeBattle_StatusAndBonusDamageMove
  def initialize(battle,move)
    super
    @status = :POISON
  end
end 

# Infernal Parade
class PokeBattle_Move_209 < PokeBattle_StatusAndBonusDamageMove
  def initialize(battle,move)
    super
    @status = :BURN
  end
end 

#===============================================================================
# Raises critical hit ratio + decreases defense. (Triple Arrows)
#===============================================================================

class PokeBattle_Move_20A < PokeBattle_TargetStatDownMove
  def initialize(battle,move)
    super
    @statDown = [:DEFENSE, 1]
  end
  
  def pbEffectAfterAllHits(user,target)
    return if user.effects[PBEffects::FocusEnergy] > 2
    user.effects[PBEffects::FocusEnergy] = 2 
    @battle.pbDisplay(_INTL("{1} is getting pumped!",user.pbThis))
  end 
end 

#===============================================================================
# Heals the user + cures its status. (Lunar Blessing)
#===============================================================================
class PokeBattle_Move_20B < PokeBattle_HealingMove
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
class PokeBattle_Move_20C < PokeBattle_MultiStatUpMove
  def initialize(battle,move)
    super
    @statUp = [:ATTACK, 1, :DEFENSE, 1, 
                  :SPECIAL_ATTACK, 1, :SPECIAL_DEFENSE, 1]
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