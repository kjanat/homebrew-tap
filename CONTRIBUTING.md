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

The [Cask checks workflow](.github/workflows/casks.yml) selects affected casks and runs release integrity and macOS install checks. It is also available as a manual run for the full tap.

## Open a pull request

Describe what changed and why. For a version bump, link the upstream release and say how you verified the hashes. Include the checks you ran.
