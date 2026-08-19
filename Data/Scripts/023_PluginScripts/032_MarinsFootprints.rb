#===============================================================================
# Bushido Footprints
#===============================================================================

module BushidoFootprints
  TERRAIN_TAG = 3
  FADE_SPEED  = 6

  WALK_X_OFFSET = 0
  WALK_Y_OFFSET = 0

  BIKE_X_OFFSET = -8
  BIKE_Y_OFFSET = 0

  @spritesets = {}

  def self.register_spriteset(spriteset, viewport)
    return if !spriteset
    return if !spriteset.map

    @spritesets[spriteset.map.map_id] = spriteset
    spriteset.bushido_footprint_setup(viewport)
  end

  def self.unregister_spriteset(spriteset)
    return if !spriteset
    return if !spriteset.map

    if @spritesets[spriteset.map.map_id] == spriteset
      @spritesets.delete(spriteset.map.map_id)
    end
  end

  def self.spriteset_for_map(map_id)
    return @spritesets[map_id]
  end

  def self.direction_name(direction)
    case direction
    when 2; return "Down"
    when 4; return "Left"
    when 6; return "Right"
    when 8; return "Up"
    end
    return nil
  end

  def self.sand_tile?(map, x, y)
    return false if !map
    return false if !map.valid?(x, y)

    return map.terrain_tag(x, y) == TERRAIN_TAG
  end

  def self.create_for_player(map_id, x, y)
    return if !$game_player
    return if !$game_player.character_name
    return if $game_player.character_name.empty?

    map = $MapFactory.getMap(map_id)
    return if !map
    return if !sand_tile?(map, x, y)

    spriteset = spriteset_for_map(map_id)
    return if !spriteset

    spriteset.bushido_add_footprint(
      x,
      y,
      $game_player.direction,
      $PokemonGlobal && $PokemonGlobal.bicycle
    )
  end
end


#===============================================================================
# Spriteset footprint manager
#===============================================================================

class Spriteset_Map
  attr_reader :map

  def bushido_footprint_setup(viewport)
    @bushido_footprint_viewport = viewport
    @bushido_footprints = []
  end

  def bushido_add_footprint(tile_x, tile_y, direction, bicycle = false)
    return if !@bushido_footprint_viewport

    dir_name = BushidoFootprints.direction_name(direction)
    return if !dir_name

    filename = "Graphics/Characters/steps#{dir_name}"
    filename += "Bike" if bicycle

    sprite = nil

    begin
      sprite = Sprite.new(@bushido_footprint_viewport)
      sprite.bitmap = RPG::Cache.load_bitmap(filename)
    rescue
      sprite.dispose if sprite && !sprite.disposed?
      return
    end

    sprite.ox = sprite.bitmap.width / 2
    sprite.oy = sprite.bitmap.height
    sprite.z  = 1

    if bicycle
      x_offset = BushidoFootprints::BIKE_X_OFFSET
      y_offset = BushidoFootprints::BIKE_Y_OFFSET
    else
      x_offset = BushidoFootprints::WALK_X_OFFSET
      y_offset = BushidoFootprints::WALK_Y_OFFSET
    end

    world_x = tile_x + x_offset / Game_Map::TILE_WIDTH.to_f
    world_y = tile_y + y_offset / Game_Map::TILE_HEIGHT.to_f

    data = [
      sprite,
      world_x,
      world_y
    ]

    @bushido_footprints << data

    bushido_position_footprint(data)
  end

  def bushido_position_footprint(data)
    sprite, x, y = data

    return if !sprite
    return if sprite.disposed?

    sprite.x =
      -@map.display_x / Game_Map::X_SUBPIXELS +
      x * Game_Map::TILE_WIDTH +
      Game_Map::TILE_WIDTH / 2

    sprite.y =
      -@map.display_y / Game_Map::Y_SUBPIXELS +
      (y + 1) * Game_Map::TILE_HEIGHT
  end

  def bushido_update_footprints
    return if !@bushido_footprints

    @bushido_footprints.each do |data|
      next if !data

      sprite = data[0]
      next if !sprite
      next if sprite.disposed?

      bushido_position_footprint(data)

      sprite.opacity -= BushidoFootprints::FADE_SPEED

      if sprite.opacity <= 0
        sprite.dispose
        data[0] = nil
      end
    end

    @bushido_footprints.delete_if do |data|
      !data || !data[0] || data[0].disposed?
    end
  end

  def bushido_dispose_footprints
    return if !@bushido_footprints

    @bushido_footprints.each do |data|
      next if !data

      sprite = data[0]

      if sprite && !sprite.disposed?
        sprite.dispose
      end
    end

    @bushido_footprints.clear
  end

  alias bushido_footprints_update update
  def update
    bushido_footprints_update
    bushido_update_footprints
  end

  alias bushido_footprints_dispose dispose
  def dispose
    BushidoFootprints.unregister_spriteset(self)
    bushido_dispose_footprints
    bushido_footprints_dispose
  end
end


#===============================================================================
# Register each map spriteset
#===============================================================================

Events.onSpritesetCreate += proc { |_sender, e|
  spriteset = e[0]
  viewport  = e[1]

  BushidoFootprints.register_spriteset(spriteset, viewport)
}


#===============================================================================
# Create footprints the instant the player leaves a sand tile
#===============================================================================

Events.onLeaveTile += proc { |_sender, e|
  character = e[0]
  map_id    = e[1]
  x         = e[2]
  y         = e[3]

  next if character != $game_player

  BushidoFootprints.create_for_player(
    map_id,
    x,
    y
  )
}