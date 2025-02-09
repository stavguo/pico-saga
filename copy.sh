#!/bin/bash

# Directory to process
dir="src"

# Check if the directory exists
if [ ! -d "$dir" ]; then
  echo "Directory $dir does not exist!"
  exit 1
fi

# Variable to store all file contents
all_contents=""

# Loop through all files in the directory
for file in "$dir"/*; do
  # Check if it's a file (not a directory)
  if [ -f "$file" ]; then
    # Get the filename with extension
    filename=$(basename "$file")
    
    # Prepend the filename and append the file contents
    all_contents+="=== File: $filename ===\n"
    all_contents+="$(cat "$file")\n\n"
  fi
done

# Copy the accumulated contents to the clipboard
echo "$all_contents" | pbcopy

echo "All file contents have been copied to the clipboard!"