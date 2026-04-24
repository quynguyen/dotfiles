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
brew install make || true  # May already be installed
brew install gcc || true   # May already be installed  
brew install git || true   # May already be installed
brew install zsh || true   # May already be installed
brew install tmux
brew install neovim
brew install unzip || true # May already be installed

# Language runtimes are managed by mise (~/.config/mise/config.toml).
# mise installs node, pnpm, ruby, bun, and rust from its config after stow.
echo "Installing mise (language runtime manager)..."
brew install mise

# CLI utilities
echo "Installing CLI utilities..."
brew install lazygit
brew install gettext        # Provides envsubst
brew install stow
brew install antidote
brew install tmuxinator
brew install bat
brew install source-highlight
brew install yazi           # Terminal file browser
brew install fzf
brew install ripgrep
brew install direnv
brew install zoxide
brew install jupyter

# Shell alternatives and themes
echo "Installing shell alternatives and themes..."
brew install fish
brew install nushell
brew install starship

# Yazi preview dependencies
echo "Installing Yazi preview dependencies..."
brew install ffmpeg       # Video preview
brew install poppler      # PDF preview
brew install imagemagick  # Font, HEIC, JPEG XL preview
brew install resvg        # SVG preview
brew install sevenzip     # Archive extraction and preview
brew install jq           # JSON preview (already installed above, but listed for completeness)
brew install fd           # File searching (already installed above, but listed for completeness)

# Platform-specific packages
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	brew install xsel
fi

# Additional utilities
brew install nvimpager

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