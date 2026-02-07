# Vendor Directory

This directory contains vendored dependencies for the rocksdb-zig project.

## RocksDB

To use RocksDB as a local submodule/vendored dependency:

### Setup (Git Repository)

If this is a git repository, add RocksDB as a submodule:

```bash
git submodule add -b v10.9.1 https://github.com/facebook/rocksdb.git vendor/rocksdb
git submodule update --init --recursive
```

### Setup (Non-Git)

If this is not a git repository, clone RocksDB directly:

```bash
git clone --depth 1 --branch v10.9.1 https://github.com/facebook/rocksdb.git vendor/rocksdb
```

## Building for MSVC

When building with `-Dtarget=native-windows-msvc`, you need to build RocksDB with MSVC first.

### Quick Start

Use the provided PowerShell script:

```powershell
cd vendor
.\build_rocksdb.ps1 -BuildType Debug    # For debug builds
.\build_rocksdb.ps1 -BuildType Release  # For release builds
```

This will:
1. Configure RocksDB with CMake using Visual Studio 2022
2. Build the static library
3. Place it in `vendor/build_rocksdb_Debug/Debug/rocksdb.lib` or `vendor/build_rocksdb_Release/Release/rocksdb.lib`

### Manual Build

If you prefer to build manually:

```bash
cd vendor
cmake -S rocksdb -B build_rocksdb_Debug -G "Visual Studio 17 2022" -A x64 -DCMAKE_BUILD_TYPE=Debug -DROCKSDB_BUILD_SHARED=OFF -DWITH_TESTS=OFF -DWITH_TOOLS=OFF
cd build_rocksdb_Debug
cmake --build . --config Debug
```

### After Building

Once the library is built, the Zig build system will automatically detect and link against it:

```bash
cd ../..  # Back to rocksdb-zig root
zig build -Dtarget=native-windows-msvc
zig build test -Dtarget=native-windows-msvc
```

## Default Build

When building without MSVC target (default clang build), the build system uses the Zig dependency system from `build.zig.zon` instead of the vendor directory. No manual build step is needed.
