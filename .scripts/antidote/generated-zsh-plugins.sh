#!/bin/bash

echo "********************************************************************************"
echo "Installing Zsh plugins"
echo "********************************************************************************"

if ! command -v zsh &> /dev/null; then
	echo "Error: zsh not found; install it first (brew install zsh / pacman -S zsh)"
	exit 1
fi

# Find antidote. Homebrew and distro packages put it in different places; if
# none is present, clone it (upstream's recommended install) into ~/.antidote.
ANTIDOTE_CANDIDATES=(
	"${HOMEBREW_PREFIX:-/opt/homebrew}/opt/antidote/share/antidote/antidote.zsh"
	"/opt/homebrew/opt/antidote/share/antidote/antidote.zsh"
	"/usr/local/opt/antidote/share/antidote/antidote.zsh"
	"/home/linuxbrew/.linuxbrew/opt/antidote/share/antidote/antidote.zsh"
	"/usr/share/zsh-antidote/antidote.zsh"
	"/usr/share/zsh/plugins/zsh-antidote/antidote.zsh"
	"$HOME/.antidote/antidote.zsh"
)
ANTIDOTE_PATH=""
for candidate in "${ANTIDOTE_CANDIDATES[@]}"; do
	if [[ -f "$candidate" ]]; then
		ANTIDOTE_PATH="$candidate"
		break
	fi
done
if [[ -z "$ANTIDOTE_PATH" ]]; then
	echo "antidote not found; cloning into ~/.antidote..."
	git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
	ANTIDOTE_PATH="$HOME/.antidote/antidote.zsh"
fi
echo "Using antidote at $ANTIDOTE_PATH"

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
