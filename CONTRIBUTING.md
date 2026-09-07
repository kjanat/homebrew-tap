# Contributing

## actionlint cask

GoReleaser in [kjanat/actionlint](https://github.com/kjanat/actionlint) generates `Casks/actionlint.rb` on release.
Make lasting changes in that repository's `.goreleaser.yaml`; release generation overwrites edits to the cask here.
Actionlint releases update this tap only. The old `kjanat/actionlint` tap is a compatibility redirect.

## ShellCheck refresh

`Bump shellcheck` checks upstream releases every Monday at 06:17 UTC and supports manual dispatch. It updates the version
and asset hashes, refreshes the four completion headers, validates them, and opens a PR when files change. Existing PRs are
reused; if a previous run pushed the branch but failed to open its PR, the next run retries PR creation. Branch names
include a hash of the cask and completion files, so different content does not collide with an earlier PR for the same version.

The workflow uses `GITHUB_TOKEN`. Enable **Settings → Actions → General → Allow GitHub Actions to create and approve pull
requests** before running it. This repository setting is separate from the workflow's `pull-requests: write` permission.

Completion flag definitions are maintained in `completions/shellcheck/`; changing their version headers does not add support
for new upstream options. The cask copies these files from the installed tap during installation; no embedding step is
needed. See the [completion documentation](completions/shellcheck/README.md) for implementation details and tests.
