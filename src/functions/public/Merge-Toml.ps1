function Merge-Toml {
    <#
        .SYNOPSIS
        Merges two or more TOML documents into one.

        .DESCRIPTION
        Parses TOML documents with ConvertFrom-Toml, deep-merges the resulting
        ordered dictionaries with the private Merge-TomlTableObject helper, and
        serializes the combined result back to TOML text with ConvertTo-Toml.

        Nested tables are always merged recursively. Arrays of tables are always
        concatenated, base entries first, then override entries. Scalar key
        conflicts (including inline arrays, which are treated as scalars) are
        resolved with -Strategy:
        - LastWins (default): the override value replaces the base value
        - FirstWins: the base value is kept and the override value is ignored
        - ErrorOnConflict: a duplicate scalar key throws

        When -Path or -LiteralPath is given with more than two files, documents
        are merged left to right: the first file is the base, and each
        subsequent file is merged on top of the accumulated result in order.

        .EXAMPLE
        Merge-Toml -BaseObject 'a = 1' -OverrideObject 'b = 2'

        Merges two TOML strings with no overlapping keys. The result is a
        string containing both key-value pairs.

        .EXAMPLE
        Merge-Toml -Path 'defaults.toml', 'local.toml' -Strategy 'FirstWins'

        Merges two files in order, keeping the base value whenever both files
        define the same scalar key.

        .INPUTS
        None

        .OUTPUTS
        [string]

        .NOTES
        Throws when a file cannot be found or read, when either document is not
        valid TOML, or when -Strategy 'ErrorOnConflict' encounters a duplicate
        scalar key.

        .LINK
        https://psmodule.io/Toml/Functions/Merge-Toml
    #>
    [OutputType([string])]
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param(
        # The base TOML document, provided as a string.
        [Parameter(Mandatory, ParameterSetName = 'Default')]
        [ValidateNotNullOrEmpty()]
        [string] $BaseObject,

        # The override TOML document applied on top of the base document.
        [Parameter(Mandatory, ParameterSetName = 'Default')]
        [ValidateNotNullOrEmpty()]
        [string] $OverrideObject,

        # File paths to merge in order. The first path is the base document,
        # and each subsequent path is merged on top of the accumulated result.
        [Parameter(Mandatory, ParameterSetName = 'Path')]
        [ValidateCount(2, [int]::MaxValue)]
        [string[]] $Path,

        # Literal file paths to merge in order, without wildcard expansion.
        # The first path is the base document, and each subsequent path is
        # merged on top of the accumulated result.
        [Parameter(Mandatory, ParameterSetName = 'LiteralPath')]
        [ValidateCount(2, [int]::MaxValue)]
        [string[]] $LiteralPath,

        # The strategy used to resolve scalar key conflicts between documents.
        [Parameter()]
        [ValidateSet('LastWins', 'FirstWins', 'ErrorOnConflict')]
        [string] $Strategy = 'LastWins'
    )

    process {
        $documents = switch ($PSCmdlet.ParameterSetName) {
            'Default' {
                @($BaseObject, $OverrideObject)
            }
            'Path' {
                Write-Verbose "Reading $($Path.Count) file(s) for merge."
                foreach ($p in $Path) {
                    $resolvedPath = Resolve-Path -Path $p -ErrorAction Stop
                    [System.IO.File]::ReadAllText($resolvedPath.ProviderPath)
                }
            }
            'LiteralPath' {
                Write-Verbose "Reading $($LiteralPath.Count) file(s) for merge."
                foreach ($p in $LiteralPath) {
                    $resolvedPath = Resolve-Path -LiteralPath $p -ErrorAction Stop
                    [System.IO.File]::ReadAllText($resolvedPath.ProviderPath)
                }
            }
        }

        $merged = (ConvertFrom-Toml -InputObject $documents[0]).Data
        for ($i = 1; $i -lt $documents.Count; $i++) {
            $override = (ConvertFrom-Toml -InputObject $documents[$i]).Data
            Write-Verbose "Merging document $($i + 1) of $($documents.Count) using strategy '$Strategy'."
            $merged = Merge-TomlTableObject -Base $merged -Override $override -Strategy $Strategy
        }

        return ConvertTo-Toml -InputObject $merged
    }
}
