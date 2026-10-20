# Release publication

`release.yml` accepts release notifications from
[Beepboop](https://github.com/kjanat/beepboop) on `master`.
The receiver uses this repository's `GITHUB_TOKEN`; source projects need no tap
credential.

Inputs identify the source repository ID, release ID, exact source commit and
router operation. They cannot select a destination file, asset URL or executable.
The pinned publication action checks the allowed source/destination mapping,
signed release tag, manifest attestation and prepared asset digest before
validating and publishing the Homebrew cask.

Repeated operations must be harmless. Identity changes, modified release bytes and
version downgrades fail. `dry_run: true` performs validation without publication.
The operation's workflow name is `Beepboop <operation_id>` for retry reconciliation.

Validation runs in the receiver. Its local-token commit does not rely on a second
push-triggered CI workflow. Source publication and receiver publication remain
separate outcomes; a successful dispatch alone is not a published tap update.
