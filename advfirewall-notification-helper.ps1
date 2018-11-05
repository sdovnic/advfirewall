if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
}

if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSCommandPath = $MyInvocation.MyCommand.Definition
}

# Import-LocalizedData -BaseDirectory $PSScriptRoot\Locales -BindingVariable Messages

Import-Module -Name (Join-Path -Path $PSScriptRoot\Modules -ChildPath Show-Balloon)
Import-Module -Name (Join-Path -Path $PSScriptRoot\Modules -ChildPath Convert-DevicePathToDriveLetter)

if ($args) {
    $Arguments = $args[0]  
    #Show-Balloon -TipTitle "Windows Firewall" -TipText ([string] $Arguments) -TipIcon Info -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
    if ($Arguments.Contains("advfirewall:pid")) {
        $Id = ($Arguments -split "=")[-1]
        $Id
        Stop-Process -Id $Id
        Show-Balloon -TipTitle "Windows Firewall" -TipText ("Advanced Firewall Notifications are now disabled.") -TipIcon Info -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
    } elseif ($Arguments.Contains("advfirewall:hide")) {
        $Arguments = ($Arguments -split "=")[-1]
        $Arguments = [Convert]::FromBase64String($Arguments) -split ","
        if ($Arguments[2]) {
            $Services = $Arguments[2]
        }
        $Application = $Arguments[7]
        $Application = Convert-DevicePathToDriveLetter -Path $Application
        Show-Balloon -TipTitle "Windows Firewall" -TipText ("Notifications for {0} are now hidden." -f $Application) -TipIcon Info -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
    } elseif ($Arguments.Contains("advfirewall:allow")) {
        $Arguments = ($Arguments -split "=")[1] # -split ","
        $Arguments
        $Arguments = [Convert]::FromBase64String($Arguments + "=")
        $Arguments
        $Arguments = -split ","
        <#
        if (-not $Arguments[2]) {
            $Application = $Arguments[7]
            $Application = Convert-DevicePathToDriveLetter -Path $Application
            Show-Balloon -TipTitle "Windows Firewall" -TipText ([string] $Arguments) -TipIcon Info -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
            #("Network connections for {0} are now allowed." -f $Arguments)
        }
        #>
    }
}
pause

# start advfirewall:allow=$(Get-Content -Path C:\Portable\advfirewall\advfirewall-events.csv -Tail 1)
