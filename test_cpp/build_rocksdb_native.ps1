#!/usr/bin/env pwsh
# Build RocksDB natively with MSVC, then build and run our test

param(
    [string]$BuildType = "Debug"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Building RocksDB and C API Test (Native MSVC Build) ===" -ForegroundColor Cyan
Write-Host "Test Build Type: $BuildType" -ForegroundColor Yellow
Write-Host ""

# Paths
$rocksdbSource = "$env:USERPROFILE\AppData\Local\zig\p\N-V-__8AAEv0kgK0ypKHX8K7uy2ja2yMJb-o6B8pmW-B0ur5"
$rocksdbBuildDir = "../build/rocksdb_native"
$testBuildDir = "build_native_$($BuildType.ToLower())"

if (-not (Test-Path $rocksdbSource)) {
    Write-Host "ERROR: RocksDB source not found at $rocksdbSource" -ForegroundColor Red
    Write-Host "Please run 'zig build' in parent directory first to fetch RocksDB" -ForegroundColor Red
    exit 1
}

# Step 1: Build RocksDB with MSVC
Write-Host "Step 1: Building RocksDB with MSVC ($BuildType mode)..." -ForegroundColor Cyan

if (Test-Path $rocksdbBuildDir) {
    Write-Host "  Using existing RocksDB build directory..." -ForegroundColor Yellow
} else {
    mkdir $rocksdbBuildDir | Out-Null
}

Set-Location $rocksdbBuildDir

Write-Host "  Configuring RocksDB..." -ForegroundColor Yellow
cmake $rocksdbSource `
    -G "Visual Studio 17 2022" -A x64 `
    -DCMAKE_BUILD_TYPE=$BuildType `
    -DCMAKE_CXX_FLAGS="/FS" `
    -DROCKSDB_BUILD_SHARED=OFF `
    -DWITH_TESTS=OFF `
    -DWITH_TOOLS=OFF `
    -DWITH_GFLAGS=OFF `
    -DWITH_SNAPPY=OFF `
    -DWITH_LZ4=OFF `
    -DWITH_ZLIB=OFF `
    -DWITH_ZSTD=OFF `
    -DFAIL_ON_WARNINGS=OFF

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: CMake configuration failed" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Write-Host "  Building RocksDB (this may take several minutes)..." -ForegroundColor Yellow
cmake --build . --config $BuildType

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: RocksDB build failed" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Set-Location ..
Write-Host "  ✓ RocksDB built successfully" -ForegroundColor Green

# Step 2: Build our C test
Write-Host "`nStep 2: Building C API test ($BuildType mode)..." -ForegroundColor Cyan

if (Test-Path $testBuildDir) {
    Write-Host "  Using existing test build directory..." -ForegroundColor Yellow
} else {
    mkdir $testBuildDir | Out-Null
}

Set-Location $testBuildDir

Write-Host "  Configuring test..." -ForegroundColor Yellow
cmake .. `
    -G "Visual Studio 17 2022" -A x64 `
    -DUSE_NATIVE_ROCKSDB=ON `
    -DROCKSDB_BUILD_DIR="$PWD\..\$rocksdbBuildDir"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Test CMake configuration failed" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Write-Host "  Building test..." -ForegroundColor Yellow
cmake --build . --config $BuildType

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Test build failed" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Write-Host "  ✓ Test built successfully" -ForegroundColor Green

# Step 3: Run the test
Write-Host "`nStep 3: Running test..." -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan

$exePath = ".\$BuildType\test_c_api.exe"
if (-not (Test-Path $exePath)) {
    $exePath = ".\test_c_api.exe"
}

if (-not (Test-Path $exePath)) {
    Write-Host "ERROR: Could not find test executable" -ForegroundColor Red
    Set-Location ..
    exit 1
}

& $exePath

$exitCode = $LASTEXITCODE
Set-Location ..

Write-Host ""
if ($exitCode -eq 0) {
    Write-Host "=== TEST PASSED ===" -ForegroundColor Green
} else {
    Write-Host "=== TEST FAILED (exit code: $exitCode) ===" -ForegroundColor Red
    if ($exitCode -eq 9 -or $exitCode -eq 3) {
        Write-Host "This appears to be an assertion failure!" -ForegroundColor Yellow
    }
}

exit $exitCode
