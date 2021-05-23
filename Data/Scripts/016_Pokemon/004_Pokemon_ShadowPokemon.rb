=begin
All types except Shadow have Shadow as a weakness.
Shadow has Shadow as a resistance.
On a side note, the Shadow moves in Colosseum will not be affected by Weaknesses
or Resistances, while in XD the Shadow-type is Super-Effective against all other
types.
2/5 - display nature

XD - Shadow Rush -- 55, 100 - Deals damage.
Colosseum - Shadow Rush -- 90, 100
If this attack is successful, user loses half of HP lost by opponent due to this
attack (recoil). If user is in Hyper Mode, this attack has a good chance for a
critical hit.
=end

#===============================================================================
# Purify a Shadow Pokémon.
#===============================================================================
def pbPurify(pokemon,scene)
  if pokemon.isSpecies?(:LUGIA)
    scene.pbDisplay(_INTL("Shadow Lugia refuses to be purified."))
    return
  end
  return if pokemon.heartgauge!=0 || !pokemon.shadow
  return if !pokemon.savedev && !pokemon.savedexp
  pbMEPlay("Bug catching 1st")
  pokemon.shadow = false
  pokemon.giveRibbon(PBRibbons::NATIONAL)
  # Thundaga, make purified pokemon perfect IVs
  pokemon.iv[0] = 31
  pokemon.iv[1] = 31
  pokemon.iv[2] = 31
  pokemon.iv[3] = 31
  pokemon.iv[4] = 31
  pokemon.iv[5] = 31
  scene.pbDisplay(_INTL("{1} opened the door to its heart!",pokemon.name))
  # Chance to become shiny after being purified
  randOdds=rand(200)
  if randOdds==1
    pbMEPlay("Bug catching 3rd")
    scene.pbDisplay(_INTL("{1} became shiny after being purified!",pokemon.name))
    pokemon.makeShiny
  end
  # loop through all pokemon and see if they've been purified, check if has NATIONAL ribbon?
  if $game_variables[94]==0
    $game_variables[94]=pbGetTotalPurified
  else
    $game_variables[94]+=1
  end
  scene.pbDisplay(_INTL("You have now purified {1} Pokémon!",pbGet(94)))
  oldmoves = []
  for i in 0...4; oldmoves.push(pokemon.moves[i].id); end
  pokemon.pbUpdateShadowMoves
  for i in 0...4
    next if pokemon.moves[i].id<=0 || pokemon.moves[i].id==oldmoves[i]
    scene.pbDisplay(_INTL("{1} regained the move \n{2}!",pokemon.name,PBMoves.getName(pokemon.moves[i].id)))
  end
  pokemon.pbRecordFirstMoves
  if pokemon.savedev
    for i in 0...6
      pbApplyEVGain(pokemon,i,pokemon.savedev[i])
    end
    pokemon.savedev = nil
  end
  newexp = PBExperience.pbAddExperience(pokemon.exp,pokemon.savedexp||0,pokemon.growthrate)
  pokemon.savedexp = nil
  newlevel = PBExperience.pbGetLevelFromExperience(newexp,pokemon.growthrate)
  curlevel = pokemon.level
  if newexp!=pokemon.exp
    scene.pbDisplay(_INTL("{1} regained {2} Exp. Points!",pokemon.name,newexp-pokemon.exp))
  end
  if newlevel==curlevel
    pokemon.exp = newexp
    pokemon.calcStats
  else
    pbChangeLevel(pokemon,newlevel,scene) # for convenience
    pokemon.exp = newexp
  end
  speciesname = PBSpecies.getName(pokemon.species)
  if scene.pbConfirm(_INTL("Would you like to give a nickname to {1}?",speciesname)) || Nuzlocke.on?
    newname = pbEnterPokemonName(_INTL("{1}'s nickname?",speciesname),
       0,PokeBattle_Pokemon::MAX_POKEMON_NAME_SIZE,"",pokemon)
    pokemon.name = newname if newname!=""
  end
  #Thundaga teach a new move to all shadows
  #scene.pbDisplay(_INTL("{1} can now learn Luminescence after being purified!",pokemon.name))
  #if scene.pbConfirm(_INTL("Would you like to teach {1} the new attack, Luminescence?",pokemon.name))
  #  move = pbChooseMoveList
  #  if move!=0
  #    pbLearnMove(pokemon,move)
  #    pbRefreshSingle(pokemon.id)
  #  end
  #end
end

def pbApplyEVGain(pokemon,ev,evgain)
  totalev = 0
  for i in 0...6
    totalev += pokemon.ev[i]
  end
  if totalev+evgain>PokeBattle_Pokemon::EV_LIMIT   # Can't exceed overall limit
    evgain -= totalev+evgain-PokeBattle_Pokemon::EV_LIMIT
  end
  if pokemon.ev[ev]+evgain>PokeBattle_Pokemon::EV_STAT_LIMIT
    evgain -= totalev+evgain-PokeBattle_Pokemon::EV_STAT_LIMIT
  end
  if evgain>0
    pokemon.ev[ev] += evgain
  end
end

def pbReplaceMoves(pokemon,move1,move2=0,move3=0,move4=0)
  return if !pokemon
  [move1,move2,move3,move4].each { |move|
    moveIndex = -1
    if move!=0
      # Look for given move
      for i in 0...4
        moveIndex = i if pokemon.moves[i].id==move
      end
    end
    if moveIndex==-1
      # Look for slot to replace move
      for i in 0...4
        if (pokemon.moves[i].id==0 && move!=0) || (
            pokemon.moves[i].id!=move1 &&
            pokemon.moves[i].id!=move2 &&
            pokemon.moves[i].id!=move3 &&
            pokemon.moves[i].id!=move4)
          # Replace move
          pokemon.moves[i] = PBMove.new(move)
          break
        end
      end
    end
  }
end



#===============================================================================
# Relic Stone scene.
#===============================================================================
class RelicStoneScene
  def pbPurify
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbDisplay(msg,brief=false)
    UIHelper.pbDisplay(@sprites["msgwindow"],msg,brief) { pbUpdate }
  end

  def pbConfirm(msg)
    UIHelper.pbConfirm(@sprites["msgwindow"],msg) { pbUpdate }
  end

  def pbStartScene(pokemon)
    @sprites = {}
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @pokemon = pokemon
    addBackgroundPlane(@sprites,"bg","relicstonebg",@viewport)
    @sprites["msgwindow"] = Window_AdvancedTextPokemon.new("")
    @sprites["msgwindow"].viewport = @viewport
    @sprites["msgwindow"].x        = 0
    @sprites["msgwindow"].y        = Graphics.height-96
    @sprites["msgwindow"].width    = Graphics.width
    @sprites["msgwindow"].height   = 96
    @sprites["msgwindow"].text     = ""
    @sprites["msgwindow"].visible  = true
    pbDeactivateWindows(@sprites)
    pbFadeInAndShow(@sprites) { pbUpdate }
  end
end



class RelicStoneScreen
  def initialize(scene)
    @scene = scene
  end

  def pbDisplay(x)
    @scene.pbDisplay(x)
  end

  def pbConfirm(x)
    @scene.pbConfirm(x)
  end

  def pbUpdate; end

  def pbRefresh; end

  def pbStartScreen(pokemon)
    @scene.pbStartScene(pokemon)
    @scene.pbPurify
    pbPurify(pokemon,self)
    @scene.pbEndScene
  end
end



def pbRelicStoneScreen(pkmn)
  retval = true
  pbFadeOutIn {
    scene = RelicStoneScene.new
    screen = RelicStoneScreen.new(scene)
    retval = screen.pbStartScreen(pkmn)
  }
  return retval
end



#===============================================================================
#
#===============================================================================
def pbIsPurifiable?(pkmn)
  return false if !pkmn
  return false if pkmn.isSpecies?(:LUGIA)
  return false if !pkmn.shadowPokemon? || pkmn.heartgauge>0
  return true
end

def pbHasPurifiableInParty?
  return $Trainer.party.any? { |pkmn| pbIsPurifiable?(pkmn) }
end

def pbHasShadowInParty?
  return $Trainer.party.any? { |pkmn| pkmn.shadowPokemon? }
end

def pbRelicStone
  if !pbHasPurifiableInParty?
    pbMessage(_INTL("You have no Pokémon that can be purified."))
    return
  end
  pbMessage(_INTL("There's a Pokémon that may open the door to its heart!"))
  # Choose a purifiable Pokemon
  pbChoosePokemon(1,2,proc { |pkmn|
    !pkmn.egg? && pkmn.hp>0 && pkmn.shadowPokemon? && pkmn.heartgauge==0 && !pkmn.isSpecies?(:LUGIA)
  })
  if $game_variables[1]>=0
    pbRelicStoneScreen($Trainer.party[$game_variables[1]])
  end
end

def pbReadyToPurify(pkmn)
  return unless pkmn && pkmn.shadowPokemon?
  pkmn.pbUpdateShadowMoves
  if pkmn.heartgauge==0 && !pkmn.isSpecies?(:LUGIA)
    pbMessage(_INTL("{1} can now be purified!",pkmn.name))
  end
end



#===============================================================================
# Pokémon class.
#===============================================================================
class PokeBattle_Pokemon
  attr_writer   :heartgauge
  attr_accessor :shadow
  attr_writer   :hypermode
  attr_accessor :savedev
  attr_accessor :savedexp
  attr_accessor :shadowmoves
  attr_accessor :shadowmovenum
  HEARTGAUGESIZE = 3840

  alias :__shadow_expeq :exp=
  def exp=(value)
    if shadowPokemon?
      @savedexp += value-self.exp
    else
      __shadow_expeq(value)
    end
  end

  alias :__shadow_hpeq :hp=
  def hp=(value)
    __shadow_hpeq(value)
    @hypermode = false if value<=0
  end

  def hypermode
    return (self.heartgauge==0 || self.hp==0) ? false : @hypermode
  end

  def heartgauge
    return @heartgauge || 0
  end

  def heartStage
    return 0 if !@shadow
    hg = HEARTGAUGESIZE/5.0
    return ([self.heartgauge,HEARTGAUGESIZE].min/hg).ceil
  end

  def adjustHeart(value)
    return if !@shadow
    @heartgauge = 0 if !@heartgauge
    @heartgauge += value
    @heartgauge = HEARTGAUGESIZE if @heartgauge>HEARTGAUGESIZE
    @heartgauge = 0 if @heartgauge<0
  end

  def shadowPokemon?
    return @shadow && @heartgauge && @heartgauge>=0
  end
  alias :isShadow? :shadowPokemon?

  def makeShadow
    self.shadow      = true
    self.heartgauge  = HEARTGAUGESIZE
    self.savedexp    = 0
    self.savedev     = [0,0,0,0,0,0]
    self.shadowmoves = [0,0,0,0,0,0,0,0]
    # Retrieve shadow moves
    shadow_movesets = pbLoadShadowMovesets
    shadow_moves = shadow_movesets[self.fSpecies]
    shadow_moves = shadow_movesets[self.species] if !shadow_moves || shadow_moves.length == 0
    if shadow_moves && shadow_moves.length > 0
      for i in 0...[4,shadow_moves.length].min
        self.shadowmoves[i] = shadow_moves[i]
      end
      self.shadowmovenum = shadow_moves.length
    else
      # No special shadow moves
      self.shadowmoves[0] = getConst(PBMoves,:SHADOWRUSH) || 0
      self.shadowmovenum = 1
    end
    for i in 0...4   # Save old moves
      self.shadowmoves[4+i] = self.moves[i].id
    end
    pbUpdateShadowMoves
  end

  def pbUpdateShadowMoves(allmoves=false)
    return if !@shadowmoves
    m = @shadowmoves
    if !@shadow
      # No shadow moves
      pbReplaceMoves(self,m[4],m[5],m[6],m[7])
      @shadowmoves = nil
    else
      moves = []
      relearning = (allmoves) ? 3 : [3,3,2,1,1,0][self.heartStage]
      relearned = 0
      # Add all Shadow moves
      for i in 0...4; moves.push(m[i]) if m[i]!=0; end
      # Add X regular moves
      for i in 0...4
        next if i<@shadowmovenum
        if m[i+4]!=0 && relearned<relearning
          moves.push(m[i+4]); relearned += 1
        end
      end
      pbReplaceMoves(self,moves[0] || 0,moves[1] || 0,moves[2] || 0,moves[3] || 0)
    end
  end

  alias :__shadow_clone :clone
  def clone
    ret = __shadow_clone
    ret.savedev     = self.savedev.clone if self.savedev
    ret.shadowmoves = self.shadowmoves.clone if self.shadowmoves
    return ret
  end
end



#===============================================================================
# Shadow Pokémon in battle.
#===============================================================================
class PokeBattle_Battle
  alias __shadow__pbCanUseItemOnPokemon? pbCanUseItemOnPokemon?

  def pbCanUseItemOnPokemon?(item,pkmn,battler,scene,showMessages=true)
    ret = __shadow__pbCanUseItemOnPokemon?(item,pkmn,battler,scene,showMessages)
    if ret && pkmn.hypermode &&
       !isConst?(item,PBItems,:JOYSCENT) &&
       !isConst?(item,PBItems,:EXCITESCENT) &&
       !isConst?(item,PBItems,:VIVIDSCENT)
      scene.pbDisplay(_INTL("This item can't be used on that Pokémon."))
      return false
    end
    return ret
  end
end



class PokeBattle_Battler
  alias __shadow__pbInitPokemon pbInitPokemon

  def pbInitPokemon(*arg)
    if self.pokemonIndex>0 && inHyperMode?
      # Called out of Hyper Mode
      self.pokemon.hypermode = false
      self.pokemon.adjustHeart(-50)
    end
    __shadow__pbInitPokemon(*arg)
    # Called into battle
    if shadowPokemon?
      if hasConst?(PBTypes,:SHADOW)
        self.type1 = getID(PBTypes,:SHADOW)
        self.type2 = getID(PBTypes,:SHADOW)
      end
      self.pokemon.adjustHeart(-30) if pbOwnedByPlayer?
    end
  end

  def shadowPokemon?
    p = self.pokemon
    return p && p.respond_to?("shadowPokemon?") && p.shadowPokemon?
  end
  alias isShadow? shadowPokemon?

  def inHyperMode?
    return false if fainted?
    p = self.pokemon
    return p && p.respond_to?("hypermode") && p.hypermode
  end

  def pbHyperMode
    return if fainted? || !shadowPokemon? || inHyperMode?
    p = self.pokemon
    if @battle.pbRandom(p.heartgauge)<=PokeBattle_Pokemon::HEARTGAUGESIZE/4
      p.hypermode = true
      @battle.pbDisplay(_INTL("{1}'s emotions rose to a fever pitch!\nIt entered Hyper Mode!",self.pbThis))
    end
  end

  def pbHyperModeObedience(move)
    return true if !inHyperMode?
    return true if !move || isConst?(move.type,PBTypes,:SHADOW)
    return rand(100)<20
  end
end



#===============================================================================
# Shadow item effects.
#===============================================================================
def pbRaiseHappinessAndReduceHeart(pokemon,scene,amount)
  if !pokemon.shadowPokemon?
    scene.pbDisplay(_INTL("It won't have any effect."))
    return false
  end
  if pokemon.happiness==255 && pokemon.heartgauge==0
    scene.pbDisplay(_INTL("It won't have any effect."))
    return false
  elsif pokemon.happiness==255
    pokemon.adjustHeart(-amount)
    scene.pbDisplay(_INTL("{1} adores you!\nThe door to its heart opened a little.",pokemon.name))
    pbReadyToPurify(pokemon)
    return true
  elsif pokemon.heartgauge==0
    pokemon.changeHappiness("vitamin")
    scene.pbDisplay(_INTL("{1} turned friendly.",pokemon.name))
    return true
  else
    pokemon.changeHappiness("vitamin")
    pokemon.adjustHeart(-amount)
    scene.pbDisplay(_INTL("{1} turned friendly.\nThe door to its heart opened a little.",pokemon.name))
    pbReadyToPurify(pokemon)
    return true
  end
end

#===============================================================================
# No additional effect. (Shadow Blast, Shadow Blitz, Shadow Break, Shadow Rave,
# Shadow Rush, Shadow Wave)
#===============================================================================
class PokeBattle_Move_126 < PokeBattle_Move_000
end



#===============================================================================
# Paralyzes the target. (Shadow Bolt)
#===============================================================================
class PokeBattle_Move_127 < PokeBattle_Move_007
end



#===============================================================================
# Burns the target. (Shadow Fire)
#===============================================================================
class PokeBattle_Move_128 < PokeBattle_Move_00A
end



#===============================================================================
# Freezes the target. (Shadow Chill)
#===============================================================================
class PokeBattle_Move_129 < PokeBattle_Move_00C
end



#===============================================================================
# Confuses the target. (Shadow Panic)
#===============================================================================
class PokeBattle_Move_12A < PokeBattle_Move_013
end



#===============================================================================
# Decreases the target's Defense by 2 stages. (Shadow Down)
#===============================================================================
class PokeBattle_Move_12B < PokeBattle_Move_04C
end



#===============================================================================
# Decreases the target's evasion by 2 stages. (Shadow Mist)
#===============================================================================
class PokeBattle_Move_12C < PokeBattle_TargetStatDownMove
  def initialize(battle,move)
    super
    @statDown = [PBStats::EVASION,2]
  end
end



#===============================================================================
# Power is doubled if the target is using Dive. (Shadow Storm)
#===============================================================================
class PokeBattle_Move_12D < PokeBattle_Move_075
end



#===============================================================================
# Two turn attack. On first turn, halves the HP of all active Pokémon.
# Skips second turn (if successful). (Shadow Half)
#===============================================================================
class PokeBattle_Move_12E < PokeBattle_Move
  def pbMoveFailed?(user,targets)
    failed = true
    @battle.eachBattler do |b|
      next if b.hp==1
      failed = false
      break
    end
    if failed
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end

  def pbEffectGeneral(user)
    @battle.eachBattler do |b|
      next if b.hp==1
      b.pbReduceHP(b.hp/2,false)
    end
    @battle.pbDisplay(_INTL("Each Pokémon's HP was halved!"))
    @battle.eachBattler { |b| b.pbItemHPHealCheck }
    user.effects[PBEffects::HyperBeam] = 2
    user.currentMove = @id
  end
end



#===============================================================================
# Target can no longer switch out or flee, as long as the user remains active.
# (Shadow Hold)
#===============================================================================
class PokeBattle_Move_12F < PokeBattle_Move_0EF
end



#===============================================================================
# User takes recoil damage equal to 1/2 of its current HP. (Shadow End)
#===============================================================================
class PokeBattle_Move_130 < PokeBattle_RecoilMove
  def pbRecoilDamage(user,target)
    return (target.damageState.totalHPLost/2.0).round
  end

  def pbEffectAfterAllHits(user,target)
    return if user.fainted? || target.damageState.unaffected
    # NOTE: This move's recoil is not prevented by Rock Head/Magic Guard.
    amt = pbRecoilDamage(user,target)
    amt = 1 if amt<1
    user.pbReduceHP(amt,false)
    @battle.pbDisplay(_INTL("{1} is damaged by recoil!",user.pbThis))
    user.pbItemHPHealCheck
  end
end



#===============================================================================
# Starts shadow weather. (Shadow Sky)
#===============================================================================
class PokeBattle_Move_131 < PokeBattle_WeatherMove
  def initialize(battle,move)
    super
    @weatherType = PBWeather::ShadowSky
  end
end



#===============================================================================
# Ends the effects of Light Screen, Reflect and Safeguard on both sides.
# (Shadow Shed)
#===============================================================================
class PokeBattle_Move_132 < PokeBattle_Move
  def pbEffectGeneral(user)
    for i in @battle.sides
      i.effects[PBEffects::AuroraVeil]  = 0
      i.effects[PBEffects::Reflect]     = 0
      i.effects[PBEffects::LightScreen] = 0
      i.effects[PBEffects::Safeguard]   = 0
    end
    @battle.pbDisplay(_INTL("It broke all barriers!"))
  end
end



#===============================================================================
#
#===============================================================================
class PokemonTemp
  attr_accessor :heartgauges
end



Events.onStartBattle += proc { |_sender|
  # Record current heart gauges of Pokémon in party, to see if they drop to zero
  # during battle and need to say they're ready to be purified afterwards
  $PokemonTemp.heartgauges = []
  for i in 0...$Trainer.party.length
    $PokemonTemp.heartgauges[i] = $Trainer.party[i].heartgauge
  end
}

Events.onEndBattle += proc { |_sender,_e|
  for i in 0...$PokemonTemp.heartgauges.length
    pokemon = $Trainer.party[i]
    if pokemon && $PokemonTemp.heartgauges[i] &&
       $PokemonTemp.heartgauges[i]!=0 && pokemon.heartgauge==0
      pbReadyToPurify(pokemon)
    end
  end
}

Events.onStepTaken += proc {
  for pkmn in $Trainer.ablePokemonParty
    if pkmn.heartgauge>0
      pkmn.adjustHeart(-1)
      pbReadyToPurify(pkmn) if pkmn.heartgauge==0
    end
  end
  if ($PokemonGlobal.purifyChamber rescue nil)
    $PokemonGlobal.purifyChamber.update
  end
  for i in 0...2
    pkmn = $PokemonGlobal.daycare[i][0]
    next if !pkmn
    pkmn.adjustHeart(-1)
    pkmn.pbUpdateShadowMoves
  end
}
