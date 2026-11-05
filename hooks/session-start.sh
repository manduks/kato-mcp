#!/usr/bin/env bash
# Kato SessionStart hook: print at most 5 lines of "what's new for the client
# this folder is bound to", or one line if Kato is not installed. Prints nothing else, never blocks, always exits 0.
set -u

KATO="${KATO_CLI:-}"
if [ -z "$KATO" ]; then
  KATO="$(command -v kato 2>/dev/null || true)"
fi
if [ -z "$KATO" ]; then
  KATO="$HOME/.local/bin/kato"
fi
BRAIN="${KATO_BRAIN:-$HOME/kato}"

if [ ! -x "$KATO" ]; then
  echo "Kato isn't installed on this Mac, so its tools won't start. Get it at https://installkato.com/?utm_medium=listing&utm_source=kato-hook"
  exit 0
fi
[ -f "$BRAIN/agent/SOUL.md" ] || exit 0

OUT="$(mktemp "${TMPDIR:-/tmp}/kato-hook.XXXXXX" 2>/dev/null)" || exit 0
trap 'rm -f "$OUT"' EXIT

# Hard 5 s bound (macOS has no `timeout`): run in the background, poll, kill.
# stdout/stderr go to files, so an orphaned grandchild can never hold our pipe.
"$KATO" new "$BRAIN" --cwd "$PWD" --digest </dev/null >"$OUT" 2>/dev/null &
PID=$!
i=0
while [ "$i" -lt 50 ]; do
  kill -0 "$PID" 2>/dev/null || break
  sleep 0.1
  i=$((i + 1))
done
if kill -0 "$PID" 2>/dev/null; then
  pkill -P "$PID" 2>/dev/null
  kill "$PID" 2>/dev/null
  { wait "$PID"; } 2>/dev/null
  # A timed-out digest is dropped whole rather than printed half-written.
  exit 0
fi
wait "$PID" 2>/dev/null
RC=$?

# Print ONLY a digest this script understands: kato exited 0 and wrote ONE line of JSON
# {"kato":"digest","schema":1,"lines":[...]}. Anything else prints nothing: a kato that predates
# `kato new` prints its help text for it (exit 1), and that must never reach a session.
[ "$RC" -eq 0 ] || exit 0
[ -s "$OUT" ] || exit 0
[ "$(wc -l < "$OUT" | tr -d ' ')" -le 1 ] || exit 0
PL=/usr/bin/plutil
[ -x "$PL" ] || exit 0
[ "$("$PL" -extract kato raw -o - -- "$OUT" 2>/dev/null)" = "digest" ] || exit 0
[ "$("$PL" -extract schema raw -o - -- "$OUT" 2>/dev/null)" = "1" ] || exit 0
TXT="$(mktemp "${TMPDIR:-/tmp}/kato-hook-txt.XXXXXX" 2>/dev/null)" || exit 0
trap 'rm -f "$OUT" "$TXT"' EXIT
n=0
while [ "$n" -lt 5 ]; do
  line="$("$PL" -extract "lines.$n" raw -o - -- "$OUT" 2>/dev/null)" || break
  printf '%s\n' "$line" >>"$TXT"
  n=$((n + 1))
done
head -n 5 "$TXT"
exit 0
