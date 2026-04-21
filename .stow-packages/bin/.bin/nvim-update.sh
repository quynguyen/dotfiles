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
# Note: checkhealth writes to a buffer, not stdout — must use :w! to capture.
check_health() {
  local baseline_path="$1"
  local tmpfile
  tmpfile=$(mktemp)
  nvim --headless +"checkhealth" +"w! $tmpfile" +qa 2>/dev/null || true

  if [[ ! -f "$baseline_path" ]]; then
    cp "$tmpfile" "$baseline_path"
    rm -f "$tmpfile"
    return 0
  fi

  local health_diff
  health_diff=$(diff "$baseline_path" "$tmpfile" 2>/dev/null || true)
  rm -f "$tmpfile"

  if [[ -n "$health_diff" ]]; then
    echo "$health_diff"
  fi
}

# snapshot_lockfile()
# Copies lockfile to a temp location and prints the temp path.
snapshot_lockfile() {
  local snapshot
  snapshot=$(mktemp)
  cp "$LOCKFILE" "$snapshot"
  echo "$snapshot"
}

# notify(message)
# Sends macOS notification and creates attention flag.
notify() {
  local message="$1"
  touch "$ATTENTION_FLAG"
  osascript -e "display notification \"$message\" with title \"Neovim\"" 2>/dev/null || true
}

main() {
  local today
  today=$(date +%Y-%m-%d)

  # Ensure report directory exists
  mkdir -p "$REPORT_DIR"

  # Step 1: Snapshot
  local snapshot
  snapshot=$(snapshot_lockfile)

  # Step 2: Update
  nvim --headless +"Lazy! update" +qa 2>/dev/null

  # Step 3: Diff
  local changes
  changes=$(diff_lockfile "$snapshot" "$LOCKFILE")
  if [[ -z "$changes" ]]; then
    rm -f "$snapshot"
    exit 0
  fi

  # Step 4: Scan commits for breaking signals
  local updated_json="[]"
  local has_breaking_signals=false
  local plugin old_sha new_sha commits scan_exit

  while IFS='|' read -r plugin old_sha new_sha; do
    commits=$(scan_commits "$plugin" "$old_sha" "$new_sha") && scan_exit=0 || scan_exit=$?
    local breaking_signals=false
    if [[ $scan_exit -ne 0 ]]; then
      breaking_signals=true
      has_breaking_signals=true
    fi

    # Build JSON array entry
    updated_json=$(echo "$updated_json" | python3 -c "
import json, sys
arr = json.loads(sys.stdin.read())
commits = [l.strip() for l in sys.argv[4].splitlines() if l.strip()]
arr.append({
    'plugin': sys.argv[1],
    'old_sha': sys.argv[2],
    'new_sha': sys.argv[3],
    'commits': commits,
    'breaking_signals': sys.argv[5] == 'true'
})
print(json.dumps(arr))
" "$plugin" "$old_sha" "$new_sha" "$commits" "$breaking_signals")
  done <<< "$changes"

  # Step 5: Startup check
  local startup_error=""
  local rolled_back_json="[]"
  if ! startup_error=$(check_startup); then
    # Step 7: Rollback — restore entire lockfile
    cp "$snapshot" "$LOCKFILE"
    nvim --headless +"Lazy! restore" +qa 2>/dev/null || true

    # Move all updated plugins to rolled_back
    rolled_back_json=$(echo "$updated_json" | python3 -c "
import json, sys
updated = json.loads(sys.stdin.read())
rolled_back = [dict(p, error='$(echo "$startup_error" | head -5 | tr "'" " ")') for p in updated]
for p in rolled_back:
    del p['breaking_signals']
print(json.dumps(rolled_back))
")
    updated_json="[]"

    # Verify recovery
    local status="needs_attention"
    if ! check_startup >/dev/null 2>&1; then
      status="startup_failure"
    fi

    # Step 6: Checkhealth (on rolled-back state)
    local health_diff
    health_diff=$(check_health "$BASELINE_FILE")

    # Skip commit — lockfile is back to original
    # Step 9: Write report
    generate_report "$today" "$updated_json" "$rolled_back_json" "$health_diff" "$status" \
      > "$REPORT_DIR/$today.json"

    # Step 10: Notify
    notify "Plugin update rolled back — needs attention"
    rm -f "$snapshot"
    exit 0
  fi

  # Step 6: Checkhealth (on updated state)
  local health_diff
  health_diff=$(check_health "$BASELINE_FILE")

  # Determine status
  local status="clean"
  if [[ "$has_breaking_signals" == "true" ]]; then
    status="needs_attention"
  fi

  # Step 8: Commit lockfile
  local commit_msg="chore(nvim): daily plugin update $today"
  if [[ "$status" == "needs_attention" ]]; then
    commit_msg="chore(nvim): daily plugin update $today (breaking signals detected)"
  fi
  (
    cd "$HOME/dotfiles"
    git add .stow-packages/nvim/.config/nvim/lazy-lock.json
    git commit -m "$commit_msg" 2>/dev/null || true
  )

  # Step 9: Write report
  generate_report "$today" "$updated_json" "$rolled_back_json" "$health_diff" "$status" \
    > "$REPORT_DIR/$today.json"

  # Step 10: Notify (only if not clean)
  if [[ "$status" != "clean" ]]; then
    notify "Plugin update has breaking signals — review recommended"
  fi

  # Update baseline on clean run
  if [[ "$status" == "clean" ]]; then
    nvim --headless +"checkhealth" +"w! $BASELINE_FILE" +qa 2>/dev/null || true
  fi

  rm -f "$snapshot"
}

# Allow sourcing without executing main
if [[ "${1:-}" == "--source-only" ]]; then
  return 0 2>/dev/null || true
fi

main "$@"
