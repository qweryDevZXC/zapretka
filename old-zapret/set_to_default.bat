@echo off
setlocal EnableDelayedExpansion
chcp 65001 > nul
:: 65001 - UTF-8

net session >nul 2>&1
if not %errorLevel% == 0 (
	powershell -Command "Start-Process 'cmd.exe' -ArgumentList '/c \"\"%~f0\" admin\"' -Verb RunAs"
	exit /b
)

:: Main
cd /d "%~dp0"
set BIN_PATH=%~dp0bin\
set LISTS_PATH=%~dp0lists\

:: Searching for .bat files in current folder, except files that start with "service"
echo Pick one of the options:
set "count=0"
for %%f in (*.bat) do (
    set "filename=%%~nxf"
    if /i not "!filename:~0,7!"=="service" if /i not "!filename:~0,13!"=="check_updates" if /i not "!filename:~0,17!"=="cloudflare_switch" if /i not "!filename!"=="set_to_default.bat" (
        set /a count+=1
        echo !count!. %%f
        set "file!count!=%%f"
    )
)

:: Choosing file
set "choice="
set /p "choice=Input file index (number): "
if "!choice!"=="" goto :eof

set "selectedFile=!file%choice%!"
if not defined selectedFile (
    echo Wrong choice, exiting...
    pause
    goto :eof
)

:: Save to default.txt file
set "defaultFile=default.txt"
if exist "%defaultFile%" del "%defaultFile%"
echo !selectedFile! > "%defaultFile%"

:: Clear console
cls

:: Notify user
echo The default file has been set to: !selectedFile!
pause
goto :eof