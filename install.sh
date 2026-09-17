#!/bin/bash

# go there the directory of this currently 'sourced' script ( quietly )
pushd $(dirname ${BASH_SOURCE:-$0}) >/dev/null

# Homebrew now defaults to "ask mode", prompting "Do you want to proceed with the
# installation? [y/n]" whenever a plan pulls in dependencies. A bootstrap script
# should never block on that, so answer yes up front.
export HOMEBREW_NO_ASK=1

# Keep the run's output signal-only. Hints are Homebrew's "you could set this env
# var" chatter, and we run `brew update` explicitly in install-homebrew.sh, so the
# implicit auto-update before every install is redundant. Real warnings and errors
# still print: both go to stderr and neither is suppressed by these.
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_AUTO_UPDATE=1

# Package Management (Homebrew/Nix/etc)
source .scripts/package-management/initialize-packages.sh

# $HOME dotfiles
source .scripts/stow/create-home-dotfile-symlinks.sh

# mise-managed language runtimes (needs stow symlink for ~/.config/mise/conf.d/dotfiles.toml)
source .scripts/mise/install-mise-tools.sh

# Login shell (chsh to zsh/fish/nu per ~/.shell_config; no-op when already set)
source .scripts/shells/set-login-shell.sh

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
