function Merge-TomlTableObject {
    <#
        .SYNOPSIS
        Recursively merges two TOML table dictionaries.

        .DESCRIPTION
        Walks every key in the override dictionary and combines it with the base
        dictionary. Keys missing from the base are added as-is. Nested tables
        (OrderedDictionary) are merged recursively. Arrays of tables (ArrayList of
        OrderedDictionary) are concatenated, base entries first. Any other
        overlapping key — scalar or inline array — is resolved with the given
        merge strategy: LastWins keeps the override value, FirstWins keeps the
        base value, and ErrorOnConflict throws.

        .EXAMPLE
        $base = [ordered]@{ a = 1; server = [ordered]@{ host = 'localhost' } }
        $override = [ordered]@{ b = 2; server = [ordered]@{ port = 80 } }
        Merge-TomlTableObject -Base $base -Override $override -Strategy 'LastWins'
        # Returns: OrderedDictionary { a = 1, server = { host = 'localhost', port = 80 }, b = 2 }

        Deep-merges a nested table while preserving keys unique to each side.

        .EXAMPLE
        $base = [ordered]@{ key = 'base' }
        $override = [ordered]@{ key = 'override' }
        Merge-TomlTableObject -Base $base -Override $override -Strategy 'ErrorOnConflict'
        # Throws because 'key' is defined on both sides.

        Demonstrates conflict detection for duplicate scalar keys.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [System.Collections.Specialized.OrderedDictionary]
    #>
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    [CmdletBinding()]
    param(
        # The base table. Its keys are preserved unless overridden.
        [Parameter(Mandatory)]
        [System.Collections.Specialized.OrderedDictionary] $Base,

        # The override table applied on top of the base.
        [Parameter(Mandatory)]
        [System.Collections.Specialized.OrderedDictionary] $Override,

        # The strategy used to resolve scalar key conflicts.
        [Parameter(Mandatory)]
        [ValidateSet('LastWins', 'FirstWins', 'ErrorOnConflict')]
        [string] $Strategy
    )

    $result = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)
    foreach ($key in $Base.Keys) {
        $result[$key] = $Base[$key]
    }

    foreach ($key in $Override.Keys) {
        if (-not $result.Contains($key)) {
            Write-Verbose "Adding override-only key '$key'."
            $result[$key] = $Override[$key]
            continue
        }

        $baseValue = $result[$key]
        $overrideValue = $Override[$key]

        if ($baseValue -is [System.Collections.Specialized.OrderedDictionary] -and
            $overrideValue -is [System.Collections.Specialized.OrderedDictionary]) {
            Write-Verbose "Deep-merging nested table for key '$key'."
            $result[$key] = Merge-TomlTableObject -Base $baseValue -Override $overrideValue -Strategy $Strategy
            continue
        }

        if ($baseValue -is [System.Collections.ArrayList] -and $overrideValue -is [System.Collections.ArrayList]) {
            Write-Verbose "Concatenating array-of-tables for key '$key'."
            $combined = [System.Collections.ArrayList]::new($baseValue)
            $null = $combined.AddRange($overrideValue)
            $result[$key] = $combined
            continue
        }

        switch ($Strategy) {
            'LastWins' {
                Write-Verbose "Resolving scalar conflict for key '$key' using LastWins."
                $result[$key] = $overrideValue
            }
            'FirstWins' {
                Write-Verbose "Resolving scalar conflict for key '$key' using FirstWins."
            }
            'ErrorOnConflict' {
                throw [System.InvalidOperationException]::new(
                    "The key '$key' is defined in both documents and the merge strategy is 'ErrorOnConflict'."
                )
            }
        }
    }

    return $result
}
