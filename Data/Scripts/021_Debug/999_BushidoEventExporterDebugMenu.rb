#===============================================================================
# Bushido Event Exporter - Debug Menu Integration
# Pokemon Bushido / Essentials v18.1
#
# Requires:
#   997_BushidoEventExporter.rb
#   998_BushidoEventExporterUI.rb
#
# Adds:
#   Debug Menu
#     -> Information editors...
#        -> Event Exporter
#===============================================================================


#===============================================================================
# Extend pbDebugMenuCommands
#===============================================================================

unless defined?(bushido_event_exporter_pbDebugMenuCommands)

  alias bushido_event_exporter_pbDebugMenuCommands pbDebugMenuCommands

  def pbDebugMenuCommands(showall=true)
    commands = bushido_event_exporter_pbDebugMenuCommands(showall)

    commands.add(
      "editorsmenu",
      "eventexporter",
      _INTL("Event Exporter"),
      _INTL(
        "Browse maps and export individual events or entire maps " +
        "as readable text files."
      )
    )

    return commands
  end

end


#===============================================================================
# Extend pbDebugMenuActions
#===============================================================================

unless defined?(bushido_event_exporter_pbDebugMenuActions)

  alias bushido_event_exporter_pbDebugMenuActions pbDebugMenuActions

  def pbDebugMenuActions(cmd="", sprites=nil, viewport=nil)

    #-------------------------------------------------------------------------
    # Bushido Event Exporter
    #-------------------------------------------------------------------------

    if cmd == "eventexporter"

      # Hide the existing Debug Menu while the exporter owns the screen.
      if sprites
        pbFadeOutAndHide(sprites) {
          pbUpdateSpriteHash(sprites)
        }
      end

      begin
        BushidoEventExporterUI.open
      rescue => e
        # If the exporter itself fails, make sure the Debug Menu can still
        # come back rather than leaving the player on a blank screen.
        if sprites
          pbFadeInAndShow(sprites) {
            pbUpdateSpriteHash(sprites)
          }
        end

        pbMessage(
          _INTL(
            "Event Exporter failed.\n\n{1}: {2}",
            e.class.to_s,
            e.message.to_s
          )
        )

        return false
      end

      # Restore the existing Debug Menu after leaving the exporter.
      if sprites
        pbFadeInAndShow(sprites) {
          pbUpdateSpriteHash(sprites)
        }
      end

      # false means:
      # "Keep the Debug Menu open."
      return false
    end


    #-------------------------------------------------------------------------
    # Everything else uses the original Essentials/Bushido action handler.
    #-------------------------------------------------------------------------

    return bushido_event_exporter_pbDebugMenuActions(
      cmd,
      sprites,
      viewport
    )
  end

end