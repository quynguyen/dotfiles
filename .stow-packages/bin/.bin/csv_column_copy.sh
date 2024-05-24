#!/bin/bash

# Function to copy a column from a CSV to the clipboard
copy_column() {
	local filename="$1"
	local column_name="$2"

	# Select the column, remove the header, and copy to clipboard
	xsv select "$column_name" "$filename" | grep -v "$column_name" | paste -sd ',' - | pbcopy
	echo "Column '$column_name' from '$filename' has been copied to the clipboard, as a CSV"
}

# Mode 1: Command line arguments
if [ "$#" -eq 2 ]; then
	filename=$1
	column_name=$2
	copy_column "$filename" "$column_name"
	exit 0
fi

# Mode 2: Interactive selection using fzf
if [ "$#" -eq 0 ]; then
	# Select file using fzf
	selected_file=$(find . -name '*.csv' | fzf --prompt="Select a CSV file: ")
	if [ -z "$selected_file" ]; then
		echo "No file selected."
		exit 1
	fi

	# Select column using fzf
	selected_header=$(head -n 1 "$selected_file" | tr ',' '\n' | fzf --prompt="Which column do you want to grab? ")
	if [ -z "$selected_header" ]; then
		echo "No column selected."
		exit 1
	fi

	# Copy the selected column to the clipboard
	copy_column "$selected_file" "$selected_header"
	exit 0
fi

# If no mode fits
echo "Usage: $0 <filename.csv> <column_name>"
echo "Or run without arguments for interactive mode."
exit 1
