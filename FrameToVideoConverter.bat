@echo off
setlocal enabledelayedexpansion
del temp_files.txt
del padded_files.txt
del sorted_files.txt
cls

rem Set folder path and frame rate
set folder_path=ss
set framerate=24
set quality=35
set /p folder_path="Enter the folder name relative to the script path: "
set /p framerate="Enter the frame rate (e.g., 24): "
set /p quality="Enter the quality level (e.g., 35): "

:: Create Temp Folder to prevent permanet loss
set "temp_folder_path=%folder_path%_temp"
rmdir /s /q "%temp_folder_path%"
mkdir "%temp_folder_path%"
xcopy "%folder_path%\*.jpg" "%temp_folder_path%\" /y

:: Create a temporary file to list all jpg files
dir /b /a-d "%temp_folder_path%\*.jpg" > temp_files.txt

:: Pad numbers with leading zeros and store in padded_files.txt
(for /f "tokens=*" %%a in (temp_files.txt) do (
    set filename=%%~na
    set padded=0000000000!filename!
    set padded=!padded:~-10!
	ren "%temp_folder_path%\%%a" "!padded!.jpg"
    echo !padded!.jpg >> padded_files.txt
))

:: Sort the padded file list numerically and store in sorted_files.txt
sort padded_files.txt > sorted_files.txt

:: Initialize the counter
set i=0

:: Read the sorted list and rename files
(for /f "tokens=* delims=" %%b in (sorted_files.txt) do (
	echo "%temp_folder_path%\%%b"
    ren "%temp_folder_path%\%%b" "!i!.jpg"
    set /a i+=1
))

:: Clean up temporary files
del temp_files.txt
del padded_files.txt
del sorted_files.txt
cls

rem Convert images to HEVC MP4
mkdir "%folder_path%\output"
ffmpeg -hide_banner -loglevel warning -stats -hwaccel cuda -framerate %framerate% -i "%temp_folder_path%\%%01d.jpg" -c:v hevc_nvenc -cq %quality% -fps_mode vfr -an -dn -sn -preset:v 1 -tune 5 -profile:v 0 -2pass 1 -multipass 2 -rc 1 -rc-lookahead 30 -no-scenecut 1 -movflags faststart -y "%folder_path%\output\output.mp4"

rmdir /s /q "%temp_folder_path%"
echo Done!
pause

