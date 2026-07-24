function Skip-TomlWhitespace {
    <#
        .SYNOPSIS
        Advances an index past whitespace in a TOML source string.

        .DESCRIPTION
        Increments $Index.Value while the character at that position in $Source is
        classified as whitespace by [char]::IsWhiteSpace. Used to position the index
        before the next meaningful character during value parsing.

        .EXAMPLE
        $src = '   42'; $i = 0
        Skip-TomlWhitespace -Source $src -Index ([ref]$i)
        # $i is now 3, pointing at '4'
        Skips three leading spaces.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [void]
    #>
    [OutputType([void])]
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
