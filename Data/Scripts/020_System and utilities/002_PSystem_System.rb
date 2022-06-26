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
  if System.platform[/Windows/]
    old_save_data = File.join(RTP.getLegacySaveFolder, "Game.rxdata")
    keybinds_file = RTP.getSaveFileName("keybindings.mkxp1")
    if safeExists?(old_save_data)
      File.rename(old_save_data, File.join(RTP.getLegacySaveFolder, "Game_old.rxdata"))
#      File.delete(keybinds_file) if safeExists?(keybinds_file)
    end
#    File.copy("Data/keybindings.mkxp1", keybinds_file) if !safeExists?(keybinds_file)
  end
  save_file = RTP.getSaveFileName("Settings.rxdata")
  no_data = true
  if safeExists?(save_file)
    game_system   = nil
    pokemon_system = nil
    File.open(save_file) { |f|
      pokemon_system = Marshal.load(f)
      game_system    = Marshal.load(f)
    }
    no_data = false if game_system.is_a?(Game_System) && pokemon_system.is_a?(PokemonSystem)
  end
  if no_data
    game_system    = Game_System.new
    pokemon_system = PokemonSystem.new
  end
  if !$INEDITOR
    $PokemonSystem = pokemon_system
    $game_system   = game_system
    pbSetResizeFactor([$PokemonSystem.screensize, 4].min)
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
    eval(Zlib::Inflate.inflate(script[2]), nil, script[1])
  end
  if LANGUAGES.length >= 2
    pokemon_system.language = pbChooseLanguage if !havedata
    pbLoadMessages("Data/" + LANGUAGES[pokemon_system.language][1])
  end
end

pbSetUpSystem
