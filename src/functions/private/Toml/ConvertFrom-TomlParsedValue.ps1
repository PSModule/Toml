function ConvertFrom-TomlParsedValue {
    <#
        .SYNOPSIS
        Parses a TOML value at the current source index.
    #>
    [OutputType([object])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Source,

        [Parameter(Mandatory)]
        [ref] $Index
    )

    Skip-TomlWhitespace -Source $Source -Index $Index
    if ($Index.Value -ge $Source.Length) {
        throw [System.InvalidOperationException]::new('Unexpected end of TOML value.')
    }

    $ch = $Source[$Index.Value]
    if ($ch -eq '"') {
        return ConvertFrom-TomlBasicStringValue -Source $Source -Index $Index
    }
    if ($ch -eq '''') {
        return ConvertFrom-TomlLiteralStringValue -Source $Source -Index $Index
    }

    if ($ch -eq '[') {
        $Index.Value++
        $items = [System.Collections.ArrayList]::new()
        while ($true) {
            Skip-TomlWhitespace -Source $Source -Index $Index
            if ($Index.Value -ge $Source.Length) {
                throw [System.InvalidOperationException]::new('Unterminated TOML array.')
            }
            if ($Source[$Index.Value] -eq ']') {
                $Index.Value++
                break
            }

            $null = $items.Add((ConvertFrom-TomlParsedValue -Source $Source -Index $Index))
            Skip-TomlWhitespace -Source $Source -Index $Index
            if ($Index.Value -lt $Source.Length -and $Source[$Index.Value] -eq ',') {
                $Index.Value++
                continue
            }
            if ($Index.Value -lt $Source.Length -and $Source[$Index.Value] -eq ']') {
                continue
            }
            if ($Index.Value -ge $Source.Length) {
                throw [System.InvalidOperationException]::new('Unterminated TOML array.')
            }
            throw [System.InvalidOperationException]::new('Invalid TOML array separator.')
        }
        return $items.ToArray()
    }

    if ($ch -eq '{') {
        $Index.Value++
        $dict = [System.Collections.Specialized.OrderedDictionary]::new([System.StringComparer]::Ordinal)
        while ($true) {
            Skip-TomlWhitespace -Source $Source -Index $Index
            if ($Index.Value -ge $Source.Length) {
                throw [System.InvalidOperationException]::new('Unterminated TOML inline table.')
            }

            if ($Source[$Index.Value] -eq '}') {
                $Index.Value++
                break
            }

            $key = if ($Source[$Index.Value] -eq '"') {
                ConvertFrom-TomlBasicStringValue -Source $Source -Index $Index
            } elseif ($Source[$Index.Value] -eq '''') {
                ConvertFrom-TomlLiteralStringValue -Source $Source -Index $Index
            } else {
                Get-TomlBareToken -Source $Source -Index $Index -StopAtEquals $true
            }

            Skip-TomlWhitespace -Source $Source -Index $Index
            if ($Index.Value -ge $Source.Length -or $Source[$Index.Value] -ne '=') {
                throw [System.InvalidOperationException]::new("Invalid TOML inline table entry for key '$key'.")
            }
            $Index.Value++

            $dict[$key] = ConvertFrom-TomlParsedValue -Source $Source -Index $Index
            Skip-TomlWhitespace -Source $Source -Index $Index

            if ($Index.Value -lt $Source.Length -and $Source[$Index.Value] -eq ',') {
                $Index.Value++
                continue
            }
            if ($Index.Value -lt $Source.Length -and $Source[$Index.Value] -eq '}') {
                continue
            }
        }
        return $dict
    }

    $token = Get-TomlBareToken -Source $Source -Index $Index
    return ConvertFrom-TomlScalarToken -Token $token
}
