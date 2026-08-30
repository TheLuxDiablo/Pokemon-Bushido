class PokeBattle_Battler

  # Special stat raising method for Katana Techniques (covers the weak katana toggle)
  def pbRaiseStatStageEx(stats, incs, anim = true, user = nil, forced: false)
    user = self if user.nil?
    if user.fainted?
        user = self
    end
    return false if !forced && !opposes?(user) && !strong_katanas?
    return false if self.fainted?
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

  # Special stat raising method for Player Katana Techniques
  def pbRaiseStatStagePKT(stats, incs, anim = true, user = nil, forced: false)
    user = self if user.nil?
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

  # Special stat lowering method for PKT
  def pbLowerStatStagePKT(stats, incs, anim = true, user = nil, forced: false)
    user = self if user.nil?
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
  def pbInflictStatusEx(stat, newStatusCount = 0, anim = nil, user = nil, ignoreStatus = false, msg = nil, move = nil, targets = nil, forced: false)
    user = self if user.nil?
    targets = self if targets.nil?

    return false if !forced && opposes?(user) && !strong_katanas?
    return false if !strong_katanas?
    yield if block_given?
    case anim
    when Symbol
      @battle.pbAnimation(getID(PBMoves, anim), user, targets) if !fainted? && !user.fainted?
    when String
      @battle.pbCommonAnimation(anim, user, targets) if !fainted? && !user.fainted?
    end
    newStatus = getID(PBStatuses, stat) if stat.is_a?(Symbol)
    return false if !pbCanInflictStatus?(newStatus, user, true, move, ignoreStatus)
    return pbInflictStatus(newStatus, newStatusCount, msg, user)
  end

    # Special status inflicting method for PKT
  def pbInflictStatusPKT(stat, newStatusCount = 0, anim = nil, user = nil, ignoreStatus = false, msg = nil, move = nil, forced: false)
    user = self if user.nil?
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
    return false if !forced && opposes?(user) && !strong_katanas?
    yield if block_given?
    @battle.pbAnimation(getID(PBMoves, move), user, self) if !fainted? && !user.fainted?
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
    anim_id = getID(PBMoves, terr_id)

    # Check if @battle exists, otherwise try to extract it from the user (the Pokémon object)
    battle_obj = @battle || (user.respond_to?(:battle) ? user.battle : nil)
  
    if anim && anim_id && battle_obj
        battle_obj.pbAnimation(anim_id, user, nil)
    end

    pbStartTerrain(user, getID(PBBattleTerrains, terrain), true)
  end

  def EvilRandomEffect(effectNum, battle, scene, ally1=nil, ally2=nil, enemy1=nil, enemy2=nil)
    pbMessage(_INTL("Effect Number: {1}", effectNum))
    case effectNum
    when 0
        enemy1.pbRaiseStatStageEx(:ATTACK, 1, forced: true)
        enemy2.pbRaiseStatStageEx(:ATTACK, 1, forced: true)
    when 1
        enemy1.pbRaiseStatStageEx(:DEFENSE, 1, forced: true)
        enemy2.pbRaiseStatStageEx(:DEFENSE, 1, forced: true)
    when 2
        enemy1.pbRaiseStatStageEx(:SPEED, 1, forced: true)
        enemy2.pbRaiseStatStageEx(:SPEED, 1, forced: true)
    when 3
        enemy1.pbRaiseStatStageEx(:SPDEF, 1, forced: true)
        enemy2.pbRaiseStatStageEx(:SPDEF, 1, forced: true)
    when 4
        enemy1.pbRaiseStatStageEx(:SPATK, 1, forced: true)
        enemy2.pbRaiseStatStageEx(:SPATK, 1, forced: true)
    end
  end

  def RandomSukiroQuiz(effectNum, battle, scene, ally=nil, enemy=nil)
    #pbMessage(_INTL("Effect Number: {1}", effectNum))
    statToBuff = getARandomStat()
    pbMessage("\\bNow, \\PN... Tell me...")
    case effectNum
    when 0
        cmd= pbMessage("\\bWhat is a Kenshi's source of power?", ["Spear", "Pokémon", "Katana", "Odachi"])
        if cmd == 1
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 1
        cmd= pbMessage("\\bWhat is the name of our village?", ["Eco", "Edo", "Ezo", "Evo"])
        if cmd == 2
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 2
        cmd= pbMessage("\\bWhat is the name of the capitol city in Aisho?", ["Hagane", "Tsuchi", "Izumi", "Hanatsu"])
        if cmd == 0
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 3
        cmd= pbMessage("\\bHow old am I?", ["67", "69", "70", "90"])
        if cmd == 2
          pbMessage("\\se[SwShCorrect]\\bCorrect! I am 70 years old.")
          scene.pbHideOpponent
          scene.disappearBar
          ally.pbRaiseStatStagePKT(statToBuff, 1, true, ally)
        elsif cmd == 3
          pbMessage("\\se[SwShIncorrect]\\bI don't look that old... Do I, \\PN?!")
          scene.pbHideOpponent
          scene.disappearBar
          ally.pbLowerStatStageEx(statToBuff, 1, true, ally) if strong_katanas?
          enemy.pbRaiseStatStageEx(statToBuff, 1, true, enemy) if strong_katanas?
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 4
        cmd= pbMessage("\\bWhich type is most effective against the Konchu Clan?", ["Water", "Electric", "Psychic", "Fire"])
        if cmd == 3
          pbMessage("\\se[SwShCorrect]\\bWell done! That is correct!")
          pbMessage("\\bFire moves would tend to be most effective against the Bug-Types of the Konchu Clan!")
          scene.pbHideOpponent
          scene.disappearBar
          ally.pbRaiseStatStagePKT(statToBuff, 1, true, ally)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 5
        cmd= pbMessage("\\bWhat rare resource are they known for mining in Hanatsu Cave?", ["Gold", "Silver", "Orichalcum", "Hanatsium"])
        if cmd == 3
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 6
        cmd= pbMessage("\\bWhat is the name of the clan that uses Ice-Type Pokémon?", ["Kori", "Yuki", "Hyo", "Fubuki"])
        if cmd == 1
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 7
        cmd= pbMessage("\\bWhich type is most effective against the Komorei Clan?", ["Flying", "Bug", "Fighting", "Dark"])
        if cmd == 0
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 8
        cmd= pbMessage("\\bWhich type is most effective against the Nensho Clan?", ["Steel", "Ground", "Electric", "Normal"])
        if cmd == 1
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 9
        cmd= pbMessage("\\bWhich type is most effective against the Shimizu Clan?", ["Fairy", "Dark", "Ice", "Grass"])
        if cmd == 3
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 10
        cmd= pbMessage("\\bWhich type is most effective against the Iwa Clan?", ["Poison", "Steel", "Water", "Flying"])
        if cmd == 2
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 11
        cmd= pbMessage("\\bWhich type is most effective against the Yuki Clan?", ["Electric", "Fighting", "Fairy", "Ground"])
        if cmd == 1
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 12
        cmd= pbMessage("\\bWhat do you call the small shrines that Kenshi pray at throughout the region?", ["Honden", "Torii", "Tsukiyomi", "Hokora"])
        if cmd == 3
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 13
        cmd= pbMessage("\\bWhat is the name of the sea to the west of Hagane City?", ["Kaiyo", "Chikyu", "Hagane", "Umi"])
        if cmd == 0
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 14
        cmd= pbMessage("\\bWhat is the name of the forest to the south of Hagane City?", ["Tsuchi", "Kusa", "Shizen", "Mori"])
        if cmd == 2
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 15
        cmd= pbMessage("\\bWhich of these Pokémon is the fastest?", ["Lucario", "Greninja", "Sharpedo", "Mienshao"])
        if cmd == 1
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 16
        cmd= pbMessage("\\bWhich of these Pokémon has the highest Attack?", ["Pangoro", "Tyranitar", "Conkeldurr", "Garchomp"])
        if cmd == 2
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 17
        cmd= pbMessage("\\bWhich of these Pokémon has the highest Special Attack?", ["Froslass", "Slowking", "Ninetales", "Jolteon"])
        if cmd == 3
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 18
        cmd= pbMessage("\\bWhat is the name of my favorite place to eat in Hagane City?", ["Kogeta Yakitori", "Kimoi Tempura", "Oishi Sushi", "Raku Raku Ramen"])
        if cmd == 3
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 19
        cmd= pbMessage("\\bWhat is the name of the region we live in?", ["Aisho", "Ashiro", "Sekai", "Heiwa"])
        if cmd == 0
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 20
        cmd= pbMessage("\\bWhat is the name of the clan that uses Fire-Type Pokémon?", ["Nensho", "Moyasu", "Kaji", "Kogeru"])
        if cmd == 0
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 21
        cmd= pbMessage(_INTL("\\bWhat is the name of {1}'s clan?", getRivalsName()), ["Hadouken", "Hakuho", "Hashimoto", "Uzumaki"])
        if cmd == 2
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 22
        cmd= pbMessage("\\bWhat is the name of the clan that uses Water-Type Pokémon?", ["Mizu", "Taki", "Sui", "Shimizu"])
        if cmd == 3
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 23
        cmd= pbMessage("\\bWhat is the name of the clan that uses Grass-Type Pokémon?", ["Komorei", "Taima", "Mori", "Tsurukusa"])
        if cmd == 0
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 24
        cmd= pbMessage("\\bWhen a Pokémon's heart is shrouded in darkness, what are they called?", ["Oni Pokémon", "Evil Pokémon", "Dark Pokémon", "Shadow Pokémon"])
        if cmd == 3
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 25
        cmd= pbMessage("\\bWhat type of trees grow on the route to the west of Ezo Village?", ["Cypress", "Bonsai", "Sakura", "Gingko"])
        if cmd == 2
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    when 26
        cmd= pbMessage("\\bWhat is the best place to catch Bug-Type Pokémon?", ["Yogan Cavern","Mushi Grove", "Shizen Trail", "Fubuki Bay"])
        if cmd == 1
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    else # Default Question
        cmd= pbMessage("\\bWhat is a Kenshi's source of power?", ["Spear", "Pokémon", "Katana"])
        if cmd == 1
          correctAnswerGenericResponse(scene, ally, statToBuff)
        else
          incorrectAnswerGenericResponse(scene, ally, statToBuff, enemy)
        end
    end
  end
end
