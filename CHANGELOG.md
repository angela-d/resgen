## Resgen Changelog ##

| Changes | Release |
| -- | -- |
| Major update; new dependencies &amp; functionality added for scraping* | 1.1.0 |
| Public release | 1.0.0 |

* ** 1.1.0 introduces some notable changes, including:**
- OS detection (Linux, Mac or Windows?), while I made efforts to test Mac &amp; Windows in a virtualized setting to ensure cross-compatibility; nothing is as good as the real thing, so please
don't hesitate to [file a bug](https://notabug.org/angela/resgen/issues) if something is broken for you.
- Based on OS detection results, Resgen will attempt to load the Gecko driver needed for the headless browser to scrape.  If you're on a 32-bit OS, you'll
need to [get in touch](https://notabug.org/angela/resgen/issues) and let your presence be known; it is assumed no one is using a 32-bit machine nowadays.
- Because of the new features, there's new dependencies; make sure you run `bundle install` to grab them all
