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
        Show-Balloon -TipTitle "Windows Firewall" -TipText ("Advanced Firewall Notifications are now disabled.") `
                     -TipIcon Info -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
    } elseif ($Arguments.Contains("advfirewall:hide")) {
        $Arguments = ($Arguments -split "=")
        $Event = [System.Net.WebUtility]::UrlDecode($Arguments[1])
        $Event = $Event -split ","
        if (-not (Test-Path -Path $PSScriptRoot\advfirewall-notification-hide.xml)) {
            [System.Collections.ArrayList] $Applications = @()
            [System.Collections.ArrayList] $Services = @()
            $HiddenEvents = @{
                "Services" = $Services
                "Applications" = $Applications
            }
            $HiddenEvents |  Export-Clixml -Path $PSScriptRoot\advfirewall-notification-hide.xml -Verbose
            $HiddenEvents = Import-Clixml -Path $PSScriptRoot\advfirewall-notification-hide.xml -Verbose
        } else {
            $HiddenEvents = Import-Clixml -Path $PSScriptRoot\advfirewall-notification-hide.xml -Verbose
        }
        if ($Event[2]) {
            $Hidden = $Event[2] -replace "`"", ""
            if (-not $HiddenEvents.Services.Contains($Hidden)) {
                $HiddenEvents.Services.Add($Hidden)
            }
        } else {
            $Hidden =  Convert-DevicePathToDriveLetter -Path ($Event[7]  -replace "`"", "")
            if (-not $HiddenEvents.Applications.Contains($Hidden)) {
                $HiddenEvents.Applications.Add($Hidden)
            }
        }
        $HiddenEvents | Export-Clixml -Path $PSScriptRoot\advfirewall-notification-hide.xml -Verbose

        Show-Balloon -TipTitle "Windows Firewall" -TipText ("Notifications for {0} are now hidden." -f $Hidden) `
                     -TipIcon Info -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
    } elseif ($Arguments.Contains("advfirewall:allow")) {
        $Arguments = ($Arguments -split "=")
        $Event = [System.Net.WebUtility]::UrlDecode($Arguments[1])
        $Event = $Event -split ","
        if ($Event[2]) {
            $Service = $Event[2] -replace "`"", ""
        } else {
            $Application =  Convert-DevicePathToDriveLetter -Path ($Event[7]  -replace "`"", "")
        }

        $Direction = "out"

        if (-not $Service) {
            & powershell -File "$PSScriptRoot\advfirewall-add-rule.ps1" $Direction $Application
            Show-Balloon -TipTitle "Windows Firewall" -TipText ("{0} now allowed." -f $Allow) `
                         -TipIcon Info -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
        }
    }
}

# start shell:StartUp
# start advfirewall:allow=$(Get-Content -Path C:\Portable\advfirewall\advfirewall-events.csv -Tail 1)
