#===============================================================================
# User is protected against damaging moves this round. Decreases the Defense of
# the user of a stopped contact move by 2 stages. (Obstruct)
#===============================================================================
class PokeBattle_Move_180 < PokeBattle_ProtectMove
  def initialize(battle,move)
    super
    @effect = PBEffects::Obstruct
  end
end



#===============================================================================
# Lowers target's Defense and Special Defense by 1 stage at the end of each
# turn. Prevents target from retreating. (Octolock)
#===============================================================================
class PokeBattle_Move_181 < PokeBattle_Move
  def pbFailsAgainstTarget?(user,target)
    if target.effects[PBEffects::OctolockUser]>=0 || (target.damageState.substitute && !ignoresSubstitute?(user))
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    if NEWEST_BATTLE_MECHANICS && target.pbHasType?(:GHOST)
      @battle.pbDisplay(_INTL("It doesn't affect {1}...",target.pbThis(true)))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
    target.effects[PBEffects::OctolockUser] = user.index
    target.effects[PBEffects::Octolock] = true
    @battle.pbDisplay(_INTL("{1} can no longer escape!",target.pbThis))
  end
end



#===============================================================================
# Ignores move redirection from abilities and moves. (Snipe Shot)
#===============================================================================
class PokeBattle_Move_182 < PokeBattle_Move
end



#===============================================================================
# Consumes berry and raises the user's Defense by 2 stages. (Stuff Cheeks)
#===============================================================================
class PokeBattle_Move_183 < PokeBattle_Move
  def pbEffectGeneral(user)
    if !user.item || user.item==0 || !pbIsBerry?(user.item)
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
# Substitutes. (Tea Time)
#===============================================================================
class PokeBattle_Move_184 < PokeBattle_Move
  def ignoresSubstitute?(user); return true; end

  def pbMoveFailed?(user,targets)
    @validTargets = []
    @battle.eachBattler do |b|
      next if !b.item == 0 || !pbIsBerry?(b.item)
      @validTargets.push(b.index)
    end
    if @validTargets.length==0
      @battle.pbDisplay(_INTL("But it failed!"))
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
    target.pbConsumeItem(true,true,false) if pbIsBerry?(target.item)
  end
end



#===============================================================================
# Decreases Opponent's Defense by 1 stage. Does Double Damage under gravity
# (Grav Apple)
#===============================================================================
class PokeBattle_Move_185 < PokeBattle_TargetStatDownMove
  def initialize(battle,move)
    super
    @statDown = [PBStats::DEFENSE,1]
  end

  def pbBaseDamage(baseDmg,user,target)
    baseDmg=baseDmg*1.5 if @battle.field.effects[PBEffects::Gravity]>0
    return baseDmg
  end
end



#===============================================================================
# Decrease 1 stage of speed and weakens target to fire moves. (Tar Shot)
#===============================================================================
class PokeBattle_Move_186 < PokeBattle_Move
  def pbEffectAgainstTarget(user,target)
    if !target.pbCanLowerStatStage?(PBStats::SPEED,target,self) && !target.effects[PBEffects::TarShot]
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    if target.pbCanLowerStatStage?(PBStats::SPEED,target,self)
      target.pbLowerStatStage(PBStats::SPEED,1,target)
    end
    if target.effects[PBEffects::TarShot]==false
      target.effects[PBEffects::TarShot]=true
      @battle.pbDisplay(_INTL("{1} became weaker to fire!",target.pbThis))
    end
  end
end



#===============================================================================
# Changes Category based on Opponent's Def and SpDef. Has 20% Chance to Poison
# (Shell Side Arm)
#===============================================================================
class PokeBattle_Move_187 < PokeBattle_PoisonMove
  def initialize(battle,move)
    super
    @calcCategory = 1
  end

  def physicalMove?(thisType=nil); return (@calcCategory==0); end
  def specialMove?(thisType=nil);  return (@calcCategory==1); end

  def pbOnStartUse(user,targets)
    return false if !targets || !targets[0]
    stageMul = [2,2,2,2,2,2, 2, 3,4,5,6,7,8]
    stageDiv = [8,7,6,5,4,3, 2, 2,2,2,2,2,2]
    defense      = targets[0].defense || 0
    defenseStage = targets[0].stages[PBStats::DEFENSE] + 6
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
# Hits 3 times and always critical. (Surging Strikes)
#===============================================================================
class PokeBattle_Move_188 < PokeBattle_Move_0A0
  def multiHitMove?;           return true; end
  def pbNumHits(user,targets); return 3;    end
end

#===============================================================================
# Restore HP and heals any status conditions of itself and its allies
# (Jungle Healing)
#===============================================================================
class PokeBattle_Move_189 < PokeBattle_Move
  def healingMove?; return true; end

  def pbMoveFailed?(user,targets)
    jglheal = 0
    for i in 0...targets.length
      jglheal += 1 if (targets[i].hp == targets[i].totalhp || !targets[i].canHeal?) && targets[i].status ==PBStatuses::NONE
    end
    if jglheal == targets.length
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectAgainstTarget(user,target)
      target.pbCureStatus
    if target.hp != target.totalhp && target.canHeal?
      hpGain = (target.totalhp/4.0).round
      target.pbRecoverHP(hpGain)
      @battle.pbDisplay(_INTL("{1}'s health was restored.",target.pbThis))
    end
    super
  end
end



#===============================================================================
# Changes type and base power based on Battle Terrain (Terrain Pulse)
#===============================================================================
class PokeBattle_Move_18A < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 2 if @battle.field.terrain != PBBattleTerrains::None && !user.airborne?
    return baseDmg
  end

  def pbBaseType(user)
    ret = getID(PBTypes,:NORMAL)
    if !user.airborne?
      case @battle.field.terrain
      when PBBattleTerrains::Electric
        ret = getConst(PBTypes,:ELECTRIC) || ret
      when PBBattleTerrains::Grassy
        ret = getConst(PBTypes,:GRASS) || ret
      when PBBattleTerrains::Misty
        ret = getConst(PBTypes,:FAIRY) || ret
      when PBBattleTerrains::Psychic
        ret = getConst(PBTypes,:PSYCHIC) || ret
      end
    end
    return ret
  end

  def pbShowAnimation(id,user,targets,hitNum=0,showAnimation=true)
    t = pbBaseType(user)
    hitNum = 1 if isConst?(t,PBTypes,:ELECTRIC)
    hitNum = 2 if isConst?(t,PBTypes,:GRASS)
    hitNum = 3 if isConst?(t,PBTypes,:FAIRY)
    hitNum = 4 if isConst?(t,PBTypes,:PSYCHIC)
    super
  end
end



#===============================================================================
# Burns opposing Pokemon that have increased their stats in that turn before the
# execution of this move (Burning Jealousy)
#===============================================================================
class PokeBattle_Move_18B < PokeBattle_Move
  def pbAdditionalEffect(user,target)
    return if target.damageState.substitute
    if target.pbCanBurn?(user,false,self) &&
       target.effects[PBEffects::BurningJealousy]
      target.pbBurn(user)
    end
  end
end



#===============================================================================
# Move has increased Priority in Grassy Terrain (Grassy Glide)
#===============================================================================
class PokeBattle_Move_18C < PokeBattle_Move
end



#===============================================================================
# Power Doubles onn Electric Terrain (Rising Voltage)
#===============================================================================
class PokeBattle_Move_18D < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 2 if @battle.field.terrain==PBBattleTerrains::Electric &&
                    !target.airborne?
    return baseDmg
  end
end



#===============================================================================
# Boosts Targets' Attack and Defense (Coaching)
#===============================================================================
class PokeBattle_Move_18E < PokeBattle_TargetMultiStatUpMove
  def initialize(battle,move)
    super
    @statUp = [PBStats::ATTACK,1,PBStats::DEFENSE,1]
  end
end



#===============================================================================
# Renders item unusable (Corrosive Gas)
#===============================================================================
class PokeBattle_Move_18F < PokeBattle_Move
  def pbEffectAgainstTarget(user,target)
    return if @battle.wildBattle? && user.opposes?   # Wild Pokémon can't knock off
    return if user.fainted?
    return if target.damageState.substitute
    return if target.item==0 || target.unlosableItem?(target.item)
    return if target.hasActiveAbility?(:STICKYHOLD) && !@battle.moldBreaker
    itemName = target.itemName
    target.pbRemoveItem(false)
    @battle.pbDisplay(_INTL("{1} dropped its {2}!",target.pbThis,itemName))
  end
end



#===============================================================================
# Power is boosted on Psychic Terrain (Expanding Force)
#===============================================================================
class PokeBattle_Move_190 < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 1.5 if @battle.field.terrain==PBBattleTerrains::Psychic
    return baseDmg
  end
end



#===============================================================================
# Boosts Sp Atk on 1st Turn and Attacks on 2nd (Meteor Beam)
#===============================================================================
class PokeBattle_Move_191 < PokeBattle_TwoTurnMove
  def pbChargingTurnMessage(user,targets)
    @battle.pbDisplay(_INTL("{1} is overflowing with space power!",user.pbThis))
  end

  def pbChargingTurnEffect(user,target)
    if user.pbCanRaiseStatStage?(PBStats::SPATK,user,self)
      user.pbRaiseStatStage(PBStats::SPATK,1,user)
    end
  end
end



#===============================================================================
# Fails if the Target has no Item (Poltergeist)
#===============================================================================
class PokeBattle_Move_192 < PokeBattle_Move
  def pbFailsAgainstTarget?(user,target)
    if target.item!=0
      @battle.pbDisplay(_INTL("{1} is about to be attacked by its {2}!",target.pbThis,target.itemName))
      return false
    end
    @battle.pbDisplay(_INTL("But it failed!"))
    return true
  end
end



#===============================================================================
# Reduces Defense and Raises Speed after all hits (Scale Shot)
#===============================================================================
class PokeBattle_Move_193 < PokeBattle_Move_0C0
  def pbEffectAfterAllHits(user,target)
    if user.pbCanRaiseStatStage?(PBStats::SPEED,user,self)
      user.pbRaiseStatStage(PBStats::SPEED,1,user)
    end
    if user.pbCanLowerStatStage?(PBStats::DEFENSE,target)
      user.pbLowerStatStage(PBStats::DEFENSE,1,user)
    end
  end
end



#===============================================================================
# Double damage if stats were lowered that turn. (Lash Out)
#===============================================================================
class PokeBattle_Move_194 < PokeBattle_Move
  def pbBaseDamage(baseDmg,user,target)
    baseDmg *= 2 if user.effects[PBEffects::LashOut]
    return baseDmg
  end
end



#===============================================================================
# Removes all Terrain. Fails if there is no Terrain (Steel Roller)
#===============================================================================
class PokeBattle_Move_195 < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    if @battle.field.terrain == PBBattleTerrains::None
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    case @battle.field.terrain
      when PBBattleTerrains::Electric
        @battle.pbDisplay(_INTL("The electric current disappeared from the battlefield!"))
      when PBBattleTerrains::Grassy
        @battle.pbDisplay(_INTL("The grass disappeared from the battlefield!"))
      when PBBattleTerrains::Misty
        @battle.pbDisplay(_INTL("The mist disappeared from the battlefield!"))
      when PBBattleTerrains::Psychic
        @battle.pbDisplay(_INTL("The weirdness disappeared from the battlefield!"))
    end
    @battle.pbStartTerrain(user,PBBattleTerrains::None,true)
  end
end



#===============================================================================
# Self KO. Boosted Damage when on Misty Terrain (Misty Explosion)
#===============================================================================
class PokeBattle_Move_196 < PokeBattle_Move_0E0
  def pbBaseDamage(baseDmg,user,target)
    if @battle.field.terrain==PBBattleTerrains::Misty && !user.airborne?
      baseDmg = (baseDmg*1.5).round
    end
    return baseDmg
  end
end



#===============================================================================
# Target becomes Psychic type. (Magic Powder)
#===============================================================================
class PokeBattle_Move_197 < PokeBattle_Move
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
    target.pbChangeTypes(newType)
    typeName = PBTypes.getName(newType)
    @battle.pbDisplay(_INTL("{1} transformed into the {2} type!",target.pbThis,typeName))
  end
end

#===============================================================================
# Target's last move used loses 3 PP. (Eerie Spell - Galarian Slowking)
#===============================================================================
class PokeBattle_Move_198 < PokeBattle_Move
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
# Deals double damage to Dynamax POkémons. Dynamax is not implemented though.
# (Behemoth Blade, Behemoth Bash, Dynamax Cannon)
#===============================================================================
class PokeBattle_Move_199 < PokeBattle_Move
  # DYNAMAX IS NOT IMPLEMENTED.
end



# NOTE: If you're inventing new move effects, use function code 199 and onwards.
#       Actually, you might as well use high numbers like 500+ (up to FFFF),
#       just to make sure later additions to Essentials don't clash with your
#       new effects.

#===============================================================================
# Target gets a random status: Poisoned, Burned, or put to Sleep.
# (Dire Claw)
#===============================================================================
class PokeBattle_Move_500 < PokeBattle_Move
  def pbAdditionalEffect(user,target)
    return if target.damageState.substitute
    case @battle.pbRandom(3)
    when 0 then target.pbSleep          if target.pbCanSleep?(user, false, self)
    when 1 then target.pbPoison(user)   if target.pbCanPoison?(user, false, self)
    when 2 then target.pbParalyze(user) if target.pbCanParalyze?(user, false, self)
    end
  end
end

#===============================================================================
# User takes recoil damage equal to 1/2 of their maximum health.
# (Steel Beam, Chloroblast)
#===============================================================================
class PokeBattle_Move_501 < PokeBattle_RecoilMove
  def pbRecoilDamage(user,target)
    return (user.totalhp/2.0).round
  end
end

#===============================================================================
# Gigaton Hammer, Blood Moon
#===============================================================================
# This move becomes unselectable if you try to use it on consecutive turns.
#-------------------------------------------------------------------------------
class PokeBattle_Move_502 < PokeBattle_Move
  def pbEffectWhenDealingDamage(user, target)
    user.effects[PBEffects::SuccessiveMove] = @id
  end
end

#===============================================================================
# Last Respects
#===============================================================================
# Power is increased by 50 for each time a teammate fainted this battle.
#-------------------------------------------------------------------------------
class PokeBattle_Move_503 < PokeBattle_Move
  def pbBaseDamage(baseDmg, user, target)
    numFainted = user.num_fainted_allies
    
    return baseDmg if numFainted <= 0
    baseDmg += 50 * numFainted
    return baseDmg
  end
end

#===============================================================================
# Power is doubled if the target is poisoned. Chance to poison. (Barb Barrage)
#===============================================================================
class PokeBattle_Move_504 < PokeBattle_PoisonMove
  def pbBaseDamage(baseDmg,user,target)
    if target.poisoned? &&
       (target.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(user))
      baseDmg *= 2
    end
    return baseDmg
  end
end

#===============================================================================
# Leaves Stealth Rocks behind after the attack (Stone Axe)
#===============================================================================
class PokeBattle_Move_505 < PokeBattle_Move
  def pbEffectGeneral(user)
    user.pbOpposingSide.effects[PBEffects::StealthRock] = true
    @battle.pbDisplay(_INTL("Pointed stones float in the air around {1}!",
       user.pbOpposingTeam(true)))
  end
end

#===============================================================================
# Power is doubled if the target has a status problem. Chance to Burn. (Infernal Parade)
#===============================================================================
class PokeBattle_Move_506 < PokeBattle_BurnMove
  def pbBaseDamage(baseDmg,user,target)
    if target.pbHasAnyStatus? &&
       (target.effects[PBEffects::Substitute]==0 || ignoresSubstitute?(user))
      baseDmg *= 2
    end
    return baseDmg
  end
end

#===============================================================================
# Triple Arrows
#===============================================================================
# Lowers the target's Defense by 1 stage. May cause flinching.
#-------------------------------------------------------------------------------
class PokeBattle_Move_507 < PokeBattle_Move
  def pbAdditionalEffect(user, target)
    return if target.damageState.substitute
    chance = pbAdditionalEffectChance(user, target, 50)
    if @battle.pbRandom(100) < chance
      # CHANGED: :DEFENSE replaced with PBStats::DEFENSE
      if target.pbCanLowerStatStage?(PBStats::DEFENSE, user, self) && 
         target.pbLowerStatStage(PBStats::DEFENSE, 1, user)
      end
    end
    chance = pbAdditionalEffectChance(user, target, 30)
    return if chance == 0
    target.pbFlinch(user) if @battle.pbRandom(100) < chance
  end
end

#===============================================================================
# Increases the user's Attack, Defense and Speed by 1 stage each.
# (Victory Dance)
#===============================================================================
class PokeBattle_Move_508 < PokeBattle_MultiStatUpMove
  def initialize(battle,move)
    super
    @statUp = [PBStats::ATTACK,1,PBStats::DEFENSE,1,PBStats::SPEED,1]
  end
end

#===============================================================================
# Axe Kick
#===============================================================================
# If attack misses, user takes crash damage of 1/2 of max HP. May cause confusion.
#-------------------------------------------------------------------------------
class PokeBattle_Move_509 < PokeBattle_ConfuseMove
  def recoilMove?; return true; end
  
  def pbCrashDamage(user)
    return if !user.takesIndirectDamage?
    @battle.pbDisplay(_INTL("{1} kept going and crashed!", user.pbThis))
    @battle.scene.pbDamageAnimation(user)
    user.pbReduceHP((user.totalhp / 2), false)
    user.pbItemHPHealCheck
    user.pbFaint if user.fainted?
  end
end