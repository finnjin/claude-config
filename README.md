# claude-config

Personal Claude Code + Codex harness: doctrine, settings, statusline, and the
Codex bridge that shares them with `codex`.

## New machine

```sh
git clone git@github.com:finnjin/claude-config.git ~/.claude
bash ~/.claude/bootstrap.sh
```

`bootstrap.sh` is idempotent. It renders `~/.codex/hooks.json` from
`codex/hooks.json.tmpl`, merges the portable sections of
`codex/config.toml.snippet` into `~/.codex/config.toml` without touching the
machine's own `[projects.*]` trust list, links `~/.codex/AGENTS.md` to
`CLAUDE.md`, and runs `codex/harness-sync/sync.py` to link `~/.agents/skills`
and generate `~/.codex/agents/*.toml` adapters for any local agent definitions.

## What is not in here

- `skills/`, `agents/`, `scripts/`, `prompts/` — work content; distributed
  separately (team registry / local only). `bootstrap.sh` creates an empty
  `skills/` so the Codex link never dangles; the bridge picks contents up as
  they appear.
- Machine and account state: `settings.local.json`, `memory/`, `projects/`,
  `~/.codex/auth.json`, and the bridge's `state.json` / `backups/` / `logs/`
  (those stay in `~/.codex/harness-sync/`).

`.gitignore` is a whitelist: everything is ignored, tracked paths are opted in
one by one. Add a `!path` rule when you want something version-controlled.

## Known limitation

`settings.json` hardcodes `/Users/finnjin` in `permissions.additionalDirectories`
and needs a manual edit on a machine with a different username. `bootstrap.sh`
deliberately does not rewrite it, because patching a tracked file would leave
the clone permanently dirty.
