function Get-LogEntry () {
    param([string] $LogEntry)
    [hashtable] $Protocol = @{
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
    $result | Add-Member -MemberType NoteProperty -Name "Datum" -Value ([regex]::Match($LogEntry, '([\d|.]+)').Groups[1].Value)
    $result | Add-Member -MemberType NoteProperty -Name "Uhrzeit" -Value ([regex]::Match($LogEntry, '\ ([\d|:]+)').Groups[1].Value)
    $ProcessID = [regex]::Match($LogEntry, '\-pid\ (\d+)\ ').Groups[1].Value
    $result | Add-Member -MemberType NoteProperty -Name "Prozess" -Value $ProcessID
    $result | Add-Member -MemberType NoteProperty -Name "Thread" -Value ([regex]::Match($LogEntry, '\-threadid\ (\d+)\ ').Groups[1].Value)
    $result | Add-Member -MemberType NoteProperty -Name "IP Adresse" -Value ([regex]::Match($LogEntry,'\-ip\ ([^ ]+)\ ').Groups[1].Value)
    $result | Add-Member -MemberType NoteProperty -Name "Port" -Value ([regex]::Match($LogEntry, '\-port\ (\d+)\ ').Groups[1].Value)
    [int] $ProtocolNumber = [regex]::Match($LogEntry, '\-protocol\ (\d+)\ ').Groups[1].Value
    $result | Add-Member -MemberType NoteProperty -Name "Protokoll" -Value $ProtocolNumber
    $result | Add-Member -MemberType NoteProperty -Name "Protokoll Name" -Value ($Protocol[$ProtocolNumber])
    #$result | Add-Member -MemberType NoteProperty -Name LocalPort -Value ([regex]::Match($LogEntry, '\-localport\ (\d+)\ ').Groups[1].Value)
    $result | Add-Member -MemberType NoteProperty -Name "Pfad" -Value ([regex]::Match($LogEntry,'\-path\ (.*)').Groups[1].Value)
    [array] $Services = Get-WmiObject Win32_Service -Filter "ProcessID LIKE $ProcessID" -ErrorAction SilentlyContinue | select -ExpandProperty Name
    $result | Add-Member -MemberType NoteProperty -Name "Dienste" -Value "$Services"
    return $result
}
if (Test-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events.log")) {
    Write-Host "Processing log file ... this may take a while ... " -NoNewline
    $LogFile = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events.log") # -Tail 100
    [array] $FirewallLog = @()
    foreach($LogEntry in $LogFile) {
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