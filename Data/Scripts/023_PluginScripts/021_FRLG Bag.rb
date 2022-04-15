# :Splice: Change Bag Row Height
class Window_PokemonBag
  def initialize(bag,filterlist,pocket,x,y,width,height)
    @bag        = bag
    @filterlist = filterlist
    @pocket     = pocket
    @sorting = false
    @adapter = PokemonMartAdapter.new
    super(x,y,width,height)
    @swaparrow = AnimatedBitmap.new("Graphics/Pictures/Bag/cursor_swap")
    self.windowskin = nil
    self.rowHeight  = 36
  end

  def drawCursor(index,rect)
    if self.index==index
      bmp = (@sorting) ? @swaparrow.bitmap : @selarrow.bitmap
      pbCopyBitmap(self.contents,bmp,rect.x,rect.y+18)
    end
  end

  def itemRect(item)
    if item<0 || item>=@item_max || item<self.top_item ||
       item>self.top_item+self.page_item_max
      return Rect.new(0,0,0,0)
    else
      cursor_width = (self.width-self.borderX-(@column_max-1)*@column_spacing) / @column_max
      x = item % @column_max * (cursor_width + @column_spacing)
      y = item / @column_max * @row_height - @virtualOy - 2
      return Rect.new(x, y, cursor_width, @row_height)
    end
  end

  def refresh
    @item_max = itemCount()
    self.update_cursor_rect
    dwidth  = self.width-self.borderX
    dheight = self.height-self.borderY
    self.contents = pbDoEnsureBitmap(self.contents,dwidth,dheight)
    self.contents.clear
    for i in 0...@item_max
      next if i<self.top_item || i>self.top_item+self.page_item_max
      drawItem(i,@item_max,itemRect(i))
    end
    drawCursor(self.index,itemRect(self.index))
  end

  def update
    super
    @uparrow.visible   = true
    @downarrow.visible = true
  end
end

class PokemonBag_Scene
  ITEMLISTBASECOLOR     = MessageConfig::DARKTEXTBASE
  ITEMLISTSHADOWCOLOR   = MessageConfig::DARKTEXTSHADOW
  ITEMTEXTBASECOLOR     = Color.new(248, 248, 248)
  ITEMTEXTSHADOWCOLOR   = Color.new(96, 96, 96)
  POCKETNAMEBASECOLOR   = Color.new(248, 248, 248)
  POCKETNAMESHADOWCOLOR = Color.new(96, 96, 96)
  ITEMSVISIBLE          = 7

  def pbStartScene(bag,choosing=false,filterproc=nil,resetpocket=true)
    @viewport = Viewport.new(0,0,Graphics.width,Graphics.height)
    @viewport.z = 99999
    @bag        = bag
    @choosing   = choosing
    @filterproc = filterproc
    pbRefreshFilter
    lastpocket = @bag.lastpocket
    numfilledpockets = @bag.pockets.length-1
    if @choosing
      numfilledpockets = 0
      if @filterlist!=nil
        for i in 1...@bag.pockets.length
          numfilledpockets += 1 if @filterlist[i].length>0
        end
      else
        for i in 1...@bag.pockets.length
          numfilledpockets += 1 if @bag.pockets[i].length>0
        end
      end
      lastpocket = (resetpocket) ? 1 : @bag.lastpocket
      if (@filterlist && @filterlist[lastpocket].length==0) ||
         (!@filterlist && @bag.pockets[lastpocket].length==0)
        for i in 1...@bag.pockets.length
          if @filterlist && @filterlist[i].length>0
            lastpocket = i; break
          elsif !@filterlist && @bag.pockets[i].length>0
            lastpocket = i; break
          end
        end
      end
    end
    @bag.lastpocket = lastpocket
    @sliderbitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/Bag/icon_slider"))
    @pocketbitmap = AnimatedBitmap.new(_INTL("Graphics/Pictures/Bag/icon_pocket"))
    @sprites = {}
    @sprites["background"] = IconSprite.new(0,0,@viewport)
    @sprites["overlay"] = BitmapSprite.new(Graphics.width,Graphics.height,@viewport)
    pbSetSystemFont(@sprites["overlay"].bitmap)
    # :Splice: Change Bag Spr Positions
    @sprites["bagsprite"]  = IconSprite.new(94, 134, @viewport)
    @sprites["pocketicon"] = BitmapSprite.new(186,32,@viewport)
    # :Splice: Change Pocket Icon Positions
    @sprites["pocketicon"].x = 8
    @sprites["pocketicon"].y = 228
    @sprites["leftarrow"] = AnimatedSprite.new("Graphics/Pictures/leftarrow",8,40,28,2,@viewport)
    @sprites["leftarrow"].x       = -2
    # :Splice: Change Arrow Positions
    @sprites["leftarrow"].y       = 126
    @sprites["leftarrow"].visible = (!@choosing || numfilledpockets>1)
    @sprites["leftarrow"].play
    @sprites["rightarrow"] = AnimatedSprite.new("Graphics/Pictures/rightarrow",8,40,28,2,@viewport)
    @sprites["rightarrow"].x       = 148
    # :Splice: Change Arrow Positions
    @sprites["rightarrow"].y       = 126
    @sprites["rightarrow"].visible = (!@choosing || numfilledpockets>1)
    @sprites["rightarrow"].play
    # :Splice: Change Itemlist size
    @sprites["itemlist"] = Window_PokemonBag.new(@bag, @filterlist, lastpocket, 204, 0, 300, 42 + ITEMSVISIBLE * 36)
    @sprites["itemlist"].viewport    = @viewport
    @sprites["itemlist"].startX      = 4
    @sprites["itemlist"].startY      = 0
    @sprites["itemlist"].pocket      = lastpocket
    @sprites["itemlist"].index       = @bag.getChoice(lastpocket)
    @sprites["itemlist"].baseColor   = ITEMLISTBASECOLOR
    @sprites["itemlist"].shadowColor = ITEMLISTSHADOWCOLOR
    @sprites["itemlist"].refresh
    @sprites["itemicon"] = ItemIconSprite.new(48,Graphics.height-48,nil,@viewport)
    @sprites["itemtext"] = Window_UnformattedTextPokemon.newWithSize("",
       72, 270, Graphics.width - 72 - 24, 128, @viewport)
    @sprites["itemtext"].baseColor   = ITEMTEXTBASECOLOR
    @sprites["itemtext"].shadowColor = ITEMTEXTSHADOWCOLOR
    @sprites["itemtext"].visible     = true
    @sprites["itemtext"].windowskin  = nil
    @sprites["tm_compat"] = TMCompatibilityPanel.new(@viewport)
    @sprites["tm_compat"].bitmap = pbBitmap("Graphics/Pictures/Bag/tm_panel")
    @sprites["tm_compat"].x      = 2
    @sprites["tm_compat"].y      = 62
    @sprites["tm_compat"].visible = pbIsMachine?(@sprites["itemlist"].item)
    @sprites["tm_compat"].z = 10000
    @sprites["helpwindow"] = Window_UnformattedTextPokemon.new("")
    @sprites["helpwindow"].visible  = false
    @sprites["helpwindow"].viewport = @viewport
    @sprites["msgwindow"] = Window_AdvancedTextPokemon.new("")
    @sprites["msgwindow"].visible  = false
    @sprites["msgwindow"].viewport = @viewport
    pbBottomLeftLines(@sprites["helpwindow"],1)
    pbDeactivateWindows(@sprites)
    pbRefresh
    pbFadeInAndShow(@sprites)
  end

  def pbRefresh
    # Set the background image
    # :Splice: Change Bag background
    value = ($Trainer.female?) ? "f" : "m"
    @sprites["background"].setBitmap(sprintf("Graphics/Pictures/Bag/bg_#{value}"))
    # Set the bag sprite
    fbagexists = pbResolveBitmap(sprintf("Graphics/Pictures/Bag/bag_#{@bag.lastpocket}_f"))
    if $Trainer.female? && fbagexists
      @sprites["bagsprite"].setBitmap("Graphics/Pictures/Bag/bag_#{@bag.lastpocket}_f")
    else
      @sprites["bagsprite"].setBitmap("Graphics/Pictures/Bag/bag_#{@bag.lastpocket}")
    end
    @sprites["bagsprite"].ox = @sprites["bagsprite"].bitmap.width/2
    @sprites["bagsprite"].oy = @sprites["bagsprite"].bitmap.height/2
    # Draw the pocket icons
    @sprites["pocketicon"].bitmap.clear
    if @choosing && @filterlist
      for i in 1...@bag.pockets.length
        if @filterlist[i].length==0
          # :Splice: Change Pocketicon bitmap
          @sprites["pocketicon"].bitmap.blt(2+(i-1)*22,2,
            @pocketbitmap.bitmap,Rect.new((i-1)*24,26,24,26))
        end
      end
    end
    # :Splice: Change Pocketicon bitmap
    @sprites["pocketicon"].bitmap.blt(2+(@sprites["itemlist"].pocket-1)*22,2,
       @pocketbitmap.bitmap,Rect.new((@sprites["itemlist"].pocket-1)*24,0,24,26))
    # Refresh the item window
    @sprites["itemlist"].refresh
    # Refresh more things
    pbRefreshIndexChanged
  end

  def pbRefreshIndexChanged
    itemlist = @sprites["itemlist"]
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    # Draw the pocket name
    # :Splice: Change Pocket name Position
    pocket_name = (PokemonBag.pocketNames[@bag.lastpocket]).upcase
    bmp_height = overlay.text_size(pocket_name).height
    pbDrawTextPositions(overlay,[
       [pocket_name, 96, 36 - bmp_height, 2, POCKETNAMEBASECOLOR, POCKETNAMESHADOWCOLOR]
    ])
    # :Splice: Change Slider
    showslider = false
    showslider = true if itemlist.top_row > 0
    showslider = true if itemlist.top_item + itemlist.page_item_max < itemlist.itemCount
    # Draw slider box
    if showslider
      sliderheight = 242
      boxheight = (sliderheight*itemlist.page_row_max/itemlist.row_max).floor
      boxheight += [(sliderheight-boxheight)/2,sliderheight/6].min
      boxheight = [boxheight.floor,38].max
      x = 479
      y = 18
      y += ((sliderheight-boxheight)*itemlist.top_row/(itemlist.row_max-itemlist.page_row_max)).floor
      overlay.blt(x,y,@sliderbitmap.bitmap,Rect.new(36,0,36,4))
      i = 0
      while i*16<boxheight-4-18
        height = [boxheight-4-18-i*16,16].min
        overlay.blt(x,y+4+i*16,@sliderbitmap.bitmap,Rect.new(36,4,36,height))
        i += 1
      end
      overlay.blt(x,y+boxheight-18,@sliderbitmap.bitmap,Rect.new(36,20,36,18))
    end
    # Set the selected item's icon
    @sprites["itemicon"].item = itemlist.item
    # Set the selected item's description
    if itemlist.item == 0
      @sprites["tm_compat"].move    = 0
      @sprites["tm_compat"].visible = false
      @sprites["itemtext"].text      = _INTL("Close bag.")
    elsif pbIsMachine?(itemlist.item)
      machine = pbGetMachine(itemlist.item)
      @sprites["tm_compat"].move    = machine
      @sprites["tm_compat"].visible = true
      @sprites["itemtext"].text     = pbGetMessage(MessageTypes::MoveDescriptions,machine)
    else
      @sprites["tm_compat"].move    = 0
      @sprites["tm_compat"].visible = false
      @sprites["itemtext"].text     = pbGetMessage(MessageTypes::ItemDescriptions,itemlist.item)
    end
  end


  # Called when the item screen wants an item to be chosen from the screen
  def pbChooseItem
    @sprites["helpwindow"].visible = false
    itemwindow = @sprites["itemlist"]
    thispocket = @bag.pockets[itemwindow.pocket]
    swapinitialpos = -1
    pbActivateWindow(@sprites,"itemlist") {
      loop do
        oldindex = itemwindow.index
        Graphics.update
        Input.update
        pbUpdate
        if itemwindow.sorting && itemwindow.index>=thispocket.length
          itemwindow.index = (oldindex==thispocket.length-1) ? 0 : thispocket.length-1
        end
        if itemwindow.index!=oldindex
          # Move the item being switched
          if itemwindow.sorting
            thispocket.insert(itemwindow.index,thispocket.delete_at(oldindex))
          end
          # Update selected item for current pocket
          @bag.setChoice(itemwindow.pocket,itemwindow.index)
          pbRefresh
        end
        if itemwindow.sorting
          if Input.trigger?(Input::A) ||
             Input.trigger?(Input::C)
            itemwindow.sorting = false
            pbPlayDecisionSE
            pbRefresh
          elsif Input.trigger?(Input::B)
            thispocket.insert(swapinitialpos,thispocket.delete_at(itemwindow.index))
            itemwindow.index = swapinitialpos
            itemwindow.sorting = false
            pbPlayCancelSE
            pbRefresh
          end
        else
          # Change pockets
          if Input.trigger?(Input::LEFT)
            newpocket = itemwindow.pocket
            loop do
              newpocket = (newpocket==1) ? PokemonBag.numPockets : newpocket-1
              break if !@choosing || newpocket==itemwindow.pocket
              if @filterlist
                break if @filterlist[newpocket].length>0
              else
                break if @bag.pockets[newpocket].length>0
              end
            end
            if itemwindow.pocket!=newpocket
              itemwindow.pocket = newpocket
              @bag.lastpocket   = itemwindow.pocket
              thispocket = @bag.pockets[itemwindow.pocket]
              pbPlayCursorSE
              # :Splice: Show Pocket Change Animation
              3.times do
                Graphics.update; pbUpdate
                @sprites["bagsprite"].angle -= 1
              end
              pbRefresh
              3.times do
                Graphics.update; pbUpdate
                @sprites["bagsprite"].angle += 1
              end
            end
          elsif Input.trigger?(Input::RIGHT)
            newpocket = itemwindow.pocket
            loop do
              newpocket = (newpocket==PokemonBag.numPockets) ? 1 : newpocket+1
              break if !@choosing || newpocket==itemwindow.pocket
              if @filterlist
                break if @filterlist[newpocket].length>0
              else
                break if @bag.pockets[newpocket].length>0
              end
            end
            if itemwindow.pocket!=newpocket
              itemwindow.pocket = newpocket
              @bag.lastpocket   = itemwindow.pocket
              thispocket = @bag.pockets[itemwindow.pocket]
              pbPlayCursorSE
              # :Splice: Show Pocket Change Animation
              3.times do
                Graphics.update; pbUpdate
                @sprites["bagsprite"].angle += 1
              end
              pbRefresh
              3.times do
                Graphics.update; pbUpdate
                @sprites["bagsprite"].angle -= 1
              end
            end
#          elsif Input.trigger?(Input::SPECIAL)   # Register/unregister selected item
#            if !@choosing && itemwindow.index<thispocket.length
#              if @bag.pbIsRegistered?(itemwindow.item)
#                @bag.pbUnregisterItem(itemwindow.item)
#              elsif pbCanRegisterItem?(itemwindow.item)
#                @bag.pbRegisterItem(itemwindow.item)
#              end
#              pbPlayDecisionSE
#              pbRefresh
#            end
          elsif Input.trigger?(Input::A)   # Start switching the selected item
            if !@choosing
              if thispocket.length>1 && itemwindow.index<thispocket.length &&
                 !BAG_POCKET_AUTO_SORT[itemwindow.pocket]
                itemwindow.sorting = true
                swapinitialpos = itemwindow.index
                pbPlayDecisionSE
                pbRefresh
              end
            end
          elsif Input.trigger?(Input::B)   # Cancel the item screen
            pbPlayCloseMenuSE
            return 0
          elsif Input.trigger?(Input::C)   # Choose selected item
            (itemwindow.item == 0) ? pbPlayCloseMenuSE : pbPlayDecisionSE
            return itemwindow.item
          end
        end
      end
    }
  end
end
