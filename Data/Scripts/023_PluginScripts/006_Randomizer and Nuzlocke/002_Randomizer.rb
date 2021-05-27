#===============================================================================
#  Randomizer Functionality for vanilla Essentials
#-------------------------------------------------------------------------------
#  Randomizes compiled data instead of generating random battlers on the fly
#===============================================================================
module Randomizer
  @@randomizer = false
  @@rules = []

  #-----------------------------------------------------------------------------
  #  check if randomizer is on
  #-----------------------------------------------------------------------------
  def self.running?
    return $PokemonGlobal && $PokemonGlobal.isRandomizer
  end
  def self.on?
    return self.running? && @@randomizer
  end
  #-----------------------------------------------------------------------------
  #  get nuzlocke rules
  #-----------------------------------------------------------------------------
  def self.rules; return @@rules; end
  def self.set_rules(rules); @@rules = rules; end
  #-----------------------------------------------------------------------------
  #  toggle randomizer state
  #-----------------------------------------------------------------------------
  def self.toggle(force = nil)
    @@randomizer = force.nil? ? !@@randomizer : force
    # refresh encounter tables
    $PokemonEncounters.setup($game_map.map_id) if $PokemonEncounters
  end
  #-----------------------------------------------------------------------------
  #  randomizes compiled trainer data
  #-----------------------------------------------------------------------------
  def self.randomizeTrainers
    # loads compiled data and creates new array
    data = load_data("Data/trainers.dat")
    return if !data.is_a?(Array) # failsafe
    # iterates through each trainer
    for i in 0...data.length
      # if defined as an exclusion rule, trainer will not be randomized
      excl = Randomizer::EXCLUSIONS_TRAINERS
      if !excl.nil? && excl.is_a?(Array)
        for ent in excl
          next if !ent.is_a?(Numeric) && !hasConst?(PBTrainers, ent)
          t = ent.is_a?(Numeric) ? ent : getConst(PBTrainers, ent)
          break if data[i][0] == t
        end
        next if data[i][0] == t
      end
      # randomizes the species of each trainer party and removes move data if present
      for j in 0...data[i][3].length
        # if defined as an exclusion rule, species will not be randomized
        default = data[i][3][j][TPSPECIES]
        data[i][3][j][TPSPECIES] = self.getRandomizedPkmn(:TRAINER,default,default)
        # erases moves so they get auto-generated
        data[i][3][j][TPMOVES] = []
      end
    end
    return data
  end
  #-----------------------------------------------------------------------------
  #  randomizes map encounters
  #-----------------------------------------------------------------------------
  def self.randomizeEncounters
    # loads map encounters
    data = load_data("Data/encounters.dat")
    return if !data.is_a?(Hash) # failsafe
    # iterates through each map point
    for key in data.keys
      for i in 0...data[key][1].length
        next if data[key][1][i].nil?
        # compiles hashtable for duplicate species
        hash = {}
        for j in 0...data[key][1][i].length
          default = data[key][1][i][j][0]
          hash[data[key][1][i][j][0]] = self.getRandomizedPkmn(:ENCDATA,default,default)
        end
        # randomizes species for each specified encounter type and frequency
        for j in 0...data[key][1][i].length
          data[key][1][i][j][0] = hash[data[key][1][i][j][0]]
        end
      end
    end
    return data
  end
  #-----------------------------------------------------------------------------
  #  randomize the pokedex
  #-----------------------------------------------------------------------------
  def self.randomizeRegionalDex(extreme = false)
    if extreme
      rgdex = (1..PBSpecies.maxValue).to_a
    else
      rgdex = pbAllRegionalSpecies(2)
    end
    rgdex.delete(0)
    rgdex.compact!
    rgdex.uniq!
    finalHash = {}
    shuffledDexes = {}
    keys = [:STATIC,:GIFTS,:ENCDATA,:TRAINER]
    for key in keys
      finalHash[key] = []
      shuffledDexes[key] = rgdex.clone
      4.times {shuffledDexes[key].shuffle!}
    end
    index = 0
    excl = Randomizer::EXCLUSIONS_SPECIES.clone.map!{|s|
      getID(PBSpecies,s) if s.is_a?(Symbol)
      next s
    }
    for i in 1..PBSpecies.maxValue
      toPut = 0
      toPut = i if excl.include?(i) || !rgdex.include?(i)
      for key in keys
        incIndex =
        if toPut != 0
          finalHash[key][i] = toPut
        else
          finalHash[key][i] = shuffledDexes[key][index]
        end
      end
      index += 1 if toPut == 0
    end
    return finalHash
  end
  #-----------------------------------------------------------------------------
  #  randomizes static battles called through events
  #-----------------------------------------------------------------------------
  def self.getRandomizedPkmn(key ,data = nil, index = nil)
    array = self.getRandomizedData(nil,:DEXORDER)
    return data if !array || !array[key]
    return array[key] if !index
    return array[key][index]
  end
  #-----------------------------------------------------------------------------
  #  randomizes items received through events
  #-----------------------------------------------------------------------------
  def self.randomizeItems
    new = []
    item = 1
    # shuffles up item indexes to load a different one
    (PBItems.maxValue - 1).times do
      loop do
        item = 1 + rand(PBItems.maxValue)
        break if !pbIsKeyItem?(item)
      end
      new.push(item)
    end
    return new
  end
  #-----------------------------------------------------------------------------
  #  randomizes all movesets
  #-----------------------------------------------------------------------------
  def self.randomizeMovesets
    # shuffles up item indexes to load a different one
    new = (1..PBMoves.maxValue).to_a
    4.times {new.shuffle!}
    data = load_data("Data/species_movesets.dat").clone
    for i in 1...data.length
      moveset = data[i]
      for j in 0...moveset.length
        move = moveset[j]
        data[i][j][1] = new[move[1]]
      end
    end
    return data
  end
  #-----------------------------------------------------------------------------
  #  begins the process of randomizing all data
  #-----------------------------------------------------------------------------
  def self.randomizeData
    data = {}
    # compiles hashtable with randomized values
    randomized = {
      :TRAINERS => proc{ next Randomizer.randomizeTrainers },
      :ENCOUNTERS => proc {next Randomizer.randomizeEncounters },
      :STATIC => proc{ next Randomizer.getRandomizedPkmn(:STATIC) },
      :GIFTS => proc{ next Randomizer.getRandomizedPkmn(:GIFTS) },
      :ITEMS => proc{ next Randomizer.randomizeItems },
      :SPECIES_MOVESETS => proc{ next Randomizer.randomizeMovesets },
    }
    # applies randomized data for specified rule sets
    for key in @@rules
      data[key] = randomized[key].call if randomized.has_key?(key)
    end
    # return randomized data
    return data
  end
  #-----------------------------------------------------------------------------
  #  returns randomized data for specific entry
  #-----------------------------------------------------------------------------
  def self.getRandomizedData(data, symbol, index = nil)
    return data if !self.on?
    if $PokemonGlobal && $PokemonGlobal.randomizedData && $PokemonGlobal.randomizedData.has_key?(symbol)
      return $PokemonGlobal.randomizedData[symbol][index] if !index.nil?
      return $PokemonGlobal.randomizedData[symbol]
    end
    return data
  end
  #-----------------------------------------------------------------------------
  # randomizes all data and toggles on randomizer
  #-----------------------------------------------------------------------------
  def self.start(skip = false,extreme = false)
    ret = $PokemonGlobal && $PokemonGlobal.isRandomizer
    ret, cmd = self.randomizerSelection unless skip
    @@randomizer = ret
    $PokemonGlobal.isRandomizer = ret
    # randomize data and cache it
    if !$PokemonGlobal.randomizedData
      rand_dex =  Randomizer.randomizeRegionalDex(extreme)
      $PokemonGlobal.randomizedData = {}
      $PokemonGlobal.randomizedData[:DEXORDER] = rand_dex.clone
      $PokemonGlobal.randomizedData = self.randomizeData
      $PokemonGlobal.randomizedData[:DEXORDER] = rand_dex.clone
    end
    # refresh encounter tables
    pbClearData(true)
    $PokemonEncounters.setup($game_map.map_id) if $PokemonEncounters
    # display confirmation message
    return if skip
    msg = _INTL("Your selected Randomizer rules have been applied.")
    msg = _INTL("No Randomizer rules have been applied.") if @@rules.length < 1
    msg = _INTL("Your selection has been cancelled.") if cmd < 0
    pbMessage(msg)
  end
  #-----------------------------------------------------------------------------
  #  clear the randomizer content
  #-----------------------------------------------------------------------------
  def self.reset
    @@randomizer = false
    if $PokemonGlobal
      $PokemonGlobal.randomizedData = nil
      $PokemonGlobal.isRandomizer = nil
      $PokemonGlobal.randomizerRules = nil
    end
    pbClearData(true)
    $PokemonEncounters.setup($game_map.map_id) if $PokemonEncounters
  end
  #-----------------------------------------------------------------------------
end

#-----------------------------------------------------------------------------
#  load randomized data
#-----------------------------------------------------------------------------
def pbLoadEncountersData
  $PokemonTemp = PokemonTemp.new if !$PokemonTemp
  if !$PokemonTemp.encountersData
    if pbRgssExists?("Data/encounters.dat")
      data = load_data("Data/encounters.dat")
      $PokemonTemp.encountersData = Randomizer.getRandomizedData(data, :ENCOUNTERS)
    end
  end
  return $PokemonTemp.encountersData
end

def pbLoadTrainersData
  $PokemonTemp = PokemonTemp.new if !$PokemonTemp
  if !$PokemonTemp.trainersData
    data = load_data("Data/trainers.dat") || []
    $PokemonTemp.trainersData = Randomizer.getRandomizedData(data, :TRAINERS)
  end
  return $PokemonTemp.trainersData
end

def pbLoadMovesetsData
  $PokemonTemp = PokemonTemp.new if !$PokemonTemp
  if !$PokemonTemp.speciesMovesets
    data = load_data("Data/species_movesets.dat") || []
    $PokemonTemp.speciesMovesets = Randomizer.getRandomizedData(data, :SPECIES_MOVESETS)
  end
  return $PokemonTemp.speciesMovesets
end

#===============================================================================
#  helper functions to return randomized battlers and items
#===============================================================================
def randomizeSpecies(species, static = false, gift = false)
  return species if !Randomizer.on?
  pokemon = nil
  if species.is_a?(PokeBattle_Pokemon)
    pokemon = species.clone
    species = pokemon.species
  elsif !species.is_a?(Numeric)
    species = getID(PBSpecies, species)
  end
  # randomizes static encounters
  species = Randomizer.getRandomizedPkmn(:STATIC, species, species) if static
  species = Randomizer.getRandomizedPkmn(:GIFTS, species, species) if gift
  if !pokemon.nil?
    pokemon.species = species
    pokemon.calcStats
    pokemon.resetMoves
  end
  return pokemon.nil? ? species : pokemon
end

def randomizeItem(item)
  return item if !Randomizer.on?
  item = getID(PBItems, item) unless item.is_a?(Numeric)
  return item if pbIsKeyItem?(item)
  # if defined as an exclusion rule, species will not be randomized
  excl = Randomizer::EXCLUSIONS_ITEMS
  if !excl.nil? && excl.is_a?(Array)
    for ent in excl
      i = ent.is_a?(Numeric) ? ent : getID(PBItems, ent)
      return item if item == i
    end
  end
  return Randomizer.getRandomizedData(item, :ITEMS, item)
end
#===============================================================================
#  aliasing to return randomized battlers
#===============================================================================
alias pbBattleOnStepTaken_randomizer_x pbBattleOnStepTaken unless defined?(pbBattleOnStepTaken_randomizer_x)
def pbBattleOnStepTaken(*args)
  $PokemonTemp.nonStaticEncounter = true
  pbBattleOnStepTaken_randomizer_x(*args)
  $PokemonTemp.nonStaticEncounter = false
end
#===============================================================================
#  aliasing to randomize static battles
#===============================================================================
alias pbWildBattle_randomizer_x pbWildBattle unless defined?(pbWildBattle_randomizer_x)
def pbWildBattle(*args)
  # randomizer
  for i in [0]
    ret = randomizeSpecies(args[i], !$PokemonTemp.nonStaticEncounter)
    args[i] = ret
  end
  # starts battle processing
  return pbWildBattle_randomizer_x(*args)
end

alias pbDoubleWildBattle_randomizer_x pbDoubleWildBattle unless defined?(pbDoubleWildBattle_randomizer_x)
def pbDoubleWildBattle(*args)
  # randomizer
  for i in [0, 2]
    args[i] = randomizeSpecies(args[i], !$PokemonTemp.nonStaticEncounter)
  end
  # starts battle processing
  return pbDoubleWildBattle_randomizer_x(*args)
end

alias pbTripleWildBattle_randomizer_x pbTripleWildBattle unless defined?(pbTripleWildBattle_randomizer_x)
def pbTripleWildBattle(*args)
  # randomizer
  for i in [0, 2, 4]
    args[i] = randomizeSpecies(args[i], !$PokemonTemp.nonStaticEncounter)
  end
  # starts battle processing
  return pbTripleWildBattle_randomizer_x(*args)
end
#===============================================================================
#  aliasing to randomize gifted Pokemon
#===============================================================================
alias pbAddPokemon_randomizer_x pbAddPokemon unless defined?(pbAddPokemon_randomizer_x)
def pbAddPokemon(*args)
  # randomizer
  args[0] = randomizeSpecies(args[0], false, true)
  # gives Pokemon
  return pbAddPokemon_randomizer_x(*args)
end

alias pbAddPokemonSilent_randomizer_x pbAddPokemonSilent unless defined?(pbAddPokemonSilent_randomizer_x)
def pbAddPokemonSilent(*args)
  # randomizer
  args[0] = randomizeSpecies(args[0], false, true)
  # gives Pokemon
  return pbAddPokemonSilent_randomizer_x(*args)
end
#===============================================================================
#  snipped of code used to alias the item receiving
#===============================================================================
#-----------------------------------------------------------------------------
#  item find
alias pbItemBall_randomizer_x pbItemBall unless defined?(pbItemBall_randomizer_x)
def pbItemBall(*args)
  args[0] = randomizeItem(args[0])
  return pbItemBall_randomizer_x(*args)
end
#-----------------------------------------------------------------------------
#  item receive
alias pbReceiveItem_randomizer_x pbReceiveItem unless defined?(pbReceiveItem_randomizer_x)
def pbReceiveItem(*args)
  args[0] = randomizeItem(args[0])
  return pbReceiveItem_randomizer_x(*args)
end
#===============================================================================
#  additional entry to Global Metadata for randomized data storage
#===============================================================================
class PokemonGlobalMetadata
  attr_accessor :randomizedData
  attr_accessor :isRandomizer
  attr_accessor :randomizerRules
end

#===============================================================================
#  refresh cache on load
#===============================================================================
class PokemonLoadScreen
  alias pbStartLoadScreen_randomizer_x pbStartLoadScreen unless self.method_defined?(:pbStartLoadScreen_randomizer_x)
  def pbStartLoadScreen
    ret = pbStartLoadScreen_randomizer_x
    # refresh current cache
    if $PokemonGlobal && $PokemonGlobal.isRandomizer
      Randomizer.start(true)
      Randomizer.set_rules($PokemonGlobal.randomizerRules) if !$PokemonGlobal.randomizerRules.nil?
    end
    return ret
  end
end

alias randomizer_pbReceiveMysteryGift pbReceiveMysteryGift
def pbReceiveMysteryGift(id)
  oldrandomizer = $PokemonGlobal.isRandomizer
  $PokemonGlobal.isRandomizer = false
  randomizer_pbReceiveMysteryGift(id)
  $PokemonGlobal.isRandomizer = oldrandomizer
end
