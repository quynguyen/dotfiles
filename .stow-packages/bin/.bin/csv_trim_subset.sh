#!/bin/bash

# Function to determine the smaller and larger files
determine_files() {
	local file1="$1"
	local file2="$2"

	local count1 count2
	count1=$(($(wc -l <"$file1") - 1)) # Exclude header
	count2=$(($(wc -l <"$file2") - 1)) # Exclude header

	if [ "$count1" -gt "$count2" ]; then
		set_file="$file1"
		subset_file="$file2"
	else
		set_file="$file2"
		subset_file="$file1"
	fi
}

# Function to trim whitespace from a CSV file
trim_whitespace() {
	local file="$1"
	[ ! -f "$file" ] && {
		echo "File not found!"
		return 1
	}

	local temp_file
	temp_file=$(mktemp)

	# Using portable AWK script for both GNU and BSD versions
	awk 'BEGIN { FS = OFS = "," } { 
        for (i = 1; i <= NF; i++) { 
            gsub(/^[ \t]+|[ \t]+$/, "", $i) # Trim leading/trailing whitespace
        } 
        print 
    }' "$file" >"$temp_file"

	mv "$temp_file" "$file"
	echo "Whitespace trimmed for file: $file"
}

# Function to prompt for file deletion using fzf
prompt_delete() {
	local file="$1"
	local options=("No" "Yes")

	echo "Do you want to delete the original file ($file)?"
	echo ""
	local selection=$(printf "%s\n" "${options[@]}" | fzf --prompt="Select an option: " --height 10 --layout=reverse --border)

	if [[ "$selection" == "Yes" ]]; then
		rm "$file"
		echo "**** Deleted original file:"
	else
		echo "**** Kept original file:"
	fi
	echo "$file"
	echo ""
}

# Function to trim subset from set
trim_subset() {
	local set_file="$1"
	local subset_file="$2"

	trim_whitespace "$subset_file"
	trim_whitespace "$set_file"

	local set_basename trimmed_name output_file
	set_basename=$(basename "$set_file")
	trimmed_name="${set_basename%.csv}"
	output_file="${trimmed_name}.trimmed.tmp.csv"

	head -n 1 "$set_file" >"$output_file" # Copy header
	tail -n +2 "$set_file" | grep -vf <(tail -n +2 "$subset_file") >>"$output_file"

	local set_line_count subset_line_count set_output_file subset_output_file
	set_line_count=$(($(wc -l <"$output_file") - 1)) # Exclude header in count
	set_output_file="${trimmed_name}.trimmed.${set_line_count}.csv"
	mv "$output_file" "$set_output_file"

	subset_line_count=$(($(wc -l <"$subset_file") - 1)) # Exclude header in count
	subset_output_file="${trimmed_name}.trimmed.${subset_line_count}.csv"
	cp "$subset_file" "$subset_output_file"

	echo -e "\n**** Created new files:"
	echo "$set_output_file"
	echo "$subset_output_file"
	echo ""

	prompt_delete "$set_file"
	prompt_delete "$subset_file"
}

# Main logic
if [ "$#" -eq 2 ]; then
	if [ ! -f "$1" ] || [ ! -f "$2" ]; then
		echo "Both files must exist."
		exit 1
	fi

	determine_files "$1" "$2"
	trim_subset "$set_file" "$subset_file"
	exit 0
fi

if [ "$#" -eq 0 ]; then
	set -e
	echo "Select the larger set file:"
	larger_set_file=$(find . -name '*.csv' | fzf --prompt="Select the larger set file: ") || {
		echo "No file selected."
		exit 1
	}

	echo "Select the smaller set file (subset):"
	smaller_subset_file=$(find . -name '*.csv' | fzf --prompt="Select the smaller set file (subset): ") || {
		echo "No file selected."
		exit 1
	}
	set +e

	determine_files "$larger_set_file" "$smaller_subset_file"
	trim_subset "$set_file" "$subset_file"
	exit 0
fi

echo "Usage: $0 <set.csv> <subset.csv>"
echo "Or run without arguments for interactive mode."
exit 1
