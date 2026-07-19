        function Get-Toml {
            <#
                .SYNOPSIS
                Reads TOML content from a file.

                .DESCRIPTION
                Returns the raw TOML text from the specified file path.

                .EXAMPLE
                Get-Toml -Path '.\settings.toml'
            #>
            [CmdletBinding()]
            param (
                # Path to a TOML file.
                [Parameter(Mandatory)]
                [ValidateNotNullOrEmpty()]
                [string] $Path
            )
            Get-Content -LiteralPath $Path -Raw -ErrorAction Stop
        }
