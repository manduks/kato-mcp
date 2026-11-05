# Kato for Claude Code

Kato is the eyes and ears of your agents. It runs on your Mac, hears your client calls and files them by client. This plugin lets an agent working in a client's folder ask what was said, shown and promised, with no paste. What an agent reports done shows as "says done, not verified".

## You need the Kato app

This repository holds only the plugin. **The Kato app is not open source and is sold separately:** $29/month USD with a 7-day trial and a card up front, at [installkato.com](https://installkato.com/?utm_medium=listing&utm_source=github). It runs on an Apple Silicon Mac with macOS 14 or later (14.4 or later for both sides of a call). Without the app the plugin does nothing except say so.

Know what the app does before you install it. It starts on its own on any call, client or personal, when a meeting app or a browser is in front with your mic in use. Between calls it reads the text of the window you're in. Audio stays on your Mac; transcript and window text go to the hosted brain, logged in a ledger on your Mac. Its [privacy page](https://installkato.com/privacy?utm_medium=listing&utm_source=github) has the details.

## What this plugin runs and sends

- `bin/kato-mcp.sh` starts `~/.local/bin/kato mcp ~/kato`, a local server over stdio, in the folder it was started in (in Claude's desktop app, the client folder you picked). If that file is missing, it prints where to get Kato and stops; in Claude's desktop app, every tool call answers with that link instead, and the same for a folder not picked yet or gone.
- `hooks/session-start.sh` runs the same local tool at session start and prints at most 5 lines of what is new for the client this folder is bound to, or one line if Kato isn't installed.
- `skills/whats-new` tells the agent when to ask.

The plugin opens no network connection and has no key.

## Install

1. Install the app from the link above and start the trial.
2. Install the command-line tool from Kato's right-click menu.
3. In your shell:

```
claude plugin marketplace add manduks/kato-mcp
claude plugin install kato@kato
```

Run `/reload-plugins` or start a new session afterwards. The server reads the brain at `~/kato`. Elsewhere, use `kato connect <brain>` instead, which also registers Kato in Cursor, Codex and OpenCode. Pick one: with both, Claude Code shows the tools twice.

### Claude's desktop app

Claude's desktop app doesn't start Kato in a folder, so Kato needs you to pick one. Download `kato-mcp.mcpb` from the [latest release](https://github.com/manduks/kato-mcp/releases/latest), open it and press **Install**; Claude turns Kato on. Then open Settings > Extensions > Kato and pick the **Client folder**. Until you do, every Kato tool answers with that step. Bind that folder first (next section): a folder bound to no client gets a refusal from every tool. Kato in Claude's app then answers for that folder's client and nothing else, or for every client if you bound it with `--all`. Every conversation in Claude's app uses this one folder.

## Bind a folder to a client

An agent gets nothing until its folder is bound, and a client exists in Kato only once you have filed a call to it (Kato asks which client when the call ends) or named it when you set up the app. So a new install answers nothing before your first call. After that:

```
kato spaces ~/kato
kato bind ~/kato <client> <dir>
```

A folder bound to a client sees only that client, on EVERY tool of the `kato`
server (transcripts, notes, commitments, search, brief, not only `whats_new`):
asking for another client is refused with no content. A folder bound to no
client gets a refusal from every tool (it names no client) and silence from the
hook. For your own operator workspace, where an agent should see every client:

```
kato bind ~/kato --all <dir>
```

That is set by hand only; Kato never learns or guesses it. `kato bind ~/kato
--unbind <dir>` removes either kind.

A folder that holds two or more git repositories (and has no `.git` of its own)
is refused, because binding it would hand the client to every one of them; the
refusal lists the repositories it found. A folder holding just one binds, and
`kato bind` names that one project so it is in view. If Kato later learns that
project is another client's (a folder it has seen you use for that client), the
project's folder answers no client until you bind it yourself. A folder Kato
cannot fully read (permissions) is refused unless it already found two
repositories. Hidden folders (`.founder`, `.claude`)
and dependency folders (`node_modules`, `vendor`, `third_party`, `Carthage`,
`Pods`) are not counted. If it is one project, `git init` in it makes it
bindable. If every repository in it belongs to that client, bind it anyway:

```
kato bind ~/kato <client> <dir> --wide-ok
```

`--wide-ok` is recorded with the binding and lifts only that rule: your home
folder, `/`, `/tmp` and a non-git folder directly in your home are still refused.
Kato checks what a folder holds once, when you bind it, so a repository cloned
into a bound folder later does not change who that folder answers for. (A row
Kato learned on its own is checked the first time a session starts in it.)
`--unbind` makes a folder answer no client — also one inside another client's
bound folder, and also an `--all` folder — and says what the folder answers
afterwards (and which outer folder answers for its other folders again).
A bound folder whose path now runs through a symlink, or a binding Kato cannot
read in `agent/work-roots.json`, answers no client until you bind it again.

## Codex

Skills use the shared `skills/<name>/SKILL.md` layout. OpenAI documents
`.claude-plugin/marketplace.json` as a legacy-compatible marketplace location
but does not document reading Claude's `plugin.json`, so for Codex use
`kato connect` (it registers `[mcp_servers.kato]` in `~/.codex/config.toml`).
Codex plugin hooks are not supported for directory submission.

## Privacy

The plugin and its server run on your Mac and open no network connection. The app
itself sends transcript and window text to the hosted brain, as said above. Answers
to agents are redacted by default (`[REDACTED:...]`).
A sealed client returns routing only (when, with whom), never content, on every
tool. Through the `kato` MCP server, a folder bound to one client never receives
another client's content.

Said plainly: this wall binds an agent that reaches Kato only through MCP. An
agent that can run shell commands can run `kato transcript` or read the brain's
files (`~/kato`) directly; the folder binding does not stop that. The CLI keeps
`--space` because a terminal is your own process.

The hook prints only a digest it can parse (one JSON line from `kato new
--digest`); an older `kato` that does not know `new` prints nothing. It moves the
folder's place forward only after the digest is written and only while there is
still time for the hook to print it (3.5 s into its 5 s), so a slow start repeats
the news next session instead of skipping it.
