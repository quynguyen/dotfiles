# OpenMemory MCP Server Setup

OpenMemory provides persistent memory across different chat sessions and AI platforms, allowing you to maintain context and continuity in your conversations.

## Prerequisites

- Docker Desktop (installed with desktop applications)
- OpenAI API key
- Python 3.9+ (system/Homebrew)
- Node.js (installed via dotfiles)

## Setup Process

### 1. Initial Setup

Run the automated setup during dotfiles installation:
```bash
./install.sh
```

Or manually:
```bash
./.scripts/openmemory/setup-openmemory.sh
```

### 2. Configure API Keys

Copy and edit the environment templates:

```bash
# Copy templates to active configuration
cp ~/.config/openmemory/api.env.template ~/.config/openmemory/api.env
cp ~/.config/openmemory/ui.env.template ~/.config/openmemory/ui.env
```

Edit `~/.config/openmemory/api.env`:
```bash
OPENAI_API_KEY=sk-your-actual-openai-api-key-here
USER=your-unique-user-id
```

Edit `~/.config/openmemory/ui.env`:
```bash
NEXT_PUBLIC_API_URL=http://localhost:8765
NEXT_PUBLIC_USER_ID=your-unique-user-id
```

### 3. Start OpenMemory

```bash
./.scripts/openmemory/start-openmemory.sh
```

### 4. Access OpenMemory

- **MCP Server**: http://localhost:8765 (used by Claude Code)
- **Web UI**: http://localhost:3000 (for managing memories)

## Usage

### In Claude Code

Once OpenMemory is running, the `open-memory` MCP server will be automatically available in Claude Code. You can:

- Store memories across sessions
- Retrieve relevant context automatically
- Manage persistent information

### Via Web UI

Use the web interface at http://localhost:3000 to:

- View stored memories
- Manually add/edit memories
- Search through your memory database
- Manage user profiles

## Management Commands

```bash
# Start OpenMemory
./.scripts/openmemory/start-openmemory.sh

# Stop OpenMemory  
./.scripts/openmemory/stop-openmemory.sh

# View logs
cd ~/Development/mem0/openmemory && docker-compose logs -f

# Rebuild containers (if needed)
cd ~/Development/mem0/openmemory && make build
```

## Troubleshooting

### Docker Issues
- Ensure Docker Desktop is installed via `.scripts/homebrew/install-desktop-apps.sh`
- Launch Docker Desktop from Applications and wait for it to start
- Check `docker info` works without errors
- Docker Desktop requires admin privileges during installation

### Environment Issues
- Verify API keys are correctly set in `~/.config/openmemory/api.env`
- Ensure user IDs match between API and UI configurations

### Port Conflicts
- Default ports: 8765 (API), 3000 (UI)
- Check no other services are using these ports

### Memory Issues
- Memories are stored in Docker volumes
- To reset: `docker-compose down -v` (WARNING: deletes all memories)

## File Structure

```
~/.config/openmemory/
├── README.md                 # This file
├── api.env.template          # API configuration template
├── ui.env.template           # UI configuration template
├── api.env                   # Your actual API configuration (not in git)
└── ui.env                    # Your actual UI configuration (not in git)

~/Development/mem0/openmemory/
├── api/                      # OpenMemory API service
├── ui/                       # OpenMemory web interface
├── docker-compose.yml        # Docker services configuration
└── Makefile                  # Build and run commands
```

## Security Notes

- Never commit `api.env` or `ui.env` files to git (they contain secrets)
- Templates are safe to commit and share
- API keys should be kept secure and rotated regularly