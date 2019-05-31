#!/bin/bash

file_list=""
tmp_dir="/tmp/sane-multi-pdf/"
ind=0
orient="p"

usage()
{
	echo "Usage: $(basename $0) [ -o \"filename.pdf\" ] [ -n <number of pages> ]"
	echo "Use $(basename $0) -h for optional arguments"
	exit 1
}

int_exit()
{
	echo Interrupt signal recieved, cleaning up...
	if [ -d $tmp_dir ]
	then
		rm -r $tmp_dir
	fi
	exit 9
}

trap int_exit SIGINT

if [ -z "$XDG_CONFIG_HOME" ]
then
	config="$HOME/.config"
else
	config=$XDG_CONFIG_HOME
fi

conf_path="$config/sane-multi-pdf/config"
profile_path="$config/sane-multi-pdf/default_profile"

while getopts ":n:o:ihx:y:s:" arg; do
	case "${arg}" in

		n) #number of pages
			pages=${OPTARG}
			if ! [ "$pages" -eq "$pages" ] 2> /dev/null
			then
				echo Number of pages must be an integer
				exit 1
			elif [ "$pages" -lt 1 ]
			then
				echo Number of pages must be 1 or greater
				exit 1
			fi
			;;

		o) #output path
			out_name=${OPTARG}
			;;

		i) #keep individual pdfs
			ind=1
			;;

		h) #help
			echo "Usage: $(basename $0) [ -o \"filename.pdf\" ] [ -n <number of pages> ]"
			echo Use -i to preserve individual page pdfs 
			echo Use -x \<width\>, -y \<height\>\ for custom dimensions\; all units in mm
			echo Use -s \<c\|g\|l\> for custom page style \(color, gray, lineart\)
			exit 1
			;;
		x)
			x=${OPTARG}
			if ! [ "$x" -eq "$x" ] 2> /dev/null
			then
				echo x is not a valid number
				exit 1
			elif [ "$x" -lt 0 ]
			then
				echo x cannot be less than 0
				exit 1
			fi
			;;

		y)
			y=${OPTARG}
			if ! [ "$y" -eq "$y" ] 2> /dev/null
			then
				echo y is not a valid number
				exit 1
			elif [ "$y" -lt 0 ]
			then
				echo y cannot be less than 0
				exit 1
			fi
			;;
		s)
			arg=${OPTARG}
			if [ "$arg" = "c" ] || [ "$arg" = "C" ]
			then
				pg_style="Color"
			elif [ "$arg" = "g" ] || [ "$arg" = "G" ]
			then
				pg_style="Gray"
			elif [ "$arg" = "l" ] || [ "$arg" = "L" ]
			then
				pg_style="Lineart"
			else
				echo Valid style arguments: c, g, l \(color, gray, lineart\)
				exit 1
			fi
			;;

		*)
			usage
			exit 1
			;;
	esac
done

if [ -z "$pages" ] || [ -z "$out_name" ] 
then
	usage
       	exit 1
fi

#check for a config file 
#if it don't exist, ask for a device URI and put it in a new config file

if [ ! -f "$conf_path" ]
then
	if [ ! -d "$(dirname $conf_path)" ]
	then
		echo No config file or directory found\; first run assumed
		mkdir $(dirname $conf_path)
	else
		echo No config file found
	fi
	#the config file will just contain the URI of the preferred scan device
	echo Setting up config file\; please enter URI of preferred scanner
	read -p "Enter URI: " scanner
	touch $conf_path 
	echo $scanner>$conf_path
	echo Enter the default location for the scanned pdf
	read -p "Enter path to directory: " def_path
	if ! [ -d "$def_path" ]
	then
		echo invalid directory\; exiting.
		rm $conf_path
		exit 1
	fi
	echo $def_path >> $conf_path
	echo Enter the default pdf viewer to preview files
	echo \(just hit enter anything to skip\)
	read -p "Enter program name: " pdf_prog
	if [ "$pdf_prog" = "" ]
	then
		echo Skipping step
		echo >> $conf_path
	elif ! [ -x "$(command -v $pdf_prog)" ]
	then
		echo Invalid program\; skipping
		echo >> $conf_path
	else
		echo Default program set
		echo $pdf_prog >> $conf_path
	fi
fi

if [ ! -f "$profile_path" ]
then
	touch $profile_path
	echo Setting up a default profile\; this will specify the \
		default dimensions of the page to be scanned
	echo Should the default style be Color, Gray, or Lineart? \([c]/g/l\)
	read -p ": " style
	if [ "$style" = "c" ] || [ "$style" = "C" ]
	then
		echo "Color">$profile_path
	elif [ "$style" = "g" ] || [ "$style" = "G" ]
	then
		echo "Gray">$profile_path
	elif [ "$style" = "l" ] || [ "$style" = "L" ]
	then
		echo "Lineart">$profile_path
	else
		echo Defaulting to \"color\"
		echo "Color">$profile_path
	fi
	
	echo Enter \"a\" to set the default dimension to \"A4\"
	echo Enter \"l\" to set the default to letter \(8.5\"x11\"\)
	echo Enter \"c\" to set custom dimensions \(a/l/[c]\)
	read -p ": " style
	if [ "$style" = "a" ] || [ "$style" = "A" ]
	then
		echo "210" >> $profile_path
		echo "297" >> $profile_path
	elif [ "$style" = "l" ] || [ "$style" = "L" ]
	then
		echo "215.9" >> $profile_path
		echo "279.4" >> $profile_path
	else
		for dim in width height
		do
			read -p "$dim in mm: " style
			if ! [ "$style" -eq "$style" ] 2> /dev/null
			then
				echo Invalid number, aborting!
				rm $profile_path
				exit 3
			elif [ "$style" -lt 0 ]
			then
				echo Number cannot be less than zero, aborting!
				rm $profile_path
				exit 4
			else
				echo $style >> $profile_path
			fi
		done
	fi
	echo Dimensions set.
fi

scanner=$(awk 'NR==1' $conf_path)
output="$(awk 'NR==2' $conf_path)/$out_name"
pdf_prog="$(awk 'NR==3' $conf_path)"

if [ -z "$x" ]
then
	x=$(awk 'NR==2' $profile_path)
fi

if [ -z "$y" ]
then
	y=$(awk 'NR==3' $profile_path)
fi

if [ -z "$pg_style" ]
then
	pg_style=$(awk 'NR==1' $profile_path)
fi

scanstring="--device $scanner --mode $pg_style --resolution 300 -x $x -y $y"

if [ -f "$output" ]
then
	echo WARNING: file exists at chosen output location!
	echo Overwrite? \(y/n\)
	read -p ": " ans
	if [ "$ans" = "y" ] || [ "$ans" = "Y" ]
	then
		echo Overwriting.
	else
		echo Aborting!
		exit 2
	fi
fi

if [ ! -d "$tmp_dir" ]
then
	mkdir "$tmp_dir"
fi

cd "$tmp_dir"

echo The scan is commencing\; enter h at the prompt for additional commands
for ((i = 1; i <= pages ; i++)); do
	echo Scanning page $i...
	scanimage $scanstring 2>/dev/null 1> "$i.png" 
#	scanimage $scanstring 1> "$i.png" to not supress warnings/errors
	convert "$i.png" -density 300 -quality 0 "$i.pdf" 
	if [ "$i" = "$pages" ]
	then
		echo Final page scanned\;
	else		
		echo Page $i scanned- place page $(($i+1)) on the bed and enter to continue
	fi
	while :
	do
		read -p ": " input
		if [ "$input" = "p" ]
		then
			echo "$pdf_prog $tmp_dir/$i.pdf" | /bin/sh
		elif [ "$input" = "h" ]
		then
			echo Enter \'r\' to redo the previous page \(keep the previous page on \
				the scanner bed\)
			echo Enter \'a\' to add a page\; enter \'f\' to finish the scan \
				prematurely
			if ! [ "$pdf_prog" = "" ]
			then
				echo Enter p to preview the scanned page
			fi
		else
			break
		fi
	done

	if [ "$input" == "r" ] 
	then
		echo Redoing previous page...
		rm "$i.png" "$i.pdf"
		i=$(($i-1))
		continue
	elif [ "$input" = "a" ]
	then
		echo Adding page...
		pages=$(($pages+1))
	fi

	if [ "$i" = "1" ]
	then
		file_list="1.pdf"
	else
		file_list="$file_list $i.pdf"
	fi

	if [ "$input" = "f" ]
	then
		echo Finishing scan...
		break
	fi
done

pdfjoin -q $file_list -o $output 

if [ -f "$output" ]
then
	echo File outputted to $output
	if [ "$ind" -eq "1" ]
	then
		echo Individual page scans can be found \
			in $tmp_dir
	else
		rm -r "$tmp_dir"
	fi
else
	echo An error occured\; merged file not outputted!
	echo Inspect $tmp_dir to possibly recover individual pages\' scans.
	exit 4
fi
exit 0
