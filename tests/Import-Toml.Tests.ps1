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

Describe 'Toml' {
    Describe 'Import-Toml' {
        BeforeAll {
            . (Join-Path $PSScriptRoot 'bootstrap.ps1')
            $testDataDir = Join-Path $PSScriptRoot 'data'
        }

        Context 'Import-Toml - return type' {
            It 'Import-Toml - returns a TomlDocument' {
                $path = Join-Path $testDataDir 'full-example.toml'
                $result = Import-Toml -Path $path
                $result.GetType().Name | Should -Be 'TomlDocument'
            }

            It 'Import-Toml - sets FilePath to resolved absolute path' {
                $path = Join-Path $testDataDir 'full-example.toml'
                $result = Import-Toml -Path $path
                $result.FilePath | Should -Not -BeNullOrEmpty
                [System.IO.Path]::IsPathRooted($result.FilePath) | Should -BeTrue
            }

            It 'Import-Toml - Data property is an OrderedDictionary' {
                $path = Join-Path $testDataDir 'full-example.toml'
                $result = Import-Toml -Path $path
                $result.Data | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }
        }

        Context 'Import-Toml - file content' {
            It 'Import-Toml - reads all keys from full example file' {
                $path = Join-Path $testDataDir 'full-example.toml'
                $result = Import-Toml -Path $path
                $result.Data['title'] | Should -Be 'TOML Example'
                $result.Data['owner']['name'] | Should -Be 'Tom Preston-Werner'
                $result.Data['database']['enabled'] | Should -Be $true
            }

            It 'Import-Toml - reads integer file correctly' {
                $path = Join-Path $testDataDir 'integers.toml'
                $result = Import-Toml -Path $path
                $result.Data['decimal'] | Should -Be 42
                $result.Data['negative'] | Should -Be -17
                $result.Data['hex'] | Should -Be 3735928559  # 0xDEADBEEF as unsigned long
            }

            It 'Import-Toml - reads float file correctly' {
                $path = Join-Path $testDataDir 'floats.toml'
                $result = Import-Toml -Path $path
                ([double]$result.Data['positive'] - 3.1415) | Should -BeLessThan 0.0001
                [double]::IsNaN($result.Data['special_nan']) | Should -BeTrue
            }

            It 'Import-Toml - reads boolean file correctly' {
                $path = Join-Path $testDataDir 'booleans.toml'
                $result = Import-Toml -Path $path
                $result.Data['enabled'] | Should -Be $true
                $result.Data['disabled'] | Should -Be $false
            }

            It 'Import-Toml - reads datetime file correctly' {
                $path = Join-Path $testDataDir 'datetimes.toml'
                $result = Import-Toml -Path $path
                $result.Data['offset_dt_z'] | Should -BeOfType [System.DateTimeOffset]
                $result.Data['local_date'] | Should -BeOfType [System.DateTime]
                $result.Data['local_time'] | Should -BeOfType [System.TimeSpan]
            }

            It 'Import-Toml - reads array file correctly' {
                $path = Join-Path $testDataDir 'arrays.toml'
                $result = Import-Toml -Path $path
                $result.Data['integers'] | Should -HaveCount 3
                $result.Data['empty'] | Should -HaveCount 0
            }

            It 'Import-Toml - reads array-of-tables file correctly' {
                $path = Join-Path $testDataDir 'array-of-tables.toml'
                $result = Import-Toml -Path $path
                $result.Data['products'] | Should -HaveCount 2
                $result.Data['products'][0]['name'] | Should -Be 'Hammer'
            }
        }

        Context 'Import-Toml - pipeline' {
            It 'Import-Toml - accepts path from pipeline' {
                $path = Join-Path $testDataDir 'booleans.toml'
                $result = $path | Import-Toml
                $result.GetType().Name | Should -Be 'TomlDocument'
            }
        }

        Context 'Import-Toml - error handling' {
            It 'Import-Toml - throws when file does not exist' {
                { Import-Toml -Path 'nonexistent-file-that-does-not-exist.toml' } | Should -Throw
            }

            It 'Import-Toml - throws when file contains invalid TOML' {
                $badToml = Join-Path $TestDrive 'bad.toml'
                Set-Content -Path $badToml -Value 'invalid = = "bad"'
                { Import-Toml -Path $badToml } | Should -Throw
            }
        }
    }
}
