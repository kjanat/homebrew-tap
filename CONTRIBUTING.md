# Contributing

## actionlint cask

GoReleaser in [kjanat/actionlint](https://github.com/kjanat/actionlint) generates `Casks/actionlint.rb` on release.
Make lasting changes in that repository's `.goreleaser.yaml`; release generation overwrites edits to the cask here.
Actionlint releases update this tap only. The old `kjanat/actionlint` tap is a compatibility redirect.

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
