# AdvFirewall Scripts

A Collection of Scripts to Manage your Advanced Windows Firewall.

Eine Sammlung von Skripten zum Verwalten Ihrer Windows-Firewall mit erweiterter Sicherheit.

## Description / Beschreibung

Easy adding of new Rules for your Applications Incoming and Outgoing Traffic. Windows Firewall Event Logging to simple Text Logfile. You will find the Log Files in your Script Directory. You can even restore your custom Firewall Rules when running the Rules Logfile as a Command Script. From your StartMenu you can pause the Firewall and view the logged Firewall Events.

Einfaches Hinzufügen neuer Regeln für den Eingehenden und Ausgehenden Datenverkehr Ihrer Anwendungen. Ereignisse werden in eine einfache Datei gespeichert. Sie finden die Protokolldateien in Ihrem Skript-Verzeichnis. Sie können sogar Ihre Benutzerdefinierten Firewall-Regeln wiederherstellen wenn sie das Protokoll der Regeln als Kommando-Skript ausführen. Von Ihrem Startmenü können Sie die Firewall pausieren und die erfassten Firewall Ereignisse ansehen.

## Requirements / Vorraussetzungen

* Windows Operating System
* Elevated Command Prompt (Only for the Event Logger / Nur für die Ereignisprotokollierung)

## Supported Operating Systems / Unterstützte Betriebssysteme

* Windows 7
* Windows 8
* Windows 8.1
* Windows 10
* Windows Server 2012
* Windows Server 2012 R2
* Windows Server 2016 Technical Preview

## Installation

Extract the Archive and put the Folder to your desired Location.

Run the Install Scripts depending on what you want to be installed.

### Windows Firewall SendTo Shortcuts

If the ExecutionPolicy from PowerShell is Restricted run:

    install.cmd

With PowerShell and configured ExecutionPolicy run:

    advfirewall-installer.ps1

### Windows Firewall Event Logging

If the ExecutionPolicy from PowerShell is Restricted run:

    install-logger.cmd

With PowerShell and configured ExecutionPolicy run:

    advfirewall-installer.ps1 logger

## Deinstallation

Run the Removal Scripts depending on what you have installed.

### Windows Firewall SendTo Shortcuts

If the ExecutionPolicy from PowerShell is Restricted run:

    remove.cmd

With PowerShell and configured ExecutionPolicy run:

    advfirewall-installer.ps1 remove

### Windows Firewall Event Logging

If the ExecutionPolicy from PowerShell is Restricted run:

    remove-logger.cmd

With PowerShell and configured ExecutionPolicy run:

    advfirewall-installer.ps1 remove logger

## [Netsh AdvFirewall Firewall Commands](http://technet.microsoft.com/de-de/library/dd734783%28v=ws.10%29.aspx)

Available Profiles

* domainprofile
* privateprofile
* publicprofile

Turn on Firewall:

    netsh advfirewall set allprofiles state on

Block All:

    netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound

Block Inbound and Outbound of Private Profile:

    netsh advfirewall set privateprofile firewallpolicy blockinbound,blockoutbound

Allow Inbound and Outbound of Private Profile:

    netsh advfirewall set privateprofile firewallpolicy allowinbound,allowoutbound

Add Rule:

    netsh advfirewall firewall add rule name="iexplore" program="C:\Program Files (x86)\Internet Explorer\iexplore.exe" action=allow dir=out profile=private,public enable=yes

Delete Rule:

    netsh advfirewall firewall delete rule name="iexplore" program="C:\Program Files (x86)\Internet Explorer\iexplore.exe" action=allow dir=out profile=private,public enable=yes

Allow SSH Traffic for all Programs:

    netsh advfirewall firewall add rule name="SSH" dir=out action=allow protocol=TCP remoteport=22 profile=any enable=yes

Allow Network-Printing:

    netsh advfirewall firewall add rule name="Advanced TCP/IP Printer Port" dir=out action=allow protocol=TCP remoteport=9100 remoteip=localsubnet profile=any enable=yes

Allow ICMPv4 Traffic (Ping):

    netsh advfirewall firewall add rule name="ICMPv4" dir=out action=allow protocol=ICMPv4 profile=any enable=yes

Allow NetBIOS Traffic in LocalSubNet:

    netsh advfirewall firewall add rule name="NetBIOS" dir=out action=allow protocol=UDP remoteport=137 remoteip=localsubnet profile=any enable=yes

Allow Network Time Protocol Traffic:

    netsh advfirewall firewall add rule name="W32Time" service="W32Time" dir=out action=allow profile=any enable=yes

Allow the Windows Update Service:

    netsh advfirewall firewall add rule name="Windows Update Service" service="wuauserv" dir=out action=allow profile=private enable=yes

Windows Update on Windows 10:

    netsh advfirewall firewall add rule name="Windows Update" program="%systemroot%\system32\svchost.exe" remoteport=443 protocol=TCP remoteip=157.55.240.220,157.56.96.54,65.55.163.222,191.234.72.183,191.234.72.188,191.234.72.186,191.232.80.60,131.253.61.68,131.253.61.80,131.253.61.82,131.253.61.84,131.253.61.98,134.170.115.62,64.4.54.117,157.56.96.123,157.55.133.204,65.55.138.111,191.232.139.2,64.4.54.18 dir=out action=allow profile=private,public enable=yes

Disable Teredo IPv6 Tunneling:

    netsh interface teredo set state disabled
