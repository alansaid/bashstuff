#!/bin/bash

# SSH with host name and IP address in background (only in iTerm.app)

# First, check to see if we have the correct terminal!
if [ "$(tty)" == 'not a tty' ] || [ "$TERM_PROGRAM" != "iTerm.app" ] ; then
  /usr/bin/ssh "$@"
  exit $?
fi

function __calculate_iterm_window_dimensions {
  local size=( $(osascript -e "tell application \"iTerm\"
    get bounds of the first window
  end tell" | tr ',' ' ') )

  local x1=${size[0]} y1=${size[1]} x2=${size[2]} y2=${size[3]}
  # 15px - scrollbar width
  local w=$(( $x2 - $x1 - 15 ))
  # 44px - titlebar + tabs height
  local h=$(( $y2 - $y1 - 44))
  echo "${w}x${h}"
}

# Console dimensions
DIMENSIONS=$(__calculate_iterm_window_dimensions)

BG_COLOR="#000000"       # Background color
FG_COLOR="#C62020"       # Foreground color
GRAVITY="NorthEast"      # Text gravity (NorthWest, North, NorthEast,
                         # West, Center, East, SouthWest, South, SouthEast)
OFFSET1="20,10"          # Text offset
OFFSET2="20,80"          # Text offset
FONT_SIZE="60"           # Font size in points
FONT_STYLE="Normal"      # Font style (Any, Italic, Normal, Oblique)
# Font path
#FONT="$HOME/.bash/resources/SimpleLife.ttf"
#FONT="/Users/alan/bin/SimpleLife.ttf"
FONT="/System/Library/Fonts/Menlo.ttc"

HOSTNAME=`echo $@ | sed -e "s/.*@//" -e "s/ .*//"`

# RESOLVED_HOSTNAME=`nslookup $HOSTNAME|tail -n +4|grep '^Name:'|cut -f2 -d $'\t'`
# RESOLVED_IP=`nslookup $HOSTNAME|tail -n +4|grep '^Address:'|cut -f2 -d $':'|tail -c +2`
output=`dscacheutil -q host -a name $HOSTNAME`
RESOLVED_HOSTNAME=`echo -e "$output"|grep '^name:'|awk '{print $2}'`
RESOLVED_IP=`echo -e "$output"|grep '^ip_address:'|awk '{print $2}'`
	
function set_bg() {
local R=$1
local G=$2
local B=$3
local BG=$4

  local tty=$(tty)
  osascript -e "
    tell application \"iTerm\"
      repeat with theTerminal in terminals
        tell theTerminal
          try
            tell session id \"$tty\"
              set background image path to \"$4\"
	      set background color to {$(($R*65535/255)), $(($B*65535/255)), $(($G*65535/255))}
            end tell
          on error errmesg number errn
          end try
        end tell
      end repeat
    end tell"
}

on_exit () {
  if [ ! -f /tmp/iTermBG.empty.png ]; then
    convert -size "$DIMENSIONS" xc:"$BG_COLOR" "/tmp/iTermBG.empty.png"
  fi
  rm "/tmp/iTermBG.$$.png"
  set_bg 0 0 0 
#"/tmp/iTermBG.empty.png"

}
trap on_exit EXIT

convert \
  -size "$DIMENSIONS" xc:"$BG_COLOR" -gravity "$GRAVITY" -fill "$FG_COLOR" -font "$FONT" -style "$FONT_STYLE" -pointsize "$FONT_SIZE" -antialias -draw "text $OFFSET1 '${RESOLVED_HOSTNAME:-$HOSTNAME}'" \
  -pointsize 30 -draw "text $OFFSET2 '${RESOLVED_IP:-}'" -alpha Off \
  "/tmp/iTermBG.$$.png"

if [[ "$@" =~ munich ]]; then
	set_bg 40 0 0 "/tmp/iTermBG.$$.png"
elif [[ "$@" =~ recommend1 ]]; then
	set_bg 0 40 0 "/tmp/iTermBG.$$.png"
elif [[ "$@" =~ recommend2 ]]; then
	set_bg 0 0 40 "/tmp/iTermBG.$$.png"
else
	HASH=`echo $HOSTNAME | md5`
	RED=`expr 255 - $((0x${HASH:0:2}))`
	GREEN=`expr 255 - $((0x${HASH:2:2}))`
	BLUE=`expr 255 - $((0x${HASH:4:2}))`
	if [ $RED -gt 100 ]; then
		RED=`expr $RED / 3`
	fi
	if [ $GREEN -gt 100 ]; then
		GREEN=`expr $GREEN / 3`
	fi
	if [ $BLUE -gt 100 ]; then
		BLUE=`expr $BLUE / 3`
	fi
	if [ `expr $RED + $GREEN + $BLUE` -gt 300 ]; then
		RED=`expr $RED / 10`
		GREEN=`expr $GREEN / 10`
echo hello
	fi
	set_bg $RED $GREEN $BLUE "/tmp/iTermBG.$$.png"
fi


/usr/bin/ssh "$@"
