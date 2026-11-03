# Agent Session Bridge

[English](README.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md)

Local Claude Code and Codex session metadata for macOS apps, available as a Swift library and a small CLI.
Applications can share session detection and hooks while being installed and run independently.

Requires macOS 14+ and Swift 6 (Xcode Command Line Tools). No package dependencies or background daemon.

## Build and install

```sh
git clone https://github.com/chesterXalan/agent-session-bridge.git
cd agent-session-bridge
make build
.build/release/agent-session-bridge install
```

`install` copies the executable to `~/Library/Application Support/AgentSessionBridge/bin/agent-session-bridge`
and explicitly configures both providers' hooks. Restart CLI sessions and approve their updated hooks if prompted.
`install-runtime` copies only the executable; it does not change hooks.

```sh
"$HOME/Library/Application Support/AgentSessionBridge/bin/agent-session-bridge" list
```

`list` prints six tab-separated fields: provider, PID, state, title, working directory, and optional cmux location.
States are `working`, `waiting`, `idle`, or `unknown`. Missing or ambiguous hook metadata stays `unknown`.
`record --provider claude|codex` consumes hook JSON on stdin, stores only metadata, and always exits successfully.
For Codex it responds with `{}`. Use `--home DIR` to test against an isolated home directory.

`uninstall` removes the shared hooks for **all consumers**; it keeps the runtime and records.
Use `--provider claude|codex` with install/uninstall to limit the change to one provider.
Deleting a consumer app does not remove the shared runtime or hooks.

## Integration

Consumers pin this repository as `vendor/agent-session-bridge` using a Git submodule.
Clone them with `--recurse-submodules`, or run `git submodule update --init --recursive` in an existing checkout.
Swift apps depend on the `AgentSessionCore` library through a local Swift package dependency.
Other runtimes invoke the standalone CLI without a shell.

Update the submodule commit deliberately after testing the consuming applications. Build scripts never follow the
latest branch automatically. Consumers can build and bundle their pinned helper, then explicitly install it at the
shared path. Keep the CLI output and stored record format backward compatible within this initial protocol.

## Data and privacy

Metadata lives in `~/Library/Application Support/AgentSessionBridge/sessions/`.
Hook installation preserves unrelated settings and hooks, with `*.agent-session-bridge-<time>.bak` backups before changes.
For older installations, see the [migration guide](docs/migration.md).

Process matching prefers PID plus start time, then an explicit conversation ID. The limited Codex directory fallback
requires one eligible process and one recent conversation; it never guesses between multiple sessions.
tmux and cmux location metadata is retained, but this package does not focus terminals or control windows.

No prompts, tool arguments, terminal output, or conversation messages are stored or exposed.
Friendly titles use Codex's title index and bounded reads of Claude transcript title metadata.
The bridge makes no network requests; cmux title lookup uses its local CLI.

## Development

Run `make test` and `make build`. Tests cover provider/terminal/directory combinations, ambiguous identities,
title lookup, legacy migration, hook preservation, and standalone runtime installation.

Keep the English, Traditional Chinese, and Japanese README files in sync when changing setup or behavior.
Technical documentation and code comments remain in English.

## Credits

Extracted from [MH Desk Pets](https://github.com/chesterXalan/mh-desk-pets), based on [youngOman/desk-pets](https://github.com/youngOman/desk-pets).
Distributed under the [MIT License](LICENSE), retaining both copyright notices.
