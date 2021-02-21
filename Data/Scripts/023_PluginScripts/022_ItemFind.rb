#-------------------------------------------------------------------------------
# Item Find
# v1.2
# By Boonzeet
#-------------------------------------------------------------------------------
# A script to show a helpful message with item name, icon and description
# when an item is found for the first time.
#-------------------------------------------------------------------------------

PluginManager.register({
  :name => "Item Find",
  :version => "1.2",
  :credits => ["Boonzeet","Golispod User"],
  :link => "https://reliccastle.com/resources/371/"
})

#-------------------------------------------------------------------------------
# Config
#-------------------------------------------------------------------------------

WINDOWSKIN_NAME = "" # set for custom windowskin

#-------------------------------------------------------------------------------
# Base Class
#-------------------------------------------------------------------------------

class PokemonItemFind_Scene

  attr_reader :smallShow

  def initialize
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 100000
    @sprites = {}

    skin = WINDOWSKIN_NAME == "" ? MessageConfig.pbGetSystemFrame : "Graphics/Windowskins/" + WINDOWSKIN_NAME

     @sprites["background"] = Window_UnformattedTextPokemon.newWithSize("", 0, 0, Graphics.width, 0, @viewport)
     @sprites["background"].z = @viewport.z - 1
     @sprites["background"].visible = false
     @sprites["background"].setSkin(skin)
     pbSetSmallFont(@sprites["background"].contents)

    colors = getDefaultTextColors(@sprites["background"].windowskin)

    @sprites["itemicon"] = ItemIconSprite.new(42, Graphics.height - 48, -1, @viewport)
    @sprites["itemicon"].visible = false
    @sprites["itemicon"].z = @viewport.z + 10

    @sprites["descwindow"] = Window_AdvancedTextPokemon.newWithSize("", 64, 0, Graphics.width - 64, 64, @viewport)
    @sprites["descwindow"].windowskin = nil
    @sprites["descwindow"].z = @viewport.z
    @sprites["descwindow"].visible = false
    @sprites["descwindow"].baseColor = colors[0]
    @sprites["descwindow"].shadowColor = colors[1]

    pbSetSmallFont(@sprites["descwindow"].contents)
    @sprites["descwindow"].lineHeight(30)
    @smallShow = false
  end

  def pbShow(item)
    @smallShow = false
    description = pbGetMessage(MessageTypes::ItemDescriptions, item)

    descwindow = @sprites["descwindow"]
    descwindow.resizeToFit(description, Graphics.width - 64)
    descwindow.text = description
    descwindow.y = 0
    descwindow.visible = true

    background = @sprites["background"]
    background.height = descwindow.height
    background.y = 0
    background.visible = true

    itemicon = @sprites["itemicon"]
    itemicon.item = item
    itemicon.y = (descwindow.height / 2).floor
    itemicon.visible = true
  end

  def pbShowSmall(item)
    @smallShow = true
    descwindow = @sprites["descwindow"]
    descwindow.visible = false
    background = @sprites["background"]
    background.visible = false
    itemicon = @sprites["itemicon"]
    itemicon.item = item
    itemicon.y = Graphics.height - 48
    itemicon.x = Graphics.width - 48 - 10
    itemicon.visible = true
  end

  def update
    pbUpdateSpriteHash(@sprites)
  end

  def pbEndScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#-------------------------------------------------------------------------------
# Game Player changes
#-------------------------------------------------------------------------------
# Adds a list of found items to the Game Player which is maintained over saves
#-------------------------------------------------------------------------------

class Game_Player
  alias initialize_itemfind initialize
  def initialize(*args)
    @found_items = []
    initialize_itemfind(*args)
  end

  def addFoundItem(item)
    if !defined?(@found_items)
      @found_items = []
    end
    scene = PokemonItemFind_Scene.new
    if !@found_items.include?(item)
      @found_items.push(item)
      scene.pbShow(item)
    else
      scene.pbShowSmall(item)
    end
    return scene
  end
end

#-------------------------------------------------------------------------------
# Overrides of pbItemBall and pbReceiveItem
#-------------------------------------------------------------------------------
# Picking up an item found on the ground
#-------------------------------------------------------------------------------

def pbItemBall(item, quantity = 1)
  item = getID(PBItems,item)
  return false if !item || item<=0 || quantity<1
  itemname = (quantity>1) ? PBItems.getNamePlural(item) : PBItems.getName(item)
  pocket = pbGetPocket(item)
  meName = $PokemonBag.pbCanStore?(item,quantity) ? ((pbIsKeyItem?(item)) ? "HGSSGetKeyItem" : "HGSSGetItem") : ""
  if $PokemonBag.pbCanStore?(item,quantity)
    scene = $game_player.addFoundItem(item)
  else
    scene = false
  end
  if isConst?(item, PBItems, :LEFTOVERS) || pbGetPocket(item) == 6
    pbMessage(_INTL("\\me[{1}]You found some "+ ((scene && scene.smallShow)? "\\n" : "") + "\\c[1]{2}!\\wtnp[30]", meName, itemname))
  elsif pbIsMachine?(item) # TM or HM
    pbMessage(_INTL("\\me[{1}]You found "+ ((scene && scene.smallShow)? "\\n" : "") + "\\c[1]{2} {3}!\\wtnp[30]", meName, itemname,  PBMoves.getName(pbGetMachine(item))))
  elsif quantity > 1
    pbMessage(_INTL("\\me[{1}]You found {2} "+ ((scene && scene.smallShow)? "\\n" : "") + "\\c[1]{3}!\\wtnp[30]", meName, quantity ,itemname))
  elsif ["a", "e", "i", "o", "u"].include?(itemname[0, 1].downcase)
    pbMessage(_INTL("\\me[{1}]You found an "+ ((scene && scene.smallShow)? "\\n" : "") + "\\c[1]{2}!\\wtnp[30]", meName, itemname))
  else
    pbMessage(_INTL("\\me[{1}]You found a "+ ((scene && scene.smallShow)? "\\n" : "") + "\\c[1]{2}!\\wtnp[30]", meName, itemname))
  end
  if $PokemonBag.pbStoreItem(item, quantity) # If item can be picked up
    pbMessage(_INTL("You put the {1} away in \\nthe <icon=bagPocket{2}>\\c[1]{3} Pocket.",
                           itemname, pocket, PokemonBag.pocketNames()[pocket]))
    scene.pbEndScene
    return true
  else
    pbMessage(_INTL("But your Bag is full..."))
    return false
  end
end

#-------------------------------------------------------------------------------
# Being given an item
#-------------------------------------------------------------------------------
def pbReceiveItem(item, quantity = 1)
  item = getID(PBItems,item)
  return false if !item || item<=0 || quantity<1
  itemname = (quantity>1) ? PBItems.getNamePlural(item) : PBItems.getName(item)
  pocket = pbGetPocket(item)
  meName = $PokemonBag.pbCanStore?(item,quantity) ? ((pbIsKeyItem?(item)) ? "HGSSGetKeyItem" : "HGSSGetItem") : ""
  if $PokemonBag.pbCanStore?(item,quantity)
    scene = $game_player.addFoundItem(item)
  else
    scene = false
  end
  if isConst?(item, PBItems, :LEFTOVERS) || pbGetPocket(item) == 6
    pbMessage(_INTL("\\me[{1}]You obtained some "+ ((scene && scene.smallShow)? "\\n" : "") + "\\c[1]{2}!\\wtnp[30]", meName, itemname))
  elsif pbIsMachine?(item) # TM or HM
    pbMessage(_INTL("\\me[{1}]You obtained "+ ((scene && scene.smallShow)? "\\n" : "") + "\\c[1]{2} {3}!\\wtnp[30]", meName, itemname,  PBMoves.getName(pbGetMachine(item))))
  elsif quantity > 1
    pbMessage(_INTL("\\me[{1}]You obtained {2} "+ ((scene && scene.smallShow)? "\\n" : "") + "\\c[1]{3}!\\wtnp[30]", meName, quantity ,itemname))
  elsif ["a", "e", "i", "o", "u"].include?(itemname[0, 1].downcase)
    pbMessage(_INTL("\\me[{1}]You obtained an "+ ((scene && scene.smallShow)? "\\n" : "") + "\\c[1]{2}!\\wtnp[30]", meName, itemname))
  else
    pbMessage(_INTL("\\me[{1}]You obtained a "+ ((scene && scene.smallShow)? "\\n" : "") + "\\c[1]{2}!\\wtnp[30]", meName, itemname))
  end
  if $PokemonBag.pbStoreItem(item, quantity) # If item can be picked up
    pbMessage(_INTL("You put the {1} away in \\nthe <icon=bagPocket{2}>\\c[1]{3} Pocket.",
                           itemname, pocket, PokemonBag.pocketNames()[pocket]))
    scene.pbEndScene
    return true
  else
    pbMessage(_INTL("But your Bag is full..."))
    return false
  end
end
