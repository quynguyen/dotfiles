#!/bin/bash

echo "********************************************************************************"
echo "Stopping OpenMemory MCP Server"
echo "********************************************************************************"

# Define paths
OPENMEMORY_DIR="$HOME/Development/mem0/openmemory"

# Check if OpenMemory is set up
if [[ ! -d "$OPENMEMORY_DIR" ]]; then
    echo "Error: OpenMemory not found. Nothing to stop."
    exit 1
fi

cd "$OPENMEMORY_DIR" || exit 1

# Stop OpenMemory services
echo "Stopping OpenMemory services..."
docker-compose down

echo "********************************************************************************"
echo "OpenMemory stopped successfully!"
echo "********************************************************************************"
echo ""
echo "To start OpenMemory again, run: .scripts/openmemory/start-openmemory.sh"