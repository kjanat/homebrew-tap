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
