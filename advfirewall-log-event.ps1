param(
    [string] $SystemTime,
    [string] $ThreadID,
    [string] $ProcessID,
    $Application,
    [string] $Direction,
    [string] $SourceAddress,
    [string] $SourcePort,
    [string] $DestAddress,
    [string] $DestPort,
    [string] $Protocol
)
if ($PSVersionTable.PSVersion.Major -lt 3) {
    [string] $PSScriptRoot = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
}
$Event = @{
    SystemTime = $SystemTime
    ThreadID = [int] $ThreadID
    ProcessID = [int] $ProcessID
    Application = [string] "$Application"
    Direction = $Direction
    SourceAddress = $SourceAddress
    SourcePort = $SourcePort
    DestAddress = $DestAddress
    DestPort = $DestPort
    Protocol = $Protocol
    Services = [string] (Get-WmiObject -Class Win32_Service -Filter "ProcessID LIKE $ProcessID" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
}
Export-Csv -Path (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events.csv") -Append -InputObject (New-Object -TypeName PsObject -Property $Event)
