# Name-box by By Theo/MrGela @ theo#7722
# Expected behaviour and use:
# Use in a text command, with an added keyword like "\xn[Test]" in order to
# display a small box to the top-left of the message window, displaying "Test".
# This window will rely on the user's choice of text frame unless there's one
# specified in DEFAULT_WINDOWSKIN below.
#===============================================================================
# HOW TO USE THIS?
# \xn[Text,baseColor,shadowColor,fontName,fontSize,textAlignment,windowX,windowY,windowSkin]
# EXAMPLES:
# \xn[Prof. Oak,0073ff,7bbdef,Power Clear,,2]Test.
# \wu\xn[Prof. Oak,,,,,2,18,162]Test.
#===============================================================================
# CONFIGURATION
#===============================================================================
# SHIFT NAMEWINDOW IN X AXIS (except when specifying a particular X location)
OFFSET_NAMEWINDOW_X=0
# SHIFT NAMEWINDOW IN Y AXIS (except when specifying a particular Y location)
OFFSET_NAMEWINDOW_Y=0
# WHETHER THE TEXT SHOULD BE CENTERED (0=right, 1=center, 2=right)
DEFAULT_ALIGNMENT=1
# ENSURES A MIN. WIDTH OF THE WINDOW
MIN_WIDTH=200
# DEFAULT FONT
DEFAULT_FONT="Power Clear" # "Power Clear", etc.
# DEFAULT FONT SIZE
DEFAULT_FONT_SIZE=nil
# DEFAULT WINDOWSKIN (nil = based on the currently displayed message windowskin)
# (File inside Graphics/Windowskins/)
DEFAULT_WINDOWSKIN="speechbushido"
#===============================================================================
# END CONFIGURATION / Don't touch anything below this point or you'll get a bonk
#===============================================================================
# Params:
# 0       = msgwindow (required)
# 1       = string (required)
# 2       = use dark windowskin? (boolean) (defaults to false)
# 3       = color override
# 4       = shadow override
# 4       = font override
# 5       = font size override
# 6       = alignment (defaults to 0, left)
# 7 and 8 = forced X and Y of the namewindow
def pbDisplayNameWindow(params)
  name         = params[1]
  isDark       = params[2]  if params[2]
  colorBase    = colorToRgb32(MessageConfig::LIGHTTEXTBASE)
  colorBase    = colorToRgb32(MessageConfig::DARKTEXTBASE) if isDark==true
  colorBase    = params[3]  if !params[3].nil?
  colowShadow  = colorToRgb32(MessageConfig::LIGHTTEXTSHADOW)
  colorShadow  = colorToRgb32(MessageConfig::DARKTEXTSHADOW) if isDark==true
  colorShadow  = params[4]  if !params[4].nil?
  font         = params[5]  if !params[5].nil?
  font         = DEFAULT_FONT if font.nil? || font=="0"
  fontSize     = DEFAULT_FONT_SIZE
  fontSize     = params[6]  if !params[6].nil?
  position     = params[7]  if !params[7].nil?
  newX         = 0
  newY         = 0
  newX         = params[8]  if !params[8].nil?
  newY         = params[9]  if !params[9].nil?
  newSkin      = params[10] if params[10] != (nil || "0")
  newSkin      = DEFAULT_WINDOWSKIN if newSkin=="nil" || (newSkin==nil || newSkin=="0")
  msgwindow=params[0]
  fullName=(params[1].split(","))[0]
  # Handle text alignment
  align=""
  alignEnd=""
  case DEFAULT_ALIGNMENT
  when 0
    align="<al>"
    alignEnd="</al>"
  when 1
    align="<ac>"
    alignEnd="</ac>"
  when 2
    align="<ar>"
    alignEnd="</ar>"
  end
  # If position is defined, use that instead
  if !position.nil? || position!="nil"
    case position
    when "0"
      align="<al>"
      alignEnd="</al>"
    when "1", "", nil
      align="<ac>"
      alignEnd="</ac>"
    when "2"
      align="<ar>"
      alignEnd="</ar>"
    end
  end
  fullName.insert(0,align)
  fullName+=alignEnd
  # Handle text color
  # If base or shadow are empty somehow, load windowskin-sensitive colors
  if colorBase.nil? || colorBase.empty?
    colorBase=colorToRgb32(MessageConfig::DARKTEXTBASE)
    colorBase=colorToRgb32(MessageConfig::LIGHTTEXTBASE) if isDark==true
  end
  if colorShadow.nil? || colorShadow.empty?
    colorShadow=colorToRgb32(MessageConfig::DARKTEXTSHADOW)
    colorShadow=colorToRgb32(MessageConfig::LIGHTTEXTSHADOW) if isDark==true
  end
  fullColor="<c3="+colorBase+","+colorShadow+">"
  fullName.insert(0,fullColor) unless fullColor=="<c3=0,0>"
  # Handle text font
  if font.nil? || font.empty?
  elsif font.is_a?(String)
    fullFont="<fn="+font+">"
    fullName.insert(0,fullFont)
    fullName+="</fn>"
  end
  # Handle text font size
  if fontSize.nil?
  elsif (fontSize.is_a?(Numeric) && fontSize!=0) || (fontSize.is_a?(String) && !fontSize.empty? && fontSize!="0")
    fullFontSize="<fs="+fontSize.to_s+">"
    fullName.insert(0,fullFontSize)
    fullName+="</fs>"
  end
  namewindow=Window_AdvancedTextPokemon.new(_INTL(fullName.to_s))
  if isDark==true
    namewindow.setSkin("Graphics/Windowskins/speech black")
  end
  if newSkin!=nil
    if newSkin==DEFAULT_WINDOWSKIN
      if isDark==true
      else
        namewindow.setSkin("Graphics/Windowskins/"+newSkin)
      end
    else
      namewindow.setSkin("Graphics/Windowskins/"+newSkin)
    end
  end
  namewindow.resizeToFit(namewindow.text,Graphics.width)
  namewindow.width=MIN_WIDTH if namewindow.width<=MIN_WIDTH
  namewindow.width = namewindow.width
  namewindow.y=msgwindow.y-namewindow.height
  if newX != (nil || "0") && !newX.empty?
    namewindow.x=newX.to_i
  else
    namewindow.x+=OFFSET_NAMEWINDOW_X
  end
  if newY != (nil || "0") && !newY.empty?
    namewindow.y=newY.to_i
  else
    namewindow.y+=OFFSET_NAMEWINDOW_Y
  end

  namewindow.viewport=msgwindow.viewport
  namewindow.z=msgwindow.z
  return namewindow
end

def pbMessageDisplay(msgwindow,message,letterbyletter=true,commandProc=nil)
  return if !msgwindow
  oldletterbyletter=msgwindow.letterbyletter
  msgwindow.letterbyletter=(letterbyletter) ? true : false
  ret=nil
  count=0
  commands=nil
  facewindow=nil
  goldwindow=nil
  coinwindow=nil
  namewindow=nil
  cmdvariable=0
  cmdIfCancel=0
  msgwindow.waitcount=0
  autoresume=false
  text=message.clone
  msgback=nil
  linecount=(Graphics.height>400) ? 3 : 2
  ### Text replacement
  text.gsub!(/\\\\/,"\5")
  if $game_actors
    text.gsub!(/\\[Nn]\[([1-8])\]/){
       m=$1.to_i
       next $game_actors[m].name
    }
  end
  text.gsub!(/\\[Ss][Ii][Gg][Nn]\[([^\]]*)\]/){
     next "\\op\\cl\\ts[]\\w["+$1+"]"
  }
  text.gsub!(/\\[Pp][Nn]/,$Trainer.name) if $Trainer
  text.gsub!(/\\[Pp][Mm]/,_INTL("${1}",$Trainer.money.to_s_formatted)) if $Trainer
  text.gsub!(/\\[Nn]/,"\n")
  text.gsub!(/\\\[([0-9A-Fa-f]{8,8})\]/){ "<c2="+$1+">" }
  text.gsub!(/\\[Pp][Gg]/,"\\b") if $Trainer && $Trainer.isMale?
  text.gsub!(/\\[Pp][Gg]/,"\\r") if $Trainer && $Trainer.isFemale?
  text.gsub!(/\\[Pp][Oo][Gg]/,"\\r") if $Trainer && $Trainer.isMale?
  text.gsub!(/\\[Pp][Oo][Gg]/,"\\b") if $Trainer && $Trainer.isFemale?
  text.gsub!(/\\[Pp][Gg]/,"")
  text.gsub!(/\\[Pp][Oo][Gg]/,"")
  text.gsub!(/\\[Bb]/,"<c2=6546675A>")
  text.gsub!(/\\[Rr]/,"<c2=043C675A>")
  text.gsub!(/\\1/,"\1")
  colortag=""
  shout = 0
    if text=~/\\sh/i
      text.gsub!(/\\sh/i,"")
      msgwindow.setSkin("Graphics/Windowskins/shout",false)
      shout=16
      startSE="shout"
    end
  isDarkSkin=isDarkWindowskin(msgwindow.windowskin)
  if ($game_message && $game_message.background>0) ||
     ($game_system && $game_system.respond_to?("message_frame") &&
      $game_system.message_frame != 0)
    colortag=getSkinColor(msgwindow.windowskin,0,true)
  else
    colortag=getSkinColor(msgwindow.windowskin,0,isDarkSkin)
  end
  text.gsub!(/\\[Cc]\[([0-9]+)\]/){
     m=$1.to_i
     next getSkinColor(msgwindow.windowskin,m,isDarkSkin)
  }
  begin
    last_text = text.clone
    text.gsub!(/\\[Vv]\[([0-9]+)\]/) { $game_variables[$1.to_i] }
  end until text == last_text
  begin
    last_text = text.clone
    text.gsub!(/\\[Ll]\[([0-9]+)\]/) {
       linecount=[1,$1.to_i].max;
       next ""
    }
  end until text == last_text
  text=colortag+text
  ### Controls
  textchunks=[]
  controls=[]
  while text[/(?:\\([Xn][Nn]|[DdXxNn][Xx][Nn]|[Xn][Nn][Aa]|[Xn][Nn][Bb]|[Xn][Nn][Cc]|[WwFf]|[Ff][Ff]|[Tt][Ss]|[Cc][Ll]|[Mm][Ee]|[Ss][Ee]|[Ww][Tt]|[Ww][Tt][Nn][Pp]|[Cc][Hh])\[([^\]]*)\]|\\([Gg]|[Cc][Nn]|[Ww][Dd]|[Ww][Mm]|[Oo][Pp]|[Cc][Ll]|[Ww][Uu]|[\.]|[\|]|[\!]|[\x5E])())/i]
    textchunks.push($~.pre_match)
    if $~[1]
      controls.push([$~[1].downcase,$~[2],-1])
    else
      controls.push([$~[3].downcase,"",-1])
    end
    text=$~.post_match
  end
  textchunks.push(text)
  for chunk in textchunks
    chunk.gsub!(/\005/,"\\")
  end
  textlen=0
  for i in 0...controls.length
    control=controls[i][0]
    if control=="wt" || control=="wtnp" || control=="." || control=="|"
      textchunks[i]+="\2"
    elsif control=="!"
      textchunks[i]+="\1"
    end
    textlen+=toUnformattedText(textchunks[i]).scan(/./m).length
    controls[i][2]=textlen
  end
  text=textchunks.join("")
  unformattedText=toUnformattedText(text)
  signWaitCount=0
  haveSpecialClose=false
  specialCloseSE=""
  for i in 0...controls.length
    control=controls[i][0]
    param=controls[i][1]
    if control=="f"
      facewindow.dispose if facewindow
      facewindow=PictureWindow.new("Graphics/Pictures/#{param}")
    elsif control=="op"
      signWaitCount=21
    elsif control=="cl"
      text=text.sub(/\001\z/,"") # fix: '$' can match end of line as well
      haveSpecialClose=true
      specialCloseSE=param
    elsif control=="se" && controls[i][2]==0
      startSE=param
      controls[i]=nil
    elsif control=="ff"
      facewindow.dispose if facewindow
      facewindow=FaceWindowVX.new(param)
    elsif control=="ch"
      cmds=param.clone
      cmdvariable=pbCsvPosInt!(cmds)
      cmdIfCancel=pbCsvField!(cmds).to_i
      commands=[]
      while cmds.length>0
        commands.push(pbCsvField!(cmds))
      end
    elsif control=="wtnp" || control=="^"
      text=text.sub(/\001\z/,"") # fix: '$' can match end of line as well
    end
  end
  if startSE!=nil
    pbSEPlay(pbStringToAudioFile(startSE))
  elsif signWaitCount==0 && letterbyletter
    pbPlayDecisionSE()
  end
  ########## Position message window  ##############
  pbRepositionMessageWindow(msgwindow,linecount)
  if $game_message && $game_message.background==1
    msgback=IconSprite.new(0,msgwindow.y,msgwindow.viewport)
    msgback.z=msgwindow.z-1
    msgback.setBitmap("Graphics/System/MessageBack")
  end
  if facewindow
    pbPositionNearMsgWindow(facewindow,msgwindow,:left)
    facewindow.viewport=msgwindow.viewport
    facewindow.z=msgwindow.z
  end
  atTop=(msgwindow.y==0)
  ########## Show text #############################
  msgwindow.text=text
  Graphics.frame_reset if Graphics.frame_rate>40
  begin
    if shout != 0
      shout=(shout*-0.9).floor
      if atTop
        msgwindow.y=shout
      else
        msgwindow.y=Graphics.height-(msgwindow.height + shout)
      end
    end
    if signWaitCount>0
      signWaitCount-=1
      if atTop
        msgwindow.y=-(msgwindow.height*(signWaitCount)/20)
      else
        msgwindow.y=Graphics.height-(msgwindow.height*(20-signWaitCount)/20)
      end
    end
    for i in 0...controls.length
      if controls[i] && controls[i][2]<=msgwindow.position && msgwindow.waitcount==0
        control=controls[i][0]
        param=controls[i][1]
        case control
        # NEW
        when "xn"
          # Show name box, displaying string
          string=controls[i][1]
          extra=string.split(",")
          # Feed them 0/nil to pass down and later ignore
          extra[1]="" if extra[1]=="" || !extra[1]
          extra[2]="" if extra[2]=="" || !extra[2]
          extra[3]="0" if extra[3]=="" || !extra[3]
          extra[4]="0" if extra[4]=="" || !extra[4]
          extra[5]="nil" if extra[5]=="" || !extra[5]
          extra[6]="0" if extra[6]=="" || !extra[6]
          extra[7]="0" if extra[7]=="" || !extra[7]
          extra[8]="0" if extra[8]=="" || !extra[8]
          colorBase=extra[1]
          colorShadow=extra[2]
          font=extra[3]
          fontSize=extra[4]
          alignment=extra[5]
          forcedX=extra[6]
          forcedY=extra[7]
          newSkin=extra[8]
          namewindow.dispose if namewindow
          namewindow=pbDisplayNameWindow([msgwindow,string,false,colorBase,colorShadow,font,fontSize,alignment,forcedX,forcedY,newSkin])
        when "dxn"
          # Show dark name box, displaying string
          string=controls[i][1]
          extra=string.split(",")
          # Feed them 0/nil to pass down and later ignore
          extra[1]="" if extra[1]=="" || !extra[1]
          extra[2]="" if extra[2]=="" || !extra[2]
          extra[3]="0" if extra[3]=="" || !extra[3]
          extra[4]="0" if extra[4]=="" || !extra[4]
          extra[5]="nil" if extra[5]=="" || !extra[5]
          extra[6]="0" if extra[6]=="" || !extra[6]
          extra[7]="0" if extra[7]=="" || !extra[7]
          extra[8]="0" if extra[8]=="" || !extra[8]
          colorBase=extra[1]
          colorShadow=extra[2]
          font=extra[3]
          fontSize=extra[4]
          alignment=extra[5]
          forcedX=extra[6]
          forcedY=extra[7]
          newSkin=extra[8]
          namewindow.dispose if namewindow
          namewindow=pbDisplayNameWindow([msgwindow,string,true,colorBase,colorShadow,font,fontSize,alignment,forcedX,forcedY,newSkin])
        # START SAMPLES / PRESETS
        # Three samples, use xna, xnb or xnc instead of xn or dxn in the text command
        # These do not take any additional parameters except for name
        # I created these samples so if, for example, you use a couple of commands
        # all the time (like to make the text blue/red for some NPCs) you don't
        # have to manually type them all the time, and can use these as shortcuts
        # instead!
        # Customize at your own peril but feel free to contact me on the
        # resource's thread for some directions.
        # namewindow=pbDisplayNameWindow([msgwindow,string,true,colorBase,colorShadow,font,fontSize,alignment,forcedX,forcedY,newSkin])
        # Only keep msgwindow, string and the true/false, and set the others (as "0"/nil)
        when "xna"
          # Sample, sets a particular color (red)
          string=controls[i][1]
          namewindow.dispose if namewindow
          namewindow=pbDisplayNameWindow([msgwindow,string,false,"ef2110","ffadbd","0","0",nil,"0","0","0"])
        when "xnb"
          # Sample, sets a particular color (blue)
          string=controls[i][1]
          namewindow.dispose if namewindow
          namewindow=pbDisplayNameWindow([msgwindow,string,false,"0073ff","7bbdef","0","0",nil,"0","0","0"])
        when "xnc"
          # Sample, window is placed at 96, 96, uses a different font and windowskin
          string=controls[i][1]
          namewindow.dispose if namewindow
          namewindow=pbDisplayNameWindow([msgwindow,string,false,"0","0","Power Clear","0",nil,"96","96","speech frlg"])
        # END SAMPLES / PRESETS
        when "f"
          facewindow.dispose if facewindow
          facewindow=PictureWindow.new("Graphics/Pictures/#{param}")
          pbPositionNearMsgWindow(facewindow,msgwindow,:left)
          facewindow.viewport=msgwindow.viewport
          facewindow.z=msgwindow.z
        when "ts"
          if param==""
            msgwindow.textspeed=-999
          else
            msgwindow.textspeed=param.to_i
          end
        when "ff"
          facewindow.dispose if facewindow
          facewindow=FaceWindowVX.new(param)
          pbPositionNearMsgWindow(facewindow,msgwindow,:left)
          facewindow.viewport=msgwindow.viewport
          facewindow.z=msgwindow.z
        when "g" # Display gold window
          goldwindow.dispose if goldwindow
          goldwindow=pbDisplayGoldWindow(msgwindow)
        when "cn" # Display coins window
          coinwindow.dispose if coinwindow
          coinwindow=pbDisplayCoinsWindow(msgwindow,goldwindow)
        when "wu"
          msgwindow.y=0
          atTop=true
          msgback.y=msgwindow.y if msgback
          pbPositionNearMsgWindow(facewindow,msgwindow,:left)
          msgwindow.y=-(msgwindow.height*(signWaitCount)/20)
        when "wm"
          atTop=false
          msgwindow.y=(Graphics.height/2)-(msgwindow.height/2)
          msgback.y=msgwindow.y if msgback
          pbPositionNearMsgWindow(facewindow,msgwindow,:left)
        when "wd"
          atTop=false
          msgwindow.y=(Graphics.height)-(msgwindow.height)
          msgback.y=msgwindow.y if msgback
          pbPositionNearMsgWindow(facewindow,msgwindow,:left)
          msgwindow.y=Graphics.height-(msgwindow.height*(20-signWaitCount)/20)
        when "."
          msgwindow.waitcount+=Graphics.frame_rate/4
        when "|"
          msgwindow.waitcount+=Graphics.frame_rate
        when "wt" # Wait
          param=param.sub(/\A\s+/,"").sub(/\s+\z/,"")
          msgwindow.waitcount+=param.to_i*2
        when "w" # Windowskin
          if param==""
            msgwindow.windowskin=nil
          else
            msgwindow.setSkin("Graphics/Windowskins/#{param}")
          end
          msgwindow.width=msgwindow.width  # Necessary evil
        when "^" # Wait, no pause
          autoresume=true
        when "wtnp" # Wait, no pause
          param=param.sub(/\A\s+/,"").sub(/\s+\z/,"")
          msgwindow.waitcount=param.to_i*2
          autoresume=true
        when "se" # Play SE
          pbSEPlay(pbStringToAudioFile(param))
        when "me" # Play ME
          pbMEPlay(pbStringToAudioFile(param))
        end
        controls[i]=nil
      end
    end
    break if !letterbyletter
    Graphics.update
    Input.update
    facewindow.update if facewindow
    if $DEBUG && Input.trigger?(Input::F6)
      pbRecord(unformattedText)
    end
    if autoresume && msgwindow.waitcount==0
      msgwindow.resume if msgwindow.busy?
      break if !msgwindow.busy?
    end
    if Input.press?(Input::B) && $DEBUG
      msgwindow.textspeed=-999
      msgwindow.update
      if msgwindow.busy?
        pbPlayDecisionSE() if msgwindow.pausing?
        msgwindow.resume
      else
        break if signWaitCount==0
      end
    end
    if (Input.trigger?(Input::C) || Input.trigger?(Input::B))
      if msgwindow.busy?
        pbPlayDecisionSE() if msgwindow.pausing?
        msgwindow.resume
      else
        break if signWaitCount==0
      end
    end
    pbUpdateSceneMap
    msgwindow.update
    yield if block_given?
  end until (!letterbyletter || commandProc || commands) && !msgwindow.busy?
  Input.update # Must call Input.update again to avoid extra triggers
  msgwindow.letterbyletter=oldletterbyletter
  if commands
    $game_variables[cmdvariable]=pbShowCommands(
       msgwindow,commands,cmdIfCancel)
    $game_map.need_refresh = true if $game_map
  end
  if commandProc
    ret=commandProc.call(msgwindow)
  end
  msgback.dispose if msgback
  # NEW
  namewindow.dispose if namewindow
  goldwindow.dispose if goldwindow
  coinwindow.dispose if coinwindow
  facewindow.dispose if facewindow
  if haveSpecialClose
    pbSEPlay(pbStringToAudioFile(specialCloseSE))
    atTop=(msgwindow.y==0)
    for i in 0..20
      if atTop
        msgwindow.y=-(msgwindow.height*(i)/20)
      else
        msgwindow.y=Graphics.height-(msgwindow.height*(20-i)/20)
      end
      Graphics.update
      Input.update
      pbUpdateSceneMap
      msgwindow.update
    end
  end
  return ret
end
