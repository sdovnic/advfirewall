If ($PSVersionTable.PSVersion.Major -lt 3) {
    [String] $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
}
If ($PSVersionTable.PSVersion.Major -lt 3) {
    [String] $PSCommandPath = $MyInvocation.MyCommand.Definition
}
If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    [Boolean] $Elevate = $false
    If ($args.Length -gt 1) {
        If ($args[1].Contains("logger")) {
            $Elevate = $true
        }
    } ElseIf ($args.Length -gt 0) {
        If ($args[0].Contains("logger")) {
            $Elevate = $true
        }
    }
    If ($Elevate) {
        Start-Process powershell -WindowStyle Hidden -WorkingDirectory $PSScriptRoot -Verb runAs `
                                 -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $PSCommandPath $args"
        return
    }
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
Function Add-ShortCut {
    Param(
        [Parameter(Mandatory=$true)] [String] $Link,
        [Parameter(Mandatory=$true)] [String] $TargetPath,
        [String] $Arguments,
        [String] $IconLocation,
        [String] $WorkingDirectory,
        [String] $Description,
        [Parameter(Mandatory=$false)] [ValidateSet("Normal", "Minimized", "Maximized")] [String] $WindowStyle
    )
    If (Test-Path -Path $TargetPath) {
        $WShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WShell.CreateShortcut($Link)
        $Shortcut.TargetPath = $TargetPath
        If ($Arguments) { $Shortcut.Arguments = $Arguments; }
        If ($IconLocation) { $Shortcut.IconLocation = $IconLocation; }
        If ($WorkingDirectory) { $Shortcut.WorkingDirectory = $WorkingDirectory; }
        If ($WindowStyle) {
            Switch ($WindowStyle) {
                "Normal" { [Int] $WindowStyleNumerate = 4 };
                "Minimized" { [Int] $WindowStyleNumerate = 7 };
                "Maximized" { [Int] $WindowStyleNumerate = 3 };
            }
            $Shortcut.WindowStyle = $WindowStyleNumerate;
        }
        If ($Description) { $Shortcut.Description = $Description; }
        $Shortcut.Save()
    }
}
Function Remove-Shortcut {
    Param([Parameter(Mandatory=$true)] [String] $Link)
    If (Test-Path -Path $Link) { Remove-Item $Link; }
}
If ($args.Length -gt 0) {
    [string] $TaskName = "advfirewall-log-event"
    [string] $TaskScript = (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-log-event.ps1")
    [string] $LogFile = (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events.log")
    [string] $TaskDescription = "Zeichnet Windows Firewall Ereignisse auf, benötigt $TaskScript und schreibt in die Datei $LogFile."
    [string] $TaskCommand = (Join-Path -Path $PSHOME -ChildPath "powershell.exe")
    [string] $TaskArguments = "-NoProfile -ExecutionPolicy Bypass -File `"$TaskScript`" -pid `$(ProcessID) -threadid `$(ThreadID) -ip `$(DestAddress) -port `$(DestPort) -protocol `$(Protocol) -localport `$(SourcePort) -path `"`$(Application)`""
    [string] $TaskFile = (Join-Path -Path $PSScriptRoot -ChildPath "$TaskName.xml")
    [string] $TaskTemplate = "<?xml version=`"1.0`" encoding=`"UTF-16`"?>
<Task version=`"1.2`" xmlns=`"http://schemas.microsoft.com/windows/2004/02/mit/task`">
	<RegistrationInfo>
		<Date>2015-08-16T03:36:29</Date>
		<Author>Rally Vincent</Author>
		<Description>lalalala</Description>
		<URI>lalalala</URI>
	</RegistrationInfo>
	<Triggers>
		<EventTrigger>
			<StartBoundary>2015-08-16T03:36:29</StartBoundary>
			<Enabled>true</Enabled>
			<Subscription>&lt;QueryList&gt;&lt;Query&gt;&lt;Select Path='Security'&gt;*[System[(Level=4 or Level=0) and (EventID=5157)]] and *[EventData[Data[@Name='LayerRTID']='48']]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
			<ValueQueries>
			<Value name=`"Application`">Event/EventData/Data[@Name='Application']</Value>
			<Value name=`"DestAddress`">Event/EventData/Data[@Name='DestAddress']</Value>
			<Value name=`"DestPort`">Event/EventData/Data[@Name='DestPort']</Value>
			<Value name=`"ProcessID`">Event/EventData/Data[@Name='ProcessID']</Value>
			<Value name=`"Protocol`">Event/EventData/Data[@Name='Protocol']</Value>
			<Value name=`"SourcePort`">Event/EventData/Data[@Name='SourcePort']</Value>
			<Value name=`"ThreadID`">Event/System/Execution/@ThreadID</Value>
			</ValueQueries>
		</EventTrigger>
	</Triggers>
	<Principals>
		<Principal id=`"Author`">
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
	<Actions Context=`"Author`">
		<Exec>
			<Command>lalalala</Command>
			<Arguments>lalalala</Arguments>
		</Exec>
	</Actions>
</Task>"
    If ($args[0].Contains("logger")) {
        If (Get-Command -Name Get-ScheduledTask -ErrorAction SilentlyContinue) {
            If (Get-ScheduledTask -TaskName $TaskName -TaskPath "\" -ErrorAction SilentlyContinue) {
                Write-Warning "Task already exist!"
            } Else {
                $TaskTemplate = $TaskTemplate -replace "<Description>(.*)</Description>", "<Description>$TaskDescription</Description>"
                $TaskTemplate = $TaskTemplate -replace "<URI>(.*)</URI>", "<URI>\$TaskName</URI>"
                $TaskTemplate = $TaskTemplate -replace "<Command>(.*)</Command>", "<Command>$TaskCommand</Command>"
                $TaskTemplate = $TaskTemplate -replace "<Arguments>(.*)</Arguments>", "<Arguments>$TaskArguments</Arguments>"
                Set-Content -Path $TaskFile -Value $TaskTemplate
                Start-Process "schtasks" -ArgumentList ("/Create", "/TN `"\$TaskName`"", "/XML `"$PSScriptRoot\$TaskName.xml`"") -WindowStyle Hidden -Wait
                Start-Process "auditpol" -ArgumentList ("/set", "/subcategory:{0CCE9226-69AE-11D9-BED3-505054503030}", "/failure:enable") -WindowStyle Hidden
                Remove-Item -Path $TaskFile
            }
        } Else {
            Write-Warning "Get-ScheduledTask not supported."
            $Query = schtasks /Query /TN "\$TaskName" | Out-String
            If ($Query.Contains($TaskName)) {
                Write-Warning "Task already exist!"
            } Else {
                $TaskTemplate = $TaskTemplate -replace "<Description>(.*)</Description>", "<Description>$TaskDescription</Description>"
                $TaskTemplate = $TaskTemplate -replace "<URI>(.*)</URI>", "<URI>\$TaskName</URI>"
                $TaskTemplate = $TaskTemplate -replace "<Command>(.*)</Command>", "<Command>$TaskCommand</Command>"
                $TaskTemplate = $TaskTemplate -replace "<Arguments>(.*)</Arguments>", "<Arguments>$TaskArguments</Arguments>"
                Set-Content -Path $TaskFile -Value $TaskTemplate
                Start-Process "schtasks" -ArgumentList ("/Create", "/TN `"\$TaskName`"", "/XML `"$PSScriptRoot\$TaskName.xml`"") -WindowStyle Hidden -Wait
                Start-Process "auditpol" -ArgumentList ("/set", "/subcategory:{0CCE9226-69AE-11D9-BED3-505054503030}", "/failure:enable") -WindowStyle Hidden
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
                     -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\advfirewall-view-events.ps1`"" `
                     -IconLocation "%SystemRoot%\system32\miguiresource.dll,0" `
                     -Description "Zeigt die aufgezeichneten Ereignisse der Windows Firewall an."
        Add-Type -AssemblyName System.Windows.Forms
        $Result = [System.Windows.Forms.MessageBox]::Show(
            "Windows Firewall Event Logging installiert.", "Windows Firewall", 0,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        Show-Balloon -TipTitle "Windows Firewall" -TipText "Windows Firewall Event Logging installiert." `
                     -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
    } ElseIf ($args[0].Contains("remove")) {
        If ($args.Length -gt 1) {
            If ($args[1].Contains("logger")) {
                If (Get-Command -Name Get-ScheduledTask -ErrorAction SilentlyContinue) {
                    If (Get-ScheduledTask -TaskName $TaskName -TaskPath "\" -ErrorAction SilentlyContinue) {
                        Unregister-ScheduledTask -TaskName $TaskName -TaskPath "\" -Confirm:$False
                        Start-Process "auditpol" -ArgumentList ("/set", "/subcategory:{0CCE9226-69AE-11D9-BED3-505054503030}", "/failure:disable") -WindowStyle Hidden
                    }
                } Else {
                    Write-Warning "Get-ScheduledTask not supported."
                    $Query = schtasks /Query /TN "\$TaskName" | Out-String
                    If ($Query.Contains($TaskName)) {
                        [array] $ArgumentList = @("/Delete", "/TN `"\$TaskName`"", "/F")
                        Start-Process "schtasks" -ArgumentList $ArgumentList -WindowStyle Hidden
                        Start-Process "auditpol" -ArgumentList ("/set", "/subcategory:{0CCE9226-69AE-11D9-BED3-505054503030}", "/failure:disable") -WindowStyle Hidden
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
                $Result = [System.Windows.Forms.MessageBox]::Show(
                    "Windows Firewall Event Logging entfernt.", "Windows Firewall", 0,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
                Show-Balloon -TipTitle "Windows Firewall" -TipText "Windows Firewall Event Logging entfernt." `
                             -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
            }
        } Else {
            Remove-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("SendTo")) -ChildPath "Windows Firewall Ausgehende Regel eintragen.lnk")
            Remove-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("SendTo")) -ChildPath "Windows Firewall Eingehende Regel eintragen.lnk")
            Remove-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("StartMenu")) -ChildPath "Windows Firewall Pause.lnk")
            Add-Type -AssemblyName System.Windows.Forms
            $Result = [System.Windows.Forms.MessageBox]::Show(
                "Senden an Windows Firewall entfernt.", "Windows Firewall", 0,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
            Show-Balloon -TipTitle "Windows Firewall" -TipText "Senden an Windows Firewall entfernt." `
                         -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
        }
    }
} Else {
    Add-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("SendTo")) -ChildPath "Windows Firewall Ausgehende Regel eintragen.lnk") `
                 -TargetPath (Join-Path -Path $PSHOME -ChildPath "powershell.exe") `
    			 -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\advfirewall-add-rule.ps1`" out" `
                 -IconLocation "%SystemRoot%\system32\FirewallControlPanel.dll,0" `
                 -WorkingDirectory $PSScriptRoot -WindowStyle Minimized `
                 -Description "Trägt eine Ausgehende Regel in die Windows Firewall ein."
    Add-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("SendTo")) -ChildPath "Windows Firewall Eingehende Regel eintragen.lnk") `
    			 -TargetPath (Join-Path -Path $PSHOME -ChildPath "powershell.exe") `
    			 -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\advfirewall-add-rule.ps1`" in" `
                 -IconLocation "%SystemRoot%\system32\FirewallControlPanel.dll,0" `
                 -WorkingDirectory $PSScriptRoot -WindowStyle Minimized `
                 -Description "Trägt eine Einghende Regel in die Windows Firewall ein."
    Add-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("StartMenu")) -ChildPath "Windows Firewall Pause.lnk") `
    			 -TargetPath (Join-Path -Path $PSHOME -ChildPath "powershell.exe") `
    			 -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\advfirewall-pause.ps1`"" `
                 -IconLocation "%SystemRoot%\system32\FirewallControlPanel.dll,0" `
                 -WorkingDirectory $PSScriptRoot -WindowStyle Minimized `
                 -Description "Schaltet vorübergehend die Windows Firewall aus."
    Add-Type -AssemblyName System.Windows.Forms
    $Result = [System.Windows.Forms.MessageBox]::Show(
        "Senden an Windows Firewall installiert.", "Windows Firewall", 0,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    Show-Balloon -TipTitle "Windows Firewall" -TipText "Senden an Windows Firewall installiert." `
                 -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
}
