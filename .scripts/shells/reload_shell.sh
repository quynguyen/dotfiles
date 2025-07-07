#!/bin/bash

# Reload the shell based on configured preference
reload_shell() {
	# Only reload if in a terminal
	if [[ -z "$TERM" ]]; then
		return 0
	fi
	
	# Load shell configuration
	if [[ -f ~/.shell_config ]]; then
		source ~/.shell_config
	fi
	
	# Default to zsh-p10k if not configured
	DOTFILES_SHELL_MODE="${DOTFILES_SHELL_MODE:-zsh-p10k}"
	
	# Switch to appropriate shell
	case "$DOTFILES_SHELL_MODE" in
		"fish")
			echo "🐟 Switching to Fish shell..."
			export SHELL="$(which fish)"
			exec fish
			;;
		"nushell")
			echo "🚀 Switching to Nushell..."
			export SHELL="$(which nu)"
			exec nu
			;;
		"zsh-p10k"|"zsh-starship"|*)
			if [[ "$DOTFILES_SHELL_MODE" == "zsh-p10k" ]]; then
				echo "⚡ Switching to Zsh with Powerlevel10k..."
			else
				echo "🚀 Switching to Zsh with Starship..."
			fi
			export SHELL="$(which zsh)"
			exec zsh
			;;
	esac
}

# Execute if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	reload_shell
fi