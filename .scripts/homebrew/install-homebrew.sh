#!/bin/bash

echo "********************************************************************************"
echo "Installing/Updating Homebrew"
echo "********************************************************************************"

set -e

# Install Homebrew (if not already installed)
if ! command -v brew &> /dev/null; then
	echo "Installing Homebrew..."
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Detect platform and set Homebrew path
if [[ "$OSTYPE" == "darwin"* ]]; then
	# macOS
	if [[ -f "/opt/homebrew/bin/brew" ]]; then
		# Apple Silicon
		HOMEBREW_PREFIX="/opt/homebrew"
	else
		# Intel
		HOMEBREW_PREFIX="/usr/local"
	fi
else
	# Linux
	HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
fi

# Add Homebrew to PATH for current session
export PATH="$HOMEBREW_PREFIX/bin:$PATH"

# Update Homebrew
echo "Updating Homebrew..."
brew update

echo "Homebrew installation/update complete"