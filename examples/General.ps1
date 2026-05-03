<#
  .SYNOPSIS
    This is a general example of how to use the Toml module.
#>

# Import the module
Import-Module -Name 'Toml'

# Convert a TOML string to a PowerShell object
$toml = @'
[database]
host = "localhost"
port = 5432
'@
ConvertFrom-Toml -InputObject $toml
