# About

Quy's dotfiles, aimed to be portable across platforms and environments

## Quickstark

Run this idempotent install script
```
./install.sh
```
👆 That will:
1. Pick a package manager for the platform (see below) and install it if needed
2. Install Quy's commonly used packages (zsh, neovim, tmux, lazygit, etc)
3. Put symlinks for various dotfile configurations into  ~/
4. Install mise-managed runtimes, make zsh the login shell, install shell/tmux/nvim plugins
5. Reload the shell (zsh)

## Platforms

| Platform | Package manager | Notes |
|---|---|---|
| macOS | Homebrew | also installs desktop apps (casks) |
| Arch Linux / Omarchy (e.g. `leopard`) | pacman + yay (AUR) | `sudo` will prompt for your password |
| other Linux | Linuxbrew if present, else Nix | |

Override detection with `DOTFILES_PACKAGE_MANAGER=homebrew|pacman|nix ./install.sh`.

On Linux the macOS-only stow packages (`karabiner`, `raycast`, `launchagents`,
`logseq`, `espanso`, `ghostty`) are skipped. Any pre-existing file that would
block a symlink (for example the configs Omarchy ships in `~/.config`) is moved
to `~/.dotfiles-backup/<timestamp>/` with its relative path preserved, and the
install prints what it moved.

## Tests

```
bats .scripts/tests/
```

## Uses:
* homebrew / pacman / nix
  * As the package manager, chosen per platform
* gnu-stow
  * As a symlink manager to create symlinks into ~/
* mise
  * For language runtimes; config is layered from `~/.config/mise/conf.d/dotfiles.toml`
    so an OS-provided `~/.config/mise/config.toml` (Omarchy) keeps working
