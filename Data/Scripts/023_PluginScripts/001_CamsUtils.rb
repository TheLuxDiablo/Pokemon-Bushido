#=============================
# Cam's Utility Functions
#=============================
def poisonAllPokemon(event=nil)
    for pkmn in $Trainer.ablePokemonParty
       next if pkmn.hasType?(:POISON)  || pkmn.hasType?(:STEEL) ||
          pkmn.hasAbility?(:COMATOSE)  || pkmn.hasAbility?(:SHIELDSDOWN) ||
          pkmn.status!=0
       pkmn.status = 2
       pkmn.statusCount = 1
     end
end

def paralyzeAllPokemon(event=nil)
    for pkmn in $Trainer.ablePokemonParty
       next if pkmn.hasType?(:ELECTRIC) ||
          pkmn.hasAbility?(:COMATOSE)  || pkmn.hasAbility?(:SHIELDSDOWN) ||
          pkmn.status!=0
       pkmn.status = 4
     end
end

def drawPlayerPicture(opacity=255)
  if $Trainer.gender==0 # Male
      $game_screen.pictures[1].show("Character0-"+$Trainer.outfit.to_s,0,0,0,100,100,opacity,0)
  else #Female
      $game_screen.pictures[1].show("Character1-"+$Trainer.outfit.to_s,0,0,0,100,100,opacity,0)
  end
end

def drawPlayerPictureFlipped(opacity=255)
  if $Trainer.gender==0 # Male
      $game_screen.pictures[1].show("Character0-"+$Trainer.outfit.to_s+"-flipped",0,0,0,100,100,opacity,0)
  else #Female
      $game_screen.pictures[1].show("Character1-"+$Trainer.outfit.to_s+"-flipped",0,0,0,100,100,opacity,0)
  end
end

# Outfit Utilities
def pbUnlockOutfit(id,displayName)
  if !$game_variables[56].is_a?(Array)
    $game_variables[56]=[[0,"Default"]]
  end
  ids= []
  outfits = $game_variables[56]
  for i in 0...outfits.length
    if outfits[i].is_a?(Array)
      ids.push(outfits[i][0])
    end
  end
  if !ids.include?(id)
    $game_variables[56].push([id,displayName])
    return true
  end
  return false
end

def pbSelectOutfit
  choices=[]
  ids= []
  if $game_variables[56].is_a?(Array) && $game_variables[56].length>1
    outfits = $game_variables[56]
    for i in 0...outfits.length
      if outfits[i].is_a?(Array)
        choices.push(outfits[i][1])
        ids.push(outfits[i][0])
      end
    end
    choices.push("Cancel")
    outfitVal=pbMessage(_INTL("Select an Outfit:<ar>(Outfits Unlocked: {1})</ar>",choices.length-1),choices)
    if outfitVal == choices.length-1
      return
    end
    if $Trainer.outfit != ids[outfitVal]
      viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
      viewport.z = 99999
      bmp = pbFade
      screen = Sprite.new(viewport)
      screen.bitmap = bmp
      10.times do
        Graphics.update
        pbWait(1)
      end
      $Trainer.outfit = ids[outfitVal]
      10.times do
        Graphics.update
        pbWait(1)
      end
      screen.visible= false
      pbFade(true)
      screen.dispose
      viewport.dispose
      drawPlayerPicture(255)
      messages=["Looking good!","Fits like a glove!","Very stylish!","What a stunner!","How fabulous!","Beautiful!"]
      pbMessage(_INTL("\\se[OutfitChange]\\pg{1}",messages[rand(messages.length)]))
      $game_screen.pictures[1].erase
    else
      pbMessage(_INTL("You're already wearing this outfit!"))
    end
  else
    pbMessage("Hmm... looks like there aren't any other clothes in here.")
  end
end

#===============================================================================
#  Fade Out Animation by Luka SJ
#===============================================================================
def pbFade(reverse=false)
  return if !$game_player || !$scene.is_a?(Scene_Map)
  viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
  viewport.z = 99999
  viewport.color = Color.new(0,0,0,reverse ? 255 : 0)
  15.times do
    viewport.color.alpha += 17*(reverse ? -1 : 1)
    Graphics.update
  end
  bmp = Graphics.snap_to_bitmap
  viewport.dispose
  return bmp
end

def pbSetArenayCharacterName(event,form=nil,shiny=false)
  return false if !event
  return false if !$game_map.events[event]
  s = ""
  s = "s" if shiny
  f = "_" + form.to_s
  f = "" if !form.is_a?(Numeric) || form <= 0
  if pbResolveBitmap("Graphics/Characters/907#{s}#{f}")
    pbMoveRoute($game_map.events[event],[PBMoveRoute::Graphic,"907#{s}#{f}",0,2,0])
  end
end

def pbSaveArenayToVariable(var)
  return if !var
  $Trainer.party.each_with_index do |pkmn,i|
    if pkmn && pkmn.isSpecies?(:ARENAY)
      $game_variables[var] = $Trainer.party[i]
      $Trainer.party[i] = nil
    end
  end
  $Trainer.party.compact!
  for i in 0...$PokemonStorage.maxBoxes
    for j in 0...$PokemonStorage.maxPokemon(i)
      pkmn = $PokemonStorage[i,j]
      if pkmn && pkmn.isSpecies?(:ARENAY)
        $game_variables[var] = $PokemonStorage[i,j]
        $PokemonStorage[i,j] = nil
      end
    end
  end
  $PokemonBag.pbStoreItem($game_variables[var].item) if $game_variables[var].hasItem?
  $game_variables[var].setItem(0)
end

def pbGetTotalPurified
  totalPurified = 0
  $Trainer.party.each_with_index do |pkmn,i|
    if pkmn && pkmn.hasRibbon?(PBRibbons::NATIONAL)
      totalPurified += 1
    end
  end
  $Trainer.party.compact!
  for i in 0...$PokemonStorage.maxBoxes
    for j in 0...$PokemonStorage.maxPokemon(i)
      pkmn = $PokemonStorage[i,j]
      if pkmn && pkmn.hasRibbon?(PBRibbons::NATIONAL)
        totalPurified += 1
      end
    end
  end
  return totalPurified
end

def getCurrentVialCharges()
    return $game_variables[50]
end

def getMaxVialCharges()
    return $game_variables[52]
end

def refillVial()
    return $game_variables[50] = getMaxVialCharges()
end

def pbHealingVial(currentChargeVar=50,maxChargeVar=52)
  if(PLAYERKATANATECHNIQUES)
    # Do logic A (Spirit Energy)
    energyCost = 3
    if(hasEnoughEnergy(energyCost))
        decrementPlayerCurrentEnergy(energyCost)
        for i in $Trainer.party
          i.heal
        end
        pbMessage(_INTL("\\me[HGSSGetItem]Your Pokémon were fully healed by the Katana of Light!"))
    else
        pbMessage(_INTL("\\se[SwShIncorrect]You need at least {1} Spirit Energy...", energyCost))
    end
  else
    # Do Logic B (Charges)
      if $game_variables[maxChargeVar] == 0 #Thundaga, making it so the healing can always be used initially.
        $game_variables[currentChargeVar] = 1
        $game_variables[maxChargeVar] = 1
      end
      case $game_variables[currentChargeVar]
      when 0
        pbMessage(_INTL("\\se[SwShIncorrect]You do not have any healing energy left..."))
      when 1
        pbMessage("You have 1 charge of healing energy left.")
        if pbConfirmMessage("Would you like to heal your Pokémon?")
          $game_variables[currentChargeVar] -= 1
          for i in $Trainer.party
           i.heal
          end
          pbMessage(_INTL("\\me[HGSSGetItem]Your Pokémon were fully healed by the Katana of Light!"))
          pbMessage(_INTL("You have no more healing energy left."))
         end
      else
        pbMessage(_INTL("You have {1} charges of healing energy left.",$game_variables[currentChargeVar]))
        if pbConfirmMessage("Would you like to heal your Pokémon?")
          $game_variables[currentChargeVar] -= 1
          for i in $Trainer.party
           i.heal
          end
          pbMessage(_INTL("\\me[HGSSGetItem]Your Pokémon were fully healed by the Katana of Light!"))
          pbMessage(_INTL("{1} charge(s) remain.",$game_variables[currentChargeVar]))
         end
       end
    end
end

# More like GolisopodUser's utilities am i right? He's great, to be honest though
def getTrainerPartyLength(trainerid,trainername,partyid=0)
  if trainerid.is_a?(String) || trainerid.is_a?(Symbol)
    if !hasConst?(PBTrainers,trainerid)
      raise _INTL("Trainer type does not exist ({1}, {2}, ID {3})",trainerid,trainername,partyid)
    end
    trainerid = getID(PBTrainers,trainerid)
  end
  trainers  = pbLoadTrainersData
  for trainer in trainers
    thistrainerid = trainer[0]
    name          = trainer[1]
    thispartyid   = trainer[4]
    next if thistrainerid!=trainerid || name!=trainername || thispartyid!=partyid
    return (trainer[3]. length - 1)
  end
  return 0
end

# Registers the item in the Ready Menu.
def pbRegisterItemOutOfBag(item)
  item = getID(PBItems,item)
  if !item || item<1
    raise ArgumentError.new(_INTL("Item number {1} is invalid.",item))
  end
  registeredlist = $PokemonBag.registeredItems
  registeredlist.push(item) if !registeredlist.include?(item)
end

# Main game char data
#$TrainerMainGame=$Trainer.clone
#$PokemonBagMainGame=$PokemonBag.clone
#$PokemonStorageMainGame=$PokemonStorage.clone
#$PokemonGlobalMainGame=$PokemonGlobal.clone

# Hattori Char data
#$TrainerHattori=$Trainer.clone
#$PokemonBagHattori=$PokemonBag.clone
#$PokemonStorageHattori=$PokemonStorage.clone
#$PokemonGlobalHattori=$PokemonGlobal.clone

# Changing players
def saveCharDataToVariables()
    $TrainerMainGame=$Trainer.clone
    $PokemonBagMainGame=$PokemonBag.clone
    $PokemonStorageMainGame=$PokemonStorage.clone
    $PokemonGlobalMainGame=$PokemonGlobal.clone
end

def saveHattoriDataToVariables()
  $TrainerHattori=$Trainer.clone
  $PokemonBagHattori=$PokemonBag.clone
  $PokemonStorageHattori=$PokemonStorage.clone
  $PokemonGlobalHattori=$PokemonGlobal.clone
end

# Resetting character data
def resetCharData()
  $Trainer.send :initialize2
  $PokemonBag.send :initialize
  $PokemonStorage.send :initialize
  $PokemonGlobal.send :initialize
end

#switch characters
def switchToCharacter(char=0)
  if char==2
    saveCharDataToVariables()
    resetCharData()
    pbChangePlayer(char)
    $game_variables[99]="Hattori"
    if !$game_switches[160]
      $Trainer.name="Hattori"
      $Trainer.money=5000
      vAI("JAM1",10)
      vAI("JAM2",5)
      vAI("REVIVE",3)
      vAPS("ZORUA",20)
      $game_switches[160]=!$game_switches[160]
    else
      $Trainer=$TrainerHattori
      $PokemonBag=$PokemonBagHattori
      $PokemonStorage=$PokemonStorageHattori
      $PokemonGlobal=$PokemonGlobalHattori
    end
  else
    saveHattoriDataToVariables()
    resetCharData()
    pbChangePlayer($game_variables[28])
    $Trainer=$TrainerMainGame
    $PokemonBag=$PokemonBagMainGame
    $PokemonStorage=$PokemonStorageMainGame
    $PokemonGlobal=$PokemonGlobalMainGame
    $game_variables[99]=7
  end
end

def shadowCheckAndSwitch(poke,switch)
  if $Trainer.shadowcaught[getID(PBSpecies,poke.upcase)]
    vSST(switch)
  end
end

def KatanaOfLightAwakened?()
    return $game_switches[67] == true
end

def KatanaLevel()
    return $game_variables[100]
end

def HasChoppedDownOneTree?()
    return $game_switches[180] == true
end

def setChopDownOneTree()
    $game_switches[180] = true
end

  def setSlopeData(xincline, yincline, ypos, yheight, offset)
    $game_player.slope(xincline, yincline, ypos, yheight, offset)
  end

  def currentChapter()
    return $game_variables[99]
  end

  def setChapter(int)
    $game_variables[99] = int
  end

# ===================================================================
# Player Katana Techniques
# ===================================================================
# New bag pocket for them???
# Receive them from each dojo, and/or at pivotal moments

# Kaifuku: Heal the whole party out of battle: COST = 3
# DONE - Hikari: Lower Enemy accuracy 1 level, restore 25% HP, Protect for 1 turn. COST = 1
# DONE - Sakuryaku: Set up Trick Room (5 turns), boost Def/Spdef. Cost = 1
# DONE - Moya: Clear stat changes from all. Cost = 1
# DONE - Komorei: HealStatus, Half HP, and Setup Grassy Terrain. COST = 2
# DONE - Nensho: Burn Enemy, Setup Sun, raise our ATK/SPATK one stage. COST = 3
# DONE - Shimizu: Rain, Setup Aqua Ring on self, setup Misty Terrain. COST = 2
# Tsume: Shadow Cleave all enemies, cut HP in half (never kill), then put to Sleep. COST = 4. WAY OP, POSTGAME
# Masayoshi: Reflect + LightScreen, same as Ryo. Cost = 1
# Akui: Shadow Clone for Evasion and Speed, Toxic Spikes. Cost = 3.
# Raikami: paralyze, elec Terrain. Cost = 2.
# Iwa: stealth rocks + sandstorm + spdefUP. Cost = 2.
# Yuki: Hail, freeze. Cost = 3.
# Hattori: Wonder Room, 
#      :Gravity         => "Gravity",
#      :NeutralizingGas => "Neutralizing Gas"

#How to set energy, perhaps based on chapter or badge for old save files we force set max EN

def restorePlayerEnergy()
    $game_variables[226] = getPlayerMaxEnergy()
end

def getPlayerCurrentEnergy()
    return $game_variables[226]
end

def getPlayerMaxEnergy()
    return $game_variables[227]
end

def hasEnoughEnergy(enCheck)
    return (getPlayerCurrentEnergy() >= enCheck)
end

def healPlayerEnergy(incAmt)
    $game_variables[226] = ($game_variables[226] + incAmt)
    if($game_variables[226] > getPlayerMaxEnergy())
        $game_variables[226] = getPlayerMaxEnergy()
    end
end

def fullyRecoverEnergy()
    healPlayerEnergy(getPlayerMaxEnergy())
end

def increaseMaxEnergy(increaseAmt)
    $game_variables[227] = (getPlayerMaxEnergy() + increaseAmt)
    healPlayerEnergy(increaseAmt)
end

def decrementPlayerCurrentEnergy(decAmt)
    if(getPlayerCurrentEnergy() >= decAmt)
        # We have enough energy and can return true
        $game_variables[226] = (getPlayerCurrentEnergy() - decAmt)
        return true
    else
        # Message for not enough energy and return false
        pbMessage(_INTL("Not enough Spirit to use this Technique!"))
        return false
    end
end

def doesPlayerHaveEnoughEnergy(energyCheck)
    if(getPlayerCurrentEnergy() >= energyCheck)
        return true
    else
        pbMessage(_INTL("Not enough Spirit to use this Technique!"))
        return false
    end
end

def isPlayerAtMaxEnergy()
    return getPlayerMaxEnergy() == getPlayerCurrentEnergy()
end

def energyRatio()
  return _INTL("{1}/{2}", getPlayerCurrentEnergy(), getPlayerMaxEnergy())
end

def printEnergyValues()
  pbMessage(_INTL("Spirit: {1}", energyRatio()))
end

def initializePlayerEnergy()
    $game_variables[227] = INITIAL_ENERGY
    restorePlayerEnergy()
end

def camsHackyInitMethod()
    # early out if we're disabling PKT
    pbMessage(_INTL("hacky init start!"))
    if (PLAYERKATANATECHNIQUES == false)
        return
    end

    # call on load, if no energy then initialize it (old save files would have no energy, so init them)
    if(getPlayerMaxEnergy() <= 0)
        initializePlayerEnergy()
        #pbMessage(_INTL("No energy set yet, so initializing now."))
    end

    # Then check progress to determine roughly what techniques player should have and silently add them to our inventory
    # if katana level 1 then
    # if katana level 2 then etc
end

def pbHotSpringRecovery()
    if(PLAYERKATANATECHNIQUES)
        fullyRecoverEnergy()
        pbMessage(_INTL("Your Spirit Energy was fully restored!"))
    else
        if(KatanaOfLightAwakened?())
            if(getCurrentVialCharges() < getMaxVialCharges())
                refillVial()
                pbMessage(_INTL("The healing energy in the Katana of Light has also been refilled!"))
            end
        end
    end
end

def getPKTCost(item)
  if PLAYERKATANATECHNIQUES == false
    pbMessage(_INTL("Don't use PKT when they're disabled! Returning a cost of 999!"))
    return 999
  end

  def getPKTTechniqueName(string)
        str = string.gsub("KT - ","")
        str = str.sub(/\(.*/, '')
        str = str.delete("-")
        str = str.rstrip
        return str
  end
  
  item_display_name = ""
  if item && item > 0
    item_display_name = PBItems.getName(item).to_s rescue ""
  end

  if item_display_name.include?("Technique") || item_display_name.include?("KT")
    return pbGetItemData(item, ITEM_PRICE)
  else
    return 10
  end
end

def isItemAPKT(item)
  item_display_name = PBItems.getName(item).to_s rescue ""
  
  return item_display_name.include?("Technique") || item_display_name.include?("KT")
end

