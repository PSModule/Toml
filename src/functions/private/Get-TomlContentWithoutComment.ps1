function Get-TomlContentWithoutComment {
    <#
        .SYNOPSIS
        Removes TOML inline comments while preserving quoted text.

        .DESCRIPTION
        Scans a TOML source line character-by-character, tracking basic-string and
        literal-string context to avoid treating # inside a string as a comment
        delimiter. Returns the content up to (but not including) the first unquoted #.

        .EXAMPLE
        Get-TomlContentWithoutComment -Line 'port = 5432 # the DB port'
        # Returns: 'port = 5432 '
        Strips the inline comment from a key-value line.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [string]
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Line
    )

    $sb = [System.Text.StringBuilder]::new()
    $inBasic = $false
    $inLiteral = $false
    $escape = $false
    for ($i = 0; $i -lt $Line.Length; $i++) {
        $ch = $Line[$i]

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

        if ($ch -eq '#') {
            break
        }

        $null = $sb.Append($ch)
    }

    return $sb.ToString()
}
