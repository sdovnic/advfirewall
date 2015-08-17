[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
$objBalloon = New-Object System.Windows.Forms.NotifyIcon
$objBalloon.Icon = "$PSScriptRoot\advfirewall.ico"
$objBalloon.BalloonTipIcon = "Info"
$objBalloon.BalloonTipTitle = "Windows Firewall"
$objBalloon.BalloonTipText = $args
$objBalloon.Visible = $True
$objBalloon.ShowBalloonTip(5000)
Start-Sleep -Milliseconds 500
$objBalloon.Dispose()
