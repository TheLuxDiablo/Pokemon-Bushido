class PokemonSystem
  attr_accessor :old_save_restored
end

def old_save_restoration
  return false if $PokemonSystem.old_save_restored
  return false if !Randomizer.rules.empty?
  return false if !Nuzlocke.rules.empty?
  save_file = File.join(RTP.getLegacySaveFolder, "Game_old.rxdata")
  return false if !File.file?(save_file)
  trainer = nil
  storage = nil
  File.open(save_file) { |f|
    trainer = Marshal.load(f)
    Marshal.load(f)
    Marshal.load(f)
    Marshal.load(f)   # PokemonSystem already loaded
    Marshal.load(f)   # Current map id no longer needed
    Marshal.load(f)
    Marshal.load(f)
    Marshal.load(f)
    Marshal.load(f)
    Marshal.load(f)
    Marshal.load(f)
    Marshal.load(f)
    Marshal.load(f)
    Marshal.load(f)
    storage = Marshal.load(f)
  }
  return false if !trainer.is_a?(PokeBattle_Trainer) || !storage.is_a?(PokemonStorage)
  trainer.party.each do |pkmn|
    next if !pkmn || pkmn.shadowPokemon?
    next if Randomizer::EXCLUSIONS_SPECIES.include?(getID(PBSpecies, pkmn.species)) && !pkmn.shiny?
    $Trainer.setSeen(pkmn.species)
    $Trainer.setOwned(pkmn.species)
    pbSeenForm(pkmn)
    pkmn.level = 5
    pkmn.resetMoves
    pkmn.calcStats
    $PokemonStorage.pbStoreCaught(pkmn)
  end
  (0...storage.maxBoxes).each do |i|
    storage.maxPokemon(i).times do |j|
      pkmn = storage[i][j]
      next if !pkmn || pkmn.shadowPokemon?
      next if Randomizer::EXCLUSIONS_SPECIES.any? { |s| getID(PBSpecies, s) == pkmn.species } && !pkmn.shiny?
      $Trainer.setSeen(pkmn.species)
      $Trainer.setOwned(pkmn.species)
      pbSeenForm(pkmn)
      pkmn.level = 5
      pkmn.resetMoves
      pkmn.calcStats
      $PokemonStorage.pbStoreCaught(pkmn)
    end
  end
  $PokemonSystem.old_save_restored = true
  $game_variables[1] = trainer.name
  return true
end

class ControlConfig

end
