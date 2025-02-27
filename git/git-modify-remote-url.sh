#!/usr/bin/env bash

#
# title: Modify 'git remote url'
# developer: parkjunhong77@gmail.com
# since: 2025/02/21
# license: MIT 2.0
# support by: gemini
#

# Help function
help() {
  echo "This script modifies the 'git remote url' for repositories."
  echo ""
  echo "File Name: $(basename "$0")"
  echo "Function Called: ${FUNCNAME[1]}" # Print the name of the calling function
  echo "Called Line: ${BASH_LINENO[0]}" # Print the line number where the function was called
  echo ""
  echo "Usage:"
  echo "  $(basename "$0") -d <directory> -s <target_string> -t <replacement_string> -f <prefix>"
  echo ""
  echo "Options:"
  echo "  -d <directory>: Target directory (required)"
  echo "  -s <target_string>: Target string to replace (required)"
  echo "  -t <replacement_string>: Replacement string (required)"
  echo "  -f <prefix>: Prefix of subdirectory name to process (required)"
  echo "  -h, --help: Print help message"
  exit 0
}

# Check for help option
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  help
fi

# Check for required arguments
if [[ $# -ne 8 ]]; then
  echo "Error: Missing required arguments."
  help
  exit 1
fi

# Process arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d) directory="$2"; shift 2 ;;
    -s) target_string="$2"; shift 2 ;;
    -t) replacement_string="$2"; shift 2 ;;
    -f) prefix="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; help; exit 1 ;;
  esac
done

# Validate arguments
if [ ! -d "$directory" ]; then
  echo "Error: Directory '$directory' not found."
  exit 1
fi

if [ -z "$target_string" ]; then
  echo "Error: Target string is empty."
  exit 1
fi

if [ -z "$replacement_string" ]; then
  echo "Error: Replacement string is empty."
  exit 1
fi

if [ -z "$prefix" ]; then
  echo "Error: Prefix is empty."
  exit 1
fi

# Get the absolute path of the target directory
target_dir_abs=$(realpath "$directory")

# Traverse subdirectories
find "$directory" -mindepth 1 -type d | while read -r subdir; do
  # Get the absolute path of the subdirectory
  subdir_abs=$(realpath "$subdir")

  # Remove the target directory path from the subdirectory path
  subdir_rel="${subdir_abs#$target_dir_abs/}"

  # Process only subdirectories starting with the specified prefix
  if [[ "$subdir_rel" == "$prefix"* ]]; then
    # Check if .git directory exists and has write permission
    if [ -d "$subdir/.git" ] && [ -w "$subdir/.git" ]; then
      # Change to the .git directory and modify the remote URL
      pushd "$subdir" > /dev/null

      # Get the existing remote URL
      remote_url=$(git remote get-url origin 2>/dev/null)

      # Proceed only if the remote URL exists
      if [[ -n "$remote_url" ]]; then
        # Modify the remote URL if it contains the target string
        if [[ "$remote_url" == *"$target_string"* ]]; then
          # Use 'git remote set-url' to change the remote URL
          git remote set-url origin "${remote_url/$target_string/$replacement_string}"
          echo "Modified remote URL for $subdir: $remote_url -> ${remote_url/$target_string/$replacement_string}"
        else
          echo "Target string not found in the remote URL for $subdir: $remote_url"
        fi
      else
        echo "No remote URL found for $subdir."
      fi

      popd > /dev/null
    else
      if [ ! -d "$subdir/.git" ]; then
        echo "$subdir: .git directory not found."
      else
        echo "$subdir: .git directory found, but no write permission."
      fi
    fi
  fi
done

exit 0

