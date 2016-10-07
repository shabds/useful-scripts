@echo off

REM Anvil-ION.NET Launch Script v1.5.4 10/07/2013
set ERRORLEVEL=

:: Set MMI version
set MMIVER=135p53_x64

set ENV=%1
set WSOPT=%2

if [%ENV%]==[] goto ERRORENV

:: Set workspace from AFC2 login
set WORKSPACE=%USERNAME%%ENV%

:: Set to 1 to send double double to Anvil support
set DEBUG=

:: Workspace repository address
set REPOSITORY=\\Tdbf-iafil-sc01.tdbfg.com\grp\
set COMMONFOLDER=Anvil-ION.NET
set LOCATION=TOR

:: Repository root directory
set ROOTREMOTE=%REPOSITORY%\%COMMONFOLDER%

:: User network drive directory - workspace backup location
set ROOTNET=%HOMEDRIVE%\AppData\ION Trading\%COMMONFOLDER%

:: Local PC directory to copy files from repository i.e plugins, templates - must have write access
:: Windows XP
set ROOTLOCAL=%APPDATA%\ION Trading\%COMMONFOLDER%
:: This checks if Windows7, overwrites local PC directory setting
:: Windows 7 - London and Singapore users
if exist "%SYSTEMDRIVE%\Users" if exist "%SYSTEMDRIVE%\%COMMONFOLDER%" (set ROOTLOCAL=%SYSTEMDRIVE%\%COMMONFOLDER%)
:: Windows 7 EDGE - Toronto users
if exist "%SYSTEMDRIVE%\Users" if not exist "%SYSTEMDRIVE%\%COMMONFOLDER%" (set ROOTLOCAL=%MMI_ROOT%\%COMMONFOLDER%)

:: Location of Environment.xml file in repository
set ENVREMOTE=%ROOTREMOTE%\WS
:: Location of Environment.xml file on user network drive
set ENVLOCAL=%ROOTNET%\WS
:: User workspace directory in repository
set WSREMOTE=%ENVREMOTE%\%ENV%\%LOCATION%\%WORKSPACE%
:: User workspace directory on user network drive
set WSLOCAL=%ENVLOCAL%\%ENV%\%LOCATION%\%WORKSPACE%

:: Plugins and addons location on local drive
set PLUGINSPATH=%ROOTLOCAL%\GUI_Latest\Plugins
set ADDONSPATH=%ROOTLOCAL%\GUI_Latest\Addons
:: Disable common file lookup. Plugins and addons from above location will be loaded
set CMM=false
:: Log files location on local drive
set LOGSPATH=%ROOTLOCAL%\%ENV%\%WORKSPACE%


:: MMI default installation directory for different MMI installation
set "MMI_ROOT=%SYSTEMDRIVE%\Program Files\ION Trading"
:: set "MMI_ROOT_X86=%SYSTEMDRIVE%\Program Files (x86)\ION Trading"
:: set "DEFAULT_MMI_X86=%MMI_ROOT_X86%\ION.NET %MMIVER%"
set "DEFAULT_MMI_X64=%MMI_ROOT%\ION.NET %MMIVER% (64-bit)"

echo MMI path:
set "MMI=MMI %MMIVER% Not installed"
:: if exist "%DEFAULT_MMI_X86%" set MMI=%DEFAULT_MMI_X86%
if exist "%DEFAULT_MMI_X64%" set MMI=%DEFAULT_MMI_X64%
echo %MMI% OK
echo.

if "%MMI%"=="MMI %MMIVER% Not installed" (echo "%MMI%" ERROR && goto COPYMMI)


:PREP
:: Check if user have read/write access on repository - to save workspace
if not exist "%WSREMOTE%" mkdir "%WSREMOTE%"
if not exist "%WSREMOTE%" goto ERRORWRITEREMOTE

:: Copy plugins into local drive
"%REPOSITORY%\%COMMONFOLDER%\robocopy.exe" "%ROOTREMOTE%\GUI_Latest\User" "%ROOTLOCAL%\GUI_Latest" /MIR /NDL /R:3 /COPY:DT

:: Create log directory in local drive
if not exist "%LOGSPATH%" mkdir "%LOGSPATH%"

:PLUGINS
echo Plugins path:
if not exist "%PLUGINSPATH%" echo %PLUGINSPATH% ERROR && goto ERROR
echo %PLUGINSPATH% OK
echo.

:ADDONS
echo Addons path:
if not exist "%ADDONSPATH%" echo %ADDONSPATH% ERROR && goto ERROR
echo %ADDONSPATH% OK
echo.

:WORKSPACE
echo Workspace path:
if not exist "%WSREMOTE%" echo %WSREMOTE% ERROR && goto ERROR
echo %WSREMOTE% OK
echo. 

:LOG 
echo Log path:
if not exist "%LOGSPATH%" echo %LOGSPATH% ERROR && goto ERROR
echo %LOGSPATH% OK
echo.

goto MAIN

:MAIN
:: Launch MMI
start "" /D"%ENVREMOTE%\%ENV%" "%MMI%"\mmi.exe -pluginspath="%PLUGINSPATH%" -addonspath="%ADDONSPATH%" -commonfiles=%CMM% -logspath="%LOGSPATH%" -dbpath="%LOGSPATH%" -workspace="%WORKSPACE%" -env="%ENV%" -envpath="%ENVREMOTE%" -usefullrefdata=true -env:select=false -env:edit=false

goto BACKUPWS
goto EXIT

:ERROR
if "%ERRORLEVEL%"=="2" (goto MAIN)
echo.
echo Missing directory/file.
echo Error level = %ERRORLEVEL%
echo.
pause
goto EXIT

:ERRORWRITEREMOTE
echo. 
echo Insufficient write priviledge
echo Unable to create workspace on %REPOSITORY%
echo Please contact Anvil support
echo.
pause
goto EXIT

:ERRORENV
echo.
echo Unable to set environment connection. Please copy correct shortcut in repository.
echo Error level = %ERRORLEVEL%
echo.
pause
goto EXIT

:BACKUPWS
:: Backup existing workspace in repository into user network drive
"%REPOSITORY%\%COMMONFOLDER%\robocopy.exe" "%WSREMOTE%" "%WSLOCAL%" /e /NDL /R:3 
:: Copy pre-prepared Environment.xml and Workspaces.xml files into user network drive - to be used when repository is unavailable
"%REPOSITORY%\%COMMONFOLDER%\robocopy.exe" "%ROOTREMOTE%\WS" "%ENVLOCAL%" Environment.xml /COPY:DAT /NDL /R:3 /COPY:DT
"%REPOSITORY%\%COMMONFOLDER%\robocopy.exe" "%ROOTREMOTE%\WS\WSConf\Failover" "%ENVLOCAL%\%ENV%" Workspaces.xml /NDL /R:3 /COPY:DT
:: Copy workspace template into local drive
"%REPOSITORY%\%COMMONFOLDER%\robocopy.exe" "%ROOTREMOTE%\WS-Template\Latest_210" "%ROOTLOCAL%\WST_210" /MIR /NDL /R:3 /COPY:DT
if "%DEBUG%"=="1" pause
goto EXIT

:COPYMMI
"%REPOSITORY%\%COMMONFOLDER%\robocopy.exe" "%REPOSITORY%\%COMMONFOLDER%\MMI\ION.NET%MMIVER%" "%ROOTLOCAL%\ION.NET%MMIVER%" /e /NDL /R:3 /COPY:DT
set MMI=%ROOTLOCAL%\ION.NET%MMIVER%
goto PREP

:EXIT
exit /B 0
