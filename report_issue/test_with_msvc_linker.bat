@echo off
setlocal enabledelayedexpansion
REM Change to script's directory
pushd "%~dp0"

echo ========================================
echo WORKAROUND: Building with MSVC linker
echo ========================================
echo.

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

echo Initializing MSVC environment...
set "VSCMD_ARG_no_logo=1"
call "%VSCMD_PATH%" -arch=x64 -host_arch=x64 >nul 2>&1

if not exist test_lib.lib (
    echo Building test_lib.lib first...
    call "%~dp0build_test_lib.bat"
    if %ERRORLEVEL% NEQ 0 (
        popd
        exit /b 1
    )
)

echo.
echo Creating C test program that uses test_lib...
echo #include ^<stdio.h^> > msvc_test.c
echo. >> msvc_test.c
echo extern int test_add(int a, int b); >> msvc_test.c
echo extern void test_alloc_free(void); >> msvc_test.c
echo. >> msvc_test.c
echo int main(void) { >> msvc_test.c
echo     printf("Testing with MSVC Debug CRT...\n"); >> msvc_test.c
echo     int result = test_add(5, 3); >> msvc_test.c
echo     printf("test_add(5, 3) = %%d\n", result); >> msvc_test.c
echo     test_alloc_free(); >> msvc_test.c
echo     printf("test_alloc_free() completed\n"); >> msvc_test.c
echo     printf("\n✓ All tests passed with MSVC linker!\n"); >> msvc_test.c
echo     return 0; >> msvc_test.c
echo } >> msvc_test.c

echo.
echo Step 1: Compile with MSVC using Debug CRT (/MDd)...
cl.exe /nologo /MDd /Zi /Od msvc_test.c /link test_lib.lib /OUT:msvc_test.exe

if %ERRORLEVEL% NEQ 0 (
    echo ✗ Compilation failed!
    popd
    exit /b 1
)

echo.
echo Step 2: Run the test...
msvc_test.exe

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ✓ SUCCESS with MSVC linker!
    echo ========================================
    echo.
    echo This proves the issue is with lld-link, not the code.
    echo MSVC's link.exe handles debug CRT correctly.
    echo.
    echo Compare this to: zig build test -Dtarget=native-windows-msvc
    echo which FAILS with duplicate symbol errors from lld-link.
) else (
    echo ✗ Test execution failed!
    popd
    exit /b 1
)

REM Cleanup (vc140.pdb is kept as it belongs with test_lib.lib)
del msvc_test.c msvc_test.obj msvc_test.exe msvc_test.ilk msvc_test.pdb 2>nul

popd
