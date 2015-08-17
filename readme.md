# AdvFirewall Scripts

## Installation

Installation "Senden an Firewall":

    advfirewall-install.vbs

Installation "Firewall Logging":

    advfirewall-log-task-install.cmd

## Regeln ansehen

Einträge in der Firewall:

    %windir%\system32\WF.msc

Log der Regeln:

    notepad %~dp0/advfirewall-rules.Log

## Was hat die Firewall geblockt?

Log der geblockten Verbindungen:

    notepad %~dp0/advfirewall-task.Log

Task anschauen:

    %windir%\system32\taskschd.msc /s

## Deinstallation

Entfernen "Senden an Firewall":

    advfirewall-uninstall.vbs

Entfernen "Firewall Logging":

    advfirewall-log-task-remove.cmd

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

Disable Teredo IPv6 Tunneling:

    netsh interface teredo set state disabled
