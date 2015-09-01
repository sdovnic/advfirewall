[string] $LogFile = (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events.log")
Add-Content -Path $LogFile -Value ((Get-Date -Format "dd.MM.yyy HH:mm:ss") + " " + "$args")
