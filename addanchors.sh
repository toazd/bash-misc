#!/usr/bin/env bash

# Function to process a single file
process_file() {
  local file="$1"
  local temp_file=$(mktemp)
  local line_num=1
  local html_file="${file%.lrc}.html"

  echo "<html><style>* {font-family:sans-serif;font-size:1.1em;background:#FFF0DF;color:black;}</style><head></head><body>" > "$temp_file"

  while IFS= read -r line; do
    # Trim leading and trailing spaces (Bash built-ins)
    #line="${line#"${line%%[![:space:]]*}"}"
    #line="${line%"${line##*[![:space:]]}"}"

    if [[ -n "$line" ]]; then
      # exclude any unwanted lines
      [[ $line = *"[by:whisper.cpp]"* ]] && continue
      # HTML escape (Bash built-ins)
      #line="${line//&/&amp;}"
      #line="${line//</&lt;}"
      #line="${line//>/&gt;}"
      #line="${line//\"/&quot;}"
      #line="${line//\'/&#39;}"

      # add a space after the timestamp for readability
      #line=$(echo "$line" | sed 's/\]/& /')
      line=${line/]/] }
      line=${line/[/<B>[}
      line=${line/]/]</B>}

      # use the line number as the anchor link for that line
      printf '<a name="%d"></a>%s<br>\n' "$line_num" "$line" >>"$temp_file"
      ((line_num++))
    fi
  done <"$file"

  echo "</body></html>" >>"$temp_file"

  mv "$temp_file" "$html_file"
  rm "$file"
}

# Function to recursively process a directory
process_directory() {
  local dir="$1"

  find "$dir" -type f -iname "*.lrc" -print0 | while IFS= read -r -d $'\0' file; do
    #echo "Processing: $file"
    process_file "$file"
  done
}

# Check if a directory is provided as an argument
if [ $# -ne 1 ]; then
  echo "Usage: $0 <directory>"
  exit 1
fi

# Check if the directory exists
if [ ! -d "$1" ]; then
  echo "Error: Directory '$1' not found."
  exit 1
fi

# Process the directory
process_directory "$1"

echo "Finished processing text files and creating HTML files."
