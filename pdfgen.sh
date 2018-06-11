#!/bin/sh

# invoke libreoffice to generate pdf & silence it (cleaner feedback provided in ruby script)
lowriter --headless --convert-to pdf "$1" > /dev/null
