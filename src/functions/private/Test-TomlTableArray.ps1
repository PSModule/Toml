function Test-TomlTableArray {
    <#
        .SYNOPSIS
        Tests whether a value is an array of TOML tables.
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object] $Value
    )

    if ($null -eq $Value) {
        return $false
    }

    if ($Value -is [string]) {
        return $false
    }

    if ($Value -is [System.Collections.IDictionary]) {
        return $false
    }

    if ($Value -isnot [System.Collections.IEnumerable]) {
        return $false
    }

    $hasAny = $false
    foreach ($item in $Value) {
        $hasAny = $true
        if ($item -isnot [System.Collections.Specialized.OrderedDictionary]) {
            return $false
        }
    }

    return $hasAny
}
