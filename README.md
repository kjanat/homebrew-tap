# homebrew-tap

Homebrew tap for tools by [kjanat](https://github.com/kjanat).

```sh
brew install kjanat/tap/actionlint
```

| Cask | Source | Maintained by |
| --- | --- | --- |
| `actionlint` | [kjanat/actionlint](https://github.com/kjanat/actionlint) | GoReleaser, on every release of the source repository |
| `shellcheck` | [koalaman/shellcheck](https://github.com/koalaman/shellcheck) | by hand, from the static binaries ShellCheck releases |

The `shellcheck` cask installs the static binary with no dependencies, which the homebrew-core formula cannot offer, and
conflicts with that formula. Do not edit the GoReleaser-generated casks by hand.
