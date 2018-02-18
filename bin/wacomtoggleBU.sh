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





# Configuration information wacom intuos

# Enter here the active area of your tablet in centimeters (mesure in physical world) :
XtabletactiveareaCM=21.6
YtabletactiveareaCM=13.5
# Custom preference
# Correction scaling can enlarge a bit the precision zone.
# I saw during test a precision zone slightly larger has no impact on control quality, and might feels better.
# default=1 for real precision zone, enlarge=1.5 or reduce=0.8
# myfav: slighly-larger=1.11 with Intuos3 A4 and 96dpi 21inch 1080p workstation screen.
#        larger=1.5 with Intuos4 Medium and 120dpi 15inch 1080p laptop screen.
correctionscalefactor=1.3


#########################################################################################################
########################     Under this line, everything should be automatic     ########################
#########################################################################################################



# Tablet
tabletstylus=$(xsetwacom --list | grep STYLUS | cut -d ' ' -f 1-7 | sed -e 's/[[:space:]]*$//')
tabletpad=$(xsetwacom --list | grep PAD | cut -d ' ' -f 1-7 | sed -e 's/[[:space:]]*$//')
xsetwacom --set "$tabletstylus" ResetArea
fulltabletarea=`xsetwacom get "$tabletstylus" Area | grep "[0-9]\+ [0-9]\+$" -o`
Xtabletmaxarea=`echo $fulltabletarea | grep "^[0-9]\+" -o`
Ytabletmaxarea=`echo $fulltabletarea | grep "[0-9]\+$" -o`

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
YscreenpixALL="$(($Yscreenpix1+$Yscreenpix2))"
Ytabletmaxarearatiosized=$(bc <<< "scale = 0; $Yscreenpix1 * $Xtabletmaxarea / $XscreenpixALL")

# Precision Mode
XtabletactiveareaPIX_FLOAT=$(bc -l <<< "$XtabletactiveareaCM * $screenPPI / 2.54 * $correctionscalefactor")
YtabletactiveareaPIX_FLOAT=$(bc -l <<< "$YtabletactiveareaCM * $screenPPI / 2.54 * $correctionscalefactor")
XtabletactiveareaPIX=$(bc <<< "scale=0; $XtabletactiveareaPIX_FLOAT / 1")
YtabletactiveareaPIX=$(bc <<< "scale=0; $YtabletactiveareaPIX_FLOAT / 1")

XOffsettabletactiveareaPIX1=$(bc <<< "scale = 0; ($Xscreenpix1 - $XtabletactiveareaPIX) / 2")
YOffsettabletactiveareaPIX1=$(bc <<< "scale = 0; ($Yscreenpix1 - $YtabletactiveareaPIX) / 2")

XOffsettabletactiveareaPIX2=$(bc <<< "scale = 0; ($Xscreenpix2 - $XtabletactiveareaPIX) / 2")
YOffsettabletactiveareaPIX2=$(bc <<< "scale = 0; ($Yscreenpix2 - $YtabletactiveareaPIX) / 2")


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

exit 0

#### note: tabletstylus values = tableteraser
