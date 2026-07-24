function ConvertFrom-TomlTable {
    <#
        .SYNOPSIS
        Parses a TOML document string into an ordered dictionary.

        .DESCRIPTION
        Processes TOML line-by-line: strips comments, handles standard table headers
        ([...]), array-of-table headers ([[...]]), multi-line values (""", ''', [, {),
        and dotted key assignments. Returns the root ordered dictionary preserving
        key insertion order. Validates against duplicate keys and structural conflicts.

        .EXAMPLE
        ConvertFrom-TomlTable -InputObject "title = `"Test`"`n[server]`nport = 80"
        # Returns: OrderedDictionary { title = "Test", server = { port = 80 } }
        Parses a minimal two-key TOML document.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [System.Collections.Specialized.OrderedDictionary]
    #>
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $InputObject
    )

    $root = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)
    $currentTable = $root
    $definedHeaders = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $arrayLastTableByPath = @{}

    $text = $InputObject -replace "`r`n", "`n" -replace "`r", "`n"
    $lines = $text -split "`n"

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $rawLine = $lines[$i]
        $line = (Get-TomlContentWithoutComment -Line $rawLine).Trim()
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        if ($line.StartsWith('[[') -and $line.EndsWith(']]')) {
            $header = $line.Substring(2, $line.Length - 4).Trim()
            $pathSegments = Split-TomlDottedKey -KeyPath $header
            if ($pathSegments.Count -eq 0) {
                throw [System.InvalidOperationException]::new('Invalid array-of-tables header.')
            }

                # Clear headers from sub-tables of any previous entry in this same array,
                # so that each [[arr]] entry may independently define [arr.sub] headers.
                $aoKeyPath = Join-TomlKeyPath -Segments $pathSegments
                $toRemove = $definedHeaders | Where-Object { $_ -eq $aoKeyPath -or $_.StartsWith("$aoKeyPath.") }
                foreach ($h in @($toRemove)) {
                    $null = $definedHeaders.Remove($h)
                }

            $parentSegments = if ($pathSegments.Count -gt 1) { $pathSegments[0..($pathSegments.Count - 2)] } else { @() }
            $name = $pathSegments[-1]
            $parent = Get-TomlNestedTable -StartTable $root -Segments $parentSegments -ArrayLastTableByPath $arrayLastTableByPath

            if (-not $parent.Contains($name)) {
                $parent[$name] = [System.Collections.ArrayList]::new()
            } elseif ($parent[$name] -isnot [System.Collections.ArrayList]) {
                throw [System.InvalidOperationException]::new("Cannot redefine '$header' as array-of-tables.")
            }

            $entry = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)
            $null = $parent[$name].Add($entry)
            $currentTable = $entry
            $arrayLastTableByPath[(Join-TomlKeyPath -Segments $pathSegments)] = $entry
            continue
        }

        if ($line.StartsWith('[') -and $line.EndsWith(']')) {
            $header = $line.Substring(1, $line.Length - 2).Trim()
            $pathSegments = Split-TomlDottedKey -KeyPath $header
            $headerPath = Join-TomlKeyPath -Segments $pathSegments
            if ($definedHeaders.Contains($headerPath)) {
                throw [System.InvalidOperationException]::new("The key '$headerPath' is already defined and cannot be redefined.")
            }
            $null = $definedHeaders.Add($headerPath)

            $parentSegments = if ($pathSegments.Count -gt 1) { $pathSegments[0..($pathSegments.Count - 2)] } else { @() }
            $name = $pathSegments[-1]
            $parent = Get-TomlNestedTable -StartTable $root -Segments $parentSegments -ArrayLastTableByPath $arrayLastTableByPath

            if ($parent.Contains($name)) {
                if ($parent[$name] -is [System.Collections.Specialized.OrderedDictionary]) {
                    throw [System.InvalidOperationException]::new("The key '$headerPath' is already defined and cannot be redefined.")
                }
                throw [System.InvalidOperationException]::new("Cannot define table '$headerPath' because the key already exists as a non-table.")
            }

            $parent[$name] = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)
            $currentTable = $parent[$name]
            continue
        }

        $eqIndex = $line.IndexOf('=')
        if ($eqIndex -lt 1) {
            throw [System.InvalidOperationException]::new("Invalid TOML assignment on line $($i + 1): '$rawLine'.")
        }

        $keyPath = $line.Substring(0, $eqIndex).Trim()
        $valueText = $line.Substring($eqIndex + 1).Trim()
        if ($valueText.Length -eq 0) {
            throw [System.InvalidOperationException]::new("Missing value for key '$keyPath' on line $($i + 1).")
        }

        if ($valueText.StartsWith('"""') -and
            ($valueText.Length -lt 6 -or -not $valueText.Substring(3).Contains('"""'))) {
            $collector = [System.Text.StringBuilder]::new()
            $null = $collector.Append($valueText)
            while ($i -lt ($lines.Count - 1)) {
                $i++
                $next = $lines[$i]
                $null = $collector.Append("`n")
                $null = $collector.Append($next)
                if ($next.Contains('"""')) {
                    break
                }
            }
            $valueText = $collector.ToString()
        } elseif ($valueText.StartsWith("'''") -and
            ($valueText.Length -lt 6 -or -not $valueText.Substring(3).Contains("'''"))) {
            $collector = [System.Text.StringBuilder]::new()
            $null = $collector.Append($valueText)
            while ($i -lt ($lines.Count - 1)) {
                $i++
                $next = $lines[$i]
                $null = $collector.Append("`n")
                $null = $collector.Append($next)
                if ($next.Contains("'''")) {
                    break
                }
            }
            $valueText = $collector.ToString()
        } elseif (($valueText.StartsWith('[') -and -not $valueText.EndsWith(']')) -or
            ($valueText.StartsWith('{') -and -not $valueText.EndsWith('}'))) {
            $collector = [System.Text.StringBuilder]::new()
            $null = $collector.Append($valueText)
            while ($i -lt ($lines.Count - 1)) {
                $i++
                $next = (Get-TomlContentWithoutComment -Line $lines[$i]).Trim()
                if ($next.Length -eq 0) {
                    continue
                }
                $null = $collector.Append(' ')
                $null = $collector.Append($next)
                if ($valueText.StartsWith('[') -and $collector.ToString().Trim().EndsWith(']')) { break }
                if ($valueText.StartsWith('{') -and $collector.ToString().Trim().EndsWith('}')) { break }
            }
            $valueText = $collector.ToString()
        }

        $keySegments = Split-TomlDottedKey -KeyPath $keyPath
        $target = $currentTable
        for ($s = 0; $s -lt ($keySegments.Count - 1); $s++) {
            $segment = $keySegments[$s]
            if (-not $target.Contains($segment)) {
                $target[$segment] = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)
            }
            if ($target[$segment] -isnot [System.Collections.Specialized.OrderedDictionary]) {
                throw [System.InvalidOperationException]::new("Cannot define dotted key '$keyPath' because '$segment' is not a table.")
            }
            $target = $target[$segment]
        }

        $leafKey = $keySegments[-1]
        if ($target.Contains($leafKey)) {
            throw [System.InvalidOperationException]::new("The key '$keyPath' is already defined and cannot be redefined.")
        }

        if ($valueText.Trim() -eq '[]') {
            $target[$leafKey] = @()
        } else {
            $target[$leafKey] = ConvertFrom-TomlValue -Value $valueText
        }
    }

    return $root
}
