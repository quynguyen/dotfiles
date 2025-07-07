# OpenMemory Setup Quick Guide

## What was added to your dotfiles:

### 1. Docker Support
- **File**: `.scripts/homebrew/install-desktop-apps.sh`
- **Added**: Docker Desktop installation via Homebrew cask
- **Includes**: Docker and Docker Compose
- **Note**: Moved to desktop apps to avoid password prompts during CLI package installation

### 2. OpenMemory Configuration
- **Directory**: `.stow-packages/openmemory/.config/openmemory/`
- **Files**:
  - `api.env.template` - API configuration template
  - `ui.env.template` - UI configuration template  
  - `README.md` - Detailed setup documentation

### 3. Claude Code MCP Integration
- **File**: `.stow-packages/claude-code/.claude/settings.json`
- **Added**: `open-memory` MCP server pointing to `http://localhost:8765`

### 4. Management Scripts
- **Directory**: `.scripts/openmemory/`
- **Scripts**:
  - `setup-openmemory.sh` - Initial setup and repository cloning
  - `start-openmemory.sh` - Start OpenMemory services
  - `stop-openmemory.sh` - Stop OpenMemory services

### 5. Installation Integration
- **File**: `install.sh`
- **Added**: Optional OpenMemory setup during dotfiles installation

## Quick Start (Next Steps):

1. **Run Installation** (if not done yet):
   ```bash
   ./install.sh
   ```
   - Say "y" when prompted about OpenMemory setup

2. **Configure API Keys**:
   ```bash
   cp ~/.config/openmemory/api.env.template ~/.config/openmemory/api.env
   cp ~/.config/openmemory/ui.env.template ~/.config/openmemory/ui.env
   ```
   
   Edit `~/.config/openmemory/api.env` with your OpenAI API key:
   ```
   OPENAI_API_KEY=sk-your-actual-api-key
   USER=your-unique-user-id
   ```

3. **Start OpenMemory**:
   ```bash
   ./.scripts/openmemory/start-openmemory.sh
   ```

4. **Access Services**:
   - MCP Server: http://localhost:8765 (automatically used by Claude Code)
   - Web UI: http://localhost:3000 (for memory management)

## Benefits:

- **Persistent Memory**: Context maintained across chat sessions
- **Cross-Platform**: Works with different AI tools
- **Portable**: Configuration travels with your dotfiles
- **Automated**: One-command setup and management
- **Integrated**: Seamlessly works with Claude Code via MCP