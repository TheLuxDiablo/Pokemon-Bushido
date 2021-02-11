module PBDayNight
  HourlyTones = [
    Tone.new(-50, -50, -5,  80),   # Night           # Midnight *
    Tone.new(-50, -50, -5,  80),   # Night           # 1AM
    Tone.new(-50, -50, -5,  80),   # Night           # 2AM
    Tone.new(-50, -50, -5,  80),   # Night           # 3AM
    Tone.new(-35, -35, 15,  60),   # Night           # 4AM
    Tone.new(-25, -25,  5,  60),   # Day/morning     # 5AM
    Tone.new(-25, -25,  5,  60),   # Day/morning     # 6AM *
    Tone.new(-25, -25,  5,  60),   # Day/morning     # 7AM
    Tone.new( -5,  -5,  0,  10),   # Day/morning     # 8AM
    Tone.new( -5,  -5,  0,  10),   # Day/morning     # 9AM
    Tone.new( -5,  -5,  0,  10),   # Day             # 10AM
    Tone.new( -5,  -5,  0,  10),   # Day             # 11AM
    Tone.new(  0,   0,   0,  0),   # Day             # Noon *
    Tone.new(  0,   0,   0,  0),   # Day             # 1PM
    Tone.new(  0,   0,   0,  0),   # Day/afternoon   # 2PM
    Tone.new(  0,   0,   0,  0),   # Day/afternoon   # 3PM
    Tone.new(  0,  -5,  -5, 10),   # Day/afternoon   # 4PM
    Tone.new(  5, -10,-30,  15),   # Day/afternoon   # 5PM
    Tone.new( 10, -35,-35,  75),   # Day/evening     # 6PM *
    Tone.new(-30, -30,  0,  60),   # Day/evening     # 7PM
    Tone.new(-50, -50, -5,  80),   # Day/evening     # 8PM
    Tone.new(-50, -50, -5,  80),   # Night           # 9PM
    Tone.new(-50, -50, -5,  80),   # Night           # 10PM
    Tone.new(-50, -50, -5,  80)    # Night           # 11PM
  ]
end

PluginManager.register({
  :name => "Gen 4 Day and Night Tones",
  :credits => ["VanillaSunshine"],
})
