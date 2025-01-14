#===============================================================================
#  Nuzlocke functionality for vanilla Essentials
#-------------------------------------------------------------------------------
#  creates a Nuzlocke Game Mode complete with all the proper rules
#===============================================================================
module Nuzlocke
  @@nuzlocke = false
  @@rules = []
  #-----------------------------------------------------------------------------
  #  check if nuzlocke is on
  #-----------------------------------------------------------------------------
  def self.running?
    return $PokemonGlobal && $PokemonGlobal.isNuzlocke
  end
  def self.on?
    return self.running? && @@nuzlocke
  end
  #-----------------------------------------------------------------------------
  #  toggle nuzlocke state
  #-----------------------------------------------------------------------------
  def self.toggle(force = nil)
    @@nuzlocke = force.nil? ? !@@nuzlocke : force
  end
  #-----------------------------------------------------------------------------
  #  get nuzlocke rules
  #-----------------------------------------------------------------------------
  def self.rules; return @@rules; end
  def self.set_rules(rules); @@rules = rules; end
  #-----------------------------------------------------------------------------
  #  recurring function to get the very first species in the evolutionary line
  #-----------------------------------------------------------------------------
  def self.getFirstEvo(species)
    prev = pbGetPreviousForm(species)
    return species if prev == species
    return self.getFirstEvo(prev)
  end
  #-----------------------------------------------------------------------------
  #  recurring function to get every evolution after defined species
  #-----------------------------------------------------------------------------
  def self.getNextEvos(species)
    evo = pbGetEvolvedFormData(species); all = []
    return [species] if evo.length < 1
    for arr in evo
      all += [arr[2]]
      all += self.getNextEvos(arr[2])
    end
    return all.uniq
  end
  #-----------------------------------------------------------------------------
  #  function to get all species inside an evolutionary line
  #-----------------------------------------------------------------------------
  def self.getEvolutionaryLine(species)
    species = self.getFirstEvo(species)
    return [species] + self.getNextEvos(species)
  end
  #-----------------------------------------------------------------------------
  #  checks if an evo line has been caught so far
  #-----------------------------------------------------------------------------
  def self.checkEvoNuzlocke?(species)
    return false if !$PokemonGlobal || !$PokemonGlobal.nuzlockeData
    for poke in self.getEvolutionaryLine(species)
      return true if $Trainer.owned?(poke)
    end
    return false
  end
  #-----------------------------------------------------------------------------
  #  starts nuzlocke mode
  #-----------------------------------------------------------------------------
  def self.start(skip = false)
    ret = $PokemonGlobal && $PokemonGlobal.isNuzlocke
    ret = self.selection unless skip
    $PokemonGlobal.qNuzlocke = ret
    # sets the nuzlocke to true if already has a bag and Pokeballs
    if !$PokemonBag
      for i in 1..PBItems.maxValue
        if pbIsPokeBall?(i) && $PokemonBag && $PokemonBag.pbHasItem?(i)
          @@nuzlocke = ret
          $PokemonGlobal.isNuzlocke = ret
          break
        end
      end
    end
    # creates global variable
    $PokemonGlobal.nuzlockeData = {} if $PokemonGlobal.nuzlockeData.nil?
    $PokemonGlobal.nuzlockeShiny = {} if $PokemonGlobal.nuzlockeShiny.nil?
  end
  #-----------------------------------------------------------------------------
  #  clear the randomizer content
  #-----------------------------------------------------------------------------
  def self.reset
    @@nuzlocke = false
    if $PokemonGlobal
      $PokemonGlobal.qNuzlocke = nil
      $PokemonGlobal.nuzlockeData = nil
      $PokemonGlobal.nuzlockeShiny = nil
      $PokemonGlobal.isNuzlocke = nil
      $PokemonGlobal.nuzlockeRules = nil
    end
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  adding nuzlocke functionality to battler specific classes
#===============================================================================
class PokeBattle_Pokemon
  def permaFaint
    @permaFaint = false if !@permaFaint
    return @permaFaint
  end
  #-----------------------------------------------------------------------------
  #  modifies returned HP
  #-----------------------------------------------------------------------------
  alias hpget_nuzlocke_x hp unless method_defined?(:hpget_nuzlocke_x)
  def hp
    return (@permaFaint && Nuzlocke.on?) ? 0 : hpget_nuzlocke_x
  end
  #-----------------------------------------------------------------------------
  #  if HP falls to (or below 0) permanent faint is in effect
  #-----------------------------------------------------------------------------
  alias hpset_nuzlocke_x hp= unless method_defined?(:hpset_nuzlocke_x)
  def hp=(val)
    data = Nuzlocke.rules; data = [] if data.nil?
    @permaFaint = true if Nuzlocke.on? && data.include?(:NOREVIVE) && val <= 0
    hpset_nuzlocke_x((@permaFaint && Nuzlocke.on?) ? 0 : val)
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  registers battler for map if fainted in battle
#===============================================================================
class PokeBattle_Scene
  attr_accessor :firstFainted
  #-----------------------------------------------------------------------------
  #  registers defeated battler on map
  #-----------------------------------------------------------------------------
  alias pbFaintBattler_nuzlocke_x pbFaintBattler unless method_defined?(:pbFaintBattler_nuzlocke_x)
  def pbFaintBattler(battler)
  data = Nuzlocke.rules; data = [] if data.nil?
    if battler.opposes? && !self.firstFainted && @battle.wildBattle?
      if Nuzlocke.on? && data.include?(:ONEROUTE)
        evo      = Nuzlocke.checkEvoNuzlocke?(battler.pokemon.species) && data.include?(:DUPSCLAUSE)
        static   = data.include?(:STATIC) && !$PokemonTemp.nonStaticEncounter
        shiny    = battler.shiny? || battler.shadowPokemon?
        enc_type = {
            :BASE   => !static && !evo && !shiny,
            :SHINY_OR_SHADOW  => !static && shiny && !evo,
            :STATIC => static && !evo && !shiny
        }
        $PokemonGlobal.nuzlockeData[$game_map.map_id] = {} if !$PokemonGlobal.nuzlockeData[$game_map.map_id]
        enc_type.each do |type, value|
          map = $PokemonGlobal.nuzlockeData[$game_map.map_id][type]
          $PokemonGlobal.nuzlockeData[$game_map.map_id][type] = true if map.nil? && value
        end
      end
      self.firstFainted = true
    end
    # returns original function
    return pbFaintBattler_nuzlocke_x(battler)
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  adding nuzlocke functionality to delete fainted battlers from party
#  (applied after battle is finished)
#===============================================================================
class PokeBattle_Battle
  #-----------------------------------------------------------------------------
  #  allows for the catching of only one Pokemon per route
  #-----------------------------------------------------------------------------
  alias pbThrowPokeBall_nuzlocke_x pbThrowPokeBall unless method_defined?(:pbThrowPokeBall_nuzlocke_x)
  def pbThrowPokeBall(*args)
    old_caught_length = @caughtPokemon.length
    battler = @battlers[args[0]]
    pokemon = battler.pokemon.clone
    # part to disable Pokeball throwing if already caught
    data = Nuzlocke.rules; data = [] if data.nil?
    if Nuzlocke.on? && data.include?(:ONEROUTE)
      evo      = Nuzlocke.checkEvoNuzlocke?(battler.pokemon.species) && data.include?(:DUPSCLAUSE)
      static   = data.include?(:STATIC) && !$PokemonTemp.nonStaticEncounter
      shiny    = battler.shiny? || battler.shadowPokemon?
      enc_type = {
          :BASE   => !static && !shiny && !evo,
          :SHINY_OR_SHADOW  => !static && shiny && !evo,
          :STATIC => static && !shiny && !evo
      }
      enc_type.each do |type, value|
        next if !$PokemonGlobal.nuzlockeData[$game_map.map_id]
        map = $PokemonGlobal.nuzlockeData[$game_map.map_id][type]
        next if !map || !value
        message = _INTL("Nuzlocke rules prevent you from catching a Pokémon on a map you already had an encounter on!")
        message = _INTL("Nuzlocke rules prevent you from catching a Pokémon on a map you already had a #{type.to_s.gsub("_", " ").downcase} encounter on!") if type != :BASE
        return pbDisplay(message)
      end
    end
    ret = pbThrowPokeBall_nuzlocke_x(*args)
    # part that registers caught Pokemon for map
    if Nuzlocke.on? && data.include?(:ONEROUTE) && old_caught_length != @caughtPokemon.length
      evo      = Nuzlocke.checkEvoNuzlocke?(pokemon.species) && data.include?(:DUPSCLAUSE)
      static   = data.include?(:STATIC) && !$PokemonTemp.nonStaticEncounter
      shiny    = (pokemon.shiny? || pokemon.shadowPokemon?)
      enc_type = {
          :BASE   => !static && !evo && !shiny,
          :SHINY_OR_SHADOW  => !static && shiny && !evo,
          :STATIC => static && !evo && !shiny
      }
      $PokemonGlobal.nuzlockeData[$game_map.map_id] = {} if !$PokemonGlobal.nuzlockeData[$game_map.map_id]
      enc_type.each do |type, value|
        map = $PokemonGlobal.nuzlockeData[$game_map.map_id][type]
        $PokemonGlobal.nuzlockeData[$game_map.map_id][type] = true if map.nil? && value
      end
    end
    return ret
  end
  #-----------------------------------------------------------------------------
  #  registers Pokemon for nuzlocke map when fleeing
  #-----------------------------------------------------------------------------
  alias pbRun_nuzlocke_x pbRun unless method_defined?(:pbRun_nuzlocke_x)
  def pbRun(*args)
    data = Nuzlocke.rules; data = [] if data.nil?
    battler = nil
    eachOtherSideBattler { |b| battler = b; break }
    if Nuzlocke.on? && data.include?(:ONEROUTE) && wildBattle?
      evo      = Nuzlocke.checkEvoNuzlocke?(battler.pokemon.species) && data.include?(:DUPSCLAUSE)
      static   = data.include?(:STATIC) && !$PokemonTemp.nonStaticEncounter
      shiny    = battler.shiny? || battler.shadowPokemon?
      enc_type = {
          :BASE   => !static && !evo && !shiny,
          :SHINY_OR_SHADOW  => !static && shiny && !evo,
          :STATIC => static && !evo && !shiny
      }
      $PokemonGlobal.nuzlockeData[$game_map.map_id] = {} if !$PokemonGlobal.nuzlockeData[$game_map.map_id]
      enc_type.each do |type, value|
        map = $PokemonGlobal.nuzlockeData[$game_map.map_id][type]
        $PokemonGlobal.nuzlockeData[$game_map.map_id][type] = true if map.nil? && value
      end
    end
    # returns original function
    return pbRun_nuzlocke_x(*args)
  end
  #-----------------------------------------------------------------------------
end
#===============================================================================
#  losing the nuzlocke
#===============================================================================
alias pbStartOver_nuzlocke_x pbStartOver unless defined?(pbStartOver_nuzlocke_x)
def pbStartOver(*args)
  if Nuzlocke.on?
    resume = false
    pbEachPokemon do |pkmn|
      next if !pkmn.able?
      resume = true
      break
    end
    data = Nuzlocke.rules; data = [] if data.nil?
    if resume && !data.include?(:NOWHITEOUT)
      while pbAllFainted
        pbMessage(_INTL("\\w[]\\wm\\l[3]All your Pokémon have fainted. But you still have Pokémon on Sukiro's Island with which you can continue the challenge."))
        pbFadeOutIn {
          scene = PokemonStorageScene.new
          screen = PokemonStorageScreen.new(scene, $PokemonStorage)
          screen.pbStartScreen(1)
        }
      end
    else
      pbMessage(_INTL("\\w[]\\wm\\l[3]All your Pokémon have fainted. You have lost the Nuzlocke challenge! Nuzlocke Mode will now be turned off."))
      Nuzlocke.toggle(false)
      $PokemonGlobal.isNuzlocke = false
    end
  end
  return pbStartOver_nuzlocke_x(*args)
end
#===============================================================================
#  additional entry to Global Metadata for randomized data storage
#===============================================================================
class PokemonGlobalMetadata
  attr_accessor :qNuzlocke
  attr_accessor :nuzlockeData
  attr_accessor :nuzlockeShiny
  attr_accessor :isNuzlocke
  attr_accessor :nuzlockeRules
end
#===============================================================================
#  starts nuzlocke only after obtaining a Pokeball
#===============================================================================
class PokemonBag
  alias pbStoreItem_nuzlocke_x pbStoreItem unless method_defined?(:pbStoreItem_nuzlocke_x)
  def pbStoreItem(*args)
    ret = pbStoreItem_nuzlocke_x(*args)
    item = args[0]
    if $PokemonGlobal && $PokemonGlobal.qNuzlocke && pbIsPokeBall?(item)
      Nuzlocke.toggle(true)
      Nuzlocke.set_rules($PokemonGlobal.nuzlockeRules) if !$PokemonGlobal.nuzlockeRules.nil?
      $PokemonGlobal.qNuzlocke = false
      $PokemonGlobal.isNuzlocke = true
      pbMessage(_INTL("Your Nuzlocke has begun!"))
    end
    return ret
  end
end
#===============================================================================
#  refresh cache on load
#===============================================================================
class PokemonLoadScreen
  alias pbStartLoadScreen_nuzlocke_x pbStartLoadScreen unless method_defined?(:pbStartLoadScreen_nuzlocke_x)
  def pbStartLoadScreen
    ret = pbStartLoadScreen_nuzlocke_x
    if $PokemonGlobal && $PokemonGlobal.isNuzlocke
      Nuzlocke.toggle(true)
      Nuzlocke.set_rules($PokemonGlobal.nuzlockeRules) if !$PokemonGlobal.nuzlockeRules.nil?
    end
    return ret
  end
end
#===============================================================================
#  force nicknames
#===============================================================================
def pbEnterPokemonName(helptext,minlength,maxlength,initialText="",pokemon=nil,nofadeout=false)
  data = Nuzlocke.rules; data = [] if data.nil?
  ret  = ""
  loop do
    ret = pbEnterText(helptext,minlength,maxlength,initialText,2,pokemon,nofadeout)
    break if $DEBUG
    break if !Nuzlocke.on? || !data.include?(:NICKNAME)
    speciesname = pokemon.nil? ? initialText : pokemon.speciesName
    break if !nil_or_empty?(ret) && ret.downcase != speciesname.downcase
    pbMessage(_INTL("Nuzlocke rules make it mandatory to nickname your Pokémon!"))
  end
  return ret
end


#===============================================================================
#  Cannot buy medicinal items from the store
#===============================================================================
def pbIsMedicine?(item)
  ret = pbGetItemData(item, ITEM_BATTLE_USE)
  return [1, 2, 6, 7].include?(ret) && !pbIsBerry?(item)
end

class PokemonMartScreen
  def pbBuyScreen
    @scene.pbStartBuyScene(@stock,@adapter)
    item=0
    loop do
      item=@scene.pbChooseBuyItem
      quantity=0
      break if item==0
      itemname=@adapter.getDisplayName(item)
      price=@adapter.getPrice(item)
      if @adapter.getMoney<price
        pbDisplayPaused(_INTL("You don't have enough money."))
        next
      end
      data = Nuzlocke.rules; data = [] if data.nil?
      if pbIsMedicine?(item) && Nuzlocke.on? && data.include?(:NOSTORE)
        pbDisplayPaused(_INTL("Nuzlocke rules prevent you from purchasing medicinal items from Marts."))
        next
      end
      if pbIsImportantItem?(item)
        if !pbConfirm(_INTL("Certainly. You want {1}. That will be ${2}. OK?",
           itemname,price.to_s_formatted))
          next
        end
        quantity=1
      else
        maxafford=(price<=0) ? BAG_MAX_PER_SLOT : @adapter.getMoney/price
        maxafford=BAG_MAX_PER_SLOT if maxafford>BAG_MAX_PER_SLOT
        quantity=@scene.pbChooseNumber(
           _INTL("{1}? Certainly. How many would you like?",itemname),item,maxafford)
        next if quantity==0
        price*=quantity
        if !pbConfirm(_INTL("{1}, and you want {2}. That will be ${3}. OK?",
           itemname,quantity,price.to_s_formatted))
          next
        end
      end
      if @adapter.getMoney<price
        pbDisplayPaused(_INTL("You don't have enough money."))
        next
      end
      added=0
      quantity.times do
        if !@adapter.addItem(item)
          break
        end
        added+=1
      end
      if added!=quantity
        added.times do
          if !@adapter.removeItem(item)
            raise _INTL("Failed to delete stored items")
          end
        end
        pbDisplayPaused(_INTL("You have no more room in the Bag."))
      else
        @adapter.setMoney(@adapter.getMoney-price)
        for i in 0...@stock.length
          if pbIsImportantItem?(@stock[i]) && $PokemonBag.pbHasItem?(@stock[i])
            @stock[i]=nil
          end
        end
        @stock.compact!
        pbDisplayPaused(_INTL("Here you are! Thank you!")) { pbSEPlay("Mart buy item") }
        if $PokemonBag
          if quantity>=10 && pbIsPokeBall?(item) && hasConst?(PBItems,:PREMIERBALL)
            if @adapter.addItem(getConst(PBItems,:PREMIERBALL))
              pbDisplayPaused(_INTL("I'll throw in a Premier Ball, too."))
            end
          end
        end
      end
    end
    @scene.pbEndBuyScene
  end
end
