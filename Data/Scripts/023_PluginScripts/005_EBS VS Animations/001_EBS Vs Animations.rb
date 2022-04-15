#-------------------------------------------------------------------------------
# New EBS VS. animation
#-------------------------------------------------------------------------------
def vsSequenceNew(viewport,trainername,trainerid,tbargraphic,tgraphic)
  Graphics.frame_rate = 40
  #------------------
  # sets the face2 graphic to be the shadow instead of larger mug
  showShadow = false
  # decides whether or not to colour the vsLight(s) according to the vsBar
  colorLight = true
  # decides whether or not to return to default white colour
  colorReset = true
  #------------------
  ow = Sprite.new(viewport)
  ow.bitmap = Graphics.snap_to_bitmap
  ow.blur_sprite
  ow.opacity = 0
  ow.tone = Tone.new(-92,-92,-92)

  bmp = pbBitmap("Graphics/Transitions/vsLight3")
  globaly = viewport.rect.height*0.4

  bar = Sprite.new(viewport)
  bar.bitmap = pbBitmap(tbargraphic)
  bar.ox = bar.bitmap.width
  bar.oy = bar.bitmap.height/2
  bar.x = viewport.rect.width*2 + 64
  bar.y = globaly

  color = bar.bitmap.get_pixel(bar.bitmap.width/2,1)

  bbar1 = Sprite.new(viewport)
  bbar1.bitmap = Bitmap.new(viewport.rect.width,2)
  bbar1.bitmap.fill_rect(0,0,viewport.rect.width,2,Color.new(0,0,0))
  bbar1.y = bar.y - bar.oy
  bbar1.zoom_y = 0
  bbar1.z = 99

  bbar2 = Sprite.new(viewport)
  bbar2.bitmap = Bitmap.new(viewport.rect.width,2)
  bbar2.bitmap.fill_rect(0,0,viewport.rect.width,2,Color.new(0,0,0))
  bbar2.oy = 2
  bbar2.y = bar.y + bar.oy + 8
  bbar2.zoom_y = 0
  bbar2.z = 99

  face2 = Sprite.new(viewport)
  face2.bitmap = pbBitmap(tgraphic)
  face2.src_rect.set(0,face2.bitmap.height/4,face2.bitmap.width,face2.bitmap.height/2) if !showShadow
  face2.oy = face2.src_rect.height/2
  face2.y = globaly
  face2.zoom_x = 2 if !showShadow
  face2.zoom_y = 2 if !showShadow
  face2.opacity = showShadow ? 255 : 92
  face2.visible = false
  face2.x = showShadow ? (viewport.rect.width - face2.bitmap.width + 16) : (viewport.rect.width - face2.bitmap.width*2 + 64)
  face2.color = Color.new(0,0,0,255) if showShadow

  light3 = Sprite.new(viewport)
  light3.bitmap = Bitmap.new(bmp.width*2,bmp.height)
  for i in 0...2
    light3.bitmap.blt(bmp.width*i,0,bmp,Rect.new(0,0,bmp.width,bmp.height))
  end
  light3.x = viewport.rect.width
  light3.oy = bmp.height/2
  light3.y = globaly
  if colorLight
    light3.color = color
    light3.color.alpha = 127
  end

  light1 = Sprite.new(viewport)
  light1.bitmap = pbBitmap("Graphics/Transitions/vsLight1")
  light1.ox = light1.bitmap.width/2
  light1.oy = light1.bitmap.height/2
  light1.x = viewport.rect.width*0.25
  light1.y = globaly
  light1.zoom_x = 0
  light1.zoom_y = 0
  if colorLight
    light1.color = color
    light1.color.alpha = 127
  end

  light2 = Sprite.new(viewport)
  light2.bitmap = pbBitmap("Graphics/Transitions/vsLight2")
  light2.ox = light2.bitmap.width/2
  light2.oy = light2.bitmap.height/2
  light2.x = viewport.rect.width*0.25
  light2.y = globaly
  light2.zoom_x = 0
  light2.zoom_y = 0
  if colorLight
    light2.color = color
    light2.color.alpha = 127
  end

  vs = Sprite.new(viewport)
  vs.bitmap = pbBitmap("Graphics/Transitions/vs")
  vs.ox = vs.bitmap.width/2
  vs.oy = vs.bitmap.height/2
  vs.x = viewport.rect.width*0.25
  vs.y = globaly
  vs.opacity = 0
  vs.zoom_x = 4
  vs.zoom_y = 4

  face1 = Sprite.new(viewport)
  face1.bitmap = pbBitmap(tgraphic)
  face1.oy = face1.bitmap.height/2
  face1.y = globaly
  face1.x = viewport.rect.width
  face1.color = Color.new(0,0,0,255)

  name = Sprite.new(viewport)
  name.bitmap = Bitmap.new(viewport.rect.width/2,96)
  pbSetSystemFont(name.bitmap)
  name.ox = name.bitmap.width/2
  name.x = viewport.rect.width*0.75
  name.y = bar.y + bar.oy
  pbDrawTextPositions(name.bitmap,[[trainername,name.bitmap.width/2,4,2,Color.new(255,255,255),nil]])
  name.visible = false

  ripples = Sprite.new(viewport)
  ripples.bitmap = pbBitmap("Graphics/Transitions/ripples")
  ripples.ox = ripples.bitmap.width/2
  ripples.oy = ripples.bitmap.height/2
  ripples.x = vs.x
  ripples.y = globaly
  ripples.opacity = 0
  ripples.z = 99
  ripples.zoom_x = 0.0
  ripples.zoom_y = 0.0

  8.times do
    light1.zoom_x+=1.0/16
    light1.zoom_y+=1.0/16
    light2.zoom_x+=1.0/8
    light2.zoom_y+=1.0/8
    light1.angle-=32
    light2.angle+=64
    light3.x-=64
    ow.opacity+=12.8
    pbWait(1)
  end
  n = false
  k = false
  max = 224
  for i in 0...max
    n = !n if i%8==0
    k = !k if i%4==0
    ow.opacity+=12.8 if ow.opacity < 255
    light1.zoom_x+=(n ? 1.0/16 : -1.0/16)
    light1.zoom_y+=(n ? 1.0/16 : -1.0/16)
    light1.angle-=16
    light2.angle+=32
    light3.x-=32
    light3.x = 0 if light3.x <= -light3.bitmap.width/2
    if i >= 32 && i < 41
      bar.x-=64
      pbSEPlay("Ice8",80) if i==32
    end
    if i >= 32
      face1.x-=(face1.x-viewport.rect.width/2)*0.1
    end
    viewport.color.alpha-=255/20.0 if viewport.color.alpha > 0
    face2.x -= (showShadow ? -1 : 1) if i%(showShadow ? 4 : 2)==0 && face2.visible
    vs.x+=(k ? 2 : -2)/2 if i >= 72
    vs.y-=(k ? 2 : -2)/2 if i >= 72
    ripples.opacity-=12.8 if ripples.opacity > 0
    ripples.zoom_x+=0.2 if ripples.opacity > 0
    ripples.zoom_y+=0.2 if ripples.opacity > 0
    if i > 62
      vs.opacity+=25.5 if vs.opacity < 255
      vs.zoom_x-=0.2 if vs.zoom_x > 1
      vs.zoom_y-=0.2 if vs.zoom_y > 1
    end
    if i==72
      viewport.color = Color.new(255,255,255,255)
      ow.color = Color.new(0,0,0,255)
      face2.visible = true
      face1.color = Color.new(0,0,0,0)
      name.visible = true
      ripples.opacity = 255
      pbSEPlay("Saint9",50)
      pbSEPlay("Flash2",50)
      if colorReset
        light1.color = Color.new(0,0,0,0)
        light2.color = Color.new(0,0,0,0)
        light3.color = Color.new(0,0,0,0)
      end
    end
    if i >= max-8
      bbar1.zoom_y+=8
      bbar2.zoom_y+=8
      name.opacity-=255/4.0
    end
    pbWait(1)
  end
  viewport.color = Color.new(0,0,0,255)
  ow.dispose
  bar.dispose
  bbar1.dispose
  bbar2.dispose
  face1.dispose
  face2.dispose
  light1.dispose
  light2.dispose
  light3.dispose
  ripples.dispose
  vs.dispose
  Graphics.frame_rate = 60
  return true
end

#-------------------------------------------------------------------------------
# Elite Four EBS VS. animation
#-------------------------------------------------------------------------------
def vsSequenceElite(viewport,trainername,trainerid,tbargraphic,tgraphic)
  ow = Sprite.new(viewport)
  ow.bitmap = Graphics.snap_to_bitmap
  ow.blur_sprite
  ow.opacity = 0
  ow.tone = Tone.new(-92,-92,-92)

  effect1 = Sprite.new(viewport)
  effect1.bitmap = pbBitmap("Graphics/Transitions/vsBg")
  effect1.ox = effect1.bitmap.width/2
  effect1.x = viewport.rect.width/2
  effect1.oy = effect1.bitmap.height/2
  effect1.y = viewport.rect.height/2
  effect1.visible = false

  bmp = pbBitmap("Graphics/Transitions/vsLight3")

  bar1 = Sprite.new(viewport)
  bar1.bitmap = pbBitmap(tbargraphic)
  bar1.oy = bar1.bitmap.height/2
  bar1.y = viewport.rect.height*0.25
  bar1.x = viewport.rect.width

  light1 = Sprite.new(viewport)
  light1.bitmap = Bitmap.new(bmp.width*2,bmp.height)
  for i in 0...2
    light1.bitmap.blt(bmp.width*i,0,bmp,Rect.new(0,0,bmp.width,bmp.height))
  end
  light1.x = viewport.rect.width
  light1.oy = bmp.height/2
  light1.y = viewport.rect.height*0.25

  shadow1 = Sprite.new(viewport)
  shadow1.bitmap = pbBitmap(tgraphic)
  shadow1.oy = shadow1.bitmap.height/2
  shadow1.y = viewport.rect.height*0.25
  shadow1.x = viewport.rect.width/2 - 16
  shadow1.color = Color.new(0,0,0,255)
  shadow1.opacity = 96
  shadow1.visible = false

  face1 = Sprite.new(viewport)
  face1.bitmap = pbBitmap(tgraphic)
  face1.oy = face1.bitmap.height/2
  face1.y = viewport.rect.height*0.25
  face1.x = viewport.rect.width
  face1.color = Color.new(0,0,0,255)

  #-------------------
  outfit=$Trainer ? $Trainer.outfit : 0
  pbargraphic=sprintf("Graphics/Transitions/vsBarElite%s_%d",getConstantName(PBTrainers,$Trainer.trainertype),outfit) rescue nil
  pbargraphic=sprintf("Graphics/Transitions/vsBarElite%d_%d",$Trainer.trainertype,outfit) if !pbResolveBitmap(pbargraphic)
  if !pbResolveBitmap(pbargraphic)
    pbargraphic=sprintf("Graphics/Transitions/vsBarElite%s",getConstantName(PBTrainers,$Trainer.trainertype)) rescue nil
  end
  pbargraphic=sprintf("Graphics/Transitions/vsBarElite%d",$Trainer.trainertype) if !pbResolveBitmap(pbargraphic)
  pgraphic=sprintf("Graphics/Transitions/vsTrainer%s_%d",getConstantName(PBTrainers,$Trainer.trainertype),outfit) rescue nil
  pgraphic=sprintf("Graphics/Transitions/vsTrainer%d_%d",$Trainer.trainertype,outfit) if !pbResolveBitmap(pgraphic)
  if !pbResolveBitmap(pgraphic)
    pgraphic=sprintf("Graphics/Transitions/vsTrainer%s",getConstantName(PBTrainers,$Trainer.trainertype)) rescue nil
  end
  pgraphic=sprintf("Graphics/Transitions/vsTrainer%d",$Trainer.trainertype) if !pbResolveBitmap(pgraphic)
  #-------------------

  bar2 = Sprite.new(viewport)
  bar2.bitmap = pbBitmap(pbargraphic)
  bar2.oy = bar2.bitmap.height/2
  bar2.y = viewport.rect.height*0.75
  bar2.x = -bar2.bitmap.width

  light2 = Sprite.new(viewport)
  light2.bitmap = light1.bitmap.clone
  light2.mirror = true
  light2.x = -light2.bitmap.width
  light2.oy = bmp.height/2
  light2.y = viewport.rect.height*0.75

  shadow2 = Sprite.new(viewport)
  shadow2.bitmap = pbBitmap(pgraphic)
  shadow2.oy = shadow2.bitmap.height/2
  shadow2.y = viewport.rect.height*0.75
  shadow2.x = 16
  shadow2.color = Color.new(0,0,0,255)
  shadow2.opacity = 96
  shadow2.visible = false

  face2 = Sprite.new(viewport)
  face2.bitmap = pbBitmap(pgraphic)
  face2.oy = face2.bitmap.height/2
  face2.y = viewport.rect.height*0.75
  face2.x = -face2.bitmap.width
  face2.color = Color.new(0,0,0,255)

  ripples = Sprite.new(viewport)
  ripples.bitmap = pbBitmap("Graphics/Transitions/ripples")
  ripples.ox = ripples.bitmap.width/2
  ripples.oy = ripples.bitmap.height/2
  ripples.x = viewport.rect.width/2
  ripples.y = viewport.rect.height/2
  ripples.opacity = 0
  ripples.zoom_x = 0.0
  ripples.zoom_y = 0.0
  ripples.z = 999

  vs = Sprite.new(viewport)
  vs.bitmap = pbBitmap("Graphics/Transitions/vs")
  vs.ox = vs.bitmap.width/2
  vs.oy = vs.bitmap.height/2
  vs.x = viewport.rect.width/2
  vs.y = viewport.rect.height/2
  vs.opacity = 0
  vs.zoom_x = 4
  vs.zoom_y = 4
  vs.z = 999

  names = Sprite.new(viewport)
  names.bitmap = Bitmap.new(viewport.rect.width,viewport.rect.height)
  names.z = 99999
  pbSetSystemFont(names.bitmap)
  txt = [
    [trainername,viewport.rect.width*0.25,viewport.rect.height*0.25+32,2,Color.new(255,255,255),Color.new(32,32,32)],
    [$Trainer.name,viewport.rect.width*0.75,viewport.rect.height*0.75+32,2,Color.new(255,255,255),Color.new(32,32,32)]
  ]
  pbDrawTextPositions(names.bitmap,txt)
  names.visible = false

  max = 224
  k = false
  for i in 0...max
    k = !k if i%4==0
    viewport.color.alpha-=255/16.0 if viewport.color.alpha > 0
    ow.opacity+=12.8 if ow.opacity < 255
    light1.x-=(light1.x > 0) ? 64 : 32
    light1.x = 0 if light1.x <= -light1.bitmap.width/2
    bar1.x-=(bar1.x)*0.2 if i >= 32

    face1.x-=(face1.x-viewport.rect.width/2)*0.1 if i >= 16
    face2.x+=(0-face2.x)*0.1 if i >= 16

    light2.x+=(light2.x < -light2.bitmap.width/2) ? 64 : 32
    light2.x = -light2.bitmap.width/2 if light2.x >= 0
    bar2.x+=(0-bar2.x)*0.2 if i >= 32

    effect1.angle+=2 if $PokemonSystem.screensize < 2
    vs.x+=(k ? 2 : -2)/2 if i >= 72
    vs.y-=(k ? 2 : -2)/2 if i >= 72
    ripples.opacity-=12.8 if ripples.opacity > 0
    ripples.zoom_x+=0.2 if ripples.opacity > 0
    ripples.zoom_y+=0.2 if ripples.opacity > 0
    if i%4 == 0
      shadow1.x-=1
      shadow2.x+=1
    end
    if i > 62 && i < max-16
      vs.opacity+=25.5 if vs.opacity < 255
      vs.zoom_x-=0.2 if vs.zoom_x > 1
      vs.zoom_y-=0.2 if vs.zoom_y > 1
    end
    if i == 72
      face1.color = Color.new(0,0,0,0)
      face2.color = Color.new(0,0,0,0)
      viewport.color = Color.new(255,255,255,255)
      ow.color = Color.new(0,0,0,255)
      effect1.visible = true
      ripples.opacity = 255
      names.visible = true
      shadow1.visible = true
      shadow2.visible = true
      pbSEPlay("Saint9",50)
      pbSEPlay("Flash2",50)
    end
    viewport.color = Color.new(0,0,0,0) if i == max-17
    if i >= max-16
      vs.zoom_x+=0.2
      vs.zoom_y+=0.2
      viewport.color.alpha+=255/8.0
    end

    pbWait(1)
  end
  viewport.color = Color.new(0,0,0,255)
  ow.dispose
  effect1.dispose
  bar1.dispose
  bar2.dispose
  light1.dispose
  light2.dispose
  face1.dispose
  face2.dispose
  shadow1.dispose
  shadow2.dispose
  names.dispose
  vs.dispose
  ripples.dispose
  return true
end

#-------------------------------------------------------------------------------
# Special EBS VS. animation
#-------------------------------------------------------------------------------
def vsSequenceSpecial(viewport,trainername,trainerid,tbargraphic,tgraphic)
  Graphics.frame_rate = 40
  ow = Sprite.new(viewport)
  ow.bitmap = Graphics.snap_to_bitmap
  ow.blur_sprite
  ow.opacity = 0

  bg = Sprite.new(viewport)
  bg.visible = false

  light = AnimatedPlane.new(viewport)
  light.bitmap = pbBitmap("Graphics/Transitions/vsSpecialLight")
  light.opacity = 0

  vss = Sprite.new(viewport)
  vss.bitmap = pbBitmap("Graphics/Transitions/vs")
  vss.color = Color.new(0,0,0,255)
  vss.ox = vss.bitmap.width/2
  vss.oy = vss.bitmap.height/2
  vss.x = 110 + 16
  vss.y = 132 + 16
  vss.opacity = 128
  vss.visible = false

  vs = Sprite.new(viewport)
  vs.bitmap = pbBitmap("Graphics/Transitions/vs")
  vs.ox = vs.bitmap.width/2
  vs.oy = vs.bitmap.height/2
  vs.x = 110
  vs.y = 132
  vs.visible = false

  names = Sprite.new(viewport)
  names.x = 6
  names.y = 4
  names.opacity = 128
  names.color = Color.new(0,0,0,255)
  names.visible = false

  name = Sprite.new(viewport)
  name.bitmap = Bitmap.new(viewport.rect.width,viewport.rect.height)
  name.bitmap.font.name = "Arial"
  name.bitmap.font.size = 48
  name.visible = false
  pbSetSystemFont(name.bitmap)
  name.bitmap.font.size = 69
  name.z = 100
  pbDrawOutlineText(name.bitmap,32,viewport.rect.height-160,-1,-1,"#{trainername}",Color.new(255,255,255),Color.new(0,0,0),2)
  names.bitmap = name.bitmap.clone

  border1 = Sprite.new(viewport)
  border1.bitmap = pbBitmap("Graphics/Transitions/vsBorder")
  border1.zoom_x = 1.2
  border1.y = -border1.bitmap.height
  border1.z = 97

  border2 = Sprite.new(viewport)
  border2.bitmap = pbBitmap("Graphics/Transitions/vsBorder")
  border2.zoom_x = 1.2
  border2.x = viewport.rect.width
  border2.angle = 180
  border2.y = viewport.rect.height+border2.bitmap.height
  border2.z = 97

  trainer = Sprite.new(viewport)
  trainer.bitmap = pbBitmap(tgraphic)
  trainer.x = 0
  trainer.ox = trainer.bitmap.width
  trainer.z = 99
  trainer.color = Color.new(0,0,0,255)

  shadow = Sprite.new(viewport)
  shadow.bitmap = pbBitmap(tgraphic)
  shadow.x = viewport.rect.width + 22
  shadow.ox = shadow.bitmap.width
  shadow.y = 22
  shadow.color = Color.new(0,0,0,255)
  shadow.opacity = 128
  shadow.visible = false

  if pbResolveBitmap(tbargraphic)
    bg.bitmap = pbBitmap(tbargraphic)
  else
    bg.bitmap = Bitmap.new(viewport.rect.width,viewport.rect.height)
    color = trainer.getAvgColor
    avg = ((color.red+color.green+color.blue)/3)-120
    color = Color.new(color.red-avg,color.green-avg,color.blue-avg)
    bg.bitmap.fill_rect(0,0,viewport.rect.width,viewport.rect.height,color)
  end

  bg.blur_sprite
  y1 = border1.y.to_f
  y2 = border2.y.to_f
  30.times do
    ow.opacity += 12.8
    y1 += ((70-border1.bitmap.height)-y1)*0.2
    border1.y = y1
    y2 -= (y2-(viewport.rect.height+border2.bitmap.height-70))*0.2
    border2.y = y2
    light.opacity+=12.8
    light.ox += 24
    pbWait(1)
  end
  40.times do
    trainer.x += ((viewport.rect.width)-trainer.x)*0.2
    light.ox += 24
    pbWait(1)
  end

  viewport.tone = Tone.new(255,255,255)
  bg.visible = true
  shadow.visible = true
  vs.visible = true
  vss.visible = true
  name.visible = true
  names.visible = true
  trainer.color = Color.new(0,0,0,0)

  p = 1
  20.times do
    viewport.tone.red -= 255/20.0
    viewport.tone.green -= 255/20.0
    viewport.tone.blue -= 255/20.0
    light.ox += 24
    vs.x += p; vs.y -= p
    p = -1 if vs.x >= 112
    p = +1 if vs.x <= 108
    vss.x = vs.x + 16; vss.y = vs.y + 16
    pbWait(1)
  end
  120.times do
    light.ox += 24
    vs.x += p; vs.y -= p
    p = -1 if vs.x >= 112
    p = +1 if vs.x <= 108
    vss.x = vs.x + 16; vss.y = vs.y + 16
    pbWait(1)
  end
  y1 = border1.y.to_f
  y2 = border2.y.to_f
  6.times do
    trainer.x -= 1
    shadow.x = trainer.x + 22
    light.ox += 24
    vs.x += p; vs.y -= p
    p = -1 if vs.x >= 112
    p = +1 if vs.x <= 108
    vss.x = vs.x + 16; vss.y = vs.y + 16
    pbWait(1)
  end
  30.times do
    trainer.x += ((viewport.rect.width*2)-trainer.x)*0.2
    name.opacity -= 84
    shadow.x = trainer.x + 22
    y1 += ((0)-y1)*0.2
    border1.y = y1
    y2 -= (y2-(viewport.rect.height))*0.2
    border2.y = y2
    light.ox += 24
    vs.x += p; vs.y -= p
    p = -1 if vs.x >= 112
    p = +1 if vs.x <= 108
    vss.x = vs.x + 16; vss.y = vs.y + 16
    pbWait(1)
  end
  ow.dispose
  bg.dispose
  vs.dispose
  vss.dispose
  name.dispose
  names.dispose
  trainer.dispose
  shadow.dispose
  light.dispose
  viewport.color=Color.new(0,0,0,255)
  Graphics.frame_rate = 60
  return true
end

#-------------------------------------------------------------------------------
# New EBS VS. animation
#-------------------------------------------------------------------------------
def vsSequenceEvil(viewport,trainername,trainerid,tbargraphic,tgraphic,tlogographic)
  Graphics.frame_rate = 40
  trainername = PBTrainers.getName(trainerid)
  #------------------
  # sets the face2 graphic to be the shadow instead of larger mug
  showShadow = false
  # decides whether or not to colour the vsLight(s) according to the vsBar
  colorLight = true
  # decides whether or not to return to default white colour
  colorReset = true
  #------------------
  ow = Sprite.new(viewport)
  ow.bitmap = Graphics.snap_to_bitmap
  ow.blur_sprite
  ow.opacity = 0
  ow.tone = Tone.new(-92,-92,-92)

  bmp = pbBitmap("Graphics/Transitions/vsLight3")
  globaly = viewport.rect.height*0.4

  bar = Sprite.new(viewport)
  bar.bitmap = pbBitmap(tbargraphic)
  bar.ox = bar.bitmap.width
  bar.oy = bar.bitmap.height/2
  bar.x = viewport.rect.width*2 + 64
  bar.y = globaly

  color = bar.bitmap.get_pixel(bar.bitmap.width/2,1)

  bbar1 = Sprite.new(viewport)
  bbar1.bitmap = Bitmap.new(viewport.rect.width,2)
  bbar1.bitmap.fill_rect(0,0,viewport.rect.width,2,Color.new(0,0,0))
  bbar1.y = bar.y - bar.oy
  bbar1.zoom_y = 0
  bbar1.z = 99

  bbar2 = Sprite.new(viewport)
  bbar2.bitmap = Bitmap.new(viewport.rect.width,2)
  bbar2.bitmap.fill_rect(0,0,viewport.rect.width,2,Color.new(0,0,0))
  bbar2.oy = 2
  bbar2.y = bar.y + bar.oy + 8
  bbar2.zoom_y = 0
  bbar2.z = 99

  face2 = Sprite.new(viewport)
  face2.bitmap = pbBitmap(tlogographic)
  face2.src_rect.set(0,face2.bitmap.height/4,face2.bitmap.width,face2.bitmap.height/2) if !showShadow
  face2.oy = face2.src_rect.height/2
  face2.y = globaly
  face2.zoom_x = 2 if !showShadow
  face2.zoom_y = 2 if !showShadow
  face2.opacity = 175
  face2.visible = false
  face2.x = showShadow ? (viewport.rect.width - face2.bitmap.width + 16) : (viewport.rect.width - face2.bitmap.width*2 + 64)
  face2.color = Color.new(0,0,0,255) if showShadow

  light3 = Sprite.new(viewport)
  light3.bitmap = Bitmap.new(bmp.width*2,bmp.height)
  for i in 0...2
    light3.bitmap.blt(bmp.width*i,0,bmp,Rect.new(0,0,bmp.width,bmp.height))
  end
  light3.x = viewport.rect.width
  light3.oy = bmp.height/2
  light3.y = globaly
  if colorLight
    light3.color = color
    light3.color.alpha = 127
  end

  light1 = Sprite.new(viewport)
  light1.bitmap = pbBitmap("Graphics/Transitions/vsLight1")
  light1.ox = light1.bitmap.width/2
  light1.oy = light1.bitmap.height/2
  light1.x = viewport.rect.width*0.25
  light1.y = globaly
  light1.zoom_x = 0
  light1.zoom_y = 0
  if colorLight
    light1.color = color
    light1.color.alpha = 127
  end

  light2 = Sprite.new(viewport)
  light2.bitmap = pbBitmap("Graphics/Transitions/vsLight2")
  light2.ox = light2.bitmap.width/2
  light2.oy = light2.bitmap.height/2
  light2.x = viewport.rect.width*0.25
  light2.y = globaly
  light2.zoom_x = 0
  light2.zoom_y = 0
  if colorLight
    light2.color = color
    light2.color.alpha = 127
  end

  vs = Sprite.new(viewport)
  vs.bitmap = pbBitmap("Graphics/Transitions/vs")
  vs.ox = vs.bitmap.width/2
  vs.oy = vs.bitmap.height/2
  vs.x = viewport.rect.width*0.25
  vs.y = globaly
  vs.opacity = 0
  vs.zoom_x = 4
  vs.zoom_y = 4

  face1 = Sprite.new(viewport)
  face1.bitmap = pbBitmap(tgraphic)
  face1.oy = face1.bitmap.height/2
  face1.y = globaly
  face1.x = viewport.rect.width
  face1.color = Color.new(0,0,0,255)

  name = Sprite.new(viewport)
  name.bitmap = Bitmap.new(viewport.rect.width/2,96)
  pbSetSystemFont(name.bitmap)
  name.ox = name.bitmap.width/2
  name.x = viewport.rect.width*0.75
  name.y = bar.y + bar.oy
  pbDrawTextPositions(name.bitmap,[[trainername,name.bitmap.width/2,4,2,Color.new(255,255,255),nil]])
  name.visible = false

  ripples = Sprite.new(viewport)
  ripples.bitmap = pbBitmap("Graphics/Transitions/ripples")
  ripples.ox = ripples.bitmap.width/2
  ripples.oy = ripples.bitmap.height/2
  ripples.x = vs.x
  ripples.y = globaly
  ripples.opacity = 0
  ripples.z = 99
  ripples.zoom_x = 0.0
  ripples.zoom_y = 0.0

  8.times do
    light1.zoom_x+=1.0/16
    light1.zoom_y+=1.0/16
    light2.zoom_x+=1.0/8
    light2.zoom_y+=1.0/8
    light1.angle-=32
    light2.angle+=64
    light3.x-=64
    ow.opacity+=12.8
    pbWait(1)
  end
  n = false
  k = false
  max = 224
  for i in 0...max
    n = !n if i%8==0
    k = !k if i%4==0
    ow.opacity+=12.8 if ow.opacity < 255
    light1.zoom_x+=(n ? 1.0/16 : -1.0/16)
    light1.zoom_y+=(n ? 1.0/16 : -1.0/16)
    light1.angle-=16
    light2.angle+=32
    light3.x-=32
    light3.x = 0 if light3.x <= -light3.bitmap.width/2
    if i >= 32 && i < 41
      bar.x-=64
      pbSEPlay("Ice8",80) if i==32
    end
    if i >= 32
      face1.x-=(face1.x-viewport.rect.width/2)*0.1
    end
    viewport.color.alpha-=255/20.0 if viewport.color.alpha > 0
    face2.x -= (showShadow ? -1 : 1) if i%(showShadow ? 4 : 2)==0 && face2.visible
    vs.x+=(k ? 2 : -2)/2 if i >= 72
    vs.y-=(k ? 2 : -2)/2 if i >= 72
    ripples.opacity-=12.8 if ripples.opacity > 0
    ripples.zoom_x+=0.2 if ripples.opacity > 0
    ripples.zoom_y+=0.2 if ripples.opacity > 0
    if i > 62
      vs.opacity+=25.5 if vs.opacity < 255
      vs.zoom_x-=0.2 if vs.zoom_x > 1
      vs.zoom_y-=0.2 if vs.zoom_y > 1
    end
    if i==72
      viewport.color = Color.new(255,255,255,255)
      ow.color = Color.new(0,0,0,255)
      face2.visible = true
      face1.color = Color.new(0,0,0,0)
      name.visible = true
      ripples.opacity = 255
      pbSEPlay("Saint9",50)
      pbSEPlay("Flash2",50)
      if colorReset
        light1.color = Color.new(0,0,0,0)
        light2.color = Color.new(0,0,0,0)
        light3.color = Color.new(0,0,0,0)
      end
    end
    if i >= max-8
      bbar1.zoom_y+=8
      bbar2.zoom_y+=8
      name.opacity-=255/4.0
    end
    pbWait(1)
  end
  viewport.color = Color.new(0,0,0,255)
  ow.dispose
  bar.dispose
  bbar1.dispose
  bbar2.dispose
  face1.dispose
  face2.dispose
  light1.dispose
  light2.dispose
  light3.dispose
  ripples.dispose
  vs.dispose
  Graphics.frame_rate = 60
  return true
end
