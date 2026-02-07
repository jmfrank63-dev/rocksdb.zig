#!/usr/bin/env pwsh
# Build RocksDB with MSVC for use with Zig build system

param(
    [ValidateSet("Debug", "Release")]
    [string]$Config = "Debug"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Building RocksDB with MSVC ===" -ForegroundColor Cyan
Write-Host "Configuration: $Config" -ForegroundColor Yellow
Write-Host ""

if (-not (Test-Path "vendor/rocksdb")) {
    Write-Host "ERROR: vendor/rocksdb not found" -ForegroundColor Red
    Write-Host "Clone it with: git clone --depth 1 --branch v10.9.1 https://github.com/facebook/rocksdb.git vendor/rocksdb" -ForegroundColor Yellow
    exit 1
}

$buildDir = "build/rocksdb_$(if ($Config -eq 'Debug') { 'Debug' } else { 'Release' })"

# Create build directory
if (-not (Test-Path $buildDir)) {
    Write-Host "Creating build directory: $buildDir" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

Set-Location $buildDir

# Configure with CMake
Write-Host "Configuring RocksDB with CMake..." -ForegroundColor Cyan
cmake ../vendor/rocksdb `
    -G "Visual Studio 17 2022" -A x64 `
    -DCMAKE_BUILD_TYPE=$Config `
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

# Build with CMake
Write-Host "Building RocksDB (this may take several minutes)..." -ForegroundColor Cyan
cmake --build . --config $Config

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Build failed" -ForegroundColor Red
    Set-Location ..
    exit 1
}

Set-Location ..

$libPath = "$buildDir/$Config/rocksdb.lib"
if (Test-Path $libPath) {
    Write-Host ""
    Write-Host "✅ SUCCESS!" -ForegroundColor Green
    Write-Host "RocksDB library built at: $libPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now build with: zig build -Dtarget=native-windows-msvc" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "❌ ERROR: Library not found at expected path: $libPath" -ForegroundColor Red
    exit 1
}
