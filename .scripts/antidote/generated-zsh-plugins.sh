#!/bin/bash

echo "********************************************************************************"
echo "Installing Zsh plugins"
echo "********************************************************************************"

# Find antidote installation path
ANTIDOTE_PATH=""
if [[ -f "/opt/homebrew/opt/antidote/share/antidote/antidote.zsh" ]]; then
	ANTIDOTE_PATH="/opt/homebrew/opt/antidote/share/antidote/antidote.zsh"
elif [[ -f "/usr/local/opt/antidote/share/antidote/antidote.zsh" ]]; then
	ANTIDOTE_PATH="/usr/local/opt/antidote/share/antidote/antidote.zsh"
else
	echo "Error: antidote not found. Please install via 'brew install antidote'"
	exit 1
fi

# Load shell configuration to determine which plugins to use
DOTFILES_SHELL_MODE="zsh-p10k"
if [[ -f ~/.shell_config ]]; then
	source ~/.shell_config
fi

# Create the appropriate plugin file based on shell mode
if [[ "$DOTFILES_SHELL_MODE" == "zsh-p10k" ]]; then
	# Combine base plugins with p10k
	cat ~/.zsh_plugins_base.txt > ~/.zsh_plugins.txt
	echo "" >> ~/.zsh_plugins.txt
	cat ~/.zsh_plugins_p10k.txt >> ~/.zsh_plugins.txt
elif [[ "$DOTFILES_SHELL_MODE" == "zsh-starship" ]]; then
	# Use only base plugins (no p10k)
	cp ~/.zsh_plugins_base.txt ~/.zsh_plugins.txt
fi

# Run antidote bundle in zsh environment since antidote requires zsh
zsh -c "source '$ANTIDOTE_PATH' && antidote bundle <~/.zsh_plugins.txt >~/.zsh_plugins.sh"
