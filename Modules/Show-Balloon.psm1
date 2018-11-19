function Show-Balloon {
    <#
        .SYNOPSIS
            Show a Balloon.
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)] [string] $TipTitle,
        [parameter(Mandatory=$true)] [string] $TipText,
        [parameter(Mandatory=$false)] [ValidateSet("Info", "Error", "Warning")] [string] $TipIcon,
        [parameter(Mandatory=$false)] [string] $Icon,
        [parameter(Mandatory=$false)] [string] $Delay = 5000
    )
    begin {
        [Void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    }
    process {
        $FormsNotifyIcon = New-Object -TypeName System.Windows.Forms.NotifyIcon -Verbose
        if (-not $Icon) { $Icon = (Join-Path -Path $PSHOME -ChildPath "powershell.exe") }
        $DrawingIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($Icon)
        $FormsNotifyIcon.Icon = $DrawingIcon
        if (-not $TipIcon) { $TipIcon = "Info"; }
        $FormsNotifyIcon.BalloonTipIcon = $TipIcon;
        $FormsNotifyIcon.BalloonTipTitle = $TipTitle
        $FormsNotifyIcon.BalloonTipText = $TipText
        $FormsNotifyIcon.Visible = $True
        $FormsNotifyIcon.ShowBalloonTip($Delay)
        Start-Sleep -Milliseconds $Delay -Verbose
        $FormsNotifyIcon.Dispose()
    }
}
