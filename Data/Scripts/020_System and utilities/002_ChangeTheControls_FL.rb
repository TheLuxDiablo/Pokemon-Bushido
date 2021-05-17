#===============================================================================
# * Set the Controls Screen - by FL (Credits will be apreciated)
#===============================================================================

#===============================================================================
# * Legacy save support. This doesn't do anything now.
#===============================================================================

module Keys
  # Available keys
  CONTROLSLIST = {
    # Mouse buttons
    _INTL("Backspace") => 0x08,
    _INTL("Tab") => 0x09,
    _INTL("Clear") => 0x0C,
    _INTL("Enter") => 0x0D,
    _INTL("Shift") => 0x10,
    _INTL("Ctrl") => 0x11,
    _INTL("Alt") => 0x12,
    _INTL("Pause") => 0x13,
    _INTL("Caps Lock") => 0x14,
    # IME keys
    _INTL("Esc") => 0x1B,
    # More IME keys
    _INTL("Space") => 0x20,
    _INTL("Page Up") => 0x21,
    _INTL("Page Down") => 0x22,
    _INTL("End") => 0x23,
    _INTL("Home") => 0x24,
    _INTL("Left") => 0x25,
    _INTL("Up") => 0x26,
    _INTL("Right") => 0x27,
    _INTL("Down") => 0x28,
    _INTL("Select") => 0x29,
    _INTL("Print") => 0x2A,
    _INTL("Execute") => 0x2B,
    _INTL("Print Screen") => 0x2C,
    _INTL("Insert") => 0x2D,
    _INTL("Delete") => 0x2E,
    _INTL("Help") => 0x2F,
    _INTL("0") => 0x30,
    _INTL("1") => 0x31,
    _INTL("2") => 0x32,
    _INTL("3") => 0x33,
    _INTL("4") => 0x34,
    _INTL("5") => 0x35,
    _INTL("6") => 0x36,
    _INTL("7") => 0x37,
    _INTL("8") => 0x38,
    _INTL("9") => 0x39,
    _INTL("A") => 0x41,
    _INTL("B") => 0x42,
    _INTL("C") => 0x43,
    _INTL("D") => 0x44,
    _INTL("E") => 0x45,
    _INTL("F") => 0x46,
    _INTL("G") => 0x47,
    _INTL("H") => 0x48,
    _INTL("I") => 0x49,
    _INTL("J") => 0x4A,
    _INTL("K") => 0x4B,
    _INTL("L") => 0x4C,
    _INTL("M") => 0x4D,
    _INTL("N") => 0x4E,
    _INTL("O") => 0x4F,
    _INTL("P") => 0x50,
    _INTL("Q") => 0x51,
    _INTL("R") => 0x52,
    _INTL("S") => 0x53,
    _INTL("T") => 0x54,
    _INTL("U") => 0x55,
    _INTL("V") => 0x56,
    _INTL("W") => 0x57,
    _INTL("X") => 0x58,
    _INTL("Y") => 0x59,
    _INTL("Z") => 0x5A,
    # Windows keys
    _INTL("Numpad 0") => 0x60,
    _INTL("Numpad 1") => 0x61,
    _INTL("Numpad 2") => 0x62,
    _INTL("Numpad 3") => 0x63,
    _INTL("Numpad 4") => 0x64,
    _INTL("Numpad 5") => 0x65,
    _INTL("Numpad 6") => 0x66,
    _INTL("Numpad 7") => 0x67,
    _INTL("Numpad 8") => 0x68,
    _INTL("Numpad 9") => 0x69,
    _INTL("Multiply") => 0x6A,
    _INTL("Add") => 0x6B,
    _INTL("Separator") => 0x6C,
    _INTL("Subtract") => 0x6D,
    _INTL("Decimal") => 0x6E,
    _INTL("Divide") => 0x6F,
    _INTL("F1") => 0x70,
    _INTL("F2") => 0x71,
    _INTL("F3") => 0x72,
    _INTL("F4") => 0x73,
    _INTL("F5") => 0x74,
    _INTL("F6") => 0x75,
    _INTL("F7") => 0x76,
    _INTL("F8") => 0x77,
    _INTL("F9") => 0x78,
    _INTL("F10") => 0x79,
    _INTL("F11") => 0x7A,
    _INTL("F12") => 0x7B,
    _INTL("F13") => 0x7C,
    _INTL("F14") => 0x7D,
    _INTL("F15") => 0x7E,
    _INTL("F16") => 0x7F,
    _INTL("F17") => 0x80,
    _INTL("F18") => 0x81,
    _INTL("F19") => 0x82,
    _INTL("F20") => 0x83,
    _INTL("F21") => 0x84,
    _INTL("F22") => 0x85,
    _INTL("F23") => 0x86,
    _INTL("F24") => 0x87,
    _INTL("Num Lock") => 0x90,
    _INTL("Scroll Lock") => 0x91,
    # Multiple position Shift, Ctrl and Menu keys
    _INTL(";:") => 0xBA,
    _INTL("+") => 0xBB,
    _INTL(",") => 0xBC,
    _INTL("-") => 0xBD,
    _INTL(".") => 0xBE,
    _INTL("/?") => 0xBF,
    _INTL("`~") => 0xC0,
    _INTL("{") => 0xDB,
    _INTL("\|") => 0xDC,
    _INTL("}") => 0xDD,
    _INTL("'\"") => 0xDE,
    _INTL("AX") => 0xE1, # Japan only
    _INTL("\|") => 0xE2
    # Disc keys
  }

  # Here you can change the number of keys for each action and the
  # default values
  def self.defaultControls
    return [
      ControlConfig.new(_INTL("Down"),_INTL("Down")),
      ControlConfig.new(_INTL("Left"),_INTL("Left")),
      ControlConfig.new(_INTL("Right"),_INTL("Right")),
      ControlConfig.new(_INTL("Up"),_INTL("Up")),
      ControlConfig.new(_INTL("Action"),_INTL("C")),
      ControlConfig.new(_INTL("Action"),_INTL("Enter")),
      ControlConfig.new(_INTL("Cancel"),_INTL("X")),
      ControlConfig.new(_INTL("Cancel"),_INTL("Esc")),
      ControlConfig.new(_INTL("Run/Sort"),_INTL("Z")),
      ControlConfig.new(_INTL("Scroll down"),_INTL("Page Down")),
      ControlConfig.new(_INTL("Scroll up"),_INTL("Page Up")),
      ControlConfig.new(_INTL("Registered"),_INTL("F")),
      ControlConfig.new(_INTL("Speedup"),_INTL("Alt")),
      ControlConfig.new(_INTL("Quicksave"),_INTL("S"))
    ]
  end

  def self.getKeyName(keyCode)
    ret  = CONTROLSLIST.index(keyCode)
    return ret ? ret : (keyCode==0 ? _INTL("None") : "?")
  end

  def self.getKeyCode(keyName)
    ret  = CONTROLSLIST[keyName]
    raise "The button #{keyName} no longer exists! " if !ret
    return ret
  end

  def self.detectKey
    loop do
      Graphics.update
      Input.update
      for keyCode in CONTROLSLIST.values
        return keyCode if Input.triggerex?(keyCode)
      end
    end
  end
end

class ControlConfig
  attr_reader :controlAction
  attr_accessor :keyCode

  def initialize(controlAction,defaultKey)
    @controlAction = controlAction
    @keyCode = Keys.getKeyCode(defaultKey)
  end

  def keyName
    return Keys.getKeyName(@keyCode)
  end
end
