#!/bin/bash

if [[ -n "$SPIN" ]]; then
	echo "********************************************************************************"
	echo "This is a SPIN environment.  Sourcing existing Nix install"
	echo "********************************************************************************"

	# Source Nix
	source ~/.nix-profile/etc/profile.d/nix.sh
	return 0
fi

echo "********************************************************************************"
echo "Installing/Updating Nix"
echo "********************************************************************************"

set -e

# install nix (if not already installed)
if [[ ! -f ~/.nix-profile/etc/profile.d/nix.sh ]]; then
	sh <(curl -L https://nixos.org/nix/install) --no-daemon
fi

# Source Nix
source ~/.nix-profile/etc/profile.d/nix.sh

# Use the most update-to-date packages
nix-channel --update && nix-env -u
