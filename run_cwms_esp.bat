@echo off
SETLOCAL ENABLEEXTENSIONS
title CWMS ESP Viewer
rem This runs the R scripts that launch the CWMS ESP viewer

rem R executable location on the "V" drive
set rExecutablePath="\\nww-netapp1\prjmgnt\CWMS\software\R-3.4.2\bin\Rscript.exe"
set rExecutablePath="D:\crt_crso\FRA_Plotter_v4.6.1\resources\R-3.4.2\bin\Rscript.exe"

rem Chrome browser executable path
set chromeExecutablePath="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"

set rScript=webapp\run.R
rem rScript=webapp\test.R

echo --- Launching CWMS ESP Viewer ---

set defaultHost=127.0.0.1
set defaultPort=4456
set defaultURL=http://%defaultHost%:%defaultPort%/

echo Host IP: %defaultHost%
echo Port:    %defaultPort%
echo url:     %defaultURL%
echo R Executable Path: %rExecutablePath%
echo webapp location:   %rScript%
echo ---------------------------------
echo.
echo.
echo.
echo Navigate browser to the following url:  %defaultURL%
echo   (Use Chrome or Firefox)
echo.
echo.



rem passing arguments to R script for host and port
%rExecutablePath% "%rScript%" %defaultHost% %defaultPort%


pause