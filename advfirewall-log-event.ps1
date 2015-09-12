[String] $LogEntry = "$args"
[Int] $ProcessID = [regex]::Match($LogEntry, '\-pid\ (\d+)\ ').Groups[1].Value
[String] $Services = Get-WmiObject Win32_Service -Filter "ProcessID LIKE $ProcessID" -ErrorAction SilentlyContinue | select -ExpandProperty Name
If ($Services) {
    [String] $Value = (Get-Date -Format "dd.MM.yyy HH:mm:ss") + " " + $LogEntry + " -services " + $Services
} Else {
    [String] $Value = (Get-Date -Format "dd.MM.yyy HH:mm:ss") + " " + $LogEntry
}
[String] $LogFile = Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events.log"
Add-Content -Path $LogFile -Value $Value
