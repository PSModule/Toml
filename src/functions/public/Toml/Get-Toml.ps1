function Get-Toml {
    <#
        .SYNOPSIS
        Get TOML content from a file.

        .DESCRIPTION
        Reads a TOML file from disk and returns its raw text content as a single string.

        .EXAMPLE
        Get-Toml -Path '.\settings.toml'
        Returns the TOML content from settings.toml as a string.

        .INPUTS
        [string]

        .OUTPUTS
        [string]

        .NOTES
        This command returns raw TOML text and does not parse TOML into objects.

        .LINK
        https://github.com/PSModule/Toml
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # Path to the TOML file.
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    $resolvedPath = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($Path)
    [System.IO.File]::ReadAllText($resolvedPath)
}
