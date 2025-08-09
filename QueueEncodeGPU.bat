@echo off
setlocal enabledelayedexpansion
set start=%time%

:: ===== INITIALIZATION =====
echo GPU Video Encoder - Supports NVIDIA, AMD, and Intel GPUs
echo.

:: Check FFmpeg availability
where ffmpeg >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: FFmpeg not found in PATH
    echo Install FFmpeg or add it to system PATH
    echo Download: https://ffmpeg.org/download.html
    pause
    exit /b 1
)

:: Create required directories
if not exist "Input\" mkdir "Input"
if not exist "Output\" mkdir "Output"

:: ===== ENCODER SELECTION =====
echo =========================================
echo "(1/4) Select GPU Encoder"
echo =========================================
echo "[1] NVIDIA - h264_nvenc (Best compatibility)"
echo "[2] NVIDIA - hevc_nvenc (Best compression)"
echo "[3] AMD - h264_amf (Good compatibility)"
echo "[4] AMD - hevc_amf (Good compression)"
echo "[5] Intel - h264_qsv (Fast encoding)"
echo "[6] Intel - hevc_qsv (Efficient compression)"
echo =========================================
choice /C:123456 /M:"Select encoder:"
set "encoderChoice=%ERRORLEVEL%"

:: ===== AUDIO SETTINGS =====
echo.
echo =========================================
echo "(2/4) Audio Settings"
echo =========================================
echo "[1] Include audio (AAC 128kbps)"
echo "[2] No audio"
echo =========================================
choice /C:12 /M:"Select audio option:"
set "audioChoice=%ERRORLEVEL%"

:: ===== QUALITY SETTINGS =====
echo.
echo =========================================
echo "(3/4) Video Quality"
echo =========================================
echo "CQ/CRF value (0-51): Lower = Higher quality"
echo "Recommended: 18-23 (high), 24-28 (medium), 29-36 (low)"
echo =========================================
set /p qualityValue="Enter quality value (default 23): "

:: Validate quality input
if "%qualityValue%"=="" set "qualityValue=23"
echo %qualityValue%| findstr /r "^[0-9][0-9]*$" >nul
if %ERRORLEVEL% neq 0 (
    echo Invalid input. Using default: 23
    set "qualityValue=23"
)

:: ===== SCALING SETTINGS =====
echo.
echo =========================================
echo "(4/4) Video Scaling"
echo =========================================
echo "Scaling percentage (50-200)"
echo "100 = Original size, 50 = Half size, 200 = Double size"
echo =========================================
set /p scaleValue="Enter scale percentage (default 100): "

:: Validate scaling input
if "%scaleValue%"=="" set "scaleValue=100"
echo %scaleValue%| findstr /r "^[0-9][0-9]*$" >nul
if %ERRORLEVEL% neq 0 (
    echo Invalid input. Using default: 100
    set "scaleValue=100"
)

:: ===== BUILD COMMAND PARAMETERS =====

:: Encoder parameters


:: Set encoder and codec based on choice
if "%encoderChoice%"=="1" (
    set "encoderParam=-c:v h264_nvenc -preset slow -profile:v main -cq %qualityValue%"
    set "encoderName=NVIDIA H.264"
    set "hwaccel=cuda"
)
if "%encoderChoice%"=="2" (
    set "encoderParam=-c:v hevc_nvenc -preset slow -profile:v main -cq %qualityValue%"
    set "encoderName=NVIDIA H.265/HEVC"
    set "hwaccel=cuda"
)
if "%encoderChoice%"=="3" (
    set "encoderParam=-c:v h264_amf -preset quality -profile:v main -quality quality -qp %qualityValue%"
    set "encoderName=AMD H.264"
    set "hwaccel=d3d11va"
)
if "%encoderChoice%"=="4" (
    set "encoderParam=-c:v hevc_amf -preset quality -profile:v main -quality quality -qp %qualityValue%"
    set "encoderName=AMD H.265/HEVC"
    set "hwaccel=d3d11va"
)
if "%encoderChoice%"=="5" (
    set "encoderParam=-c:v h264_qsv -preset veryslow -profile:v main -global_quality %qualityValue%"
    set "encoderName=Intel H.264"
    set "hwaccel=qsv"
)
if "%encoderChoice%"=="6" (
    set "encoderParam=-c:v hevc_qsv -preset veryslow -profile:v main -global_quality %qualityValue%"
    set "encoderName=Intel H.265/HEVC"
    set "hwaccel=qsv"
)

:: Audio parameters
if "%audioChoice%"=="1" (
    set "audioParams=-c:a aac -q:a 0.75"
) else (
    set "audioParams=-an"
)

:: Hardware acceleration and output format
if "%scaleValue%"=="100" (
    :: No scaling - use hwaccel_output_format for better performance
    set "scaleFilter="
    set "hwaccelParams=-hwaccel %hwaccel% -hwaccel_output_format %hwaccel%"
) else (
    :: Scaling - keep surface in system memory
    set "scaleFilter=-vf scale=w=iw*%scaleValue%/100:h=ih*%scaleValue%/100:flags=lanczos"
    set "hwaccelParams=-hwaccel %hwaccel%"
)

:: Base parameters
set "baseParams=-hide_banner -loglevel warning -stats -nostdin"
set "outputParams=-movflags faststart"

:: ===== DISPLAY SETTINGS AND START ENCODING =====
cls
echo =========================================
echo ENCODING SETTINGS
echo =========================================
echo Encoder: %encoderName%
echo Audio: %audioChoice% ^(1=Yes, 2=No^)
echo Quality: %qualityValue%
echo Scale: %scaleValue%%%
echo =========================================
echo Starting encoding...
echo.

:: ===== PROCESS FILES =====
for /r "Input" %%F in (*.mp4 *.avi *.mkv *.mov *.wmv *.webm *.flv *.m4v *.ts *.mts *.mpeg *.mpg) do (
    set "inputFile=%%F"
    set "fileName=%%~nF"
    set "fileDir=%%~dpF"
    
    :: Calculate relative path for output structure
    set "relativePath=!fileDir:*Input\=!"
    if "!relativePath!"=="!fileDir!" set "relativePath="
    
    :: Create output directory
    set "outputDir=Output\!relativePath!"
    if not exist "!outputDir!" mkdir "!outputDir!" 2>nul
    
    :: Set output file
    set "outputFile=!outputDir!!fileName!.mp4"
    
    :: Display current file
    if "!relativePath!"=="" (
        echo Processing: %%~nxF
    ) else (
        echo Processing: !relativePath!%%~nxF
    )
    
    :: Execute encoding command
    ffmpeg %baseParams% %hwaccelParams% -i "%%F" %scaleFilter% %encoderParam% %audioParams% %outputParams% -y "!outputFile!"

    :: Clean up temporary files
    del "ffmpeg2pass-0.log" 2>nul
)

:: ===== CALCULATE AND DISPLAY EXECUTION TIME =====
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
echo.
echo =========================================
echo ENCODING COMPLETED!
echo Total time: %hours%:%mins%:%secs%.%ms% (%totalsecs%.%ms%s)
echo =========================================
echo.

pause