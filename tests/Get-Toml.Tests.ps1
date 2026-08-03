#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '6.0.0'; MaximumVersion = '6.*' }

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

Describe 'Get-Toml' {
    It 'Returns raw TOML content from file' {
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
