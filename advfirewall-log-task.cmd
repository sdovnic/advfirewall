@echo on

echo %date% %time% %* >> %~dp0\advfirewall-task.log

setlocal enableextensions enabledelayedexpansion
shift
set advpid=%1
shift
set advthreadid=%2
shift
set advip=%3
shift
set advport=%4
shift
set advprotocol=%5
shift
set advlocalport=%6
shift
set advpath=%7
rem echo %date% %time% %advpid% %advthreadid% %advip% %advport% %advprotocol% %advlocalport% %advpath% >> %current%\advfirewall-task.log
rem if not x%advpath:svchost=%==x%advpath% tasklist /svc /fi "pid eq %advpid%" >> %~dp0\advfirewall-task.log
endlocal

rem echo %username% >> %~dp0\advfirewall-task.log

rem runas /noprofile /user:rvincent powershell -NoProfile -ExecutionPolicy Bypass -File %~dp0/advfirewall-notify.ps1 %*

rem msg * /Time:5 /Server:%computername% %*
