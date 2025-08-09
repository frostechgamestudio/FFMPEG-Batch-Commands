@echo off
setlocal enabledelayedexpansion
set start=%time%

echo Frame Sequence to Video Converter
echo Supports PNG and JPG image sequences
echo.

:: Check if FFmpeg is available
where ffmpeg >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo.
    echo =========================================
    echo ERROR: FFmpeg is not found in your PATH.
    echo Please install FFmpeg or add it to your system PATH.
    echo You can download FFmpeg from https://ffmpeg.org/download.html
    echo.
    pause
    exit /b 1
)

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

:: 1. Codec Selection
echo.
echo =========================================
echo "(1/5) Select Video Codec"
echo =========================================
echo "[1] H.264 (CPU) - Better compatibility"
echo "[2] H.265/HEVC (CPU) - Better compression"
echo "[3] H.264 (NVIDIA GPU) - Faster encoding"
echo "[4] H.265/HEVC (NVIDIA GPU) - Fastest + Best compression"
echo =========================================
choice /C:1234 /M:"Select an option:"
set "codecChoice=%ERRORLEVEL%"
if "%codecChoice%"=="1" set "codec=libx264"
if "%codecChoice%"=="2" set "codec=libx265"
if "%codecChoice%"=="3" set "codec=h264_nvenc"
if "%codecChoice%"=="4" set "codec=hevc_nvenc"

:: 2. Frame Rate Selection
echo.
echo =========================================
echo "(2/5) Frame Rate Setting"
echo =========================================
echo "[1] 24 FPS (Cinema)"
echo "[2] 30 FPS (Standard)"
echo "[3] 60 FPS (High framerate)"
echo "[4] Custom"
echo =========================================
choice /C:1234 /M:"Select an option:"
set "fpsChoice=%ERRORLEVEL%"
if "%fpsChoice%"=="1" set "framerate=24"
if "%fpsChoice%"=="2" set "framerate=30"
if "%fpsChoice%"=="3" set "framerate=60"
if "%fpsChoice%"=="4" (
    set /p framerate="Enter custom frame rate: "
    if "!framerate!"=="" set "framerate=24"
)

:: 3. Quality Selection
echo.
echo =========================================
echo "(3/5) Video Quality Setting"
echo =========================================
echo "Quality values (lower = better quality, larger files):"
echo "18-22: Very High Quality"
echo "23-28: High Quality (recommended)"
echo "29-35: Medium Quality"
echo "36-42: Low Quality"
echo =========================================
set /p quality="Enter quality value (default is 25): "
if "%quality%"=="" set "quality=25"

:: 4. Image Format Selection
echo.
echo =========================================
echo "(4/5) Input Image Format"
echo =========================================
echo "[1] JPG/JPEG files"
echo "[2] PNG files"
echo "[3] Both JPG and PNG"
echo =========================================
choice /C:123 /M:"Select an option:"
set "imageChoice=%ERRORLEVEL%"

:: 5. Processing Mode
echo.
echo =========================================
echo "(5/5) Processing Mode"
echo =========================================
echo "[1] Process all subfolders individually"
echo "[2] Process specific folder only"
echo =========================================
choice /C:12 /M:"Select an option:"
set "processMode=%ERRORLEVEL%"

if "%processMode%"=="2" (
    echo.
    echo Available folders in Input directory:
    for /d %%D in ("Input\*") do echo   %%~nxD
    echo.
    set /p specificFolder="Enter folder name to process: "
)

:: Set codec-specific parameters
if "%codecChoice%"=="1" set "codecParams=-c:v libx264 -crf %quality% -preset medium"
if "%codecChoice%"=="2" set "codecParams=-c:v libx265 -crf %quality% -preset medium"
if "%codecChoice%"=="3" set "codecParams=-c:v h264_nvenc -cq %quality% -preset medium"
if "%codecChoice%"=="4" set "codecParams=-c:v hevc_nvenc -cq %quality% -preset medium"

:: Set common parameters
set "commonParams=-pix_fmt yuv420p -movflags faststart -an"
set "preParam=-hide_banner -loglevel warning -stats -nostdin"

cls
echo.
echo =========================================
echo "Frame Sequence to Video Converter"
if "%codecChoice%"=="1" echo "Codec: H.264 (CPU)"
if "%codecChoice%"=="2" echo "Codec: H.265/HEVC (CPU)"
if "%codecChoice%"=="3" echo "Codec: H.264 (NVIDIA GPU)"
if "%codecChoice%"=="4" echo "Codec: H.265/HEVC (NVIDIA GPU)"
echo "Frame Rate: %framerate% FPS"
echo "Quality: %quality%"
if "%imageChoice%"=="1" echo "Input Format: JPG/JPEG"
if "%imageChoice%"=="2" echo "Input Format: PNG"
if "%imageChoice%"=="3" echo "Input Format: JPG and PNG"
echo =========================================
echo Starting conversion...
echo.

:: Process folders based on mode
if "%processMode%"=="1" (
    :: Process all subfolders
    for /d %%D in ("Input\*") do (
        call :ProcessFolder "%%D"
    )
) else (
    :: Process specific folder
    if exist "Input\%specificFolder%" (
        call :ProcessFolder "Input\%specificFolder%"
    ) else (
        echo Error: Folder "Input\%specificFolder%" not found!
        pause
        exit /b 1
    )
)

goto :EndScript

:ProcessFolder
set "inputDir=%~1"
set "folderName=%~nx1"
set "outputDir=Output\%folderName%"

echo.
echo Processing folder: %folderName%

:: Create output directory
if not exist "%outputDir%" mkdir "%outputDir%"

:: Create temporary working directory
set "tempDir=%inputDir%_temp"
if exist "%tempDir%" rmdir /s /q "%tempDir%"
mkdir "%tempDir%"

:: Copy and process images based on format choice
set "imageCount=0"
if "%imageChoice%"=="1" (
    for %%F in ("%inputDir%\*.jpg" "%inputDir%\*.jpeg") do (
        if exist "%%F" (
            set /a imageCount+=1
            copy "%%F" "%tempDir%\!imageCount!.jpg" >nul
        )
    )
    set "inputPattern=%tempDir%\%%d.jpg"
)
if "%imageChoice%"=="2" (
    for %%F in ("%inputDir%\*.png") do (
        if exist "%%F" (
            set /a imageCount+=1
            copy "%%F" "%tempDir%\!imageCount!.png" >nul
        )
    )
    set "inputPattern=%tempDir%\%%d.png"
)
if "%imageChoice%"=="3" (
    for %%F in ("%inputDir%\*.jpg" "%inputDir%\*.jpeg" "%inputDir%\*.png") do (
        if exist "%%F" (
            set /a imageCount+=1
            copy "%%F" "%tempDir%\!imageCount!%%~xF" >nul
        )
    )
    set "inputPattern=%tempDir%\%%d.*"
)

if !imageCount! equ 0 (
    echo   No image files found in %folderName%
    rmdir /s /q "%tempDir%"
    goto :eof
)

echo   Found !imageCount! image files
echo   Converting to video...

:: Convert images to video
ffmpeg %preParam% -framerate %framerate% -i "%inputPattern%" %codecParams% %commonParams% -y "%outputDir%\%folderName%.mp4"

:: Clean up temporary directory
rmdir /s /q "%tempDir%"

echo   Completed: %outputDir%\%folderName%.mp4
goto :eof

:EndScript
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
echo.
echo =========================================
echo "Conversion completed!"
echo "Command took %hours%:%mins%:%secs%.%ms% (%totalsecs%.%ms%s total)"
echo.

pause