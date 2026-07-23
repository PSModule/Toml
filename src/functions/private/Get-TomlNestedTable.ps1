function Get-TomlNestedTable {
    <#
        .SYNOPSIS
        Resolves or creates nested table path segments.
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
