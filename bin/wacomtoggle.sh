#! /bin/bash



#         /$$  /$$  /$$  /$$$$$$   /$$$$$$$  /$$$$$$  /$$$$$$/$$$$
#        | $$ | $$ | $$ |____  $$ /$$_____/ /$$__  $$| $$_  $$_  $$
#        | $$ | $$ | $$  /$$$$$$$| $$      | $$  \ $$| $$ \ $$ \ $$
#        | $$ | $$ | $$ /$$__  $$| $$      | $$  | $$| $$ | $$ | $$
#        |  $$$$$/$$$$/|  $$$$$$$|  $$$$$$$|  $$$$$$/| $$ | $$ | $$
#         \_____/\___/  \_______/ \_______/ \______/ |__/ |__/ |__/
#
#   _____ _____ _____ _____ __    _____    _____ _____ _____ _____ _____ _____
#  |_   _|     |   __|   __|  |  |   __|  |   __|     | __  |   __|   __|   | |
#    | | |  |  |  |  |  |  |  |__|   __|  |__   |   --|    -|   __|   __| | | |
#    |_| |_____|_____|_____|_____|_____|  |_____|_____|__|__|_____|_____|_|___|
#

# A bash script for an advanced setup of a Wacom on Linux :
# with a grep, automatic parsing of the Wacom identifier, of the screen, of dpi and with a precision mode
# ( drawing at 1:1 scale , the tablet / the screen ) .
# Only the button layout remain custom to the model ( Intuos 3 in this example )
# and can be easily adapted with other buttons ID.
#
# Dependencies: libwacom (xsetwacom), Bash and bc for the math, xrandr
#               optional: Gnome icon, notify-send
#               ( tested/created on Mint 17.2 Cinnamon, 11/2015 )
#
# Usage: Edit the script to enter the real world size of your tablet active zone (around line 20),
#        Edit the script to get your button layout correctly setup ( around line 80),
#        Execute the script to setup the tablet. It's a toggle:
#        1. First launch, tablet will be mapped fullscreen, with ratio correction.
#        2. Second launch, tablet will setup a precision mode.
#        3. Third launch loop to 1 , etc... a toggle.
#        4. I'm using the Linux Mint settings to attribute a keybind to launch this script.
#           (the unused 'email' button on my keyboard)
#         Art usage: I like to paint with fullscreen mapping (normal) mode
#                    I like to draw with precision mode.
#        (Note: Krita does support live change of config without any observed bugs.)
#
# License: CC-0/Public-Domain/WTFPL (http://www.wtfpl.net/) license
# autor: www.peppercarrot.com

# IMPORTANT: If only one monitor is connected, the script will apply the ratio under the SCREEN 1 message.

#### GLOBAL VALUES

# Tablet physical size in centimeters

XtabletactiveareaCM=21.6
YtabletactiveareaCM=13.5

# Tablet
tabletstylus=$(xsetwacom --list | grep STYLUS | cut -d ' ' -f 1-7 | sed -e 's/[[:space:]]*$//')
tabletpad=$(xsetwacom --list | grep PAD | cut -d ' ' -f 1-7 | sed -e 's/[[:space:]]*$//')
xsetwacom --set "$tabletstylus" ResetArea
fulltabletarea=`xsetwacom get "$tabletstylus" Area | grep "[0-9]\+ [0-9]\+$" -o`
Xtabletmaxarea=`echo $fulltabletarea | grep "^[0-9]\+" -o`
Ytabletmaxarea=`echo $fulltabletarea | grep "[0-9]\+$" -o`

# Monitors
currentmonitor=$(xrandr | awk '/\ connected/ && /[[:digit:]]x[[:digit:]].*+/{print $1}')
double=$'eDP-1\HDMI-2'
right=$'eDP-1'
left=$'HDMI-2'

if [ "$currentmonitor" = "$right" ] || [ "$currentmonitor" = "$left" ]
	then

correctionscalefactor=1.3

# Screen
Xscreenpix=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f1)
Yscreenpix=$(xrandr --current | grep '*' | uniq | awk '{print $1}' | cut -d 'x' -f2)
screenPPI=$(xdpyinfo | grep dots | awk '{print $2}' | awk -Fx '{print $1}')
XscreenPPI=$(bc <<< "scale = 2; $Xscreenpix / $screenPPI")
YscreenPPI=$(bc <<< "scale = 2; $Yscreenpix / $screenPPI")
XscreenCM=$(bc <<< "scale = 0; $Xscreenpix * 0.0254")
YscreenCM=$(bc <<< "scale = 0; $Yscreenpix * 0.0254")

# Precise Mode + Ratio
Ytabletmaxarearatiosized=$(bc <<< "scale = 0; $Yscreenpix * $Xtabletmaxarea / $Xscreenpix")
XtabletactiveareaPIX_FLOAT=$(bc -l <<< "$XtabletactiveareaCM * $screenPPI / 2.54 * $correctionscalefactor")
YtabletactiveareaPIX_FLOAT=$(bc -l <<< "$YtabletactiveareaCM * $screenPPI / 2.54 * $correctionscalefactor")
XtabletactiveareaPIX=$(bc <<< "scale=0; $XtabletactiveareaPIX_FLOAT / 1")
YtabletactiveareaPIX=$(bc <<< "scale=0; $YtabletactiveareaPIX_FLOAT / 1")
XOffsettabletactiveareaPIX=$(bc <<< "scale = 0; ($Xscreenpix - $XtabletactiveareaPIX) / 2")
YOffsettabletactiveareaPIX=$(bc <<< "scale = 0; ($Yscreenpix - $YtabletactiveareaPIX) / 2")

# Verbose for debugging
echo "Setup script for your $tabletpad"
echo "-----------------------------------------"
echo ""
echo "Debug information:"
echo "Tablet size (cm) :" "$XtabletactiveareaCM" x "$YtabletactiveareaCM"
echo "Screen size (px) :" "$Xscreenpix" x "$Yscreenpix"
echo "Screen size (cm) :" "$XscreenCM" x "$YscreenCM"
echo "Screen ppi :" "$screenPPI"
echo "Correction factor :" "$correctionscalefactor"
echo "Maximum tablet-Area (Wacom unit):" "$Xtabletmaxarea" x "$Ytabletmaxarea"
#echo "Precision-mode area (px):" "$XtabletactiveareaPIX" x "$YtabletactiveareaPIX"
#echo "Precision-mode offset (px):" "$XOffsettabletactiveareaPIX" x "$YOffsettabletactiveareaPIX"


# Wacom Intuos PT M 2 Infos: this is my tablet
# max area : 0 0 60960 45720
# ---------
# | 1 | 3 |
# |---|---|
# | 9 | 8 |
# ---------
xsetwacom set "$tabletpad" Button 1 "key 1" # Eraser
xsetwacom set "$tabletpad" Button 3 "key 2" # Resize widget with Krita
xsetwacom set "$tabletpad" Button 8 "key 3" # Control color picker
xsetwacom set "$tabletpad" Button 9 "key 4" #
xsetwacom set "$tabletstylus" RawSample 4


# In case of Nvidia gfx:
#xsetwacom set "$tabletstylus" MapToOutput "HEAD-0"
#xsetwacom set "$tableteraser" MapToOutput "HEAD-0"
#xsetwacom set "$tabletpad" MapToOutput "HEAD-0"


#############################
# Precision mode start here :
#############################

# Dual configuration
		if [ -f /tmp/wacomscript-memory-tokken ]; then
		# Here Precision mode; full tablet area in cm are 1:1 on a portion of the screen.
		echo "Precision mode"
		xsetwacom set "$tabletstylus" Area 0 0 "$Xtabletmaxarea" "$Ytabletmaxarea"
		xsetwacom set "$tabletstylus" MapToOutput "$XtabletactiveareaPIX"x"$YtabletactiveareaPIX"+"$XOffsettabletactiveareaPIX"+"$YOffsettabletactiveareaPIX"
		notify-send "Precision mode" "$XtabletactiveareaPIX x $YtabletactiveareaPIX part-of-screen"
		rm /tmp/wacomscript-memory-tokken
		else
		# Here normal mode; tablet map to Fullscreen with ratio correction
		echo "Full-screen mode with ratio correction"
		xsetwacom set "$tabletstylus" Area 0 0 "$Xtabletmaxarea" "$Ytabletmaxarearatiosized"
		xsetwacom set "$tabletstylus" MapToOutput "$Xscreenpix"x"$Yscreenpix"+0+0
		notify-send  "Normal mode" "full-screen"
		touch /tmp/wacomscript-memory-tokken
		fi


	else


# Screen 1

screenPPI=$(xdpyinfo | grep dots | awk '{print $2}' | awk -Fx '{print $1}')

Xscreenpix1=$(xrandr | grep \* | awk 'NR==1{print $1}' | cut -d 'x' -f1)
Yscreenpix1=$(xrandr | grep \* | awk 'NR==1{print $1}' | cut -d 'x' -f2)
XscreenPPI1=$(bc <<< "scale = 2; $Xscreenpix1 / $screenPPI")
YscreenPPI1=$(bc <<< "scale = 2; $Yscreenpix1 / $screenPPI")
XscreenCM1=$(bc <<< "scale = 0; $Xscreenpix1 * 0.0254")
YscreenCM1=$(bc <<< "scale = 0; $Yscreenpix1 * 0.0254")

# Screen 2
Xscreenpix2=$(xrandr | grep \* | awk 'NR==2{print $1}' | cut -d 'x' -f1)
Yscreenpix2=$(xrandr | grep \* | awk 'NR==2{print $1}' | cut -d 'x' -f2)
XscreenPPI2=$(bc <<< "scale = 2; $Xscreenpix2 / $screenPPI")
YscreenPPI2=$(bc <<< "scale = 2; $Yscreenpix2 / $screenPPI")
XscreenCM2=$(bc <<< "scale = 0; $Xscreenpix2 * 0.0254")
YscreenCM2=$(bc <<< "scale = 0; $Yscreenpix2 * 0.0254")

# Ratio
Ytabletmaxarearatiosized1=$(bc <<< "scale = 0; $Yscreenpix1 * $Xtabletmaxarea / $Xscreenpix1")
Ytabletmaxarearatiosized2=$(bc <<< "scale = 0; $Yscreenpix2 * $Xtabletmaxarea / $Xscreenpix2")

XscreenpixALL="$(($Xscreenpix1+$Xscreenpix2))"

		if (( "$Yscreenpix1" -gt "$Yscreenpix2" )); then
				YscreenpixALL=$Yscreenpix1
		else
				YscreenpixALL=$Yscreenpix2
		fi

Ytabletmaxarearatiosized=$(bc <<< "scale = 0; $Yscreenpix1 * $Xtabletmaxarea / $XscreenpixALL")


# Verbose for debugging
echo "Setup script for your $tabletpad"
echo "-----------------------------------------"
echo ""
echo "Debug information:"
echo "Tablet size (cm) :" "$XtabletactiveareaCM" x "$YtabletactiveareaCM"
echo "Screen 1 size (px) :" "$Xscreenpix1" x "$Yscreenpix1"
echo "Screen 1 size (cm) :" "$XscreenCM1" x "$YscreenCM1"
echo "Screen 1 ppi :" "$screenPPI1"
echo "Screen 2 size (px) :" "$Xscreenpix2" x "$Yscreenpix2"
echo "Screen 2 size (cm) :" "$XscreenCM2" x "$YscreenCM2"
echo "Screen 2 ppi :" "$screenPPI2"
echo "Correction factor :" "$correctionscalefactor"
echo "Maximum tablet-Area (Wacom unit):" "$Xtabletmaxarea" x "$Ytabletmaxarea"
#echo "Precision-mode area (px):" "$XtabletactiveareaPIX1" x "$YtabletactiveareaPIX1"
#echo "Precision-mode offset (px):" "$XOffsettabletactiveareaPIX1" x "$YOffsettabletactiveareaPIX1"


# Wacom Intuos PT M 2 Infos:
# max area : 0 0 21600 13500
# ---------
# | 1 | 3 |
# |---|---|
# | 9 | 8 |
# ---------
xsetwacom set "$tabletpad" Button 1 "key 1" # Eraser
xsetwacom set "$tabletpad" Button 3 "key 2" # Resize widget with Krita
xsetwacom set "$tabletpad" Button 8 "key 3" # Control color picker
xsetwacom set "$tabletpad" Button 9 "key 4" #
xsetwacom set "$tabletstylus" RawSample 4


# Toggle configuration

	if [ -f /tmp/wacomscript-memory-tokken0 ]; then
		# Screen 1
		echo "Screen 1 with ratio correction"
		xsetwacom set "$tabletstylus" Area 0 0 "$Xtabletmaxarea" "$Ytabletmaxarearatiosized1"
		xsetwacom set "$tabletstylus" MapToOutput "$Xscreenpix1"x"$Yscreenpix1"+0+0
		notify-send -i /usr/share/icons/gnome/22x22/devices/input-tablet.png "SCREEN 1" "with ratio correction"
		rm /tmp/wacomscript-memory-tokken0
		touch /tmp/wacomscript-memory-tokken1

	elif [ -f /tmp/wacomscript-memory-tokken1 ]; then
		# Screen 2
		echo "Screen 2 with ratio correction"
		xsetwacom set "$tabletstylus" Area 0 0 "$Xtabletmaxarea" "$Ytabletmaxarearatiosized2"
		xsetwacom set "$tabletstylus" MapToOutput "$Xscreenpix2"x"$Yscreenpix2"+"$Xscreenpix1"+0
		notify-send -i /usr/share/icons/gnome/22x22/devices/input-tablet.png "SCREEN 2" "with ratio correction"
		rm /tmp/wacomscript-memory-tokken1

	else
		# Dual Screen
		echo "Dual Screen with ratio correction"
		xsetwacom set "$tabletstylus" Area 0 0 "$Xtabletmaxarea" "$Ytabletmaxarearatiosized"
		xsetwacom set "$tabletstylus" MapToOutput "$XscreenpixALL"x"$Yscreenpix1"+0+0
		notify-send "DUAL SCREEN" "Default mode without ratio correction"
		touch /tmp/wacomscript-memory-tokken0
	fi

fi

exit 0
