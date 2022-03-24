def pbChangeEventSpriteToMon(eventID, mon, shiny = false)
  # Get the event from its id
  thisevent = $game_map.events[eventID]
  monid = mon.species
  # Setting up shininess, form and stuffs
  fname = _INTL("")
  fname += _INTL("0") if monid < 100
  fname += _INTL("0") if monid < 10
  fname += _INTL("{1}",monid)
  fname += _INTL("s") if shiny
  fname += _INTL(".png")
  # Finally sets the graphic
  thisevent.character_name = fname
  thisevent.character_hue = 0
end

def generateRandomPkmn(species,level)
  species = getID(PBSpecies, species) if species.is_a?(Symbol) || species.is_a?(String)
  pkmn = PokeBattle_Pokemon.new(species, level, $Trainer)
  newpkmn = randomizeSpecies(pkmn, true)
  return newpkmn
end

# Draw a Pokemon on the screen
def pbDrawPokemon(pkmn, frames = 10, scale = 1)
  spr      = StarterSprite.new(pkmn)
  spr.zoom = scale
  frames.times do |i|
    Graphics.update
    pbUpdateSceneMap
    spr.update
    factor      = (i + 1) / frames.to_f
    spr.opacity = 255 * factor
  end
  $game_variables[2] = spr
end

# Dispose of the Pokemon on the screen
def pbDisposePokemon
  frames = 10
  spr = $game_variables[2]
  frames.times do |i|
    Graphics.update
    pbUpdateSceneMap
    spr.update
    factor      = (i + 1) / frames.to_f
    spr.opacity = 255 * (1 - factor)
  end
  spr.dispose
  pbSet(2, nil)
end

class StarterSprite
  def initialize(pkmn)
    @sprites = {}
    @number  = 5
    @bitmap  = pbLoadPokemonBitmap(pkmn, false)
    # draws the outline
    outline_color = RPG::Cache.load_bitmap("Graphics/Pictures/types").get_pixel(3, 3 + pkmn.type1 * 28)
    num = 5
    @number.times do |j|
      i = @number - j - 1
      @sprites["pkmn_#{i}"] = Sprite.new
      @sprites["pkmn_#{i}"].bitmap  = @bitmap.bitmap
      @sprites["pkmn_#{i}"].color   = outline_color if i != 0
      @sprites["pkmn_#{i}"].x       = Graphics.width / 2
      @sprites["pkmn_#{i}"].y       = Graphics.height / 2
      @sprites["pkmn_#{i}"].ox      = @sprites["pkmn_#{i}"].bitmap.width / 2
      @sprites["pkmn_#{i}"].oy      = @sprites["pkmn_#{i}"].bitmap.height / 2
    end
    self.opacity = 0
  end

  def opacity=(value)
    v = value
    @number.times do |i|
      @sprites["pkmn_#{i}"].opacity = v
      v *= 0.6
    end
  end

  def zoom=(value)
    v      = value
    offset = @bitmap.width / 10000.0
    @number.times do |i|
      @sprites["pkmn_#{i}"].zoom = v
      v += offset
    end
  end

  def update
    pbUpdateSpriteHash(@sprites)
  end

  def dispose
    pbDisposeSpriteHash(@sprites)
    @bitmap.dispose
  end
end
