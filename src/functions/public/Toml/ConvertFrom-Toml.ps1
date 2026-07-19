function ConvertFrom-Toml {
    <#
        .SYNOPSIS
        Converts a TOML string to a TomlDocument object.

        .DESCRIPTION
        Parses a TOML-formatted string using the Tomlyn library and returns a
        TomlDocument whose Data property contains an ordered dictionary of the
        document's key-value pairs. TOML tables become nested ordered dictionaries,
        arrays become object arrays, and TOML scalar types are mapped to PowerShell
        types as follows:

        | TOML type           | PowerShell type          |
        |---------------------|--------------------------|
        | String              | [string]                 |
        | Integer             | [long]                   |
        | Float               | [double]                 |
        | Boolean             | [bool]                   |
        | Offset date-time    | [System.DateTimeOffset]  |
        | Local date-time     | [System.DateTime]        |
        | Local date          | [System.DateTime]        |
        | Local time          | [System.TimeSpan]        |
        | Array               | [object[]]               |
        | Table / Inline table| [ordered] hashtable      |

        Full TOML 1.0.0 specification is supported.

        .EXAMPLE
        $doc = ConvertFrom-Toml -InputObject '[database]
        host = "localhost"
        port = 5432'

        $doc.Data.database.host  # returns 'localhost'
        $doc.Data.database.port  # returns 5432

        Parses a simple TOML document with a table and two keys.

        .EXAMPLE
        $toml = Get-Content 'config.toml' -Raw
        $config = ConvertFrom-Toml -InputObject $toml
        $config.Data.server.timeout

        Reads a TOML file and accesses a nested value.

        .INPUTS
        [string]

        .OUTPUTS
        [TomlDocument]

        .NOTES
        Throws [Tomlyn.TomlException] or [System.InvalidOperationException] on
        invalid TOML input. Error messages include line and column information
        from the Tomlyn parser.
    #>
    [OutputType([TomlDocument])]
    [CmdletBinding()]
    param(
        # The TOML-formatted string to parse. Must be valid TOML 1.0.0.
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string] $InputObject
    )

    process {
        $opts = [Tomlyn.TomlSerializerOptions]::new()
        $tomlTable = $null

        try {
            # SyntaxParser.ParseStrict validates the full document and throws a
            # detailed exception on duplicate keys or table redefinition, which
            # TomlSerializer.Deserialize does not enforce by itself.
            $null = [Tomlyn.Parsing.SyntaxParser]::ParseStrict($InputObject, $opts, $null, $true)
        } catch {
            throw [System.InvalidOperationException]::new(
                "Failed to parse TOML: $($_.Exception.Message)",
                $_.Exception
            )
        }

        try {
            $tomlTable = [Tomlyn.TomlSerializer]::Deserialize[Tomlyn.Model.TomlTable](
                $InputObject,
                $opts
            )
        } catch [Tomlyn.TomlException] {
            throw [System.InvalidOperationException]::new(
                "Failed to parse TOML: $($_.Exception.Message)",
                $_.Exception
            )
        } catch {
            throw [System.InvalidOperationException]::new(
                "Unexpected error parsing TOML: $($_.Exception.Message)",
                $_.Exception
            )
        }

        $data = ConvertFrom-TomlynTable -Table $tomlTable
        [TomlDocument]::new($data)
    }
}
