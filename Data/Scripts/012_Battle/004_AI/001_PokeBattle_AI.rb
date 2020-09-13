# AI skill levels:
#     0:     Wild Pokémon
#     1-31:  Basic trainer (young/inexperienced)
#     32-47: Some skill
#     48-99: High skill
#     100+:  Best trainers (Gym Leaders, Elite Four, Champion)
# NOTE: A trainer's skill value can range from 0-255, but by default only four
#       distinct skill levels exist. The skill value is typically the same as
#       the trainer's base money value.
module PBTrainerAI
  # Minimum skill level to be in each AI category.
  def self.minimumSkill; return 1;   end
  def self.mediumSkill;  return 32;  end
  def self.highSkill;    return 48;  end
  def self.bestSkill;    return 100; end
end



class PokeBattle_AI
  attr_accessor :scores
  attr_accessor :targets
  attr_accessor :myChoices
  attr_accessor :aiMoveMemory

  def initialize(battle)
    @battle = battle
    @aiMoveMemory = [[],[],[[],[],[],[],[],[],[],[],[],[],[],[]]]
  end

  def pbAIRandom(x); return rand(x); end

=begin
  # Essentials method
  def pbStdDev(choices)
    sum = 0
    n   = 0
    choices.each do |c|
      sum += c[1]
      n   += 1
    end
    return 0 if n<2
    mean = sum.to_f/n.to_f
    varianceTimesN = 0
    choices.each do |c|
      next if c[1]<=0
      deviation = c[1].to_f-mean
      varianceTimesN += deviation*deviation
    end
    # Using population standard deviation
    # [(n-1) makes it a sample std dev, would be 0 with only 1 sample]
    return Math.sqrt(varianceTimesN/n)
  end
=end

  # Reborn method (the difference is that each element in "choices" is an array
  # in Essentials but just a number in Reborn)
  def pbStdDev(choices)
    sum = 0
    n   = 0
    choices.each do |c|
      sum += c
      n += 1
    end
    return 0 if n<2
    mean = sum.to_f/n.to_f
    varianceTimesN = 0
    for i in 0...choices.length
      next if choices[i]<=0
      deviation = choices[i].to_f-mean
      varianceTimesN += deviation*deviation
    end
    # Using population standard deviation
    # [(n-1) makes it a sample std dev, would be 0 with only 1 sample]
    return Math.sqrt(varianceTimesN/n)
  end

  #=============================================================================
  # Decide whether the opponent should Mega Evolve their Pokémon
  #=============================================================================
  def pbEnemyShouldMegaEvolve?(idxBattler)
    battler = @battle.battlers[idxBattler]
    if @battle.pbCanMegaEvolve?(idxBattler)   # Simple "always should if possible"
      PBDebug.log("[AI] #{battler.pbThis} (#{idxBattler}) will Mega Evolve")
      return true
    end
    return false
  end

  #=============================================================================
  # Decide whether the opponent should Ultra Burst their Pokémon.
  #=============================================================================
  def pbEnemyShouldUltraBurst?(idxBattler)
    battler = @battle.battlers[idxBattler]
    if @battle.pbCanUltraBurst?(idxBattler)   # Simple "always should if possible"
      PBDebug.log("[AI] #{battler.pbThis} (#{idxBattler}) will Ultra Burst")
      return true
    end
    return false
  end

  #=============================================================================
  # Choose an action
  #=============================================================================
=begin
  # Essentials method
  def pbDefaultChooseEnemyCommand(idxBattler)
    return if pbEnemyShouldUseItem?(idxBattler)
    return if pbEnemyShouldWithdraw?(idxBattler)
    return if @battle.pbAutoFightMenu(idxBattler)
    @battle.pbRegisterMegaEvolution(idxBattler) if pbEnemyShouldMegaEvolve?(idxBattler)
    pbChooseMoves(idxBattler)
  end
=end

  # Reborn method
  def pbDefaultChooseEnemyCommand(idxBattler)
    if !@battle.pbCanShowFightMenu?(idxBattler)
      return if pbEnemyShouldUseItem?(idxBattler)
#      return if pbEnemyShouldWithdraw?(idxBattler)   # Old Switching Method
      return if pbShouldSwitch?(idxBattler)
      return if @battle.pbAutoFightMenu(idxBattler)
      @battle.pbAutoChooseMove(idxBattler)
      return
    end
    pbBuildMoveScores(idxBattler)   # Grab the array of scores/targets before doing anything else
    return if pbShouldSwitch?(idxBattler)
#    return if pbEnemyShouldWithdraw?(idxBattler)   # Old Switching Method
    return if pbEnemyShouldUseItem?(idxBattler)
    return if @battle.pbAutoFightMenu(idxBattler)
    @battle.pbRegisterUltraBurst(idxBattler) if pbEnemyShouldUltraBurst?(idxBattler)
    @battle.pbRegisterMegaEvolution(idxBattler) if pbEnemyShouldMegaEvolve?(idxBattler)
    if pbEnemyShouldZMove?(idxBattler)
      return pbChooseEnemyZMove(idxBattler)
    end
    pbChooseMoves(idxBattler)
  end
end
