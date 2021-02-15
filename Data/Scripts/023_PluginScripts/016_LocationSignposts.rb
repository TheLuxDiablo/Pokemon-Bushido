################################################################################
# Location signpost - Updated by LostSoulsDev / carmaniac & PurpleZaffre
################################################################################
class LocationWindow
  def initialize(name)
    @sprites = {}

    @sprites["overlay"]=Sprite.new
    @sprites["overlay"].bitmap=Bitmap.new(Graphics.width*4,Graphics.height*4)
    @sprites["overlay"].z=9999999
    pbSetSystemFont(@sprites["overlay"].bitmap)
    @overlay = @sprites["overlay"].bitmap
    @overlay.clear
    @baseColor=Color.new(0,0,0)
    @shadowColor=Color.new(148,148,165)

    @sprites["Image"] = Sprite.new
    if $game_map.name.include?("Route")
      @sprites["Image"].bitmap = BitmapCache.load_bitmap("Graphics/Maps/Route_1")
    elsif $game_map.name.include?("Town")
      @sprites["Image"].bitmap = BitmapCache.load_bitmap("Graphics/Maps/Town_1")
    elsif $game_map.name.include?("Lake")
      @sprites["Image"].bitmap = BitmapCache.load_bitmap("Graphics/Maps/Lake_1")
    elsif $game_map.name.include?("Cave")
      @sprites["Image"].bitmap = BitmapCache.load_bitmap("Graphics/Maps/Cave_1")
    elsif $game_map.name.include?("City")
      @sprites["Image"].bitmap = BitmapCache.load_bitmap("Graphics/Maps/City_1")
    else
      @sprites["Image"].bitmap = BitmapCache.load_bitmap("Graphics/Maps/Blank")
    end
    @sprites["Image"].x = 8
    @sprites["Image"].y = 0 - @sprites["Image"].bitmap.height
    @sprites["Image"].z = 99999

    @window=Window_AdvancedTextPokemon.new(name)
    @window.x=0
    @window.y=-@window.height
    @window.z=99999
    @currentmap=$game_map.map_id
    @frames=0
  end

  def disposed?
    @window.disposed?
  end

  def dispose
    @window.dispose
    @sprites["Image"].dispose
    @overlay.dispose
  end

  def update
    return if @window.disposed?
    @window.update
    @sprites["overlay"].update
    if $game_temp.message_window_showing ||
       @currentmap!=$game_map.map_id
      @window.dispose
      @sprites["Image"].dispose
      @overlay.dispose
      return
    end
    if @frames>120
      @sprites["Image"].y-= ((@sprites["Image"].bitmap.height)/10)
      @overlay.clear if @frames == 121
      @overlay.dispose if @sprites["Image"].y+@sprites["Image"].bitmap.height<0
      @window.dispose if @sprites["Image"].y+@sprites["Image"].bitmap.height<0
      @sprites["Image"].dispose if @sprites["Image"].y+@sprites["Image"].bitmap.height<0
    elsif $game_temp.in_menu==true
      @sprites["Image"].y-= ((@sprites["Image"].bitmap.height)/8)
      @overlay.clear
      @overlay.dispose if @sprites["Image"].y+@sprites["Image"].bitmap.height<0
      @window.dispose if @sprites["Image"].y+@sprites["Image"].bitmap.height<0
      @sprites["Image"].dispose if @sprites["Image"].y+@sprites["Image"].bitmap.height<0
    else
      @sprites["Image"].y+= ((@sprites["Image"].bitmap.height)/10) if @sprites["Image"].y<0
      if @frames == 14
        textpos=[]
        textpos.push([$game_map.name,20,((@sprites["Image"].y) + (@sprites["Image"].bitmap.height))-47,0,@baseColor,@shadowColor])
        pbDrawTextPositions(@overlay,textpos)
      end
      @frames+=1
    end
  end
end
