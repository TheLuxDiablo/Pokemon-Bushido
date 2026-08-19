#===============================================================================
# Bushido Event Exporter
# Pokemon Bushido / Essentials v18.1
#
# Backend only.
# Reads RMXP map/event data and exports human-readable .txt files.
#===============================================================================

module BushidoEventExporter
  EXPORT_FOLDER = "EventExports"

  #=============================================================================
  # Event command names
  #=============================================================================

  EVENT_COMMAND_NAMES = {
    0   => "End",

    101 => "Show Text",
    102 => "Show Choices",
    103 => "Input Number",
    104 => "Change Text Options",
    105 => "Button Input Processing",
    106 => "Wait",
    108 => "Comment",

    111 => "Conditional Branch",
    112 => "Loop",
    113 => "Break Loop",
    115 => "Exit Event Processing",
    116 => "Erase Event",
    117 => "Call Common Event",
    118 => "Label",
    119 => "Jump to Label",

    121 => "Control Switches",
    122 => "Control Variables",
    123 => "Control Self Switch",
    124 => "Control Timer",
    125 => "Change Gold",
    126 => "Change Items",
    127 => "Change Weapons",
    128 => "Change Armor",
    129 => "Change Party Member",

    131 => "Change Windowskin",
    132 => "Change Battle BGM",
    133 => "Change Battle End ME",
    134 => "Change Save Access",
    135 => "Change Menu Access",
    136 => "Change Encounter",

    201 => "Transfer Player",
    202 => "Set Event Location",
    203 => "Scroll Map",
    204 => "Change Map Settings",

    207 => "Show Animation",
    208 => "Change Transparency",
    209 => "Set Move Route",
    210 => "Wait for Move Completion",

    221 => "Prepare for Transition",
    222 => "Execute Transition",
    223 => "Change Screen Color Tone",
    224 => "Screen Flash",
    225 => "Screen Shake",

    231 => "Show Picture",
    232 => "Move Picture",
    233 => "Rotate Picture",
    234 => "Change Picture Color Tone",
    235 => "Erase Picture",
    236 => "Set Weather Effects",

    241 => "Play BGM",
    242 => "Fade Out BGM",
    245 => "Play BGS",
    246 => "Fade Out BGS",
    247 => "Memorize BGM/BGS",
    248 => "Restore BGM/BGS",
    249 => "Play ME",
    250 => "Play SE",
    251 => "Stop SE",

    301 => "Battle Processing",
    302 => "Shop Processing",
    303 => "Name Input Processing",

    311 => "Change Actor HP",
    312 => "Change Actor SP",
    313 => "Change Actor State",
    314 => "Recover All",
    315 => "Change EXP",
    316 => "Change Level",
    317 => "Change Parameters",
    318 => "Change Skills",
    319 => "Change Equipment",
    320 => "Change Actor Name",
    321 => "Change Actor Class",
    322 => "Change Actor Graphic",

    331 => "Change Enemy HP",
    332 => "Change Enemy SP",
    333 => "Change Enemy State",
    334 => "Enemy Recover All",
    335 => "Enemy Appearance",
    336 => "Enemy Transform",
    337 => "Show Battle Animation",
    339 => "Force Action",
    340 => "Abort Battle",

    351 => "Call Menu Screen",
    352 => "Call Save Screen",
    353 => "Game Over",
    354 => "Return to Title Screen",
    355 => "Script",

    401 => "Text",
    402 => "When Choice",
    403 => "When Cancel",
    404 => "Choice End",

    408 => "Comment",

    411 => "Else",
    412 => "Branch End",
    413 => "Repeat Above",

    509 => "Move Route Command",

    601 => "If Win",
    602 => "If Escape",
    603 => "If Lose",
    604 => "Battle Branch End",

    605 => "Shop Item",

    655 => "Script"
  }


  #=============================================================================
  # Data loading
  #=============================================================================

  def self.load_map(map_id)
    filename = sprintf("Data/Map%03d.rxdata", map_id)

    unless FileTest.exist?(filename)
      raise "Map file not found: #{filename}"
    end

    return load_data(filename)
  end


  def self.load_map_infos
    filename = "Data/MapInfos.rxdata"

    unless FileTest.exist?(filename)
      raise "MapInfos.rxdata not found."
    end

    return load_data(filename)
  end


  def self.get_map_name(map_id)
    infos = load_map_infos

    if infos && infos[map_id]
      return infos[map_id].name
    end

    return sprintf("Map%03d", map_id)
  end


  def self.get_event(map_id, event_id)
    map = load_map(map_id)

    unless map.events
      raise "Map #{map_id} contains no event data."
    end

    event = map.events[event_id]

    unless event
      raise "Event #{event_id} does not exist on map #{map_id}."
    end

    return event
  end


  #=============================================================================
  # File helpers
  #=============================================================================

  def self.ensure_export_folder
    unless FileTest.directory?(EXPORT_FOLDER)
      Dir.mkdir(EXPORT_FOLDER)
    end
  end


  def self.sanitize_filename(name)
    name = name.to_s.strip
    name = "Unnamed" if name.empty?

    name = name.gsub(/[\\\/:\*\?"<>\|]/, "_")
    name = name.gsub(/\s+/, "_")

    return name
  end


  #=============================================================================
  # Naming helpers
  #=============================================================================

  def self.switch_name(id)
    begin
      name = $data_system.switches[id]

      if name && name != ""
        return sprintf("%03d %s", id, name)
      end
    rescue
    end

    return "Switch #{id}"
  end


  def self.variable_name(id)
    begin
      name = $data_system.variables[id]

      if name && name != ""
        return sprintf("%03d %s", id, name)
      end
    rescue
    end

    return "Variable #{id}"
  end


  def self.common_event_name(id)
    begin
      common = $data_common_events[id]

      if common && common.name && common.name != ""
        return common.name
      end
    rescue
    end

    return "Common Event #{id}"
  end


  def self.trigger_name(value)
    case value
    when 0
      return "Action Button"
    when 1
      return "Player Touch"
    when 2
      return "Event Touch"
    when 3
      return "Autorun"
    when 4
      return "Parallel Process"
    end

    return value.to_s
  end


  def self.move_type_name(value)
    case value
    when 0
      return "Fixed"
    when 1
      return "Random"
    when 2
      return "Approach"
    when 3
      return "Custom"
    end

    return value.to_s
  end


  def self.direction_name(value)
    case value
    when 2
      return "Down"
    when 4
      return "Left"
    when 6
      return "Right"
    when 8
      return "Up"
    end

    return value.to_s
  end


  def self.blend_name(value)
    case value
    when 0
      return "Normal"
    when 1
      return "Add"
    when 2
      return "Subtract"
    end

    return value.to_s
  end


  #=============================================================================
  # Command formatting
  #=============================================================================

  def self.format_conditional_branch(params)
    return "Unknown condition" if !params || params.empty?

    type = params[0]

    case type
    when 0
      id = params[1]
      state = params[2] == 0 ? "ON" : "OFF"
      return "#{switch_name(id)} is #{state}"

    when 1
      variable_id = params[1]
      operand_type = params[2]
      operand = params[3]
      operator = params[4]

      operators = [
        "==",
        ">=",
        "<=",
        ">",
        "<",
        "!="
      ]

      operator_text = operators[operator] || "?"

      right_side =
        if operand_type == 0
          operand.to_s
        else
          variable_name(operand)
        end

      return "#{variable_name(variable_id)} #{operator_text} #{right_side}"

    when 2
      letter = params[1]
      state = params[2] == 0 ? "ON" : "OFF"

      return "Self Switch #{letter} is #{state}"

    when 3
      seconds = params[1]
      comparison = params[2] == 0 ? ">=" : "<="

      return "Timer #{comparison} #{seconds} seconds"

    when 6
      character_id = params[1]
      direction = params[2]
      return "Character #{character_id} facing #{direction_name(direction)}"

    when 7
      amount = params[1]
      comparison = params[2]

      operators = [">=", "<="]

      return "Gold #{operators[comparison] || '?'} #{amount}"

    when 12
      return "Script: #{params[1]}"
    end

    return "Condition #{params.inspect}"
  end


  def self.format_switch_command(params)
    return params.inspect if !params || params.length < 3

    first_id = params[0]
    last_id  = params[1]
    state    = params[2] == 0 ? "ON" : "OFF"

    if first_id == last_id
      return "#{switch_name(first_id)} = #{state}"
    end

    return "Switches #{first_id}..#{last_id} = #{state}"
  end


  def self.format_variable_command(params)
    return params.inspect if !params || params.length < 4

    first_id     = params[0]
    last_id      = params[1]
    operation    = params[2]
    operand_type = params[3]

    operations = [
      "=",
      "+=",
      "-=",
      "*=",
      "/=",
      "%="
    ]

    operation_text = operations[operation] || "?"

    operand_text = "?"

    case operand_type
    when 0
      operand_text = params[4].to_s

    when 1
      operand_text = variable_name(params[4])

    when 2
      operand_text = "Random #{params[4]}..#{params[5]}"

    when 7
      operand_text = "Game Data #{params[4..-1].inspect}"

    else
      operand_text = params[4..-1].inspect
    end

    variable_text =
      if first_id == last_id
        variable_name(first_id)
      else
        "Variables #{first_id}..#{last_id}"
      end

    return "#{variable_text} #{operation_text} #{operand_text}"
  end


  def self.format_audio(audio)
    return "None" if !audio

    begin
      return sprintf(
        "%s (Volume %d, Pitch %d)",
        audio.name,
        audio.volume,
        audio.pitch
      )
    rescue
      return audio.inspect
    end
  end


  def self.format_transfer(params)
    return params.inspect if !params || params.length < 6

    direct = params[0]

    if direct == 0
      map_id = params[1]
      x      = params[2]
      y      = params[3]

      return sprintf(
        "%03d %s (%d,%d)",
        map_id,
        get_map_name(map_id),
        x,
        y
      )
    end

    return "Variable-based transfer #{params.inspect}"
  end


  def self.format_event_command(command, number=nil)
    code   = command.code
    params = command.parameters || []

    indent = "  " * command.indent

    prefix = number ? sprintf("[%03d] ", number) : ""

    case code
    when 0
      return nil

    #-------------------------------------------------------------------------
    # Dialogue
    #-------------------------------------------------------------------------

    when 101
      return "#{indent}#{prefix}◆ Text: #{params[0]}"

    when 401
      return "#{indent}      #{params[0]}"

    #-------------------------------------------------------------------------
    # Choices
    #-------------------------------------------------------------------------

    when 102
      choices = params[0] || []

      return "#{indent}#{prefix}◆ Show Choices: #{choices.join(' / ')}"

    when 402
      return "#{indent}#{prefix}◆ When [#{params[1]}]"

    when 403
      return "#{indent}#{prefix}◆ When Cancel"

    when 404
      return "#{indent}#{prefix}◆ Choice End"

    #-------------------------------------------------------------------------
    # Branches
    #-------------------------------------------------------------------------

    when 111
      return "#{indent}#{prefix}◆ Conditional Branch: " +
             format_conditional_branch(params)

    when 411
      return "#{indent}#{prefix}◆ Else"

    when 412
      return "#{indent}#{prefix}◆ Branch End"

    #-------------------------------------------------------------------------
    # Loops
    #-------------------------------------------------------------------------

    when 112
      return "#{indent}#{prefix}◆ Loop"

    when 113
      return "#{indent}#{prefix}◆ Break Loop"

    when 413
      return "#{indent}#{prefix}◆ Repeat Above"

    #-------------------------------------------------------------------------
    # Event flow
    #-------------------------------------------------------------------------

    when 115
      return "#{indent}#{prefix}◆ Exit Event Processing"

    when 116
      return "#{indent}#{prefix}◆ Erase Event"

    when 117
      id = params[0]

      return sprintf(
        "%s%s◆ Call Common Event: %03d - %s",
        indent,
        prefix,
        id,
        common_event_name(id)
      )

    when 118
      return "#{indent}#{prefix}◆ Label: #{params[0]}"

    when 119
      return "#{indent}#{prefix}◆ Jump to Label: #{params[0]}"

    #-------------------------------------------------------------------------
    # Switches / variables
    #-------------------------------------------------------------------------

    when 121
      return "#{indent}#{prefix}◆ Control Switches: " +
             format_switch_command(params)

    when 122
      return "#{indent}#{prefix}◆ Control Variables: " +
             format_variable_command(params)

    when 123
      state = params[1] == 0 ? "ON" : "OFF"

      return "#{indent}#{prefix}◆ Control Self Switch: " +
             "#{params[0]} = #{state}"

    #-------------------------------------------------------------------------
    # Timing
    #-------------------------------------------------------------------------

    when 106
      return "#{indent}#{prefix}◆ Wait: #{params[0]} frame(s)"

    #-------------------------------------------------------------------------
    # Map
    #-------------------------------------------------------------------------

    when 201
      return "#{indent}#{prefix}◆ Transfer Player: #{format_transfer(params)}"

    when 202
      return "#{indent}#{prefix}◆ Set Event Location: #{params.inspect}"

    when 203
      return "#{indent}#{prefix}◆ Scroll Map: #{params.inspect}"

    when 207
      return "#{indent}#{prefix}◆ Show Animation: #{params.inspect}"

    when 208
      return "#{indent}#{prefix}◆ Change Transparency: #{params.inspect}"

    when 209
      return "#{indent}#{prefix}◆ Set Move Route: #{params.inspect}"

    when 210
      return "#{indent}#{prefix}◆ Wait for Move Completion"

    #-------------------------------------------------------------------------
    # Screen
    #-------------------------------------------------------------------------

    when 221
      return "#{indent}#{prefix}◆ Prepare for Transition"

    when 222
      return "#{indent}#{prefix}◆ Execute Transition: #{params.inspect}"

    when 223
      return "#{indent}#{prefix}◆ Change Screen Color Tone: #{params.inspect}"

    when 224
      return "#{indent}#{prefix}◆ Screen Flash: #{params.inspect}"

    when 225
      return "#{indent}#{prefix}◆ Screen Shake: #{params.inspect}"

    #-------------------------------------------------------------------------
    # Audio
    #-------------------------------------------------------------------------

    when 241
      return "#{indent}#{prefix}◆ Play BGM: #{format_audio(params[0])}"

    when 242
      return "#{indent}#{prefix}◆ Fade Out BGM: #{params.inspect}"

    when 245
      return "#{indent}#{prefix}◆ Play BGS: #{format_audio(params[0])}"

    when 246
      return "#{indent}#{prefix}◆ Fade Out BGS: #{params.inspect}"

    when 249
      return "#{indent}#{prefix}◆ Play ME: #{format_audio(params[0])}"

    when 250
      return "#{indent}#{prefix}◆ Play SE: #{format_audio(params[0])}"

    when 251
      return "#{indent}#{prefix}◆ Stop SE"

    #-------------------------------------------------------------------------
    # Comments
    #-------------------------------------------------------------------------

    when 108
      return "#{indent}#{prefix}◆ Comment: #{params[0]}"

    when 408
      return "#{indent}      #{params[0]}"

    #-------------------------------------------------------------------------
    # Scripts
    #-------------------------------------------------------------------------

    when 355
      return "#{indent}#{prefix}◆ Script: #{params[0]}"

    when 655
      return "#{indent}      #{params[0]}"

    #-------------------------------------------------------------------------
    # Standard commands
    #-------------------------------------------------------------------------

    when 351
      return "#{indent}#{prefix}◆ Call Menu Screen"

    when 352
      return "#{indent}#{prefix}◆ Call Save Screen"

    when 353
      return "#{indent}#{prefix}◆ Game Over"

    when 354
      return "#{indent}#{prefix}◆ Return to Title Screen"
    end

    name = EVENT_COMMAND_NAMES[code]

    if name
      if params.empty?
        return "#{indent}#{prefix}◆ #{name}"
      end

      return "#{indent}#{prefix}◆ #{name}: #{params.inspect}"
    end

    return sprintf(
      "%s%s◆ Unknown Command %d: %s",
      indent,
      prefix,
      code,
      params.inspect
    )
  end


  #=============================================================================
  # Event export
  #=============================================================================

  def self.build_event_text(map_id, event_id)
    event    = get_event(map_id, event_id)
    map_name = get_map_name(map_id)

    output = []

    output << "============================================================"
    output << "BUSHIDO EVENT EXPORT"
    output << "============================================================"
    output << ""
    output << "Map: #{map_name}"
    output << "Map ID: #{map_id}"
    output << ""
    output << "Event: #{event.name}"
    output << "Event ID: #{event.id}"
    output << "Position: X=#{event.x}, Y=#{event.y}"
    output << "Pages: #{event.pages ? event.pages.length : 0}"
    output << ""

    if !event.pages || event.pages.empty?
      output << "No event pages found."
      return output.join("\n")
    end

    event.pages.each_with_index do |page, index|
      output << "============================================================"
      output << "PAGE #{index + 1}"
      output << "============================================================"
      output << ""

      #-------------------------------------------------------------------------
      # Conditions
      #-------------------------------------------------------------------------

      output << "CONDITIONS"
      output << "------------------------------------------------------------"

      condition = page.condition

      if condition
        if condition.switch1_valid
          output << "Switch 1: #{switch_name(condition.switch1_id)}"
        else
          output << "Switch 1: None"
        end

        if condition.switch2_valid
          output << "Switch 2: #{switch_name(condition.switch2_id)}"
        else
          output << "Switch 2: None"
        end

        if condition.variable_valid
          output << "Variable: #{variable_name(condition.variable_id)} >= " +
                    "#{condition.variable_value}"
        else
          output << "Variable: None"
        end

        if condition.self_switch_valid
          output << "Self Switch: #{condition.self_switch_ch}"
        else
          output << "Self Switch: None"
        end
      else
        output << "No conditions."
      end

      output << ""

      #-------------------------------------------------------------------------
      # Graphic
      #-------------------------------------------------------------------------

      output << "GRAPHIC"
      output << "------------------------------------------------------------"

      graphic = page.graphic

      if graphic
        output << "Tile ID: #{graphic.tile_id}"
        output << "Character: #{graphic.character_name}"
        output << "Hue: #{graphic.character_hue}"
        output << "Direction: #{direction_name(graphic.direction)}"
        output << "Pattern: #{graphic.pattern}"
        output << "Opacity: #{graphic.opacity}"
        output << "Blend Type: #{blend_name(graphic.blend_type)}"
      else
        output << "No graphic."
      end

      output << ""

      #-------------------------------------------------------------------------
      # Settings
      #-------------------------------------------------------------------------

      output << "SETTINGS"
      output << "------------------------------------------------------------"

      output << "Trigger: #{trigger_name(page.trigger)}"
      output << "Move Type: #{move_type_name(page.move_type)}"
      output << "Move Speed: #{page.move_speed}"
      output << "Move Frequency: #{page.move_frequency}"
      output << "Walk Animation: #{page.walk_anime}"
      output << "Step Animation: #{page.step_anime}"
      output << "Direction Fix: #{page.direction_fix}"
      output << "Through: #{page.through}"
      output << "Always On Top: #{page.always_on_top}"
      output << ""

      #-------------------------------------------------------------------------
      # Commands
      #-------------------------------------------------------------------------

      output << "COMMANDS"
      output << "------------------------------------------------------------"

      if page.list && !page.list.empty?
        page.list.each_with_index do |command, command_index|
          line = format_event_command(
            command,
            command_index + 1
          )

          output << line if line
        end
      else
        output << "No commands."
      end

      output << ""
    end

    return output.join("\n")
  end


  def self.export_event(map_id, event_id)
    ensure_export_folder

    event    = get_event(map_id, event_id)
    map_name = get_map_name(map_id)

    text = build_event_text(map_id, event_id)

    filename = sprintf(
      "%s/%03d_%s_Event%03d_%s.txt",
      EXPORT_FOLDER,
      map_id,
      sanitize_filename(map_name),
      event_id,
      sanitize_filename(event.name)
    )

    File.open(filename, "wb") do |file|
      file.write(text)
    end

    return filename
  end


  def self.export_map(map_id)
    ensure_export_folder

    map      = load_map(map_id)
    map_name = get_map_name(map_id)

    output = []

    output << "============================================================"
    output << "BUSHIDO MAP EVENT EXPORT"
    output << "============================================================"
    output << ""
    output << "Map: #{map_name}"
    output << "Map ID: #{map_id}"
    output << ""

    if !map.events || map.events.empty?
      output << "No events found."
    else
      map.events.keys.sort.each do |event_id|
        output << build_event_text(map_id, event_id)
        output << ""
        output << ""
      end
    end

    filename = sprintf(
      "%s/%03d_%s_ALL_EVENTS.txt",
      EXPORT_FOLDER,
      map_id,
      sanitize_filename(map_name)
    )

    File.open(filename, "wb") do |file|
      file.write(output.join("\n"))
    end

    return filename
  end
end