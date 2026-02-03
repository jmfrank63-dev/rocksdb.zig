# Build RocksDB C++ Test with MSVC-built RocksDB

This test builds RocksDB from source using MSVC CMake, then links our test against it.

## Quick Start

```powershell
.\build_rocksdb_native.ps1
```

This will:

1. Download/use RocksDB source from Zig package cache
2. Build RocksDB using CMake + MSVC in Release mode
3. Build and run the C API test in Debug mode
4. This lets us test if the assertion is in RocksDB itself or our wrapper

## Manual Steps

If you want to build manually:

```powershell
# 1. Build RocksDB with MSVC CMake (Release mode - faster)
mkdir build_rocksdb
cd build_rocksdb
cmake "$env:USERPROFILE\AppData\Local\zig\p\N-V-__8AAEv0kgK0ypKHX8K7uy2ja2yMJb-o6B8pmW-B0ur5" `
    -G "Visual Studio 17 2022" -A x64 `
    -DCMAKE_BUILD_TYPE=Release `
    -DROCKSDB_BUILD_SHARED=OFF `
    -DWITH_TESTS=OFF `
    -DWITH_GFLAGS=OFF `
    -DWITH_SNAPPY=OFF
cmake --build . --config Release

# 2. Build our C test  (Debug mode - to trigger assertion)
cd ..
mkdir build_debug
cd build_debug  
cmake .. -G "Visual Studio 17 2022" -A x64
cmake --build . --config Debug

# 3. Run
.\Debug\test_c_api.exe
```

## Why This Works

- **Same compiler**: Both RocksDB and our test use MSVC, so ABI is compatible
- **Debug test + Release RocksDB**: We build our test in Debug to trigger RocksDB's assertions, but RocksDB itself in Release for speed
- **C API**: Using C API (not C++) ensures the most stable ABI

## Expected Results

If the test **FAILS** with the assertion → RocksDB bug  
If the test **PASSES** → Our Zig wrapper bug
