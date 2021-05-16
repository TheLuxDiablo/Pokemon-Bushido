#==============================================================================
# * Scene_Controls
#------------------------------------------------------------------------------
# Shows a help screen listing the keyboard controls.
# Display with:
#      pbEventScreen(ButtonEventScene)
#==============================================================================
class ButtonEventScene < EventScene
  def initialize(viewport = nil)
    super
    Graphics.freeze
    @current_screen = 1
    @labels = []
    addImage(0, 0, "Graphics/Pictures/Controls/help_bg")
    @label_screens = []
    @keys = []
    @key_screens = []

    addImageForScreen(1, 0, 0, "Graphics/Pictures/Controls/help_bg_1")
    addImageForScreen(1, 16, 154, "Graphics/Pictures/Controls/help_arrows")
    addLabelForScreen(1, 138, 100, 342, _INTL("Use the Arrow keys to move the main character."))
    addLabelForScreen(1, 138, 188, 342, _INTL("You can also use the Arrow keys to select entries and navigate menus."))

    addImageForScreen(2, 0, 0, "Graphics/Pictures/Controls/help_bg")
    addImageForScreen(2, 36, 90, "Graphics/Pictures/Controls/help_c")
    addImageForScreen(2, 36, 252, "Graphics/Pictures/Controls/help_b")
    addLabelForScreen(2, 138, 64, 342, _INTL("Used to confirm a choice, interact with people and things, and move through text.\n(Default: C)"))
    if $PokemonSystem && $PokemonSystem.controlScheme == 1
      addLabelForScreen(2, 138, 222, 342, _INTL("Used to exit or cancel a choice. While moving around, hold to move at a different speed. (Default: X)"))
    else
      addLabelForScreen(2, 138, 222, 342, _INTL("Used to exit, cancel a choice, and cancel a mode. Also used to open the Pause Menu. (Default: X)"))
    end

    addImageForScreen(3, 0, 0, "Graphics/Pictures/Controls/help_bg")
    addImageForScreen(3, 36, 90, "Graphics/Pictures/Controls/help_a")
    addImageForScreen(3, 36, 252, "Graphics/Pictures/Controls/help_x")
    if $PokemonSystem && $PokemonSystem.controlScheme == 1
      addLabelForScreen(3, 138, 64, 342, _INTL("Has various functions depending on context. Opens the pause menu, when in the overworld. (Default: Z)"))
    else
      addLabelForScreen(3, 138, 64, 342, _INTL("Has various functions depending on context. While moving around, hold to move at a different speed. (Default: Z)"))
    end
    addLabelForScreen(3, 138, 222, 342, _INTL("Press to open the Ready Menu, where registered items and can be used. (Default: A)"))


    addImageForScreen(4, 0, 0, "Graphics/Pictures/Controls/help_bg")
    addImageForScreen(4, 20, 90, "Graphics/Pictures/Controls/help_yz")
    addImageForScreen(4, 36, 252, "Graphics/Pictures/Controls/help_l")
    addLabelForScreen(4, 138, 64, 342, _INTL("Use these keys to quickly navigate through long lists like the Bag. (Default: S , D)"))
    addLabelForScreen(4, 138, 222, 342, _INTL("Save your current progress without opening the menu. (Default: Q)"))

    addImageForScreen(5, 0, 0, "Graphics/Pictures/Controls/help_bg")
    addImageForScreen(5, 36, 90, "Graphics/Pictures/Controls/help_f1")
    addImageForScreen(5, 36, 252, "Graphics/Pictures/Controls/help_f8")
    addLabelForScreen(5, 138, 64, 342, _INTL("Opens the Key Bindings window, where you can choose which keyboard keys to use for each control."))
    addLabelForScreen(5, 138, 222, 342, _INTL("Take a screenshot. It is put in the same folder as where the game was downloaded."))

    set_up_screen(@current_screen)
    Graphics.transition(20)
    # Go to next screen when user presses USE
    onCTrigger.set(method(:pbOnScreenEnd))
  end

  def addLabelForScreen(number, x, y, width, text)
    @labels.push(addLabel(x, y, width, text))
    @label_screens.push(number)
    @picturesprites[@picturesprites.length - 1].opacity = 0
  end

  def addImageForScreen(number, x, y, filename)
    @keys.push(addImage(x, y, filename))
    @key_screens.push(number)
    @picturesprites[@picturesprites.length - 1].opacity = 0
  end

  def set_up_screen(number)
    @label_screens.each_with_index do |screen, i|
      @labels[i].moveOpacity((screen == number) ? 10 : 0, 10, (screen == number) ? 255 : 0)
    end
    @key_screens.each_with_index do |screen, i|
      @keys[i].moveOpacity((screen == number) ? 10 : 0, 10, (screen == number) ? 255 : 0)
    end
    pictureWait   # Update event scene with the changes
  end

  def pbOnScreenEnd(scene, *args)
    last_screen = [@label_screens.max, @key_screens.max].max
    if @current_screen >= last_screen
      # End scene
      Graphics.freeze
      Graphics.transition(20, "fadetoblack")
      scene.dispose
      pbWait(Graphics.frame_rate/2)
      System.show_settings if pbConfirmMessage("Would you like to rebind the controls?")
    else
      # Next screen
      @current_screen += 1
      onCTrigger.clear
      set_up_screen(@current_screen)
      onCTrigger.set(method(:pbOnScreenEnd))
    end
  end
end
