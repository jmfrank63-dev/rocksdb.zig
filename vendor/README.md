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

Use the provided PowerShell script from the project root:

```powershell
# From rocksdb-zig root directory
.\scripts\build_rocksdb.ps1 Release  # Recommended for production
.\scripts\build_rocksdb.ps1 Debug    # For debug (note: Zig tests use Release lib in both modes)
```

This will:
1. Configure RocksDB with CMake using Ninja generator
2. Build the static library with optimal parallel compilation
3. Place it in `build\rocksdb_Release\rocksdb.lib` or `build\rocksdb_Debug\rocksdb.lib`

### What the Script Does

- Automatically detects Visual Studio installation
- Sets up MSVC environment for Ninja
- Builds with static CRT (`/MT`) to avoid linker warnings
- Enables RTTI for RocksDB compatibility
- Uses all CPU cores for parallel compilation

### Manual Build (Advanced)

If you prefer to build manually with Ninja:

```powershell
# From rocksdb-zig root
mkdir build\rocksdb_Release
cd build\rocksdb_Release

# Setup MSVC environment (PowerShell)
$vsPath = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
Import-Module "$vsPath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
Enter-VsDevShell -VsInstallPath $vsPath -SkipAutomaticLocation

# Configure with Ninja
cmake ..\..\vendor\rocksdb -G "Ninja" -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_DEFAULT_CMP0091=NEW -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreaded -DWITH_MD_LIBRARY=OFF -DUSE_RTTI=ON -DROCKSDB_BUILD_SHARED=OFF -DWITH_TESTS=OFF -DWITH_TOOLS=OFF -DFAIL_ON_WARNINGS=OFF

# Build
cmake --build . --parallel
```

### After Building

Once the library is built, the Zig build system will automatically detect and link against it:

```powershell
# Back to rocksdb-zig root
zig build -Dtarget=native-windows-msvc
zig build test -Dtarget=native-windows-msvc --release=fast
```

**Note:** Zig builds always use the Release RocksDB library to avoid CRT debug symbol conflicts, regardless of whether you build Zig code in Debug or Release mode.

## Default Build

When building without MSVC target (default clang build), the build system uses the Zig dependency system from `build.zig.zon` instead of the vendor directory. No manual build step is needed.
