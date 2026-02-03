# RocksDB C++ Backup/Restore Test

This directory contains a C++ test that reproduces the backup/restore workflow from our Zig wrapper to determine if the assertion failure is in RocksDB itself or in our wrapper code.

## Purpose

We're experiencing an assertion failure in RocksDB's debug builds:

```text
Assertion failed: GetRefcount(h.meta.LoadRelaxed()) == 0
File: cache/clock_cache.cc, line 2086
Location: AutoHyperClockTable::~AutoHyperClockTable()
```

This test mimics our Zig wrapper's restore test workflow using pure C++ to isolate whether this is:

- **A RocksDB bug**: The C++ test will fail with the same assertion
- **A wrapper bug**: The C++ test will pass, indicating our lifecycle management is incorrect

## Test Cases

The test runs two scenarios:

1. **Test 1**: Default options with block cache enabled
   - This matches typical RocksDB usage

2. **Test 2**: Block cache disabled
   - This matches our Zig wrapper's mitigation attempt

## Workflow

Each test follows these steps:

1. Create a database and populate it with data
2. Open a BackupEngine and create a backup
3. Close the BackupEngine
4. Open the BackupEngine again
5. Restore from the backup
6. Verify the restored data

This mirrors exactly what our Zig wrapper's restore tests do.

## Building and Running

### Prerequisites

- CMake 3.10+
- Visual Studio 2022 (or compatible C++ compiler)
- RocksDB library built (run `zig build` in parent directory first)

### Run the test

**Debug mode** (to reproduce the assertion):

```powershell
.\build_and_run.ps1 -BuildType Debug
```

**Release mode** (should pass):

```powershell
.\build_and_run.ps1 -BuildType Release
```

### Manual build (alternative)

```powershell
# Configure
mkdir build_debug
cd build_debug
cmake .. -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=Debug

# Build
cmake --build . --config Debug

# Run
.\Debug\test_backup_restore.exe
```

## Expected Results

### If RocksDB has the bug

- Debug build: **FAILS** with assertion at clock_cache.cc:2086
- Release build: **PASSES**
- Conclusion: This is a RocksDB debug-mode assertion issue, not our wrapper

### If wrapper has the bug

- Debug build: **PASSES**
- Release build: **PASSES**  
- Conclusion: Our Zig wrapper's lifecycle management needs fixing

## Analysis

The assertion is in `AutoHyperClockTable::~AutoHyperClockTable()`, which is part of RocksDB's HyperClockCache implementation. The assertion checks that there are no outstanding cache entry references during destruction.

Key observations:

- The assertion only triggers in debug builds (release builds skip assertion checks)
- It occurs during BackupEngine cleanup/destruction
- It's related to cache reference counting, not correctness
- The issue may be a race condition or overly strict assertion in RocksDB's debug code

## References

- RocksDB clock cache implementation: `cache/clock_cache.cc`
- RocksDB documentation mentions old ClockCache bugs: `HISTORY.md:1654`
- HyperClockCache is the current default implementation
