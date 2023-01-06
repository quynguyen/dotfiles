#!/bin/bash

# Use `stow` to symlink files to home directory
for p in .stow-packages/*; do
	stow -D -v 1 --target ~/ --dir .stow-packages $(basename $p)
done

