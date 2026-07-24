function Join-TomlKeyPath {
    <#
        .SYNOPSIS
        Joins key path segments into a dotted path.

        .DESCRIPTION
        Concatenates an array of key segments with a dot separator. Returns an
        empty string for a null or empty segment array. Used to build the canonical
        path string for header-deduplication tracking.

        .EXAMPLE
        Join-TomlKeyPath -Segments @('a', 'b', 'c')
        # Returns: 'a.b.c'
        Joins three segments into a dotted path.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [string]
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowEmptyCollection()]
        [string[]] $Segments
    )

    if ($null -eq $Segments) {
        return ''
    }

    return ($Segments -join '.')
}
