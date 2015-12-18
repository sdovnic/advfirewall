if (-not ((Get-WmiObject -Class Win32_OperatingSystem).Caption -match "Windows 10")) {
    Show-Balloon -TipTitle "Windows Update Firewall" -TipText "Ihr Betriebssystem ist nicht Microsoft Windows 10." -TipIcon Error
    $Result = [System.Windows.Forms.MessageBox]::Show(
        "Ihr Betriebssystem ist nicht Microsoft Windows 10.", "Windows Update Firewall", 0,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    break
}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process -FilePath "powershell" -WindowStyle Hidden -WorkingDirectory $PSScriptRoot -Verb runAs `
                    -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $PSCommandPath $args"
    return
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
        $FormsNotifyIcon.ShowBalloonTip(500)
        Start-Sleep -Milliseconds 500
        $FormsNotifyIcon.Dispose()
    }
}

function Set-WindowsUpdateFirewall {
    [CmdLetBinding()]
    param(
        [parameter(Mandatory=$true)] [string] $Name,
        [parameter(Mandatory=$true)] [ValidateSet("80", "443")] [string] $Port,
        [parameter(Mandatory=$true)] [string] $LogFile
    )
    begin {
        $Service = "wuauserv"
        $Protocol = "TCP"
        $Program = "%SystemRoot%\System32\svchost.exe"
        if (Test-Path -Path $LogFile) {
            $Import = Import-Csv -Path $LogFile
        } else {
            Show-Balloon -TipTitle "Windows Update Firewall" -TipText "Es konnte kein Firewall Ereignisprotokoll gefunden werden." -TipIcon Error
            $Result = [System.Windows.Forms.MessageBox]::Show(
                "Es konnte kein Firewall Ereignisprotokoll gefunden werden.", "Windows Update Firewall", 0,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            break
        }
    }
    process {
        Write-Verbose -Message "$Name"
        $RemoteAddress = (
            $Import | Where-Object {
                $_.Services -match $Service -and $_.DestPort -match $Port
            } | Select-Object -ExpandProperty DestAddress -Unique
        )
        if (-not (Get-NetFirewallRule -Name $Name -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -Name $Name -DisplayName $Name -Enabled True `
                                -Profile Any -Direction Outbound -Action Allow `
                                -LocalAddress Any -RemoteAddress $RemoteAddress `                                -Protocol $Protocol -LocalPort Any -RemotePort $Port `                                -Program $Program
        }
        $RuleRemoteAddress = (Get-NetFirewallRule -Name $Name | Get-NetFirewallAddressFilter).RemoteAddress
        $NewRemoteAddress = Compare-Object -ReferenceObject $RuleRemoteAddress -DifferenceObject $RemoteAddress -PassThru | Where-Object { $_.SideIndicator -eq '=>' }
        if ($NewRemoteAddress) {
            Write-Verbose -Message "$NewRemoteAddress"
            Set-NetFirewallRule -Name $Name -RemoteAddress $RemoteAddress
            Show-Balloon -TipTitle "Folgende Adressen wurden zu `"$Name`" hinzugef$([char]0x00FC)gt." -TipText ($NewRemoteAddress -join ", ") -TipIcon Info
        } else {
            Show-Balloon -TipTitle "Windows Firewall Update" -TipText "Es wurden keine neuen Adressen zu `"$Name`" hinzugef$([char]0x00FC)gt."  -TipIcon Warning
        }
    }
}

$LogFile = Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events.csv"

Set-WindowsUpdateFirewall -Name "Windows Update 80" -Port 80 -LogFile $LogFile
Set-WindowsUpdateFirewall -Name "Windows Update 443" -Port 443 -LogFile $LogFile
