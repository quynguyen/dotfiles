#!/bin/bash

# go there the directory of this currently 'sourced' script ( quietly )
pushd $(dirname ${BASH_SOURCE:-$0}) >/dev/null

# Package Management (Homebrew/Nix/etc)
source .scripts/package-management/initialize-packages.sh

# $HOME dotfiles
source .scripts/stow/create-home-dotfile-symlinks.sh

# mise-managed language runtimes (needs stow symlink for ~/.config/mise/config.toml)
source .scripts/mise/install-mise-tools.sh

# Shell-specific initialization
source .scripts/shells/initialize-shell.sh

# Tmux Plugins
source .scripts/tmux/install-tmux-plugins.sh

# Neovim plugins
source .scripts/nvim/install-nvim-plugins.sh

# Desktop applications (macOS only, optional but automated)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "********************************************************************************"
    echo "Installing Desktop Applications"
    echo "********************************************************************************"
    source .scripts/homebrew/install-desktop-apps.sh
else
    echo "Skipping desktop applications (not on macOS)"
fi

# OpenMemory MCP Server setup (optional)
# Check if OpenMemory is already set up
OPENMEMORY_REPO_EXISTS=false
OPENMEMORY_CONFIG_EXISTS=false
OPENMEMORY_RUNNING=false

if [[ -d "$HOME/Development/mem0/openmemory" ]]; then
    OPENMEMORY_REPO_EXISTS=true
fi

if [[ -f ~/.config/openmemory/api.env ]] && [[ -f ~/.config/openmemory/ui.env ]]; then
    OPENMEMORY_CONFIG_EXISTS=true
fi

if command -v docker &> /dev/null && docker ps --filter "name=openmemory" --format "table {{.Names}}" 2>/dev/null | grep -q "openmemory"; then
    OPENMEMORY_RUNNING=true
fi

# Only prompt if OpenMemory is not fully set up
if [[ "$OPENMEMORY_REPO_EXISTS" == true ]] && [[ "$OPENMEMORY_CONFIG_EXISTS" == true ]]; then
    echo "********************************************************************************"
    echo "OpenMemory MCP Server Setup"
    echo "********************************************************************************"
    echo "✅ OpenMemory is already set up!"
    
    if [[ "$OPENMEMORY_RUNNING" == true ]]; then
        echo "✅ OpenMemory services are running"
        echo "   - MCP Server: http://localhost:8765"
        echo "   - Web UI: http://localhost:3000"
    else
        echo "💡 To start OpenMemory services, run: .scripts/openmemory/start-openmemory.sh"
    fi
    
    echo "💡 To manage memories, visit: http://localhost:3000"
else
    echo "********************************************************************************"
    echo "OpenMemory MCP Server Setup"
    echo "********************************************************************************"
    echo "OpenMemory provides persistent memory across chat sessions and AI platforms."
    echo "Setup requires:"
    echo "  - Docker Desktop (installed with desktop apps)"
    echo "  - OpenAI API key (user-provided)"
    echo ""
    read -p "Do you want to set up OpenMemory? (y/N): " setup_openmemory
    if [[ "$setup_openmemory" =~ ^[Yy]$ ]]; then
        # Ensure stow packages are deployed first
        if [[ ! -f ~/.config/openmemory/api.env.template ]]; then
            echo "Deploying OpenMemory configuration templates..."
            cd .stow-packages && stow openmemory --target ~/
            cd ..
        fi
        
        echo "Running OpenMemory setup..."
        source .scripts/openmemory/setup-openmemory.sh
    else
        echo "Skipping OpenMemory setup (you can run '.scripts/openmemory/setup-openmemory.sh' later)"
    fi
fi

# Reload the shell based on configured preference
source .scripts/shells/reload_shell.sh

# go back to working directory ( quietly )
popd >/dev/null
