#!/usr/bin/env python3
"""Exercise actual Readline insertion. pexpect is a test-only dependency."""

import os
import re
import shlex
import tempfile
import unittest
from pathlib import Path

import pexpect  # pyright: ignore[reportMissingModuleSource]  # ty: ignore[unresolved-import]

SCRIPT = Path(__file__).resolve().parents[1] / "bash" / "shellcheck"


class ReadlineTests(unittest.TestCase):
    def test_interactive_insertions(self):
        with tempfile.TemporaryDirectory(prefix="shellcheck-readline-") as directory:
            root = Path(directory)
            for name in ("alpha", "script with spaces", "script"):
                (root / name).touch()
            (root / "src").mkdir()
            env = dict(os.environ, PS1="SC_PROMPT> ", TERM="dumb", INPUTRC="/dev/null")
            child = pexpect.spawn(
                "bash",
                ["--noprofile", "--norc", "-i"],
                cwd=directory,
                env=env,
                encoding="utf8",
                timeout=5,
            )
            try:
                child.expect_exact("SC_PROMPT> ")
                child.sendline(
                    f"source {shlex.quote(str(SCRIPT))}; bind 'set bell-style none'; "
                    "_show_line() { printf '\\nSC_LINE:%s\\n' \"$READLINE_LINE\"; }; "
                    "bind -x '\"\\C-x\\C-g\":_show_line'"
                )
                child.expect_exact("SC_PROMPT> ")
                cases = [
                    ("shellcheck --format=js", "shellcheck --format=json"),
                    ("shellcheck --shell=bu", "shellcheck --shell=busybox "),
                    ("shellcheck -S w", "shellcheck -S warning "),
                    ("shellcheck --color a", "shellcheck --color alpha "),
                    (
                        "shellcheck --source-path=SCRIPTDIR:sr",
                        "shellcheck --source-path=SCRIPTDIR:src/",
                    ),
                    (
                        r"shellcheck --rcfile=script\ w",
                        "shellcheck --rcfile=script\\ with\\ spaces ",
                    ),
                    (
                        "shellcheck --rcfile='script w",
                        "shellcheck --rcfile='script with spaces' ",
                    ),
                    (
                        'shellcheck --rcfile="script w',
                        'shellcheck --rcfile="script with spaces" ',
                    ),
                ]
                for before, after in cases:
                    with self.subTest(before=before):
                        child.send(before + "\t\x18\x07")
                        child.expect(r"SC_LINE:([^\r\n]*)")
                        match = child.match
                        assert isinstance(match, re.Match)
                        self.assertEqual(match.group(1), after)
                        child.send("\x15")
            finally:
                child.close(force=True)


if __name__ == "__main__":
    unittest.main(verbosity=2)
