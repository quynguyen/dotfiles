# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Repository Overview

This is Quy's personal dotfiles repository - a comprehensive development environment setup designed for cross-platform portability. It uses Homebrew for package management and GNU Stow for symlink management.

## Core Architecture

The repository follows a modular, script-driven architecture:

- **Main Entry**: `./install.sh` - Single idempotent installation script
- **Scripts**: `.scripts/` - Organized by tool/purpose (homebrew/, stow/, zsh/, etc.)
- **Configurations**: `.stow-packages/` - Individual "packages" managed by GNU Stow
- **Custom Utilities**: `.stow-packages/bin/` - Large collection of custom scripts

## Essential Commands

### Setup and Installation
```bash
# Complete environment setup (idempotent)
./install.sh

# Individual component setup
./.scripts/homebrew/install-homebrew-packages.sh
./.scripts/homebrew/install-custom-packages.sh
./.scripts/stow/create-home-dotfile-symlinks.sh
./.scripts/antidote/generated-zsh-plugins.sh
./.scripts/zsh/generate-home-zshrc.sh

# Desktop applications are automatically included on macOS
# Run separately if needed: ./.scripts/homebrew/install-desktop-apps.sh
```

### Package Management
```bash
# Install/update Homebrew packages
brew install package-name

# Update all Homebrew packages
brew update && brew upgrade

# Manage dotfile symlinks
stow -D package-name  # unstow
stow package-name     # stow
```

### Configuration Management
```bash
# Regenerate shell configuration
./.scripts/zsh/generate-zshrc.sh

# Update tmux plugins
tmux run-shell ~/.tmux/plugins/tpm/scripts/install_plugins.sh

# Update Neovim plugins (within nvim)
:Lazy sync
```

## Key Configuration Files

- `.stow-packages/zsh/.zshrc_template` - Main shell configuration template with variable substitution
- `.stow-packages/tmux/.tmux.conf` - Comprehensive tmux configuration 
- `.stow-packages/nvim/.config/nvim-lazyvim/` - Neovim setup using LazyVim distribution
- `.scripts/homebrew/install-homebrew-packages.sh` - Package definitions for Homebrew
- `.scripts/antidote/generated-zsh-plugins.sh` - Zsh plugin management with Antidote

## Tools and Systems Managed

**Core Development Stack:**
- Zsh with Powerlevel10k theme and Antidote plugin management
- Neovim with LazyVim distribution
- Tmux with custom keybindings and plugin ecosystem
- Git with custom configurations and Lazygit integration

**Command Line Tools:**
- lf (file manager), fzf (fuzzy finder), ripgrep, bat, direnv
- tmuxinator for session management
- Extensive collection of custom utilities in `bin/`

## Platform-Specific Features

- **Cross-Platform**: Homebrew ensures consistent package versions across macOS and Linux
- **Environment Adaptation**: Scripts detect and adapt to different environments
- **Desktop Apps Separation**: GUI applications are isolated from core CLI tools for maximum portability

### Desktop Applications (Automated on macOS)

The desktop applications are automatically installed on macOS as part of `./install.sh`:

**Automatically installs on:**
- Personal laptops and desktop computers (macOS)
- Local development environments

**Automatically skipped on:**
- Cloud servers and remote environments  
- Linux/WSL environments (not supported)
- Non-macOS systems

**Included desktop apps:**
- **JetBrains Mono Nerd Font** - Terminal font with programming ligatures and icons
- **Google Drive** - Cloud storage and file synchronization
- **Logseq** - Knowledge management and note-taking
- **Obsidian** - Note-taking and personal knowledge base
- **Codex Desktop** - Official Anthropic Codex AI desktop application
- **ChatGPT Desktop** - Official OpenAI ChatGPT desktop application
- **Claudia** - Community GUI toolkit for Codex (built from source)

**Manual usage (if needed):**
```bash
# Run separately from main installation (only if needed)
./.scripts/homebrew/install-desktop-apps.sh
```

**Build times:**
- Claudia: 10-15 minutes on first build (compiles Rust dependencies)
- Other apps: Install quickly via Homebrew casks

Note: Desktop apps require interactive installation (admin password) and are macOS-specific.

### Custom Package Management

The custom packages script (`.scripts/homebrew/install-custom-packages.sh`) handles tools not available through Homebrew:

**When to use:**
- Installing development tools not in Homebrew package registry
- Tools that require custom installation methods
- Runtime managers and language-specific toolchains

**Currently managed custom packages:**
- **Bun** - Fast all-in-one JavaScript runtime and package manager

**Installation process:**
- Uses official installation scripts when available
- Configures PATH and shell integration automatically
- Idempotent - safe to run multiple times
- Automatically called during `./install.sh`

**Usage:**
```bash
# Run separately (after Homebrew packages)
./.scripts/homebrew/install-custom-packages.sh
```

**Architecture benefits:**
- Clean separation between package managers
- Extensible for future custom installations (rustup, volta, etc.)
- Maintains dotfiles portability across environments

## Development Workflow

When making changes:
1. Test changes in isolation before running full `./install.sh`
2. Use individual scripts for specific components
3. Stow packages are modular - changes to one don't affect others
4. The `.zshrc` file is generated from template - edit `.zshrc_template` instead
5. Custom scripts go in appropriate subdirectories under `bin/`

## Important Notes

- Installation is idempotent - safe to run multiple times
- Uses GNU Stow for symlink management - files are linked, not copied
- Zsh configuration is template-based with variable substitution
- Git submodules are used for tmux plugins
- Homebrew provides consistent package management across platforms
- Custom AI assistant configurations in `.cursor/` and `.Codex/` directories