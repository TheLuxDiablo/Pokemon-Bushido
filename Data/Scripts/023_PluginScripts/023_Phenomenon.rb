#-------------------------------------------------------------------------------
# Phenomenon: BW Style Grass Rustle, Water Drops, Cave Dust & Flying Birds
# v2.0 by Boonzeet
# With code help from Maruno & Marin
# Grass graphic by DaSpirit
#-------------------------------------------------------------------------------
# Please give credit when using.
#-------------------------------------------------------------------------------
# Changes in this version:
# - Complete rewrite for performance
# - Only counters are changed on step, no calculations performed until counter
#   ticks over
# - Phenomenon checks turn off when entering a map without phenomena
#-------------------------------------------------------------------------------

PluginManager.register({
  :name => "Phenomenon",
  :version => "2.0",
  :credits => ["Boonzeet","Maruno","Marin", "DaSpirit"],
  :link => "https://reliccastle.com/resources/356/"
})

#-------------------------------------------------------------------------------
# EncounterTypes
#-------------------------------------------------------------------------------
module EncounterTypes
  ph_enclen = EncounterTypes::Names.size
  PhenomenonGrass = ph_enclen
  PhenomenonWater = ph_enclen+1
  PhenomenonCave = ph_enclen+2
  PhenomenonBird = ph_enclen+3
  Names.push("PhenomenonGrass","PhenomenonWater","PhenomenonCave","PhenomenonBird")
  EnctypeChances.push([50, 20, 10, 5, 5, 5, 5],[50, 20, 10, 5, 5, 5, 5],[50, 30, 10, 5, 5],[50, 30, 10, 5, 5])
  EnctypeDensities.push(100,100,100,100)
  EnctypeCompileDens.push(1,1,1,1)
end

#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------

module PhenomenonConfig
  Frequency = 400 # Chance for phenomenon to generate on step. Between 350-600.
  Timer = 800 # How many frames to wait before phenomenon disappears
  Switch = 77 # Switch that when ON enables phenomena

  Pokemon = {
    :shiny => true, # 4x chance of shininess
    :expBoost => true, # 1.3x Exp Boost
    # Below are 1/n chance of Pokémon being generated with these settings
    # Set to -1 to disable
    :ivs => 10, # 2 perfect IVs
    :eggMoves => 1, # A random egg move
    :hiddenAbility => -1 # Generated with hidden ability
  }

  Types = {
# Animation ID, sound, animation height (1 above player 0 below), encounter type
    :grass => [57, "phenomenon_grass", 1, EncounterTypes::PhenomenonGrass],
    :water => [58, "phenomenon_water", 0, EncounterTypes::PhenomenonWater],
    :cave => [59,  "phenomenon_cave", 1, EncounterTypes::PhenomenonCave],
    :bird => [60, "phenomenon_bird", 0, EncounterTypes::PhenomenonBird]
  }

  BattleMusic = "" # Custom music to play during Phenomenon
  BirdTerrainTag = 18 # Terrain tag for Bird encounters. Important! This is
                      # to prevent encounters appearing in inaccessible spots
  Items = {
    # 80% chance of appearing in dust
    :commonCave => [:FIREGEM, :WATERGEM, :ICEGEM, :ELECTRICGEM, :GRASSGEM, :FIGHTINGGEM,
                    :POISONGEM, :GROUNDGEM, :FLYINGGEM, :PSYCHICGEM, :BUGGEM, :ROCKGEM,
                    :GHOSTGEM, :DRAGONGEM, :DARKGEM, :STEELGEM, :NORMALGEM, :REDSHARD,
                    :BLUESHARD, :YELLOWSHARD, :GREENSHARD],
    # 10% chance
    :rareCave => [:THUNDERSTONE, :WATERSTONE, :LEAFSTONE, :MOONSTONE, :FIRESTONE,
                  :SUNSTONE, :SHINYSTONE, :DUSKSTONE, :DAWNSTONE, :EVERSTONE, :OVALSTONE],
    :bird => [:HEALTHWING, :RESISTWING, :CLEVERWING, :PRETTYWING, :MUSCLEWING, :GENIUSWING, :SWIFTWING]
  }
end

#===============================================================================
# Main code
#-------------------------------------------------------------------------------
# Support can't be provided for edits made below this line.
#===============================================================================

module PBTerrain
  BirdBridge = PhenomenonConfig::BirdTerrainTag
end

class PokemonTemp
  attr_accessor :phenomenon   # [x,y,type,timer]
  attr_accessor :phenomenonPossible # bool
end

class Array # Add quick random array fetch - by Marin
  def random
    return self[rand(self.size)]
  end
end

class Phenomenon
  attr_accessor :timer # number
  attr_accessor :x
  attr_accessor :y
  attr_accessor :type # symbol
  attr_accessor :active # bool
  attr_accessor :drawing # bool

  def initialize(types)
    Kernel.echo("Initializing with types: #{types}")
    @x = nil
    @y = nil
    @types = types
    timer_val = PhenomenonConfig::Frequency <= 60 ? 60 : rand(PhenomenonConfig::Frequency-60)+6
    @timer = Graphics.frame_count + timer_val
    @active = false
  end

  def generate!
    Kernel.echo("Generating...\n")
    phenomenon_tiles = []   # x, y, type
    # limit range to around the player to reduce CPU load
    x_range = [[$game_player.x - 20, 0].max, [$game_player.x + 20, $game_map.width].min]
    y_range = [[$game_player.y - 20, 0].max, [$game_player.y + 20, $game_map.height].min]
    # list all grass tiles
    for x in x_range[0]..x_range[1]
      for y in y_range[0]..y_range[1]
        terrain_tag = $game_map.terrain_tag(x, y)
        if @types.include?(:grass) && PBTerrain.isJustGrass?(terrain_tag)
          phenomenon_tiles.push([x, y, :grass])
        end
        if @types.include?(:water) && PBTerrain.isJustWater?(terrain_tag) && !PBTerrain.isDeepWater?(terrain_tag)
          phenomenon_tiles.push([x, y, :water])
        end
        if @types.include?(:cave) && terrain_tag == PBTerrain::Rock
          if $game_player.passable?(x,y,0)
            phenomenon_tiles.push([x, y, :cave])
          end
        end
        if @types.include?(:bird) && (!defined?(PhenomenonConfig::BirdTerrainTag) || PhenomenonConfig::BirdTerrainTag == -1 ||
          terrain_tag == PBTerrain::BirdBridge) && $MapFactory.isPassable?($game_map.map_id, x, y)
          phenomenon_tiles.push([x, y, :bird])
        end
      end
    end
    if phenomenon_tiles.length == 0
      Kernel.echo("No phenomenon tiles available!!!\n\n")
      pbPhenomenonCancel
    else
      selected_tile = phenomenon_tiles.random
      @x = selected_tile[0]
      @y = selected_tile[1]
      @type = selected_tile[2]
      @timer = Graphics.frame_count + (PhenomenonConfig::Timer*2)
      @active = true
    end
  end

  def activate!
    Kernel.echo("Activating!...\n")
    encounter = nil
    item = nil
    chance = rand(10)
    # Different types have different effects, e.g. items in caves
    case @type
    when :grass
      encounter = $PokemonEncounters.pbEncounteredPokemon(PhenomenonConfig::Types[:grass][3])
    when :water
      encounter = $PokemonEncounters.pbEncounteredPokemon(PhenomenonConfig::Types[:water][3])
    when :cave
      if chance >= 5
        encounter = $PokemonEncounters.pbEncounteredPokemon(PhenomenonConfig::Types[:cave][3])
      else
        item = chance > 0 ? PhenomenonConfig::Items[:commonCave].random : PhenomenonConfig::Items[:rareCave].random
      end
    when :bird
      if chance >= 8
        encounter = $PokemonEncounters.pbEncounteredPokemon(PhenomenonConfig::Types[:bird][3])
      else
        item = chance > 0 ? PhenomenonConfig::Items[:bird].random : :PRETTYWING
      end
    end
    if encounter != nil
      if PhenomenonConfig::BattleMusic != "" && FileTest.audio_exist?("Audio/BGM/#{PHENOMENON_BATTLE_MUSIC}")
        $PokemonGlobal.nextBattleBGM = PhenomenonConfig::BattleMusic
      end
      $PokemonTemp.forceSingleBattle = true
      pbWildBattle(encounter[0], encounter[1])
    elsif item != nil
      pbPhenomenonCancel
      Kernel.pbReceiveItem(item)
    end
  end

  def drawAnim(sound)
    Kernel.echo("Drawing animation\n")
    dist = (((@x - $game_player.x).abs + (@y - $game_player.y).abs) / 4).floor
    if dist <= 6 && dist >= 0
      animation = PhenomenonConfig::Types[@type]
      $scene.spriteset.addUserAnimation(animation[0], @x, @y, true, animation[2])
      level = [75, 65, 55, 40, 27, 22, 15][dist]
      pbSEPlay(animation[1], level) if sound
    end
    pbWait(1)
    @drawing = false
  end
end

# Cancels the phenomenon
def pbPhenomenonCancel
  $PokemonTemp.phenomenon = nil
end

def pbPhenomenonLoadTypes
  types = []
  PhenomenonConfig::Types.each do |(key, value)|
    Kernel.echo("Testing map #{$game_map.map_id}, against #{key}, with value #{value}...\n")
    Kernel.echo("ERROR: No encounters setup!\n\n") if !$PokemonEncounters
    types.push(key) if $PokemonEncounters && $PokemonEncounters.pbMapHasEncounter?($game_map.map_id, value[3])
  end
  $PokemonTemp.phenomenonPossible = types.size > 0
  $PokemonTemp.phenomenonTypes = types
end

def pbPhenomenonInactive?
  return defined?($PokemonTemp.phenomenon) && $PokemonTemp.phenomenon != nil && !$PokemonTemp.phenomenon.active
end

# Returns true if an existing phenomenon has been set up and exists
def pbPhenomenonActive?
  return defined?($PokemonTemp.phenomenon) && $PokemonTemp.phenomenon != nil && $PokemonTemp.phenomenon.active
end

# Returns true if there's a phenomenon and the player is on top of it
def pbPhenomenonPlayerOn?
  return pbPhenomenonActive? && ($game_player.x == $PokemonTemp.phenomenon.x && $game_player.y == $PokemonTemp.phenomenon.y)
end


################################################################################
# Event handlers
################################################################################
class PokemonTemp
  attr_accessor :phenomenonExp
  attr_accessor :phenomenonTypes
  attr_accessor :phenomenon
end

# Cancels phenomenon on battle start to stop animation during battle intro
Events.onStartBattle += proc { |sender, e|
  $PokemonTemp.phenomenonExp = true if PhenomenonConfig::Pokemon[:expBoost] && pbPhenomenonPlayerOn?
  pbPhenomenonCancel
}

Events.onEndBattle += proc { |sender, e|
  $PokemonTemp.phenomenonExp = false
}

# Generate the phenomenon or process the player standing on it
Events.onStepTaken += proc { |sender, e|
  if $PokemonTemp.phenomenonPossible
    if pbPhenomenonPlayerOn?
      $PokemonTemp.phenomenon.activate!
    elsif pbPhenomenonInactive?
      if Graphics.frame_count >= $PokemonTemp.phenomenon.timer
        $PokemonTemp.phenomenon.generate!
      end
    elsif $PokemonTemp.phenomenon == nil && $PokemonTemp.phenomenonTypes.size && (PhenomenonConfig::Switch == -1 || $game_switches[PhenomenonConfig::Switch])
      $PokemonTemp.phenomenon = Phenomenon.new($PokemonTemp.phenomenonTypes)
    end
  end
}

# Remove any phenomenon events on map change
Events.onMapChange += proc { |sender, e|
  pbPhenomenonCancel
}

# Process map available encounters on map change
Events.onMapSceneChange += proc { |sender, e|
  pbPhenomenonLoadTypes
}

# Modify the wild encounter based on the settings above
Events.onWildPokemonCreate+=proc {|sender,e|
  pokemon = e[0]
  if $PokemonTemp.phenomenonPossible && pbPhenomenonPlayerOn?
    if PhenomenonConfig::Pokemon[:shiny] # 4x the normal shiny chance
      pokemon.makeShiny if rand(65536) <= SHINYPOKEMONCHANCE*4
    end
    if PhenomenonConfig::Pokemon[:ivs]  > -1 && rand(PhenomenonConfig::Pokemon[:ivs]) == 0
      for i in 0...2 # gives a high chance of 2 perfect ivs and a low chance of 1
        pokemon.iv[rand(6)] = 31
      end
    end
    if PhenomenonConfig::Pokemon[:eggMoves]  > -1 && rand(PhenomenonConfig::Pokemon[:eggMoves]) == 0
      moves = []
      pbRgssOpen("Data/eggEmerald.dat","rb"){|f|
         f.pos=(pokemon.fSpecies-1)*8
         offset=f.fgetdw
         length=f.fgetdw
         if length>0
           f.pos=offset
           i=0; loop do break unless i<length
             moves.push(f.fgetw)
             i+=1
           end
         end
        }
      pokemon.pbLearnMove(moves.random) if moves.length > 0
    end
    if PhenomenonConfig::Pokemon[:hiddenAbility] > -1 && rand(PhenomenonConfig::Pokemon[:hiddenAbility]) == 0
      a = poke.getAbilityList
      if a != nil && a.length >= 2 && a[2] != nil && a[2][1] == 2
        pokemon.setAbility(a[2][1])
      end
    end
  end
}


################################################################################
# Class modifiers
################################################################################

class PokemonEncounters
  alias isCave_phenomenon isCave?
  def isCave? # show cave background on battle for dust clouds
    return self.hasEncounter?(PhenomenonConfig::Types[:cave][3]) || isCave_phenomenon
  end
end

class Spriteset_Map
  alias update_phenomenon update
  def update
    if $PokemonTemp.phenomenonPossible && pbPhenomenonActive? && !$game_temp.in_menu
      phn = $PokemonTemp.phenomenon
      if (PhenomenonConfig::Switch != -1 &&
        !$game_switches[PhenomenonConfig::Switch]) || Graphics.frame_count >= phn.timer
        pbPhenomenonCancel
      elsif !phn.drawing && Graphics.frame_count % 40 == 0 # play animation every 140 update ticks
        phn.drawing = true
        sound = phn.type == :grass ? (Graphics.frame_count % 80 == 0) : true
        phn.drawAnim(sound)
      end
    end
    update_phenomenon
  end
end
