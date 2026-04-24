# Change working dir in shell to last dir in yazi on exit
# Adapted from the lf lfcd pattern

yazicd() {
    tmp="$(mktemp)"
    yazi --cwd-file="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$(cat "$tmp")"
        rm -f "$tmp"
        if [ -d "$dir" ]; then
            if [ "$dir" != "$(pwd)" ]; then
                cd "$dir"
            fi
        fi
    fi
}
