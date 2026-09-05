# homebrew-tap

Homebrew tap for tools by [kjanat].

```sh
brew install kjanat/tap/actionlint
```

| Cask         | Source                | Maintained by                                         |
| ------------ | --------------------- | ----------------------------------------------------- |
| `actionlint` | [kjanat/actionlint]   | GoReleaser, on every release of the source repository |
| `shellcheck` | [koalaman/shellcheck] | by hand, from the static binaries ShellCheck releases |

The `shellcheck` cask installs the static binary with no dependencies, which the homebrew-core formula cannot offer, and
conflicts with that formula. Do not edit the GoReleaser-generated casks by hand.

[kjanat]: https://github.com/kjanat
[kjanat/actionlint]: https://github.com/kjanat/actionlint
[koalaman/shellcheck]: https://github.com/koalaman/shellcheck
