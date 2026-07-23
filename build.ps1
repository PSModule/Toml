#!/usr/bin/env pwsh
#Requires -Version 7.0
<#
    .SYNOPSIS
    Builds the Toml module from source into ./output/Toml/.

    .DESCRIPTION
    Assembles all source files (classes, init, private functions, public functions)
    into a single psm1 and creates a manifest, so tests can be run locally without
    the PSModule CI pipeline.
#>
[CmdletBinding()]
param(
    # Version to stamp into the manifest.
    [string] $ModuleVersion = '0.0.1'
)

$ErrorActionPreference = 'Stop'
$moduleName  = 'Toml'
$srcPath     = Join-Path $PSScriptRoot 'src'
$outputPath  = Join-Path $PSScriptRoot 'output' $moduleName

# ── clean / create output directory ─────────────────────────────────────────
if (Test-Path $outputPath) {
    Remove-Item $outputPath -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $outputPath -Force

# ── build psm1 ───────────────────────────────────────────────────────────────
$psm1Path = Join-Path $outputPath "$moduleName.psm1"
$sb = [System.Text.StringBuilder]::new()

# header
$headerPath = Join-Path $srcPath 'header.ps1'
if (Test-Path $headerPath) {
    $null = $sb.AppendLine((Get-Content $headerPath -Raw))
}

# init
foreach ($f in (Get-ChildItem (Join-Path $srcPath 'init') -Filter '*.ps1' -ErrorAction SilentlyContinue)) {
    $null = $sb.AppendLine((Get-Content $f.FullName -Raw))
}

# classes private then public
foreach ($visibility in @('private', 'public')) {
    $classPath = Join-Path $srcPath "classes/$visibility"
    foreach ($f in (Get-ChildItem $classPath -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue)) {
        $null = $sb.AppendLine((Get-Content $f.FullName -Raw))
    }
}

# private functions
foreach ($f in (Get-ChildItem (Join-Path $srcPath 'functions/private') -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue)) {
    $null = $sb.AppendLine((Get-Content $f.FullName -Raw))
}

# public functions
$publicFunctions = [System.Collections.Generic.List[string]]::new()
foreach ($f in (Get-ChildItem (Join-Path $srcPath 'functions/public') -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue)) {
    $null = $sb.AppendLine((Get-Content $f.FullName -Raw))
    $publicFunctions.Add([System.IO.Path]::GetFileNameWithoutExtension($f.Name))
}

# finally
$finallyPath = Join-Path $srcPath 'finally.ps1'
if (Test-Path $finallyPath) {
    $null = $sb.AppendLine((Get-Content $finallyPath -Raw))
}

# Export-ModuleMember
$null = $sb.AppendLine("Export-ModuleMember -Function @($($publicFunctions | ForEach-Object { "'$_'" } | Join-String -Separator ', '))")

[System.IO.File]::WriteAllText($psm1Path, $sb.ToString(), [System.Text.UTF8Encoding]::new($false))

# ── write manifest ────────────────────────────────────────────────────────────
$psd1Path = Join-Path $outputPath "$moduleName.psd1"
$manifest = @{
    Path              = $psd1Path
    ModuleVersion     = $ModuleVersion
    RootModule        = "$moduleName.psm1"
    FunctionsToExport = $publicFunctions.ToArray()
    PowerShellVersion = '7.6'
    Description       = 'PowerShell module for reading and writing TOML data.'
    Author            = 'PSModule'
    CompanyName       = 'PSModule'
    GUID              = '6f1b6f8d-1234-4321-abcd-ef0123456789'
}
New-ModuleManifest @manifest

Write-Host "Built $moduleName $ModuleVersion -> $outputPath"
Write-Host "Public functions: $($publicFunctions -join ', ')"
