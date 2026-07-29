#!/usr/bin/env bash
#
# Link this repo's config.toml into neru's default config location, so the
# running daemon reads the file that is under version control here.
#
# Usage: ./install.sh
#
set -euo pipefail

# Directory holding this script, with symlinks resolved, so the repo can be
# cloned anywhere and the link still points at the real file.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE="$SCRIPT_DIR/config.toml"

# neru reads $XDG_CONFIG_HOME/neru, falling back to ~/.config/neru on Unix.
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/neru"
TARGET="$TARGET_DIR/config.toml"

[ -f "$SOURCE" ] || { echo "error: no config.toml next to this script ($SOURCE)" >&2; exit 1; }

# The whole config directory may already be a symlink to this repo, which
# achieves the same result by a different route. Leave it as it is.
if [ -L "$TARGET_DIR" ]; then
    if [ "$(cd -- "$TARGET_DIR" && pwd -P)" = "$SCRIPT_DIR" ]; then
        echo "already linked: $TARGET_DIR -> $SCRIPT_DIR (directory-level)"
        exit 0
    fi
    echo "error: $TARGET_DIR is a symlink to somewhere else:" >&2
    echo "       $(cd -- "$TARGET_DIR" && pwd -P)" >&2
    echo "       Remove it first, then re-run." >&2
    exit 1
fi

mkdir -p "$TARGET_DIR"

# Nothing to do if the link is already correct.
if [ -L "$TARGET" ] && [ "$(readlink -- "$TARGET")" = "$SOURCE" ]; then
    echo "already linked: $TARGET -> $SOURCE"
    exit 0
fi

# Preserve a real config that is already there; it holds settings this repo
# may not have, and overwriting it silently would lose them.
if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
    BACKUP="$TARGET.backup.$(date +%Y%m%d%H%M%S)"
    mv -- "$TARGET" "$BACKUP"
    echo "backed up existing config -> $BACKUP"
fi

ln -sfn -- "$SOURCE" "$TARGET"
echo "linked: $TARGET -> $SOURCE"

# Catch a broken link or bad TOML now rather than at daemon start.
if command -v neru >/dev/null 2>&1; then
    neru config validate -c "$TARGET" >/dev/null 2>&1 \
        && echo "config validates" \
        || echo "warning: 'neru config validate' rejected the linked config" >&2
    echo "run 'neru config reload' to pick it up (or 'neru launch' if not running)"
fi
