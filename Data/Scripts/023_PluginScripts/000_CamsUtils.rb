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
    Kernel.pbMessage("Hmm... looks like there aren't any other clothes in here.")
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

ItemHandlers::UseText.add(:OUTFITCASE,proc { |item|
  next _INTL("Change Outfit")
})

ItemHandlers::UseFromBag.add(:OUTFITCASE,proc { |item|
#  if !pbGetMetadata($game_map.map_id,MetadataOutdoor)
    next 2
#  end
#  pbMessage(_INTL("Can't use that here."))
#  next 0
})

ItemHandlers::UseInField.add(:OUTFITCASE,proc { |item|
  pbMessage(_INTL("You opened the outfit case."))
  pbSelectOutfit
  next 1
})

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

def pbHealingVial(currentChargeVar=50,maxChargeVar=52)
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
