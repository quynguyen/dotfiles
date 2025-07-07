#!/bin/bash

echo "********************************************************************************"
echo "Starting OpenMemory MCP Server"
echo "********************************************************************************"

# Define paths
OPENMEMORY_DIR="$HOME/Development/mem0/openmemory"

# Check if OpenMemory is set up
if [[ ! -d "$OPENMEMORY_DIR" ]]; then
    echo "Error: OpenMemory not found. Please run setup-openmemory.sh first."
    exit 1
fi

cd "$OPENMEMORY_DIR" || exit 1

# Check if environment files exist
if [[ ! -f "api/.env" ]] || [[ ! -f "ui/.env" ]]; then
    echo "Error: Environment files not found. Please run setup-openmemory.sh first."
    exit 1
fi

# Verify Docker Desktop is installed and running
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed."
    echo "Docker Desktop should be installed via: .scripts/homebrew/install-desktop-apps.sh"
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker is not running."
    echo "Please launch Docker Desktop from Applications and wait for it to start."
    exit 1
fi

# Build and start OpenMemory
echo "Building OpenMemory containers..."
make build

echo "Starting OpenMemory services..."
make up

echo "********************************************************************************"
echo "OpenMemory is starting up!"
echo "********************************************************************************"
echo ""
echo "Services will be available at:"
echo "- MCP Server: http://localhost:8765"
echo "- Web UI: http://localhost:3000"
echo ""
echo "To stop OpenMemory, run: .scripts/openmemory/stop-openmemory.sh"
echo "To view logs, run: docker-compose logs -f"