if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
}
if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSCommandPath = $MyInvocation.MyCommand.Definition
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
        $FormsNotifyIcon.ShowBalloonTip(5000)
        Start-Sleep -Milliseconds 5000
        $FormsNotifyIcon.Dispose()
    }
}
if ($args.Length -gt 1) {
    $dir, $rest = $args
    $Program = "$rest"
    [string] $DisplayName = [io.path]::GetFileNameWithoutExtension($Program)
    [hashtable] $Directions = @{ "in" = "Inbound"; "out" = "Outbound"; }
    [string] $Direction = $Directions[$dir]
    [string] $TipIcon = "Info"
    [hashtable] $TipTexts = @{
        "in" = "Eingehende Firewall Regel f$([char]0x00FC)r `"$DisplayName`" angelegt.";
        "out" = "Ausgehende Firewall Regel f$([char]0x00FC)r `"$DisplayName`" angelegt.";
    }
    [array] $ArgumentList = @(
        "advfirewall", "firewall", "add", "rule", "name=`"$DisplayName`"",
        "program=`"$Program`"", "action=allow", "dir=$dir", "profile=any",
        "enable=yes"
    )
    [string] $LogFile = (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-rules.log")
    [string] $LogEntry = "netsh", "$ArgumentList"
    if (Get-Command -Name Get-NetFirewallRule -ErrorAction SilentlyContinue) {
        if (
            Get-NetFirewallApplicationFilter -Program $Program | `
            Get-NetFirewallRule | `
            Where-Object {$_.Direction -eq $Direction -and $_.DisplayName -eq $DisplayName}
        ) {
            Write-Warning -Message "Rule already exist!"
            [hashtable] $TipTexts = @{
                "in" = "Eingehende Firewall Regel f$([char]0x00FC)r `"$DisplayName`" bereits vorhanden!";
                "out" = "Ausgehende Firewall Regel f$([char]0x00FC)r `"$DisplayName`" bereits vorhanden!";
            }
            [string] $TipIcon = "Error"
        } else {
            New-NetFirewallRule -DisplayName $DisplayName -Program $Program -Direction $Direction `
                                -Action Allow -Enabled True -Profile Any
            Add-Content -Path $LogFile -Value $LogEntry
        }
    } else {
        Write-Warning -Message "Get-NetFirewallRule not supported, using Netsh."
        $Show = (netsh advfirewall firewall show rule name="$DisplayName" dir=$dir verbose) | Out-String
        if ($Show.Contains($Program)) {
            Write-Warning -Message "Rule already exist!"
            [hashtable] $TipTexts = @{
                "in" = "Eingehende Firewall Regel f$([char]0x00FC)r `"$DisplayName`" bereits vorhanden!";
                "out" = "Ausgehende Firewall Regel f$([char]0x00FC)r `"$DisplayName`" bereits vorhanden!";
            }
            [string] $TipIcon = "Error"
        } else {
            Start-Process -FilePath "netsh" -ArgumentList $ArgumentList -WindowStyle Hidden
            Add-Content -Path $LogFile -Value $LogEntry
        }
    }
    Show-Balloon -TipTitle "Windows Firewall" -TipText $TipTexts[$dir] `
                 -TipIcon $TipIcon -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
}
