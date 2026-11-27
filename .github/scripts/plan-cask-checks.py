import json
import os
from pathlib import Path
import subprocess


RUNNERS = ("macos-26", "macos-26-intel")
RELEASE_CHECKS = {"envctl", "fsql", "rshellcheck", "runner", "svg"}
SHARED_FILES = {
    ".github/scripts/check-cask-install.sh",
    ".github/scripts/plan-cask-checks.py",
    ".github/workflows/casks.yml",
}


def changed_paths(event_name, event):
    if event_name == "pull_request":
        pr = event["pull_request"]
        revision_range = pr["base"]["sha"] + "..." + pr["head"]["sha"]
    elif event_name == "push" and event["before"].strip("0"):
        revision_range = event["before"] + ".." + event["after"]
    else:
        return None

    result = subprocess.run(
        ["git", "diff", "--name-only", "--no-renames", "-z", revision_range],
        stdout=subprocess.PIPE,
        check=False,
    )
    if result.returncode:
        print("Could not compare revisions. Checking all casks.")
        return None
    return set(os.fsdecode(result.stdout).split("\0"))


def make_plan(casks, paths):
    if paths is None or paths & SHARED_FILES:
        selected = casks
        integrity = casks & (RELEASE_CHECKS | {"shellcheck"})
    else:
        selected = {cask for cask in casks if f"Casks/{cask}.rb" in paths}
        for cask, prefix in (
            ("shellcheck", "completions/shellcheck/"),
            ("envctl", "manpages/envctl/"),
        ):
            if cask in casks and any(path.startswith(prefix) for path in paths):
                selected.add(cask)
        integrity = selected & (RELEASE_CHECKS | {"shellcheck"})
        if ".github/scripts/check-shellcheck.ts" in paths:
            integrity |= casks & {"shellcheck"}
        if ".github/scripts/check-release-casks.ts" in paths:
            integrity |= casks & RELEASE_CHECKS

    return {
        "install": {
            "include": [
                {"cask": cask, "runner": runner}
                for cask in sorted(selected)
                for runner in RUNNERS
            ]
        },
        "integrity": {"include": [{"cask": cask} for cask in sorted(integrity)]},
    }


if __name__ == "__main__":
    event = json.loads(Path(os.environ["GITHUB_EVENT_PATH"]).read_text())
    paths = changed_paths(os.environ["GITHUB_EVENT_NAME"], event)
    plan = make_plan({path.stem for path in Path("Casks").glob("*.rb")}, paths)
    with Path(os.environ["GITHUB_OUTPUT"]).open("a") as output:
        for name, matrix in plan.items():
            print(f"{name}={json.dumps(matrix, separators=(',', ':'))}", file=output)
    print(json.dumps(plan, indent=2))
