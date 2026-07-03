#!/usr/bin/env bash

# Script to recursively replace strings in files within a directory.
# Can take replacements directly as arguments OR from a file.

# Usage: replace_string.sh <directory_path> <old_string> <new_string>
#   OR
# Usage: replace_string.sh <directory_path> -f <replacement_file>
#   OR: replace_string.sh -h | --help | -help (show this help message)
set -e

# Help message
show_help() {
    echo "Usage: $0 <directory_path> <old_string> <new_string>"
    echo "   OR: $0 <directory_path> -f <replacement_file>"
    echo "   OR: $0 -h | --help | -help (show this help message)"
    echo ""
    echo "Options:"
    echo "  -f <replacement_file> :  Specify a file with replacement pairs."
    echo "  -h, --help, -help    :  Show this help message."
    exit 0
}

# Check for help flag
if [ -z "$1" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ] || [ "$1" == "-help" ]; then
    show_help
fi

directory="$1"
old_string="$2"
new_string="$3"

if [ -z "$directory" ]; then
    show_help
fi

if [ ! -d "$directory" ]; then
    echo "Error: Directory '$directory' does not exist."
    exit 1
fi

# Escape values before writing them into a generated sed script.
escape_sed_pattern() {
    local value="$1"
    value=${value//|/\\|}
    printf '%s' "$value"
}

escape_sed_replacement() {
    local value="$1"
    value=${value//\\/\\\\}
    value=${value//&/\\&}
    value=${value//|/\\|}
    printf '%s' "$value"
}

append_sed_replacement() {
    local sed_script="$1"
    local old="$2"
    local new="$3"
    local escaped_old
    local escaped_new

    escaped_old=$(escape_sed_pattern "$old")
    escaped_new=$(escape_sed_replacement "$new")

    printf 's|\\b%s\\b|%s|gi\n' "$escaped_old" "$escaped_new" >>"$sed_script"
}

# Function to recursively process files with one or more replacements
process_files_with_sed_script() {
    local dir="$1"
    local sed_script="$2"
    local file
    local temp_file

    # html files don't exist yet
    #find "$dir" -type f \( -iname "*.lrc" -o -iname "*.html" \) -print0 | while IFS= read -r -d $'\0' file; do
    while IFS= read -r -d $'\0' file; do
        if [ -f "$file" ]; then

            #echo "Checking $file"

            # Create a temporary file to store the modified content
            temp_file=$(mktemp)

            if sed -f "$sed_script" "$file" >"$temp_file"; then
                # more advanced replacements if needed
                #sed -Ef replacements.sed -i "$temp_file"

                # Replace the original file with the modified content
                mv "$temp_file" "$file"
            else
                rm -f "$temp_file"
                return 1
            fi
        fi
    done < <(find "$dir" -type f -iname "*.lrc" -print0)
}

# Function to recursively process files
process_files() {
    local dir="$1"
    local old="$2"
    local new="$3"
    local sed_script
    local status

    sed_script=$(mktemp)
    append_sed_replacement "$sed_script" "$old" "$new"

    if process_files_with_sed_script "$dir" "$sed_script"; then
        status=0
    else
        status=$?
    fi

    rm -f "$sed_script"
    return "$status"
}

# Function to process replacements from a file
process_replacement_file() {
    local dir="$1"
    local file="$2"
    local sed_script
    local status
    local line
    local old
    local new
    local replacement_count=0

    if [ ! -f "$file" ]; then
        echo "Error: Replacement file '$file' does not exist."
        return 1
    fi

    sed_script=$(mktemp)

    while IFS= read -r line || [ -n "$line" ]; do
        IFS='|' read -r old new _ <<<"$line"
        new=${new%$'\r'}

        if [[ -n $old && -n $new ]]; then
            echo "Looking for \"$old\" to replace with \"$new\""
            append_sed_replacement "$sed_script" "$old" "$new"
            ((replacement_count += 1))
        fi
    done <"$file"

    if ((replacement_count == 0)); then
        echo "No valid replacement pairs found in '$file'."
        rm -f "$sed_script"
        return 0
    fi

    echo "Applying $replacement_count replacement(s) to files in '$dir'."

    if process_files_with_sed_script "$dir" "$sed_script"; then
        status=0
    else
        status=$?
    fi

    rm -f "$sed_script"
    return "$status"
}

# Modified argument handling
if [ "$2" = "-f" ]; then
    if [ -z "$3" ]; then
        show_help
    fi
    process_replacement_file "$directory" "$3"
else
    if [ -z "$old_string" ] || [ -z "$new_string" ]; then
        show_help
    fi
    process_files "$directory" "$old_string" "$new_string"
fi

echo "String replacement completed."

exit 0
