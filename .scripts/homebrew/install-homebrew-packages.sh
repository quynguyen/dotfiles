#!/bin/bash

echo "********************************************************************************"
echo "Installing Homebrew packages"
echo "********************************************************************************"


# Ensure Homebrew is in PATH
if [[ "$OSTYPE" == "darwin"* ]]; then
	if [[ -f "/opt/homebrew/bin/brew" ]]; then
		# Apple Silicon
		export PATH="/opt/homebrew/bin:$PATH"
	else
		# Intel
		export PATH="/usr/local/bin:$PATH"
	fi
else
	# Linux
	export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
fi

# Core development tools (conditionally installed - some may be system provided)
echo "Installing core development tools..."
brew install --quiet make || true  # May already be installed
brew install --quiet gcc || true   # May already be installed  
brew install --quiet git || true   # May already be installed
brew install --quiet zsh || true   # May already be installed
brew install --quiet tmux
brew install --quiet neovim
brew install --quiet unzip || true # May already be installed

# Language runtimes are managed by mise (~/.config/mise/config.toml).
# mise installs node, pnpm, ruby, bun, and rust from its config after stow.
echo "Installing mise (language runtime manager)..."
brew install --quiet mise
# mise config is layered: ~/.config/mise/conf.d/dotfiles.toml (this repo) on top of
# whatever the OS ships in ~/.config/mise/config.toml (Omarchy pins claude/codex/gh there).

# CLI utilities
echo "Installing CLI utilities..."
brew install --quiet lazygit
brew install --quiet gettext        # Provides envsubst
brew install --quiet stow
brew install --quiet antidote
brew install --quiet tmuxinator
brew install --quiet bat
brew install --quiet source-highlight
brew install --quiet yazi           # Terminal file browser
brew install --quiet fzf
brew install --quiet ripgrep
brew install --quiet direnv
brew install --quiet zoxide
brew install --quiet jupyter

# Shell alternatives and themes
echo "Installing shell alternatives and themes..."
brew install --quiet fish
brew install --quiet nushell
brew install --quiet starship

# Yazi preview dependencies
echo "Installing Yazi preview dependencies..."
brew install --quiet ffmpeg       # Video preview
brew install --quiet poppler      # PDF preview
brew install --quiet imagemagick  # Font, HEIC, JPEG XL preview
brew install --quiet resvg        # SVG preview
brew install --quiet sevenzip     # Archive extraction and preview
brew install --quiet jq           # JSON preview (already installed above, but listed for completeness)
brew install --quiet fd           # File searching (already installed above, but listed for completeness)

# Platform-specific packages
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	brew install --quiet xsel
fi

# Additional utilities
brew install --quiet nvimpager

# Desktop applications are managed separately
# Run .scripts/homebrew/install-desktop-apps.sh for GUI applications

# Install cht.sh
if ! command -v cht.sh &> /dev/null; then
	echo "Installing cht.sh..."
	curl -s https://cht.sh/:cht.sh > /tmp/cht.sh
	chmod +x /tmp/cht.sh
	
	# Determine Homebrew bin directory
	if [[ "$OSTYPE" == "darwin"* ]]; then
		if [[ -f "/opt/homebrew/bin/brew" ]]; then
			HOMEBREW_BIN="/opt/homebrew/bin"
		else
			HOMEBREW_BIN="/usr/local/bin"
		fi
	else
		HOMEBREW_BIN="/home/linuxbrew/.linuxbrew/bin"
	fi
	
	mv /tmp/cht.sh "$HOMEBREW_BIN/cht.sh"
	echo "cht.sh installed to $HOMEBREW_BIN/cht.sh"
fi

echo "Homebrew package installation complete"