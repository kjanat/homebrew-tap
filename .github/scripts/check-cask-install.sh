#!/usr/bin/env bash
set -euo pipefail

: "${RUNNER_TEMP:?Set RUNNER_TEMP to the smoke-test scratch directory}"
prefix=$(brew --prefix)
completion_bash=${CASK_TEST_BASH:-${prefix}/bin/bash}

cask_version() {
	brew info --cask --json=v2 "kjanat/tap/$1" | ruby -rjson -e 'puts JSON.parse(STDIN.read).fetch("casks").first.fetch("version")'
}

completion_path() {
	local command=$1 shell=$2
	case ${shell} in
		bash) printf 'etc/bash_completion.d/%s\n' "${command}" ;;
		zsh) printf 'share/zsh/site-functions/_%s\n' "${command}" ;;
		fish) printf 'share/fish/vendor_completions.d/%s.fish\n' "${command}" ;;
		pwsh | powershell) printf 'share/pwsh/completions/_%s.ps1\n' "${command}" ;;
		*) return 1 ;;
	esac
}

check_generated_completions() {
	local command=$1 generator=$2
	shift 2
	local executable shell path
	# Some generators embed the executable path in the generated script.
	executable=$(ruby -e 'puts File.realpath(ARGV.fetch(0))' "${prefix}/bin/${command}")
	for shell in "$@"; do
		path=$(completion_path "${command}" "${shell}")
		"${executable}" "${generator}" "${shell}" | cmp - "${prefix}/${path}"
	done
}

check_install() {
	local cask=$1 version=$2 generator=$3
	shift 3
	for binary in "${binaries[@]}"; do
		"${prefix}/bin/${binary}" --version | tee "${RUNNER_TEMP}/${binary}-version.txt"
		grep -F "${version}" "${RUNNER_TEMP}/${binary}-version.txt"
	done
	for path in "${artifacts[@]}"; do
		test -s "${prefix}/${path}"
	done

	if [[ -n ${generator} ]]; then
		check_generated_completions "${cask}" "${generator}" "$@"
	fi

	if [[ ${cask} == shellcheck ]]; then
		cmp completions/shellcheck/bash/shellcheck "${prefix}/etc/bash_completion.d/shellcheck"
		cmp completions/shellcheck/zsh/_shellcheck "${prefix}/share/zsh/site-functions/_shellcheck"
		cmp completions/shellcheck/fish/shellcheck.fish "${prefix}/share/fish/vendor_completions.d/shellcheck.fish"
		cmp completions/shellcheck/powershell/shellcheck.ps1 "${prefix}/share/powershell/completions/shellcheck.ps1"
		"${prefix}/bin/shellcheck" - <<-'SH'
			#!/bin/sh
			echo "${HOME}"
		SH
	elif [[ ${cask} == actionlint ]]; then
		printf 'name: Smoke\non: push\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps:\n      - run: echo ok\n' \
			| "${prefix}/bin/actionlint" -shellcheck= -pyflakes= -
	elif [[ ${cask} == runner ]]; then
		bash -es -- "${prefix}/etc/bash_completion.d/runner" <<-'BASH'
			source "$1"
			complete -p runner run
			COMP_WORDS=(runner --)
			COMP_CWORD=1
			COMP_TYPE=9
			_clap_complete_runner runner --
			[[ " ${COMPREPLY[*]} " == *" --help "* ]]
		BASH
		"${prefix}/bin/runner" --help >/dev/null
	elif [[ ${cask} == svg ]]; then
		printf '<svg xmlns="http://www.w3.org/2000/svg"><path d="M0 0L1 1"/></svg>\n' \
			| "${prefix}/bin/svg-format" >"${RUNNER_TEMP}/smoke.svg"
		test -s "${RUNNER_TEMP}/smoke.svg"
		"${prefix}/bin/svg-format" --check "${RUNNER_TEMP}/smoke.svg"
		"${prefix}/bin/svg-lint" "${RUNNER_TEMP}/smoke.svg"
	elif [[ ${cask} == rshellcheck ]]; then
		bash -s -- "${prefix}/etc/bash_completion.d/rshellcheck" <<-'BASH'
			source "$1" || exit 1
			registration=$(complete -p rshellcheck) || exit 1
			[[ ${registration} =~ " -F "([^[:space:]]+) ]] || exit 1
			completer=${BASH_REMATCH[1]}
			COMP_WORDS=(rshellcheck --sev)
			COMP_CWORD=1
			"${completer}" rshellcheck --sev rshellcheck
			[[ " ${COMPREPLY[*]} " == *" --severity "* ]]
		BASH
		cat >"${RUNNER_TEMP}/test-rshellcheck.ps1" <<-'POWERSHELL'
			param($CompletionFile)
			$ErrorActionPreference = "Stop"
			. $CompletionFile
			$line = "rshellcheck --sev"
			$result = [System.Management.Automation.CommandCompletion]::CompleteInput($line, $line.Length, $null)
			if ($result.CompletionMatches.CompletionText -notcontains "--severity") { throw "Missing --severity completion" }
		POWERSHELL
		pwsh -NoProfile -NonInteractive -File "${RUNNER_TEMP}/test-rshellcheck.ps1" "${prefix}/share/pwsh/completions/_rshellcheck.ps1"
		if command -v zsh >/dev/null; then
			zsh -n "${prefix}/share/zsh/site-functions/_rshellcheck"
		fi
		if command -v fish >/dev/null; then
			fish -n "${prefix}/share/fish/vendor_completions.d/rshellcheck.fish"
		fi
		"${prefix}/bin/rshellcheck" --norc - <<-'SH'
			#!/bin/sh
			echo "${HOME}"
		SH
	elif [[ ${cask} == fsql ]]; then
		local fixture journal_id
		fixture=$(mktemp -d "${RUNNER_TEMP}/fsql.XXXXXX")
		mkdir "${fixture}/files" "${fixture}/journals"
		printf 'sample\n' >"${fixture}/files/probe.txt"
		"${prefix}/bin/fsql" -C "${fixture}/files" -f json \
			-e "SELECT name, size FROM files WHERE kind = 'file'" >"${fixture}/result.json"
		ruby -rjson -e 'abort "Unexpected query result" unless JSON.parse(File.read(ARGV.fetch(0))) == {"name" => "probe.txt", "size" => 7}' "${fixture}/result.json"
		"${prefix}/bin/fsql" -C "${fixture}/files" \
			-e "UPDATE files SET name = 'moved.txt' WHERE name = 'probe.txt'" >"${fixture}/preview.txt"
		test -f "${fixture}/files/probe.txt"
		test ! -e "${fixture}/files/moved.txt"
		"${prefix}/bin/fsql" -C "${fixture}/files" --journal-dir "${fixture}/journals" --apply \
			-e "UPDATE files SET name = 'moved.txt' WHERE name = 'probe.txt'"
		test -f "${fixture}/files/moved.txt"
		test ! -e "${fixture}/files/probe.txt"
		journal_id=$("${prefix}/bin/fsql" --journal-dir "${fixture}/journals" journal | awk 'NR == 1 {print $1}')
		test -n "${journal_id}"
		"${prefix}/bin/fsql" --journal-dir "${fixture}/journals" undo "${journal_id}"
		printf 'sample\n' | cmp - "${fixture}/files/probe.txt"
		test ! -e "${fixture}/files/moved.txt"
	elif [[ ${cask} == envctl ]]; then
		cmp manpages/envctl/envctl.1 "${prefix}/share/man/man1/envctl.1"
		MANPATH="${prefix}/share/man" MANPAGER=cat man envctl >"${RUNNER_TEMP}/envctl-man.txt"
		grep -F 'ENVCTL' "${RUNNER_TEMP}/envctl-man.txt"
		"${prefix}/bin/envctl" module pwsh >"${RUNNER_TEMP}/envctl.psm1"
		cmp "${RUNNER_TEMP}/envctl.psm1" "${prefix}/share/powershell/Modules/envctl/envctl.psm1"
		printf 'GREETING=before\n' >"${RUNNER_TEMP}/envctl.env"
		"${prefix}/bin/envctl" set "${RUNNER_TEMP}/envctl.env" GREETING hello --raw
		local greeting
		greeting=$("${prefix}/bin/envctl" get "${RUNNER_TEMP}/envctl.env" GREETING --raw)
		test "${greeting}" = hello
		"${completion_bash}" -es -- "${prefix}/etc/bash_completion.d/envctl" <<-'BASH'
			source "$1"
			complete -p envctl
			COMP_WORDS=(envctl completions b)
			COMP_CWORD=2
			_envctl
			[[ " ${COMPREPLY[*]} " == *" bash "* ]]
		BASH
		cat >"${RUNNER_TEMP}/test-envctl.ps1" <<-'POWERSHELL'
			$ErrorActionPreference = "Stop"
			$prefix = brew --prefix
			. "$prefix/share/pwsh/completions/_envctl.ps1"
			$result = [System.Management.Automation.CommandCompletion]::CompleteInput("envctl completions b", 20, $null)
			if ($result.CompletionMatches.CompletionText -notcontains "bash") { throw "Missing Bash completion" }
			Import-Module "$prefix/share/powershell/Modules/envctl/envctl.psm1"
			$value = Get-EnvctlValue -File "$env:RUNNER_TEMP/envctl.env" -Key GREETING -Raw
			if ($value -ne "hello") { throw "Unexpected module result: $value" }
		POWERSHELL
		pwsh -NoProfile -NonInteractive -File "${RUNNER_TEMP}/test-envctl.ps1"
	fi
}

if (($# == 0)); then
	shopt -s nullglob
	for cask_file in Casks/*.rb; do
		cask_name=${cask_file##*/}
		set -- "$@" "${cask_name%.rb}"
	done
	shopt -u nullglob
fi

for cask in "$@"; do
	# Hosted runners may already have the core formula linked into the same prefix.
	if brew list --formula "${cask}" >/dev/null 2>&1; then
		brew unlink "${cask}"
	fi
	version=$(cask_version "${cask}")
	binaries=("${cask}")
	if [[ ${cask} == runner ]]; then
		binaries+=(run)
	elif [[ ${cask} == svg ]]; then
		binaries=(svg-language-server svg-format svg-lint)
	fi
	artifacts=()
	for binary in "${binaries[@]}"; do
		artifacts+=("bin/${binary}")
	done
	completion_generator=
	commands=("${cask}")
	shells=(bash zsh fish)
	case ${cask} in
		actionlint)
			completion_generator=-completion
			artifacts+=("share/man/man1/actionlint.1")
			shells+=(pwsh)
			;;
		runner | envctl)
			completion_generator=completions
			shells+=(pwsh)
			if [[ ${cask} == envctl ]]; then
				artifacts+=("share/man/man1/envctl.1" "share/powershell/Modules/envctl/envctl.psm1")
			fi
			;;
		rshellcheck)
			completion_generator=--generate-completions
			shells+=(powershell)
			;;
		shellcheck) artifacts+=("share/powershell/completions/shellcheck.ps1") ;;
		svg)
			commands=("${binaries[@]}")
			if ruby -e 'exit Gem::Version.new(ARGV.fetch(0)) > Gem::Version.new("0.5.2") ? 0 : 1' "${version}"; then
				artifacts+=("share/pwsh/completions/_svg.ps1")
			else
				shells=()
			fi
			;;
		*) shells=() ;;
	esac
	for command in "${commands[@]}"; do
		# Bash 3.2 treats an empty array as unset under nounset.
		for shell in ${shells[@]+"${shells[@]}"}; do
			path=$(completion_path "${command}" "${shell}")
			artifacts+=("${path}")
		done
	done

	brew install --cask "kjanat/tap/${cask}"
	check_install "${cask}" "${version}" "${completion_generator}" ${shells[@]+"${shells[@]}"}
	brew reinstall --cask "kjanat/tap/${cask}"
	check_install "${cask}" "${version}" "${completion_generator}" ${shells[@]+"${shells[@]}"}
	brew uninstall --cask "kjanat/tap/${cask}"
	for path in "${artifacts[@]}"; do
		test ! -e "${prefix}/${path}"
		test ! -L "${prefix}/${path}"
	done
done
