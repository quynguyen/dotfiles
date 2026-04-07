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
# Handles added/removed plugins correctly.
diff_lockfile() {
  local old_file="$1"
  local new_file="$2"

  python3 -c "
import json, sys
with open(sys.argv[1]) as f:
    old = json.load(f)
with open(sys.argv[2]) as f:
    new = json.load(f)
for plugin in sorted(set(old) | set(new)):
    old_sha = old.get(plugin, {}).get('commit', '')
    new_sha = new.get(plugin, {}).get('commit', '')
    if old_sha != new_sha:
        print(f'{plugin}|{old_sha}|{new_sha}')
" "$old_file" "$new_file"
}

# scan_commits(plugin, old_sha, new_sha)
# Outputs commit log for the plugin between old and new SHA.
# Exits 1 if any commits contain breaking-change signals.
scan_commits() {
  local plugin="$1"
  local old_sha="$2"
  local new_sha="$3"
  local plugin_path="$PLUGIN_DIR/$plugin"

  local commits
  commits=$(git -C "$plugin_path" log "${old_sha}..${new_sha}" --oneline 2>/dev/null || echo "")

  echo "$commits"

  # Check for breaking-change signals
  if echo "$commits" | grep -qiE '(breaking|deprecated|removed|!:)'; then
    return 1
  fi
  return 0
}

# check_startup()
# Runs headless nvim and checks for clean startup.
# Exits 0 if clean, exits 1 with error output on failure.
check_startup() {
  local output
  output=$(nvim --headless +qa 2>&1)
  local exit_code=$?

  if [[ $exit_code -ne 0 ]] || [[ -n "$output" ]]; then
    echo "$output"
    return 1
  fi
  return 0
}

# generate_report(date, updated_json, rolled_back_json, checkhealth_diff, status)
# Outputs a JSON report to stdout.
generate_report() {
  local date="$1"
  local updated_json="$2"
  local rolled_back_json="$3"
  local checkhealth_diff="$4"
  local status="$5"

  python3 -c "
import json, sys
report = {
    'date': sys.argv[1],
    'updated': json.loads(sys.argv[2]),
    'rolled_back': json.loads(sys.argv[3]),
    'checkhealth_diff': sys.argv[4],
    'status': sys.argv[5]
}
print(json.dumps(report, indent=2))
" "$date" "$updated_json" "$rolled_back_json" "$checkhealth_diff" "$status"
}

# check_health(baseline_path)
# Runs checkhealth headlessly and diffs against the baseline.
# On first run (no baseline), saves current output as baseline, returns empty.
# On subsequent runs, returns the diff.
check_health() {
  local baseline_path="$1"
  local current
  current=$(nvim --headless +"checkhealth" +qa 2>&1 || true)

  if [[ ! -f "$baseline_path" ]]; then
    echo "$current" > "$baseline_path"
    return 0
  fi

  local health_diff
  health_diff=$(diff <(cat "$baseline_path") <(echo "$current") 2>/dev/null || true)

  if [[ -n "$health_diff" ]]; then
    echo "$health_diff"
  fi
}

# Allow sourcing without executing main
if [[ "${1:-}" == "--source-only" ]]; then
  return 0 2>/dev/null || true
fi
