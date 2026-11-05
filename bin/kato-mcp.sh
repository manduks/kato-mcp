#!/bin/sh
# Starts Kato's local MCP server from the Kato app's command-line tool. It reads and sends nothing itself.
# Kato answers for the folder it starts in. Claude's desktop app starts it in /, so the bundle passes the
# client folder picked in Claude as the one argument. The Claude Code plugin passes none.
# In Claude's desktop app the folder is optional, so Claude turns Kato on at install. Until it is picked
# (Claude then passes the literal text ${user_config.folder}), or when Kato or the folder is missing, this
# answers every tool call with the one step that fixes it, instead of a server that silently fails.
KATO="$HOME/.local/bin/kato"
PICK='In Claude, open Settings > Extensions > Kato, pick the Client folder, then turn Kato off and on there.'
VERSION=0.2.2
tell() {  # $1 = the one sentence every tool call answers; a tiny MCP server over stdio, no other program
  while IFS= read -r line || [ -n "$line" ]; do
    # the request id: the last key (MCP SDK order), else the first (after "jsonrpc"), else the last "id" anywhere
    id=$(printf '%s\n' "$line" | sed -nE 's/.*"id"[[:space:]]*:[[:space:]]*("[^"\\]*"|-?[0-9]+)[[:space:]]*}[[:space:]]*$/\1/p')
    [ -n "$id" ] || id=$(printf '%s\n' "$line" | sed -nE 's/^[[:space:]]*[{]([[:space:]]*"jsonrpc"[[:space:]]*:[[:space:]]*"2[.]0"[[:space:]]*,)?[[:space:]]*"id"[[:space:]]*:[[:space:]]*("[^"\\]*"|-?[0-9]+).*/\2/p')
    [ -n "$id" ] || id=$(printf '%s\n' "$line" | sed -nE 's/.*"id"[[:space:]]*:[[:space:]]*("[^"\\]*"|-?[0-9]+).*/\1/p')
    [ -n "$id" ] || continue
    m=$(printf '%s\n' "$line" | sed -nE 's/.*"method"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n 1)
    case $m in
      tools/list) r='{"tools":[{"name":"kato_setup","description":"Kato: what was said, shown and promised on the client calls of the user, filed by client. Not set up yet: call this first whenever the user asks about Kato, their clients, calls, meetings or promises, and tell them the step it returns.","inputSchema":{"type":"object","properties":{}}}]}' ;;
      tools/call) r='{"content":[{"type":"text","text":"'"$1"'"}],"isError":true}' ;;
      initialize) r='{"protocolVersion":"2024-11-05","capabilities":{"tools":{}},"serverInfo":{"name":"kato","version":"'"$VERSION"'"}}' ;;
      ping) r='{}' ;;
      *) printf '{"jsonrpc":"2.0","id":%s,"error":{"code":-32601,"message":"Method not found"}}\n' "$id"; continue ;;
    esac
    printf '{"jsonrpc":"2.0","id":%s,"result":%s}\n' "$id" "$r"
  done
  exit 0
}
if [ ! -x "$KATO" ]; then
  echo "Kato isn't installed on this Mac. Get the app at https://installkato.com/?utm_medium=listing&utm_source=kato-mcp, then install its command-line tool from Kato's right-click menu." >&2
  [ $# -gt 0 ] && tell "Kato isn't installed on this Mac. Get the app at https://installkato.com/?utm_medium=listing&utm_source=kato-mcp, install its command-line tool from Kato's right-click menu, then turn Kato off and on in Claude's Settings > Extensions."
  exit 1
fi
if [ $# -gt 0 ]; then
  case $1 in
    '${user_config.folder}'|'') echo "No client folder picked in Claude yet." >&2
      tell "Kato is on, but no client folder is picked yet. $PICK It must be a folder bound to one client once, in Terminal: kato bind ~/kato <client> <folder> (kato spaces ~/kato lists the clients)." ;;
    /*) ;;
    *) echo "Kato needs the full path of the client folder picked in Claude, got: $1" >&2
      tell "The client folder picked in Claude is not a full path. $PICK" ;;
  esac
  CDPATH= cd -P "$1" >/dev/null 2>&1 || { echo "Kato can't open the client folder picked in Claude: $1" >&2
    tell "Kato can't open the client folder picked in Claude (moved or deleted?). $PICK"; }
fi
exec "$KATO" mcp "$HOME/kato"
