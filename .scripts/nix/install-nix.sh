#!/bin/bash

set -e

# install nix (if not already installed)
if [[ ! -f ~/.nix-profile/etc/profile.d/nix.sh ]]; then
	sh <(curl -L https://nixos.org/nix/install) --no-daemon
fi

# Source Nix
source ~/.nix-profile/etc/profile.d/nix.sh

# Use the most update-to-date packages
nix-channel --update && nix-env -u
