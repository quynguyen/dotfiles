#!/bin/bash

# go there the directory of this currently 'sourced' script ( quietly )
pushd $(dirname ${BASH_SOURCE:-$0}) >/dev/null

# Install/update Nix
source .scripts/nix/install-nix.sh

# Nix Packages
source .scripts/nix/install-nix-packages.sh

# $HOME dotfiles
source .scripts/stow/create-home-dotfile-symlinks.sh

# SPIN settings
source .scripts/spin/configure-spin.sh

# Zsh plugins
source .scripts/antibody/generated-zsh-plugins.sh

# ~/.zshrc
source .scripts/zsh/generate-home-zshrc.sh

# Tmux Plugins
source .scripts/tmux/install-tmux-plugins.sh

# Neovim plugins
source .scripts/nvim/install-nvim-plugins.sh

# Reload the shell, if logged into the terminal
if [[ -n "$TERM" ]]; then
	exec zsh
fi

# go back to working directory ( quietly )
popd >/dev/null
