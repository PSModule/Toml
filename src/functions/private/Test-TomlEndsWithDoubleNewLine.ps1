function Test-TomlEndsWithDoubleNewLine {
    <#
        .SYNOPSIS
        Tests whether a StringBuilder ends with two LF characters.

        .DESCRIPTION
        Inspects the last two characters of the given StringBuilder to determine
        whether the buffer already ends with a blank line (two consecutive LF
        characters). Used by the serializer to avoid inserting extra blank lines
        between sections.

        .EXAMPLE
        $sb = [System.Text.StringBuilder]::new("line1`n`n")
        Test-TomlEndsWithDoubleNewLine -StringBuilder $sb
        # Returns: $true
        Detects a trailing blank line.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [bool]
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
