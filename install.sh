#!/bin/bash

# go there the directory of this currently 'sourced' script ( quietly )
pushd $(dirname ${BASH_SOURCE:-$0}) >/dev/null

# Package Management (Homebrew/Nix/etc)
source .scripts/package-management/initialize-packages.sh

# $HOME dotfiles
source .scripts/stow/create-home-dotfile-symlinks.sh

# mise-managed language runtimes (needs stow symlink for ~/.config/mise/config.toml)
source .scripts/mise/install-mise-tools.sh

# Shell-specific initialization
source .scripts/shells/initialize-shell.sh

# Tmux Plugins
source .scripts/tmux/install-tmux-plugins.sh

# Neovim plugins
source .scripts/nvim/install-nvim-plugins.sh

# Desktop applications (macOS only, optional but automated)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "********************************************************************************"
    echo "Installing Desktop Applications"
    echo "********************************************************************************"
    source .scripts/homebrew/install-desktop-apps.sh
else
    echo "Skipping desktop applications (not on macOS)"
fi

# Reload the shell based on configured preference
source .scripts/shells/reload_shell.sh

# go back to working directory ( quietly )
popd >/dev/null
