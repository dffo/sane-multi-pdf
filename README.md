# sane-multi-pdf
It can be a pain to scan PDF documents comprising multiple pages using a flatbed scanner; not only does each page need to be scanned individually, but after that they need to be merged in the correct order into one large file, usually through the use of an external program. 

The purpose of this script is to provide an interactive command line environment for quickly scanning individual pages, and then concatenating them all into one big multipage document.

Not only that, but it allows a user to preview scanned pages, redo a previous page if necessary, and add pages on the fly.

Requires:
* libsane
* pdfjam
* ImageMagick

You'll need to know your SANE device name when setting up. If you don't know it, use ``scanimage -L`` to list compatible devices and their SANE names.

The script depends on pdfjam for pdf concatenation (see [here](https://warwick.ac.uk/fac/sci/statistics/staff/academic-research/firth/software/pdfjam/) for installation info). pdfjam requires LaTeX to be installed.

Requires ImageMagick to ``convert`` the scanned png files to pdf (SANE only scans to image).

This is a shell script; to run it simply make the file executable.
When first run, the script will generate a config file with the output directory, the scanner device and the pdf viewer program with which to preview files. It will also create a file that specifies the default dimensions of the documents to be scanned and the style (color, grayscale, lineart).

After the script has scanned a page, it will present a prompt from which commands can be issued:

* "p" will preview the previously scanned page in the default pdf viewer
* "r" will redo the previously scanned page
* "a" will add a page to the number of pages specified
* "f" will finish the job and concatenate whatever pages it has already scanned
* Once you are satisfied with the scanned page, just press enter to move on to the next page.

Once all the pages have been scanned and converted, they will be concatenated into a pdf and placed in the default directory with the specified name.
