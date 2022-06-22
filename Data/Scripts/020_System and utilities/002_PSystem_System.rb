# Loads data from a file "safely", similar to load_data. If an encrypted archive
# exists, the real file is deleted to ensure that the file is loaded from the
# encrypted archive.
def pbSafeLoad(file)
  if safeExists?("./Game.rgssad") && safeExists?(file)
    File.delete(file) rescue nil
  end
  return load_data(file)
end

def pbChooseLanguage
  commands=[]
  for lang in LANGUAGES
    commands.push(lang[0])
  end
  return pbShowCommands(nil,commands)
end

#############
#############

def pbScreenCapture
  t = pbGetTimeNow
  filestart = t.strftime("[%Y-%m-%d] %H_%M_%S")
  filestart = sprintf("%s.%03d", filestart, (t.to_f - t.to_i) * 1000)   # milliseconds
  capturefile = (sprintf("%s.png", filestart))
  Dir.mkdir("Screenshots") if !safeExists?("Screenshots/")
  Graphics.screenshot("Screenshots/" + capturefile)
  pbSEPlay("Pkmn exp full") if FileTest.audio_exist?("Audio/SE/Pkmn exp full")
end

def pbSetUpSystem
  save_file = RTP.getSaveFileName("Game_0.rxdata")
  Dir.foreach(RTP.getSaveFolder) do |f|
    next if f == "." || f == ".."
    next if File.directory?(RTP.getSaveFileName("#{f}"))
    next if !f[/Game_(\d+).rxdata/i]
    save_file = File.join(RTP.getSaveFileName("#{f}"))
    break
  end
  if safeExists?(save_file)
    trainer       = nil
    framecount    = 0
    game_system   = nil
    pokemonSystem = nil
    havedata = false
    begin
      File.open(save_file) { |f|
        trainer       = Marshal.load(f)
        framecount    = Marshal.load(f)
        game_system   = Marshal.load(f)
        pokemonSystem = Marshal.load(f)
      }
      raise "Corrupted file" if !trainer.is_a?(PokeBattle_Trainer)
      raise "Corrupted file" if !framecount.is_a?(Numeric)
      raise "Corrupted file" if !game_system.is_a?(Game_System)
      raise "Corrupted file" if !pokemonSystem.is_a?(PokemonSystem)
      havedata = true
    rescue
      game_system   = Game_System.new
      pokemonSystem = PokemonSystem.new
    end
  else
    game_system   = Game_System.new
    pokemonSystem = PokemonSystem.new
  end
  if !$INEDITOR
    $game_system   = game_system
    $PokemonSystem = pokemonSystem
    pbSetResizeFactor([$PokemonSystem.screensize,4].min)
  else
    pbSetResizeFactor(1.0)
  end
  # Load constants
  begin
    consts = pbSafeLoad("Data/Constants.rxdata")
    consts = [] if !consts
  rescue
    consts = []
  end
  for script in consts
    next if !script
    eval(Zlib::Inflate.inflate(script[2]),nil,script[1])
  end
  if LANGUAGES.length>=2
    pokemonSystem.language = pbChooseLanguage if !havedata
    pbLoadMessages("Data/"+LANGUAGES[pokemonSystem.language][1])
  end
end

pbSetUpSystem
