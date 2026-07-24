function ConvertFrom-Toml {
    <#
        .SYNOPSIS
        Converts TOML text to a TomlDocument.

        .DESCRIPTION
        Parses TOML-formatted text into a TomlDocument object with OrderedDictionary
        semantics and TOML-compatible scalar mappings.

        Supported scalar types and their PowerShell equivalents:
        - String            → [string]
        - Integer           → [long]
        - Float             → [double]
        - Boolean           → [bool]
        - Offset date-time  → [System.DateTimeOffset]
        - Local date-time   → [System.DateTime] (Kind = Unspecified)
        - Local date        → [System.DateTime] (time = 00:00:00)
        - Local time        → [System.TimeSpan]
        - Array             → [object[]]
        - Table             → [System.Collections.Specialized.OrderedDictionary]

        .EXAMPLE
        $doc = ConvertFrom-Toml -InputObject @'
        [server]
        host = "localhost"
        port = 8080
        '@
        $doc.Data.server.host  # "localhost"

        Parses an inline TOML string and accesses a nested value.

        .EXAMPLE
        'title = "My Doc"' | ConvertFrom-Toml

        Converts a TOML string from the pipeline.

        .INPUTS
        [string]

        .OUTPUTS
        [TomlDocument]

        .NOTES
        Throws [System.InvalidOperationException] for any TOML syntax error,
        duplicate key, or structural violation.

        .LINK
        https://psmodule.io/Toml/Functions/ConvertFrom-Toml
    #>
    [OutputType([TomlDocument])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $InputObject
    )

    process {
        Write-Verbose "Parsing TOML string ($($InputObject.Length) character(s))."
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
