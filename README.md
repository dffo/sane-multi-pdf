# sane-multi-pdf
For bed scanners using SANE; command line tool that scans multiple pdfs and concatenates them into a multipage file.
This script uses pdfjam to concatenate the individual pdfs into one big multipage document.

Requires libsane and a scanner that can be operated with it.
[pdfjam](https://warwick.ac.uk/fac/sci/statistics/staff/academic-research/firth/software/pdfjam/) requires LaTeX.
Also requires ImageMagick to convert the scanned png files to pdf (SANE only scans to image).

This is a shell script; to run it simply make the file executable.
When first run, the script will generate a config file with the output directory, the scanner device and the pdf viewer program with which to preview files. It will also create a file that specifies the default dimensions of the documents to be scanned and the style (color, grayscale, lineart).

After the script has scanned a page, it will present a prompt from which commands can be issued:

* "p" will preview the previously scanned page in the default pdf viewer
* "r" will redo the previously scanned page
* "a" will add a page to the number of pages specified
* "f" will finish the job and concatenate whatever pages it has already scanned

This script is mostly complete but is still a WIP.
