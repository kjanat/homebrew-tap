#!/usr/bin/env python3
import re
import sys
from pathlib import Path
from textwrap import indent

ROOT = Path(__file__).resolve().parents[1]
FILES = [
    ("bash/{name}", "{name}.bash", "SC_BASH"),
    ("fish/{name}.fish", "{name}.fish", "SC_FISH"),
    ("zsh/_{name}", "_{name}", "SC_ZSH"),
    ("powershell/{name}.ps1", "{name}.ps1", "SC_POWERSHELL"),
]


def stanzas(name: str) -> str:
    parts = []
    for source, staged, delimiter in FILES:
        text = (ROOT / "completions" / name / source.format(name=name)).read_text(
            encoding="utf-8"
        )
        if delimiter in text.splitlines():
            raise ValueError(
                f"heredoc delimiter {delimiter} collides with a line in {source}"
            )
        parts.append(
            f"  generated_script \"{staged.format(name=name)}\", content: <<~'{delimiter}'\n"
        )
        parts.append(indent(text, "    ", lambda line: line.strip() != ""))
        parts.append(f"  {delimiter}\n\n")
    return "".join(parts).rstrip("\n") + "\n"


def main(name: str) -> None:
    cask = ROOT / "Casks" / f"{name}.rb"
    text = cask.read_text(encoding="utf-8")
    pattern = re.compile(
        r"^  generated_script .*?^  SC_POWERSHELL\n", re.MULTILINE | re.DOTALL
    )
    updated, count = pattern.subn(lambda _: stanzas(name), text, count=1)
    if count != 1:
        raise SystemExit(f"{cask}: no generated_script block to replace")
    cask.write_text(updated, encoding="utf-8")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: embed_completions.py <cask>")
    main(sys.argv[1])
