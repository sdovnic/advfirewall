Option Explicit

Dim objShell
Set objShell = CreateObject("WScript.Shell")

' Script Directory
Dim strScriptFullName
strScriptFullName = Wscript.ScriptFullName

Dim objFileSystem, objFile
Set objFileSystem = CreateObject("Scripting.FileSystemObject")
Set objFile = objFileSystem.GetFile(strScriptFullName)

Dim strDirectory
strDirectory = objFileSystem.GetParentFolderName(objFile)

' Create SendTo ShortCut
Const Maximized = 3
Const Minimized = 7
Const Normal = 4

Dim strFolder
strFolder = objShell.SpecialFolders("SendTo")

Dim objShortcut
Set objShortcut = objShell.CreateShortcut(strFolder + "\Windows Firewall Ausgehende Regel eintragen.lnk")

objShortcut.WindowStyle = Normal
objShortcut.IconLocation = "%SystemRoot%\system32\FirewallControlPanel.dll, 0"
objShortcut.TargetPath = strDirectory + "\advfirewall-allow-outgoing.cmd"
objShortcut.Save

Set objShortcut = objShell.CreateShortcut(strFolder + "\Windows Firewall Eingehende Regel eintragen.lnk")

objShortcut.WindowStyle = Normal
objShortcut.IconLocation = "%SystemRoot%\system32\FirewallControlPanel.dll, 0"
objShortcut.TargetPath = strDirectory + "\advfirewall-allow-incoming.cmd"
objShortcut.Save

MsgBox "Senden an Windows-Firewall installiert.", vbInformation, "Windows Firewall"
