@echo off
setlocal enabledelayedexpansion

:: Get the start date-time for the folder name
for /f "tokens=2 delims==" %%i in ('wmic os get localdatetime /value') do set datetime=%%i
set datetime=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2%_%datetime:~8,2%-%datetime:~10,2%-%datetime:~12,2%

:: Create the folder for screenshots
set "screenshotDir=%~dp0screenshots_%datetime%"
mkdir "%screenshotDir%"

:: Initialize the counter
set /a counter=0

:loop
cls

:: Get the title of the active window
for /f "delims=" %%i in ('powershell -NoProfile -Command "Add-Type -MemberDefinition '[DllImport(\"user32.dll\")]public static extern IntPtr GetForegroundWindow();[DllImport(\"user32.dll\")]public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);public static string GetActiveWindowTitle(){const int nChars = 256;System.Text.StringBuilder Buff = new System.Text.StringBuilder(nChars);IntPtr handle = GetForegroundWindow();if (GetWindowText(handle, Buff, nChars) > 0) return Buff.ToString();return null;}' -Name 'User32' -Namespace 'WinAPI' -PassThru | Out-Null; [WinAPI.User32]::GetActiveWindowTitle()" 2^>^&1') do (
    set "activeWindow=%%i"
)

:: Check if the active window is "Affinity Photo 2"
if /i "!activeWindow!"=="Affinity Photo 2" (
    set /a counter+=1
    echo Affinity Photo 2 is active. Capturing screenshot...

    :: Capture screenshot using PowerShell
    powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $bmp = New-Object System.Drawing.Bitmap([System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width, [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height); $graphics = [System.Drawing.Graphics]::FromImage($bmp); $graphics.CopyFromScreen(0, 0, 0, 0, $bmp.Size); $bmp.Save('%screenshotDir%\\!counter!.jpg', [System.Drawing.Imaging.ImageFormat]::Jpeg); $graphics.Dispose(); $bmp.Dispose()"

) else (
    echo Active Window: !activeWindow!
    echo Waiting for "Affinity Photo 2" to become active...
)

:: Wait for 1 second
timeout /t 1 >nul

:: Repeat the loop
goto loop

:end
echo Exiting...
pause >nul
