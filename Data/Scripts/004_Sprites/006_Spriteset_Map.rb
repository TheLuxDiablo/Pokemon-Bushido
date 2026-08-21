#===============================================================================
# ** ClippableSprite
#===============================================================================
class ClippableSprite < Sprite_Character
  def initialize(viewport, event, tilemap)
    @tilemap  = tilemap
    @_src_rect = Rect.new(0, 0, 0, 0)
    super(viewport, event)
  end

  def update
    super
    return if !@tilemap || !@tilemap.map_data

    @_src_rect = self.src_rect

    tmright = @tilemap.map_data.xsize * Game_Map::TILE_WIDTH - @tilemap.ox

    if @tilemap.ox - self.ox < -self.x
      # Clipped on left.
      diff = -self.x - @tilemap.ox + self.ox

      width = @_src_rect.width - diff
      width = 0 if width < 0

      self.src_rect = Rect.new(
        @_src_rect.x + diff,
        @_src_rect.y,
        width,
        @_src_rect.height
      )
    elsif tmright - self.ox < self.x
      # Clipped on right.
      diff = self.x - tmright + self.ox

      width = @_src_rect.width - diff
      width = 0 if width < 0

      self.src_rect = Rect.new(
        @_src_rect.x,
        @_src_rect.y,
        width,
        @_src_rect.height
      )
    end
  end
end


#===============================================================================
# ** Spriteset_Map
#===============================================================================
class Spriteset_Map
  attr_reader   :map
  attr_accessor :tilemap

  # These viewports are shared between every loaded map spriteset.
  @@viewport0 = Viewport.new(0, 0, Graphics.width, Graphics.height)
  @@viewport0.z = -100

  @@viewport1 = Viewport.new(0, 0, Graphics.width, Graphics.height)
  @@viewport1.z = 0

  @@viewport3 = Viewport.new(0, 0, Graphics.width, Graphics.height)
  @@viewport3.z = 500


  #-----------------------------------------------------------------------------
  # Accessed by Spriteset_Global.
  #-----------------------------------------------------------------------------
  def self.viewport
    return @@viewport1
  end


  #-----------------------------------------------------------------------------
  # Reset shared viewport state.
  #
  # The viewport itself survives between maps, so none of the previous map's
  # position/clipping state should be allowed to carry into the next one.
  #-----------------------------------------------------------------------------
  def self.resetViewports
    @@viewport0.rect.set(0, 0, Graphics.width, Graphics.height)
    @@viewport0.ox = 0
    @@viewport0.oy = 0

    @@viewport1.rect.set(0, 0, Graphics.width, Graphics.height)
    @@viewport1.ox = 0
    @@viewport1.oy = 0

    @@viewport3.rect.set(0, 0, Graphics.width, Graphics.height)
    @@viewport3.ox = 0
    @@viewport3.oy = 0
  end


  #-----------------------------------------------------------------------------
  # Initialize.
  #-----------------------------------------------------------------------------
  def initialize(map = nil)
    @map = map ? map : $game_map

    # Shared viewports may contain state from the previously loaded map.
    Spriteset_Map.resetViewports

    @tilemap = TilemapLoader.new(@@viewport1)
    @tilemap.tileset = pbGetTileset(@map.tileset_name)

    for i in 0...7
      autotile_name = @map.autotile_names[i]
      @tilemap.autotiles[i] = pbGetAutotile(autotile_name)
    end

    @tilemap.map_data      = @map.data
    @tilemap.priorities    = @map.priorities
    @tilemap.terrain_tags  = @map.terrain_tags

    @panorama = AnimatedPlane.new(@@viewport0)

    @fog = AnimatedPlane.new(@@viewport1)
    @fog.z = 3000

    @character_sprites = []

    for i in @map.events.keys.sort
      sprite = Sprite_Character.new(@@viewport1, @map.events[i])
      @character_sprites.push(sprite)
    end

    @weather = RPG::Weather.new(@@viewport1)

    pbOnSpritesetCreate(self, @@viewport1)

    update
  end


  #-----------------------------------------------------------------------------
  # Dispose.
  #-----------------------------------------------------------------------------
  def dispose
    # Characters first, since they reference the map viewport.
    if @character_sprites
      for sprite in @character_sprites
        next if !sprite
        sprite.dispose if !sprite.disposed?
      end
      @character_sprites.clear
    end

    if @weather
      @weather.dispose
      @weather = nil
    end

    if @panorama
      @panorama.dispose
      @panorama = nil
    end

    if @fog
      @fog.dispose
      @fog = nil
    end

    if @tilemap
      # Keep the normal Essentials bitmap cleanup behavior.
      if @tilemap.tileset
        @tilemap.tileset.dispose if !@tilemap.tileset.disposed?
      end

      for i in 0...7
        autotile = @tilemap.autotiles[i]
        next if !autotile
        autotile.dispose if !autotile.disposed?
      end

      @tilemap.dispose
      @tilemap = nil
    end

    @character_sprites = []

    # The viewport itself is shared and isn't disposed, but its old map state
    # must not survive this spriteset.
    Spriteset_Map.resetViewports
  end


  #-----------------------------------------------------------------------------
  # Animation handling.
  #-----------------------------------------------------------------------------
  def getAnimations
    return @usersprites
  end


  def restoreAnimations(anims)
    @usersprites = anims
  end


  #-----------------------------------------------------------------------------
  # Update.
  #-----------------------------------------------------------------------------
  def update
    return if !@map
    return if !@tilemap

    #-------------------------------------------------------------------------
    # Panorama
    #-------------------------------------------------------------------------
    if @panorama_name != @map.panorama_name ||
       @panorama_hue != @map.panorama_hue

      @panorama_name = @map.panorama_name
      @panorama_hue  = @map.panorama_hue

      @panorama.setPanorama(nil) if @panorama.bitmap != nil

      if @panorama_name != ""
        @panorama.setPanorama(@panorama_name, @panorama_hue)
      end

      Graphics.frame_reset
    end

    #-------------------------------------------------------------------------
    # Fog
    #-------------------------------------------------------------------------
    if @fog_name != @map.fog_name ||
       @fog_hue != @map.fog_hue

      @fog_name = @map.fog_name
      @fog_hue  = @map.fog_hue

      @fog.setFog(nil) if @fog.bitmap != nil

      if @fog_name != ""
        @fog.setFog(@fog_name, @fog_hue)
      end

      Graphics.frame_reset
    end

    #-------------------------------------------------------------------------
    # Map position
    #-------------------------------------------------------------------------
    tmox = (@map.display_x / Game_Map::X_SUBPIXELS).round
    tmoy = (@map.display_y / Game_Map::Y_SUBPIXELS).round

    @tilemap.ox = tmox
    @tilemap.oy = tmoy

    # IMPORTANT:
    #
    # MapFactory can keep several Spriteset_Map objects alive at once.
    # They all use @@viewport1.
    #
    # Letting each individual map resize that shared viewport means the last
    # map updated controls clipping for every other loaded map.
    #
    # Keep the shared viewport fullscreen instead.
    @@viewport1.rect.set(
      0,
      0,
      Graphics.width,
      Graphics.height
    )

    @@viewport1.ox = $game_screen.shake
    @@viewport1.oy = 0

    @tilemap.update

    #-------------------------------------------------------------------------
    # Panorama position
    #-------------------------------------------------------------------------
    @panorama.ox = tmox / 2
    @panorama.oy = tmoy / 2

    #-------------------------------------------------------------------------
    # Fog position/settings
    #-------------------------------------------------------------------------
    @fog.ox         = tmox + @map.fog_ox
    @fog.oy         = tmoy + @map.fog_oy
    @fog.zoom_x     = @map.fog_zoom / 100.0
    @fog.zoom_y     = @map.fog_zoom / 100.0
    @fog.opacity    = @map.fog_opacity
    @fog.blend_type = @map.fog_blend_type
    @fog.tone       = @map.fog_tone

    @panorama.update
    @fog.update

    #-------------------------------------------------------------------------
    # Characters
    #-------------------------------------------------------------------------
    for sprite in @character_sprites
      sprite.update
    end

    #-------------------------------------------------------------------------
    # Weather
    #-------------------------------------------------------------------------
    if self.map != $game_map
      if @weather.max > 0
        @weather.max -= 2

        if @weather.max <= 0
          @weather.max  = 0
          @weather.type = 0
          @weather.ox   = 0
          @weather.oy   = 0
        end
      end
    else
      @weather.type = $game_screen.weather_type
      @weather.max  = $game_screen.weather_max
      @weather.ox   = tmox
      @weather.oy   = tmoy
    end

    @weather.update

    #-------------------------------------------------------------------------
    # Screen effects
    #-------------------------------------------------------------------------
    @@viewport1.tone  = $game_screen.tone
    @@viewport3.color = $game_screen.flash_color

    @@viewport1.update
    @@viewport3.update
  end
end