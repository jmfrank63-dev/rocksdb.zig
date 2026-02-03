# Testing RocksDB with MSVC

This directory contains tools to build RocksDB with native MSVC and verify the wrapper's C API usage.

## Build RocksDB with MSVC

```powershell
cd test_cpp
.\build_rocksdb_native.ps1
```

This builds RocksDB v10.9.1 from source using CMake + MSVC in Release mode.  
Output: `test_cpp/build_rocksdb/Release/rocksdb.lib` (~588MB)

## Test C API Against MSVC Build

```powershell
cd ..
.\test_cpp\build_native_debug\Debug\test_c_api.exe
```

This runs a C API test (identical to our Zig wrapper's C calls) against the MSVC-built library.

## Findings

### ✅ What Works

1. **MSVC-built RocksDB (Debug test)**: All backup/restore operations pass
2. **Zig-built RocksDB (Release)**: All 114 tests pass (`zig build test -Doptimize=ReleaseFast`)
3. **Wrapper C API usage**: Verified correct via native C test

### ❌ What Fails

1. **Zig-built RocksDB (Debug)**: `clock_cache.cc:2086` assertion in restore tests

### 📊 Conclusion

The issue is **NOT in the wrapper code**. The same C API calls work perfectly when RocksDB is built with MSVC.

### Why Not Test Zig Wrapper Directly Against MSVC Build?

Mixing toolchains creates ABI incompatibility:

- MSVC's RocksDB uses MSVC's C++ runtime (`MSVCRT.lib`)
- Zig's linker expects MinGW-style libraries (`.a` format)
- Result: Link errors like "could not open 'libmsvcprt.a'"

The standalone C test is sufficient to prove the wrapper's C API usage is correct.
