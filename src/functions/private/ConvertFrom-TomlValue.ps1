function ConvertFrom-TomlValue {
    <#
        .SYNOPSIS
        Converts a TOML value token to a native PowerShell value.

        .DESCRIPTION
        Entry point for full value parsing. Trims the token, delegates to
        ConvertFrom-TomlParsedValue via a char-level index, and validates that
        no trailing content remains after the value.

        .EXAMPLE
        ConvertFrom-TomlValue -Value '"hello world"'
        # Returns: "hello world"
        Parses a basic string token.

        .EXAMPLE
        ConvertFrom-TomlValue -Value '[1, 2, 3]'
        # Returns: @(1, 2, 3)
        Parses an inline array.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [object] — type depends on the TOML value.
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
