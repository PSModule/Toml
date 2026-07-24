function Get-TomlBareToken {
    <#
        .SYNOPSIS
        Reads a bare TOML token from source.

        .DESCRIPTION
        Advances $Index through $Source collecting characters until a delimiter
        (comma, closing bracket, or closing brace) is encountered. When -StopAtEquals
        is set, also stops at the equals sign, enabling bare key extraction in inline
        tables. Returns the trimmed token.

        .EXAMPLE
        $src = 'true, 42'; $i = 0
        Get-TomlBareToken -Source $src -Index ([ref]$i)
        # Returns: 'true'
        Reads a bare token up to the comma delimiter.

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
        [ref] $Index,

        [Parameter()]
        [switch] $StopAtEquals
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
