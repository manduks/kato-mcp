#!/bin/sh
# Starts Kato's local MCP server from the Kato app's command-line tool. It reads and sends nothing itself.
# Kato answers for the folder it starts in. Claude's desktop app starts it in /, so the bundle passes the
# client folder picked in Claude as the one argument. The Claude Code plugin passes none.
KATO="$HOME/.local/bin/kato"
if [ ! -x "$KATO" ]; then
  echo "Kato isn't installed on this Mac. Get the app at https://installkato.com/?utm_medium=listing&utm_source=kato-mcp, then install its command-line tool from Kato's right-click menu." >&2
  exit 1
fi
if [ $# -gt 0 ]; then
  case $1 in
    /*) ;;
    *) echo "Kato needs the full path of the client folder picked in Claude, got: $1" >&2; exit 1 ;;
  esac
  CDPATH= cd -P "$1" >/dev/null 2>&1 || { echo "Kato can't open the client folder picked in Claude: $1" >&2; exit 1; }
fi
exec "$KATO" mcp "$HOME/kato"
