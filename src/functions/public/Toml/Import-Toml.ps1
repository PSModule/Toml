function Import-Toml {
    <#
        .SYNOPSIS
        Imports and parses a TOML file into a TomlDocument.

        .DESCRIPTION
        Reads the content of a TOML file from disk and parses it using
        ConvertFrom-Toml. The returned TomlDocument includes the resolved
        absolute file path in its FilePath property.

        UTF-8 encoding (with or without BOM) is used when reading the file.

        .EXAMPLE
        $config = Import-Toml -Path 'config.toml'
        $config.Data.database.host

        Reads config.toml and returns a TomlDocument. The nested value is
        accessed via the Data property.

        .EXAMPLE
        Import-Toml -Path 'settings.toml' | ForEach-Object { $_.Data }

        Pipes the document and inspects the data dictionary.

        .INPUTS
        [string] — pipeline input supported for the Path parameter.

        .OUTPUTS
        [TomlDocument]

        .NOTES
        Throws when:
        - the file does not exist
        - the file cannot be read
        - the file content is not valid TOML 1.0.0

        .LINK
        https://psmodule.io/Toml/Functions/Import-Toml
    #>
    [OutputType([TomlDocument])]
    [CmdletBinding()]
    param(
        # Path to the TOML file to import. Accepts relative and absolute paths.
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    process {
        $resolvedPath = Resolve-Path -Path $Path -ErrorAction Stop

        $content = [System.IO.File]::ReadAllText($resolvedPath.ProviderPath)

        $doc = ConvertFrom-Toml -InputObject $content
        $doc.FilePath = $resolvedPath.ProviderPath
        $doc
    }
}
