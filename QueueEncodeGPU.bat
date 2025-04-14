@echo off
setlocal enabledelayedexpansion
set start=%time%

echo Only NVIDIA GPU Supported For Now.
echo will add Intel and AMD support later
echo.
echo.

:: Check if Input and Output directories exist
if not exist "Input\" (
    echo Input directory not found! Creating it...
    mkdir "Input"
)

if not exist "Output\" (
    echo Output directory not found! Creating it...
    mkdir "Output"
)

:: Common Options

:: 1. Enable Audio?
echo.
echo =========================================
echo (1/2) Enable Audio
echo =========================================
echo [1] Yes
echo [2] No
echo =========================================
choice /C:12 /M:"Select an option:"
set "enableAudio=%ERRORLEVEL%"

:: 2. Quality Selection (CQ Value)
echo.
echo =========================================
echo (2/2) Video Quality Setting
echo =========================================
echo The CQ value controls quality (0-51)
echo Lower values = Higher quality, larger files
echo Higher values = Lower quality, smaller files
echo Recommended range: 18-36
echo =========================================
set /p cqValue="Enter CQ value (default is 30): "

:: Validate input - if empty or not a number, use default
if "%cqValue%"=="" set "cqValue=30"
set "validNum=true"
for /f "delims=0123456789" %%i in ("%cqValue%") do set "validNum=false"
if "%validNum%"=="false" (
    echo Invalid number. Using default value of 30.
    set "cqValue=30"
)

:: Set optional parameters flag (hardcoded)
set "enableOptionalParam=false"

:: Execution

if "%enableAudio%"=="1" set "audioParams=-c:a aac -b:a 128k -ar 44100"
if "%enableAudio%"=="2" set "audioParams=-an"

:: Set optional parameters based on flag
if "%enableOptionalParam%"=="true" (
    set "optionalParam=-rc 1 -rc-lookahead 60 -no-scenecut 1 -tf_level 4"
) else (
    set "optionalParam="
)

for %%F in (Input\*) do (
    rem built in 2 pass
    ffmpeg -hide_banner -loglevel warning -stats -nostdin -err_detect ignore_err -hwaccel cuda -hwaccel_output_format cuda -i "%%F" -c:v hevc_nvenc -fps_mode vfr -cq %cqValue% %audioParams% -sn -dn -preset:v 1 -tune 5 -profile:v 0 -2pass 1 -multipass 2 %optionalParam% -movflags faststart -y "Output\%%~nF.mp4"

    rem rename to remove extention
    rem move "Output\%%~nF.mp4" "Output\%%~nF"
)

:: Calculate execution time
set end=%time%
set options="tokens=1-4 delims=:.," 
for /f %options% %%a in ("%start%") do set start_h=%%a&set /a start_m=100%%b %% 100&set /a start_s=100%%c %% 100&set /a start_ms=100%%d %% 100
for /f %options% %%a in ("%end%") do set end_h=%%a&set /a end_m=100%%b %% 100&set /a end_s=100%%c %% 100&set /a end_ms=100%%d %% 100

set /a hours=%end_h%-%start_h%
set /a mins=%end_m%-%start_m%
set /a secs=%end_s%-%start_s%
set /a ms=%end_ms%-%start_ms%
if %ms% lss 0 set /a secs = %secs% - 1 & set /a ms = 100%ms%
if %secs% lss 0 set /a mins = %mins% - 1 & set /a secs = 60%secs%
if %mins% lss 0 set /a hours = %hours% - 1 & set /a mins = 60%mins%
if %hours% lss 0 set /a hours = 24%hours%
if 1%ms% lss 100 set ms=0%ms%

set /a totalsecs = %hours%*3600 + %mins%*60 + %secs%
echo command took %hours%:%mins%:%secs%.%ms% (%totalsecs%.%ms%s total)

pause