function ConvertFrom-TomlynValue {
    <#
        .SYNOPSIS
        Converts a Tomlyn model value to a native PowerShell value.

        .DESCRIPTION
        Recursively maps the Tomlyn object model (TomlTable, TomlTableArray,
        TomlArray, TomlDateTime, and scalars) to corresponding PowerShell types:
        - Tomlyn.Model.TomlTable       -> [System.Collections.Specialized.OrderedDictionary]
        - Tomlyn.Model.TomlTableArray  -> [object[]] of [ordered]
        - Tomlyn.Model.TomlArray       -> [object[]]
        - Tomlyn.TomlDateTime          -> [DateTimeOffset], [datetime], or [timespan]
        - string, bool, long, double   -> their PowerShell equivalents

        .EXAMPLE
        $table = [Tomlyn.TomlSerializer]::Deserialize[Tomlyn.Model.TomlTable]($toml, $opts)
        ConvertFrom-TomlynValue -Value $table

        Returns an [ordered] hashtable representing the TOML table.

        .INPUTS
        [object] — any Tomlyn model value.

        .OUTPUTS
        [object]

        .NOTES
        Internal helper. Not exported. No pipeline input.
    #>
    [OutputType(
        [System.Collections.Specialized.OrderedDictionary], [object[]],
        [string], [long], [double], [bool],
        [System.DateTimeOffset], [System.DateTime], [System.TimeSpan]
    )]
    [CmdletBinding()]
    param(
        # The Tomlyn model value to convert.
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Value
    )

    if ($null -eq $Value) {
        return $null
    }

    if ($Value -is [Tomlyn.Model.TomlTableArray]) {
        # Array of tables: [[key]] sections
        $list = [System.Collections.Generic.List[object]]::new()
        foreach ($tableItem in $Value) {
            $list.Add((ConvertFrom-TomlynTable -Table $tableItem))
        }
        return , $list.ToArray()
    }

    if ($Value -is [Tomlyn.Model.TomlTable]) {
        return ConvertFrom-TomlynTable -Table $Value
    }

    if ($Value -is [Tomlyn.Model.TomlArray]) {
        $list = [System.Collections.Generic.List[object]]::new()
        foreach ($item in $Value) {
            $list.Add((ConvertFrom-TomlynValue -Value $item))
        }
        return , $list.ToArray()
    }

    if ($Value -is [Tomlyn.TomlDateTime]) {
        return ConvertFrom-TomlDateTime -TomlDt $Value
    }

    # Scalar: string, bool, long, double — already a native .NET type
    return $Value
}
