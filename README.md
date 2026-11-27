# kjanat/tap

Prebuilt command-line tools for GitHub Actions, shell scripts, SVG, and local automation. The casks provide builds for Apple Silicon, Intel Macs, and ARM64 or x86-64 Linux.

## Install a tool

Replace `svg` with the cask you want from the catalog below.

```sh
brew tap kjanat/tap
brew trust --cask kjanat/tap/svg
brew install --cask kjanat/tap/svg
```

| Cask          | Use it to                                               | Binaries                                        | Completions |
| ------------- | ------------------------------------------------------- | ----------------------------------------------- | :---------: |
| [actionlint]  | Check GitHub Actions workflows for errors               | `actionlint`                                    |     ✅      |
| [shellcheck]  | Find bugs and portability issues in shell scripts       | `shellcheck`                                    |     ✅      |
| [rshellcheck] | Lint shell scripts with a Rust port of ShellCheck       | `rshellcheck`                                   |     ❌      |
| [runner]      | Define and run project tasks                            | `runner`, `run`                                 |     ✅      |
| [envctl]      | Read and edit variables in environment files            | `envctl`                                        |     ✅      |
| [svg]         | Get editor support for SVG and format or lint SVG files | `svg-language-server`, `svg-format`, `svg-lint` |     ❌      |
| [fsql]        | Find and modify files with SQL                          | `fsql`                                          |     ❌      |

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
