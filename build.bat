@echo off
setlocal enabledelayedexpansion

:: ========================================
:: User Configuration (Edit these for new projects)
:: ========================================
:: MCU Device Name for J-Link (e.g., GD32C103CB, STM32F407ZG)
set "JLINK_DEVICE=GD32C103CB"

:: Path to J-Link executable
set "JLINK_EXE=D:\Program Files\SEGGER\JLink_V942\JLink.exe"

:: Build Directory Name
set "BUILD_DIR=build"

:: CMake Generator & Toolchain
set "CMAKE_GENERATOR=MinGW Makefiles"
set "TOOLCHAIN_FILE=toolchain.cmake"

:: ========================================
:: Main Router
:: ========================================
if "%~1"=="" (
    call :task_build
    call :task_report
    exit /b !ERRORLEVEL!
)

:loop
if "%~1"=="" goto end_loop
if /I "%~1"=="clean" call :task_clean
if /I "%~1"=="build" call :task_build
if /I "%~1"=="rebuild" (
    call :task_clean
    call :task_build
)
if /I "%~1"=="flash" call :task_flash
shift
goto loop

:end_loop
call :task_report
exit /b 0

:: ========================================
:: Task 1: Clean
:: ========================================
:task_clean
echo.
echo [INFO] Cleaning %BUILD_DIR% directory...
if exist %BUILD_DIR%\ (
    rmdir /S /Q %BUILD_DIR%
    echo [INFO] Clean done.
) else (
    echo [INFO] %BUILD_DIR% directory not found. No need to clean.
)
exit /b 0

:: ========================================
:: Task 2: Build
:: ========================================
:task_build
echo.
echo [INFO] Starting build...
if not exist %BUILD_DIR%\ (
    echo [INFO] CMake cache not found. Configuring...
    cmake -B %BUILD_DIR% "-DCMAKE_TOOLCHAIN_FILE=%TOOLCHAIN_FILE%" -G "%CMAKE_GENERATOR%"
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] CMake configure failed!
        exit /b !ERRORLEVEL!
    )
)

echo [INFO] Compiling...
:: Auto-detect CPU cores for maximum compilation speed
cmake --build %BUILD_DIR% -j%NUMBER_OF_PROCESSORS%
if !ERRORLEVEL! neq 0 (
    echo [ERROR] Build failed!
    exit /b !ERRORLEVEL!
)
echo [INFO] Build successful!
exit /b 0

:: ========================================
:: Task 3: Flash
:: ========================================
:task_flash
echo.
echo [INFO] Starting flash...

if not exist "%JLINK_EXE%" (
    echo [ERROR] JLink.exe not found! Please check JLINK_EXE path in build.bat or add it to system PATH.
    exit /b 1
)

set "HEX_FILE="
for %%F in (%BUILD_DIR%\*.hex) do (
    set "HEX_FILE=%%F"
    goto :found_hex
)
:found_hex

if not defined HEX_FILE (
    echo [ERROR] No .hex file found! Please run 'build.bat build' first.
    exit /b 1
)

echo [INFO] Target firmware found: !HEX_FILE!

:: Generate temporary J-Link script
set "JLINK_SCRIPT=%BUILD_DIR%\flash_tmp.jlink"
echo loadfile !HEX_FILE! > "!JLINK_SCRIPT!"
echo r >> "!JLINK_SCRIPT!"
echo g >> "!JLINK_SCRIPT!"
echo q >> "!JLINK_SCRIPT!"

echo [INFO] Flashing via J-Link (%JLINK_DEVICE%)...
"%JLINK_EXE%" -nogui 1 -device %JLINK_DEVICE% -if SWD -speed auto -autoconnect 1 -CommanderScript "!JLINK_SCRIPT!"

if !ERRORLEVEL! neq 0 (
    echo [ERROR] Flash failed! Please check connection.
) else (
    echo [INFO] Flash successful! Device restarted.
)

if exist "!JLINK_SCRIPT!" del "!JLINK_SCRIPT!"
exit /b 0

:: ========================================
:: Task 4: Memory Report
:: ========================================
:task_report
set "MAP_FILE="
for %%F in (%BUILD_DIR%\*.map) do (
    set "MAP_FILE=%%F"
    goto :found_map
)
:found_map
if defined MAP_FILE (
    python script\mem_report.py "!MAP_FILE!"
)
exit /b 0
