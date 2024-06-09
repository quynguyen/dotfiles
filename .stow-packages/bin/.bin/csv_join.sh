#!/bin/bash

# Function to join CSV files
join_csv() {
	local output_file="$1"
	shift
	local input_files=("$@")
	local total_lines=0
	local first_file=true

	# Join files
	for file in "${input_files[@]}"; do
		if [ "$first_file" = true ]; then
			# Copy the first file including the header
			cat "$file" >"$output_file"
			first_file=false
		else
			# Skip the header and append to the output file
			tail -n +2 "$file" >>"$output_file"
		fi
		# Count lines excluding the header for non-first files
		if [ "$first_file" = false ]; then
			total_lines=$((total_lines + $(wc -l <"$file") - 1))
		else
			total_lines=$((total_lines + $(wc -l <"$file")))
		fi
	done

	# Rename file to include total number of lines
	mv "$output_file" "${output_file%.csv}.joined.size.$total_lines.csv"
	echo "Files joined into ${output_file%.csv}.joined.size.$total_lines.csv"
}

# Mode 1: Command line arguments
if [ "$#" -gt 1 ]; then
	output_file=$1
	shift
	input_files=("$@")
	join_csv "$output_file" "${input_files[@]}"
	exit 0
fi

# Mode 2: Interactive selection
if [ "$#" -eq 0 ]; then
	# Select files using fzf
	selected_files=$(find . -name '*.csv' | fzf --multi --prompt="Select CSV files to join: ")
	if [ -z "$selected_files" ]; then
		echo "No files selected."
		exit 1
	fi
	IFS=$'\n' read -d '' -r -a files <<<"$selected_files"

	# Suggest output file name based on the first selected files
	# Based on the first file, removing suffixes if exists (e.g. `part.$x.size.$y.csv`, where `$x` is the part, `$y` is the total size)
	suggested_output="${files[0]%.csv}"
	suggested_output="${suggested_output%.part.*.size.*}"

	# Prompt for output file name
	echo "Enter output file name prefix [Default: ${suggested_output}]:"
	read output_name
	if [ -z "$output_name" ]; then
		output_name="$suggested_output"
	fi

	# Join selected files
	join_csv "$output_name" "${files[@]}"
	exit 0
fi

# If no mode fits
echo "Usage: $0 <output_file.csv> <input_file1.csv> <input_file2.csv> ..."
echo "Or run without arguments for interactive mode."
exit 1
