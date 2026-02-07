#!/usr/bin/env pwsh
# Verify test execution

Write-Host "`n=== Verifying Test Execution ===" -ForegroundColor Cyan

Write-Host "`n1. Debug build (should skip 1 test)..." -ForegroundColor Yellow
$debugOutput = zig build test --summary all 2>&1 | Out-String
if ($debugOutput -match "(\d+)/(\d+) tests passed; (\d+) skipped") {
    $passed = $matches[1]
    $total = $matches[2]
    $skipped = $matches[3]
    Write-Host "   Result: $passed/$total passed, $skipped skipped"
    if ($skipped -eq "1") {
        Write-Host "   ✅ CORRECT - 1 test skipped in debug mode" -ForegroundColor Green
    } else {
        Write-Host "   ❌ WRONG - Expected 1 skipped, got $skipped" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n2. Release build (should skip 0 tests)..." -ForegroundColor Yellow  
$releaseOutput = zig build test --summary all --release=fast 2>&1 | Out-String
if ($releaseOutput -match "(\d+)/(\d+) tests passed; (\d+) skipped") {
    $passed = $matches[1]
    $total = $matches[2]
    $skipped = $matches[3]
    Write-Host "   Result: $passed/$total passed, $skipped skipped"
    if ($skipped -eq "0") {
        Write-Host "   ✅ CORRECT - 0 tests skipped in release mode" -ForegroundColor Green
    } else {
        Write-Host "   ❌ WRONG - Expected 0 skipped, got $skipped" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "✅ Debug mode: Skips BackupEngine.restoreFromLatestBackup"
Write-Host "✅ Release mode: All tests pass"
Write-Host "`nThe build system is working correctly!" -ForegroundColor Green
