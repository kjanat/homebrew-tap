# Contributing

## actionlint cask

GoReleaser in [kjanat/actionlint](https://github.com/kjanat/actionlint) generates `Casks/actionlint.rb` on release.
Make lasting changes in that repository's `.goreleaser.yaml`; release generation overwrites edits to the cask here.
Actionlint releases update this tap only. The old `kjanat/actionlint` tap is a compatibility redirect.

## macOS installation checks

The `Cask checks` workflow installs, reinstalls, and uninstalls all seven casks on macOS 26 runners for Apple Silicon and Intel.
It tests the checked-out commit, runs every binary, compares installed completions with their sources or generated
output, checks the actionlint and envctl manual pages, and verifies that uninstall removes the installed files. Cask and completion
changes trigger these checks; you can also run the workflow manually.

CI builds checksum-pinned GNU Bash 5.3 with its bundled Readline for the envctl completion check. This avoids building
Homebrew's dependency updates on Intel Macs. `CASK_TEST_BASH` selects that test binary; local runs default to Homebrew Bash.

## Runner, SVG, rshellcheck, envctl, and fsql updates

Hosted Renovate groups each tool's four architecture versions and checksums into one reviewable pull request.
The release check downloads and verifies all twenty release assets; macOS jobs also exercise the installed commands.
These updates do not merge automatically. The rshellcheck manager follows `rshellcheck-v` tags in `kjanat/shellcheck-rs`.

Runner generates its completions during installation. SVG and rshellcheck currently install their released binaries without
completion files. Runner's binary archives do not include its separately published manual pages.

Envctl generates its four completion scripts and PowerShell module during installation. Its releases contain raw binaries,
so `manpages/envctl/` supplies the upstream manual and license. CI compares both files with the cask's release tag and fails
if they differ. When an envctl update changes either file, copy it from that release tag before merging the Renovate pull
request. Keep the upstream files unchanged. The macOS checks render the manual, exercise Bash and PowerShell completions,
and read a test value through both the CLI and the installed PowerShell module.

Fsql releases contain raw binaries, including builds requiring glibc 2.34 or newer on Linux. The macOS checks query a temporary fixture,
verify that a mutation preview changes nothing, apply a rename with a journal, and undo it. These checks run after both
installation and reinstallation. Shell completions and a manual page are tracked in
[fsql#38](https://github.com/kjanat/fsql/issues/38). Keep user journals and undo data out of uninstall and zap directives.

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
