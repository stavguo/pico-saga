#!/bin/bash

# Directories to process
directories=("src" "lib")

# Variable to store all file contents
all_contents=""

# Process each directory
for dir in "${directories[@]}"; do
  # Check if directory exists (skip if missing)
  if [ ! -d "$dir" ]; then
    continue
  fi

  # Loop through all files in the directory
  for file in "$dir"/*; do
    # Only process files (not directories)
    if [ -f "$file" ]; then
      # Get filename and append contents
      filename=$(basename "$file")
      all_contents+="-- File: $filename\n"
      all_contents+="$(cat "$file")\n\n"
    fi
  done
done

# Copy to clipboard (with -e to interpret newlines)
echo "$all_contents" | pbcopy

echo "All file contents have been copied to the clipboard!"