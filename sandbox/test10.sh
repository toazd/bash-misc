#!/bin/bash
#
# Creates an M3U playlist in /tmp of iPLAYLIST_SONGS number of
#  iRANDOM MODs from https://modarchive.org
#
# Change vlc in sPLAYER="vlc" to your preferred player
# Change 10 in iPLAYLIST_SONGS=10 to the number of songs
#  you want in the playlist
#
# Failed to play:
# 21347
#

set -eu

sPLAYER="vlc"
iPLAYLIST_SONGS=10
iRANDOM=0
iCOUNTER=0
sTMP_FILE=""

sTMP_FILE="$(mktemp -q "/tmp/modarchive_playlist.XXXXXXXXXX.m3u")"

printf "%s\n" "#EXTM3U" > "$sTMP_FILE"

for (( iCOUNTER=0; iCOUNTER < iPLAYLIST_SONGS; iCOUNTER++ )); do
    iRANDOM="$(shuf --input-range=1-189573 --head-count=1)"
    printf "%s\n" "https://modarchive.org/jsplayer.php?moduleid=${iRANDOM}" >> "$sTMP_FILE"
done

eval "$sPLAYER $sTMP_FILE"
