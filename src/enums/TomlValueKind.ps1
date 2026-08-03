<#
.SYNOPSIS
    Represents the TOML value type categories defined in the TOML 1.0.0 specification.

.DESCRIPTION
    TomlValueKind is a discriminated enum of every first-class TOML value type.
    Use it with Get-TomlValueKind (or inspect values returned by ConvertFrom-Toml)
    to determine the TOML-semantic type of a parsed value.
#>
enum TomlValueKind {
    String
    Integer
    Float
    Boolean
    OffsetDateTime
    LocalDateTime
    LocalDate
    LocalTime
    Array
    InlineTable
}
