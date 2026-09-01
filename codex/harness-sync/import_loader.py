#!/usr/bin/env python3
"""Expand Claude-style @file imports for Codex SessionStart.

The loader understands only import structure. It does not inspect or classify
the instructions it transports. Entry documents themselves are loaded by
Codex; this hook emits only their recursively imported files.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import re
import sys
from typing import Iterable


IMPORT_RE = re.compile(r"(?<![\w@])@(?P<path>[^\s`<>{}\[\](),;:!?，。；：！？]+)")


def _without_markdown_code(text: str) -> str:
    """Return same-length text with fenced and inline code replaced by spaces."""
    output: list[str] = []
    fence: str | None = None
    for line in text.splitlines(keepends=True):
        stripped = line.lstrip()
        fence_match = re.match(r"(`{3,}|~{3,})", stripped)
        if fence is not None:
            output.append("\n" if line.endswith("\n") else "")
            output[-1] = " " * (len(line) - len(output[-1])) + output[-1]
            if fence_match and fence_match.group(1).startswith(fence[0]) and len(fence_match.group(1)) >= len(fence):
                fence = None
            continue
        if fence_match:
            fence = fence_match.group(1)
            output.append(" " * (len(line) - (1 if line.endswith("\n") else 0)) + ("\n" if line.endswith("\n") else ""))
            continue

        chars = list(line)
        index = 0
        while index < len(chars):
            if chars[index] != "`":
                index += 1
                continue
            end_run = index
            while end_run < len(chars) and chars[end_run] == "`":
                end_run += 1
            marker = "`" * (end_run - index)
            closing = line.find(marker, end_run)
            if closing < 0:
                index = end_run
                continue
            for position in range(index, closing + len(marker)):
                if chars[position] != "\n":
                    chars[position] = " "
            index = closing + len(marker)
        output.append("".join(chars))
    return "".join(output)


def _is_within(path: Path, roots: Iterable[Path]) -> bool:
    for root in roots:
        try:
            path.relative_to(root)
            return True
        except ValueError:
            pass
    return False


class ImportExpander:
    def __init__(self, *, allowed_roots: Iterable[Path], max_depth: int = 4, max_bytes: int = 131_072):
        self.allowed_roots = tuple(root.expanduser().resolve() for root in allowed_roots)
        self.max_depth = max_depth
        self.max_bytes = max_bytes
        self.loaded: set[Path] = set()
        self.active: set[Path] = set()
        self.bytes_read = 0
        self.warnings: list[str] = []

    @staticmethod
    def _resolve(raw: str, parent: Path) -> Path:
        candidate = Path(raw).expanduser()
        if not candidate.is_absolute():
            candidate = parent / candidate
        return candidate.resolve()

    def imports_from(self, text: str, parent: Path) -> list[tuple[int, int, Path]]:
        searchable = _without_markdown_code(text)
        found: list[tuple[int, int, Path]] = []
        for match in IMPORT_RE.finditer(searchable):
            found.append((match.start(), match.end(), self._resolve(match.group("path"), parent)))
        return found

    def expand_file(self, path: Path, depth: int) -> str:
        path = path.resolve()
        if depth > self.max_depth:
            self.warnings.append(f"maximum import depth exceeded at {path}")
            return ""
        if path in self.active:
            self.warnings.append(f"cyclic import skipped: {path}")
            return ""
        if path in self.loaded:
            return ""
        if not _is_within(path, self.allowed_roots):
            self.warnings.append(f"import outside allowed roots skipped: {path}")
            return ""
        try:
            raw = path.read_bytes()
        except OSError as error:
            self.warnings.append(f"unable to read import {path}: {error.strerror or error}")
            return ""
        if self.bytes_read + len(raw) > self.max_bytes:
            self.warnings.append(f"import byte limit exceeded before {path}")
            return ""

        self.bytes_read += len(raw)
        self.loaded.add(path)
        self.active.add(path)
        text = raw.decode("utf-8", errors="replace")
        imports = self.imports_from(text, path.parent)
        pieces: list[str] = []
        cursor = 0
        for start, end, imported_path in imports:
            pieces.append(text[cursor:start])
            nested = self.expand_file(imported_path, depth + 1)
            if nested:
                pieces.append(f"\n\n<!-- imported from {imported_path} -->\n{nested}\n")
            cursor = end
        pieces.append(text[cursor:])
        self.active.remove(path)
        return "".join(pieces)

    def expand_imports_only(self, entry: Path) -> list[str]:
        try:
            text = entry.read_text(errors="replace")
        except OSError:
            return []
        blocks: list[str] = []
        for _, _, imported_path in self.imports_from(text, entry.resolve().parent):
            expanded = self.expand_file(imported_path, 1)
            if expanded:
                blocks.append(f"## Imported instructions: {imported_path}\n\n{expanded}")
        return blocks


def _project_root(cwd: Path) -> Path:
    for candidate in (cwd, *cwd.parents):
        if (candidate / ".git").exists():
            return candidate
    return cwd


def instruction_entries(cwd: Path, codex_home: Path, fallback_names: Iterable[str]) -> list[Path]:
    entries: list[Path] = []
    global_entry = codex_home / "AGENTS.override.md"
    if not global_entry.is_file():
        global_entry = codex_home / "AGENTS.md"
    if global_entry.is_file():
        entries.append(global_entry)

    root = _project_root(cwd)
    lineage = list(reversed([cwd, *cwd.parents]))
    try:
        start = lineage.index(root)
        lineage = lineage[start:]
    except ValueError:
        lineage = [cwd]
    names = ("AGENTS.override.md", "AGENTS.md", *fallback_names)
    for directory in lineage:
        for name in names:
            candidate = directory / name
            if candidate.is_file() and candidate.stat().st_size:
                entries.append(candidate)
                break

    deduplicated: list[Path] = []
    seen: set[Path] = set()
    for entry in entries:
        resolved = entry.resolve()
        if resolved not in seen:
            seen.add(resolved)
            deduplicated.append(entry)
    return deduplicated


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fallback", action="append", default=["CLAUDE.md"])
    parser.add_argument("--max-depth", type=int, default=4)
    parser.add_argument("--max-bytes", type=int, default=131_072)
    args = parser.parse_args()

    try:
        hook_input = json.load(sys.stdin)
    except json.JSONDecodeError:
        hook_input = {}
    cwd = Path(hook_input.get("cwd") or Path.cwd()).resolve()
    home = Path.home().resolve()
    codex_home = (home / ".codex").resolve()
    entries = instruction_entries(cwd, codex_home, args.fallback)
    project_root = _project_root(cwd)
    allowed_roots = [home / ".claude", project_root]
    expander = ImportExpander(allowed_roots=allowed_roots, max_depth=args.max_depth, max_bytes=args.max_bytes)

    blocks: list[str] = []
    for entry in entries:
        blocks.extend(expander.expand_imports_only(entry))
    output: dict[str, object] = {}
    if blocks:
        output["hookSpecificOutput"] = {
            "hookEventName": "SessionStart",
            "additionalContext": "\n\n".join(blocks),
        }
    if expander.warnings:
        output["systemMessage"] = "Claude instruction import bridge: " + "; ".join(expander.warnings)
    if output:
        print(json.dumps(output, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
