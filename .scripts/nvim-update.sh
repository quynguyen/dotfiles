#!/usr/bin/env bash
set -euo pipefail

# Configuration
LOCKFILE="$HOME/.config/nvim/lazy-lock.json"
PLUGIN_DIR="$HOME/.local/share/nvim/lazy"
REPORT_DIR="$HOME/.local/share/nvim/update-reports"
BASELINE_FILE="$REPORT_DIR/checkhealth-baseline.txt"
ATTENTION_FLAG="$HOME/.nvim-update-attention"

# diff_lockfile(old_lockfile, new_lockfile)
# Outputs lines of "plugin|old_sha|new_sha" for plugins that changed.
# Outputs nothing if lockfiles are identical.
diff_lockfile() {
  local old_file="$1"
  local new_file="$2"

  # Extract plugin:sha pairs from each file, compare
  local old_shas new_shas
  old_shas=$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
for k, v in sorted(d.items()):
    print(f\"{k}|{v['commit']}\")
" "$old_file")

  new_shas=$(python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    d = json.load(f)
for k, v in sorted(d.items()):
    print(f\"{k}|{v['commit']}\")
" "$new_file")

  # Compare line by line, output changed plugins
  paste <(echo "$old_shas") <(echo "$new_shas") | while IFS=$'\t' read -r old_line new_line; do
    local plugin_old="${old_line%%|*}"
    local sha_old="${old_line##*|}"
    local sha_new="${new_line##*|}"
    if [[ "$sha_old" != "$sha_new" ]]; then
      echo "${plugin_old}|${sha_old}|${sha_new}"
    fi
  done
}

# Allow sourcing without executing main
if [[ "${1:-}" == "--source-only" ]]; then
  return 0 2>/dev/null || true
fi
