################################################################################
# Type depends on the user's type. ARENAY SPLICE
# Cell shot, DNA Ray, Cell Slam, etc
################################################################################
class PokeBattle_Move_500 < PokeBattle_Move
  def pbBaseType(user)
    return user.type1
  end
=begin
This is the code to make the Move Base Power Dependent on Level
  def pbBaseDamage(basedmg,attacker,opponent)
    basedmg=attacker.level*2# if isConst?(attacker.species,PBSpecies,:ARENAY)
    basedmg=90 if basedmg>90 || attacker.level>45
#    @battle.pbDisplay(_INTL("{1}",basedmg))
    return basedmg
  end
=end
end

################################################################################
# Increase an ally's Special Defense by 1 stage.
################################################################################
class PokeBattle_Move_501 < PokeBattle_StatUpMove
  def initialize(battle,move)
    super
    @statUp = [PBStats::SPDEF,1]
  end
end

################################################################################
# Type depends on the user's type, and then explodes. ARENAY SPLICE
################################################################################
class PokeBattle_Move_502 < PokeBattle_Move_0E0
  def pbBaseType(user)
    return user.type1
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
    defense      = targets[0].defense
    defenseStage = targets[0].stages[PBStats::DEFENSE]+6
    realDefense  = (defense.to_f*stageMul[defenseStage]/stageDiv[defenseStage]).floor
    spdef        = targets[0].spdef
    spdefStage   = targets[0].stages[PBStats::SPDEF]+6
    realSpdef    = (spdef.to_f*stageMul[spdefStage]/stageDiv[spdefStage]).floor
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

#===============================================================================
# User loses 1/4 of max HP, Poison's itself and curses the target.
# Cursed Pokémon lose 1/4 of their max HP at the end of each round.
# (Pestilence)
#===============================================================================
class PokeBattle_Move_521 < PokeBattle_Move
  def ignoresSubstitute?(user); return true; end

  def pbFailsAgainstTarget?(user,target)
    if target.effects[PBEffects::Curse]
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
    @battle.pbDisplay(_INTL("{1} poisoned and hurt itself to lay a curse on {2}!",user.pbThis,target.pbThis(true)))
    target.effects[PBEffects::Curse] = true
    user.pbReduceHP(user.totalhp/4,false)
    user.pbPoison(user)
    user.pbItemHPHealCheck
  end
end

#===============================================================================
# Clears weather. (Clear Sky)
#===============================================================================
class PokeBattle_Move_522 < PokeBattle_WeatherMove
  def initialize(battle,move)
    super
    @weatherType = PBWeather::None
  end
end

#===============================================================================
# Type changes depending on the weather. (Weather Blast)
#===============================================================================
class PokeBattle_Move_523 < PokeBattle_Move
  def pbBaseType(user)
    ret = getID(PBTypes,:FLYING)
    case @battle.pbWeather
    when PBWeather::Sun, PBWeather::HarshSun
      ret = getConst(PBTypes,:FIRE) || ret
    when PBWeather::Rain, PBWeather::HeavyRain
      ret = getConst(PBTypes,:WATER) || ret
    when PBWeather::Sandstorm
      ret = getConst(PBTypes,:ROCK) || ret
    when PBWeather::Hail
      ret = getConst(PBTypes,:ICE) || ret
    end
    return ret
  end

  def pbShowAnimation(id,user,targets,hitNum=0,showAnimation=true)
    t = pbBaseType(user)
    hitNum = 1 if isConst?(t,PBTypes,:FIRE)   # Type-specific anims
    hitNum = 2 if isConst?(t,PBTypes,:WATER)
    hitNum = 3 if isConst?(t,PBTypes,:ROCK)
    hitNum = 4 if isConst?(t,PBTypes,:ICE)
    super
  end
end

#===============================================================================
# Power is doubled when there is no weather. (Clear Shot)
#===============================================================================
class PokeBattle_Move_524 < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 2 if @battle.pbWeather==PBWeather::None
    return baseDmg
  end
end

#===============================================================================
# Randomizies the weather
#===============================================================================
class PokeBattle_Move_525 < PokeBattle_Move

  def pbEffectGeneral(user)
    w = rand(5)
    @battle.pbDisplay(_INTL("{1} spun the roulette!",user.pbThis))
    @battle.pbStartWeather(user,w)
  end
end

#===============================================================================
# Decreases Accuracy of Every Pokemon on the Field that isn't fairy (Glitter Bomb)
#===============================================================================
class PokeBattle_Move_526 < PokeBattle_Move
  def ignoresSubstitute?(user); return true; end

  def pbFailsAgainstTarget?(user,target)
    return target == user
  end

  def pbAdditionalEffect(user,target)
    return false if target.pbHasType?(:FAIRY)
    return false if user == target
    return false if !target.pbCanLowerStatStage?(PBStats::ACCURACY)
    target.pbLowerStatStage(PBStats::ACCURACY,1,user)
  end
end

#===============================================================================
# Blocks attack and counter's back (Azumarill's Signature Move)
#===============================================================================
class PokeBattle_Move_527 < PokeBattle_ProtectMove
  def initialize(battle,move)
    super
    @effect = PBEffects::QuickParry
  end

  def pbProtectMessage(user)
    @battle.pbDisplay(_INTL("{1} is anticipating an attack!",user.pbThis))
  end
end

#===============================================================================
# Causes the target to flinch. Fails if this isn't the user's first turn.
# Chance to Paralyze (Manic Lunge)
#===============================================================================
class PokeBattle_Move_528 < PokeBattle_FlinchMove
  def pbMoveFailed?(user,targets)
    if user.turnCount>1 || user.lastRoundMoved>=0
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbAdditionalEffect(user,target)
    super
    if target.pbCanInflictStatus?(PBStatuses::PARALYSIS,user,false) && rand(5) < 1
      target.pbInflictStatus(PBStatuses::PARALYSIS,0,(_INTL("{1} was paralyzed by the blinding lunge!",target.pbThis)),user)
    end
  end
end

#===============================================================================
# Raises Def and SpDef sharply but lowers speed Sharply (Frost Armor)
#===============================================================================
class PokeBattle_Move_52A < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    if !user.pbCanLowerStatStage?(PBStats::DEFENSE,user,self) &&
           !user.pbCanRaiseStatStage?(PBStats::SPDEF,user,self) &&
           !user.pbCanRaiseStatStage?(PBStats::SPEED,user,self)
      @battle.pbDisplay(_INTL("{1}'s stats won't go any higher!",user.phThis))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    @battle.pbDisplay(_INTL("{1} enveloped itself in an icy armor!",user.pbThis))
    user.pbRaiseStatStage(PBStats::DEFENSE,2,user,false)
    user.pbRaiseStatStage(PBStats::SPDEF,2,user,false)
    @battle.pbCommonAnimation("StatUp",user)
    @battle.pbDisplay(_INTL("{1} Defense and Sp. Def sharply rose!",user.pbThis))
    user.pbLowerStatStage(PBStats::SPEED,2,user)
  end
end

#===============================================================================
# Doesn't affect non-graounded Pokemon (Glacial Quake)
#===============================================================================
class PokeBattle_Move_52B < PokeBattle_Move
  def pbFailsAgainstTarget?(user,target)
    if target.airborne?
      @battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
      return true
    end
    return false
  end

  def pbMoveFailed?(user,targets)
    failed = true
    targets.each do |b|
      next if b.airborne?   # Pokemon is airborne
      failed = false
      break
    end
    if failed
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end
end

#===============================================================================
# Power is doubled if the target is frozen. Thaws the target up. (Wake-Up Slap)
#===============================================================================
class PokeBattle_Move_52C < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    if target.frozen? &&
       (target.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(user))
      baseDmg *= 2
    end
    return baseDmg
  end

  def pbEffectAfterAllHits(user,target)
    return if target.fainted?
    return if target.damageState.unaffected || target.damageState.substitute
    return if target.status!=PBStatuses::FROZEN
    target.pbInflictStatus(PBStatuses::NONE,0,(_INTL("The ice around {1} was shattered!",target.pbThis(true))))
  end
end

#===============================================================================
# Two turn attack. Attacks first turn, skips second turn (if successful).
# Changes type based on user type
#===============================================================================
class PokeBattle_Move_52D < PokeBattle_Move_0C2
  def pbBaseType(user)
    return user.type1
  end
end

#===============================================================================
# 1.5x damage if the target is infatuated (Obsession Dance)
#===============================================================================
class PokeBattle_Move_52E < PokeBattle_Move_0C2
  def pbBaseDamage(baseDmg,user,target)
    if target.effects[PBEffects::Attract]>=0 &&
       (target.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(user))
      baseDmg *= 2.0
    end
    return baseDmg
  end
end

#===============================================================================
# Heals 25% HP and 1.5x damage for the next move used, if the move gets STAB.
# Can't be used in succession (Reconfigure)
#===============================================================================
class PokeBattle_Move_52F < PokeBattle_Move
  def pbBaseType(user)
    return user.type1
  end

  def pbMoveFailed?(user,targets)
    if user.effects[PBEffects::Reconfigure] == 2
      @battle.pbDisplay(_INTL("{1}'s cells are already in their optimal configuration!",user.pbThis))
      user.effects[PBEffects::Reconfigure] = 0
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    @battle.pbDisplay(_INTL("{1} reconfigured its cellular make-up!",user.pbThis))
    user.effects[PBEffects::Reconfigure] = 2
    @battle.pbDisplay(_INTL("{1} restored some health!",user.pbThis)) if user.pbRecoverHP((user.totalhp/3.0).round) > 0
  end
end

################################################################################
# Type depends on the user's type. Mega Drain
# Cell Drain
################################################################################
class PokeBattle_Move_530 < PokeBattle_Move
  def healingMove?; return NEWEST_BATTLE_MECHANICS; end

  def pbBaseType(user)
    return user.type1
  end

  def pbEffectAgainstTarget(user,target)
    return if target.damageState.hpLost<=0
    hpGain = (target.damageState.hpLost/2.0).round
    user.pbRecoverHPFromDrain(hpGain,target)
  end
end
