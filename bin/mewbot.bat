@echo off
set "PRGDIR=%cd%"

if ""%1"" == ""test"" goto doTest
if ""%1"" == ""run"" goto doRun
if ""%1"" == ""start"" goto doStart
if ""%1"" == ""stop"" goto doStop


echo Usage:  mewbot ( commands ... )
echo commands:
echo   test              Test All Mewbot
echo   run               Start Catalina in the current window
echo   start             Start Catalina in a separate window
echo   stop              Stop Catalina
goto end

:doTest
nodejs %PRGDIR%\..\node_modules\.bin\coffee %PRGDIR%\..\core\startup.coffee --test all