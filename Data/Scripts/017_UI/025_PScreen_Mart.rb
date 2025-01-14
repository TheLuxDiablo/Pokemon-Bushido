#===============================================================================
# Abstraction layer for Pokemon Essentials
#===============================================================================
class PokemonMartAdapter
  def getMoney
    return $Trainer.money
  end

  def getMoneyString
    return pbGetGoldString
  end

  def setMoney(value)
    $Trainer.money=value
  end

  def getInventory
    return $PokemonBag
  end

  def getDisplayName(item)
    itemname = PBItems.getName(item)
    if pbIsMachine?(item)
      machine = pbGetMachine(item)
      string = (pbIsTechnicalRecord?(item)) ? _INTL("Note") : _INTL("Scroll")
      itemname = _INTL("{2} {1}",string,PBMoves.getName(machine))
    end
    return itemname
  end

  def getName(item)
    return PBItems.getName(item)
  end

  def getDescription(item)
    if pbIsMachine?(item)
      machine = pbGetMachine(item)
      pbGetMessage(MessageTypes::MoveDescriptions,machine)
    else
      return pbGetMessage(MessageTypes::ItemDescriptions,item)
    end
  end

  def getItemIcon(item)
    return nil if !item
    return pbItemIconFile(item)
  end

  def getItemIconRect(_item)
    return Rect.new(0,0,48,48)
  end

  def getQuantity(item)
    return $PokemonBag.pbQuantity(item)
  end

  def showQuantity?(item)
    return !pbIsImportantItem?(item)
  end

  def getPrice(item,selling=false)
    if $game_temp.mart_prices && $game_temp.mart_prices[item]
      if selling
        return $game_temp.mart_prices[item][1] if $game_temp.mart_prices[item][1]>=0
      else
        return $game_temp.mart_prices[item][0] if $game_temp.mart_prices[item][0]>0
      end
    end
    return pbGetPrice(item)
  end

  def getDisplayPrice(item,selling=false)
    price = getPrice(item,selling).to_s_formatted
    return _INTL("$ {1}",price)
  end

  def canSell?(item)
    return (getPrice(item,true)>0 && !pbIsImportantItem?(item))
  end

  def addItem(item)
    return $PokemonBag.pbStoreItem(item)
  end

  def removeItem(item)
    return $PokemonBag.pbDeleteItem(item)
  end
end



#===============================================================================
# Abstraction layer for RPG Maker XP/VX
# Won't be used if $PokemonBag exists
#===============================================================================
class RpgxpMartAdapter
  def getMoney
    return $game_party.gold
  end

  def getMoneyString
    return pbGetGoldString
  end

  def setMoney(value)
    $game_party.gain_gold(-$game_party.gold)
    $game_party.gain_gold(value)
  end

  def getPrice(item,_selling=false)
    return item.price
  end

  def getItemIcon(item)
    return nil if !item
    if item==0
      return sprintf("Graphics/Icons/itemBack")
    elsif item.respond_to?("icon_index")
      return "Graphics/System/IconSet"
    else
      return sprintf("Graphics/Icons/%s",item.icon_name)
    end
  end

  def getItemIconRect(item)
    if item && item.respond_to?("icon_index")
      ix=item.icon_index % 16 * 24
      iy=item.icon_index / 16 * 24
      return Rect.new(ix,iy,24,24)
    else
      return Rect.new(0,0,32,32)
    end
  end

  def getInventory()
    data = []
    for i in 1...$data_items.size
      data.push($data_items[i]) if getQuantity($data_items[i]) > 0
    end
    for i in 1...$data_weapons.size
      data.push($data_weapons[i]) if getQuantity($data_weapons[i]) > 0
    end
    for i in 1...$data_armors.size
      data.push($data_armors[i]) if getQuantity($data_armors[i]) > 0
    end
    return data
  end

  def canSell?(item)
    return item ? item.price>0 : false
  end

  def getName(item)
    return item ? item.name : ""
  end

  def getDisplayName(item)
    return item ? item.name : ""
  end

  def getDisplayPrice(item,_selling=false)
    price=item.price
    return price.to_s
  end

  def getDescription(item)
    return item ? item.description : ""
  end

  def addItem(item)
    ret=(getQuantity(item)<99)
    if $game_party.respond_to?("gain_weapon")
      case item
      when RPG::Item
        $game_party.gain_item(item.id, 1) if ret
      when RPG::Weapon
        $game_party.gain_weapon(item.id, 1) if ret
      when RPG::Armor
        $game_party.gain_armor(item.id, 1) if ret
      end
    else
      $game_party.gain_item(item,1) if ret
    end
    return ret
  end

  def getQuantity(item)
    ret=0
    if $game_party.respond_to?("weapon_number")
      case item
      when RPG::Item
        ret=$game_party.item_number(item.id)
      when RPG::Weapon
        ret=($game_party.weapon_number(item.id))
      when RPG::Armor
        ret=($game_party.armor_number(item.id))
      end
    else
      return $game_party.item_number(item)
    end
    return ret
  end

  def showQuantity?(_item)
    return true
  end

  def removeItem(item)
    ret=(getQuantity(item)>0)
    if $game_party.respond_to?("lose_weapon")
      case item
      when RPG::Item
        $game_party.lose_item(item.id, 1) if ret
      when RPG::Weapon
        $game_party.lose_weapon(item.id, 1) if ret
      when RPG::Armor
        $game_party.lose_armor(item.id, 1) if ret
      end
    else
      $game_party.lose_item(item,1) if ret
    end
    return ret
  end
end


#===============================================================================
# Buy and Sell adapters
#===============================================================================
class BuyAdapter
  def initialize(adapter)
    @adapter=adapter
  end

  def getDisplayName(item)
    @adapter.getDisplayName(item)
  end

  def getDisplayPrice(item)
    @adapter.getDisplayPrice(item,false)
  end

  def isSelling?
    return false
  end
end



class SellAdapter
  def initialize(adapter)
    @adapter=adapter
  end

  def getDisplayName(item)
    @adapter.getDisplayName(item)
  end

  def getDisplayPrice(item)
    if @adapter.showQuantity?(item)
      return sprintf("x%d",@adapter.getQuantity(item))
    else
      return ""
    end
  end

  def isSelling?
    return true
  end
end



#===============================================================================
# Pokémon Mart
#===============================================================================
class Window_PokemonMart < Window_DrawableCommand
  def initialize(stock,adapter,x,y,width,height,viewport=nil)
    @stock=stock
    @adapter=adapter
    super(x,y,width,height,viewport)
    @selarrow=AnimatedBitmap.new("Graphics/Pictures/martSel")
    @baseColor=Color.new(88,88,80)
    @shadowColor=Color.new(168,184,184)
    self.windowskin=nil
  end

  def itemCount
    return @stock.length+1
  end

  def item
    return self.index>=@stock.length ? 0 : @stock[self.index]
  end

  def drawItem(index,count,ogrect)
    textpos=[]
    rect = Rect.new(ogrect.x+16,ogrect.y,ogrect.width-16,ogrect.height)
    ypos = rect.y
    if index==count-1
      pbDrawShadowText(self.contents, rect.x, ypos + 8, rect.width, rect.height, _INTL("CANCEL"), self.baseColor,self.shadowColor)
    else
      item=@stock[index]
      itemname=@adapter.getDisplayName(item)
      qty=@adapter.getDisplayPrice(item)
      sizeQty=self.contents.text_size(qty).width
      xQty=rect.x+rect.width-sizeQty-2-16
      pbDrawShadowText(self.contents, rect.x, ypos + 8, rect.width - sizeQty - 20, rect.height, itemname, self.baseColor,self.shadowColor)
      pbDrawShadowText(self.contents, xQty, ypos + 8, sizeQty, rect.height, qty, self.baseColor,self.shadowColor)
    end
    drawCursor(index,ogrect)
  end
end



class PokemonMart_Scene
  def update
    pbUpdateSpriteHash(@sprites)
    @subscene.pbUpdate if @subscene
  end

  def pbRefresh
    if @subscene
      @subscene.pbRefresh
    else
      itemwindow=@sprites["itemwindow"]
      @sprites["icon"].item=itemwindow.item
      @sprites["itemtextwindow"].text=(itemwindow.item==0) ? _INTL("Quit shopping.") :
         @adapter.getDescription(itemwindow.item)
      @sprites["tm_compat"].visible = pbIsMachine?(@sprites["itemwindow"].item)
      @sprites["tm_compat"].move = pbGetMachine(@sprites["itemwindow"].item) if pbIsMachine?(@sprites["itemwindow"].item)
      if @sprites["itemwindow"].item != 0 && !pbIsImportantItem?(@sprites["itemwindow"].item)
        @sprites["qtywindow"].visible = !pbIsMachine?(@sprites["itemwindow"].item)
        @sprites["qtywindow"].text    = _INTL("In Bag:<r>{1}", @adapter.getQuantity(itemwindow.item))
      else
        @sprites["qtywindow"].visible = false
      end
      @sprites["qtywindow"].y       = Graphics.height - 102 - @sprites["qtywindow"].height
      itemwindow.refresh
    end
    @sprites["moneywindow"].text=_INTL("Money:\r\n<r>{1}",@adapter.getMoneyString)
  end

  def pbStartBuyOrSellScene(buying,stock,adapter)
    # Scroll right before showing screen
    pbScrollMap(6,5,5)
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @stock=stock
    @adapter=adapter
    @sprites={}
    @sprites["background"]=IconSprite.new(0,0,@viewport)
    @sprites["background"].setBitmap("Graphics/Pictures/martScreen")
    @sprites["icon"]=ItemIconSprite.new(36,Graphics.height-50,-1,@viewport)
    winAdapter=buying ? BuyAdapter.new(adapter) : SellAdapter.new(adapter)
    @sprites["itemwindow"]=Window_PokemonMart.new(stock,winAdapter,
       Graphics.width-316-16,12,330+16,Graphics.height-126)
    @sprites["itemwindow"].viewport=@viewport
    @sprites["itemwindow"].index=0
    @sprites["itemwindow"].refresh
    @sprites["itemtextwindow"]=Window_UnformattedTextPokemon.new("")
    pbPrepareWindow(@sprites["itemtextwindow"])
    @sprites["itemtextwindow"].x=64
    @sprites["itemtextwindow"].y=Graphics.height-96-16
    @sprites["itemtextwindow"].width=Graphics.width-64
    @sprites["itemtextwindow"].height=128
    @sprites["itemtextwindow"].baseColor=Color.new(248,248,248)
    @sprites["itemtextwindow"].shadowColor=Color.new(0,0,0)
    @sprites["itemtextwindow"].visible=true
    @sprites["itemtextwindow"].viewport=@viewport
    @sprites["itemtextwindow"].windowskin=nil
    @sprites["helpwindow"]=Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["helpwindow"])
    @sprites["helpwindow"].visible=false
    @sprites["helpwindow"].viewport=@viewport
    pbBottomLeftLines(@sprites["helpwindow"],1)
    @sprites["moneywindow"]=Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["moneywindow"])
    @sprites["moneywindow"].setSkin("Graphics/Windowskins/goldskin")
    @sprites["moneywindow"].visible=true
    @sprites["moneywindow"].viewport=@viewport
    @sprites["moneywindow"].x=0
    @sprites["moneywindow"].y=0
    @sprites["moneywindow"].width=190
    @sprites["moneywindow"].height=96
    @sprites["moneywindow"].baseColor=Color.new(88,88,80)
    @sprites["moneywindow"].shadowColor=Color.new(168,184,184)
    @sprites["qtywindow"] = Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["qtywindow"])
    @sprites["qtywindow"].setSkin("Graphics/Windowskins/goldskin")
    @sprites["qtywindow"].viewport = @viewport
    @sprites["qtywindow"].width = 190
    @sprites["qtywindow"].height = 64
    @sprites["qtywindow"].baseColor = Color.new(88, 88, 80)
    @sprites["qtywindow"].shadowColor = Color.new(168, 184, 184)
    @sprites["qtywindow"].text = _INTL("In Bag:<r>{1}", @adapter.getQuantity(@sprites["itemwindow"].item))
    @sprites["qtywindow"].y    = Graphics.height - 102 - @sprites["qtywindow"].height
    @sprites["tm_compat"] = TMCompatibilityPanel.new(@viewport)
    @sprites["tm_compat"].bitmap = pbBitmap("Graphics/Pictures/martPanel")
    @sprites["tm_compat"].x      = 4
    @sprites["tm_compat"].y      = @sprites["moneywindow"].y + @sprites["moneywindow"].height
    @sprites["tm_compat"].z = 10000
    pbDeactivateWindows(@sprites)
    @buying=buying
    pbRefresh
    Graphics.frame_reset
  end

  def pbStartBuyScene(stock,adapter)
    pbStartBuyOrSellScene(true,stock,adapter)
  end

  def pbStartSellScene(bag,adapter)
    if $PokemonBag
      pbStartSellScene2(bag,adapter)
    else
      pbStartBuyOrSellScene(false,bag,adapter)
    end
  end

  def pbStartSellScene2(bag,adapter)
    @subscene=PokemonBag_Scene.new
    @adapter=adapter
    @viewport2=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport2.z=99999
    numFrames = Graphics.frame_rate*4/10
    alphaDiff = (255.0/numFrames).ceil
    for j in 0..numFrames
      col=Color.new(0,0,0,j*alphaDiff)
      @viewport2.color=col
      Graphics.update
      Input.update
    end
    @subscene.pbStartScene(bag)
    @viewport=Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z=99999
    @sprites={}
    @sprites["helpwindow"]=Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["helpwindow"])
    @sprites["helpwindow"].visible=false
    @sprites["helpwindow"].viewport=@viewport
    pbBottomLeftLines(@sprites["helpwindow"],1)
    @sprites["moneywindow"]=Window_AdvancedTextPokemon.new("")
    pbPrepareWindow(@sprites["moneywindow"])
    @sprites["moneywindow"].setSkin("Graphics/Windowskins/goldskin")
    @sprites["moneywindow"].visible=false
    @sprites["moneywindow"].viewport=@viewport
    @sprites["moneywindow"].x=0
    @sprites["moneywindow"].y=0
    @sprites["moneywindow"].width=186
    @sprites["moneywindow"].height=96
    @sprites["moneywindow"].baseColor=Color.new(88,88,80)
    @sprites["moneywindow"].shadowColor=Color.new(168,184,184)
    pbDeactivateWindows(@sprites)
    @buying=false
    pbRefresh
  end

  def pbEndBuyScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
    # Scroll left after showing screen
    pbScrollMap(4,5,5)
  end

  def pbEndSellScene
    if @subscene
      @subscene.pbEndScene
    end
    pbDisposeSpriteHash(@sprites)
    if @viewport2
      numFrames = Graphics.frame_rate*4/10
      alphaDiff = (255.0/numFrames).ceil
      for j in 0..numFrames
        col=Color.new(0,0,0,(numFrames-j)*alphaDiff)
        @viewport2.color=col
        Graphics.update
        Input.update
      end
      @viewport2.dispose
    end
    @viewport.dispose
    if !@subscene
      pbScrollMap(4,5,5)
    end
  end

  def pbPrepareWindow(window)
    window.visible=true
    window.letterbyletter=false
  end

  def pbShowMoney
    pbRefresh
    @sprites["moneywindow"].visible=true
  end

  def pbHideMoney
    pbRefresh
    @sprites["moneywindow"].visible=false
  end

  def pbShowQuantity
    pbRefresh
    @sprites["qtywindow"].visible = true
  end

  def pbHideQuantity
    pbRefresh
    @sprites["qtywindow"].visible = false
  end

  def pbDisplay(msg,brief=false)
    cw=@sprites["helpwindow"]
    cw.letterbyletter=true
    cw.text=msg
    pbBottomLeftLines(cw,2)
    cw.visible=true
    i=0
    loop do
      Graphics.update
      Input.update
      self.update
      if !cw.busy?
        return if brief
        pbRefresh if i==0
      end
      if Input.trigger?(Input::C) && cw.busy?
        cw.resume
      end
      return if i>=Graphics.frame_rate*3/2
      i+=1 if !cw.busy?
    end
  end

  def pbDisplayPaused(msg)
    cw=@sprites["helpwindow"]
    cw.letterbyletter=true
    cw.text=msg
    pbBottomLeftLines(cw,2)
    cw.visible=true
    yielded = false
    loop do
      Graphics.update
      Input.update
      wasbusy=cw.busy?
      self.update
      if !cw.busy? && !yielded
        yield if block_given?   # For playing SE as soon as the message is all shown
        yielded = true
      end
      pbRefresh if !cw.busy? && wasbusy
      if Input.trigger?(Input::C) && cw.resume && !cw.busy?
        @sprites["helpwindow"].visible=false
        return
      end
    end
  end

  def pbConfirm(msg)
    dw=@sprites["helpwindow"]
    dw.letterbyletter=true
    dw.text=msg
    dw.visible=true
    pbBottomLeftLines(dw,2)
    commands=[_INTL("Yes"),_INTL("No")]
    cw = Window_CommandPokemon.new(commands)
    cw.viewport=@viewport
    pbBottomRight(cw)
    cw.y-=dw.height
    cw.index=0
    loop do
      cw.visible=!dw.busy?
      Graphics.update
      Input.update
      cw.update
      self.update
      if Input.trigger?(Input::B) && dw.resume && !dw.busy?
        cw.dispose
        @sprites["helpwindow"].visible=false
        return false
      end
      if Input.trigger?(Input::C) && dw.resume && !dw.busy?
        cw.dispose
        @sprites["helpwindow"].visible=false
        return (cw.index==0)?true:false
      end
    end
  end

  def pbChooseNumber(helptext,item,maximum)
    curnumber=1
    ret=0
    helpwindow=@sprites["helpwindow"]
    itemprice=@adapter.getPrice(item,!@buying)
    itemprice/=2 if !@buying
    pbDisplay(helptext,true)
    old_visible = @sprites["qtywindow"].visible
    using(numwindow=Window_AdvancedTextPokemon.new("")) { # Showing number of items
      pbPrepareWindow(numwindow)
      numwindow.viewport=@viewport
      numwindow.width=224
      numwindow.height=64
      numwindow.baseColor=Color.new(88,88,80)
      numwindow.shadowColor=Color.new(168,184,184)
      numwindow.text=_INTL("x{1}<r>$ {2}",curnumber,(curnumber*itemprice).to_s_formatted)
      @sprites["qtywindow"].visible = true
      if @sprites["tm_compat"].visible
        @sprites["qtywindow"].x = Graphics.width - @sprites["qtywindow"].width
        @sprites["qtywindow"].y = Graphics.height - 98 - numwindow.height - @sprites["qtywindow"].height
      end
      pbBottomRight(numwindow)
      numwindow.y-=helpwindow.height
      loop do
        Graphics.update
        Input.update
        numwindow.update
        self.update
        if Input.repeat?(Input::LEFT)
          pbPlayCursorSE()
          curnumber-=10
          curnumber=1 if curnumber<1
          numwindow.text=_INTL("x{1}<r>$ {2}",curnumber,(curnumber*itemprice).to_s_formatted)
        elsif Input.repeat?(Input::RIGHT)
          pbPlayCursorSE()
          curnumber+=10
          curnumber=maximum if curnumber>maximum
          numwindow.text=_INTL("x{1}<r>$ {2}",curnumber,(curnumber*itemprice).to_s_formatted)
        elsif Input.repeat?(Input::UP)
          pbPlayCursorSE()
          curnumber+=1
          curnumber=1 if curnumber>maximum
          numwindow.text=_INTL("x{1}<r>$ {2}",curnumber,(curnumber*itemprice).to_s_formatted)
        elsif Input.repeat?(Input::DOWN)
          pbPlayCursorSE()
          curnumber-=1
          curnumber=maximum if curnumber<1
          numwindow.text=_INTL("x{1}<r>$ {2}",curnumber,(curnumber*itemprice).to_s_formatted)
        elsif Input.trigger?(Input::C)
          pbPlayDecisionSE()
          ret=curnumber
          break
        elsif Input.trigger?(Input::B)
          pbPlayCancelSE()
          ret=0
          break
        end
      end
    }
    @sprites["qtywindow"].visible = old_visible
    @sprites["qtywindow"].x = 0
    @sprites["qtywindow"].y = Graphics.height - 102 - @sprites["qtywindow"].height
    helpwindow.visible=false
    return ret
  end

  def pbChooseBuyItem
    itemwindow=@sprites["itemwindow"]
    @sprites["helpwindow"].visible=false
    pbActivateWindow(@sprites,"itemwindow") {
      pbRefresh
      loop do
        Graphics.update
        Input.update
        olditem=itemwindow.item
        self.update
        pbRefresh if itemwindow.item!=olditem
        if Input.trigger?(Input::B)
          pbPlayCloseMenuSE
          return 0
        elsif Input.trigger?(Input::C)
          if itemwindow.index<@stock.length
            pbRefresh
            return @stock[itemwindow.index]
          else
            return 0
          end
        end
      end
    }
  end

  def pbChooseSellItem
    if @subscene
      return @subscene.pbChooseItem
    else
      return pbChooseBuyItem
    end
  end
end


#######################################################


class PokemonMartScreen
  def initialize(scene,stock)
    @scene=scene
    @stock=stock
    @adapter=$PokemonBag ? PokemonMartAdapter.new : RpgxpMartAdapter.new
  end

  def pbConfirm(msg)
    return @scene.pbConfirm(msg)
  end

  def pbDisplay(msg)
    return @scene.pbDisplay(msg)
  end

  def pbDisplayPaused(msg,&block)
    return @scene.pbDisplayPaused(msg,&block)
  end

  def pbBuyScreen
    @scene.pbStartBuyScene(@stock,@adapter)
    item=0
    loop do
      item=@scene.pbChooseBuyItem
      quantity=0
      break if item==0
      itemname=@adapter.getDisplayName(item)
      price=@adapter.getPrice(item)
      if @adapter.getMoney<price
        pbDisplayPaused(_INTL("You don't have enough money."))
        next
      end
      if pbIsImportantItem?(item)
        if !pbConfirm(_INTL("Certainly. You want {1}. That will be ${2}. OK?",
           itemname,price.to_s_formatted))
          next
        end
        quantity=1
      else
        maxafford=(price<=0) ? BAG_MAX_PER_SLOT : @adapter.getMoney/price
        maxafford=BAG_MAX_PER_SLOT if maxafford>BAG_MAX_PER_SLOT
        quantity=@scene.pbChooseNumber(
           _INTL("{1}? Certainly. How many would you like?",itemname),item,maxafford)
        next if quantity==0
        price*=quantity
        if !pbConfirm(_INTL("{1}, and you want {2}. That will be ${3}. OK?",
           itemname,quantity,price.to_s_formatted))
          next
        end
      end
      if @adapter.getMoney<price
        pbDisplayPaused(_INTL("You don't have enough money."))
        next
      end
      added=0
      quantity.times do
        if !@adapter.addItem(item)
          break
        end
        added+=1
      end
      if added!=quantity
        added.times do
          if !@adapter.removeItem(item)
            raise _INTL("Failed to delete stored items")
          end
        end
        pbDisplayPaused(_INTL("You have no more room in the Bag."))
      else
        @adapter.setMoney(@adapter.getMoney-price)
        for i in 0...@stock.length
          if pbIsImportantItem?(@stock[i]) && $PokemonBag.pbHasItem?(@stock[i])
            @stock[i]=nil
          end
        end
        @stock.compact!
        pbDisplayPaused(_INTL("Here you are! Thank you!")) { pbSEPlay("Mart buy item") }
        if $PokemonBag
          if quantity>=10 && pbIsPokeBall?(item) && hasConst?(PBItems,:PREMIERBALL)
            if @adapter.addItem(getConst(PBItems,:PREMIERBALL))
              pbDisplayPaused(_INTL("I'll throw in a Premier Ball, too."))
            end
          end
        end
      end
    end
    @scene.pbEndBuyScene
  end

  def pbSellScreen
    item=@scene.pbStartSellScene(@adapter.getInventory,@adapter)
    loop do
      item=@scene.pbChooseSellItem
      break if item==0
      itemname=@adapter.getDisplayName(item)
      price=@adapter.getPrice(item,true)
      if !@adapter.canSell?(item)
        pbDisplayPaused(_INTL("{1}? Oh, no. I can't buy that.",itemname))
        next
      end
      qty=@adapter.getQuantity(item)
      next if qty==0
      @scene.pbShowMoney
      if qty>1
        qty=@scene.pbChooseNumber(
           _INTL("{1}? How many would you like to sell?",itemname),item,qty)
      end
      if qty==0
        @scene.pbHideMoney
        next
      end
      price/=2
      price*=qty
      if pbConfirm(_INTL("I can pay ${1}. Would that be OK?",price.to_s_formatted))
        @adapter.setMoney(@adapter.getMoney+price)
        qty.times do
          @adapter.removeItem(item)
        end
        pbDisplayPaused(_INTL("Turned over the {1} and received ${2}.",itemname,price.to_s_formatted)) { pbSEPlay("Mart buy item") }
        @scene.pbRefresh
      end
      @scene.pbHideMoney
    end
    @scene.pbEndSellScene
  end
end



def pbPokemonMart(stock,speech=nil,cantsell=false,gender=0)
  for i in 0...stock.length
    stock[i] = getID(PBItems,stock[i])
    if !stock[i] || stock[i]==0 ||
       (pbIsImportantItem?(stock[i]) && $PokemonBag.pbHasItem?(stock[i]))
      stock[i] = nil
    end
  end
  stock.compact!
  commands = []
  cmdBuy  = -1
  cmdSell = -1
  cmdQuit = -1
  commands[cmdBuy = commands.length]  = _INTL("Buy")
  commands[cmdSell = commands.length] = _INTL("Sell") if !cantsell
  commands[cmdQuit = commands.length] = _INTL("Quit")
  speechString = _INTL("Welcome! How may I serve you?")
  if speech.is_a?(Array)
    cmd = pbMessage("#{gender == 1 ? "\\r" : "\\b"}#{speech[0]}",commands,cmdQuit+1)
  else
    string = speech ? speech : speechString
    cmd = pbMessage("#{gender == 1 ? "\\r" : "\\b"}#{string}",commands,cmdQuit+1)
  end
  loop do
    if cmdBuy>=0 && cmd==cmdBuy
      scene = PokemonMart_Scene.new
      screen = PokemonMartScreen.new(scene,stock)
      screen.pbBuyScreen
    elsif cmdSell>=0 && cmd==cmdSell
      scene = PokemonMart_Scene.new
      screen = PokemonMartScreen.new(scene,stock)
      screen.pbSellScreen
    else
      string = speech.is_a?(Array) ? speech[1] : "Please come again!"
      pbMessage(_INTL("#{gender == 1 ? "\\r" : "\\b"}#{string}"))
      break
    end
    string = speech.is_a?(Array) ? speech[2] : "Is there anything else I can help you with?"
    cmd = pbMessage(_INTL("#{gender == 1 ? "\\r" : "\\b"}#{string}"),
      commands,cmdQuit+1)
  end
  $game_temp.clear_mart_prices
end


def pbScentSeller(stock,speech=nil,cantsell=false,gender=0)
  speechArray = []
  if speech.is_a?(String)
    speechArray[0] = speech
    gender = 1 if speech.starts_with?("\\r")
  elsif speech.is_a?(Array)
    speechArray = speech.clone
  end
  speechArray[0] = "Hello there! I sell wonderful scents. Can I interest you in some?" if !speechArray[0]
  speechArray[1] = "Please come again!" if !speechArray[1]
  speechArray[2] = "Is there anything else you're interested in?" if !speechArray[2]
  pbPokemonMart(stock,speechArray,cantsell,gender)
end

def pbNotesSeller(speech = nil,gender = 0)
  speechArray = []
  if speech.is_a?(String)
    speechArray[0] = speech
    gender = 1 if speech.starts_with?("\\r")
  elsif speech.is_a?(Array)
    speechArray = speech.clone
  end
  speechArray[0] = "Hello there! Would you like to buy some notes?" if !speechArray[0]
  speechArray[1] = "Please come again!" if !speechArray[1]
  speechArray[2] = "Is there anything else you're interested in?" if !speechArray[2]
  stock = []
  timenow = pbGetTimeNow
  wday = timenow.wday
  case wday
  when 1 # Monday
    stock = [:TR00,:TR07,:TR14,:TR21,:TR28,:TR35,:TR42,:TR49,:TR56,:TR63,:TR70,:TR77,:TR84,:TR91]
  when 2 # Tuesday
    stock = [:TR01,:TR08,:TR15,:TR22,:TR29,:TR36,:TR43,:TR50,:TR57,:TR64,:TR71,:TR78,:TR85,:TR92]
  when 3 # Wednesday
    stock = [:TR02,:TR09,:TR16,:TR23,:TR30,:TR37,:TR44,:TR51,:TR58,:TR65,:TR72,:TR79,:TR86,:TR93]
  when 4 # Thursday
    stock = [:TR03,:TR10,:TR17,:TR24,:TR31,:TR38,:TR45,:TR52,:TR59,:TR66,:TR73,:TR80,:TR87,:TR94]
  when 5 # Friday
    stock = [:TR04,:TR11,:TR18,:TR25,:TR32,:TR39,:TR46,:TR53,:TR60,:TR67,:TR74,:TR81,:TR88,:TR95]
  when 6 # Saturday
    stock = [:TR05,:TR12,:TR19,:TR26,:TR33,:TR40,:TR47,:TR54,:TR61,:TR68,:TR75,:TR82,:TR89,:TR96,:TR98]
  when 0 # Sunday
    stock = [:TR06,:TR13,:TR20,:TR27,:TR34,:TR41,:TR48,:TR55,:TR62,:TR69,:TR76,:TR83,:TR90,:TR97,:TR99]
  end
  pbPokemonMart(stock,speechArray,true,gender)
end



class Game_Temp
  attr_writer :mart_prices

  def mart_prices
    @mart_prices = [] if !@mart_prices
    return @mart_prices
  end

  def clear_mart_prices
    @mart_prices = []
  end
end



class Interpreter
  def getItem(p)
    if p[0]==0;    return $data_items[p[1]]
    elsif p[0]==1; return $data_weapons[p[1]]
    elsif p[0]==2; return $data_armors[p[1]]
    end
    return nil
  end

  def command_302
    $game_temp.battle_abort = true
    shop_goods = [getItem(@parameters)]
    # Loop
    loop do
      # Advance index
      @index += 1
      # If next event command has shop on second line or after
      if @list[@index].code == 605
        # Add goods list to new item
        shop_goods.push(getItem(@list[@index].parameters))
      else
        # End
        pbPokemonMart(shop_goods.compact)
        return true
      end
    end
  end

  def setPrice(item,buyprice=-1,sellprice=-1)
    item = getID(PBItems,item)
    $game_temp.mart_prices[item] = [-1,-1] if !$game_temp.mart_prices[item]
    $game_temp.mart_prices[item][0] = buyprice if buyprice>0
    if sellprice>=0   # 0=can't sell
      $game_temp.mart_prices[item][1] = sellprice*2
    else
      $game_temp.mart_prices[item][1] = buyprice if buyprice>0
    end
  end

  def setSellPrice(item,sellprice)
    setPrice(item,-1,sellprice)
  end
end
