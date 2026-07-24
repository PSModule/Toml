function ConvertTo-TomlValue {
    <#
        .SYNOPSIS
        Converts a normalized value to a TOML literal.

        .DESCRIPTION
        Serializes a single normalized PowerShell value to its TOML literal
        representation: strings are quoted and escaped, booleans become true/false,
        integers and floats use invariant-culture formatting, date/time types map to
        their TOML forms, arrays become inline [ ... ], and dictionaries become
        inline { ... }. Throws for null or unserializable types.

        .EXAMPLE
        ConvertTo-TomlValue -Value 'hello"world'
        # Returns: '"hello\"world"'
        Serializes a string containing a double quote.

        .EXAMPLE
        ConvertTo-TomlValue -Value ([System.DateTimeOffset]::Parse('1979-05-27T07:32:00Z'))
        # Returns: '1979-05-27T07:32:00+00:00'
        Serializes an offset date-time.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [string]
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Value
    )

    if ($null -eq $Value) {
        throw [System.InvalidOperationException]::new('TOML does not support null values.')
    }

    $culture = [System.Globalization.CultureInfo]::InvariantCulture

    if ($Value -is [string]) {
        $escaped = $Value.Replace('\', '\\').Replace('"', '\"').Replace("`t", '\t').Replace("`r", '\r').Replace("`n", '\n')
        return '"' + $escaped + '"'
    }

    if ($Value -is [bool]) {
        if ($Value) { return 'true' }
        return 'false'
    }

    if ($Value -is [byte] -or $Value -is [sbyte] -or $Value -is [int16] -or
        $Value -is [uint16] -or $Value -is [int32] -or $Value -is [uint32] -or
        $Value -is [int64] -or $Value -is [uint64]) {
        return [string]::Format($culture, '{0}', $Value)
    }

    if ($Value -is [single] -or $Value -is [double] -or $Value -is [decimal]) {
        $d = [double]$Value
        if ([double]::IsNaN($d)) { return 'nan' }
        if ([double]::IsPositiveInfinity($d)) { return 'inf' }
        if ([double]::IsNegativeInfinity($d)) { return '-inf' }
        return $d.ToString('R', $culture)
    }

    if ($Value -is [System.DateTimeOffset]) {
        return $Value.ToString('yyyy-MM-ddTHH:mm:ssK', $culture)
    }

    if ($Value -is [System.DateTime]) {
        $dt = [System.DateTime]::SpecifyKind($Value, [System.DateTimeKind]::Unspecified)
        if ($dt.TimeOfDay -eq [System.TimeSpan]::Zero) {
            return $dt.ToString('yyyy-MM-dd', $culture)
        }
        return $dt.ToString('yyyy-MM-ddTHH:mm:ss', $culture)
    }

    if ($Value -is [System.TimeSpan]) {
        $base = '{0:00}:{1:00}:{2:00}' -f $Value.Hours, $Value.Minutes, $Value.Seconds
        if ($Value.Milliseconds -gt 0) {
            return $base + '.' + $Value.Milliseconds.ToString('000', $culture)
        }
        return $base
    }

    if ($Value -is [object[]]) {
        $parts = [System.Collections.Generic.List[string]]::new()
        foreach ($item in $Value) {
            $parts.Add((ConvertTo-TomlValue -Value $item))
        }
        return '[ ' + ($parts -join ', ') + ' ]'
    }

    if ($Value -is [System.Collections.Specialized.OrderedDictionary]) {
        $parts = [System.Collections.Generic.List[string]]::new()
        foreach ($key in $Value.Keys) {
            $parts.Add("$(Format-TomlKey -Key $key) = $(ConvertTo-TomlValue -Value $Value[$key])")
        }
        return '{ ' + ($parts -join ', ') + ' }'
    }

    throw [System.InvalidOperationException]::new(
        "Cannot serialize value of type '$($Value.GetType().FullName)' to TOML."
    )
}
