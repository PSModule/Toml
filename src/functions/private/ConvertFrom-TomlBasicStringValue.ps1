function ConvertFrom-TomlBasicStringValue {
    <#
        .SYNOPSIS
        Parses a TOML basic string at the current source index.

        .DESCRIPTION
        Reads a single-line basic string ("...") or a multi-line basic string ("""...""")
        starting at $Index.Value in $Source. Processes TOML escape sequences (\n, \t,
        \uXXXX, etc.) and advances $Index past the closing delimiter.

        .EXAMPLE
        $src = '"hello\nworld"'; $i = 0
        ConvertFrom-TomlBasicStringValue -Source $src -Index ([ref]$i)
        # Returns: "hello`nworld"
        Parses a single-line basic string with an escape sequence.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [string]
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Source,

        [Parameter(Mandatory)]
        [ref] $Index
    )

    if ($Source.Substring($Index.Value).StartsWith('"""', [System.StringComparison]::Ordinal)) {
        $Index.Value += 3
        $start = $Index.Value
        $end = $Source.IndexOf('"""', $start, [System.StringComparison]::Ordinal)
        if ($end -lt 0) {
            throw [System.InvalidOperationException]::new('Unterminated multi-line basic string.')
        }
        $Index.Value = $end + 3
        return $Source.Substring($start, $end - $start)
    }

    $Index.Value++
    $sb = [System.Text.StringBuilder]::new()
    while ($Index.Value -lt $Source.Length) {
        $ch = $Source[$Index.Value]
        if ($ch -eq '"') {
            $Index.Value++
            return $sb.ToString()
        }

        if ($ch -ne '\') {
            $null = $sb.Append($ch)
            $Index.Value++
            continue
        }

        $Index.Value++
        if ($Index.Value -ge $Source.Length) {
            throw [System.InvalidOperationException]::new('Invalid trailing backslash in TOML string.')
        }
        $esc = $Source[$Index.Value]
        switch ($esc) {
            '"' { $null = $sb.Append('"') }
            '\' { $null = $sb.Append('\') }
            'b' { $null = $sb.Append("`b") }
            't' { $null = $sb.Append("`t") }
            'n' { $null = $sb.Append("`n") }
            'f' { $null = $sb.Append("`f") }
            'r' { $null = $sb.Append("`r") }
            'u' {
                if (($Index.Value + 4) -ge $Source.Length) {
                    throw [System.InvalidOperationException]::new('Invalid \u escape in TOML string.')
                }
                $hex = $Source.Substring($Index.Value + 1, 4)
                $null = $sb.Append([char][Convert]::ToInt32($hex, 16))
                $Index.Value += 4
            }
            default {
                throw [System.InvalidOperationException]::new("Unsupported TOML escape sequence '\$esc'.")
            }
        }
        $Index.Value++
    }

    throw [System.InvalidOperationException]::new('Unterminated TOML basic string.')
}
