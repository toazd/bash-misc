#!/usr/bin/env bash

set -e

source_dir="/home/wmcdannell/Audio transcribing/output/cohere-transcribe"
dest_dir="test"
extensions="lrc,mp3,txt"

if [ -z "$source_dir" ] || [ -z "$dest_dir" ] || [ -z "$extensions" ]; then
    echo "Usage: $0 <source_dir> <destination_dir> <extensions>"
    echo "Example: $0 /path/to/source /path/to/destination \"txt,pdf,jpg\""
    exit 1
fi

# Convert comma-separated extensions to an array
IFS=',' read -ra ext_array <<<"$extensions"

# clear the mispelled words list
rm -f mispelled_words.txt

check_for_misspelled_words() {
    local file="$1"
    #aspell list <"$file" >>mispelled_words.txt
    hunspell -l <"$file" >>mispelled_words.txt
}

# Function to recursively copy files
copy_files() {
    local source="$1"
    local destination="$2"

    # Create destination directory if it doesn't exist
    mkdir -p "$destination"

    # Iterate through files in the source directory
    for item in "$source"/*; do

        # don't process directories!
        if [ -f "$item" ]; then
            # check if the path has a .mp3 and a .lrc otherwise skip it
            path_to_check=$(dirname "$item")
            # don't process the source path itself
            [[ "$path_to_check" == "$source_dir" ]] && continue
            file_name=$(basename "$item")
            file_name_without_ext=${file_name%.*}

            # if they both exist, process this directory
            if [[ -e "$path_to_check/${file_name_without_ext}.mp3" && -e "$path_to_check/${file_name_without_ext}.lrc" ]]; then
                #echo "Found MP3 and LRC in $path_to_check"
                :
            else
                # if either is missing, report which one and skip this directory
                if [[ -e "$path_to_check/${file_name_without_ext}.mp3" ]]; then
                    echo "Found MP3 in $path_to_check"
                else
                    echo "Found no MP3 in $path_to_check"
                fi

                if [[ -e "$path_to_check/${file_name_without_ext}.lrc" ]]; then
                    echo "Found LRC in $path_to_check"
                else
                    echo "Found no LRC in $path_to_check"
                fi

                echo "Skipping $path_to_check because didn't find both MP3 and LRC"
                continue
            fi
        fi

        if [ -f "$item" ]; then # Check if it's a file
            local filename=$(basename "$item")
            local extension="${filename##*.}"

            # Check if the file's extension is in the allowed list
            for allowed_ext in "${ext_array[@]}"; do
                if [ "$extension" == "$allowed_ext" ]; then

                    # use the .txt transcription to find potentially mispelled words
                    if [[ $extension == "txt" ]]; then
                        #check_for_misspelled_words "$destination/$filename"
                        check_for_misspelled_words "$item"
                    elif [[ $extension == "lrc" ]]; then
                        # copy the lrc because we use that for creating the browesable html
                        cp "$item" "$destination/$filename"
                    elif [[ $extension == "mp3" ]]; then
                        # copy the file into the server folder
                        cp "$item" "$destination"
                        #ffmpeg -hide_banner -nostats -loglevel quiet -i "$item" -i "/srv/http/transcript_search/cover.jpg" -map 0 -map 1 -c copy -disposition:1 attached_pic "$destination/$(basename "$filename" .aac).mp4" &
                        #ffmpeg -i input.mp4 -i cover.jpg -map 0 -map 1 -c copy -disposition:1 attached_pic output.mp4
                        #cp "$item" "$destination/$filename"
                    fi

                    # loop through each file type
                    #break # Exit the inner loop once a match is found
                fi
            done
        elif [ -d "$item" ]; then # Check if it's a directory
            local subdir=$(basename "$item")
            copy_files "$item" "$destination/$subdir" # Recursive call
        fi
    done
}

# Check if the source directory exists
if [ ! -d "$source_dir" ]; then
    echo "Error: Source directory '$source_dir' does not exist."
    exit 1
fi

echo "Copying files..."

# Call the recursive copy function
copy_files "$source_dir" "$dest_dir"

# remove duplicates from the mispelled words list
sort <mispelled_words.txt | uniq >"/tmp/m.txt"
mv "/tmp/m.txt" mispelled_words.txt

echo "Selective copy completed."

exit 0
