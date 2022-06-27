#===============================================================================
#  Randomizer Functionality for vanilla Essentials
#-------------------------------------------------------------------------------
#  System settings
#===============================================================================
module Randomizer
  # list of trainers to exclude from the randomizer
  EXCLUDED_TRAINERS = []

  # list of species to exclude from the randomizer
  EXCLUDED_SPECIES = [
    :LUGIA, :HOOH, :COBALION, :TERRAKION, :VIRIZION, :ZERAORA, :LANDORUS,
    :TORNADUS, :THUNDURUS, :ENAMORUS, :CELEBI, :DREEPY, :DRAKOLAK, :DRAGAPULT,
    :MILCERY, :ALCREMIE, :ZORUA, :ZOROARK
  ]

  # list of items to exclude from the randomizer (Automatically excludes Key Items)
  EXCLUDED_ITEMS = [
    :HM01, :HM02, :HM03, :HM04, :HM05, :HM06, :RARECANDY, :LIGHTFLUTE,
    :GALARICACUFF, :GALARICAWREATH, :POKEBALL
  ]

  # list of moves to exclude from the randomizer (Automatically excludes shadow moves)
  EXCLUDED_MOVES = [
    :BURNKUNAI, :SHOCKKUNAI, :POISONKUNAI, :SLEEPKUNAI, :STRUGGLE
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
class PokemonSystem
  attr_accessor :game_modes_won

  def game_modes_won
    if !@game_modes_won
      @game_modes_won = []
      @game_modes_won[0] = true if $game_variables[99] > 6
    end
    return @game_modes_won
  end
end


#===============================================================================
#  UI to select game mode
#===============================================================================
def pbSelectGameMode
  vp = Viewport.new(0, 0, Graphics.width, Graphics.height)
  randomizer_rules         = [:DEXORDER, :STATIC, :ENCOUNTERS, :GIFTS, :ITEMS]
  super_randomizer_rules   = [:DEXORDER, :STATIC, :ENCOUNTERS, :GIFTS, :ITEMS, :TRAINERS]
  extreme_randomizer_rules = [:DEXORDER, :STATIC, :ENCOUNTERS, :GIFTS, :ITEMS, :MOVES, :MOVESETS, :TMS, :EGGMOVES, :ABILITIES, :TRAINERS]
  nuzlocke_rules           = [:NOREVIVE, :ONEROUTE, :NICKNAME, :DUPSCLAUSE, :STATIC]
  hardcore_nuzlocke_rules  = [:NOREVIVE, :ONEROUTE, :NICKNAME, :NOSTORE, :NOWHITEOUT]
  modes = []
  modestrings = [_INTL("Randomizer"), _INTL("Super Randomizer"), _INTL("Extreme Randomizer"), _INTL("Nuzlocke"), _INTL("Hardcore Nuzlocke")]
  modeinfo = [
    [_INTL("These are the rules of the Randomizer Mode:"),
_INTL("\\l[6]- All wild encounters are randomized
- All static encounters are randomized
- All gifted Pokemon are randomized
- All items are randomized
- Randomized Pokemon can be species from the Aisho Dex only"),
_INTL("\\l[3]You can choose to turn off the Randomizer after the main story ends, but this won't un-randomize your randomized data."),
_INTL("\\l[3]You will receive a commemorative badge on your Kenshi Card upon beating the game in Randomizer Mode.")],
[_INTL("These are the rules of the Super Randomizer Mode:"),
_INTL("\\l[7]- All wild encounters are randomized
- All static encounters are randomized
- All gifted Pokemon are randomized
- All items are randomized
- All Trainer Pokemon are randomized
- Randomized Pokemon can be any species from the National Dex"),
_INTL("\\l[3]You can choose to turn off the Randomizer after the main story ends, but this won't un-randomize your randomized data."),
_INTL("\\l[3]You will receive a commemorative badge on your Kenshi Card upon beating the game in Super Randomizer Mode.")],
[_INTL("These are the rules of the Extreme Randomizer Mode:"),
_INTL("\\l[11]- All wild encounters are randomized
- All static encounters are randomized
- All gifted Pokemon are randomized
- All items are randomized
- All Trainer Pokemon are randomized
- All Pokemon Abilities are randomized
- All movesets and egg moves are randomized
- All Moves taught by scrolls and notes are randomized
- Randomized Pokemon can be any species from the National Dex"),
_INTL("\\l[3]You can choose to turn off the Randomizer after the main story ends, but this won't un-randomize your randomized data."),
_INTL("\\l[3]You will receive a commemorative badge on your Kenshi Card upon beating the game in Extreme Randomizer Mode.")],
[_INTL("These are the rules of the Nuzlocke Mode:"),
_INTL("\\l[8]- Fainted Pokemon cannot be revived
- You can catch one non-shiny, one shiny/shadow, and one static encounter per map
- All Pokemon that are caught, must be nicknamed
- Duplicate species are disregarded from the \"one capture per map\" rule"),
_INTL("\\l[3]The challenge starts upon receiving your first Pokeball from Sukiro in Nagisa Bay and ends upon beating the main story."),
_INTL("\\l[3]You will be allowed to continue the challenge if you white out, but have Pokemon on Sukiro's Islands that can battle."),
_INTL("\\l[3]You will lose the challenge if you have no Pokemon in your Party, or on Sukiro's Islands, that are able to battle."),
_INTL("\\l[3]You will receive a commemorative badge on your Kenshi Card upon beating the game in Nuzlocke Mode.")],
[_INTL("These are the rules of the Hardcore Nuzlocke Mode:"),
_INTL("\\l[11]- Fainted Pokemon cannot be revived
- You can catch one non-shiny and one shiny/shadow per map.
- All Pokemon that are caught, must be nicknamed
- Duplicate species are counted in the \"one capture per map\" rule
- Static encounters are counted in the \"one capture per map\" rule
- You cannot purchase any medicinal items from the marts"),
_INTL("\\l[3]The challenge starts upon receiving your first Pokeball from Sukiro in Nagisa Bay and ends upon beating the main story."),
_INTL("\\l[3]You will not be allowed to continue the challenge if you white out, but have Pokemon on Sukiro's Islands."),
_INTL("\\l[3]You will lose the challenge if you have no Pokemon in your Party or on Sukiro's Islands that are able to battle."),
_INTL("\\l[3]You will receive a commemorative badge on your Kenshi Card upon beating the game in Hardcore Nuzlocke Mode.")]
  ]
  if !$DEBUG
    pbMessage(_INTL("Pokémon Bushido offers built-in challenge modifiers like Nuzlocke Mode and Randomizers."))
    pbMessage(_INTL("These are meant to offer unique ways to challenge the player in their playthrough."))
    pbMessage(_INTL("These are only recommended if you've already played through Pokémon Bushido atleast once."))
  end
  return false if pbMessage(_INTL("Would you like to play the game with challenge modifiers?"), [_INTL("No"), _INTL("Yes")]) == 0
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
      if pbConfirmMessage(_INTL("\\w[{1}]Clear current selection of modifiers and start a regular playthrough?", defaultskin))
        modes.clear
        modes = []
        break
      end
      infowindow.visible = true
      need_refresh = true
    elsif Input.trigger?(Input::A)
      cmdwindow.visible = false
      infowindow.visible = false
      modeinfo[cmdwindow.index].each{ |m|
        message = _INTL(m)
        pbMessage("\\w[#{defaultskin}]#{message}")
      }
      infowindow.visible = true
      cmdwindow.visible = true
      need_refresh = true
    elsif Input.trigger?(Input::C)
      command = cmdwindow.index
      if command == 5
        infowindow.visible = false
        finalmodes = modes.clone
        finalmodes.map!{ |m| next modestrings[m] }
        finalmodes = finalmodes.join(" and ")
        finalmodes = "" if !finalmodes
        message = _INTL("{1} mode", finalmodes)
        message = _INTL("Normal mode") if finalmodes.length == 0
        break if pbConfirmMessage(_INTL("\\w[{1}]Would you like to start the game in {2}?", defaultskin, message))
        infowindow.visible = true
      else
        pbPlayCursorSE
        if !modes.include?(command)
          modes.push(command)
          modes.uniq!
          if command == 0
            modes.delete(1)
            modes.delete(2)
          end
          if command == 1
            modes.delete(0)
            modes.delete(2)
          end
          if command == 2
            modes.delete(0)
            modes.delete(1)
          end
          modes.delete(3) if command == 4
          modes.delete(4) if command == 3
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
      case m
      when 0
        Randomizer.reset
        $PokemonGlobal.isRandomizer = true
        $PokemonGlobal.randomizerRules = randomizer_rules
        Randomizer.set_rules(randomizer_rules)
        Randomizer.start(true, false)
      when 1
        Randomizer.reset
        $PokemonGlobal.isRandomizer = true
        $PokemonGlobal.randomizerRules = super_randomizer_rules
        Randomizer.set_rules(super_randomizer_rules)
        Randomizer.start(true, true)
      when 2
        Randomizer.reset
        $PokemonGlobal.isRandomizer = true
        $PokemonGlobal.randomizerRules = extreme_randomizer_rules
        Randomizer.set_rules(extreme_randomizer_rules)
        Randomizer.start(true, true)
      when 3
        Nuzlocke.reset
        $PokemonGlobal.isNuzlocke = true
        $PokemonGlobal.nuzlockeRules = nuzlocke_rules
        Nuzlocke.set_rules(nuzlocke_rules)
        Nuzlocke.start(true)
      when 4
        Nuzlocke.reset
        $PokemonGlobal.isNuzlocke = true
        $PokemonGlobal.nuzlockeRules = hardcore_nuzlocke_rules
        Nuzlocke.set_rules(hardcore_nuzlocke_rules)
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
