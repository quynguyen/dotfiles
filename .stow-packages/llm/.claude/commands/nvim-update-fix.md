# Neovim Plugin Update Fix

Read the latest Neovim plugin update report and fix any issues.

## Instructions

1. Find the latest report in `~/.local/share/nvim/update-reports/`. Read the newest `.json` file by date.

2. If the report status is `clean`, say "Everything's fine, nothing to fix" and stop.

3. If status is `needs_attention` or `startup_failure`:

### For rolled-back plugins (report.rolled_back array):

For each rolled-back plugin:
a. Read the `commits` and `error` fields to understand what changed upstream
b. Search `~/dotfiles/.stow-packages/nvim/.config/nvim/lua/plugins/*.lua` for references to this plugin
c. If your custom config references the plugin: diagnose the incompatibility from the error + commit log, then fix the Lua file
d. If no custom config references it: the breakage is in the plugin itself or a LazyVim default — flag for manual review
e. After fixing, update the plugin's SHA in `~/dotfiles/.stow-packages/nvim/.config/nvim/lazy-lock.json` to the `new_sha` from the report
f. Run `nvim --headless +"Lazy! restore" +qa` to apply
g. Run `nvim --headless +qa 2>&1` to verify startup is clean
h. If verification fails, revert your changes and flag for manual review

### For breaking-change signals (report.updated entries where breaking_signals is true):

For each flagged plugin:
a. Read the `commits` to understand what changed
b. Search custom plugin files for references to this plugin
c. If custom config uses affected APIs: fix proactively
d. If no references found: no action needed

### After all fixes:

4. Commit all changes to `~/dotfiles`:
   ```
   git add .stow-packages/nvim/.config/nvim/
   git commit -m "fix(nvim): adapt plugin config to upstream changes"
   ```

5. Clear the attention flag: `rm -f ~/.nvim-update-attention`

6. Summarize: what was fixed, what was re-updated, and what manual testing is recommended (list specific keymaps or features to verify interactively).

## Important

- Do NOT run `:Lazy update` — the daily script owns updates
- If a fix requires changing LazyVim extras config (lazyvim.json), flag it for manual review instead of changing it
- Always verify with headless startup check after each fix
- If the report is missing or unparseable, say so and suggest running `~/dotfiles/.scripts/nvim-update.sh` manually
