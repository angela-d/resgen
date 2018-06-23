class ResgenController

  def initialize
    @model  = ResgenModel.new
    @view   = ResgenView.new
    @time   = Time.new
    @config = @model.config
  end

  def run

    if @config['driver'] == nil
      # first run, so get all the config values we'll need set
      @model.firstrun
      @view.welcome

      # user has been notified to restart
      exit
    end

    # make sure everything is pathed appropriately
    @model.test

    # if arguments are passed, the user might be requesting reports
    if !ARGV.empty? && ARGV[0] == 'week' || ARGV[0] == 'month' || ARGV[0] == 'year'

      report = ResgenReports.new
      report.report ARGV[0]
      exit

    elsif !ARGV.empty?

      @view.arg_error
      exit
    end

    # close out any libreoffice processes
    @model.runproc('soffice')

    resgen = ODFReport::Report.new(@config['coverpath']) do |merge|

      # prompt the user with definitions from the view
      @view.prompt_position
      position = gets.chomp

      @view.prompt_company
      company = gets.chomp

      # initialize the company directory name
      scrape_dir   = @model.sanitize company
      scrape_fn    = @model.sanitize position
      employer_dir = @config['appliedir'] + scrape_dir + '/'

      # make sure this is a new application
      @model.checkdir employer_dir

      @view.prompt_url
      url = gets.chomp

      # send wget to grab it, since the text is all that's really useful (and to save space)
      @view.job_scrape(url)
      @model.scrape(url, employer_dir + scrape_fn + @time.strftime("-%-m-%-d-%y") +'.html')

      # pass it to the writer doc - if you want to further customize your cover sheet, follow suit with the variables below
      merge.add_field :date, @time.strftime("%A, %B %-d, %Y")
      merge.add_field :position, "#{position}"
      merge.add_field :company, "#{company}"

      # append new data to the existing spreadsheet
      CSV.open(@config['appliedir'] + 'applied.csv', 'ab') do |csv|
        csv << [Time.now,"#{company}", "#{position}","#{url}","",""]
      end
    end

      # complete the libre office file creation
      resgen.generate('output.odt')

      # convert odt to pdf file
      @model.makepdf('output.odt')

      # remove the odt file, now that we're done with it
      @model.del('output.odt')

      # create a pdf of the resume to merge
      @model.makepdf(@config['resumepath'])

      # merge time
      respath = File.basename(@config['resumepath'], File.extname(@config['resumepath']))
      @model.mergepdf('output.pdf', respath + ".pdf", @config['destination'], @config['outputfilename'])

      # display success notice
      @view.completion

      # cleanup
      @model.del('output.pdf')
      @model.del(respath + ".pdf")
  end

  # catch a user keying cntrl + c to gracefully close
  Signal.trap("INT") {
    puts "\nExit request received.  Closing Resgen; have a nice day!"
    exit
  }
end
