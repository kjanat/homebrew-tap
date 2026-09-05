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
					}
					else {
						$process.Kill()
					}
				}
			}
			catch {
			# A missing or failed executable must not break tab completion.
			}
			finally {
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
			}
			elseif ($word.StartsWith('-') -and -not $word.StartsWith('--')) {
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
		}
		elseif ($kind -in @('positional', 'file', 'directories')) {
			# Let PowerShell handle providers, spaces, quoting, and directory suffixes.
			foreach ($match in [System.Management.Automation.CompletionCompleters]::CompleteFilename($value)) {
				if ($kind -ceq 'directories' -and $match.ResultType -ne 'ProviderContainer') { continue }
				if ($prefix.Length -eq 0 -and $head.Length -eq 0) {
					$results.Add($match)
				}
				else {
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
		}
		else {
			foreach ($result in $results) { $result }
		}
	}.GetNewClosure()

	Register-ArgumentCompleter -Native -CommandName shellcheck, shellcheck.exe -ScriptBlock $completer
}
