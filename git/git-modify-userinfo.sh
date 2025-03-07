#!/usr/bin/env bash

# =============================================================
# Title: Modify User Name & Email for Git Project
# Developer: parkjunhong77@gmail.com
# Since: 2025/02/21
# License: MIT 2.0
# =============================================================

set -e  # Exit immediately if an error occurs

# Variables
base_directories=()
username=""
email=""
verbose=0  # Default: verbose off
repo_found=0  # Flag to track if at least one Git repo was processed

##
# Print script usage information.
##
help() {
    echo "Usage: $0 -d <directory> [-d <directory> ...] -u <user.name> -e <user.email> [-verbose]"
    echo ""
    echo "Options:"
    echo "  -d <directory>   Specify one or more directories containing git repositories (can be repeated)"
    echo "  -u <user.name>   Specify the new git user name"
    echo "  -e <user.email>  Specify the new git user email"
    echo "  -verbose         Enable verbose output (debug mode)"
    echo "  -h               Show this help message"
    exit 1
}

##
# Scan a directory for Git repositories.
#
# @param $1 string Base directory to scan
#
# @return echo {count} {repo1} {repo2} ...  (Count of Git repositories followed by repository paths)
##
scan_git_repositories() {
    local base_dir="$1"
    local count=0
    local repositories=()

    for sub_dir in "$base_dir"/*; do
        if [[ -d "$sub_dir/.git" ]]; then
            repositories+=("$sub_dir")
            count=$((count + 1))
        fi
    done

    echo "$count" "${repositories[@]}"
}

##
# Update Git user.name and user.email in a repository.
#
# @param $1 string Path to the Git repository
#
# @return echo Formatted output of changes
##
update_git_config() {
    local repo="$1"

    local old_name=$(git -C "$repo" config user.name || echo "Not Set")
    local old_email=$(git -C "$repo" config user.email || echo "Not Set")

    git -C "$repo" config user.name "$username"
    git -C "$repo" config user.email "$email"

    local new_name=$(git -C "$repo" config user.name)
    local new_email=$(git -C "$repo" config user.email)

    printf "[%03d] Updating git config in: %s\n" "$repo_index" "$repo"
    printf "%-12s = %-30s <- %s\n" "user.name" "$new_name" "$old_name"
    printf "%-12s = %-30s <- %s\n" "user.email" "$new_email" "$old_email"
}

##
# Process directories and apply Git config updates.
#
# @return echo Git update results per repository
##
process_directories() {
    for base_dir in "${base_directories[@]}"; do
        if [[ ! -d "$base_dir" ]]; then
            continue
        fi

        echo "pd] base_dir= $base_dir"
        read -r count repositories <<< "$(scan_git_repositories "$base_dir")"
        repositories=($repositories)  # Convert space-separated string to array

        if [[ $count -gt 0 ]]; then
            repo_found=1
            printf "=========================================\n"
            printf "Scanning directory: [%03d] %s\n\n" "$count" "$base_dir"

            for i in "${!repositories[@]}"; do
                repo="${repositories[$i]}"
                repo_index=$((i + 1))

                update_git_config "$repo"

                if [[ $repo_index -lt $count ]]; then
                    echo "-----------------------------------------"
                fi
            done
        fi
    done
}

##
# Print the final result message after processing all directories.
#
# @return echo Success or failure message
##
print_final_message() {
    if [[ $repo_found -eq 1 ]]; then
        echo "========================================="
        echo "✅ Git user info updated successfully!"
    else
        echo "❌ No Git repositories found in the specified directories."
        exit 1
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -d)
            shift
            [[ -z "$1" || "$1" == -* ]] && help
            [[ -d "$1" ]] || { echo "Error: Directory '$1' does not exist!" >&2; help; }
            base_directories+=("$1")
            ;;
        -u)
            [[ -n "$username" ]] && help
            shift
            [[ -z "$1" || "$1" == -* ]] && help
            username="$1"
            ;;
        -e)
            [[ -n "$email" ]] && help
            shift
            [[ -z "$1" || "$1" == -* ]] && help
            email="$1"
            ;;
        -verbose)
            verbose=1
            ;;
        -h)
            help
            ;;
        *)
            echo "Error: Unknown option $1" >&2
            help
            ;;
    esac
    shift
done

# Validate required parameters
[[ ${#base_directories[@]} -eq 0 ]] && help
[[ -z "$username" || -z "$email" ]] && help

# Run processes
process_directories
print_final_message

exit 0

