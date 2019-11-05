rem This script is called from other batch scripts in the tool
rem    and sets the locations for the R and Java installations
rem    This script is located here for ease of use.


rem R executable location on the NWW "V" drive
set rExecutablePath="\\nww-netapp1\prjmgnt\CWMS\software\R-3.4.2\bin\Rscript.exe"

rem R executable location on Ross' computer
rem set rExecutablePath="D:\crt_crso\FRA_Plotter_v4.6.1\resources\R-3.4.2\bin\Rscript.exe"


rem Java location on the NWW "V" drive
set baseJavaDir=\\nww-netapp1\prjmgnt\CWMS\software\java64

rem The DSS file name to save ESP data to in watershed shared directory
set dssfile=columbia10_6hr.dss


rem Can be 0, 5, or 10, representing forecasts generated using
rem  0, 5, and 10 days of short-term weather forecasts.
set espdays="10"