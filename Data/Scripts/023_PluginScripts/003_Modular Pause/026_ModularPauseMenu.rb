#===============================================================================
#  Modular Pause Menu
#    by Luka S.J.
# ----------------
#  Provides only features present in the default version of the Pokedex in
#  Essentials. Mean as a new cosmetic overhaul, adhering to the UI design
#  language of the Elite Battle System: The Next Generation
#
#  Enjoy the script, and make sure to give credit!
#-------------------------------------------------------------------------------
#  load script
#===============================================================================
# set up plugin metadata
if defined?(PluginManager)
  PluginManager.register({
    :name => "Modular Menu",
    :version => "1.3",
    :link => "https://luka-sj.com/res/modmn",
    :dependencies => [
      ["Luka's Scripting Utilities", "3.0"]
    ],
    :credits => ["Luka S.J."]
  })
else
  raise "This script is only compatible with Essentials v18.x!"
end
#File.runScript("Data/Plugins/MODMN.rxdata")
#-------------------------------------------------------------------------------
#  Your own entries for the pause menu
#
#  How to use
#
#  MenuHandlers.addEntry(:name,"button text","icon name",proc{|menu|
#    # code you want to run
#    # when the entry in the menu is selected
#  },proc{ # code to check if menu entry is available })
#-------------------------------------------------------------------------------
# Party Screen
MenuHandlers.addEntry(:POKEMON,_INTL("Pokémon"),"menuPokemon",proc{|menu|
  sscene = PokemonParty_Scene.new
  sscreen = PokemonPartyScreen.new(sscene,$Trainer.party)
  hiddenmove = nil
  pbFadeOutIn(99999) {
    hiddenmove = sscreen.pbPokemonScreen
    if hiddenmove
      menu.pbEndScene
      menu.endscene = false
    end
  }
  if hiddenmove
    Kernel.pbUseHiddenMove(hiddenmove[0],hiddenmove[1])
    menu.close = true
  end
},proc{ next $Trainer.party.length > 0 })
# Bag Screen
MenuHandlers.addEntry(:BAG,_INTL("Bag"),"menuBag",proc{|menu|
  item = 0
  scene = PokemonBag_Scene.new
  screen = PokemonBagScreen.new(scene,$PokemonBag)
  pbFadeOutIn(99999) {
  item = screen.pbStartScreen
  if item > 0
    menu.pbEndScene
    menu.endscene = false
  end
  }
  if item > 0
    Kernel.pbUseKeyItemInField(item)
    menu.close = true
  end
},proc{ next true })
# PokeGear
MenuHandlers.addEntry(:POKEGEAR,_INTL("Pokégear"),"menuPokegear",proc{|menu|
  scene = PokemonPokegear_Scene.new
  screen = PokemonPokegearScreen.new(scene)
  pbFadeOutIn(99999) {
    screen.pbStartScreen
  }
},proc{ next $Trainer.pokegear })
# Trainer Card
MenuHandlers.addEntry(:TRAINER,_INTL("\\pn"),"menuTrainer",proc{|menu|
  scene = PokemonTrainerCard_Scene.new
  screen = PokemonTrainerCardScreen.new(scene)
  pbFadeOutIn(99999) {
    screen.pbStartScreen
  }
},proc{ next true })
# Save Screen
MenuHandlers.addEntry(:SAVE,_INTL("Save"),"menuSave",proc{|menu|
  scene = PokemonSave_Scene.new
  screen = PokemonSaveScreen.new(scene)
  menu.pbEndScene
  menu.endscene = false
  if screen.pbSaveScreen
    menu.close = true
  else
    menu.pbStartScene
    menu.pbShowMenu
    menu.close = false
  end
},proc{ next !$game_system || !$game_system.save_disabled && !(pbInSafari? || pbInBugContest?)})
# PokeDex
MenuHandlers.addEntry(:POKEDEX,_INTL("Journal"),"menuPokedex",proc{|menu|
  if USE_CURRENT_REGION_DEX
    pbFadeOutIn(99999){
      scene = PokemonPokedex_Scene.new
      screen = PokemonPokedexScreen.new(scene)
      screen.pbStartScreen
      menu.refresh
    }
  else
    if $PokemonGlobal.pokedexViable.length==1
      $PokemonGlobal.pokedexDex = $PokemonGlobal.pokedexViable[0]
      $PokemonGlobal.pokedexDex = -1 if $PokemonGlobal.pokedexDex==$PokemonGlobal.pokedexUnlocked.length-1
      pbFadeOutIn(99999){
        scene = PokemonPokedex_Scene.new
        screen = PokemonPokedexScreen.new(scene)
        screen.pbStartScreen
        menu.refresh
      }
    else
      pbFadeOutIn(99999){
        scene = PokemonPokedexMenu_Scene.new
        screen = PokemonPokedexMenuScreen.new(scene)
        screen.pbStartScreen
        menu.refresh
      }
    end
  end
},proc{ next $Trainer.pokedex && $PokemonGlobal.pokedexViable.length > 0 })
# Quit Safari-Zone
MenuHandlers.addEntry(:QUIT,_INTL("\\contest"),"menuQuit",proc{|menu|
  if pbInSafari?
    if Kernel.pbConfirmMessage(_INTL("Would you like to leave the Safari Game right now?"))
      menu.pbEndScene
      menu.endscene = false
      menu.close = true
      pbSafariState.decision=1
      pbSafariState.pbGoToStart
    end
  else
    if Kernel.pbConfirmMessage(_INTL("Would you like to end the Contest now?"))
      menu.pbEndScene
      menu.endscene = false
      menu.close = true
      pbBugContestState.pbStartJudging
      next
    end
  end
},proc{ next pbInSafari? || pbInBugContest? })
# Options Screen
MenuHandlers.addEntry(:OPTIONS,_INTL("Options"),"menuOptions",proc{|menu|
  scene = PokemonOption_Scene.new
  screen = PokemonOptionScreen.new(scene)
  pbFadeOutIn(99999) {
    screen.pbStartScreen
    pbUpdateSceneMap
  }
},proc{ next true })
# Debug Menu
MenuHandlers.addEntry(:DEBUG,_INTL("Debug"),"menuDebug",proc{|menu|
  pbFadeOutIn(99999) {
    pbDebugMenu
    menu.refresh
  }
},proc{ next $DEBUG })

# Debug Mystery Gift
MenuHandlers.addEntry(:MGIFT,_INTL("Mystery Gift"),"menuDebug",proc{|menu|
  pbFadeOutIn(99999) {
    pbDownloadMysteryGift($Trainer)
  }
},proc{ next $DEBUG })

# Debug Mystery Gift
MenuHandlers.addEntry(:ENCLIST,_INTL("Encounters"),"menuDebug",proc{|menu|
  pbFadeOutIn(99999) {
    pbEncounterListUI
  }
},proc{ next $DEBUG })

# Quit Game
MenuHandlers.addEntry(:QUITGAME,_INTL("Quit"),"menuDebug",proc{|menu|
  if pbConfirmMessage(_INTL("Are you sure you want to quit the game?"))
    menu.pbHideMenu
    scene = PokemonSave_Scene.new
    screen = PokemonSaveScreen.new(scene)
    menu.close=true
    screen.pbSaveScreen
    $scene=nil
  else
    menu.close = false
  end
},proc{ next !(pbInSafari? || pbInBugContest?) })
