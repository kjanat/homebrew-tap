# Contributing to kjanat/tap

The tap packages prebuilt tools. Report bugs in a tool to its upstream project, linked in the [README catalog](README.md#install-a-tool).

## Make a change

- Edit [`Casks/`](Casks/) for tap-owned packaging. For generated casks, change the upstream release configuration.
- Update the version and SHA-256 together for each platform. Keep platform versions in sync, and update any vendored files tied to the release.
- See [`renovate.json`](renovate.json) for dependency automation or [release publication](docs/beepboop.md) for the publication workflow.

## Check your change

From the repository root, set `cask` to the name of the cask you changed.

```sh
cask=NAME
ruby -c "Casks/$cask.rb"
brew style "Casks/$cask.rb"
```

The [Cask checks workflow](.github/workflows/casks.yml) lints the tap before scheduling release integrity and install checks for affected casks. Install checks run on macOS and also on Linux for rshellcheck. A manual run exercises the full tap.

When a cask renames or drops an installed path, test an upgrade from the previous release and check that Homebrew removes the old path. CI exercises install, reinstall, and uninstall at the proposed version.

## Open a pull request

Describe what changed and why. For a version bump, link the upstream release and say how you verified the hashes. Include the checks you ran.
