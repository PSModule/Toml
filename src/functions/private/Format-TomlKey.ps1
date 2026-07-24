function Format-TomlKey {
    <#
        .SYNOPSIS
        Formats a key for TOML output.

        .DESCRIPTION
        Returns the key unchanged when it consists entirely of alphanumeric characters,
        hyphens, and underscores (bare key). Otherwise wraps it in double quotes and
        escapes internal backslashes and double quotes.

        .EXAMPLE
        Format-TomlKey -Key 'server-host'
        # Returns: 'server-host'
        A bare key is returned as-is.

        .EXAMPLE
        Format-TomlKey -Key 'my key'
        # Returns: '"my key"'
        A key with a space is wrapped in double quotes.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [string]
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
