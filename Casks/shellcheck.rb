cask "shellcheck" do
  version "0.11.0"

  on_macos do
    on_arm do
      sha256 "56affdd8de5527894dca6dc3d7e0a99a873b0f004d7aabc30ae407d3f48b0a79"
      url "https://github.com/koalaman/shellcheck/releases/download/v#{version}/shellcheck-v#{version}.darwin.aarch64.tar.xz"
    end
    on_intel do
      sha256 "3c89db4edcab7cf1c27bff178882e0f6f27f7afdf54e859fa041fca10febe4c6"
      url "https://github.com/koalaman/shellcheck/releases/download/v#{version}/shellcheck-v#{version}.darwin.x86_64.tar.xz"
    end
  end
  on_linux do
    on_arm do
      sha256 "12b331c1d2db6b9eb13cfca64306b1b157a86eb69db83023e261eaa7e7c14588"
      url "https://github.com/koalaman/shellcheck/releases/download/v#{version}/shellcheck-v#{version}.linux.aarch64.tar.xz"
    end
    on_intel do
      sha256 "8c3be12b05d5c177a04c29e3c78ce89ac86f1595681cab149b65b97c4e227198"
      url "https://github.com/koalaman/shellcheck/releases/download/v#{version}/shellcheck-v#{version}.linux.x86_64.tar.xz"
    end
  end

  name "ShellCheck"
  desc "Static analysis tool for shell scripts, as the static binary the project releases"
  homepage "https://www.shellcheck.net/"

  livecheck do
    url :url
    strategy :github_latest
  end

  conflicts_with formula: "shellcheck"

  generated_script "shellcheck.bash", content: <<~'SC_BASH'
    # ShellCheck 0.11.0 completion. Source this file; do not execute it.
    # Requires Bash 3.2+; does not require the bash-completion package.

    _shellcheck_load_checks() {
        local exe output line name
        exe=$(type -P -- "${1:-shellcheck}") || { _shellcheck_checks=(); _shellcheck_checks_exe=; return 0; }
        if [[ ${_shellcheck_checks_exe-} == "$exe" ]]; then return 0; fi
        _shellcheck_checks=()
        if output=$(LC_ALL=C SHELLCHECK_OPTS='' "$exe" --norc --list-optional 2>/dev/null); then
            while IFS= read -r line; do
                case $line in
                    name:*)
                        read -r _ name <<< "$line"
                        [[ -n $name ]] && _shellcheck_checks+=("$name")
                        ;;
                esac
            done <<< "$output"
            _shellcheck_checks_exe=$exe
        fi
        return 0
    }

    _shellcheck_emit() {
        # Readline replaces only the fragment after a word break such as '=' or ':'.
        local candidate=$1
        if [[ -n $sc_trim && $candidate == "$sc_trim"* ]]; then
            candidate=${candidate#"$sc_trim"}
        fi
        COMPREPLY+=("$candidate")
    }

    _shellcheck_files() {
        local mode=$1 value=$2 prefix=$3 lookup path home_prefix=
        lookup=$value
        case $lookup in
            \~/*) lookup=$HOME/${lookup#\~/}; home_prefix=1 ;;
        esac
        while IFS= read -r path; do
            [[ -d $path ]] && path=${path%/}/
            [[ -n $home_prefix ]] && path=\~/${path#"$HOME"/}
            _shellcheck_emit "$prefix$path"
        done < <(compgen "$mode" -- "$lookup")
    }

    _shellcheck_complete() {
        local -a sc_words=() choices=()
        local sc_trim='' cur word previous='' option='' value='' prefix='' head='' rest char
        local i j=0 n ended=0 candidate fragment=${2-}
        COMPREPLY=()
        # compopt is not available in macOS's system Bash 3.2.
        if type compopt &>/dev/null; then compopt +o nospace 2>/dev/null || :; fi

        # Reassemble ':' and '=' fragments split by Bash's default COMP_WORDBREAKS.
        # Never eval the command line or any filename.
        for ((i=0; i<=COMP_CWORD; i++)); do
            word=${COMP_WORDS[i]}
            # Bash passes $2 without surrounding quotes. Use that form so a quoted
            # --rcfile value does not accidentally retain the --rcfile= prefix twice.
            if ((i == COMP_CWORD)) && [[ $word == *[\'\"]* ]]; then
                word=$fragment
            fi
            if ((j > 0)) && { [[ $word == = || $word == : ]] ||
                [[ $previous == = || $previous == : ]]; }; then
                sc_words[j-1]=${sc_words[j-1]}$word
            else
                sc_words[j]=$word
                j=$((j+1))
            fi
            previous=$word
        done
        n=${#sc_words[@]}
        cur=${sc_words[n-1]}
        if [[ $cur != "$fragment" && $cur == *"$fragment" ]]; then
            sc_trim=${cur:0:${#cur}-${#fragment}}
        fi

        # Only words to the left of the cursor affect argument context.
        for ((i=1; i<n-1; i++)); do
            word=${sc_words[i]}
            if [[ -n $option ]]; then option=; continue; fi
            case $word in
                --) ended=1; break ;;
                --include|--exclude|--extended-analysis|--format|--rcfile|--enable|--source-path|--shell|--severity|--wiki-link-count)
                    option=$word ;;
                --*) ;;
                -?*)
                    rest=${word#-}
                    while [[ -n $rest ]]; do
                        char=${rest:0:1}; rest=${rest:1}
                        case $char in
                            i|e|f|o|P|s|S|W)
                                [[ -z $rest ]] && option=-$char
                                break ;;
                            C) break ;; # The optional color value must be attached.
                            a|V|x) ;;
                            *) break ;;
                        esac
                    done ;;
            esac
        done

        value=$cur
        if (( !ended )) && [[ -z $option ]]; then
            case $cur in
                --*=*) option=${cur%%=*}; prefix=$option=; value=${cur#*=} ;;
                --*) ;;
                -?*)
                    rest=${cur#-}; prefix=-
                    while [[ -n $rest ]]; do
                        char=${rest:0:1}; rest=${rest:1}; prefix=$prefix$char
                        case $char in
                            C|i|e|f|o|P|s|S|W) option=-$char; value=$rest; break ;;
                            a|V|x) ;;
                            *) break ;;
                        esac
                    done
                    [[ -n $option ]] || prefix= ;;
            esac
        fi

        if ((ended)); then
            _shellcheck_files -f "$cur" ''
            [[ - == "$cur"* ]] && _shellcheck_emit -
            return 0
        fi

        case $option in
            -C|--color) choices=(auto always never) ;;
            --extended-analysis) choices=(true false) ;;
            -f|--format) choices=(checkstyle diff gcc json json1 quiet tty) ;;
            -s|--shell) choices=(sh bash dash ksh busybox) ;;
            -S|--severity) choices=(error warning info style) ;;
            -o|--enable)
                _shellcheck_load_checks "${sc_words[0]}"
                choices=(all "${_shellcheck_checks[@]}")
                if [[ $value == *,* ]]; then head=${value%,*},; value=${value##*,}; fi
                if type compopt &>/dev/null; then compopt -o nospace 2>/dev/null || :; fi
                ;;
            -P|--source-path)
                if [[ $value == *:* ]]; then head=${value%:*}:; value=${value##*:}; fi
                _shellcheck_files -d "$value" "$prefix$head"
                [[ SCRIPTDIR == "$value"* ]] && _shellcheck_emit "${prefix}${head}SCRIPTDIR"
                if type compopt &>/dev/null; then compopt -o nospace 2>/dev/null || :; fi
                return 0 ;;
            --rcfile) _shellcheck_files -f "$value" "$prefix"; return 0 ;;
            -i|--include|-e|--exclude|-W|--wiki-link-count)
                # Free-form values: do not invent a partial warning-code catalogue.
                return 0 ;;
            '')
                if [[ $cur == -* ]]; then
                    choices=(-a --check-sourced -C --color --color=auto --color=always --color=never
                        -i --include -e --exclude --extended-analysis -f --format
                        --list-optional --norc --rcfile -o --enable -P --source-path
                        -s --shell -S --severity -V --version -W --wiki-link-count
                        -x --external-sources --help -- -)
                else
                    _shellcheck_files -f "$cur" ''
                    [[ -z $cur ]] && _shellcheck_emit -
                    return 0
                fi ;;
            *) return 0 ;;
        esac
        for candidate in "${choices[@]}"; do
            [[ $candidate == "$value"* ]] || continue
            if [[ -n $head && ,$head == *,$candidate,* ]]; then continue; fi
            _shellcheck_emit "$prefix$head$candidate"
        done
        return 0
    }

    complete -o filenames -F _shellcheck_complete shellcheck
  SC_BASH

  generated_script "shellcheck.fish", content: <<~'SC_FISH'
    # ShellCheck 0.11.0. Place in ~/.config/fish/completions/shellcheck.fish.
    # Replaces any previously loaded definition for the same command.
    complete -c shellcheck -e

    function __shellcheck_optional_names
        set -l exe (command -s shellcheck)
        if test -n "$exe"
            if not set -q __shellcheck_checks_exe; or test "$__shellcheck_checks_exe" != "$exe"
                set -g __shellcheck_check_names
                set -l output (env LC_ALL=C SHELLCHECK_OPTS= "$exe" --norc --list-optional 2>/dev/null)
                if test $status -eq 0
                    for line in $output
                        set -l name (string match -r -- '^name:\s+(\S+)' "$line")
                        if set -q name[2]
                            set -ga __shellcheck_check_names "$name[2]"
                        end
                    end
                    set -g __shellcheck_checks_exe "$exe"
                end
            end
        end
        printf '%s\n' all $__shellcheck_check_names
    end

    function __shellcheck_enable_values
        set -l token (commandline -ct)
        set token (string replace -r -- '^(--enable=|-[aVx]*o)' '' "$token")
        set -l head ''
        if string match -q '*,*' -- "$token"
            set head (string replace -r -- '[^,]*$' '' "$token")
        end
        set -l used (string split , -- "$head")
        for name in (__shellcheck_optional_names)
            contains -- "$name" $used; and continue
            printf '%s\n' "$head$name"
        end
    end

    function __shellcheck_source_paths
        set -l token (commandline -ct)
        set token (string replace -r -- '^(--source-path=|-[aVx]*P)' '' "$token")
        set -l head ''
        set -l tail "$token"
        if string match -q '*:*' -- "$token"
            set head (string replace -r -- '[^:]*$' '' "$token")
            set tail (string replace -r -- '^.*:' '' "$token")
        end
        printf '%s\t%s\n' "$head"SCRIPTDIR "Input script's directory"
        for directory in (__fish_complete_directories "$tail")
            printf '%s\n' "$head$directory"
        end
    end

    complete -c shellcheck -s a -l check-sourced -d 'Include warnings from sourced files'
    # No -r: optional color arguments must be attached, never a separate word.
    complete -c shellcheck -s C -l color -f -a 'auto always never' -d 'Use color'
    complete -c shellcheck -s i -l include -x -d 'Comma-separated warning codes to include'
    complete -c shellcheck -s e -l exclude -x -d 'Comma-separated warning codes to exclude'
    complete -c shellcheck -l extended-analysis -x -a 'true false' -d 'Enable or disable dataflow analysis'
    complete -c shellcheck -s f -l format -x -a 'checkstyle diff gcc json json1 quiet tty' -d 'Select output format'
    complete -c shellcheck -l list-optional -d 'List checks disabled by default'
    complete -c shellcheck -l norc -d 'Do not search for .shellcheckrc files'
    complete -c shellcheck -l rcfile -r -F -d 'Use the specified configuration file'
    complete -c shellcheck -s o -l enable -x -a '(__shellcheck_enable_values)' -d 'Enable optional checks or all'
    complete -c shellcheck -s P -l source-path -x -a '(__shellcheck_source_paths)' -d 'Search directories for sourced files'
    complete -c shellcheck -s s -l shell -x -a 'sh bash dash ksh busybox' -d 'Select shell dialect'
    complete -c shellcheck -s S -l severity -x -a 'error warning info style' -d 'Set minimum diagnostic severity'
    complete -c shellcheck -s V -l version -d 'Print version information'
    complete -c shellcheck -s W -l wiki-link-count -x -d 'Number of wiki links'
    complete -c shellcheck -s x -l external-sources -d 'Allow sourcing files outside the input files'
    complete -c shellcheck -l help -d 'Show usage information'
    complete -c shellcheck -a '-' -d 'Read from standard input'
  SC_FISH

  generated_script "_shellcheck", content: <<~'SC_ZSH'
    #compdef shellcheck
    # ShellCheck 0.11.0. Put this file on fpath and run compinit.

    _shellcheck_optional_checks() {
        local exe output line
        local -a fields
        exe=$(whence -p -- "$words[1]") || exe=shellcheck
        if [[ ${_shellcheck_checks_exe-} != "$exe" ]]; then
            typeset -ga _shellcheck_check_names=()
            if output=$(LC_ALL=C SHELLCHECK_OPTS= "$exe" --norc --list-optional 2>/dev/null); then
                for line in "${(@f)output}"; do
                    fields=( ${=line} )
                    if [[ $fields[1] == name: && -n $fields[2] ]]; then
                        _shellcheck_check_names+=( "$fields[2]" )
                    fi
                done
                typeset -g _shellcheck_checks_exe=$exe
            fi
        fi
        _values -s , 'optional check' all "${_shellcheck_check_names[@]}"
    }

    _shellcheck_source_paths() {
        _sequence -s : _alternative \
            'special-paths:special source directory:compadd -- SCRIPTDIR' \
            'directories:source directory:_files -/'
    }

    _shellcheck_input_files() {
        _alternative 'files:input file:_files' 'stdin:standard input:compadd -- -'
    }

    _arguments -s -S \
        '(-a --check-sourced)'{-a,--check-sourced}'[Include warnings from sourced files]' \
        '-C-[Use color]::color:(auto always never)' \
        '--color=-[Use color]::color:(auto always never)' \
        '*'{-i+,--include=}'[Consider only specified warnings]:comma-separated warning codes (e.g. SC2086,SC2046): ' \
        '*'{-e+,--exclude=}'[Exclude specified warnings]:comma-separated warning codes (e.g. SC2086,SC2046): ' \
        '--extended-analysis=[Enable or disable dataflow analysis]:boolean:(true false)' \
        '(-f --format)'{-f+,--format=}'[Select output format]:format:(checkstyle diff gcc json json1 quiet tty)' \
        '--list-optional[List checks disabled by default]' \
        '--norc[Do not search for .shellcheckrc files]' \
        '--rcfile=[Use the specified configuration file]:configuration file:_files' \
        '*'{-o+,--enable=}'[Enable optional checks]:optional checks:_shellcheck_optional_checks' \
        '*'{-P+,--source-path=}'[Set search paths for sourced files]:source paths:_shellcheck_source_paths' \
        '(-s --shell)'{-s+,--shell=}'[Select shell dialect]:shell:(sh bash dash ksh busybox)' \
        '(-S --severity)'{-S+,--severity=}'[Set minimum diagnostic severity]:severity:(error warning info style)' \
        '(-V --version)'{-V,--version}'[Print version information]' \
        '(-W --wiki-link-count)'{-W+,--wiki-link-count=}'[Set number of wiki links]:number of wiki links: ' \
        '(-x --external-sources)'{-x,--external-sources}'[Allow sourcing files outside the input files]' \
        '--help[Show usage information]' \
        '*:input file:_shellcheck_input_files'
  SC_ZSH

  generated_script "shellcheck.ps1", content: <<~'SC_POWERSHELL'
    #requires -Version 7.0
    # ShellCheck 0.11.0. Dot-source this file from $PROFILE.
    # No completion engine, module, Unix shell, or awk dependency.

    & {
        $spec = @(
            @{ Short = '-a'; Long = '--check-sourced'; Kind = 'switch'; Description = 'Include warnings from sourced files' }
            @{ Short = '-C'; Long = '--color'; Kind = 'optional'; Values = @('auto', 'always', 'never'); Description = 'Use color' }
            @{ Short = '-i'; Long = '--include'; Kind = 'free'; Description = 'Comma-separated warning codes to include, e.g. SC2086,SC2046' }
            @{ Short = '-e'; Long = '--exclude'; Kind = 'free'; Description = 'Comma-separated warning codes to exclude, e.g. SC2086,SC2046' }
            @{ Short = ''; Long = '--extended-analysis'; Kind = 'enum'; Values = @('true', 'false'); Description = 'Enable or disable dataflow analysis' }
            @{ Short = '-f'; Long = '--format'; Kind = 'enum'; Values = @('checkstyle', 'diff', 'gcc', 'json', 'json1', 'quiet', 'tty'); Description = 'Select output format' }
            @{ Short = ''; Long = '--list-optional'; Kind = 'switch'; Description = 'List checks disabled by default' }
            @{ Short = ''; Long = '--norc'; Kind = 'switch'; Description = 'Do not search for .shellcheckrc files' }
            @{ Short = ''; Long = '--rcfile'; Kind = 'file'; Description = 'Use the specified configuration file' }
            @{ Short = '-o'; Long = '--enable'; Kind = 'checks'; Description = 'Enable comma-separated optional checks or all' }
            @{ Short = '-P'; Long = '--source-path'; Kind = 'directories'; Description = 'Search paths for sourced files, or SCRIPTDIR' }
            @{ Short = '-s'; Long = '--shell'; Kind = 'enum'; Values = @('sh', 'bash', 'dash', 'ksh', 'busybox'); Description = 'Select shell dialect' }
            @{ Short = '-S'; Long = '--severity'; Kind = 'enum'; Values = @('error', 'warning', 'info', 'style'); Description = 'Set minimum diagnostic severity' }
            @{ Short = '-V'; Long = '--version'; Kind = 'switch'; Description = 'Print version information' }
            @{ Short = '-W'; Long = '--wiki-link-count'; Kind = 'free'; Description = 'Number of wiki links' }
            @{ Short = '-x'; Long = '--external-sources'; Kind = 'switch'; Description = 'Allow sourcing files outside the input files' }
            @{ Short = ''; Long = '--help'; Kind = 'switch'; Description = 'Show usage information' }
        )
        # Ordinary PowerShell hashtables ignore case. -s and -S are different flags.
        $flags = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
        foreach ($item in $spec) {
            $flags[$item.Long] = $item
            if ($item.Short) { $flags[$item.Short] = $item }
        }
        $checkCache = [System.Collections.Generic.Dictionary[string, string[]]]::new([System.StringComparer]::Ordinal)

        $completer = {
            param(
                [string] $wordToComplete,
                [System.Management.Automation.Language.CommandAst] $commandAst,
                [int] $cursorPosition
            )

            function ConvertFrom-ShellCheckQuotedWord([string] $Text) {
                if ($Text.StartsWith("'")) {
                    $Text = $Text.Substring(1)
                    if ($Text.EndsWith("'")) { $Text = $Text.Substring(0, $Text.Length - 1) }
                    return $Text.Replace("''", "'")
                }
                if ($Text.StartsWith('"')) {
                    $Text = $Text.Substring(1)
                    if ($Text.EndsWith('"')) { $Text = $Text.Substring(0, $Text.Length - 1) }
                    return ($Text -replace '`(.)', '$1')
                }
                return $Text
            }

            function ConvertTo-ShellCheckQuotedWord([string] $Text) {
                # Quote the complete native argument, including --flag= when present.
                if ($Text -match '[\s''"`$;&|<>(){}\[\]#@]') {
                    return "'" + $Text.Replace("'", "''") + "'"
                }
                return $Text
            }

            function Get-ShellCheckOptionalNames {
                $name = $commandAst.GetCommandName()
                if (-not $name) { $name = 'shellcheck' }
                $executable = Get-Command -Name $name -CommandType Application -ErrorAction Ignore | Select-Object -First 1
                if (-not $executable) { return 'all' }
                $path = $executable.Path
                if ($checkCache.ContainsKey($path)) { return $checkCache[$path] }

                # Read metadata from a child process, not the user's input files.
                # Set the environment on that process only, preserving this session.
                $names = [System.Collections.Generic.List[string]]::new()
                $names.Add('all')
                $process = [System.Diagnostics.Process]::new()
                try {
                    $start = [System.Diagnostics.ProcessStartInfo]::new()
                    $start.FileName = $path
                    $start.UseShellExecute = $false
                    $start.CreateNoWindow = $true
                    $start.RedirectStandardOutput = $true
                    $start.RedirectStandardError = $true
                    $start.Environment['SHELLCHECK_OPTS'] = ''
                    $start.Environment['LC_ALL'] = 'C'
                    $start.ArgumentList.Add('--norc')
                    $start.ArgumentList.Add('--list-optional')
                    $process.StartInfo = $start
                    if ($process.Start()) {
                        $stdout = $process.StandardOutput.ReadToEndAsync()
                        $stderr = $process.StandardError.ReadToEndAsync()
                        if ($process.WaitForExit(1500)) {
                            if ($process.ExitCode -eq 0) {
                                foreach ($match in [regex]::Matches($stdout.GetAwaiter().GetResult(), '(?m)^name:\s+(\S+)')) {
                                    $names.Add($match.Groups[1].Value)
                                }
                                $checkCache[$path] = $names.ToArray()
                            }
                            $null = $stderr.GetAwaiter().GetResult()
                        } else {
                            $process.Kill()
                        }
                    }
                } catch {
                    # A missing or failed executable must not break tab completion.
                } finally {
                    $process.Dispose()
                }
                return $names.ToArray()
            }

            $results = [System.Collections.Generic.List[System.Management.Automation.CompletionResult]]::new()
            $word = ConvertFrom-ShellCheckQuotedWord $wordToComplete
            $pending = $null
            $endOfOptions = $false

            # AST offsets exclude both the current argument and words after the cursor.
            foreach ($element in $commandAst.CommandElements | Select-Object -Skip 1) {
                if ($element.Extent.StartOffset -ge $cursorPosition) { break }
                if ($wordToComplete.Length -gt 0 -and $element.Extent.EndOffset -ge $cursorPosition) { break }
                $argument = ConvertFrom-ShellCheckQuotedWord $element.Extent.Text
                if ($null -ne $pending) { $pending = $null; continue }
                if ($argument -ceq '--') { $endOfOptions = $true; break }
                if ($flags.ContainsKey($argument)) {
                    $definition = $flags[$argument]
                    if ($definition.Kind -notin @('switch', 'optional')) { $pending = $definition }
                    continue
                }
                if ($argument.StartsWith('--')) { continue }
                if ($argument.StartsWith('-') -and $argument.Length -gt 1) {
                    for ($i = 1; $i -lt $argument.Length; $i++) {
                        $key = '-' + $argument[$i]
                        if (-not $flags.ContainsKey($key)) { break }
                        $definition = $flags[$key]
                        if ($definition.Kind -ceq 'switch') { continue }
                        if ($definition.Kind -cne 'optional' -and $i -eq $argument.Length - 1) {
                            $pending = $definition
                        }
                        break
                    }
                }
            }

            $prefix = ''
            $value = $word
            $definition = $pending
            if (-not $endOfOptions -and $null -eq $definition) {
                if ($word.StartsWith('--') -and $word.Contains('=')) {
                    $equals = $word.IndexOf('=')
                    $key = $word.Substring(0, $equals)
                    if ($flags.ContainsKey($key)) {
                        $definition = $flags[$key]
                        $prefix = $word.Substring(0, $equals + 1)
                        $value = ConvertFrom-ShellCheckQuotedWord $word.Substring($equals + 1)
                    }
                } elseif ($word.StartsWith('-') -and -not $word.StartsWith('--')) {
                    for ($i = 1; $i -lt $word.Length; $i++) {
                        $key = '-' + $word[$i]
                        if (-not $flags.ContainsKey($key)) { break }
                        if ($flags[$key].Kind -ceq 'switch') { continue }
                        $definition = $flags[$key]
                        $prefix = $word.Substring(0, $i + 1)
                        $value = ConvertFrom-ShellCheckQuotedWord $word.Substring($i + 1)
                        break
                    }
                }
            }

            $kind = if ($null -ne $definition) { $definition.Kind } else { 'positional' }
            if ($endOfOptions) { $kind = 'positional' }
            $head = ''
            $values = @()
            switch ($kind) {
                { $_ -in @('enum', 'optional') } { $values = $definition.Values }
                'checks' {
                    $comma = $value.LastIndexOf(',')
                    if ($comma -ge 0) {
                        $head = $value.Substring(0, $comma + 1)
                        $value = $value.Substring($comma + 1)
                    }
                    $values = @(Get-ShellCheckOptionalNames | Where-Object { $_ -cnotin $head.Split(',') })
                }
                'directories' {
                    $separator = [System.IO.Path]::PathSeparator
                    $last = $value.LastIndexOf($separator)
                    if ($last -ge 0) {
                        $head = $value.Substring(0, $last + 1)
                        $value = $value.Substring($last + 1)
                    }
                    $values = @('SCRIPTDIR')
                }
            }
            foreach ($candidate in $values) {
                if (-not $candidate.StartsWith($value, [System.StringComparison]::Ordinal)) { continue }
                $text = ConvertTo-ShellCheckQuotedWord "$prefix$head$candidate"
                $tooltip = if ($candidate -ceq 'SCRIPTDIR') { "Input script's directory" } else { $definition.Description }
                $results.Add([System.Management.Automation.CompletionResult]::new($text, $candidate, 'ParameterValue', $tooltip))
            }

            if ($kind -ceq 'positional' -and -not $endOfOptions -and $word.StartsWith('-')) {
                foreach ($item in $spec) {
                    foreach ($flag in @($item.Short, $item.Long)) {
                        if ($flag -and $flag.StartsWith($word, [System.StringComparison]::Ordinal)) {
                            $results.Add([System.Management.Automation.CompletionResult]::new($flag, $flag, 'ParameterName', $item.Description))
                        }
                    }
                    if ($item.Kind -ceq 'optional') {
                        foreach ($color in $item.Values) {
                            $flag = $item.Long + '=' + $color
                            if ($flag.StartsWith($word, [System.StringComparison]::Ordinal)) {
                                $results.Add([System.Management.Automation.CompletionResult]::new($flag, $flag, 'ParameterName', $item.Description))
                            }
                        }
                    }
                }
                if ('--'.StartsWith($word, [System.StringComparison]::Ordinal)) {
                    $results.Add([System.Management.Automation.CompletionResult]::new('--', '--', 'ParameterName', 'End option parsing'))
                }
            } elseif ($kind -in @('positional', 'file', 'directories')) {
                # Let PowerShell handle providers, spaces, quoting, and directory suffixes.
                foreach ($match in [System.Management.Automation.CompletionCompleters]::CompleteFilename($value)) {
                    if ($kind -ceq 'directories' -and $match.ResultType -ne 'ProviderContainer') { continue }
                    if ($prefix.Length -eq 0 -and $head.Length -eq 0) {
                        $results.Add($match)
                    } else {
                        $path = ConvertFrom-ShellCheckQuotedWord $match.CompletionText
                        $text = ConvertTo-ShellCheckQuotedWord "$prefix$head$path"
                        $results.Add([System.Management.Automation.CompletionResult]::new($text, $match.ListItemText, $match.ResultType, $match.ToolTip))
                    }
                }
            }
            if ($kind -ceq 'positional' -and '-'.StartsWith($word, [System.StringComparison]::Ordinal)) {
                $results.Add([System.Management.Automation.CompletionResult]::new('-', '-', 'ParameterValue', 'Read from standard input'))
            }
            if ($results.Count -eq 0) {
                # Suppress default filename fallback in numeric/check-code contexts.
                ''
            } else {
                foreach ($result in $results) { $result }
            }
        }.GetNewClosure()

        Register-ArgumentCompleter -Native -CommandName shellcheck, shellcheck.exe -ScriptBlock $completer
    }
  SC_POWERSHELL

  binary "shellcheck-v#{version}/shellcheck"
  bash_completion "shellcheck.bash", target: "shellcheck"
  fish_completion "shellcheck.fish"
  zsh_completion "_shellcheck"
  artifact "shellcheck.ps1",
           target: "#{HOMEBREW_PREFIX}/share/powershell/completions/shellcheck.ps1"

  caveats <<~EOS
    PowerShell completion is installed to
      #{HOMEBREW_PREFIX}/share/powershell/completions/shellcheck.ps1
    Load it from your PowerShell profile:
      . (Join-Path (brew --prefix) 'share/powershell/completions/shellcheck.ps1')
  EOS
end
