# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is Quy's personal dotfiles repository - a comprehensive development environment setup designed for cross-platform portability. It uses Homebrew (macOS) or pacman/yay (Arch Linux, incl. Omarchy) for package management and GNU Stow for symlink management. Runs on the Mac and on `leopard`, an always-on Omarchy server reachable via `ssh quy@leopard` (Tailscale).

## Core Architecture

The repository follows a modular, script-driven architecture:

- **Main Entry**: `./install.sh` - Single idempotent installation script
- **Scripts**: `.scripts/` - Organized by tool/purpose (homebrew/, stow/, zsh/, etc.)
- **Configurations**: `.stow-packages/` - Individual "packages" managed by GNU Stow
- **Custom Utilities**: `.stow-packages/bin/` - Large collection of custom scripts

## Platform Handling

- `.scripts/package-management/detect.sh` picks the package manager: Spin -> nix; macOS -> homebrew; Linux -> pacman if present, else linuxbrew, else nix. `DOTFILES_PACKAGE_MANAGER` overrides.
- `.scripts/pacman/install-pacman-packages.sh` mirrors the Homebrew package list for Arch (repo packages via `sudo pacman`, AUR via `yay`). Keep the two lists in sync when adding tools.
- `.scripts/stow/lib.sh` owns the list of macOS-only stow packages (`MACOS_ONLY_STOW_PACKAGES`) and `backup_conflicts`, which moves pre-existing target files to `~/.dotfiles-backup/<timestamp>/` before stowing. It never descends into symlinks that already point into `.stow-packages` (folded links) - walking through them would move the repo's own files.
- `DOTFILES_OWNED_DIRS` (same file) lists target directories we own outright, currently just `.config/nvim`. A pre-existing real directory there is moved aside whole instead of merged file-by-file, so stow can fold the path into one symlink and the OS's leftovers (Omarchy ships its own LazyVim config) do not load alongside ours. Symlinks from an earlier stow run are pruned first so the backup holds only the OS's files.
- mise config lives in `.stow-packages/mise/.config/mise/conf.d/dotfiles.toml` so Omarchy's own `~/.config/mise/config.toml` (claude, codex, gh) is left intact.
- Clipboard: `~/.bin/xcopy` and `~/.bin/xpaste` choose pbcopy / wl-copy / xclip / xsel and are the single place that decision lives. tmux's copy-mode bindings pipe to `xcopy`, and on non-macOS the zsh `pbcopy`/`pbpaste` aliases are just those two scripts. Both need `WAYLAND_DISPLAY` to pick wl-copy, so over SSH with no display they fall back rather than failing to reach a Wayland server.
- tmux applies `~/.tmux.conf` **and** `$XDG_CONFIG_HOME/tmux/tmux.conf`, in that order, so on Omarchy the OS's config wins every option both set. `.tmux.conf` hooks `session-created` (the first point at which every config file has been read) to re-source `~/.tmux/includes/after-os-config.tmux.conf` and take back what we want - currently only `status-right`. Keep that list short: anything reclaimed there stops following `omarchy theme set`. It is Linux-only, because macOS has no such file and re-applying would clobber the dracula bar. Omarchy's migrations edit `~/.config/tmux/tmux.conf` in place, so never write to it.
- The nvim daily-update LaunchAgent is macOS-only on purpose: only one machine should commit `lazy-lock.json`. `nvim-update.sh` neither pulls nor pushes, so a second writer means divergent histories to merge by hand. devbook writes the pins; leopard reproduces them.
- Bootstrapping nvim is a reproduce step, not an authoring one. lazy.nvim's `install` clones and checks out the *branch head*, ignoring the lockfile (only `restore` reads it, and `restore` never clones). A bare `nvim --headless +qa` on a fresh machine therefore installs everything at latest and rewrites `lazy-lock.json`. `.scripts/nvim/install-nvim-plugins-lazyvim.sh` runs `Lazy! install` then `Lazy! restore`, and puts the lockfile back if it moved.
- Tests: `bats .scripts/tests/` (platform detection, stow selection, conflict backup, nvim-update).

## Essential Commands

### Setup and Installation
```bash
# Complete environment setup (idempotent)
./install.sh

# Individual component setup
./.scripts/homebrew/install-homebrew-packages.sh   # macOS
./.scripts/pacman/install-pacman-packages.sh       # Arch / Omarchy
./.scripts/stow/create-home-dotfile-symlinks.sh
./.scripts/antidote/generated-zsh-plugins.sh
./.scripts/shells/set-login-shell.sh

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
# Regenerate the antidote plugin bundle (~/.zsh_plugins.sh) after editing
# .zsh_plugins_base.txt / .zsh_plugins_p10k.txt
./.scripts/antidote/generated-zsh-plugins.sh

# Update tmux plugins (or just re-run the script, which installs then updates)
./.scripts/tmux/install-tmux-plugins.sh

# Update Neovim plugins (within nvim)
:Lazy sync
```

## Key Configuration Files

- `.stow-packages/zsh/.zshrc` - Main shell configuration, stowed directly to `~/.zshrc` (no templating)
- `.stow-packages/zsh/.zsh/` - Sourced fragments (aliases, functions) that `.zshrc` pulls in
- `.stow-packages/tmux/.tmux.conf` - Comprehensive tmux configuration
- `.stow-packages/nvim/.config/nvim/` - Neovim setup using LazyVim distribution
- `.stow-packages/mise/.config/mise/conf.d/dotfiles.toml` - Language runtimes (node, pnpm, ruby, bun, rust, python)
- `.scripts/homebrew/install-homebrew-packages.sh` - Package definitions for Homebrew (macOS)
- `.scripts/pacman/install-pacman-packages.sh` - Package definitions for pacman/yay (Arch/Omarchy)
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

- **Cross-Platform**: Homebrew on macOS, pacman/yay on Arch/Omarchy, Nix elsewhere; stow packages that only make sense on macOS are skipped on Linux
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
- **Claude Desktop** - Official Anthropic Claude AI desktop application
- **ChatGPT Desktop** - Official OpenAI ChatGPT desktop application
- **Claudia** - Community GUI toolkit for Claude Code (built from source)

**Manual usage (if needed):**
```bash
# Run separately from main installation (only if needed)
./.scripts/homebrew/install-desktop-apps.sh
```

**Build times:**
- Claudia: 10-15 minutes on first build (compiles Rust dependencies)
- Other apps: Install quickly via Homebrew casks

Note: Desktop apps require interactive installation (admin password) and are macOS-specific.

### Language Runtimes

Runtimes are managed by mise, not by a bespoke installer. They are declared in
`.stow-packages/mise/.config/mise/conf.d/dotfiles.toml` (node, pnpm, ruby, bun,
rust, python) and installed by `.scripts/mise/install-mise-tools.sh` during
`./install.sh`.

Because the dotfiles ship `conf.d/dotfiles.toml` rather than `config.toml`, an
OS-provided `~/.config/mise/config.toml` (Omarchy's, holding claude/codex/gh)
keeps working and both layers apply. Check what is active with `mise config ls`.

To add a runtime, edit `dotfiles.toml` and re-run `./install.sh` (or `mise install`).

## Development Workflow

When making changes:
1. Test changes in isolation before running full `./install.sh`
2. Use individual scripts for specific components
3. Stow packages are modular - changes to one don't affect others
4. `.zshrc` is stowed directly - edit `.stow-packages/zsh/.zshrc` (or a fragment under `.stow-packages/zsh/.zsh/`)
5. Custom scripts go in appropriate subdirectories under `bin/`
6. Run `bats .scripts/tests/` after touching anything under `.scripts/`

## Important Notes

- Installation is idempotent - safe to run multiple times
- Uses GNU Stow for symlink management - files are linked, not copied
- Zsh configuration is stowed as-is; there is no template step
- Git submodules are used for tmux plugins (tpm). Scope submodule commands to
  that path - unrelated gitlinks in the tree would otherwise break them
- Package management is per-platform: Homebrew on macOS, pacman/yay on
  Arch/Omarchy, Nix elsewhere
- Custom AI assistant configurations live in `.stow-packages/llm/` (`.claude/`,
  `.agents/`, `.gemini/`) and `.codex/`