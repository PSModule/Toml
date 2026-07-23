function Skip-TomlWhitespace {
    <#
        .SYNOPSIS
        Advances an index past whitespace in a TOML source string.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Source,

        [Parameter(Mandatory)]
        [ref] $Index
    )

    while ($Index.Value -lt $Source.Length -and [char]::IsWhiteSpace($Source[$Index.Value])) {
        $Index.Value++
    }
}
