# Build and run RocksDB C++ backup/restore test
# This helps determine if the assertion failure is in RocksDB itself or our wrapper

param(
    [string]$BuildType = "Debug"
)

Write-Host "=== RocksDB C++ Backup/Restore Test ===" -ForegroundColor Cyan
Write-Host "Build Type: $BuildType" -ForegroundColor Yellow
Write-Host ""

$ErrorActionPreference = "Stop"

# Ensure we're in the right directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Make sure RocksDB is built first
Write-Host "Checking if RocksDB is built..." -ForegroundColor Yellow
$rocksdbLib = Get-ChildItem -Path "..\zig-out\lib\rocksdb.lib" -ErrorAction SilentlyContinue
if (-not $rocksdbLib) {
    Write-Host "RocksDB library not found. Building..." -ForegroundColor Yellow
    Push-Location ..
    zig build
    Pop-Location
}

# Create build directory
$buildDir = "build_$($BuildType.ToLower())"
if (Test-Path $buildDir) {
    Remove-Item -Recurse -Force $buildDir
}
New-Item -ItemType Directory -Path $buildDir | Out-Null

# Configure with CMake
Write-Host "`nConfiguring CMake ($BuildType)..." -ForegroundColor Yellow
Push-Location $buildDir
cmake .. -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=$BuildType
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Host "CMake configuration failed!" -ForegroundColor Red
    exit 1
}

# Build
Write-Host "`nBuilding..." -ForegroundColor Yellow
cmake --build . --config $BuildType
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}
Pop-Location

# Run the test
Write-Host "`nRunning C API test..." -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan

$exePath = Join-Path $buildDir "$BuildType\test_c_api.exe"
if (-not (Test-Path $exePath)) {
    # Try alternative path
    $exePath = Join-Path $buildDir "test_c_api.exe"
}

if (-not (Test-Path $exePath)) {
    Write-Host "Could not find test executable at: $exePath" -ForegroundColor Red
    exit 1
}

& $exePath
$testResult = $LASTEXITCODE

Write-Host "================================================" -ForegroundColor Cyan

if ($testResult -eq 0) {
    Write-Host "`nTest PASSED" -ForegroundColor Green
} else {
    Write-Host "`nTest FAILED (exit code: $testResult)" -ForegroundColor Red
    Write-Host "This indicates the issue is in RocksDB itself, not the Zig wrapper." -ForegroundColor Yellow
}

exit $testResult
