function ConvertTo-TomlynTable {
    <#
        .SYNOPSIS
        Converts a PowerShell dictionary or PSCustomObject to a Tomlyn TomlTable.

        .DESCRIPTION
        Iterates the properties/keys of the input and calls ConvertTo-TomlynValue
        recursively for each value. Accepts [hashtable], [ordered],
        [System.Collections.Specialized.OrderedDictionary], and [PSCustomObject].

        .EXAMPLE
        ConvertTo-TomlynTable -Value @{ host = 'localhost'; port = 5432 }

        Returns a [Tomlyn.Model.TomlTable] with two entries.

        .INPUTS
        [object]

        .OUTPUTS
        [Tomlyn.Model.TomlTable]

        .NOTES
        Internal helper. Not exported. No pipeline input.
    #>
    [OutputType([Tomlyn.Model.TomlTable])]
    [CmdletBinding()]
    param(
        # The dictionary or PSCustomObject to convert.
        [Parameter(Mandatory)]
        [object] $Value
    )

    $table = [Tomlyn.Model.TomlTable]::new()

    if ($Value -is [System.Management.Automation.PSCustomObject]) {
        foreach ($prop in $Value.PSObject.Properties) {
            if ($prop.MemberType -notin 'NoteProperty', 'ScriptProperty', 'Property') {
                continue
            }
            $table[$prop.Name] = ConvertTo-TomlynValue -Value $prop.Value
        }
    } elseif ($Value -is [System.Collections.IDictionary]) {
        foreach ($key in $Value.Keys) {
            $table[$key.ToString()] = ConvertTo-TomlynValue -Value $Value[$key]
        }
    } else {
        throw [System.InvalidOperationException]::new(
            "Cannot convert '$($Value.GetType().FullName)' to a TOML table. " +
            'Provide a [hashtable], [ordered], or [PSCustomObject].'
        )
    }

    # Wrap in array to prevent PowerShell from enumerating TomlTable (which implements IEnumerable)
    return , $table
}
