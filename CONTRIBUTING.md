# Contributing

## actionlint cask

GoReleaser in [kjanat/actionlint](https://github.com/kjanat/actionlint) generates `Casks/actionlint.rb` on release.
Make lasting changes in that repository's `.goreleaser.yaml`; release generation overwrites edits to the cask here.
Actionlint releases update this tap only. The old `kjanat/actionlint` tap is a compatibility redirect.

## macOS installation checks

The `Cask checks` workflow installs, reinstalls, and uninstalls all five casks on macOS 26 runners for Apple Silicon and Intel.
It tests the checked-out commit, runs every binary, compares installed completions with their sources or generated
output, checks the actionlint manual page, and verifies that uninstall removes the installed files. Cask and completion
changes trigger these checks; you can also run the workflow manually.

## Runner, SVG, and rshellcheck updates

Hosted Renovate groups each tool's four architecture versions and checksums into one reviewable pull request.
The release check downloads and verifies all twelve archives; macOS jobs also exercise the installed commands.
These updates do not merge automatically. The rshellcheck manager follows `rshellcheck-v` tags in `kjanat/shellcheck-rs`.

Runner generates its completions during installation. SVG and rshellcheck currently install their released binaries without
completion files. Runner's binary archives do not include its separately published manual pages.

## ShellCheck refresh

The hosted Renovate App opens one pull request for each ShellCheck update. Its custom managers update the four architecture
versions and SHA-256 checksums together with the four completion headers. Each architecture keeps its version beside its
checksum so Renovate can replace both in one operation. Keep all four versions equal.

The `ShellCheck release integrity` check downloads all four release archives, verifies their checksums, and checks that the
completion headers match the cask version. Review this check before merging; these updates do not merge automatically.
Renovate leaves the actionlint cask to its existing release publisher.

Completion flag definitions are maintained in `completions/shellcheck/`; changing their version headers does not add support
for new upstream options. The cask reads the files from the tap into declarative preflight steps, which write them into the
staging directory during installation. See the [completion documentation](completions/shellcheck/README.md) for implementation
details and tests.
