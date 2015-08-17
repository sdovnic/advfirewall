Option Explicit

Dim objShell
Set objShell = CreateObject("WScript.Shell")

' Delete SendTo ShortCut
Dim strFolder
strFolder = objShell.SpecialFolders("SendTo")

Dim objFileSystem
Set objFileSystem = CreateObject("Scripting.FileSystemObject")

Dim objFile
Set objFile = objFileSystem.GetFile(strFolder + "\Windows Firewall Ausgehende Regel eintragen.lnk")
objFile.Delete
Set objFile = objFileSystem.GetFile(strFolder + "\Windows Firewall Eingehende Regel eintragen.lnk")
objFile.Delete

MsgBox "Senden an Windows Firewall deinstalliert.", vbInformation, "Windows Firewall"
