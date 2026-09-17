#!/bin/bash

echo "********************************************************************************"
echo "Installing Neovim plugins"
echo "********************************************************************************"

LOCKFILE_REL=".stow-packages/nvim/.config/nvim/lazy-lock.json"

# Bootstrapping is a *reproduce* step, never an authoring one.
#
# lazy.nvim's install pipeline clones and then checks out the branch head, not
# the lockfile commit - only restore consults the lockfile, and restore has no
# clone step. So a bare `nvim --headless +qa` on a fresh machine pulls every
# plugin at latest and rewrites lazy-lock.json, which silently makes that
# machine an author of the pins. Run both verbs: install what is missing, then
# pin everything to the committed lockfile.
nvim --headless +"Lazy! install" +qa 2>/dev/null
nvim --headless +"Lazy! restore" +qa 2>/dev/null

# Only the daily update job (~/.bin/nvim-update.sh, macOS-only on purpose) is
# allowed to move the pins. If installing churned the lockfile anyway, put it
# back so no other machine commits a version of it by accident.
if git -C "$(dirname "${BASH_SOURCE:-$0}")/../.." diff --quiet -- "$LOCKFILE_REL" 2>/dev/null; then
	echo "Neovim plugins match the committed lockfile"
else
	echo "Install moved lazy-lock.json; restoring it (only the daily update job owns the pins)"
	git -C "$(dirname "${BASH_SOURCE:-$0}")/../.." checkout -- "$LOCKFILE_REL"
	nvim --headless +"Lazy! restore" +qa 2>/dev/null
fi
