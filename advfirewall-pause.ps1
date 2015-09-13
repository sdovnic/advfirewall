If ($PSVersionTable.PSVersion.Major -lt 3) {
    [String] $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
}
If ($PSVersionTable.PSVersion.Major -lt 3) {
    [String] $PSCommandPath = $MyInvocation.MyCommand.Definition
}
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell -WindowStyle Hidden -WorkingDirectory $PSScriptRoot -Verb runAs `
                             -ArgumentList "-ExecutionPolicy Bypass -File $PSCommandPath $args"
    return
}
Function Show-Balloon {
    Param(
        [Parameter(Mandatory=$true)] [String] $TipTitle,
        [Parameter(Mandatory=$true)] [String] $TipText,
        [Parameter(Mandatory=$false)] [ValidateSet("Info", "Error", "Warning")] [String] $TipIcon,
        [String] $Icon
    )
    [Void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $FormsNotifyIcon = New-Object System.Windows.Forms.NotifyIcon
    If (-not $Icon) { $Icon = (Join-Path -Path $PSHOME -ChildPath "powershell.exe"); }
    $DrawingIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)
    $FormsNotifyIcon.Icon = $DrawingIcon
    If (-not $TipIcon) { $TipIcon = "Info"; }
    $FormsNotifyIcon.BalloonTipIcon = $TipIcon;
    $FormsNotifyIcon.BalloonTipTitle = $TipTitle
    $FormsNotifyIcon.BalloonTipText = $TipText
    $FormsNotifyIcon.Visible = $True
    $FormsNotifyIcon.ShowBalloonTip(5000)
    Start-Sleep -Milliseconds 5000
    $FormsNotifyIcon.Dispose()
}
If (Get-Command -Name Get-NetFirewallRule -ErrorAction SilentlyContinue) {
    Set-NetFirewallProfile -DefaultInboundAction Allow `
                           -DefaultOutboundAction Allow `
                           -All
} Else {
    Write-Warning "Get-NetFirewallRule not supported."
    Start-Process "netsh" -ArgumentList ("advfirewall", "set", "allprofiles", "firewallpolicy", "allowinbound,allowoutbound") -WindowStyle Hidden -Wait
}
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$Result = [System.Windows.Forms.MessageBox]::Show(
    "Achtung! Die Windows Firewall wurde angehalten, w�hlen Sie OK um den vorherigen Zustand wieder herzustellen.",
    "Windows Firewall", 0, [System.Windows.Forms.MessageBoxIcon]::Error
)
If ($Result -eq "OK") {
    If (Get-Command -Name Get-NetFirewallRule -ErrorAction SilentlyContinue) {
        Set-NetFirewallProfile -DefaultInboundAction Block `
                               -DefaultOutboundAction Block `
                               -All
    } Else {
        Write-Warning "Get-NetFirewallRule not supported."
        Start-Process "netsh" -ArgumentList ("advfirewall", "set", "allprofiles", "firewallpolicy", "blockinbound,blockoutbound") -WindowStyle Hidden -Wait
    }
    Show-Balloon -TipTitle "Windows Firewall" -TipText "Windows Firewall wieder eingeschaltet." `
                 -TipIcon "Info" -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
}
