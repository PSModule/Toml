# Toml

Toml is a PowerShell module for reading TOML file content from disk so scripts can load and process configuration text.

## Installation

Install the module from the PowerShell Gallery:

```powershell
Install-PSResource -Name Toml
Import-Module -Name Toml
```

## Capabilities

Use this command to read TOML content from a file path:

```powershell
Get-Toml -Path '.\settings.toml'
```

## Documentation

Documentation is published at [psmodule.io/Toml](https://psmodule.io/Toml/).

Use PowerShell help and command discovery for details:

```powershell
Get-Command -Module Toml
Get-Help -Name Get-Toml -Examples
```
