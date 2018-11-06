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
    if ($Arguments.Contains("advfirewall:pid")) {
        $Id = ($Arguments -split "=")[-1]
        Stop-Process -Id $Id -Verbose
        Show-Balloon -TipTitle "Windows Firewall" -TipText ("Advanced Firewall Notifications are now disabled.") -TipIcon Info -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
    } elseif ($Arguments.Contains("advfirewall:hide")) {
        $Arguments = ($Arguments -split "=")
        $Event = [System.Net.WebUtility]::UrlDecode($Arguments[1])
        $Event = $Event -split ","
        if ($Event[2]) {
            $Services = $Event[2] -replace "`"", ""
        }
        $Application =  Convert-DevicePathToDriveLetter -Path ($Event[7]  -replace "`"", "")
        Show-Balloon -TipTitle "Windows Firewall" -TipText ("Notifications for {0} are now hidden." -f $Application) -TipIcon Info -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
    } elseif ($Arguments.Contains("advfirewall:allow")) {
        $Arguments = ($Arguments -split "=")
        $Event = [System.Net.WebUtility]::UrlDecode($Arguments[1])
        $Event = $Event -split ","
        if ($Event[2]) {
            $Services = $Event[2] -replace "`"", ""
        }
        $Application =  Convert-DevicePathToDriveLetter -Path ($Event[7]  -replace "`"", "")
        Show-Balloon -TipTitle "Windows Firewall" -TipText ("Notifications for {0} are now hidden." -f $Application) -TipIcon Info -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
    }
}

# start shell:StartUp
# start advfirewall:allow=$(Get-Content -Path C:\Portable\advfirewall\advfirewall-events.csv -Tail 1)
