@echo off
setlocal enabledelayedexpansion
set start=%time%

echo Only NVIDIA GPU Supported For Now.
echo will add Intel and AMD support later
echo.
echo.


:: Common Options

:: 1. Enable Audio?
echo.
echo =========================================
echo (1/1) Enable Audio
echo =========================================
echo [1] Yes
echo [2] No
echo =========================================
choice /C:12 /M:"Select an option:"
set "enableAudio=%ERRORLEVEL%"

:: Execution

if "%enableAudio%"=="1" set "audioParams=-c:a aac -b:a 128k -ar 44100"
if "%enableAudio%"=="2" set "audioParams=-an"

for %%F in (Input\*) do (
    rem built in 2 pass
    ffmpeg -hide_banner -loglevel warning -stats -nostdin -err_detect ignore_err -hwaccel cuda -hwaccel_output_format cuda -i "%%F" -c:v hevc_nvenc -fps_mode vfr -cq 30 %audioParams% -sn -dn -preset:v 1 -tune 5 -profile:v 0 -2pass 1 -multipass 2 -rc 1 -rc-lookahead 60 -no-scenecut 1 -tf_level 4 -movflags faststart -y "Output\%%~nF.mp4"

	rem rename to remove extention
	move "Output\%%~nF.mp4" "Output\%%~nF"
)

:eof
:: Mission accomplished
cmd /c %*
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