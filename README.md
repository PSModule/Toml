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

- Implemented with in-repository PowerShell parser/serializer logic (no external TOML runtime dependency).
- Duplicate keys and table redefinition are rejected per the TOML 1.0.0 spec.
- Files are written as UTF-8 without BOM.


### Example 2

Provide examples for typical commands that a user would like to do with the module.

```powershell
Import-Module -Name PSModuleTemplate
```

### Find more examples

To find more examples of how to use the module, please refer to the [examples](examples) folder.

Alternatively, you can use the Get-Command -Module 'This module' to find more commands that are available in the module.
To find examples of each of the commands you can use Get-Help -Examples 'CommandName'.

## Documentation

Link to further documentation if available, or describe where in the repository users can find more detailed documentation about
the module's functions and features.

## Contributing

Coder or not, you can contribute to the project! We welcome all contributions.

### For Users

If you don't code, you still sit on valuable information that can make this project even better. If you experience that the
product does unexpected things, throw errors or is missing functionality, you can help by submitting bugs and feature requests.
Please see the issues tab on this project and submit a new issue that matches your needs.

### For Developers

If you do code, we'd love to have your contributions. Please read the [Contribution guidelines](CONTRIBUTING.md) for more information.
You can either help by picking up an existing issue or submit a new one if you have an idea for a new feature or improvement.

## Acknowledgements

Here is a list of people and projects that helped this project in some way.
