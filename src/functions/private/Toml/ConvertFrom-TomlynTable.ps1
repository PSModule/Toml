function ConvertFrom-TomlynTable {
    <#
        .SYNOPSIS
        Converts a Tomlyn TomlTable to an [ordered] hashtable.

        .DESCRIPTION
        Iterates every key-value pair in the Tomlyn model TomlTable and
        calls ConvertFrom-TomlynValue recursively, building an
        [ordered] hashtable that preserves TOML key order.

        .EXAMPLE
        $table = [Tomlyn.TomlSerializer]::Deserialize[Tomlyn.Model.TomlTable]($toml, $opts)
        ConvertFrom-TomlynTable -Table $table

        Returns an [ordered] hashtable of the table's contents.

        .INPUTS
        [Tomlyn.Model.TomlTable]

        .OUTPUTS
        [System.Collections.Specialized.OrderedDictionary]

        .NOTES
        Internal helper. Not exported. No pipeline input.
    #>
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    [CmdletBinding()]
    param(
        # The Tomlyn TomlTable to convert.
        [Parameter(Mandatory)]
        [Tomlyn.Model.TomlTable] $Table
    )

    $dict = [System.Collections.Specialized.OrderedDictionary]::new(
        [System.StringComparer]::Ordinal
    )

    foreach ($kv in $Table) {
        $dict[$kv.Key] = ConvertFrom-TomlynValue -Value $kv.Value
    }

    return $dict
}
