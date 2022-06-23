
class GetKeyItemScene
  def initialize(item, quantity, plural)
    @item = item
    @quantity = quantity
    @plural = plural
  end

  def pbStartScene
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, SCREEN_HEIGHT) # Updated DEFAULTSCREENHEIGHT
    @viewport.z = 99999
    @finished = false
    @sprites["whitescreen"] = Sprite.new(@viewport)
    @sprites["whitescreen"].bitmap = RPG::Cache.load_bitmap("Graphics/Pictures/white")
    @sprites["whitescreen"].color = Color.new(255, 255, 255)
    @sprites["whitescreen"].opacity = 0
    @sprites["bg"] = Sprite.new(@viewport)
    @sprites["bg"].bitmap = RPG::Cache.load_bitmap("Graphics/Pictures/keyitembg")
    @sprites["bg"].ox = @sprites["bg"].bitmap.width / 2
    @sprites["bg"].oy = @sprites["bg"].bitmap.height / 2
    @sprites["bg"].y = SCREEN_HEIGHT / 2 # Updated DEFAULTSCREENHEIGHT
    @sprites["bg"].x = SCREEN_WIDTH / 2  # Updated DEFAULTSCREENWIDTH
    @sprites["bg"].zoom_y = 0
    @sprites["bg"].zoom_x = 0
    @sprites["bg"].opacity = 0
    if !@item.is_a?(String)
      iconname = format("Graphics/Icons/item%03dkey", @item)
      iconname = format("Graphics/Icons/item%03d", @item) unless pbResolveBitmap(iconname)
    else
      iconname = _INTL("Graphics/Icons/{1}", @item)
      @fakeitem = true
    end
    @sprites["item"] = IconSprite.new(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2, @viewport)
    # Updated DEFAULTSCREENHEIGHT and DEFAULTSCREENWIDTH
    @sprites["item"].setBitmap(iconname)
    @sprites["item"].ox = @sprites["item"].bitmap.width / 2
    @sprites["item"].oy = @sprites["item"].bitmap.height / 2
    @sprites["item"].angle = 180
    @sprites["item"].zoom_y = 0
    @sprites["item"].zoom_x = 0
    @sprites["item"].opacity = 0
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def shakeItem
    3.delta_add.times do
      Graphics.update
      pbUpdateSceneMap
      @sprites["item"].angle += 2.delta_sub(false)
    end
    3.delta_add.times do
      Graphics.update
      pbUpdateSceneMap
      @sprites["item"].angle -= 2.delta_sub(false)
    end
    3.delta_add.times do
      Graphics.update
      pbUpdateSceneMap
      @sprites["item"].angle -= 2.delta_sub(false)
    end
    3.delta_add.times do
      Graphics.update
      pbUpdateSceneMap
      @sprites["item"].angle += 2.delta_sub(false)
    end
  end

  def pbUpdate(item)
    pbWait(1)
    10.delta_add.times do
      Graphics.update
      @sprites["whitescreen"].opacity += (255 / 10).delta_sub(false)
    end
    10.delta_add.times do
      Graphics.update
      @sprites["whitescreen"].opacity -= (255 / 10).delta_sub(false)
    end
    se_file = "Conquest-LevelUpWarlord"
    katanas = [:KATANALIGHT, :KATANALIGHT2, :KATANALIGHT3, :KATANALIGHT4,:KATANALIGHT5, :KATANABASIC, :KATANADARK]
    se_file = "BOTW-GetFanfare" if katanas.any? { |k| isConst?(item, PBItems, k) }
    frametome = 0
    dur = 18.delta_add
    dur.times do
      frametome += 1
      Graphics.update
      @sprites["item"].angle -= (15 / 2).delta_sub(false) if @sprites["item"].angle != 0
      @sprites["item"].angle = 0 if @sprites["item"].angle < 0
      pbMEPlay(se_file) if frametome == dur / 2 # Updated ME to Essentials Default
      @sprites["bg"].zoom_y += (0.1 / 2).delta_sub(false) if @sprites["bg"].zoom_y < 1.75
      @sprites["bg"].zoom_x += (0.1 / 2).delta_sub(false) if @sprites["bg"].zoom_x < 1.75
      @sprites["bg"].opacity += 14.16.delta_sub(false)
      @sprites["item"].zoom_y += (0.17 / 2).delta_sub(false)
      @sprites["item"].zoom_x += (0.17 / 2).delta_sub(false)
      @sprites["item"].opacity += 14.16.delta_sub(false)
    end
    12.delta_add.times do
      Graphics.update
      @sprites["item"].angle -= (15 / 2).delta_sub(false) if @sprites["item"].angle != 0
      @sprites["item"].angle = 0 if @sprites["item"].angle < 0

      @sprites["bg"].zoom_y += (0.1 / 2).delta_sub(false) if @sprites["bg"].zoom_y > 1
      @sprites["bg"].zoom_x += (0.1 / 2).delta_sub(false) if @sprites["bg"].zoom_x > 1
      @sprites["bg"].zoom_x = 1 if @sprites["bg"].zoom_x < 1
      @sprites["bg"].zoom_y = 1 if @sprites["bg"].zoom_y < 1

      @sprites["item"].zoom_y -= (0.17 / 2).delta_sub(false) if @sprites["item"].zoom_y > 1
      @sprites["item"].zoom_x -= (0.17 / 2).delta_sub(false) if @sprites["item"].zoom_x > 1
      @sprites["item"].zoom_x = 1 if @sprites["item"].zoom_x < 1
      @sprites["item"].zoom_y = 1 if @sprites["item"].zoom_y < 1
    end
    @sprites["item"].angle = 0
    @sprites["item"].zoom_y = 1
    @sprites["item"].zoom_x = 1
    @sprites["bg"].zoom_y = 1
    @sprites["bg"].zoom_x = 1
    shakeItem
    shakeItem
    pbWait(6)
    18.delta_add.times do
      Graphics.update
      @sprites["bg"].zoom_y -= (0.15 / 2).delta_sub(false)
      @sprites["bg"].zoom_x += (0.1 / 2).delta_sub(false)
      @sprites["bg"].opacity -= 14.16.delta_sub(false)
      @sprites["item"].zoom_y -= (0.17 / 2).delta_sub(false)
      @sprites["item"].zoom_x -= (0.17 / 2).delta_sub(false)
      @sprites["item"].opacity -= 14.16.delta_sub(false)
    end
    pbReceiveItem(@item, @quantity) unless @fakeitem
  end
end
###################################################

class GetKeyItem
  def initialize(scene)
    @scene = scene
  end

  def pbStartScreen(item)
    @scene.pbStartScene
    @scene.pbUpdate(item)
    @scene.pbEndScene
  end
end

def pbGetKeyItem(item, quantity = 1, plural = nil)
  scene = GetKeyItemScene.new(item, quantity, plural)
  screen = GetKeyItem.new(scene)
  screen.pbStartScreen(item)
end

PluginManager.register({
  :name => "BW Key Item Animation",
  :credits => "KleinStudio"
})
