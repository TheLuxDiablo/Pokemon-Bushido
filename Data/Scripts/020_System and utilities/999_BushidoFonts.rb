#===============================================================================
# Bushido Fonts
# Global typography system for Pokemon Bushido v2.0.0
#
# Pokemon Essentials v18.1 / RPG Maker XP / MKXP
#
# These font/size combinations were tested directly in Bushido and confirmed
# to render crisply in both windowed and fullscreen modes.
#
# Verified crisp configurations:
#   Power Clear       @ 31
#   Power Clear       @ 16
#   Power Green Small @ 25
#   Power Green Small @ 12
#
# Base usage:
#   BushidoFonts.apply(bitmap, :system)
#   BushidoFonts.apply(bitmap, :system_small)
#   BushidoFonts.apply(bitmap, :compact)
#   BushidoFonts.apply(bitmap, :compact_small)
#
# Semantic aliases can also be used:
#   BushidoFonts.apply(bitmap, :title)
#   BushidoFonts.apply(bitmap, :body)
#   BushidoFonts.apply(bitmap, :label)
#   BushidoFonts.apply(bitmap, :caption)
#===============================================================================

module BushidoFonts

  #-----------------------------------------------------------------------------
  # Verified crisp font configurations
  #
  # Keep these as the actual source-of-truth presets.
  #-----------------------------------------------------------------------------
  PRESETS = {
    :system        => ["Power Clear",       31],
    :system_small  => ["Power Green Small", 25],
    :compact       => ["Power Clear",       16],
    :compact_small => ["Power Green Small", 12]
  }

  #-----------------------------------------------------------------------------
  # Semantic aliases
  #
  # These let custom Bushido UI describe intent rather than hard-coded sizes.
  # They can be remapped later without rewriting every screen.
  #-----------------------------------------------------------------------------
  ALIASES = {
    :title   => :system,
    :body    => :system,
    :label   => :system_small,
    :small   => :system_small,
    :caption => :compact_small
  }

  #-----------------------------------------------------------------------------
  # Resolve a preset or semantic alias.
  #-----------------------------------------------------------------------------
  def self.resolve(preset)
    resolved = ALIASES[preset] || preset
    config = PRESETS[resolved]

    if !config
      raise "Unknown Bushido font preset: #{preset}"
    end

    return config
  end

  #-----------------------------------------------------------------------------
  # Apply a Bushido typography preset to a Bitmap.
  #-----------------------------------------------------------------------------
  def self.apply(bitmap, preset)
    config = resolve(preset)

    bitmap.font.name   = config[0]
    bitmap.font.size   = config[1]
    bitmap.font.bold   = false
    bitmap.font.italic = false

    return bitmap
  end

  #-----------------------------------------------------------------------------
  # Return the font face used by a preset.
  #-----------------------------------------------------------------------------
  def self.font_name(preset)
    return resolve(preset)[0]
  end

  #-----------------------------------------------------------------------------
  # Return the font size used by a preset.
  #-----------------------------------------------------------------------------
  def self.font_size(preset)
    return resolve(preset)[1]
  end

end


#===============================================================================
# Essentials Compatibility
#
# Redirect the stock Essentials helpers through BushidoFonts so existing menus
# inherit the verified crisp system typography automatically.
#===============================================================================

def pbSetSystemFont(bitmap)
  BushidoFonts.apply(bitmap, :system)
end

def pbSetSmallFont(bitmap)
  BushidoFonts.apply(bitmap, :system_small)
end