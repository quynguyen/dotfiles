#!/bin/bash

echo "********************************************************************************"
echo "Installing Desktop Applications (macOS only)"
echo "********************************************************************************"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "Desktop applications are only supported on macOS. Skipping..."
    exit 0
fi

# Ensure Homebrew is in PATH
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    # Apple Silicon
    export PATH="/opt/homebrew/bin:$PATH"
else
    # Intel
    export PATH="/usr/local/bin:$PATH"
fi

# Check if Homebrew is available
if ! command -v brew &> /dev/null; then
    echo "Error: Homebrew not found. Please install Homebrew first."
    exit 1
fi

echo "Installing desktop applications..."
echo "Note: These installations may require administrator password."

# JetBrains Mono Nerd Font for terminal icons and powerline symbols
echo "Installing JetBrains Mono Nerd Font..."
brew install --quiet --cask font-jetbrains-mono-nerd-font

# Google Drive for desktop
echo "Installing Google Drive..."
brew install --quiet --cask google-drive

# Logseq for knowledge management
echo "Installing Logseq..."
brew install --quiet --cask logseq

# Obsidian for note-taking and personal knowledge base
echo "Installing Obsidian..."
brew install --quiet --cask obsidian

# Claude Desktop - Official Anthropic Claude AI desktop app
echo "Installing Claude Desktop..."
brew install --quiet --cask claude

# ChatGPT Desktop - Official OpenAI ChatGPT desktop app
echo "Installing ChatGPT Desktop..."
brew install --quiet --cask chatgpt

# Docker Desktop - Container management and development (includes Docker Compose)
echo "Installing Docker Desktop..."
brew install --quiet --cask docker

# Visual Studio Code - Code editor
echo "Installing Visual Studio Code..."
brew install --quiet --cask visual-studio-code

# Espanso - Universal text expander / keyboard macros (cross-platform)
echo "Installing Espanso..."
brew install --quiet --cask espanso

# Claudia - Community GUI toolkit for Claude Code (build from source)
echo "Installing Claudia (Claude GUI toolkit)..."
CLAUDIA_DIR="$HOME/Development/claudia"
CLAUDIA_APP="/Applications/Claudia.app"

if [[ ! -d "$CLAUDIA_APP" ]]; then
    echo "Claudia not found, building from source..."
    
    # Create Development directory if it doesn't exist
    mkdir -p "$HOME/Development"
    
    # Clone or update Claudia repository
    if [[ ! -d "$CLAUDIA_DIR" ]]; then
        echo "Cloning Claudia repository..."
        git clone https://github.com/getAsterisk/claudia.git "$CLAUDIA_DIR"
    else
        echo "Updating Claudia repository..."
        cd "$CLAUDIA_DIR" && git pull origin main
    fi
    
    # Build Claudia
    cd "$CLAUDIA_DIR"
    
    # Bun and Rust are provided by mise (see ~/.config/mise/config.toml).
    if ! command -v bun &> /dev/null; then
        echo "Error: Bun is required to build Claudia. Ensure mise is installed and 'mise install' has run."
        echo "PATH: $PATH"
        return 1
    fi

    if ! command -v rustc &> /dev/null; then
        echo "Error: Rust is required to build Claudia. Ensure mise is installed and 'mise install' has run."
        echo "PATH: $PATH"
        return 1
    fi
    
    echo "✅ Dependencies found: Bun $(bun --version), Rust $(rustc --version | cut -d' ' -f2)"
    
    echo "Installing frontend dependencies..."
    bun install
    
    echo "Building Claudia (this may take 10-15 minutes on first build)..."
    echo "Status: Compiling Rust dependencies and building application..."
    echo "Please be patient - this is downloading and compiling hundreds of Rust crates..."
    
    # Run build with better error handling (no timeout on macOS)
    echo "Starting Claudia build (no timeout - will run until completion)..."
    if bun run tauri build; then
        echo "✅ Claudia build completed successfully!"
    else
        EXIT_CODE=$?
        echo "❌ Claudia build failed with exit code $EXIT_CODE"
        echo "This could be due to:"
        echo "  - Missing dependencies (Rust/Bun not in PATH)"
        echo "  - Network issues downloading dependencies"
        echo "  - Compilation errors"
        echo "You can try building manually:"
        echo "  cd ~/Development/claudia && export PATH=\"\$HOME/.bun/bin:\$PATH\" && bun run tauri build"
        echo "Continuing with other installations..."
        return 1
    fi
    
    # Install the built app
    if [[ -d "src-tauri/target/release/bundle/macos/Claudia.app" ]]; then
        echo "Installing Claudia to Applications..."
        cp -r "src-tauri/target/release/bundle/macos/Claudia.app" "/Applications/"
        echo "✅ Claudia installed successfully!"
    else
        echo "❌ Error: Claudia app bundle not found after build"
        echo "Build may have failed or produced output in different location"
        echo "Check ~/Development/claudia/src-tauri/target/release/bundle/ for build artifacts"
        return 1
    fi
else
    echo "✅ Claudia already installed"
fi

echo "********************************************************************************"
echo "Desktop applications installation complete"
echo "********************************************************************************"
echo ""
echo "Applications installed:"
echo "  - JetBrains Mono Nerd Font (for terminal)"
echo "  - Google Drive (cloud storage)"
echo "  - Logseq (knowledge management)"
echo "  - Obsidian (note-taking and personal knowledge base)"
echo "  - Claude Desktop (official Anthropic AI app)"
echo "  - ChatGPT Desktop (official OpenAI app)"
echo "  - Docker Desktop (container management and development)"
echo "  - Visual Studio Code (code editor)"
echo "  - Claudia (community GUI toolkit for Claude Code)
  - Espanso (universal text expander / keyboard macros)"
echo ""
echo "You may need to:"
echo "  1. Launch Google Drive and sign in"
echo "  2. Configure your terminal to use JetBrains Mono Nerd Font"
echo "  3. Launch Logseq and set up your knowledge base"
echo "  4. Launch Claude Desktop and ChatGPT Desktop to sign in"
echo "  5. Launch Docker Desktop and complete setup"
echo "  6. Launch Claudia to set up your Claude Code GUI toolkit"