#-------------------------------------------------------------------------------
# Configuration
#-------------------------------------------------------------------------------
module GameUpdateCheck
  CHECK_URL      = "https://raw.githubusercontent.com/TheLuxDiablo/Pokemon-Bushido/refs/heads/master/Data/Scripts/001_Settings.rb"
  DOWNLOAD_URL   = "https://eeveeexpo.com/bushido/"

  CHECK_IN_DEBUG = true
end

#-------------------------------------------------------------------------------
# Script
#-------------------------------------------------------------------------------
module GameUpdateCheck
  @shown = false

  def self.online_version
    content = pbDownloadToString(CHECK_URL)
    return nil if nil_or_empty?(content)
    if content =~ /GAME_VERSION\s*=\s*["']([^"']+)["']/i
      return $1.strip
    end
    cleaned = content.strip
    return cleaned if cleaned =~ /^v?\d+(\.\d+)*$/i
    return nil
  end

  def self.run
    return if !CHECK_IN_DEBUG && $DEBUG
    echoln "Checking for updates..."
    current_version = GAME_VERSION
    online_version = self.online_version
    return if nil_or_empty?(online_version)
    online_version = online_version.strip
    if PluginManager.compare_versions(current_version, online_version) < 0
      if !@shown
        @shown = true
        pbMessage(_INTL("You are currently running v{1} of the game. The latest version is v{2}.", current_version, online_version))
        pbMessage(_INTL("For the best experience, please consider updating to the latest version."))
        if DOWNLOAD_URL && !DOWNLOAD_URL.empty?
          if pbConfirmMessage(_INTL("Would you like to open the download page in your web browser?"))
            System.launch(DOWNLOAD_URL)
          end
        end
      end
    end
    echoln "Update check complete."
  rescue => e
    echoln "Error checking for updates: #{e.message}"
  end
end

GameUpdateCheck.run
