@echo off

rem https://sites.google.com/site/eneerge/scripts/batchgotadmin

>nul 2>&1 "%SystemRoot%\system32\cacls.exe" "%SystemRoot%\system32\config\system"

if '%errorlevel%' NEQ '0' (
	echo Requesting administrative privileges ...
	goto UACPrompt
) else (
	goto gotAdmin
)

:UACPrompt
	echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
	echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
	"%temp%\getadmin.vbs"
	exit /B

:gotAdmin
	if exist "%temp%\getadmin.vbs" (
		del "%temp%\getadmin.vbs"
	)
	pushd "%CD%"
	CD /D "%~dp0"

netsh advfirewall set privateprofile firewallpolicy allowinbound,allowoutbound
netsh advfirewall set publicprofile firewallpolicy allowinbound,allowoutbound
echo Die Windows Firewall wurde angehalten! Fahren Sie fort um den vorherigen Zustand wieder herzustellen.
pause
netsh advfirewall set privateprofile firewallpolicy blockinbound,blockoutbound
netsh advfirewall set publicprofile firewallpolicy blockinbound,blockoutbound
powershell -NoProfile -ExecutionPolicy Bypass -File %~dp0/advfirewall-notify.ps1 Firewall wieder hergestellt.
