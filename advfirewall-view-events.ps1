function Get-LogEntry {
    Param([Parameter(Mandatory=$true)] [String] $LogEntry)
    [HashTable] $Protocol = @{
        1 = "Internet Control Message Protocol (ICMP)";
        6 = "Transmission Control Protocol (TCP)";
        17 = "User Datagram Protocol (UDP)";
        47 = "General Routing Encapsulation (PPTP data over GRE)";
        51 = "Authentication Header (AH) IPSec";
        50 = "Encapsulation Security Payload (ESP) IPSec";
        8 = "Exterior Gateway Protocol (EGP)";
        3 = "Gateway-Gateway Protocol (GGP)";
        20 = "Host Monitoring Protocol (HMP)";
        88 = "Internet Group Management Protocol (IGMP)";
        66 = "MIT Remote Virtual Disk (RVD)";
        89 = "OSPF Open Shortest Path First";
        12 = "PARC Universal Packet Protocol (PUP)";
        27 = "Reliable Datagram Protocol (RDP)";
        46 = "Reservation Protocol (RSVP) QoS"
    }
    $result = New-Object System.Management.Automation.PSObject
    $result | Add-Member -MemberType NoteProperty -Name "Datum" -Value ([RegEx]::Match($LogEntry, '([\d|.]+)').Groups[1].Value)
    $result | Add-Member -MemberType NoteProperty -Name "Uhrzeit" -Value ([RegEx]::Match($LogEntry, '\ ([\d|:]+)').Groups[1].Value)
    $result | Add-Member -MemberType NoteProperty -Name "Prozess" -Value ([RegEx]::Match($LogEntry, '\-pid\ (\d+)\ ').Groups[1].Value)
    $result | Add-Member -MemberType NoteProperty -Name "Thread" -Value ([RegEx]::Match($LogEntry, '\-threadid\ (\d+)\ ').Groups[1].Value)
    $result | Add-Member -MemberType NoteProperty -Name "IP Adresse" -Value ([RegEx]::Match($LogEntry,'\-ip\ ([^ ]+)\ ').Groups[1].Value)
    $result | Add-Member -MemberType NoteProperty -Name "Port" -Value ([RegEx]::Match($LogEntry, '\-port\ (\d+)\ ').Groups[1].Value)
    [Int] $ProtocolNumber = [RegEx]::Match($LogEntry, '\-protocol\ (\d+)\ ').Groups[1].Value
    $result | Add-Member -MemberType NoteProperty -Name "Protokoll" -Value $ProtocolNumber
    $result | Add-Member -MemberType NoteProperty -Name "Protokoll Name" -Value ($Protocol[$ProtocolNumber])
    #$result | Add-Member -MemberType NoteProperty -Name LocalPort -Value ([RegEx]::Match($LogEntry, '\-localport\ (\d+)\ ').Groups[1].Value)
    [String] $Services = [RegEx]::Match($LogEntry,'\-services\ (.*)').Groups[1].Value
    If ($Services) {
        $result | Add-Member -MemberType NoteProperty -Name "Pfad" -Value ([RegEx]::Match($LogEntry,'\-path\ (.*)\ (\-)').Groups[1].Value)
        $result | Add-Member -MemberType NoteProperty -Name "Dienste" -Value $Services
    } Else {
        $result | Add-Member -MemberType NoteProperty -Name "Pfad" -Value ([RegEx]::Match($LogEntry,'\-path\ (.*)').Groups[1].Value)
    }
    return $result
}
if (Test-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events.log")) {
    Write-Host "Lese Ereignisprotokoll Datei"
    [Int] $Counter = 0
    $LogFile = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events.log") # -Tail 100
    [Array] $FirewallLog = @()
    $Total = $Logfile.Count
    foreach($LogEntry in $LogFile) {
        $Counter++
        Write-Host "Eintrag $Counter von $Total"
        $FirewallLog += Get-LogEntry -LogEntry $LogEntry # | Where-Object {$_.RemotePort -eq 443}
    }
    $FirewallLog | Out-GridView -Title "Windows Firewall Ereignisprotokoll" -Wait
} else {
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $Result = [System.Windows.Forms.MessageBox]::Show(
        "Es ist keine Log Datei vorhanden!",
        "Windows Firewall", 0, [System.Windows.Forms.MessageBoxIcon]::Error
    )
}
