#!/bin/bash

# Make the configured shell the login shell (chsh). On a fresh Linux box the
# login shell is bash; the dotfiles are zsh-centric, so an SSH session should
# land in zsh with this config loaded.

set_login_shell() {
    if [[ -f ~/.shell_config ]]; then
        source ~/.shell_config
    fi
    DOTFILES_SHELL_MODE="${DOTFILES_SHELL_MODE:-zsh-p10k}"

    local want
    case "$DOTFILES_SHELL_MODE" in
        fish)    want="fish" ;;
        nushell) want="nu" ;;
        *)       want="zsh" ;;
    esac

    local want_path
    want_path="$(command -v "$want" 2>/dev/null)" || {
        echo "Warning: $want not found on PATH; leaving login shell unchanged."
        return 0
    }

    local current
    current="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || true)"
    [[ -z "$current" ]] && current="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}' || true)"
    [[ -z "$current" ]] && current="$SHELL"

    if [[ "$(basename "$current")" == "$want" ]]; then
        echo "Login shell is already $current"
        return 0
    fi

    # chsh refuses a shell that is not in /etc/shells. Arch's zsh package does
    # not register itself there (the file is owned by `filesystem`), so on a
    # fresh Omarchy box we have to add the entry ourselves before chsh.
    if ! grep -qx "$want_path" /etc/shells 2>/dev/null; then
        echo "$want_path is not listed in /etc/shells; adding it (sudo may ask for your password)..."
        if ! echo "$want_path" | sudo tee -a /etc/shells >/dev/null 2>&1; then
            echo "Warning: could not add $want_path to /etc/shells; leaving login shell unchanged."
            echo "  Fix: echo $want_path | sudo tee -a /etc/shells"
            return 0
        fi
    fi

    if [[ ! -t 0 ]]; then
        echo "Warning: no TTY, cannot run chsh. Run manually:  chsh -s $want_path"
        return 0
    fi

    echo "Changing login shell from $current to $want_path (chsh may ask for your password)..."
    chsh -s "$want_path" || echo "Warning: chsh failed; run manually:  chsh -s $want_path"
}

if [[ "${1:-}" == "--source-only" ]]; then
    return 0 2>/dev/null || true
fi

echo "********************************************************************************"
echo "Setting login shell"
echo "********************************************************************************"
set_login_shell
