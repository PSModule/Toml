function Get-TomlBareToken {
    <#
        .SYNOPSIS
        Reads a bare TOML token from source.
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Source,

        [Parameter(Mandatory)]
        [ref] $Index,

        [Parameter()]
        [bool] $StopAtEquals = $false
    )

    $start = $Index.Value
    while ($Index.Value -lt $Source.Length) {
        $ch = $Source[$Index.Value]
        if ($ch -in ',', ']', '}') {
            break
        }
        if ($StopAtEquals -and $ch -eq '=') {
            break
        }
        $Index.Value++
    }

    return $Source.Substring($start, $Index.Value - $start).Trim()
}
