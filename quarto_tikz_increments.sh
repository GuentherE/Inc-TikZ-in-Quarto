#!/bin/bash
# Guenther Erhard

# Modifying a TikZ drawing file by commenting out code parts to create an incremental
# image in a Quarto revealjs presentation (like Pause in Latex Beamer or animated slides in PowerPoint)

VERSION="2024-08-14"
# 2024-08-10: first version
# 2024-08-14: bug fix for -i 0 - now you can include or exclude image parts from the basic drawing
#						  by enclosing the code in "% $BEGINTAG 0" and "% $ENDTAG 0"

###########################################################
# Adjust these variables to your taste:
BEGINTAG="begin increment number"
ENDTAG="end increment number"
COMMENTCHARACTER="%" # the comment character used in TikZ
TIKZFILESUFFIX="-increments"
###########################################################

TIKZFILE=""
TIKZFILEBASE=""
TIKZOUTPUTFILE=""
DEBUG=0
WORKFOLDER=""
TMPARRAY=()
INCARRAY=()
INCCOUNT=0
TMPINC=0
MAXINC=0

function usage ()
{
	echo "quarto_tikz_increments Version $VERSION"
  echo "Syntax:"
  echo "quarto_tikz_increments [-h] [-d WORKING FOLDER] -f FILE -i INCREMENT NUMBER [-i INCREMENT NUMBER]"
  echo
  echo "  -v: switch on Debug (should be first option!). Use it only for debugging!"
  echo "      Turn off when script is called from quarto."
  echo "  -h: This help text!"
  echo "  -d WORKING FOLDER: working directory - if not provided the current folder is used"
  echo "  -f FILE: TIKZ file"
  echo "  -i INCREMENT NUMBER: one number is always required, option can be repeated multiple times;"
  echo "                       if only one number is provided all increments up to that number are included."
  echo ""
}
export -f usage

if [ $# -eq 0 ]
then
  usage
  exit 1
fi

function echolog ()
{
  echo "  $1"
}
export -f echolog

function debuglog ()
{
    if [ $DEBUG -eq 1 ]
    then
      echo "  $1"
    fi
}
export -f debuglog

while [ $# -gt 0 ]
do
# echo $#
    case "$1" in
      -v)  DEBUG=1;
           debuglog "Number of arguments provided: $* ($#)"
        ;;
      -h)  usage
        ;;
      -d ) shift
        	WORKFOLDER=$1
        	if [ -d "$WORKFOLDER" ]
        	then
          	cd "$WORKFOLDER"
          	debuglog "Argument -d: set working directory to \"$(pwd)\" ..."
        	else
          	echolog "Directory \"$WORKFOLDER\" does not exist!"
          	exit 1
        	fi
        ;;
      -f ) shift
        	TIKZFILE=$1
        	if [ ! -f "$TIKZFILE" ]
        	then
          	echolog "File \"$TIKZFILE\" does not exist"
          	exit 1
        	else
          	debuglog "Argument -f: \"$TIKZFILE\" found ..."
        	fi
        ;;
      -i ) shift
        	if [ -n $1 ]
        	then
          	INCARRAY+=( $1 )
          	debuglog "Argument -i: Increment number ($INCCOUNT): ${INCARRAY[$INCCOUNT]}"
          	INCCOUNT=$(( INCCOUNT + 1 ))
        	else
          	debuglog "Argument -i: No increments number(s) given"
          	exit 1
        	fi
        ;;
    esac
    shift
done

if [ -z "$WORKFOLDER" ]
then
	WORKFOLDER="./"
fi


debuglog "$TIKZFILE"
TIKZFILEBASE=${TIKZFILE%.*}
debuglog "$TIKZFILEBASE"
TIKZOUTPUTFILE="${TIKZFILEBASE}${TIKZFILESUFFIX}.tikz"
debuglog "$TIKZOUTPUTFILE"

TMPINC=$(grep "$BEGINTAG [0-9]$" $TIKZFILE | awk '{ print $5 }')
MAXINC=0
for i in $TMPINC
do
	debuglog "i: $i"
	if [[ $i -gt $MAXINC ]]
	then
		MAXINC=$i
	fi
done

debuglog "MAXINC: $MAXINC"

if [ $INCCOUNT -gt 0 ]
then

	TMPARRAY=()
	for i in $(seq 0 $MAXINC)
	do
    TMPARRAY[$i]=$i
    debuglog "TMPARRAY[$i]: ${TMPARRAY[$i]}"
	done
	debuglog "TMPARRAY-1: ${TMPARRAY[*]}"

	if [ $INCCOUNT -eq 1 ]
	then
		if [ ${INCARRAY[0]} -eq 0 ]
		then
			TMPARRAY=( "${TMPARRAY[@]:$(( ${INCARRAY[0]} + 1 ))}" )
		else
    	TMPARRAY=( "${TMPARRAY[@]:$(( ${INCARRAY[0]} + 1 ))}" )
    	TMPARRAY=( "0" "${TMPARRAY[@]}" )
    fi
		debuglog "TMPARRAY-2: ${TMPARRAY[*]}"
	else
		debuglog "TMPARRAY before unset: ${TMPARRAY[*]}"
		debuglog "INCARRAY before unset: ${INCARRAY[*]}"
		for (( i=0; i < ${#INCARRAY[@]}; i++ ))
		do
			debuglog "INCARRAY ($i) in loop0: ${INCARRAY[i]}"
			for (( j=0; j < ${#TMPARRAY[@]}; j++ ))
			do
				debuglog "TMPARRAY ($j) in loop1: ${TMPARRAY[j]}"
				debuglog "INCARRAY ($i) in loop1: ${INCARRAY[i]}"
				if [[ ${INCARRAY[i]} -eq ${TMPARRAY[j]} ]]
				then
					debuglog "TMPARRAY in loop2: ${TMPARRAY[j]}"
					debuglog "INCARRAY in loop2: ${INCARRAY[i]}"
					TMPARRAY=( "${TMPARRAY[@]:0:$j}" "${TMPARRAY[@]:$(($j+1))}" )
					debuglog "TMPARRAY unset: ${TMPARRAY[*]}"
				fi
			done
		done
	fi

	cp "$TIKZFILE" "$TIKZOUTPUTFILE"

	for CURINC in "${TMPARRAY[@]}"
	do
		debuglog "Begin Tag: $COMMENTCHARACTER $BEGINTAG $CURINC"
		debuglog "End Tag: $COMMENTCHARACTER $ENDTAG $CURINC"
		sed -i "/$COMMENTCHARACTER $BEGINTAG $CURINC/, /$COMMENTCHARACTER $ENDTAG $CURINC/ s/^./$COMMENTCHARACTER /" "$TIKZOUTPUTFILE"
#		sed -i "/ $BEGINTAG $CURINC/, / $ENDTAG $CURINC/ s/%//" "$TIKZOUTPUTFILE"
#		sed -i "s/$COMMENTCHARACTER $COMMENTCHARACTER $BEGINTAG $CURINC/$COMMENTCHARACTER $BEGINTAG $CURINC/" "$TIKZOUTPUTFILE"
#		sed -i "s/ $ENDTAG $CURINC/$COMMENTCHARACTER $ENDTAG $CURINC/" "$TIKZOUTPUTFILE"
	done
else
	echo
	echolog "No incrementation number(s) given. Do nothing ..."
	echo
	usage
fi
