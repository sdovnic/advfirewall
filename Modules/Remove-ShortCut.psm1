function Remove-Shortcut {
    <#
        .SYNOPSIS
            Remove a Shortcut.
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)] [string] $Link
    )
    process {
        if (Test-Path -Path $Link -ErrorAction SilentlyContinue) {
            Remove-Item -Path $Link -Verbose
        }
    }
}
