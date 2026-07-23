function ConvertTo-TomlArrayObject {
    <#
        .SYNOPSIS
        Normalizes a PowerShell enumerable to a TOML-compatible array.
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
