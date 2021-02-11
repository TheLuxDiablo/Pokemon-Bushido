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
