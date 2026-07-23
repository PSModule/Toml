function Format-TomlKey {
    <#
        .SYNOPSIS
        Formats a key for TOML output.
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Key
    )

    if ($Key -match '^[A-Za-z0-9_-]+$') {
        return $Key
    }

    $escaped = $Key.Replace('\', '\\').Replace('"', '\"')
    return '"' + $escaped + '"'
}
