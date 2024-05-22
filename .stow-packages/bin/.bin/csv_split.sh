#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
	echo "Usage: $0 <filename.csv>"
	exit 1
fi

# Check if the file exists
input_file=$1
if [ ! -f "$input_file" ]; then
	echo "File not found: $input_file"
	exit 1
fi

# Extract the total number of lines from the filename
total_lines=$(xsv count $input_file)
remaining_lines=$total_lines

# Initialize the starting line number
start_line=1
part_number=1

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
	output_file="${input_file%.csv}.part.$part_number.$part_size.csv"

	# Use xsv to slice the file
	xsv slice --start $((start_line - 1)) --end $end_line $input_file >$output_file

	# Update the start line and remaining lines for the next part
	start_line=$((end_line + 1))
	remaining_lines=$((remaining_lines - part_size))
	part_number=$((part_number + 1))

	echo "\t **** Created $output_file"
done

echo "Splitting complete."
