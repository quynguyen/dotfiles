# Neovim Spell Files

This directory contains spell checking configuration for Neovim.

## Setup

Run the setup script to download and compile a comprehensive SCOWL spell file:

```bash
~/dotfiles/.stow-packages/nvim/setup-spell
```

This will:
1. Download SCOWL word lists (comprehensive English dictionary with technical terms)
2. Add custom technical/programming terms (Treesitter, async, CamelCase, etc.)
3. Compile into Neovim's binary spell format (`en.utf-8.spl` and `en.utf-8.add`)

## Manual Compilation

If the script doesn't work, you can manually compile the spell file in Neovim:

```vim
:set spellfile=~/.config/nvim/spell/en.utf-8.add
:mkspell! ~/.config/nvim/spell/en.utf-8
```

## Usage

**Toggle spell checking:**
- `<leader>us` — Toggle on/off
- `[os` — Enable spell check
- `]os` — Disable spell check

**Built-in Vim commands:**
- `]s` / `[s` — Jump to next/previous misspelling
- `z=` — See spelling suggestions
- `zg` — Add word to dictionary

## Technical Terms Included

The spell file includes:
- SCOWL advanced English word list (comprehensive coverage)
- Custom programming terms: Treesitter, async, await, callback, LSP, TCR, CamelCase, etc.
- Regular dictionary updates via SCOWL

## Notes

- The `.add` file is the source; `.spl` is the compiled binary
- Adding new words: edit `en.utf-8.add` and run `:mkspell!` to recompile
- Removed words should be prefixed with `/` in the `.add` file (e.g., `/badword`)
