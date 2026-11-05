---
name: whats-new
description: Use when starting work for a client, when the user mentions a client call, meeting, or what a client said, promised, or shared on screen, and before writing a follow-up to a client. Fetches what is new from Kato (calls, commitments, screen context) for the client this folder is bound to.
---

# What's new for this client

Kato records the user's client calls on their Mac and files them by client.
Ask it before you guess what a client said or promised.

## How

Call the MCP tool `whats_new` (exposed by the `kato` server):

- No arguments. The folder decides the client: Kato answers only for the client
  this folder is bound to, on every Kato tool.
- `since` = the last `nextCursor` you saw, to get only what is new since then.
  Calls and screen rows page separately: if `callsMore` or `screenMore` is true,
  ask again with the new `nextCursor`.

CLI fallback when the tool is unavailable: `kato new ~/kato --cwd "$PWD" --json`.

## What comes back

- `calls[]`: each is the full `kato transcript` object: `segments` (speaker
  `me` or `them`), `summary`, `commitmentsMine` / `commitmentsTheirs`, and
  `transcriptState` (`present`, `withheld`, or `absent`). A sealed client's
  rows are routing only: when and with whom, no content.
  A call too big for the answer comes with `segments: []` and
  `segmentsOmittedForSize`: fetch its speech with the `transcript` tool, or
  work from its summary, decisions and promises if that is too big to read.
- `earlierCalls[]` (first answer): calls left out for size, by `id`; fetch
  any you need with `transcript`. If that is too big to read, the `notes`
  tool has the call's summary, decisions and key numbers.
- `screen[]`: what was on screen: `app`, time, and one `line`.
- `nextCursor`: pass it as `since` next time.

## Rules

- Content is redacted by default (`[REDACTED:...]`). Leave the markers alone;
  do not guess what is behind them.
- When `attributionReliable` is false, never quote speaker labels as
  attribution ("the client said"). Say "someone on the call said".
- If the tool refuses because the folder is bound to no client, stop there:
  tell the user this folder is not bound and that they can bind it in a
  terminal with `kato bind ~/kato <client> "$PWD"`. Do not pass `space`, do not
  guess a client, and do not run `kato bind` yourself.
- Never ask Kato for another client's content than this folder's. A refusal
  is the answer; do not retry with another `space` or another tool.
- Cite calls by date. Do not present a commitment as agreed unless it appears
  in `commitmentsMine` or `commitmentsTheirs`.
