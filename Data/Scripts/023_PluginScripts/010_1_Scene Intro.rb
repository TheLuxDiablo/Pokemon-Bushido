#===============================================================================
#  New animated and modular Title Screen for Pokemon Essentials
#    by Luka S.J.
#
#  ONLY FOR Essentials v17.x and v18.x
# ----------------
#  Adds new visual styles to the Pokemon Essentials title screen, and animates
#  depending on the styles selected.
#
#  A lot of time and effort went into making this an extensive and comprehensive
#  resource. So please be kind enough to give credit when using it.
#===============================================================================
class Scene_Intro

  def main
    Graphics.transition(0)
    # Loads up a species cry for the title screen
    species = MTS_SPECIES
    species = species.upcase.to_sym if species.is_a?(String)
    species = getConst(PBSpecies, MTS_SPECIES) if !MTS_SPECIES.nil? && !MTS_SPECIES.is_a?(Numeric)
    @cry = pbCryFile(species, MTS_SPECIES_FORM) if !species.nil?
    # Cycles through the intro pictures
    @skip = false
    self.cyclePics(@pics)
    # loads the modular title screen
    @screen = ModularTitleScreen.new
    # Plays defined title screen BGM
    @screen.playBGM
    # Plays the title screen intro (is skippable)
    @screen.intro
    # Creates/updates the main title screen loop
    self.update
    Graphics.freeze
  end

  # update for the title screen
  def update
    ret = 0
    loop do
      @screen.update
      Graphics.update
      Input.update
      if Input.press?(Input::DOWN) && Input.press?(Input::B) && Input.press?(Input::CTRL)
        ret = 1
        break
      end
      if Input.trigger?(Input::C) || (defined?($mouse) && $mouse.leftClick?)
        ret = 2
        break
      end
    end
    case ret
    when 1
      closeTitleDelete
    when 2
      closeTitle
    end
  end

  def closeTitle
    # Play Pokemon cry
    pbSEPlay(@cry,100,100) if @cry
    # Fade out
    pbBGMStop(1.0)
    # disposes current title screen
    disposeTitle
    # initializes load screen
    sscene = PokemonLoad_Scene.new
    sscreen = PokemonLoadScreen.new(sscene)
    sscreen.pbStartLoadScreen
  end

  def closeTitleDelete
    pbBGMStop(1.0)
    # disposes current title screen
    disposeTitle
    # initializes delete screen
    sscene = PokemonLoad_Scene.new
    sscreen = PokemonLoadScreen.new(sscene)
    sscreen.pbStartLoadScreen
  end

  def cyclePics(pics)
    sprite = Sprite.new
    sprite.opacity = 0
    for i in 0...pics.length
      bitmap = pbBitmap("Graphics/Titles/#{pics[i]}")
      sprite.bitmap = bitmap
      15.times do
        sprite.opacity += 17
        pbWait(1)
      end
      wait(90)
      15.times do
        sprite.opacity -= 17
        pbWait(1)
      end
    end
    sprite.dispose
  end

  def disposeTitle
    @screen.dispose
  end

  def wait(frames, advance = true)
    return false if @skip
    frames.times do
      Graphics.update
      Input.update
      @skip = true if Input.trigger?(Input::C)
    end
    return true
  end
end
#===============================================================================
