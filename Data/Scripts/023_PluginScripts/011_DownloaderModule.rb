#===============================================================================
# ** Downloader Module
#  module by Luka S.J.
#
#  Enjoy the script, and make sure to give credit!
#-------------------------------------------------------------------------------
# Uses Berka's HTTP script (with modifications)
#===============================================================================
# set up plugin metadata
if defined?(PluginManager)
  PluginManager.register({
    :name => "Downloader Module",
    :version => "1.0",
    :credits => ["Luka S.J."],
    :link => "https://luka-sj.com/res/dlmd"
  })
end
#===============================================================================
module Downloader
  #-----------------------------------------------------------------------------
  #  returns ratio of downloaded files
  #-----------------------------------------------------------------------------
  def self.files?
    return Net::HTTP.files?
  end
  #-----------------------------------------------------------------------------
  #  Checks if any file is currently being downloaded
  #-----------------------------------------------------------------------------
  def self.downloading?
    return !Net::HTTP.finished?
  end
  #-----------------------------------------------------------------------------
  #  Main module update loop
  #-----------------------------------------------------------------------------
  def self.update(*args, &block)
    Net::HTTP.update
    block.call(*args) if !block.nil? && block.respond_to?(:call)
  end
  #-----------------------------------------------------------------------------
  #  Return the current downloading progress (as a percentage)
  #-----------------------------------------------------------------------------
  def self.progress?
    return Net::HTTP.progress
  end
  #-----------------------------------------------------------------------------
  #  Adds file to download queue
  #-----------------------------------------------------------------------------
  def self.download(url, filename, string = false)
    Net::HTTP.refresh
    Net::HTTP.download(url, filename, string)
  end
  #-----------------------------------------------------------------------------
  #  Stores the last downloaded ret
  #-----------------------------------------------------------------------------
  def self.output?
    return Net::HTTP.output?
  end
  #-----------------------------------------------------------------------------
  #  To replace pbDownloadToString
  #-----------------------------------------------------------------------------
  def self.toString(url, *args, &block)
    self.download(url, "", true)
    loop do
      Graphics.update
      256.times do; self.update; end
      block.call(*args) if !block.nil? && block.respond_to?(:call)
      break if !self.downloading?
    end
    return self.output?
  end
  #-----------------------------------------------------------------------------
  #  To replace pbDownloadToFile
  #-----------------------------------------------------------------------------
  def self.toFile(url, file, *args, &block)
    self.download(url, file)
    loop do
      Graphics.update(false)
      256.times do; self.update; end
      block.call(*args) if !block.nil? && block.respond_to?(:call)
      break if !self.downloading?
    end
    return self.output?
  end
  #-----------------------------------------------------------------------------
  #  Gets the list of all the directories and files at URL
  #-----------------------------------------------------------------------------
  def self.getContent(url)
    s = self.toString(url)
    lines = s.split("\n")
    files = []
    for line in lines
      next if !line.include?("<tr><td valign=\"top\">")
      next if line.include?("[PARENTDIR]")
      f = line.split("<a href=\"")[1]
      f = f.split("\">")[0]
      files.push(f)
    end
    return files
  end
  #-----------------------------------------------------------------------------
  #  Evaluates script at url
  #-----------------------------------------------------------------------------
  def self.run(url)
    script = self.toString(url)
    eval(script, TOPLEVEL_BINDING)
  end
end
#-------------------------------------------------------------------------------
# Processes download in the background with each frame update
#-------------------------------------------------------------------------------
module Graphics
  class << Graphics
    alias update_downloader update unless self.method_defined?(:update_downloader)
  end

  def self.update(download = true)
    update_downloader
    Downloader.update if download
  end
end
#===============================================================================
#                   Download Files with RGSS
#  by Berka                      v 2.1                  rgss 1
#===============================================================================
# thanks to: http://www.66rpg.com for documentation on wininet
#===============================================================================
# Error messages
#-------------------------------------------------------------------------------
module Berka
  module NetError
    ErrConIn = "Unable to connect to Internet"
    ErrConFtp = "Unable to connect to Ftp"
    ErrConHttp = "Unable to connect to the Server"
    ErrNoFFtpIn = "The file to be downloadeded doesn't exist"
    ErrTranHttp = "Http Download failed"
    ErrDownFtp = "Ftp Download  failed"
    ErrNoFile = "No file to be downloaded"
  end
end
#-------------------------------------------------------------------------------
# Net::HTTP module for use with the above downloader module
#-------------------------------------------------------------------------------
module Net
  W = 'wininet'
  SPC = Win32API.new('kernel32','SetPriorityClass','pi','i').call(-1,128)
  IOA = Win32API.new(W,'InternetOpenA','plppl','l').call('',0,'','',0)
  IC = Win32API.new(W,'InternetConnectA','lplpplll','l')
  raise Berka::NetErrorErr::ConIn if IOA == 0
  module HTTP
    IOU = Win32API.new(W,'InternetOpenUrl','lppllp','l')
    IRF = Win32API.new(W,'InternetReadFile','lpip','l')
    ICH = Win32API.new(W,'InternetCloseHandle','l','l')
    HQI = Win32API.new(W,'HttpQueryInfo','llppp','i')
    CCD = Win32API.new(W,'DeleteUrlCacheEntry','p','l')
    @@output = ""
    @@time_out = Time.now
    module_function
    # calculates the current progress of all files
    def self.progress
      if @fich.length > 0
        fract = 1.0/@fich.length.to_f
      else
        fract = 1.0
      end
      loaded = 0
      total = 1.0
      for fich in @fich
        next if @read[fich].nil? || @size[fich].nil?
        if @finished && @finished[fich]
          # adds a whole fraction metric when file is complete
          loaded += fract
        else
          # calculates the percentage of files being downloaded
          s = 1; s = (@size[fich] > 0 ? @size[fich] : 1) if !@size[fich].nil?
          prog = (@read[fich].to_f/s.to_f)*fract
          prog = fract if prog > fract
          loaded += prog
        end
      end
      # returns the result
      return loaded.to_f/total.to_f
    end
    # returns the ratio of downloaded files
    def self.files?
      return 0 if !@finished
      return 0 if @finished.keys.length < 1
      f = 0
      for key in @finished.keys
        f += 1 if @finished[key]
      end
      return f.to_f/@finished.keys.length.to_f
    end
    # returns output if Downloader.toString
    def self.output?; return @@output; end
    # called to reset the local variables
    def self.refresh
      return if !self.finished?
      @dls = {}
      @finished = {}
      @started = {}
      @size = {}
      @read = {}
      @url = {}
      @int = {}
      @string = {}
      @txt = {}
      @fich = []
      @index = 0
      @indexes = 0
      @begun = false
      @@time_out = Time.now
    end
    # returns true if download process is completed
    def self.finished?
      ret = true
      if @finished
        for key in @finished.keys
          ret = false if !@finished[key]
        end
      end
      return ret
    end
    # main function to download files
    def self.download(url,int='./',string=false)
      return if url.nil?
      a = url.split('/')
      serv, root, fich = a[2], a[3..a.size].join('/'), @indexes
      @indexes += 1
      # error
      raise Berka::NetErrorErr::ErrNoFile if fich.nil?
      # logs the download
      @fich.push(fich)
      @finished[fich] = false
      @started[fich] = false
      @url[fich] = url
      @int[fich] = int
      @string[fich] = string
      # deletes existing file
      File.delete(int) if int && File.exist?(int)
    end
    # starts download from queue
    def self.start
      # failsafes first
      return if !@fich || !@fich.is_a?(Array) || @fich.length < 1
      fich = @fich[@index]
      url, int, string = @url[fich], @int[fich], @string[fich]
      return if url.nil?
      # data parsing
      a = url.split('/')
      serv, root = a[2], a[3..a.size].join('/')
      @txt = ''
      # opens file to write data to
      @file = File.open(int,'ab') if !string
      # deletes url cache
      # CCD.call(url)
      # calls the HTTP requests
      @dls[fich] = Thread.start(url,int,fich) {|url,int,fich|
        @fs = IOU.call(IOA, url, nil, 0, 0, 0)
        HQI.call(@fs, 5, k="\0"*1024, [k.size-1].pack('l'), nil)
        @read[fich] = 0
        @size[fich] = @fs
        # logs as started
        @started[fich] = true
      }
      @begun = true
    end
    # main update method for the threads
    def self.update
      self.start if !@begun
      return if !@fich || !@fich.is_a?(Array) || @fich.length < 1
      fich = @fich[@index]
      if @started[fich] == true && @finished[fich] == false
          # script hanging failsafe
          if Time.now > @@time_out + 2
            @@time_out = Time.now
            return
          end
          # buffer
          size = 1024
          buf, n = ' '*size, 0
          r = IRF.call(@fs, buf, size, o=[n].pack('i!'))
          n = o.unpack('i!')[0]
          # if all the data gets loaded
          if r&&n == 0
            self.conclude
            return
          end
          # pushes packets into main temp variable
          packet = buf[0,n]
          @txt << packet
          if !@string[fich]
            # writes to file procedurally
            @file.write(packet)
          end
          @read[fich] = @txt.size
      end
    end
    # finishes processing download
    def self.conclude
      return if !@fich || !@fich.is_a?(Array) || @fich.length < 1
      fich = @fich[@index]
      if @string[fich]
        # outputs downloaded chunks as string
        @@output = @txt
      else
        # closes file
        @file.close
      end
      # ends HTTP request
      ICH.call(@fs)
      # logs as finished
      @finished[fich] = true
      @index += 1
      self.refresh
      self.start
    end
  end
  #-----------------------------------------------------------------------------
end
