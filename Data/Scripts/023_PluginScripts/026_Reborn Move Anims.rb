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
