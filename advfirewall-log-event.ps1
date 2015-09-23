if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
}
[string] $LogEntry = "$args"
[int] $ProcessID = [RegEx]::Match($LogEntry, '\-pid\ (\d+)\ ').Groups[1].Value
[string] $Services = Get-WmiObject -Class Win32_Service -Filter "ProcessID LIKE $ProcessID" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
if ($Services) {
    [string] $Value = (Get-Date -Format "dd.MM.yyy HH:mm:ss") + " " + $LogEntry + " -services " + $Services
} else {
    [string] $Value = (Get-Date -Format "dd.MM.yyy HH:mm:ss") + " " + $LogEntry
}
[string] $LogFile = Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events.log"
Add-Content -Path $LogFile -Value $Value
