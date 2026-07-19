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

# ── copy assemblies ──────────────────────────────────────────────────────────
$assembliesSrc = Join-Path $srcPath 'assemblies'
$assembliesDst = Join-Path $outputPath 'assemblies'
$null = New-Item -ItemType Directory -Path $assembliesDst -Force
Copy-Item -Path (Join-Path $assembliesSrc '*.dll') -Destination $assembliesDst -ErrorAction SilentlyContinue

# ── build psm1 ───────────────────────────────────────────────────────────────
$psm1Path = Join-Path $outputPath "$moduleName.psm1"
$sb = [System.Text.StringBuilder]::new()

# header
$headerPath = Join-Path $srcPath 'header.ps1'
if (Test-Path $headerPath) {
    $null = $sb.AppendLine((Get-Content $headerPath -Raw))
}

# init — emit a corrected version that uses the assembled module's own PSScriptRoot
# The source init uses '../assemblies/Tomlyn.dll' relative to src/init/.
# In the built module, assemblies live next to the psm1, so we rewrite the path.
$initContent = @'
$assemblyPath = Join-Path -Path $PSScriptRoot -ChildPath 'assemblies\Tomlyn.dll'
$resolvedPath = [System.IO.Path]::GetFullPath($assemblyPath)

if (-not [System.AppDomain]::CurrentDomain.GetAssemblies().Where({ $_.GetName().Name -eq 'Tomlyn' })) {
    [System.Reflection.Assembly]::LoadFrom($resolvedPath) | Out-Null
    Write-Verbose "Loaded Tomlyn assembly from: $resolvedPath"
}
'@
$null = $sb.AppendLine($initContent)

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
    PowerShellVersion = '7.2'
    Description       = 'PowerShell module for reading and writing TOML data.'
    Author            = 'PSModule'
    CompanyName       = 'PSModule'
    GUID              = '6f1b6f8d-1234-4321-abcd-ef0123456789'
}
New-ModuleManifest @manifest

Write-Host "Built $moduleName $ModuleVersion -> $outputPath"
Write-Host "Public functions: $($publicFunctions -join ', ')"
