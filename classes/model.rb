class ResgenModel

  def create
    @config = YAML.load_file('config.yml')
  end


  def wget url, fn
    %x(wget --header="Accept: text/html" --user-agent="Mozilla/5.0 \(X11; Linux x86_64; rv:57.0\) Gecko/20100101 Firefox/57.0"  #{url} -O #{fn} --quiet)
  end


  def del fn
    File.delete("#{fn}")
  end


  def runproc proc
    pid        = %x(pidof "#{proc}").to_i
    checkagain = false

    if pid > 0
      puts "LibreOffice is still running.  Please save your work & close it; press any key to continue."
      checkagain = true
    end

    if checkagain == true and $stdin.getch != nil
      # one more check for libreoffice..
      final = %x(pidof "#{proc}").to_i

      begin
        # user is being a turd & disobeyed advice; forcefully terminate libreoffice
        # an active libreoffice session prevents the pdfs from being generated
        if final > 0
          Process.kill('QUIT', final)
        end
      rescue Errno::ESRCH
      end
    end
  end


  def makepdf filename
    # invoke the sh shell to execute the built-in libreoffice odt -> pdf merge
    %x(sh ./pdfgen.sh #{filename})
  end


  def mergepdf cover, resume, dest, fn

    # merge the cover letter and resume automagically
    pdf = CombinePDF.new
    pdf << CombinePDF.load(cover)
    pdf << CombinePDF.load(resume)
    pdf.save dest + fn

  end
end
