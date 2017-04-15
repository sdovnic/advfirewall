function Remove-ShortCut {
    param(
        [parameter(Mandatory=$true)] [string] $Link
    )
    process {
        if (Test-Path -Path $Link) {
            Remove-Item -Path $Link;
        }
    }
}
