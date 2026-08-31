#===============================================================================
# Fishing Overworld Reveal
#===============================================================================

FISHING_SURFACE_FRAMES = 20
FISHING_SURFACE_HOLD   = 30
FISHING_SURFACE_RISE   = 14

def pbFishingRevealEncounter(enctype)
  $PokemonTemp.encounterType = enctype

  begin
    encounter1 =
      $PokemonEncounters.pbEncounteredPokemon(
        enctype
      )

    encounter1 =
      EncounterModifier.trigger(
        encounter1
      )

    return false if !encounter1

    species =
      encounter1[0]

    level =
      encounter1[1]

    fishing_pokemon =
      pbFishingGeneratePokemon(
        species,
        level
      )

    pbFishingShowPokemon(
      fishing_pokemon
    )

    if $PokemonGlobal.partner
      encounter2 =
        $PokemonEncounters.pbEncounteredPokemon(
          enctype
        )

      encounter2 =
        EncounterModifier.trigger(
          encounter2
        )

      return false if !encounter2

      pbDoubleWildBattle(
        species,
        level,
        encounter2[0],
        encounter2[1]
      )

    else
      pbWildBattle(
        species,
        level
      )
    end

    return true

  ensure
    $PokemonTemp.encounterType = -1
  end
end

def pbFishingGeneratePokemon(species, level)
  pokemon = nil

  begin
    pokemon =
      PokeBattle_Pokemon.new(
        species,
        level,
        $Trainer
      )
  rescue
    begin
      pokemon =
        PokeBattle_Pokemon.new(
          species,
          level
        )
    rescue
      pokemon = nil
    end
  end

  return pokemon
end

def pbFishingPokemonCharset(pokemon)
  return nil if !pokemon

  species =
    pokemon.species

  form = 0

  begin
    form =
      pokemon.form
  rescue
    form = 0
  end

  species_id = nil
  species_name = nil

  begin
    species_id =
      getID(
        PBSpecies,
        species
      )
  rescue
    species_id =
      species if species.is_a?(Numeric)
  end

  begin
    species_name =
      getConstantName(
        PBSpecies,
        species_id
      )
  rescue
    species_name =
      species.to_s
  end

  candidates = []

  if form && form > 0
    if species_id
      candidates.push(
        sprintf(
          "%03d_%d",
          species_id,
          form
        )
      )

      candidates.push(
        sprintf(
          "%d_%d",
          species_id,
          form
        )
      )
    end

    if species_name
      candidates.push(
        sprintf(
          "%s_%d",
          species_name.to_s,
          form
        )
      )

      candidates.push(
        sprintf(
          "%s_%d",
          species_name.to_s.downcase,
          form
        )
      )
    end
  end

  if species_id
    candidates.push(
      sprintf(
        "%03d",
        species_id
      )
    )

    candidates.push(
      species_id.to_s
    )
  end

  if species_name
    candidates.push(
      species_name.to_s
    )

    candidates.push(
      species_name.to_s.downcase
    )
  end

  candidates.each do |name|
    begin
      resolved =
        pbResolveBitmap(
          "Graphics/Characters/" +
          name
        )

      return resolved if resolved
    rescue
    end
  end

  return nil
end

def pbFishingPokemonPosition
  x =
    $game_player.screen_x

  y =
    $game_player.screen_y

  case $game_player.direction
  when 2
    y += 32

  when 4
    x -= 32

  when 6
    x += 32

  when 8
    y -= 32
  end

  return [x, y]
end

def pbFishingPokemonDirectionRow(player_direction)
  case player_direction
  when 2
    return 3

  when 4
    return 2

  when 6
    return 1

  when 8
    return 0
  end

  return 0
end

def pbFishingShowPokemon(pokemon_data)
  return if !pokemon_data

  charset =
    pbFishingPokemonCharset(
      pokemon_data
    )

  return if !charset

  viewport =
    Viewport.new(
      0,
      0,
      Graphics.width,
      Graphics.height
    )

  viewport.z =
    99999

  pokemon =
    Sprite.new(
      viewport
    )

  begin
    pokemon.bitmap =
      Bitmap.new(
        charset
      )
  rescue
    pokemon.dispose
    viewport.dispose
    return
  end

  bitmap =
    pokemon.bitmap

  if bitmap.width % 4 == 0 &&
     bitmap.height % 4 == 0

    frame_width =
      bitmap.width / 4

    frame_height =
      bitmap.height / 4

    row =
      pbFishingPokemonDirectionRow(
        $game_player.direction
      )

    frame_column = 1

    source_x =
      frame_column *
      frame_width

    source_y =
      row *
      frame_height

  else
    frame_width =
      bitmap.width

    frame_height =
      bitmap.height

    source_x = 0
    source_y = 0
  end

  pokemon.src_rect.set(
    source_x,
    source_y,
    frame_width,
    frame_height
  )

  pokemon.ox =
    frame_width / 2

  pokemon.oy =
    frame_height

  position =
    pbFishingPokemonPosition

  target_x =
    position[0]

  target_y =
    position[1]

  start_y =
    target_y +
    FISHING_SURFACE_RISE

  pokemon.x =
    target_x

  pokemon.y =
    start_y

  pokemon.z =
    99999

  pokemon.opacity =
    0

  pokemon.zoom_x =
    1.0

  pokemon.zoom_y =
    1.0

  begin
    pbSEPlay(
      "Water splash"
    )
  rescue
  end

  FISHING_SURFACE_FRAMES.times do |i|
    Graphics.update
    Input.update
    pbUpdateSceneMap

    t =
      (i + 1).to_f /
      FISHING_SURFACE_FRAMES.to_f

    eased =
      1.0 -
      (
        (1.0 - t) *
        (1.0 - t)
      )

    pokemon.x =
      target_x

    pokemon.y =
      start_y -
      (
        (start_y - target_y) *
        eased
      )

    pokemon.opacity =
      (255 * eased).to_i
  end

  pokemon.x =
    target_x

  pokemon.y =
    target_y

  pokemon.opacity =
    255

  FISHING_SURFACE_HOLD.times do |i|
    Graphics.update
    Input.update
    pbUpdateSceneMap

    wave =
      Math.sin(
        (i.to_f / 12.0) *
        Math::PI
      )

    bob =
      wave >= 0 ?
      0 :
      2

    pokemon.y =
      target_y +
      bob
  end

  pokemon.y =
    target_y

  8.times do
    Graphics.update
    Input.update
    pbUpdateSceneMap
  end

  if pokemon.bitmap &&
     !pokemon.bitmap.disposed?
    pokemon.bitmap.dispose
  end

  pokemon.dispose
  viewport.dispose
end