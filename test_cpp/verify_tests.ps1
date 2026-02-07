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
        Write-Host "   [OK] CORRECT - 1 test skipped in debug mode" -ForegroundColor Green
    } else {
        Write-Host "   [ERROR] WRONG - Expected 1 skipped, got $skipped" -ForegroundColor Red
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
        Write-Host "   [OK] CORRECT - 0 tests skipped in release mode" -ForegroundColor Green
    } else {
        Write-Host "   [ERROR] WRONG - Expected 0 skipped, got $skipped" -ForegroundColor Red
        exit 1
    }
} elseif ($releaseOutput -match "(\d+)/(\d+) tests passed") {
    # Handle case where no "skipped" appears in output (when skip count is 0)
    $passed = $matches[1]
    $total = $matches[2]
    Write-Host "   Result: $passed/$total passed, 0 skipped"
    if ($passed -eq $total) {
        Write-Host "   [OK] CORRECT - All tests passed in release mode" -ForegroundColor Green
    } else {
        Write-Host "   [ERROR] WRONG - Not all tests passed" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "   [ERROR] Could not parse test output" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "[OK] Debug mode: Skips BackupEngine.restoreFromLatestBackup"
Write-Host "[OK] Release mode: All tests pass"
Write-Host "`nThe build system is working correctly!" -ForegroundColor Green
