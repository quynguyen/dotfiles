#!/bin/bash

set -e

# install nix (if not already installed)
if [[ ! -f ~/.nix-profile/etc/profile.d/nix.sh ]]; then
	sh <(curl -L https://nixos.org/nix/install) --no-daemon
else
	nix-channel --update && nix-env -u
fi

# Source Nix
source ~/.nix-profile/etc/profile.d/nix.sh
