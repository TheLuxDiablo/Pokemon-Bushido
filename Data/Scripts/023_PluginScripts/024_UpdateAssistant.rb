def pbCheckForUpdates(trainer = nil)
  echo "Checking for updates..."
  # Offline Save Version
  str = trainer ? trainer.save_version : GAME_VERSION
  # Online Game Real Version
  gvr = pbDownloadToString("https://pastebin.com/raw/zsXnmekq")
  return if nil_or_empty?(gvr)
  if PluginManager.compare_versions(str,gvr) < 0
    emsg = "You are currently running v\\PN of the game, which is an outdated version. The latest version of the game is v#{gvr}."
    emsg.gsub!(/\\PN/,str)
    if !$shown
      pbMessage("Checking for updates...\\wt[16] ...\\wt[16] ...\\wtnp[32]\\se[Battle ball drop]\\wtnp[30]")
      pbMessage(emsg)
      pbMessage("The game will now close and you will be redirected to the the official Relic Castle Page to download the update.\\wtnp[15].\\wtnp[15].\\wtnp[15]")
      $shown = true
    end
    System.launch("https://reliccastle.com/threads/3558/")
    exit!
  elsif PluginManager.compare_versions(str,gvr) > 0
    PluginManager.error("Stop manipulating the game's files, you muppet.")
  end
  echoln "done"
end

pbCheckForUpdates
