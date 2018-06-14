class ResgenController

  def initialize
    @model  = ResgenModel.new
    @view   = ResgenView.new
    @time   = Time.new
    @config = @model.create
  end

  def run

    # close out any libreoffice processes
    @model.runproc('soffice.bin')

    resgen = ODFReport::Report.new(@config['coverpath']) do |merge|

      # prompt the user with definitions from the view
      @view.prompt_position
      position = gets.chomp

      @view.prompt_company
      company = gets.chomp

      # initialize the company directory name
      wget_dir     = company.gsub(/\s/,'-')
      wget_fn      = position.gsub(/\s/,'-')
      employer_dir = @config['appliedir'] + wget_dir + '/'

      # make sure this is a new application
      checkdir employer_dir

      @view.prompt_url
      url = gets.chomp

      # send wget to grab it, since the text is all that's really useful (and to save space)
      @view.job_scrape(url)
      @model.wget(url, employer_dir + wget_fn + @time.strftime("-%-m-%-d") +'.html')

      # pass it to the writer doc
      merge.add_field :date, @time.strftime("%A, %B %-m, %Y")
      merge.add_field :position, "#{position}"
      merge.add_field :company, "#{company}"
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


  def checkdir dir

    if Dir.exist?(dir)
      @view.dir_exists

      if $stdin.getch == 'n'
        exit
      end
      # if n is not keyed, move on with the process

    else
        # create the directory
        Dir.mkdir dir
    end
  end
end
