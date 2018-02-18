#! /bin/bash
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


# Configuration information
# Enter here the active area of your tablet in centimeters (mesure in physical world) :
XtabletactiveareaCM=21.6
YtabletactiveareaCM=13.5
# Custom preference
# Correction scaling can enlarge a bit the precision zone.
# I saw during test a precision zone slightly larger has no impact on control quality, and might feels better.
# default=1 for real precision zone, enlarge=1.5 or reduce=0.8
# myfav: slighly-larger=1.11 with Intuos3 A4 and 96dpi 21inch 1080p workstation screen.
#        larger=1.5 with Intuos4 Medium and 120dpi 15inch 1080p laptop screen.
correctionscalefactor=1

# Under this line, everything should be automatic, exept customising your buttons
# Tablet
tabletstylus=$(xsetwacom --list | grep STYLUS | cut -d ' ' -f 1-7 | sed -e 's/[[:space:]]*$//')
#tableteraser=$(xsetwacom --list | grep ERASER | cut -d ' ' -f 1-7 | sed -e 's/[[:space:]]*$//')
tabletpad=$(xsetwacom --list | grep PAD | cut -d ' ' -f 1-7 | sed -e 's/[[:space:]]*$//')
xsetwacom --set "$tabletstylus" ResetArea
#xsetwacom --set "$tableteraser" ResetArea
fulltabletarea=`xsetwacom get "$tabletstylus" Area | grep "[0-9]\+ [0-9]\+$" -o`
Xtabletmaxarea=`echo $fulltabletarea | grep "^[0-9]\+" -o`
Ytabletmaxarea=`echo $fulltabletarea | grep "[0-9]\+$" -o`

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
XtabletactiveareaPIX=$(bc <<< "scale = 0; $XtabletactiveareaCM * $screenPPI / 2.54 * $correctionscalefactor")
YtabletactiveareaPIX=$(bc <<< "scale = 0; $YtabletactiveareaCM * $screenPPI / 2.54 * $correctionscalefactor")
XtabletactiveareaPIX=$(bc <<< "scale = 0; ($XtabletactiveareaPIX + 0.5) / 1")
YtabletactiveareaPIX=$(bc <<< "scale = 0; ($YtabletactiveareaPIX + 0.5) / 1")
XOffsettabletactiveareaPIX=$(bc <<< "scale = 0; ($Xscreenpix - $XtabletactiveareaPIX) / 2")
YOffsettabletactiveareaPIX=$(bc <<< "scale = 0; ($Yscreenpix - $YtabletactiveareaPIX) / 2")

# Verbose for debugging
echo "Setup script for your $tabletpad"
echo "-----------------------------------------"
echo ""
echo "Debug informations:"
echo "Tablet size (cm) :" "$XtabletactiveareaCM" x "$YtabletactiveareaCM"
echo "Screen size (px) :" "$Xscreenpix" x "$Yscreenpix"
echo "Screen size (cm) :" "$XscreenCM" x "$YscreenCM"
echo "Screen ppi :" "$screenPPI"
echo "Correction factor :" "$correctionscalefactor"
echo "Maximum tablet-Area (Wacom unit):" "$Xtabletmaxarea" x "$Ytabletmaxarea"
echo "Precision-mode area (px):" "$XtabletactiveareaPIX" x "$YtabletactiveareaPIX"
echo "Precision-mode offset (px):" "$XOffsettabletactiveareaPIX" x "$YOffsettabletactiveareaPIX"


# Wacom Intuos PT M 2 Infos:
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

# Other example
# xsetwacom set "$tabletpad" Button 1 "key greater" # '>' Symbol ; I map on it a color selector, or a custom feature of Krita
# xsetwacom set "$tabletpad" Button 8 "key comma" # ',' key ; another easy key to bind an on-canvas color selector
# xsetwacom set "$tabletstylus" Button 2 "key ctrl" # A way to add Color picker on stylus.

# In case of Nvidia gfx:
xsetwacom set "$tabletstylus" MapToOutput "HEAD-0"
#xsetwacom set "$tableteraser" MapToOutput "HEAD-0"
xsetwacom set "$tabletpad" MapToOutput "HEAD-0"

# Precision mode start here :
# Dual configuration
if [ -f /tmp/wacomscript-memory-tokken ]; then
  # Here Precision mode; full tablet area in cm are 1:1 on a portion of the screen.
  echo "Precision mode"
  xsetwacom set "$tabletstylus" Area 0 0 "$Xtabletmaxarea" "$Ytabletmaxarea"
#  xsetwacom set "$tableteraser" Area 0 0 "$Xtabletmaxarea" "$Ytabletmaxarea"
  xsetwacom set "$tabletstylus" MapToOutput "$XtabletactiveareaPIX"x"$YtabletactiveareaPIX"+"$XOffsettabletactiveareaPIX"+"$YOffsettabletactiveareaPIX"
  notify-send -i /usr/share/icons/gnome/22x22/devices/input-tablet.png "Precision mode" "$XtabletactiveareaPIX x $YtabletactiveareaPIX part-of-screen"
  rm /tmp/wacomscript-memory-tokken
else
  # Here normal mode; tablet map to Fullscreen with ratio correction
  echo "Full-screen mode with ratio correction"
  xsetwacom set "$tabletstylus" Area 0 0 "$Xtabletmaxarea" "$Ytabletmaxarearatiosized"
#  xsetwacom set "$tableteraser" Area 0 0 "$Xtabletmaxarea" "$Ytabletmaxarearatiosized"
  xsetwacom set "$tabletstylus" MapToOutput "$Xscreenpix"x"$Yscreenpix"+0+0
  notify-send -i /usr/share/icons/gnome/22x22/devices/input-tablet.png "Normal mode" "full-screen"
  touch /tmp/wacomscript-memory-tokken
fi
