#===============================================================================
# Pokémon Bushido - Town Map
#===============================================================================

#===============================================================================
# Hover location bubble
#===============================================================================
class BushidoMapHoverSprite < SpriteWrapper
  PADDING_X      = 10
  PADDING_Y      = 6
  POINTER_HEIGHT = 5
  MIN_WIDTH      = 28
  CURSOR_GAP     = 12

  def initialize(viewport=nil)
    super(viewport)

    @text       = ""
    @anchor_x   = 0
    @anchor_y   = 0

    @thisbitmap = BitmapWrapper.new(
      Graphics.width,
      Graphics.height
    )

    self.bitmap  = @thisbitmap
    self.x       = 0
    self.y       = 0
    self.z       = 100
    self.visible = false

    pbSetSmallFont(@thisbitmap)
  end

  def dispose
    @thisbitmap.dispose
    super
  end

  def set_location(text,x,y)
    text = "" if !text

    return if @text == text &&
              @anchor_x == x &&
              @anchor_y == y

    @text     = text
    @anchor_x = x
    @anchor_y = y

    refresh
  end

  def refresh
    self.bitmap.clear

    if !@text || @text == ""
      self.visible = false
      return
    end

    self.visible = true
    pbSetSmallFont(self.bitmap)

    text_size = self.bitmap.text_size(@text)

    bubble_width =
      text_size.width +
      (PADDING_X * 2)

    bubble_width =
      MIN_WIDTH if bubble_width < MIN_WIDTH

    bubble_height =
      text_size.height +
      (PADDING_Y * 2)

    bubble_x =
      @anchor_x -
      (bubble_width / 2)

    bubble_y =
      @anchor_y -
      bubble_height -
      POINTER_HEIGHT -
      CURSOR_GAP

    # Keep bubble inside the screen horizontally.
    if bubble_x < 4
      bubble_x = 4

    elsif bubble_x + bubble_width >
          Graphics.width - 4

      bubble_x =
        Graphics.width -
        bubble_width -
        4
    end

    pointer_up = false

    # If there isn't enough space above,
    # place it underneath the cursor instead.
    if bubble_y < 4
      bubble_y =
        @anchor_y + 18

      pointer_up = true
    end

    bubble_color =
      Color.new(
        0,
        0,
        0,
        180
      )

    text_color =
      Color.new(
        255,
        255,
        255
      )

    transparent =
      Color.new(
        0,
        0,
        0,
        0
      )

    # Slightly softened rectangular bubble.
    self.bitmap.fill_rect(
      bubble_x + 2,
      bubble_y,
      bubble_width - 4,
      bubble_height,
      bubble_color
    )

    self.bitmap.fill_rect(
      bubble_x,
      bubble_y + 2,
      bubble_width,
      bubble_height - 4,
      bubble_color
    )

    pointer_center =
      @anchor_x

    min_pointer =
      bubble_x + 7

    max_pointer =
      bubble_x +
      bubble_width -
      7

    pointer_center =
      min_pointer if pointer_center < min_pointer

    pointer_center =
      max_pointer if pointer_center > max_pointer

    if pointer_up
      for i in 0...POINTER_HEIGHT
        width =
          1 + (i * 2)

        self.bitmap.fill_rect(
          pointer_center -
          (width / 2),

          bubble_y -
          POINTER_HEIGHT +
          i,

          width,
          1,

          bubble_color
        )
      end

    else
      for i in 0...POINTER_HEIGHT
        width =
          (POINTER_HEIGHT * 2) -
          (i * 2) -
          1

        self.bitmap.fill_rect(
          pointer_center -
          (width / 2),

          bubble_y +
          bubble_height +
          i,

          width,
          1,

          bubble_color
        )
      end
    end

    pbDrawTextPositions(
      self.bitmap,
      [
        [
          @text,

          bubble_x +
          (bubble_width / 2),

          bubble_y +
          PADDING_Y -
          2,

          2,

          text_color,
          transparent
        ]
      ]
    )
  end
end


#===============================================================================
# Location information panel
#===============================================================================
class BushidoMapLocationPanel < SpriteWrapper
  PANEL_WIDTH = 320
  BASE_HEIGHT = 132
  ROW_HEIGHT  = 22

  def initialize(viewport=nil)
    super(viewport)

    @thisbitmap = BitmapWrapper.new(
      Graphics.width,
      Graphics.height
    )

    self.bitmap  = @thisbitmap
    self.x       = 0
    self.y       = 0
    self.z       = 200
    self.visible = false
  end

  def dispose
    @thisbitmap.dispose
    super
  end

  def show_location(name,points,visited)
    self.bitmap.clear

    points = [] if !points

    point_rows =
      [points.length,1].max

    panel_height =
      BASE_HEIGHT +
      ((point_rows - 1) * ROW_HEIGHT)

    panel_height =
      270 if panel_height > 270

    panel_x =
      (Graphics.width - PANEL_WIDTH) / 2

    panel_y =
      (Graphics.height - panel_height) / 2

    # Darken map behind panel.
    self.bitmap.fill_rect(
      0,
      0,
      Graphics.width,
      Graphics.height,
      Color.new(0,0,0,80)
    )

    panel_color =
      Color.new(
        0,
        0,
        0,
        225
      )

    border_color =
      Color.new(
        255,
        255,
        255,
        65
      )

    white =
      Color.new(
        255,
        255,
        255
      )

    muted =
      Color.new(
        175,
        175,
        175
      )

    transparent =
      Color.new(
        0,
        0,
        0,
        0
      )

    # Main panel.
    self.bitmap.fill_rect(
      panel_x + 2,
      panel_y,
      PANEL_WIDTH - 4,
      panel_height,
      panel_color
    )

    self.bitmap.fill_rect(
      panel_x,
      panel_y + 2,
      PANEL_WIDTH,
      panel_height - 4,
      panel_color
    )

    # Thin border.
    self.bitmap.fill_rect(
      panel_x + 2,
      panel_y,
      PANEL_WIDTH - 4,
      1,
      border_color
    )

    self.bitmap.fill_rect(
      panel_x + 2,
      panel_y + panel_height - 1,
      PANEL_WIDTH - 4,
      1,
      border_color
    )

    self.bitmap.fill_rect(
      panel_x,
      panel_y + 2,
      1,
      panel_height - 4,
      border_color
    )

    self.bitmap.fill_rect(
      panel_x + PANEL_WIDTH - 1,
      panel_y + 2,
      1,
      panel_height - 4,
      border_color
    )

    #---------------------------------------------------------------------------
    # Location name
    #---------------------------------------------------------------------------
    pbSetSystemFont(self.bitmap)

    pbDrawTextPositions(
      self.bitmap,
      [
        [
          name,
          Graphics.width / 2,
          panel_y + 14,
          2,
          white,
          transparent
        ]
      ]
    )

    #---------------------------------------------------------------------------
    # Visit status
    #---------------------------------------------------------------------------
    pbSetSmallFont(self.bitmap)

    status =
      visited ?
      _INTL("Visited") :
      _INTL("Not Visited")

    pbDrawTextPositions(
      self.bitmap,
      [
        [
          status,
          Graphics.width / 2,
          panel_y + 47,
          2,
          visited ? white : muted,
          transparent
        ]
      ]
    )

    #---------------------------------------------------------------------------
    # Points of interest
    #---------------------------------------------------------------------------
    pbDrawTextPositions(
      self.bitmap,
      [
        [
          _INTL("POINTS OF INTEREST"),
          panel_x + 20,
          panel_y + 74,
          0,
          muted,
          transparent
        ]
      ]
    )

    y =
      panel_y + 98

    if points.length == 0
      pbDrawTextPositions(
        self.bitmap,
        [
          [
            _INTL("No recorded points of interest."),
            panel_x + 20,
            y,
            0,
            muted,
            transparent
          ]
        ]
      )

    else
      for point in points
        break if y >
                 panel_y +
                 panel_height -
                 20

        pbDrawTextPositions(
          self.bitmap,
          [
            [
              "• " + point,
              panel_x + 20,
              y,
              0,
              white,
              transparent
            ]
          ]
        )

        y += ROW_HEIGHT
      end
    end

    self.visible = true
  end

  def hide
    self.visible = false
    self.bitmap.clear
  end
end


#===============================================================================
# Region Map scene
#===============================================================================
class PokemonRegionMap_Scene
  LEFT   = 0
  TOP    = 0
  RIGHT  = 29
  BOTTOM = 19

  SQUAREWIDTH  = 16
  SQUAREHEIGHT = 16

  MAP_WIDTH  = 480
  MAP_HEIGHT = 320

  BORDER_X = 16
  BORDER_Y = 32

  def initialize(region=-1,wallmap=true)
    @region  = region
    @wallmap = wallmap
  end

  def pbUpdate
    pbUpdateSpriteHash(@sprites)
  end

  #-----------------------------------------------------------------------------
  # Start scene
  #-----------------------------------------------------------------------------
  def pbStartScene(aseditor=false,mode=0)
    @viewport = Viewport.new(
      0,
      0,
      Graphics.width,
      Graphics.height
    )

    @viewport.z = 99999

    @sprites = {}
    @mapdata = pbLoadTownMapData

    playerpos =
      (!$game_map) ?
      nil :
      pbGetMetadata(
        $game_map.map_id,
        MetadataMapPosition
      )

    if !playerpos
      mapindex = 0
      @map     = @mapdata[0]
      @mapX    = LEFT
      @mapY    = TOP

    elsif @region >= 0 &&
          @region != playerpos[0] &&
          @mapdata[@region]

      mapindex = @region
      @map     = @mapdata[@region]
      @mapX    = LEFT
      @mapY    = TOP

    else
      mapindex = playerpos[0]
      @map     = @mapdata[playerpos[0]]
      @mapX    = playerpos[1]
      @mapY    = playerpos[2]

      mapsize =
        (!$game_map) ?
        nil :
        pbGetMetadata(
          $game_map.map_id,
          MetadataMapSize
        )

      if mapsize &&
         mapsize[0] &&
         mapsize[0] > 0

        sqwidth =
          mapsize[0]

        sqheight =
          (
            mapsize[1].length *
            1.0 /
            mapsize[0]
          ).ceil

        if sqwidth > 1
          @mapX += (
            $game_player.x *
            sqwidth /
            $game_map.width
          ).floor
        end

        if sqheight > 1
          @mapY += (
            $game_player.y *
            sqheight /
            $game_map.height
          ).floor
        end
      end
    end

    @mapindex = mapindex

    if !@map
      pbMessage(
        _INTL(
          "The map data cannot be found."
        )
      )

      return false
    end

    #---------------------------------------------------------------------------
    # Border
    #
    # 512x384 game screen
    # 480x320 Town Map
    #
    # Remaining space:
    # Horizontal: 32 total = 16 left + 16 right
    # Vertical:   64 total = 32 top  + 32 bottom
    #---------------------------------------------------------------------------
    @sprites["border"] =
      BitmapSprite.new(
        Graphics.width,
        Graphics.height,
        @viewport
      )

    @sprites["border"].bitmap.fill_rect(
      0,
      0,
      Graphics.width,
      Graphics.height,
      Color.new(0,0,0)
    )

    @sprites["border"].z = 0

    #---------------------------------------------------------------------------
    # Region map
    #
    # Native 480x320. Never stretched.
    #---------------------------------------------------------------------------
    @sprites["map"] =
      IconSprite.new(
        0,
        0,
        @viewport
      )

    @sprites["map"].setBitmap(
      "Graphics/Pictures/#{@map[1]}"
    )

    @sprites["map"].x =
      BORDER_X

    @sprites["map"].y =
      BORDER_Y

    @sprites["map"].z = 1

    #---------------------------------------------------------------------------
    # Hidden / conditional map graphics
    #
    # Restores the original REGION_MAP_EXTRAS behavior.
    #
    # hidden[0] = region
    # hidden[1] = switch
    # hidden[2] = map X
    # hidden[3] = map Y
    # hidden[4] = graphic
    # hidden[5] = show on wall map
    #---------------------------------------------------------------------------
    for hidden in REGION_MAP_EXTRAS
      next if hidden[0] != mapindex

      show_extra = false

      # Wall maps can explicitly show an extra regardless
      # of the normal story switch.
      if @wallmap &&
         hidden[5]

        show_extra = true

      # Normal Town Map only shows it once its switch is on.
      elsif !@wallmap &&
            hidden[1] &&
            hidden[1] > 0 &&
            $game_switches[hidden[1]]

        show_extra = true
      end

      next if !show_extra

      if !@sprites["map2"]
        @sprites["map2"] =
          BitmapSprite.new(
            @sprites["map"].bitmap.width,
            @sprites["map"].bitmap.height,
            @viewport
          )

        @sprites["map2"].x =
          @sprites["map"].x

        @sprites["map2"].y =
          @sprites["map"].y

        @sprites["map2"].z = 2
      end

      pbDrawImagePositions(
        @sprites["map2"].bitmap,
        [
          [
            "Graphics/Pictures/#{hidden[4]}",
            hidden[2] * SQUAREWIDTH,
            hidden[3] * SQUAREHEIGHT
          ]
        ]
      )
    end

    #---------------------------------------------------------------------------
    # Roaming Pokémon
    #---------------------------------------------------------------------------
    drawRoamingPosition(
      mapindex
    )

    #---------------------------------------------------------------------------
    # Player marker
    #---------------------------------------------------------------------------
    if playerpos &&
       mapindex == playerpos[0]

      @sprites["player"] =
        IconSprite.new(
          0,
          0,
          @viewport
        )

      @sprites["player"].setBitmap(
        pbPlayerHeadFile(
          $Trainer.trainertype
        )
      )

      @sprites["player"].x =
        -(SQUAREWIDTH)/2 +
        (@mapX * SQUAREWIDTH) +
        @sprites["map"].x -
        (
          @sprites["player"].bitmap.width -
          (SQUAREWIDTH * 2)
        )

      @sprites["player"].y =
        -(SQUAREHEIGHT)/2 +
        (@mapY * SQUAREHEIGHT) +
        @sprites["map"].y -
        (
          @sprites["player"].bitmap.height -
          (SQUAREHEIGHT * 2)
        )

      @sprites["player"].z = 20
    end

    #---------------------------------------------------------------------------
    # Fly markers
    #---------------------------------------------------------------------------
    if mode > 0
      k = 0

      for i in LEFT..RIGHT
        for j in TOP..BOTTOM
          healspot =
            pbGetHealingSpot(
              i,
              j
            )

          next if !healspot

          # Hidden locations shouldn't expose themselves as Fly points.
          next if !pbTownMapPointVisible?(
            i,
            j
          )

          next if !$PokemonGlobal.visitedMaps[
            healspot[0]
          ]

          @sprites["point#{k}"] =
            AnimatedSprite.create(
              "Graphics/Pictures/mapFly",
              2,
              16
            )

          @sprites["point#{k}"].viewport =
            @viewport

          @sprites["point#{k}"].x =
            -SQUAREWIDTH/2 +
            (i * SQUAREWIDTH) +
            @sprites["map"].x

          @sprites["point#{k}"].y =
            -SQUAREHEIGHT/2 +
            (j * SQUAREHEIGHT) +
            @sprites["map"].y

          @sprites["point#{k}"].z = 15

          @sprites["point#{k}"].play

          k += 1
        end
      end
    end

    #---------------------------------------------------------------------------
    # Cursor
    #---------------------------------------------------------------------------
    @sprites["cursor"] =
      AnimatedSprite.create(
        "Graphics/Pictures/mapCursor",
        2,
        5
      )

    @sprites["cursor"].viewport =
      @viewport

    @sprites["cursor"].x =
      -SQUAREWIDTH/2 +
      (@mapX * SQUAREWIDTH) +
      @sprites["map"].x

    @sprites["cursor"].y =
      -SQUAREHEIGHT/2 +
      (@mapY * SQUAREHEIGHT) +
      @sprites["map"].y

    @sprites["cursor"].z = 30

    @sprites["cursor"].play

    #---------------------------------------------------------------------------
    # Hover bubble
    #---------------------------------------------------------------------------
    @sprites["hover"] =
      BushidoMapHoverSprite.new(
        @viewport
      )

    #---------------------------------------------------------------------------
    # Location information panel
    #---------------------------------------------------------------------------
    @sprites["locationPanel"] =
      BushidoMapLocationPanel.new(
        @viewport
      )

    pbRefreshHoverLabel

    pbFadeInAndShow(@sprites) {
      pbUpdate
    }

    return true
  end

  #-----------------------------------------------------------------------------
  # End scene
  #-----------------------------------------------------------------------------
  def pbEndScene
    pbFadeOutAndHide(@sprites)

    pbDisposeSpriteHash(
      @sprites
    )

    @viewport.dispose
  end

  #-----------------------------------------------------------------------------
  # Is a Town Map point currently visible?
  #-----------------------------------------------------------------------------
  def pbTownMapPointVisible?(x,y)
    return false if !@map[2]

    for loc in @map[2]
      next if loc[0] != x
      next if loc[1] != y

      # No switch requirement.
      return true if !loc[7] ||
                     loc[7] == 0

      # Hidden points only become visible on the player's
      # normal map once their switch has been enabled.
      if !@wallmap &&
         $game_switches[loc[7]]

        return true
      end
    end

    return false
  end

  #-----------------------------------------------------------------------------
  # Get location name
  #-----------------------------------------------------------------------------
  def pbGetMapLocation(x,y)
    return "" if !@map[2]

    for loc in @map[2]
      next if loc[0] != x
      next if loc[1] != y

      # Respect hidden Town Map points.
      if loc[7] &&
         loc[7] != 0

        if @wallmap
          return ""
        end

        if !$game_switches[loc[7]]
          return ""
        end
      end

      name =
        pbGetMessageFromHash(
          MessageTypes::PlaceNames,
          loc[2]
        )

      # Bushido's existing Yami Island story rule.
      if name.include?("Yami") &&
         $game_switches[155] == false

        return ""
      end

      return name
    end

    return ""
  end

  #-----------------------------------------------------------------------------
  # Location description / landmark
  #-----------------------------------------------------------------------------
  def pbGetMapDetails(x,y)
    return "" if !@map[2]

    for loc in @map[2]
      next if loc[0] != x
      next if loc[1] != y

      if loc[7] &&
         loc[7] != 0

        if @wallmap
          return ""
        end

        if !$game_switches[loc[7]]
          return ""
        end
      end

      return pbGetMessageFromHash(
        MessageTypes::PlaceDescriptions,
        loc[3]
      )
    end

    return ""
  end

  #-----------------------------------------------------------------------------
  # Get every landmark/POI belonging to a location
  #
  # Town Map Point format:
  #
  # Point=X,Y,Location Name,Landmark,FlyMap,FlyX,FlyY,Switch
  #
  # If multiple Point entries use the same location name, all of their
  # landmarks are collected here.
  #-----------------------------------------------------------------------------
  def pbGetPointsOfInterest(x,y)
    return [] if !@map[2]

    location_name =
      pbGetMapLocation(
        x,
        y
      )

    return [] if !location_name ||
                 location_name == ""

    points = []

    for loc in @map[2]
      # Respect hidden points.
      if loc[7] &&
         loc[7] != 0

        next if @wallmap
        next if !$game_switches[loc[7]]
      end

      this_name =
        pbGetMessageFromHash(
          MessageTypes::PlaceNames,
          loc[2]
        )

      next if this_name != location_name

      landmark =
        pbGetMessageFromHash(
          MessageTypes::PlaceDescriptions,
          loc[3]
        )

      next if !landmark
      next if landmark == ""
      next if points.include?(landmark)

      points.push(
        landmark
      )
    end

    return points
  end

  #-----------------------------------------------------------------------------
  # Fly destination
  #-----------------------------------------------------------------------------
  def pbGetHealingSpot(x,y)
    return nil if !@map[2]

    for loc in @map[2]
      next if loc[0] != x
      next if loc[1] != y

      if !loc[4] ||
         !loc[5] ||
         !loc[6]

        return nil
      end

      return [
        loc[4],
        loc[5],
        loc[6]
      ]
    end

    return nil
  end

  #-----------------------------------------------------------------------------
  # Check whether a location has been visited
  #-----------------------------------------------------------------------------
  def pbLocationVisited?(x,y)
    # Current player location.
    if $game_map
      playerpos =
        pbGetMetadata(
          $game_map.map_id,
          MetadataMapPosition
        )

      if playerpos &&
         playerpos[0] == @mapindex

        current_x =
          playerpos[1]

        current_y =
          playerpos[2]

        mapsize =
          pbGetMetadata(
            $game_map.map_id,
            MetadataMapSize
          )

        if mapsize &&
           mapsize[0] &&
           mapsize[0] > 0

          sqwidth =
            mapsize[0]

          sqheight =
            (
              mapsize[1].length *
              1.0 /
              mapsize[0]
            ).ceil

          if sqwidth > 1
            current_x += (
              $game_player.x *
              sqwidth /
              $game_map.width
            ).floor
          end

          if sqheight > 1
            current_y += (
              $game_player.y *
              sqheight /
              $game_map.height
            ).floor
          end
        end

        if current_x == x &&
           current_y == y

          return true
        end
      end
    end

    # Fly destination provides an exact associated map.
    healspot =
      pbGetHealingSpot(
        x,
        y
      )

    if healspot &&
       $PokemonGlobal.visitedMaps[
         healspot[0]
       ]

      return true
    end

    # Check every previously visited map whose
    # MetadataMapPosition overlaps this Town Map cell.
    begin
      mapinfos =
        load_data(
          "Data/MapInfos.rxdata"
        )

      for map_id in mapinfos.keys
        next if !$PokemonGlobal.visitedMaps[
          map_id
        ]

        pos =
          pbGetMetadata(
            map_id,
            MetadataMapPosition
          )

        next if !pos
        next if pos[0] != @mapindex

        map_x =
          pos[1]

        map_y =
          pos[2]

        mapsize =
          pbGetMetadata(
            map_id,
            MetadataMapSize
          )

        if mapsize &&
           mapsize[0] &&
           mapsize[0] > 0

          sqwidth =
            mapsize[0]

          sqheight =
            (
              mapsize[1].length *
              1.0 /
              mapsize[0]
            ).ceil

          if x >= map_x &&
             x < map_x + sqwidth &&
             y >= map_y &&
             y < map_y + sqheight

            return true
          end

        elsif map_x == x &&
              map_y == y

          return true
        end
      end

    rescue
    end

    return false
  end

  #-----------------------------------------------------------------------------
  # Hover bubble
  #-----------------------------------------------------------------------------
  def pbRefreshHoverLabel(anchor_x=nil,anchor_y=nil)
    name =
      pbGetMapLocation(
        @mapX,
        @mapY
      )

    if anchor_x.nil? ||
       anchor_y.nil?

      anchor_x =
        @sprites["cursor"].x +
        SQUAREWIDTH

      anchor_y =
        @sprites["cursor"].y +
        SQUAREHEIGHT
    end

    @sprites["hover"].set_location(
      name,
      anchor_x,
      anchor_y
    )
  end

  #-----------------------------------------------------------------------------
  # Location panel
  #-----------------------------------------------------------------------------
  def pbShowLocationPanel
    name =
      pbGetMapLocation(
        @mapX,
        @mapY
      )

    return if !name ||
              name == ""

    points =
      pbGetPointsOfInterest(
        @mapX,
        @mapY
      )

    visited =
      pbLocationVisited?(
        @mapX,
        @mapY
      )

    @sprites["hover"].visible =
      false

    @sprites["locationPanel"].show_location(
      name,
      points,
      visited
    )

    pbPlayDecisionSE

    loop do
      Graphics.update
      Input.update
      pbUpdate

      if Input.trigger?(Input::B) ||
         Input.trigger?(Input::C)

        pbPlayCancelSE

        @sprites["locationPanel"].hide

        pbRefreshHoverLabel

        break
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Main map loop
  #-----------------------------------------------------------------------------
  def pbMapScene(mode=0)
    xOffset = 0.0
    yOffset = 0.0
    newX    = 0.0
    newY    = 0.0

    @sprites["cursor"].x =
      -SQUAREWIDTH/2 +
      (@mapX * SQUAREWIDTH) +
      @sprites["map"].x

    @sprites["cursor"].y =
      -SQUAREHEIGHT/2 +
      (@mapY * SQUAREHEIGHT) +
      @sprites["map"].y

    pbRefreshHoverLabel

    loop do
      Graphics.update
      Input.update
      pbUpdate

      #-------------------------------------------------------------------------
      # Smooth cursor movement
      #-------------------------------------------------------------------------
      if xOffset != 0 ||
         yOffset != 0

        distancePerFrame =
          8.0 *
          20.0 /
          Graphics.frame_rate

        if xOffset > 0
          xOffset -=
            distancePerFrame

          xOffset =
            0 if xOffset < 0

        elsif xOffset < 0
          xOffset +=
            distancePerFrame

          xOffset =
            0 if xOffset > 0
        end

        if yOffset > 0
          yOffset -=
            distancePerFrame

          yOffset =
            0 if yOffset < 0

        elsif yOffset < 0
          yOffset +=
            distancePerFrame

          yOffset =
            0 if yOffset > 0
        end

        @sprites["cursor"].x =
          newX - xOffset

        @sprites["cursor"].y =
          newY - yOffset

        # Bubble travels with cursor.
        pbRefreshHoverLabel(
          @sprites["cursor"].x +
          SQUAREWIDTH,

          @sprites["cursor"].y +
          SQUAREHEIGHT
        )

        next
      end

      pbRefreshHoverLabel

      ox = 0
      oy = 0

      case Input.dir8
      when 1
        oy = 1 if @mapY < BOTTOM
        ox = -1 if @mapX > LEFT

      when 2
        oy = 1 if @mapY < BOTTOM

      when 3
        oy = 1 if @mapY < BOTTOM
        ox = 1 if @mapX < RIGHT

      when 4
        ox = -1 if @mapX > LEFT

      when 6
        ox = 1 if @mapX < RIGHT

      when 7
        oy = -1 if @mapY > TOP
        ox = -1 if @mapX > LEFT

      when 8
        oy = -1 if @mapY > TOP

      when 9
        oy = -1 if @mapY > TOP
        ox = 1 if @mapX < RIGHT
      end

      #-------------------------------------------------------------------------
      # Begin movement
      #-------------------------------------------------------------------------
      if ox != 0 ||
         oy != 0

        @mapX += ox
        @mapY += oy

        oldX =
          @sprites["cursor"].x

        oldY =
          @sprites["cursor"].y

        newX =
          -SQUAREWIDTH/2 +
          (@mapX * SQUAREWIDTH) +
          @sprites["map"].x

        newY =
          -SQUAREHEIGHT/2 +
          (@mapY * SQUAREHEIGHT) +
          @sprites["map"].y

        xOffset =
          newX - oldX

        yOffset =
          newY - oldY

        pbRefreshHoverLabel(
          @sprites["cursor"].x +
          SQUAREWIDTH,

          @sprites["cursor"].y +
          SQUAREHEIGHT
        )
      end

      #-------------------------------------------------------------------------
      # Back
      #-------------------------------------------------------------------------
      if Input.trigger?(Input::B)
        break

      #-------------------------------------------------------------------------
      # Confirm
      #-------------------------------------------------------------------------
      elsif Input.trigger?(Input::C)

        #-----------------------------------------------------------------------
        # Fly mode
        #-----------------------------------------------------------------------
        if mode == 1
          # Don't allow hidden destinations.
          next if !pbTownMapPointVisible?(
            @mapX,
            @mapY
          )

          healspot =
            pbGetHealingSpot(
              @mapX,
              @mapY
            )

          if healspot
            if $PokemonGlobal.visitedMaps[
                 healspot[0]
               ] ||
               (
                 $DEBUG &&
                 Input.press?(Input::CTRL)
               )

              return healspot
            end
          end

        #-----------------------------------------------------------------------
        # Normal Town Map
        #-----------------------------------------------------------------------
        else
          pbShowLocationPanel
        end
      end
    end

    pbPlayCloseMenuSE

    return nil
  end
end


#===============================================================================
# Region Map screen
#===============================================================================
class PokemonRegionMapScreen
  def initialize(scene)
    @scene = scene
  end

  #-----------------------------------------------------------------------------
  # Fly
  #-----------------------------------------------------------------------------
  def pbStartFlyScreen
    @scene.pbStartScene(
      false,
      1
    )

    ret =
      @scene.pbMapScene(
        1
      )

    @scene.pbEndScene

    return ret
  end

  #-----------------------------------------------------------------------------
  # Normal Town Map
  #-----------------------------------------------------------------------------
  def pbStartScreen
    @scene.pbStartScene(
      false,
      0
    )

    @scene.pbMapScene(
      0
    )

    @scene.pbEndScene
  end
end


#===============================================================================
# Show Town Map
#===============================================================================
def pbShowMap(region=-1,wallmap=true)
  pbFadeOutIn {
    scene =
      PokemonRegionMap_Scene.new(
        region,
        wallmap
      )

    screen =
      PokemonRegionMapScreen.new(
        scene
      )

    screen.pbStartScreen
  }
end