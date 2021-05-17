############################################
#    Simple Encounter List Window by raZ   #
#     Additions from Nuri Yuri, Vendily    #
#                  v1.2                    #
#   Icon edits + NatDex iter. by Zaffre    #
#     Updated to v18 by ThatWelshOne_      #
############################################
#    To use it, call the following         #
#    function:                             #
#                                          #
#    pbEncounterListUI                     #
############################################

PluginManager.register({
  :name => "Simple Encounter List UI",
  :version => "1.3",
  :credits => ["raZ","Nuri Yuri","Vendily","Savordez","Marin","PurpleZaffre","ThatWelshOne_"],
  :link => "https://reliccastle.com/resources/401/"
})

# Currently known issues:
# 1. Common crash if not starting from a new save.

# Method that checks whether a specific form has been seen by the player
def pbFormSeen?(species,form)
  return $Trainer.formseen[species][0][form] ||
    $Trainer.formseen[species][1][form]
end

# Method that checks whether a specific form is owned by the player
def pbFormOwned?(species,form)
  return $Trainer.formowned[species][0][form] ||
    $Trainer.formowned[species][1][form]
end

##############################################
### Setting up the new formowned variable  ###
##############################################

# In this class, we add a new bit of data that checks whether a specific form is owned by the player
class PokeBattle_Trainer
  attr_accessor :formowned

  def formowned
    if !@formowned
      @formowned = []
      for i in 1..PBSpecies.maxValue
        @formowned[i]     = [[],[]]
      end
    end
    return @formowned
  end

  # Initiate empty arrays
  def clearPokedex
    @seen         = []
    @owned        = []
    @formseen     = []
    @formowned    = []
    @formlastseen = []
    for i in 1..PBSpecies.maxValue
      @seen[i]         = false
      @owned[i]        = false
      @formlastseen[i] = []
      @formseen[i]     = [[],[]]
      @formowned[i]     = [[],[]]
    end
  end
end

# Need to add this method to all existing methods that updates the Pokédex
# Being given a Pokémon, Pokémon evolving, catching a Pokémon, trading, eggs
def pbOwnedForm(pkmn,gender=0,form=0)
  $Trainer.formowned     = [] if !$Trainer.formowned
  if pkmn.is_a?(PokeBattle_Pokemon)
    gender  = pkmn.gender
    form    = (pkmn.form rescue 0)
    species = pkmn.species
  else
    species = getID(PBSpecies,pkmn)
  end
  return if !species || species<=0
  fSpecies = pbGetFSpeciesFromForm(species,form)
  species, form = pbGetSpeciesFromFSpecies(fSpecies)
  gender = 0 if gender>1
  dexForm = pbGetSpeciesData(species,form,SpeciesPokedexForm)
  form = dexForm if dexForm>0
  fSpecies = pbGetFSpeciesFromForm(species,form)
  formName = pbGetMessage(MessageTypes::FormNames,fSpecies)
  form = 0 if !formName || formName==""
  $Trainer.formowned[species] = [[],[]] if !$Trainer.formowned[species]
  $Trainer.formowned[species][gender][form] = true
end

###############################################################################
### The following methods have been edited to update the formowned variable ###
###############################################################################

# Gift Pokémon
alias encounter_pbAddPokemon pbAddPokemon
def pbAddPokemon(pokemon,level=nil,seeform=true,ownform=true)
  ret = encounter_pbAddPokemon(pokemon,level,seeform)
  pbOwnedForm(pokemon) if ownform && ret
  return ret
end

# Silently gift Pokémon
alias encounter_pbAddPokemonSilent pbAddPokemonSilent
def pbAddPokemonSilent(pokemon,level=nil,seeform=true,ownform=true)
  ret = encounter_pbAddPokemonSilent(pokemon,level,seeform)
  pbOwnedForm(pokemon) if ownform && ret
  return ret
end

# Adding Pokémon to party
alias encounter_pbAddToParty pbAddToParty
def pbAddToParty(pokemon,level=nil,seeform=true,ownform=true)
  ret = encounter_pbAddToParty(pokemon,level,seeform)
  pbOwnedForm(pokemon) if ownform && ret
  return ret
end

# Silently adding Pokémon to party
alias encounter_pbAddToPartySilent pbAddToPartySilent
def pbAddToPartySilent(pokemon,level=nil,seeform=true,ownform=true)
  ret = encounter_pbAddToPartySilent(pokemon,level,seeform)
  pbOwnedForm(pokemon) if ownform && ret
  return ret
end

# Adding foreign Pokémon like Shuckie
alias encounter_pbAddForeignPokemon pbAddForeignPokemon
def pbAddForeignPokemon(pokemon,level=nil,ownerName=nil,nickname=nil,ownerGender=0,seeform=true,ownform=true)
  ret = encounter_pbAddForeignPokemon(pokemon,level,seeform)
  pbOwnedForm(pokemon) if ownform && ret
  return ret
end

# Adding foreign Pokémon like Shuckie
alias encounter_pbAddForeignPokemonBetter pbAddForeignPokemonBetter
def pbAddForeignPokemonBetter(pokemon,level=nil,ownerName=nil,nickname=nil,
  ownerGender=0,seeform=true,shiny=true,ability=0,form=0,pokeGender=0,nature=0,ballUsed=0,
  move1=nil,move2=nil,move3=nil,move4=nil,
  hpIV=rand(31),atkIV=rand(31),defIV=rand(31),spdIV=rand(31),satkIV=rand(31),sdefIV=rand(31),ownform = true)
  ret = encounter_pbAddForeignPokemonBetter(pokemon,level,ownerName,nickname,
    ownerGender,seeform,shiny,ability,form,pokeGender,nature,ballUsed,move1,
    move2,move3,move4,hpIV,atkIV,defIV,spdIV,satkIV,sdefIV)
  pbOwnedForm(pokemon) if ownform && ret
  return ret
end

# Hatching an egg
alias encounter_pbHatch pbHatch
def pbHatch(pokemon)
  encounter_pbHatch(pokemon)
  pbOwnedForm(pokemon) # Edit
end

class PokemonEvolutionScene

  # Evolution
  alias encounter_pbEvolutionSuccess pbEvolutionSuccess
  def pbEvolutionSuccess
    encounter_pbEvolutionSuccess
    pbOwnedForm(@pokemon) # Edit
  end

  class << self
    alias encounter_pbDuplicatePokemon pbDuplicatePokemon
    def pbDuplicatePokemon(pkmn, new_species)
      encounter_pbDuplicatePokemon(pkmn, new_species)
      pbOwnedForm(new_pkmn)
    end
  end
end

# Trading
alias encounter_pbStartTrade pbStartTrade
def pbStartTrade(pokemonIndex,newpoke,nickname,trainerName,trainerGender=0)
  encounter_pbStartTrade(pokemonIndex,newpoke,nickname,trainerName,trainerGender)
  pbOwnedForm(yourPokemon) # Edit
end

module PokeBattle_BattleCommon

  # Catching
  alias encounter_pbRecordAndStoreCaughtPokemon pbRecordAndStoreCaughtPokemon
  def pbRecordAndStoreCaughtPokemon
    @caughtPokemon.each do |pkmn|
      pbOwnedForm(pkmn)
    end
    encounter_pbRecordAndStoreCaughtPokemon
  end
end

##########################
### Encounter list UI  ###
##########################

# This is the name of a graphic in your Graphics/Pictures folder that changes the look of the UI
# If the graphic does not exist, you will get an error
WINDOWSKIN = "book.png"

# This array allows you to overwrite the names of your encounter types if you want them to be more logical
# E.g. "Surfing" instead of "Water"
# By default, the method uses the encounter type names in the EncounterTypes module
NAMES = ["Grass", "Cave", "Surfing", "Rock Smash", "Fishing (Old Rod)",
      "Fishing (Good Rod)", "Fishing (Super Rod)", "Headbutt (Low)",
      "Headbutt (High)", "Grass (morning)", "Grass (day)", "Grass (night)",
      "Bug Contest", "Shaking Grass", "Rippling Water", "Dust Clouds", "Birbs"]

# Controls whether Deerling's seasonal form is used for the UI
DEERLING = true

class EncounterListUI_withforms
  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @encarray1 = []
    @encarray2 = []
    @index = 0
    @encdata = load_data("Data/encounters.dat")
    @mapid = $game_map.map_id
  end

  def pbStartMenu
    getEncData
    if !File.file?("Graphics/Pictures/"+WINDOWSKIN)
      raise _INTL("You are missing the graphic for this UI. Make sure the image is in your Graphics/Pictures folder and that it is named appropriately.")
    end
    @sprites["background"] = IconSprite.new(0,0,@viewport)
    @sprites["background"].setBitmap("Graphics/Pictures/"+WINDOWSKIN)
    @sprites["background"].ox = @sprites["background"].bitmap.width/2
    @sprites["background"].oy = @sprites["background"].bitmap.height/2
    @sprites["background"].x  = Graphics.width/2; @sprites["background"].y = Graphics.height/2
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @h = (Graphics.height - @sprites["background"].bitmap.height)/2
    @w = (Graphics.width - @sprites["background"].bitmap.width)/2
    if !@num_enc
      @sprites["overlay"].bitmap.clear
      textpos = []
      textpos.push([_INTL("{1}", $game_map.name,@name),256,32,2,Color.new(64,64,64),Color.new(176,176,176)])
      textpos.push([_INTL("This area has no encounters!", @encarray2.length),256,64,2,Color.new(64,64,64),Color.new(176,176,176)])
      textpos.push(["-----------------------------------------",256,96,2,Color.new(64,64,64),Color.new(176,176,176)])
      pbDrawTextPositions(@sprites["overlay"].bitmap,textpos)
      pbFadeInAndShow(@sprites) {pbUpdate}
      main3
    else
      if !NAMES.nil? # If NAMES is not nil
        @name = NAMES[@type[@index]] # Pull string from NAMES array
      else
        @name = [EncounterTypes::Names].flatten[@type[@index]] # Otherwise, use default names
      end
      @sprites["overlay"].bitmap.clear
      textpos = []
      textpos.push([_INTL("{1}: {2}", $game_map.name,@name),256,32,2,Color.new(64,64,64),Color.new(176,176,176)])
      textpos.push([_INTL("Total encounters for area: {1}", @encarray2.length),256,64,2,Color.new(64,64,64),Color.new(176,176,176)])
      textpos.push(["-----------------------------------------",256,96,2,Color.new(64,64,64),Color.new(176,176,176)])
      pbDrawTextPositions(@sprites["overlay"].bitmap,textpos)
      @encarray2.each_with_index do |specie,i| # Loops over internal IDs of encounters on current map
        fSpecies = pbGetSpeciesFromFSpecies(specie) # Array of internal ID of base form and form ID of specie
        if !pbFormSeen?(fSpecies[0],fSpecies[1])
          @sprites["icon_#{i}"] = PokemonSpeciesIconSprite.new(0,@viewport)
        else
          @sprites["icon_#{i}"] = PokemonSpeciesIconSprite.new(fSpecies[0],@viewport)
          @sprites["icon_#{i}"].pbSetParams(fSpecies[0],0,fSpecies[1],false)
        end
        # @sprites["icon_#{i}"].color = Color.new(118,91,38,220)
        if i > 6 && i < 14
          @sprites["icon_#{i}"].y = @h + 128 + 64
          @sprites["icon_#{i}"].x = @w + 28 + (64*(i-7))
        elsif i > 13
          @sprites["icon_#{i}"].y = @h + 128 + 128
          @sprites["icon_#{i}"].x = @w + 28 + (64*(i-14))
        else
          @sprites["icon_#{i}"].y = @h + 128
          @sprites["icon_#{i}"].x = @w + 28 + 64*i
        end
      end
      @sprites["rightarrow"] = AnimatedSprite.new("Graphics/Pictures/rightarrow",8,40,28,2,@viewport)
      @sprites["rightarrow"].x = Graphics.width - @sprites["rightarrow"].bitmap.width
      @sprites["rightarrow"].y = Graphics.height/2 - @sprites["rightarrow"].bitmap.height/16
      @sprites["rightarrow"].visible = false
      @sprites["rightarrow"].play
      @sprites["leftarrow"] = AnimatedSprite.new("Graphics/Pictures/leftarrow",8,40,28,2,@viewport)
      @sprites["leftarrow"].x = 0
      @sprites["leftarrow"].y = Graphics.height/2 - @sprites["rightarrow"].bitmap.height/16
      @sprites["leftarrow"].visible = false
      @sprites["leftarrow"].play
      pbFadeInAndShow(@sprites) {pbUpdate}
      main1
    end
  end

  def pbListOfEncounters(encounter) # This method is from Nuri Yuri
    return [] unless encounter
    encable = encounter.compact # Remove nils
    encable.map! {|enc| enc[0]} # Pull first element from each array
    encable.flatten! # Transform array of arrays into array
    encable.uniq! # Prevent duplication
    return encable
  end

  def getEncData
    if @encdata.is_a?(Hash) && @encdata[@mapid]
      enc = @encdata[@mapid][1]
      @num_enc = enc.compact.length # Number of defined encounter types on current map
      @type = (0...enc.length).reject {|i| enc[i].nil? } # Array indices of non-nil array elements
      @first = enc.index(enc.find { |i| !i.nil? } || false) # From Yuri to get index of first non-nil array element
      enctypes = enc[@type[@index]]
      @encarray1 = pbListOfEncounters(enctypes)
      temp = []
      @encarray1.each_with_index do |s,i| # Funky method for grouping forms with their base forms
        if (isConst?(s,PBSpecies,:DEERLING) ||
          isConst?(s,PBSpecies,:SAWSBUCK)) && DEERLING
          @encarray1[i] = pbGetFSpeciesFromForm(s,pbGetSeason)
        end
        fSpecies = pbGetSpeciesFromFSpecies(s)
        temp.push(fSpecies[0] + fSpecies[1]*0.001)
      end
      temp_sort = temp.sort
      id = temp_sort.map{|s| temp.index(s)}
      @encarray2 = []
      for i in 0..@encarray1.length-1
        @encarray2[i] = @encarray1[id[i]]
      end
    else
      @encarray2 = [7]
    end
  end

  def pbUpdate
    #for key in @sprites.keys
    #  next if key[/icon/]
    #  @sprites[key].update
    #end
    pbUpdateSpriteHash(@sprites)
  end

  def pbShift
    for i in 0...@encarray2.length
      @sprites["icon_#{i}"].dispose
    end
  end

  def main1
    loop do
      Graphics.update
      Input.update
      pbUpdate
        if @first == @type[@index] && @num_enc >1 # If first page and there are more pages
          @sprites["leftarrow"].visible=false
          @sprites["rightarrow"].visible=true
        elsif @index == @type.length-1 && @num_enc >1 # If last page and there is more than one page
          @sprites["leftarrow"].visible=true
          @sprites["rightarrow"].visible=false
        end
        if Input.trigger?(Input::RIGHT) && @num_enc >1 && @index< @num_enc-1
          pbPlayCursorSE
          @index += 1
          pbShift # Dispose sprites
          main2
          @sprites["leftarrow"].visible=true
          @sprites["rightarrow"].visible=true
        elsif Input.trigger?(Input::LEFT) && @num_enc >1 && @index !=0
          pbPlayCursorSE
          @index -= 1
          pbShift # Dispose sprites
          main2
          @sprites["leftarrow"].visible=true
          @sprites["rightarrow"].visible=true
        elsif Input.trigger?(Input::C) || Input.trigger?(Input::B)
          pbPlayCloseMenuSE
          break
        end
      end
    dispose
  end

  def main2
    getEncData
    if !NAMES.nil?
      @name = NAMES[@type[@index]]
    else
      @name = [EncounterTypes::Names].flatten[@type[@index]]
    end
    @sprites["overlay"].bitmap.clear
    textpos = []
    textpos.push([_INTL("{1}: {2}", $game_map.name,@name),256,32,2,Color.new(64,64,64),Color.new(176,176,176)])
    textpos.push([_INTL("Total encounters for area: {1}", @encarray2.length),256,64,2,Color.new(64,64,64),Color.new(176,176,176)])
    textpos.push(["-----------------------------------------",256,96,2,Color.new(64,64,64),Color.new(176,176,176)])
    pbDrawTextPositions(@sprites["overlay"].bitmap,textpos)
    @encarray2.each_with_index do |specie,i| # Loops over internal IDs of encounters on current map
      fSpecies = pbGetSpeciesFromFSpecies(specie) # Array of internal ID of base form and form ID of specie
      if !pbFormSeen?(fSpecies[0],fSpecies[1])
        @sprites["icon_#{i}"] = PokemonSpeciesIconSprite.new(0,@viewport)
      else
        @sprites["icon_#{i}"] = PokemonSpeciesIconSprite.new(fSpecies[0],@viewport)
        @sprites["icon_#{i}"].pbSetParams(fSpecies[0],0,fSpecies[1],false)
      end
      # @sprites["icon_#{i}"].color = Color.new(118,91,38,220)
      if i > 6 && i < 14
        @sprites["icon_#{i}"].y = @h + 128 + 64
        @sprites["icon_#{i}"].x = @w + 28 + (64*(i-7))
      elsif i > 13
        @sprites["icon_#{i}"].y = @h + 128 + 128
        @sprites["icon_#{i}"].x = @w + 28 + (64*(i-14))
      else
        @sprites["icon_#{i}"].y = @h + 128
        @sprites["icon_#{i}"].x = @w + 28 + 64*i
      end
    end
  end

  def main3
    loop do
      Graphics.update
      Input.update
      if Input.trigger?(Input::C) || Input.trigger?(Input::B)
        pbPlayCloseMenuSE
        break
      end
    end
    dispose
  end

  def dispose
    pbFadeOutAndHide(@sprites) {pbUpdate}
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

###############################################
### Cleaner way of calling the class method ###
###############################################

def pbEncounterListUI
  EncounterListUI_withforms.new.pbStartMenu
end
