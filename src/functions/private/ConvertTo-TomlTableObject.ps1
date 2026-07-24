function ConvertTo-TomlTableObject {
    <#
        .SYNOPSIS
        Normalizes input data to TOML-compatible objects.

        .DESCRIPTION
        Converts any PowerShell value into a form the serializer can handle:
        IDictionary → OrderedDictionary, PSCustomObject → OrderedDictionary,
        IEnumerable (non-string) → object[] via ConvertTo-TomlArrayObject,
        scalars → unchanged. Throws if the value is null.

        .EXAMPLE
        ConvertTo-TomlTableObject -Value @{ a = 1; b = 'two' }
        # Returns: [OrderedDictionary] { a = 1, b = "two" }
        Converts a regular hashtable to an ordered dictionary.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [object] — OrderedDictionary, object[], or the original scalar.
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
