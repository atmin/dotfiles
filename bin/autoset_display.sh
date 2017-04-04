#!/bin/sh

## set default display (e.g. LVDS1, VGA1)
DEFAULT_DISPLAY="eDP1"

## set your default display resolution
DEFAULT_DISPLAY_RESOLUTION="1920x1080"

## set default port for alternative display
DEFAULT_ALTERNATIVE_DISPLAY_PORT="HDMI2"

## set 1 if you want to autodetect and overwrite default display
DEFAULT_DISPLAY_AUTO=0

## set default position (same, right, left, above, below, off)
DEFAULT_POSITION="above"

## set 1 if you want to auto set wallpaper
SET_WALLPAPER_AUTO=1

## set wallpaper infomation
# default wallpaper
WALLPAPER_SOURCE_DEFAULT=~/Pictures/gits_1.jpg
# alternate wallpaper
WALLPAPER_SOURCE_ALTERNATIVE=~/Pictures/gits_2.jpg
# directory to store wallpaper
WALLPAPER_OUTPUT=/dev/shm/current_wp.jpg


## check if xrandr is available
which xrandr > /dev/null
if [ $? -ne 0 ]
then
    echo "Error: xrandr not fount"
    exit
fi

## cache xrandr output
tmpfile="/tmp/xrandr-tmp-`date +%s`"
xrandr -q > $tmpfile


function finalize() {
    rm -rf $tmpfile
    exit
}


function createSingleWallpaper() {

    if [ $# -ne 3 ]
    then
	echo "usage: $0 <input file> <width>x<height> <output file>"
	exit 1
    fi

    CI_SOURCE_IMG=$1
    CI_TARGET_WIDTH=`echo $2 | awk -F 'x' '{print $1}'`
    CI_TARGET_HEIGHT=`echo $2 | awk -F 'x' '{print $2}'`
    CI_OUTPUT_IMG=$3

    CI_TEMP_IMG=/dev/shm/tmp_mkwallpaper.jpg
    CI_SOURCE_WIDTH=`identify $CI_SOURCE_IMG | awk '{print $3}' | awk -F 'x' '{print $1}'`
    CI_SOURCE_HEIGHT=`identify $CI_SOURCE_IMG | awk '{print $3}' | awk -F 'x' '{print $2}'`

    if [ `expr ${CI_SOURCE_WIDTH} \* ${CI_TARGET_HEIGHT} / ${CI_SOURCE_HEIGHT}` -gt $CI_TARGET_WIDTH ]
    then
	CI_TEMP_WIDTH=`expr ${CI_SOURCE_WIDTH} \* ${CI_TARGET_HEIGHT} / ${CI_SOURCE_HEIGHT}`
	convert -geometry ${CI_TEMP_WIDTH}x${CI_TARGET_HEIGHT}! $CI_SOURCE_IMG $CI_TEMP_IMG
	convert -crop ${CI_TARGET_WIDTH}x${CI_TARGET_HEIGHT}+`perl -e "print abs( $CI_TEMP_WIDTH - $CI_TARGET_WIDTH ) / 2"`+0 $CI_TEMP_IMG $CI_OUTPUT_IMG
    else
	CI_TEMP_HEIGHT=`expr ${CI_SOURCE_HEIGHT} \* ${CI_TARGET_WIDTH} / ${CI_SOURCE_WIDTH}`
	convert -geometry ${CI_TARGET_WIDTH}x${CI_TEMP_HEIGHT}! $CI_SOURCE_IMG $CI_TEMP_IMG
	convert -crop ${CI_TARGET_WIDTH}x${CI_TARGET_HEIGHT}+0+`perl -e "print abs( $CI_TEMP_HEIGHT - $CI_TARGET_HEIGHT ) / 2"` $CI_TEMP_IMG $CI_OUTPUT_IMG
    fi

    rm -rf $TEMP_IMG
}


function createTwinWallpaper() {

    if [ $# -ne 6 ]
    then
	echo "usage: $0 <input file1> <resolution1> [<input file2> <resolution2> {right|left|above|below}] <output file>"
	exit 1
    fi

    CW_SOURCE_IMG1=$1
    CW_RESOLUTION1=$2
    CW_SOURCE_IMG2=$3
    CW_RESOLUTION2=$4
    CW_MODE=$5
    CW_OUTPUT_IMG=$6

    CW_TEMP_OUTPUT1="/dev/shm/tmp1.jpg"
    CW_TEMP_OUTPUT2="/dev/shm/tmp2.jpg"

    createSingleWallpaper $CW_SOURCE_IMG1 $CW_RESOLUTION1 $CW_TEMP_OUTPUT1
    createSingleWallpaper $CW_SOURCE_IMG2 $CW_RESOLUTION2 $CW_TEMP_OUTPUT2

    case "$CW_MODE" in
	"right") convert +append $CW_TEMP_OUTPUT1 $CW_TEMP_OUTPUT2 $CW_OUTPUT_IMG;;
	"left" ) convert +append $CW_TEMP_OUTPUT2 $CW_TEMP_OUTPUT1 $CW_OUTPUT_IMG;;
	"above") convert -append $CW_TEMP_OUTPUT2 $CW_TEMP_OUTPUT1 $CW_OUTPUT_IMG;;
	"below") convert -append $CW_TEMP_OUTPUT1 $CW_TEMP_OUTPUT2 $CW_OUTPUT_IMG;;
	*) echo "invalid mode: '$CW_MODE'"; exit 1;;
    esac

    rm -rf $CW_TEMP_OUTPUT1
    rm -rf $CW_TEMP_OUTPUT2
}


function setDefaultWallpaper() {
    createSingleWallpaper $WALLPAPER_SOURCE_DEFAULT $DEFAULT_DISPLAY_RESOLUTION $WALLPAPER_OUTPUT
    hsetroot -fill $WALLPAPER_OUTPUT
}


## set default display
if [ $DEFAULT_DISPLAY_AUTO -eq 1 ]
then
    echo -n "detecting default display... "
    default=`cat $tmpfile | grep ' connected' | head -1 | awk '{print $1}'`
else
    echo -n "default display is "
    default=$DEFAULT_DISPLAY
fi
echo "$default"


## check if your default display is connected
echo -n "check if default display is connected... "
detected=`cat $tmpfile | grep ' connected' | grep "$default" | awk '{print $1}'`
if [ "$detected" != "$default" ]
then
    echo "no"
    echo
    echo "Error: Default display ($default) differs from detected display ($detected)."
    finalize
fi
echo "yes"


## detect another display connected
echo -n "detecting another display connected... "
output=`cat $tmpfile | grep ' connected' | grep -v "$default" | awk '{print $1}'`

if [ -z "$output" ]
then
    echo "no"
    echo
    echo "Error: No other display is connected."
    xrandr --output $DEFAULT_ALTERNATIVE_DISPLAY_PORT --off
    setDefaultWallpaper
    finalize
fi
echo "$output"


if [ "$1" = "--init" ]
then
    exit
fi


## detect preferred mode
echo -n "detecting preferred mode... "
targetline=`cat $tmpfile | cat -n | grep $output | awk '{print $1}'`
targetline=`expr $targetline + 1`
preferredmode=`cat $tmpfile | tail -n +$targetline | egrep '[[:digit:]]x[[:digit:]]' | grep '+' | head -1 | awk '{print $1}'`

if [ -z "$preferredmode" ]
then
    echo
    echo 
    echo "Error: cannot detect preferred mode."
    finalize
else
    echo "$preferredmode"
fi


## print available modes
echo

modes=(`xrandr -q | tail -n +8 | egrep -o '[[:digit:]]+x[[:digit:]]+' | perl -pe 's/\n/ /'`)
index=0
for mode in ${modes[@]}
do
    index=`expr $index + 1`
    echo "$index: $mode"
done

echo
echo -n ">> select mode (default=$preferredmode): "
read modeinput

if [ -z "$modeinput" ]
then
    echo "set mode to default ($preferredmode)"
    selectedmode=$preferredmode
else
    modeinput=`expr $modeinput - 1`

    if [ $modeinput -gt 0 -a $modeinput -le $index ]
    then
	echo "set mode to ${modes[$modeinput]}"
	selectedmode=${modes[$modeinput]}
    else
	echo "Error: out of range"
	finalize
    fi
fi


## set position of another display
echo
echo "set position of another display..."
valid=0
while [ $valid -eq 0 ]
do
    echo -n ">> Select position [same,right,left,above,below,off]: "
    read input

    if [ -z "$input" -a -n "$DEFAULT_POSITION" ]
    then
	echo "set position to default ($DEFAULT_POSITION)"
	input=$DEFAULT_POSITION
	valid=1
    fi

    case "$input" in
	"same" ) position="--same-as"; valid=1;;
	"right") position="--right-of"; valid=1;;
	"left" ) position="--left-of"; valid=1;;
	"above") position="--above"; valid=1;;
	"below") position="--below"; valid=1;;
	"off"  ) valid=1;;
    esac
    
done


## print detected settings
echo

if [ -n "$position" ]
then
    echo "* Current Display:  $default"	
    echo "* Output Display:   $output"		
    echo "* Display Position: $input"
    echo "* Output Mode:      $selectedmode"
else
    echo "* Output Display:   $output"		
    echo "* Output Mode:      off"
fi    


## confirm xrandr options
echo
echo -n ">> Apply above settings?[Y/n]: "
read apply

if [ -n "$apply" -a "$apply" != "y" -a "$apply" != "Y" ]
then
    echo "canceled."
    finalize
fi


## apply display settings
echo

if [ -z "$position" ]
then
    echo "* xrandr --output $output --off"
    xrandr --output $output --off
    if [ $SET_WALLPAPER_AUTO -eq 1 ]
    then
	echo "* setting default wallpaper..."
	setDefaultWallpaper
	exit
    fi
else
    echo "* xrandr --output $output --mode $selectedmode $position $default"
    xrandr --output $output --mode $selectedmode $position $default
fi


## set wallpaper
if [ $SET_WALLPAPER_AUTO -eq 1 ]
then
    echo
    echo "setting wallpaper..."

    if [ $input != "same" ]
    then
	echo "* createTwinWallpaper $WALLPAPER_SOURCE_DEFAULT $DEFAULT_DISPLAY_RESOLUTION $WALLPAPER_SOURCE_ALTERNATIVE $selectedmode $input $WALLPAPER_OUTPUT"
	createTwinWallpaper $WALLPAPER_SOURCE_DEFAULT $DEFAULT_DISPLAY_RESOLUTION $WALLPAPER_SOURCE_ALTERNATIVE $selectedmode $input $WALLPAPER_OUTPUT
	echo "* hsetroot -fill $WALLPAPER_OUTPUT"
	hsetroot -fill $WALLPAPER_OUTPUT
    else
	setDefaultWallpaper
    fi

fi

echo
finalize
