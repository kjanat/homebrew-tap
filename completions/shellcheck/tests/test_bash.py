#!/usr/bin/env python3
"""Regression tests for the Bash completer. Python is a test-only dependency."""

import os
import shlex
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "bash" / "shellcheck"


class BashCompletionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="shellcheck-completion-")
        cls.cwd = Path(cls.temp.name)
        for name in (
            "script",
            "script with spaces",
            "alpha",
            "bash-file",
            "--shell-file",
            ".shellcheckrc",
        ):
            (cls.cwd / name).touch()
        for name in ("src", "source space", "bin"):
            (cls.cwd / name).mkdir()
        (cls.cwd / "src" / "nested").mkdir()
        (cls.cwd / "src" / "not-a-directory").touch()
        executable = cls.cwd / "bin" / "shellcheck"
        executable.write_text("""#!/bin/sh
[ -z "$SHELLCHECK_OPTS" ] || exit 9
[ "$1" = --norc ] && [ "$2" = --list-optional ] || exit 8
printf '%s\\n' 'name:    add-default-case' 'desc: Example' '' 'name:    quote-safe-variables'
""")
        executable.chmod(0o755)
        cls.env = dict(
            os.environ,
            PATH=str(cls.cwd / "bin") + ":" + os.environ["PATH"],
            SHELLCHECK_OPTS="--invalid-flag",
        )

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def complete(self, *args, fragment=None):
        words = ["shellcheck", *args]
        if fragment is None:
            fragment = words[-1]
        code = f"""source {shlex.quote(str(SCRIPT))}
COMP_WORDS=({" ".join(map(shlex.quote, words))})
COMP_CWORD={len(words) - 1}
_shellcheck_complete shellcheck {shlex.quote(fragment)} ''
if (( ${{#COMPREPLY[@]}} )); then printf '%s\\0' "${{COMPREPLY[@]}}"; fi
"""
        result = subprocess.run(
            ["bash", "--noprofile", "--norc", "-c", code],
            cwd=self.cwd,
            env=self.env,
            capture_output=True,
            check=True,
        )
        self.assertEqual(result.stderr, b"", result.stderr.decode())
        return result.stdout.decode().rstrip("\0").split("\0") if result.stdout else []

    def test_all_long_flags(self):
        flags = self.complete("--")
        expected = [
            "check-sourced",
            "color",
            "include",
            "exclude",
            "extended-analysis",
            "format",
            "list-optional",
            "norc",
            "rcfile",
            "enable",
            "source-path",
            "shell",
            "severity",
            "version",
            "wiki-link-count",
            "external-sources",
            "help",
        ]
        for flag in expected:
            with self.subTest(flag=flag):
                self.assertIn("--" + flag, flags)

    def test_all_short_flags(self):
        flags = self.complete("-")
        for letter in "aCiefoPsSVWx":
            with self.subTest(letter=letter):
                self.assertIn("-" + letter, flags)
        self.assertNotIn("-h", flags)

    def test_enum_forms(self):
        specs = [
            ("--format", "-f", "js", ["json", "json1"]),
            ("--shell", "-s", "b", ["bash", "busybox"]),
            ("--severity", "-S", "i", ["info"]),
        ]
        for long, short, prefix, matches in specs:
            with self.subTest(option=long):
                self.assertEqual(self.complete(long, prefix), matches)
                self.assertEqual(self.complete(short, prefix), matches)
                self.assertEqual(
                    self.complete(long + "=" + prefix),
                    [long + "=" + x for x in matches],
                )
                self.assertEqual(
                    self.complete(short + prefix), [short + x for x in matches]
                )
                self.assertEqual(
                    self.complete("-ax" + short[1:] + prefix),
                    ["-ax" + short[1:] + x for x in matches],
                )
                self.assertEqual(self.complete("-ax" + short[1:], prefix), matches)

    def test_boolean(self):
        self.assertEqual(self.complete("--extended-analysis", ""), ["true", "false"])
        self.assertEqual(
            self.complete("--extended-analysis=fa"), ["--extended-analysis=false"]
        )

    def test_readline_equals_wordbreak(self):
        self.assertEqual(self.complete("--format", "=", "js"), ["json", "json1"])
        self.assertEqual(
            self.complete("--format", "=", fragment=""),
            ["checkstyle", "diff", "gcc", "json", "json1", "quiet", "tty"],
        )
        self.assertEqual(self.complete("--format=js", fragment="js"), ["json", "json1"])

    def test_readline_colon_wordbreak(self):
        self.assertEqual(self.complete("-P", "SCRIPTDIR", ":", "src"), ["src/"])
        self.assertEqual(
            self.complete("--source-path", "=", "SCRIPTDIR", ":", "src"), ["src/"]
        )
        self.assertEqual(
            self.complete("--source-path=SCRIPTDIR:src", fragment="src"), ["src/"]
        )

    def test_optional_color(self):
        self.assertEqual(self.complete("--color=a"), ["--color=auto", "--color=always"])
        self.assertEqual(self.complete("-Ca"), ["-Cauto", "-Calways"])
        self.assertEqual(self.complete("-axCn"), ["-axCnever"])
        self.assertEqual(self.complete("--color", "a"), ["alpha"])
        self.assertEqual(self.complete("-C", "a"), ["alpha"])

    def test_enable(self):
        self.assertEqual(
            self.complete("--enable", ""),
            ["all", "add-default-case", "quote-safe-variables"],
        )
        self.assertEqual(
            self.complete("-o", "add-default-case,q"),
            ["add-default-case,quote-safe-variables"],
        )
        self.assertEqual(
            self.complete("--enable=add-default-case,q"),
            ["--enable=add-default-case,quote-safe-variables"],
        )
        self.assertEqual(
            self.complete("-oadd-default-case,q"),
            ["-oadd-default-case,quote-safe-variables"],
        )
        self.assertEqual(
            self.complete("-o", "add-default-case,a"), ["add-default-case,all"]
        )
        self.assertEqual(self.complete("-o", "add-default-case,add"), [])

    def test_sourcepaths(self):
        matches = self.complete("-P", "")
        self.assertIn("SCRIPTDIR", matches)
        self.assertIn("source space/", matches)
        self.assertNotIn("script", matches)
        self.assertEqual(
            self.complete("-P", "SCRIPTDIR:src/n"), ["SCRIPTDIR:src/nested/"]
        )
        self.assertEqual(
            self.complete("--source-path=SCRIPTDIR:src/n"),
            ["--source-path=SCRIPTDIR:src/nested/"],
        )
        self.assertEqual(self.complete("-Psrc/n"), ["-Psrc/nested/"])

    def test_files(self):
        self.assertIn("script", self.complete("scr"))
        self.assertIn("script with spaces", self.complete("script w"))
        self.assertEqual(self.complete("--rcfile", ".s"), [".shellcheckrc"])
        self.assertEqual(self.complete("--rcfile=.s"), ["--rcfile=.shellcheckrc"])
        self.assertIn("-", self.complete(""))
        self.assertEqual(self.complete("--", "--s"), ["--shell-file"])
        self.assertIn("script", self.complete("--", "scr"))

    def test_no_irrelevant_value_suggestions(self):
        for option in ("--include", "--exclude", "--wiki-link-count", "-i", "-e", "-W"):
            with self.subTest(option=option):
                self.assertEqual(self.complete(option, ""), [])
        self.assertEqual(self.complete("--format", "bogus"), [])
        self.assertEqual(self.complete("-s", "B"), [])
        self.assertEqual(self.complete("-S", "b"), [])

    def test_options_after_files_and_completed_values(self):
        self.assertEqual(self.complete("script", "--format", "js"), ["json", "json1"])
        self.assertEqual(
            self.complete("--format", "json", "--severity", "w"), ["warning"]
        )
        self.assertEqual(
            self.complete("--format", "=", "json", "--severity", "w"), ["warning"]
        )
        self.assertEqual(
            self.complete("--rcfile", "--", "--format", "js"), ["json", "json1"]
        )


if __name__ == "__main__":
    unittest.main(verbosity=2)
