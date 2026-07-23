function ConvertFrom-Toml {
    <#
        .SYNOPSIS
        Converts TOML text to a TomlDocument.

        .DESCRIPTION
        Parses TOML-formatted text into a TomlDocument object with OrderedDictionary
        semantics and TOML-compatible scalar mappings.
    #>
    [OutputType([TomlDocument])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $InputObject
    )

    process {
        try {
            $data = ConvertFrom-TomlTable -InputObject $InputObject
            return [TomlDocument]::new($data)
        } catch {
            throw [System.InvalidOperationException]::new(
                "Failed to parse TOML: $($_.Exception.Message)",
                $_.Exception
            )
        }
    }
}
