# homebrew-tap

Homebrew tap for tools by [kjanat].

```sh
brew trust kjanat/tap
brew install kjanat/tap/actionlint
# optional, for actionlint to use if available on PATH
brew install kjanat/tap/shellcheck
brew install --cask kjanat/tap/runner kjanat/tap/svg kjanat/tap/rshellcheck
brew install --cask kjanat/tap/envctl
brew install --cask kjanat/tap/fsql
```

| Cask          | Source                 | Maintained by                                         |
| ------------- | ---------------------- | ----------------------------------------------------- |
| `actionlint`  | [kjanat/actionlint]    | GoReleaser, on every release of the source repository |
| `shellcheck`  | [koalaman/shellcheck]  | Renovate pull requests for versions and checksums     |
| `runner`      | [kjanat/runner]        | Renovate pull requests for versions and checksums     |
| `svg`         | [kjanat/svg]           | Renovate pull requests for versions and checksums     |
| `rshellcheck` | [kjanat/shellcheck-rs] | Renovate pull requests for versions and checksums     |
| `envctl`      | [kjanat/envctl]        | Renovate pull requests for versions and checksums     |
| `fsql`        | [kjanat/fsql]          | Renovate pull requests for versions and checksums     |

The `actionlint` cask has no package dependencies. ShellCheck is optional: actionlint uses it when available on `PATH`.
Install `kjanat/tap/shellcheck` separately if you want the upstream static binary and shell completions.

The `shellcheck` cask installs the upstream static binary with no dependencies. Uninstall the homebrew-core formula first
if it already owns the `shellcheck` binary.

The `runner` cask installs `runner`, `run`, and generated Bash, Zsh, Fish, and PowerShell completions.
The `svg` cask installs `svg-language-server`, `svg-format`, and `svg-lint`.
The `rshellcheck` cask installs the Rust port as `rshellcheck`, so it can coexist with upstream `shellcheck`.
The `envctl` cask installs `envctl`, its manual page, generated Bash, Zsh, Fish, and PowerShell completions, and its PowerShell
module. Its Bash completions require Bash 4 or newer; macOS includes Bash 3.2. Run `brew info --cask kjanat/tap/envctl`
for Bash setup and PowerShell loading commands.
The `fsql` cask installs the SQL filesystem CLI. Its release has no shell completions or manual page;
[fsql#38](https://github.com/kjanat/fsql/issues/38) tracks adding them. Uninstalling the cask preserves journals and undo data.
All five use prebuilt releases for Apple Silicon, Intel Macs, and ARM64 or x86-64 Linux.
The fsql Linux binaries require glibc 2.34 or newer.

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
[kjanat/runner]: https://github.com/kjanat/runner
[kjanat/svg]: https://github.com/kjanat/svg
[kjanat/shellcheck-rs]: https://github.com/kjanat/shellcheck-rs
[kjanat/envctl]: https://github.com/kjanat/envctl
[kjanat/fsql]: https://github.com/kjanat/fsql
