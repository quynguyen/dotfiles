#!/bin/bash

# Package Management Initialization
# Abstracts package manager selection and delegates to appropriate implementation

#   - -e (errexit): Exit immediately if any command fails (non-zero exit code)
#   - -u (nounset): Exit if you try to use an undefined variable
#   - -o pipefail: Make pipes fail if any command in the pipe fails (not just the last one)
set -euo pipefail

# Determine which package manager to use
# Priority: Environment variable > OS detection > Default
get_package_manager() {
    # Allow override via environment variable
    if [[ -n "${DOTFILES_PACKAGE_MANAGER:-}" ]]; then
        echo "$DOTFILES_PACKAGE_MANAGER"
        return 0
    fi
    
    # Auto-detect based on environment
    if [[ -f "/opt/dev/dev.sh" ]]; then
        # Shopify Spin environment - use Nix
        echo "nix"
    elif command -v brew &> /dev/null; then
        # Homebrew is available - use it
        echo "homebrew"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux - prefer Nix
        echo "nix"
    else
        # Default to Homebrew for macOS
        echo "homebrew"
    fi
}

# Initialize package manager
initialize_package_manager() {
    local package_manager="$1"
    
    case "$package_manager" in
        "homebrew")
            echo "********************************************************************************"
            echo "Initializing Homebrew package management"
            echo "********************************************************************************"
            
            # Install/update Homebrew
            if [[ -f ".scripts/homebrew/install-homebrew.sh" ]]; then
                source .scripts/homebrew/install-homebrew.sh
            else
                echo "Warning: Homebrew installation script not found"
            fi
            
            # Install packages
            if [[ -f ".scripts/homebrew/install-homebrew-packages.sh" ]]; then
                source .scripts/homebrew/install-homebrew-packages.sh
            else
                echo "Warning: Homebrew packages script not found"
            fi
            ;;
        "nix")
            echo "********************************************************************************"
            echo "Initializing Nix package management"
            echo "********************************************************************************"
            
            # Install/update Nix packages
            if [[ -f ".scripts/nix/install-nix-packages.sh" ]]; then
                source .scripts/nix/install-nix-packages.sh
            else
                echo "Warning: Nix packages script not found"
                echo "Note: For Shopify Spin, packages are managed by dev environment"
            fi
            ;;
        *)
            echo "Error: Unknown package manager '$package_manager'"
            echo "Supported package managers: homebrew, nix"
            exit 1
            ;;
    esac
}

# Install packages required for a specific shell mode
install_shell_packages() {
    local mode="$1"
    local package_manager="$2"
    
    case "$package_manager" in
        "homebrew")
            case "$mode" in
                "zsh-starship")
                    if ! command -v starship &> /dev/null; then
                        echo "Installing starship via Homebrew..."
                        brew install --quiet starship
                    fi
                    ;;
                "fish")
                    if ! command -v fish &> /dev/null; then
                        echo "Installing fish via Homebrew..."
                        brew install --quiet fish
                    fi
                    ;;
                "nushell")
                    if ! command -v nu &> /dev/null; then
                        echo "Installing nushell via Homebrew..."
                        brew install --quiet nushell
                    fi
                    ;;
            esac
            
            # Install zoxide for smart directory navigation
            if ! command -v zoxide &> /dev/null; then
                echo "Installing zoxide via Homebrew..."
                brew install --quiet zoxide
            fi
            ;;
        "nix")
            # Nix package installation would go here
            # For now, assume packages are available in the environment
            case "$mode" in
                "zsh-starship")
                    if ! command -v starship &> /dev/null; then
                        echo "Warning: starship not found. Install via nix-env or add to configuration.nix"
                    fi
                    ;;
                "fish")
                    if ! command -v fish &> /dev/null; then
                        echo "Warning: fish not found. Install via nix-env or add to configuration.nix"
                    fi
                    ;;
                "nushell")
                    if ! command -v nu &> /dev/null; then
                        echo "Warning: nushell not found. Install via nix-env or add to configuration.nix"
                    fi
                    ;;
            esac
            
            # Check for zoxide
            if ! command -v zoxide &> /dev/null; then
                echo "Warning: zoxide not found. Install via nix-env or add to configuration.nix"
            fi
            ;;
    esac
}

# Always run package manager initialization when this script is sourced/executed
PACKAGE_MANAGER=$(get_package_manager)
echo "Using package manager: $PACKAGE_MANAGER"
initialize_package_manager "$PACKAGE_MANAGER"