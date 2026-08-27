#===============================================================================
# Pokémon Bushido - Tournament System
# Essentials v18.1 / Bushido v2
#===============================================================================
# PBS files:
#   PBS/tournamenttrainers.txt
#   PBS/tournaments.txt
#
# Full automatic tournament:
#   BushidoTournament.play(:KENSHI_STORY)
#
# Showcase presentation:
#   BushidoTournament.show_opening_match       # opening + first matchup, seamless
#   BushidoTournament.show_results(nil, true) # results + next matchup, auto-close
#   BushidoTournament.show_results_and_finale # final result + champion, seamless
#
# Individual presentation calls remain available:
#   BushidoTournament.show_opening
#   BushidoTournament.show_current_match
#   BushidoTournament.show_results
#   BushidoTournament.show_finale
#
# Story pacing:
#   BushidoTournament.phase
#   BushidoTournament.advance
#   BushidoTournament.player_won       # external/story battle won
#   BushidoTournament.player_lost      # external/story battle lost
#   BushidoTournament.show_results(nil, true) # reveal next matchup
#
# Dynamic rival helpers:
#   BushidoTournament.rival_name
#   BushidoTournament.rival_trainer_type
#
# Story-event / granular API:
#   BushidoTournament.start(:KENSHI_STORY)
#   BushidoTournament.show_bracket
#   BushidoTournament.show_current_match
#   BushidoTournament.battle
#   BushidoTournament.resolve_round
#   BushidoTournament.show_results
#   BushidoTournament.current_opponent_id
#   BushidoTournament.current_opponent_name
#   BushidoTournament.round
#   BushidoTournament.player_alive?
#   BushidoTournament.finished?
#   BushidoTournament.player_champion?
#   BushidoTournament.finish
#
# Notes:
# - RPG Maker events remain the "director" for story tournaments.
# - This script owns bracket state, PBS data, battles, NPC simulation and PWT UI.
#===============================================================================

module BushidoTournament
  TRAINER_PBS    = "PBS/tournamenttrainers.txt"
  TOURNAMENT_PBS = "PBS/tournaments.txt"
  PORTRAIT_DIR   = "Graphics/Pictures/Tournament/Trainers/"

  # Legacy constants retained for compatibility. The tournament UI no longer
  # color-codes the left and right sides.
  LEFT_ACCENT  = Color.new(156, 136, 112)
  RIGHT_ACCENT = Color.new(156, 136, 112)
  PATH_WHITE   = Color.new(245, 245, 245)
  PATH_GREY    = Color.new(110, 110, 116)
  PATH_RED     = Color.new(218, 76, 40)
  PATH_YELLOW  = Color.new(255, 185, 25)

  #-------------------------------------------------------------------------
  # Optional presentation SFX hooks
  #-------------------------------------------------------------------------
  # Assign filenames without extensions later. nil is intentionally silent.
  SE_OPEN           = nil
  SE_PORTRAIT_IN    = nil
  SE_NAMEPLATE_IN   = nil
  SE_NAMEPLATE_OUT  = nil
  SE_RESULT         = nil
  SE_ROUTE_TICK     = nil
  SE_ROUTE_COMPLETE = nil
  SE_ELIMINATED     = nil
  SE_FINALISTS      = nil
  SE_CHAMPION       = nil

  def self.play_ui_se(name, volume = 80, pitch = 100)
    return if !name || name.to_s.empty?
    begin
      pbSEPlay(name, volume, pitch)
    rescue
      # Presentation SFX must never break tournament progression.
    end
  end

  #=============================================================================
  # PBS DATA
  #=============================================================================
  class TrainerData
    attr_accessor :id
    attr_accessor :name
    attr_accessor :trainer_type
    attr_accessor :trainer_name
    attr_accessor :party
    attr_accessor :lose_text
    attr_accessor :intro_script
    attr_accessor :last_script
    attr_accessor :ace
    attr_accessor :strength
    attr_accessor :graphic
    attr_accessor :dynamic
    attr_accessor :male_name
    attr_accessor :female_name
    attr_accessor :male_trainer_type
    attr_accessor :female_trainer_type
    attr_accessor :male_graphic
    attr_accessor :female_graphic
    attr_accessor :battle_args

    def initialize(id)
      @id           = id
      @name         = id.to_s
      @trainer_type = nil
      @trainer_name = nil
      @party        = 0
      @lose_text    = nil
      @intro_script = nil
      @last_script  = nil
      @ace          = nil
      @strength     = 50
      @graphic      = nil
      @dynamic      = nil
      @male_name    = nil
      @female_name  = nil
      @male_trainer_type   = nil
      @female_trainer_type = nil
      @male_graphic   = nil
      @female_graphic = nil
      @battle_args  = nil
    end
  end

  class TournamentData
    attr_accessor :id
    attr_accessor :name
    attr_accessor :description
    attr_accessor :mode
    attr_accessor :entry_count
    attr_accessor :player_slot
    attr_accessor :heal_between_rounds
    attr_accessor :participants
    attr_accessor :pool
    attr_accessor :preset_winners

    def initialize(id)
      @id                  = id
      @name                = id.to_s
      @description         = ""
      @mode                = :PRESET
      @entry_count         = 8
      @player_slot         = :RANDOM
      @heal_between_rounds = true
      @participants        = []
      @pool                = []
      @preset_winners      = {}
    end
  end

  module PBS
    def self.read_sections(path)
      raise "Tournament PBS file not found: #{path}" if !FileTest.exist?(path)
      sections = {}
      current = nil
      File.open(path, "rb") do |f|
        f.each_line do |raw|
          line = raw.to_s.gsub(/\r|\n/, "").strip
          next if line.empty?
          next if line[0, 1] == "#"
          if line =~ /^\[(.+)\]$/
            current = $1.strip
            sections[current] = {}
            next
          end
          next if !current
          next if line.index("=").nil?
          key, value = line.split("=", 2)
          sections[current][key.strip] = value ? value.strip : ""
        end
      end
      return sections
    end

    def self.bool(value, default = false)
      return default if value.nil?
      value = value.to_s.strip.downcase
      return true  if value == "true" || value == "yes" || value == "1"
      return false if value == "false" || value == "no" || value == "0"
      return default
    end

    def self.symbol(value)
      return nil if value.nil? || value.to_s.strip.empty?
      return value.to_s.strip.upcase.to_sym
    end

    def self.script_symbol(value)
      return nil if value.nil? || value.to_s.strip.empty?
      return value.to_s.strip.to_sym
    end

    def self.id_list(value)
      return [] if value.nil? || value.to_s.strip.empty?
      return value.split(",").collect { |v| v.strip.upcase.to_sym }
    end

    def self.scalar(value)
      return nil if value.nil?
      s = value.to_s.strip
      return nil   if s.downcase == "nil"
      return true  if s.downcase == "true"
      return false if s.downcase == "false"
      return s.to_i if s =~ /^-?\d+$/
      if s.length >= 2 && ((s[0,1] == '"' && s[-1,1] == '"') || (s[0,1] == "'" && s[-1,1] == "'"))
        return s[1, s.length - 2]
      end
      return s
    end

    def self.mixed_list(value)
      return nil if value.nil? || value.to_s.strip.empty?
      return value.split(",").collect { |v| scalar(v) }
    end
  end

  @trainer_data    = {}
  @tournament_data = {}
  @data_loaded     = false

  def self.reload_data
    @trainer_data    = {}
    @tournament_data = {}

    trainer_sections = PBS.read_sections(TRAINER_PBS)
    trainer_sections.each do |section, values|
      id = section.to_s.upcase.to_sym
      data = TrainerData.new(id)
      data.name         = values["Name"] || section
      data.trainer_type = PBS.symbol(values["TrainerType"])
      data.trainer_name = values["TrainerName"] || data.name
      data.party        = (values["Party"] || "0").to_i
      data.lose_text    = values["LoseText"]
      data.intro_script = PBS.script_symbol(values["IntroScript"])
      data.last_script  = PBS.script_symbol(values["LastScript"])
      data.ace          = values["Ace"] ? values["Ace"].to_i : nil
      data.strength     = values["Strength"] ? values["Strength"].to_i : 50
      data.graphic      = values["Graphic"]
      data.dynamic      = PBS.symbol(values["Dynamic"])
      data.male_name    = values["MaleName"]
      data.female_name  = values["FemaleName"]
      data.male_trainer_type   = PBS.symbol(values["MaleTrainerType"])
      data.female_trainer_type = PBS.symbol(values["FemaleTrainerType"])
      data.male_graphic   = values["MaleGraphic"]
      data.female_graphic = values["FemaleGraphic"]
      data.battle_args  = PBS.mixed_list(values["BattleArgs"])
      @trainer_data[id] = data
    end

    tournament_sections = PBS.read_sections(TOURNAMENT_PBS)
    tournament_sections.each do |section, values|
      id = section.to_s.upcase.to_sym
      data = TournamentData.new(id)
      data.name                = values["Name"] || section
      data.description         = values["Description"] || ""
      data.mode                = PBS.symbol(values["Mode"] || "PRESET")
      data.entry_count         = (values["EntryCount"] || "8").to_i
      data.heal_between_rounds = PBS.bool(values["HealBetweenRounds"], true)
      data.participants        = PBS.id_list(values["Participants"])
      data.pool                = PBS.id_list(values["Pool"])

      if values["PlayerSlot"]
        ps = values["PlayerSlot"].to_s.strip
        data.player_slot = (ps.upcase == "RANDOM") ? :RANDOM : ps.to_i
      end

      values.each do |key, value|
        if key =~ /^PresetWinner(\d)(\d)$/i
          round = $1.to_i - 1
          match = $2.to_i - 1
          data.preset_winners[[round, match]] = value.to_s.strip.upcase.to_sym
        end
      end

      @tournament_data[id] = data
    end

    @data_loaded = true
    return true
  end

  def self.ensure_data
    reload_data if !@data_loaded
  end

  def self.trainer_data(id)
    ensure_data
    return @trainer_data[id.to_s.upcase.to_sym]
  end

  def self.tournament_data(id)
    ensure_data
    return @tournament_data[id.to_s.upcase.to_sym]
  end

  def self.available_tournaments
    ensure_data
    return @tournament_data.keys
  end

  #=============================================================================
  # RUNTIME ENTRANT / MATCH / TOURNAMENT
  #=============================================================================
  class Entrant
    attr_reader :id
    attr_reader :data
    attr_reader :name

    def initialize(id, data = nil)
      @id   = id
      @data = data
      @name = player? ? $Trainer.name : (data ? data.name : id.to_s)
    end

    def player?
      return @id == :PLAYER
    end

    def strength
      return 60 if player?
      return @data ? @data.strength : 50
    end
  end

  class Match
    attr_reader :entrant1
    attr_reader :entrant2
    attr_reader :round
    attr_reader :index
    attr_reader :winner

    def initialize(a, b, round, index)
      @entrant1 = a
      @entrant2 = b
      @round    = round
      @index    = index
      @winner   = nil
    end

    def key
      return [@round, @index]
    end

    def finished?
      return !@winner.nil?
    end

    def player_match?
      return (@entrant1 && @entrant1.player?) || (@entrant2 && @entrant2.player?)
    end

    def opponent
      return nil if !player_match?
      return @entrant2 if @entrant1 && @entrant1.player?
      return @entrant1 if @entrant2 && @entrant2.player?
      return nil
    end

    def set_winner(entrant)
      @winner = entrant
    end
  end

  class Tournament
    attr_reader :data
    attr_reader :entrants
    attr_reader :rounds
    attr_reader :current_round
    attr_reader :champion
    attr_reader :pending_results
    attr_reader :phase
    attr_reader :opening_shown

    def initialize(data)
      @data            = data
      @entrants        = []
      @rounds          = [[], [], []]
      @current_round   = 0
      @champion        = nil
      @player_alive    = true
      @pending_results = []
      @phase           = :NOT_STARTED
      @opening_shown   = false
      build_entrants
      build_first_round
    end

    def set_phase(value)
      @phase = value
    end

    def begin!
      @phase = :AWAITING_MATCH
    end

    def mark_opening_shown!
      @opening_shown = true
    end

    def build_entrants
      ids = []
      if @data.mode == :RANDOM
        pool = @data.pool.clone
        pool = pool.sort_by { rand }
        needed = @data.entry_count - 1
        ids = pool[0, needed] || []
        slot = @data.player_slot
        if slot == :RANDOM || slot.to_i <= 0
          slot = rand(@data.entry_count) + 1
        end
        slot = [[slot.to_i, 1].max, @data.entry_count].min
        ids.insert(slot - 1, :PLAYER)
      else
        ids = @data.participants.clone
      end

      if ids.length != 8
        raise "Tournament #{@data.id} must currently contain exactly 8 entrants."
      end

      ids.each do |id|
        if id == :PLAYER
          @entrants << Entrant.new(:PLAYER, nil)
        else
          tdata = BushidoTournament.trainer_data(id)
          raise "Unknown tournament trainer: #{id}" if !tdata
          tdata = BushidoTournament.resolved_trainer_data(tdata)
          @entrants << Entrant.new(id, tdata)
        end
      end
    end

    def build_first_round
      4.times do |i|
        @rounds[0] << Match.new(@entrants[i * 2], @entrants[i * 2 + 1], 0, i)
      end
    end

    def entrant(id)
      @entrants.each { |e| return e if e.id == id }
      return nil
    end

    def slot_for(id)
      @entrants.each_with_index { |e, i| return i if e.id == id }
      return nil
    end

    def player_match
      @rounds.each do |round|
        round.each do |match|
          next if match.finished?
          return match if match.player_match?
        end
      end
      return nil
    end

    def current_opponent
      m = player_match
      return m ? m.opponent : nil
    end

    def record_result(match, winner)
      return if match.finished?
      match.set_winner(winner)
      @pending_results << match
      if match.player_match? && winner && !winner.player?
        @player_alive = false
      end
      refresh_bracket
    end

    def player_won!
      m = player_match
      raise "No active player tournament match." if !m
      record_result(m, entrant(:PLAYER))
    end

    def player_lost!
      m = player_match
      raise "No active player tournament match." if !m
      record_result(m, m.opponent)
    end

    def scripted_winner(match)
      id = @data.preset_winners[match.key]
      return id ? entrant(id) : nil
    end

    def simulated_winner(match)
      forced = scripted_winner(match)
      return forced if forced
      a = [match.entrant1.strength, 1].max
      b = [match.entrant2.strength, 1].max
      roll = rand(a + b)
      return roll < a ? match.entrant1 : match.entrant2
    end

    def resolve_current_round
      round = @rounds[@current_round]
      return if !round
      round.each do |match|
        next if match.finished?
        next if match.player_match?
        record_result(match, simulated_winner(match))
      end
      refresh_bracket
    end

    def refresh_bracket
      if @rounds[1].empty? && @rounds[0].all? { |m| m.finished? }
        @rounds[1] << Match.new(@rounds[0][0].winner, @rounds[0][1].winner, 1, 0)
        @rounds[1] << Match.new(@rounds[0][2].winner, @rounds[0][3].winner, 1, 1)
        @current_round = 1
      end

      if !@rounds[1].empty? && @rounds[2].empty? && @rounds[1].all? { |m| m.finished? }
        @rounds[2] << Match.new(@rounds[1][0].winner, @rounds[1][1].winner, 2, 0)
        @current_round = 2
      end

      if !@rounds[2].empty? && @rounds[2][0].finished?
        @champion = @rounds[2][0].winner
      end
    end

    def consume_pending_results
      results = @pending_results.clone
      @pending_results.clear
      return results
    end

    def player_alive?
      return @player_alive
    end

    def finished?
      return !@champion.nil?
    end

    def player_champion?
      return @champion && @champion.player?
    end
  end

  @active_tournament = nil

  #=============================================================================
  # PUBLIC STATE API
  #=============================================================================


  def self.start(id)
    # Tournament data is tiny, and reloading here prevents stale PBS data when
    # iterating in development. It also guarantees dynamic rival graphics use
    # the latest FemaleGraphic/MaleGraphic definitions.
    reload_data

    data = tournament_data(id)
    raise "Unknown tournament: #{id}" if !data

    @active_tournament = Tournament.new(data)
    @active_tournament.begin!
    return true
  end

  def self.active
    return @active_tournament
  end

  def self.finish
    @active_tournament = nil
    return true
  end

  def self.round
    return nil if !@active_tournament
    return @active_tournament.current_round + 1
  end

  def self.current_opponent_id
    return nil if !@active_tournament
    o = @active_tournament.current_opponent
    return o ? o.id : nil
  end

  # Record a result from a battle launched by the map event itself.
  # This lets story tournaments keep their bespoke BattleScripting hooks.
  def self.player_won
    return false if !@active_tournament
    @active_tournament.player_won!
    @active_tournament.set_phase(:AWAITING_RESULTS)
    return true
  end

  def self.player_lost
    return false if !@active_tournament
    @active_tournament.player_lost!
    @active_tournament.set_phase(:ELIMINATED)
    return true
  end

  def self.player_alive?
    return false if !@active_tournament
    return @active_tournament.player_alive?
  end

  def self.finished?
    return false if !@active_tournament
    return @active_tournament.finished?
  end

  def self.player_champion?
    return false if !@active_tournament
    return @active_tournament.player_champion?
  end

  def self.current_opponent_name
    return nil if !@active_tournament
    opponent = @active_tournament.current_opponent
    return opponent ? opponent.name : nil
  end

  def self.tournament_name
    return nil if !@active_tournament
    return @active_tournament.data.name
  end

  def self.heal_between_rounds?
    return false if !@active_tournament
    return @active_tournament.data.heal_between_rounds
  end

  def self.phase
    return :NONE if !@active_tournament
    return @active_tournament.phase
  end

  # Story events call this after their between-round map dialogue/cutscene.
  def self.advance
    return false if !@active_tournament
    return false if !@active_tournament.player_alive?
    return false if @active_tournament.finished?
    @active_tournament.set_phase(:AWAITING_MATCH)
    return true
  end


  def self.resolve_round
    return false if !@active_tournament
    @active_tournament.resolve_current_round
    @active_tournament.set_phase(:AWAITING_RESULTS)
    return true
  end

  def self.heal_party
    return if !$Trainer || !$Trainer.party
    $Trainer.party.each do |pkmn|
      next if !pkmn
      pkmn.heal
    end
  end

  #=============================================================================
  # BATTLE
  #=============================================================================
  def self.prepare_battle_scripts(data)
    if data.intro_script
      BattleScripting.setInScript("turnStart0", data.intro_script)
    end
    if data.last_script
      BattleScripting.setInScript("lastOpp", data.last_script)
    end
    if !data.ace.nil?
      BattleScripting.setTrainerAce(data.ace)
    end
  end

  def self.default_battle_args(data)
    # Arguments following LoseText in Essentials v18 pbTrainerBattle.
    # Matches Kayoko/Tsuku's existing Bushido calls by default.
    return [false, data.party, false]
  end



  def self.battle
    return false if !@active_tournament

    match = @active_tournament.player_match
    return false if !match

    opponent = match.opponent
    return false if !opponent || !opponent.data

    data = opponent.data
    if !data.trainer_type
      raise "Tournament trainer #{data.id} has no TrainerType and cannot battle the player."
    end

    @active_tournament.set_phase(:AWAITING_BATTLE)
    prepare_battle_scripts(data)

    args = data.battle_args ? data.battle_args.clone : default_battle_args(data)

    won = pbTrainerBattle(
      data.trainer_type,
      data.trainer_name,
      data.lose_text,
      *args
    )

    if won
      @active_tournament.player_won!
    else
      @active_tournament.player_lost!
    end

    @active_tournament.set_phase(:AWAITING_RESULTS)
    return won
  end



  def self.play(id = :KENSHI_STORY)
    start(id)
    show_opening_match

    loop do
      break if finished?
      break if !player_alive?

      heal_party if @active_tournament.data.heal_between_rounds

      won = battle
      resolve_round

      if finished? && won
        show_results_and_finale
        return true
      end

      show_results(nil, true)

      break if !won
      break if finished?

      advance
    end

    if !player_alive?
      show_bracket(_INTL("{1} has been eliminated from the tournament.", $Trainer.name))
    end
    return false
  end

  def self.play_full(id = :KENSHI_STORY)
    return play(id)
  end

  #=============================================================================
  # UI-ONLY TOURNAMENT TEST
  #=============================================================================
  #
  # Runs the complete tournament presentation without launching real battles.
  # Every player match is treated as a player victory. After each "battle",
  # all results for that round are revealed one-by-one in bracket order.
  #
  # Usage from an event:
  #
  #   BushidoTournament.test_ui(:KENSHI_STORY)
  #
  #=============================================================================
  def self.test_ui(id = :KENSHI_STORY)
    start(id)

    show_bracket("The Kenshi Tournament begins!")

    #-------------------------------------------------------------------------
    # Quarterfinals
    #-------------------------------------------------------------------------
    # The actual battle-introduction nameplates are shown ONCE by the results/
    # matchup choreography. Do not pre-show a second generic set of plates.
    @active_tournament.player_won!
    @active_tournament.resolve_current_round
    show_results(nil, true)

    #-------------------------------------------------------------------------
    # Semifinals
    #-------------------------------------------------------------------------
    @active_tournament.player_won!
    @active_tournament.resolve_current_round
    show_results(nil, true)

    #-------------------------------------------------------------------------
    # Final
    #-------------------------------------------------------------------------
    @active_tournament.player_won!
    show_results

    show_bracket("The tournament is over!")

    return true
  end

  #=============================================================================
  # DYNAMIC TRAINER RESOLUTION
  #=============================================================================
  # Bushido's rival is the opposite-gender childhood friend:
  #   player gender 0 -> Akane / RIVALBUSHIDO_F
  #   player gender 1 -> Yakeru / RIVALBUSHIDO_M
  #
  # This mirrors the game's intro setup, which stores Akane/Yakeru in variable 26.

  def self.resolved_trainer_data(source)
    return source if !source
    return source if source.dynamic != :RIVAL

    data = source.dup
    player_gender = ($Trainer && $Trainer.respond_to?(:gender)) ? $Trainer.gender : 0

    if player_gender == 0
      data.name         = source.female_name || "Akane"
      data.trainer_name = data.name
      data.trainer_type = source.female_trainer_type || :RIVALBUSHIDO_F
    else
      data.name         = source.male_name || "Yakeru"
      data.trainer_name = data.name
      data.trainer_type = source.male_trainer_type || :RIVALBUSHIDO_M
    end

    # Keep Graphic as the generic fallback. character_graphic_for resolves
    # FemaleGraphic/MaleGraphic at render time.
    data.graphic = source.graphic

    if $game_variables && $game_variables[26] && !$game_variables[26].to_s.empty?
      data.name = $game_variables[26].to_s
      data.trainer_name = data.name
    end

    return data
  end

  def self.rival_trainer_type
    return ($Trainer && $Trainer.gender == 0) ? :RIVALBUSHIDO_F : :RIVALBUSHIDO_M
  end

  def self.rival_name
    return $game_variables[26].to_s if $game_variables && $game_variables[26] && !$game_variables[26].to_s.empty?
    return ($Trainer && $Trainer.gender == 0) ? "Akane" : "Yakeru"
  end

  #=============================================================================
  # GRAPHIC HELPERS
  #=============================================================================

  def self.existing_bitmap_path(base)
    return nil if !base || base.to_s.empty?

    base = base.to_s
    return base if FileTest.exist?(base)

    [".png", ".bmp", ".jpg", ".jpeg"].each do |ext|
      path = base + ext
      return path if FileTest.exist?(path)
    end

    return nil
  end


  def self.character_graphic_for(entrant)
    if entrant.player?
      if $game_player && $game_player.character_name && !$game_player.character_name.empty?
        return $game_player.character_name
      end
      return nil
    end

    return nil if !entrant.data
    data = entrant.data

    # Dynamic rival: prefer the gender-specific PBS graphic every time the
    # portrait is requested. This makes the visual resolve independently from
    # the trainer type/name resolution and is robust to data reloads.
    if data.dynamic == :RIVAL
      player_gender = ($Trainer && $Trainer.respond_to?(:gender)) ? $Trainer.gender : 0
      specific = (player_gender == 0) ? data.female_graphic : data.male_graphic
      return specific if specific && !specific.to_s.empty?
    end

    graphic = data.graphic
    return nil if !graphic || graphic.to_s.empty?
    return graphic
  end

  def self.show_opening_match(message = nil)
    return false if !@active_tournament
    return false if !@active_tournament.player_match

    message = _INTL("The {1} begins!", @active_tournament.data.name) if !message
    scene = PokemonTournament_Scene.new(@active_tournament, :OPENING_MATCH, message, [])
    scene.main

    @active_tournament.mark_opening_shown!
    @active_tournament.set_phase(:AWAITING_BATTLE)
    return true
  end

  # Seamless championship ending:
  # final result reveal -> champion finale -> one exit transition.
  def self.show_results_and_finale(message = nil)
    return false if !@active_tournament

    results = @active_tournament.consume_pending_results
    scene = PokemonTournament_Scene.new(@active_tournament, :RESULTS_FINALE, message, results)
    scene.main

    if @active_tournament.finished?
      @active_tournament.set_phase(:FINISHED)
    elsif !@active_tournament.player_alive?
      @active_tournament.set_phase(:ELIMINATED)
    else
      @active_tournament.set_phase(:BETWEEN_ROUNDS)
    end
    return true
  end

  def self.show_bracket(message = nil)
    return false if !@active_tournament
    scene = PokemonTournament_Scene.new(@active_tournament, :BRACKET, message, [])
    scene.main
    return true
  end

  def self.show_opening(message = nil)
    return false if !@active_tournament
    message = _INTL("The {1} begins!", @active_tournament.data.name) if !message
    scene = PokemonTournament_Scene.new(@active_tournament, :OPENING, message, [])
    scene.main
    @active_tournament.mark_opening_shown!
    @active_tournament.set_phase(:AWAITING_MATCH)
    return true
  end

  def self.show_current_match(message = nil)
    return false if !@active_tournament
    return false if !@active_tournament.player_match

    @active_tournament.set_phase(:AWAITING_BATTLE)
    scene = PokemonTournament_Scene.new(@active_tournament, :MATCH, message, [])
    scene.main
    return true
  end


  def self.show_results(message = nil, reveal_next = false)
    return false if !@active_tournament

    results = @active_tournament.consume_pending_results
    mode = reveal_next ? :RESULTS_NEXT : :RESULTS
    scene = PokemonTournament_Scene.new(@active_tournament, mode, message, results)
    scene.main

    if @active_tournament.finished?
      @active_tournament.set_phase(:FINISHED)
    elsif !@active_tournament.player_alive?
      @active_tournament.set_phase(:ELIMINATED)
    else
      @active_tournament.set_phase(:BETWEEN_ROUNDS)
    end
    return true
  end

  def self.show_finale(message = nil)
    return false if !@active_tournament
    return false if !@active_tournament.finished?

    champion = @active_tournament.champion
    if !message
      message = champion ? _INTL("{1} is the Tournament Champion!", champion.name) : _INTL("The tournament is over!")
    end

    scene = PokemonTournament_Scene.new(@active_tournament, :FINALE, message, [])
    scene.main
    @active_tournament.set_phase(:FINISHED)
    return true
  end

end

#===============================================================================
# Animated native-size tournament trainer sprite
#===============================================================================
# Tournament trainer graphics are standard 4x4 overworld character sheets.
# The UI uses the entirety of row 1 (row index 0) and loops all four frames.
# No scaling is applied.
#===============================================================================
class TournamentTrainerSprite < Sprite
  FRAME_COUNT = 4
  ROW_INDEX   = 0
  FRAME_TIME  = 10

  attr_reader :entrant
  attr_reader :frame_width
  attr_reader :frame_height

  def initialize(viewport, entrant)
    super(viewport)
    @entrant       = entrant
    @source_bitmap = nil
    @frame         = 0
    @frame_timer   = 0
    @frame_width   = 0
    @frame_height  = 0
    load_graphic
  end


  def load_graphic
    graphic = BushidoTournament.character_graphic_for(@entrant)
    return if !graphic || graphic.to_s.empty?

    path = nil
    graphic = graphic.to_s

    # Accept either a full project-relative path or a normal character filename.
    if graphic.index("Graphics/") == 0
      path = BushidoTournament.existing_bitmap_path(graphic)
    else
      path = BushidoTournament.existing_bitmap_path("Graphics/Characters/" + graphic)
    end

    # If a dynamic gender-specific rival graphic was configured but mistyped or
    # missing, gracefully fall back to Graphic= rather than rendering nothing.
    if !path && @entrant.data && @entrant.data.dynamic == :RIVAL
      fallback = @entrant.data.graphic
      if fallback && !fallback.to_s.empty? && fallback.to_s != graphic
        fallback = fallback.to_s
        if fallback.index("Graphics/") == 0
          path = BushidoTournament.existing_bitmap_path(fallback)
        else
          path = BushidoTournament.existing_bitmap_path("Graphics/Characters/" + fallback)
        end
      end
    end

    return if !path

    @source_bitmap = Bitmap.new(path)
    @frame_width   = @source_bitmap.width / 4
    @frame_height  = @source_bitmap.height / 4
    self.bitmap    = @source_bitmap
    update_src_rect
  end

  def update
    super
    return if !@source_bitmap

    @frame_timer += 1
    if @frame_timer >= FRAME_TIME
      @frame_timer = 0
      @frame = (@frame + 1) % FRAME_COUNT
      update_src_rect
    end
  end

  def update_src_rect
    return if !@source_bitmap
    self.src_rect.set(
      @frame * @frame_width,
      ROW_INDEX * @frame_height,
      @frame_width,
      @frame_height
    )
  end

  def graphic_loaded?
    return !@source_bitmap.nil?
  end

  def dispose
    # Sprite does not own a separately-created display bitmap; its bitmap is the
    # source character sheet itself, so dispose it exactly once here.
    if @source_bitmap && !@source_bitmap.disposed?
      @source_bitmap.dispose
    end
    @source_bitmap = nil
    self.bitmap = nil
    super if !disposed?
  end
end

#===============================================================================
# PWT-STYLE TOURNAMENT SCENE
#===============================================================================
class PokemonTournament_Scene
  ASSET_DIR = "Graphics/Pictures/Tournament/"

  #-------------------------------------------------------------------------
  # Visual language
  #-------------------------------------------------------------------------
  # Keep all tournament geometry on a 2px grid. The layout stays PWT-inspired,
  # while the surfaces lean into Bushido's ink/paper/vermillion presentation.
  GRID              = 2
  BORDER            = 2
  INNER_BORDER      = 4
  PATH_WIDTH        = 4
  PATH_PULSE_SIZE   = 4
  PATH_PULSE_GAP    = 12

  INK_DARK          = Color.new(28, 24, 22)
  INK_MID           = Color.new(56, 48, 44)
  PAPER_LIGHT       = Color.new(236, 224, 196)
  PAPER_MID         = Color.new(207, 190, 158)
  PAPER_DARK        = Color.new(156, 136, 112)
  VERMILION         = Color.new(218, 76, 40)
  GOLD              = Color.new(240, 174, 58)
  WHITE_INK         = Color.new(246, 240, 226)

  FIELD_BG      = Color.new(36, 30, 28)
  PANEL_WHITE   = Color.new(236, 224, 196)
  PANEL_DARK    = Color.new(54, 44, 40)
  PANEL_BORDER  = Color.new(28, 24, 22)
  TEXT_DARK     = Color.new(48, 38, 34)
  TEXT_LIGHT    = Color.new(246, 240, 226)
  MUTED         = Color.new(128, 108, 92)

  PORTRAIT_W = 68
  PORTRAIT_H = 62
  FIELD_BOTTOM_MARGIN = 82

  def initialize(tournament, mode, message, results)
    @tournament = tournament
    @mode       = mode
    @message    = message
    @results    = results || []
    @hidden_result_keys = {}
    @results.each { |m| @hidden_result_keys[m.key] = true }

    # Result/nameplate focus and moving-square phase for completed orange routes.
    @focus_match = nil
    @nameplate_slide = 0.0
    @nameplate_left_slide  = 0.0
    @nameplate_right_slide = 0.0
    @impact_loser = nil
    @impact_winner = nil
    @animating_result_match = nil

    # Opening modes must start already stripped down underneath the black
    # transition. Otherwise the fully-built bracket is visible for a frame,
    # then disappears, then animates back in.
    opening_mode = (@mode == :OPENING || @mode == :OPENING_MATCH)
    @hide_paths = opening_mode
    @hide_crown = opening_mode

    # Explicitly initialize input-indicator state. v5 created the sprite but
    # missed these fields, which caused nil + 1 inside update_sprites.
    @continue_visible = false
    @continue_tick    = 0

    @cinematic_transition = (@mode == :OPENING || @mode == :MATCH ||
                             @mode == :RESULTS || @mode == :RESULTS_NEXT ||
                             @mode == :FINALE || @mode == :OPENING_MATCH ||
                             @mode == :RESULTS_FINALE)

    # Keep phase within one exact spacing period so the loop has no jump.
    @path_phase = 0
    @path_tick  = 0
  end




  def main
    start_scene
    animate_scene_entry if @cinematic_transition

    auto_exit = false

    if @mode == :OPENING
      animate_opening

    elsif @mode == :OPENING_MATCH
      # One continuous ceremony. No fade out/in between opening and matchup.
      animate_opening
      wait_frames(8)
      animate_current_match_reveal(true)
      auto_exit = true

    elsif @mode == :MATCH
      @nameplate_left_slide  = 0.0
      @nameplate_right_slide = 0.0
      refresh
      animate_nameplates(true)

    elsif (@mode == :RESULTS || @mode == :RESULTS_NEXT) && !@results.empty?
      animate_results
      if @mode == :RESULTS_NEXT && @tournament.player_match
        animate_next_match_reveal
        auto_exit = true
      end

    elsif @mode == :RESULTS_FINALE
      animate_results if !@results.empty?
      wait_frames(8)
      animate_finale if @tournament.finished?
      auto_exit = true

    elsif @mode == :FINALE
      animate_finale
    end

    if !auto_exit
      wait_for_continue
    end

    if @mode == :MATCH && (@nameplate_left_slide > 0.0 || @nameplate_right_slide > 0.0)
      animate_nameplates(false)
    end

    animate_scene_exit if @cinematic_transition
    end_scene
  end

  def load_ui_assets
    @ui_assets = {}
    [
      "background",
      "portrait_frame",
      "nameplate",
      "message_box",
      "crest",
      "transition",
      "path_white",
      "path_grey",
      "path_winner",
      "pulse_bright",
      "pulse_mid",
      "pulse_dark",
      "gold_tile"
    ].each do |name|
      path = BushidoTournament.existing_bitmap_path(ASSET_DIR + name)
      raise "Missing tournament UI asset: #{ASSET_DIR}#{name}.png" if !path
      @ui_assets[name] = Bitmap.new(path)
    end
  end

  def ui_asset(name)
    return @ui_assets[name]
  end

  def dispose_ui_assets
    return if !@ui_assets
    @ui_assets.each_value do |bmp|
      bmp.dispose if bmp && !bmp.disposed?
    end
    @ui_assets.clear
    @ui_assets = nil
  end

  # Tile a tiny PNG across an authored rectangle. This replaces all former
  # fill_rect-based path/pulse/ceremony drawing while preserving exact pixels.
  def blit_tiled_rect(bitmap, x, y, w, h, asset_name)
    return if w <= 0 || h <= 0
    tile = ui_asset(asset_name)
    return if !tile

    yy = 0
    while yy < h
      th = [tile.height, h - yy].min
      xx = 0
      while xx < w
        tw = [tile.width, w - xx].min
        bitmap.blt(
          x + xx,
          y + yy,
          tile,
          Rect.new(0, 0, tw, th)
        )
        xx += tile.width
      end
      yy += tile.height
    end
  end

  def path_asset_name(color)
    return "path_winner" if color == BushidoTournament::PATH_RED
    return "path_grey"   if color == BushidoTournament::PATH_GREY
    return "path_white"
  end

  def start_scene
    load_ui_assets

    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites = {}

    @sprites["base"] = Sprite.new(@viewport)
    @sprites["base"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    pbSetSystemFont(@sprites["base"].bitmap)

    # Animated yellow "squares" that travel along permanent orange winner paths.
    # Kept separate so the orange route can stay alive without redrawing the
    # whole scene or disturbing matchup/result overlays.
    @sprites["pulse"] = Sprite.new(@viewport)
    @sprites["pulse"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprites["pulse"].z = 8

    @sprites["overlay"] = Sprite.new(@viewport)
    @sprites["overlay"].bitmap = Bitmap.new(Graphics.width, Graphics.height)
    @sprites["overlay"].z = 12
    pbSetSystemFont(@sprites["overlay"].bitmap)

    @sprites["transition"] = Sprite.new(@viewport)
    @sprites["transition"].bitmap = ui_asset("transition")
    @sprites["transition"].z = 100
    @sprites["transition"].opacity = @cinematic_transition ? 255 : 0

    @sprites["continue"] = Sprite.new(@viewport)
    arrow_path = BushidoTournament.existing_bitmap_path("Graphics/Pictures/Arrow")
    raise "Missing dialogue arrow graphic: Graphics/Pictures/Arrow.png" if !arrow_path
    @sprites["continue"].bitmap = Bitmap.new(arrow_path)
    @sprites["continue"].src_rect.set(0, 0, 32, 32)
    @sprites["continue"].x = Graphics.width - 42
    @sprites["continue"].y = Graphics.height - 38
    @sprites["continue"].z = 50
    @sprites["continue"].visible = false

    build_portrait_sprites

    if @mode == :OPENING || @mode == :OPENING_MATCH
      8.times do |i|
        spr = @sprites["portrait#{i}"]
        next if !spr
        home_x, home_y = @portrait_home[i]
        spr.x = home_x + (i < 4 ? -24 : 24)
        spr.y = home_y + 4
        spr.opacity = 0
      end
    end

    refresh
  end

  def animate_scene_entry
    trans = @sprites["transition"]
    return if !trans

    # Black -> tournament screen. This prevents the PWT screen from simply
    # popping over a fully-visible arena.
    10.times do |i|
      trans.opacity = 255 - (((i + 1) * 255) / 10)
      Graphics.update
      Input.update
      update_sprites
    end
    trans.opacity = 0
  end

  def animate_scene_exit
    trans = @sprites["transition"]
    return if !trans

    # Tournament screen -> black. Story events should perform their arena
    # repositioning immediately after this call, while the map is faded out.
    10.times do |i|
      trans.opacity = ((i + 1) * 255) / 10
      Graphics.update
      Input.update
      update_sprites
    end
    trans.opacity = 255
  end


  def end_scene
    pbDisposeSpriteHash(@sprites)
    dispose_ui_assets

    if @viewport && !@viewport.disposed?
      @viewport.dispose
    end
    @viewport = nil
  end

  def update_sprites
    @sprites.each_value do |spr|
      next if !spr
      next if spr.disposed?
      spr.update
    end

    @path_tick = 0 if @path_tick.nil?
    @path_phase = 0 if @path_phase.nil?
    @path_tick += 1
    if @path_tick >= 3
      @path_tick = 0
      @path_phase = (@path_phase + 1) % 12
      refresh_idle_path_animation
    end

    # Animate Bushido's shared 2x2 Arrow.png exactly as a four-frame sheet.
    @continue_visible = false if @continue_visible.nil?
    @continue_tick = 0 if @continue_tick.nil?

    if @continue_visible && @sprites["continue"]
      @continue_tick = (@continue_tick + 1) % 32
      frame = (@continue_tick / 8) % 4
      frame_x = (frame % 2) * 32
      frame_y = (frame / 2) * 32
      @sprites["continue"].src_rect.set(frame_x, frame_y, 32, 32)
    end
  end

  def field_bottom
    return Graphics.height - FIELD_BOTTOM_MARGIN
  end

  def slot_y(index)
    gap = snap2((field_bottom - 8 - PORTRAIT_H * 4) / 3)
    return snap2(4 + (PORTRAIT_H + gap) * (index % 4))
  end

  def slot_center_y(index)
    return slot_y(index) + PORTRAIT_H / 2
  end

  def left_portrait_x
    return snap2(6)
  end

  def right_portrait_x
    return snap2(Graphics.width - PORTRAIT_W - 6)
  end

  def left_entry_x
    return snap2(left_portrait_x + PORTRAIT_W + 6)
  end

  def right_entry_x
    return snap2(right_portrait_x - 6)
  end

  def left_merge_x
    return snap2(Graphics.width * 0.30)
  end

  def right_merge_x
    return snap2(Graphics.width - left_merge_x)
  end

  def left_semi_x
    return snap2(Graphics.width * 0.42)
  end

  def right_semi_x
    return snap2(Graphics.width - left_semi_x)
  end

  def center_x
    return snap2(Graphics.width / 2)
  end

  # Snap every authored UI coordinate to the 2px presentation grid.
  def snap2(value)
    return (value.to_i / GRID) * GRID
  end

  def round1_mid_y(match_index)
    if match_index == 0
      return (slot_center_y(0) + slot_center_y(1)) / 2
    elsif match_index == 1
      return (slot_center_y(2) + slot_center_y(3)) / 2
    elsif match_index == 2
      return (slot_center_y(4) + slot_center_y(5)) / 2
    else
      return (slot_center_y(6) + slot_center_y(7)) / 2
    end
  end

  def final_y
    return (round1_mid_y(0) + round1_mid_y(1)) / 2
  end

  #-----------------------------------------------------------------------------
  # Portrait sprites
  #-----------------------------------------------------------------------------

  def build_portrait_sprites
    @portrait_home = {}

    @tournament.entrants.each_with_index do |entrant, i|
      spr = TournamentTrainerSprite.new(@viewport, entrant)

      frame_x = i < 4 ? left_portrait_x : right_portrait_x
      frame_w = spr.frame_width
      frame_h = spr.frame_height

      spr.x = frame_x + ((PORTRAIT_W - frame_w) / 2)
      spr.y = slot_y(i) + ((PORTRAIT_H - frame_h) / 2) - 2
      spr.z = 5

      @portrait_home[i] = [spr.x, spr.y]
      @sprites["portrait#{i}"] = spr
    end
  end

  def update_portrait_tones
    @tournament.entrants.each_with_index do |entrant, i|
      spr = @sprites["portrait#{i}"]
      next if !spr
      eliminated = entrant_eliminated?(entrant)
      if eliminated
        spr.tone = Tone.new(-90, -90, -90, 255)
        spr.opacity = 135
      else
        spr.tone = Tone.new(0, 0, 0, 0)
        spr.opacity = 255
      end
    end
  end

  def entrant_eliminated?(entrant)
    return true if @impact_loser && @impact_loser == entrant

    @tournament.rounds.each do |round|
      round.each do |match|
        next if !match.finished?

        # A pending result is intentionally hidden until its individual reveal.
        # This keeps the loser fully visible while the white route is still
        # waiting for the orange winner route to draw over it.
        next if @hidden_result_keys[match.key]

        if match.entrant1 == entrant || match.entrant2 == entrant
          return true if match.winner != entrant
        end
      end
    end
    return false
  end

  #-----------------------------------------------------------------------------
  # Refresh
  #-----------------------------------------------------------------------------

  def refresh
    base  = @sprites["base"].bitmap
    pulse = @sprites["pulse"].bitmap
    over  = @sprites["overlay"].bitmap
    base.clear
    pulse.clear
    over.clear

    draw_background(base)
    draw_portrait_frames(base)
    draw_all_paths(base) if !@hide_paths
    draw_crown(base) if !@hide_crown
    draw_message_box(base)

    if @mode == :MATCH
      draw_current_match_nameplates(over)
    elsif (@mode == :RESULTS || @mode == :RESULTS_NEXT) && @focus_match
      draw_match_nameplates(over, @focus_match)
    end

    update_portrait_tones
    refresh_idle_path_animation if !@hide_paths
  end


  def draw_background(bitmap)
    bitmap.blt(0, 0, ui_asset("background"), Rect.new(0, 0, Graphics.width, field_bottom))
  end


  def draw_portrait_frames(bitmap)
    frame = ui_asset("portrait_frame")
    8.times do |i|
      x = snap2(i < 4 ? left_portrait_x : right_portrait_x)
      y = snap2(slot_y(i))
      bitmap.blt(x, y, frame, Rect.new(0, 0, frame.width, frame.height))
    end
  end

  def visible_match_state(match)
    return :UNRESOLVED if @hidden_result_keys[match.key]
    return match.finished? ? :FINISHED : :UNRESOLVED
  end

  def draw_all_paths(bitmap)
    draw_round1_pair(bitmap, 0, 0, 1, true)
    draw_round1_pair(bitmap, 1, 2, 3, true)
    draw_round1_pair(bitmap, 2, 4, 5, false)
    draw_round1_pair(bitmap, 3, 6, 7, false)
    draw_semifinal_side(bitmap, 0, true)
    draw_semifinal_side(bitmap, 1, false)
  end


  def draw_round1_pair(bitmap, match_index, slot_a, slot_b, left_side)
    match = @tournament.rounds[0][match_index]
    xa = left_side ? left_entry_x : right_entry_x
    xm = left_side ? left_merge_x : right_merge_x
    xo = left_side ? left_semi_x : right_semi_x
    y1 = slot_center_y(slot_a)
    y2 = slot_center_y(slot_b)
    ym = (y1 + y2) / 2

    c1 = BushidoTournament::PATH_WHITE
    c2 = BushidoTournament::PATH_WHITE
    cout = BushidoTournament::PATH_WHITE

    if @animating_result_match == match && match.finished?
      # Result has been announced but not committed yet:
      # loser path greys immediately; winner path stays white while the orange
      # route is drawn over it by the overlay animation.
      winner_slot = @tournament.slot_for(match.winner.id)
      if winner_slot == slot_a
        c2 = BushidoTournament::PATH_GREY
      else
        c1 = BushidoTournament::PATH_GREY
      end
    elsif visible_match_state(match) == :FINISHED
      winner_slot = @tournament.slot_for(match.winner.id)
      if winner_slot == slot_a
        c1 = BushidoTournament::PATH_RED
        c2 = BushidoTournament::PATH_GREY
      else
        c1 = BushidoTournament::PATH_GREY
        c2 = BushidoTournament::PATH_RED
      end
      cout = BushidoTournament::PATH_RED
    end

    draw_route(bitmap, [[xa, y1, xm, y1], [xm, y1, xm, ym]], c1, c1 == BushidoTournament::PATH_RED)
    draw_route(bitmap, [[xa, y2, xm, y2], [xm, y2, xm, ym]], c2, c2 == BushidoTournament::PATH_RED)
    draw_route(bitmap, [[xm, ym, xo, ym]], cout, cout == BushidoTournament::PATH_RED)
  end


  def draw_semifinal_side(bitmap, semifinal_index, left_side)
    round = @tournament.rounds[1]
    y_top = left_side ? round1_mid_y(0) : round1_mid_y(2)
    y_bot = left_side ? round1_mid_y(1) : round1_mid_y(3)
    ymid  = (y_top + y_bot) / 2
    x_in  = left_side ? left_semi_x : right_semi_x
    x_mid = left_side ? (center_x - 35) : (center_x + 35)
    x_out = center_x

    match = (round && !round.empty?) ? round[semifinal_index] : nil
    c_top = BushidoTournament::PATH_WHITE
    c_bot = BushidoTournament::PATH_WHITE
    c_out = BushidoTournament::PATH_WHITE

    if match && @animating_result_match == match && match.finished?
      top_winner = left_side ? @tournament.rounds[0][0].winner : @tournament.rounds[0][2].winner
      if match.winner == top_winner
        c_bot = BushidoTournament::PATH_GREY
      else
        c_top = BushidoTournament::PATH_GREY
      end
    elsif match && visible_match_state(match) == :FINISHED
      top_winner = left_side ? @tournament.rounds[0][0].winner : @tournament.rounds[0][2].winner
      if match.winner == top_winner
        c_top = BushidoTournament::PATH_RED
        c_bot = BushidoTournament::PATH_GREY
      else
        c_top = BushidoTournament::PATH_GREY
        c_bot = BushidoTournament::PATH_RED
      end
      c_out = BushidoTournament::PATH_RED
    elsif @tournament.rounds[2] && !@tournament.rounds[2].empty?
      # Preserve the established semifinal contestants before their result.
      c_top = BushidoTournament::PATH_WHITE
      c_bot = BushidoTournament::PATH_WHITE
    end

    draw_route(bitmap, [[x_in, y_top, x_mid, y_top], [x_mid, y_top, x_mid, ymid]], c_top, c_top == BushidoTournament::PATH_RED)
    draw_route(bitmap, [[x_in, y_bot, x_mid, y_bot], [x_mid, y_bot, x_mid, ymid]], c_bot, c_bot == BushidoTournament::PATH_RED)
    draw_route(bitmap, [[x_mid, ymid, x_out, ymid]], c_out, c_out == BushidoTournament::PATH_RED)
  end

  def draw_route(bitmap, segments, color, dotted = false)
    segments.each do |seg|
      x1, y1, x2, y2 = seg
      draw_segment(bitmap, x1, y1, x2, y2, color, dotted)
    end
  end



  def draw_segment(bitmap, x1, y1, x2, y2, color, dotted = false)
    x1 = snap2(x1)
    y1 = snap2(y1)
    x2 = snap2(x2)
    y2 = snap2(y2)

    asset_name = path_asset_name(color)

    if x1 == x2
      y = [y1, y2].min
      h = snap2((y2 - y1).abs)
      blit_tiled_rect(
        bitmap,
        x1 - (PATH_WIDTH / 2),
        y,
        PATH_WIDTH,
        h,
        asset_name
      ) if h > 0
    else
      x = [x1, x2].min
      w = snap2((x2 - x1).abs)
      blit_tiled_rect(
        bitmap,
        x,
        y1 - (PATH_WIDTH / 2),
        w,
        PATH_WIDTH,
        asset_name
      ) if w > 0
    end
  end

  def draw_crown(bitmap)
    crest = ui_asset("crest")
    x = center_x - (crest.width / 2)
    y = final_y - (crest.height / 2)
    bitmap.blt(x, y, crest, Rect.new(0, 0, crest.width, crest.height))
  end

  def draw_current_match_nameplates(bitmap)
    match = @tournament.player_match
    return if !match
    draw_match_nameplates(bitmap, match)
  end


  def draw_match_nameplates(bitmap, match)
    return if !match

    [match.entrant1, match.entrant2].each do |entrant|
      slot = @tournament.entrants.index(entrant)
      next if slot.nil?
      progress = slot < 4 ? @nameplate_left_slide : @nameplate_right_slide
      draw_nameplate(bitmap, entrant, progress)
    end
  end


  def draw_nameplate(bitmap, entrant, progress = 1.0)
    slot = @tournament.entrants.index(entrant)
    return if slot.nil?

    left = slot < 4
    y = snap2(slot_y(slot) + 10)

    plate = ui_asset("nameplate")
    full_w = plate.width
    h = plate.height

    progress = [[progress.to_f, 0.0].max, 1.0].min
    visible_w = snap2(full_w * progress)
    return if visible_w <= 0

    if left
      x = snap2(left_portrait_x + PORTRAIT_W)
      src_x = 0
    else
      x = snap2(right_portrait_x - visible_w)
      src_x = full_w - visible_w
    end

    bitmap.blt(
      x,
      y,
      plate,
      Rect.new(src_x, 0, visible_w, h)
    )

    if progress >= 0.55
      draw_name_text(
        bitmap,
        x + 12,
        y + 4,
        [visible_w - 24, 1].max,
        h - 8,
        entrant.name,
        0
      )
    end
  end

  def draw_name_text(bitmap, x, y, w, h, text, align = 0)
    metrics = bitmap.text_size(text.to_s)
    text_h = metrics.height
    text_y = y + ((h - text_h) / 2)

    pbDrawShadowText(
      bitmap,
      x,
      text_y,
      w,
      text_h,
      text.to_s,
      TEXT_DARK,
      Color.new(214, 196, 164),
      align
    )
  end

  def draw_text_vertically_centered(bitmap, x, y, w, h, text, align = 0)
    metrics = bitmap.text_size(text.to_s)
    text_h = metrics.height
    text_y = y + ((h - text_h) / 2)
    bitmap.draw_text(x, text_y, w, text_h, text.to_s, align)
  end

  #-----------------------------------------------------------------------------
  # Bottom message panel
  #-----------------------------------------------------------------------------



  def draw_message_box(bitmap)
    y = field_bottom
    panel = ui_asset("message_box")
    bitmap.blt(0, y, panel, Rect.new(0, 0, panel.width, panel.height))

    return if !@message || @message.empty?

    lines = @message.to_s.split("\n")
    lines = lines[0, 2]

    inner_y = y + 6
    inner_h = Graphics.height - y - 12
    line_h = 32
    total_h = lines.length * line_h
    text_y = inner_y + ((inner_h - total_h) / 2)

    lines.each_with_index do |line, i|
      ty = text_y + (i * line_h)

      pbDrawShadowText(
        bitmap,
        18,
        ty,
        Graphics.width - 36,
        line_h,
        line.to_s,
        TEXT_DARK,
        Color.new(214, 196, 164),
        0
      )
    end
  end

  def refresh_idle_path_animation
    return if !@sprites
    return if !@sprites["pulse"]
    return if @sprites["pulse"].disposed?

    bitmap = @sprites["pulse"].bitmap
    return if !bitmap
    bitmap.clear

    @tournament.rounds.each do |round|
      round.each do |match|
        next if !match.finished?
        next if @hidden_result_keys[match.key]

        segments = winner_segments(match)
        draw_moving_route_squares(bitmap, segments) if !segments.empty?
      end
    end
  end

  # One repeating stream is measured across the ENTIRE polyline. The spacing
  # therefore continues naturally around corners instead of restarting on each
  # horizontal/vertical segment.


  def draw_moving_route_squares(bitmap, segments)
    spacing = PATH_PULSE_GAP
    phase   = @path_phase % spacing

    lengths = []
    total_length = 0
    segments.each do |seg|
      x1, y1, x2, y2 = seg
      len = (x2 - x1).abs + (y2 - y1).abs
      lengths << len
      total_length += len
    end
    return if total_length <= 0

    assets = ["pulse_bright", "pulse_mid", "pulse_dark"]

    distance = phase
    pulse_index = 0

    while distance <= total_length
      remaining = distance
      px = nil
      py = nil

      segments.each_with_index do |seg, i|
        x1, y1, x2, y2 = seg
        len = lengths[i]

        if remaining <= len
          if x1 == x2
            dir = (y2 >= y1) ? 1 : -1
            px = x1
            py = y1 + remaining * dir
          else
            dir = (x2 >= x1) ? 1 : -1
            px = x1 + remaining * dir
            py = y1
          end
          break
        end
        remaining -= len
      end

      if !px.nil? && !py.nil?
        tile = ui_asset(assets[pulse_index % assets.length])
        bitmap.blt(
          snap2(px - (PATH_PULSE_SIZE / 2)),
          snap2(py - (PATH_PULSE_SIZE / 2)),
          tile,
          Rect.new(0, 0, tile.width, tile.height)
        )
      end

      pulse_index += 1
      distance += spacing
    end
  end

  def animate_results
    @results.each_with_index do |match, i|
      winner = match.winner

      @focus_match = match
      @message = match.entrant1.name + " vs. " + match.entrant2.name + "!"
      animate_nameplates(true)

      wait_frames(12)
      wait_for_continue

      @message = winner.name + " wins!"
      refresh
      BushidoTournament.play_ui_se(BushidoTournament::SE_RESULT, 85, 100)

      wait_frames(10)
      animate_result_impact(match)
      wait_frames(12)

      animate_nameplates(false)
      @focus_match = nil

      # Immediately grey the defeated route on the BASE bracket.
      # The winning route remains white until the orange progression covers it.
      @animating_result_match = match
      refresh
      wait_frames(12)

      # Draw the winning route. animate_match_result deliberately leaves its
      # final overlay intact rather than clearing it.
      animate_match_result(match)

      # Commit the real finished state underneath that identical final overlay.
      # Since no Graphics.update occurs between commit and overlay clear, there
      # is no white/grey/red flash or redraw visible to the player.
      @hidden_result_keys.delete(match.key)
      @animating_result_match = nil
      @impact_loser = nil
      @impact_winner = nil

      refresh
      BushidoTournament.play_ui_se(BushidoTournament::SE_ROUTE_COMPLETE, 80, 100)

      wait_frames(30)
      wait_for_continue if i < @results.length - 1
    end

    @focus_match = nil
    @nameplate_slide = 0.0
    @nameplate_left_slide = 0.0
    @nameplate_right_slide = 0.0
    @animating_result_match = nil
    refresh
  end

  def animate_nameplates(show)
    total_frames = 14
    delay = 2

    BushidoTournament.play_ui_se(
      show ? BushidoTournament::SE_NAMEPLATE_IN : BushidoTournament::SE_NAMEPLATE_OUT,
      80,
      100
    )

    total_frames.times do |i|
      if show
        lt = [[(i + 1).to_f / (total_frames - delay), 0.0].max, 1.0].min
        rt = [[(i + 1 - delay).to_f / (total_frames - delay), 0.0].max, 1.0].min
      else
        lt = [[(i + 1 - delay).to_f / (total_frames - delay), 0.0].max, 1.0].min
        rt = [[(i + 1).to_f / (total_frames - delay), 0.0].max, 1.0].min
      end

      lt = lt * lt * (3.0 - 2.0 * lt)
      rt = rt * rt * (3.0 - 2.0 * rt)

      @nameplate_left_slide  = show ? lt : (1.0 - lt)
      @nameplate_right_slide = show ? rt : (1.0 - rt)
      @nameplate_slide = [@nameplate_left_slide, @nameplate_right_slide].max

      refresh
      Graphics.update
      Input.update
      update_sprites
    end

    final = show ? 1.0 : 0.0
    @nameplate_left_slide  = final
    @nameplate_right_slide = final
    @nameplate_slide       = final
    refresh
  end

  def wait_frames(frames)
    frames.times do
      Graphics.update
      Input.update
      update_sprites
    end
  end


  def wait_for_continue
    4.times do
      Graphics.update
      Input.update
      update_sprites
    end

    @continue_visible = true
    @continue_tick = 0
    if @sprites["continue"]
      @sprites["continue"].src_rect.set(0, 0, 32, 32)
      @sprites["continue"].visible = true
    end

    loop do
      Graphics.update
      Input.update
      update_sprites
      break if Input.trigger?(Input::C) || Input.trigger?(Input::B)
    end

    @continue_visible = false
    if @sprites["continue"]
      @sprites["continue"].visible = false
    end
  end


  def animate_current_match_reveal(require_input = true)
    match = @tournament.player_match
    return if !match

    @focus_match = match
    @message = match.entrant1.name + " vs. " + match.entrant2.name + "!"
    @nameplate_left_slide  = 0.0
    @nameplate_right_slide = 0.0

    # MATCH mode normally renders from player_match directly; temporarily use
    # RESULT-style focus drawing so this helper can also work in OPENING_MATCH.
    old_mode = @mode
    @mode = :RESULTS
    animate_nameplates(true)

    if require_input
      wait_for_continue
    else
      wait_frames(36)
    end

    animate_nameplates(false)
    @mode = old_mode
    @focus_match = nil
    refresh
  end


  def animate_next_match_reveal
    match = @tournament.player_match
    return if !match

    @focus_match = nil
    @message =
      if match.round == 2
        _INTL("The Grand Final is set!")
      else
        _INTL("Your next match is set!")
      end

    refresh
    wait_frames(36)

    @focus_match = match
    @message = match.entrant1.name + " vs. " + match.entrant2.name + "!"
    @nameplate_left_slide  = 0.0
    @nameplate_right_slide = 0.0

    animate_nameplates(true)

    # Give the reveal time to land before prompting.
    wait_frames(24)
    wait_for_continue

    animate_nameplates(false)

    @focus_match = nil
    refresh
    wait_frames(12)
  end


  def animate_result_impact(match)
    winner = match.winner
    loser = (match.entrant1 == winner) ? match.entrant2 : match.entrant1

    winner_slot = @tournament.entrants.index(winner)
    loser_slot  = @tournament.entrants.index(loser)

    winner_spr = winner_slot.nil? ? nil : @sprites["portrait#{winner_slot}"]
    loser_spr  = loser_slot.nil? ? nil : @sprites["portrait#{loser_slot}"]

    @impact_winner = winner
    @impact_loser  = loser

    BushidoTournament.play_ui_se(BushidoTournament::SE_ELIMINATED, 75, 100)

    # Let the winner announcement sit before the physical impact.
    wait_frames(10)

    # Winner gets a longer, readable gold flash + 2px lift.
    if winner_spr
      home_x, home_y = @portrait_home[winner_slot]

      8.times do |i|
        winner_spr.y = home_y - 2
        winner_spr.tone = Tone.new(72, 58, 12, 0)
        Graphics.update
        Input.update
        update_sprites
      end

      6.times do
        winner_spr.y = home_y
        winner_spr.tone = Tone.new(24, 18, 4, 0)
        Graphics.update
        Input.update
        update_sprites
      end

      winner_spr.x = home_x
      winner_spr.y = home_y
      winner_spr.tone = Tone.new(0, 0, 0, 0)
    end

    # Loser gets a more obvious shake, then visibly settles into elimination.
    if loser_spr
      home_x, home_y = @portrait_home[loser_slot]

      offsets = [-4, 4, -4, 4, -2, 2, -2, 2, 0]
      offsets.each do |off|
        loser_spr.x = home_x + off
        Graphics.update
        Input.update
        update_sprites
      end

      loser_spr.x = home_x
      loser_spr.y = home_y
    end

    # Pause on winner bright / loser darkened so the result actually registers.
    refresh
    wait_frames(24)
  end


  def animate_opening
    BushidoTournament.play_ui_se(BushidoTournament::SE_OPEN, 85, 100)

    # start_scene already prepared the portraits offscreen and hid the bracket
    # BEFORE the entry fade. We can animate immediately without a visual reset.
    12.times do |frame|
      t = (frame + 1).to_f / 12
      eased = t * t * (3.0 - 2.0 * t)

      8.times do |i|
        spr = @sprites["portrait#{i}"]
        next if !spr
        home_x, home_y = @portrait_home[i]
        start_x = home_x + (i < 4 ? -24 : 24)
        spr.x = snap2(start_x + ((home_x - start_x) * eased))
        spr.y = snap2(home_y + (4 * (1.0 - eased)))
        spr.opacity = (255 * eased).to_i
      end

      Graphics.update
      Input.update
      update_sprites
    end

    BushidoTournament.play_ui_se(BushidoTournament::SE_PORTRAIT_IN, 70, 100)

    # Draw the white bracket in from both sides while the base version remains
    # hidden. No fully-built template is shown before this point.
    temp = Bitmap.new(Graphics.width, Graphics.height)
    old_hide_paths = @hide_paths
    @hide_paths = false
    draw_all_paths(temp)
    @hide_paths = old_hide_paths

    over = @sprites["overlay"].bitmap

    18.times do |frame|
      over.clear
      t = (frame + 1).to_f / 18
      reveal = (center_x * t).to_i

      if reveal > 0
        over.blt(0, 0, temp, Rect.new(0, 0, reveal, field_bottom))
        over.blt(
          Graphics.width - reveal,
          0,
          temp,
          Rect.new(Graphics.width - reveal, 0, reveal, field_bottom)
        )
      end

      Graphics.update
      Input.update
      update_sprites
    end
    temp.dispose

    # Commit the bracket underneath the completed overlay, then clear the
    # overlay without ever showing a blank frame.
    @hide_paths = false
    refresh
    Graphics.update
    Input.update
    update_sprites

    # Crest stamp.
    @hide_crown = true
    refresh
    over = @sprites["overlay"].bitmap

    10.times do |frame|
      over.clear
      size = frame < 5 ? 4 + frame * 4 : 20 - (frame - 5) * 2
      size = [size, 8].max
      blit_tiled_rect(over, center_x - size, final_y - 2, size * 2, 4, "gold_tile")
      blit_tiled_rect(over, center_x - 2, final_y - size, 4, size * 2, "gold_tile")
      Graphics.update
      Input.update
      update_sprites
    end

    @hide_crown = false
    refresh
  end

  def animate_finale
    champion = @tournament.champion
    return if !champion

    BushidoTournament.play_ui_se(BushidoTournament::SE_CHAMPION, 90, 100)

    over = @sprites["overlay"].bitmap

    # Let the completed bracket breathe before the celebration starts.
    wait_frames(24)

    # Three slower crest pulses.
    3.times do
      8.times do |i|
        over.clear
        radius = 8 + (i * 3)
        blit_tiled_rect(over, center_x - radius, final_y - 2, radius * 2, 4, "gold_tile")
        blit_tiled_rect(over, center_x - 2, final_y - radius, 4, radius * 2, "gold_tile")
        Graphics.update
        Input.update
        update_sprites
      end

      6.times do |i|
        over.clear
        radius = 29 - (i * 3)
        radius = 10 if radius < 10
        blit_tiled_rect(over, center_x - radius, final_y - 2, radius * 2, 4, "gold_tile")
        blit_tiled_rect(over, center_x - 2, final_y - radius, 4, radius * 2, "gold_tile")
        Graphics.update
        Input.update
        update_sprites
      end

      over.clear
      wait_frames(6)
    end

    # Champion sprite rises in more slowly.
    champ = TournamentTrainerSprite.new(@viewport, champion)
    if champ.graphic_loaded?
      champ.x = center_x - (champ.frame_width / 2)
      target_y = final_y - champ.frame_height - 10
      champ.y = target_y + 12
      champ.z = 20
      champ.opacity = 0
      @sprites["champion"] = champ

      20.times do |i|
        t = (i + 1).to_f / 20
        eased = t * t * (3.0 - 2.0 * t)
        champ.y = snap2(target_y + (12 * (1.0 - eased)))
        champ.opacity = (255 * eased).to_i
        Graphics.update
        Input.update
        update_sprites
      end
    end

    # Hold on the champion. The continue arrow makes it explicit that the
    # player controls when the celebration is finished.
    wait_frames(30)
    wait_for_continue
  end


  def animate_match_result(match)
    segments = winner_segments(match)
    return if segments.empty?

    overlay = @sprites["overlay"].bitmap
    lengths = []
    total_length = 0

    segments.each do |seg|
      x1, y1, x2, y2 = seg
      len = (x2 - x1).abs + (y2 - y1).abs
      lengths << len
      total_length += len
    end
    return if total_length <= 0

    frames = [total_length / 4, 22].max

    frames.times do |frame|
      overlay.clear

      progress = (frame + 1).to_f / frames
      reveal_distance = (total_length * progress).to_i
      remaining = reveal_distance
      revealed_segments = []

      segments.each_with_index do |seg, i|
        break if remaining <= 0
        len = lengths[i]

        if remaining >= len
          revealed_segments << seg
          remaining -= len
        else
          revealed_segments << partial_segment(seg, remaining)
          remaining = 0
        end
      end

      revealed_segments.each do |seg|
        draw_segment(overlay, *seg, BushidoTournament::PATH_RED, false)
      end
      draw_moving_route_squares(overlay, revealed_segments) if !revealed_segments.empty?

      if frame > 0 && frame % 9 == 0
        BushidoTournament.play_ui_se(BushidoTournament::SE_ROUTE_TICK, 55, 100)
      end

      Graphics.update
      Input.update
      update_sprites
    end

    # IMPORTANT: leave the fully-drawn winner route on the overlay.
    # animate_results commits the same route to the base immediately afterward,
    # preventing the old "draw -> disappear -> redraw" flash.
  end

  def partial_segment(seg, distance)
    x1, y1, x2, y2 = seg
    distance = [distance.to_i, 0].max

    if x1 == x2
      direction = (y2 >= y1) ? 1 : -1
      ny = y1 + (distance * direction)
      if direction > 0
        ny = [ny, y2].min
      else
        ny = [ny, y2].max
      end
      return [x1, y1, x2, ny]
    else
      direction = (x2 >= x1) ? 1 : -1
      nx = x1 + (distance * direction)
      if direction > 0
        nx = [nx, x2].min
      else
        nx = [nx, x2].max
      end
      return [x1, y1, nx, y2]
    end
  end

  def winner_segments(match)
    winner = match.winner
    return [] if !winner
    if match.round == 0
      slot = @tournament.slot_for(winner.id)
      left = slot < 4
      match_index = match.index
      pair = case match_index
             when 0 then [0, 1]
             when 1 then [2, 3]
             when 2 then [4, 5]
             else [6, 7]
             end
      y = slot_center_y(slot)
      ym = (slot_center_y(pair[0]) + slot_center_y(pair[1])) / 2
      xa = left ? left_entry_x : right_entry_x
      xm = left ? left_merge_x : right_merge_x
      xo = left ? left_semi_x : right_semi_x
      return [[xa, y, xm, y], [xm, y, xm, ym], [xm, ym, xo, ym]]
    elsif match.round == 1
      left = match.index == 0
      ytop = left ? round1_mid_y(0) : round1_mid_y(2)
      ybot = left ? round1_mid_y(1) : round1_mid_y(3)
      top_winner = left ? @tournament.rounds[0][0].winner : @tournament.rounds[0][2].winner
      y = (winner == top_winner) ? ytop : ybot
      ym = (ytop + ybot) / 2
      xin = left ? left_semi_x : right_semi_x
      xmid = left ? (center_x - 35) : (center_x + 35)
      return [[xin, y, xmid, y], [xmid, y, xmid, ym], [xmid, ym, center_x, ym]]
    end
    return []
  end
end
