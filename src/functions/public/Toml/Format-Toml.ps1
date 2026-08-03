function Format-Toml {
    <#
        .SYNOPSIS
        Normalizes TOML text to a canonical form.

        .DESCRIPTION
        Parses TOML text and re-serializes it, producing consistent key quoting,
        canonical scalar formatting, and stable table ordering — semantically
        equivalent to `ConvertFrom-Toml | ConvertTo-Toml` expressed as a single
        ergonomic pipeline step. The result is idempotent: formatting already
        canonical text returns the same text unchanged.

        TOML itself is a flat, whitespace-insensitive format — nested tables are
        represented as `[a.b]` headers rather than indented blocks, so there is no
        spec-defined meaning for indentation. The `-Indent` parameter is offered as
        a display convention only: it prefixes each table header and its key-value
        lines with spaces proportional to the table's nesting depth (as some TOML
        formatters, such as Taplo, do). This never changes the parsed value of the
        document. Set `-Indent 0` to disable it and keep the flat, unindented form
        that `ConvertTo-Toml` produces.

        .EXAMPLE
        Format-Toml -InputObject 'name="value"  [ a ]  x=1'

        Reformats an inconsistently spaced TOML string into canonical form.

        .EXAMPLE
        Get-Content 'Cargo.toml' -Raw | Format-Toml

        Reads a file's content and normalizes it via the pipeline.

        .EXAMPLE
        Format-Toml -Path 'Cargo.toml' -Indent 4

        Reads a TOML file and returns its canonical form with nested tables
        indented four spaces per level.

        .EXAMPLE
        Format-Toml -LiteralPath 'C:\configs\[env].toml'

        Reads a file whose name contains wildcard-like characters, bypassing
        wildcard expansion.

        .INPUTS
        System.String

        TOML text, piped in or passed to -InputObject.

        .OUTPUTS
        System.String

        Normalized TOML text.

        .NOTES
        Throws when the input is not valid TOML 1.0.0, when a file path does not
        resolve to an existing file, or when a file cannot be read. This function
        does not validate — it formats. Use a try/catch (or `Test-Toml`, if
        available) to check validity without raising a terminating error.

        .LINK
        https://psmodule.io/Toml/Functions/Toml/Format-Toml/
    #>
    [OutputType([string])]
    [CmdletBinding(DefaultParameterSetName = 'InputObject')]
    param(
        # TOML text to normalize.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'InputObject')]
        [ValidateNotNullOrEmpty()]
        [string] $InputObject,

        # Path to a TOML file to read and normalize. Accepts relative paths and wildcards.
        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [ValidateNotNullOrEmpty()]
        [string] $Path,

        # Literal path to a TOML file to read and normalize. No wildcard expansion is performed.
        [Parameter(Mandatory, ParameterSetName = 'LiteralPath')]
        [ValidateNotNullOrEmpty()]
        [string] $LiteralPath,

        # Spaces used to indent nested table headers and keys per nesting level.
        # This is a display convention only — TOML has no indentation semantics.
        # Set to 0 to keep the flat, unindented canonical form.
        [Parameter()]
        [ValidateRange(0, 100)]
        [int] $Indent = 2
    )

    process {
        $tomlText = switch ($PSCmdlet.ParameterSetName) {
            'Path' {
                $resolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
                Write-Verbose "Reading TOML file: $($resolvedPath.ProviderPath)"
                [System.IO.File]::ReadAllText($resolvedPath.ProviderPath)
            }
            'LiteralPath' {
                $resolvedPath = Resolve-Path -LiteralPath $LiteralPath -ErrorAction Stop
                Write-Verbose "Reading TOML file: $($resolvedPath.ProviderPath)"
                [System.IO.File]::ReadAllText($resolvedPath.ProviderPath)
            }
            default {
                $InputObject
            }
        }

        Write-Verbose "Normalizing TOML text ($($tomlText.Length) character(s)), Indent=$Indent."
        $doc = ConvertFrom-Toml -InputObject $tomlText
        $canonical = ConvertTo-Toml -InputObject $doc

        return Add-TomlIndentation -Toml $canonical -Indent $Indent
    }
}
