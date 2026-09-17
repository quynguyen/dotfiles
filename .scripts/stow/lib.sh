#!/bin/bash

# Helpers for the stow step. Sourceable for tests:
#   source lib.sh --source-only

# Packages that only make sense on macOS (Library/ paths, mac-only apps, or
# configs that Omarchy owns on Linux). Everything else is stowed everywhere.
MACOS_ONLY_STOW_PACKAGES=(
    karabiner     # ~/.config/karabiner - macOS keyboard remapper
    raycast       # ~/Library/Preferences
    launchagents  # ~/Library/LaunchAgents - nvim daily update job (mac commits the lockfile)
    logseq        # graphs reference /Users/... paths; desktop app not installed on Linux
    espanso       # desktop text expander; only installed via brew cask
    ghostty       # on Omarchy the terminal config is owned by the theme system
)

# Target-relative directories the dotfiles own outright. A pre-existing real
# directory at one of these paths is moved aside wholesale rather than merged
# file-by-file, so stow can fold the path into a single symlink. Without this,
# an OS-provided config (Omarchy ships its own LazyVim setup) leaves its extra
# files behind and they load alongside ours.
DOTFILES_OWNED_DIRS=(
    .config/nvim
)

# _is_owned_dir <target-relative-path>
_is_owned_dir() {
    local candidate="$1" d
    for d in "${DOTFILES_OWNED_DIRS[@]}"; do
        [[ "$candidate" == "$d" ]] && return 0
    done
    return 1
}

# stow_packages_for_os <macos|linux> <packages-dir>
# Prints the package names (one per line, sorted) to stow on this OS.
stow_packages_for_os() {
    local os="$1"
    local dir="$2"
    local p name skip
    for p in "$dir"/*/; do
        name="$(basename "$p")"
        skip=false
        if [[ "$os" != "macos" ]]; then
            for m in "${MACOS_ONLY_STOW_PACKAGES[@]}"; do
                [[ "$name" == "$m" ]] && skip=true && break
            done
        fi
        [[ "$skip" == true ]] || echo "$name"
    done | sort
}

# _stow_owned_link <symlink> <packages-root>
# True when the symlink points into the stow packages tree (i.e. it was made by
# a previous stow run, possibly for another package, possibly now dangling).
_stow_owned_link() {
    local path="$1" root="$2" link resolved=""
    link="$(readlink "$path")"
    if [[ "$link" == /* ]]; then
        resolved="$(cd "$(dirname "$link")" 2>/dev/null && pwd -P)" && resolved="$resolved/$(basename "$link")"
    else
        resolved="$(cd "$(dirname "$path")" 2>/dev/null && cd "$(dirname "$link")" 2>/dev/null && pwd -P)" && resolved="$resolved/$(basename "$link")"
    fi
    [[ -n "$resolved" && "$resolved" == "$root"/* ]] && return 0
    [[ "$link" == *"/.stow-packages/"* ]] && return 0
    return 1
}

# backup_conflicts <package-dir> <target-dir> <backup-dir>
# Walks the package tree alongside the target. Anything in the target that
# would block stow (a real file, a real dir where the package has a file, or a
# symlink pointing outside the stow tree) is moved under backup-dir, preserving
# its relative path, and printed. Symlinks that already point into the stow
# tree are left alone and NOT descended into: on macOS ~/.bin, ~/.config/nvim
# etc. are "folded" symlinks straight into the package, and walking through
# them would mistake the package's own files for conflicts.
backup_conflicts() {
    local pkg="$1" target="$2" backup="$3" root
    root="$(cd "$pkg/.." && pwd -P)"
    _backup_walk "$pkg" "$target" "$backup" "$root" ""
}

_backup_walk() {
    local pkg="$1" target="$2" backup="$3" root="$4" rel="$5"
    local base="$pkg${rel:+/$rel}" entry name sub dest
    for entry in "$base"/* "$base"/.[!.]* "$base"/..?*; do
        [[ -e "$entry" || -L "$entry" ]] || continue
        name="$(basename "$entry")"
        sub="${rel:+$rel/}$name"
        dest="$target/$sub"

        if [[ -L "$dest" ]]; then
            _stow_owned_link "$dest" "$root" && continue
        elif [[ -d "$dest" ]]; then
            if [[ -d "$entry" && ! -L "$entry" ]]; then
                if _is_owned_dir "$sub"; then
                    # Drop symlinks a previous stow run left here: they are
                    # reproducible, and keeping them would copy our own tree
                    # into the backup. What remains is the OS's own config.
                    _prune_stow_links "$dest" "$root"
                    if [[ -z "$(ls -A "$dest")" ]]; then
                        rmdir "$dest"
                        continue
                    fi
                    mkdir -p "$backup/$(dirname "$sub")"
                    mv "$dest" "$backup/$sub"
                    echo "$sub"
                    continue
                fi
                _backup_walk "$pkg" "$target" "$backup" "$root" "$sub"
                continue
            fi
            # package wants a file/link where the target has a real directory
        elif [[ ! -e "$dest" ]]; then
            continue
        fi

        mkdir -p "$backup/$(dirname "$sub")"
        mv "$dest" "$backup/$sub"
        echo "$sub"
    done
}

# _prune_stow_links <dir> <packages-root>
# Removes symlinks under dir that point into the stow tree, then any directories
# left empty by their removal. Used before moving an owned directory aside.
_prune_stow_links() {
    local dir="$1" root="$2" link
    while IFS= read -r -d '' link; do
        _stow_owned_link "$link" "$root" && rm -f "$link"
    done < <(find "$dir" -type l -print0)
    find "$dir" -mindepth 1 -depth -type d -empty -delete 2>/dev/null || true
}
