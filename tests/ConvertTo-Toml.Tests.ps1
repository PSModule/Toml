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

    Describe 'ConvertTo-Toml' {

        Context 'ConvertTo-Toml - return type' {
            It 'ConvertTo-Toml - returns a string' {
                $result = ConvertTo-Toml -InputObject ([ordered]@{ key = 'value' })
                $result | Should -BeOfType [string]
            }

            It 'ConvertTo-Toml - result is non-empty for non-empty input' {
                $result = ConvertTo-Toml -InputObject ([ordered]@{ key = 'value' })
                $result | Should -Not -BeNullOrEmpty
            }

            It 'ConvertTo-Toml - accepts pipeline input' {
                $result = [ordered]@{ key = 'value' } | ConvertTo-Toml
                $result | Should -BeOfType [string]
            }
        }

        Context 'ConvertTo-Toml - string serialization' {
            It 'ConvertTo-Toml - serializes a simple string key' {
                $result = ConvertTo-Toml -InputObject ([ordered]@{ title = 'Hello' })
                $result | Should -Match 'title = "Hello"'
            }

            It 'ConvertTo-Toml - output is valid TOML that round-trips' {
                $original = [ordered]@{ key = 'value' }
                $toml = ConvertTo-Toml -InputObject $original
                $roundTrip = ConvertFrom-Toml -InputObject $toml
                $roundTrip.Data['key'] | Should -Be 'value'
            }
        }

        Context 'ConvertTo-Toml - integer serialization' {
            It 'ConvertTo-Toml - serializes integer' {
                $result = ConvertTo-Toml -InputObject ([ordered]@{ n = [long]42 })
                $result | Should -Match 'n = 42'
            }

            It 'ConvertTo-Toml - integer round-trips correctly' {
                $original = [ordered]@{ n = [long]12345 }
                $toml = ConvertTo-Toml -InputObject $original
                $rt = ConvertFrom-Toml -InputObject $toml
                $rt.Data['n'] | Should -Be 12345
            }
        }

        Context 'ConvertTo-Toml - float serialization' {
            It 'ConvertTo-Toml - serializes float' {
                $result = ConvertTo-Toml -InputObject ([ordered]@{ pi = 3.14 })
                $result | Should -Match 'pi = '
                $result | Should -Match '3.14'
            }

            It 'ConvertTo-Toml - float round-trips correctly' {
                $original = [ordered]@{ n = 2.718 }
                $toml = ConvertTo-Toml -InputObject $original
                $rt = ConvertFrom-Toml -InputObject $toml
                ([double]$rt.Data['n'] - 2.718) | Should -BeLessThan 0.001
            }
        }

        Context 'ConvertTo-Toml - boolean serialization' {
            It 'ConvertTo-Toml - serializes true' {
                $result = ConvertTo-Toml -InputObject ([ordered]@{ flag = $true })
                $result | Should -Match 'flag = true'
            }

            It 'ConvertTo-Toml - serializes false' {
                $result = ConvertTo-Toml -InputObject ([ordered]@{ flag = $false })
                $result | Should -Match 'flag = false'
            }
        }

        Context 'ConvertTo-Toml - datetime serialization' {
            It 'ConvertTo-Toml - serializes DateTimeOffset as offset datetime' {
                $dto = [System.DateTimeOffset]::new(1979, 5, 27, 7, 32, 0, [System.TimeSpan]::Zero)
                $result = ConvertTo-Toml -InputObject ([ordered]@{ dt = $dto })
                $result | Should -Match '1979-05-27'
            }

            It 'ConvertTo-Toml - DateTimeOffset round-trips' {
                $dto = [System.DateTimeOffset]::new(2024, 3, 15, 12, 0, 0, [System.TimeSpan]::FromHours(2))
                $original = [ordered]@{ dt = $dto }
                $toml = ConvertTo-Toml -InputObject $original
                $rt = ConvertFrom-Toml -InputObject $toml
                $rt.Data['dt'] | Should -BeOfType [System.DateTimeOffset]
                ([System.DateTimeOffset]$rt.Data['dt']).Year | Should -Be 2024
            }

            It 'ConvertTo-Toml - serializes DateTime with time as local datetime' {
                $dt = [System.DateTime]::new(2024, 6, 1, 15, 30, 0, [System.DateTimeKind]::Unspecified)
                $result = ConvertTo-Toml -InputObject ([ordered]@{ dt = $dt })
                $result | Should -Match '2024-06-01'
            }

            It 'ConvertTo-Toml - serializes date-only DateTime as local date' {
                $dt = [System.DateTime]::new(2024, 6, 1, 0, 0, 0, [System.DateTimeKind]::Unspecified)
                $result = ConvertTo-Toml -InputObject ([ordered]@{ dt = $dt })
                $result | Should -Match '2024-06-01'
            }

            It 'ConvertTo-Toml - serializes TimeSpan as local time' {
                $ts = [System.TimeSpan]::new(0, 8, 30, 0)
                $result = ConvertTo-Toml -InputObject ([ordered]@{ tm = $ts })
                $result | Should -Match '08:30:00'
            }
        }

        Context 'ConvertTo-Toml - nested table serialization' {
            It 'ConvertTo-Toml - serializes nested ordered dict as TOML table' {
                $obj = [ordered]@{
                    server = [ordered]@{ host = 'localhost'; port = [long]8080 }
                }
                $result = ConvertTo-Toml -InputObject $obj
                $result | Should -Match '\[server\]'
                $result | Should -Match 'host = "localhost"'
            }

            It 'ConvertTo-Toml - nested table round-trips' {
                $original = [ordered]@{
                    database = [ordered]@{ host = 'db.example.com'; port = [long]5432 }
                }
                $toml = ConvertTo-Toml -InputObject $original
                $rt = ConvertFrom-Toml -InputObject $toml
                $rt.Data['database']['host'] | Should -Be 'db.example.com'
                $rt.Data['database']['port'] | Should -Be 5432
            }
        }

        Context 'ConvertTo-Toml - array serialization' {
            It 'ConvertTo-Toml - serializes array of integers' {
                $obj = [ordered]@{ ports = @([long]80, [long]443, [long]8080) }
                $result = ConvertTo-Toml -InputObject $obj
                $result | Should -Match '80'
                $result | Should -Match '443'
            }

            It 'ConvertTo-Toml - integer array round-trips' {
                $original = [ordered]@{ nums = @([long]1, [long]2, [long]3) }
                $toml = ConvertTo-Toml -InputObject $original
                $rt = ConvertFrom-Toml -InputObject $toml
                $rt.Data['nums'] | Should -HaveCount 3
                $rt.Data['nums'][0] | Should -Be 1
            }
        }

        Context 'ConvertTo-Toml - PSCustomObject input' {
            It 'ConvertTo-Toml - serializes PSCustomObject' {
                $obj = [PSCustomObject]@{ name = 'Alice'; age = [long]30 }
                $result = ConvertTo-Toml -InputObject $obj
                $result | Should -Match 'name = "Alice"'
                $result | Should -Match 'age = 30'
            }
        }

        Context 'ConvertTo-Toml - TomlDocument input' {
            It 'ConvertTo-Toml - accepts TomlDocument from ConvertFrom-Toml' {
                $toml = "title = `"Test`"`n[section]`nvalue = 42"
                $doc = ConvertFrom-Toml -InputObject $toml
                $result = ConvertTo-Toml -InputObject $doc
                $result | Should -Match 'title = "Test"'
                $result | Should -Match '\[section\]'
            }
        }

        Context 'ConvertTo-Toml - round-trip' {
            It 'ConvertTo-Toml - full example round-trips losslessly for string/integer/boolean/float' {
                $path = Join-Path $PSScriptRoot 'data\full-example.toml'
                $original = ConvertFrom-Toml -InputObject (Get-Content $path -Raw)
                $toml = ConvertTo-Toml -InputObject $original
                $rt = ConvertFrom-Toml -InputObject $toml
                $rt.Data['title'] | Should -Be 'TOML Example'
                $rt.Data['owner']['name'] | Should -Be 'Tom Preston-Werner'
                $rt.Data['database']['enabled'] | Should -Be $true
                $rt.Data['database']['ports'] | Should -HaveCount 3
                $rt.Data['servers']['alpha']['ip'] | Should -Be '10.0.0.1'
            }

            It 'ConvertTo-Toml - array of integers round-trips' {
                $path = Join-Path $PSScriptRoot 'data\arrays.toml'
                $original = ConvertFrom-Toml -InputObject (Get-Content $path -Raw)
                $toml = ConvertTo-Toml -InputObject $original
                $rt = ConvertFrom-Toml -InputObject $toml
                $rt.Data['integers'] | Should -HaveCount 3
                $rt.Data['strings'] | Should -HaveCount 3
            }
        }

        Context 'ConvertTo-Toml - error handling' {
            It 'ConvertTo-Toml - throws on null input' {
                { ConvertTo-Toml -InputObject $null } | Should -Throw
            }
        }
    }
}
