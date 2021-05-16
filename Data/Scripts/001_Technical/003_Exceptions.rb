#===============================================================================
# Exceptions and critical code
#===============================================================================
class Reset < Exception
end



def pbGetExceptionMessage(e,_script="")
  emessage = e.message.dup
  emessage.force_encoding(Encoding::UTF_8)
  if e.is_a?(Hangup)
    emessage = "The script is taking too long. The game will restart."
  elsif e.is_a?(Errno::ENOENT)
    filename = emessage.sub("No such file or directory - ", "")
    emessage = "File #{filename} not found."
  end
  if emessage && !safeExists?("Game.rgssad")
    emessage = emessage.gsub(/uninitialized constant PBItems\:\:(\S+)/) {
       "The item '#{$1}' is not valid. Please add the item\r\nto the list of items in the editor. See the wiki for more information." }
    emessage = emessage.gsub(/undefined method `(\S+?)' for PBItems\:Module/) {
       "The item '#{$1}' is not valid. Please add the item\r\nto the list of items in the editor. See the wiki for more information." }
    emessage = emessage.gsub(/uninitialized constant PBTypes\:\:(\S+)/) {
       "The type '#{$1}' is not valid. Please add the type\r\nto the PBS/types.txt file." }
    emessage = emessage.gsub(/undefined method `(\S+?)' for PBTypes\:Module/) {
       "The type '#{$1}' is not valid. Please add the type\r\nto the PBS/types.txt file." }
    emessage = emessage.gsub(/uninitialized constant PBTrainers\:\:(\S+)$/) {
       "The trainer type '#{$1}' is not valid. Please add the trainer\r\nto the list of trainer types in the Editor. See the wiki for\r\nmore information." }
    emessage = emessage.gsub(/undefined method `(\S+?)' for PBTrainers\:Module/) {
       "The trainer type '#{$1}' is not valid. Please add the trainer\r\nto the list of trainer types in the Editor. See the wiki for\r\nmore information." }
    emessage = emessage.gsub(/uninitialized constant PBSpecies\:\:(\S+)$/) {
       "The Pokemon species '#{$1}' is not valid. Please\r\nadd the species to the PBS/pokemon.txt file.\r\nSee the wiki for more information." }
    emessage = emessage.gsub(/undefined method `(\S+?)' for PBSpecies\:Module/) {
       "The Pokemon species '#{$1}' is not valid. Please\r\nadd the species to the PBS/pokemon.txt file.\r\nSee the wiki for more information." }
  end
  emessage.gsub!(/Section(\d+)/) { $RGSS_SCRIPTS[$1.to_i][1] } rescue nil
  return emessage
end

def pbPrintException(e)
  premessage = "\r\n=================\r\n\r\n[#{Time.now}]\r\n"
  emessage = ""
  if $EVENTHANGUPMSG && $EVENTHANGUPMSG!=""
    emessage = $EVENTHANGUPMSG   # Message with map/event ID generated elsewhere
    $EVENTHANGUPMSG = nil
  else
    emessage = pbGetExceptionMessage(e)
  end
  btrace = ""
  if e.backtrace
    maxlength = ($INTERNAL) ? 25 : 10
    e.backtrace[0,maxlength].each { |i| btrace += "#{i}\r\n" }
  end
  btrace.gsub!(/Section(\d+)/) { $RGSS_SCRIPTS[$1.to_i][1] }  rescue nil
  #message = "[Pokémon Essentials version #{ESSENTIALS_VERSION}]\r\n"
  message = "#{ERROR_TEXT}"   # For third party scripts to add to
  message += "[#{System.game_title} v#{GAME_VERSION}]\r\n"
  message += "Exception: #{e.class}\r\n"
  message += "Message: #{emessage}\r\n"
  message += "\r\nBacktrace:\r\n#{btrace}"
  errorlog = "errorlog.txt"
  File.open(errorlog,"ab") { |f| f.write(premessage); f.write(message) }
  errorlogline = errorlog
  errorlogline.sub!(Dir.pwd + "/", "")
  errorlogline.sub!(pbGetUserName, "USERNAME")
  errorlogline = "\r\n" + errorlogline if errorlogline.length > 20
  errorlogline.gsub!("/", "\\") if System.platform[/Windows/]
  print("#{message}\r\nThis exception was logged in #{errorlogline}.\r\nHold Ctrl after closing this message to copy it to the clipboard.")
  # Give a ~500ms coyote time to start holding Control
  (0.5 / (1.0 / Graphics.frame_rate)).ceil.times{
    Graphics.update
    Input.update
    if Input.press?(Input::CTRL)
      Input.clipboard = message
      break
    end
  }
end

def pbCriticalCode
  ret = 0
  begin
    yield
    ret = 1
  rescue Exception
    e = $!
    if e.is_a?(Reset) || e.is_a?(SystemExit)
      raise
    else
      pbPrintException(e)
      if e.is_a?(Hangup)
        ret = 2
        raise Reset.new
      end
    end
  end
  return ret
end
