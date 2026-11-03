# Agent Session Bridge

- Keep this package independent of app interfaces, pet assets, browsers, and terminal focus actions.
- Preserve PID/start-time and conversation-ID matching; never guess between ambiguous sessions.
- Store only session metadata. Never log hook payloads, prompts, tool arguments, or process environments.
- Hook configuration changes require an explicit install/uninstall command. Preserve unrelated hooks and backups.
- Write new code comments, technical documentation, and Gitmoji + Conventional Commit messages in English.
- Keep README.md, README.zh-TW.md, and README.ja.md synchronized when setup or behavior changes.
- Run `make test` and `make build`. Exercise installation with a temporary `--home` before changing real hooks.
- Preserve the MIT license and original attribution.
