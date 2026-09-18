#!/usr/bin/env bats

# herdr machine-profile registration logic.
# Run: bats ~/dotfiles/.scripts/tests/herdr.bats

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"

setup() {
  source "$REPO_DIR/.scripts/herdr/setup-machines.sh" --source-only
  WORK="$(mktemp -d)"
  FAKEBIN="$WORK/bin"
  mkdir -p "$FAKEBIN"
}

teardown() {
  rm -rf "$WORK"
}

# Stub `herdr` so machine-list parsing is tested without a running server.
fake_herdr() {
  printf '#!/bin/sh\ncat <<'"'"'JSON'"'"'\n%s\nJSON\n' "$1" > "$FAKEBIN/herdr"
  chmod +x "$FAKEBIN/herdr"
  PATH="$FAKEBIN:$PATH"
}

# --- herdr_machines_for_host --------------------------------------------------

@test "devbook registers leopard" {
  result="$(herdr_machines_for_host devbook)"
  [[ "$result" == "leopard quy@leopard" ]]
}

@test "hostname is lowercased and the domain stripped" {
  result="$(herdr_machines_for_host DEVBOOK.local)"
  [[ "$result" == "leopard quy@leopard" ]]
}

@test "leopard registers nothing - it runs the server" {
  result="$(herdr_machines_for_host leopard)"
  [[ -z "$result" ]]
}

@test "an unknown host registers nothing" {
  result="$(herdr_machines_for_host some-other-box)"
  [[ -z "$result" ]]
}

@test "a missing hostname registers nothing" {
  result="$(herdr_machines_for_host)"
  [[ -z "$result" ]]
}

# --- herdr_machine_registered -------------------------------------------------

@test "herdr_machine_registered is false on an empty machine list" {
  fake_herdr '[]'
  run herdr_machine_registered leopard
  [[ "$status" -ne 0 ]]
}

@test "herdr_machine_registered finds an existing label" {
  fake_herdr '[{"id":"m1","label":"leopard","enabled":true}]'
  run herdr_machine_registered leopard
  [[ "$status" -eq 0 ]]
}

@test "herdr_machine_registered tolerates pretty-printed json" {
  fake_herdr '[
  {
    "id": "m1",
    "label": "leopard"
  }
]'
  run herdr_machine_registered leopard
  [[ "$status" -eq 0 ]]
}

@test "herdr_machine_registered does not match a different label" {
  fake_herdr '[{"id":"m1","label":"otherbox"}]'
  run herdr_machine_registered leopard
  [[ "$status" -ne 0 ]]
}
