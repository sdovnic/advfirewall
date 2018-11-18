if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
}

if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSCommandPath = $MyInvocation.MyCommand.Definition
}

Start-Transcript -Path $PSScriptRoot\advfirewall-notification-helper.log

Import-LocalizedData -BaseDirectory $PSScriptRoot\Locales -BindingVariable Messages
# Todo: Add Translations

Import-Module -Name (Join-Path -Path $PSScriptRoot\Modules -ChildPath Show-Balloon)
Import-Module -Name (Join-Path -Path $PSScriptRoot\Modules -ChildPath Convert-DevicePathToDriveLetter)

if (-not (Test-Path -Path $PSScriptRoot\advfirewall-notification-settings.xml)) {
    [System.Collections.ArrayList] $Applications = @()
    [System.Collections.ArrayList] $Services = @()
    $Settings = @{
        "Audio" = "Default"
        "Hidden" = @{
            "Services" = $Services
            "Applications" = $Applications
        }
    }
    $Settings |  Export-Clixml -Path $PSScriptRoot\advfirewall-notification-settings.xml -Verbose
    $Settings = Import-Clixml -Path $PSScriptRoot\advfirewall-notification-settings.xml -Verbose
} else {
    $Settings = Import-Clixml -Path $PSScriptRoot\advfirewall-notification-settings.xml -Verbose
}

function Show-Form {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Application]::EnableVisualStyles()
    
    $WindowsFirewallNotificationSettingsForm = New-Object system.Windows.Forms.Form
    $WindowsFirewallNotificationSettingsForm.ClientSize = '400,400'
    $WindowsFirewallNotificationSettingsForm.text = "Windows Firewall Notification Settings"
    $WindowsFirewallNotificationSettingsForm.TopMost = $false
    $WindowsFirewallNotificationSettingsForm.Icon = [system.drawing.icon]::ExtractAssociatedIcon("$env:SystemRoot\system32\FirewallControlPanel.dll")
    
    $ComboBoxAudio = New-Object system.Windows.Forms.ComboBox
    $ComboBoxAudio.width = 200
    $ComboBoxAudio.height = 31
    @(
        '',
        'Default',
        'IM',
        'Mail',
        'Reminder',
        'SMS',
        'Looping.Alarm',
        'Looping.Alarm2',
        'Looping.Alarm3',
        'Looping.Alarm4',
        'Looping.Alarm5',
        'Looping.Alarm6',
        'Looping.Alarm7',
        'Looping.Alarm8',
        'Looping.Alarm9',
        'Looping.Alarm10',
        'Looping.Call',
        'Looping.Call2',
        'Looping.Call3',
        'Looping.Call4',
        'Looping.Call5',
        'Looping.Call6',
        'Looping.Call7',
        'Looping.Call8',
        'Looping.Call9',
        'Looping.Call10'
    ) | ForEach-Object -Process {
        [void] $ComboBoxAudio.Items.Add($_)
    }
    $ComboBoxAudio.location = New-Object System.Drawing.Point(15,17)
    $ComboBoxAudio.Font = 'Microsoft Sans Serif,10'
    if ($Settings.Audio) {
        $ComboBoxAudio.SelectedIndex = $ComboBoxAudio.FindStringExact($Settings.Audio)
    }
    
    $ButtonAudio = New-Object system.Windows.Forms.Button
    $ButtonAudio.text = "Set Audio"
    $ButtonAudio.width = 160
    $ButtonAudio.height = 30
    $ButtonAudio.Anchor = 'top,right'
    $ButtonAudio.location = New-Object System.Drawing.Point(229,15)
    $ButtonAudio.Font = 'Microsoft Sans Serif,10'
    
    $ButtonUnhideApplications = New-Object system.Windows.Forms.Button
    $ButtonUnhideApplications.text = "Unhide Applications"
    $ButtonUnhideApplications.width = 372
    $ButtonUnhideApplications.height = 30
    $ButtonUnhideApplications.location = New-Object System.Drawing.Point(15,65)
    $ButtonUnhideApplications.Font = 'Microsoft Sans Serif,10'
    
    $ButtonUnhideServices = New-Object system.Windows.Forms.Button
    $ButtonUnhideServices.text = "Unhide Services"
    $ButtonUnhideServices.width = 372
    $ButtonUnhideServices.height = 30
    $ButtonUnhideServices.location = New-Object System.Drawing.Point(15,114)
    $ButtonUnhideServices.Font = 'Microsoft Sans Serif,10'
    
    $ButtonStop = New-Object system.Windows.Forms.Button
    $ButtonStop.text = "Stop Notifications"
    $ButtonStop.width = 372
    $ButtonStop.height = 30
    $ButtonStop.location = New-Object System.Drawing.Point(15,162)
    $ButtonStop.Font = 'Microsoft Sans Serif,10'
    
    $ButtonStart = New-Object system.Windows.Forms.Button
    $ButtonStart.text = "Start Notifications"
    $ButtonStart.width = 372
    $ButtonStart.height = 30
    $ButtonStart.location = New-Object System.Drawing.Point(15,210)
    $ButtonStart.Font = 'Microsoft Sans Serif,10'
    
    $ButtonClose = New-Object system.Windows.Forms.Button
    $ButtonClose.text = "Close"
    $ButtonClose.width = 106
    $ButtonClose.height = 30
    $ButtonClose.location = New-Object System.Drawing.Point(280,358)
    $ButtonClose.Font = 'Microsoft Sans Serif,10'
    
    $WindowsFirewallNotificationSettingsForm.controls.AddRange(
        @(
            $ComboBoxAudio,
            $ButtonAudio,
            $ButtonUnhideApplications,
            $ButtonUnhideServices,
            $ButtonStop,
            $ButtonStart,
            $ButtonClose
        )
    )
    
    $ButtonAudio.Add_Click({
        ButtonAudioClick
    })
    $ButtonUnhideApplications.Add_Click({
        ButtonUnhideApplicationsClick
    })
    $ButtonUnhideServices.Add_Click({ ButtonUnhideServicesClick })
    $ButtonStop.Add_Click({ ButtonStopClick })
    $ButtonStart.Add_Click({ ButtonStartClick })
    $ButtonClose.Add_Click({ ButtonCloseClick })
    
    function ButtonUnhideApplicationsClick {
        if ($Settings.Hidden.Applications) {
            $Selected = @()
            $Settings.Hidden.Applications | Out-GridView -PassThru | ForEach-Object -Process {
                $Selected += $_
                # Todo: Unhide Applications
            }
            if ($Selected) {
                [System.Windows.Forms.MessageBox]::Show(($Selected -join ", "), "Unhided Applications")
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show("No Applications hidden.", "Unhided Applications")
        }
    }
    function ButtonUnhideServicesClick {
        if ($Settings.Hidden.Services) {
            $Selected = @()
            $Settings.Hidden.Services | Out-GridView -PassThru | ForEach-Object -Process {
                $Selected += $_
                # Todo: Unhide Services
            }
            if ($Selected) {
                [System.Windows.Forms.MessageBox]::Show(($Selected -join ", "), "Unhide Services")
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show("No Services hidden.", "Unhide Services")
        }
    }
    function ButtonAudioClick {
        # $ComboBoxAudio.SelectedItem
        # [System.Windows.Forms.MessageBox]::Show($Settings.Audio, "Current")
        if ($ComboBoxAudio.SelectedItem) {
            [System.Windows.Forms.MessageBox]::Show($ComboBoxAudio.SelectedItem, "Audio set to")
            $Settings.Audio = $ComboBoxAudio.SelectedItem
            $Settings | Export-Clixml -Path $PSScriptRoot\advfirewall-notification-settings.xml -Verbose
        } else {
            $Settings.Audio = ""
            [System.Windows.Forms.MessageBox]::Show("Silent", "Audio set to")
        }
    }
    function ButtonStopClick {
        $CurrentPID = Get-Content -Path $PSScriptRoot\advfirewall-notification.pid -First 1 -Verbose
        Stop-Process -Id $CurrentPID -Verbose
        [System.Windows.Forms.MessageBox]::Show("Stopped", "Notifications")
    }
    function ButtonStartClick {
        & powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "$PSScriptRoot\advfirewall-notification.ps1"
        [System.Windows.Forms.MessageBox]::Show("Started", "Notifications")
    }
    function ButtonCloseClick {
        [void] $WindowsFirewallNotificationSettingsForm.Close()
    }
    
    [void] $WindowsFirewallNotificationSettingsForm.ShowDialog()
}


if ($args) {
    $Arguments = $args[0]
    if ($Arguments.Contains("advfirewall:stop")) {
        $Id = ($Arguments -split "=")[-1]
        Stop-Process -Id $Id -Verbose
        Show-Balloon -TipTitle "Windows Firewall" -TipText ("Advanced Firewall Notifications are now disabled.") `
                     -TipIcon Info -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
    } elseif ($Arguments.Contains("advfirewall:settings")) {
        Show-Form
    } elseif ($Arguments.Contains("advfirewall:hide")) {
        $Arguments = ($Arguments -split "=")
        $Event = [System.Net.WebUtility]::UrlDecode($Arguments[1])
        $Event = $Event -split ","
        if ($Event[2]) {
            $Hidden = $Event[2] -replace "`"", ""
            if (-not $Settings.Hidden.Services.Contains($Hidden)) {
                $Settings.Hidden.Services.Add($Hidden)
            }
        } else {
            $Hidden =  Convert-DevicePathToDriveLetter -Path ($Event[7]  -replace "`"", "")
            if (-not $Settings.Hidden.Applications.Contains($Hidden)) {
                $Settings.Hidden.Applications.Add($Hidden)
            }
        }
        $Settings | Export-Clixml -Path $PSScriptRoot\advfirewall-notification-settings.xml -Verbose

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

        # Todo: Get Direction
        $Direction = "out"

        if (-not $Service) {
            & powershell -File "$PSScriptRoot\advfirewall-add-rule.ps1" $Direction $Application
            Show-Balloon -TipTitle "Windows Firewall" -TipText ("{0} now allowed." -f $Allow) `
                         -TipIcon Info -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
        }
    }
} else {
    Show-Form
}

# start shell:StartUp
# start advfirewall:allow=$(Get-Content -Path C:\Portable\advfirewall\advfirewall-events.csv -Tail 1)

Stop-Transcript