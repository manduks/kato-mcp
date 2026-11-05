#!/bin/sh
# Starts Kato's local MCP server from the Kato app's command-line tool. It reads and sends nothing itself.
KATO="$HOME/.local/bin/kato"
if [ ! -x "$KATO" ]; then
  echo "Kato isn't installed on this Mac. Get the app at https://installkato.com/?utm_medium=listing&utm_source=kato-mcp, then install its command-line tool from Kato's right-click menu." >&2
  exit 1
fi
exec "$KATO" mcp "$HOME/kato"
