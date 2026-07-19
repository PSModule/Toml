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
        . (Join-Path -Path $PSScriptRoot -ChildPath '..\src\functions\public\Get-Toml.ps1')
    }

    It 'Function: Get-Toml - Returns raw TOML content from file' {
        $path = Join-Path -Path $TestDrive -ChildPath 'sample.toml'
        $expected = @'
[database]
host = "localhost"
port = 5432
'@

        Set-Content -LiteralPath $path -Value $expected -NoNewline

        Get-Toml -Path $path | Should -BeExactly $expected
    }
}
