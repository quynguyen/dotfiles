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
			;;
	esac
}

# install.sh *sources* this file, so a "run only when executed directly" guard
# would make the whole zsh plugin step a silent no-op and leave ~/.zshrc
# sourcing a ~/.zsh_plugins.sh that was never generated. Follow the same
# --source-only convention the other scripts here use instead.
if [[ "${1:-}" == "--source-only" ]]; then
	return 0 2>/dev/null || true
fi

initialize_shell
