#!/usr/bin/env bash
#
# Link this repo's config.toml into neru's default config location, so the
# running daemon reads the file that is under version control here. Offers to
# install neru first if it is missing.
#
# Usage: ./install.sh
#
set -euo pipefail

# Homebrew's `neru` cask follows the tagged releases; `neru-nightly` follows a
# build that moves under you. This config is written against the tagged line.
NERU_TAP="y3owk1n/tap"
NERU_CASK="$NERU_TAP/neru"

# Directory holding this script, with symlinks resolved, so the repo can be
# cloned anywhere and the link still points at the real file.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE="$SCRIPT_DIR/config.toml"

# neru reads $XDG_CONFIG_HOME/neru, falling back to ~/.config/neru on Unix.
TARGET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/neru"
TARGET="$TARGET_DIR/config.toml"

[ -f "$SOURCE" ] || { echo "error: no config.toml next to this script ($SOURCE)" >&2; exit 1; }

# Install neru itself, with a confirmation, since this reaches outside the repo
# and pulls a third-party cask. Returns non-zero if it did not happen, and the
# caller carries on: linking a config for a neru that is not here yet is still
# useful, it just cannot be validated.
install_neru() {
    if ! command -v brew >/dev/null 2>&1; then
        echo "neru is not installed, and neither is Homebrew." >&2
        echo "Install it from https://github.com/y3owk1n/neru, then re-run." >&2
        return 1
    fi

    cat <<EOF
neru is not installed. This would run:

  brew tap $NERU_TAP
  brew trust --cask $NERU_CASK
  brew install --cask $NERU_CASK

That is the tagged release line, not neru-nightly. Homebrew will not load a
cask from a third-party tap until it is trusted, hence the middle command.

EOF

    # No terminal means nothing to confirm with; say so rather than assume yes.
    if [ ! -t 0 ]; then
        echo "not running interactively, so not installing; run the above yourself" >&2
        return 1
    fi

    printf 'Install neru now? [y/N] '
    read -r reply
    case "$reply" in
        [yY] | [yY][eE][sS]) ;;
        *) echo "skipping the install"; return 1 ;;
    esac

    brew tap "$NERU_TAP"
    # Older Homebrew has no trust command and needs no trusting; ignore it there.
    brew trust --cask "$NERU_CASK" 2>/dev/null || true
    brew install --cask "$NERU_CASK"
}

if ! command -v neru >/dev/null 2>&1; then
    install_neru || true
fi

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
