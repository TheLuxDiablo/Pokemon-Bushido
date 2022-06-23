class PokeBattle_Move_0CE
  def pbShowAnimation(id,user,targets,hitNum=0,showAnimation=true)
    hitNum = 1 if @chargingTurn && !@damagingTurn   # Charging anim
    if hitNum == 0
      target = (targets.is_a?(Array) ? target[0] : targets)
      @battle.scene.sprites["pokemon_#{user.index}"]&.no_anim   = false
      @battle.scene.sprites["pokemon_#{target.index}"]&.no_anim = false
    end
    super
    if hitNum == 1
      target = (targets.is_a?(Array) ? target[0] : targets)
      @battle.scene.sprites["pokemon_#{user.index}"]&.no_anim   = true
      @battle.scene.sprites["pokemon_#{target.index}"]&.no_anim = true
    end
  end
end

class PokeBattle_Battler
  alias twoturn_pbSuccessCheckAgainstTarget pbSuccessCheckAgainstTarget unless method_defined?(:twoturn_pbSuccessCheckAgainstTarget)
  def pbSuccessCheckAgainstTarget(*args)
    ret = twoturn_pbSuccessCheckAgainstTarget(*args)
    move   = args[0]
    user   = args[1]
    target = args[2]
    @battle.scene.sprites["pokemon_#{user.index}"]&.no_anim   = false if !ret
    @battle.scene.sprites["pokemon_#{target.index}"]&.no_anim = false if !ret && move.function == "0CE"
    @battle.scene.pbFrameUpdate
    return ret
  end

  alias twoturn_pbCancelMoves pbCancelMoves unless method_defined?(:twoturn_pbCancelMoves)
  def pbCancelMoves(*args)
    ret = twoturn_pbCancelMoves(*args)
    @battle.scene.sprites["pokemon_#{self.index}"]&.no_anim = false
    @battle.scene.pbFrameUpdate
    return ret
  end
end

class PokemonBattlerSprite
  attr_reader :no_anim

  def no_anim=(value)
    @no_anim = value
    self.visible = !value
    self.opacity = value ? 0 : 255
  end
end

def pbSearchAnimations(animations, cmdwin, canvas, animwin)
  window   = ControlWindow.new(320, 128, 320, 32 * 4)
  window.z = 99999
  window.addControl(TextField.new(_INTL("Search for:"), ""))
  okbutton = window.addButton(_INTL("OK"))
  cancelbutton = window.addButton(_INTL("Cancel"))
  window.opacity = 224
  breaking_off = false
  searchname = nil
  Input.text_input = true
  loop do
    Graphics.update
    Input.update
    window.update
    if window.changed?(okbutton) || Input.triggerex?(:RETURN)
      searchname = window.controls[0].text
      break
    end
    if window.changed?(cancelbutton) || Input.triggerex?(:ESCAPE)
      breaking_off = true
      break
    end
  end
  Input.text_input = false
  if breaking_off
    window.dispose
    return false
  end
  window.dispose
  hassearchterm = []
  newanimations = []
  searchnameupcase = searchname.upcase
  (0...animations.length).each do |i|
    upcasednames = animations[i].name.upcase
    if upcasednames.include?(searchnameupcase)
      newanimations.push(animations[i])
      hassearchterm.push([i, animations[i]])
    end
  end
  if hassearchterm.length == 0
    pbMessage("No results found.")
    return
  end
  commands = []
  (0...hassearchterm.length).each do |i|
    hassearchterm[i][1] = PBAnimation.new if !hassearchterm[i][1]
    commands[commands.length] = _INTL("{1} {2}", hassearchterm[i][0], hassearchterm[i][1].name)
  end
  cmdwin = pbListWindow(commands, 320)
  cmdwin.height = 416
  cmdwin.opacity = 224
  cmdwin.index = 0
  cmdwin.viewport = canvas.viewport
  helpwindow = Window_UnformattedTextPokemon.newWithSize(
    _INTL("C: Load/rename an animation\nEsc: Cancel"),
    320, 0, 320, 128, canvas.viewport
  )
  maxsizewindow = ControlWindow.new(0, 416, 320, 32 * 3)
  maxsizewindow.addSlider(_INTL("Total Animations:"), 1, 2000, newanimations.length)
  maxsizewindow.addButton(_INTL("Resize Animation List"))
  maxsizewindow.opacity = 224
  maxsizewindow.viewport = canvas.viewport
  loop do
    Graphics.update
    Input.update
    cmdwin.update
    maxsizewindow.update
    helpwindow.update
    if Input.trigger?(Input::C) && animations.length > 0
      cmd2 = pbShowCommands(helpwindow, [
                                     _INTL("Load Animation"),
                                     _INTL("Rename"),
                                     _INTL("Delete")
                                   ], -1)
      if cmd2 == 0 # Load Animation
        canvas.loadAnimation(hassearchterm[cmdwin.index][1])
        animwin.animbitmap = canvas.animbitmap
        animations.selected = hassearchterm[cmdwin.index][0]

        break
      elsif cmd2 == 1 # Rename
        pbAnimName(hassearchterm[cmdwin.index][1], cmdwin)
        cmdwin.refresh
      elsif cmd2 == 2 # Delete
        if pbConfirmMessage(_INTL("Are you sure you want to delete this animation?"))
          hassearchterm[cmdwin.index][1] = PBAnimation.new
          cmdwin.commands[cmdwin.index] = _INTL("{1} {2}", cmdwin.index, hassearchterm[cmdwin.index][1].name)
          cmdwin.refresh
        end
      end
    end
    break if Input.trigger?(Input::B)
  end
  helpwindow.dispose
  maxsizewindow.dispose
  cmdwin.dispose
  window.dispose
  return
end

PluginManager.register({
  :name => "Move Animations",
  :credits => "Pokemon Reborn Team"
})
