from pathlib import Path
import tempfile
import unittest

from import_loader import ImportExpander, _without_markdown_code, instruction_entries


class ImportLoaderTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def test_recursive_imports_and_code_are_handled_structurally(self):
        (self.root / "nested.md").write_text("nested body\n")
        (self.root / "direct.md").write_text("direct body @nested.md\n")
        entry = self.root / "CLAUDE.md"
        entry.write_text("Use @direct.md\n`@ignored.md`\n```\n@also-ignored.md\n```\n")

        expander = ImportExpander(allowed_roots=[self.root])
        blocks = expander.expand_imports_only(entry)

        self.assertEqual(1, len(blocks))
        self.assertIn("direct body", blocks[0])
        self.assertIn("nested body", blocks[0])
        self.assertNotIn("ignored.md", "\n".join(expander.warnings))

    def test_cycle_outside_root_and_depth_are_bounded(self):
        outside = self.root.parent / "outside-import-test.md"
        (self.root / "a.md").write_text("@b.md @../outside-import-test.md\n")
        (self.root / "b.md").write_text("@a.md\n")
        entry = self.root / "CLAUDE.md"
        entry.write_text("@a.md\n")
        expander = ImportExpander(allowed_roots=[self.root], max_depth=4)
        expander.expand_imports_only(entry)
        self.assertTrue(any("cyclic import" in warning for warning in expander.warnings))
        self.assertTrue(any("outside allowed roots" in warning for warning in expander.warnings))
        self.assertFalse(outside.exists())

    def test_instruction_entry_precedence_and_fallback(self):
        codex = self.root / ".codex"
        codex.mkdir()
        (codex / "AGENTS.md").write_text("global\n")
        repo = self.root / "repo"
        child = repo / "src"
        child.mkdir(parents=True)
        (repo / ".git").mkdir()
        (repo / "CLAUDE.md").write_text("repo\n")
        (child / "AGENTS.md").write_text("child agents\n")
        (child / "CLAUDE.md").write_text("child fallback\n")

        entries = instruction_entries(child, codex, ["CLAUDE.md"])
        self.assertEqual([codex / "AGENTS.md", repo / "CLAUDE.md", child / "AGENTS.md"], entries)

    def test_code_mask_preserves_offsets(self):
        text = "before `@no.md` @yes.md\n```md\n@nope.md\n```\n"
        masked = _without_markdown_code(text)
        self.assertEqual(len(text), len(masked))
        self.assertNotIn("@no.md", masked)
        self.assertIn("@yes.md", masked)
        self.assertNotIn("@nope.md", masked)


if __name__ == "__main__":
    unittest.main()
