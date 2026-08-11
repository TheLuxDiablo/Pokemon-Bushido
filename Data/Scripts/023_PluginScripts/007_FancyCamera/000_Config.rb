#===============================================================================
# FancyCamera - Pokemon Essentials v18.1 Port
# Original plugin by ENLS
# v18.1 compatibility port for Pokemon Bushido
#===============================================================================

class FancyCamera
  # Default camera interpolation speed.
  DEFAULT_SPEED = 1.0

  # Kept for compatibility with ENLS's config/API.
  # The v18 port does not override Bushido's movement charset logic.
  INCREASE_WHEN_RUNNING = true

  # Override RPG Maker's Scroll Map event command.
  OVERRIDE_SCROLL_MAP = true
end
