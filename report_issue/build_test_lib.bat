@echo off
REM Change to script's directory to ensure we can find test_lib.c
pushd "%~dp0"

echo Building test_lib.c with MSVC Debug CRT (/MDd)...

REM Detect Visual Studio installation (try 2022, then 2019, then Build Tools)
set "VSCMD_PATH="

if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat" (
    set "VSCMD_PATH=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\VsDevCmd.bat"
    goto :found_vs
)
if exist "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\Tools\VsDevCmd.bat" (
    set "VSCMD_PATH=C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\Tools\VsDevCmd.bat"
    goto :found_vs
)
if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" (
    set "VSCMD_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat"
    goto :found_vs
)
if exist "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat" (
    set "VSCMD_PATH=C:\Program Files\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat"
    goto :found_vs
)
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\Tools\VsDevCmd.bat" (
    set "VSCMD_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\Tools\VsDevCmd.bat"
    goto :found_vs
)
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\Tools\VsDevCmd.bat" (
    set "VSCMD_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\Tools\VsDevCmd.bat"
    goto :found_vs
)
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\Tools\VsDevCmd.bat" (
    set "VSCMD_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\Tools\VsDevCmd.bat"
    goto :found_vs
)
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\Common7\Tools\VsDevCmd.bat" (
    set "VSCMD_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\Common7\Tools\VsDevCmd.bat"
    goto :found_vs
)

echo ✗ Error: Visual Studio not found!
echo Please install Visual Studio 2019/2022 (any edition) or Build Tools with C++ support.
popd
exit /b 1

:found_vs

set "VSCMD_ARG_no_logo=1"
call "%VSCMD_PATH%" -arch=x64 -host_arch=x64 >nul 2>&1

REM Compile test_lib.c with Debug CRT
cl.exe /nologo /c /MDd /Zi /Od test_lib.c

REM Create static library
lib.exe /nologo /out:test_lib.lib test_lib.obj

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ Successfully built test_lib.lib with MSVC Debug CRT
    echo   Size: 
    dir /b test_lib.lib | findstr /v "^$"
    echo.
    echo Now try: zig build test -Dtarget=native-windows-msvc
    echo This WILL FAIL with duplicate symbol errors from lld-link
    popd
    exit /b 0
) else (
    echo.
    echo ✗ Build failed!
    popd
    exit /b 1
)
