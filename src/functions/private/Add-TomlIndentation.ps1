function Add-TomlIndentation {
    <#
        .SYNOPSIS
        Indents nested TOML table sections by nesting depth.

        .DESCRIPTION
        Re-indents already-serialized TOML text so that table headers and their
        key/value lines are prefixed with spaces proportional to the table's nesting
        depth. Depth is derived from the dotted path in each `[path]` / `[[path]]`
        header — a root table has depth 1, `[a.b]` has depth 2, and so on. Header
        lines are indented one level shallower than the keys they contain, so the
        keys visually nest under their header. Root-level keys (before any header)
        are never indented. TOML is whitespace-insensitive around keys and headers,
        so this is purely a display convention and does not change the parsed value.

        .EXAMPLE
        Add-TomlIndentation -Toml "[a]`nx = 1`n[a.b]`ny = 2" -Indent 2
        # Returns:
        # [a]
        #   x = 1
        #   [a.b]
        #     y = 2

        Indents nested table `[a.b]` and its key two spaces per nesting level.

        .INPUTS
        None. Parameters only.

        .OUTPUTS
        [string]
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The canonical, non-indented TOML text produced by ConvertTo-Toml.
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Toml,

        # Number of spaces to indent per nesting level. 0 disables indentation.
        [Parameter(Mandatory)]
        [ValidateRange(0, 100)]
        [int] $Indent
    )

    if ($Indent -eq 0 -or [string]::IsNullOrEmpty($Toml)) {
        return $Toml
    }

    $lines = $Toml -split "`n"
    $result = [System.Text.StringBuilder]::new()
    $depth = 0

    foreach ($rawLine in $lines) {
        $line = $rawLine.TrimEnd("`r")

        if ($line -match '^\[\[(.+)\]\]$' -or $line -match '^\[(.+)\]$') {
            $path = $Matches[1]
            $depth = (Split-TomlDottedKey -KeyPath $path).Count
            $headerIndent = ' ' * ([Math]::Max(0, $depth - 1) * $Indent)
            $null = $result.AppendLine("$headerIndent$line")
            continue
        }

        if ([string]::IsNullOrWhiteSpace($line)) {
            $null = $result.AppendLine()
            continue
        }

        $lineIndent = ' ' * ($depth * $Indent)
        $null = $result.AppendLine("$lineIndent$line")
    }

    return $result.ToString().TrimEnd()
}
