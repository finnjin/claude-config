# Claude Code → Codex harness bridge

Claude Code is the read-only source of truth. The bridge never writes under
`~/.claude`.

Directly shared (symbolic links, so content changes are immediate):

- `~/.codex/AGENTS.md` → `~/.claude/CLAUDE.md`
- `~/.agents/skills` → `~/.claude/skills`
- Claude agents stay at their original paths; generated Codex TOML files are
  thin adapters that read those files at invocation time.
- Claude-style `@file` imports are recursively expanded by a Codex-owned
  `SessionStart` hook. The entry document body is still loaded by Codex itself.

Structurally reconciled because the host schemas differ:

- Claude agents → thin `~/.codex/agents/*.toml` adapters

The reconciler knows file locations, extensions, and target schemas only. It
does not parse workflow instructions, copy definition bodies, select models, infer
permissions, or translate tool policies. Claude hooks are intentionally not
synchronized; hooks are host-native. Also separate: permissions and sandbox
policy, plugins, MCP ownership, memories, chats, jobs, and runtime state.

Most shared content updates immediately. Run the bridge only after adding,
removing, or renaming a Claude agent:

```sh
python3 ~/.claude/codex/harness-sync/sync.py --check
python3 ~/.claude/codex/harness-sync/sync.py
```

`--adopt` is only for the initial migration or an intentional takeover. It
backs up conflicting Codex files before replacing them.

Machine-local state (`state.json`, `backups/`, `logs/`) stays in
`~/.codex/harness-sync/`; only the code is version-controlled here.

There is no timer, login job, or background process. The Claude tree is always
read-only to this bridge.
