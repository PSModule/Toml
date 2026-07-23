function ConvertFrom-TomlDateTime {
    <#
        .SYNOPSIS
        Converts a TOML date/time token to a PowerShell date/time value.

        .DESCRIPTION
        Parses TOML local date, local time, local date-time, and offset date-time
        tokens and returns the corresponding PowerShell type.
    #>
    [OutputType([System.DateTimeOffset], [System.DateTime], [System.TimeSpan])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $Token
    )

    $value = $Token.Trim()
    $culture = [System.Globalization.CultureInfo]::InvariantCulture
    $dateStyles = [System.Globalization.DateTimeStyles]::None

    if ($value -match '^\d{4}-\d{2}-\d{2}[Tt ]\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+\-]\d{2}:\d{2})$') {
        $normalized = $value -replace '^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2})', '$1T$2'
        $dto = [System.DateTimeOffset]::Parse($normalized, $culture, $dateStyles)
        return $dto
    }

    if ($value -match '^\d{4}-\d{2}-\d{2}[Tt ]\d{2}:\d{2}:\d{2}(?:\.\d+)?$') {
        $normalized = $value -replace '^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2})', '$1T$2'
        $dt = [System.DateTime]::Parse($normalized, $culture, $dateStyles)
        return [System.DateTime]::SpecifyKind($dt, [System.DateTimeKind]::Unspecified)
    }

    if ($value -match '^\d{4}-\d{2}-\d{2}$') {
        $dt = [System.DateTime]::ParseExact($value, 'yyyy-MM-dd', $culture, $dateStyles)
        return [System.DateTime]::SpecifyKind($dt, [System.DateTimeKind]::Unspecified)
    }

    if ($value -match '^\d{2}:\d{2}:\d{2}(?:\.\d+)?$') {
        return [System.TimeSpan]::Parse($value, $culture)
    }

    throw [System.InvalidOperationException]::new("Invalid TOML date/time token: '$Token'.")
}
