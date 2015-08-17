@echo off

echo %date% %time% %* >> C:\Portable\portable\advfirewall-task.log

rem powershell -NoProfile -ExecutionPolicy Bypass -File C:\Portable\portable\advfirewall/advfirewall-notify.ps1 %*

rem msg * /TIME:1 %*
