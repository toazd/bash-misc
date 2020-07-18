#!/bin/bash
#
# Creates an M3U playlist in /tmp of iPLAYLIST_SONGS number of
#  iRANDOM MODs from https://modarchive.org
#
# Change vlc in sPLAYER="vlc" to your preferred player
#
# Change 1000 in iPLAYLIST_SONGS=1000 to the number of songs
#  you want in the playlist
#

set -eu

sPLAYER="vlc"
iPLAYLIST_SONGS=1000
sMODARCHIVE_URL="https://modarchive.org/jsplayer.php?moduleid="
sTMP_FILE=""
sTMP_FILE_PREFIX="modarchive_playlist"
iSHUF_RANGE_MIN=1
iSHUF_RANGE_MAX=189573

sTMP_FILE="$(mktemp -q --tmpdir "$sTMP_FILE_PREFIX.XXXXXXXXXX.m3u")"

printf "%s\n" "#EXTM3U" > "$sTMP_FILE"

mapfile <<< "$(shuf --input-range=$iSHUF_RANGE_MIN-$iSHUF_RANGE_MAX --head-count=$iPLAYLIST_SONGS)"

for (( iCOUNTER=0; iCOUNTER < iPLAYLIST_SONGS; iCOUNTER++ )); do
    printf "%s" "$sMODARCHIVE_URL${MAPFILE[iCOUNTER]}" >> "$sTMP_FILE"
done

eval "$sPLAYER $sTMP_FILE" &>/dev/null &
