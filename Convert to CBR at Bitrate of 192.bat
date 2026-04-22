@echo off
setlocal enabledelayedexpansion

:: Define the output folder name
set "OUTDIR=Converted"
set "SUFFIX= CBR 192kbps"

:: 1. Check if FFmpeg is installed
ffmpeg -version >nul 2>&1
if %errorlevel% neq 0 (
    echo FFmpeg not found. Attempting to install via WinGet...
    winget install -e --id Gyan.FFmpeg
    
    if !errorlevel! neq 0 (
        echo [ERROR] WinGet failed to install FFmpeg. 
        pause
        exit /b
    )
    
    for /f "tokens=2*" %%A in ('reg query "HKLM\System\CurrentControlSet\Control\Session Manager\Environment" /v Path') do set "syspath=%%B"
    for /f "tokens=2*" %%A in ('reg query "HKCU\Environment" /v Path') do set "userpath=%%B"
    set "PATH=!syspath!;!userpath!"
    echo FFmpeg installed successfully.
)

:: 2. Clear existing conversions
if exist "%OUTDIR%" (
    echo Cleaning existing conversions in %OUTDIR%...
    del /q "%OUTDIR%\*%SUFFIX%.mp3"
) else (
    mkdir "%OUTDIR%"
)

:: 3. Convert all MP3s (with error handling for corrupt headers)
echo Starting conversion to 192kbps CBR...

for %%f in (*.mp3) do (
    set "filename=%%~nf"
    echo Processing: "%%f"
    
    :: Added -fflags +genpts to fix "Header missing" and timing errors
    ffmpeg -fflags +genpts -i "%%f" -codec:a libmp3lame -b:a 192k -map_metadata 0 -ignore_unknown "%OUTDIR%\!filename!!SUFFIX!.mp3" -loglevel error

    if !errorlevel! neq 0 (
        echo [WARNING] Could not convert "%%f". The file might be severely corrupted.
    )
)

echo.
echo Process complete. Check the "%OUTDIR%" folder.
pause