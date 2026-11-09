#!/usr/bin/env bash
set -euo pipefail

prefix=$(brew --prefix)

check_install() {
	local cask=$1
	local version
	version=$(brew info --cask --json=v2 "kjanat/tap/$cask" | ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("casks").first.fetch("version")')
	"$prefix/bin/$cask" --version | tee "$RUNNER_TEMP/$cask-version.txt"
	grep -F "$version" "$RUNNER_TEMP/$cask-version.txt"
	for path in "${artifacts[@]}"; do
		test -s "$prefix/$path"
	done

	if [[ $cask == shellcheck ]]; then
		cmp completions/shellcheck/bash/shellcheck "$prefix/etc/bash_completion.d/shellcheck"
		cmp completions/shellcheck/zsh/_shellcheck "$prefix/share/zsh/site-functions/_shellcheck"
		cmp completions/shellcheck/fish/shellcheck.fish "$prefix/share/fish/vendor_completions.d/shellcheck.fish"
		cmp completions/shellcheck/powershell/shellcheck.ps1 "$prefix/share/powershell/completions/shellcheck.ps1"
		printf '#!/bin/sh\necho "$HOME"\n' | "$prefix/bin/shellcheck" -
	else
		for shell in bash zsh fish pwsh; do
			"$prefix/bin/actionlint" -completion "$shell" >"$RUNNER_TEMP/actionlint-$shell"
		done
		cmp "$RUNNER_TEMP/actionlint-bash" "$prefix/etc/bash_completion.d/actionlint"
		cmp "$RUNNER_TEMP/actionlint-zsh" "$prefix/share/zsh/site-functions/_actionlint"
		cmp "$RUNNER_TEMP/actionlint-fish" "$prefix/share/fish/vendor_completions.d/actionlint.fish"
		cmp "$RUNNER_TEMP/actionlint-pwsh" "$prefix/share/pwsh/completions/_actionlint.ps1"
		printf 'name: Smoke\non: push\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps:\n      - run: echo ok\n' \
			| "$prefix/bin/actionlint" -shellcheck= -pyflakes= -
	fi
}

for cask in actionlint shellcheck; do
	# Hosted runners may already have the core formula linked into the same prefix.
	if brew list --formula "$cask" >/dev/null 2>&1; then
		brew unlink "$cask"
	fi
	artifacts=(
		"bin/$cask"
		"etc/bash_completion.d/$cask"
		"share/zsh/site-functions/_$cask"
		"share/fish/vendor_completions.d/$cask.fish"
	)
	if [[ $cask == actionlint ]]; then
		artifacts+=("share/man/man1/actionlint.1" "share/pwsh/completions/_actionlint.ps1")
	else
		artifacts+=("share/powershell/completions/shellcheck.ps1")
	fi

	brew install --cask "kjanat/tap/$cask"
	check_install "$cask"
	brew reinstall --cask "kjanat/tap/$cask"
	check_install "$cask"
	brew uninstall --cask "kjanat/tap/$cask"
	for path in "${artifacts[@]}"; do
		test ! -e "$prefix/$path"
		test ! -L "$prefix/$path"
	done
done
