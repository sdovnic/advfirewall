if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
}

if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSCommandPath = $MyInvocation.MyCommand.Definition
}

Start-Transcript -Path $PSScriptRoot\advfirewall-notification.log

$global:FileChanged = $false

Import-LocalizedData -BaseDirectory $PSScriptRoot\Locales -BindingVariable Messages

Import-Module -Name (Join-Path -Path $PSScriptRoot\Modules -ChildPath Convert-DevicePathToDriveLetter)

if (Test-Path -Path $PSScriptRoot\advfirewall-notification.pid -ErrorAction SilentlyContinue) {
    Stop-Process -Id (Get-Content -Path $PSScriptRoot\advfirewall-notification.pid -First 1) -ErrorAction SilentlyContinue -Verbose
}
$PID | Set-Content -Path $PSScriptRoot\advfirewall-notification.pid -Verbose

$Host.UI.RawUI.WindowTitle = "Windows Firewall Notifications"

function Show-Toast {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] $Log,
        [Parameter(Mandatory = $true)] $DirectionName,
        [Parameter(Mandatory = $true)] $DestAddress,
        [Parameter(Mandatory = $true)] $DestPort,
        [Parameter(Mandatory = $true)] $Protocol,
        [Parameter(Mandatory = $true)] $ProcessId,
        [Parameter(Mandatory = $true)] $ThreadId,
        [Parameter(Mandatory = $true)] $Text,
        [Parameter(Mandatory = $false)] [ValidateSet('long', 'short')] [string] $Duration,
        [Parameter(Mandatory = $false, ParameterSetName = 'Audio')] [ValidateSet(
            'Default', 'IM', 'Mail', 'Reminder', 'SMS',
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
        )] [String] $Audio,
        [Parameter(Mandatory = $false)] [ValidateSet(
            "ToastImageAndText01",
            "ToastImageAndText02",
            "ToastImageAndText03",
            "ToastImageAndText04",
            "ToastText01",
            "ToastText02",
            "ToastText03",
            "ToastText04",
            "ToastGeneric"
        )] [string] $BindingTemplate = "ToastGeneric"
    )
    begin {
        $ApplicationId = (Get-StartApps | Where-Object -FilterScript { $_.AppID -match 'SecHealthUI' }).AppID
        [void] [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        [void] [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime]
        [void] [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
        if ($Duration) {
            $XmlDuration = ("duration=`"{0}`"" -f $Duration)
        }
        foreach ($TextItem in $Text) {
            $Index = $Index + 1
            $XmlText = $XmlText + ("<text id=`"{0}`">{1}</text>" -f ($index, $TextItem))
        }
        if ($Audio) {
            $XmlAudio = ("<audio src=`"ms-winsoundevent:Notification.{0}`" loop=`"false`" />" -f $Audio)
        } else {
            $XmlAudio = "<audio silent=`"true`" />"
            # $XmlAudio = ("<audio src=`"ms-winsoundevent:Notification.{0}`" loop=`"false`" />" -f $Audio)
        }
        $ImagePath = ("{0}\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy\Assets\Square71x71Logo.contrast-black_scale-400.png" -f $env:windir)
        if (Test-Path -Path $ImagePath -ErrorAction SilentlyContinue) {
            $Image = ("file:///{0}" -f $ImagePath)
        }
        foreach ($ImageItem in $Image) {
            $Index = $Index + 1
            $XmlImage = ("<image id=`"{0}`" hint-crop=`"none`" placement=`"appLogoOverride`" src=`"{1}`"/>" -f ($Index, $ImageItem))
        }
    }
    process {
        $XmlToast = @"
            <toast launch="advfirewall:settings" activationType="protocol" $($XmlDuration)>
                <visual>
                    <binding template="$($BindingTemplate)">
                        $($XmlText)
                        $($XmlImage)
                        <group>
                            <subgroup>
                                <text hint-style="base">$($DirectionName)</text>
                                <text hint-style="captionSubtle">$($DestAddress)</text>
                                <text hint-style="captionSubtle">$($DestPort)</text>
                                <text hint-style="captionSubtle">$($Protocol)</text>
                            </subgroup>
                            <subgroup>
                                <text hint-style="base"></text>
                                <text hint-style="captionSubtle" hint-align="right">$($ProcessId)</text>
                                <text hint-style="captionSubtle" hint-align="right">$($ThreadId)</text>
                            </subgroup>
                        </group>
                    </binding>
                </visual>
                <actions>
                    <action activationType="protocol" content="$($Messages."Allow")" arguments="advfirewall:allow=$($Log)" />
                    <action activationType="protocol" content="$($Messages."Hide")" arguments="advfirewall:hide=$($Log)" />
                    <action activationType="protocol" content="$($Messages."Settings")" arguments="advfirewall:settings" />
                    
                </actions>
                $($XmlAudio)
            </toast>
"@
        $XmlDocument = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument -Verbose
        $XmlDocument.LoadXml($XmlToast)
        $ToastNotification = New-Object -TypeName Windows.UI.Notifications.ToastNotification -ArgumentList $XmlDocument -Verbose
        $ToastNotificationManager = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($ApplicationId)
        $ToastNotificationManager.Show($ToastNotification)
    }
}

function Wait-FileChange {
    [CmdletBinding()]
    param(
        [string] $File
    )
    $FilePath = Split-Path $File -Parent
    $FileName = Split-Path $File -Leaf

    $Watcher = New-Object IO.FileSystemWatcher $FilePath, $FileName -Property @{ 
        IncludeSubdirectories = $false
        EnableRaisingEvents = $true
    }
    $onChange = Register-ObjectEvent $Watcher Changed -Action {$global:FileChanged = $true} -Verbose
    while ($global:FileChanged -eq $false){
        Start-Sleep -Milliseconds 100 -Verbose
    }
########
$Log = (Get-Content -Path "$PSScriptRoot\advfirewall-events.csv" -Tail 1)
$Last = $Log -split ","
$Log = [System.Net.WebUtility]::UrlEncode($Log)
[hashtable] $Protocol = @{
    1 = "ICMP";
    3 = "GGP";
    6 = "TCP";
    8 = "EGP";
    12 = "PUP";
    17 = "UDP";
    20 = "HMP";
    27 = "RDP";
    46 = "RSVP";
    47 = "PPTP)";
    51 = "AH";
    58 = "IPv6-ICMP"
    50 = "ESP";
    66 = "RVD";
    88 = "IGMP";
    89 = "OSPF";
}
$Direction = @{
    "%%14593" = $Messages."Outgoing";
    "%%14592" = $Messages."Incoming";
}
[int] $ProtocolNumber = $Last[0] -replace "`"", ""
[string] $ProtocolName = ($Protocol[$ProtocolNumber])
[int] $ProcessId = $Last[1] -replace "`"", ""
[string] $Services = $Last[2] -replace "`"", ""
[int] $SourcePort = $Last[3] -replace "`"", ""
[string] $DirectionIdentifier = $Last[4] -replace "`"", ""
[string] $DirectionName = $Direction[$DirectionIdentifier]
[int] $DestPort = $Last[5] -replace "`"", ""
[string] $SourceAddress = $Last[6] -replace "`"", ""
[string] $Application = $Last[7] -replace "`"", ""
$Application = Convert-DevicePathToDriveLetter -Path $Application
[string] $SystemTime = $Last[8] -replace "`"", ""
[int] $ThreadId = $Last[9] -replace "`"", ""
[string] $DestAddress = $Last[10] -replace "`"", ""
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
if ($Services) {
    $ServicesText = ("{0}: {1}" -f ($Messages."Services", $Services))
    if ($Settings.Hidden.Services.Contains($Services)) {
        $Hidden = $true
    }
}
if ($Application) {
    $ApplicationText = ("{0}: {1}" -f ($Messages."Application", $Application))
    if ($Settings.Hidden.Applications.Contains($Application) -and -not $Services) {
        $Hidden = $true
    }
}
if (-not $Hidden) {
    if (Test-Path -Path $PSScriptRoot\advfirewall-notification-settings.xml) {
        $Settings = Import-Clixml -Path $PSScriptRoot\advfirewall-notification-settings.xml
    }

    if ($Settings.Audio) {
        Show-Toast -Text $Messages."Network connection rejected", $ApplicationText, $ServicesText `
                   -Duration short `
                   -BindingTemplate ToastGeneric `
                   -DirectionName ("{0}: {1}" -f ($Messages."Direction", $DirectionName)) `
                   -DestAddress ("{0}: {1}" -f ($Messages."Address", $DestAddress)) `
                   -DestPort ("{0}: {1}" -f ($Messages."Port", $DestPort)) `
                   -ProcessId ("{0}: {1}" -f ($Messages."Process", $ProcessId)) `
                   -ThreadId ("{0}: {1}" -f ($Messages."Thread", $ThreadId)) `
                   -Protocol ("{0}: {1}" -f ($Messages."Protocol", $ProtocolName)) `
                   -Log $Log `
                   -Audio $Settings.Audio `
                   -Verbose 
    } else {
        Show-Toast -Text $Messages."Network connection rejected", $ApplicationText, $ServicesText `
                   -Duration short `
                   -BindingTemplate ToastGeneric `
                   -DirectionName ("{0}: {1}" -f ($Messages."Direction", $DirectionName)) `
                   -DestAddress ("{0}: {1}" -f ($Messages."Address", $DestAddress)) `
                   -DestPort ("{0}: {1}" -f ($Messages."Port", $DestPort)) `
                   -ProcessId ("{0}: {1}" -f ($Messages."Process", $ProcessId)) `
                   -ThreadId ("{0}: {1}" -f ($Messages."Thread", $ThreadId)) `
                   -Protocol ("{0}: {1}" -f ($Messages."Protocol", $ProtocolName)) `
                   -Log $Log `
                   -Verbose 
    }
}
########
    $global:FileChanged = $false
    Unregister-Event -SubscriptionId $onChange.Id -Verbose
}

while ($true) {
    Wait-FileChange -File "$PSScriptRoot\advfirewall-events.csv" -Verbose
}

Stop-Transcript