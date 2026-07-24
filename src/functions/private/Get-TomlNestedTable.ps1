function Get-TomlNestedTable {
    <#
        .SYNOPSIS
        Resolves or creates nested table path segments.

        .DESCRIPTION
        Walks the path segments into the root ordered dictionary, creating
        intermediate tables when absent. When a segment resolves to an
        ArrayList (array-of-tables), the last entry of the array is used
        as the current table context, matching TOML's semantics for nested
        table headers inside [[arr]] blocks.

        .EXAMPLE
        $root = [ordered]@{}
        Get-TomlNestedTable -StartTable $root -Segments @('a', 'b') -ArrayLastTableByPath @{}
        # Returns: the OrderedDictionary at root['a']['b'], creating it if needed.
        Resolves a two-level path, creating intermediate tables.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [System.Collections.Specialized.OrderedDictionary]
    #>
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.Specialized.OrderedDictionary] $StartTable,

        [Parameter()]
        [AllowEmptyCollection()]
        [string[]] $Segments,

        [Parameter(Mandatory)]
        [hashtable] $ArrayLastTableByPath
    )

    $table = $StartTable
    $pathParts = [System.Collections.Generic.List[string]]::new()
    foreach ($segment in $Segments) {
        $pathParts.Add($segment)
        $path = Join-TomlKeyPath -Segments $pathParts.ToArray()

        if (-not $table.Contains($segment)) {
            $table[$segment] = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)
        }

        $candidate = $table[$segment]
        if ($candidate -is [System.Collections.ArrayList]) {
            if ($candidate.Count -eq 0) {
                throw [System.InvalidOperationException]::new("Array-of-tables '$path' has no current item.")
            }
            $table = $candidate[-1]
            $ArrayLastTableByPath[$path] = $table
            continue
        }

        if ($candidate -isnot [System.Collections.Specialized.OrderedDictionary]) {
            throw [System.InvalidOperationException]::new("Cannot define table '$path' because '$segment' is already a non-table value.")
        }

        $table = $candidate
    }

    return $table
}
