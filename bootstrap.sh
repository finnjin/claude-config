#!/bin/bash
# Bring a fresh machine up to this harness. Assumes this repo is cloned to ~/.claude.
# Idempotent: safe to re-run after every pull.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX="$HOME/.codex"
STAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$CODEX" "$HOME/.agents"

# --- Codex SessionStart hook (absolute paths, so it is generated per machine) ---
HOOKS="$CODEX/hooks.json"
RENDERED="$(sed "s|__HOME__|$HOME|g" "$REPO/codex/hooks.json.tmpl")"
if [ ! -e "$HOOKS" ]; then
  printf '%s\n' "$RENDERED" > "$HOOKS"
  echo "created $HOOKS"
elif [ "$RENDERED" = "$(cat "$HOOKS")" ]; then
  echo "ok      $HOOKS"
else
  cp "$HOOKS" "$HOOKS.bak-$STAMP"
  printf '%s\n' "$RENDERED" > "$HOOKS"
  echo "updated $HOOKS (previous saved as $HOOKS.bak-$STAMP)"
fi

# --- Codex config: merge portable sections only, never clobber machine state ---
# ([projects.*] trust decisions and account state live in the same file.)
SNIPPET="$REPO/codex/config.toml.snippet"
CONFIG="$CODEX/config.toml"
if [ ! -e "$CONFIG" ]; then
  cp "$SNIPPET" "$CONFIG"
  echo "created $CONFIG"
else
  # ponytail: one marker line per block decides presence; a half-written block is
  # not detected. Switch to a real TOML merge if that ever bites.
  block() { awk -v m="$1" 'index($0,m)==1{f=1} f&&NF==0{exit} f' "$SNIPPET"; }
  if ! grep -q '^project_doc_fallback_filenames' "$CONFIG"; then
    # top-level keys must land above the first [section] header or TOML swallows them
    { block 'model = '; echo; cat "$CONFIG"; } > "$CONFIG.tmp" && mv "$CONFIG.tmp" "$CONFIG"
    echo "added   $CONFIG: top-level keys"
  fi
  for section in '[features]' '[mcp_servers.codegraph]' '[tui]'; do
    if ! grep -qF "$section" "$CONFIG"; then
      { echo; block "$section"; } >> "$CONFIG"
      echo "added   $CONFIG: $section"
    fi
  done
fi

# --- Codex entry point: AGENTS.md is Claude's CLAUDE.md ---
AGENTS="$CODEX/AGENTS.md"
if [ "$(readlink "$AGENTS" 2>/dev/null || true)" != "../.claude/CLAUDE.md" ]; then
  if [ -e "$AGENTS" ] || [ -L "$AGENTS" ]; then
    mv "$AGENTS" "$AGENTS.bak-$STAMP"
    echo "backed up existing $AGENTS"
  fi
  ln -sfn ../.claude/CLAUDE.md "$AGENTS"
  echo "linked  $AGENTS -> ../.claude/CLAUDE.md"
fi

# --- skills symlink + generated Codex agent adapters ---
# skills/ is not version-controlled; a fresh clone lacks it and the link must not dangle.
mkdir -p "$REPO/skills"
python3 "$REPO/codex/harness-sync/sync.py"
