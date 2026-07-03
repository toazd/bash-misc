#!/usr/bin/env bash

# if any command fails, exit
set -e

[[ -e "test" ]] && rm -rf test

# bring new files in
bash copy_test_files.sh

# remove empty dirs created by copy_test_files
# (if LRC and MP3 files are found in the source neither are copied but the dest path was already created)
find . -type d -empty -delete

# fix words in the base
bash replace_text_with.sh test -f replacements.txt

# convert lrc to html and add links for each line
bash addanchors.sh test

# remove old backups
rm -rf transcripts.old

# backup the prev data just in case
[[ -e "transcripts" ]] && mv transcripts transcripts.old

# move the new data so it can be used
mv test transcripts

# fix the permissions (web server/caddy and editor must both be in the http group)
#chmod -R 777 ./*

#Restore directory traversal permissions:
find /srv/http/transcript_search -type d -exec chmod 2775 {} +

# Restore file read/write permissions separately:
find /srv/http/transcript_search -type f -exec chmod 664 {} +

# Restore execute permission only for shell scripts:
find /srv/http/transcript_search -type f -name '*.sh' -exec chmod 775 {} +
