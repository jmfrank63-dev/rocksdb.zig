# Build and use RocksDB in zig

## Build Dependencies

`rocksdb-zig` is pinned to [Zig `0.15`](https://ziglang.org/download/), so you will need to have it installed.

## Usage

Supported use cases:

- [⬇️](#build-rocksdb) Build a RocksDB static library using the zig build system.
- [⬇️](#import-rocksdb-c-api-in-the-zig-build-system) Use the RocksDB C API through auto-generated Zig bindings.
- [⬇️](#import-the-zig-bindings-library-using-the-zig-build-system) Import an idiomatic zig library of bindings that wrap the RocksDB library with hand-written zig code.

## Build RocksDB

Clone this repository, then run `zig build`.

You will find a statically linked `rocksdb` archive
in `zig-out/lib/librocksdb.a`.

You can use this with any language or build system.

### Build variants and flags

Default build (full C++ API, static):

```bash
zig build
```

C-API-only static library:

```bash
zig build -Denable_c_api_static=true
```

Shared library (non-Windows):

```bash
zig build
```

Shared library on Windows (C-API-only):

```bash
zig build -Denable_c_api_shared=true
```

ReleaseFast builds:

```bash
zig build -Doptimize=ReleaseFast
zig build -Doptimize=ReleaseFast -Denable_c_api_static=true
zig build -Doptimize=ReleaseFast -Denable_c_api_shared=true
```

### Windows shared library note

On Windows, only the C API can be built as a shared library. This is a known
RocksDB limitation due to the DLL export symbol limit. See
<https://github.com/facebook/rocksdb/issues/981> for details.

## Import RocksDB C API in the Zig Build System

Fetch `rocksdb` and save it to your `build.zig.zon`:

```bash
zig fetch --save=rocksdb https://github.com/Syndica/rocksdb-zig/archive/<COMMIT_HASH>.tar.gz
```

Add the import to a module:

```zig
const rocksdb = b.dependency("rocksdb", .{}).module("rocksdb");
exe.root_module.addImport("rocksdb", rocksdb);
```

Import the `rocksdb` module.

```zig
const rocksdb = @import("rocksdb");
```

## Import the Zig bindings library using the Zig Build System

Fetch `rocksdb` and save it to your `build.zig.zon`:

```bash
zig fetch --save=rocksdb https://github.com/Syndica/rocksdb-zig/archive/<COMMIT_HASH>.tar.gz
```

Add the import to a module:

```zig
const bindings = b.dependency("rocksdb", .{}).module("bindings");
exe.root_module.addImport("rocksdb", bindings);
```

Import the `rocksdb` module.

```zig
const rocksdb = @import("rocksdb");
```
