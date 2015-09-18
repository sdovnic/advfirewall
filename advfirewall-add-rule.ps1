If ($PSVersionTable.PSVersion.Major -lt 3) {
    [String] $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
}
If ($PSVersionTable.PSVersion.Major -lt 3) {
    [String] $PSCommandPath = $MyInvocation.MyCommand.Definition
}
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell -WindowStyle Hidden -WorkingDirectory $PSScriptRoot -Verb runAs `
                             -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $PSCommandPath $args"
    return
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
If ($args.Length -gt 1) {
    $dir, $rest = $args
    $Program = "$rest"
    [string] $DisplayName = [io.path]::GetFileNameWithoutExtension($Program)
    [hashtable] $Directions = @{ "in" = "Inbound"; "out" = "Outbound"; }
    [string] $Direction = $Directions[$dir]
    [string] $TipIcon = "Info"
    [hashtable] $TipTexts = @{
        "in" = "Eingehende Firewall Regel für `"$DisplayName`" angelegt.";
        "out" = "Ausgehende Firewall Regel für `"$DisplayName`" angelegt.";
    }
    [array] $ArgumentList = @(
        "advfirewall", "firewall", "add", "rule", "name=`"$DisplayName`"",
        "program=`"$Program`"", "action=allow", "dir=$dir", "profile=any",
        "enable=yes"
    )
    [string] $LogFile = (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-rules.log")
    [string] $LogEntry = "netsh", "$ArgumentList"
    If (Get-Command -Name Get-NetFirewallRule -ErrorAction SilentlyContinue) {
        If (
            Get-NetFirewallApplicationFilter -Program $Program | `
            Get-NetFirewallRule | `
            Where-Object {$_.Direction -eq $Direction -and $_.DisplayName -eq $DisplayName}
        ) {
            Write-Warning "Rule already exist!"
            [hashtable] $TipTexts = @{
                "in" = "Eingehende Firewall Regel für `"$DisplayName`" bereits vorhanden!";
                "out" = "Ausgehende Firewall Regel für `"$DisplayName`" bereits vorhanden!";
            }
            [string] $TipIcon = "Error"
        } Else {
            New-NetFirewallRule -DisplayName $DisplayName -Program $Program -Direction $Direction `
                                -Action Allow -Enabled True -Profile Any
            Add-Content -Path $LogFile -Value $LogEntry
        }
    } Else {
        Write-Warning "Get-NetFirewallRule not supported."
        $Show = (netsh advfirewall firewall show rule name="$DisplayName" dir=$dir verbose) | Out-String
        If ($Show.Contains($Program)) {
            Write-Warning "Rule already exist!"
            [hashtable] $TipTexts = @{
                "in" = "Eingehende Firewall Regel für `"$DisplayName`" bereits vorhanden!";
                "out" = "Ausgehende Firewall Regel für `"$DisplayName`" bereits vorhanden!";
            }
            [string] $TipIcon = "Error"
        } Else {
            Start-Process "netsh" -ArgumentList $ArgumentList -WindowStyle Hidden
            Add-Content -Path $LogFile -Value $LogEntry
        }
    }
    Show-Balloon -TipTitle "Windows Firewall" -TipText $TipTexts[$dir] `
                 -TipIcon $TipIcon -Icon "$env:SystemRoot\system32\FirewallControlPanel.dll"
}
