function Join-TomlKeyPath {
    <#
        .SYNOPSIS
        Joins key path segments into a dotted path.
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
