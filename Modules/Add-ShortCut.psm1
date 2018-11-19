function Add-ShortCut {
    <#
        .SYNOPSIS
            Add a Shortcut.
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)] [string] $Link,
        [parameter(Mandatory=$true)] [string] $TargetPath,
        [string] $Arguments,
        [string] $IconLocation,
        [string] $WorkingDirectory,
        [string] $Description,
        [parameter(Mandatory=$false)] [ValidateSet("Normal", "Minimized", "Maximized")] [string] $WindowStyle
    )
    process {
        if (Test-Path -Path $TargetPath) {
            $WShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WShell.CreateShortcut($Link)
            $Shortcut.TargetPath = $TargetPath
            if ($Arguments) { $Shortcut.Arguments = $Arguments }
            if ($IconLocation) { $Shortcut.IconLocation = $IconLocation }
            if ($WorkingDirectory) { $Shortcut.WorkingDirectory = $WorkingDirectory }
            if ($WindowStyle) {
                switch ($WindowStyle) {
                    "Normal" { [int] $WindowStyleNumerate = 4 }
                    "Minimized" { [int] $WindowStyleNumerate = 7 }
                    "Maximized" { [int] $WindowStyleNumerate = 3 }
                }
                $Shortcut.WindowStyle = $WindowStyleNumerate
            }
            if ($Description) { $Shortcut.Description = $Description }
            $Shortcut.Save()
        }
    }
}
