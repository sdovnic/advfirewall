#$Action = 'Write-Output "The watched file was changed"'
$global:FileChanged = $false
$VerbosePreference = "Continue"

if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
}

if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSCommandPath = $MyInvocation.MyCommand.Definition
}

if ($psISE) {
    $PSScriptRoot = "C:\Portable\advfirewall"
    Set-Location -Path $PSScriptRoot
    Import-LocalizedData -BaseDirectory $PSScriptRoot\Locales -BindingVariable Messages -FileName advfirewall-notification.psd1
} else {
    Import-LocalizedData -BaseDirectory $PSScriptRoot\Locales -BindingVariable Messages
}

Import-Module -Name (Join-Path -Path $PSScriptRoot\Modules -ChildPath Convert-DevicePathToDriveLetter)

#        [Parameter(Mandatory = $true)] [string] $Log,

function Show-Toast {
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
        )] [String] $Audio = 'Default',
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
        $ApplicationId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
        $ApplicationId = 'Microsoft.Windows.SecHealthUI_cw5n1h2txyewy!SecHealthUI'
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
            $Index = $Index + 1
            $XmlAudio = ("<audio src=`"ms-winsoundevent:Notification.{0}`" loop=`"false`" />" -f $Audio)
        }
        $Image = "file:///C:\Windows\SystemApps\Microsoft.Windows.SecHealthUI_cw5n1h2txyewy\Assets\Square71x71Logo.contrast-black_scale-400.png"
        $Image = "file:///C:\Program Files\Windows Defender\Defendericon.png"
        foreach ($ImageItem in $Image) {
            $Index = $Index + 1
            $XmlImage = ("<image id=`"{0}`" hint-crop=`"none`" placement=`"appLogoOverride`" src=`"{1}`"/>" -f ($Index, $ImageItem))
        }
        
    }
    process {
        $XmlToast = @"
            <toast launch="advfirewall:choice" activationType="protocol" $($XmlDuration)>
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
                    <action activationType="protocol" content="$($Messages."Close")" arguments="advfirewall:pid=$($PID)" />
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
    param(
        [string]$File,
        [string]$Action
    )
    $FilePath = Split-Path $File -Parent
    $FileName = Split-Path $File -Leaf
    #$ScriptBlock = [scriptblock]::Create($Action)

    $Watcher = New-Object IO.FileSystemWatcher $FilePath, $FileName -Property @{ 
        IncludeSubdirectories = $false
        EnableRaisingEvents = $true
    }
    $onChange = Register-ObjectEvent $Watcher Changed -Action {$global:FileChanged = $true}

    while ($global:FileChanged -eq $false){
        Start-Sleep -Milliseconds 100
    }

    #& $ScriptBlock

########

$Log = (Get-Content -Path "C:\Portable\advfirewall\advfirewall-events.csv" -Tail 1)
$Last = $Log -split ","
$Log = [System.Text.Encoding]::UTF8.GetBytes($Log)
$Log = [Convert]::ToBase64String($Log)

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
[string] $Executable = ($Last[7] -split "\\")[-1]
$Application = Convert-DevicePathToDriveLetter -Path $Application

[string] $SystemTime = $Last[8] -replace "`"", ""

[int] $ThreadId = $Last[9] -replace "`"", ""

[string] $DestAddress = $Last[10] -replace "`"", ""


if ($Application) {
    $ApplicationText = ("{0}: {1}" -f ($Messages."Application", $Application))
}

if ($Services) {
    $ServicesText = ("{0}: {1}" -f ($Messages."Services", $Services))
}

Show-Toast -Text $Messages."Network connection rejected", $ApplicationText, $ServicesText `
           -Duration short -Audio Default -BindingTemplate ToastGeneric `
           -DirectionName ("{0}: {1}" -f ($Messages."Direction", $DirectionName)) `
           -DestAddress ("{0}: {1}" -f ($Messages."Address", $DestAddress)) `
           -DestPort ("{0}: {1}" -f ($Messages."Port", $DestPort)) `
           -ProcessId ("{0}: {1}" -f ($Messages."Process", $ProcessId)) `
           -ThreadId ("{0}: {1}" -f ($Messages."Thread", $ThreadId)) `
           -Protocol ("{0}: {1}" -f ($Messages."Protocol", $ProtocolName)) `
           -Log $Log

########

    $global:FileChanged = $false

    Unregister-Event -SubscriptionId $onChange.Id
}

$File = "C:\ProgramData\advfirewall\advfirewall-events.csv"
$File = "C:\Portable\advfirewall\advfirewall-events.csv"


while ($true) {
    Wait-FileChange -File $File #-Action $Action
}