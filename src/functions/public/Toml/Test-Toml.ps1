function Test-Toml {
    <#
        .SYNOPSIS
        Tests whether a string or file contains valid TOML.

        .DESCRIPTION
        Validates TOML content without throwing. Returns $true when the input
        parses successfully and $false when it does not. On failure, a
        non-terminating error is written via Write-Error so the caller can
        inspect $Error or use -ErrorVariable while the pipeline continues.

        Three parameter sets are supported:
        - Default    : -InputObject — validates a TOML string directly.
        - Path       : -Path        — reads a file (relative paths resolved).
        - LiteralPath: -LiteralPath — reads a file (no wildcard expansion).

        .EXAMPLE
        Test-Toml -InputObject 'title = "Hello"'

        Returns $true because the string is valid TOML.

        .EXAMPLE
        Test-Toml -InputObject 'bad = = "syntax"'

        Returns $false and writes a non-terminating error describing the parse
        failure.

        .EXAMPLE
        Test-Toml -Path '.\config.toml'

        Reads the file and returns $true if its content is valid TOML.

        .EXAMPLE
        Test-Toml -LiteralPath 'C:\Configs\app.toml'

        Reads the file using a literal path (no glob expansion) and returns
        $true if the content parses successfully.

        .INPUTS
        System.String

        TOML text, piped in or passed to -InputObject.

        .OUTPUTS
        System.Boolean

        $true if the input is valid TOML; otherwise $false.

        .NOTES
        Mirrors the pattern of the built-in Test-Json cmdlet.
        All exceptions from the parser are caught and surfaced as
        non-terminating errors so the function never throws.

        .LINK
        https://psmodule.io/Toml/Functions/Toml/Test-Toml/
    #>
    [OutputType([bool])]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        # The TOML string to validate. Accepts pipeline input.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'Default')]
        [AllowEmptyString()]
        [string] $InputObject,

        # Path to a TOML file to validate. Relative paths are resolved against
        # the current working directory.
        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [string] $Path,

        # Literal path to a TOML file to validate. No wildcard expansion is
        # performed.
        [Parameter(Mandatory, ParameterSetName = 'LiteralPath')]
        [string] $LiteralPath
    )

    process {
        $content = $null

        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            Write-Verbose "Resolving path: $Path"
            try {
                $resolved = Resolve-Path -Path $Path -ErrorAction Stop
            } catch {
                Write-Error -Message "Cannot find path '$Path': $($_.Exception.Message)" -ErrorAction Continue
                return $false
            }
            try {
                $content = [System.IO.File]::ReadAllText($resolved.ProviderPath)
            } catch {
                Write-Error -Message "Cannot read file '$($resolved.ProviderPath)': $($_.Exception.Message)" -ErrorAction Continue
                return $false
            }
        } elseif ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
            Write-Verbose "Using literal path: $LiteralPath"
            try {
                $resolved = Resolve-Path -LiteralPath $LiteralPath -ErrorAction Stop
            } catch {
                Write-Error -Message "Cannot find path '$LiteralPath': $($_.Exception.Message)" -ErrorAction Continue
                return $false
            }
            try {
                $content = [System.IO.File]::ReadAllText($resolved.ProviderPath)
            } catch {
                Write-Error -Message "Cannot read file '$($resolved.ProviderPath)': $($_.Exception.Message)" -ErrorAction Continue
                return $false
            }
        } else {
            $content = $InputObject
        }

        Write-Verbose "Validating TOML content ($($content.Length) character(s))."
        try {
            if ([string]::IsNullOrEmpty($content)) {
                throw [System.ArgumentException]::new('Input is empty.')
            }
            $null = ConvertFrom-Toml -InputObject $content
            return $true
        } catch {
            Write-Error -Message "TOML validation failed: $($_.Exception.Message)" -ErrorAction Continue
            return $false
        }
    }
}
