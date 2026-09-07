# Standalone ShellCheck completions

Four independent native completion files for the ShellCheck 0.11.0 interface supplied in the request. No Carapace, completion daemon, generated wrapper executable, or changes to ShellCheck are required. PowerShell does not call `sh`, `awk`, or another Unix tool.

| Shell        | File                        |
| ------------ | --------------------------- |
| Bash         | `bash/shellcheck`           |
| Fish         | `fish/shellcheck.fish`      |
| PowerShell 7 | `powershell/shellcheck.ps1` |
| Zsh          | `zsh/_shellcheck`           |

## Load in the current session

Run the relevant command from this extracted directory.

PowerShell:

```powershell
. ./powershell/shellcheck.ps1
```

Bash:

```bash
source ./bash/shellcheck
```

Zsh:

```zsh
fpath=("$PWD/zsh" $fpath)
autoload -Uz compinit
compinit
autoload -Uz _shellcheck
compdef _shellcheck shellcheck
```

Fish:

```fish
source ./fish/shellcheck.fish
```

For persistent loading, put the PowerShell or Bash source command in the appropriate profile with a stable absolute path. Zsh's directory must be on `fpath` before `compinit`. Fish can autoload the file from `~/.config/fish/completions/shellcheck.fish`.

## What they cover

All 17 long flags and their documented short aliases; output formats; dialects; severity levels; boolean values; attached and separate required option arguments; attached optional color arguments; input filenames without an extension restriction; configuration-file paths; directory-only source-path suggestions including `SCRIPTDIR`; comma-separated optional checks; and filenames after `--`.

`--include`, `--exclude`, and `--wiki-link-count` accept free-form values. These completers deliberately do not suggest a small arbitrary subset of warning codes or numbers, and do not fall back to irrelevant filenames in those argument positions.

`--color=auto` and `-Cauto` are valid color-value forms. After a separate `--color` or `-C`, the next word is an input filename, not a color argument.

When optional check names are needed, the completer reads the installed executable's `--norc --list-optional` metadata and caches successful results for that executable path in the shell session. It runs no analysis of input scripts and writes no cache files. `SHELLCHECK_OPTS` is cleared only for that child process. If metadata discovery fails, `all` is still available. Start a new shell to refresh cached check names after upgrading ShellCheck in place.

The Bash, Zsh, and Fish source-path lists use `:` and target macOS/Linux. PowerShell uses the platform's path-list separator: `:` on Unix and `;` on Windows. PowerShell quotes completed arguments containing semicolons or spaces.

## Use from your Homebrew cask without changing ShellCheck

`Casks/shellcheck.rb` uses a `preflight` block to copy all four files from `cask.tap.path/"completions/shellcheck"` into the staging directory. Homebrew's completion/artifact stanzas then install them. There is no need to modify, rebuild, or repackage ShellCheck's upstream archive.

The installation stanzas are:

```ruby
bash_completion "shellcheck.bash", target: "shellcheck"
fish_completion "shellcheck.fish"
zsh_completion "_shellcheck"
artifact "shellcheck.ps1",
         target: "#{HOMEBREW_PREFIX}/share/powershell/completions/shellcheck.ps1"
```

The `preflight` block supplies the completion files missing from the upstream archive before these artifacts are installed.

Homebrew has dedicated artifact types for Bash, Fish, and Zsh, not PowerShell. The generic `artifact` installs the PowerShell script at a stable shared location. Add this line to the PowerShell profile to load it:

```powershell
. (Join-Path (brew --prefix) 'share/powershell/completions/shellcheck.ps1')
```

The cask intentionally does not modify user shell profiles. Bash, Fish, and Zsh still need their usual Homebrew completion directories configured in their shell.

Edit the four source files directly. Once the updated tap is available locally, reinstall the cask to refresh installed completions:

```sh
brew reinstall --cask kjanat/tap/shellcheck
```

Python is only used to run tests. It is not an installation or completion-time dependency.

## Verification and limitations

Homebrew 6.0.22 on Ubuntu WSL was tested with the local cask and tap files:

- Installation ran ShellCheck 0.11.0 and installed all four completion files byte-for-byte from the tap.
- Reinstallation picked up changed tap completion files without a ShellCheck version change.
- All 12 Bash regression test methods passed against the installed completion file.
- Uninstallation removed the binary and all four completion artifacts.

The original completion creation environment also covered:

- Bash 5.2.37 syntax check.
- All 12 regression test methods in `tests/test_bash.py`, with multiple argument forms per method, passed. Optional-check discovery uses a controlled mock executable.
- Eight real interactive Readline scenarios in `tests/test_bash_readline.py` passed, including single-quoted, double-quoted, and backslash-escaped paths with spaces.

Bash avoids features newer than Bash 3.2, but Bash 3.2 itself was not available to execute. With Bash 3.2, completion can insert a space after a completed list item; newer Bash uses `compopt` to keep comma/path lists open for continued editing.

The Ubuntu installation checks did not exercise interactive PowerShell, Zsh, or Fish completion behavior. Windows and macOS cask installation remain unverified.

The Bash filename helper uses line-delimited `compgen` output, so filenames containing literal newline characters are not supported. Ordinary filenames with spaces are covered by the interactive tests.

Run the Bash regression suite:

```sh
python3 tests/test_bash.py
```

The interactive suite additionally needs the test-only Python package `pexpect`:

```sh
python3 tests/test_bash_readline.py
```

## References

- ShellCheck 0.11.0 argument parsing and metadata output: https://github.com/koalaman/shellcheck/blob/v0.11.0/shellcheck.hs
- PowerShell native argument completers: https://learn.microsoft.com/powershell/module/microsoft.powershell.core/register-argumentcompleter
- PowerShell filename completion implementation: https://github.com/PowerShell/PowerShell/blob/b664c2e026d1610e9b5a6cc5b14d3c86aae9ab81/src/System.Management.Automation/engine/CommandCompletion/CompletionCompleters.cs
- Zsh completion system: https://zsh.sourceforge.io/Doc/Release/Completion-System.html
- Fish `complete`: https://fishshell.com/docs/current/cmds/complete.html
- Homebrew cask stanzas: https://docs.brew.sh/Cask-Cookbook
