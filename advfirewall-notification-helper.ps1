if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
}

if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSCommandPath = $MyInvocation.MyCommand.Definition
}

Start-Transcript -Path $PSScriptRoot\advfirewall-notification-helper.log

Import-LocalizedData -BaseDirectory $PSScriptRoot\Locales -BindingVariable Messages

Import-Module -Name (Join-Path -Path $PSScriptRoot\Modules -ChildPath Show-Balloon)
Import-Module -Name (Join-Path -Path $PSScriptRoot\Modules -ChildPath Show-MessageBox)
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
    $WindowsFirewallNotificationSettingsForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $WindowsFirewallNotificationSettingsForm.MinimizeBox = $false
    $WindowsFirewallNotificationSettingsForm.MaximizeBox = $false
    $WindowsFirewallNotificationSettingsForm.SizeGripStyle = "Hide"
    $WindowsFirewallNotificationSettingsForm.Text = $Messages."Windows Firewall Notification Settings"
    $WindowsFirewallNotificationSettingsForm.TopMost = $false
    $WindowsFirewallNotificationSettingsForm.Icon = [system.drawing.icon]::ExtractAssociatedIcon("$env:SystemRoot\system32\FirewallControlPanel.dll")
    
    $ComboBoxAudio = New-Object system.Windows.Forms.ComboBox
    $ComboBoxAudio.Width = 200
    $ComboBoxAudio.Height = 31
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
    $ComboBoxAudio.Location = New-Object System.Drawing.Point(15,17)
    $ComboBoxAudio.Font = 'Microsoft Sans Serif,10'
    if ($Settings.Audio) {
        $ComboBoxAudio.SelectedIndex = $ComboBoxAudio.FindStringExact($Settings.Audio)
    }
    
    $ButtonAudio = New-Object system.Windows.Forms.Button
    $ButtonAudio.Text = $Messages."Set Audio"
    $ButtonAudio.Width = 160
    $ButtonAudio.Height = 30
    $ButtonAudio.Anchor = 'top,right'
    $ButtonAudio.Location = New-Object System.Drawing.Point(229,15)
    $ButtonAudio.Font = 'Microsoft Sans Serif,10'
    
    $ButtonUnhideApplications = New-Object system.Windows.Forms.Button
    $ButtonUnhideApplications.Text = $Messages."Unhide Applications"
    $ButtonUnhideApplications.Width = 372
    $ButtonUnhideApplications.Height = 30
    $ButtonUnhideApplications.Location = New-Object System.Drawing.Point(15,65)
    $ButtonUnhideApplications.Font = 'Microsoft Sans Serif,10'
    
    $ButtonUnhideServices = New-Object system.Windows.Forms.Button
    $ButtonUnhideServices.Text = $Messages."Unhide Services"
    $ButtonUnhideServices.Width = 372
    $ButtonUnhideServices.Height = 30
    $ButtonUnhideServices.Location = New-Object System.Drawing.Point(15,114)
    $ButtonUnhideServices.Font = 'Microsoft Sans Serif,10'
    
    $ButtonStop = New-Object system.Windows.Forms.Button
    $ButtonStop.Text = $Messages."Stop Notifications"
    $ButtonStop.Width = 372
    $ButtonStop.Height = 30
    $ButtonStop.Location = New-Object System.Drawing.Point(15,162)
    $ButtonStop.Font = 'Microsoft Sans Serif,10'
    
    $ButtonStart = New-Object system.Windows.Forms.Button
    $ButtonStart.Text = $Messages."Start Notifications"
    $ButtonStart.Width = 372
    $ButtonStart.height = 30
    $ButtonStart.Location = New-Object System.Drawing.Point(15,210)
    $ButtonStart.Font = 'Microsoft Sans Serif,10'
    
    $ButtonClose = New-Object system.Windows.Forms.Button
    $ButtonClose.Text = $Messages."Close"
    $ButtonClose.Width = 106
    $ButtonClose.Height = 30
    $ButtonClose.Location = New-Object System.Drawing.Point(280,358)
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
    $ButtonUnhideServices.Add_Click({
        ButtonUnhideServicesClick
    })
    $ButtonStop.Add_Click({
        ButtonStopClick
    })
    $ButtonStart.Add_Click({
        ButtonStartClick
    })
    $ButtonClose.Add_Click({
        ButtonCloseClick
    })
    
    function ButtonUnhideApplicationsClick {
        $Settings = Import-Clixml -Path $PSScriptRoot\advfirewall-notification-settings.xml -Verbose
        if ($Settings.Hidden.Applications) {
            $Selected = @()
            $Settings.Hidden.Applications | Out-GridView -PassThru -Title $Messages."Select Applications to unhide" | ForEach-Object -Process {
                $Selected += $_
            }
            if ($Selected) {
                foreach ($SelectedItem in $Selected) {
                    $Settings.Hidden.Applications.Remove($SelectedItem)
                }
                $Settings |  Export-Clixml -Path $PSScriptRoot\advfirewall-notification-settings.xml -Verbose
                Show-MessageBox -Caption $Messages."Unhide Applications" -Text ($Selected -join ", ") -Buttons OK -Icon Information
            }
        } else {
            Show-MessageBox -Caption $Messages."Unhide Applications" -Text $Messages."No Applications hidden." -Buttons OK -Icon Error
        }
    }
    function ButtonUnhideServicesClick {
        $Settings = Import-Clixml -Path $PSScriptRoot\advfirewall-notification-settings.xml -Verbose
        if ($Settings.Hidden.Services) {
            $Selected = @()
            $Settings.Hidden.Services | Out-GridView -PassThru -Title $Messages."Select Services to unhide" | ForEach-Object -Process {
                $Selected += $_
            }
            if ($Selected) {
                foreach ($SelectedItem in $Selected) {
                    $Settings.Hidden.Services.Remove($SelectedItem)
                }
                $Settings |  Export-Clixml -Path $PSScriptRoot\advfirewall-notification-settings.xml -Verbose
                Show-MessageBox -Caption $Messages."Unhide Services" -Text ($Selected -join ", ") -Buttons OK -Icon Information
            }
        } else {
            Show-MessageBox -Caption $Messages."Unhide Services" -Text $Messages."No Services hidden." -Buttons OK -Icon Error
        }
    }
    function ButtonAudioClick {
        if ($ComboBoxAudio.SelectedItem) {
            Show-MessageBox -Caption $Messages."Set to" -Text $ComboBoxAudio.SelectedItem -Buttons OK -Icon Information
            $Settings.Audio = $ComboBoxAudio.SelectedItem
            $Settings | Export-Clixml -Path $PSScriptRoot\advfirewall-notification-settings.xml -Verbose
        } else {
            $Settings.Audio = ""
            Show-MessageBox -Caption $Messages."Set to" -Text $Messages."Silent" -Buttons OK -Icon Information
        }
    }
    function ButtonStopClick {
        $CurrentPID = Get-Content -Path $PSScriptRoot\advfirewall-notification.pid -First 1 -Verbose
        if (Get-Process -Id $CurrentPID) {
            Stop-Process -Id $CurrentPID -Verbose
            Show-MessageBox -Caption $Messages."Notifications" -Text $Messages."Stopped" -Buttons OK -Icon Information
        } else {
            Show-MessageBox -Caption $Messages."Notifications" -Text $Messages."Already Stopped" -Buttons OK -Icon Error
        }
    }
    function ButtonStartClick {
        $FilePath = "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe"
        $ArgumentList = (
            "-WindowStyle", "Hidden",
            "-STA",
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", "`"$PSScriptRoot\advfirewall-notification.ps1`""
        )
        $CurrentPID = Get-Content -Path $PSScriptRoot\advfirewall-notification.pid -First 1 -Verbose
        if (Get-Process -Id $CurrentPID) {
            Stop-Process -Id $CurrentPID -Verbose
        }
        Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -PassThru -WindowStyle Hidden
        Start-Sleep 1
        $CurrentPID = Get-Content -Path $PSScriptRoot\advfirewall-notification.pid -First 1 -Verbose
        if (Get-Process -Id $CurrentPID) {
            Show-MessageBox -Caption $Messages."Notifications" -Text $Messages."Started" -Buttons OK -Icon Information
        }
        
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
        Show-Balloon -TipTitle "Windows Firewall" `
                     -TipText ($Messages."Advanced Firewall Notifications are now disabled.") `
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

        Show-Balloon -TipTitle "Windows Firewall" `
                      -TipText ($Messages."Notifications for {0} are now hidden." -f $Hidden) `
                     -TipIcon Info -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
    } elseif ($Arguments.Contains("advfirewall:allow")) {
        $Arguments = ($Arguments -split "=")
        $Event = [System.Net.WebUtility]::UrlDecode($Arguments[1])
        $Event = $Event -split ","
        if ($Event[2]) {
            $Service = $Event[2] -replace "`"", ""
        } else {
            $Application =  Convert-DevicePathToDriveLetter -Path ($Event[7] -replace "`"", "")
        }

        $Direction = @{
            "%%14593" = "out"
            "%%14592" = "in"
        }
        
        if (-not $Service) {
            & powershell -File "$PSScriptRoot\advfirewall-add-rule.ps1" $Direction.Item(($Event[4] -replace "`"", "")) $Application
        }
    }
} else {
    Show-Form
}

# start shell:StartUp
# start advfirewall:allow=$(Get-Content -Path C:\Portable\advfirewall\advfirewall-events.csv -Tail 1)

Stop-Transcript
