function ConvertFrom-TomlValue {
    <#
        .SYNOPSIS
        Converts a TOML value token to a native PowerShell value.
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Value
    )

    $text = $Value.Trim()
    if ($text.Length -eq 0) {
        throw [System.InvalidOperationException]::new('Missing TOML value.')
    }

    $index = 0
    $parsed = ConvertFrom-TomlParsedValue -Source $text -Index ([ref]$index)
    Skip-TomlWhitespace -Source $text -Index ([ref]$index)
    if ($index -lt $text.Length) {
        throw [System.InvalidOperationException]::new("Unexpected trailing token in TOML value: '$($text.Substring($index))'.")
    }

    return $parsed
}
