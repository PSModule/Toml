function Add-TomlTableText {
    <#
        .SYNOPSIS
        Appends TOML text for a table to a string builder.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Text.StringBuilder] $StringBuilder,

        [Parameter(Mandatory)]
        [System.Collections.Specialized.OrderedDictionary] $Table,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Path,

        [Parameter(Mandatory)]
        [bool] $EmitHeader
    )

    if ($EmitHeader -and -not [string]::IsNullOrEmpty($Path)) {
        if ($StringBuilder.Length -gt 0 -and -not (Test-TomlEndsWithDoubleNewLine -StringBuilder $StringBuilder)) {
            $null = $StringBuilder.AppendLine()
        }
        $null = $StringBuilder.AppendLine("[$Path]")
    }

    foreach ($key in $Table.Keys) {
        $value = $Table[$key]
        if ($value -is [System.Collections.Specialized.OrderedDictionary]) {
            continue
        }
        if (Test-TomlTableArray -Value $value) {
            continue
        }
        $null = $StringBuilder.AppendLine("$(Format-TomlKey -Key $key) = $(ConvertTo-TomlValue -Value $value)")
    }

    foreach ($key in $Table.Keys) {
        $value = $Table[$key]
        if ($value -isnot [System.Collections.Specialized.OrderedDictionary]) {
            continue
        }

        $childPath = if ([string]::IsNullOrEmpty($Path)) {
            Format-TomlKey -Key $key
        } else {
            "$Path.$(Format-TomlKey -Key $key)"
        }
        Add-TomlTableText -StringBuilder $StringBuilder -Table $value -Path $childPath -EmitHeader:$true
    }

    foreach ($key in $Table.Keys) {
        $value = $Table[$key]
        if (-not (Test-TomlTableArray -Value $value)) {
            continue
        }

        $arrayPath = if ([string]::IsNullOrEmpty($Path)) {
            Format-TomlKey -Key $key
        } else {
            "$Path.$(Format-TomlKey -Key $key)"
        }

        foreach ($item in $value) {
            if ($StringBuilder.Length -gt 0 -and -not (Test-TomlEndsWithDoubleNewLine -StringBuilder $StringBuilder)) {
                $null = $StringBuilder.AppendLine()
            }
            $null = $StringBuilder.AppendLine("[[$arrayPath]]")
            Add-TomlTableText -StringBuilder $StringBuilder -Table $item -Path $arrayPath -EmitHeader:$false
        }
    }
}
