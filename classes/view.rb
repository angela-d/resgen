class ResgenView

  def green text
    # add some color to the prompt
    print " \e[32m>> #{text}\e[0m"
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
    puts " >> Obtaining a copy of the job posting for you.."
    if url.include? "linkup"
      puts "\e[33m >> Due to the JS redirect embedded in this listing, you might want to manually scrape the job posting to save a copy.\e[0m"
    end
  end

  def completion
    puts green("\t\e[1mYour resume has been processed!")
  end
end
