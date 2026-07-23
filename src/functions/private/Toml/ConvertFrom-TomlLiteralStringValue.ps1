function ConvertFrom-TomlLiteralStringValue {
    <#
        .SYNOPSIS
        Parses a TOML literal string at the current source index.
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
