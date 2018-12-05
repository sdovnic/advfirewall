# AdvFirewall Scripts

A Collection of Scripts to Manage your Advanced Windows Firewall.

Eine Sammlung von Skripten zum Verwalten Ihrer Windows-Firewall mit erweiterter Sicherheit.

## Description / Beschreibung

Easy adding of new Rules for your Applications Incoming and Outgoing Traffic. Windows Firewall Event Logging to simple Text Logfile. You will find the Log Files in your Script Directory. You can even restore your custom Firewall Rules when running the Rules Logfile as a Command Script. From your StartMenu you can pause the Firewall and view the logged Firewall Events.

Einfaches Hinzufügen neuer Regeln für den Eingehenden und Ausgehenden Datenverkehr Ihrer Anwendungen. Ereignisse werden in eine einfache Datei gespeichert. Sie finden die Protokolldateien in Ihrem Skript-Verzeichnis. Sie können sogar Ihre Benutzerdefinierten Firewall-Regeln wiederherstellen wenn sie das Protokoll der Regeln als Kommando-Skript ausführen. Von Ihrem Startmenü können Sie die Firewall pausieren und die erfassten Firewall Ereignisse ansehen.

Get a Notification when an Application or Service is blocked. You are able to hide Notifications for selected Services and Applications. There is an Settingsmenu where you can unhide hidden Notifications and set the Audio of the Notification, even to Silent.

Erhalten Sie Benachrichtigungen wenn eine Anwendung oder ein Dienst geblockt wurde. Sie können auch Benachrichtigungen ausblenden für ausgewählte Dienste und Anwendungen. Es gibt ein Einstellungsmenü in dem Sie die ausgeblendeten Benachrichtigungen wieder einblenden lassen können, auch kann der Ton für die Benachrichtigungen geändert werden (Auch kein Ton).

## Requirements / Vorraussetzungen

* Windows Operating System
* Elevated Command Prompt (Only for the Event Logger and Notification installation / Nur für die Ereignisprotokollierung und Benachrichtigungen installation)

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

### Windows Firewall Notification

If the ExecutionPolicy from PowerShell is Restricted run:

    install-notification.cmd

With PowerShell and configured ExecutionPolicy run:

    advfirewall-installer.ps1 notification

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

### Windows Firewall Notification

If the ExecutionPolicy from PowerShell is Restricted run:

    remove-notification.cmd

With PowerShell and configured ExecutionPolicy run:

    advfirewall-installer.ps1 remove notification

## How does the advfirewall scripts work

### Enable logging failures

#### Useful sources

[Auditpol](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/auditpol-list) Displays information about and performs functions to manipulate audit policies.

We are looking for the [Auditing Constant](https://docs.microsoft.com/en-us/windows/desktop/secauthz/auditing-constants) \*\*Audit\\_ObjectAccess\\_FirewallConnection\*\* (0cce9226-69ae-11d9-bed3-505054503030).

We are looking for the GUID to anable logging of failures in policy category ObjectAccess with subcategory FirewallConnection

#### List all categories

Example windows command prompt output:

    auditpol /list /category /v

    Kategorie/Unterkategorie                GUID
    An-/Abmeldung                           {69979849-797A-11D9-BED3-505054503030}
    Berechtigungen                          {6997984B-797A-11D9-BED3-505054503030}
    Detaillierte Nachverfolgung             {6997984C-797A-11D9-BED3-505054503030}
    DS-Zugriff                              {6997984F-797A-11D9-BED3-505054503030}
    Kontenverwaltung                        {6997984E-797A-11D9-BED3-505054503030}
    Kontoanmeldung                          {69979850-797A-11D9-BED3-505054503030}
    Objektzugriff                           {6997984A-797A-11D9-BED3-505054503030}
    Richtlinienänderung                     {6997984D-797A-11D9-BED3-505054503030}
    System                                  {69979848-797A-11D9-BED3-505054503030}

#### List subcategory of category ObjectAccess

  Example windows command prompt output:

      auditpol /list /subcategory:{6997984A-797A-11D9-BED3-505054503030} /v

      Kategorie/Unterkategorie                GUID
      Objektzugriff                           {6997984A-797A-11D9-BED3-505054503030}
        Dateisystem                               {0CCE921D-69AE-11D9-BED3-505054503030}
        Registrierung                             {0CCE921E-69AE-11D9-BED3-505054503030}
        Kernelobjekt                              {0CCE921F-69AE-11D9-BED3-505054503030}
        SAM                                       {0CCE9220-69AE-11D9-BED3-505054503030}
        Zertifizierungsdienste                    {0CCE9221-69AE-11D9-BED3-505054503030}
        Anwendung wurde generiert.                {0CCE9222-69AE-11D9-BED3-505054503030}
        Handleänderung                            {0CCE9223-69AE-11D9-BED3-505054503030}
        Dateifreigabe                             {0CCE9224-69AE-11D9-BED3-505054503030}
        Filterplattform: Verworfene Pakete        {0CCE9225-69AE-11D9-BED3-505054503030}
        Filterplattformverbindung                 {0CCE9226-69AE-11D9-BED3-505054503030}
        Andere Objektzugriffsereignisse           {0CCE9227-69AE-11D9-BED3-505054503030}
        Detaillierte Dateifreigabe                {0CCE9244-69AE-11D9-BED3-505054503030}
        Wechselmedien                             {0CCE9245-69AE-11D9-BED3-505054503030}
        Staging zentraler Richtlinien             {0CCE9246-69AE-11D9-BED3-505054503030}

#### Show the default settings of the subcategory FirewallConnection

  Example windows command prompt output:

      auditpol /get /subcategory:{0CCE9226-69AE-11D9-BED3-505054503030}

      Systemüberwachungsrichtlinie
      Kategorie/Unterkategorie                  Einstellung
      Objektzugriff
        Filterplattformverbindung               Keine Überwachung

#### Set the default failure auditing setting of the subcategory FirewallConnection to enable failure logging

Example windows command prompt output:

    auditpol /set /subcategory:{0CCE9226-69AE-11D9-BED3-505054503030} /failure:enable

    Der Befehl wurde erfolgreich ausgeführt.

Example windows command prompt output:

    auditpol /get /subcategory:{0CCE9226-69AE-11D9-BED3-505054503030}

    Systemüberwachungsrichtlinie
    Kategorie/Unterkategorie                  Einstellung
    Objektzugriff
      Filterplattformverbindung               Fehler

### Use the Event Viewer Security Log

Look in the Event Viewer at the Windows Logs for the Security Log. We now get Microsoft Windows security auditing log entries for event 5157.

Example Event XML Data content:

    <Event xmlns="http://schemas.microsoft.com/win/2004/08/events/event">
      <System>
        <Provider Name="Microsoft-Windows-Security-Auditing" Guid="{54849625-5478-4994-A5BA-3E3B0328C30D}" />
        <EventID>5157</EventID>
        <Version>1</Version>
        <Level>0</Level>
        <Task>12810</Task>
        <Opcode>0</Opcode>
        <Keywords>0x8010000000000000</Keywords>
        <TimeCreated SystemTime="2018-11-14T21:35:46.321006100Z" />
        <EventRecordID>1063918</EventRecordID>
        <Correlation />
        <Execution ProcessID="4" ThreadID="6548" />
        <Channel>Security</Channel>
        <Computer>evaunit01</Computer>
        <Security />
      </System>
      <EventData>
        <Data Name="ProcessID">6652</Data>
        <Data Name="Application">\device\harddiskvolume4\windows\systemapps\microsoft.windows.cortana_cw5n1h2txyewy\searchui.exe</Data>
        <Data Name="Direction">%%14593</Data>
        <Data Name="SourceAddress">192.168.42.101</Data>
        <Data Name="SourcePort">2191</Data>
        <Data Name="DestAddress">13.107.21.200</Data>
        <Data Name="DestPort">443</Data>
        <Data Name="Protocol">6</Data>
        <Data Name="FilterRTID">68063</Data>
        <Data Name="LayerName">%%14611</Data>
        <Data Name="LayerRTID">48</Data>
        <Data Name="RemoteUserID">S-1-0-0</Data>
        <Data Name="RemoteMachineID">S-1-0-0</Data>
      </EventData>
    </Event>

### Trigger an Sheduled Task by the event

Now we create a Sheduled Task that will be triggered if this event occurs.

Example Task XML File contents:

    <?xml version="1.0" encoding="UTF-16"?>
    <Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
      <RegistrationInfo>
        <Date>2015-08-16T03:36:29</Date>
        <Author>Rally Vincent</Author>
        <Description>Zeichnet Windows Firewall Ereignisse auf, benötigt C:\Portable\advfirewall\advfirewall-log-event.ps1 und schreibt in die Datei C:\Portable\advfirewall\advfirewall-events.csv.</Description>
        <URI>\advfirewall-log-event</URI>
      </RegistrationInfo>
      <Triggers>
        <EventTrigger>
          <StartBoundary>2015-08-16T03:36:29</StartBoundary>
          <Enabled>true</Enabled>
          <Subscription>&lt;QueryList&gt;&lt;Query&gt;&lt;Select Path='Security'&gt;*[System[(Level=4 or Level=0) and (EventID=5157)]] and *[EventData[Data[@Name='LayerRTID']='48']]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
          <ValueQueries>
            <Value name="Application">Event/EventData/Data[@Name='Application']</Value>
            <Value name="DestAddress">Event/EventData/Data[@Name='DestAddress']</Value>
            <Value name="DestPort">Event/EventData/Data[@Name='DestPort']</Value>
            <Value name="Direction">Event/EventData/Data[@Name='Direction']</Value>
            <Value name="ProcessID">Event/EventData/Data[@Name='ProcessID']</Value>
            <Value name="Protocol">Event/EventData/Data[@Name='Protocol']</Value>
            <Value name="SourceAddress">Event/EventData/Data[@Name='SourceAddress']</Value>
            <Value name="SourcePort">Event/EventData/Data[@Name='SourcePort']</Value>
            <Value name="SystemTime">Event/System/TimeCreated/@SystemTime</Value>
            <Value name="ThreadID">Event/System/Execution/@ThreadID</Value>
          </ValueQueries>
        </EventTrigger>
      </Triggers>
      <Principals>
        <Principal id="Author">
          <UserId>S-1-5-18</UserId>
          <RunLevel>HighestAvailable</RunLevel>
        </Principal>
      </Principals>
      <Settings>
        <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
        <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
        <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
        <AllowHardTerminate>true</AllowHardTerminate>
        <StartWhenAvailable>false</StartWhenAvailable>
        <RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>
        <IdleSettings>
          <StopOnIdleEnd>true</StopOnIdleEnd>
          <RestartOnIdle>false</RestartOnIdle>
        </IdleSettings>
        <AllowStartOnDemand>false</AllowStartOnDemand>
        <Enabled>true</Enabled>
        <Hidden>false</Hidden>
        <RunOnlyIfIdle>false</RunOnlyIfIdle>
        <WakeToRun>false</WakeToRun>
        <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
        <Priority>7</Priority>
      </Settings>
      <Actions Context="Author">
        <Exec>
          <Command>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</Command>
          <Arguments>-NoProfile -ExecutionPolicy Bypass -File "C:\Portable\advfirewall\advfirewall-log-event.ps1" -SystemTime $(SystemTime) -ThreadID $(ThreadID) -ProcessID $(ProcessID) -Application "$(Application)" -Direction $(Direction) -SourceAddress $(SourceAddress) -SourcePort $(SourcePort) -DestAddress $(DestAddress) -DestPort $(DestPort) -Protocol $(Protocol)</Arguments>
        </Exec>
      </Actions>
    </Task>

Inside the Task we use System Level 4 or Level 0, EventID 5157 and EventData Data Name LayerRTID with value 48 as the trigger.

Trigger XML content:

    <QueryList>
      <Query Id="0" Path="Security">
        <Select Path="Security">*[System[(Level=4 or Level=0) and (EventID=5157)]] and *[EventData[Data[@Name='LayerRTID']='48']]</Select>
      </Query>
    </QueryList>

### Run a Powershell Script from the Sheduled Task

As we can see the Task starts a Powershell Script with the given Parameters from the security event.

    C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Portable\advfirewall\advfirewall-log-event.ps1" -SystemTime $(SystemTime) -ThreadID $(ThreadID) -ProcessID $(ProcessID) -Application "$(Application)" -Direction $(Direction) -SourceAddress $(SourceAddress) -SourcePort $(SourcePort) -DestAddress $(DestAddress) -DestPort $(DestPort) -Protocol $(Protocol)

### Notifications

#### Todo, write an explanation

...

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
