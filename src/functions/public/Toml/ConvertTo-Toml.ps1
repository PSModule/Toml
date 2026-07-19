function ConvertTo-Toml {
    <#
        .SYNOPSIS
        Converts a PowerShell object graph to a TOML string.

        .DESCRIPTION
        Serializes a [TomlDocument], [hashtable], [ordered] dictionary, or
        [PSCustomObject] into a TOML-formatted string using the Tomlyn library.

        Accepted input types and their TOML encoding:
        - [string]                    -> TOML String
        - [bool]                      -> TOML Boolean (true / false)
        - [int16/32/64] / [byte]      -> TOML Integer
        - [single] / [double]         -> TOML Float
        - [System.DateTimeOffset]     -> TOML Offset date-time
        - [System.DateTime]  (no time component) -> TOML Local date
        - [System.DateTime]  (has time)          -> TOML Local date-time
        - [System.TimeSpan]           -> TOML Local time
        - [hashtable] / [ordered] / [PSCustomObject] -> TOML Table
        - [array] / [List<T>] / IEnumerable       -> TOML Array
        - [TomlDocument]              -> TOML document from .Data

        Null values are not supported by TOML and cause a terminating error.

        .EXAMPLE
        ConvertTo-Toml -InputObject ([ordered]@{
            title = 'Config'
            server = [ordered]@{ host = 'localhost'; port = 8080 }
        })

        Produces:
        title = "Config"
        [server]
        host = "localhost"
        port = 8080

        .EXAMPLE
        $doc = ConvertFrom-Toml -InputObject $tomlString
        ConvertTo-Toml -InputObject $doc

        Round-trips a parsed TOML document back to a TOML string.

        .INPUTS
        [object]

        .OUTPUTS
        [string]

        .NOTES
        The output format follows Tomlyn's default serialization, which produces
        valid TOML 1.0.0. Key order is preserved when the input is an [ordered]
        dictionary or [TomlDocument].
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The object to serialize to TOML. Accepts TomlDocument, hashtable,
        # ordered dictionary, or PSCustomObject.
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [object] $InputObject
    )

    process {
        # Unwrap TomlDocument to its data dict
        $source = if ($InputObject -is [TomlDocument]) {
            $InputObject.Data
        } else {
            $InputObject
        }

        $tomlTable = $null
        try {
            $tomlTable = ConvertTo-TomlynTable -Value $source
        } catch [System.ArgumentNullException] {
            throw [System.InvalidOperationException]::new(
                "Cannot serialize object: $($_.Exception.Message)",
                $_.Exception
            )
        } catch {
            throw [System.InvalidOperationException]::new(
                "Failed to build TOML model: $($_.Exception.Message)",
                $_.Exception
            )
        }

        $opts = [Tomlyn.TomlSerializerOptions]::new()
        try {
            [Tomlyn.TomlSerializer]::Serialize[Tomlyn.Model.TomlTable]($tomlTable, $opts)
        } catch {
            throw [System.InvalidOperationException]::new(
                "Failed to serialize TOML: $($_.Exception.Message)",
                $_.Exception
            )
        }
    }
}
