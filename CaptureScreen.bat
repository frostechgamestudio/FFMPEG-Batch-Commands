@echo off
setlocal

:: Configuration
set OUTPUT_FILE=recording_%DATE:~-4%-%DATE:~-7,2%-%DATE:~-10,2%_%TIME:~0,2%-%TIME:~3,2%-%TIME:~6,2%.mp4
set OUTPUT_FILE=%OUTPUT_FILE: =0%
set FRAMERATE=60
set BITRATE=8M

echo Starting screen recording with NVIDIA GPU acceleration...
echo Press q to stop recording

:: Fixed NVIDIA CUDA acceleration (hwaccel must come BEFORE input)
ffmpeg -hwaccel cuda -hwaccel_output_format cuda ^
    -f gdigrab -framerate %FRAMERATE% -i desktop -draw_mouse 1 ^
    -c:v h264_nvenc -rc:v vbr_hq -cq:v 18 -qmin 15 -qmax 21 ^
    -b:v %BITRATE% -maxrate:v 10M -preset p7 -tune hq ^
    -pix_fmt nv12 -y "%OUTPUT_FILE%"

echo Recording saved to %OUTPUT_FILE%