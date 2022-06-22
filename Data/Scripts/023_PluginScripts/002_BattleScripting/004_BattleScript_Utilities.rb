class PokeBattle_Battler

  # Special stat raising method for Katana Techniques (covers the weak katana toggle)
  def pbRaiseStatStageEx(stats, incs, anim = true, user = nil, forced: false)
    user = self if user.nil?
    return false if !forced && !opposes?(user) && !strong_katanas?
    yield if block_given?
    stats    = [stats] if !stats.is_a?(Array)
    incs     = [incs] if !incs.is_a?(Array)
    failed   = true
    shown    = false
    stats.each_with_index do |stat, i|
      increment = incs[i] || incs[0]
      stat      = getID(PBStats, stat) if stat.is_a?(Symbol)
      showAnim  = false
      next if !pbCanRaiseStatStage?(stat, user)
      if !shown
        case anim
        when Symbol
          @battle.pbAnimation(getID(PBMoves, anim), user, self)
          showAnim = true
          shown    = true
        when String
          @battle.pbCommonAnimation(anim, user, self)
          showAnim = true
          shown    = true
        when TrueClass
          showAnim = true
          shown    = true
        end
      end
      pbRaiseStatStage(stat, increment, user, showAnim, true)
      failed = false
    end
    return !failed
  end

  # Special stat lowering method for Katana Techniques (covers the weak katana toggle)
  def pbLowerStatStageEx(stats, incs, anim = true, user = nil, forced: false)
    user = self if user.nil?
    return false if !forced && opposes?(user) && !strong_katanas?
    yield if block_given?
    stats    = [stats] if !stats.is_a?(Array)
    incs     = [incs] if !incs.is_a?(Array)
    failed   = true
    shown    = false
    stats.each_with_index do |stat, i|
      increment = incs[i] || incs[0]
      stat      = getID(PBStats, stat) if stat.is_a?(Symbol)
      showAnim  = false
      next if !pbCanLowerStatStage?(stat, user)
      if !shown
        case anim
        when Symbol
          @battle.pbAnimation(getID(PBMoves, anim), user, self)
          showAnim = true
          shown    = true
        when String
          @battle.pbCommonAnimation(anim, user, self)
          showAnim = true
          shown    = true
        when TrueClass
          showAnim = true
          shown    = true
        end
      end
      pbLowerStatStage(stat, increment, user, showAnim, true, true)
      failed = false
    end
    return !failed
  end

  # Special status inflicting method for Katana Techniques (covers the weak katana toggle)
  def pbInflictStatusEx(newStatus, newStatusCount = 0, anim = nil, user = nil, ignoreStatus = false, msg = nil, move = nil, forced: false)
    user = self if user.nil?
    return false if !forced && opposes?(user) && !strong_katanas?
    yield if block_given?
    case anim
    when Symbol
      @battle.pbAnimation(getID(PBMoves, anim), user, self) if !fainted? && !user.fainted?
    when String
      @battle.pbCommonAnimation(anim, user, self) if !fainted? && !user.fainted?
    end
    newStatus = getID(PBStatuses, stat) if stat.is_a?(Symbol)
    return false if !pbCanInflictStatus?(newStatus, user, true, move, ignoreStatus)
    return pbInflictStatus(newStatus, newStatusCount, msg, user)
  end

  # Special entry hazard setting method for Katana Techniques (covers the weak katana toggle)
  def pbSetHazards(move, user, harsh = strong_katanas?, forced: false)
    return false if !forced && opposes?(user) && !strong_katanas
    yield if block_given?
    @battle.pbAnimation(getID(PBMoves, anim), user, self) if !fainted? && !user.fainted?
    case move
    when :STEALTHROCK
      @battle.pbDisplay(_INTL("Pointed stones float in the air around {1}!", pbTeam(true)))
      pbOwnSide.effects[PBEffects::StealthRock] = true
    when :SPIKES
      @battle.pbDisplay(_INTL("Spikes were scattered all around {1}'s feet!", pbTeam(true)))
      pbOwnSide.effects[PBEffects::Spikes] = (harsh ? 3 : 1)
    when :TOXICSPIKES
      @battle.pbDisplay(_INTL("Poison spikes were scattered all around {1}'s feet!", pbTeam(true)))
      pbOwnSide.effects[PBEffects::ToxicSpikes] = (harsh ? 2 : 1)
    when :STICKYWEB
      @battle.pbDisplay(_INTL("A sticky web has been laid out beneath {1}'s feet!", pbTeam(true)))
      pbOwnSide.effects[PBEffects::StickyWeb] = true
      pbOwnSide.effects[PBEffects::StickyWebUser] = user.index
    end
  end

  # Special trapping move method for Katana Techniques (covers the weak katana toggle)
  def pbTrapWithMove(move, user, harsh = false, forced: false)
    return false if !forced && opposes?(user) && !strong_katanas?
    yield if block_given?
    @battle.pbAnimation(getID(PBMoves, move), user, self) if !fainted? && !user.fainted?
    if fainted? || self.damageState.substitute || @effects[PBEffects::Trapping] > 0 || @effects[PBEffects::MeanLook] > -1
      @battle.pbDisplay(_INTL("{1} couldn't be trapped!", pbThis))
      return false
    end
    # Add Jaw Lock
    # Add Octolock
    if isConst?(move, PBMoves,:MEANLOOK)
      @effects[PBEffects::MeanLook] = user.index
    else
      if user.hasActiveItem?(:GRIPCLAW) || harsh
        @effects[PBEffects::Trapping] = (NEWEST_BATTLE_MECHANICS) ? 8 : 6
      else
        @effects[PBEffects::Trapping] = 5 + rand(2)
      end
      @effects[PBEffects::TrappingMove] = getID(PBMoves, move)
      @effects[PBEffects::TrappingUser] = user.index
    end
    # Message
    if isConst?(move, PBMoves, :BIND)
      msg = _INTL("{1} was squeezed by {2}!", pbThis, user.pbThis(true))
    elsif isConst?(move, PBMoves, :CLAMP)
      msg = _INTL("{1} clamped {2}!", user.pbThis, pbThis(true))
    elsif isConst?(move, PBMoves, :FIRESPIN)
      msg = _INTL("{1} was trapped in the fiery vortex!", pbThis)
    elsif isConst?(move, PBMoves, :INFESTATION)
      msg = _INTL("{1} has been afflicted with an infestation by {2}!", pbThis, user.pbThis(true))
    elsif isConst?(move, PBMoves, :MAGMASTORM)
      msg = _INTL("{1} became trapped by Magma Storm!", pbThis)
    elsif isConst?(move, PBMoves, :SANDTOMB)
      msg = _INTL("{1} became trapped by Sand Tomb!", pbThis)
    elsif isConst?(move, PBMoves, :WHIRLPOOL)
      msg = _INTL("{1} became trapped in the vortex!", pbThis)
    elsif isConst?(move, PBMoves, :SNAPTRAP)
      msg = _INTL("{1} was caught in the Snap Trap!", pbThis)
    elsif isConst?(move, PBMoves, :THUNDERCAGE)
      msg = _INTL("{1} trapped {2} in a Thunder Cage!", user.pbThis, pbThis(true))
    elsif isConst?(move, PBMoves, :WRAP)
      msg = _INTL("{1} was wrapped by {2}!", pbThis ,user.pbThis(true))
    else
      msg = _INTL("{1} can no longer escape!", pbThis)
    end
    @battle.pbDisplay(msg)
    return true
  end
end

class PokeBattle_Battle
  def pbStartWeatherEx(user, weather)
    @field.weather = PBWeather::None
    pbStartWeather(user, getID(PBWeather, weather), true)
  end

  def pbStartTerrainEx(user, terrain, anim = true)
    @field.terrain = PBBattleTerrains::None
    terr_id = (terrain.to_s.upcase + "TERRAIN").to_sym
    @battle.pbAnimation(getID(PBMoves, terr_id), user, nil) if anim
    pbStartTerrain(user, getID(PBBattleTerrains, terrain), true)
  end
end
