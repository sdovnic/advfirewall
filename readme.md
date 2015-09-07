# AdvFirewall Scripts

A Collection of Scripts to Manage your Advanced Windows Firewall.

## Description

Easy adding of new Rules for your Applications Incoming and Outgoing Traffic. Windows Firewall Event Logging to simple Text Logfile. You will find the Log Files in your Script Directory. You can even restore your custom Firewall Rules when running the Rules Logfile as a Command Script. From your StartMenu you can pause the Firewall and view the logged Firewall Events.

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

    netsh advfirewall firewall add rule name="SSH" dir=out action=allow protocol=TCP remoteport=22 profile=private enable=yes

Allow Network-Printing:

    netsh advfirewall firewall add rule name="TCP 9100 192.168.0.0/24" dir=out action=allow protocol=TCP remoteport=9100 remoteip=192.168.0.0/24 profile=private enable=yes

Allow the Windows Update Service:

    netsh advfirewall firewall add rule name="Windows Update Service" service="wuauserv" dir=out action=allow profile=private enable=yes

Windows Update on Windows 10:

    netsh advfirewall firewall add rule name="Windows Update" program="%systemroot%\system32\svchost.exe" remoteport=443 protocol=TCP remoteip=157.55.240.220,157.56.96.54,65.55.163.222,191.234.72.183,191.234.72.188,191.234.72.186 dir=out action=allow profile=private,public enable=yes

Disable Teredo IPv6 Tunneling:

    netsh interface teredo set state disabled
