"""A failed Git snapshot must never be reported as a verified build commit."""
from pathlib import Path
from subprocess import CompletedProcess
import sys
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "template/tools"))
import build


def reply(stdout="", code=0, stderr=""):
    return CompletedProcess([], code, stdout, stderr)


class SnapshotTests(unittest.TestCase):
    def test_index_write_denied_stops_before_build(self):
        with patch.object(build, "run", side_effect=[reply("/tmp/repo\n"),
                reply(code=128, stderr="index.lock: Operation not permitted")]) as git:
            with self.assertRaisesRegex(SystemExit, "git add failed"):
                build.commit_tree([])
            self.assertEqual(git.call_count, 2)

    def test_commit_failure_is_fatal(self):
        with patch.object(build, "run", side_effect=[reply("/tmp/repo\n"), reply(),
                reply(code=1), reply(code=128, stderr="cannot write commit")]):
            with self.assertRaisesRegex(SystemExit, "git commit failed"):
                build.commit_tree([])

    def test_literal_head_is_not_a_commit(self):
        with patch.object(build, "run", side_effect=[reply("/tmp/repo\n"), reply(),
                reply(), reply("HEAD\n")]):
            with self.assertRaisesRegex(SystemExit, "valid commit ID"):
                build.commit_tree([])

    def test_clean_tree_reuses_real_commit(self):
        commit = "a" * 40
        with patch.object(build, "run", side_effect=[reply("/tmp/repo\n"), reply(),
                reply(), reply(commit + "\n")]) as git:
            self.assertEqual(build.commit_tree([]), commit)
            self.assertFalse(any(call.args[0][1] == "commit" for call in git.call_args_list))


if __name__ == "__main__":
    unittest.main()
