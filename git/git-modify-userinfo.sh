#!/usr/bin/env bash

# =============================================================
# Title: Modify User Name & Email for Git Project
# Developer: parkjunhong77@gmail.com
# Since: 2025/02/21
# License: MIT 2.0
# =============================================================

set -e  # Exit immediately if an error occurs

# Help function
help() {
    echo "File: $0"
    echo "Called by: ${FUNCNAME[1]} at line ${BASH_LINENO[0]}"
    echo "Usage: $0 -d <directory> -u <user.name> -e <user.email>"
    echo "  -d <directory>  - The root directory to search for Git repositories"
    echo "  -u <user.name>  - The Git user.name to set"
    echo "  -e <user.email> - The Git user.email to set"
    exit 0
}

# Default values
target_dir=""
user_name=""
user_email=""

# Parse command-line options
while getopts "d:u:e:h" opt; do
    case "$opt" in
        d) target_dir="$OPTARG" ;;
        u) user_name="$OPTARG" ;;
        e) user_email="$OPTARG" ;;
        h) help ;;
        *) help ;;
    esac
done

# Validate required parameters
if [ -z "$target_dir" ] || [ -z "$user_name" ] || [ -z "$user_email" ]; then
    echo "Error: Missing required arguments."
    help
fi

# Check if the directory exists
if [ ! -d "$target_dir" ]; then
    echo "Error: The specified directory does not exist."
    exit 1
fi

# Recursive function to apply git configuration
git_configure_recursive() {
    local dir="$1"
    
    for sub_dir in "$dir"/*/; do
        [ -d "$sub_dir" ] || continue  # Check if it's a directory
        
        pushd "$sub_dir" > /dev/null
        
        if [ -d ".git" ]; then
            git config user.name "$user_name"
            git config user.email "$user_email"
            echo "'$sub_dir' project's user information has been updated:"
            echo "  - user.name  = $user_name"
            echo "  - user.email = $user_email"
            git_configure_recursive "$sub_dir"  # Recursive call
        fi
        
        popd > /dev/null
    done
}

# Execute the function
git_configure_recursive "$target_dir"

exit 0

