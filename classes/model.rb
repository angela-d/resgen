class ResgenModel

  def create
    @config = YAML.load_file('config.yml')
  end


  def firstrun

    require 'os'
    require 'pathname'

    # initialize variables we'll be sending to config.yml
    if OS.linux?
      # yeah, linux isn't an os, but this way we cover all the thousands of distributions without unnecessary overhead
      os          = 'linux'
      driver      = 'linux64'
      libreoffice = 'lowriter'
    elsif OS.mac?
      os          = 'mac'
      driver      = 'macos'
      obtain_path = %x(mdfind "kMDItemFSName = LibreOffice.app")
      exe_path    = obtain_path.split('\n').first.chomp
      libreoffice = File.join(exe_path, '/Contents/MacOS/soffice')
    elsif OS.windows?
      os          = 'windows'
      driver      = 'win64'
      libreoffice = "C:\\Program Files\\LibreOffice\\program\\soffice.exe"
    else
      view.os_detection_failed
      exit
    end

    # generate a set of config values unique to this user
    resgenpath = Pathname.new((File.dirname(__FILE__))).split.first.to_s

    open('config.yml', 'a') { |write|
      write << "\r# auto-generated values by resgen - delete everything below to reset your installation:\n"
      write << "resgenpath: #{resgenpath}/\n"
      write << "os: #{os}\n"
      write << "driver: #{driver}\n"
      write << "libreoffice: #{libreoffice}\n"
    }
  end


  def sanitize text
    # remove special characters, spaces & force case, so we have consistency for comparison on future applications
    text = text.strip.to_s.downcase

    rules = [
      [/[^0-9a-z ]/i, ''],
      [/\s/, '-'],
    ]

    result = rules.inject(text) do |clean, (before, after)|
     clean.gsub(before, after)
    end

    return result
  end


  def checkdir dir

    if Dir.exist?(dir)
      view.dir_exists

      if $stdin.getch == 'n'
        exit
      end
      # if n is not keyed, move on with the process

    else
      # create the directory
  		if @config['os'] == 'windows'
  			# windows doesn't interpret a relative path as a merge request, so special treatment is required..
        destdir   = dir.partition('/').first
        createdir = dir.partition('/').last

  			%x(cd "#{destdir}" && mkdir -p "#{createdir}")
  		else
  			Dir.mkdir dir
  		end
    end
  end


  def scrape url, fn

    # add our gecko driver to the env path
    ENV['PATH'] = "#{ENV['PATH']}#{File::PATH_SEPARATOR}#{@config['resgenpath'] + 'drivers/'+ @config['driver']}"

    headless = Selenium::WebDriver::Firefox::Options.new(args: ['--headless'])
    driver   = Selenium::WebDriver.for(:firefox, options: headless)

    driver.manage.timeouts.implicit_wait = 5
    driver.get("#{url}")

    save = File.new("#{fn}", "w")
    save.puts(driver.page_source)
    save.close

    driver.quit
  end


  def del fn
    File.delete("#{fn}")
  end


  def runproc proc
    if @config['os'] == 'windows'
      pid = %x(tasklist | find "#{proc}.bin").scan(/\d+/).first.to_i
    else
      pid = %x(pgrep "#{proc}").to_i
    end
      checkagain = false

    if pid > 0
      view.active_process
      checkagain = true
    end

    if checkagain == true and $stdin.getch != nil
      # one more check for libreoffice..
      if @config['os'] == 'windows'
        final = %x(tasklist | find "#{proc}").scan(/\d+/).first.to_i
      else
        final = %x(pgrep "#{proc}").to_i
      end

      # user is being a turd & disobeyed advice; forcefully terminate libreoffice
  		if @config['os'] == 'windows' && final > 0
  			# use window's taskkill to terminate, otherwise process exit is bugged out on ruby
  			%x(taskkill /pid "#{pid}" /f)
  		elsif final > 0
  		  begin
  			# an active libreoffice session prevents the pdfs from being generated
  			  Process.kill('QUIT', final)
  		  rescue Errno::ESRCH
  		  end
  		end
    end
  end

  def makepdf filename
    # invoke the dash shell to execute the built-in libreoffice odt -> pdf merge
      %x("#{@config['libreoffice']}" --headless --convert-to pdf --outdir "#{@config['resgenpath']}" "#{filename}")
  end


  def mergepdf cover, resume, dest, fn
    # merge the cover letter and resume automagically
    pdf = CombinePDF.new
    pdf << CombinePDF.load(cover)
    pdf << CombinePDF.load(resume)
    pdf.save dest + fn
  end

private
  # pull in the view so we don't have to put verbiage in the model
  def view
    ResgenView.new
  end
end
