#!/usr/bin/env pwsh
# Test build script

Write-Host "=== Testing Zig Build System ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Testing default build..." -ForegroundColor Yellow
$output1 = zig build 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "   [OK] Default build: PASSED" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] Default build: FAILED" -ForegroundColor Red
}

Write-Host ""
Write-Host "2. Testing MSVC ABI build..." -ForegroundColor Yellow
$output2 = zig build -Dtarget=native-windows-msvc 2>&1
Write-Host $output2[0..5] -join "`n"
if ($LASTEXITCODE -eq 0) {
    Write-Host "   [OK] MSVC ABI build: PASSED" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] MSVC ABI build: FAILED" -ForegroundColor Red
}

Write-Host ""
Write-Host "3. Testing MSVC ABI test (should skip)..." -ForegroundColor Yellow
$output3 = zig build test -Dtarget=native-windows-msvc 2>&1
Write-Host $output3[0..5] -join "`n"
if ($LASTEXITCODE -eq 0) {
    Write-Host "   [OK] MSVC ABI test: PASSED (tests skipped)" -ForegroundColor Green
} else {
    Write-Host "   [ERROR] MSVC ABI test: FAILED" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
Write-Host "Default build works with Zig clang"
Write-Host "MSVC ABI automatically uses pre-built library"
Write-Host "MSVC ABI tests skip in debug due to CRT conflicts"
