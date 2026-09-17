#!/bin/bash

# Package manager detection.
# Sourced by initialize-packages.sh; sourceable on its own for tests:
#   source detect.sh --source-only

# get_package_manager [ostype]
# Prints the package manager to use. Priority:
#   1. DOTFILES_PACKAGE_MANAGER environment override
#   2. Shopify Spin marker -> nix
#   3. macOS -> homebrew
#   4. Linux: pacman (Arch/Omarchy) > linuxbrew > nix
get_package_manager() {
    local ostype="${1:-$OSTYPE}"

    if [[ -n "${DOTFILES_PACKAGE_MANAGER:-}" ]]; then
        echo "$DOTFILES_PACKAGE_MANAGER"
        return 0
    fi

    if [[ -f "/opt/dev/dev.sh" ]]; then
        echo "nix"
        return 0
    fi

    case "$ostype" in
        darwin*)
            echo "homebrew"
            ;;
        *)
            if command -v pacman &> /dev/null; then
                echo "pacman"
            elif command -v brew &> /dev/null; then
                echo "homebrew"
            else
                echo "nix"
            fi
            ;;
    esac
}

# dotfiles_os
# Prints "macos" or "linux" (anything non-Darwin is treated as linux).
dotfiles_os() {
    case "${1:-$OSTYPE}" in
        darwin*) echo "macos" ;;
        *)       echo "linux" ;;
    esac
}
