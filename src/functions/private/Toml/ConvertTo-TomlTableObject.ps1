function ConvertTo-TomlTableObject {
    <#
        .SYNOPSIS
        Normalizes input data to TOML-compatible objects.
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object] $Value
    )

    if ($null -eq $Value) {
        throw [System.ArgumentNullException]::new('Value', 'TOML does not support null values.')
    }

    if ($Value -is [System.Collections.Specialized.OrderedDictionary]) {
        $result = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)
        foreach ($key in $Value.Keys) {
            $result[$key] = ConvertTo-TomlTableObject -Value $Value[$key]
        }
        return $result
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $result = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)
        foreach ($key in $Value.Keys) {
            $result[$key.ToString()] = ConvertTo-TomlTableObject -Value $Value[$key]
        }
        return $result
    }

    if ($Value -is [System.Management.Automation.PSCustomObject] -or
        ($Value -is [psobject] -and $Value -isnot [string] -and $Value -isnot [System.Collections.IEnumerable])) {
        $result = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)
        foreach ($prop in $Value.PSObject.Properties) {
            if ($prop.MemberType -notin 'NoteProperty', 'Property', 'ScriptProperty') {
                continue
            }
            $result[$prop.Name] = ConvertTo-TomlTableObject -Value $prop.Value
        }
        return $result
    }

    if ($Value -is [System.Collections.IEnumerable] -and $Value -isnot [string]) {
        return ConvertTo-TomlArrayObject -Value $Value
    }

    return $Value
}
