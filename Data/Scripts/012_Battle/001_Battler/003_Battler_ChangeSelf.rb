class PokeBattle_Battler
  #=============================================================================
  # Change HP
  #=============================================================================
  def pbReduceHP(amt,anim=true,registerDamage=true,anyAnim=true)
    amt = amt.round
    amt = @hp if amt>@hp
    amt = 1 if amt<1 && !fainted?
    oldHP = @hp
    self.hp -= amt
    PBDebug.log("[HP change] #{pbThis} lost #{amt} HP (#{oldHP}=>#{@hp})") if amt>0
    raise _INTL("HP less than 0") if @hp<0
    raise _INTL("HP greater than total HP") if @hp>@totalhp
    @battle.scene.pbHPChanged(self,oldHP,anim) if anyAnim && amt>0
    @tookDamage = true if amt>0 && registerDamage
    return amt
  end

  def pbRecoverHP(amt,anim=true,anyAnim=true)
    amt = amt.round
    amt = @totalhp-@hp if amt>@totalhp-@hp
    amt = 1 if amt<1 && @hp<@totalhp
    oldHP = @hp
    self.hp += amt
    PBDebug.log("[HP change] #{pbThis} gained #{amt} HP (#{oldHP}=>#{@hp})") if amt>0
    raise _INTL("HP less than 0") if @hp<0
    raise _INTL("HP greater than total HP") if @hp>@totalhp
    @battle.scene.pbHPChanged(self,oldHP,anim) if anyAnim && amt>0
    self.yamaskhp = 0
    return amt
  end

  def pbRecoverHPFromDrain(amt,target,msg=nil)
    if target.hasActiveAbility?(:LIQUIDOOZE)
      @battle.pbShowAbilitySplash(target)
      pbReduceHP(amt)
      @battle.pbDisplay(_INTL("{1} sucked up the liquid ooze!",pbThis))
      @battle.pbHideAbilitySplash(target)
      pbItemHPHealCheck
    else
      msg = _INTL("{1} had its energy drained!",target.pbThis) if !msg || msg==""
      @battle.pbDisplay(msg)
      if canHeal?
        amt = (amt*1.3).floor if hasActiveItem?(:BIGROOT)
        pbRecoverHP(amt)
      end
    end
  end

  def pbFaint(showMessage=true)
    if !fainted?
      PBDebug.log("!!!***Can't faint with HP greater than 0")
      return
    end
    return if @fainted   # Has already fainted properly
    @battle.pbDisplayBrief(_INTL("{1} fainted!",pbThis)) if showMessage
    PBDebug.log("[Pokémon fainted] #{pbThis} (#{@index})") if !showMessage
    @battle.scene.pbFaintBattler(self)
    pbInitEffects(false)
    # Reset status
    self.status      = PBStatuses::NONE
    self.statusCount = 0
    # Lose happiness
    if @pokemon && @battle.internalBattle
      badLoss = false
      @battle.eachOtherSideBattler(@index) do |b|
        badLoss = true if b.level>=self.level+30
      end
      @pokemon.changeHappiness((badLoss) ? "faintbad" : "faint")
    end
    # Reset form
    @battle.peer.pbOnLeavingBattle(@battle,@pokemon,@battle.usedInBattle[idxOwnSide][@index/2])
    @pokemon.makeUnmega if mega?
    @pokemon.makeUnprimal if primal?
	  @pokemon.yamaskhp = 0 # Yamask
    # Do other things
    @battle.pbClearChoice(@index)   # Reset choice
    pbOwnSide.effects[PBEffects::LastRoundFainted] = @battle.turnCount
    # Check other battlers' abilities that trigger upon a battler fainting
    pbAbilitiesOnFainting
    # Check for end of primordial weather
    @battle.pbEndPrimordialWeather
  end

  #=============================================================================
  # Move PP
  #=============================================================================
  def pbSetPP(move,pp)
    move.pp = pp
    # No need to care about @effects[PBEffects::Mimic], since Mimic can't copy
    # Mimic
    if move.realMove && move.id==move.realMove.id && !@effects[PBEffects::Transform]
      move.realMove.pp = pp
    end
  end

  def pbReducePP(move)
    return true if usingMultiTurnAttack?
    return true if move.pp<0         # Don't reduce PP for special calls of moves
    return true if move.totalpp<=0   # Infinite PP, can always be used
    return false if move.pp==0       # Ran out of PP, couldn't reduce
    pbSetPP(move,move.pp-1) if move.pp>0
    return true
  end

  def pbReducePPOther(move)
    pbSetPP(move,move.pp-1) if move.pp>0
  end

  #=============================================================================
  # Change type
  #=============================================================================
  def pbChangeTypes(newType)
    if newType.is_a?(PokeBattle_Battler)
      newTypes = newType.pbTypes
      newTypes.push(getConst(PBTypes,:NORMAL) || 0) if newTypes.length==0
      newType3 = newType.effects[PBEffects::Type3]
      newType3 = -1 if newTypes.include?(newType3)
      @type1 = newTypes[0]
      @type2 = (newTypes.length==1) ? newTypes[0] : newTypes[1]
      @effects[PBEffects::Type3] = newType3
    else
      newType = getConst(PBTypes,newType) if newType.is_a?(Symbol) || newType.is_a?(String)
      @type1 = newType
      @type2 = newType
      @effects[PBEffects::Type3] = -1
    end
    @effects[PBEffects::BurnUp] = false
    @effects[PBEffects::Roost]  = false
  end

  #=============================================================================
  # Forms
  #=============================================================================
  def pbChangeForm(newForm,msg)
    return if fainted? || @effects[PBEffects::Transform] || @form==newForm
    oldForm = @form
    oldDmg = @totalhp-@hp
    self.form = newForm
    pbUpdate(true)
    @hp = @totalhp-oldDmg
    @effects[PBEffects::WeightChange] = 0 if NEWEST_BATTLE_MECHANICS
    @battle.scene.pbChangePokemon(self,@pokemon)
    @battle.scene.pbRefreshOne(@index)
    @battle.pbDisplay(msg) if msg && msg!=""
    PBDebug.log("[Form changed] #{pbThis} changed from form #{oldForm} to form #{newForm}")
    @battle.pbSetSeen(self)
  end

  def pbCheckFormOnStatusChange
    return if fainted? || @effects[PBEffects::Transform]
    # Shaymin - reverts if frozen
    if isSpecies?(:SHAYMIN) && frozen?
      pbChangeForm(0,_INTL("{1} transformed!",pbThis))
    end
  end

  def pbCheckFormOnMovesetChange
    return if fainted? || @effects[PBEffects::Transform]
    # Keldeo - knowing Secret Sword
    if isSpecies?(:KELDEO)
      newForm = 0
      newForm = 1 if pbHasMove?(:SECRETSWORD)
      pbChangeForm(newForm,_INTL("{1} transformed!",pbThis))
    end
  end

  def pbCheckFormOnWeatherChange
    return if fainted? || @effects[PBEffects::Transform]
    return if hasUtilityUmbrella?
    # Castform - Forecast
    if isSpecies?(:CASTFORM)
      if hasActiveAbility?(:FORECAST)
        newForm = 0
        case @battle.pbWeather
        when PBWeather::Sun, PBWeather::HarshSun
          newForm = 1
        when PBWeather::Rain, PBWeather::HeavyRain
          newForm = 2
        when PBWeather::Hail
          newForm = 3
        end
        if @form!=newForm
          @battle.pbShowAbilitySplash(self,true)
          @battle.pbHideAbilitySplash(self)
          pbChangeForm(newForm,_INTL("{1} transformed!",pbThis))
        end
      else
        pbChangeForm(0,_INTL("{1} transformed!",pbThis))
      end
    end
    # Cherrim - Flower Gift
    if isSpecies?(:CHERRIM)
      if hasActiveAbility?(:FLOWERGIFT)
        newForm = 0
        case @battle.pbWeather
        when PBWeather::Sun, PBWeather::HarshSun; newForm = 1
        end
        if @form!=newForm
          @battle.pbShowAbilitySplash(self,true)
          @battle.pbHideAbilitySplash(self)
          pbChangeForm(newForm,_INTL("{1} transformed!",pbThis))
        end
      else
        pbChangeForm(0,_INTL("{1} transformed!",pbThis))
      end
    end
    # Eiscue - Ice Face
    if isConst?(@species,PBSpecies,:EISCUE) && hasActiveAbility?(:ICEFACE) && @battle.pbWeather == PBWeather::Hail
      if @form==1
        @battle.pbShowAbilitySplash(self,true)
        @battle.pbHideAbilitySplash(self)
        pbChangeForm(0,_INTL("{1} transformed!",pbThis))
      end
    end
  end

  #=============================================================================
  # Change type of Galarian Stunfisk - Mimicry
  #=============================================================================
  def pbChangeTypes(newType)
    if newType.is_a?(PokeBattle_Battler)
      newTypes = newType.pbTypes
      newTypes.push(getConst(PBTypes,:NORMAL) || 0) if newTypes.length==0
      newType3 = newType.effects[PBEffects::Type3]
      newType3 = -1 if newTypes.include?(newType3)
      @type1 = newTypes[0]
      @type2 = (newTypes.length==1) ? newTypes[0] : newTypes[1]
      @effects[PBEffects::Type3] = newType3
    elsif newType.is_a?(Array)
      newType = newType.map {|t|
        if t.is_a?(Symbol) || t.is_a?(String)
          getConst(PBTypes,t)
        else
          t
        end
      }
      newType3 = newType[2] || -1
      @type1 = newType[0]
      @type2 = newType[1] || newType[0]
      @effects[PBEffects::Type3] = newType3
    else
      newType = getConst(PBTypes,newType) if newType.is_a?(Symbol) || newType.is_a?(String)
      @type1 = newType
      @type2 = newType
      @effects[PBEffects::Type3] = -1
    end
    @effects[PBEffects::BurnUp] = false
    @effects[PBEffects::Roost]  = false
  end

   def pbCheckFormOnTerrainChange
    return if fainted? #|| @effects[PBEffects::Transform] Ditto reverts back to Normal.
    if hasActiveAbility?(:MIMICRY)
      newTypes = self.pbTypes
      originalTypes=[@pokemon.type1,@pokemon.type2] | []
      case @battle.field.terrain
      when PBBattleTerrains::Electric;   newTypes = [getID(PBTypes,:ELECTRIC)]
      when PBBattleTerrains::Grassy;     newTypes = [getID(PBTypes,:GRASS)]
      when PBBattleTerrains::Misty;      newTypes = [getID(PBTypes,:FAIRY)]
      when PBBattleTerrains::Psychic;    newTypes = [getID(PBTypes,:PSYCHIC)]
      else;                              newTypes = originalTypes.dup
      end
      if self.pbTypes!=newTypes
        pbChangeTypes(newTypes)
        @battle.pbShowAbilitySplash(self,true)
        @battle.pbHideAbilitySplash(self)
        if newTypes!=originalTypes
          if PokeBattle_SceneConstants::USE_ABILITY_SPLASH
            @battle.pbDisplay(_INTL("{1}'s type changed to {3}!",pbThis,
             self.abilityName,PBTypes.getName(newTypes[0])))
          else
            @battle.pbDisplay(_INTL("{1}'s {2} made it the {3} type!",pbThis,
             self.abilityName,PBTypes.getName(newTypes[0])))
          end
        else
          @battle.pbDisplay(_INTL("{1} returned back to normal!",pbThis))
        end
      end
    end
  end

  # Checks the Pokémon's form and updates it if necessary. Used for when a
  # Pokémon enters battle (endOfRound=false) and at the end of each round
  # (endOfRound=true).
  def pbCheckForm(endOfRound=false)
    return if fainted? || @effects[PBEffects::Transform]
    # Form changes upon entering battle and when the weather changes
    pbCheckFormOnWeatherChange if !endOfRound
	  pbCheckFormOnTerrainChange if !endOfRound
    # Darmanitan - Zen Mode
    if isConst?(@species,PBSpecies,:DARMANITAN) && isConst?(@ability,PBAbilities,:ZENMODE)
      if @hp<=@totalhp/2
        if @form!=2 && @form!=3
          @battle.pbShowAbilitySplash(self,true)
          @battle.pbHideAbilitySplash(self)
          pbChangeForm(2,_INTL("{1} triggered!",abilityName)) if @form == 0
          pbChangeForm(3,_INTL("{1} triggered!",abilityName)) if @form == 1
        end
      elsif @form!=0 && @form != 1
        @battle.pbShowAbilitySplash(self,true)
        @battle.pbHideAbilitySplash(self)
        pbChangeForm(0,_INTL("{1} triggered!",abilityName)) if @form == 2
        pbChangeForm(1,_INTL("{1} triggered!",abilityName)) if @form == 3
      end
    end
    # Minior - Shields Down
    if isSpecies?(:MINIOR) && isConst?(@ability,PBAbilities,:SHIELDSDOWN)
      if @hp>@totalhp/2   # Turn into Meteor form
        newForm = (@form>=7) ? @form-7 : @form
        if @form!=newForm
          @battle.pbShowAbilitySplash(self,true)
          @battle.pbHideAbilitySplash(self)
          pbChangeForm(newForm,_INTL("{1} deactivated!",abilityName))
        elsif !endOfRound
          @battle.pbDisplay(_INTL("{1} deactivated!",abilityName))
        end
      elsif @form<7   # Turn into Core form
        @battle.pbShowAbilitySplash(self,true)
        @battle.pbHideAbilitySplash(self)
        pbChangeForm(@form+7,_INTL("{1} activated!",abilityName))
      end
    end
    # Wishiwashi - Schooling
    if isSpecies?(:WISHIWASHI) && isConst?(@ability,PBAbilities,:SCHOOLING)
      if @level>=20 && @hp>@totalhp/4
        if @form!=1
          @battle.pbShowAbilitySplash(self,true)
          @battle.pbHideAbilitySplash(self)
          pbChangeForm(1,_INTL("{1} formed a school!",pbThis))
        end
      elsif @form!=0
        @battle.pbShowAbilitySplash(self,true)
        @battle.pbHideAbilitySplash(self)
        pbChangeForm(0,_INTL("{1} stopped schooling!",pbThis))
      end
    end
    # Zygarde - Power Construct
    if isSpecies?(:ZYGARDE) && isConst?(@ability,PBAbilities,:POWERCONSTRUCT) &&
       endOfRound
      if @hp<=@totalhp/2 && @form<2   # Turn into Complete Forme
        newForm = @form+2
        @battle.pbDisplay(_INTL("You sense the presence of many!"))
        @battle.pbShowAbilitySplash(self,true)
        @battle.pbHideAbilitySplash(self)
        pbChangeForm(newForm,_INTL("{1} transformed into its Complete Forme!",pbThis))
      end
    end
  end

  def pbTransform(target)
    if target.shadowPokemon?
      @battle.pbDisplay(_INTL("{1} is unable to transform into {2}!",pbThis,target.pbThis))
      return false
    end
    oldAbil = @ability
    @effects[PBEffects::Transform]        = true
    @effects[PBEffects::TransformSpecies] = target.species
    pbChangeTypes(target)
    @ability = target.ability
    @attack  = target.attack
    @defense = target.defense
    @spatk   = target.spatk
    @spdef   = target.spdef
    @speed   = target.speed
    PBStats.eachBattleStat { |s| @stages[s] = target.stages[s] }
    if NEWEST_BATTLE_MECHANICS
      @effects[PBEffects::FocusEnergy] = target.effects[PBEffects::FocusEnergy]
      @effects[PBEffects::LaserFocus]  = target.effects[PBEffects::LaserFocus]
    end
    @moves.clear
    target.moves.each_with_index do |m,i|
      @moves[i] = PokeBattle_Move.pbFromPBMove(@battle,PBMove.new(m.id))
      @moves[i].pp      = 5
      @moves[i].totalpp = 5
    end
    @effects[PBEffects::Disable]      = 0
    @effects[PBEffects::DisableMove]  = 0
    @effects[PBEffects::WeightChange] = target.effects[PBEffects::WeightChange]
    @battle.scene.pbRefreshOne(@index)
    @battle.pbDisplay(_INTL("{1} transformed into {2}!",pbThis,target.pbThis(true)))
    pbOnAbilityChanged(oldAbil)
  end

  def pbHyperMode; end
end
