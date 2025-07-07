#!/bin/bash

# Initialize shell-specific configurations based on configured shell mode

initialize_shell() {
	# Load shell configuration
	if [[ -f ~/.shell_config ]]; then
		source ~/.shell_config
	fi
	
	# Default to zsh-p10k if not configured
	DOTFILES_SHELL_MODE="${DOTFILES_SHELL_MODE:-zsh-p10k}"
	
	case "$DOTFILES_SHELL_MODE" in
		"zsh-p10k"|"zsh-starship")
			echo "Initializing Zsh configuration..."
			
			# Zsh plugins
			echo "Installing Zsh plugins..."
			source .scripts/antidote/generated-zsh-plugins.sh
			
			# Generate ~/.zshrc
			echo "Generating ~/.zshrc..."
			source .scripts/zsh/generate-home-zshrc.sh
			;;
		"fish")
			echo "Initializing Fish configuration..."
			# Fish-specific initialization would go here
			# Currently handled by stow symlinks
			;;
		"nushell")
			echo "Initializing Nushell configuration..."
			# Nushell-specific initialization would go here
			# Currently handled by stow symlinks
			;;
		*)
			echo "Unknown shell mode: $DOTFILES_SHELL_MODE"
			echo "Falling back to zsh initialization..."
			source .scripts/antidote/generated-zsh-plugins.sh
			source .scripts/zsh/generate-home-zshrc.sh
			;;
	esac
}

# Execute if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	initialize_shell
fi