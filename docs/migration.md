# Migrating from DeskPets hooks

The shared bridge was extracted from [MH Desk Pets](https://github.com/chesterXalan/mh-desk-pets)
at commit `ac97087`. New installations do not need DeskPets or its data directory.

## Install the shared hooks

Follow the [build and install steps](../README.md#build-and-install). The `install` command:

- Copies the executable to `~/Library/Application Support/AgentSessionBridge/bin/agent-session-bridge`.
- Replaces legacy `deskpets-hook-v1` entries with one `agent-session-bridge-v1` entry per supported event.
- Preserves unrelated settings and hooks in `~/.claude/settings.json` and `~/.codex/hooks.json`.
- Backs up changed files as `*.agent-session-bridge-<time>.bak` before writing.

Restart CLI sessions and approve their updated hooks if prompted. Starting a consumer app does not
install or change hooks automatically. Both providers use the same shared runtime and metadata directory.

## Existing sessions and records

New records are written to `~/Library/Application Support/AgentSessionBridge/sessions/`.
Readers also accept old records from `~/Library/Application Support/DeskPets/sessions/` while already-running
CLI sessions finish using their loaded hooks. The latest matching record wins; files are not moved or deleted.
This compatibility path is optional and is not needed for fresh installations.

The updated desktop app retains `deskpets-hook` as a compatibility command. Session and hook operations
delegate to the shared implementation; `pets show|hide` remains specific to the desktop app.

## Removing an app or hooks

Deleting a consumer app does not remove the shared runtime or hooks. Other consumers keep working.
The explicit `uninstall` command removes shared hooks for **all consumers**, including legacy entries,
but keeps the executable and records. Use `--provider claude|codex` to limit removal to one provider.
