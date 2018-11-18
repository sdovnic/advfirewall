if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
}

if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSCommandPath = $MyInvocation.MyCommand.Definition
}

$Administrator = (
        [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole(
        [Security.Principal.WindowsBuiltInRole] "Administrator"
    )

if (-not $Administrator) {
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

Import-LocalizedData -BaseDirectory $PSScriptRoot\Locales -BindingVariable Messages -Verbose

Import-Module -Name (Join-Path -Path $PSScriptRoot\Modules -ChildPath Show-Balloon) -Verbose
Import-Module -Name (Join-Path -Path $PSScriptRoot\Modules -ChildPath Add-ShortCut) -Verbose
Import-Module -Name (Join-Path -Path $PSScriptRoot\Modules -ChildPath Remove-ShortCut) -Verbose

if ($args.Length -gt 0) {
    [string] $TaskName = "advfirewall-log-event"
    [string] $TaskScript = (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-log-event.ps1")
    [string] $LogFile = (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events.csv")
    [string] $TaskDescription = $Messages."Records Windows Firewall events, requires {0}, and writes to file {1}." -f $TaskScript, $LogFile
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
		<MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
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
    if ($args[0].Contains("local")) {
    } elseif ($args[0].Contains("notification")) {
        if (-not (Test-Path -Path "HKCU:\Software\Classes\advfirewall" -ErrorAction SilentlyContinue)) {
            New-Item -Path "HKCU:\Software\Classes\advfirewall" -Verbose
            Set-ItemProperty -Path "HKCU:\Software\Classes\advfirewall" -Name "(Default)" -Value "URL:advfirewall Protocol" -Verbose
        }

        if (-not (Get-ItemProperty -Path "HKCU:\Software\Classes\advfirewall" -Name "EditFlags" -ErrorAction SilentlyContinue)) {
            New-ItemProperty -Path "HKCU:\Software\Classes\advfirewall" -Name "EditFlags" -Value 0x00210000 -Verbose
        }
        if (-not (Get-ItemProperty -Path "HKCU:\Software\Classes\advfirewall" -Name "URL Protocol" -ErrorAction SilentlyContinue)) {
            New-ItemProperty -Path "HKCU:\Software\Classes\advfirewall" -Name "URL Protocol" -Value "" -Verbose
        }

        if (-not (Test-Path -Path "HKCU:\Software\Classes\advfirewall\DefaultIcon" -ErrorAction SilentlyContinue)) {
            New-Item -Path "HKCU:\Software\Classes\advfirewall\DefaultIcon" -Verbose
            Set-ItemProperty -Path "HKCU:\Software\Classes\advfirewall\DefaultIcon" -Name "(Default)" `
                             -Value "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -Verbose
        }

        if (-not (Test-Path -Path "HKCU:\Software\Classes\advfirewall\shell" -ErrorAction SilentlyContinue)) {
            New-Item -Path "HKCU:\Software\Classes\advfirewall\shell" -Verbose
        }

        if (-not (Test-Path -Path "HKCU:\Software\Classes\advfirewall\shell\open" -ErrorAction SilentlyContinue)) {
            New-Item -Path "HKCU:\Software\Classes\advfirewall\shell\open" -Verbose
        }

        if (-not (Test-Path -Path "HKCU:\Software\Classes\advfirewall\shell\open\command" -ErrorAction SilentlyContinue)) {
            New-Item -Path "HKCU:\Software\Classes\advfirewall\shell\open\command" -Verbose
            Set-ItemProperty -Path "HKCU:\Software\Classes\advfirewall\shell\open\command" -Name "(Default)" `
                             -Value "$(Join-Path -Path $PSHOME -ChildPath "powershell.exe") -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSScriptRoot\advfirewall-notification-helper.ps1`" `"%1`"" -Verbose
        }
        $Username = Get-WMIObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Username | Split-Path -Leaf
        if (-not ($env:USERNAME -eq $Username)) {
            $Path = [Environment]::GetFolderPath("StartUp") -replace $env:USERNAME, $Username
        } else {
            $Path = [Environment]::GetFolderPath("StartUp")
        }
        Add-ShortCut -Link (Join-Path -Path $Path -ChildPath ("{0}.lnk" -f $Messages."Windows Firewall Notification")) `
                     -TargetPath (Join-Path -Path $PSHOME -ChildPath "powershell.exe") `
                     -Arguments "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSScriptRoot\advfirewall-notification.ps1`"" `
                     -IconLocation "%SystemRoot%\system32\miguiresource.dll,0" `
                     -Description $Messages."Notification for Windows Firewall events."
        $Username = Get-WMIObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Username | Split-Path -Leaf
        if (-not ($env:USERNAME -eq $Username)) {
            $Path = [Environment]::GetFolderPath("Programs") -replace $env:USERNAME, $Username
        } else {
            $Path = [Environment]::GetFolderPath("Programs")
        }
        Add-ShortCut -Link (Join-Path -Path $Path -ChildPath ("{0}.lnk" -f $Messages."Windows Firewall Notification")) `
                     -TargetPath (Join-Path -Path $PSHOME -ChildPath "powershell.exe") `
                     -Arguments "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSScriptRoot\advfirewall-notification-helper.ps1`"" `
                     -IconLocation "%SystemRoot%\system32\FirewallControlPanel.dll,2" `
                     -Description $Messages."Notification for Windows Firewall events."
        Add-Type -AssemblyName System.Windows.Forms
        Show-Balloon -TipTitle "Windows Firewall" -TipText $Messages."Windows Firewall Notification installed." `
                     -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
        $Result = [System.Windows.Forms.MessageBox]::Show(
            $Messages."Windows Firewall Notification installed.", "Windows Firewall", 0,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    } elseif ($args[0].Contains("logger")) {
        if (Get-Command -Name Get-ScheduledTask -ErrorAction SilentlyContinue) {
            if (Get-ScheduledTask -TaskName $TaskName -TaskPath "\" -ErrorAction SilentlyContinue) {
                Write-Warning -Message $Messages."Task already exist!"
            } else {
                $TaskTemplate = $TaskTemplate -replace "<Description>(.*)</Description>", "<Description>$TaskDescription</Description>"
                $TaskTemplate = $TaskTemplate -replace "<URI>(.*)</URI>", "<URI>\$TaskName</URI>"
                $TaskTemplate = $TaskTemplate -replace "<Command>(.*)</Command>", "<Command>$TaskCommand</Command>"
                $TaskTemplate = $TaskTemplate -replace "<Arguments>(.*)</Arguments>", "<Arguments>$TaskArguments</Arguments>"
                Set-Content -Path $TaskFile -Value $TaskTemplate
                Start-Process -FilePath "schtasks" `
                              -ArgumentList ("/Create", "/TN `"\$TaskName`"", "/XML `"$PSScriptRoot\$TaskName.xml`"") `
                              -WindowStyle Hidden -Wait
                Start-Process -FilePath "auditpol" `
                              -ArgumentList ("/set", "/subcategory:{0CCE9226-69AE-11D9-BED3-505054503030}", "/failure:enable") `
                              -WindowStyle Hidden
                Remove-Item -Path $TaskFile
            }
        } else {
            Write-Warning -Message $Messages."Get-ScheduledTask not supported, using Schtasks."
            $Query = schtasks /Query /TN "\$TaskName" | Out-String
            if ($Query.Contains($TaskName)) {
                Write-Warning -Message $Messages."Task already exist!"
            } else {
                $TaskTemplate = $TaskTemplate -replace "<Description>(.*)</Description>", "<Description>$TaskDescription</Description>"
                $TaskTemplate = $TaskTemplate -replace "<URI>(.*)</URI>", "<URI>\$TaskName</URI>"
                $TaskTemplate = $TaskTemplate -replace "<Command>(.*)</Command>", "<Command>$TaskCommand</Command>"
                $TaskTemplate = $TaskTemplate -replace "<Arguments>(.*)</Arguments>", "<Arguments>$TaskArguments</Arguments>"
                Set-Content -Path $TaskFile -Value $TaskTemplate
                Start-Process -FilePath "schtasks" `
                              -ArgumentList ("/Create", "/TN `"\$TaskName`"", "/XML `"$PSScriptRoot\$TaskName.xml`"") `
                              -WindowStyle Hidden -Wait
                Start-Process -FilePath "auditpol" `
                              -ArgumentList ("/set", "/subcategory:{0CCE9226-69AE-11D9-BED3-505054503030}", "/failure:enable") `
                              -WindowStyle Hidden
                Remove-Item -Path $TaskFile
            }
        }
        $Username = Get-WMIObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Username | Split-Path -Leaf
        if (-not ($env:USERNAME -eq $Username)) {
            $Path = [Environment]::GetFolderPath("StartMenu") -replace $env:USERNAME, $Username
        } else {
            $Path = [Environment]::GetFolderPath("StartMenu")
        }
        Add-ShortCut -Link (Join-Path -Path $Path -ChildPath ("{0}.lnk" -f $Messages."Windows Firewall Events")) `
                     -TargetPath (Join-Path -Path $PSHOME -ChildPath "powershell.exe") `
                     -Arguments "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PSScriptRoot\advfirewall-view-events.ps1`"" `
                     -IconLocation "%SystemRoot%\system32\miguiresource.dll,0" `
                     -Description $Messages."Displays the recorded events of the Windows Firewall."
        Add-Type -AssemblyName System.Windows.Forms
        Show-Balloon -TipTitle "Windows Firewall" -TipText $Messages."Windows Firewall Event Logging installed." `
                     -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
        $Result = [System.Windows.Forms.MessageBox]::Show(
            $Messages."Windows Firewall Event Logging installed.", "Windows Firewall", 0,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
    } elseif ($args[0].Contains("remove")) {
        if ($args.Length -gt 1) {
            if ($args[1].Contains("local")) {
            } elseif ($args[1].Contains("notification")) {
                if (Test-Path -Path "HKCU:\Software\Classes\advfirewall" -ErrorAction SilentlyContinue) {
                    Remove-Item -Path "HKCU:\Software\Classes\advfirewall" -Recurse -Verbose
                }
                # Todo: Remove StartUp Link
                $Username = Get-WMIObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Username | Split-Path -Leaf
                if (-not ($env:USERNAME -eq $Username)) {
                    $Path = [Environment]::GetFolderPath("StartUp") -replace $env:USERNAME, $Username
                } else {
                    $Path = [Environment]::GetFolderPath("StartUp")
                }
                Remove-ShortCut -Link (Join-Path -Path $Path -ChildPath ("{0}.lnk" -f $Messages."Windows Firewall Notification")) -Verbose
                Add-Type -AssemblyName System.Windows.Forms
                Show-Balloon -TipTitle "Windows Firewall" -TipText $Messages."Windows Firewall Notification removed." `
                             -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
                $Result = [System.Windows.Forms.MessageBox]::Show(
                    $Messages."Windows Firewall Notification removed.", "Windows Firewall", 0,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            } elseif ($args[1].Contains("logger")) {
                if (Get-Command -Name Get-ScheduledTask -ErrorAction SilentlyContinue) {
                    if (Get-ScheduledTask -TaskName $TaskName -TaskPath "\" -ErrorAction SilentlyContinue) {
                        Unregister-ScheduledTask -TaskName $TaskName -TaskPath "\" -Confirm:$False
                        Start-Process -FilePath "auditpol" `
                                      -ArgumentList ("/set", "/subcategory:{0CCE9226-69AE-11D9-BED3-505054503030}", "/failure:disable") `
                                      -WindowStyle Hidden
                    }
                } else {
                    Write-Warning -Message $Messages."Get-ScheduledTask not supported, using Schtasks."
                    $Query = schtasks /Query /TN "\$TaskName" | Out-String
                    if ($Query.Contains($TaskName)) {
                        [array] $ArgumentList = @("/Delete", "/TN `"\$TaskName`"", "/F")
                        Start-Process -FilePath "schtasks" -ArgumentList $ArgumentList -WindowStyle Hidden
                        Start-Process -FilePath "auditpol" `
                                      -ArgumentList ("/set", "/subcategory:{0CCE9226-69AE-11D9-BED3-505054503030}", "/failure:disable") `
                                      -WindowStyle Hidden
                    }
                }
                $Username = Get-WMIObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Username | Split-Path -Leaf
                if (-not ($env:USERNAME -eq $Username)) {
                    $Path = [Environment]::GetFolderPath("StartMenu") -replace $env:USERNAME, $Username
                } else {
                    $Path = [Environment]::GetFolderPath("StartMenu")
                }
                Remove-ShortCut -Link (Join-Path -Path $Path -ChildPath ("{0}.lnk" -f $Messages."Windows Firewall Events"))
                Add-Type -AssemblyName System.Windows.Forms
                Show-Balloon -TipTitle "Windows Firewall" -TipText $Messages."Windows Firewall Event Logging removed." `
                             -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
                $Result = [System.Windows.Forms.MessageBox]::Show(
                    $Messages."Windows Firewall Event Logging removed.", "Windows Firewall", 0,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            }
        } else {
            Remove-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("SendTo")) `
                            -ChildPath ("{0}.lnk" -f $Messages."Windows Firewall create Outgoing Rule"))
            Remove-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("SendTo")) `
                            -ChildPath ("{0}.lnk" -f $Messages."Windows Firewall create Incoming Rule"))
            Remove-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("StartMenu")) `
                            -ChildPath ("{0}.lnk" -f $Messages."Windows Firewall Pause"))
            Add-Type -AssemblyName System.Windows.Forms
            Show-Balloon -TipTitle "Windows Firewall" -TipText $Messages."Send to Windows Firewall removed." `
                         -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
            $Result = [System.Windows.Forms.MessageBox]::Show(
                $Messages."Send to Windows Firewall removed.", "Windows Firewall", 0,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        }
    }
} else {
    Add-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("SendTo")) `
                 -ChildPath ("{0}.lnk" -f $Messages."Windows Firewall create Outgoing Rule")) `
                 -TargetPath (Join-Path -Path $PSHOME -ChildPath "powershell.exe") `
    			 -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\advfirewall-add-rule.ps1`" out" `
                 -IconLocation "%SystemRoot%\system32\FirewallControlPanel.dll,0" `
                 -WorkingDirectory $PSScriptRoot -WindowStyle Minimized `
                 -Description $Messages."Adds an Outgoing Rule to the Windows Firewall."
    Add-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("SendTo")) `
                 -ChildPath ("{0}.lnk" -f $Messages."Windows Firewall create Incoming Rule")) `
    			 -TargetPath (Join-Path -Path $PSHOME -ChildPath "powershell.exe") `
    			 -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\advfirewall-add-rule.ps1`" in" `
                 -IconLocation "%SystemRoot%\system32\FirewallControlPanel.dll,0" `
                 -WorkingDirectory $PSScriptRoot -WindowStyle Minimized `
                 -Description $Messages."Adds an Incoming Rule to the Windows Firewall."
    Add-ShortCut -Link (Join-Path -Path ([environment]::GetFolderPath("StartMenu")) `
                 -ChildPath ("{0}.lnk" -f $Messages."Windows Firewall Pause")) `
    			 -TargetPath (Join-Path -Path $PSHOME -ChildPath "powershell.exe") `
    			 -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$PSScriptRoot\advfirewall-pause.ps1`"" `
                 -IconLocation "%SystemRoot%\system32\FirewallControlPanel.dll,0" `
                 -WorkingDirectory $PSScriptRoot -WindowStyle Minimized `
                 -Description $Messages."Temporarily turns off Windows Firewall."
    Add-Type -AssemblyName System.Windows.Forms
    Show-Balloon -TipTitle "Windows Firewall" -TipText $Messages."Send to Windows Firewall installed." `
                 -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
    $Result = [System.Windows.Forms.MessageBox]::Show(
        $Messages."Send to Windows Firewall installed.", "Windows Firewall", 0,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
}
