#!/bin/bash

echo "********************************************************************************"
echo "Installing mise-managed language runtimes"
echo "********************************************************************************"

if ! command -v mise &> /dev/null; then
    echo "Warning: mise not found on PATH; skipping tool install."
    echo "Ensure 'brew install mise' ran earlier in the bootstrap."
    return 0 2>/dev/null || exit 0
fi

if [[ ! -f "$HOME/.config/mise/config.toml" ]]; then
    echo "Warning: ~/.config/mise/config.toml not found; skipping tool install."
    echo "Ensure the mise stow package was deployed (create-home-dotfile-symlinks.sh)."
    return 0 2>/dev/null || exit 0
fi

mise install
