#!/usr/bin/env bash
set -eu

BASE_URL="${CMUS_NOW_PLAYING_BASE_URL:-http://gentoo.local:3000/mArdek/cmus-now-playing/raw/branch/main}"
PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="$PREFIX/bin"

command -v curl >/dev/null 2>&1 || {
    printf '%s\n' 'install: curl is required' >&2
    exit 1
}
command -v bash >/dev/null 2>&1 || {
    printf '%s\n' 'install: bash is required' >&2
    exit 1
}

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cmus-now-playing.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

printf 'Downloading cmus-now-playing...\n'
curl -fsSL "$BASE_URL/cmus-now-playing" -o "$TMP_DIR/cmus-now-playing"
bash -n "$TMP_DIR/cmus-now-playing"
mkdir -p "$BIN_DIR"
chmod 755 "$TMP_DIR/cmus-now-playing"
mv "$TMP_DIR/cmus-now-playing" "$BIN_DIR/cmus-now-playing"
printf 'Installed %s\n' "$BIN_DIR/cmus-now-playing"

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) printf 'Add %s to PATH to run cmus-now-playing directly.\n' "$BIN_DIR" ;;
esac
