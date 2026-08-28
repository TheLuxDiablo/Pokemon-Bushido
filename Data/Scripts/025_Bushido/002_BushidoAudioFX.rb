
# BushidoAudioFX.
module BushidoAudioFX

  ENABLE_FOOTSTEPS = true
  ENABLE_AMBIENCE  = true

  MAX_POSITIONAL_VOLUME = 90

  FOOTSTEP_FALLBACK = [
    "Bushido/Footsteps/ground_1",
    "Bushido/Footsteps/ground_2",
    "Bushido/Footsteps/ground_3"
  ]

  FOOTSTEP_TERRAINS = {

    0 => {
      :sounds => [
        "Bushido/Footsteps/ground_1",
        "Bushido/Footsteps/ground_2",
        "Bushido/Footsteps/ground_3"
      ],
      :volume => 72,
      :pitch  => 100
    },

    1 => {
      :sounds => [
        "Bushido/Footsteps/grass_1",
        "Bushido/Footsteps/grass_2",
        "Bushido/Footsteps/grass_3"
      ],
      :volume => 68,
      :pitch  => 100
    },

    2 => {
      :sounds => [
        "Bushido/Footsteps/stone_1",
        "Bushido/Footsteps/stone_2",
        "Bushido/Footsteps/stone_3"
      ],
      :volume => 76,
      :pitch  => 100
    },

    3 => {
      :sounds => [
        "Bushido/Footsteps/wood_1",
        "Bushido/Footsteps/wood_2",
        "Bushido/Footsteps/wood_3"
      ],
      :volume => 78,
      :pitch  => 100
    },

    4 => {
      :sounds => [
        "Bushido/Footsteps/sand_1",
        "Bushido/Footsteps/sand_2",
        "Bushido/Footsteps/sand_3"
      ],
      :volume => 65,
      :pitch  => 100
    },

    5 => {
      :sounds => [
        "Bushido/Footsteps/water_1",
        "Bushido/Footsteps/water_2",
        "Bushido/Footsteps/water_3"
      ],
      :volume => 78,
      :pitch  => 100
    }

  }

  FOOTSTEP_PITCH_VARIATION  = 5
  FOOTSTEP_VOLUME_VARIATION = 4

  FOOTSTEP_PATTERNS = [0, 2]

  AMBIENT_TYPES = {

    :waves => {
      :sounds => [
        "Bushido/Ambience/waves_1",
        "Bushido/Ambience/waves_2",
        "Bushido/Ambience/waves_3"
      ],
      :radius   => 12,
      :volume   => 80,
      :pitch    => 100,
      :interval => 110,
      :variance => 40
    },

    :waterfall => {
      :sounds => [
        "Bushido/Ambience/waterfall_1",
        "Bushido/Ambience/waterfall_2"
      ],
      :radius   => 10,
      :volume   => 85,
      :pitch    => 100,
      :interval => 75,
      :variance => 15
    },

    :river => {
      :sounds => [
        "Bushido/Ambience/river_1",
        "Bushido/Ambience/river_2"
      ],
      :radius   => 9,
      :volume   => 65,
      :pitch    => 100,
      :interval => 95,
      :variance => 25
    },

    :fire => {
      :sounds => [
        "Bushido/Ambience/fire_1",
        "Bushido/Ambience/fire_2",
        "Bushido/Ambience/fire_3"
      ],
      :radius   => 7,
      :volume   => 60,
      :pitch    => 100,
      :interval => 80,
      :variance => 25
    },

    :birds => {
      :sounds => [
        "Bushido/Ambience/birds_1",
        "Bushido/Ambience/birds_2",
        "Bushido/Ambience/birds_3"
      ],
      :radius   => 14,
      :volume   => 50,
      :pitch    => 100,
      :interval => 220,
      :variance => 100
    },

    :insects => {
      :sounds => [
        "Bushido/Ambience/insects_1",
        "Bushido/Ambience/insects_2"
      ],
      :radius   => 10,
      :volume   => 45,
      :pitch    => 100,
      :interval => 180,
      :variance => 60
    }

  }

  MAP_AMBIENCE = {

  }

  @emitters        = []
  @global_ambience = []
  @current_map     = nil

  class << self

    def update
      return if !ENABLE_AMBIENCE
      return if !$game_map
      return if !$game_player

      if @current_map != $game_map.map_id
        setup_map
      end

      update_emitters
      update_global_ambience
    end

    def setup_map
      return if !$game_map

      @current_map     = $game_map.map_id
      @emitters        = []
      @global_ambience = []

      scan_map_events
      setup_global_ambience
    end

    def scan_map_events
      return if !$game_map
      return if !$game_map.events

      $game_map.events.each_value do |event|
        next if !event

        rpg_event = event.instance_variable_get(:@event)
        next if !rpg_event

        comments = get_event_comments(event)
        next if comments.empty?

        comments.each do |comment|
          parse_ambient_comment(event, comment)
        end
      end
    end

    def get_event_comments(event)
      ret = []

      return ret if !event

      rpg_event = event.instance_variable_get(:@event)
      return ret if !rpg_event
      return ret if !rpg_event.pages

      page_index = event.instance_variable_get(:@page_index)

      return ret if page_index.nil?
      return ret if page_index < 0
      return ret if page_index >= rpg_event.pages.length

      page = rpg_event.pages[page_index]

      return ret if !page
      return ret if !page.list

      page.list.each do |command|
        next if !command
        next if command.code != 108 && command.code != 408
        next if !command.parameters

        ret.push(command.parameters[0].to_s)
      end

      return ret
    end

    def parse_ambient_comment(event, comment)
      return if !comment
      return if comment !~ /<ambient\s*:\s*([^>]+)>/i

      data   = $1.to_s
      pieces = data.split(",")

      return if pieces.length == 0

      type_name = pieces.shift.to_s.strip.downcase
      type      = type_name.to_sym

      definition = AMBIENT_TYPES[type]

      return if !definition

      emitter = {
        :event    => event,
        :type     => type,
        :sounds   => definition[:sounds],
        :radius   => definition[:radius] || 10,
        :volume   => definition[:volume] || 60,
        :pitch    => definition[:pitch] || 100,
        :interval => definition[:interval] || 120,
        :variance => definition[:variance] || 0,
        :timer    => rand(60)
      }

      pieces.each do |piece|
        next if !piece

        pair = piece.split("=")

        next if pair.length < 2

        key   = pair[0].to_s.strip.downcase
        value = pair[1].to_s.strip

        case key
        when "radius"
          emitter[:radius] = value.to_f

        when "volume"
          emitter[:volume] = value.to_i

        when "pitch"
          emitter[:pitch] = value.to_i

        when "interval"
          emitter[:interval] = value.to_i

        when "variance"
          emitter[:variance] = value.to_i
        end
      end

      @emitters.push(emitter)
    end

    def setup_global_ambience
      return if !$game_map

      list = MAP_AMBIENCE[$game_map.map_id]

      return if !list

      list.each do |data|
        next if !data

        ambience = {
          :sounds   => data[:sounds],
          :volume   => data[:volume] || 40,
          :pitch    => data[:pitch] || 100,
          :interval => data[:interval] || 200,
          :variance => data[:variance] || 0,
          :timer    => rand(80)
        }

        @global_ambience.push(ambience)
      end
    end

    def update_emitters
      return if !@emitters
      return if !$game_player

      @emitters.each do |emitter|
        next if !emitter

        event = emitter[:event]

        next if !event

        erased = event.instance_variable_get(:@erased)

        next if erased

        emitter[:timer] -= 1

        next if emitter[:timer] > 0

        distance = distance_between(
          $game_player.x,
          $game_player.y,
          event.x,
          event.y
        )

        if distance <= emitter[:radius]

          volume = positional_volume(
            distance,
            emitter[:radius],
            emitter[:volume]
          )

          play_random_sound(
            emitter[:sounds],
            volume,
            emitter[:pitch]
          )

        end

        emitter[:timer] = next_interval(
          emitter[:interval],
          emitter[:variance]
        )
      end
    end

    def update_global_ambience
      return if !@global_ambience

      @global_ambience.each do |ambience|
        next if !ambience

        ambience[:timer] -= 1

        next if ambience[:timer] > 0

        play_random_sound(
          ambience[:sounds],
          ambience[:volume],
          ambience[:pitch]
        )

        ambience[:timer] = next_interval(
          ambience[:interval],
          ambience[:variance]
        )
      end
    end

    def distance_between(x1, y1, x2, y2)
      dx = x2 - x1
      dy = y2 - y1

      return Math.sqrt((dx * dx) + (dy * dy))
    end

    def positional_volume(distance, radius, max_volume)
      return 0 if radius <= 0
      return 0 if distance >= radius

      percentage = 1.0 - (distance.to_f / radius.to_f)
      percentage *= percentage

      volume = (max_volume * percentage).to_i

      volume = MAX_POSITIONAL_VOLUME if volume > MAX_POSITIONAL_VOLUME
      volume = 0 if volume < 0

      return volume
    end

    def next_interval(base, variance)
      base     = base.to_i
      variance = variance.to_i

      base     = 1 if base < 1
      variance = 0 if variance < 0

      return base if variance == 0

      minimum = base - variance
      maximum = base + variance

      minimum = 1 if minimum < 1
      maximum = minimum if maximum < minimum

      return minimum + rand(maximum - minimum + 1)
    end

    def play_random_sound(sounds, volume, pitch = 100)
      return if !sounds
      return if sounds.length == 0
      return if volume <= 0

      valid_sounds = sounds.select { |sound| audio_file_exists?(sound) }

      return if valid_sounds.empty?

      sound = valid_sounds[rand(valid_sounds.length)]

      pbSEPlay(sound, volume, pitch)
    end

    def audio_file_exists?(sound)
      return false if !sound
      return false if sound.empty?

      base = "Audio/SE/" + sound

      extensions = [
        ".ogg",
        ".wav",
        ".mp3",
        ".mid",
        ".midi"
      ]

      extensions.each do |ext|
        return true if FileTest.exist?(base + ext)
      end

      return false
    end

    def footstep
      return if !ENABLE_FOOTSTEPS
      return if !$game_player
      return if !$game_map

      return if player_should_be_silent?

      terrain = current_terrain_tag
      data    = FOOTSTEP_TERRAINS[terrain]

      if !data
        data = {
          :sounds => FOOTSTEP_FALLBACK,
          :volume => 72,
          :pitch  => 100
        }
      end

      sounds = data[:sounds] || FOOTSTEP_FALLBACK

      valid_sounds = sounds.select do |sound|
        audio_file_exists?(sound)
      end

      if valid_sounds.empty?
        valid_sounds = FOOTSTEP_FALLBACK.select do |sound|
          audio_file_exists?(sound)
        end
      end

      return if valid_sounds.empty?

      sound = valid_sounds[rand(valid_sounds.length)]

      base_volume = data[:volume] || 45
      base_pitch  = data[:pitch] || 100

      volume_change = rand((FOOTSTEP_VOLUME_VARIATION * 2) + 1)
      volume_change -= FOOTSTEP_VOLUME_VARIATION

      pitch_change = rand((FOOTSTEP_PITCH_VARIATION * 2) + 1)
      pitch_change -= FOOTSTEP_PITCH_VARIATION

      volume = base_volume + volume_change
      pitch  = base_pitch + pitch_change

      volume = 1   if volume < 1
      volume = 100 if volume > 100

      pitch = 50  if pitch < 50
      pitch = 150 if pitch > 150

      pbSEPlay(sound, volume, pitch)
    end

    def current_terrain_tag
      return 0 if !$game_map
      return 0 if !$game_player

      begin
        return $game_map.terrain_tag(
          $game_player.x,
          $game_player.y
        )
      rescue
        return 0
      end
    end

    def player_should_be_silent?
      return true if !$game_player

      if defined?($PokemonGlobal) && $PokemonGlobal

        begin
          return true if $PokemonGlobal.bicycle
        rescue
        end

        begin
          return true if $PokemonGlobal.surfing
        rescue
        end

      end

      return false
    end

    def reset
      @current_map     = nil
      @emitters        = []
      @global_ambience = []
    end

    def emitter_count
      return 0 if !@emitters
      return @emitters.length
    end

  end
end

# Game_Player.
class Game_Player < Game_Character

  if method_defined?(:update_pattern) &&
     !method_defined?(:bushido_audiofx_update_pattern)

    alias bushido_audiofx_update_pattern update_pattern

    def update_pattern
      old_pattern = @pattern

      bushido_audiofx_update_pattern

      return if @pattern == old_pattern

      return if !moving?

      begin
        return if jumping?
      rescue
      end

      if BushidoAudioFX::FOOTSTEP_PATTERNS.include?(@pattern)
        BushidoAudioFX.footstep
      end
    end

  end

end

# Scene_Map.
class Scene_Map

  if method_defined?(:update) &&
     !method_defined?(:bushido_audiofx_update)

    alias bushido_audiofx_update update

    def update
      bushido_audiofx_update
      BushidoAudioFX.update
    end

  end

end
