#!/usr/bin/env bats

# Cross-platform bootstrap logic: package manager detection, stow package
# selection, and conflict backup.
# Run: bats ~/dotfiles/.scripts/tests/platform.bats

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

setup() {
  source "$REPO_DIR/.scripts/package-management/detect.sh" --source-only
  source "$REPO_DIR/.scripts/stow/lib.sh" --source-only
  WORK="$(mktemp -d)"
  FAKEBIN="$WORK/bin"
  mkdir -p "$FAKEBIN"
  unset DOTFILES_PACKAGE_MANAGER
}

teardown() {
  rm -rf "$WORK"
}

fake_cmd() {
  printf '#!/bin/sh\nexit 0\n' > "$FAKEBIN/$1"
  chmod +x "$FAKEBIN/$1"
}

# --- get_package_manager ------------------------------------------------------

@test "get_package_manager honours DOTFILES_PACKAGE_MANAGER override" {
  DOTFILES_PACKAGE_MANAGER=nix
  result=$(get_package_manager darwin24)
  [[ "$result" == "nix" ]]
}

@test "get_package_manager picks homebrew on macOS" {
  result=$(PATH="$FAKEBIN" get_package_manager darwin24)
  [[ "$result" == "homebrew" ]]
}

@test "get_package_manager picks pacman on Arch-based Linux" {
  fake_cmd pacman
  result=$(PATH="$FAKEBIN" get_package_manager linux-gnu)
  [[ "$result" == "pacman" ]]
}

@test "get_package_manager prefers pacman over an installed linuxbrew" {
  fake_cmd pacman
  fake_cmd brew
  result=$(PATH="$FAKEBIN" get_package_manager linux-gnu)
  [[ "$result" == "pacman" ]]
}

@test "get_package_manager picks homebrew on Linux when only brew is present" {
  fake_cmd brew
  result=$(PATH="$FAKEBIN" get_package_manager linux-gnu)
  [[ "$result" == "homebrew" ]]
}

@test "get_package_manager falls back to nix on Linux without pacman or brew" {
  result=$(PATH="$FAKEBIN" get_package_manager linux-gnu)
  [[ "$result" == "nix" ]]
}

# --- stow_packages_for_os -----------------------------------------------------

@test "stow_packages_for_os on linux drops macOS-only packages" {
  pkgs="$WORK/pkgs"
  mkdir -p "$pkgs"/{bin,zsh,karabiner,raycast,launchagents,logseq,espanso,ghostty,tmux}
  result=$(stow_packages_for_os linux "$pkgs" | tr '\n' ' ')
  [[ "$result" == "bin tmux zsh " ]]
}

@test "stow_packages_for_os on macos keeps every package" {
  pkgs="$WORK/pkgs"
  mkdir -p "$pkgs"/{bin,zsh,karabiner,raycast,launchagents,logseq,espanso,ghostty,tmux}
  result=$(stow_packages_for_os macos "$pkgs" | tr '\n' ' ')
  [[ "$result" == "bin espanso ghostty karabiner launchagents logseq raycast tmux zsh " ]]
}

# --- backup_conflicts ---------------------------------------------------------

@test "backup_conflicts moves a pre-existing real file out of the way" {
  pkg="$WORK/pkgs/lazygit"; home="$WORK/home"; backup="$WORK/backup"
  mkdir -p "$pkg/.config/lazygit" "$home/.config/lazygit"
  echo ours > "$pkg/.config/lazygit/config.yml"
  echo theirs > "$home/.config/lazygit/config.yml"

  run backup_conflicts "$pkg" "$home" "$backup"
  [[ "$status" -eq 0 ]]
  [[ ! -e "$home/.config/lazygit/config.yml" ]]
  [[ "$(cat "$backup/.config/lazygit/config.yml")" == "theirs" ]]
  [[ "$output" == *".config/lazygit/config.yml"* ]]
}

# --- owned directories --------------------------------------------------------
# Paths in DOTFILES_OWNED_DIRS are moved aside as a whole so stow can fold them
# into a single symlink, instead of being merged file-by-file.

@test "backup_conflicts moves an owned directory wholesale" {
  pkg="$WORK/pkgs/nvim"; home="$WORK/home"; backup="$WORK/backup"
  mkdir -p "$pkg/.config/nvim" "$home/.config/nvim/lua/plugins"
  echo ours > "$pkg/.config/nvim/init.lua"
  echo theirs > "$home/.config/nvim/init.lua"
  echo theirs > "$home/.config/nvim/lua/plugins/theme.lua"

  run backup_conflicts "$pkg" "$home" "$backup"
  [[ "$status" -eq 0 ]]
  # the whole directory is gone, so stow can fold it
  [[ ! -e "$home/.config/nvim" ]]
  # including files the package has no counterpart for
  [[ "$(cat "$backup/.config/nvim/lua/plugins/theme.lua")" == "theirs" ]]
  [[ "$(cat "$backup/.config/nvim/init.lua")" == "theirs" ]]
  [[ "$output" == *".config/nvim"* ]]
}

@test "backup_conflicts prunes our own symlinks from an owned directory" {
  pkg="$WORK/pkgs/nvim"; home="$WORK/home"; backup="$WORK/backup"
  mkdir -p "$pkg/.config/nvim" "$home/.config/nvim/lua/plugins"
  echo ours > "$pkg/.config/nvim/init.lua"
  ln -s "$pkg/.config/nvim/init.lua" "$home/.config/nvim/init.lua"
  echo theirs > "$home/.config/nvim/lua/plugins/theme.lua"

  run backup_conflicts "$pkg" "$home" "$backup"
  [[ "$status" -eq 0 ]]
  [[ ! -e "$home/.config/nvim" ]]
  # only the foreign file is preserved; our reproducible symlink is not copied
  [[ "$(cat "$backup/.config/nvim/lua/plugins/theme.lua")" == "theirs" ]]
  [[ ! -e "$backup/.config/nvim/init.lua" ]]
}

@test "backup_conflicts removes an owned directory holding only our symlinks" {
  pkg="$WORK/pkgs/nvim"; home="$WORK/home"; backup="$WORK/backup"
  mkdir -p "$pkg/.config/nvim" "$home/.config/nvim"
  echo ours > "$pkg/.config/nvim/init.lua"
  ln -s "$pkg/.config/nvim/init.lua" "$home/.config/nvim/init.lua"

  run backup_conflicts "$pkg" "$home" "$backup"
  [[ "$status" -eq 0 ]]
  [[ ! -e "$home/.config/nvim" ]]
  # nothing worth keeping, so no backup entry is made
  [[ ! -d "$backup/.config/nvim" ]]
  [[ -z "$output" ]]
}

@test "backup_conflicts leaves an owned directory alone once it is a folded symlink" {
  pkg="$WORK/pkgs/nvim"; home="$WORK/home"; backup="$WORK/backup"
  mkdir -p "$pkg/.config/nvim" "$home/.config"
  echo ours > "$pkg/.config/nvim/init.lua"
  ln -s "$pkg/.config/nvim" "$home/.config/nvim"

  run backup_conflicts "$pkg" "$home" "$backup"
  [[ "$status" -eq 0 ]]
  [[ -L "$home/.config/nvim" ]]
  [[ -z "$output" ]]
}

@test "backup_conflicts leaves a symlink that already points into the package alone" {
  pkg="$WORK/pkgs/zsh"; home="$WORK/home"; backup="$WORK/backup"
  mkdir -p "$pkg" "$home"
  echo ours > "$pkg/.zshrc"
  ln -s "$pkg/.zshrc" "$home/.zshrc"

  run backup_conflicts "$pkg" "$home" "$backup"
  [[ "$status" -eq 0 ]]
  [[ -L "$home/.zshrc" ]]
  [[ ! -e "$backup" ]]
}

@test "backup_conflicts moves a foreign symlink out of the way" {
  pkg="$WORK/pkgs/starship"; home="$WORK/home"; backup="$WORK/backup"
  mkdir -p "$pkg/.config" "$home/.config" "$WORK/elsewhere"
  echo ours > "$pkg/.config/starship.toml"
  echo theirs > "$WORK/elsewhere/starship.toml"
  ln -s "$WORK/elsewhere/starship.toml" "$home/.config/starship.toml"

  run backup_conflicts "$pkg" "$home" "$backup"
  [[ "$status" -eq 0 ]]
  [[ ! -e "$home/.config/starship.toml" && ! -L "$home/.config/starship.toml" ]]
  [[ -L "$backup/.config/starship.toml" ]]
}

@test "backup_conflicts does nothing when the target does not exist" {
  pkg="$WORK/pkgs/bin"; home="$WORK/home"; backup="$WORK/backup"
  mkdir -p "$pkg/.bin" "$home"
  echo ours > "$pkg/.bin/tool"

  run backup_conflicts "$pkg" "$home" "$backup"
  [[ "$status" -eq 0 ]]
  [[ -z "$output" ]]
  [[ ! -e "$backup" ]]
}

@test "backup_conflicts moves a real directory that the package wants as a symlinked file" {
  # e.g. ~/.tmux/plugins/tpm exists as a plain dir on the target
  pkg="$WORK/pkgs/tmux"; home="$WORK/home"; backup="$WORK/backup"
  mkdir -p "$pkg/.tmux/includes" "$home/.tmux"
  echo ours > "$pkg/.tmux/includes/x.conf"
  mkdir -p "$home/.tmux/includes"
  echo theirs > "$home/.tmux/includes/x.conf"

  run backup_conflicts "$pkg" "$home" "$backup"
  [[ "$status" -eq 0 ]]
  [[ "$(cat "$backup/.tmux/includes/x.conf")" == "theirs" ]]
}

@test "backup_conflicts skips a folded directory symlink that points into the package" {
  # macOS after a first stow: ~/.bin -> ../dotfiles/.stow-packages/bin/.bin
  pkg="$WORK/pkgs/bin"; home="$WORK/home"; backup="$WORK/backup"
  mkdir -p "$pkg/.bin" "$home"
  echo ours > "$pkg/.bin/tool"
  ln -s "../pkgs/bin/.bin" "$home/.bin"

  run backup_conflicts "$pkg" "$home" "$backup"
  [[ "$status" -eq 0 ]]
  [[ -z "$output" ]]
  [[ -f "$pkg/.bin/tool" ]]
  [[ ! -e "$backup" ]]
}

@test "backup_conflicts skips a folded directory symlink into a sibling package" {
  # ~/.config/nvim folded into the nvim package while stowing the tmux package
  pkg="$WORK/pkgs/tmux"; other="$WORK/pkgs/nvim"; home="$WORK/home"; backup="$WORK/backup"
  mkdir -p "$pkg/.config/tmux" "$other/.config/nvim" "$home/.config"
  echo ours > "$pkg/.config/tmux/tmux.conf"
  echo theirs > "$other/.config/nvim/init.lua"
  ln -s "../../pkgs/nvim/.config/nvim" "$home/.config/nvim"
  # and a stray package file living under a name that also exists in home via that link
  mkdir -p "$pkg/.config/nvim"; echo ours > "$pkg/.config/nvim/init.lua"

  run backup_conflicts "$pkg" "$home" "$backup"
  [[ "$status" -eq 0 ]]
  [[ -z "$output" ]]
  [[ "$(cat "$other/.config/nvim/init.lua")" == "theirs" ]]
  [[ ! -e "$backup" ]]
}

@test "backup_conflicts moves a foreign directory symlink out of the way" {
  pkg="$WORK/pkgs/nvim"; home="$WORK/home"; backup="$WORK/backup"
  mkdir -p "$pkg/.config/nvim" "$home/.config" "$WORK/elsewhere/nvim"
  echo ours > "$pkg/.config/nvim/init.lua"
  echo theirs > "$WORK/elsewhere/nvim/init.lua"
  ln -s "$WORK/elsewhere/nvim" "$home/.config/nvim"

  run backup_conflicts "$pkg" "$home" "$backup"
  [[ "$status" -eq 0 ]]
  [[ "$output" == ".config/nvim" ]]
  [[ ! -L "$home/.config/nvim" ]]
  [[ -L "$backup/.config/nvim" ]]
  [[ "$(cat "$WORK/elsewhere/nvim/init.lua")" == "theirs" ]]
}

@test "backup_conflicts skips a dangling symlink that used to point into the package" {
  # mise/config.toml moved to mise/conf.d/dotfiles.toml; stow -R prunes the old link
  pkg="$WORK/pkgs/mise"; home="$WORK/home"; backup="$WORK/backup"
  mkdir -p "$pkg/.config/mise/conf.d" "$home/.config/mise"
  echo ours > "$pkg/.config/mise/conf.d/dotfiles.toml"
  ln -s "../../../pkgs/mise/.config/mise/config.toml" "$home/.config/mise/config.toml"
  mkdir -p "$pkg/.config/mise"; : # package has no config.toml any more

  run backup_conflicts "$pkg" "$home" "$backup"
  [[ "$status" -eq 0 ]]
  [[ -z "$output" ]]
  [[ -L "$home/.config/mise/config.toml" ]]
}

# --- bash 3.2 compatibility ---------------------------------------------------

# macOS ships bash 3.2.57 as /bin/bash (Apple froze it at the last GPLv2
# release), so every script install.sh reaches on macOS must avoid bash 4+
# syntax. This suite otherwise runs on Linux under bash 5, where such a bug is
# invisible - it only surfaces on devbook, mid-bootstrap.
#
# The pacman script is exempt: it is Linux-only by construction, reached only
# when get_package_manager returns "pacman".
@test "no bash 4+ only syntax on the macOS bootstrap path" {
  local offenders=""
  local f
  for f in $(find "$REPO_DIR/.scripts" -name '*.sh' -not -path '*/pacman/*' | sort); do
    # Strip comments so documentation naming these builtins does not trip it.
    local hits
    hits="$(sed 's/#.*//' "$f" \
      | grep -nE '\b(mapfile|readarray)\b|declare -A|\$\{[A-Za-z_][A-Za-z_0-9]*(,,|\^\^)\}' \
      || true)"
    if [[ -n "$hits" ]]; then
      offenders+="${f#$REPO_DIR/}: $hits"$'\n'
    fi
  done
  if [[ -n "$offenders" ]]; then
    echo "bash 4+ syntax found on the macOS path:" >&2
    echo "$offenders" >&2
  fi
  [[ -z "$offenders" ]]
}
