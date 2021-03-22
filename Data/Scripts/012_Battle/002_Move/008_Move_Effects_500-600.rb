
################################################################################
# Increase an ally's Special Defense by 1 stage.
################################################################################
class PokeBattle_Move_501 < PokeBattle_StatUpMove
  def initialize(battle,move)
    super
    @statUp = [PBStats::SPDEF,1]
  end
end


#===============================================================================
# Reduces the user's HP by 1/3 of max, and increases all stats.
# (Clangorous Soul)
#===============================================================================
class PokeBattle_Move_503 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    hpLoss = [user.totalhp/3,1].max
    if user.hp<=hpLoss
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return true if !user.pbCanRaiseStatStage?(PBStats::ATTACK,user,self,true)
    return true if !user.pbCanRaiseStatStage?(PBStats::DEFENSE,user,self,true)
    return true if !user.pbCanRaiseStatStage?(PBStats::SPATK,user,self,true)
    return true if !user.pbCanRaiseStatStage?(PBStats::SPDEF,user,self,true)
    return true if !user.pbCanRaiseStatStage?(PBStats::SPEED,user,self,true)
    return false
  end

  def pbEffectGeneral(user)
    hpLoss = [user.totalhp/3,1].max
    user.pbReduceHP(hpLoss,false)
    if user.hasActiveAbility?(:CONTRARY)
      user.stages[PBStats::ATTACK] -= 1
      user.stages[PBStats::DEFENSE] -= 1
      user.stages[PBStats::SPATK] -= 1
      user.stages[PBStats::SPDEF] -= 1
      user.stages[PBStats::SPEED] -= 1
      @battle.pbCommonAnimation("StatDown",user)
      @battle.pbDisplay(_INTL("{1} cut its own HP and lower all of its stats!",user.pbThis))
    else
      user.stages[PBStats::ATTACK] += 1
      user.stages[PBStats::DEFENSE] += 1
      user.stages[PBStats::SPATK] += 1
      user.stages[PBStats::SPDEF] += 1
      user.stages[PBStats::SPEED] += 1
      @battle.pbCommonAnimation("StatUp",user)
      @battle.pbDisplay(_INTL("{1} cut its own HP and increased all of its stats!",user.pbThis))
    end
    user.pbItemHPHealCheck
  end
end

#===============================================================================
# Heals user and ally by 1/4 of max HP. (Life Dew)
#===============================================================================
class PokeBattle_Move_504 < PokeBattle_Move
  def ignoresSubstitute?(user); return true; end

  def pbEffectAgainstTarget(user,target)
    showAnim = true
    target.pbRecoverHP((target.totalhp/4.0).round)
    @battle.pbDisplay(_INTL("{1} was healed by the energy of the life dew!",target.pbThis))
  end

  def pbEffectGeneral(user)
    return if pbTarget(user)==PBTargets::UserAndAllies
    @validTargets.each { |b| pbEffectAgainstTarget(user,b) }
  end
end

#===============================================================================
# This attack is always a critical hit and hits 3 times. (Surging Strikes)
#===============================================================================
class PokeBattle_Move_505 < PokeBattle_Move
  def pbCritialOverride(user,target); return 1; end
  def multiHitMove?;           return true; end
  def pbNumHits(user,targets); return 3;    end
end

#===============================================================================
# Cures all party Pokémon of permanent status problems.
# Also heals user and allies by 25% of max HP. (Jungle Healing)
#===============================================================================
class PokeBattle_Move_506 < PokeBattle_Move
  def ignoresSubstitute?(user); return true; end

  def pbEffectAgainstTarget(user,target)
    showAnim = true
    target.pbRecoverHP((target.totalhp/4.0).round)
    target.pbCureStatus(false)
    @battle.pbDisplay(_INTL("{1} was healed by the energy of the jungle!",target.pbThis))
  end

  def pbEffectGeneral(user)
    return if pbTarget(user)==PBTargets::UserAndAllies
    @validTargets.each { |b| pbEffectAgainstTarget(user,b) }
  end
end

################################################################################
# Swaps barriers, veils and other effects between each side of the battlefield.
# (Court Change)
################################################################################
class PokeBattle_Move_507 < PokeBattle_Move
  def pbEffectGeneral(user)
    changeside=false
    for i in 0...2
      next if @battle.sides[i].effects[PBEffects::Reflect]==0 &&
              @battle.sides[i].effects[PBEffects::LightScreen]==0 &&
              @battle.sides[i].effects[PBEffects::AuroraVeil]==0 &&
              @battle.sides[i].effects[PBEffects::SeaOfFire]==0 && # Fire Pledge
              @battle.sides[i].effects[PBEffects::Swamp]==0 &&     # Grass Pledge
              @battle.sides[i].effects[PBEffects::Rainbow]==0 &&   # Water Pledge
              @battle.sides[i].effects[PBEffects::Mist]==0 &&
              @battle.sides[i].effects[PBEffects::Safeguard]==0 &&
             !@battle.sides[i].effects[PBEffects::StealthRock] &&
              @battle.sides[i].effects[PBEffects::Spikes]==0 &&
             !@battle.sides[i].effects[PBEffects::StickyWeb] &&
              @battle.sides[i].effects[PBEffects::ToxicSpikes]==0 &&
              @battle.sides[i].effects[PBEffects::Tailwind]==0
      changeside=true
    end
    if !changeside
      @battle.pbDisplay(_INTL("But it failed!"))
      return -1
    else
      #pbShowAnimation(@id,user,nil,hitnum,alltargets,showanimation)
      ownside=@battle.sides[0]; oppside=@battle.sides[1]
      reflect=ownside.effects[PBEffects::Reflect]
      ownside.effects[PBEffects::Reflect]=oppside.effects[PBEffects::Reflect]
      oppside.effects[PBEffects::Reflect]=reflect
      lightscreen=ownside.effects[PBEffects::LightScreen]
      ownside.effects[PBEffects::LightScreen]=oppside.effects[PBEffects::LightScreen]
      oppside.effects[PBEffects::LightScreen]=lightscreen
      auroraveil=ownside.effects[PBEffects::AuroraVeil]
      ownside.effects[PBEffects::AuroraVeil]=oppside.effects[PBEffects::AuroraVeil]
      oppside.effects[PBEffects::AuroraVeil]=auroraveil
      firepledge=ownside.effects[PBEffects::SeaOfFire]
      ownside.effects[PBEffects::SeaOfFire]=oppside.effects[PBEffects::SeaOfFire]
      oppside.effects[PBEffects::SeaOfFire]=firepledge
      grasspledge=ownside.effects[PBEffects::Swamp]
      ownside.effects[PBEffects::Swamp]=oppside.effects[PBEffects::Swamp]
      oppside.effects[PBEffects::Swamp]=grasspledge
      waterpledge=ownside.effects[PBEffects::Rainbow]
      ownside.effects[PBEffects::Rainbow]=oppside.effects[PBEffects::Rainbow]
      oppside.effects[PBEffects::Rainbow]=waterpledge
      mist=ownside.effects[PBEffects::Mist]
      ownside.effects[PBEffects::Mist]=oppside.effects[PBEffects::Mist]
      oppside.effects[PBEffects::Mist]=mist
      spikes=ownside.effects[PBEffects::Spikes]
      ownside.effects[PBEffects::Spikes]=oppside.effects[PBEffects::Spikes]
      oppside.effects[PBEffects::Spikes]=spikes
      toxicspikes=ownside.effects[PBEffects::ToxicSpikes]
      ownside.effects[PBEffects::ToxicSpikes]=oppside.effects[PBEffects::ToxicSpikes]
      oppside.effects[PBEffects::ToxicSpikes]=toxicspikes
      stealthrock=ownside.effects[PBEffects::StealthRock]
      ownside.effects[PBEffects::StealthRock]=oppside.effects[PBEffects::StealthRock]
      oppside.effects[PBEffects::StealthRock]=stealthrock
      stickyweb=ownside.effects[PBEffects::StickyWeb]
      ownside.effects[PBEffects::StickyWeb]=oppside.effects[PBEffects::StickyWeb]
      oppside.effects[PBEffects::StickyWeb]=stickyweb
      tailwind=ownside.effects[PBEffects::Tailwind]
      ownside.effects[PBEffects::Tailwind]=oppside.effects[PBEffects::Tailwind]
      oppside.effects[PBEffects::Tailwind]=tailwind
      @battle.pbDisplay(_INTL("{1} swapped the battle effects affecting each side of the field!",user.pbThis))
      return 0
    end
  end
end

################################################################################
# Type depends on the user's form, also increases speed. Morpeko's Aura Wheel
################################################################################
class PokeBattle_Move_508 < PokeBattle_Move
  def pbBaseType(user)
    if isConst?(user.species,PBSpecies,:MORPEKO) && user.form==1 #Hangry Mode
      return user.type2 # Dark
    else
      return user.type1 # Electric
    end
  end
  def pbAdditionalEffect(user,target)
    if user.pbCanRaiseStatStage?(PBStats::SPEED,user,self)
      user.pbRaiseStatStage(PBStats::SPEED,1,user)
    end
  end
end

################################################################################
# Move does damage based on the user's defense stat. Body Press
################################################################################
class PokeBattle_Move_509 < PokeBattle_Move
  def pbGetAttackStats(user,target)
    return user.defense, user.stages[PBStats::DEFENSE]+6
  end
end

#===============================================================================
# Power is doubled when attacking before the target. Fishious Rend and Bolt Beak
#===============================================================================
class PokeBattle_Move_510 < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    if @battle.choices[target.index][0]!=:None &&
       ((@battle.choices[target.index][0]!=:UseMove &&
       @battle.choices[target.index][0]!=:Shift) || !target.movedThisRound?)
      baseDmg *= 2
    end
    return baseDmg
  end
end

################################################################################
# Sharply raises the target's ATK and SPATK. Decorate
################################################################################
class PokeBattle_Move_511 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    failed = true
    targets.each do |b|
      next if !b.pbCanRaiseStatStage?(PBStats::ATTACK,user,self) &&
              !b.pbCanConfuse?(user,false,self)
      failed = false
      break
    end
    if failed
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
    if target.pbCanRaiseStatStage?(PBStats::ATTACK,user,self)
      target.pbRaiseStatStage(PBStats::ATTACK,2,user)
    end
    if target.pbCanRaiseStatStage?(PBStats::SPATK,user,self)
      target.pbRaiseStatStage(PBStats::SPATK,2,user)
    end
  end
end

################################################################################
# Hits twice, and changes target to second enemy if they exist. Dragon Darts
################################################################################
class PokeBattle_Move_512 < PokeBattle_Move
  def multiHitMove?;           return true; end
  def pbNumHits(user,targets); return 2;    end
end


################################################################################
# Prevents both the user and the target from escaping. (Jaw Lock)
################################################################################
class PokeBattle_Move_513 < PokeBattle_Move
  def pbEffectAfterAllHits(user,target)
    if (target.effects[PBEffects::JawLockUser]<0 && !target.effects[PBEffects::JawLock] &&
        user.effects[PBEffects::JawLockUser]<0 && !user.effects[PBEffects::JawLock])
      target.effects[PBEffects::JawLockUser]=user.index
      user.effects[PBEffects::JawLockUser]=user.index
      target.effects[PBEffects::JawLock]=true
      user.effects[PBEffects::JawLock]=true
      @battle.pbDisplay(_INTL("{1} locked {1} in it's jaws! Neither Pokémon can run away.",user.pbThis,target.pbThis(true)))
    end
  end
end

#===============================================================================
# Target becomes Psychic type. (Magic Powder)
#===============================================================================
class PokeBattle_Move_514 < PokeBattle_Move
  def pbFailsAgainstTarget?(user,target)
    if !target.canChangeType? ||
       !target.pbHasOtherType?(getConst(PBTypes,:PSYCHIC))
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
    newType = getConst(PBTypes,:PSYCHIC)
    user.pbChangeTypes(newType)
    typeName = PBTypes.getName(newType)
    @battle.pbDisplay(_INTL("{1} transformed into the {2} type!",target.pbThis,typeName))
  end
end

################################################################################
# Increases each stat by 1 stage. Prevents user from fleeing. (No Retreat)
################################################################################
class PokeBattle_Move_515 < PokeBattle_Move
  def pbEffectGeneral(user)
    if user.effects[PBEffects::NoRetreatUser]<0 && !user.effects[PBEffects::NoRetreat]
      user.effects[PBEffects::NoRetreatUser]=user.index
      user.effects[PBEffects::NoRetreat]=true
      @battle.pbDisplay(_INTL("{1} will not retreat!",user.pbThis))
      if user.pbCanRaiseStatStage?(PBStats::ATTACK,user,self)
        user.pbRaiseStatStage(PBStats::ATTACK,1,user)
      end
    else
      @battle.pbDisplay(_INTL("But it failed!"))
    end
  end
end


################################################################################
# The attack cannot be redirected. Snipe Shot
################################################################################
class PokeBattle_Move_516 < PokeBattle_Move
  def cannotRedirect?; return true; end
end

#===============================================================================
# Target's last move used loses 3 PP. (Eerie Spell - Galarian Slowking)
#===============================================================================
class PokeBattle_Move_517 < PokeBattle_Move
  def pbFailsAgainstTarget?(user,target)
    failed = true
    target.eachMove do |m|
      next if m.id!=target.lastRegularMoveUsed || m.pp==0 || m.totalpp<=0
      failed = false; break
    end
    if failed
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
    target.eachMove do |m|
      next if m.id!=target.lastRegularMoveUsed
      reduction = [3,m.pp].min
      target.pbSetPP(m,m.pp-reduction)
      @battle.pbDisplay(_INTL("It reduced the PP of {1}'s {2} by {3}!",
         target.pbThis(true),m.name,reduction))
      break
    end
  end
end


#===============================================================================
# Does physical or special damage based on what would hurt more.
# Also has a chance to poison
# (Shell Side Arm - Galarian Slowbro)
#===============================================================================
class PokeBattle_Move_518 < PokeBattle_Move_005
  def initialize(battle,move)
    super
    @calcCategory = 1
  end

  def pbEffectAgainstTarget(user,target)
    if rand(5)<1 && target.pbCanPoison?(user,true,self)
      target.pbPoison(user)
    end
  end

  def physicalMove?(thisType=nil); return (@calcCategory==0); end
  def specialMove?(thisType=nil);  return (@calcCategory==1); end

  def pbOnStartUse(user,targets)
    stageMul = [2,2,2,2,2,2, 2, 3,4,5,6,7,8]
    stageDiv = [8,7,6,5,4,3, 2, 2,2,2,2,2,2]
    begin
      defense      = targets[0].defense
      defenseStage = targets[0].stages[PBStats::DEFENSE]+6
      realDefense  = (defense.to_f*stageMul[defenseStage]/stageDiv[defenseStage]).floor
      spdef        = targets[0].spdef
      spdefStage   = targets[0].stages[PBStats::SPDEF]+6
      realSpdef    = (spdef.to_f*stageMul[spdefStage]/stageDiv[spdefStage]).floor
    rescue
      realDefense=2
      realSpdef=3
    end
    # Determine move's category
    return @calcCategory = 0 if realDefense<realSpdef
    return @calcCategory = 1 if realDefense>=realSpdef
    if isConst?(@id,PBMoves,:WONDERROOM); end
  end
end

#===============================================================================
# Stuff cheeks - Eat a berry and raise defense 2 levels
#===============================================================================
class PokeBattle_Move_519 < PokeBattle_Move
  def pbEffectGeneral(user)
    if !user.item || !pbIsBerry?(user.item)
      @battle.pbDisplay("But it failed!")
      return -1
    end
    if user.pbCanRaiseStatStage?(PBStats::DEFENSE,user,self)
      user.pbRaiseStatStage(PBStats::DEFENSE,2,user)
    end
    user.pbHeldItemTriggerCheck(user.item,false)
    user.pbConsumeItem(true,true,false) if user.item>0
  end
end

#===============================================================================
# Forces all active Pokémon to consume their held berries. This move bypasses
# Substitutes. (Tea Time) Teatime
#===============================================================================
class PokeBattle_Move_520 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    @validTargets = []
    @battle.eachBattler do |b|
      next if !b.item == 0 || !pbIsBerry?(b.item)
      @validTargets.push(b.index)
    end
    if @validTargets.length==0
      @battle.pbDisplay(_INTL("But nothing happened!"))
      return true
    end
    @battle.pbDisplay(_INTL("It's tea time! Everyone dug in to their Berries!"))
    return false
  end

  def pbFailsAgainstTarget?(user,target)
    return false if @validTargets.include?(target.index)
    return true if target.semiInvulnerable?
  end

  def pbEffectAgainstTarget(user,target)
    target.pbHeldItemTriggerCheck(target.item,false)
    target.pbConsumeItem(true,true,false) if target.pokemon.hasItem?
  end
end
