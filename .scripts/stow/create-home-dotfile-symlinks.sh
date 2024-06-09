#!/bin/bash

# go there the directory of this currently 'sourced' script ( quietly )
pushd $( dirname ${BASH_SOURCE:-$0} ) > /dev/null 

echo "********************************************************************************"
echo "Symlinking home dotfiles"
echo "********************************************************************************"

# Use `stow` to symlink files to home directory
for p in ../../.stow-packages/*; do
	stow -v 1 --target ~/ --dir ../../.stow-packages $(basename $p)
done

# go back to working directory ( quietly )
popd  > /dev/null
