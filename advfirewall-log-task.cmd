@echo off

echo %date% %time% %* >> %~dp0\advfirewall-task.log

rem powershell -NoProfile -ExecutionPolicy Bypass -File %~dp0/advfirewall-notify.ps1 %*

rem msg * /TIME:1 %*
