#!/bin/sh
# 
# Wrapper around 'asciidoctor' and 'asciidoctor-pdf' with the goal
# to use less parameters due to use of some conventions.
# For use without any warranty or other claimable rights.
#
# Autor   : Tim Pommerening, 2020
# Licence : CC BY 4.0 <https://creativecommons.org/licenses/by/4.0/>
#

# FUNCTIONS START ##################
die() {
    printf '%s\n' "$1" >&2
    exit 1
}

verb1() {
	if [ $verbose -gt 0 ]; then
		printf '%s\n' "$1" >&2
	fi
}

show_help() {
	printf "Usage: adoc [OPTION]... FILE...\n\n"
	printf "Wrapper around 'asciidoctor' and 'asciidoctor-pdf' with the goal \n"
	printf "to use less parameters due to use of some conventions."
	printf "\n\n"
    printf "    -b, --basedir BASEDIR   Setting BASEDIR as basedir. If none is set, the directory of FILE is used.\n"
    printf "    -H, --home HOMEDIR      Setting HOMEDIR as adoc home. In this structered folder the pdf themes are looked for.\n"
    printf "                            If not set the environment variable ADOC_HOME is used as a default.\n"
    printf "                            If ADOC_HOME is not set 'basedir' is used.\n"
	printf "    -m, --marked2           Using the marked2 environment variable 'MARKED_ORIGIN' as basedir.\n"
	printf "    -o, --options           Options directly passed to 'asciidoctor'. Must be placed in '' or \"\" to avoid whitespace.\n"
	printf "    -P, --pdf               Uses 'asciidoctor-pdf' to create pdf output.\n"
	printf "    -t, --theme NAME        For pdf creation only: Uses theme found in 'HOMEDIR/themes/NAME/NAME-theme.yml'\n"
	printf "    -p, --pipe              Using STDIN as input file and STDOUT as output file for use in pipes.\n"
	printf "    -v, --verbose           Prints verbose output.\n"
	printf "    -h, --help              This help.\n"
	printf "\n\n"
	printf "EXAMPLE 1   adoc --pdf --theme my /home/me/docs/text.adoc\n"
	printf "              Creates 'text.pdf' in folder of 'text.adoc' using theme 'my' found in \$ADOC_HOME/themes/my/my-theme.yml.\n"
	printf "EXAMPLE 2   cat 'text.adoc' |adoc --pipe\n"
	printf "              Creates html5 output of 'text.adoc' to STDOUT.\n"
	printf "EXAMPLE 3   adoc -o '--attribute confdir=/conf --safe-mode=safe' /home/me/docs/text.adoc\n"
	printf "              Creates 'text.html' from 'text.adoc' respecting attribute 'confdir' and explicitly setting of 'safe-mode'.\n"
	printf "\n\n"

}

run_piped() {
	verb1 "Running asciidoctor in pipe mode (with input and output file from stdin/stdout) ..."
	infile="-"
	outfile="-"
	run_asciidoctor
}

run_asciidoctor() {
	verb1 "Using adoc='$adoc' ..."
	verb1 "Using basedir='$basedir' ..."
	verb1 "Using home='$home' ..."
	verb1 "Using backend='$backend' ..."
	verb1 "Using infile='$infile' ..."
	verb1 "Using outfile='$outfile' ..."
	verb1 "Using options='$options' ..."
	verb1 "Using theme='$theme' ..."
	verb1 "Using themepart='$themepart' ..."

	ofpart=""
	if [ "$outfile" ]; then
	    ofpart="--out-file $outfile"
	fi

	$adoc \
	  --base-dir $basedir \
	  --safe-mode safe \
	  --attribute confdir=../_conf \
	  --attribute imagesdir=images \
	  --attribute datadir=../data \
	  --attribute codedir=../code \
	  --attribute toc \
	  --section-numbers \
	  --backend $backend \
	  --attribute icons=font \
	  --require asciidoctor-diagram \
	  --doctype book $themepart $ofpart $options $infile
}
# FUNCTIONS END ##################
#--require asciidoctor-diagram \

# MAIN START ##################
adoc=`which asciidoctor`
if [ $? -ne 0 ]; then
	die "Could not find binary 'asciidoctor'. Is it not installed?"
fi
verbose=0
basedir=""
home=$ADOC_HOME
backend=html5
infile=""
outfile=""
options=""
theme=""
themepart=""

while :; do
    case $1 in
        -h|-\?|--help)
            show_help    # Display a usage synopsis.
            exit
            ;;
        -v|--verbose)
            verbose=$((verbose + 1))  # Each -v adds 1 to verbosity.
            ;;
        -m|--marked2)
			basedir=$MARKED_ORIGIN
			if [ $ADOC_HOME ]; then
		  		home=$ADOC_HOME
			else 
		  		home=$basedir
			fi
			;;
		-o|--options)
			if [ "$2" ]; then
            	options="$options $2"
                shift
            else
                die 'ERROR: "--option" requires a non-empty option argument.'
            fi
            ;;
        -b|--basedir)
			if [ "$2" ]; then
            	basedir=$2
				if [ $ADOC_HOME ]; then
		  			home=$ADOC_HOME
				else 
		  			home=$basedir
				fi
                shift
            else
                die 'ERROR: "--basedir" requires a non-empty option argument.'
            fi
            ;;
        -P|--pdf)
			adoc=`which asciidoctor-pdf`
			backend=pdf
			if [ $? -ne 0 ]; then
				die "Could not find binary 'asciidoctor-pdf'. Is it not installed?"
			fi
			;;
	    -t|--theme)
            if [ "$2" ]; then
            	theme=$2
            	themepart="--attribute pdf-style=$theme-theme.yml --attribute pdf-stylesdir=$home/themes/$theme/ --attribute pdf-fontsdir=$home/themes/$theme/fonts/"
                shift
            else
                die 'ERROR: "--theme" requires a non-empty option argument.'
            fi
            ;;
        -H|--home)
			if [ "$2" ]; then
            	home=$2
                shift
            else
                die 'ERROR: "--home" requires a non-empty option argument.'
            fi
            ;;
        -p|--pipe)       # Takes an option argument; ensure it has been specified.
            run_piped
            exit
            ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: No more options, so break out of the loop.
			if [ "$1" ]; then
				infile=$@
				if [ "X$basedir" = "X" ]; then
					basedir=$(dirname $infile)
				fi				
				if [ "X$home" = "X" ]; then
		  			die "ERROR: Can not find home directory. Use Parameter or set ADOC_HOME environment variable to your asciidoc directory above themes and documents."
				fi	
			else
				die "ERROR: input 'adoc' file is required to run."
			fi
			run_asciidoctor 
            break
    esac

    shift
done
# MAIN END ##################

