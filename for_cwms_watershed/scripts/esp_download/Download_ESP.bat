@echo off
SETLOCAL ENABLEEXTENSIONS
setlocal EnableDelayedExpansion
title Download ESP
@echo off
rem Finding the most current version of R installed and running script
rem executable path should be something like this: "C:\Program Files\R\R-3.3.2\bin\x64\R.exe"

rem The assumed script name
set basedir=%cd%
set scriptname=%cd%/"ESP Download.R"

rem Establishing R, Java, and ESP config
rem loads 'rExecutablePath', 'baseJavaDir', 'dssfile', and 'espdays'
call ../../../../cwms_esp/r_java_esp_config.bat


echo Executing the following script: %scriptname%
echo Executing R from the following executable: %executablepath%


rem arguments to pass to the script
set configFile="../../../../cwms_esp/config.xlsx"
set saveLocation="../../shared/%dssfile%"

@echo on
set eval=%rExecutablePath% --vanilla %scriptname% %saveLocation% %configFile% %espdays%

rem echo evaluating the following expression: %eval%

%eval%

@echo off
echo Finished Execution of script.

pause