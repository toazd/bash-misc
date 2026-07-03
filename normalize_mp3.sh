#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

# Check if a directory path was provided
if [ $# -eq 0 ]; then
    echo "Error: Please provide a target directory path."
    echo "Usage: $0 /path/to/directory"
    exit 1
fi

TARGET_DIR="$1"

# Verify the provided path is a valid directory
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: '$TARGET_DIR' is not a valid directory."
    exit 1
fi

# Define the processing function and export it so xargs can use it
process_file() {
    local file="$1"
    echo "Processing: $file"

    # Create a unique temporary file in the system temp directory
    local temp_file
    temp_file=$(mktemp --suffix=.mp3)

    # Run the ffmpeg command. -nostdin prevents standard input conflicts.
    if ffmpeg -y -nostdin -i "$file" -filter:a "loudnorm=I=-16:TP=-1.5:LRA=11" "$temp_file" 2>/dev/null; then
        # Overwrite the original file with the processed version
        mv "$temp_file" "$file"
        echo "Successfully normalized: $file"
    else
        echo "Error: Failed to process $file"
        rm -f "$temp_file"
    fi
}
export -f process_file

echo "Starting parallel recursive MP3 normalization (4 jobs) in: $TARGET_DIR"
echo "-------------------------------------------------------------------"

# Find files and pipe them into xargs running up to 8 jobs at a time
find -L "$TARGET_DIR" -type f -iname "*.mp3" -print0 | xargs -0 -P 4 -I {} bash -c 'process_file "$@"' _ {}

echo "-------------------------------------------------------------------"
echo "Normalization process complete!"
