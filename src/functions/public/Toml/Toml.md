# Toml

The `Toml` group contains commands for reading, writing, validating, and merging [TOML](https://toml.io) data in PowerShell.

## Commands

| Command | Description |
| --- | --- |
| `ConvertFrom-Toml` | Parses TOML text into a `TomlDocument`. |
| `ConvertTo-Toml` | Serializes a PowerShell object graph to TOML text. |
| `Import-Toml` | Reads a TOML file from disk into a `TomlDocument`. |
| `Export-Toml` | Writes a `TomlDocument` or object graph to a TOML file. |
| `Format-Toml` | Normalizes TOML text into a canonical form. |
| `Test-Toml` | Validates TOML content without throwing. |
| `Merge-Toml` | Deep-merges two or more TOML documents. |

## Type mapping

| TOML type | PowerShell type |
| --- | --- |
| String | `[string]` |
| Integer | `[long]` |
| Float | `[double]` |
| Boolean | `[bool]` |
| Offset date-time | `[System.DateTimeOffset]` |
| Local date-time | `[System.DateTime]` |
| Local date | `[System.DateTime]` |
| Local time | `[System.TimeSpan]` |
| Array | `[object[]]` |
| Table / Inline table | `[System.Collections.Specialized.OrderedDictionary]` |
| Array of tables | `[object[]]` of ordered dictionaries |
