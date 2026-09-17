#!/bin/bash

# Arch Linux / Omarchy package installation via pacman (official repos) and
# yay (AUR). Mirrors the Homebrew package set in install-homebrew-packages.sh.
# Sourceable for validation:  source install-pacman-packages.sh --source-only

# Official-repo packages. Anything Omarchy already ships is skipped by --needed.
pacman_repo_packages() {
    cat <<'PKGS'
base-devel
git
zsh
tmux
neovim
unzip
bc
stow
gettext
lazygit
bat
source-highlight
yazi
fzf
ripgrep
fd
direnv
zoxide
jq
fish
nushell
starship
ffmpeg
poppler
imagemagick
resvg
7zip
wl-clipboard
jupyterlab
bats
PKGS
    # Omarchy ships mise as `mise-bin`, which conflicts with the `mise` package.
    command -v mise &> /dev/null || echo "mise"
}

# AUR packages (need yay). Kept separate so a missing AUR helper degrades to a
# warning instead of failing the whole bootstrap.
pacman_aur_packages() {
    cat <<'PKGS'
tmuxinator
nvimpager
PKGS
}

install_pacman_packages() {
    echo "********************************************************************************"
    echo "Installing pacman packages (Arch Linux / Omarchy)"
    echo "********************************************************************************"

    local -a repo aur
    mapfile -t repo < <(pacman_repo_packages)
    mapfile -t aur < <(pacman_aur_packages)

    echo "Refreshing package databases (sudo may ask for your password)..."
    sudo pacman -Sy --noconfirm

    echo "Installing ${#repo[@]} repo packages..."
    sudo pacman -S --needed --noconfirm "${repo[@]}"

    if command -v yay &> /dev/null; then
        echo "Installing ${#aur[@]} AUR packages via yay..."
        yay -S --needed --noconfirm --answerdiff None --answerclean None --removemake "${aur[@]}" \
            || echo "Warning: some AUR packages failed to install: ${aur[*]}"
    else
        echo "Warning: yay not found; skipping AUR packages: ${aur[*]}"
    fi

    echo "pacman package installation complete"
}

if [[ "${1:-}" == "--source-only" ]]; then
    return 0 2>/dev/null || true
fi

install_pacman_packages
