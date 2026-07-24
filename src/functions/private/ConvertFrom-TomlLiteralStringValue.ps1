function ConvertFrom-TomlLiteralStringValue {
    <#
        .SYNOPSIS
        Parses a TOML literal string at the current source index.

        .DESCRIPTION
        Reads a single-line literal string ('...') or a multi-line literal string ('''...''')
        starting at $Index.Value in $Source. No escape processing is performed.
        Advances $Index past the closing delimiter.

        .EXAMPLE
        $src = "'C:\Users\Alice'"; $i = 0
        ConvertFrom-TomlLiteralStringValue -Source $src -Index ([ref]$i)
        # Returns: "C:\Users\Alice"
        Parses a literal string containing backslashes with no escape processing.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [string]
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Source,

        [Parameter(Mandatory)]
        [ref] $Index
    )

    if ($Source.Substring($Index.Value).StartsWith("'''", [System.StringComparison]::Ordinal)) {
        $Index.Value += 3
        $start = $Index.Value
        $end = $Source.IndexOf("'''", $start, [System.StringComparison]::Ordinal)
        if ($end -lt 0) {
            throw [System.InvalidOperationException]::new('Unterminated multi-line literal string.')
        }
        $Index.Value = $end + 3
        return $Source.Substring($start, $end - $start)
    }

    $Index.Value++
    $start = $Index.Value
    while ($Index.Value -lt $Source.Length) {
        if ($Source[$Index.Value] -eq '''') {
            $literal = $Source.Substring($start, $Index.Value - $start)
            $Index.Value++
            return $literal
        }
        $Index.Value++
    }

    throw [System.InvalidOperationException]::new('Unterminated TOML literal string.')
}
