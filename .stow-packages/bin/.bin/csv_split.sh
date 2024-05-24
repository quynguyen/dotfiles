#!/bin/bash

split_csv() {
	local input_file="$1"
	local total_lines=$(xsv count "$input_file")
	local remaining_lines=$total_lines
	local start_line=1
	local part_number=1

	# Loop until all lines are accounted for
	while [ $remaining_lines -gt 0 ]; do
		# Ask for the size of the current part
		echo "Input the size for part $part_number [Default: $remaining_lines (remaining)]:"
		read part_size

		# Default to remaining lines if no input is given
		if [ -z "$part_size" ]; then
			part_size=$remaining_lines
		fi

		# Validate the input
		if ! [[ "$part_size" =~ ^[0-9]+$ ]] || [ "$part_size" -le 0 ] || [ "$part_size" -gt "$remaining_lines" ]; then
			echo "Invalid size. Please enter a positive number up to $remaining_lines."
			continue
		fi

		# Calculate the ending line number
		end_line=$((start_line + part_size - 1))

		# Generate the output filename
		output_file="${input_file%.csv}.part.${part_number}.size.${part_size}.csv"

		# Use xsv to slice the file
		xsv slice --start $((start_line - 1)) --end $end_line $input_file >"$output_file"

		# Update the start line and remaining lines for the next part
		start_line=$((end_line + 1))
		remaining_lines=$((remaining_lines - part_size))
		part_number=$((part_number + 1))

		echo ""
		echo "****** Created $output_file"
		echo ""
	done

	echo "Splitting complete."
}

# Mode 1: Command line argument
if [ "$#" -eq 1 ]; then
	input_file=$1
	if [ ! -f "$input_file" ]; then
		echo "File not found: $input_file"
		exit 1
	fi
	split_csv "$input_file"
	exit 0
fi

# Mode 2: Interactive file selection
if [ "$#" -eq 0 ]; then
	# Select file using fzf
	input_file=$(find . -name '*.csv' | fzf --prompt="Select a CSV file to split: ")
	if [ -z "$input_file" ]; then
		echo "No file selected."
		exit 1
	fi
	split_csv "$input_file"
	exit 0
fi

# If no mode fits
echo "Usage: $0 <filename.csv>"
echo "Or run without arguments for interactive mode."
exit 1
