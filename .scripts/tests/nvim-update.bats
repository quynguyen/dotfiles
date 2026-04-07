#!/usr/bin/env bats

# Test suite for nvim-update.sh
# Run: bats ~/dotfiles/.scripts/tests/nvim-update.bats

SCRIPT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/tests/fixtures"

setup() {
  source "$SCRIPT_DIR/nvim-update.sh" --source-only
  TMPDIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TMPDIR"
}

@test "diff_lockfile outputs changed plugins with old and new SHAs" {
  result=$(diff_lockfile "$FIXTURES_DIR/lockfile-before.json" "$FIXTURES_DIR/lockfile-after.json")
  [[ $(echo "$result" | wc -l | tr -d ' ') -eq 2 ]]
  echo "$result" | grep -q "plugin-a|aaaa1111aaaa1111aaaa1111aaaa1111aaaa1111|aaaa4444aaaa4444aaaa4444aaaa4444aaaa4444"
  echo "$result" | grep -q "plugin-b|bbbb2222bbbb2222bbbb2222bbbb2222bbbb2222|bbbb5555bbbb5555bbbb5555bbbb5555bbbb5555"
}

@test "diff_lockfile outputs nothing when lockfiles are identical" {
  result=$(diff_lockfile "$FIXTURES_DIR/lockfile-before.json" "$FIXTURES_DIR/lockfile-no-change.json")
  [[ -z "$result" ]]
}

@test "scan_commits detects breaking-change signals and exits 1" {
  # Mock git to return fixture data
  git() { cat "$FIXTURES_DIR/git-log-breaking.txt"; }
  export -f git

  run scan_commits "plugin-a" "oldsha" "newsha"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"feat!: rename setup()"* ]]
  [[ "$output" == *"BREAKING: remove deprecated"* ]]
}

@test "scan_commits exits 0 when no breaking signals" {
  git() { echo "abc1234 fix: handle nil check in diagnostics"; echo "def5678 chore: bump dependency"; }
  export -f git

  run scan_commits "plugin-a" "oldsha" "newsha"
  [[ "$status" -eq 0 ]]
}

@test "check_startup exits 0 when nvim starts cleanly" {
  nvim() { return 0; }
  export -f nvim

  run check_startup
  [[ "$status" -eq 0 ]]
}

@test "check_startup exits 1 and captures error on failure" {
  nvim() { echo "E5113: Error while calling lua chunk" >&2; return 1; }
  export -f nvim

  run check_startup
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"E5113"* ]]
}
