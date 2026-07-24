function Test-TomlTableArray {
    <#
        .SYNOPSIS
        Tests whether a value is an array of TOML tables.

        .DESCRIPTION
        Returns $true when the value is a non-empty IEnumerable (but not a string
        or IDictionary) whose every element is an OrderedDictionary. This is used by
        the serializer to distinguish TOML arrays-of-tables from regular scalar arrays.

        .EXAMPLE
        $aot = [System.Collections.ArrayList]@(
            [ordered]@{ name = 'a' },
            [ordered]@{ name = 'b' }
        )
        Test-TomlTableArray -Value $aot
        # Returns: $true
        A list of ordered dictionaries is an array of tables.

        .EXAMPLE
        Test-TomlTableArray -Value @(1, 2, 3)
        # Returns: $false
        A scalar array is not an array of tables.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [bool]
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
