If ($PSVersionTable.PSVersion.Major -lt 3) {
    [String] $PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
}
Function Get-LogEntry {
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
        $result | Add-Member -MemberType NoteProperty -Name "Dienste" -Value ""
    }
    return $result
}
If (Test-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath "advfirewall-events.log")) {
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
    If ($PSVersionTable.PSVersion.Major -lt 3) {
        $WaitHelperSource = @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Threading;

namespace Utils
{
  public delegate bool Win32Callback(IntPtr hwnd, IntPtr lParam);

  public class WindowHelper
  {
    private const int PROCESS_QUERY_LIMITED_INFORMATION = 0x1000;
    private IntPtr _mainHwnd;
    private IntPtr _ogvHwnd;
    private IntPtr _poshProcessHandle;
    private int _poshPid;
    private bool _ogvWindowFound;

    public WindowHelper()
    {
      Process process = Process.GetCurrentProcess();
      _mainHwnd = process.MainWindowHandle;
      _poshProcessHandle = process.Handle;
      _poshPid = process.Id;
    }

    public void WaitForOutGridViewWindowToClose()
    {
      do
      {
        _ogvWindowFound = false;
        EnumChildWindows(IntPtr.Zero, EnumChildWindowsHandler,
                 IntPtr.Zero);
        Thread.Sleep(500);
      } while (_ogvWindowFound);
    }

    [DllImport("User32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool EnumChildWindows(
      IntPtr parentHandle, Win32Callback callback, IntPtr lParam);

    [DllImport("User32.dll")]
    public static extern int GetWindowThreadProcessId(IntPtr hWnd, out int processId);

    [DllImport("Kernel32.dll")]
    public static extern int GetLastError();

    private bool EnumChildWindowsHandler(IntPtr hwnd, IntPtr lParam)
    {
      if (_ogvHwnd == IntPtr.Zero)
      {
        int processId;
        int thread = GetWindowThreadProcessId(hwnd, out processId);

        if (processId == 0)
        {
          Console.WriteLine("GetWindowThreadProcessId error:{0}",
                   GetLastError());
          return true;
        }
        if (processId == _poshPid)
        {
          if (hwnd != _mainHwnd)
          {
            _ogvHwnd = hwnd;
            _ogvWindowFound = true;
            return false;
          }
        }
      }
      else if (hwnd == _ogvHwnd)
      {
        _ogvWindowFound = true;
        return false;
      }
      return true;
    }
  }
}
'@
        Add-Type -TypeDefinition $WaitHelperSource
        $FirewallLog | Out-GridView -Title "Windows Firewall Ereignisprotokoll"
        $WaitHelper = new-object Utils.WindowHelper 
        $WaitHelper.WaitForOutGridViewWindowToClose()
    } Else {
        $FirewallLog | Out-GridView -Title "Windows Firewall Ereignisprotokoll" -Wait
    }
} Else {
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $Result = [System.Windows.Forms.MessageBox]::Show(
        "Es ist keine Log Datei vorhanden!",
        "Windows Firewall", 0, [System.Windows.Forms.MessageBoxIcon]::Error
    )
}
