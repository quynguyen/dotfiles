#!/bin/bash

# go there the directory of this currently 'sourced' script ( quietly )
pushd $( dirname ${BASH_SOURCE:-$0} ) > /dev/null

echo "********************************************************************************"
echo "Symlinking home dotfiles"
echo "********************************************************************************"

source ./lib.sh --source-only
source ../package-management/detect.sh --source-only

PACKAGES_DIR="$(cd ../../.stow-packages && pwd)"
OS="$(dotfiles_os)"
# Pre-existing files that would block stow (e.g. Omarchy's shipped ~/.config)
# are moved here, preserving their relative path, so nothing is lost.
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

echo "Platform: $OS"

for pkg in $(stow_packages_for_os "$OS" "$PACKAGES_DIR"); do
	moved="$(backup_conflicts "$PACKAGES_DIR/$pkg" "$HOME" "$BACKUP_DIR")"
	if [[ -n "$moved" ]]; then
		echo "[$pkg] backed up pre-existing files to $BACKUP_DIR:"
		echo "$moved" | sed 's/^/    /'
	fi
	# -R (restow) also prunes symlinks left dangling by files that moved
	# inside a package, e.g. mise/config.toml -> mise/conf.d/dotfiles.toml.
	stow -R -v 1 --target ~/ --dir "$PACKAGES_DIR" "$pkg"
done

if [[ -d "$BACKUP_DIR" ]]; then
	echo "Pre-existing dotfiles were backed up under $BACKUP_DIR"
fi

# go back to working directory ( quietly )
popd  > /dev/null
