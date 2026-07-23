function ConvertTo-Toml {
    <#
        .SYNOPSIS
        Converts a PowerShell object graph to TOML text.
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [object] $InputObject
    )

    process {
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
