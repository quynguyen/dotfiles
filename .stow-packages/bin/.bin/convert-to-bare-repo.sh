#!/usr/bin/env bash
# Convert a regular git repo into a bare repo with parallel worktrees,
# prefixed `wt-`, for use with worktrunk (`wt`).
#
# Before:  <path>/            (regular repo with .git/ + working tree)
# After:   <path>/             (bare repo internals)
#          <path>/wt-main/     (main worktree)
#          <path>-backup/      (original, safety net — delete once verified)
#
# See docs/guides/bare-repo-worktree-migration.md for background.

set -euo pipefail

usage() {
    cat <<EOF
Usage: $(basename "$0") <path-to-repo>

Converts a git repo into a bare repo layout with parallel worktrees
prefixed 'wt-'. The 'main' worktree is created automatically.

Requires:
  - 'main' branch is checked out
  - working tree is clean (no uncommitted or staged changes)
  - no existing linked worktrees

The original repo is preserved at <path>-backup as a safety net.
Delete it once you've verified the new layout works.
EOF
}

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
esac

if [[ $# -ne 1 ]]; then
    usage >&2
    exit 1
fi

if [[ ! -d "$1" ]]; then
    echo "Error: not a directory: $1" >&2
    exit 1
fi

REPO_PATH="$(cd "$1" && pwd -P)"
REPO_NAME="$(basename "$REPO_PATH")"
PARENT_DIR="$(dirname "$REPO_PATH")"
BACKUP_PATH="$PARENT_DIR/$REPO_NAME-backup"
TMP_BARE_PATH="$PARENT_DIR/$REPO_NAME-tmp-bare.$$"

cleanup_on_error() {
    if [[ -d "$TMP_BARE_PATH" ]]; then
        rm -rf "$TMP_BARE_PATH"
    fi
}
trap cleanup_on_error ERR

# --- Preflight ---

if [[ ! -d "$REPO_PATH/.git" ]]; then
    echo "Error: $REPO_PATH is not a (non-bare) git repository" >&2
    exit 1
fi

if [[ -e "$BACKUP_PATH" ]]; then
    echo "Error: backup path already exists: $BACKUP_PATH" >&2
    echo "Move or delete it first." >&2
    exit 1
fi

CURRENT_BRANCH="$(git -C "$REPO_PATH" symbolic-ref --short HEAD 2>/dev/null || echo "")"
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    echo "Error: expected 'main' to be checked out, got '${CURRENT_BRANCH:-<detached>}'" >&2
    exit 1
fi

if ! git -C "$REPO_PATH" diff --quiet || ! git -C "$REPO_PATH" diff --cached --quiet; then
    echo "Error: working tree is not clean. Commit or stash your changes first." >&2
    git -C "$REPO_PATH" status --short >&2
    exit 1
fi

if [[ "$(git -C "$REPO_PATH" worktree list | wc -l)" -gt 1 ]]; then
    echo "Error: this repo has linked worktrees. Remove them first:" >&2
    git -C "$REPO_PATH" worktree list >&2
    exit 1
fi

echo "==> Source:       $REPO_PATH"
echo "==> Backup:       $BACKUP_PATH"
echo "==> New worktree: $REPO_PATH/wt-main"
echo ""

# --- Migrate ---

echo "==> Cloning bare..."
git clone --bare "$REPO_PATH" "$TMP_BARE_PATH"

echo "==> Swapping directories..."
mv "$REPO_PATH" "$BACKUP_PATH"
mv "$TMP_BARE_PATH" "$REPO_PATH"

# `git clone --bare` sets origin to the source path. After the swap, that path
# is the backup (local-only repo) or still a real remote URL.
ORIGIN_URL="$(git -C "$REPO_PATH" remote get-url origin 2>/dev/null || true)"
if [[ -n "$ORIGIN_URL" ]]; then
    if [[ "$ORIGIN_URL" == "$BACKUP_PATH" || "$ORIGIN_URL" == "$REPO_PATH" ]]; then
        echo "==> Removing stale local origin ($ORIGIN_URL)..."
        git -C "$REPO_PATH" remote remove origin
    else
        # Bare clones need explicit fetch refspec for `origin/*` tracking.
        echo "==> Configuring fetch refs for origin ($ORIGIN_URL)..."
        git -C "$REPO_PATH" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    fi
fi

echo "==> Creating wt-main worktree..."
git -C "$REPO_PATH" worktree add wt-main main

# Bare clones drop gitignored content (env files, node_modules, .venv, ...).
# Copy them from the backup so the new worktree is immediately usable.
echo "==> Copying gitignored files from backup..."
while IFS= read -r -d '' item; do
    clean="${item%/}"
    [[ -z "$clean" ]] && continue
    src="$BACKUP_PATH/$clean"
    dest="$REPO_PATH/wt-main/$clean"
    if [[ -e "$src" ]]; then
        mkdir -p "$(dirname "$dest")"
        cp -R "$src" "$dest"
        echo "    copied: $clean"
    fi
done < <(git -C "$BACKUP_PATH" ls-files --others --ignored --exclude-standard --directory -z)

echo ""
echo "==> Done."
echo ""
echo "New layout:"
echo "    $REPO_PATH/          (bare repo)"
echo "    $REPO_PATH/wt-main/  (main worktree)"
echo ""
echo "Next steps:"
echo "    cd $REPO_PATH/wt-main"
echo "    git status"
echo "    wt list"
echo ""
echo "Once verified, remove the backup:"
echo "    rm -rf '$BACKUP_PATH'"
