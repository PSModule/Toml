function Split-TomlDottedKey {
    <#
        .SYNOPSIS
        Splits a TOML dotted key into normalized key segments.

        .DESCRIPTION
        Tokenizes a TOML key path respecting basic-string ("...") and literal-string
        ('...') quoting, so dots inside quoted segments are not treated as separators.
        Quoted segments are decoded (basic) or used as-is (literal). Bare segments are
        returned unchanged. Throws for empty segments.

        .EXAMPLE
        Split-TomlDottedKey -KeyPath 'a.b.c'
        # Returns: @('a', 'b', 'c')
        Splits a simple dotted key.

        .EXAMPLE
        Split-TomlDottedKey -KeyPath '"my.key".sub'
        # Returns: @('my.key', 'sub')
        Dot inside a quoted segment is treated as literal.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [string[]]
    #>
    [OutputType([string[]])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $KeyPath
    )

    $segments = [System.Collections.Generic.List[string]]::new()
    $sb = [System.Text.StringBuilder]::new()
    $inBasic = $false
    $inLiteral = $false
    $escape = $false

    for ($i = 0; $i -lt $KeyPath.Length; $i++) {
        $ch = $KeyPath[$i]
        if ($escape) {
            $null = $sb.Append($ch)
            $escape = $false
            continue
        }

        if ($inBasic) {
            $null = $sb.Append($ch)
            if ($ch -eq '\') {
                $escape = $true
            } elseif ($ch -eq '"') {
                $inBasic = $false
            }
            continue
        }

        if ($inLiteral) {
            $null = $sb.Append($ch)
            if ($ch -eq '''') {
                $inLiteral = $false
            }
            continue
        }

        if ($ch -eq '"') {
            $inBasic = $true
            $null = $sb.Append($ch)
            continue
        }
        if ($ch -eq '''') {
            $inLiteral = $true
            $null = $sb.Append($ch)
            continue
        }

        if ($ch -eq '.') {
            $segments.Add($sb.ToString().Trim())
            $null = $sb.Clear()
            continue
        }

        $null = $sb.Append($ch)
    }

    $segments.Add($sb.ToString().Trim())
    $normalized = [System.Collections.Generic.List[string]]::new()
    foreach ($segment in $segments) {
        if ($segment.Length -eq 0) {
            throw [System.InvalidOperationException]::new("Invalid dotted key path '$KeyPath'.")
        }

        if ($segment.StartsWith('"') -and $segment.EndsWith('"')) {
            $normalized.Add((ConvertFrom-TomlValue -Value $segment))
            continue
        }

        if ($segment.StartsWith("'") -and $segment.EndsWith("'")) {
            $normalized.Add((ConvertFrom-TomlValue -Value $segment))
            continue
        }

        $normalized.Add($segment)
    }

    return , $normalized.ToArray()
}
