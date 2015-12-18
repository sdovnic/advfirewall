if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
}
if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSCommandPath = $MyInvocation.MyCommand.Definition
}
function Show-Balloon {
    param(
        [parameter(Mandatory=$true)] [string] $TipTitle,
        [parameter(Mandatory=$true)] [string] $TipText,
        [parameter(Mandatory=$false)] [ValidateSet("Info", "Error", "Warning")] [string] $TipIcon,
        [string] $Icon
    )
    process {
        [Void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        $FormsNotifyIcon = New-Object -TypeName System.Windows.Forms.NotifyIcon
        if (-not $Icon) { $Icon = (Join-Path -Path $PSHOME -ChildPath "powershell.exe"); }
        $DrawingIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)
        $FormsNotifyIcon.Icon = $DrawingIcon
        if (-not $TipIcon) { $TipIcon = "Info"; }
        $FormsNotifyIcon.BalloonTipIcon = $TipIcon;
        $FormsNotifyIcon.BalloonTipTitle = $TipTitle
        $FormsNotifyIcon.BalloonTipText = $TipText
        $FormsNotifyIcon.Visible = $True
        $FormsNotifyIcon.ShowBalloonTip(2500)
        $FormsNotifyIcon.Dispose()
    }
}
function Add-ShortCut {
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
            if ($Arguments) { $Shortcut.Arguments = $Arguments; }
            if ($IconLocation) { $Shortcut.IconLocation = $IconLocation; }
            if ($WorkingDirectory) { $Shortcut.WorkingDirectory = $WorkingDirectory; }
            if ($WindowStyle) {
                switch ($WindowStyle) {
                    "Normal" { [int] $WindowStyleNumerate = 4 };
                    "Minimized" { [int] $WindowStyleNumerate = 7 };
                    "Maximized" { [int] $WindowStyleNumerate = 3 };
                }
                $Shortcut.WindowStyle = $WindowStyleNumerate;
            }
            if ($Description) { $Shortcut.Description = $Description; }
            $Shortcut.Save()
        }
    }
}
function Remove-Shortcut {
    param([parameter(Mandatory=$true)] [string] $Link)
    if (Test-Path -Path $Link) { Remove-Item -Path $Link; }
}
if ($args.Length -gt 0) {
    $Username = Get-WMIObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Username | Split-Path -Leaf
    if (-not ($env:USERNAME -eq $Username)) {
        $Path = [Environment]::GetFolderPath("StartMenu") -replace $env:USERNAME, $Username
    } else {
        $Path = [Environment]::GetFolderPath("StartMenu")
    }
    Remove-ShortCut -Link (Join-Path -Path $Path -ChildPath "Aktualisiere Windows Update Service Regeln.lnk")
    Show-Balloon -TipTitle "Windows Firewall" -TipText "Die Verkn$([char]0x00FC)pfung zum aktualisieren von Windows Update Service Regeln wurde entfernt." `
                 -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
    Add-Type -AssemblyName System.Windows.Forms
    $Result = [System.Windows.Forms.MessageBox]::Show(
        "Die Verkn$([char]0x00FC)pfung zum aktualisieren von Windows Update Service Regeln wurde entfernt.", "Windows Firewall", 0,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
} else {
    $Username = Get-WMIObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Username | Split-Path -Leaf
    if (-not ($env:USERNAME -eq $Username)) {
        $Path = [Environment]::GetFolderPath("StartMenu") -replace $env:USERNAME, $Username
    } else {
        $Path = [Environment]::GetFolderPath("StartMenu")
    }
    Add-ShortCut -Link (Join-Path -Path $Path -ChildPath "Aktualisiere Windows Update Service Regeln.lnk") `
                 -TargetPath (Join-Path -Path $PSHOME -ChildPath "powershell.exe") `
                 -Arguments "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSScriptRoot\advfirewall-wuauserv-update.ps1`"" `
                 -IconLocation "%SystemRoot%\system32\imageres.dll,1" `
                 -Description "F$([char]0x00FC)ge Ausnahmen f$([char]0x00FC)r IP-Adressen hinzu um die Ausf$([char]0x00FC)hrung des Windows Update Service zu erm$([char]0x00F6)glichen."
    Show-Balloon -TipTitle "Windows Firewall" -TipText "Verkn$([char]0x00FC)pfung zum aktualisieren von Windows Update Service Regeln angelegt." `
                 -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
    Add-Type -AssemblyName System.Windows.Forms
    $Result = [System.Windows.Forms.MessageBox]::Show(
        "Verkn$([char]0x00FC)pfung zum aktualisieren von Windows Update Service Regeln angelegt.", "Windows Firewall", 0,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}
