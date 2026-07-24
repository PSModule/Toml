[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '', Justification = 'Required for Pester tests')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'Required for Pester tests')]
[CmdletBinding()]
param()

Describe 'Toml' {
    BeforeAll {
        $dataDir = Join-Path $PSScriptRoot 'data'
    }

    Context 'Module' {
        It 'exposes the expected public commands' {
            $commands = Get-Command -Module Toml | Select-Object -ExpandProperty Name | Sort-Object
            $commands | Should -Contain 'ConvertFrom-Toml'
            $commands | Should -Contain 'ConvertTo-Toml'
            $commands | Should -Contain 'Import-Toml'
            $commands | Should -Contain 'Export-Toml'
        }
    }

    Describe 'ConvertFrom-Toml' {

        Context 'Return type' {
            It 'returns a TomlDocument for a minimal document' {
                $result = ConvertFrom-Toml -InputObject 'key = "value"'
                $result.GetType().Name | Should -Be 'TomlDocument'
            }

            It 'Data property is an OrderedDictionary' {
                $result = ConvertFrom-Toml -InputObject 'key = "value"'
                $result.Data | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }

            It 'FilePath is null when parsed from string' {
                $result = ConvertFrom-Toml -InputObject 'key = "value"'
                $result.FilePath | Should -BeNullOrEmpty
            }

            It 'accepts pipeline input' {
                $result = 'key = "value"' | ConvertFrom-Toml
                $result.GetType().Name | Should -Be 'TomlDocument'
            }
        }

        Context 'Strings' {
            It 'parses a basic string' {
                $result = ConvertFrom-Toml -InputObject 'key = "hello"'
                $result.Data['key'] | Should -Be 'hello'
            }

            It 'parses a literal string' {
                $result = ConvertFrom-Toml -InputObject "key = 'C:\path'"
                $result.Data['key'] | Should -Be 'C:\path'
            }

            It 'parses escape sequences in a basic string' {
                $result = ConvertFrom-Toml -InputObject 'key = "tab\there"'
                $result.Data['key'] | Should -Be "tab`there"
            }

            It 'parses escaped quotes in a basic string' {
                $result = ConvertFrom-Toml -InputObject 'key = "say \"hi\""'
                $result.Data['key'] | Should -Be 'say "hi"'
            }

            It 'parses a Unicode \uXXXX escape sequence' {
                $result = ConvertFrom-Toml -InputObject 'key = "\u03B1"'
                $result.Data['key'] | Should -Be ([char]0x03B1).ToString()
            }

            It 'parses a multi-line basic string' {
                $toml = "key = `"`"`"`nline one`nline two`n`"`"`""
                $result = ConvertFrom-Toml -InputObject $toml
                $result.Data['key'] | Should -Match 'line one'
                $result.Data['key'] | Should -Match 'line two'
            }

            It 'parses a multi-line literal string' {
                $toml = "key = '''" + [System.Environment]::NewLine + "raw\nno escape" + [System.Environment]::NewLine + "'''"
                $result = ConvertFrom-Toml -InputObject $toml
                $result.Data['key'] | Should -Match 'raw\\nno escape'
            }

            It 'parses an empty string' {
                $result = ConvertFrom-Toml -InputObject 'key = ""'
                $result.Data['key'] | Should -Be ''
            }

            It 'parses strings fixture file' {
                $result = ConvertFrom-Toml -InputObject (Get-Content (Join-Path $dataDir 'strings.toml') -Raw)
                $result.Data['literal'] | Should -Be 'C:\Users\nodejs\templates'
                $result.Data['empty'] | Should -Be ''
            }
        }

        Context 'Integers' {
            It 'parses a decimal integer as [long]' {
                $result = ConvertFrom-Toml -InputObject 'n = 42'
                $result.Data['n'] | Should -Be 42
                $result.Data['n'] | Should -BeOfType [long]
            }

            It 'parses a negative integer' {
                $result = ConvertFrom-Toml -InputObject 'n = -17'
                $result.Data['n'] | Should -Be -17
            }

            It 'parses zero' {
                $result = ConvertFrom-Toml -InputObject 'n = 0'
                $result.Data['n'] | Should -Be 0
            }

            It 'parses an integer with underscore separators' {
                $result = ConvertFrom-Toml -InputObject 'n = 1_000_000'
                $result.Data['n'] | Should -Be 1000000
            }

            It 'parses a hexadecimal integer' {
                $result = ConvertFrom-Toml -InputObject 'n = 0xFF'
                $result.Data['n'] | Should -Be 255
            }

            It 'parses an octal integer' {
                $result = ConvertFrom-Toml -InputObject 'n = 0o17'
                $result.Data['n'] | Should -Be 15
            }

            It 'parses a binary integer' {
                $result = ConvertFrom-Toml -InputObject 'n = 0b1010'
                $result.Data['n'] | Should -Be 10
            }

            It 'parses integers fixture file' {
                $result = ConvertFrom-Toml -InputObject (Get-Content (Join-Path $dataDir 'integers.toml') -Raw)
                $result.Data['decimal'] | Should -Be 42
                $result.Data['negative'] | Should -Be -17
                $result.Data['hex'] | Should -Be 3735928559
                $result.Data['octal'] | Should -Be 493
                $result.Data['binary'] | Should -Be 214
            }
        }

        Context 'Floats' {
            It 'parses a positive float as [double]' {
                $result = ConvertFrom-Toml -InputObject 'n = 3.14'
                $result.Data['n'] | Should -Be 3.14
                $result.Data['n'] | Should -BeOfType [double]
            }

            It 'parses a negative float' {
                $result = ConvertFrom-Toml -InputObject 'n = -0.01'
                $result.Data['n'] | Should -Be -0.01
            }

            It 'parses scientific notation' {
                $result = ConvertFrom-Toml -InputObject 'n = 5e+22'
                $result.Data['n'] | Should -Be 5e22
            }

            It 'parses inf' {
                $result = ConvertFrom-Toml -InputObject 'n = inf'
                $result.Data['n'] | Should -Be ([double]::PositiveInfinity)
            }

            It 'parses -inf' {
                $result = ConvertFrom-Toml -InputObject 'n = -inf'
                $result.Data['n'] | Should -Be ([double]::NegativeInfinity)
            }

            It 'parses nan' {
                $result = ConvertFrom-Toml -InputObject 'n = nan'
                [double]::IsNaN($result.Data['n']) | Should -BeTrue
            }

            It 'parses floats fixture file' {
                $result = ConvertFrom-Toml -InputObject (Get-Content (Join-Path $dataDir 'floats.toml') -Raw)
                ([double]$result.Data['positive'] - 3.1415) | Should -BeLessThan 0.0001
                ([double]$result.Data['negative'] - (-0.01)) | Should -BeLessThan 0.0001
            }
        }

        Context 'Booleans' {
            It 'parses true as [bool]' {
                $result = ConvertFrom-Toml -InputObject 'flag = true'
                $result.Data['flag'] | Should -Be $true
                $result.Data['flag'] | Should -BeOfType [bool]
            }

            It 'parses false as [bool]' {
                $result = ConvertFrom-Toml -InputObject 'flag = false'
                $result.Data['flag'] | Should -Be $false
            }
        }

        Context 'Datetimes' {
            It 'parses an offset datetime with Z suffix as DateTimeOffset' {
                $result = ConvertFrom-Toml -InputObject 'dt = 1979-05-27T07:32:00Z'
                $result.Data['dt'] | Should -BeOfType [System.DateTimeOffset]
                ([System.DateTimeOffset]$result.Data['dt']).Year | Should -Be 1979
                ([System.DateTimeOffset]$result.Data['dt']).Day | Should -Be 27
            }

            It 'parses an offset datetime with +HH:MM offset' {
                $result = ConvertFrom-Toml -InputObject 'dt = 1979-05-27T07:32:00+05:30'
                $result.Data['dt'] | Should -BeOfType [System.DateTimeOffset]
                ([System.DateTimeOffset]$result.Data['dt']).Offset.Hours | Should -Be 5
                ([System.DateTimeOffset]$result.Data['dt']).Offset.Minutes | Should -Be 30
            }

            It 'parses an offset datetime with space separator' {
                $result = ConvertFrom-Toml -InputObject 'dt = 1987-07-05 17:45:00Z'
                $result.Data['dt'] | Should -BeOfType [System.DateTimeOffset]
                ([System.DateTimeOffset]$result.Data['dt']).Year | Should -Be 1987
            }

            It 'parses a local datetime as DateTime with Unspecified kind' {
                $result = ConvertFrom-Toml -InputObject 'dt = 1979-05-27T07:32:00'
                $result.Data['dt'] | Should -BeOfType [System.DateTime]
                ([System.DateTime]$result.Data['dt']).Kind | Should -Be ([System.DateTimeKind]::Unspecified)
            }

            It 'parses a local date as DateTime with zero time' {
                $result = ConvertFrom-Toml -InputObject 'dt = 1979-05-27'
                $result.Data['dt'] | Should -BeOfType [System.DateTime]
                $dt = [System.DateTime]$result.Data['dt']
                $dt.Year | Should -Be 1979
                $dt.Month | Should -Be 5
                $dt.Day | Should -Be 27
                $dt.Hour | Should -Be 0
            }

            It 'parses a local time as TimeSpan' {
                $result = ConvertFrom-Toml -InputObject 'tm = 07:32:00'
                $result.Data['tm'] | Should -BeOfType [System.TimeSpan]
                ([System.TimeSpan]$result.Data['tm']).Hours | Should -Be 7
                ([System.TimeSpan]$result.Data['tm']).Minutes | Should -Be 32
            }

            It 'parses datetimes fixture file' {
                $result = ConvertFrom-Toml -InputObject (Get-Content (Join-Path $dataDir 'datetimes.toml') -Raw)
                $result.Data['offset_dt_z'] | Should -BeOfType [System.DateTimeOffset]
                $result.Data['offset_dt_num'] | Should -BeOfType [System.DateTimeOffset]
                $result.Data['local_dt'] | Should -BeOfType [System.DateTime]
                $result.Data['local_date'] | Should -BeOfType [System.DateTime]
                $result.Data['local_time'] | Should -BeOfType [System.TimeSpan]
            }
        }

        Context 'Arrays' {
            It 'parses an integer array' {
                $result = ConvertFrom-Toml -InputObject 'arr = [1, 2, 3]'
                $result.Data['arr'] | Should -HaveCount 3
                $result.Data['arr'][0] | Should -Be 1
                $result.Data['arr'][2] | Should -Be 3
            }

            It 'parses a string array' {
                $result = ConvertFrom-Toml -InputObject 'arr = ["a", "b", "c"]'
                $result.Data['arr'][0] | Should -Be 'a'
                $result.Data['arr'][1] | Should -Be 'b'
            }

            It 'parses an empty array' {
                $result = ConvertFrom-Toml -InputObject 'arr = []'
                $result.Data['arr'] | Should -HaveCount 0
            }

            It 'parses a nested array' {
                $result = ConvertFrom-Toml -InputObject 'arr = [[1, 2], [3, 4]]'
                $result.Data['arr'] | Should -HaveCount 2
                $result.Data['arr'][0][1] | Should -Be 2
            }

            It 'parses a multiline array' {
                $result = ConvertFrom-Toml -InputObject "arr = [`n  1,`n  2,`n  3,`n]"
                $result.Data['arr'] | Should -HaveCount 3
            }

            It 'parses arrays fixture file' {
                $result = ConvertFrom-Toml -InputObject (Get-Content (Join-Path $dataDir 'arrays.toml') -Raw)
                $result.Data['integers'] | Should -HaveCount 3
                $result.Data['strings'] | Should -HaveCount 3
                $result.Data['empty'] | Should -HaveCount 0
                $result.Data['nested'] | Should -HaveCount 2
            }
        }

        Context 'Tables' {
            It 'parses a standard table' {
                $result = ConvertFrom-Toml -InputObject "[server]`nhost = `"localhost`""
                $result.Data['server'] | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
                $result.Data['server']['host'] | Should -Be 'localhost'
            }

            It 'parses an inline table' {
                $result = ConvertFrom-Toml -InputObject 'point = { x = 1, y = 2 }'
                $result.Data['point']['x'] | Should -Be 1
                $result.Data['point']['y'] | Should -Be 2
            }

            It 'parses deeply nested tables via dotted header' {
                $result = ConvertFrom-Toml -InputObject "[a.b.c]`nkey = `"deep`""
                $result.Data['a']['b']['c']['key'] | Should -Be 'deep'
            }

            It 'parses tables fixture file' {
                $result = ConvertFrom-Toml -InputObject (Get-Content (Join-Path $dataDir 'tables.toml') -Raw)
                $result.Data['simple']['key'] | Should -Be 'value'
                $result.Data['dotted']['key']['works'] | Should -Be $true
                $result.Data['inline_parent']['inline']['one'] | Should -Be 1
            }
        }

        Context 'Array of tables' {
            It 'parses array of tables from fixture file' {
                $result = ConvertFrom-Toml -InputObject (Get-Content (Join-Path $dataDir 'array-of-tables.toml') -Raw)
                $result.Data['products'] | Should -HaveCount 2
                $result.Data['products'][0]['name'] | Should -Be 'Hammer'
                $result.Data['products'][1]['name'] | Should -Be 'Nail'
            }

            It 'parses nested array of tables' {
                $result = ConvertFrom-Toml -InputObject (Get-Content (Join-Path $dataDir 'array-of-tables.toml') -Raw)
                $result.Data['fruits'][0]['varieties'] | Should -HaveCount 2
                $result.Data['fruits'][0]['varieties'][0]['name'] | Should -Be 'red delicious'
            }

            It 'parses sub-tables independently per array entry' {
                $toml = "[[stages]]`nname = `"build`"`n`n  [stages.env]`n  KEY = `"A`"`n`n[[stages]]`nname = `"test`"`n`n  [stages.env]`n  KEY = `"B`""
                $result = ConvertFrom-Toml -InputObject $toml
                $result.Data['stages'][0]['env']['KEY'] | Should -Be 'A'
                $result.Data['stages'][1]['env']['KEY'] | Should -Be 'B'
            }
        }

        Context 'Keys' {
            It 'parses a bare key' {
                $result = ConvertFrom-Toml -InputObject 'bare_key = "value"'
                $result.Data['bare_key'] | Should -Be 'value'
            }

            It 'parses a quoted key with spaces' {
                $result = ConvertFrom-Toml -InputObject '"quoted key" = "value"'
                $result.Data['quoted key'] | Should -Be 'value'
            }

            It 'parses a dotted key into nested tables' {
                $result = ConvertFrom-Toml -InputObject 'a.b = "value"'
                $result.Data['a']['b'] | Should -Be 'value'
            }

            It 'preserves key insertion order' {
                $result = ConvertFrom-Toml -InputObject "z = 1`ny = 2`nx = 3"
                $keys = $result.Data.Keys
                $keys[0] | Should -Be 'z'
                $keys[1] | Should -Be 'y'
                $keys[2] | Should -Be 'x'
            }
        }

        Context 'Comments and whitespace' {
            It 'ignores inline comments' {
                $result = ConvertFrom-Toml -InputObject 'key = "value" # comment'
                $result.Data['key'] | Should -Be 'value'
            }

            It 'ignores full-line comments' {
                $result = ConvertFrom-Toml -InputObject "# comment`nkey = `"value`""
                $result.Data['key'] | Should -Be 'value'
            }

            It 'handles CRLF line endings' {
                $result = ConvertFrom-Toml -InputObject "a = 1`r`nb = 2"
                $result.Data['a'] | Should -Be 1
                $result.Data['b'] | Should -Be 2
            }
        }

        Context 'Full example' {
            It 'parses the full example fixture file' {
                $result = ConvertFrom-Toml -InputObject (Get-Content (Join-Path $dataDir 'full-example.toml') -Raw)
                $result.Data['title'] | Should -Be 'TOML Example'
                $result.Data['owner']['name'] | Should -Be 'Tom Preston-Werner'
                $result.Data['database']['enabled'] | Should -Be $true
                $result.Data['database']['ports'] | Should -HaveCount 3
                $result.Data['servers']['alpha']['ip'] | Should -Be '10.0.0.1'
                $result.Data['servers']['beta']['role'] | Should -Be 'backend'
            }
        }

        Context 'Advanced fixtures' {
            It 'parses ci-pipeline.toml' {
                $result = ConvertFrom-Toml -InputObject (Get-Content (Join-Path $dataDir 'advanced\ci-pipeline.toml') -Raw)
                $result.Data['pipeline']['name'] | Should -Be 'my-app-ci'
                $result.Data['pipeline']['stages'] | Should -HaveCount 3
                $result.Data['pipeline']['stages'][0]['steps'] | Should -HaveCount 2
            }

            It 'parses numbers-and-datetimes.toml' {
                $result = ConvertFrom-Toml -InputObject (Get-Content (Join-Path $dataDir 'advanced\numbers-and-datetimes.toml') -Raw)
                $result.Data['integers']['hex-upper'] | Should -Be 3735928559
                $result.Data['floats']['infinity'] | Should -Be ([double]::PositiveInfinity)
                $result.Data['datetimes']['utc-space-sep'] | Should -BeOfType [System.DateTimeOffset]
                $result.Data['arrays']['deeply-nested'] | Should -HaveCount 2
            }

            It 'parses app-config.toml' {
                $result = ConvertFrom-Toml -InputObject (Get-Content (Join-Path $dataDir 'advanced\app-config.toml') -Raw)
                $result.Data['app']['version'] | Should -Be '2.4.1'
                $result.Data['feature_flag'] | Should -HaveCount 3
                $result.Data['feature_flag'][0]['targeting']['segments'] | Should -Contain 'beta-users'
            }

            It 'parses cargo-manifest.toml' {
                $result = ConvertFrom-Toml -InputObject (Get-Content (Join-Path $dataDir 'advanced\cargo-manifest.toml') -Raw)
                $result.Data['package']['name'] | Should -Be 'my-awesome-lib'
                $result.Data['package']['limits']['max-size-binary'] | Should -Be 1048576
                $result.Data['bench'] | Should -HaveCount 3
            }

            It 'parses database-server.toml' {
                $result = ConvertFrom-Toml -InputObject (Get-Content (Join-Path $dataDir 'advanced\database-server.toml') -Raw)
                $result.Data['cluster']['name'] | Should -Be 'primary-pg-cluster'
                $result.Data['nodes']['replicas'] | Should -HaveCount 2
                $result.Data['nodes']['replicas'][0]['slots'] | Should -HaveCount 2
            }
        }

        Context 'Error handling' {
            It 'throws on invalid TOML syntax' {
                { ConvertFrom-Toml -InputObject 'invalid = = "bad"' } | Should -Throw
            }

            It 'throws on a duplicate key' {
                { ConvertFrom-Toml -InputObject "key = 1`nkey = 2" } | Should -Throw
            }

            It 'throws on a missing value' {
                { ConvertFrom-Toml -InputObject 'key =' } | Should -Throw
            }

            It 'throws on empty string input' {
                { ConvertFrom-Toml -InputObject '' } | Should -Throw
            }

            It 'throws on table redefinition' {
                { ConvertFrom-Toml -InputObject "[a]`nkey = 1`n[a]`nother = 2" } | Should -Throw
            }
        }
    }

    Describe 'ConvertTo-Toml' {

        Context 'Return type' {
            It 'returns a string' {
                $result = ConvertTo-Toml -InputObject ([ordered]@{ key = 'value' })
                $result | Should -BeOfType [string]
            }

            It 'result is non-empty for non-empty input' {
                $result = ConvertTo-Toml -InputObject ([ordered]@{ key = 'value' })
                $result | Should -Not -BeNullOrEmpty
            }

            It 'accepts pipeline input' {
                $result = [ordered]@{ key = 'value' } | ConvertTo-Toml
                $result | Should -BeOfType [string]
            }
        }

        Context 'Scalar serialization' {
            It 'serializes a string value' {
                $result = ConvertTo-Toml -InputObject ([ordered]@{ title = 'Hello' })
                $result | Should -Match 'title = "Hello"'
            }

            It 'serializes an integer value' {
                $result = ConvertTo-Toml -InputObject ([ordered]@{ n = [long]42 })
                $result | Should -Match 'n = 42'
            }

            It 'serializes true and false' {
                ConvertTo-Toml -InputObject ([ordered]@{ flag = $true }) | Should -Match 'flag = true'
                ConvertTo-Toml -InputObject ([ordered]@{ flag = $false }) | Should -Match 'flag = false'
            }

            It 'serializes a float value' {
                $result = ConvertTo-Toml -InputObject ([ordered]@{ pi = 3.14 })
                $result | Should -Match '3\.14'
            }

            It 'serializes a DateTimeOffset' {
                $dto = [System.DateTimeOffset]::new(1979, 5, 27, 7, 32, 0, [System.TimeSpan]::Zero)
                ConvertTo-Toml -InputObject ([ordered]@{ dt = $dto }) | Should -Match '1979-05-27'
            }

            It 'serializes a DateTime (local datetime)' {
                $dt = [System.DateTime]::new(2024, 6, 1, 15, 30, 0, [System.DateTimeKind]::Unspecified)
                ConvertTo-Toml -InputObject ([ordered]@{ dt = $dt }) | Should -Match '2024-06-01'
            }

            It 'serializes a TimeSpan as local time' {
                $ts = [System.TimeSpan]::new(0, 8, 30, 0)
                ConvertTo-Toml -InputObject ([ordered]@{ tm = $ts }) | Should -Match '08:30:00'
            }
        }

        Context 'Nested tables and arrays' {
            It 'serializes a nested ordered dict as a TOML table header' {
                $result = ConvertTo-Toml -InputObject ([ordered]@{
                    server = [ordered]@{ host = 'localhost'; port = [long]8080 }
                })
                $result | Should -Match '\[server\]'
                $result | Should -Match 'host = "localhost"'
            }

            It 'serializes an array of integers' {
                $result = ConvertTo-Toml -InputObject ([ordered]@{ ports = @([long]80, [long]443) })
                $result | Should -Match '80'
                $result | Should -Match '443'
            }

            It 'serializes a PSCustomObject' {
                $result = ConvertTo-Toml -InputObject ([PSCustomObject]@{ name = 'Alice'; age = [long]30 })
                $result | Should -Match 'name = "Alice"'
                $result | Should -Match 'age = 30'
            }

            It 'accepts a TomlDocument as input' {
                $doc = ConvertFrom-Toml -InputObject "title = `"Test`"`n[section]`nvalue = 42"
                $result = ConvertTo-Toml -InputObject $doc
                $result | Should -Match 'title = "Test"'
                $result | Should -Match '\[section\]'
            }
        }

        Context 'Round-trip' {
            It 'string and integer values survive a round-trip' {
                $toml = ConvertTo-Toml -InputObject ([ordered]@{ key = 'value' })
                (ConvertFrom-Toml -InputObject $toml).Data['key'] | Should -Be 'value'
            }

            It 'integer value survives a round-trip' {
                $toml = ConvertTo-Toml -InputObject ([ordered]@{ n = [long]12345 })
                (ConvertFrom-Toml -InputObject $toml).Data['n'] | Should -Be 12345
            }

            It 'float value survives a round-trip' {
                $toml = ConvertTo-Toml -InputObject ([ordered]@{ n = 2.718 })
                ([double](ConvertFrom-Toml -InputObject $toml).Data['n'] - 2.718) | Should -BeLessThan 0.001
            }

            It 'DateTimeOffset survives a round-trip' {
                $dto = [System.DateTimeOffset]::new(2024, 3, 15, 12, 0, 0, [System.TimeSpan]::FromHours(2))
                $toml = ConvertTo-Toml -InputObject ([ordered]@{ dt = $dto })
                $rt = (ConvertFrom-Toml -InputObject $toml).Data['dt']
                $rt | Should -BeOfType [System.DateTimeOffset]
                ([System.DateTimeOffset]$rt).Year | Should -Be 2024
            }

            It 'nested table survives a round-trip' {
                $toml = ConvertTo-Toml -InputObject ([ordered]@{
                    database = [ordered]@{ host = 'db.example.com'; port = [long]5432 }
                })
                $rt = (ConvertFrom-Toml -InputObject $toml).Data
                $rt['database']['host'] | Should -Be 'db.example.com'
                $rt['database']['port'] | Should -Be 5432
            }

            It 'integer array survives a round-trip' {
                $toml = ConvertTo-Toml -InputObject ([ordered]@{ nums = @([long]1, [long]2, [long]3) })
                $rt = (ConvertFrom-Toml -InputObject $toml).Data['nums']
                $rt | Should -HaveCount 3
                $rt[0] | Should -Be 1
            }

            It 'full example fixture file survives a round-trip' {
                $original = ConvertFrom-Toml -InputObject (Get-Content (Join-Path $dataDir 'full-example.toml') -Raw)
                $rt = ConvertFrom-Toml -InputObject (ConvertTo-Toml -InputObject $original)
                $rt.Data['title'] | Should -Be 'TOML Example'
                $rt.Data['owner']['name'] | Should -Be 'Tom Preston-Werner'
                $rt.Data['database']['enabled'] | Should -Be $true
                $rt.Data['database']['ports'] | Should -HaveCount 3
                $rt.Data['servers']['alpha']['ip'] | Should -Be '10.0.0.1'
            }
        }

        Context 'Error handling' {
            It 'throws on null input' {
                { ConvertTo-Toml -InputObject $null } | Should -Throw
            }
        }
    }

    Describe 'Import-Toml' {

        Context 'Return type' {
            It 'returns a TomlDocument' {
                $result = Import-Toml -Path (Join-Path $dataDir 'full-example.toml')
                $result.GetType().Name | Should -Be 'TomlDocument'
            }

            It 'sets FilePath to the resolved absolute path' {
                $result = Import-Toml -Path (Join-Path $dataDir 'full-example.toml')
                $result.FilePath | Should -Not -BeNullOrEmpty
                [System.IO.Path]::IsPathRooted($result.FilePath) | Should -BeTrue
            }

            It 'Data is an OrderedDictionary' {
                $result = Import-Toml -Path (Join-Path $dataDir 'full-example.toml')
                $result.Data | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }
        }

        Context 'File content' {
            It 'reads the full example fixture file' {
                $result = Import-Toml -Path (Join-Path $dataDir 'full-example.toml')
                $result.Data['title'] | Should -Be 'TOML Example'
                $result.Data['owner']['name'] | Should -Be 'Tom Preston-Werner'
                $result.Data['database']['enabled'] | Should -Be $true
            }

            It 'reads integers fixture file' {
                $result = Import-Toml -Path (Join-Path $dataDir 'integers.toml')
                $result.Data['decimal'] | Should -Be 42
                $result.Data['negative'] | Should -Be -17
                $result.Data['hex'] | Should -Be 3735928559
            }

            It 'reads floats fixture file' {
                $result = Import-Toml -Path (Join-Path $dataDir 'floats.toml')
                ([double]$result.Data['positive'] - 3.1415) | Should -BeLessThan 0.0001
                [double]::IsNaN($result.Data['special_nan']) | Should -BeTrue
            }

            It 'reads booleans fixture file' {
                $result = Import-Toml -Path (Join-Path $dataDir 'booleans.toml')
                $result.Data['enabled'] | Should -Be $true
                $result.Data['disabled'] | Should -Be $false
            }

            It 'reads datetimes fixture file' {
                $result = Import-Toml -Path (Join-Path $dataDir 'datetimes.toml')
                $result.Data['offset_dt_z'] | Should -BeOfType [System.DateTimeOffset]
                $result.Data['local_date'] | Should -BeOfType [System.DateTime]
                $result.Data['local_time'] | Should -BeOfType [System.TimeSpan]
            }

            It 'reads arrays fixture file' {
                $result = Import-Toml -Path (Join-Path $dataDir 'arrays.toml')
                $result.Data['integers'] | Should -HaveCount 3
                $result.Data['empty'] | Should -HaveCount 0
            }

            It 'reads array-of-tables fixture file' {
                $result = Import-Toml -Path (Join-Path $dataDir 'array-of-tables.toml')
                $result.Data['products'] | Should -HaveCount 2
                $result.Data['products'][0]['name'] | Should -Be 'Hammer'
            }
        }

        Context 'Pipeline' {
            It 'accepts a path from the pipeline' {
                $result = (Join-Path $dataDir 'booleans.toml') | Import-Toml
                $result.GetType().Name | Should -Be 'TomlDocument'
            }
        }

        Context 'Error handling' {
            It 'throws when the file does not exist' {
                { Import-Toml -Path 'nonexistent-file.toml' } | Should -Throw
            }

            It 'throws when the file contains invalid TOML' {
                $bad = Join-Path $TestDrive 'bad.toml'
                Set-Content -Path $bad -Value 'invalid = = "bad"'
                { Import-Toml -Path $bad } | Should -Throw
            }
        }
    }

    Describe 'Export-Toml' {

        Context 'Basic write' {
            It 'creates a file at the given path' {
                $path = Join-Path $TestDrive 'output.toml'
                Export-Toml -InputObject ([ordered]@{ key = 'value' }) -Path $path
                Test-Path -Path $path | Should -BeTrue
            }

            It 'file content is valid TOML' {
                $path = Join-Path $TestDrive 'content.toml'
                Export-Toml -InputObject ([ordered]@{ title = 'Hello' }) -Path $path
                Get-Content -Path $path -Raw | Should -Match 'title = "Hello"'
            }

            It 'returns nothing to the output stream' {
                $path = Join-Path $TestDrive 'void.toml'
                $result = Export-Toml -InputObject ([ordered]@{ k = 'v' }) -Path $path
                $result | Should -BeNullOrEmpty
            }

            It 'creates parent directories when they do not exist' {
                $path = Join-Path $TestDrive 'nested\subdir\output.toml'
                Export-Toml -InputObject ([ordered]@{ k = 'v' }) -Path $path
                Test-Path -Path $path | Should -BeTrue
            }
        }

        Context 'Round-trip via Import-Toml' {
            It 'preserves string values' {
                $path = Join-Path $TestDrive 'rt-string.toml'
                Export-Toml -InputObject ([ordered]@{ greeting = 'Hello World' }) -Path $path
                (Import-Toml -Path $path).Data['greeting'] | Should -Be 'Hello World'
            }

            It 'preserves integer values' {
                $path = Join-Path $TestDrive 'rt-int.toml'
                Export-Toml -InputObject ([ordered]@{ count = [long]42 }) -Path $path
                (Import-Toml -Path $path).Data['count'] | Should -Be 42
            }

            It 'preserves boolean values' {
                $path = Join-Path $TestDrive 'rt-bool.toml'
                Export-Toml -InputObject ([ordered]@{ enabled = $true; disabled = $false }) -Path $path
                $rt = (Import-Toml -Path $path).Data
                $rt['enabled'] | Should -Be $true
                $rt['disabled'] | Should -Be $false
            }

            It 'preserves float values' {
                $path = Join-Path $TestDrive 'rt-float.toml'
                Export-Toml -InputObject ([ordered]@{ pi = 3.14159 }) -Path $path
                ([double](Import-Toml -Path $path).Data['pi'] - 3.14159) | Should -BeLessThan 0.00001
            }

            It 'preserves nested tables' {
                $path = Join-Path $TestDrive 'rt-nested.toml'
                Export-Toml -InputObject ([ordered]@{ server = [ordered]@{ host = 'localhost'; port = [long]8080 } }) -Path $path
                $rt = (Import-Toml -Path $path).Data
                $rt['server']['host'] | Should -Be 'localhost'
                $rt['server']['port'] | Should -Be 8080
            }

            It 'preserves integer arrays' {
                $path = Join-Path $TestDrive 'rt-array.toml'
                Export-Toml -InputObject ([ordered]@{ ports = @([long]80, [long]443) }) -Path $path
                $rt = (Import-Toml -Path $path).Data['ports']
                $rt | Should -HaveCount 2
                $rt[0] | Should -Be 80
            }

            It 'full file survives a round-trip' {
                $outPath = Join-Path $TestDrive 'rt-full.toml'
                Export-Toml -InputObject (Import-Toml -Path (Join-Path $dataDir 'full-example.toml')) -Path $outPath
                $rt = (Import-Toml -Path $outPath).Data
                $rt['title'] | Should -Be 'TOML Example'
                $rt['owner']['name'] | Should -Be 'Tom Preston-Werner'
                $rt['database']['enabled'] | Should -Be $true
                $rt['servers']['alpha']['ip'] | Should -Be '10.0.0.1'
            }
        }

        Context 'UTF-8 encoding' {
            It 'writes UTF-8 without BOM' {
                $path = Join-Path $TestDrive 'utf8.toml'
                Export-Toml -InputObject ([ordered]@{ key = 'αβγ' }) -Path $path
                $bytes = [System.IO.File]::ReadAllBytes($path)
                if ($bytes.Length -ge 3) {
                    ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) | Should -BeFalse
                }
            }

            It 'round-trips Unicode string content correctly' {
                $path = Join-Path $TestDrive 'unicode.toml'
                Export-Toml -InputObject ([ordered]@{ msg = 'こんにちは' }) -Path $path
                (Import-Toml -Path $path).Data['msg'] | Should -Be 'こんにちは'
            }
        }

        Context 'Pipeline input' {
            It 'accepts a TomlDocument from the pipeline' {
                $outPath = Join-Path $TestDrive 'from-pipeline.toml'
                Import-Toml -Path (Join-Path $dataDir 'booleans.toml') | Export-Toml -Path $outPath
                Test-Path $outPath | Should -BeTrue
                (Import-Toml -Path $outPath).Data['enabled'] | Should -Be $true
            }
        }

        Context 'WhatIf' {
            It 'does not create a file when -WhatIf is passed' {
                $path = Join-Path $TestDrive 'whatif.toml'
                Export-Toml -InputObject ([ordered]@{ k = 'v' }) -Path $path -WhatIf
                Test-Path -Path $path | Should -BeFalse
            }
        }

        Context 'Error handling' {
            It 'throws on null InputObject' {
                { Export-Toml -InputObject $null -Path (Join-Path $TestDrive 'null.toml') } | Should -Throw
            }
        }
    }
}
