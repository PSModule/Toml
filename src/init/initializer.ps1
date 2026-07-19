$assemblyPath = Join-Path -Path $PSScriptRoot -ChildPath '..\assemblies\Tomlyn.dll'
$resolvedPath = [System.IO.Path]::GetFullPath($assemblyPath)

if (-not [System.AppDomain]::CurrentDomain.GetAssemblies().Where({ $_.GetName().Name -eq 'Tomlyn' })) {
    [System.Reflection.Assembly]::LoadFrom($resolvedPath) | Out-Null
    Write-Verbose "Loaded Tomlyn assembly from: $resolvedPath"
}
