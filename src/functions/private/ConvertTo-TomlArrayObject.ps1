function ConvertTo-TomlArrayObject {
    <#
        .SYNOPSIS
        Normalizes a PowerShell enumerable to a TOML-compatible array.

        .DESCRIPTION
        Iterates each item of the enumerable and passes it through
        ConvertTo-TomlTableObject so that dictionaries, PSCustomObjects, and
        nested arrays are each normalized recursively. Returns an object array.

        .EXAMPLE
        ConvertTo-TomlArrayObject -Value @(1, 'two', $true)
        # Returns: @(1, "two", $true)
        Normalizes a mixed scalar array.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [object[]]
    #>
    [OutputType([object[]])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.IEnumerable] $Value
    )

    $items = [System.Collections.Generic.List[object]]::new()
    foreach ($item in $Value) {
        $items.Add((ConvertTo-TomlTableObject -Value $item))
    }

    return , $items.ToArray()
}
