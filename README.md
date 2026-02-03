# rocksdb.zig

## Comprehensive Zig bindings for RocksDB v10.9.1

A production-ready, feature-rich Zig wrapper for Facebook's RocksDB embedded database, providing both low-level C API bindings and high-level idiomatic Zig interfaces.

## Attribution

This project was originally forked from [Syndica/rocksdb-zig](https://github.com/Syndica/rocksdb-zig) and has been **extensively rewritten and modernized** for Zig 0.15.2 and RocksDB v10.9.1.

- **Original work**: Copyright © Syndica (Apache 2.0 License)
- **Substantial modifications and additions**: Copyright © 2024-2026 Johannes Maria Frank <jmfrank63@gmail.com>

This fork represents a near-complete rewrite with ~97% new code, including comprehensive DBOptions, backup/recovery systems, transactions, merge operators, and a 114-test suite. See [NOTICE](NOTICE) for detailed attribution.

## Features

- ✅ **Complete DBOptions system** - 30+ options including compression, bloom filters, compaction control
- ✅ **Backup & Recovery** - BackupEngine, Checkpoint, incremental backups, restore operations
- ✅ **Transactions** - OptimisticTransactionDB and TransactionDB with full isolation support
- ✅ **Merge Operators** - Built-in (StringAppend, UInt64Add, Max) + custom callback support
- ✅ **Comprehensive Read/Write Options** - Checksums, caching, snapshots, WAL control
- ✅ **Iterator API** - Forward/reverse iteration with seek operations
- ✅ **Column Families** - Create, manage, and query multiple column families
- ✅ **Write Batches** - Atomic batch operations across column families
- ✅ **Snapshots** - Point-in-time consistent reads
- ✅ **114 passing tests** - Comprehensive test coverage with memory leak detection
- ✅ **Production-ready** - Battle-tested with RocksDB v10.9.1

See [ROADMAP.md](ROADMAP.md) for complete feature status and future plans.

## Build Dependencies

`rocksdb.zig` requires [Zig `0.15.2`](https://ziglang.org/download/) and uses [RocksDB `10.9.1`](https://github.com/facebook/rocksdb/releases/tag/v10.9.1).

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

Add `-Doptimize=ReleaseFast` to any build command for optimized release builds:

```bash
zig build -Doptimize=ReleaseFast
zig build -Doptimize=ReleaseFast -Denable_c_api_static=true
zig build -Doptimize=ReleaseFast -Denable_c_api_shared=true
```

#### Additional options

- `-Denable_snappy=true` - Enable Snappy compression support
- `-Dforce_pic=true` - Force position-independent code for libraries

### Windows shared library note

On Windows, only the C API can be built as a shared library. This is a known
RocksDB limitation due to the DLL export symbol limit. See
<https://github.com/facebook/rocksdb/issues/981> for details.

## Import RocksDB in your Zig Project

Fetch `rocksdb.zig` and save it to your `build.zig.zon`:

```bash
zig fetch --save=rocksdb <https://github.com/jmfrank63/rocksdb.zig/archive/<COMMIT_HASH>.tar.gz>
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

## Testing

Run the comprehensive test suite:

```bash
# Recommended: Release mode (all 114 tests pass)
zig build test -Doptimize=ReleaseFast

# Debug mode (see ROADMAP.md for known Zig linker limitations on Windows)
zig build test
```

## Documentation

- [ROADMAP.md](ROADMAP.md) - Complete feature list, implementation status, and future plans
- [NOTICE](NOTICE) - Detailed attribution and modification history
- [report_issue/](report_issue/) - Known issues and workarounds for Zig toolchain

## License

This project is licensed under the Apache License 2.0 - see [LICENSE](LICENSE) for details.

Original work: Copyright © Syndica  
Modifications and additions: Copyright © 2024-2026 Johannes Maria Frank

## Contact & Support

- **Author**: Johannes Maria Frank
- **Email**: <jmfrank63@gmail.com>
- **Repository**: <https://github.com/jmfrank63/rocksdb.zig>
- **Original Source**: <https://github.com/Syndica/rocksdb-zig>

## Contributing

Contributions are welcome! This project maintains compatibility with Zig 0.15.2 and RocksDB v10.9.1.

When contributing, please:

1. Ensure all tests pass (`zig build test -Doptimize=ReleaseFast`)
2. Add tests for new features
3. Update ROADMAP.md for major additions
4. Follow existing code style and patterns

---

**Note**: If migrating from Syndica/rocksdb-zig, this is a hard fork with substantial breaking changes. Review the [NOTICE](NOTICE) file for a complete list of modifications.
