# Resgen: Resume Generator Automation
A Ruby-based application to automate the lengthy steps for writing and dating cover letters.  Generate PDFs from Libre Office .odt templates on the fly *and* save a copy of the job posting, all without ever having to leave your terminal!

The only thing Resgen doesn't do for you is actually send the resume (but with some minor tweaks, it could do that, too!)

![Resgen in action](resgen.gif)

### Zero technical skill required for use
How it works:
- Initialize Resgen by navigating to it's directory in your terminal and running `ruby resgen`
- Resgen will prompt you for information about your job prospect &amp; even alert you if you've applied there before
- Based on the information you give Resgen, a customized cover letter with the employer name and current date will be generated and merged with your regular resume, straight from .odt templates; no needing to have to create the PDFs by hand any time you want to update it - Resgen does it for you
- Resgen also scrapes the job posting and saves a textual copy (and dates the  file), so you have a point of reference when you're called in for an interview

Note: This was built &amp; tested in a Linux desktop environment; it should also work for Mac or Windows, so as long as you have a Ruby environment with Dash Shell command capability.

## Install
```bash
git clone https://notabug.org/angela/resgen.git && cd resgen
```

## Dependencies

- Ruby >= 2.4.x
- Ruby gems
- Libre Office

You can run `bundle install` in Resgen's directory to automatically install the needed gems.  If you wish to do it manually:

```ruby
gem install odf-report
gem install combine_pdf
```

## Customizing
The configuration for the application can be found at [config.yml](config.yml); modify the paths according to your environment.

The [template.odt](templates/template.odt) file has examples of the variables you'll need to add to your own cover letter in order for Resgen to automate for you.  If you wish to add more fields, do so by modifying the `resgen` loop in [controller.rb](classes/controller.rb) and featuring the subsequent `[NEW_VARS]` in your cover letter template.

## Bugs or Issues
Post an issue on the [bug tracker](https://notabug.org/angela/resgen/issues)

## License
GPLv2 only

## Find this useful?
Please [leave feedback](https://notabug.org/angela/resgen/issues) or star the repo on Github
