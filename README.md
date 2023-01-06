# About

Quy's dotfiles, aimed to be portable across platforms and environments

## Quickstark

Run this idempotent install script
```
./install.sh
```
👆 That will:
1. Install Nix if not already installed
2. Install Quy's commonly used packages (zsh, neovim, tmux, lazygit, etc)
3. Put symlinks for various dotfile configurations into  ~/
4. Reload the shell (zsh)

## Uses:
* nix-env 
  * As a cross-platform package manager
* gnu-stow
  * As a symlink manager to create symlinks into ~/
