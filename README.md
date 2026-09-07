# homebrew-tap

Homebrew tap for tools by [kjanat].

```sh
brew install kjanat/tap/actionlint
```

| Cask         | Source                | Maintained by                                         |
| ------------ | --------------------- | ----------------------------------------------------- |
| `actionlint` | [kjanat/actionlint]   | GoReleaser, on every release of the source repository |
| `shellcheck` | [koalaman/shellcheck] | scheduled release checks and update pull requests     |

The `shellcheck` cask installs the upstream static binary with no dependencies. Uninstall the homebrew-core formula first
if it already owns the `shellcheck` binary. Do not edit the GoReleaser-generated casks by hand.

The old `kjanat/actionlint` tap redirects here through `tap_migrations.json`; actionlint releases update this tap only.

## ShellCheck refresh

`Bump shellcheck` checks upstream releases every Monday at 06:17 UTC and supports manual dispatch. It updates the version
and asset hashes, refreshes the four completion headers, validates them, and opens a PR when files change. Existing PRs are
reused; if a previous run pushed the branch but failed to open its PR, the next run retries PR creation. Branch names
include a hash of the cask and completion files, so different content does not collide with an earlier PR for the same version.

The workflow uses `GITHUB_TOKEN`. Enable **Settings → Actions → General → Allow GitHub Actions to create and approve pull
requests** before running it. This repository setting is separate from the workflow's `pull-requests: write` permission.

Completion flag definitions are maintained in `completions/shellcheck/`; changing their version headers does not add support
for new upstream options. The cask copies these files from the installed tap during installation; no embedding step is
needed. After updating the tap, run `brew reinstall --cask kjanat/tap/shellcheck` to pick up completion changes without a
new ShellCheck version.

[kjanat]: https://github.com/kjanat
[kjanat/actionlint]: https://github.com/kjanat/actionlint
[koalaman/shellcheck]: https://github.com/koalaman/shellcheck
