#!/bin/bash

pushd $( dirname ${BASH_SOURCE:-$0} ) > /dev/null # go there the directory of this currently 'sourced' script ( quietly )

# install nix (if not already installed)
if [[ ! -f ~/.nix-profile/etc/profile.d/nix.sh ]]; then
	sh <(curl -L https://nixos.org/nix/install) --no-daemon
else
	nix-channel --update && nix-env -u
fi

# source nix
. ~/.nix-profile/etc/profile.d/nix.sh

# install packages
nix-env -iA nixpkgs.git
nix-env -iA nixpkgs.lazygit
nix-env -iA nixpkgs.gnumake
nix-env -iA nixpkgs.gcc
nix-env -iA nixpkgs.envsubst
nix-env -iA nixpkgs.stow
nix-env -iA nixpkgs.zsh
nix-env -iA nixpkgs.antibody
nix-env -iA nixpkgs.tmux
nix-env -iA nixpkgs.tmuxinator
nix-env -iA nixpkgs.bat
nix-env -iA nixpkgs.sourceHighlight
nix-env -iA nixpkgs.lf
nix-env -iA nixpkgs.xsel
nix-env -iA nixpkgs.fzf
nix-env -iA nixpkgs.ripgrep
nix-env -iA nixpkgs.neovim
nix-env -iA nixpkgs.nvimpager
nix-env -iA nixpkgs.unzip
nix-env -iA nixpkgs.cht-sh
nix-env -iA nixpkgs.direnv

# Generate a .zshrc from a template, REPLACING in ${USER}-specific values
export REPLACE_warning="# WARNING! This file is generated.  To change it, look for the '<filename>_template' version."
export REPLACE_p10k_home='${XDG_CACHE_HOME:-$HOME/.cache}'
export REPLACE_p10k_prompt='${(%):-%n}'
export REPLACE_home=$HOME
envsubst < .stow-packages/zsh/.zshrc_template > .stow-packages/zsh/.zshrc

# Move any existing .zshrc
if [[ -f ~/.zshrc ]]; then
	mv ~/.zshrc ~/.zshrc.old
fi

# Use `stow` to symlink files to home directory
for p in .stow-packages/*; do
	stow -v 1 --target ~/ --dir .stow-packages $(basename $p)
done

# Install or Update plugins
if [[ ! -f ~/.tmux/plugins/tpm/bin/install_plugins ]]; then
	# Install plugins
	git submodule update --init --remote --merge
	~/.tmux/plugins/tpm/bin/install_plugins
else
	# Update plugins
	command -v ~/.tmux/plugins/tpm/bin/update_plugins all
fi


# Take the list of plugins in `.zsh_plugins.txt`, and turn that into a `.sh` file that will get sourced in `.zshrc`
antibody bundle < ~/.zsh_plugins.txt > ~/.zsh_plugins.sh

# install neovim plugins
nvim --headless +PackerInstall +qall

# for interactive shells
if [[ $- == *i* ]]; then
	# add zsh to valid login shells
	command -v zsh | sudo tee -a /etc/shells
	# make zsh the default shell
	chsh -s $(which zsh) $USER
fi

# apply changes
exec zsh

popd  > /dev/null # go back to working directory ( quietly )
