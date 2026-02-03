@echo off
setlocal enabledelayedexpansion
REM Change to script's directory to ensure we can find test_lib.c
pushd "%~dp0"

echo Building test_lib.c with MSVC Debug CRT (/MDd)...

REM Detect Visual Studio installation using vswhere.exe (official VS discovery tool)
REM This handles Preview, Insiders, custom installs, and future VS versions
set "VSCMD_PATH="
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"

if exist "%VSWHERE%" (
    for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
        set "VS_INSTALL_PATH=%%i"
    )
    
    if defined VS_INSTALL_PATH (
        set "VSCMD_PATH=!VS_INSTALL_PATH!\Common7\Tools\VsDevCmd.bat"
        if exist "!VSCMD_PATH!" goto :found_vs
    )
    echo vswhere.exe found no VS installation with C++ tools, trying fallback paths...
) else (
    echo vswhere.exe not found, trying fallback paths...
)

REM Fallback: Manual path detection (for compatibility)
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
