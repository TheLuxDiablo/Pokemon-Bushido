#===============================================================================
# Island Pokémon
#===============================================================================
class IslandPokemon
  attr_reader :pokemon
  attr_reader :box
  attr_reader :index
  attr_reader :sprite_filename
  attr_reader :x
  attr_reader :y

  def initialize(pokemon, box, index, viewport, x, y)
    @pokemon = pokemon
    @box = box
    @index = index

    @x = x
    @y = y

    @carry_x = x
    @carry_y = y

    @landing_x = x
    @landing_y = y

    @state = :grounded
    @hovered = false

    @lift_amount = 0.0
    @lift_speed = 0.22
    @lift_height = 34

    @sprite_filename = resolve_sprite_filename

    @bitmap = AnimatedBitmap.new(
      "Graphics/Characters/" + @sprite_filename
    )

    @sprite = Sprite.new(viewport)
    @sprite.bitmap = @bitmap.bitmap

    @frame_width = @bitmap.width / 4
    @frame_height = @bitmap.height / 4

    @frame = 0
    @frame_timer = 0
    @frame_delay = 14
    @direction_row = 0

    @visible_centers = []

    calculate_visible_centers
    create_outline(viewport)
    create_shadow(viewport)

    refresh_src_rect
    refresh_position
  end

  def resolve_sprite_filename
    shiny = @pokemon.shiny?

    if @pokemon.respond_to?(:superVariant) &&
       !@pokemon.superVariant.nil? &&
       @pokemon.superShiny?
      shiny = @pokemon.superVariant
    end

    return pbLoadOverworldPokemonBitmap([
      @pokemon.species,
      @pokemon.female?,
      shiny,
      @pokemon.form,
      @pokemon.shadowPokemon?
    ])
  end

  def calculate_visible_centers
    4.times do |frame|
      left = @frame_width
      right = 0
      top = @frame_height
      bottom = 0
      found_pixel = false

      start_x = frame * @frame_width
      start_y = @direction_row * @frame_height

      @frame_height.times do |y|
        @frame_width.times do |x|
          color = @bitmap.bitmap.get_pixel(
            start_x + x,
            start_y + y
          )

          next if color.alpha == 0

          found_pixel = true

          left = x if x < left
          right = x if x > right
          top = y if y < top
          bottom = y if y > bottom
        end
      end

      if found_pixel
        center_x = (left + right) / 2.0
        center_y = (top + bottom) / 2.0
      else
        center_x = @frame_width / 2.0
        center_y = @frame_height / 2.0
      end

      @visible_centers.push([
        center_x,
        center_y
      ])
    end
  end

  def create_outline(viewport)
    @outline_bitmap = Bitmap.new(
      @frame_width * 4,
      @frame_height
    )

    white = Color.new(
      255,
      255,
      255,
      255
    )

    4.times do |frame|
      source_x = frame * @frame_width

      @frame_height.times do |y|
        @frame_width.times do |x|
          source_color = @bitmap.bitmap.get_pixel(
            source_x + x,
            (@direction_row * @frame_height) + y
          )

          next if source_color.alpha == 0

          (-2..2).each do |offset_y|
            (-2..2).each do |offset_x|
              next if offset_x == 0 &&
                      offset_y == 0

              next if (
                (offset_x * offset_x) +
                (offset_y * offset_y)
              ) > 4

              outline_x = x + offset_x
              outline_y = y + offset_y

              next if outline_x < 0
              next if outline_x >= @frame_width
              next if outline_y < 0
              next if outline_y >= @frame_height

              @outline_bitmap.set_pixel(
                source_x + outline_x,
                outline_y,
                white
              )
            end
          end
        end
      end
    end

    4.times do |frame|
      source_x = frame * @frame_width

      @frame_height.times do |y|
        @frame_width.times do |x|
          source_color = @bitmap.bitmap.get_pixel(
            source_x + x,
            (@direction_row * @frame_height) + y
          )

          next if source_color.alpha == 0

          @outline_bitmap.set_pixel(
            source_x + x,
            y,
            Color.new(0, 0, 0, 0)
          )
        end
      end
    end

    @outline_sprite = Sprite.new(viewport)
    @outline_sprite.bitmap = @outline_bitmap
    @outline_sprite.visible = false
    @outline_sprite.opacity = 255

    @outline_timer = 0
  end

  def create_shadow(viewport)
    @shadow_sprite = Sprite.new(viewport)
    @shadow_sprite.bitmap = Bitmap.new(32, 12)

    shadow_color = Color.new(
      0,
      0,
      0,
      120
    )

    @shadow_sprite.bitmap.fill_rect(
      8,
      0,
      16,
      12,
      shadow_color
    )

    @shadow_sprite.bitmap.fill_rect(
      4,
      2,
      24,
      8,
      shadow_color
    )

    @shadow_sprite.bitmap.fill_rect(
      0,
      4,
      32,
      4,
      shadow_color
    )

    @shadow_sprite.ox = 16
    @shadow_sprite.oy = 6

    @shadow_sprite.zoom_x = 0.0
    @shadow_sprite.zoom_y = 0.0
    @shadow_sprite.opacity = 0
    @shadow_sprite.visible = false
  end

  def update
    @bitmap.update
    @sprite.bitmap = @bitmap.bitmap

    update_animation
    update_lift
    update_outline
    refresh_position
  end

  def update_animation
    @frame_timer += 1

    if @frame_timer >= @frame_delay
      @frame_timer = 0
      @frame = (@frame + 1) % 4

      refresh_src_rect
    end
  end

  def update_lift
    case @state
    when :lifting
      @lift_amount += (
        1.0 - @lift_amount
      ) * @lift_speed

      if @lift_amount >= 0.98
        @lift_amount = 1.0
        @state = :held
      end

    when :dropping
      @lift_amount += (
        0.0 - @lift_amount
      ) * @lift_speed

      if @lift_amount <= 0.02
        @lift_amount = 0.0

        @x = @landing_x
        @y = @landing_y

        @carry_x = @x
        @carry_y = @y

        @state = :grounded
      end
    end
  end

  def update_outline
    show_outline = (
      @hovered ||
      @state == :lifting ||
      @state == :held ||
      @state == :dropping
    )

    if !show_outline
      @outline_sprite.visible = false
      return
    end

    @outline_timer += 1

    pulse = (
      Math.sin(@outline_timer * 0.10) + 1.0
    ) / 2.0

    @outline_sprite.opacity = (
      155 + (pulse * 100)
    )

    @outline_sprite.visible = true
  end

  def move_held_to(x, y)
    return if !carrying?

    @carry_x = x
    @carry_y = y

    @landing_x = x
    @landing_y = y + @lift_height
  end

  def begin_held
    return if @state != :grounded

    @carry_x = @x
    @carry_y = @y

    @landing_x = @x
    @landing_y = @y

    @state = :lifting
    @lift_amount = 0.0
  end

  def begin_drop
    return false if @state != :held

    @state = :dropping

    return true
  end

  def cancel_to(x, y)
    @landing_x = x
    @landing_y = y

    @carry_x = x
    @carry_y = y - @lift_height

    @state = :dropping
  end

  def grounded?
    return @state == :grounded
  end

  def lifting?
    return @state == :lifting
  end

  def held?
    return @state == :held
  end

  def dropping?
    return @state == :dropping
  end

  def carrying?
    return (
      @state == :lifting ||
      @state == :held
    )
  end

  def set_hovered(value)
    @hovered = value
  end

  def refresh_position
    case @state
    when :grounded
      refresh_grounded_position
    when :lifting
      refresh_lifting_position
    when :held
      refresh_held_position
    when :dropping
      refresh_dropping_position
    end

    refresh_outline_position
  end

  def refresh_grounded_position
    @sprite.ox = @frame_width / 2.0
    @sprite.oy = @frame_height

    @sprite.x = @x
    @sprite.y = @y
    @sprite.z = @y

    @shadow_sprite.visible = false
  end

  def refresh_lifting_position
    visible_center = @visible_centers[@frame]

    normal_ox = @frame_width / 2.0
    normal_oy = @frame_height

    @sprite.ox = lerp(
      normal_ox,
      visible_center[0],
      @lift_amount
    )

    @sprite.oy = lerp(
      normal_oy,
      visible_center[1],
      @lift_amount
    )

    start_x = @x
    start_y = @y

    target_x = @carry_x
    target_y = @carry_y

    @sprite.x = lerp(
      start_x,
      target_x,
      @lift_amount
    )

    @sprite.y = lerp(
      start_y,
      target_y,
      @lift_amount
    )

    @sprite.z = 1001

    refresh_shadow(
      @landing_x,
      @landing_y,
      @lift_amount
    )
  end

  def refresh_held_position
    visible_center = @visible_centers[@frame]

    @sprite.ox = visible_center[0]
    @sprite.oy = visible_center[1]

    @sprite.x = @carry_x
    @sprite.y = @carry_y
    @sprite.z = 1001

    refresh_shadow(
      @landing_x,
      @landing_y,
      1.0
    )
  end

  def refresh_dropping_position
    visible_center = @visible_centers[@frame]

    @sprite.ox = lerp(
      @frame_width / 2.0,
      visible_center[0],
      @lift_amount
    )

    @sprite.oy = lerp(
      @frame_height,
      visible_center[1],
      @lift_amount
    )

    airborne_x = @landing_x
    airborne_y = @landing_y - @lift_height

    @sprite.x = @landing_x

    @sprite.y = lerp(
      @landing_y,
      airborne_y,
      @lift_amount
    )

    @sprite.z = 1001

    refresh_shadow(
      @landing_x,
      @landing_y,
      @lift_amount
    )
  end

  def refresh_shadow(x, y, amount)
    @shadow_sprite.x = x
    @shadow_sprite.y = y
    @shadow_sprite.z = 1000

    @shadow_sprite.zoom_x = (
      0.25 + (0.75 * amount)
    )

    @shadow_sprite.zoom_y = (
      0.25 + (0.75 * amount)
    )

    @shadow_sprite.opacity = (
      120 * amount
    )

    @shadow_sprite.visible = (
      amount > 0.01
    )
  end

  def refresh_outline_position
    return if !@outline_sprite.visible

    @outline_sprite.ox = @sprite.ox
    @outline_sprite.oy = @sprite.oy

    @outline_sprite.x = @sprite.x
    @outline_sprite.y = @sprite.y

    @outline_sprite.z = @sprite.z - 1
  end

  def refresh_src_rect
    sprite_x = @frame * @frame_width
    sprite_y = @direction_row * @frame_height

    @sprite.src_rect.set(
      sprite_x,
      sprite_y,
      @frame_width,
      @frame_height
    )

    @outline_sprite.src_rect.set(
      sprite_x,
      0,
      @frame_width,
      @frame_height
    )
  end

  def lerp(start_value, end_value, amount)
    return start_value + (
      (end_value - start_value) * amount
    )
  end

  def dispose
    if @shadow_sprite
      if @shadow_sprite.bitmap
        @shadow_sprite.bitmap.dispose
      end

      if !@shadow_sprite.disposed?
        @shadow_sprite.dispose
      end
    end

    if @outline_sprite &&
       !@outline_sprite.disposed?
      @outline_sprite.dispose
    end

    if @outline_bitmap
      @outline_bitmap.dispose
    end

    @sprite.dispose if @sprite && !@sprite.disposed?
    @bitmap.dispose if @bitmap
  end
end


#===============================================================================
# Island Cursor
#===============================================================================
class IslandCursor
  attr_reader :x
  attr_reader :y
  attr_reader :hovered_pokemon

  def initialize(viewport)
    @sprite = Sprite.new(viewport)
    @sprite.bitmap = Bitmap.new(40, 40)

    @sprite.ox = 20
    @sprite.oy = 20

    @sprite.x = Graphics.width / 2
    @sprite.y = Graphics.height / 2
    @sprite.z = 999

    @x = @sprite.x
    @y = @sprite.y

    @speed = 4

    @min_x = 24
    @max_x = Graphics.width - 24
    @min_y = 60
    @max_y = Graphics.height - 20

    @hover_radius = 28
    @hovered_pokemon = nil
    @holding = false
    @visual_state = nil

    refresh_graphic
  end

  def update(island_pokemon)
    update_movement

    if !@holding
      update_hover(island_pokemon)
    end
  end

  def update_movement
    move_x = 0
    move_y = 0

    move_x -= @speed if Input.press?(Input::LEFT)
    move_x += @speed if Input.press?(Input::RIGHT)
    move_y -= @speed if Input.press?(Input::UP)
    move_y += @speed if Input.press?(Input::DOWN)

    @sprite.x += move_x
    @sprite.y += move_y

    @sprite.x = @min_x if @sprite.x < @min_x
    @sprite.x = @max_x if @sprite.x > @max_x
    @sprite.y = @min_y if @sprite.y < @min_y
    @sprite.y = @max_y if @sprite.y > @max_y

    @x = @sprite.x
    @y = @sprite.y
  end

  def update_hover(island_pokemon)
    nearest = nil
    nearest_distance = nil

    island_pokemon.each do |island_pkmn|
      next if !island_pkmn.grounded?

      dx = @x - island_pkmn.x
      dy = @y - island_pkmn.y

      distance = Math.sqrt(
        (dx * dx) + (dy * dy)
      )

      next if distance > @hover_radius

      if nearest_distance.nil? ||
         distance < nearest_distance
        nearest = island_pkmn
        nearest_distance = distance
      end
    end

    return if @hovered_pokemon == nearest

    if @hovered_pokemon
      @hovered_pokemon.set_hovered(false)
    end

    @hovered_pokemon = nearest

    if @hovered_pokemon
      @hovered_pokemon.set_hovered(true)
    end

    refresh_graphic
  end

  def clear_hover
    if @hovered_pokemon
      @hovered_pokemon.set_hovered(false)
    end

    @hovered_pokemon = nil

    refresh_graphic
  end

  def begin_holding(pokemon)
    @holding = true
    @hovered_pokemon = pokemon

    refresh_graphic
  end

  def end_holding
    if @hovered_pokemon
      @hovered_pokemon.set_hovered(false)
    end

    @holding = false
    @hovered_pokemon = nil

    refresh_graphic
  end

  def holding?
    return @holding
  end

  def refresh_graphic
    new_state = if @holding
                  :holding
                elsif @hovered_pokemon
                  :hover
                else
                  :normal
                end

    return if @visual_state == new_state

    @visual_state = new_state
    @sprite.bitmap.clear

    case @visual_state
    when :holding
      color = Color.new(255, 150, 40)
    when :hover
      color = Color.new(255, 215, 70)
    else
      color = Color.new(255, 255, 255)
    end

    width = @sprite.bitmap.width
    height = @sprite.bitmap.height
    thickness = 3

    @sprite.bitmap.fill_rect(
      0,
      0,
      width,
      thickness,
      color
    )

    @sprite.bitmap.fill_rect(
      0,
      height - thickness,
      width,
      thickness,
      color
    )

    @sprite.bitmap.fill_rect(
      0,
      0,
      thickness,
      height,
      color
    )

    @sprite.bitmap.fill_rect(
      width - thickness,
      0,
      thickness,
      height,
      color
    )
  end

  def dispose
    if @hovered_pokemon
      @hovered_pokemon.set_hovered(false)
    end

    @sprite.bitmap.dispose if @sprite.bitmap
    @sprite.dispose if !@sprite.disposed?
  end
end


#===============================================================================
# Island Interaction Controller
#===============================================================================
class IslandInteractionController
  def initialize(cursor)
    @cursor = cursor
    @held_pokemon = nil
    @original_x = nil
    @original_y = nil
  end

  def update
    update_held_pokemon

    if Input.trigger?(Input::C)
      if @held_pokemon && @held_pokemon.held?
        drop_pokemon
      elsif !holding?
        pickup_pokemon
      end
    end

    finish_drop_if_needed
  end

  def pickup_pokemon
    pokemon = @cursor.hovered_pokemon

    return if !pokemon
    return if !pokemon.grounded?

    @held_pokemon = pokemon

    @original_x = pokemon.x
    @original_y = pokemon.y

    @held_pokemon.begin_held

    @cursor.begin_holding(
      @held_pokemon
    )
  end

  def update_held_pokemon
    return if !@held_pokemon
    return if !@held_pokemon.carrying?

    @held_pokemon.move_held_to(
      @cursor.x,
      @cursor.y
    )
  end

  def drop_pokemon
    return if !@held_pokemon
    return if !@held_pokemon.held?

    @held_pokemon.begin_drop
  end

  def cancel_pickup
    return if !@held_pokemon
    return if @held_pokemon.dropping?

    @held_pokemon.cancel_to(
      @original_x,
      @original_y
    )
  end

  def finish_drop_if_needed
    return if !@held_pokemon
    return if !@held_pokemon.grounded?

    @held_pokemon = nil
    @original_x = nil
    @original_y = nil

    @cursor.end_holding
  end

  def holding?
    return !@held_pokemon.nil?
  end
end


#===============================================================================
# Pokémon Island Screen
#===============================================================================
class PokemonIslandScreen
  def self.open
    screen = PokemonIslandScreen.new
    screen.main
  end

  def initialize
    @viewport = Viewport.new(
      0,
      0,
      Graphics.width,
      Graphics.height
    )

    @viewport.z = 99999

    @background_sprite = nil
    @island_pokemon = []
    @cursor = nil
    @interaction = nil

    @current_box = 0

    @a_was_pressed = false
    @d_was_pressed = false
  end

  def main
    create_background
    load_box(@current_box)

    @cursor = IslandCursor.new(@viewport)

    @interaction = IslandInteractionController.new(
      @cursor
    )

    loop do
      Graphics.update
      Input.update
      update

      if Input.trigger?(Input::B)
        if @interaction.holding?
          @interaction.cancel_pickup
        else
          break
        end
      end
    end

    dispose
  end

  def create_background
    bitmap = Bitmap.new(
      Graphics.width,
      Graphics.height
    )

    bitmap.fill_rect(
      0,
      0,
      Graphics.width,
      Graphics.height,
      Color.new(80, 160, 200)
    )

    edge_color = Color.new(100, 150, 70)
    grass_color = Color.new(145, 195, 95)

    bitmap.fill_rect(
      80,
      55,
      352,
      310,
      edge_color
    )

    bitmap.fill_rect(
      45,
      75,
      422,
      270,
      edge_color
    )

    bitmap.fill_rect(
      25,
      105,
      462,
      210,
      edge_color
    )

    bitmap.fill_rect(
      88,
      63,
      336,
      294,
      grass_color
    )

    bitmap.fill_rect(
      53,
      83,
      406,
      254,
      grass_color
    )

    bitmap.fill_rect(
      33,
      113,
      446,
      194,
      grass_color
    )

    @background_sprite = Sprite.new(@viewport)
    @background_sprite.bitmap = bitmap
    @background_sprite.z = 0
  end

  def load_box(box)
    @cursor.clear_hover if @cursor

    @island_pokemon.each do |island_pkmn|
      island_pkmn.dispose
    end

    @island_pokemon.clear

    positions = pokemon_positions
    visual_index = 0

    for storage_index in 0...$PokemonStorage.maxPokemon(box)
      pkmn = $PokemonStorage[box, storage_index]

      next if !pkmn

      position = positions[visual_index]

      break if !position

      island_pkmn = IslandPokemon.new(
        pkmn,
        box,
        storage_index,
        @viewport,
        position[0],
        position[1]
      )

      @island_pokemon.push(
        island_pkmn
      )

      visual_index += 1
    end
  end

  def pokemon_positions
    positions = []

    rows = [
      [66, 120, 6],
      [92, 175, 6],
      [66, 230, 6],
      [92, 285, 6],
      [66, 340, 6]
    ]

    rows.each do |row|
      start_x = row[0]
      y = row[1]
      count = row[2]

      spacing = (
        Graphics.width - (start_x * 2)
      ) / (count - 1)

      count.times do |i|
        x = start_x + (spacing * i)

        positions.push([
          x,
          y
        ])
      end
    end

    return positions
  end

  def update_island_navigation
    a_pressed = Input.pressex?("A")
    d_pressed = Input.pressex?("D")

    if !@interaction.holding?
      if a_pressed && !@a_was_pressed
        previous_island
      elsif d_pressed && !@d_was_pressed
        next_island
      end
    end

    @a_was_pressed = a_pressed
    @d_was_pressed = d_pressed
  end

  def previous_island
    @current_box -= 1

    if @current_box < 0
      @current_box = $PokemonStorage.maxBoxes - 1
    end

    p "Island PC: #{@current_box} - #{$PokemonStorage[@current_box].name}"

    load_box(@current_box)
  end

  def next_island
    @current_box += 1

    if @current_box >= $PokemonStorage.maxBoxes
      @current_box = 0
    end

    p "Island PC: #{@current_box} - #{$PokemonStorage[@current_box].name}"

    load_box(@current_box)
  end

  def update
    @island_pokemon.each do |island_pkmn|
      island_pkmn.update
    end

    @cursor.update(
      @island_pokemon
    ) if @cursor

    @interaction.update if @interaction

    update_island_navigation
  end

  def dispose
    if @cursor
      @cursor.dispose
      @cursor = nil
    end

    @interaction = nil

    @island_pokemon.each do |island_pkmn|
      island_pkmn.dispose
    end

    @island_pokemon.clear

    if @background_sprite
      if @background_sprite.bitmap
        @background_sprite.bitmap.dispose
      end

      if !@background_sprite.disposed?
        @background_sprite.dispose
      end
    end

    @viewport.dispose if @viewport
  end
end