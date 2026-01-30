# Build and use RocksDB in zig

## Build Dependencies

`rocksdb-zig` is pinned to [Zig `0.15`](https://ziglang.org/download/) and uses [RocksDB `10.9.1`](https://github.com/facebook/rocksdb/releases/tag/v10.9.1).

## Usage

Supported use cases:

- [⬇️](#build-rocksdb) Build a RocksDB static library using the zig build system.
- [⬇️](#import-rocksdb-in-your-zig-project) Use the RocksDB C API through auto-generated Zig bindings.
- [⬇️](#import-rocksdb-in-your-zig-project) Import an idiomatic zig library of bindings that wrap the RocksDB library with hand-written zig code.

## Build RocksDB

Clone this repository, then run `zig build`.

You will find a statically linked `rocksdb` archive
in `zig-out/lib/librocksdb.a`.

You can use this with any language or build system.

### Build variants and flags

#### Default build (full C++ API, static)

```bash
zig build
```

Includes all RocksDB C++ APIs. Produces `zig-out/lib/librocksdb.a` on non-Windows or `zig-out/lib/rocksdb.lib` on Windows.

#### C-API-only static library

```bash
zig build -Denable_c_api_static=true
```

Builds a static library exposing only the C API (from `rocksdb/c.h`). This produces a smaller library and reduces final executable size compared to the full C++ API build. Useful when you only need the C API or are concerned about binary size.

#### Shared library (non-Windows)

```bash
zig build
```

On Linux/macOS, both static and shared libraries are built by default. The shared library includes the full C++ API.

#### Shared library on Windows (C-API-only)

```bash
zig build -Denable_c_api_shared=true
```

On Windows, only the C API can be exported to a DLL due to symbol export limits. See the Windows shared library note below for details.

#### ReleaseFast builds

Add `--release=fast` to any build command for optimized release builds:

```bash
zig build --release=fast
zig build --release=fast -Denable_c_api_static=true
zig build --release=fast -Denable_c_api_shared=true
```

#### Additional options

- `-Denable_snappy=true` - Enable Snappy compression support
- `-Dforce_pic=true` - Force position-independent code for libraries

### Windows shared library note

On Windows, only the C API can be built as a shared library. This is a known
RocksDB limitation due to the DLL export symbol limit. See
<https://github.com/facebook/rocksdb/issues/981> for details.

## Import RocksDB in your Zig Project

Fetch `rocksdb-zig` and save it to your `build.zig.zon`:

```bash
zig fetch --save=rocksdb https://github.com/Syndica/rocksdb-zig/archive/<COMMIT_HASH>.tar.gz
```

Add the import to a module in your `build.zig`:

```zig
// Choose ONE of the following:

// Option 1 (RECOMMENDED): Idiomatic Zig bindings with error handling and RAII
const rocksdb = b.dependency("rocksdb", .{}).module("bindings");

// Option 2: Raw C API bindings (auto-generated from rocksdb/c.h)
// const rocksdb = b.dependency("rocksdb", .{}).module("rocksdb");

exe.root_module.addImport("rocksdb", rocksdb);
```

Then import the module in your code:

```zig
const rocksdb = @import("rocksdb");
```
