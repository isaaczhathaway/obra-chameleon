@echo off
setlocal

cd /d "%~dp0"
title Obra Chameleon Installer

echo Obra Chameleon Windows Installer v0.2
echo.
echo This window will remain open so you can read all messages.
echo.

where powershell.exe >nul 2>nul
if errorlevel 1 (
	echo ERROR: Windows PowerShell was not found.
	set "INSTALL_EXIT_CODE=1"
	goto finished
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -NoPause
set "INSTALL_EXIT_CODE=%ERRORLEVEL%"

:finished
echo.
if not "%INSTALL_EXIT_CODE%"=="0" (
	echo Installation failed with exit code %INSTALL_EXIT_CODE%.
	echo Review the error above before closing this window.
) else (
	echo Installer finished successfully.
)
echo.
pause
exit /b %INSTALL_EXIT_CODE%
