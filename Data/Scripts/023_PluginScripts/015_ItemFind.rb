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
  elsif isConst?(item,PBItems,:SHINYCHARM) || isConst?(item,PBItems,:RAINBOWFEATHER)
    pbMessage(_INTL("You were given the \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
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
  if isConst?(item,PBItems,:KATANABASIC)
    meName = "BOTW-GetFanfare"
  elsif isConst?(item,PBItems,:KATANALIGHT)
    meName = "BOTW-GetFanfare"
  elsif isConst?(item,PBItems,:KATANALIGHT2)
    meName = "BOTW-GetFanfare"
  elsif isConst?(item,PBItems,:KATANALIGHT3)
    meName = "BOTW-GetFanfare"
  elsif isConst?(item,PBItems,:KATANALIGHT4)
    meName = "BOTW-GetFanfare"
  elsif isConst?(item,PBItems,:KATANALIGHT5)
    meName = "BOTW-GetFanfare"
  elsif isConst?(item,PBItems,:HABITATSCROLL)
    meName = "BOTW-GetFanfare"
  end
  if $PokemonBag.pbCanStore?(item,quantity)
    scene = $game_player.addFoundItem(item)
  else
    scene = false
  end
  if isConst?(item,PBItems,:LEFTOVERS)
    pbMessage(_INTL("\\me[{1}]You obtained some \\c[1]{2}\\c[0]!\\wtnp[30]",meName,itemname))
  elsif isConst?(item,PBItems,:KATANABASIC)
    pbMessage(_INTL("You obtained the \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
    pbMessage(_INTL("It's a rusty old Katana, with a mystical aura."))
  elsif isConst?(item,PBItems,:KATANADARK)
    pbMessage(_INTL("You found the \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
    pbMessage(_INTL("It emanates an ominous and mesmerizing energy."))
    pbMessage(_INTL("It can be used to corrupt the hearts of Pokémon, changing them into shadow forms."))
  elsif isConst?(item,PBItems,:SUKIROLETTER)
    pbMessage(_INTL("You obtained \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
    pbMessage(_INTL("This letter can be used to get into the Kenshi Tournament.",itemname))
  elsif isConst?(item,PBItems,:SHINYCHARM) || isConst?(item,PBItems,:RAINBOWFEATHER) || isConst?(item,PBItems,:HABITATSCROLL)
    pbMessage(_INTL("You were given the \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
  elsif isConst?(item,PBItems,:EXPALL)
    pbMessage(_INTL("You obtained \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
    pbMessage(_INTL("This special charm belonged to your father, Ryo.",itemname))
  elsif isConst?(item,PBItems,:KATANALIGHT)
    pbMessage(_INTL("You obtained the \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
    pbMessage(_INTL("In its weakest form, the \\c[1]{1}\\c[0] can expose the hearts of shadow Pokémon and heal your Pokémon outside of battle.",itemname))
    pbMessage(_INTL("The \\c[1]{1}\\c[0] can also be used as a light source to illuminate dark caves.",itemname))
  elsif isConst?(item,PBItems,:KATANALIGHT2)
    pbMessage(_INTL("You learned the Solid Strike style for the \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
    pbMessage(_INTL("You can now slice through rocks by utlizing a strong stance and resolute slice!"))
  elsif isConst?(item,PBItems,:KATANALIGHT3)
    pbMessage(_INTL("You learned the Water Walking style for the \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
    pbMessage(_INTL("The \\c[1]{1}\\c[0] can now control the flow of water, allowing you to easily run on water!",itemname))
  elsif isConst?(item,PBItems,:KATANALIGHT4)
    if $game_switches[136]
      pbMessage(_INTL("You recovered the \\c[1]{1}\\c[0] from the Akui Clan!\\wtnp[30]",itemname))
    else
      pbMessage(_INTL("The \\c[1]{1}\\c[0] was awakened to its true form!\\wtnp[30]",itemname))
      pbMessage(_INTL("The Katana of Light can now purify the hearts of Shadow Pokémon when their Heart Gauge is empty!"))
      pbMessage(_INTL("It can also now banish the shadow fog in Nagisa Bay!"))
    end
  elsif isConst?(item,PBItems,:KATANALIGHT5)
    pbMessage(_INTL("You learned the final technique for the \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
    pbMessage(_INTL("The Light Blade can open the hearts of Shadow Pokémon!"))
    pbMessage(_INTL("It can also illuminate dark maps, and banish the shadow fog in Nagisa Bay!"))
  elsif isConst?(item,PBItems,:KOMOREILEAF) || isConst?(item,PBItems,:NENSHOLEAF) || isConst?(item,PBItems,:MAPLELEAF)
    pbMessage(_INTL("You found a \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
  elsif isConst?(item,PBItems,:CAMLETTER) || isConst?(item,PBItems,:LUXLETTER) || isConst?(item,PBItems,:TRISTANLETTER) || isConst?(item,PBItems,:HAUNTEDLETTER)
    pbMessage(_INTL("You were given a \\c[1]{1}\\c[0] by one of the Bushido Developers!\\wtnp[30]",itemname))
  elsif isConst?(item,PBItems,:SHIMIZULEAF)
    pbMessage(_INTL("You found an \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
  elsif isConst?(item,PBItems,:OVALCHARM) || isConst?(item,PBItems,:ILEXLEAF)
    pbMessage(_INTL("You were given an \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
  elsif isConst?(item,PBItems,:DEXCERT)
    pbMessage(_INTL("You were given the \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
  elsif isConst?(item,PBItems,:AKUIKEY)
    pbMessage(_INTL("You found one of the \\c[1]{1}s\\c[0]!\\wtnp[30]",itemname))
  elsif isConst?(item,PBItems,:PRISONKEY)
    pbMessage(_INTL("You found the \\c[1]{1}\\c[0]!\\wtnp[30]",itemname))
    pbMessage(_INTL("Now Ryo, Darmanitan, and all of the other Pokémon can be freed from the Akui Prison!"))
  elsif pbIsMachine?(item)   # TM or HM
    pbMessage(_INTL("\\me[{1}]You obtained \\c[1]{2} {3}\\c[0]!\\wtnp[30]",meName,itemname,PBMoves.getName(pbGetMachine(item))))
  elsif quantity>1
    pbMessage(_INTL("\\me[{1}]You obtained {2} \\c[1]{3}\\c[0]!\\wtnp[30]",meName,quantity,itemname))
  elsif itemname.starts_with_vowel?
    pbMessage(_INTL("\\me[{1}]You obtained an \\c[1]{2}\\c[0]!\\wtnp[30]",meName,itemname))
  else
    pbMessage(_INTL("\\me[{1}]You obtained a \\c[1]{2}\\c[0]!\\wtnp[30]",meName,itemname))
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
