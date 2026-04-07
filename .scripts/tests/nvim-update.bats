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
