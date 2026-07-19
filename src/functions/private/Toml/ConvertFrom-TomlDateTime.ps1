function ConvertFrom-TomlDateTime {
    <#
        .SYNOPSIS
        Converts a Tomlyn TomlDateTime to the appropriate PowerShell date/time type.

        .DESCRIPTION
        Maps each TOML date/time variant to the most natural PowerShell type:
        - OffsetDateTimeByZ / OffsetDateTimeByNumber -> [System.DateTimeOffset]
        - LocalDateTime                              -> [System.DateTime] (Unspecified Kind)
        - LocalDate                                  -> [System.DateTime] (date only, 00:00:00)
        - LocalTime                                  -> [System.TimeSpan] (time of day)

        .EXAMPLE
        ConvertFrom-TomlDateTime -TomlDt $tomlDateTimeValue

        Returns a [DateTimeOffset], [DateTime], or [TimeSpan] depending on kind.

        .INPUTS
        [Tomlyn.TomlDateTime]

        .OUTPUTS
        [object] — [System.DateTimeOffset], [System.DateTime], or [System.TimeSpan]

        .NOTES
        Internal helper. Not exported. No pipeline input.
    #>
    [OutputType([System.DateTimeOffset], [System.DateTime], [System.TimeSpan])]
    [CmdletBinding()]
    param(
        # The Tomlyn TomlDateTime to convert.
        [Parameter(Mandatory)]
        [Tomlyn.TomlDateTime] $TomlDt
    )

    switch ($TomlDt.Kind) {
        ([Tomlyn.TomlDateTimeKind]::OffsetDateTimeByZ) {
            return $TomlDt.DateTime
        }
        ([Tomlyn.TomlDateTimeKind]::OffsetDateTimeByNumber) {
            return $TomlDt.DateTime
        }
        ([Tomlyn.TomlDateTimeKind]::LocalDateTime) {
            # Strip offset — keep year/month/day/hour/minute/second as-is
            $utc = $TomlDt.DateTime.DateTime
            return [System.DateTime]::SpecifyKind($utc, [System.DateTimeKind]::Unspecified)
        }
        ([Tomlyn.TomlDateTimeKind]::LocalDate) {
            $utc = $TomlDt.DateTime.Date
            return [System.DateTime]::SpecifyKind($utc, [System.DateTimeKind]::Unspecified)
        }
        ([Tomlyn.TomlDateTimeKind]::LocalTime) {
            return $TomlDt.DateTime.TimeOfDay
        }
        default {
            # Fallback: return DateTimeOffset
            return $TomlDt.DateTime
        }
    }
}
