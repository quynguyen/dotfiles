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
