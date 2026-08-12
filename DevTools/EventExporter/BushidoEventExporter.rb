# encoding: UTF-8

# ============================================================
# BUSHIDO EVENT EXPORTER
# Standalone RMXP companion tool
#
# Pass 1 goal:
# - Find the Bushido project root
# - Load an RMXP MapXXX.rxdata file
# - Read its RPG::Event objects
# - Print all event IDs, names, and coordinates
# ============================================================


# ------------------------------------------------------------
# Minimal RGSS compatibility classes
# ------------------------------------------------------------
#
# RPG Maker XP map files contain RGSS-specific objects.
# Ruby needs to know these class names before Marshal.load
# can reconstruct the data.
#
# For this first pass, we don't need to actually manipulate
# map tile data, colors, tones, etc. We just need Marshal.load
# to accept them.
# ------------------------------------------------------------

class Table
  def self._load(data)
    obj = allocate
    obj.instance_variable_set(:@marshal_data, data)
    return obj
  end
end


class Color
  def self._load(data)
    obj = allocate
    obj.instance_variable_set(:@marshal_data, data)
    return obj
  end
end


class Tone
  def self._load(data)
    obj = allocate
    obj.instance_variable_set(:@marshal_data, data)
    return obj
  end
end


# ------------------------------------------------------------
# Minimal RPG Maker XP data classes
# ------------------------------------------------------------

module RPG

  class Map
    attr_accessor :tileset_id
    attr_accessor :width
    attr_accessor :height
    attr_accessor :autoplay_bgm
    attr_accessor :bgm
    attr_accessor :autoplay_bgs
    attr_accessor :bgs
    attr_accessor :encounter_list
    attr_accessor :encounter_step
    attr_accessor :data
    attr_accessor :events
  end


  class Event
    attr_accessor :id
    attr_accessor :name
    attr_accessor :x
    attr_accessor :y
    attr_accessor :pages
  end


  class Event::Page
    attr_accessor :condition
    attr_accessor :graphic
    attr_accessor :move_type
    attr_accessor :move_speed
    attr_accessor :move_frequency
    attr_accessor :move_route
    attr_accessor :walk_anime
    attr_accessor :step_anime
    attr_accessor :direction_fix
    attr_accessor :through
    attr_accessor :always_on_top
    attr_accessor :trigger
    attr_accessor :list
  end


  class Event::Page::Condition
    attr_accessor :switch1_valid
    attr_accessor :switch2_valid
    attr_accessor :variable_valid
    attr_accessor :self_switch_valid

    attr_accessor :switch1_id
    attr_accessor :switch2_id
    attr_accessor :variable_id
    attr_accessor :variable_value
    attr_accessor :self_switch_ch
  end


  class Event::Page::Graphic
    attr_accessor :tile_id
    attr_accessor :character_name
    attr_accessor :character_hue
    attr_accessor :direction
    attr_accessor :pattern
    attr_accessor :opacity
    attr_accessor :blend_type
  end


  class EventCommand
    attr_accessor :code
    attr_accessor :indent
    attr_accessor :parameters
  end


  class MoveRoute
    attr_accessor :repeat
    attr_accessor :skippable
    attr_accessor :list
  end


  class MoveCommand
    attr_accessor :code
    attr_accessor :parameters
  end


  class AudioFile
    attr_accessor :name
    attr_accessor :volume
    attr_accessor :pitch
  end


  class BGM < AudioFile
  end


  class BGS < AudioFile
  end


  class ME < AudioFile
  end


  class SE < AudioFile
  end
end


# ------------------------------------------------------------
# Bushido Event Exporter
# ------------------------------------------------------------

module BushidoEventExporter

  # This script lives at:
  #
  # Pokemon-Bushido/
  #   DevTools/
  #     EventExporter/
  #       BushidoEventExporter.rb
  #
  # So the project root is two directories above this file.
  PROJECT_ROOT = File.expand_path("../..", __dir__)

  DATA_FOLDER = File.join(PROJECT_ROOT, "Data")


  # ----------------------------------------------------------
  # Utility
  # ----------------------------------------------------------

  def self.map_filename(map_id)
    File.join(
      DATA_FOLDER,
      sprintf("Map%03d.rxdata", map_id)
    )
  end


  def self.load_rxdata(filename)
    File.open(filename, "rb") do |file|
      Marshal.load(file)
    end
  end


  def self.load_map(map_id)
    filename = map_filename(map_id)

    unless File.exist?(filename)
      raise "Map file not found:\n#{filename}"
    end

    load_rxdata(filename)
  end


  # ----------------------------------------------------------
  # Event listing
  # ----------------------------------------------------------

  def self.list_events(map_id)
    map = load_map(map_id)

    puts
    puts "=============================================="
    puts "BUSHIDO EVENT EXPORTER"
    puts "=============================================="
    puts
    puts sprintf("Map ID: %03d", map_id)
    puts "Size: #{map.width} x #{map.height}"
    puts

    if map.events.nil? || map.events.empty?
      puts "No events found."
      return
    end

    puts "EVENTS"
    puts "----------------------------------------------"

    map.events.keys.sort.each do |event_id|
      event = map.events[event_id]

      puts sprintf(
        "[%03d] %-30s X:%3d Y:%3d",
        event.id,
        event.name.to_s,
        event.x,
        event.y
      )
    end

    puts "----------------------------------------------"
    puts "#{map.events.length} event(s) found."
    puts
  end


  # ----------------------------------------------------------
  # Command-line UI
  # ----------------------------------------------------------

  def self.run
    system("cls") if Gem.win_platform?

    puts "=============================================="
    puts "BUSHIDO EVENT EXPORTER"
    puts "=============================================="
    puts
    puts "Project:"
    puts PROJECT_ROOT
    puts

    unless Dir.exist?(DATA_FOLDER)
      puts "ERROR:"
      puts "Could not find Bushido's Data folder."
      puts
      puts DATA_FOLDER
      puts
      pause
      return
    end

    print "Enter a Map ID: "

    input = STDIN.gets

    if input.nil?
      return
    end

    input = input.strip

    unless input =~ /^\d+$/
      puts
      puts "Please enter a numeric map ID."
      pause
      return
    end

    map_id = input.to_i

    begin
      list_events(map_id)
    rescue => e
      puts
      puts "=============================================="
      puts "ERROR"
      puts "=============================================="
      puts
      puts "#{e.class}: #{e.message}"
      puts
      puts e.backtrace.join("\n")
      puts
    end

    pause
  end


  def self.pause
    puts
    puts "Press Enter to close."
    STDIN.gets
  end
end


BushidoEventExporter.run