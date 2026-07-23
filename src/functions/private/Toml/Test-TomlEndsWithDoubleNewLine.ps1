function Test-TomlEndsWithDoubleNewLine {
    <#
        .SYNOPSIS
        Tests whether a StringBuilder ends with two LF characters.
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Text.StringBuilder] $StringBuilder
    )

    if ($StringBuilder.Length -lt 2) {
        return $false
    }

    $last = $StringBuilder[$StringBuilder.Length - 1]
    $prev = $StringBuilder[$StringBuilder.Length - 2]
    return ($prev -eq "`n" -and $last -eq "`n")
}
