#===============================================================================
#  Randomizer Functionality for vanilla Essentials
#-------------------------------------------------------------------------------
#  System settings
#===============================================================================
module Randomizer
  # list of trainers to exclude from the randomizer
  EXCLUSIONS_TRAINERS = []

  # list of species to exclude from the randomizer
  EXCLUSIONS_SPECIES = [
    :LUGIA, :HOOH, :COBALION, :TERRAKION, :VIRIZION, :ZERAORA, :LANDORUS,
    :TORNADUS, :THUNDURUS, :CELEBI
  ]

  # list of items to exclude from the randomizer (Automatically excludes Key Items)
  EXCLUSIONS_ITEMS = [
    :HM01, :HM02, :HM03, :HM04, :HM05, :HM06, :RARECANDY, :LIGHTFLUTE,
    :GALARICACUFF, :GALARICAWREATH, :POKEBALL
  ]

  # list of moves to exclude from the randomizer (Automatically excludes shadow moves)
  EXCLUSIONS_MOVES = [
    :BURNKUNAI, :SHOCKKUNAI, :POISONKUNAI, :SLEEPKUNAI
  ]
end

#===============================================================================
#  entry to store state of battle (static or non-static)
#===============================================================================
class PokemonTemp
  attr_accessor :nonStaticEncounter

  def nonStaticEncounter
    @nonStaticEncounter = false if !@nonStaticEncounter
    return @nonStaticEncounter
  end
end

#===============================================================================
#  entry to store state of battle (static or non-static)
#===============================================================================
class PokemonGlobalMetadata
  attr_accessor :gameModesWon

  def gameModesWon
    if !@gameModesWon
      @gameModesWon = []
      @gameModesWon[0] = true if $game_variables[99] > 6
    end
    return @gameModesWon
  end
end


#===============================================================================
#  UI to select game mode
#===============================================================================
def pbSelectGameMode
  vp = Viewport.new(0,0,Graphics.width,Graphics.height)
  randomizerRules = [:STATIC,:ENCOUNTERS,:GIFTS,:ITEMS]
  extremeRandomizerRules = [:STATIC,:ENCOUNTERS,:GIFTS,:ITEMS,:TRAINERS,:SPECIES_MOVESETS]
  nuzlockeRules = [:NOREVIVE, :ONEROUTE, :DUPSCLAUSE, :STATIC, :NICKNAME]
  hardcoreNuzlockeRules = [:NOREVIVE, :ONEROUTE, :NICKNAME, :NOSTORE, :NOWHITEOUT]
  modes = []
  modestrings = ["Randomizer","Extreme Randomizer","Nuzlocke","Hardcore Nuzlocke"]
  modeinfo = [
    ["These are the rules of the Randomizer Mode:",
"\\l[6]- All wild encounters are randomized
- All static encounters are randomized
- All gifted Pokemon are randomized
- All items are randomized
- Randomized Pokemon can be species from the Aisho Dex only",
"\\l[3]You can choose to turn off the Randomizer after the main story ends, but this won't un-randomize your randomized data.",
"\\l[3]You will receive a commemorative badge on your Kenshi Card upon beating the game in Randomizer Mode."],
["These are the rules of the Extreme Randomizer Mode:",
"\\l[8]- All wild encounters are randomized
- All static encounters are randomized
- All gifted Pokemon are randomized
- All items are randomized
- All Trainer Pokemon are randomized
- All Pokemon have their movesets randomized
- Randomized Pokemon can be any species from the National Dex",
"\\l[3]You can choose to turn off the Randomizer after the main story ends, but this won't un-randomize your randomized data.",
"\\l[3]You will receive a commemorative badge on your Kenshi Card upon beating the game in Extreme Randomizer Mode."],
["These are the rules of the Nuzlocke Mode:",
"\\l[8]- Fainted Pokemon cannot be revived
- You can catch one non-shiny, one shiny/shadow, and one static encounter per map
- All Pokemon that are caught, must be nicknamed
- Duplicate species are disregarded from the \"one capture per map\" rule",
"\\l[2]The challenge starts upon receiving your first Pokeball and ends upon beating the main story.",
"\\l[3]You will lose the challenge if you have no Pokemon in your Party, or on Sukiro's Islands, that are able to battle.",
"\\l[3]You will receive a commemorative badge on your Kenshi Card upon beating the game in Nuzlocke Mode."],
["These are the rules of the Hardcore Nuzlocke Mode:",
"\\l[11]- Fainted Pokemon cannot be revived
- You can catch one non-shiny and one shiny/shadow per map.
- All Pokemon that are caught, must be nicknamed
- Duplicate species are counted in the \"one capture per map\" rule
- Static encounters are counted in the \"one capture per map\" rule
- You cannot purchase any medicinal items from the marts",
"\\l[2]The challenge starts upon receiving your first Pokeball and ends upon beating the main story.",
"\\l[3]You will lose the challenge if you have no Pokemon in your Party that are able to battle. Pokemon on Sukiro's Islands do not count.",
"\\l[3]You will receive a commemorative badge on your Kenshi Card upon beating the game in Hardcore Nuzlocke Mode."]
  ]
  pbMessage("Pokémon Bushido offers built-in challenge modifiers like Nuzlocke Mode and Randomizers.")
  pbMessage("These are meant to offer unique ways to challenge the player in their playthrough.")
  pbMessage("These are only recommended if you've already played through Pokémon Bushido atleast once.")
  return false if !pbConfirmMessageSerious("Would you like to play the game with challenge modifiers?")
  infowindow = Window_AdvancedTextPokemon.newWithSize("",0,Graphics.height - 96,Graphics.width,0,vp)
  infowindow.text = _INTL("Select the modifiers of your choice.\nC: Add/Remove                                 A: More Info")
  infowindow.resizeHeightToFit(infowindow.text)
  infowindow.setSkin(MessageConfig.pbGetSystemFrame)
  cmdwindow = Window_CommandPokemonEx.new([])
  need_refresh = true
  command = 0
  defaultskin = MessageConfig.pbGetSystemFrame.gsub("Graphics/Windowskins/","")
  loop do
    if need_refresh
      commands = modestrings.clone
      commands.map!{|c| next "[#{(modes.include?(commands.index(c)))? "x" : "  "}] #{c}"}
      commands.push("Start Game")
      cmdwindow.commands = commands
      cmdwindow.resizeToFit(cmdwindow.commands)
    end
    Graphics.update
    Input.update
    cmdwindow.update
    infowindow.update
    if Input.trigger?(Input::B)
      infowindow.visible = false
      if pbConfirmMessage("\\w[#{defaultskin}]Clear current selection of modifiers and start a regular playthrough?")
        modes.clear
        modes = []
        break
      end
      infowindow.visible = true
      need_refresh = true
    elsif Input.trigger?(Input::A)
      cmdwindow.visible = false
      infowindow.visible = false
      modeinfo[cmdwindow.index].each{|m|
        pbMessage("\\w[#{defaultskin}]#{m}")
      }
      infowindow.visible = true
      cmdwindow.visible = true
      need_refresh = true
    elsif Input.trigger?(Input::C)
      command = cmdwindow.index
      if command == 4
        infowindow.visible = false
        finalmodes = modes.clone
        finalmodes.map!{|m| next modestrings[m]}
        finalmodes = finalmodes.to_s.gsub!("\"","")
        finalmodes = "" if !finalmodes
        break if pbConfirmMessage("\\w[#{defaultskin}]Would you like to start the game with #{finalmodes.length == 0 ? "no modifiers?" : "these modifiers: #{finalmodes}"}")
        infowindow.visible = true
      else
        pbPlayCursorSE
        if !modes.include?(command)
          modes.push(command)
          modes.uniq!
          modes.delete(1) if command == 0
          modes.delete(0) if command == 1
          modes.delete(3) if command == 2
          modes.delete(2) if command == 3
        else
          modes.delete(command)
          modes.uniq!
        end
      end
      need_refresh = true
    end
  end
  pbFadeOutIn(99999) {
    modes.each do |m|
      if [0,1].include?(m)
        Randomizer.reset
        $PokemonGlobal.isRandomizer = true
        $PokemonGlobal.randomizerRules = (m == 1)? extremeRandomizerRules : randomizerRules
        Randomizer.set_rules((m == 1)? extremeRandomizerRules : randomizerRules)
        Randomizer.start(true,m == 1)
      elsif [2,3].include?(m)
        Nuzlocke.reset
        $PokemonGlobal.isNuzlocke = true
        $PokemonGlobal.nuzlockeRules = (m == 3)? hardcoreNuzlockeRules : nuzlockeRules
        Nuzlocke.toggle(true)
        Nuzlocke.set_rules((m == 3)? hardcoreNuzlockeRules : nuzlockeRules)
        Nuzlocke.start(true)
      end
    end
    cmdwindow.dispose
    infowindow.dispose
    vp.dispose
  }
end

PluginManager.register({
  :name => "Randomizer X",
  :credits => "Luka S.J."
})

PluginManager.register({
  :name => "Nuzlocke X",
  :credits => "Luka S.J."
})

PluginManager.register({
  :name => "Auto Hue Sprites",
  :credits => "Vendily"
})

PluginManager.register({
  :name => "EBS SpriteScaler",
  :credits => "Luka S.J."
})
