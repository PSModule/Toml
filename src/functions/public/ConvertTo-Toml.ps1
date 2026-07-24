function ConvertTo-Toml {
    <#
        .SYNOPSIS
        Converts a PowerShell object graph to TOML text.

        .DESCRIPTION
        Serializes a PowerShell object — TomlDocument, hashtable, ordered dictionary,
        or PSCustomObject — into a TOML string. Nested dictionaries become TOML tables;
        arrays of dictionaries become TOML arrays of tables.

        Supported PowerShell → TOML type mappings:
        - [string]                → basic string (special characters escaped)
        - [bool]                  → true / false
        - Integer types           → TOML integer
        - [double] / [float]      → TOML float (inf, -inf, nan handled)
        - [System.DateTimeOffset] → offset date-time
        - [System.DateTime]       → local date or local date-time
        - [System.TimeSpan]       → local time
        - Scalar [object[]]       → inline TOML array
        - IDictionary             → TOML table
        - Array of IDictionary    → TOML array of tables

        .EXAMPLE
        $toml = ConvertTo-Toml -InputObject ([ordered]@{
            title  = 'My App'
            server = [ordered]@{ host = 'localhost'; port = 8080 }
        })
        Write-Host $toml

        Serializes a nested ordered dictionary to TOML text.

        .EXAMPLE
        Import-Toml -Path 'config.toml' | ConvertTo-Toml

        Round-trips a TOML file back to TOML text.

        .INPUTS
        [object] — pipeline input supported.

        .OUTPUTS
        [string]

        .NOTES
        Throws when the object graph contains null values (TOML has no null type),
        or types that cannot be serialized such as script blocks or COM objects.
        Key order is preserved when the input uses an ordered dictionary.

        .LINK
        https://psmodule.io/Toml/Functions/ConvertTo-Toml
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [object] $InputObject
    )

    process {
        Write-Verbose "Serializing object graph to TOML."
        $source = if ($InputObject -is [TomlDocument]) {
            $InputObject.Data
        } else {
            $InputObject
        }

        $root = ConvertTo-TomlTableObject -Value $source
        if ($root -isnot [System.Collections.Specialized.OrderedDictionary]) {
            throw [System.InvalidOperationException]::new(
                'TOML documents must be dictionaries/objects at the root.'
            )
        }

        $sb = [System.Text.StringBuilder]::new()
        Add-TomlTableText -StringBuilder $sb -Table $root -Path '' -EmitHeader:$false
        return $sb.ToString().TrimEnd()
    }
}
