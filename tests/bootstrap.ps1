<#
    .SYNOPSIS
    Bootstrap helper for local Pester runs.

    .DESCRIPTION
    Imports the built Toml module from ./output/Toml/ before tests run.
    Call from a BeforeAll block in every test file.
#>
[CmdletBinding()]
param()

$outputManifest = Join-Path $PSScriptRoot '..' 'output' 'Toml' 'Toml.psd1'
if (-not (Test-Path $outputManifest)) {
    throw "Module manifest not found at '$outputManifest'. Run build.ps1 first."
}

Import-Module $outputManifest -Force -ErrorAction Stop
