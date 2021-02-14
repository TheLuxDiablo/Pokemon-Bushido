
################################################################################
# Simple Exit Arrows - by Tustin2121
#
# To use, set the graphic of your exit warp event to an arrow with
# the desired hue and name it "ExitArrow" (without the quotes).
#
# The below code will do the work of hiding and showing the arrow when needed.
################################################################################

def checkExitArrows(init=false)
  px = $game_player.x
  py = $game_player.y
  for event in $game_map.events.values
    next if event.name != "ExitArrow"
    case $game_player.direction
    when 2; event.transparent = !(px == event.x && py == event.y-1)
    when 8; event.transparent = !(px == event.x && py == event.y+1)
    when 4; event.transparent = !(px == event.x+1 && py == event.y)
    when 6; event.transparent = !(px == event.x-1 && py == event.y)
    end
    pbMoveRoute(event,[PBMoveRoute::ChangeSpeed,2,PBMoveRoute::StepAnimeOn,PBMoveRoute::DirectionFixOn,PBMoveRoute::WalkAnimeOff])
  end
end

# Run on scene change, init them as well
Events.onMapSceneChange+=proc{|sender,e|
  checkExitArrows(true)
}

Events.onChangeDirection += proc{|sender,e|
  checkExitArrows
}

# Run on every step taken
Events.onStepTaken+=proc {|sender,e|
  checkExitArrows
}
