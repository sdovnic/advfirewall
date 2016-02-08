if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
}
if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSCommandPath = $MyInvocation.MyCommand.Definition
}
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    [bool] $Elevate = $false
    if ($args.Length -gt 1) {
        if ($args[1].Contains("logger")) {
            $Elevate = $true
        }
    } elseif ($args.Length -gt 0) {
        if ($args[0].Contains("logger")) {
            $Elevate = $true
        }
    }
    if ($Elevate) {
        Start-Process -FilePath "powershell" -WindowStyle Hidden -WorkingDirectory $PSScriptRoot -Verb runAs `
                      -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $PSCommandPath $args"
        return
    }
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
    [string] $TaskName = "advfirewall-log-event"
    [string] $TaskScript = (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-log-event.ps1")
    [string] $LogFile = (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events.csv")
    [string] $TaskDescription = "Zeichnet Windows Firewall Ereignisse auf, ben$([char]0x00F6)tigt $TaskScript und schreibt in die Datei $LogFile."
    [string] $TaskCommand = (Join-Path -Path $PSHOME -ChildPath "powershell.exe")
    [string] $TaskArguments = "-NoProfile -ExecutionPolicy Bypass -File `"$TaskScript`" -SystemTime `$(SystemTime) -ThreadID `$(ThreadID) -ProcessID `$(ProcessID) -Application `"`$(Application)`" -Direction `$(Direction) -SourceAddress `$(SourceAddress) -SourcePort `$(SourcePort) -DestAddress `$(DestAddress) -DestPort `$(DestPort) -Protocol `$(Protocol)"
    [string] $TaskFile = (Join-Path -Path $PSScriptRoot -ChildPath "$TaskName.xml")
    [string] $TaskTemplate = @'
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
	<RegistrationInfo>
		<Date>2015-08-16T03:36:29</Date>
		<Author>Rally Vincent</Author>
		<Description></Description>
		<URI></URI>
	</RegistrationInfo>
	<Triggers>
		<EventTrigger>
			<StartBoundary>2015-08-16T03:36:29</StartBoundary>
			<Enabled>true</Enabled>
			<Subscription>&lt;QueryList&gt;&lt;Query&gt;&lt;Select Path='Security'&gt;*[System[(Level=4 or Level=0) and (EventID=5157)]] and *[EventData[Data[@Name='LayerRTID']='48']]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
			<ValueQueries>
                <Value name="SystemTime">Event/System/TimeCreated/@SystemTime</Value>
                <Value name="ThreadID">Event/System/Execution/@ThreadID</Value>
                <Value name="ProcessID">Event/EventData/Data[@Name='ProcessID']</Value>
                <Value name="Application">Event/EventData/Data[@Name='Application']</Value>
                <Value name="Direction">Event/EventData/Data[@Name='Direction']</Value>
                <Value name="SourceAddress">Event/EventData/Data[@Name='SourceAddress']</Value>
                <Value name="SourcePort">Event/EventData/Data[@Name='SourcePort']</Value>
                <Value name="DestAddress">Event/EventData/Data[@Name='DestAddress']</Value>
			    <Value name="DestPort">Event/EventData/Data[@Name='DestPort']</Value>
		        <Value name="Protocol">Event/EventData/Data[@Name='Protocol']</Value>
			</ValueQueries>
		</EventTrigger>
	</Triggers>
	<Principals>
		<Principal id="Author">
			<UserId>S-1-5-18</UserId>
			<RunLevel>HighestAvailable</RunLevel>
		</Principal>
	</Principals>
	<Settings>
		<MultipleInstancesPolicy>Parallel</MultipleInstancesPolicy>
		<DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
		<StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
		<AllowHardTerminate>true</AllowHardTerminate>
		<StartWhenAvailable>false</StartWhenAvailable>
		<RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>
		<IdleSettings>
			<StopOnIdleEnd>true</StopOnIdleEnd>
			<RestartOnIdle>false</RestartOnIdle>
		</IdleSettings>
		<AllowStartOnDemand>false</AllowStartOnDemand>
		<Enabled>true</Enabled>
		<Hidden>false</Hidden>
		<RunOnlyIfIdle>false</RunOnlyIfIdle>
		<WakeToRun>false</WakeToRun>
		<ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
		<Priority>7</Priority>
	</Settings>
	<Actions Context="Author">
		<Exec>
			<Command></Command>
			<Arguments></Arguments>
		</Exec>
	</Actions>
</Task>
'@
    if ($args[0].Contains("logger")) {
        if (Get-Command -Name Get-ScheduledTask -ErrorAction SilentlyContinue) {
            if (Get-ScheduledTask -TaskName $TaskName -TaskPath "\" -ErrorAction SilentlyContinue) {
                Write-Warning -Message "Task already exist!"
            } else {
                $TaskTemplate = $TaskTemplate -replace "<Description>(.*)</Description>", "<Description>$TaskDescription</Description>"
                $TaskTemplate = $TaskTemplate -replace "<URI>(.*)</URI>", "<URI>\$TaskName</URI>"
                $TaskTemplate = $TaskTemplate -replace "<Command>(.*)</Command>", "<Command>$TaskCommand</Command>"
                $TaskTemplate = $TaskTemplate -replace "<Arguments>(.*)</Arguments>", "<Arguments>$TaskArguments</Arguments>"
                Set-Content -Path $TaskFile -Value $TaskTemplate
                Start-Process -FilePath "schtasks" -ArgumentList ("/Create", "/TN `"\$TaskName`"", "/XML `"$PSScriptRoot\$TaskName.xml`"") -WindowStyle Hidden -Wait
                Start-Process -FilePath "auditpol" -ArgumentList ("/set", "/subcategory:{0CCE9226-69AE-11D9-BED3-505054503030}", "/failure:enable") -WindowStyle Hidden
                Remove-Item -Path $TaskFile
            }
        } else {
            Write-Warning -Message "Get-ScheduledTask not supported, using Schtasks."
            $Query = schtasks /Query /TN "\$TaskName" | Out-String
            if ($Query.Contains($TaskName)) {
                Write-Warning -Message "Task already exist!"
            } else {
                $TaskTemplate = $TaskTemplate -replace "<Description>(.*)</Description>", "<Description>$TaskDescription</Description>"
                $TaskTemplate = $TaskTemplate -replace "<URI>(.*)</URI>", "<URI>\$TaskName</URI>"
                $TaskTemplate = $TaskTemplate -replace "<Command>(.*)</Command>", "<Command>$TaskCommand</Command>"
                $TaskTemplate = $TaskTemplate -replace "<Arguments>(.*)</Arguments>", "<Arguments>$TaskArguments</Arguments>"
                Set-Content -Path $TaskFile -Value $TaskTemplate
                Start-Process -FilePath "schtasks" -ArgumentList ("/Create", "/TN `"\$TaskName`"", "/XML `"$PSScriptRoot\$TaskName.xml`"") -WindowStyle Hidden -Wait
                Start-Process -FilePath "auditpol" -ArgumentList ("/set", "/subcategory:{0CCE9226-69AE-11D9-BED3-505054503030}", "/failure:enable") -WindowStyle Hidden
                Remove-Item -Path $TaskFile
            }
        }
        $Username = Get-WMIObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Username | Split-Path -Leaf
        if (-not ($env:USERNAME -eq $Username)) {
            $Path = [Environment]::GetFolderPath("StartMenu") -replace $env:USERNAME, $Username
        } else {
            $Path = [Environment]::GetFolderPath("StartMenu")
        }
        Add-ShortCut -Link (Join-Path -Path $Path -ChildPath "Windows Firewall Ereignisse.lnk") `
                     -TargetPath (Join-Path -Path $PSHOME -ChildPath "powershell.exe") `
                     -Arguments "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSScriptRoot\advfirewall-view-events.ps1`"" `
                     -IconLocation "%SystemRoot%\system32\miguiresource.dll,0" `
                     -Description "Zeigt die aufgezeichneten Ereignisse der Windows Firewall an."
        Add-Type -AssemblyName System.Windows.Forms
        Show-Balloon -TipTitle "Windows Firewall" -TipText "Windows Firewall Event Logging installiert." `
                     -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
        $Result = [System.Windows.Forms.MessageBox]::Show(
            "Windows Firewall Event Logging installiert.", "Windows Firewall", 0,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    } elseif ($args[0].Contains("remove")) {
        if ($args.Length -gt 1) {
            if ($args[1].Contains("logger")) {
                if (Get-Command -Name Get-ScheduledTask -ErrorAction SilentlyContinue) {
                    if (Get-ScheduledTask -TaskName $TaskName -TaskPath "\" -ErrorAction SilentlyContinue) {
                        Unregister-ScheduledTask -TaskName $TaskName -TaskPath "\" -Confirm:$False
                        Start-Process -FilePath "auditpol" -ArgumentList ("/set", "/subcategory:{0CCE9226-69AE-11D9-BED3-505054503030}", "/failure:disable") -WindowStyle Hidden
                    }
                } else {
                    Write-Warning -Message "Get-ScheduledTask not supported, using Schtasks."
                    $Query = schtasks /Query /TN "\$TaskName" | Out-String
                    if ($Query.Contains($TaskName)) {
                        [array] $ArgumentList = @("/Delete", "/TN `"\$TaskName`"", "/F")
                        Start-Process -FilePath "schtasks" -ArgumentList $ArgumentList -WindowStyle Hidden
                        Start-Process -FilePath "auditpol" -ArgumentList ("/set", "/subcategory:{0CCE9226-69AE-11D9-BED3-505054503030}", "/failure:disable") -WindowStyle Hidden
                    }
                }
                $Username = Get-WMIObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Username | Split-Path -Leaf
                if (-not ($env:USERNAME -eq $Username)) {
                    $Path = [Environment]::GetFolderPath("StartMenu") -replace $env:USERNAME, $Username
                } else {
                    $Path = [Environment]::GetFolderPath("StartMenu")
                }
                Remove-ShortCut -Link (Join-Path -Path $Path -ChildPath "Windows Firewall Ereignisse.lnk")
                Add-Type -AssemblyName System.Windows.Forms
                Show-Balloon -TipTitle "Windows Firewall" -TipText "Windows Firewall Event Logging entfernt." `
                             -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
                $Result = [System.Windows.Forms.MessageBox]::Show(
                    "Windows Firewall Event Logging entfernt.", "Windows Firewall", 0,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }
        } else {
            Remove-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("SendTo")) -ChildPath "Windows Firewall Ausgehende Regel eintragen.lnk")
            Remove-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("SendTo")) -ChildPath "Windows Firewall Eingehende Regel eintragen.lnk")
            Remove-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("StartMenu")) -ChildPath "Windows Firewall Pause.lnk")
            Add-Type -AssemblyName System.Windows.Forms
            Show-Balloon -TipTitle "Windows Firewall" -TipText "Senden an Windows Firewall entfernt." `
                         -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
            $Result = [System.Windows.Forms.MessageBox]::Show(
                "Senden an Windows Firewall entfernt.", "Windows Firewall", 0,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
    }
} else {
    Add-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("SendTo")) -ChildPath "Windows Firewall Ausgehende Regel eintragen.lnk") `
                 -TargetPath (Join-Path -Path $PSHOME -ChildPath "powershell.exe") `
    			 -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\advfirewall-add-rule.ps1`" out" `
                 -IconLocation "%SystemRoot%\system32\FirewallControlPanel.dll,0" `
                 -WorkingDirectory $PSScriptRoot -WindowStyle Minimized `
                 -Description "Tr$([char]0x00E4)gt eine Ausgehende Regel in die Windows Firewall ein."
    Add-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("SendTo")) -ChildPath "Windows Firewall Eingehende Regel eintragen.lnk") `
    			 -TargetPath (Join-Path -Path $PSHOME -ChildPath "powershell.exe") `
    			 -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\advfirewall-add-rule.ps1`" in" `
                 -IconLocation "%SystemRoot%\system32\FirewallControlPanel.dll,0" `
                 -WorkingDirectory $PSScriptRoot -WindowStyle Minimized `
                 -Description "Tr$([char]0x00E4)gt eine Einghende Regel in die Windows Firewall ein."
    Add-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("StartMenu")) -ChildPath "Windows Firewall Pause.lnk") `
    			 -TargetPath (Join-Path -Path $PSHOME -ChildPath "powershell.exe") `
    			 -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\advfirewall-pause.ps1`"" `
                 -IconLocation "%SystemRoot%\system32\FirewallControlPanel.dll,0" `
                 -WorkingDirectory $PSScriptRoot -WindowStyle Minimized `
                 -Description "Schaltet vor$([char]0x00FC)bergehend die Windows Firewall aus."
    Add-Type -AssemblyName System.Windows.Forms
    Show-Balloon -TipTitle "Windows Firewall" -TipText "Senden an Windows Firewall installiert." `
                 -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
    $Result = [System.Windows.Forms.MessageBox]::Show(
        "Senden an Windows Firewall installiert.", "Windows Firewall", 0,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}
