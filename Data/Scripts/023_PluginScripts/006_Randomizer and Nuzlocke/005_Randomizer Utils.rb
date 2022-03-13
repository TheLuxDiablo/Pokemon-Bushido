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
  pkmn = PokeBattle_Pokemon.new(species,level,$Trainer)
  newpkmn = randomizeSpecies(pkmn, true)
  return newpkmn
end

def pbAddPokemonNoRandomizer(pokemon,level=nil,seeform=true)
  return if !pokemon
  if pbBoxesFull?
    pbMessage(_INTL("There's no more room for Pokémon!\1"))
    pbMessage(_INTL("The Pokémon Boxes are full and can't accept any more!"))
    return false
  end
  pokemon = getID(PBSpecies,pokemon)
  if pokemon.is_a?(Integer) && level.is_a?(Integer)
    pokemon = pbNewPkmn(pokemon,level)
  end
  speciesname = PBSpecies.getName(pokemon.species)
  pbMessage(_INTL("\\me[Pkmn get]{1} obtained {2}!\1",$Trainer.name,speciesname))
  pbNicknameAndStore(pokemon)
  pbSeenForm(pokemon) if seeform
  return true
end

# Draw a Pokemon on the screen
def pbDrawPokemon(num,x=0,y=0,frames=20,scale=1)
  scene = DrawPokemon_Scene.new(num,x,y,frames,scale)
  screen = DrawPokemon_Screen.new(scene)
  screen.pbStartScreen
  $game_variables[2] = screen
end

# Dispose of the Pokemon on the screen
def pbDisposePokemon
  screen = $game_variables[2]
  screen.pbEndScreen
end

def pbGenerateImages(backsprite=false,thickness=5)
  pokes = []
  for i in 0..2
    pkmn = pbGet(73+i)
    sprite = Sprite.new
    sprite.visible = false
    sprite.bitmap = pbLoadPokemonBitmap(pkmn,backsprite).bitmap.clone
    # draws the outline
    outline_color = Bitmap.new(_INTL("Graphics/Pictures/types")).get_pixel(3,3+pkmn.type1*28)
    for i in 0..thickness
      outline_color.alpha*=0.6
      sprite.create_outline(outline_color,1)
    end
    pokes.push(sprite)
    sprite.dispose
  end
  pbSet(4,pokes)
end

class DrawPokemon_Scene
  def initialize(num,x,y,frames,scale)
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}
    @pokemon_sprite = pbGet(4)[num]
    @sprite_pos = [x,y]
    @frames = frames # how many frames it takes to fade in.
    @scale = scale
    @disposed = false
  end
  
  # draw scene elements
  def pbStartScene
    case @scale
    when 1 then scale_offset = 2
    when 2 then scale_offset = 1
    when 3 then scale_offset = 0.5
    when 4 then scale_offset = 0.25
    else scale_offset = 0
    end
    @sprites["pokemon_sprite"] = Sprite.new(@viewport)
    @sprites["pokemon_sprite"].bitmap = @pokemon_sprite.bitmap
    @sprites["pokemon_sprite"].zoom_x *= @scale
    @sprites["pokemon_sprite"].zoom_y *= @scale
    @sprites["pokemon_sprite"].x = (Graphics.width/2-@sprites["pokemon_sprite"].bitmap.width/scale_offset) + @sprite_pos[0]
    @sprites["pokemon_sprite"].y = (Graphics.height/2-@sprites["pokemon_sprite"].bitmap.height/scale_offset) + @sprite_pos[1]
    @sprites["pokemon_sprite"].visible = true
    @sprites["pokemon_sprite"].opacity = 0
    pbFadeSprites(@sprites)
  end

  # fades the sprites
  def pbFadeSprites(sprites,fades_out=false)
    sprites.each do |s|
      sprite = s[1]
      old_alpha = sprite.opacity
      for i in 0..@frames
        if fades_out
          next if !sprite
          next if pbDisposed?(sprite)
          sprite.opacity = old_alpha-(i*(old_alpha/@frames))
          if sprite.opacity == 0
            sprite.visible = false
            sprite.dispose
          end
        else
          sprite.opacity = i*(255/@frames)
        end
        pbUpdate if sprite && !pbDisposed?(sprite)
      end
      sprite.opacity = 255 if sprite
    end
  end

  def pbUpdate
    Graphics.update
    pbUpdateSpriteHash(@sprites)
  end

  def pbEndScene
    pbFadeSprites(@sprites,true)
    pbDisposeSpriteHash(@sprites)
    @disposed = true
    @viewport.dispose
  end
end

class DrawPokemon_Screen
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen
    @scene.pbStartScene
  end

  def pbEndScreen
    @scene.pbEndScene
  end
end