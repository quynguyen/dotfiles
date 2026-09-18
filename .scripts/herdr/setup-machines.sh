#!/bin/bash

# herdr saved-machine profiles.
#
# Everything else about herdr is declarative: the binary comes from the package
# lists and `config.toml` is stowed. Machine profiles are not - `herdr machine
# add` contacts the remote, prepares its installation and starts its server
# before saving, and the profiles live outside `config.toml`, so they cannot be
# committed. This script is the one imperative step, made idempotent.
#
# Note this is only needed for `herdr --machine <label> <cmd>`, which drives a
# remote's panes over the socket API without attaching. Plain
# `herdr --remote leopard --remote-keybindings server` needs nothing registered.
#
# Sourceable for tests:  source setup-machines.sh --source-only

# herdr_machines_for_host [hostname]
# Prints "<label> <ssh-target>" per machine this host should register, or
# nothing. Hostname is lowercased and the domain stripped, so "DEVBOOK.local"
# and "devbook" behave alike.
#
# Only devbook registers anything: leopard runs the herdr server, and a machine
# profile pointing at itself would be meaningless.
herdr_machines_for_host() {
    local host
    host="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
    host="${host%%.*}"

    case "$host" in
        devbook) echo "leopard quy@leopard" ;;
        *)       : ;;
    esac
}

# herdr_machine_registered <label>
# True when herdr already has a saved profile with this label. Parsed without
# jq so a missing jq cannot break the bootstrap.
herdr_machine_registered() {
    local label="$1"
    herdr machine list --json 2>/dev/null \
        | tr -d '[:space:]' \
        | grep -q "\"label\":\"${label}\""
}

setup_herdr_machines() {
    echo "********************************************************************************"
    echo "Registering herdr machines"
    echo "********************************************************************************"

    if ! command -v herdr &> /dev/null; then
        echo "herdr not installed; skipping machine registration"
        return 0
    fi

    # No mapfile/readarray here: macOS ships bash 3.2 as /bin/bash (Apple froze
    # it at the last GPLv2 release) and both are bash 4+ builtins. This loop is
    # the portable equivalent, and it drops blank lines while it goes.
    local -a entries=()
    local line
    while IFS= read -r line; do
        [[ -n "$line" ]] && entries+=("$line")
    done < <(herdr_machines_for_host "$(hostname 2>/dev/null)")

    if [[ ${#entries[@]} -eq 0 ]]; then
        echo "No herdr machines to register on $(hostname 2>/dev/null); nothing to do"
        return 0
    fi

    local entry label target
    for entry in "${entries[@]}"; do
        [[ -z "$entry" ]] && continue
        read -r label target <<< "$entry"

        if herdr_machine_registered "$label"; then
            echo "[$label] already registered; skipping"
            continue
        fi

        # BatchMode so an unreachable or auth-prompting host fails fast instead
        # of blocking the bootstrap. Tailscale SSH needs no key, so this
        # succeeds without one when the tailnet is up.
        if ! ssh -o BatchMode=yes -o ConnectTimeout=5 "$target" true 2>/dev/null; then
            echo "Warning: [$label] $target is unreachable; skipping."
            echo "         Re-run this script once the tailnet is up."
            continue
        fi

        # `machine add` asks before replacing an incompatible remote server and
        # defaults to No. That prompt must stay a human decision, so we never
        # pass a confirmation flag and refuse to run without a terminal.
        if [[ ! -t 0 ]]; then
            echo "Warning: [$label] needs an interactive terminal (setup may prompt"
            echo "         before replacing an incompatible remote server). Run by hand:"
            echo "             herdr machine add $target --label $label"
            continue
        fi

        echo "[$label] registering $target ..."
        if herdr machine add "$target" --label "$label"; then
            echo "[$label] registered"
        else
            echo "Warning: [$label] registration failed; run by hand:"
            echo "             herdr machine add $target --label $label"
        fi
    done

    echo "herdr machine registration complete"
}

if [[ "${1:-}" == "--source-only" ]]; then
    return 0 2>/dev/null || true
fi

setup_herdr_machines
