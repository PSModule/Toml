function ConvertTo-TomlynValue {
    <#
        .SYNOPSIS
        Converts a PowerShell value to the appropriate Tomlyn model object.

        .DESCRIPTION
        Maps PowerShell types to Tomlyn model objects used by TomlSerializer:
        - [System.DateTimeOffset]                   -> Tomlyn.TomlDateTime (OffsetDateTimeByNumber)
        - [System.DateTime]  (date-only = midnight) -> Tomlyn.TomlDateTime (LocalDate)
        - [System.DateTime]  (has time component)   -> Tomlyn.TomlDateTime (LocalDateTime)
        - [System.TimeSpan]                         -> Tomlyn.TomlDateTime (LocalTime)
        - [hashtable] / [OrderedDictionary] / [PSCustomObject] / [PSObject] -> TomlTable
        - [array] / [List] / [IEnumerable]          -> TomlArray
        - [bool]                                    -> bool
        - [int16/32/64] / [byte] / [sbyte]          -> long
        - [single/double]                           -> double
        - [string]                                  -> string
        - everything else                           -> string via ToString()

        .EXAMPLE
        ConvertTo-TomlynValue -Value 42
        Returns [long] 42.

        .EXAMPLE
        ConvertTo-TomlynValue -Value @{ key = 'val' }
        Returns a [Tomlyn.Model.TomlTable].

        .INPUTS
        [object]

        .OUTPUTS
        [object]

        .NOTES
        Internal helper. Not exported. No pipeline input.
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param(
        # The PowerShell value to convert.
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Value
    )

    if ($null -eq $Value) {
        throw [System.ArgumentNullException]::new(
            'Value',
            'TOML does not support null values. Remove the key or supply a valid value.'
        )
    }

    # Unwrap PSObject wrapper
    if ($Value -is [System.Management.Automation.PSObject] -and
        $Value -isnot [System.Management.Automation.PSCustomObject]) {
        $Value = $Value.BaseObject
    }

    if ($Value -is [System.DateTimeOffset]) {
        return [Tomlyn.TomlDateTime]::new(
            $Value,
            0,
            [Tomlyn.TomlDateTimeKind]::OffsetDateTimeByNumber
        )
    }

    if ($Value -is [System.DateTime]) {
        if ($Value.TimeOfDay -eq [System.TimeSpan]::Zero) {
            # Date-only: use the (year, month, day) constructor for LocalDate
            return [Tomlyn.TomlDateTime]::new($Value.Year, $Value.Month, $Value.Day)
        } else {
            # Date + time: use (DateTime) constructor for LocalDateTime
            return [Tomlyn.TomlDateTime]::new(
                [System.DateTime]::SpecifyKind($Value, [System.DateTimeKind]::Unspecified)
            )
        }
    }

    if ($Value -is [System.TimeSpan]) {
        # LocalTime — build a DateTimeOffset on epoch with the time component
        $dto = [System.DateTimeOffset]::new(
            1970, 1, 1,
            $Value.Hours, $Value.Minutes, $Value.Seconds,
            [System.TimeSpan]::Zero
        )
        return [Tomlyn.TomlDateTime]::new($dto, 0, [Tomlyn.TomlDateTimeKind]::LocalTime)
    }

    if ($Value -is [bool]) {
        return $Value
    }

    if ($Value -is [System.Int16] -or
        $Value -is [System.Int32] -or
        $Value -is [System.Int64] -or
        $Value -is [System.Byte] -or
        $Value -is [System.SByte] -or
        $Value -is [System.UInt16] -or
        $Value -is [System.UInt32] -or
        $Value -is [System.UInt64]) {
        return [long]$Value
    }

    if ($Value -is [System.Single] -or $Value -is [System.Double]) {
        return [double]$Value
    }

    if ($Value -is [string]) {
        return $Value
    }

    if ($Value -is [System.Collections.IDictionary] -or
        $Value -is [System.Management.Automation.PSCustomObject]) {
        $subTable = ConvertTo-TomlynTable -Value $Value
        # Use , to prevent PowerShell from iterating the TomlTable (IEnumerable) in the pipeline
        return , $subTable
    }

    # Array and list types
    if ($Value -is [System.Collections.IEnumerable]) {
        $subArray = ConvertTo-TomlynArray -Value $Value
        # Use , to prevent PowerShell from iterating the TomlArray (IEnumerable) in the pipeline
        return , $subArray
    }

    # Fallback: stringify
    return $Value.ToString()
}
