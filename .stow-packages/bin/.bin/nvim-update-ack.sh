#!/usr/bin/env bash
set -euo pipefail

# Clears the Neovim plugin update attention flag.
# Run after /nvim-update-fix has verified the latest report is resolved.

rm -f "$HOME/.nvim-update-attention"
