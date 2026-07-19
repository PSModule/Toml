function Export-Toml {
    <#
        .SYNOPSIS
        Serializes an object graph to a TOML file.

        .DESCRIPTION
        Converts the input object to a TOML string using ConvertTo-Toml and
        writes it to the specified file path. Intermediate directories are
        created when they do not exist.

        The file is written in UTF-8 encoding without a BOM, which is the
        recommended encoding for TOML files.

        .EXAMPLE
        $config = [ordered]@{
            title  = 'My App'
            server = [ordered]@{ host = 'localhost'; port = 8080 }
        }
        Export-Toml -InputObject $config -Path 'config.toml'

        Writes a TOML file with a string key and a nested table.

        .EXAMPLE
        Import-Toml 'input.toml' | Export-Toml -Path 'output.toml'

        Round-trips a TOML file: parse then re-serialize.

        .INPUTS
        [object] — pipeline input supported.

        .OUTPUTS
        [void] — nothing is written to the output stream.

        .NOTES
        Throws when:
        - the object graph contains null values (TOML has no null)
        - the object graph contains types that cannot be serialized to TOML
        - the file cannot be created or written
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # The object to serialize. Accepts TomlDocument, hashtable,
        # ordered dictionary, or PSCustomObject.
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [object] $InputObject,

        # Destination file path. Created (including parent directories) if absent.
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string] $Path
    )

    process {
        $tomlString = ConvertTo-Toml -InputObject $InputObject

        $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        $parent = [System.IO.Path]::GetDirectoryName($resolvedPath)

        if (-not [System.IO.Directory]::Exists($parent)) {
            $null = [System.IO.Directory]::CreateDirectory($parent)
        }

        if ($PSCmdlet.ShouldProcess($resolvedPath, 'Write TOML file')) {
            [System.IO.File]::WriteAllText(
                $resolvedPath,
                $tomlString,
                [System.Text.UTF8Encoding]::new($false)  # UTF-8 without BOM
            )
        }
    }
}
