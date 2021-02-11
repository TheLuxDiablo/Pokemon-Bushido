class TilemapLoader
  def initialize(viewport)
    @viewport = viewport
    @tilemap  = nil
    @color    = Color.new(0,0,0,0)
    @tone     = Tone.new(0,0,0,0)
    updateClass
  end

  def updateClass
    case $PokemonSystem.tilemap
    when 1   # Custom (recommended)
      setClass(CustomTilemap)
    when 2   # Perspective
      setClass(Draw_Tilemap)
    else     # Original (SynchronizedTilemap) or custom (CustomTilemap)
      if Tilemap.method_defined?(:passages)
        setClass(CustomTilemap)
      else
        if mkxp?
          setClass(SynchronizedTilemap)
        else
          setClass(($ResizeFactor==1.0) ? SynchronizedTilemap : CustomTilemap)
        end
      end
    end
  end

  def setClass(cls)
    newtilemap = cls.new(@viewport)
    if @tilemap
      newtilemap.tileset      = @tilemap.tileset
      newtilemap.map_data     = @tilemap.map_data
      newtilemap.flash_data   = @tilemap.flash_data
      newtilemap.priorities   = @tilemap.priorities
      newtilemap.terrain_tags = @tilemap.terrain_tags
      newtilemap.visible      = @tilemap.visible
      newtilemap.ox           = @tilemap.ox
      newtilemap.oy           = @tilemap.oy
      for i in 0...7
        newtilemap.autotiles[i] = @tilemap.autotiles[i]
      end
      @tilemap.dispose
      @tilemap = newtilemap
      newtilemap.update if cls!=SynchronizedTilemap
    else
      @tilemap = newtilemap
    end
  end

  def dispose;          @tilemap.dispose;                       end
  def disposed?;        @tilemap && @tilemap.disposed?;         end
  def update;           @tilemap.update;                        end
  def viewport;         @tilemap.viewport;                      end
  def autotiles;        @tilemap.autotiles;                     end
  def tileset;          @tilemap.tileset;                       end
  def tileset=(v);      @tilemap.tileset = v;                   end
  def map_data;         @tilemap.map_data;                      end
  def map_data=(v);     @tilemap.map_data = v;                  end
  def flash_data;       @tilemap.flash_data;                    end
  def flash_data=(v);   @tilemap.flash_data = v;                end
  def priorities;       @tilemap.priorities;                    end
  def priorities=(v);   @tilemap.priorities = v;                end
  def terrain_tags;     (@tilemap.terrain_tags rescue nil);     end
  def terrain_tags=(v); (@tilemap.terrain_tags = v rescue nil); end
  def visible;          @tilemap.visible;                       end
  def visible=(v);      @tilemap.visible = v;                   end
  def tone;             (@tilemap.tone rescue @tone);           end
  def tone=(value);     (@tilemap.tone = value rescue nil);     end
  def ox;               @tilemap.ox;                            end
  def ox=(v);           @tilemap.ox = v;                        end
  def oy;               @tilemap.oy;                            end
  def oy=(v);           @tilemap.oy = v;                        end
end
