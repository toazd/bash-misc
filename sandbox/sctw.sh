#!/bin/sh
#https://git.sr.ht/~moviuro/moviuro.bin/blob/master/sctw
# Copyright 2018 Moviuro <moviuro+git@gmail.com>
# Uses https://sunrise-sunset.org/api
# Uses https://www.tedunangst.com/flak/post/sct-set-color-temperature

# sctw is a sct wrapper
# takes $SCTW_LAT $SCTW_LNG for position, and calculates a comfortable screen
# temperature at the time it's run.
# requires curl(1), jq(1)

myname="$(basename "$0")"
today="$(date "+%Y-%m-%d")"

: "${SCTW_CONFIG:="${XDG_CONFIG_HOME:=$HOME/.config}/$myname.rc"}"
: "${TMPDIR:="/tmp"}"

if [ -r "$SCTW_CONFIG" ]; then
  . "$SCTW_CONFIG"
fi

if [ -n "$SCTW_LAT" ] && [ -n "$SCTW_LNG" ]; then
  :
else
  echo "Using 'Notre Maison' as coordinates; excellent restaurant BTW" >&2
  SCTW_LAT="45.764457"
  SCTW_LNG="4.827656"
fi

umask 077
mkdir "$TMPDIR/$myname" >/dev/null 2>&1
[ -d "$TMPDIR/$myname" ] || exit 3
myfile="$TMPDIR/$myname/$today.$SCTW_LAT-$SCTW_LNG"
mytmpfile="$myfile.tmp"
if [ -r "$myfile" ]; then
  :
else
  # Remove previous data: it's not needed anymore
  rm "${TMPDIR:?WOW}/${myname:?DANGER}/"*
  # Store and generate today's data
  curl -s \
   "https://api.sunrise-sunset.org/json?lat=${SCTW_LAT}&lng=${SCTW_LNG}&formatted=0&date=${today}" \
   > "$mytmpfile"
  for item in sunrise sunset day_length; do
    printf '%s=%s\n' "$item" "$(jq .results.$item < "$mytmpfile")"
  done > "$myfile"
  . "$myfile"
  if [ -z "$sunrise" ] || [ -z "$sunset" ]; then
    echo "No sunset or sunrise values!" >&2
    exit 4
  fi
  if man date 2>&1 | grep -q GNU; then
    printf '%s=%s\n' \
     night_end "$(date -d "$sunrise -1 hour" "+%s")" \
     dawn_end  "$(date -d "$sunrise +1 hour" "+%s")" \
     day_end   "$(date -d "$sunset  -1 hour" "+%s")" \
     dusk_end  "$(date -d "$sunset  +1 hour" "+%s")" > "$myfile"
  else
    echo "Unsupported date(1), help me fix it." 2>&1
    exit 5
  fi
fi

. "$myfile"

: "${SCTW_DAY_K:=6500}"
: "${SCTW_NIGHT_K:=4500}"
# We're doing something linear from NIGHT_K to DAY_K from sunrise -1h to
# sunrise +1h; and same for sunset.
Kdiff="$(( SCTW_DAY_K - SCTW_NIGHT_K ))"

now="$(date "+%s")"
night="$(( now < night_end ))"
dawn="$(( now < dawn_end ))"
day="$(( now < day_end ))"
dusk="$(( now < dusk_end ))"
if [ "$night" -eq 1 ]; then
  sct "$SCTW_NIGHT_K"
elif [ "$dawn" -eq 1 ]; then
  timediff="$(( now - night_end ))"
  sct "$(( SCTW_NIGHT_K + Kdiff * timediff / 7200 ))"
elif [ "$day" -eq 1 ]; then
  sct "$SCTW_DAY_K"
elif [ "$dusk" -eq 1 ]; then
  timediff="$(( dusk_end - now ))"
  sct "$(( SCTW_NIGHT_K + Kdiff * timediff / 7200 ))"
else
  sct "$SCTW_NIGHT_K"
fi
