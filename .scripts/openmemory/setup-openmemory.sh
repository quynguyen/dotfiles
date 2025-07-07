#!/bin/bash

echo "********************************************************************************"
echo "Setting up OpenMemory MCP Server"
echo "********************************************************************************"

# Define paths
OPENMEMORY_DIR="$HOME/Development/openmemory"
CONFIG_DIR="$HOME/.config/openmemory"

# Create Development directory if it doesn't exist
mkdir -p "$HOME/Development"

# Clone OpenMemory repository if it doesn't exist
if [[ ! -d "$OPENMEMORY_DIR" ]]; then
    echo "Cloning OpenMemory repository..."
    git clone https://github.com/mem0ai/mem0.git "$HOME/Development/mem0"
    # The openmemory MCP server is in the openmemory subdirectory
    OPENMEMORY_DIR="$HOME/Development/mem0/openmemory"
else
    echo "OpenMemory repository already exists at $OPENMEMORY_DIR"
fi

# Navigate to the openmemory directory
if [[ -d "$HOME/Development/mem0/openmemory" ]]; then
    OPENMEMORY_DIR="$HOME/Development/mem0/openmemory"
elif [[ -d "$OPENMEMORY_DIR" ]]; then
    # Already set correctly
    :
else
    echo "Error: Could not find OpenMemory directory"
    exit 1
fi

cd "$OPENMEMORY_DIR" || exit 1

# Check if environment files exist, if not copy from templates
echo "Setting up environment files..."

if [[ ! -f "api/.env" ]]; then
    if [[ -f "$CONFIG_DIR/api.env" ]]; then
        echo "Copying API environment from ~/.config/openmemory/api.env"
        cp "$CONFIG_DIR/api.env" "api/.env"
    else
        echo "Warning: No API environment file found. Please:"
        echo "1. Copy ~/.config/openmemory/api.env.template to ~/.config/openmemory/api.env"
        echo "2. Edit api.env with your OpenAI API key and user ID"
        echo "3. Run this script again"
        exit 1
    fi
else
    echo "API environment file already exists"
fi

if [[ ! -f "ui/.env" ]]; then
    if [[ -f "$CONFIG_DIR/ui.env" ]]; then
        echo "Copying UI environment from ~/.config/openmemory/ui.env"
        cp "$CONFIG_DIR/ui.env" "ui/.env"
    else
        echo "Warning: No UI environment file found. Please:"
        echo "1. Copy ~/.config/openmemory/ui.env.template to ~/.config/openmemory/ui.env"
        echo "2. Edit ui.env with your configuration"
        echo "3. Run this script again"
        exit 1
    fi
else
    echo "UI environment file already exists"
fi

# Verify Docker Desktop is installed and running
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed."
    echo "Docker Desktop should be installed via: .scripts/homebrew/install-desktop-apps.sh"
    echo "Or run the full installation: ./install.sh"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is not running."
    echo "Please:"
    echo "  1. Launch Docker Desktop from Applications"
    echo "  2. Wait for Docker Desktop to start (may take a minute)"
    echo "  3. Try running this script again"
    exit 1
fi

echo "********************************************************************************"
echo "OpenMemory setup complete!"
echo "********************************************************************************"
echo ""
echo "Next steps:"
echo "1. Edit ~/.config/openmemory/api.env with your OpenAI API key"
echo "2. Edit ~/.config/openmemory/ui.env with your user ID"
echo "3. Run: .scripts/openmemory/start-openmemory.sh"
echo ""
echo "OpenMemory will be available at:"
echo "- MCP Server: http://localhost:8765"
echo "- Web UI: http://localhost:3000"