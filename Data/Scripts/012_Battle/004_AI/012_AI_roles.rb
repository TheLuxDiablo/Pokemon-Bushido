# TODO: Reborn has the REVENGEKILLER role which compares mon's speed with
#       opponent (only when deciding whether to switch mon in) - this comparison
#       should be calculated when needed instead of being a role.
module BattleRole
  PHAZER         = 0
  CLERIC         = 1
  STALLBREAKER   = 2
  STATUSABSORBER = 3
  BATONPASSER    = 4
  SPINNER        = 5
  FIELDSETTER    = 6
  WEATHERSETTER  = 7
  SWEEPER        = 8
  PIVOT          = 9
  PHYSICALWALL   = 10
  SPECIALWALL    = 11
  TANK           = 12
  TRAPPER        = 13
  SCREENER       = 14
  ACE            = 15
  LEAD           = 16
  SECOND         = 17
end



class PokeBattle_AI
  #=============================================================================
  # Determine the roles filled by a Pokémon on a given side at a given party
  # index.
  #=============================================================================
  def determine_roles(side, index)
    pkmn = @battle.pbParty(side)[index]
    ret = []
    return ret if !pkmn || pkmn.egg?

    # Check for moves indicative of particular roles
    hasHealMove  = false
    hasPivotMove = false
    pkmn.moves.each do |m|
      next if !m || m.id == 0
      move = PokeBattle_Move.pbFromPBMove(@battle, m, pkmn)
      hasHealMove = true if !hasHealMove && move.healingMove?
      case move.function
      when "004", "0E5", "0EB", "0EC"   # Yawn, Perish Song, Roar, Circle Throw
        ret.push(BattleRole::PHAZER)
      when "019"   # Aromatherapy/Heal Bell
        ret.push(BattleRole::CLERIC)
      when "0BA"   # Taunt
        ret.push(BattleRole::STALLBREAKER)
      when "0D7"   # Wish
        ret.push(BattleRole::CLERIC) if pkmn.ev[PBStats::HP] == PokeBattle_Pokemon::EV_STAT_LIMIT
      when "0D9"   # Rest
        ret.push(BattleRole::STATUSABSORBER)
      when "0ED"   # Baton Pass
        ret.push(BattleRole::BATONPASSER)
      when "0EE"   # U-turn
        hasPivotMove = true
      when "110"   # Rapid Spin
        ret.push(BattleRole::SPINNER)
      when "154", "155", "156", "173"   # Terrain moves
        ret.push(BattleRole::FIELDSETTER)
      else
        ret.push(BattleRole::WEATHERSETTER) if move.is_a?(PokeBattle_WeatherMove)
      end
    end

    # Check EVs, nature and moves for combinations indicative of particular roles
    if pkmn.ev[PBStats::SPEED] == PokeBattle_Pokemon::EV_STAT_LIMIT
      if [PBNatures::MODEST, PBNatures::ADAMANT,   # SpAtk+ Atk-, Atk+ SpAtk-
          PBNatures::TIMID, PBNatures::JOLLY].include?(pkmn.nature)   # Spd+ Atk-, Spd+ SpAtk-
        ret.push(BattleRole::SWEEPER)
      end
    end
    if hasHealMove
      ret.push(BattleRole::PIVOT) if hasPivotMove
      if PBNatures.getStatRaised(pkmn.nature) == PBStats::DEFENSE &&
         PBNatures.getStatLowered(pkmn.nature) != PBStats::DEFENSE
        ret.push(BattleRole::PHYSICALWALL) if pkmn.ev[PBStats::DEFENSE] == PokeBattle_Pokemon::EV_STAT_LIMIT
      elsif PBNatures.getStatRaised(pkmn.nature) == PBStats::SPDEF &&
            PBNatures.getStatLowered(pkmn.nature) != PBStats::SPDEF
        ret.push(BattleRole::SPECIALWALL) if pkmn.ev[PBStats::SPDEF] == PokeBattle_Pokemon::EV_STAT_LIMIT
      end
    else
      ret.push(BattleRole::TANK) if pkmn.ev[PBStats::HP] == PokeBattle_Pokemon::EV_STAT_LIMIT
    end

    # Check for abilities indicative of particular roles
    if pkmn.hasAbility?(:REGENERATOR)
      ret.push(BattleRole::PIVOT)
    elsif pkmn.hasAbility?(:GUTS) || pkmn.hasAbility?(:QUICKFEET) ||
          pkmn.hasAbility?(:FLAREBOOST) || pkmn.hasAbility?(:TOXICBOOST) ||
          pkmn.hasAbility?(:NATURALCURE) || pkmn.hasAbility?(:MAGICGUARD) ||
          pkmn.hasAbility?(:MAGICBOUNCE) || pkmn.hasAbility?(:HYDRATION)
      ret.push(BattleRole::STATUSABSORBER)
    elsif pkmn.hasAbility?(:SHADOWTAG) || pkmn.hasAbility?(:ARENATRAP) ||
          pkmn.hasAbility?(:MAGNETPULL)
      ret.push(BattleRole::TRAPPER)
    elsif pkmn.hasAbility?(:DROUGHT) || pkmn.hasAbility?(:DRIZZLE) ||
          pkmn.hasAbility?(:SANDSTREAM) || pkmn.hasAbility?(:SNOWWARNING) ||
          pkmn.hasAbility?(:PRIMORDIALSEA) || pkmn.hasAbility?(:DESOLATELAND) ||
          pkmn.hasAbility?(:DELTASTREAM)
      ret.push(BattleRole::WEATHERSETTER)
    elsif pkmn.hasAbility?(:GRASSYSURGE) || pkmn.hasAbility?(:ELECTRICSURGE) ||
          pkmn.hasAbility?(:MISTYSURGE) || pkmn.hasAbility?(:PSYCHICSURGE)
      ret.push(BattleRole::FIELDSETTER)
    end

    # Check for items indicative of particular roles
    if pkmn.hasItem?(:LIGHTCLAY)
      ret.push(BattleRole::SCREENER)
    elsif pkmn.hasItem?(:ASSAULTVEST)
      ret.push(BattleRole::TANK)
    elsif pkmn.hasItem?(:CHOICEBAND) ||  pkmn.hasItem?(:CHOICESPECS)
      ret.push(BattleRole::STALLBREAKER)
      ret.push(BattleRole::SWEEPER) if pkmn.ev[PBStats::SPEED] == PokeBattle_Pokemon::EV_STAT_LIMIT
    elsif pkmn.hasItem?(:CHOICESCARF)
      ret.push(BattleRole::SWEEPER) if pkmn.ev[PBStats::SPEED] == PokeBattle_Pokemon::EV_STAT_LIMIT
    elsif pkmn.hasItem?(:TOXICORB) ||  pkmn.hasItem?(:FLAMEORB)
      ret.push(BattleRole::STATUSABSORBER)
    elsif pkmn.hasItem?(:TERRAINEXTENDER)
      ret.push(BattleRole::FIELDSETTER)
    end

    # Check for position in team, level relative to other levels in team
    partyStarts = @battle.pbPartyStarts(side)
    if partyStarts.include?(index + 1) || index == partyStarts.length - 1
      ret.push(BattleRole::ACE)
    else
      ret.push(BattleRole::LEAD) if partyStarts.include?(index)
      idxTrainer = pbGetOwnerIndexFromPartyIndex(side, index)
      maxLevel = @battle.pbMaxLevelInTeam(side, idxTrainer)
      if pkmn.level >= maxLevel
        ret.push(BattleRole::SECOND)
      else
        secondHighest = true
        seenHigherLevel = false
        @battle.eachInTeam(side, pbGetOwnerIndexFromPartyIndex(side, index)).each do |p|
          next if p.level < pkmn.level
          if seenHigherLevel
            secondHighest = false
            break
          end
          seenHigherLevel = true
        end
        # NOTE: There can be multiple "second"s if all their levels are equal
        #       and the highest in the team (and none are the ace).
        ret.push(BattleRole::SECOND) if secondHighest
      end
    end

    return ret
  end
end
