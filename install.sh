#!/bin/bash

# go there the directory of this currently 'sourced' script ( quietly )
pushd $(dirname ${BASH_SOURCE:-$0}) >/dev/null

if [[ -z "$SPIN" ]]; then
	source .scripts/nix/install-nix.sh
else
	echo "********************************************************************************"
	echo "This is a SPIN environment"
	echo "Nix is already installed"
	echo "********************************************************************************"
fi

# Nix Packages
source .scripts/nix/install-nix-packages.sh

# $HOME dotfiles
source .scripts/stow/create-home-dotfile-symlinks.sh

# Zsh plugins
source .scripts/antibody/generated-zsh-plugins.sh

# ~/.zshrc
source .scripts/zsh/generate-home-zshrc.sh

# Reload zsh
exec zsh

# Tmux Plugins
source .scripts/tmux/install-tmux-plugins.sh

# Neovim plugins
source .scripts/nvim/install-nvim-plugins.sh

# go back to working directory ( quietly )
popd >/dev/null
