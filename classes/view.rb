class ResgenView

  def green text
    # add some color to the prompt
    print " \e[32m>> #{text}\e[0m"
  end

  def yellow text
    print " \e[31m\e[1m >> #{text}\e[0m"
  end

  def prompt_position
    puts green("What position are you applying for?")
  end

  def prompt_company
    puts green("At what company?")
  end

  def prompt_url
    puts green("Job posting URL?")
  end

  def dir_exists
    puts "\e[31m\e[1m >> Hey, you may have applied here already!\nWant to continue?\n\tn to cancel; any other key to proceed.\e[0m"
  end

  def job_scrape url
    puts " >> Obtaining a copy of the job posting for you, one moment.. it may take a few seconds, depending on the speed of your internet and proximity to the remote host."
    if url.include? "linkedin"
      puts yellow("Linkedin are notorious turds about automated visits, you might want to double check your applied directory to ensure the posting was scraped properly.")
    end
  end

  def completion
    puts green("\t\e[1mYour resume has been processed!")
  end

  def active_process
    puts "LibreOffice is still running.  Please save your work & close it; press any key to continue."
  end

  def welcome
    puts "\n\e[35m\e[1mThanks for using Resgen!\e[22m\nIf you find the program useful, please share it!\n\n"
    puts "Since this was your first run, Resgen created config settings based on your operating system in config.yml, to save you some time."
    puts "\e[1mIn order for these to take effect, please restart Resgen.\e[22m\n\n"
    puts "Good luck in your search!\e[0m"
  end

  def os_detection_failed
    puts "Your operating system either cannot be detected or is not yet supported."
    puts "Please open a bug report and let me know: https://notabug.org/angela/resgen/issues"
  end
end
