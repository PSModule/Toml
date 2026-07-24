<#
  .SYNOPSIS
    General usage examples for the Toml module.
#>

# Import the module
Import-Module -Name 'Toml'

# ── Parse TOML string ──────────────────────────────────────────────────────
$doc = ConvertFrom-Toml -InputObject @'
[database]
host = "localhost"
port = 5432
enabled = true
tags = ["production", "primary"]

[database.credentials]
user = "admin"
'@

$doc.Data.database.host            # "localhost"
$doc.Data.database.port            # 5432
$doc.Data.database.enabled         # True
$doc.Data.database.tags            # @("production", "primary")
$doc.Data.database.credentials.user  # "admin"

# ── Serialize to TOML ──────────────────────────────────────────────────────
$toml = ConvertTo-Toml -InputObject ([ordered]@{
    title   = 'My Application'
    version = 2
    debug   = $false
    server  = [ordered]@{
        host = '0.0.0.0'
        port = 8080
    }
    features = @('auth', 'logging', 'metrics')
})
Write-Host $toml

# ── Import from file ───────────────────────────────────────────────────────
# $doc = Import-Toml -Path './config.toml'
# $doc.FilePath   # absolute path to the source file
# $doc.Data       # [ordered] hashtable of all top-level keys

# ── Export to file ─────────────────────────────────────────────────────────
# Export-Toml -InputObject ([ordered]@{ key = 'value' }) -Path './config.toml'

# ── Round-trip: file → edit → file ────────────────────────────────────────
# $doc = Import-Toml -Path './config.toml'
# $doc.Data['version'] = 3
# Export-Toml -InputObject $doc -Path './config.toml'

# ── Pipeline usage ─────────────────────────────────────────────────────────
# '[server]
# host = "localhost"' | ConvertFrom-Toml | ConvertTo-Toml

# ── All TOML scalar types ──────────────────────────────────────────────────
$types = ConvertFrom-Toml -InputObject @'
a_string       = "hello"
an_integer     = 42
a_float        = 3.14
a_bool         = true
an_offset_dt   = 1979-05-27T07:32:00Z
a_local_dt     = 1979-05-27T07:32:00
a_local_date   = 1979-05-27
a_local_time   = 07:32:00
'@

$types.Data.a_string      # [string]
$types.Data.an_integer    # [long]
$types.Data.a_float       # [double]
$types.Data.a_bool        # [bool]
$types.Data.an_offset_dt  # [System.DateTimeOffset]
$types.Data.a_local_dt    # [System.DateTime] (Kind=Unspecified)
$types.Data.a_local_date  # [System.DateTime] (00:00:00)
$types.Data.a_local_time  # [System.TimeSpan]
