# kjanat/tap

Prebuilt command-line tools for GitHub Actions, shell scripts, SVG, and local automation. The casks provide builds for Apple Silicon, Intel Macs, and ARM64 or x86-64 Linux.

## Install a tool

Replace `svg` with the cask you want from the catalog below.

```sh
brew tap kjanat/tap
brew trust --cask kjanat/tap/svg
brew install --cask kjanat/tap/svg
```

### Linting

| Cask          | What it installs                                       |
| ------------- | ------------------------------------------------------ |
| [actionlint]  | GitHub Actions workflow linter                         |
| [shellcheck]  | Upstream shell script linter and shell completions     |
| [rshellcheck] | Rust ShellCheck port, installed alongside `shellcheck` |

### Automation

| Cask     | What it installs                                        |
| -------- | ------------------------------------------------------- |
| [runner] | Task runner with `runner`, `run`, and shell completions |
| [envctl] | Environment file CLI, manual, and shell integrations    |

### File tooling

| Cask   | What it installs                                    |
| ------ | --------------------------------------------------- |
| [svg]  | `svg-language-server`, `svg-format`, and `svg-lint` |
| [fsql] | SQL CLI for querying and changing files             |

## Setup and upgrades

- **Shell setup.** Run `brew info --cask kjanat/tap/envctl` for Bash and PowerShell setup. Its Bash completions require Bash 4 or newer.
- **ShellCheck with actionlint.** Actionlint uses ShellCheck when it finds it on `PATH`. If the core `shellcheck` formula is installed, uninstall it before installing the tap’s cask to avoid a binary conflict.
- **Completion-only updates.** After `brew update`, run `brew reinstall --cask kjanat/tap/shellcheck` to pick up completion changes at the same ShellCheck version.
- **fsql on Linux.** The release binaries require glibc 2.34 or newer.

## Help and contributions

Use the project links in the catalog for help with a tool. Report installation or packaging issues in the [tap’s issue tracker]. To change a cask or its automation, see [Contributing](CONTRIBUTING.md).

[actionlint]: https://github.com/kjanat/actionlint
[shellcheck]: https://github.com/koalaman/shellcheck
[runner]: https://github.com/kjanat/runner
[svg]: https://github.com/kjanat/svg
[rshellcheck]: https://github.com/kjanat/shellcheck-rs
[envctl]: https://github.com/kjanat/envctl
[fsql]: https://github.com/kjanat/fsql
[tap’s issue tracker]: https://github.com/kjanat/homebrew-tap/issues
