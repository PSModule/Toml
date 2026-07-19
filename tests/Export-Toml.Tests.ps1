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
    BeforeAll {
        . (Join-Path $PSScriptRoot 'bootstrap.ps1')
    }

    Describe 'Export-Toml' {

        Context 'Export-Toml - basic write' {
            It 'Export-Toml - creates a file at the given path' {
                $path = Join-Path $TestDrive 'output.toml'
                Export-Toml -InputObject ([ordered]@{ key = 'value' }) -Path $path
                Test-Path -Path $path | Should -BeTrue
            }

            It 'Export-Toml - file content is valid TOML' {
                $path = Join-Path $TestDrive 'output.toml'
                Export-Toml -InputObject ([ordered]@{ title = 'Hello' }) -Path $path
                $content = Get-Content -Path $path -Raw
                $content | Should -Match 'title = "Hello"'
            }

            It 'Export-Toml - returns nothing to the output stream' {
                $path = Join-Path $TestDrive 'void.toml'
                $result = Export-Toml -InputObject ([ordered]@{ k = 'v' }) -Path $path
                $result | Should -BeNullOrEmpty
            }

            It 'Export-Toml - creates parent directory when it does not exist' {
                $path = Join-Path $TestDrive 'nested\subdir\output.toml'
                Export-Toml -InputObject ([ordered]@{ k = 'v' }) -Path $path
                Test-Path -Path $path | Should -BeTrue
            }
        }

        Context 'Export-Toml - round-trip via Import-Toml' {
            It 'Export-Toml - round-trip preserves string values' {
                $inputDoc = [ordered]@{ greeting = 'Hello World' }
                $path = Join-Path $TestDrive 'rt-string.toml'
                Export-Toml -InputObject $inputDoc -Path $path
                $result = Import-Toml -Path $path
                $result.Data['greeting'] | Should -Be 'Hello World'
            }

            It 'Export-Toml - round-trip preserves integer values' {
                $inputDoc = [ordered]@{ count = [long]42 }
                $path = Join-Path $TestDrive 'rt-int.toml'
                Export-Toml -InputObject $inputDoc -Path $path
                $result = Import-Toml -Path $path
                $result.Data['count'] | Should -Be 42
            }

            It 'Export-Toml - round-trip preserves boolean values' {
                $inputDoc = [ordered]@{ enabled = $true; disabled = $false }
                $path = Join-Path $TestDrive 'rt-bool.toml'
                Export-Toml -InputObject $inputDoc -Path $path
                $result = Import-Toml -Path $path
                $result.Data['enabled'] | Should -Be $true
                $result.Data['disabled'] | Should -Be $false
            }

            It 'Export-Toml - round-trip preserves float values' {
                $inputDoc = [ordered]@{ pi = 3.14159 }
                $path = Join-Path $TestDrive 'rt-float.toml'
                Export-Toml -InputObject $inputDoc -Path $path
                $result = Import-Toml -Path $path
                ([double]$result.Data['pi'] - 3.14159) | Should -BeLessThan 0.00001
            }

            It 'Export-Toml - round-trip preserves nested tables' {
                $inputDoc = [ordered]@{
                    server = [ordered]@{ host = 'localhost'; port = [long]8080 }
                }
                $path = Join-Path $TestDrive 'rt-nested.toml'
                Export-Toml -InputObject $inputDoc -Path $path
                $result = Import-Toml -Path $path
                $result.Data['server']['host'] | Should -Be 'localhost'
                $result.Data['server']['port'] | Should -Be 8080
            }

            It 'Export-Toml - round-trip preserves integer arrays' {
                $inputDoc = [ordered]@{ ports = @([long]80, [long]443) }
                $path = Join-Path $TestDrive 'rt-array.toml'
                Export-Toml -InputObject $inputDoc -Path $path
                $result = Import-Toml -Path $path
                $result.Data['ports'] | Should -HaveCount 2
                $result.Data['ports'][0] | Should -Be 80
            }

            It 'Export-Toml - full file round-trip' {
                $srcPath = Join-Path $PSScriptRoot 'data\full-example.toml'
                $original = Import-Toml -Path $srcPath

                $outPath = Join-Path $TestDrive 'rt-full.toml'
                Export-Toml -InputObject $original -Path $outPath

                $rt = Import-Toml -Path $outPath
                $rt.Data['title'] | Should -Be 'TOML Example'
                $rt.Data['owner']['name'] | Should -Be 'Tom Preston-Werner'
                $rt.Data['database']['enabled'] | Should -Be $true
                $rt.Data['servers']['alpha']['ip'] | Should -Be '10.0.0.1'
            }
        }

        Context 'Export-Toml - UTF-8 encoding' {
            It 'Export-Toml - writes UTF-8 without BOM' {
                $path = Join-Path $TestDrive 'utf8.toml'
                Export-Toml -InputObject ([ordered]@{ key = 'αβγ' }) -Path $path
                $bytes = [System.IO.File]::ReadAllBytes($path)
                # UTF-8 BOM is EF BB BF — should not be present
                if ($bytes.Length -ge 3) {
                    ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) | Should -BeFalse
                }
            }

            It 'Export-Toml - round-trips Unicode string content correctly' {
                $path = Join-Path $TestDrive 'unicode.toml'
                Export-Toml -InputObject ([ordered]@{ msg = 'こんにちは' }) -Path $path
                $result = Import-Toml -Path $path
                $result.Data['msg'] | Should -Be 'こんにちは'
            }
        }

        Context 'Export-Toml - pipeline input' {
            It 'Export-Toml - accepts TomlDocument from pipeline' {
                $srcPath = Join-Path $PSScriptRoot 'data\booleans.toml'
                $outPath = Join-Path $TestDrive 'from-pipeline.toml'
                Import-Toml -Path $srcPath | Export-Toml -Path $outPath
                Test-Path $outPath | Should -BeTrue
                $rt = Import-Toml -Path $outPath
                $rt.Data['enabled'] | Should -Be $true
            }
        }

        Context 'Export-Toml - WhatIf support' {
            It 'Export-Toml - WhatIf does not create file' {
                $path = Join-Path $TestDrive 'whatif.toml'
                Export-Toml -InputObject ([ordered]@{ k = 'v' }) -Path $path -WhatIf
                Test-Path -Path $path | Should -BeFalse
            }
        }

        Context 'Export-Toml - error handling' {
            It 'Export-Toml - throws on null InputObject' {
                $path = Join-Path $TestDrive 'null.toml'
                { Export-Toml -InputObject $null -Path $path } | Should -Throw
            }
        }
    }
}
