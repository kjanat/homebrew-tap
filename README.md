# homebrew-tap

Homebrew tap for tools by [kjanat].

```sh
brew trust kjanat/tap
brew install kjanat/tap/actionlint
# optional, for actionlint to use if available on PATH
brew install kjanat/tap/shellcheck
```

| Cask         | Source                | Maintained by                                         |
| ------------ | --------------------- | ----------------------------------------------------- |
| `actionlint` | [kjanat/actionlint]   | GoReleaser, on every release of the source repository |
| `shellcheck` | [koalaman/shellcheck] | scheduled release checks and update pull requests     |

The `actionlint` cask has no package dependencies. ShellCheck is optional: actionlint uses it when available on `PATH`.
Install `kjanat/tap/shellcheck` separately if you want the upstream static binary and shell completions.

The `shellcheck` cask installs the upstream static binary with no dependencies. Uninstall the homebrew-core formula first
if it already owns the `shellcheck` binary.

The old `kjanat/actionlint` tap redirects here through `tap_migrations.json`; actionlint releases update this tap only.

## Updating ShellCheck completions

After updating the tap, reinstall ShellCheck to pick up completion changes without a new ShellCheck version:

```sh
brew update
brew reinstall --cask kjanat/tap/shellcheck
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for cask maintenance and automation setup.

[kjanat]: https://github.com/kjanat
[kjanat/actionlint]: https://github.com/kjanat/actionlint
[koalaman/shellcheck]: https://github.com/koalaman/shellcheck
