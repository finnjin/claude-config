import json
import os
from pathlib import Path
import tempfile
import unittest

from sync import MANAGED_AGENT_HEADER, Sync


class SyncTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        root = Path(self.temp.name)
        self.source = root / ".claude"
        self.codex = root / ".codex"
        self.agents = root / ".agents"
        (self.source / "skills" / "review").mkdir(parents=True)
        (self.source / "skills" / "review" / "SKILL.md").write_text("---\nname: review\n---\nDo it.\n")
        (self.source / "agents").mkdir()
        (self.source / "agents" / "reviewer.md").write_text(
            "---\nname: reviewer\ndescription: Review changes\ntools: Bash, Read\n---\nReview carefully.\n"
        )

    def tearDown(self):
        self.temp.cleanup()

    def run_sync(self, *, check=False, adopt=False):
        return Sync(self.source, self.codex, self.agents, check=check, adopt=adopt).run()

    def test_links_and_translates_without_touching_source(self):
        before = (self.source / "skills" / "review" / "SKILL.md").read_text()
        self.assertEqual(0, self.run_sync(adopt=True))
        self.assertTrue((self.agents / "skills").is_symlink())
        self.assertEqual((self.source / "skills").resolve(), (self.agents / "skills").resolve())
        agent = (self.codex / "agents" / "reviewer.toml").read_text()
        self.assertTrue(agent.startswith(MANAGED_AGENT_HEADER))
        self.assertIn('name = "reviewer"', agent)
        self.assertIn(str(self.source / "agents" / "reviewer.md"), agent)
        self.assertNotIn("Review carefully.", agent)
        self.assertNotIn("sandbox_mode", agent)
        self.assertFalse((self.codex / "hooks.json").exists())
        self.assertEqual(before, (self.source / "skills" / "review" / "SKILL.md").read_text())

    def test_check_reports_drift(self):
        self.assertEqual(1, self.run_sync(check=True))
        self.assertFalse((self.agents / "skills" / "review").exists())

    def test_adopt_backs_up_existing_codex_target(self):
        target = self.agents / "skills"
        target.parent.mkdir(parents=True)
        target.write_text("old codex copy\n")
        self.assertEqual(2, self.run_sync())
        self.assertEqual("old codex copy\n", target.read_text())
        self.assertEqual(0, self.run_sync(adopt=True))
        self.assertTrue(target.is_symlink())
        backups = list((self.codex / "harness-sync" / "backups").rglob("agents-skills"))
        self.assertEqual(1, len(backups))
        self.assertEqual("old codex copy\n", backups[0].read_text())

    def test_retired_command_links_are_removed(self):
        stale = self.codex / "prompts" / "cr.md"
        stale.parent.mkdir(parents=True)
        stale.symlink_to(self.source / "commands" / "cr.md")
        state = self.codex / "harness-sync" / "state.json"
        state.parent.mkdir(parents=True)
        state.write_text(json.dumps({"links": {str(stale): str(self.source / "commands" / "cr.md")}}))
        self.assertEqual(0, self.run_sync(adopt=True))
        self.assertFalse(os.path.lexists(stale))


if __name__ == "__main__":
    unittest.main()
