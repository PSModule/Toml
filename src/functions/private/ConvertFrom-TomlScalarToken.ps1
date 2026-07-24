function ConvertFrom-TomlScalarToken {
    <#
        .SYNOPSIS
        Converts a scalar TOML token to a PowerShell value.

        .DESCRIPTION
        Interprets a bare scalar token string as the correct PowerShell type:
        boolean, special float (inf/nan), datetime, hex/octal/binary/decimal
        integer, or floating-point number. Throws for unrecognized tokens.

        .EXAMPLE
        ConvertFrom-TomlScalarToken -Token 'true'
        # Returns: [bool] $true
        Converts the TOML boolean literal.

        .EXAMPLE
        ConvertFrom-TomlScalarToken -Token '0xFF'
        # Returns: 255 ([long])
        Converts a hexadecimal integer literal.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [object] — bool, double, long, DateTimeOffset, DateTime, or TimeSpan.
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Token
    )

    if ($Token -ceq 'true') { return $true }
    if ($Token -ceq 'false') { return $false }
    if ($Token -ceq 'inf' -or $Token -ceq '+inf') { return [double]::PositiveInfinity }
    if ($Token -ceq '-inf') { return [double]::NegativeInfinity }
    if ($Token -ceq 'nan' -or $Token -ceq '+nan' -or $Token -ceq '-nan') { return [double]::NaN }

    if ($Token -match '^\d{4}-\d{2}-\d{2}(?:[Tt ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+\-]\d{2}:\d{2})?)?$' -or
        $Token -match '^\d{2}:\d{2}:\d{2}(?:\.\d+)?$') {
        return ConvertFrom-TomlDateTime -Token $Token
    }

    if ($Token -match '^[+\-]?0x[0-9A-Fa-f_]+$') {
        $isNegative = $Token.StartsWith('-')
        $hex = $Token.TrimStart('+', '-').Substring(2).Replace('_', '')
        $number = [Convert]::ToUInt64($hex, 16)
        if ($isNegative) { return - ([long]$number) }
        return [long]$number
    }

    if ($Token -match '^[+\-]?0o[0-7_]+$') {
        $isNegative = $Token.StartsWith('-')
        $oct = $Token.TrimStart('+', '-').Substring(2).Replace('_', '')
        $number = [Convert]::ToInt64($oct, 8)
        if ($isNegative) { return - $number }
        return [long]$number
    }

    if ($Token -match '^[+\-]?0b[01_]+$') {
        $isNegative = $Token.StartsWith('-')
        $bin = $Token.TrimStart('+', '-').Substring(2).Replace('_', '')
        $number = [Convert]::ToInt64($bin, 2)
        if ($isNegative) { return - $number }
        return [long]$number
    }

    if ($Token -match '^[+\-]?\d[\d_]*$') {
        return [long]::Parse($Token.Replace('_', ''), [System.Globalization.CultureInfo]::InvariantCulture)
    }

    if ($Token -match '^[+\-]?(?:\d[\d_]*\.\d[\d_]*|\d[\d_]*[eE][+\-]?\d[\d_]*|\d[\d_]*\.\d[\d_]*[eE][+\-]?\d[\d_]*)$') {
        return [double]::Parse($Token.Replace('_', ''), [System.Globalization.CultureInfo]::InvariantCulture)
    }

    throw [System.InvalidOperationException]::new("Unsupported or invalid TOML scalar value: '$Token'.")
}
