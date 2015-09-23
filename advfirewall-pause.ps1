if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
}
if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSCommandPath = $MyInvocation.MyCommand.Definition
}
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process -FilePath "powershell" -WindowStyle Hidden -WorkingDirectory $PSScriptRoot -Verb runAs `
                  -ArgumentList "-ExecutionPolicy Bypass -File $PSCommandPath $args"
    return
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
        $FormsNotifyIcon.ShowBalloonTip(5000)
        Start-Sleep -Milliseconds 5000
        $FormsNotifyIcon.Dispose()
    }
}
if (Get-Command -Name Get-NetFirewallRule -ErrorAction SilentlyContinue) {
    Set-NetFirewallProfile -DefaultInboundAction Allow `
                           -DefaultOutboundAction Allow `
                           -All
} else {
    Write-Warning -Message "Get-NetFirewallRule not supported, using Netsh."
    Start-Process -FilePath "netsh" -ArgumentList ("advfirewall", "set", "allprofiles", "firewallpolicy", "allowinbound,allowoutbound") -WindowStyle Hidden -Wait
}
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$Result = [System.Windows.Forms.MessageBox]::Show(
    "Achtung! Die Windows Firewall wurde angehalten, w$([char]0x00E4)hlen Sie OK um den vorherigen Zustand wieder herzustellen.",
    "Windows Firewall", 0, [System.Windows.Forms.MessageBoxIcon]::Error
)
if ($Result -eq "OK") {
    if (Get-Command -Name Get-NetFirewallRule -ErrorAction SilentlyContinue) {
        Set-NetFirewallProfile -DefaultInboundAction Block `
                               -DefaultOutboundAction Block `
                               -All
    } else {
        Write-Warning -Message "Get-NetFirewallRule not supported, using Netsh."
        Start-Process -FilePath "netsh" -ArgumentList ("advfirewall", "set", "allprofiles", "firewallpolicy", "blockinbound,blockoutbound") -WindowStyle Hidden -Wait
    }
    Show-Balloon -TipTitle "Windows Firewall" -TipText "Windows Firewall wieder eingeschaltet." `
                 -TipIcon "Info" -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
}
