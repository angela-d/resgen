class ResgenModel

  attr_accessor :config

  def initialize
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

    # create a starter spreadsheet (only if it doesn't already exist)
    if !File.exists? @config['appliedir'] + 'applied.csv'
      CSV.open(@config['appliedir'] + 'applied.csv', 'wb') do |csv|
        csv << ['DATE','EMPLOYER','POSITION','URL','INTERVIEW','REJECTION']
      end
    end

    open('config.yml', 'a') { |write|
      write << "\r# auto-generated values by resgen - delete everything below to reset your installation:\n"
      write << "resgenpath: #{resgenpath}/\n"
      write << "os: #{os}\n"
      write << "driver: #{driver}\n"
      write << "libreoffice: #{libreoffice}\n"
    }
  end

  def test
    # ensure paths to all needed files are set appropriately or have not been modified carelessly in the config
    notice = nil
    if !File.directory? @config['appliedir']
      notice = 'appliedir: ' + @config['appliedir']
    elsif !File.directory? @config['destination']
      notice = 'destination: ' + @config['destination']
    elsif !File.directory? @config['resgenpath']
      notice = 'resgenpath: ' + @config['resgenpath']
    elsif !File.exists? @config['coverpath']
      notice = 'coverpath: ' + @config['coverpath']
    elsif !File.exists? @config['resumepath']
      notice = 'resumepath: ' + @config['resumepath']
    elsif !File.exists? @config['appliedir'] + 'applied.csv'
      notice = 'applied.csv is missing, it should be in the "appliedir": ' + "\n" + @config['appliedir'] + 'applied.csv'
    end

    if notice != nil
      view.missing notice
    end
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


  def mergepdf cover, resume, dest, fn, resume_copy
    # merge the cover letter and resume automagically
    pdf = CombinePDF.new
    pdf << CombinePDF.load(cover)
    pdf << CombinePDF.load(resume)
    # save to primary destination (ie. desktop); pulled from config
    pdf.save dest + fn
    # save a copy to the employer directory
    pdf.save resume_copy + fn
  end

private
  # pull in the view so we don't have to put verbiage in the model
  def view
    ResgenView.new
  end
end


class ResgenReports < ResgenModel

  def report limit

    require 'date'
    today            = Date.today # will utilize the last 7 days
    month            = today.strftime("%Y-%m") # calendar month
    year             = today.strftime("%Y") # calendar year
    csvloc           = @config['appliedir'] + 'applied.csv'
    total_columns    = $stdout.winsize[1] - 50
    text_column_size = total_columns / 4
    total            = 0

    # display a banner above the report breakdown
    view.heading limit.upcase

    # parse the csv line by line; we don't necessrily want everything
    reportgen = []
    CSV.foreach(csvloc, :headers => true).select do |job|
      # parse the date so ruby can compare the threshold requested
      date             = Date.parse job['DATE']
      datem            = date.strftime("%Y-%m")
      datey            = date.strftime("%Y")
      formatted_output = date.strftime("%A, %B %-d, %Y") + "\t" +
                          "\e[#{10 + 23}G" + job['EMPLOYER'].slice(0, text_column_size) + "\t" +
                          "\e[#{text_column_size + 20}G" + job['POSITION'].slice(0, text_column_size) + "\t" +
                          "\e[#{text_column_size + 65}G" + job['URL'].slice(0, text_column_size)
        output         = date.strftime("%A, %B %-d, %Y") + "\t\t" + job['EMPLOYER'] + "\t\t" + job['POSITION'] + "\t\t" + job['URL']

      if limit == 'week' && date >= today - 7
        puts formatted_output   # display the output to the terminal
        total     += 1          # sum the total of results
        reportgen += [output]   # loop the output for an array if we're saving the report
      elsif limit == 'month' && datem == month
        puts formatted_output
        total     += 1
        reportgen += [output]
      elsif limit == 'year' && datey == year
        puts formatted_output
        total     += 1
        reportgen += [output]
      end
    end
    puts "\t" + total.to_s + " TOTAL"

    # prompt to see if the user wants a copy of the report that was just generated
    view.save_report
    confirm = $stdin.getch
    generate_report confirm, limit, reportgen
  end

  def generate_report confirm, limit, content

    if confirm == 'y'

      # first save? generate a config variable
      if @config['reports'] == nil
        open('config.yml', 'a') { |write|
          write << "reports: #{@config['resgenpath']}\n"
        }

        path      = @config['resgenpath']
        first_run = true
      else
        path = @config['reports']
      end

      date        = Date.today.strftime("-%-m-%-d-%y")
      destination = path + limit + 'ly' + date + '.txt'

      content.each_with_index do |job,index|
        open(destination, 'a') { |write|
          write << "#{job}\n"
        }
      end

      view.report_saved destination

      if first_run != nil
        view.reports_first_save
      end
    end
  end
end
