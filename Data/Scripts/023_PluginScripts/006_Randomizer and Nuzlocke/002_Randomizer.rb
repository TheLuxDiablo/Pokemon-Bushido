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
      excl = Randomizer::EXCLUDED_TRAINERS
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
    excl = Randomizer::EXCLUDED_SPECIES.clone.map!{ |s|
      next getID(PBSpecies, s) if s.is_a?(Symbol)
      next s
    }
    if extreme
      rgdex = (1..PBSpecies.maxValue).to_a
    else
      rgdex = pbAllRegionalSpecies(2)
    end
    rgdex.delete(0)
    rgdex.compact!
    rgdex.uniq!
    if !extreme
      for i in 1..PBSpecies.maxValue
        excl.push(i) if !rgdex.include?(i)
      end
    end
    excl.push(0)
    excl.uniq!
    allowed = (0..PBSpecies.maxValue).to_a
    allowed.delete_if { |s| excl.include?(s) }
    $PokemonGlobal.randomizedData[:ALLOWED_SPECIES] = allowed.clone
    shuffled_dex = {}
    keys = [:STATIC, :GIFTS, :ENCDATA, :TRAINER]
    for key in keys
      shuffled_dex[key] = (0..PBSpecies.maxValue).to_a
      4.times { shuffled_dex[key].shuffle! }
      excl.each do |pkmn|
        new_pkmn = shuffled_dex[key].index(pkmn)
        next if !new_pkmn
        shuffled_dex[key][pkmn], shuffled_dex[key][new_pkmn] = shuffled_dex[key][new_pkmn], shuffled_dex[key][pkmn]
      end
    end
    return shuffled_dex
  end
  #-----------------------------------------------------------------------------
  #  randomizes static battles called through events
  #-----------------------------------------------------------------------------
  def self.getRandomizedPkmn(key ,data = nil, index = nil)
    array = self.getRandomizedData(nil, :DEXORDER)
    return data if !array || !array[key]
    return array[key] if !index
    return array[key][index]
  end
  #-----------------------------------------------------------------------------
  #  randomizes items received through events
  #-----------------------------------------------------------------------------
  def self.randomizeItems
    # shuffles up item indexes to load a different one
    items = (0..PBItems.maxValue).to_a
    items.compact!
    items.uniq!
    4.times { items.shuffle! }
    excl = Randomizer::EXCLUDED_ITEMS.clone.map! { |s|
      next getID(PBItems, s) if s.is_a?(Symbol)
      next s
    }
    (1..PBItems.maxValue).each do |item|
      excl.push(item) if pbIsMegaStone?(item)
      excl.push(item) if pbIsKeyItem?(item)
      excl.push(item) if pbIsLeafItem?(item)
      excl.push(item) if pbIsTechnicalMachine?(item) || pbIsHiddenMachine?(item)
    end
    excl.push(0)
    excl.uniq!
    excl.each do |item|
      new_item = items.index(item)
      next if !new_item
      items[item], items[new_item] = items[new_item], items[item]
    end
    return items
  end
  #-----------------------------------------------------------------------------
  #  randomizes all abilities
  #-----------------------------------------------------------------------------
  def self.randomizeAbilities
    # shuffles up ability indexes to load a different one
    abils = (0..PBAbilities.maxValue).to_a
    abils.compact!
    abils.uniq!
    4.times { abils.shuffle! }
    excl = []
    excl.push(0)
    excl.uniq!
    excl.each do |abil|
      new_abil = abils.index(abil)
      next if !new_abil
      abils[abil], abils[new_abil] = abils[new_abil], abils[abil]
    end
    return abils
  end
  #-----------------------------------------------------------------------------
  #  randomizes all moves
  #-----------------------------------------------------------------------------
  def self.randomizeMoves
    # shuffles up move indexes to load a different one
    moves = (0..PBMoves.maxValue).to_a
    moves.compact!
    moves.uniq!
    4.times { moves.shuffle! }
    excl = Randomizer::EXCLUDED_MOVES.clone.map! { |s|
      next getID(PBMoves, s) if s.is_a?(Symbol)
      next s
    }
    (1..PBMoves.maxValue).each do |move|
      type = pbGetMoveData(move, MOVE_TYPE)
      excl.push(move) if type == getID(PBTypes, :SHADOW)
    end
    excl.push(0)
    excl.each do |move|
      new_move = moves.index(move)
      next if !new_move
      moves[move], moves[new_move] = moves[new_move], moves[move]
    end
    return moves
  end
  #-----------------------------------------------------------------------------
  #  randomizes all movesets
  #-----------------------------------------------------------------------------
  def self.randomizeMovesets
    data = load_data("Data/species_movesets.dat").clone
    for i in 1...data.length
      moveset = data[i]
      for j in 0...moveset.length
        move     = moveset[j][1]
        new_move = Randomizer.getRandomizedData(move, :MOVES, move)
        data[i][j][1] = new_move
      end
    end
    return data
  end
  #-----------------------------------------------------------------------------
  #  randomizes all movesets
  #-----------------------------------------------------------------------------
  def self.randomizeSpeciesAbilities
    data = pbLoadSpeciesData.clone
    for i in 1...data.length
      abil   = data[i][SpeciesAbilities].clone
      h_abil = data[i][SpeciesHiddenAbility].clone
      if abil.is_a?(Array)
        data[i][SpeciesAbilities] = abil.map! { |a| next Randomizer.getRandomizedData(a, :ABILITIES, a || 0) }
      else
        data[i][SpeciesAbilities] = Randomizer.getRandomizedData(abil, :ABILITIES, abil || 0)
      end
      if h_abil.is_a?(Array)
        data[i][SpeciesHiddenAbility] = h_abil.map! { |a| next Randomizer.getRandomizedData(a, :ABILITIES, a || 0) }
      else
        data[i][SpeciesHiddenAbility] = Randomizer.getRandomizedData(h_abil, :ABILITIES, h_abil || 0)
      end
    end
    $PokemonGlobal.randomizedData[:SPECIES] = data.clone
    $PokemonTemp.speciesData = nil
    return true
  end
  #-----------------------------------------------------------------------------
  #  randomizes all TM compatibility
  #-----------------------------------------------------------------------------
  def self.randomizeTMs
    tm_data = {}
    (1..PBMoves.maxValue).each do |move|
      tm_data[move] = Randomizer.getRandomizedPkmn(:STATIC).sample(PBSpecies.maxValueF)
    end
    return tm_data
  end
  #-----------------------------------------------------------------------------
  #  randomizes all Egg Moves
  #-----------------------------------------------------------------------------
  def self.randomizeEggMoves
    data = load_data("Data/species_eggmoves.dat").clone
    for i in 1...data.length
      egg_data = data[i]
      next if !egg_data
      for j in 0...egg_data.length
        move     = egg_data[j]
        new_move = Randomizer.getRandomizedData(move, :MOVES, move)
        data[i][j] = new_move
      end
    end
    return data
  end
  #-----------------------------------------------------------------------------
  #  begins the process of randomizing all data
  #-----------------------------------------------------------------------------
  def self.randomizeData(extreme)
    $PokemonGlobal.randomizedData = {}
    # compiles hashtable with randomized values
    randomized = {
      :DEXORDER   => proc { next Randomizer.randomizeRegionalDex(extreme) },
      :TRAINERS   => proc { next Randomizer.randomizeTrainers },
      :ENCOUNTERS => proc { next Randomizer.randomizeEncounters },
      :STATIC     => proc { next Randomizer.getRandomizedPkmn(:STATIC) },
      :GIFTS      => proc { next Randomizer.getRandomizedPkmn(:GIFTS) },
      :ITEMS      => proc { next Randomizer.randomizeItems },
      :MOVES      => proc { next Randomizer.randomizeMoves },
      :MOVESETS   => proc { next Randomizer.randomizeMovesets },
      :ABILITIES  => proc {
        ret = Randomizer.randomizeAbilities
        $PokemonGlobal.randomizedData[:ABILITIES] = ret
        Randomizer.randomizeSpeciesAbilities
        next ret
      },
      :TMS        => proc { next Randomizer.randomizeTMs },
      :EGGMOVES   => proc { next Randomizer.randomizeEggMoves },
    }
    # applies randomized data for specified rule sets
    for key in @@rules
      $PokemonGlobal.randomizedData[key] = randomized[key].call if randomized.has_key?(key)
    end
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
  def self.start(skip = false, extreme = false)
    ret = $PokemonGlobal && $PokemonGlobal.isRandomizer
    ret, cmd = self.randomizerSelection unless skip
    @@randomizer = ret
    $PokemonGlobal.isRandomizer = ret
    # randomize data and cache it
    self.randomizeData(extreme) if !$PokemonGlobal.randomizedData
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
    $PokemonTemp.speciesMovesets = Randomizer.getRandomizedData(data, :MOVESETS)
  end
  return $PokemonTemp.speciesMovesets
end

def pbLoadSpeciesTMData
  $PokemonTemp = PokemonTemp.new if !$PokemonTemp
  if !$PokemonTemp.speciesTMData
    data = load_data("Data/tm.dat") || []
    $PokemonTemp.speciesTMData = Randomizer.getRandomizedData(data, :TMS)
  end
  return $PokemonTemp.speciesTMData
end

def pbLoadEggMovesData
  $PokemonTemp = PokemonTemp.new if !$PokemonTemp
  if !$PokemonTemp.speciesEggMoves
    data = load_data("Data/species_eggmoves.dat") || []
    $PokemonTemp.speciesEggMoves = Randomizer.getRandomizedData(data, :EGGMOVES)
  end
  return $PokemonTemp.speciesEggMoves
end

def pbLoadSpeciesData
  $PokemonTemp = PokemonTemp.new if !$PokemonTemp
  if !$PokemonTemp.speciesData
    data = load_data("Data/species.dat") || []
    $PokemonTemp.speciesData = Randomizer.getRandomizedData(data, :SPECIES)
  end
  return $PokemonTemp.speciesData
end

alias pbGetItemData_randomizer pbGetItemData unless defined?(pbGetItemData_randomizer)
def pbGetItemData(*args)
  type = args[1]
  ret  = pbGetItemData_randomizer(*args)
  rules = Randomizer.rules || []
  if rules.include?(:TMS)
    if type < 0
      move = ret[ITEM_MACHINE]
      ret[ITEM_MACHINE] = Randomizer.getRandomizedData(move, :MOVES, move)
    elsif type == ITEM_MACHINE
      ret = Randomizer.getRandomizedData(ret, :MOVES, ret)
    end
  end
  return ret
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
    old_level = pokemon.level
    pokemon.species = species
    pokemon.calcStats
    pokemon.resetMoves
    pokemon.level = old_level
  end
  return pokemon.nil? ? species : pokemon
end

def randomizeStarter(pokemon)
  return pokemon if !Randomizer.on?
  allowed_pkmn = $PokemonGlobal.randomizedData[:ALLOWED_SPECIES]
  rand_species = allowed_pkmn.sample
  new_species = randomizeSpecies(rand_species, true)
  old_level = pokemon.level
  pokemon.species = new_species
  pokemon.calcStats
  pokemon.resetMoves
  pokemon.level = old_level
  return pokemon
end

def randomizeItem(item)
  return item if !Randomizer.on?
  item = getID(PBItems, item) unless item.is_a?(Numeric)
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

alias pbEncounter_randomizer_x pbEncounter unless defined?(pbEncounter_randomizer_x)
def pbEncounter(*args)
  $PokemonTemp.nonStaticEncounter = true
  ret = pbEncounter_randomizer_x(*args)
  $PokemonTemp.nonStaticEncounter = false
  return ret
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
  alias pbStartLoadScreen_randomizer_x pbStartLoadScreen unless method_defined?(:pbStartLoadScreen_randomizer_x)
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

alias randomizer_pbReceiveMysteryGift pbReceiveMysteryGift unless defined?(randomizer_pbReceiveMysteryGift)
def pbReceiveMysteryGift(id)
  oldrandomizer = $PokemonGlobal.isRandomizer
  $PokemonGlobal.isRandomizer = false
  randomizer_pbReceiveMysteryGift(id)
  $PokemonGlobal.isRandomizer = oldrandomizer
end
=begin
alias randomizer_pbPokemonMart pbPokemonMart unless defined?(randomizer_pbPokemonMart)
def pbPokemonMart(*args)
  args[0].each do

  end
  return randomizer_pbPokemonMart
end
=end
