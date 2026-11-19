#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/cmus-now-playing"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cmus-now-playing-tests.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM
mkdir "$TMP_DIR/bin"
cat > "$TMP_DIR/bin/cmus-remote" <<'MOCK'
#!/usr/bin/env bash
[ "${CMUS_MOCK_FAIL:-0}" -eq 0 ] || exit 1
printf '%s\n' "$CMUS_MOCK_OUTPUT"
MOCK
chmod +x "$TMP_DIR/bin/cmus-remote"

TESTS=0
FAILURES=0
STATUS=0
STDOUT=''
STDERR=''

run() {
    if STDOUT="$("$@" 2>"$TMP_DIR/stderr")"; then STATUS=0; else STATUS=$?; fi
    STDERR="$(cat "$TMP_DIR/stderr")"
}

check() {
    local name="$1" expected="$2" actual="$3"
    TESTS=$((TESTS + 1))
    if [ "$actual" = "$expected" ]; then
        printf 'ok %d - %s\n' "$TESTS" "$name"
    else
        printf 'not ok %d - %s\n  expected: %s\n  actual:   %s\n' \
            "$TESTS" "$name" "$expected" "$actual"
        FAILURES=$((FAILURES + 1))
    fi
}

invoke_cmus() {
    if [ "${CMUS_MOCK_FAIL:-0}" -eq 0 ]; then
        env PATH="$TMP_DIR/bin:/usr/bin:/bin" CMUS_MOCK_OUTPUT="$1" \
            /bin/bash "$SCRIPT" "${@:2}"
    else
        env PATH="$TMP_DIR/bin:/usr/bin:/bin" CMUS_MOCK_OUTPUT="$1" \
            CMUS_MOCK_FAIL=1 /bin/bash "$SCRIPT" "${@:2}"
    fi
}

cmus() { run invoke_cmus "$@"; }

PLAYING='status playing
file /music/Archangel.flac
tag artist Burial
tag title Archangel
tag album Untrue
tag tracknumber 3
tag date 2007
duration 309
position 134'

cmus "$PLAYING"
check 'default output' 'Burial - Archangel' "$STDOUT"
cmus "$PLAYING" -f '{state_icon} {artist} - {title} [{position}/{duration}/{remaining}] {album} {tracknumber} {date}'
check 'common placeholders' '▶ Burial - Archangel [2:14/5:09/2:55] Untrue 3 2007' "$STDOUT"

cmus 'status paused
file /music/My song.mp3' -f '{state_icon} {artist} - {title}'
check 'paused state and filename fallback' '⏸  - My song' "$STDOUT"

cmus 'status playing
file /music/test.mp3
tag artist {title}
tag title {artist}'
check 'metadata placeholders are not expanded recursively' '{title} - {artist}' "$STDOUT"

cmus 'status playing
file /music/test.mp3' -f 'before {unknown} after {unterminated'
check 'unknown and incomplete placeholders stay literal' 'before {unknown} after {unterminated' "$STDOUT"

cmus 'status playing
tag title Radio
stream Live stream' -f '{stream}'
check 'stream title' 'Live stream' "$STDOUT"

cmus 'status playing
file /music/test.mp3
duration invalid
position 10' -f '{duration} {position} {remaining}'
check 'invalid times' '--:-- 0:10 --:--' "$STDOUT"

cmus 'status playing
file /music/test.mp3
duration 10
position 20' -f '{remaining}'
check 'remaining time cannot be negative' '0:00' "$STDOUT"

cmus "$PLAYING" --state
check 'state-only output' 'playing' "$STDOUT"

cmus 'status stopped
tag title Old song' --empty-stopped
check 'stopped output can be suppressed' '' "$STDOUT"

cmus "$PLAYING" -f '123456789' --max-length 5
check 'truncation includes ellipsis' '1234…' "$STDOUT"
cmus "$PLAYING" -f '123' --max-length 1
check 'one-character truncation' '…' "$STDOUT"
cmus "$PLAYING" -f '123' --max-length 0
check 'zero-character truncation' '' "$STDOUT"

cmus 'status playing
tag artist A "quoted" \ artist
tag title Line' --json
check 'JSON escaping and fields' '{"text":"A \"quoted\" \\ artist - Line","alt":"playing","class":"playing"}' "$STDOUT"

CMUS_MOCK_FAIL=1 cmus ''
check 'remote failure exit code' '1' "$STATUS"
check 'remote failure message' 'cmus-now-playing: cmus is not running (cmus-remote -Q failed)' "$STDERR"
CMUS_MOCK_FAIL=1 cmus '' --quiet
check 'quiet remote failure' '' "$STDERR"
unset CMUS_MOCK_FAIL

cmus "$PLAYING" --max-length nope
check 'invalid max length exit code' '2' "$STATUS"
cmus "$PLAYING" --unknown
check 'unknown option exit code' '2' "$STATUS"

run env PATH="$TMP_DIR/empty" /bin/bash "$SCRIPT"
check 'missing cmus-remote exit code' '127' "$STATUS"
check 'missing cmus-remote message' 'cmus-now-playing: cmus-remote is not installed' "$STDERR"

run /bin/bash "$SCRIPT" --help
check 'help exit code' '0' "$STATUS"

printf '1..%d\n' "$TESTS"
if [ "$FAILURES" -ne 0 ]; then
    printf '%d test(s) failed\n' "$FAILURES" >&2
    exit 1
fi
