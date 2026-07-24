function Add-TomlTableText {
    <#
        .SYNOPSIS
        Appends TOML text for a table to a string builder.

        .DESCRIPTION
        Recursively emits TOML-formatted assignments for all scalar and sub-table
        keys in the given ordered dictionary. Sub-tables are emitted as [path] headers
        after all scalars; arrays of tables are emitted last as [[path]] sections.

        .EXAMPLE
        $sb = [System.Text.StringBuilder]::new()
        Add-TomlTableText -StringBuilder $sb -Table $root -Path '' -EmitHeader:$false
        Appends all root-level keys to $sb without a section header.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [void]. Content is appended to the StringBuilder passed via -StringBuilder.
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
        [switch] $EmitHeader
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
