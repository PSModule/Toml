# Toml

PowerShell module for reading and writing [TOML](https://toml.io) data, with full TOML 1.0.0 specification support.

## Prerequisites

- PowerShell 7.6 LTS
- The [PSModule framework](https://github.com/PSModule/Process-PSModule) for building, testing and publishing the module.

## Installation

To install the module from the PowerShell Gallery, you can use the following command:

```powershell
Install-PSResource -Name Toml
Import-Module -Name Toml
```

## Usage

### Parse a TOML string

```powershell
$doc = ConvertFrom-Toml -InputObject @'
[database]
host = "localhost"
port = 5432
enabled = true
'@

$doc.Data.database.host     # "localhost"
$doc.Data.database.port     # 5432 [long]
$doc.Data.database.enabled  # $true
```

### Import from a TOML file

```powershell
$doc = Import-Toml -Path './config.toml'
$doc.FilePath   # absolute path to the file
$doc.Data       # OrderedDictionary of all top-level keys
```

### Serialize an object to TOML

```powershell
$toml = ConvertTo-Toml -InputObject ([ordered]@{
    title   = 'My App'
    version = 1
    server  = [ordered]@{
        host = 'localhost'
        port = 8080
    }
})
# title = "My App"
# version = 1
#
# [server]
# host = "localhost"
# port = 8080
```

### Export to a TOML file

```powershell
$config = [ordered]@{
    name    = 'example'
    enabled = $true
}
Export-Toml -InputObject $config -Path './output.toml'
```

### Round-trip: file → modify → file

```powershell
$doc = Import-Toml -Path './config.toml'
$doc.Data['version'] = 2
Export-Toml -InputObject $doc -Path './config.toml'
```

## TOML type mapping

| TOML type            | PowerShell type            |
|----------------------|----------------------------|
| String               | `[string]`                 |
| Integer              | `[long]`                   |
| Float                | `[double]`                 |
| Boolean              | `[bool]`                   |
| Offset date-time     | `[System.DateTimeOffset]`  |
| Local date-time      | `[System.DateTime]`        |
| Local date           | `[System.DateTime]`        |
| Local time           | `[System.TimeSpan]`        |
| Array                | `[object[]]`               |
| Table / Inline table | `[ordered]` hashtable      |
| Array of tables      | `[object[]]` of hashtables |

## Commands

| Command           | Description                              |
|-------------------|------------------------------------------|
| `ConvertFrom-Toml` | Parse TOML text → `TomlDocument`        |
| `ConvertTo-Toml`  | Serialize object → TOML text             |
| `Import-Toml`     | Read TOML file → `TomlDocument`          |
| `Export-Toml`     | Write object or `TomlDocument` to file   |

## Implementation notes

- Pure PowerShell parser and serializer — no external TOML runtime dependency.
- Duplicate keys and table redefinition are rejected per the TOML 1.0.0 spec.
- Files are written as UTF-8 without BOM.

## More examples

See the [examples](examples) folder for runnable scripts. Use PowerShell help for per-command examples:

```powershell
Get-Help ConvertFrom-Toml -Examples
Get-Help Import-Toml -Examples
```

## Documentation

Full documentation is available at [psmodule.io/Toml](https://psmodule.io/Toml).

## Contributing

Coder or not, you can contribute to the project! We welcome all contributions.

### For Users

If you experience unexpected behavior, errors, or missing functionality, please open an issue on the [issues tab](https://github.com/PSModule/Toml/issues).

### For Developers

Please read the [Contribution guidelines](CONTRIBUTING.md) and pick up an existing issue or submit a new one.
