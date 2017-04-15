param(
    [string] $SystemTime,
    [string] $ThreadID,
    [string] $ProcessID,
    [string] $Application,
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

# Todo: Tray {} Catch {}
# Todo: $ErrorLog = (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events-error.log")

if ($PSVersionTable.PSVersion.Major -gt 2) {
    Export-Csv -Path (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events.csv") -Append -InputObject (New-Object -TypeName PsObject -Property $Event)
} else {
    if (-not (Test-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events.csv"))) {
        Export-Csv -Path (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events-temp.csv") -InputObject (New-Object -TypeName PsObject -Property $Event)
        $Data = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events-temp.csv")
    } else {
        Export-Csv -Path (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events-temp.csv") -NoTypeInformation -InputObject (New-Object -TypeName PsObject -Property $Event)
        $Data = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events-temp.csv") | Select-Object -Last 1
    }
    Out-File -FilePath (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events.csv") -Append -InputObject $Data
    Remove-Item -Path (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events-temp.csv")
}

if ($Event.Services -match "wuauserv") {
    if ((Get-WmiObject -Class Win32_OperatingSystem).Caption -match "Windows 10") {
        $Name = "Windows Update {0}" -f $Event.DestPort
        if (-not (Get-NetFirewallRule -Name $Name -ErrorAction SilentlyContinue)) {
            New-NetFirewallRule -Name $Name -DisplayName $Name -Enabled True `
                                -Profile Any -Direction Outbound -Action Allow `
                                -LocalAddress Any -RemoteAddress $Event.DestAddress `
                                -Protocol "TCP" -LocalPort Any -RemotePort $Event.DestPort `
                                -Program "%SystemRoot%\System32\svchost.exe"
        } else {
            [array] $RuleRemoteAddress = (Get-NetFirewallRule -Name $Name | Get-NetFirewallAddressFilter).RemoteAddress
            [array] $RemoteAddress = ($RuleRemoteAddress) + $Event.DestAddress
            Set-NetFirewallRule -Name $Name -RemoteAddress $RemoteAddress
        }
    }
}
