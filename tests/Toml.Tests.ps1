[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSReviewUnusedParameter', '',
    Justification = 'Required for Pester tests'
)]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute(
    'PSUseDeclaredVarsMoreThanAssignments', '',
    Justification = 'Required for Pester tests'
)]
[CmdletBinding()]
param()

Describe 'Module' {
    BeforeAll {
        . (Join-Path $PSScriptRoot 'bootstrap.ps1')
    }

    It 'Module has expected commands' {
        $commands = Get-Command -Module Toml | Select-Object -ExpandProperty Name | Sort-Object
        $commands | Should -Contain 'ConvertFrom-Toml'
        $commands | Should -Contain 'ConvertTo-Toml'
        $commands | Should -Contain 'Import-Toml'
        $commands | Should -Contain 'Export-Toml'
    }
}
