@echo off

echo Setze Globale Variablen (benoetigt SetX)
setx advfirewallprogram %1
setx advfirewallname "%~n1"

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

echo Eingehende Firewall Regel eingetragen.
netsh advfirewall firewall add rule name="%advfirewallname%" program="%advfirewallprogram%" action=allow dir=in profile=private,public enable=yes
echo netsh advfirewall firewall add rule name="%advfirewallname%" program="%advfirewallprogram%" action=allow dir=in profile=private,public enable=yes >> advfirewall-rules.log
echo Entferne Variablen.
setx advfirewallprogram
setx advfirewallname
set advfirewallprogram=
set advfirewallname=
