# Contributing to kjanat/tap

Start in [`Casks/`](Casks/) for install behavior. For a bug in one of the binaries, use its upstream project from the [README](README.md#install-a-tool).

## Source files

| Change                               | Where to make it                                                                    |
| ------------------------------------ | ----------------------------------------------------------------------------------- |
| actionlint cask or release packaging | [Upstream GoReleaser config][actionlint-release]                                    |
| Other cask install behavior          | [`Casks/<name>.rb`](Casks/)                                                         |
| Automated version and hash updates   | [`renovate.json`](renovate.json)                                                    |
| ShellCheck completion behavior       | [`completions/shellcheck/`](completions/shellcheck/README.md)                       |
| envctl manual and license            | [`manpages/envctl/`](manpages/envctl/)                                              |
| Cask validation and CI selection     | [Cask checks workflow](.github/workflows/casks.yml) and [scripts](.github/scripts/) |

GoReleaser regenerates the actionlint cask on release. Make lasting changes upstream. For the separate release publication flow, see [Beepboop publication](docs/beepboop.md).

## Update a cask

1. Find the upstream release and its assets. Update the version and SHA-256 for each platform together. Keep the four platform versions equal in casks that declare a version per platform.
2. Preserve the existing archive paths and installed command names unless the upstream release changed them. For rshellcheck, the tag has an `rshellcheck-v` prefix, and Renovate matches digests by archive name and target.
3. If you update **envctl**, copy the manual and license verbatim from the same release tag. If you update **ShellCheck**, keep all four completion headers aligned with the cask version and check upstream flag changes against the completion definitions.

Renovate groups platform updates into one PR per cask. SVG is configured for auto-merge after checks pass. Other Renovate cask updates need a manual merge.

## Validate locally

From the root of the checkout, replace `rshellcheck` with the cask under test. Run the tap registration and install checks in a disposable macOS environment because the smoke test installs, reinstalls, uninstalls, and may unlink a conflicting core formula. Commit the changes you want Homebrew to test before registering the checkout as a local tap.

```sh
ruby -c Casks/rshellcheck.rb
brew style Casks/rshellcheck.rb

brew tap --custom-remote kjanat/tap "$PWD"
brew trust --cask kjanat/tap/rshellcheck
brew audit --cask kjanat/tap/rshellcheck
RUNNER_TEMP="$(mktemp -d)" HOMEBREW_NO_AUTO_UPDATE=1 \
  bash .github/scripts/check-cask-install.sh rshellcheck
```

For an envctl smoke test, point `CASK_TEST_BASH` to Bash 4 or newer and have `pwsh` on `PATH`. The script defaults to Bash under the Homebrew prefix. For checksum and vendored manual checks, use the matching Deno command from the [Cask checks workflow](.github/workflows/casks.yml).

## Open a pull request

Name the cask and upstream release in the PR. Call out any changes to installed binaries, completions, or uninstall behavior and list the checks you ran. Keep fsql journals and undo data outside uninstall and zap directives.

CI discovers casks in `Casks/` and runs each affected cask in its own Apple Silicon and Intel macOS jobs. It also runs applicable release integrity checks. Changes to shared install logic and manual runs exercise the full tap. Only the envctl jobs need the checksum-keyed native Bash cache.

[actionlint-release]: https://github.com/kjanat/actionlint/blob/HEAD/.goreleaser.yaml
