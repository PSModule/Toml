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

    Describe 'ConvertFrom-Toml' {

        Context 'ConvertFrom-Toml - return type' {
            It 'ConvertFrom-Toml - returns a TomlDocument for a minimal document' {
                $result = ConvertFrom-Toml -InputObject 'key = "value"'
                $result.GetType().Name | Should -Be 'TomlDocument'
            }

            It 'ConvertFrom-Toml - Data property is an OrderedDictionary' {
                $result = ConvertFrom-Toml -InputObject 'key = "value"'
                $result.Data | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
            }

            It 'ConvertFrom-Toml - FilePath is null when parsed from string' {
                $result = ConvertFrom-Toml -InputObject 'key = "value"'
                $result.FilePath | Should -BeNullOrEmpty
            }

            It 'ConvertFrom-Toml - accepts pipeline input' {
                $result = 'key = "value"' | ConvertFrom-Toml
                $result.GetType().Name | Should -Be 'TomlDocument'
            }
        }

        Context 'ConvertFrom-Toml - strings' {
            It 'ConvertFrom-Toml - parses basic string' {
                $result = ConvertFrom-Toml -InputObject 'key = "hello"'
                $result.Data['key'] | Should -Be 'hello'
            }

            It 'ConvertFrom-Toml - parses literal string' {
                $result = ConvertFrom-Toml -InputObject "key = 'C:\path'"
                $result.Data['key'] | Should -Be 'C:\path'
            }

            It 'ConvertFrom-Toml - parses basic string with escape sequences' {
                $result = ConvertFrom-Toml -InputObject 'key = "tab\there"'
                $result.Data['key'] | Should -Be "tab`there"
            }

            It 'ConvertFrom-Toml - parses basic string with quoted escape' {
                $result = ConvertFrom-Toml -InputObject 'key = "say \"hi\""'
                $result.Data['key'] | Should -Be 'say "hi"'
            }

            It 'ConvertFrom-Toml - parses Unicode escape sequence' {
                $result = ConvertFrom-Toml -InputObject 'key = "\u03B1"'
                $result.Data['key'] | Should -Be ([char]0x03B1).ToString()
            }

            It 'ConvertFrom-Toml - parses multi-line basic string' {
                $toml = "key = `"`"`"`nline one`nline two`n`"`"`""
                $result = ConvertFrom-Toml -InputObject $toml
                $result.Data['key'] | Should -Match 'line one'
                $result.Data['key'] | Should -Match 'line two'
            }

            It 'ConvertFrom-Toml - parses multi-line literal string' {
                $toml = "key = '''" + [System.Environment]::NewLine + "raw\nno escape" + [System.Environment]::NewLine + "'''"
                $result = ConvertFrom-Toml -InputObject $toml
                $result.Data['key'] | Should -Match 'raw\\nno escape'
            }

            It 'ConvertFrom-Toml - parses empty string' {
                $result = ConvertFrom-Toml -InputObject 'key = ""'
                $result.Data['key'] | Should -Be ''
            }

            It 'ConvertFrom-Toml - parses strings from file' {
                $path = Join-Path $PSScriptRoot 'data\strings.toml'
                $result = ConvertFrom-Toml -InputObject (Get-Content $path -Raw)
                $result.Data['literal'] | Should -Be 'C:\Users\nodejs\templates'
                $result.Data['empty'] | Should -Be ''
            }
        }

        Context 'ConvertFrom-Toml - integers' {
            It 'ConvertFrom-Toml - parses decimal integer' {
                $result = ConvertFrom-Toml -InputObject 'n = 42'
                $result.Data['n'] | Should -Be 42
                $result.Data['n'] | Should -BeOfType [long]
            }

            It 'ConvertFrom-Toml - parses negative integer' {
                $result = ConvertFrom-Toml -InputObject 'n = -17'
                $result.Data['n'] | Should -Be -17
            }

            It 'ConvertFrom-Toml - parses zero' {
                $result = ConvertFrom-Toml -InputObject 'n = 0'
                $result.Data['n'] | Should -Be 0
            }

            It 'ConvertFrom-Toml - parses integer with underscore separator' {
                $result = ConvertFrom-Toml -InputObject 'n = 1_000_000'
                $result.Data['n'] | Should -Be 1000000
            }

            It 'ConvertFrom-Toml - parses hexadecimal integer' {
                $result = ConvertFrom-Toml -InputObject 'n = 0xFF'
                $result.Data['n'] | Should -Be 255
            }

            It 'ConvertFrom-Toml - parses octal integer' {
                $result = ConvertFrom-Toml -InputObject 'n = 0o17'
                $result.Data['n'] | Should -Be 15
            }

            It 'ConvertFrom-Toml - parses binary integer' {
                $result = ConvertFrom-Toml -InputObject 'n = 0b1010'
                $result.Data['n'] | Should -Be 10
            }

            It 'ConvertFrom-Toml - parses all integer forms from file' {
                $path = Join-Path $PSScriptRoot 'data\integers.toml'
                $result = ConvertFrom-Toml -InputObject (Get-Content $path -Raw)
                $result.Data['decimal'] | Should -Be 42
                $result.Data['negative'] | Should -Be -17
                $result.Data['hex'] | Should -Be 3735928559  # 0xDEADBEEF as unsigned long
                $result.Data['octal'] | Should -Be 493  # 0o755
                $result.Data['binary'] | Should -Be 214  # 0b11010110
            }
        }

        Context 'ConvertFrom-Toml - floats' {
            It 'ConvertFrom-Toml - parses positive float' {
                $result = ConvertFrom-Toml -InputObject 'n = 3.14'
                $result.Data['n'] | Should -Be 3.14
                $result.Data['n'] | Should -BeOfType [double]
            }

            It 'ConvertFrom-Toml - parses negative float' {
                $result = ConvertFrom-Toml -InputObject 'n = -0.01'
                $result.Data['n'] | Should -Be -0.01
            }

            It 'ConvertFrom-Toml - parses scientific notation' {
                $result = ConvertFrom-Toml -InputObject 'n = 5e+22'
                $result.Data['n'] | Should -Be 5e22
            }

            It 'ConvertFrom-Toml - parses inf' {
                $result = ConvertFrom-Toml -InputObject 'n = inf'
                $result.Data['n'] | Should -Be ([double]::PositiveInfinity)
            }

            It 'ConvertFrom-Toml - parses -inf' {
                $result = ConvertFrom-Toml -InputObject 'n = -inf'
                $result.Data['n'] | Should -Be ([double]::NegativeInfinity)
            }

            It 'ConvertFrom-Toml - parses nan' {
                $result = ConvertFrom-Toml -InputObject 'n = nan'
                [double]::IsNaN($result.Data['n']) | Should -BeTrue
            }

            It 'ConvertFrom-Toml - parses floats from file' {
                $path = Join-Path $PSScriptRoot 'data\floats.toml'
                $result = ConvertFrom-Toml -InputObject (Get-Content $path -Raw)
                ([double]$result.Data['positive'] - 3.1415) | Should -BeLessThan 0.0001
                ([double]$result.Data['negative'] - (-0.01)) | Should -BeLessThan 0.0001
            }
        }

        Context 'ConvertFrom-Toml - booleans' {
            It 'ConvertFrom-Toml - parses true' {
                $result = ConvertFrom-Toml -InputObject 'flag = true'
                $result.Data['flag'] | Should -Be $true
                $result.Data['flag'] | Should -BeOfType [bool]
            }

            It 'ConvertFrom-Toml - parses false' {
                $result = ConvertFrom-Toml -InputObject 'flag = false'
                $result.Data['flag'] | Should -Be $false
            }
        }

        Context 'ConvertFrom-Toml - datetimes' {
            It 'ConvertFrom-Toml - parses offset datetime with Z suffix as DateTimeOffset' {
                $result = ConvertFrom-Toml -InputObject 'dt = 1979-05-27T07:32:00Z'
                $result.Data['dt'] | Should -BeOfType [System.DateTimeOffset]
                ([System.DateTimeOffset]$result.Data['dt']).Year | Should -Be 1979
                ([System.DateTimeOffset]$result.Data['dt']).Month | Should -Be 5
                ([System.DateTimeOffset]$result.Data['dt']).Day | Should -Be 27
            }

            It 'ConvertFrom-Toml - parses offset datetime with numeric offset as DateTimeOffset' {
                $result = ConvertFrom-Toml -InputObject 'dt = 1979-05-27T07:32:00+05:30'
                $result.Data['dt'] | Should -BeOfType [System.DateTimeOffset]
                $offset = ([System.DateTimeOffset]$result.Data['dt']).Offset
                $offset.Hours | Should -Be 5
                $offset.Minutes | Should -Be 30
            }

            It 'ConvertFrom-Toml - parses local datetime as DateTime with Unspecified kind' {
                $result = ConvertFrom-Toml -InputObject 'dt = 1979-05-27T07:32:00'
                $result.Data['dt'] | Should -BeOfType [System.DateTime]
                ([System.DateTime]$result.Data['dt']).Kind | Should -Be ([System.DateTimeKind]::Unspecified)
                ([System.DateTime]$result.Data['dt']).Year | Should -Be 1979
            }

            It 'ConvertFrom-Toml - parses local date as DateTime with zero time' {
                $result = ConvertFrom-Toml -InputObject 'dt = 1979-05-27'
                $result.Data['dt'] | Should -BeOfType [System.DateTime]
                $dt = [System.DateTime]$result.Data['dt']
                $dt.Year | Should -Be 1979
                $dt.Month | Should -Be 5
                $dt.Day | Should -Be 27
                $dt.Hour | Should -Be 0
                $dt.Minute | Should -Be 0
                $dt.Second | Should -Be 0
            }

            It 'ConvertFrom-Toml - parses local time as TimeSpan' {
                $result = ConvertFrom-Toml -InputObject 'tm = 07:32:00'
                $result.Data['tm'] | Should -BeOfType [System.TimeSpan]
                ([System.TimeSpan]$result.Data['tm']).Hours | Should -Be 7
                ([System.TimeSpan]$result.Data['tm']).Minutes | Should -Be 32
            }

            It 'ConvertFrom-Toml - parses all datetime types from file' {
                $path = Join-Path $PSScriptRoot 'data\datetimes.toml'
                $result = ConvertFrom-Toml -InputObject (Get-Content $path -Raw)
                $result.Data['offset_dt_z'] | Should -BeOfType [System.DateTimeOffset]
                $result.Data['offset_dt_num'] | Should -BeOfType [System.DateTimeOffset]
                $result.Data['local_dt'] | Should -BeOfType [System.DateTime]
                $result.Data['local_date'] | Should -BeOfType [System.DateTime]
                $result.Data['local_time'] | Should -BeOfType [System.TimeSpan]
            }
        }

        Context 'ConvertFrom-Toml - arrays' {
            It 'ConvertFrom-Toml - parses integer array' {
                $result = ConvertFrom-Toml -InputObject 'arr = [1, 2, 3]'
                $result.Data['arr'] | Should -HaveCount 3
                $result.Data['arr'][0] | Should -Be 1
                $result.Data['arr'][2] | Should -Be 3
            }

            It 'ConvertFrom-Toml - parses string array' {
                $result = ConvertFrom-Toml -InputObject 'arr = ["a", "b", "c"]'
                $result.Data['arr'][0] | Should -Be 'a'
                $result.Data['arr'][1] | Should -Be 'b'
            }

            It 'ConvertFrom-Toml - parses empty array' {
                $result = ConvertFrom-Toml -InputObject 'arr = []'
                $result.Data['arr'] | Should -HaveCount 0
            }

            It 'ConvertFrom-Toml - parses nested array' {
                $result = ConvertFrom-Toml -InputObject 'arr = [[1, 2], [3, 4]]'
                $result.Data['arr'] | Should -HaveCount 2
                $result.Data['arr'][0] | Should -HaveCount 2
                $result.Data['arr'][0][1] | Should -Be 2
            }

            It 'ConvertFrom-Toml - parses multiline array' {
                $toml = "arr = [`n  1,`n  2,`n  3,`n]"
                $result = ConvertFrom-Toml -InputObject $toml
                $result.Data['arr'] | Should -HaveCount 3
            }

            It 'ConvertFrom-Toml - parses arrays from file' {
                $path = Join-Path $PSScriptRoot 'data\arrays.toml'
                $result = ConvertFrom-Toml -InputObject (Get-Content $path -Raw)
                $result.Data['integers'] | Should -HaveCount 3
                $result.Data['strings'] | Should -HaveCount 3
                $result.Data['empty'] | Should -HaveCount 0
                $result.Data['nested'] | Should -HaveCount 2
            }
        }

        Context 'ConvertFrom-Toml - tables' {
            It 'ConvertFrom-Toml - parses standard table' {
                $toml = "[server]`nhost = `"localhost`""
                $result = ConvertFrom-Toml -InputObject $toml
                $result.Data['server'] | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
                $result.Data['server']['host'] | Should -Be 'localhost'
            }

            It 'ConvertFrom-Toml - parses inline table' {
                $result = ConvertFrom-Toml -InputObject 'point = { x = 1, y = 2 }'
                $result.Data['point'] | Should -BeOfType [System.Collections.Specialized.OrderedDictionary]
                $result.Data['point']['x'] | Should -Be 1
                $result.Data['point']['y'] | Should -Be 2
            }

            It 'ConvertFrom-Toml - parses nested tables via dotted header' {
                $toml = "[a.b.c]`nkey = `"deep`""
                $result = ConvertFrom-Toml -InputObject $toml
                $result.Data['a']['b']['c']['key'] | Should -Be 'deep'
            }

            It 'ConvertFrom-Toml - tables from file' {
                $path = Join-Path $PSScriptRoot 'data\tables.toml'
                $result = ConvertFrom-Toml -InputObject (Get-Content $path -Raw)
                $result.Data['simple']['key'] | Should -Be 'value'
                $result.Data['dotted']['key']['works'] | Should -Be $true
                $result.Data['inline_parent']['inline']['one'] | Should -Be 1
            }
        }

        Context 'ConvertFrom-Toml - array of tables' {
            It 'ConvertFrom-Toml - parses array of tables' {
                $path = Join-Path $PSScriptRoot 'data\array-of-tables.toml'
                $result = ConvertFrom-Toml -InputObject (Get-Content $path -Raw)
                $result.Data['products'] | Should -HaveCount 2
                $result.Data['products'][0]['name'] | Should -Be 'Hammer'
                $result.Data['products'][1]['name'] | Should -Be 'Nail'
            }

            It 'ConvertFrom-Toml - parses nested array of tables' {
                $path = Join-Path $PSScriptRoot 'data\array-of-tables.toml'
                $result = ConvertFrom-Toml -InputObject (Get-Content $path -Raw)
                $result.Data['fruits'][0]['varieties'] | Should -HaveCount 2
                $result.Data['fruits'][0]['varieties'][0]['name'] | Should -Be 'red delicious'
            }
        }

        Context 'ConvertFrom-Toml - keys' {
            It 'ConvertFrom-Toml - parses bare key' {
                $result = ConvertFrom-Toml -InputObject 'bare_key = "value"'
                $result.Data['bare_key'] | Should -Be 'value'
            }

            It 'ConvertFrom-Toml - parses quoted key' {
                $result = ConvertFrom-Toml -InputObject '"quoted key" = "value"'
                $result.Data['quoted key'] | Should -Be 'value'
            }

            It 'ConvertFrom-Toml - parses dotted key' {
                $result = ConvertFrom-Toml -InputObject 'a.b = "value"'
                $result.Data['a']['b'] | Should -Be 'value'
            }

            It 'ConvertFrom-Toml - preserves key order' {
                $toml = "z = 1`ny = 2`nx = 3"
                $result = ConvertFrom-Toml -InputObject $toml
                $keys = $result.Data.Keys
                $keys[0] | Should -Be 'z'
                $keys[1] | Should -Be 'y'
                $keys[2] | Should -Be 'x'
            }
        }

        Context 'ConvertFrom-Toml - comments and whitespace' {
            It 'ConvertFrom-Toml - ignores inline comments' {
                $result = ConvertFrom-Toml -InputObject 'key = "value" # this is a comment'
                $result.Data['key'] | Should -Be 'value'
            }

            It 'ConvertFrom-Toml - ignores full-line comments' {
                $toml = "# comment`nkey = `"value`""
                $result = ConvertFrom-Toml -InputObject $toml
                $result.Data['key'] | Should -Be 'value'
            }

            It 'ConvertFrom-Toml - handles CRLF line endings' {
                $toml = "a = 1`r`nb = 2"
                $result = ConvertFrom-Toml -InputObject $toml
                $result.Data['a'] | Should -Be 1
                $result.Data['b'] | Should -Be 2
            }
        }

        Context 'ConvertFrom-Toml - full example file' {
            It 'ConvertFrom-Toml - parses full example document' {
                $path = Join-Path $PSScriptRoot 'data\full-example.toml'
                $result = ConvertFrom-Toml -InputObject (Get-Content $path -Raw)
                $result.Data['title'] | Should -Be 'TOML Example'
                $result.Data['owner']['name'] | Should -Be 'Tom Preston-Werner'
                $result.Data['database']['enabled'] | Should -Be $true
                $result.Data['database']['ports'] | Should -HaveCount 3
                $result.Data['servers']['alpha']['ip'] | Should -Be '10.0.0.1'
                $result.Data['servers']['beta']['role'] | Should -Be 'backend'
            }
        }

        Context 'ConvertFrom-Toml - error handling' {
            It 'ConvertFrom-Toml - throws on invalid TOML syntax' {
                { ConvertFrom-Toml -InputObject 'invalid = = "bad"' } | Should -Throw
            }

            It 'ConvertFrom-Toml - throws on duplicate key' {
                $toml = "key = 1`nkey = 2"
                { ConvertFrom-Toml -InputObject $toml } | Should -Throw
            }

            It 'ConvertFrom-Toml - throws on missing value' {
                { ConvertFrom-Toml -InputObject 'key =' } | Should -Throw
            }

            It 'ConvertFrom-Toml - throws on empty string input' {
                { ConvertFrom-Toml -InputObject '' } | Should -Throw
            }

            It 'ConvertFrom-Toml - throws on redefining a table as a key' {
                $toml = "[a]`nkey = 1`n[a]`nother = 2"
                { ConvertFrom-Toml -InputObject $toml } | Should -Throw
            }
        }
    }
}
