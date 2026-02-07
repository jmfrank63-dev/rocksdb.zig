@echo off
setlocal enabledelayedexpansion

echo ===================================================
echo Building test_restore_msvc_debug.c with MSVC Debug
echo Using MSVC Compiler (cl.exe) + MSVC Linker (link.exe)
echo ===================================================
echo.

REM Initialize MSVC environment
set "VSCMD_ARG_no_logo=1"
call "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\VsDevCmd.bat" -arch=x64 -host_arch=x64 >nul 2>&1

REM Paths
set ROCKSDB_INCLUDE=%LOCALAPPDATA%\zig\p\N-V-__8AAEv0kgK0ypKHX8K7uy2ja2yMJb-o6B8pmW-B0ur5\include
set ROCKSDB_LIB_DEBUG=build_rocksdb\Debug\rocksdb.lib

REM Check if Debug library exists
if not exist "%ROCKSDB_LIB_DEBUG%" (
    echo ERROR: Debug rocksdb.lib not found at %ROCKSDB_LIB_DEBUG%
    echo Please build it first: cd build_rocksdb ^&^& msbuild rocksdb.sln /p:Configuration=Debug /p:Platform=x64
    exit /b 1
)

echo Compiling with MSVC Debug mode...
echo.

REM Compile with MSVC in Debug mode
cl.exe /nologo ^
    /Zi ^
    /Od ^
    /MDd ^
    /D_DEBUG ^
    /D_CRT_SECURE_NO_WARNINGS ^
    /I"%ROCKSDB_INCLUDE%" ^
    test_restore_msvc_debug.c ^
    "%ROCKSDB_LIB_DEBUG%" ^
    Rpcrt4.lib ^
    Shlwapi.lib ^
    /Fe:test_restore_msvc_debug_msvc.exe

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Compilation failed!
    exit /b 1
)

echo.
echo ===================================================
echo Build successful! Running test...
echo ===================================================
echo.

test_restore_msvc_debug_msvc.exe

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo *** TEST FAILED ***
    exit /b 1
) else (
    echo.
    echo *** TEST PASSED ***
    exit /b 0
)
