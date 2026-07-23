function Get-TomlContentWithoutComment {
    <#
        .SYNOPSIS
        Removes TOML inline comments while preserving quoted text.
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
