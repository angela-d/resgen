class Upgrade

require 'io/console'
require 'yaml'
require 'csv'

  def initialize
    @config = YAML.load_file('config.yml')
  end

  def revsan text
    # reverse sanitize!
    text = text.strip.to_s.downcase

    rules = [
      ['-', ' '],
      [/\s+$/,'']
    ]

    result = rules.inject(text) do |clean, (before, after)|
     clean.gsub(before, after)
    end

    return result.split(/ |\_/).map(&:capitalize).join(' ')
  end

  def now

    puts "Welcome to Resgen Upgrade!\nThis script will merge your existing Resgen data with the new reports spreadsheet release in v1.1.0\n"
    puts "Press any key to continue."

    $stdin.getch
    puts "Creating a starter spreadsheet..."

    # create a starter spreadsheet (only if it doesn't already exist)
    if !File.exists? @config['appliedir'] + 'applied.csv'
      CSV.open(@config['appliedir'] + 'applied.csv', "wb") do |csv|
        csv << ['DATE','EMPLOYER','POSITION','URL','INTERVIEW','REJECTION']
      end

      puts "\e[1;92mSince a spreadsheet didn't yet exist, one was added to " + @config['appliedir'] + "\e[0m\nYou can change this destination in config.yml"
    end

    puts "Preparing your data for import..."
    require 'date'

      # pull the previous applicant data
	    Dir.entries(@config['appliedir'])
	      .reject{ |name| name.include? '.' }
	      .each { |employer|

          # set the known structure
	        dir  = @config['appliedir'] + employer + '/'

          # get the position by selecting the job postings scraped by resgen
	        Dir.entries(dir)
	        .select { |type| type.include? '.html' }
	        .each { |position|

            # format the strings we'll be importing to the spreadsheet
            date  = File.mtime(dir + position).to_s
	          snip  = position.scan(/\d+|\D+/)
            title = snip[0].split('.html')

            employer = revsan employer
            position = revsan title[0]

            CSV.open(@config['appliedir'] + 'applied.csv', 'ab') do |csv|
              csv << ["#{date}","#{employer}", "#{position}","","",""]
            end
	        }
	      }
        puts "Done.\n\nYour upgrade is now complete.\nRun:\truby resgen week\nto see what you've applied to this week."
  end
end

startup = Upgrade.new
startup.now
