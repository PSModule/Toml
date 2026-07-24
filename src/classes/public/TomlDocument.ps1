# Represents a parsed TOML document.
# Exposes the root key-value data as an ordered dictionary and records the
# file path when the document was loaded from disk.
class TomlDocument {
    # The root key-value pairs of the TOML document, preserving insertion order.
    [System.Collections.Specialized.OrderedDictionary] $Data

    # The absolute path to the source file, if loaded with Import-Toml.
    # $null when the document was created from a string.
    [string] $FilePath

    TomlDocument() {
        $this.Data = [System.Collections.Specialized.OrderedDictionary]::new(
            [System.StringComparer]::Ordinal
        )
    }

    TomlDocument([System.Collections.Specialized.OrderedDictionary] $data) {
        $this.Data = $data
    }

    # Returns true when the document contains the given top-level key.
    [bool] ContainsKey([string] $key) {
        return $this.Data.Contains($key)
    }

    # Returns the number of top-level keys.
    [int] GetCount() {
        return $this.Data.Count
    }

    [string] ToString() {
        return "TomlDocument[$($this.Data.Count) key(s)]"
    }
}
