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
