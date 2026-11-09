#!/usr/bin/env bash
set -euo pipefail

prefix=$(brew --prefix)

check_install() {
	local cask=$1
	local version
	version=$(brew info --cask --json=v2 "kjanat/tap/$cask" | ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("casks").first.fetch("version")')
	for binary in "${binaries[@]}"; do
		"$prefix/bin/$binary" --version | tee "$RUNNER_TEMP/$binary-version.txt"
		grep -F "$version" "$RUNNER_TEMP/$binary-version.txt"
	done
	for path in "${artifacts[@]}"; do
		test -s "$prefix/$path"
	done

	if [[ $cask == shellcheck ]]; then
		cmp completions/shellcheck/bash/shellcheck "$prefix/etc/bash_completion.d/shellcheck"
		cmp completions/shellcheck/zsh/_shellcheck "$prefix/share/zsh/site-functions/_shellcheck"
		cmp completions/shellcheck/fish/shellcheck.fish "$prefix/share/fish/vendor_completions.d/shellcheck.fish"
		cmp completions/shellcheck/powershell/shellcheck.ps1 "$prefix/share/powershell/completions/shellcheck.ps1"
		printf '#!/bin/sh\necho "$HOME"\n' | "$prefix/bin/shellcheck" -
	elif [[ $cask == actionlint ]]; then
		for shell in bash zsh fish pwsh; do
			"$prefix/bin/actionlint" -completion "$shell" >"$RUNNER_TEMP/actionlint-$shell"
		done
		cmp "$RUNNER_TEMP/actionlint-bash" "$prefix/etc/bash_completion.d/actionlint"
		cmp "$RUNNER_TEMP/actionlint-zsh" "$prefix/share/zsh/site-functions/_actionlint"
		cmp "$RUNNER_TEMP/actionlint-fish" "$prefix/share/fish/vendor_completions.d/actionlint.fish"
		cmp "$RUNNER_TEMP/actionlint-pwsh" "$prefix/share/pwsh/completions/_actionlint.ps1"
		printf 'name: Smoke\non: push\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps:\n      - run: echo ok\n' \
			| "$prefix/bin/actionlint" -shellcheck= -pyflakes= -
	elif [[ $cask == runner ]]; then
		for shell in bash zsh fish pwsh; do
			"$prefix/bin/runner" completions "$shell" >"$RUNNER_TEMP/runner-$shell"
		done
		cmp "$RUNNER_TEMP/runner-bash" "$prefix/etc/bash_completion.d/runner"
		cmp "$RUNNER_TEMP/runner-zsh" "$prefix/share/zsh/site-functions/_runner"
		cmp "$RUNNER_TEMP/runner-fish" "$prefix/share/fish/vendor_completions.d/runner.fish"
		cmp "$RUNNER_TEMP/runner-pwsh" "$prefix/share/pwsh/completions/_runner.ps1"
		bash -c 'source "$1"; complete -p runner run' bash "$prefix/etc/bash_completion.d/runner"
		"$prefix/bin/runner" --help >/dev/null
	elif [[ $cask == svg ]]; then
		printf '<svg xmlns="http://www.w3.org/2000/svg"><path d="M0 0L1 1"/></svg>\n' \
			| "$prefix/bin/svg-format" >"$RUNNER_TEMP/smoke.svg"
		test -s "$RUNNER_TEMP/smoke.svg"
		"$prefix/bin/svg-format" --check "$RUNNER_TEMP/smoke.svg"
		"$prefix/bin/svg-lint" "$RUNNER_TEMP/smoke.svg"
	elif [[ $cask == rshellcheck ]]; then
		printf '#!/bin/sh\necho "$HOME"\n' | "$prefix/bin/rshellcheck" --norc -
	fi
}

for cask in actionlint shellcheck runner svg rshellcheck; do
	# Hosted runners may already have the core formula linked into the same prefix.
	if brew list --formula "$cask" >/dev/null 2>&1; then
		brew unlink "$cask"
	fi
	binaries=("$cask")
	if [[ $cask == runner ]]; then
		binaries+=(run)
	elif [[ $cask == svg ]]; then
		binaries=(svg-language-server svg-format svg-lint)
	fi
	artifacts=()
	for binary in "${binaries[@]}"; do
		artifacts+=("bin/$binary")
	done
	if [[ $cask == actionlint || $cask == shellcheck || $cask == runner ]]; then
		artifacts+=(
			"etc/bash_completion.d/$cask"
			"share/zsh/site-functions/_$cask"
			"share/fish/vendor_completions.d/$cask.fish"
		)
	fi
	if [[ $cask == actionlint ]]; then
		artifacts+=("share/man/man1/actionlint.1" "share/pwsh/completions/_actionlint.ps1")
	elif [[ $cask == shellcheck ]]; then
		artifacts+=("share/powershell/completions/shellcheck.ps1")
	elif [[ $cask == runner ]]; then
		artifacts+=("share/pwsh/completions/_runner.ps1")
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
