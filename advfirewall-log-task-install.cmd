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

powershell -NoProfile -ExecutionPolicy Bypass -File %~dp0/advfirewall-log-task-template.ps1 Task Installed
schtasks /Create /TN advfirewall-log-task /XML %~dp0\advfirewall-log-task.xml
auditpol /set /subcategory:{0CCE9226-69AE-11D9-BED3-505054503030} /failure:enable
powershell -NoProfile -ExecutionPolicy Bypass -File %~dp0/advfirewall-notify.ps1 Task Installed
