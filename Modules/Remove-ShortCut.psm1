function Remove-ShortCut {
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
