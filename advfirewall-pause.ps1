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

Import-LocalizedData -BaseDirectory $PSScriptRoot\Locales -BindingVariable Messages

Import-Module -Name (Join-Path -Path $PSScriptRoot\Modules -ChildPath Show-Balloon)

if (Get-Command -Name Get-NetFirewallRule -ErrorAction SilentlyContinue) {
    Set-NetFirewallProfile -DefaultInboundAction Allow `
                           -DefaultOutboundAction Allow `
                           -All
} else {
    Write-Warning -Message $Messages."Get-NetFirewallRule not supported, using Netsh."
    Start-Process -FilePath "netsh" -ArgumentList ("advfirewall", "set", "allprofiles", "firewallpolicy", "allowinbound,allowoutbound") -WindowStyle Hidden -Wait
}

[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$Result = [System.Windows.Forms.MessageBox]::Show(
    $Messages."Warning! Windows Firewall has been stopped, select OK to restore the previous state.",
    "Windows Firewall", 0, [System.Windows.Forms.MessageBoxIcon]::Error
)

if ($Result -eq "OK") {
    if (Get-Command -Name Get-NetFirewallRule -ErrorAction SilentlyContinue) {
        Set-NetFirewallProfile -DefaultInboundAction Block `
                               -DefaultOutboundAction Block `
                               -All
    } else {
        Write-Warning -Message $Messages."Get-NetFirewallRule not supported, using Netsh."
        Start-Process -FilePath "netsh" -ArgumentList ("advfirewall", "set", "allprofiles", "firewallpolicy", "blockinbound,blockoutbound") -WindowStyle Hidden -Wait
    }
    Show-Balloon -TipTitle "Windows Firewall" -TipText $Messages."Windows Firewall turned back on." `
                 -TipIcon "Info" -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
}
