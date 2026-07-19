function ConvertTo-TomlynArray {
    <#
        .SYNOPSIS
        Converts a PowerShell enumerable to a Tomlyn TomlArray.

        .DESCRIPTION
        Iterates each element of the input collection and calls ConvertTo-TomlynValue
        recursively. Strings are enumerated character-by-character by default in
        PowerShell, so strings are handled explicitly before the IEnumerable path.

        .EXAMPLE
        ConvertTo-TomlynArray -Value @(1, 2, 3)

        Returns a [Tomlyn.Model.TomlArray] with three integer elements.

        .INPUTS
        [System.Collections.IEnumerable]

        .OUTPUTS
        [Tomlyn.Model.TomlArray]

        .NOTES
        Internal helper. Not exported. No pipeline input.
    #>
    [OutputType([Tomlyn.Model.TomlArray])]
    [CmdletBinding()]
    param(
        # The collection to convert.
        [Parameter(Mandatory)]
        [System.Collections.IEnumerable] $Value
    )

    $array = [Tomlyn.Model.TomlArray]::new()

    foreach ($item in $Value) {
        $array.Add((ConvertTo-TomlynValue -Value $item))
    }

    # Wrap to prevent PowerShell from enumerating TomlArray (IEnumerable)
    return , $array
}
