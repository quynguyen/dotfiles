#!/bin/bash

echo "********************************************************************************"
echo "Installing Neovim plugins"
echo "********************************************************************************"

LOCKFILE="$HOME/.config/nvim/lazy-lock.json"

# Bootstrapping is a *reproduce* step, never an authoring one.
#
# lazy.nvim only consults the lockfile when it checks out with lockfile=true,
# which is what restore does and install does not (lua/lazy/manage/init.lua).
# Filling in one missing plugin happens to land on the pin anyway, but
# bootstrapping an *empty* plugin tree resolves to branch head and rewrites
# lazy-lock.json - verified on a fresh run, where SchemaStore.nvim and
# gitsigns.nvim both moved to upstream head. That is exactly the new-machine
# case, so it is the one that matters. restore has no clone step, so it cannot
# do the job alone. Only
# the daily update job (~/.bin/nvim-update.sh, macOS-only on purpose) may move
# them, so put the lockfile back before restoring - otherwise restore would just
# re-pin to whatever install happened to fetch.
#
# ~/.config/nvim is stowed, so the lockfile is a tracked file in this repo. We
# compare against a copy rather than `git checkout` it, to avoid discarding
# lockfile edits someone made on purpose.
lockfile_before=""
if [[ -f "$LOCKFILE" ]]; then
	lockfile_before="$(mktemp)"
	cp "$LOCKFILE" "$lockfile_before"
fi

nvim --headless +"Lazy! install" +qa 2>/dev/null

if [[ -n "$lockfile_before" ]] && ! cmp -s "$LOCKFILE" "$lockfile_before"; then
	echo "Install moved the pins; restoring lazy-lock.json before pinning plugins"
	cp "$lockfile_before" "$LOCKFILE"
fi

nvim --headless +"Lazy! restore" +qa 2>/dev/null

if [[ -n "$lockfile_before" ]]; then
	if cmp -s "$LOCKFILE" "$lockfile_before"; then
		echo "Neovim plugins match the lockfile"
	else
		echo "Warning: lazy-lock.json still differs after restore; leaving it alone."
		echo "  Check with: git -C ~/dotfiles diff -- .stow-packages/nvim/.config/nvim/lazy-lock.json"
	fi
	rm -f "$lockfile_before"
fi
